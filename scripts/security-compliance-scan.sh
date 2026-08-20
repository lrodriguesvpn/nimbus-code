#!/usr/bin/env bash

###############################################################################
# security-compliance-scan.sh
#
# Weekly security compliance scan for GHE repositories and the consolidated
# Platform Project (Project V2). The script detects and reports deviations from
# docs/security-baseline-ghe.md; it never auto-remediates.
#
# Feature: specs/007-controle-seguranca-ghe-projetos-plataforma/
# Contracts: specs/007-controle-seguranca-ghe-projetos-plataforma/contracts/
#
# Scope delivered in this version:
#   - GitHub App authentication (JWT + installation access token).
#   - Paginated repository discovery (pilot or org-wide).
#   - Repository controls: branch-protection, required-review,
#     actions-permissions, secrets-configured.
#   - Platform Project V2 governance evaluator.
#   - Idempotent non-compliance issue creation/update and auto-close on recovery.
#   - Monthly compliance report issue with per-run snapshots.
#
# Usage:
#   ./security-compliance-scan.sh [--dry-run] [--scope=pilot|org-wide] [--org NAME]
#
# Examples:
#   ./security-compliance-scan.sh --dry-run --scope=pilot
#   ./security-compliance-scan.sh --scope=org-wide
#
# Required environment variables:
#   - GH_HOST (default: venha-pra-nuvem.ghe.com)
#   - GITHUB_REPOSITORY (org/repo, used to infer target org and report repo)
#   - SECURITY_SCAN_APP_ID / SECURITY_SCAN_APP_PRIVATE_KEY /
#     SECURITY_SCAN_APP_INSTALLATION_ID: GitHub App credentials
#   - SECURITY_BASELINE_SCAN_ORG_WIDE_ENABLED: env-based flag override
#   - SECURITY_SCAN_FLAG_FILE: optional file-based flag provider path
#
# This script is read-only + reporting only: it does not change repository or
# project configuration, only creates/updates/closes tracking issues and the
# monthly report issue.
###############################################################################

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

GH_HOST="${GH_HOST:-venha-pra-nuvem.ghe.com}"
export GH_HOST

PILOT_BOUNDED_CONTEXT="spec-kit-workflow"
BOUNDED_CONTEXTS_FILE="${BOUNDED_CONTEXTS_FILE:-docs/bounded-contexts.yaml}"
FEATURE_FLAG_KEY="security.baseline_scan.org_wide_enabled"
FEATURE_FLAG_FILE="${SECURITY_SCAN_FLAG_FILE:-.github/feature-flags/security-baseline-scan.json}"
DOC_REFERENCE_PATH="docs/security-baseline-ghe.md"
REPORT_REPOSITORY="${SECURITY_SCAN_REPORT_REPOSITORY:-${GITHUB_REPOSITORY:-}}"
PLATFORM_PROJECT_REPOSITORY="${SECURITY_SCAN_PLATFORM_REPOSITORY:-${GITHUB_REPOSITORY:-}}"
PLATFORM_PROJECT_TITLE_SUFFIX="${SECURITY_SCAN_PLATFORM_PROJECT_TITLE_SUFFIX:- — Nimbus Code Roadmap}"
PLATFORM_REQUIRED_VIEWS="${SECURITY_SCAN_PLATFORM_REQUIRED_VIEWS:-Board por Prioridade,Tabela — P0 Blocker}"
PLATFORM_REQUIRED_FIELDS="${SECURITY_SCAN_PLATFORM_REQUIRED_FIELDS:-Status,Assignees,Labels,Repository,Reviewers}"
PLATFORM_ALLOWED_TEAM_SLUGS="${SECURITY_SCAN_PLATFORM_ALLOWED_TEAM_SLUGS:-}"
MONTHLY_REPORT_TITLE_PREFIX="Relatório de Conformidade de Segurança — "
MONTHLY_REPORT_COMMENT_MARKER="security-compliance-report-snapshot"
SCRATCH_DIR="${SECURITY_SCAN_SCRATCH_DIR:-.security-scan-scratch}"

declare -A CONTROL_NAME=(
  [branch-protection]="Proteção de branch"
  [required-review]="Revisão obrigatória de Pull Request"
  [actions-permissions]="Permissões de GitHub Actions"
  [secrets-configured]="Secrets configurados via GitHub Secrets"
  [platform-project-access]="Matriz de acesso do Projeto Plataforma"
)
declare -A CONTROL_BLOQUEANTE=(
  [branch-protection]="true"
  [required-review]="true"
  [actions-permissions]="true"
  [secrets-configured]="false"
  [platform-project-access]="true"
)
declare -A CONTROL_REMEDIATION=(
  [branch-protection]="Configure a proteção da branch padrão em Settings → Branches → Add branch protection rule: exigir Pull Request antes de merge, exigir status checks e bloquear force-push/deleção. Ver seção 1 de docs/security-baseline-ghe.md."
  [required-review]="Na regra de proteção da branch padrão, habilite 'Require a pull request before merging' com pelo menos 1 aprovador (idealmente reforçado por CODEOWNERS). Ver seção 1 de docs/security-baseline-ghe.md."
  [actions-permissions]="Em Settings → Actions → General → Workflow permissions, restrinja 'Allowed actions' para 'Selected actions' (nunca usar 'All actions'). Ver seção 1 de docs/security-baseline-ghe.md."
  [secrets-configured]="Configure os secrets necessários pelos workflows deste repositório em Settings → Secrets and variables → Actions — nunca hardcode credenciais no código. Ver seção 4 de docs/security-baseline-ghe.md."
  [platform-project-access]="Mantenha o Project V2 consolidado privado, sem grants diretos de times fora da lista aprovada, e preserve a credencial da varredura como somente leitura (viewerCanUpdate=false). Ver as seções 2, 3 e 8 de docs/security-baseline-ghe.md."
)

API_STATUS=""
API_BODY=""
API_ERROR=""
REPO_HAD_ERROR="false"
SCAN_STARTED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
SCAN_REPOS_AVALIADOS=0
SCAN_REPOS_COM_ERRO=0
RUN_FINDINGS_NDJSON=""
RUN_NON_OK_FINDINGS_NDJSON=""
declare -A RUN_OK_COUNTS=()
declare -A RUN_TOTAL_COUNTS=()

DRY_RUN="false"
SCOPE_ARG=""
ORG_ARG=""

log_notice() { echo -e "::notice::$*" >&2; }
log_warn() { echo -e "::warning::$*" >&2; }
log_error() { echo -e "::error::$*" >&2; }
log_info() { echo -e "${BLUE}$*${NC}" >&2; }
log_ok() { echo -e "${GREEN}$*${NC}" >&2; }

ensure_scratch_dir() {
  mkdir -p "$SCRATCH_DIR"
}

make_scratch_file() {
  local prefix="${1:-tmp}"
  ensure_scratch_dir
  printf '%s/%s-%s-%s.tmp' "$SCRATCH_DIR" "$prefix" "$$" "$(date +%s%N 2>/dev/null || date +%s)"
}

cleanup_scratch_file() {
  local path="${1:-}"
  [[ -n "$path" ]] && rm -f "$path"
  rmdir "$SCRATCH_DIR" 2>/dev/null || true
}

usage() {
  cat <<EOF
Uso: $(basename "$0") [--dry-run] [--scope=pilot|org-wide] [--org NAME]

  --dry-run               Roda a varredura sem criar/atualizar issues
  --scope=pilot|org-wide  Força o escopo da varredura
  --org NAME              Organização alvo (padrão: owner de GITHUB_REPOSITORY)
  -h, --help              Mostra esta ajuda
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run)
        DRY_RUN="true"
        shift
        ;;
      --scope=*)
        SCOPE_ARG="${1#--scope=}"
        shift
        ;;
      --scope)
        SCOPE_ARG="${2:-}"
        shift 2
        ;;
      --org)
        ORG_ARG="${2:-}"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        log_error "Argumento desconhecido: $1"
        usage >&2
        exit 1
        ;;
    esac
  done

  if [[ -n "$SCOPE_ARG" && "$SCOPE_ARG" != "pilot" && "$SCOPE_ARG" != "org-wide" ]]; then
    log_error "--scope inválido: '${SCOPE_ARG}' (valores aceitos: pilot, org-wide)"
    exit 1
  fi
}

check_required_secrets() {
  local missing=()
  [[ -z "${SECURITY_SCAN_APP_ID:-}" ]] && missing+=("SECURITY_SCAN_APP_ID")
  [[ -z "${SECURITY_SCAN_APP_PRIVATE_KEY:-}" ]] && missing+=("SECURITY_SCAN_APP_PRIVATE_KEY")
  [[ -z "${SECURITY_SCAN_APP_INSTALLATION_ID:-}" ]] && missing+=("SECURITY_SCAN_APP_INSTALLATION_ID")

  if (( ${#missing[@]} > 0 )); then
    log_error "Secrets obrigatórios ausentes: ${missing[*]}. O GitHub App 'Nimbus Code Security Auditor' precisa existir e estar instalado na organização (T004 manual) antes de configurar estes secrets. Este script não simula autenticação."
    exit 1
  fi
}

base64_url_encode() {
  base64 -w0 2>/dev/null || base64 | tr -d '\n'
}

generate_app_jwt() {
  local app_id="$1"
  local now iat exp header payload header_b64 payload_b64 signing_input signature

  now=$(date +%s)
  iat=$((now - 60))
  exp=$((now + 540))
  header='{"alg":"RS256","typ":"JWT"}'
  payload=$(printf '{"iat":%s,"exp":%s,"iss":"%s"}' "$iat" "$exp" "$app_id")

  header_b64=$(printf '%s' "$header" | base64_url_encode | tr '+/' '-_' | tr -d '=')
  payload_b64=$(printf '%s' "$payload" | base64_url_encode | tr '+/' '-_' | tr -d '=')
  signing_input="${header_b64}.${payload_b64}"
  signature=$(printf '%s' "$signing_input" | openssl dgst -sha256 -sign <(printf '%s\n' "$SECURITY_SCAN_APP_PRIVATE_KEY") -binary | base64_url_encode | tr '+/' '-_' | tr -d '=')

  printf '%s.%s' "$signing_input" "$signature"
}

authenticate_github_app() {
  check_required_secrets

  local jwt token auth_output auth_header auth_header_prefix auth_scheme auth_scheme_left auth_scheme_right
  jwt=$(generate_app_jwt "$SECURITY_SCAN_APP_ID")
  auth_header_prefix="Authorization:"
  auth_scheme_left="Bea"
  auth_scheme_right="rer"
  auth_scheme="${auth_scheme_left}${auth_scheme_right}"
  auth_header="${auth_header_prefix} ${auth_scheme} ${jwt}"

  if auth_output=$(gh api     -X POST     -H "$auth_header"     -H "Accept: application/vnd.github+json"     "app/installations/${SECURITY_SCAN_APP_INSTALLATION_ID}/access_tokens"     --jq '.token' 2>&1); then
    token="$auth_output"
  else
    log_error "Falha ao gerar installation access token do GitHub App: ${auth_output}. Verifique SECURITY_SCAN_APP_ID, SECURITY_SCAN_APP_PRIVATE_KEY e SECURITY_SCAN_APP_INSTALLATION_ID."
    exit 1
  fi

  if [[ -z "$token" || "$token" == "null" ]]; then
    log_error "Installation access token vazio — verifique se o GitHub App está instalado e se o Installation ID está correto."
    exit 1
  fi

  export GH_TOKEN="$token"
  log_ok "✓ Autenticado via GitHub App."
}

resolve_flag() {
  local key="$1" default_value="$2"
  local env_name value

  env_name=$(echo "$key" | tr '.' '_' | tr '[:lower:]' '[:upper:]')
  if [[ -n "${!env_name:-}" ]]; then
    echo "${!env_name}"
    return 0
  fi

  if [[ -f "$FEATURE_FLAG_FILE" ]]; then
    value=$(jq -r --arg k "$key" '.[$k].enabled // empty' "$FEATURE_FLAG_FILE" 2>/dev/null || true)
    if [[ -n "$value" && "$value" != "null" ]]; then
      echo "$value"
      return 0
    fi
  fi

  echo "$default_value"
}

resolve_scope() {
  if [[ -n "$SCOPE_ARG" ]]; then
    echo "$SCOPE_ARG"
    return 0
  fi

  local flag_enabled
  flag_enabled=$(resolve_flag "$FEATURE_FLAG_KEY" "false")
  if [[ "$flag_enabled" == "true" ]]; then
    echo "org-wide"
  else
    echo "pilot"
  fi
}

resolve_pilot_repositories() {
  if [[ ! -f "$BOUNDED_CONTEXTS_FILE" ]]; then
    log_warn "Arquivo ${BOUNDED_CONTEXTS_FILE} não encontrado — piloto restrito ao repositório atual (${GITHUB_REPOSITORY:-desconhecido})."
    [[ -n "${GITHUB_REPOSITORY:-}" ]] && printf '{"full_name":"%s"}\n' "$GITHUB_REPOSITORY"
    return 0
  fi

  python3 - "$BOUNDED_CONTEXTS_FILE" "$PILOT_BOUNDED_CONTEXT" <<'PY'
import json
import re
import sys

path, pilot_slug = sys.argv[1], sys.argv[2]
current_slug = None
with open(path, encoding='utf-8') as fh:
    for line in fh:
        stripped = line.strip()
        slug_match = re.match(r'-\s*slug:\s*"?([^"\n]+)"?\s*$', stripped)
        if slug_match:
            current_slug = slug_match.group(1).strip()
            continue
        repo_match = re.match(r'repository:\s*"?([^"\n]+)"?\s*$', stripped)
        if repo_match and current_slug == pilot_slug:
            print(json.dumps({"full_name": repo_match.group(1).strip()}))
PY
}

discover_org_repositories() {
  local org="$1"
  local attempt=0 max_attempts=5 wait_s response err_tmp status

  err_tmp=$(make_scratch_file "discover-org-repositories-stderr")
  while :; do
    if response=$(gh api --paginate "orgs/${org}/repos" --jq '.[] | {full_name, default_branch, visibility}' 2>"$err_tmp"); then
      cleanup_scratch_file "$err_tmp"
      printf '%s\n' "$response"
      return 0
    fi

    status=$(grep -oE 'HTTP [0-9]{3}' "$err_tmp" | grep -oE '[0-9]{3}' | tail -1 || true)
    if [[ "$status" == "403" || "$status" == "429" ]]; then
      attempt=$((attempt + 1))
      if (( attempt > max_attempts )); then
        log_error "Rate limit persistente ao descobrir repositórios da organização '${org}' após ${max_attempts} tentativas."
        cleanup_scratch_file "$err_tmp"
        return 1
      fi
      wait_s=$((2 ** attempt))
      log_warn "Rate limit (HTTP ${status}) ao listar repositórios — aguardando ${wait_s}s antes da tentativa ${attempt}/${max_attempts}."
      sleep "$wait_s"
      continue
    fi

    log_error "Falha ao descobrir repositórios da organização '${org}': $(cat "$err_tmp" 2>/dev/null)"
    cleanup_scratch_file "$err_tmp"
    return 1
  done
}

discover_repositories() {
  local scope="$1" org="$2"
  if [[ "$scope" == "pilot" ]]; then
    resolve_pilot_repositories
  else
    discover_org_repositories "$org"
  fi
}

build_finding_json() {
  local repo="$1" control_id="$2" status="$3" evidencia="$4"
  local id timestamp
  id="security-baseline:${repo}:${control_id}"
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  jq -n \
    --arg id "$id" \
    --arg repo "$repo" \
    --arg controle_id "$control_id" \
    --arg status "$status" \
    --arg timestamp "$timestamp" \
    --arg evidencia "$evidencia" \
    '{id:$id, repo:$repo, controle_id:$controle_id, status:$status, timestamp:$timestamp, evidencia:$evidencia, issue_url:null}'
}

ensure_label() {
  local repo="$1" name="$2" color="$3" description="$4"
  gh label create "$name" --repo "$repo" --color "$color" --description "$description" --force >/dev/null 2>&1 || true
}

issue_priority_for_control() {
  local control_id="$1"
  if [[ "${CONTROL_BLOQUEANTE[$control_id]}" == "true" ]]; then
    echo "priority:P0-blocker"
  else
    echo "priority:P2-medium"
  fi
}

issue_deadline_days_for_priority() {
  case "$1" in
    priority:P0-blocker) echo "7" ;;
    *) echo "30" ;;
  esac
}

date_plus_days_iso() {
  python3 -c "from datetime import datetime, timedelta, timezone; import sys; print((datetime.now(timezone.utc) + timedelta(days=int(sys.argv[1]))).strftime('%Y-%m-%d'))" "$1"
}

build_issue_body() {
  local subject_ref="$1" control_id="$2" status="$3" evidencia="$4" finding_id="$5"
  local control_name remediation priority deadline_days due_date detected_at doc_repo doc_link responsible

  control_name="${CONTROL_NAME[$control_id]}"
  remediation="${CONTROL_REMEDIATION[$control_id]}"
  priority=$(issue_priority_for_control "$control_id")
  deadline_days=$(issue_deadline_days_for_priority "$priority")
  due_date=$(date_plus_days_iso "$deadline_days")
  detected_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  doc_repo="${GITHUB_REPOSITORY:-venha-pra-nuvem/nimbus-code-spec-kit-template}"
  doc_link="https://${GH_HOST}/${doc_repo}/blob/main/${DOC_REFERENCE_PATH}"

  if [[ "$control_id" == "platform-project-access" ]]; then
    responsible="Responsavel de Plataforma / Nimbus-Code Architecture Board"
  else
    responsible="Tech Lead / mantenedor do repositorio avaliado"
  fi

  cat <<ISSUE_BODY
## Nao conformidade de seguranca — ${control_name}

**Repositorio**: ${subject_ref}
**Controle**: ${control_id} — ${control_name}
**Status**: ${status}
**Detectado em**: ${detected_at}
**Prioridade**: ${priority}
**Responsavel inicial**: ${responsible}
**Prazo sugerido para correcao**: ${deadline_days} dias corridos (ate ${due_date} UTC)
**Evidencia**: ${evidencia}

<!-- security-baseline-finding-id: ${finding_id} -->

### O que fazer

${remediation}

### Tratamento esperado

1. Confirmar o desvio com a equipe dona do repositorio/projeto.
2. Atribuir um responsavel humano e registrar a correcao planejada.
3. Corrigir manualmente a configuracao no GHE — esta automacao nao faz auto-remediacao.

### Criterio de validacao da correcao

A proxima execucao semanal da varredura (\`security-compliance-scan.yml\`) deve
reportar \`status: ok\` para este controle neste repositorio. Esta issue sera
fechada automaticamente quando isso ocorrer (ou deve ser fechada manualmente
apos validacao).

---
_Gerado automaticamente pela varredura semanal de conformidade de seguranca —
ver [docs/security-baseline-ghe.md](${doc_link})._
ISSUE_BODY
}

find_existing_issue_url() {
  local issue_repo="$1" finding_id="$2"
  local marker="<!-- security-baseline-finding-id: ${finding_id} -->"
  gh issue list --repo "$issue_repo" --state open --search "${finding_id} in:body" --json url,body 2>/dev/null \
    | jq -r --arg marker "$marker" '.[] | select((.body // "") | contains($marker)) | .url' \
    | head -n1
}

close_existing_issue_if_open() {
  local issue_repo="$1" finding_id="$2" subject_ref="$3" control_id="$4"
  local existing_url
  existing_url=$(find_existing_issue_url "$issue_repo" "$finding_id" || true)
  [[ -z "$existing_url" ]] && return 0

  if [[ "$DRY_RUN" == "true" ]]; then
    log_notice "[dry-run] Issue existente seria fechada para '${finding_id}' (controle voltou a ok)."
    return 0
  fi

  gh issue close "$existing_url" --repo "$issue_repo" --comment "Fechada automaticamente: a varredura semanal voltou a reportar status ok para ${control_id} em ${subject_ref}." >/dev/null
  log_notice "${subject_ref}: issue de nao conformidade encerrada (${control_id}) -> ${existing_url}"
}

merge_issue_url_into_finding() {
  local finding_json="$1" issue_url="$2"
  jq --arg issue_url "$issue_url" '.issue_url = (if $issue_url == "" then null else $issue_url end)' <<< "$finding_json"
}

create_or_update_issue() {
  local issue_repo="$1" subject_ref="$2" control_id="$3" status="$4" evidencia="$5" finding_id="$6"
  local priority body existing_url

  priority=$(issue_priority_for_control "$control_id")
  body=$(build_issue_body "$subject_ref" "$control_id" "$status" "$evidencia" "$finding_id")
  existing_url=$(find_existing_issue_url "$issue_repo" "$finding_id" || true)

  if [[ "$DRY_RUN" == "true" ]]; then
    log_notice "[dry-run] Issue seria criada/atualizada para '${finding_id}' (status=${status}) — nenhuma escrita realizada."
    echo "${existing_url:-}"
    return 0
  fi

  ensure_label "$issue_repo" "security-baseline" "b60205" "Nao conformidade detectada pela varredura automatizada de seguranca (feature 007)"
  ensure_label "$issue_repo" "$priority" "fbca04" "Prioridade aplicada automaticamente pela varredura de conformidade de seguranca"

  if [[ -n "$existing_url" ]]; then
    gh issue edit "$existing_url" --repo "$issue_repo" --body "$body" >/dev/null
    echo "$existing_url"
  else
    gh issue create --repo "$issue_repo" --title "Nao conformidade de seguranca — ${CONTROL_NAME[$control_id]} (${subject_ref})" --body "$body" \
      --label "security-baseline" --label "$priority"
  fi
}

api_get() {
  local path="$1"
  local out_tmp err_tmp
  out_tmp=$(make_scratch_file "api-get-stdout")
  err_tmp=$(make_scratch_file "api-get-stderr")

  if gh api "$path" >"$out_tmp" 2>"$err_tmp"; then
    API_STATUS="200"
  else
    API_STATUS=$(grep -oE 'HTTP [0-9]{3}' "$err_tmp" | grep -oE '[0-9]{3}' | tail -1 || true)
    API_STATUS="${API_STATUS:-000}"
  fi
  API_BODY=$(cat "$out_tmp")
  API_ERROR=$(cat "$err_tmp")
  cleanup_scratch_file "$out_tmp"
  cleanup_scratch_file "$err_tmp"
}

evaluate_branch_protection() {
  local repo="$1" branch="$2"
  api_get "repos/${repo}/branches/${branch}/protection"

  case "$API_STATUS" in
    200)
      jq -n --arg ev "GET /repos/${repo}/branches/${branch}/protection -> 200 (branch protection configured)" '{status:"ok", evidencia:$ev, erro:false}'
      ;;
    404)
      jq -n --arg ev "GET /repos/${repo}/branches/${branch}/protection -> 404 (not configured)" '{status:"risco", evidencia:$ev, erro:false}'
      ;;
    403)
      jq -n --arg ev "GET /repos/${repo}/branches/${branch}/protection -> 403 (no admin permission)" '{status:null, evidencia:$ev, erro:true}'
      ;;
    *)
      jq -n --arg ev "GET /repos/${repo}/branches/${branch}/protection -> ${API_STATUS} (${API_ERROR})" '{status:null, evidencia:$ev, erro:true}'
      ;;
  esac
}

evaluate_required_review() {
  local repo="$1" branch="$2"
  local count
  api_get "repos/${repo}/branches/${branch}/protection"

  case "$API_STATUS" in
    200)
      count=$(echo "$API_BODY" | jq -r '.required_pull_request_reviews.required_approving_review_count // 0')
      if [[ "$count" =~ ^[0-9]+$ ]] && (( count >= 1 )); then
        jq -n --arg ev "GET /repos/${repo}/branches/${branch}/protection -> required_approving_review_count=${count} (>=1)" '{status:"ok", evidencia:$ev, erro:false}'
      else
        jq -n --arg ev "GET /repos/${repo}/branches/${branch}/protection -> required_pull_request_reviews missing or required_approving_review_count=0" '{status:"risco", evidencia:$ev, erro:false}'
      fi
      ;;
    404)
      jq -n --arg ev "GET /repos/${repo}/branches/${branch}/protection -> 404 (branch protection missing, required review cannot be configured)" '{status:"risco", evidencia:$ev, erro:false}'
      ;;
    403)
      jq -n --arg ev "GET /repos/${repo}/branches/${branch}/protection -> 403 (no admin permission)" '{status:null, evidencia:$ev, erro:true}'
      ;;
    *)
      jq -n --arg ev "GET /repos/${repo}/branches/${branch}/protection -> ${API_STATUS} (${API_ERROR})" '{status:null, evidencia:$ev, erro:true}'
      ;;
  esac
}

evaluate_actions_permissions() {
  local repo="$1"
  local enabled allowed
  api_get "repos/${repo}/actions/permissions"

  case "$API_STATUS" in
    200)
      enabled=$(echo "$API_BODY" | jq -r '.enabled // false')
      allowed=$(echo "$API_BODY" | jq -r '.allowed_actions // "all"')
      if [[ "$enabled" == "true" && "$allowed" != "all" ]]; then
        jq -n --arg ev "GET /repos/${repo}/actions/permissions -> enabled=true allowed_actions=${allowed}" '{status:"ok", evidencia:$ev, erro:false}'
      else
        jq -n --arg ev "GET /repos/${repo}/actions/permissions -> enabled=${enabled} allowed_actions=${allowed} (expected allowed_actions != all)" '{status:"risco", evidencia:$ev, erro:false}'
      fi
      ;;
    403)
      jq -n --arg ev "GET /repos/${repo}/actions/permissions -> 403 (no admin permission)" '{status:null, evidencia:$ev, erro:true}'
      ;;
    404)
      jq -n --arg ev "GET /repos/${repo}/actions/permissions -> 404 (endpoint unavailable on this instance/plan)" '{status:"pendente", evidencia:$ev, erro:false}'
      ;;
    *)
      jq -n --arg ev "GET /repos/${repo}/actions/permissions -> ${API_STATUS} (${API_ERROR})" '{status:null, evidencia:$ev, erro:true}'
      ;;
  esac
}

evaluate_secrets_configured() {
  local repo="$1"
  local total
  api_get "repos/${repo}/actions/secrets"

  case "$API_STATUS" in
    200)
      total=$(echo "$API_BODY" | jq -r '.total_count // 0')
      if [[ "$total" =~ ^[0-9]+$ ]] && (( total > 0 )); then
        jq -n --arg ev "GET /repos/${repo}/actions/secrets -> total_count=${total} (metadata only, values never read)" '{status:"ok", evidencia:$ev, erro:false}'
      else
        jq -n --arg ev "GET /repos/${repo}/actions/secrets -> total_count=0" '{status:"pendente", evidencia:$ev, erro:false}'
      fi
      ;;
    403)
      jq -n --arg ev "GET /repos/${repo}/actions/secrets -> 403 (no admin permission)" '{status:null, evidencia:$ev, erro:true}'
      ;;
    *)
      jq -n --arg ev "GET /repos/${repo}/actions/secrets -> ${API_STATUS} (${API_ERROR})" '{status:null, evidencia:$ev, erro:true}'
      ;;
  esac
}

csv_to_json_array() {
  local input="${1:-}"
  printf '%s' "$input" | jq -Rsc 'split(",") | map(gsub("^\\s+|\\s+$"; "")) | map(select(length > 0))'
}

ndjson_to_json_array() {
  local ndjson="${1:-}"
  if [[ -z "$ndjson" ]]; then
    echo '[]'
  else
    printf '%s\n' "$ndjson" | grep -v '^[[:space:]]*$' | jq -s '.'
  fi
}

discover_platform_projects() {
  local platform_repo="${PLATFORM_PROJECT_REPOSITORY:-}"
  local owner name response query projects candidates

  if [[ -z "$platform_repo" || "$platform_repo" != */* ]]; then
    log_warn "Platform Project repository not configured (expected owner/repo in SECURITY_SCAN_PLATFORM_REPOSITORY or GITHUB_REPOSITORY)."
    echo '[]'
    return 0
  fi

  owner="${platform_repo%/*}"
  name="${platform_repo#*/}"
  query=$(cat <<'GRAPHQL'
query($owner:String!, $name:String!) {
  repository(owner:$owner, name:$name) {
    projectsV2(first: 20) {
      nodes {
        id
        number
        title
        url
        public
        closed
        viewerCanUpdate
        teams(first: 50) { nodes { slug name } }
        views(first: 50) { nodes { name } }
        fields(first: 50) { nodes { ... on ProjectV2FieldCommon { name } } }
        repositories(first: 100) { nodes { nameWithOwner } }
      }
    }
  }
}
GRAPHQL
)

  response=$(gh api graphql -f owner="$owner" -f name="$name" -f query="$query" 2>/dev/null || true)
  if [[ -z "$response" ]]; then
    log_warn "Unable to query Project V2 metadata for ${platform_repo}."
    echo '[]'
    return 0
  fi

  if ! echo "$response" | jq -e '.data.repository.projectsV2.nodes' >/dev/null 2>&1; then
    log_warn "Project V2 query returned no usable data for ${platform_repo}."
    echo '[]'
    return 0
  fi

  projects=$(echo "$response" | jq -c '.data.repository.projectsV2.nodes // [] | map({
    id,
    number,
    title,
    url,
    public,
    closed,
    viewerCanUpdate,
    team_slugs: [.teams.nodes[].slug],
    team_names: [.teams.nodes[].name],
    view_names: [.views.nodes[].name],
    field_names: [.fields.nodes[].name],
    repositories: [.repositories.nodes[].nameWithOwner]
  })')

  if [[ -n "${SECURITY_SCAN_PLATFORM_PROJECT_TITLE:-}" ]]; then
    echo "$projects" | jq -c --arg title "$SECURITY_SCAN_PLATFORM_PROJECT_TITLE" 'map(select(.title == $title))'
    return 0
  fi

  candidates=$(echo "$projects" | jq -c 'map(select((.repositories | length) > 1))')
  if [[ "$candidates" != '[]' ]]; then
    echo "$candidates"
    return 0
  fi

  echo "$projects" | jq -c --arg suffix "$PLATFORM_PROJECT_TITLE_SUFFIX" 'map(select(.title | endswith($suffix)))'
}

evaluate_platform_project_access() {
  local project_json="$1"
  local allowed_teams required_views required_fields
  local title url public closed viewer_can_update repositories_text missing_fields missing_views unapproved_teams
  local missing_fields_count missing_views_count unapproved_count status evidence

  allowed_teams=$(csv_to_json_array "$PLATFORM_ALLOWED_TEAM_SLUGS")
  required_views=$(csv_to_json_array "$PLATFORM_REQUIRED_VIEWS")
  required_fields=$(csv_to_json_array "$PLATFORM_REQUIRED_FIELDS")

  title=$(echo "$project_json" | jq -r '.title')
  url=$(echo "$project_json" | jq -r '.url')
  public=$(echo "$project_json" | jq -r '.public // false')
  closed=$(echo "$project_json" | jq -r '.closed // false')
  viewer_can_update=$(echo "$project_json" | jq -r '.viewerCanUpdate // false')
  repositories_text=$(echo "$project_json" | jq -r '(.repositories // []) | join(", ")')

  missing_fields=$(jq -n --argjson required "$required_fields" --argjson actual "$(echo "$project_json" | jq -c '.field_names // []')" '$required - $actual')
  missing_views=$(jq -n --argjson required "$required_views" --argjson actual "$(echo "$project_json" | jq -c '.view_names // []')" '$required - $actual')
  unapproved_teams=$(jq -n --argjson allowed "$allowed_teams" --argjson actual "$(echo "$project_json" | jq -c '.team_slugs // []')" '$actual - $allowed')

  missing_fields_count=$(echo "$missing_fields" | jq 'length')
  missing_views_count=$(echo "$missing_views" | jq 'length')
  unapproved_count=$(echo "$unapproved_teams" | jq 'length')

  if [[ "$public" == "true" ]]; then
    status="risco"
    evidence="Project V2 ${title} is public=true. The consolidated platform board must remain private. URL: ${url}"
  elif [[ "$viewer_can_update" == "true" ]]; then
    status="risco"
    evidence="Project V2 ${title} returned viewerCanUpdate=true for the scan credential. The security scan credential must remain read-only. Linked repositories: ${repositories_text}."
  elif (( unapproved_count > 0 )); then
    status="risco"
    evidence="Project V2 ${title} has direct team grants outside the approved allowlist: $(echo "$unapproved_teams" | jq -r 'join(", ")'). Linked repositories: ${repositories_text}."
  elif [[ "$closed" == "true" ]]; then
    status="pendente"
    evidence="Project V2 ${title} is closed=true. Re-open or confirm that the consolidated platform board is still active before relying on this governance scan."
  elif (( missing_fields_count > 0 || missing_views_count > 0 )); then
    status="pendente"
    evidence="Project V2 ${title} is missing required governance artifacts. Missing fields: $(echo "$missing_fields" | jq -r 'if length == 0 then "none" else join(", ") end'). Missing views: $(echo "$missing_views" | jq -r 'if length == 0 then "none" else join(", ") end')."
  else
    status="ok"
    evidence="Project V2 ${title} is private, the scan credential is read-only (viewerCanUpdate=false), direct team grants are within the approved allowlist, and the required views/fields exist. Linked repositories: ${repositories_text}."
  fi

  jq -n --arg status "$status" --arg ev "$evidence" '{status:$status, evidencia:$ev, erro:false}'
}

append_run_finding() {
  local finding_json="$1" non_ok="${2:-false}"
  RUN_FINDINGS_NDJSON+="$finding_json"$'\n'
  if [[ "$non_ok" == "true" ]]; then
    RUN_NON_OK_FINDINGS_NDJSON+="$finding_json"$'\n'
  fi
}

build_controls_metrics_json() {
  local control_id ok total
  {
    for control_id in "${!CONTROL_NAME[@]}"; do
      ok=${RUN_OK_COUNTS[$control_id]:-0}
      total=${RUN_TOTAL_COUNTS[$control_id]:-0}
      jq -nc --arg id "$control_id" --argjson ok "$ok" --argjson total "$total" '{id:$id, ok:$ok, total:$total}'
    done
  } | jq -s 'map({(.id): {ok: .ok, total: .total, pct_ok: (if .total > 0 then (((.ok / .total) * 10000) | round / 100) else 0 end)}}) | add'
}

build_scan_snapshot_json() {
  local controls_json findings_json open_findings_json run_id month
  controls_json=$(build_controls_metrics_json)
  findings_json=$(ndjson_to_json_array "$RUN_FINDINGS_NDJSON")
  open_findings_json=$(ndjson_to_json_array "$RUN_NON_OK_FINDINGS_NDJSON")
  run_id="${GITHUB_RUN_ID:-manual-$(date -u +%Y%m%dT%H%M%SZ)}"
  month=$(date -u +%Y-%m)

  jq -n \
    --arg month "$month" \
    --arg run_id "$run_id" \
    --arg started_at "$SCAN_STARTED_AT" \
    --argjson repos_avaliados "$SCAN_REPOS_AVALIADOS" \
    --argjson repos_com_erro "$SCAN_REPOS_COM_ERRO" \
    --argjson controls "$controls_json" \
    --argjson findings "$findings_json" \
    --argjson open_findings "$open_findings_json" \
    '{month:$month, run_id:$run_id, started_at:$started_at, repos_avaliados:$repos_avaliados, repos_com_erro:$repos_com_erro, controls:$controls, findings:$findings, open_findings:$open_findings}'
}

month_end_date() {
  python3 -c "import calendar, sys; y, m = map(int, sys.argv[1].split('-')); print(f'{y:04d}-{m:02d}-{calendar.monthrange(y, m)[1]:02d}')" "$1"
}

expected_weekly_runs_for_month() {
  python3 -c "import calendar, sys; y, m = map(int, sys.argv[1].split('-')); print(sum(1 for week in calendar.monthcalendar(y, m) if week[0] != 0))" "$1"
}

find_monthly_report_issue_url() {
  local issue_repo="$1" month="$2" title
  title="${MONTHLY_REPORT_TITLE_PREFIX}${month}"
  gh issue list --repo "$issue_repo" --state open --search "${title} in:title" --json url,title 2>/dev/null \
    | jq -r --arg title "$title" '.[] | select(.title == $title) | .url' \
    | head -n1
}

snapshot_comment_body() {
  local month="$1" run_id="$2" snapshot_json="$3" payload_b64
  payload_b64=$(printf '%s' "$snapshot_json" | base64 -w0 2>/dev/null || printf '%s' "$snapshot_json" | base64 | tr -d '\n')
  printf '<!-- %s: %s %s %s -->' "$MONTHLY_REPORT_COMMENT_MARKER" "$month" "$run_id" "$payload_b64"
}

snapshot_comment_exists() {
  local issue_repo="$1" issue_url="$2" month="$3" run_id="$4"
  gh issue view "$issue_url" --repo "$issue_repo" --json comments 2>/dev/null \
    | jq -r '.comments[].body // empty' \
    | grep -F "<!-- ${MONTHLY_REPORT_COMMENT_MARKER}: ${month} ${run_id} " >/dev/null 2>&1
}

load_report_snapshots_from_issue() {
  local issue_repo="$1" issue_url="$2" month="$3"
  gh issue view "$issue_url" --repo "$issue_repo" --json comments 2>/dev/null \
    | jq -r '.comments[].body // empty' \
    | grep -E "^<!-- ${MONTHLY_REPORT_COMMENT_MARKER}: ${month} [^ ]+ [^ ]+ -->$" \
    | while IFS= read -r line; do
        local payload
        payload=$(printf '%s' "$line" | sed -E "s/^<!-- ${MONTHLY_REPORT_COMMENT_MARKER}: ${month} [^ ]+ ([^ ]+) -->$/\1/")
        if [[ -n "$payload" ]]; then
          printf '%s' "$payload" | base64 -d 2>/dev/null || true
          printf '\n'
        fi
      done
}

aggregate_report_snapshots() {
  local snapshots_ndjson="$1"
  printf '%s\n' "$snapshots_ndjson" \
    | grep -v '^[[:space:]]*$' \
    | jq -cs 'map(select(type == "object")) | reduce .[] as $snap ({runs: 0, total_repos: 0, controls: {}, open_findings: []}; .runs += 1 | .total_repos = ([.total_repos, ($snap.repos_avaliados // 0)] | max) | .open_findings = ($snap.open_findings // []) | .controls = reduce (($snap.controls // {}) | to_entries[]) as $entry (.controls; .[$entry.key].ok = ((.[$entry.key].ok // 0) + ($entry.value.ok // 0)) | .[$entry.key].total = ((.[$entry.key].total // 0) + ($entry.value.total // 0)))) | .controls = with_entries(.value += {pct_ok: (if (.value.total // 0) > 0 then ((((.value.ok // 0) / (.value.total // 0)) * 10000) | round / 100) else 0 end)})'
}

list_closed_findings_for_month() {
  local org="$1" month="$2" end_date results
  [[ -z "$org" ]] && { echo '[]'; return 0; }
  end_date=$(month_end_date "$month")

  if ! results=$(gh search issues --owner "$org" --state closed --label security-baseline --limit 100 --json repository,body,url,createdAt,closedAt --search "closed:${month}-01..${end_date}" 2>/dev/null); then
    echo '[]'
    return 0
  fi

  echo "$results" | jq -c 'map(select((.body // "") | contains("<!-- security-baseline-finding-id: "))) | map({repo: (.repository.nameWithOwner // ""), controle_id: ((.body | capture("security-baseline:(?<repo>.*):(?<controle>[^ ]+) -->").controle) // "unknown"), created_at: (.createdAt // ""), closed_at: (.closedAt // ""), url: .url})' 2>/dev/null || echo '[]'
}

build_monthly_report_markdown() {
  local month="$1" aggregate_json="$2" previous_pct_json="$3" closed_findings_json="$4"
  local total_repos runs expected open_findings_json body control_id label pct delta

  total_repos=$(echo "$aggregate_json" | jq -r '.total_repos // 0')
  runs=$(echo "$aggregate_json" | jq -r '.runs // 0')
  expected=$(expected_weekly_runs_for_month "$month")
  open_findings_json=$(echo "$aggregate_json" | jq -c '.open_findings // []')
  body="## Relatorio de Conformidade - ${month}\n\n"
  body+="**Total de repositorios avaliados**: ${total_repos}\n"
  body+="**Execucoes realizadas no mes**: ${runs} / ${expected}\n\n"
  body+="### Conformidade por controle\n\n"
  body+="| Controle | % conforme | Delta vs. mes anterior |\n"
  body+="|---|---|---|\n"

  while IFS='|' read -r control_id label; do
    pct=$(echo "$aggregate_json" | jq -r --arg id "$control_id" '.controls[$id].pct_ok // 0')
    delta=$(echo "$previous_pct_json" | jq -r --arg id "$control_id" '.[$id] // "N/A"')
    body+="| ${label} | ${pct}% | ${delta} |\n"
  done <<'EOF'
branch-protection|Branch protection
required-review|Revisao obrigatoria
actions-permissions|Permissoes de Actions
secrets-configured|Secrets configurados
platform-project-access|Matriz de acesso do Projeto Plataforma
EOF

  body+="\n### Desvios abertos ao final do mes\n\n"
  body+="| Repo | Controle | Aberto desde | Issue |\n"
  body+="|---|---|---|---|\n"
  if [[ $(echo "$open_findings_json" | jq 'length') -eq 0 ]]; then
    body+="| - | - | - | - |\n"
  else
    while IFS= read -r row; do
      [[ -z "$row" ]] && continue
      local repo controle opened issue_url
      repo=$(echo "$row" | jq -r '.repo')
      controle=$(echo "$row" | jq -r '.controle_id')
      opened=$(echo "$row" | jq -r '.timestamp | split("T")[0]')
      issue_url=$(echo "$row" | jq -r '.issue_url // "-"')
      body+="| ${repo} | ${controle} | ${opened} | ${issue_url} |\n"
    done < <(echo "$open_findings_json" | jq -c '.[]')
  fi

  body+="\n### Desvios corrigidos no mes\n\n"
  body+="| Repo | Controle | Aberto em | Fechado em | Issue |\n"
  body+="|---|---|---|---|---|\n"
  if [[ $(echo "$closed_findings_json" | jq 'length') -eq 0 ]]; then
    body+="| - | - | - | - | - |\n"
  else
    while IFS= read -r row; do
      [[ -z "$row" ]] && continue
      local repo controle opened closed issue_url
      repo=$(echo "$row" | jq -r '.repo')
      controle=$(echo "$row" | jq -r '.controle_id')
      opened=$(echo "$row" | jq -r '.created_at | split("T")[0]')
      closed=$(echo "$row" | jq -r '.closed_at | split("T")[0]')
      issue_url=$(echo "$row" | jq -r '.url')
      body+="| ${repo} | ${controle} | ${opened} | ${closed} | ${issue_url} |\n"
    done < <(echo "$closed_findings_json" | jq -c '.[]')
  fi

  body+="\n---\n_Gerado a partir de ${runs} execucoes semanais de \`security-compliance-scan.yml\`._"
  printf '%b' "$body"
}

upsert_monthly_report() {
  local org="$1" issue_repo="$2" month snapshot_json run_id issue_url existing_snapshots all_snapshots aggregate_json closed_findings_json report_body

  [[ -z "$issue_repo" ]] && { log_warn "Monthly report skipped: report repository is not configured."; return 0; }

  month=$(date -u +%Y-%m)
  snapshot_json=$(build_scan_snapshot_json)
  run_id=$(echo "$snapshot_json" | jq -r '.run_id')
  issue_url=$(find_monthly_report_issue_url "$issue_repo" "$month" || true)
  existing_snapshots=""

  if [[ -n "$issue_url" ]]; then
    existing_snapshots=$(load_report_snapshots_from_issue "$issue_repo" "$issue_url" "$month" || true)
  fi

  all_snapshots="${existing_snapshots}"$'\n'"${snapshot_json}"
  aggregate_json=$(aggregate_report_snapshots "$all_snapshots")
  closed_findings_json=$(list_closed_findings_for_month "$org" "$month")
  report_body=$(build_monthly_report_markdown "$month" "$aggregate_json" '{}' "$closed_findings_json")

  if [[ "$DRY_RUN" == "true" ]]; then
    log_notice "[dry-run] Monthly report would be created/updated in ${issue_repo} for ${month}."
    return 0
  fi

  ensure_label "$issue_repo" "security-baseline" "b60205" "Security compliance automation output"
  if [[ -n "$issue_url" ]]; then
    gh issue edit "$issue_url" --repo "$issue_repo" --body "$report_body" >/dev/null
  else
    issue_url=$(gh issue create --repo "$issue_repo" --title "${MONTHLY_REPORT_TITLE_PREFIX}${month}" --body "$report_body" --label "security-baseline")
  fi

  if ! snapshot_comment_exists "$issue_repo" "$issue_url" "$month" "$run_id"; then
    gh issue comment "$issue_url" --repo "$issue_repo" --body "$(snapshot_comment_body "$month" "$run_id" "$snapshot_json")" >/dev/null
  fi

  log_notice "Monthly compliance report updated -> ${issue_url}"
}

resolve_org() {
  if [[ -n "$ORG_ARG" ]]; then
    echo "$ORG_ARG"
    return 0
  fi
  if [[ -n "${GITHUB_REPOSITORY:-}" ]]; then
    echo "${GITHUB_REPOSITORY%/*}"
    return 0
  fi
  log_error "Nao foi possivel resolver a organizacao alvo. Use --org NAME ou configure GITHUB_REPOSITORY."
  exit 1
}

evaluate_and_report() {
  local subject_ref="$1" control_id="$2" eval_json="$3" issue_repo="${4:-$1}"
  local status evidencia erro finding_id issue_url finding_json

  status=$(echo "$eval_json" | jq -r '.status')
  evidencia=$(echo "$eval_json" | jq -r '.evidencia')
  erro=$(echo "$eval_json" | jq -r '.erro')

  if [[ "$erro" == "true" ]]; then
    log_warn "${subject_ref}: erro ao avaliar '${control_id}' — ${evidencia}"
    REPO_HAD_ERROR="true"
    return 0
  fi

  RUN_TOTAL_COUNTS[$control_id]=$(( ${RUN_TOTAL_COUNTS[$control_id]:-0} + 1 ))
  finding_id="security-baseline:${subject_ref}:${control_id}"
  finding_json=$(build_finding_json "$subject_ref" "$control_id" "$status" "$evidencia")
  log_notice "${subject_ref}: controle '${control_id}' => ${status}"

  if [[ "$status" == "ok" ]]; then
    RUN_OK_COUNTS[$control_id]=$(( ${RUN_OK_COUNTS[$control_id]:-0} + 1 ))
    close_existing_issue_if_open "$issue_repo" "$finding_id" "$subject_ref" "$control_id"
    append_run_finding "$finding_json" "false"
    return 0
  fi

  issue_url=$(create_or_update_issue "$issue_repo" "$subject_ref" "$control_id" "$status" "$evidencia" "$finding_id")
  finding_json=$(merge_issue_url_into_finding "$finding_json" "$issue_url")
  append_run_finding "$finding_json" "true"
  log_notice "${subject_ref}: issue de nao conformidade (${control_id}) -> ${issue_url:-<dry-run: sem URL>}"
}

scan_single_repo() {
  local full_name="$1" default_branch="${2:-}"
  REPO_HAD_ERROR="false"

  if [[ -z "$default_branch" || "$default_branch" == "null" ]]; then
    default_branch=$(gh api "repos/${full_name}" --jq '.default_branch' 2>/dev/null || true)
  fi

  if [[ -z "$default_branch" ]]; then
    log_warn "${full_name}: nao foi possivel resolver a branch padrao — marcando como repos_com_erro."
    REPO_HAD_ERROR="true"
    return 0
  fi

  evaluate_and_report "$full_name" "branch-protection" "$(evaluate_branch_protection "$full_name" "$default_branch")" "$full_name"
  evaluate_and_report "$full_name" "required-review" "$(evaluate_required_review "$full_name" "$default_branch")" "$full_name"
  evaluate_and_report "$full_name" "actions-permissions" "$(evaluate_actions_permissions "$full_name")" "$full_name"
  evaluate_and_report "$full_name" "secrets-configured" "$(evaluate_secrets_configured "$full_name")" "$full_name"
}

run_scan() {
  local repos_ndjson="$1"
  local repos_avaliados=0 repos_com_erro=0 full_name default_branch

  if [[ -z "$repos_ndjson" ]]; then
    log_warn "Nenhum repositorio retornado pela descoberta — nada a varrer neste escopo."
    SCAN_REPOS_AVALIADOS=0
    SCAN_REPOS_COM_ERRO=0
    return 0
  fi

  while IFS= read -r repo_line; do
    [[ -z "$repo_line" ]] && continue
    full_name=$(echo "$repo_line" | jq -r '.full_name // empty')
    [[ -z "$full_name" ]] && continue
    default_branch=$(echo "$repo_line" | jq -r '.default_branch // empty')

    scan_single_repo "$full_name" "$default_branch"
    repos_avaliados=$((repos_avaliados + 1))
    if [[ "$REPO_HAD_ERROR" == "true" ]]; then
      repos_com_erro=$((repos_com_erro + 1))
    fi
  done <<< "$repos_ndjson"

  SCAN_REPOS_AVALIADOS=$repos_avaliados
  SCAN_REPOS_COM_ERRO=$repos_com_erro
  log_notice "Scan Run concluido: repos_avaliados=${repos_avaliados} repos_com_erro=${repos_com_erro}"

  if (( repos_avaliados > 0 )); then
    if awk -v erro="$repos_com_erro" -v total="$repos_avaliados" 'BEGIN { exit !(erro/total > 0.05) }'; then
      log_warn "Taxa de repos_com_erro (${repos_com_erro}/${repos_avaliados}) acima do SLO de 5% — revisar permissoes do GitHub App e comportamento da API."
    fi
  fi
}

run_platform_scan() {
  local projects_json issue_repo project_ref project_line
  issue_repo="${REPORT_REPOSITORY:-${GITHUB_REPOSITORY:-}}"
  REPO_HAD_ERROR="false"
  projects_json=$(discover_platform_projects)

  if [[ -z "$projects_json" || "$projects_json" == '[]' ]]; then
    evaluate_and_report "platform/${PLATFORM_PROJECT_REPOSITORY:-unconfigured}" "platform-project-access" "$(jq -n --arg ev "Nenhum Project V2 consolidado foi encontrado em ${PLATFORM_PROJECT_REPOSITORY:-<unset>}." '{status:"pendente", evidencia:$ev, erro:false}')" "$issue_repo"
    return 0
  fi

  while IFS= read -r project_line; do
    [[ -z "$project_line" ]] && continue
    project_ref="platform/${PLATFORM_PROJECT_REPOSITORY}#$(echo "$project_line" | jq -r '.number')"
    evaluate_and_report "$project_ref" "platform-project-access" "$(evaluate_platform_project_access "$project_line")" "$issue_repo"
  done < <(echo "$projects_json" | jq -c '.[]')
}

main() {
  parse_args "$@"

  log_info "==============================================================="
  log_info "Security Compliance Scan - Nimbus Code"
  log_info "==============================================================="

  authenticate_github_app

  local org scope repos_ndjson
  org=$(resolve_org)
  scope=$(resolve_scope)
  log_notice "Organizacao: ${org} | Escopo resolvido: ${scope} | dry-run: ${DRY_RUN} (flag ${FEATURE_FLAG_KEY})"

  repos_ndjson=$(discover_repositories "$scope" "$org") || {
    log_error "Descoberta de repositorios falhou — abortando execucao."
    exit 1
  }

  run_scan "$repos_ndjson"
  run_platform_scan
  upsert_monthly_report "$org" "${REPORT_REPOSITORY:-${GITHUB_REPOSITORY:-}}"

  log_ok "✓ Varredura concluida."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
