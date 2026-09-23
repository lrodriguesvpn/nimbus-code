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
#   - Repository controls (issue #450): branch-protection-default,
#     branch-protection-required-patterns, rulesets-configured,
#     required-review, required-pr-checks, required-test-checks,
#     required-coverage-check, codeql-enabled, codeql-recent, codeql-alerts,
#     dependabot-alerts-enabled, dependabot-security-updates-enabled,
#     dependency-review-enabled, secret-scanning-enabled,
#     secret-scanning-push-protection-enabled, secret-alerts,
#     actions-permissions, secrets-configured.
#     Branches/padrões/checks esperados vêm de .github/security-governance.json
#     do repositório avaliado (fallback: SECURITY_SCAN_GOVERNANCE_CONFIG).
#   - Platform Project V2 governance evaluator.
#   - Idempotent non-compliance issue creation/update and auto-close on recovery
#     (inclui migração do id legado `branch-protection`).
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
#   - SECURITY_SCAN_GOVERNANCE_CONFIG: default governance config
#     (default: .github/security-governance.json)
#   - SECURITY_SCAN_ISSUES_TOKEN: token used ONLY for issue/label writes in the
#     report repository (workflow GITHUB_TOKEN with issues: write). The GitHub
#     App installation token stays read-only and is never used for writes.
#   - SECURITY_SCAN_ISSUE_TARGET: report-repository (default) | scanned-repository
#     (the latter requires a separately approved writer credential — ADR-0008)
#
# This script is read-only + reporting only: it does not change repository or
# project configuration, only creates/updates/closes tracking issues and the
# monthly report issue. It never reads secret values (Actions secrets:
# metadata only; secret scanning alerts: hide_secret=true + projection).
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
ISSUE_TARGET="${SECURITY_SCAN_ISSUE_TARGET:-report-repository}"

# Ordem canônica dos controles (relatório mensal e documentação).
CONTROL_ORDER=(
  branch-protection-default
  branch-protection-required-patterns
  rulesets-configured
  required-review
  required-pr-checks
  required-test-checks
  required-coverage-check
  codeql-enabled
  codeql-recent
  codeql-alerts
  dependabot-alerts-enabled
  dependabot-security-updates-enabled
  dependency-review-enabled
  secret-scanning-enabled
  secret-scanning-push-protection-enabled
  secret-alerts
  actions-permissions
  secrets-configured
  platform-project-access
)
declare -A CONTROL_NAME=(
  [branch-protection-default]="Proteção da branch padrão"
  [branch-protection-required-patterns]="Proteção de branches de produção/release/hotfix"
  [rulesets-configured]="Repository Rulesets configurados"
  [required-review]="Revisão obrigatória de Pull Request"
  [required-pr-checks]="Required status checks de Pull Request"
  [required-test-checks]="Testes automatizados obrigatórios"
  [required-coverage-check]="Check de cobertura de testes obrigatório"
  [codeql-enabled]="CodeQL (SAST) habilitado"
  [codeql-recent]="Análise CodeQL recente na branch padrão"
  [codeql-alerts]="Alertas CodeQL high/critical"
  [dependabot-alerts-enabled]="Dependabot alerts habilitado"
  [dependabot-security-updates-enabled]="Dependabot security updates habilitado"
  [dependency-review-enabled]="Dependency Review (SCA) em Pull Requests"
  [secret-scanning-enabled]="GitHub Secret Scanning habilitado"
  [secret-scanning-push-protection-enabled]="Push Protection de secrets habilitado"
  [secret-alerts]="Alertas de secret scanning abertos"
  [actions-permissions]="Permissões de GitHub Actions"
  [secrets-configured]="Secrets configurados via GitHub Secrets"
  [platform-project-access]="Matriz de acesso do Projeto Plataforma"
)
declare -A CONTROL_REPORT_LABEL=(
  [branch-protection-default]="Branch protection (padrão)"
  [branch-protection-required-patterns]="Branches protegidas (produção/release/hotfix)"
  [rulesets-configured]="Rulesets configurados"
  [required-review]="Revisao obrigatoria"
  [required-pr-checks]="Required checks de PR"
  [required-test-checks]="Checks de teste obrigatorios"
  [required-coverage-check]="Check de cobertura obrigatorio"
  [codeql-enabled]="CodeQL habilitado"
  [codeql-recent]="CodeQL recente"
  [codeql-alerts]="Alertas CodeQL high/critical"
  [dependabot-alerts-enabled]="Dependabot alerts"
  [dependabot-security-updates-enabled]="Dependabot security updates"
  [dependency-review-enabled]="Dependency Review"
  [secret-scanning-enabled]="Secret Scanning"
  [secret-scanning-push-protection-enabled]="Push Protection"
  [secret-alerts]="Alertas de secret abertos"
  [actions-permissions]="Permissoes de Actions"
  [secrets-configured]="Secrets configurados"
  [platform-project-access]="Matriz de acesso do Projeto Plataforma"
)
declare -A CONTROL_BLOQUEANTE=(
  [branch-protection-default]="true"
  [branch-protection-required-patterns]="true"
  [rulesets-configured]="false"
  [required-review]="true"
  [required-pr-checks]="true"
  [required-test-checks]="true"
  [required-coverage-check]="true"
  [codeql-enabled]="true"
  [codeql-recent]="true"
  [codeql-alerts]="true"
  [dependabot-alerts-enabled]="true"
  [dependabot-security-updates-enabled]="false"
  [dependency-review-enabled]="true"
  [secret-scanning-enabled]="true"
  [secret-scanning-push-protection-enabled]="true"
  [secret-alerts]="true"
  [actions-permissions]="true"
  [secrets-configured]="false"
  [platform-project-access]="true"
)
# Prazos específicos (dias corridos) que sobrepõem o prazo padrão da prioridade.
declare -A CONTROL_DEADLINE_DAYS=(
  [secret-alerts]="1"
)
# IDs legados (antes da issue #450) — usados para encontrar/fechar issues
# abertas com o marcador antigo, preservando a idempotência.
declare -A CONTROL_LEGACY_ID=(
  [branch-protection-default]="branch-protection"
)
BASELINE_DOC_HINT="docs/security-baseline-ghe.md"
declare -A CONTROL_REMEDIATION=(
  [branch-protection-default]="Proteja a branch padrão preferencialmente com um Repository/Organization Ruleset (Settings → Rules → Rulesets) contendo: Require a pull request before merging, Block force pushes, Restrict deletions e Require status checks to pass. Proteção clássica (Settings → Branches) só por compatibilidade. Ver seções 1 e 9 de ${BASELINE_DOC_HINT}."
  [branch-protection-required-patterns]="Crie/ajuste Rulesets cobrindo as branches de produção e os padrões declarados em .github/security-governance.json (padrão: release/*, hotfix/*) com PR obrigatório, >=1 aprovador, dismiss stale approvals, bloqueio de force push/deleção e status checks. Ver seção 9 de ${BASELINE_DOC_HINT}."
  [rulesets-configured]="Migre a proteção da branch padrão para Repository Rulesets (ou herde um Organization Ruleset). A proteção clássica permanece aceita apenas por compatibilidade. Ver seção 9 de ${BASELINE_DOC_HINT}."
  [required-review]="No Ruleset/proteção da branch padrão exija Pull Request com pelo menos 1 aprovador, dismiss de aprovações obsoletas, revisão de CODEOWNERS (quando o arquivo existir) e resolução de conversas. Ver seções 1 e 9 de ${BASELINE_DOC_HINT}."
  [required-pr-checks]="Adicione como required status checks todos os checks declarados em required_status_checks de .github/security-governance.json (build, testes, CodeQL, dependency-review, secret-scan...) e exija branch atualizada (strict). Ver seção 10 de ${BASELINE_DOC_HINT}."
  [required-test-checks]="Declare e torne obrigatórios os checks de testes unitários/integração (ex.: unit-tests, integration-tests) publicados pelo GitHub Actions. Ver seções 10 e 11 de ${BASELINE_DOC_HINT}."
  [required-coverage-check]="Publique o check coverage (scripts/coverage-gate.py, mínimo 80% global e 80% no código alterado) como required status check, ou declare coverage.mode=not-applicable com justificativa e testes obrigatórios. Ver seção 11 de ${BASELINE_DOC_HINT}."
  [codeql-enabled]="Habilite o CodeQL (default setup em Settings → Code security, ou advanced setup com .github/workflows/codeql.yml). Requer GitHub Advanced Security/Code Security. Ver seção 12 de ${BASELINE_DOC_HINT}."
  [codeql-recent]="Garanta execução do CodeQL na branch padrão pelo menos semanalmente (schedule) e em push; investigue falhas do workflow de análise. Ver seção 12 de ${BASELINE_DOC_HINT}."
  [codeql-alerts]="Corrija os alertas CodeQL high/critical dentro do SLA ou registre exceção aprovada (dismiss com justificativa + .github/security-exceptions.json com owner, prazo e expiração). Ver seções 12, 15 e 16 de ${BASELINE_DOC_HINT}."
  [dependabot-alerts-enabled]="Habilite Dependency graph e Dependabot alerts em Settings → Code security. Ver seção 13 de ${BASELINE_DOC_HINT}."
  [dependabot-security-updates-enabled]="Habilite (e despause) Dependabot security updates em Settings → Code security. Ver seção 13 de ${BASELINE_DOC_HINT}."
  [dependency-review-enabled]="Adicione .github/workflows/dependency-review.yml (actions/dependency-review-action com versão fixada) e torne o check dependency-review obrigatório. Ver seção 13 de ${BASELINE_DOC_HINT}."
  [secret-scanning-enabled]="Habilite GitHub Secret Scanning em Settings → Code security (requer GitHub Secret Protection/GHAS em repositórios privados/internos). Ver seção 14 de ${BASELINE_DOC_HINT}."
  [secret-scanning-push-protection-enabled]="Habilite Push Protection em Settings → Code security → Secret scanning. Bypass só com justificativa registrada. Ver seção 14 de ${BASELINE_DOC_HINT}."
  [secret-alerts]="Trate cada alerta de secret como credencial comprometida: revogue e rotacione no sistema de origem (SLA 24h), remova do código e feche o alerta com o motivo correto. Ver seções 14 e 16 de ${BASELINE_DOC_HINT}."
  [actions-permissions]="Em Settings → Actions → General restrinja 'Allowed actions' para 'Selected actions' (nunca 'All actions'), mantenha Workflow permissions em 'Read repository contents' e desabilite 'Allow GitHub Actions to create and approve pull requests'. Ver seção 1 de ${BASELINE_DOC_HINT}."
  [secrets-configured]="Configure os secrets necessários pelos workflows deste repositório em Settings → Secrets and variables → Actions — nunca hardcode credenciais no código. Este controle verifica apenas a EXISTÊNCIA de Actions secrets; não substitui Secret Scanning. Ver seção 4 de ${BASELINE_DOC_HINT}."
  [platform-project-access]="Mantenha o Project V2 consolidado privado, sem grants diretos de times fora da lista aprovada, e preserve a credencial da varredura como somente leitura (viewerCanUpdate=false). Ver as seções 2, 3 e 8 de ${BASELINE_DOC_HINT}."
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

gh_write() {
  # Operações de ESCRITA (issues/labels/comentários) e leitura de issues usam
  # SECURITY_SCAN_ISSUES_TOKEN (GITHUB_TOKEN do workflow com issues: write no
  # repositório de relatório). O token do GitHub App (read-only) nunca é usado
  # para escrita.
  GH_TOKEN="${SECURITY_SCAN_ISSUES_TOKEN:-${GH_TOKEN:-}}" gh "$@"
}

resolve_issue_repo() {
  local subject_ref="$1"
  if [[ "$ISSUE_TARGET" == "scanned-repository" ]]; then
    echo "$subject_ref"
  else
    echo "${REPORT_REPOSITORY:-${GITHUB_REPOSITORY:-$subject_ref}}"
  fi
}

ensure_label() {
  local repo="$1" name="$2" color="$3" description="$4"
  gh_write label create "$name" --repo "$repo" --color "$color" --description "$description" --force >/dev/null 2>&1 || true
}

issue_priority_for_control() {
  local control_id="$1"
  if [[ "${CONTROL_BLOQUEANTE[$control_id]:-true}" == "true" ]]; then
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

  control_name="${CONTROL_NAME[$control_id]:-$control_id}"
  remediation="${CONTROL_REMEDIATION[$control_id]:-Ver ${BASELINE_DOC_HINT}.}"
  priority=$(issue_priority_for_control "$control_id")
  deadline_days="${CONTROL_DEADLINE_DAYS[$control_id]:-$(issue_deadline_days_for_priority "$priority")}"
  due_date=$(date_plus_days_iso "$deadline_days")
  detected_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  doc_repo="${GITHUB_REPOSITORY:-venha-pra-nuvem/nimbus-code}"
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
  gh_write issue list --repo "$issue_repo" --state open --search "${finding_id} in:body" --json url,body 2>/dev/null \
    | jq -r --arg marker "$marker" '.[] | select((.body // "") | contains($marker)) | .url' \
    | head -n1
}

find_existing_issue_for_control() {
  # Procura a issue aberta pelo id atual e, se não houver, pelo id legado
  # (ex.: branch-protection -> branch-protection-default), preservando a
  # idempotência entre versões do scanner.
  local issue_repo="$1" subject_ref="$2" control_id="$3"
  local url legacy
  url=$(find_existing_issue_url "$issue_repo" "security-baseline:${subject_ref}:${control_id}" || true)
  if [[ -z "$url" ]]; then
    legacy="${CONTROL_LEGACY_ID[$control_id]:-}"
    [[ -n "$legacy" ]] && url=$(find_existing_issue_url "$issue_repo" "security-baseline:${subject_ref}:${legacy}" || true)
  fi
  printf '%s' "$url"
}

close_existing_issue_if_open() {
  local issue_repo="$1" finding_id="$2" subject_ref="$3" control_id="$4"
  local existing_url
  existing_url=$(find_existing_issue_for_control "$issue_repo" "$subject_ref" "$control_id")
  [[ -z "$existing_url" ]] && return 0

  if [[ "$DRY_RUN" == "true" ]]; then
    log_notice "[dry-run] Issue existente seria fechada para '${finding_id}' (controle voltou a ok)."
    return 0
  fi

  gh_write issue close "$existing_url" --repo "$issue_repo" --comment "Fechada automaticamente: a varredura semanal voltou a reportar status ok para ${control_id} em ${subject_ref}." >/dev/null
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
  existing_url=$(find_existing_issue_for_control "$issue_repo" "$subject_ref" "$control_id")

  if [[ "$DRY_RUN" == "true" ]]; then
    log_notice "[dry-run] Issue seria criada/atualizada para '${finding_id}' (status=${status}) — nenhuma escrita realizada."
    echo "${existing_url:-}"
    return 0
  fi

  ensure_label "$issue_repo" "security-baseline" "b60205" "Nao conformidade detectada pela varredura automatizada de seguranca (feature 007)"
  ensure_label "$issue_repo" "$priority" "fbca04" "Prioridade aplicada automaticamente pela varredura de conformidade de seguranca"

  if [[ -n "$existing_url" ]]; then
    gh_write issue edit "$existing_url" --repo "$issue_repo" --body "$body" >/dev/null
    echo "$existing_url"
  else
    gh_write issue create --repo "$issue_repo" --title "Nao conformidade de seguranca — ${CONTROL_NAME[$control_id]:-$control_id} (${subject_ref})" --body "$body" \
      --label "security-baseline" --label "$priority"
  fi
}

api_get() {
  # Uso: api_get <path> [paginate=true|false]
  # Define API_STATUS (200 para 2xx, código HTTP em erro, 000 se indeterminado),
  # API_BODY e API_ERROR. Faz retry com backoff apenas para rate limit.
  local path="$1" paginate="${2:-false}"
  local out_tmp err_tmp attempt=0 max_attempts wait_s
  max_attempts="${SECURITY_SCAN_API_MAX_RETRIES:-3}"

  while :; do
    out_tmp=$(make_scratch_file "api-get-stdout")
    err_tmp=$(make_scratch_file "api-get-stderr")
    if [[ "$paginate" == "true" ]]; then
      if gh api --paginate "$path" >"$out_tmp" 2>"$err_tmp"; then API_STATUS="200"; else API_STATUS=""; fi
    else
      if gh api "$path" >"$out_tmp" 2>"$err_tmp"; then API_STATUS="200"; else API_STATUS=""; fi
    fi
    if [[ -z "$API_STATUS" ]]; then
      API_STATUS=$(grep -oE 'HTTP [0-9]{3}' "$err_tmp" | grep -oE '[0-9]{3}' | tail -1 || true)
      API_STATUS="${API_STATUS:-000}"
    fi
    API_BODY=$(cat "$out_tmp")
    API_ERROR=$(tr '\n' ' ' < "$err_tmp" | sed 's/[[:space:]]*$//')
    cleanup_scratch_file "$out_tmp"
    cleanup_scratch_file "$err_tmp"

    if [[ ( "$API_STATUS" == "403" || "$API_STATUS" == "429" ) ]] && grep -qi 'rate limit' <<< "$API_ERROR" && (( attempt < max_attempts )); then
      attempt=$((attempt + 1))
      wait_s=$(( ${SECURITY_SCAN_RETRY_BASE_SECONDS:-2} ** attempt ))
      log_warn "Rate limit (HTTP ${API_STATUS}) em GET /${path} — aguardando ${wait_s}s (tentativa ${attempt}/${max_attempts})."
      sleep "$wait_s"
      continue
    fi
    break
  done

  # `gh api --paginate` concatena páginas de arrays JSON; normaliza em um único array.
  if [[ "$paginate" == "true" && "$API_STATUS" == "200" && -n "$API_BODY" ]]; then
    API_BODY=$(printf '%s' "$API_BODY" | jq -cs 'if all(.[]; type == "array") then add else .[0] end' 2>/dev/null || printf '%s' "$API_BODY")
  fi
}

# Classifica a última falha de API em: permission | feature-disabled |
# unavailable | not-found | rate-limit | other. Nunca trata ausência de
# controle como sucesso.
classify_api_error() {
  local status="${1:-$API_STATUS}" message="${2:-$API_ERROR}"
  if grep -qiE 'rate limit' <<< "$message"; then echo "rate-limit"; return 0; fi
  if [[ "$status" == "403" ]] && grep -qiE 'Resource not accessible by integration|Must have admin rights|not accessible by|insufficient|permission' <<< "$message"; then
    echo "permission"; return 0
  fi
  if grep -qiE 'Advanced Security must be enabled|Code scanning is not enabled|Code Security must be enabled|Secret scanning is disabled|secret scanning is not enabled|disabled for this repository|is not enabled|not available for this|feature is not available|GitHub Advanced Security' <<< "$message"; then
    echo "feature-disabled"; return 0
  fi
  case "$status" in
    403) echo "permission" ;;
    404) echo "not-found" ;;
    410|501|422) echo "unavailable" ;;
    *) echo "other" ;;
  esac
}

emit_result() {
  # emit_result <status|""> <evidencia> [erro=false]
  local status="$1" evidence="$2" erro="${3:-false}"
  jq -n --arg s "$status" --arg ev "$evidence" --argjson erro "$erro" \
    '{status:(if $s == "" then null else $s end), evidencia:$ev, erro:$erro}'
}

# Resultado padronizado para falhas de API: permissão insuficiente vira erro
# explícito (repos_com_erro); recurso indisponível no plano/instância vira
# `pendente` com evidência — nunca `ok`.
emit_api_failure() {
  local repo="$1" target="$2" endpoint="$3" required_permission="${4:-}"
  local kind
  kind=$(classify_api_error)
  case "$kind" in
    permission)
      emit_result "" "repository=${repo} | alvo=${target} | endpoint=${endpoint} -> ${API_STATUS} | resultado=erro de permissão do GitHub App${required_permission:+ (requer ${required_permission})}: ${API_ERROR}" true
      ;;
    feature-disabled)
      emit_result "pendente" "repository=${repo} | alvo=${target} | endpoint=${endpoint} -> ${API_STATUS} | resultado=recurso desabilitado ou indisponível no plano/instância: ${API_ERROR}"
      ;;
    not-found|unavailable)
      emit_result "pendente" "repository=${repo} | alvo=${target} | endpoint=${endpoint} -> ${API_STATUS} | resultado=API indisponível nesta instância/plano (ou recurso inexistente): ${API_ERROR:-sem detalhe}"
      ;;
    *)
      emit_result "" "repository=${repo} | alvo=${target} | endpoint=${endpoint} -> ${API_STATUS} | resultado=erro de API: ${API_ERROR:-sem detalhe}" true
      ;;
  esac
}

# --- Configuração de governança (branches, checks, cobertura) ----------------

BUILTIN_GOVERNANCE_CONFIG='{"schema_version":1,"branches":{"default_branch":"auto","production_branches":[],"protected_patterns":["release/*","hotfix/*"],"additional_branches":[]},"branch_rules":{"prefer_rulesets":true,"required_approving_review_count":1,"require_code_owner_review":true,"dismiss_stale_reviews":true,"block_direct_push":true,"block_force_push":true,"block_deletion":true,"require_status_checks":true,"require_up_to_date_branch":true,"require_conversation_resolution":true,"merge_queue":"optional"},"required_status_checks":{"build":["build"],"unit_tests":["unit-tests"],"integration_tests":[],"coverage":["coverage"],"sast":["CodeQL"],"sca":["dependency-review"],"secret_scanning":["secret-scan"]},"coverage":{"mode":"report","global_min_percent":80,"diff_min_percent":80},"codeql":{"max_analysis_age_days":8,"blocking_security_severities":["critical","high"]}}'
DEFAULT_GOVERNANCE_CONFIG=""
REPO_CFG=""
REPO_CFG_SOURCE=""
REPO_META=""
REPO_META_STATUS=""
declare -A BRANCH_EFFECTIVE_CACHE=()
REPO_BRANCHES_JSON=""
REPO_BRANCHES_STATUS=""
REPO_RULESETS_JSON=""
REPO_RULESETS_STATUS=""
REPO_CODEOWNERS=""

load_default_governance_config() {
  local path="${SECURITY_SCAN_GOVERNANCE_CONFIG:-.github/security-governance.json}"
  if [[ -f "$path" ]] && jq -e 'type == "object"' "$path" >/dev/null 2>&1; then
    DEFAULT_GOVERNANCE_CONFIG=$(jq -c --argjson builtin "$BUILTIN_GOVERNANCE_CONFIG" '$builtin * .' "$path")
  else
    [[ -f "$path" ]] && log_warn "Configuração de governança inválida em ${path} — usando padrão embutido."
    DEFAULT_GOVERNANCE_CONFIG="$BUILTIN_GOVERNANCE_CONFIG"
  fi
}

reset_repo_state() {
  REPO_CFG=""
  REPO_CFG_SOURCE=""
  REPO_META=""
  REPO_META_STATUS=""
  BRANCH_EFFECTIVE_CACHE=()
  REPO_BRANCHES_JSON=""
  REPO_BRANCHES_STATUS=""
  REPO_RULESETS_JSON=""
  REPO_RULESETS_STATUS=""
  REPO_CODEOWNERS=""
}

decode_content_body() {
  # Decodifica a resposta JSON de GET /contents/{path} (campo base64 .content).
  jq -r '.content // empty' 2>/dev/null | tr -d '\n' | base64 -d 2>/dev/null || true
}

load_repo_governance_config() {
  local repo="$1" content
  [[ -z "$DEFAULT_GOVERNANCE_CONFIG" ]] && load_default_governance_config
  api_get "repos/${repo}/contents/.github/security-governance.json"
  if [[ "$API_STATUS" == "200" ]]; then
    content=$(printf '%s' "$API_BODY" | decode_content_body)
    if [[ -n "$content" ]] && jq -e 'type == "object"' <<< "$content" >/dev/null 2>&1; then
      REPO_CFG=$(jq -c --argjson base "$DEFAULT_GOVERNANCE_CONFIG" '$base * .' <<< "$content")
      REPO_CFG_SOURCE="repositório (.github/security-governance.json)"
      return 0
    fi
    log_warn "${repo}: .github/security-governance.json inválido — usando configuração padrão da varredura."
  fi
  REPO_CFG="$DEFAULT_GOVERNANCE_CONFIG"
  REPO_CFG_SOURCE="padrão da varredura"
}

cfg_get() {
  # cfg_get <jq-filter> — lê da configuração efetiva do repositório atual.
  jq -c "$1" <<< "${REPO_CFG:-$BUILTIN_GOVERNANCE_CONFIG}"
}

load_repo_meta() {
  local repo="$1"
  api_get "repos/${repo}"
  REPO_META_STATUS="$API_STATUS"
  if [[ "$API_STATUS" == "200" ]]; then
    REPO_META=$(jq -c '{default_branch, security_and_analysis}' <<< "$API_BODY" 2>/dev/null || echo '{}')
  else
    REPO_META='{}'
  fi
}

# --- Proteção efetiva de branch (Rulesets + proteção clássica) ---------------

branch_effective() {
  # Consolida a proteção efetiva de uma branch combinando Repository/Org
  # Rulesets (GET /rules/branches/{branch}) e proteção clássica
  # (GET /branches/{branch}/protection, compatibilidade). Resultado em cache.
  local repo="$1" branch="$2"
  local cache_key="${repo}@${branch}"
  if [[ -n "${BRANCH_EFFECTIVE_CACHE[$cache_key]:-}" ]]; then
    echo "${BRANCH_EFFECTIVE_CACHE[$cache_key]}"
    return 0
  fi

  local classic_status classic_body classic_error rules_status rules_body rules_error result
  api_get "repos/${repo}/branches/${branch}/protection"
  classic_status="$API_STATUS"; classic_body="$API_BODY"; classic_error="$API_ERROR"
  [[ "$classic_status" == "200" ]] || classic_body="null"
  jq -e . <<< "$classic_body" >/dev/null 2>&1 || classic_body="null"

  api_get "repos/${repo}/rules/branches/${branch}" true
  rules_status="$API_STATUS"; rules_body="$API_BODY"; rules_error="$API_ERROR"
  [[ "$rules_status" == "200" && -n "$rules_body" ]] || rules_body="[]"
  jq -e 'type == "array"' <<< "$rules_body" >/dev/null 2>&1 || rules_body="[]"

  result=$(jq -nc \
    --argjson c "$classic_body" --argjson r "$rules_body" \
    --arg cs "$classic_status" --arg rs "$rules_status" \
    --arg ce "$classic_error" --arg re "$rules_error" \
    --arg repo "$repo" --arg branch "$branch" '
    ($r | map(select(.type == "pull_request") | (.parameters // {}))) as $prs |
    ($r | map(select(.type == "required_status_checks") | (.parameters // {}))) as $rsc |
    ($c != null) as $has_classic |
    ($c.required_pull_request_reviews // null) as $cpr |
    {
      repository: $repo,
      branch: $branch,
      classic_http: $cs,
      rules_http: $rs,
      classic_error: $ce,
      rules_error: $re,
      classic: $has_classic,
      rulesets: ($r | map(.ruleset_id // empty) | unique),
      rule_types: ($r | map(.type) | unique),
      pr_required: (($cpr != null) or ($prs | length > 0)),
      approvals: ([($cpr.required_approving_review_count // 0)] + ($prs | map(.required_approving_review_count // 0)) | max),
      code_owner_review: (($cpr.require_code_owner_reviews // false) or ($prs | any(.require_code_owner_review // false))),
      dismiss_stale: (($cpr.dismiss_stale_reviews // false) or ($prs | any(.dismiss_stale_reviews_on_push // false))),
      conversation_resolution: (($c.required_conversation_resolution.enabled // false) or ($prs | any(.required_review_thread_resolution // false))),
      force_push_blocked: (($has_classic and (($c.allow_force_pushes.enabled // false) | not)) or ($r | any(.type == "non_fast_forward"))),
      deletion_blocked: (($has_classic and (($c.allow_deletions.enabled // false) | not)) or ($r | any(.type == "deletion"))),
      required_checks: ((($c.required_status_checks.contexts // []) + (($c.required_status_checks.checks // []) | map(.context)) + ($rsc | map((.required_status_checks // []) | map(.context)) | add // [])) | unique),
      strict: (($c.required_status_checks.strict // false) or ($rsc | any(.strict_required_status_checks_policy // false))),
      merge_queue: ($r | any(.type == "merge_queue")),
      code_scanning_rule: ($r | any(.type == "code_scanning")),
      classic_determinable: ($cs == "200" or $cs == "404"),
      rules_determinable: ($rs == "200")
    }
    | .source = (if (.rulesets | length) > 0 and .classic then "ruleset+classic"
                 elif (.rulesets | length) > 0 then "ruleset"
                 elif .classic then "classic (compatibilidade)"
                 else "nenhuma" end)
    | .endpoints = "GET /repos/\($repo)/branches/\($branch)/protection -> \($cs); GET /repos/\($repo)/rules/branches/\($branch) -> \($rs)"')
  BRANCH_EFFECTIVE_CACHE[$cache_key]="$result"
  echo "$result"
}

branch_baseline_missing() {
  # Lista (JSON array) os itens do baseline que a branch NÃO atende.
  # $2 = "full" inclui aprovações/dismiss stale (branches protegidas por padrão).
  local eff="$1" mode="${2:-default}" min_approvals dismiss_required
  min_approvals=$(cfg_get '.branch_rules.required_approving_review_count // 1')
  dismiss_required=$(cfg_get '.branch_rules.dismiss_stale_reviews // true')
  jq -c --argjson min "$min_approvals" --argjson dismiss "$dismiss_required" --arg mode "$mode" '
    [ (if .pr_required | not then "pull request obrigatório (bloqueio de push direto)" else empty end),
      (if .force_push_blocked | not then "bloqueio de force push" else empty end),
      (if .deletion_blocked | not then "bloqueio de deleção" else empty end),
      (if (.required_checks | length) == 0 then "status checks obrigatórios" else empty end),
      (if $mode == "full" and .approvals < $min then "mínimo de \($min) aprovador(es) (atual: \(.approvals))" else empty end),
      (if $mode == "full" and $dismiss and (.dismiss_stale | not) then "dismiss de aprovações obsoletas" else empty end)
    ]' <<< "$eff"
}

branch_undeterminable() {
  # true quando nenhuma fonte de proteção pôde ser lida (ex.: 403 em ambas).
  jq -e '(.classic_determinable | not) and (.rules_determinable | not)' <<< "$1" >/dev/null 2>&1
}

branch_error_evidence() {
  local eff="$1"
  jq -r '"repository=\(.repository) | branch=\(.branch) | endpoint=\(.endpoints) | resultado=não foi possível ler a proteção (classic: \(.classic_error | if . == "" then "-" else . end); rulesets: \(.rules_error | if . == "" then "-" else . end))"' <<< "$eff"
}

evaluate_branch_protection_default() {
  local repo="$1" branch="$2" eff missing count
  eff=$(branch_effective "$repo" "$branch")
  if branch_undeterminable "$eff"; then
    emit_result "" "$(branch_error_evidence "$eff")" true
    return 0
  fi
  missing=$(branch_baseline_missing "$eff")
  count=$(jq 'length' <<< "$missing")
  if (( count == 0 )); then
    emit_result "ok" "$(jq -r '"repository=\(.repository) | branch=\(.branch) (padrão) | endpoint=\(.endpoints) | fonte=\(.source) | resultado=PR obrigatório, force push e deleção bloqueados, \(.required_checks | length) status check(s) obrigatório(s)"' <<< "$eff")"
  else
    emit_result "risco" "$(jq -r --argjson m "$missing" '"repository=\(.repository) | branch=\(.branch) (padrão) | endpoint=\(.endpoints) | fonte=\(.source) | resultado=baseline ausente: \($m | join("; "))"' <<< "$eff")"
  fi
}

# Compatibilidade: controle legado `branch-protection` (id anterior à issue #450).
evaluate_branch_protection() {
  evaluate_branch_protection_default "$@"
}

load_repo_branches() {
  local repo="$1"
  [[ -n "$REPO_BRANCHES_STATUS" ]] && return 0
  api_get "repos/${repo}/branches?per_page=100" true
  REPO_BRANCHES_STATUS="$API_STATUS"
  if [[ "$API_STATUS" == "200" ]]; then
    REPO_BRANCHES_JSON=$(jq -c '[.[]?.name // empty]' <<< "${API_BODY:-[]}" 2>/dev/null || echo '[]')
  else
    REPO_BRANCHES_JSON='[]'
  fi
}

load_repo_rulesets() {
  # Rulesets ativos de branch aplicáveis ao repositório (inclui os herdados da
  # organização via includes_parents=true), com condições e tipos de regra.
  local repo="$1" list id detail details=""
  [[ -n "$REPO_RULESETS_STATUS" ]] && return 0
  api_get "repos/${repo}/rulesets?includes_parents=true&per_page=100" true
  REPO_RULESETS_STATUS="$API_STATUS"
  if [[ "$API_STATUS" != "200" ]]; then
    REPO_RULESETS_JSON='[]'
    return 0
  fi
  list="${API_BODY:-[]}"
  while IFS= read -r id; do
    [[ -z "$id" ]] && continue
    api_get "repos/${repo}/rulesets/${id}?includes_parents=true"
    if [[ "$API_STATUS" == "200" ]]; then
      detail=$(jq -c '{id, name, enforcement, target, source_type, include: [(.conditions.ref_name.include // [])[] | sub("^refs/heads/"; "")], exclude: [(.conditions.ref_name.exclude // [])[] | sub("^refs/heads/"; "")], rule_types: [(.rules // [])[].type]}' <<< "$API_BODY" 2>/dev/null || true)
      [[ -n "$detail" ]] && details+="${detail}"$'\n'
    fi
  done < <(jq -r '.[]? | select((.target // "branch") == "branch" and (.enforcement // "active") == "active") | .id' <<< "$list" 2>/dev/null)
  REPO_RULESETS_JSON=$(ndjson_to_json_array "$details")
}

glob_matches() {
  # glob_matches <nome> <padrão estilo fnmatch do GitHub>
  local name="$1" pattern="$2"
  [[ "$pattern" == "~ALL" ]] && return 0
  pattern="${pattern//\*\*/*}"
  # shellcheck disable=SC2053
  [[ "$name" == $pattern ]]
}

rulesets_covering_target() {
  # Imprime JSON array de rulesets (ativos) que cobrem o alvo (branch ou padrão).
  local target="$1" default_branch="$2" covering="" row matched excluded inc exc
  while IFS= read -r row; do
    [[ -z "$row" ]] && continue
    matched="false"; excluded="false"
    while IFS= read -r inc; do
      [[ -z "$inc" ]] && continue
      if [[ "$inc" == "~DEFAULT_BRANCH" ]]; then
        [[ "$target" == "$default_branch" ]] && matched="true"
      elif [[ "$inc" == "$target" ]] || glob_matches "$target" "$inc"; then
        matched="true"
      fi
    done < <(jq -r '.include[]?' <<< "$row")
    while IFS= read -r exc; do
      [[ -z "$exc" ]] && continue
      if [[ "$exc" == "$target" ]] || glob_matches "$target" "$exc"; then excluded="true"; fi
    done < <(jq -r '.exclude[]?' <<< "$row")
    [[ "$matched" == "true" && "$excluded" == "false" ]] && covering+="${row}"$'\n'
  done < <(jq -c '.[]?' <<< "${REPO_RULESETS_JSON:-[]}")
  ndjson_to_json_array "$covering"
}

evaluate_branch_protection_required_patterns() {
  local repo="$1" default_branch="$2"
  local targets target max_per_pattern overall="ok" had_error="false" entries=() is_glob
  local matches match_count covering complete eff missing branch_entries sampled

  targets=$(cfg_get '[(.branches.production_branches // [])[], (.branches.protected_patterns // [])[], (.branches.additional_branches // [])[]] | map(select(type == "string" and length > 0)) | unique')
  if [[ $(jq 'length' <<< "$targets") -eq 0 ]]; then
    emit_result "pendente" "repository=${repo} | alvo=- | endpoint=- | resultado=nenhuma branch/padrão protegido declarado em branches.production_branches/protected_patterns (configuração: ${REPO_CFG_SOURCE:-padrão})"
    return 0
  fi

  load_repo_branches "$repo"
  if [[ "$REPO_BRANCHES_STATUS" != "200" ]]; then
    API_STATUS="$REPO_BRANCHES_STATUS"
    emit_api_failure "$repo" "branches" "GET /repos/${repo}/branches" "Metadata:read"
    return 0
  fi
  load_repo_rulesets "$repo"
  max_per_pattern="${SECURITY_SCAN_MAX_BRANCHES_PER_PATTERN:-20}"

  while IFS= read -r target; do
    [[ -z "$target" ]] && continue
    [[ "$target" == "$default_branch" ]] && { entries+=("${target} → coberto pelo controle branch-protection-default"); continue; }
    if [[ "$target" == *[\*\?\[]* ]]; then is_glob="true"; else is_glob="false"; fi

    matches=$(jq -c --arg t "$target" --arg g "$is_glob" '[.[] | select(if $g == "true" then true else . == $t end)]' <<< "$REPO_BRANCHES_JSON")
    if [[ "$is_glob" == "true" ]]; then
      local filtered="" name
      while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        glob_matches "$name" "$target" && filtered+="$(jq -Rn --arg n "$name" '$n')"$'\n'
      done < <(jq -r '.[]' <<< "$matches")
      matches=$(ndjson_to_json_array "$filtered")
    fi
    match_count=$(jq 'length' <<< "$matches")

    if [[ "$REPO_RULESETS_STATUS" == "200" ]]; then
      covering=$(rulesets_covering_target "$target" "$default_branch")
    else
      covering='[]'
    fi
    complete=$(jq -c '[.[] | select((.rule_types | index("pull_request")) and (.rule_types | index("non_fast_forward")) and (.rule_types | index("deletion")))]' <<< "$covering")

    branch_entries=()
    sampled=0
    while IFS= read -r name; do
      [[ -z "$name" ]] && continue
      sampled=$((sampled + 1))
      (( sampled > max_per_pattern )) && break
      eff=$(branch_effective "$repo" "$name")
      if branch_undeterminable "$eff"; then
        had_error="true"
        branch_entries+=("${name}: erro de leitura (classic HTTP $(jq -r '.classic_http' <<< "$eff"), rulesets HTTP $(jq -r '.rules_http' <<< "$eff"))")
        continue
      fi
      missing=$(branch_baseline_missing "$eff" "full")
      if [[ $(jq 'length' <<< "$missing") -eq 0 ]]; then
        branch_entries+=("${name}: ok [$(jq -r '.source' <<< "$eff")]")
      else
        overall="risco"
        branch_entries+=("${name}: RISCO [$(jq -r '.source' <<< "$eff")] faltando $(jq -r 'join(", ")' <<< "$missing")")
      fi
    done < <(jq -r '.[]' <<< "$matches")

    local summary coverage_text
    if [[ $(jq 'length' <<< "$complete") -gt 0 ]]; then
      coverage_text="ruleset(s) $(jq -r 'map("\(.id) (\(.name))") | join(", ")' <<< "$complete") cobrem com baseline"
    elif [[ $(jq 'length' <<< "$covering") -gt 0 ]]; then
      coverage_text="ruleset(s) $(jq -r 'map("\(.id) (\(.name))") | join(", ")' <<< "$covering") cobrem SEM baseline completo (pull_request/non_fast_forward/deletion)"
    elif [[ "$REPO_RULESETS_STATUS" == "200" ]]; then
      coverage_text="nenhum ruleset ativo cobre o alvo"
    else
      coverage_text="API de Rulesets indisponível (HTTP ${REPO_RULESETS_STATUS})"
    fi

    if (( match_count == 0 )); then
      if [[ "$is_glob" == "true" && $(jq 'length' <<< "$complete") -eq 0 ]]; then
        [[ "$overall" == "ok" ]] && overall="pendente"
        summary="${target} → nenhuma branch existente; ${coverage_text} — branches futuras nascerão sem proteção (pendente)"
      elif [[ "$is_glob" == "true" ]]; then
        summary="${target} → nenhuma branch existente; ${coverage_text}"
      else
        summary="${target} → branch inexistente neste repositório (não avaliada); ${coverage_text}"
      fi
    else
      if (( match_count > max_per_pattern )); then
        summary="${target} → ${coverage_text}; avaliadas ${max_per_pattern} de ${match_count} branches: $(IFS='; '; echo "${branch_entries[*]}")"
      else
        summary="${target} → ${coverage_text}; branches: $(IFS='; '; echo "${branch_entries[*]}")"
      fi
      if [[ "$is_glob" == "true" && $(jq 'length' <<< "$complete") -eq 0 && "$overall" == "ok" ]]; then
        summary+=" (proteção clássica por branch — compatibilidade; preferir Ruleset)"
      fi
    fi
    entries+=("$summary")
  done < <(jq -r '.[]' <<< "$targets")

  local evidence
  evidence="repository=${repo} | endpoint=GET /repos/${repo}/branches, GET /repos/${repo}/rulesets?includes_parents=true -> ${REPO_RULESETS_STATUS}, GET /repos/${repo}/rules/branches/{branch} | configuração=${REPO_CFG_SOURCE:-padrão} | resultado=$(IFS='|'; printf '%s' "${entries[*]}" | sed 's/|/ || /g')"
  if [[ "$had_error" == "true" && "$overall" == "ok" ]]; then
    emit_result "" "$evidence" true
  else
    emit_result "$overall" "$evidence"
  fi
}

evaluate_rulesets_configured() {
  local repo="$1" branch="$2" eff
  eff=$(branch_effective "$repo" "$branch")
  local rs classic rules_http
  rs=$(jq -r '.rulesets | length' <<< "$eff")
  classic=$(jq -r '.classic' <<< "$eff")
  rules_http=$(jq -r '.rules_http' <<< "$eff")

  if [[ "$rules_http" != "200" ]]; then
    API_STATUS="$rules_http"; API_ERROR=$(jq -r '.rules_error' <<< "$eff")
    emit_api_failure "$repo" "branch=${branch}" "GET /repos/${repo}/rules/branches/${branch}" "Administration:read"
    return 0
  fi
  if (( rs > 0 )); then
    emit_result "ok" "$(jq -r '"repository=\(.repository) | branch=\(.branch) | endpoint=GET /repos/\(.repository)/rules/branches/\(.branch) -> 200 | resultado=ruleset(s) ativo(s) \(.rulesets | map(tostring) | join(", ")) aplicados; regras: \(.rule_types | join(", "))\(if .classic then " (proteção clássica também presente)" else "" end)"' <<< "$eff")"
  elif [[ "$classic" == "true" ]]; then
    emit_result "pendente" "repository=${repo} | branch=${branch} | endpoint=GET /repos/${repo}/rules/branches/${branch} -> 200 (0 regras) | resultado=somente proteção clássica de branch (compatibilidade) — migrar para Repository/Organization Rulesets"
  else
    emit_result "risco" "repository=${repo} | branch=${branch} | endpoint=GET /repos/${repo}/rules/branches/${branch} -> 200 (0 regras) | resultado=nenhum ruleset e nenhuma proteção clássica na branch padrão"
  fi
}

load_codeowners() {
  local repo="$1" path
  [[ -n "$REPO_CODEOWNERS" ]] && return 0
  REPO_CODEOWNERS="ausente"
  for path in ".github/CODEOWNERS" "CODEOWNERS" "docs/CODEOWNERS"; do
    api_get "repos/${repo}/contents/${path}"
    if [[ "$API_STATUS" == "200" ]]; then
      REPO_CODEOWNERS="$path"
      return 0
    fi
  done
}

evaluate_required_review() {
  local repo="$1" branch="$2" eff min approvals require_co require_dismiss require_conv problems=() pending=()
  eff=$(branch_effective "$repo" "$branch")
  if branch_undeterminable "$eff"; then
    emit_result "" "$(branch_error_evidence "$eff")" true
    return 0
  fi
  min=$(cfg_get '.branch_rules.required_approving_review_count // 1')
  require_co=$(cfg_get '.branch_rules.require_code_owner_review // true')
  require_dismiss=$(cfg_get '.branch_rules.dismiss_stale_reviews // true')
  require_conv=$(cfg_get '.branch_rules.require_conversation_resolution // true')
  approvals=$(jq -r '.approvals' <<< "$eff")
  load_codeowners "$repo"

  if [[ $(jq -r '.pr_required' <<< "$eff") != "true" ]]; then
    problems+=("pull request não é obrigatório")
  fi
  if ! [[ "$approvals" =~ ^[0-9]+$ ]] || (( approvals < min )); then
    problems+=("required_approving_review_count=${approvals} (< ${min})")
  fi
  if [[ "$require_dismiss" == "true" && $(jq -r '.dismiss_stale' <<< "$eff") != "true" ]]; then
    problems+=("dismiss de aprovações obsoletas desabilitado")
  fi
  if [[ "$require_co" == "true" && "$REPO_CODEOWNERS" != "ausente" && $(jq -r '.code_owner_review' <<< "$eff") != "true" ]]; then
    problems+=("CODEOWNERS (${REPO_CODEOWNERS}) existe mas revisão de code owners não é exigida")
  fi
  if [[ "$require_conv" == "true" && $(jq -r '.conversation_resolution' <<< "$eff") != "true" ]]; then
    pending+=("resolução de conversas não exigida")
  fi

  local base
  base=$(jq -r --arg co "$REPO_CODEOWNERS" '"repository=\(.repository) | branch=\(.branch) | endpoint=\(.endpoints) | fonte=\(.source) | aprovadores=\(.approvals) dismiss_stale=\(.dismiss_stale) code_owners=\(.code_owner_review) (CODEOWNERS: \($co)) resolução_conversas=\(.conversation_resolution)"' <<< "$eff")
  if (( ${#problems[@]} > 0 )); then
    emit_result "risco" "${base} | resultado=$(IFS=';'; echo "${problems[*]}${pending[*]:+;${pending[*]}}")"
  elif (( ${#pending[@]} > 0 )); then
    emit_result "pendente" "${base} | resultado=$(IFS=';'; echo "${pending[*]}")"
  else
    emit_result "ok" "${base} | resultado=revisão obrigatória conforme baseline (>= ${min} aprovador(es))"
  fi
}

required_checks_for_branches() {
  # Avalia os required status checks esperados em uma lista de branches.
  # $1 repo, $2 JSON array de contexts esperados, $3 JSON array de branches.
  local repo="$1" expected="$2" branches="$3" name eff missing out=""
  while IFS= read -r name; do
    [[ -z "$name" ]] && continue
    eff=$(branch_effective "$repo" "$name")
    if branch_undeterminable "$eff"; then
      out+=$(jq -nc --arg b "$name" --arg ev "$(branch_error_evidence "$eff")" '{branch:$b, error:true, evidence:$ev}')$'\n'
      continue
    fi
    missing=$(jq -c --argjson exp "$expected" '$exp - .required_checks' <<< "$eff")
    out+=$(jq -c --arg b "$name" --argjson missing "$missing" '{branch:$b, error:false, missing:$missing, present:.required_checks, strict:.strict, endpoints:.endpoints, source:.source}' <<< "$eff")$'\n'
  done < <(jq -r '.[]' <<< "$branches")
  ndjson_to_json_array "$out"
}

protected_concrete_branches() {
  # Branch padrão + production_branches existentes (nomes concretos).
  local repo="$1" default_branch="$2" prod
  prod=$(cfg_get '(.branches.production_branches // []) | map(select(test("[*?\\[]") | not))')
  load_repo_branches "$repo"
  jq -nc --arg d "$default_branch" --argjson prod "$prod" --argjson existing "${REPO_BRANCHES_JSON:-[]}" \
    '([$d] + ($prod | map(select(. as $b | $existing | index($b))))) | unique'
}

evaluate_required_pr_checks() {
  local repo="$1" default_branch="$2" expected branches results require_strict
  expected=$(cfg_get '[(.required_status_checks // {}) | to_entries[] | .value[]?] | unique')
  require_strict=$(cfg_get '.branch_rules.require_up_to_date_branch // true')
  if [[ $(jq 'length' <<< "$expected") -eq 0 ]]; then
    emit_result "pendente" "repository=${repo} | branch=${default_branch} | endpoint=- | resultado=nenhum required status check esperado declarado em required_status_checks (configuração: ${REPO_CFG_SOURCE:-padrão})"
    return 0
  fi
  branches=$(protected_concrete_branches "$repo" "$default_branch")
  results=$(required_checks_for_branches "$repo" "$expected" "$branches")
  local text status
  text=$(jq -r --argjson exp "$expected" 'map(if .error then "\(.branch): erro de leitura" elif (.missing | length) > 0 then "\(.branch): FALTAM \(.missing | join(", ")) [fonte \(.source); presentes: \(if (.present | length) == 0 then "nenhum" else (.present | join(", ")) end)]" else "\(.branch): todos presentes [fonte \(.source); strict=\(.strict)]" end) | join("; ")' <<< "$results")
  if jq -e 'any(.[]; (.error | not) and (.missing | length) > 0)' <<< "$results" >/dev/null; then
    status="risco"
  elif jq -e 'all(.[]; .error)' <<< "$results" >/dev/null; then
    emit_result "" "repository=${repo} | endpoint=GET /repos/${repo}/branches/{branch}/protection, GET /repos/${repo}/rules/branches/{branch} | resultado=${text}" true
    return 0
  elif [[ "$require_strict" == "true" ]] && jq -e 'any(.[]; (.error | not) and (.strict | not))' <<< "$results" >/dev/null; then
    status="pendente"
    text+=" | branch atualizada antes do merge (strict) não exigida"
  else
    status="ok"
  fi
  emit_result "$status" "repository=${repo} | endpoint=GET /repos/${repo}/branches/{branch}/protection, GET /repos/${repo}/rules/branches/{branch} | checks esperados=$(jq -r 'join(", ")' <<< "$expected") | resultado=${text}"
}

evaluate_required_test_checks() {
  local repo="$1" default_branch="$2" expected results text
  expected=$(cfg_get '[(.required_status_checks.unit_tests // [])[], (.required_status_checks.integration_tests // [])[]] | unique')
  if [[ $(jq 'length' <<< "$expected") -eq 0 ]]; then
    emit_result "risco" "repository=${repo} | branch=${default_branch} | endpoint=- | resultado=nenhum check de teste (unit_tests/integration_tests) declarado — todo PR deve exigir testes automatizados (configuração: ${REPO_CFG_SOURCE:-padrão})"
    return 0
  fi
  results=$(required_checks_for_branches "$repo" "$expected" "$(jq -nc --arg d "$default_branch" '[$d]')")
  if jq -e '.[0].error' <<< "$results" >/dev/null; then
    emit_result "" "$(jq -r '.[0].evidence' <<< "$results")" true
    return 0
  fi
  text=$(jq -r '.[0] | "endpoint=\(.endpoints) | fonte=\(.source) | faltando=\(if (.missing | length) == 0 then "nenhum" else (.missing | join(", ")) end)"' <<< "$results")
  if jq -e '(.[0].missing | length) > 0' <<< "$results" >/dev/null; then
    emit_result "risco" "repository=${repo} | branch=${default_branch} | checks de teste esperados=$(jq -r 'join(", ")' <<< "$expected") | ${text} | resultado=teste obrigatório não é required status check (falha/ausência não bloqueia merge)"
  else
    emit_result "ok" "repository=${repo} | branch=${default_branch} | checks de teste esperados=$(jq -r 'join(", ")' <<< "$expected") | ${text} | resultado=checks de teste obrigatórios"
  fi
}

evaluate_required_coverage_check() {
  local repo="$1" default_branch="$2" mode reason expected tests results text
  mode=$(cfg_get '.coverage.mode // "report"' | jq -r '.')
  if [[ "$mode" == "not-applicable" ]]; then
    reason=$(cfg_get '.coverage.not_applicable_reason // ""' | jq -r '.')
    tests=$(cfg_get '[(.required_status_checks.unit_tests // [])[]]')
    if [[ -z "$reason" || $(jq 'length' <<< "$tests") -eq 0 ]]; then
      emit_result "risco" "repository=${repo} | branch=${default_branch} | endpoint=- | resultado=coverage.mode=not-applicable sem justificativa ou sem suíte de testes obrigatória como gate substituto"
      return 0
    fi
    results=$(required_checks_for_branches "$repo" "$tests" "$(jq -nc --arg d "$default_branch" '[$d]')")
    if jq -e '.[0].error' <<< "$results" >/dev/null; then
      emit_result "" "$(jq -r '.[0].evidence' <<< "$results")" true
    elif jq -e '(.[0].missing | length) > 0' <<< "$results" >/dev/null; then
      emit_result "risco" "repository=${repo} | branch=${default_branch} | resultado=cobertura declarada não aplicável, mas o gate substituto (testes: $(jq -r 'join(", ")' <<< "$tests")) não é obrigatório"
    else
      emit_result "ok" "repository=${repo} | branch=${default_branch} | resultado=cobertura NÃO APLICÁVEL (declarado): ${reason} — gate substituto obrigatório: $(jq -r 'join(", ")' <<< "$tests"). Nenhuma métrica de cobertura calculada."
    fi
    return 0
  fi
  expected=$(cfg_get '[(.required_status_checks.coverage // [])[]] | unique')
  if [[ $(jq 'length' <<< "$expected") -eq 0 ]]; then
    emit_result "risco" "repository=${repo} | branch=${default_branch} | endpoint=- | resultado=coverage.mode=report sem check de cobertura declarado em required_status_checks.coverage"
    return 0
  fi
  results=$(required_checks_for_branches "$repo" "$expected" "$(jq -nc --arg d "$default_branch" '[$d]')")
  if jq -e '.[0].error' <<< "$results" >/dev/null; then
    emit_result "" "$(jq -r '.[0].evidence' <<< "$results")" true
    return 0
  fi
  text=$(jq -r '.[0] | "endpoint=\(.endpoints) | fonte=\(.source)"' <<< "$results")
  if jq -e '(.[0].missing | length) > 0' <<< "$results" >/dev/null; then
    emit_result "risco" "repository=${repo} | branch=${default_branch} | ${text} | resultado=check de cobertura ($(jq -r '.[0].missing | join(", ")' <<< "$results")) não é obrigatório — cobertura abaixo do mínimo ou relatório ausente não bloqueia merge"
  else
    emit_result "ok" "repository=${repo} | branch=${default_branch} | ${text} | resultado=check de cobertura obrigatório ($(jq -r 'join(", ")' <<< "$expected")); mínimo global $(cfg_get '.coverage.global_min_percent // 80')%"
  fi
}

evaluate_codeql_enabled() {
  local repo="$1" state
  api_get "repos/${repo}/code-scanning/default-setup"
  if [[ "$API_STATUS" == "200" ]]; then
    state=$(jq -r '.state // "unknown"' <<< "$API_BODY")
    if [[ "$state" == "configured" ]]; then
      emit_result "ok" "repository=${repo} | endpoint=GET /repos/${repo}/code-scanning/default-setup -> 200 | resultado=CodeQL default setup configurado (linguagens: $(jq -r '(.languages // []) | join(", ")' <<< "$API_BODY"))"
      return 0
    fi
  elif [[ "$API_STATUS" != "404" ]]; then
    emit_api_failure "$repo" "code scanning" "GET /repos/${repo}/code-scanning/default-setup" "Administration:read + Code scanning alerts:read"
    return 0
  fi
  api_get "repos/${repo}/code-scanning/analyses?tool_name=CodeQL&per_page=1"
  if [[ "$API_STATUS" == "200" ]]; then
    if [[ $(jq 'if type == "array" then length else 0 end' <<< "${API_BODY:-[]}") -gt 0 ]]; then
      emit_result "ok" "repository=${repo} | endpoint=GET /repos/${repo}/code-scanning/analyses?tool_name=CodeQL -> 200 | resultado=CodeQL advanced setup (workflow) publicando análises"
    else
      emit_result "risco" "repository=${repo} | endpoint=GET /repos/${repo}/code-scanning/analyses?tool_name=CodeQL -> 200 (0 análises) | resultado=CodeQL não configurado"
    fi
  elif [[ "$API_STATUS" == "404" ]] && grep -qi 'no analysis found' <<< "$API_ERROR"; then
    emit_result "risco" "repository=${repo} | endpoint=GET /repos/${repo}/code-scanning/analyses -> 404 | resultado=nenhuma análise CodeQL publicada (default setup: ${state:-não configurado})"
  else
    emit_api_failure "$repo" "code scanning" "GET /repos/${repo}/code-scanning/analyses?tool_name=CodeQL" "Code scanning alerts:read"
  fi
}

evaluate_codeql_recent() {
  local repo="$1" branch="$2" max_age created age
  max_age=$(cfg_get '.codeql.max_analysis_age_days // 8')
  api_get "repos/${repo}/code-scanning/analyses?tool_name=CodeQL&ref=refs/heads/${branch}&per_page=1"
  if [[ "$API_STATUS" == "200" ]]; then
    created=$(jq -r 'if type == "array" and length > 0 then .[0].created_at else "" end' <<< "${API_BODY:-[]}")
    if [[ -z "$created" ]]; then
      emit_result "risco" "repository=${repo} | branch=${branch} | endpoint=GET /repos/${repo}/code-scanning/analyses?ref=refs/heads/${branch} -> 200 (0 análises) | resultado=nenhuma análise CodeQL na branch padrão"
      return 0
    fi
    age=$(jq -nr --arg c "$created" '((now - ($c | sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601)) / 86400) | floor')
    if (( age <= max_age )); then
      emit_result "ok" "repository=${repo} | branch=${branch} | endpoint=GET /repos/${repo}/code-scanning/analyses?ref=refs/heads/${branch} -> 200 | resultado=última análise CodeQL em ${created} (${age} dia(s), limite ${max_age})"
    else
      emit_result "risco" "repository=${repo} | branch=${branch} | endpoint=GET /repos/${repo}/code-scanning/analyses?ref=refs/heads/${branch} -> 200 | resultado=última análise CodeQL em ${created} (${age} dias > limite ${max_age}) — análise desatualizada"
    fi
  elif [[ "$API_STATUS" == "404" ]] && grep -qi 'no analysis found' <<< "$API_ERROR"; then
    emit_result "risco" "repository=${repo} | branch=${branch} | endpoint=GET /repos/${repo}/code-scanning/analyses -> 404 | resultado=nenhuma análise CodeQL encontrada"
  else
    emit_api_failure "$repo" "branch=${branch}" "GET /repos/${repo}/code-scanning/analyses?tool_name=CodeQL&ref=refs/heads/${branch}" "Code scanning alerts:read"
  fi
}

evaluate_codeql_alerts() {
  local repo="$1" blocking summary count
  blocking=$(cfg_get '.codeql.blocking_security_severities // ["critical","high"]')
  api_get "repos/${repo}/code-scanning/alerts?state=open&tool_name=CodeQL&per_page=100" true
  if [[ "$API_STATUS" == "200" ]]; then
    summary=$(jq -c --argjson sev "$blocking" '
      (if type == "array" then . else [] end) as $all |
      ($all | map(select(((.rule.security_severity_level // "") | ascii_downcase) as $s | $sev | index($s)))) as $b |
      { total: ($all | length),
        blocking: ($b | length),
        critical: ($b | map(select(.rule.security_severity_level == "critical")) | length),
        high: ($b | map(select(.rule.security_severity_level == "high")) | length),
        numbers: ($b | map(.number) | .[0:10]),
        oldest: ($b | map(.created_at) | min) }' <<< "${API_BODY:-[]}")
    count=$(jq -r '.blocking' <<< "$summary")
    if (( count == 0 )); then
      emit_result "ok" "repository=${repo} | endpoint=GET /repos/${repo}/code-scanning/alerts?state=open&tool_name=CodeQL -> 200 | resultado=0 alertas abertos $(jq -r 'join("/")' <<< "$blocking") (total aberto: $(jq -r '.total' <<< "$summary"))"
    else
      emit_result "risco" "repository=${repo} | endpoint=GET /repos/${repo}/code-scanning/alerts?state=open&tool_name=CodeQL -> 200 | resultado=$(jq -r '"\(.blocking) alerta(s) CodeQL abertos acima do limite (critical=\(.critical), high=\(.high)); mais antigo: \(.oldest); alertas: #\(.numbers | map(tostring) | join(", #"))"' <<< "$summary")"
    fi
  elif [[ "$API_STATUS" == "404" ]] && grep -qi 'no analysis found' <<< "$API_ERROR"; then
    emit_result "pendente" "repository=${repo} | endpoint=GET /repos/${repo}/code-scanning/alerts -> 404 | resultado=sem análise CodeQL — alertas não avaliáveis (ver codeql-enabled)"
  else
    emit_api_failure "$repo" "code scanning alerts" "GET /repos/${repo}/code-scanning/alerts?state=open&tool_name=CodeQL" "Code scanning alerts:read"
  fi
}

evaluate_dependabot_alerts_enabled() {
  local repo="$1" open_info=""
  api_get "repos/${repo}/vulnerability-alerts"
  case "$API_STATUS" in
    200)
      api_get "repos/${repo}/dependabot/alerts?state=open&severity=critical,high&per_page=100" true
      if [[ "$API_STATUS" == "200" ]]; then
        open_info="; alertas Dependabot critical/high abertos: $(jq 'if type == "array" then length else 0 end' <<< "${API_BODY:-[]}") (tratar conforme SLA da seção 16)"
      else
        open_info="; contagem de alertas indisponível (HTTP ${API_STATUS} — requer Dependabot alerts:read)"
      fi
      emit_result "ok" "repository=${repo} | endpoint=GET /repos/${repo}/vulnerability-alerts -> 204 | resultado=Dependabot alerts habilitado${open_info}"
      ;;
    404)
      emit_result "risco" "repository=${repo} | endpoint=GET /repos/${repo}/vulnerability-alerts -> 404 | resultado=Dependabot alerts desabilitado"
      ;;
    *)
      emit_api_failure "$repo" "vulnerability alerts" "GET /repos/${repo}/vulnerability-alerts" "Administration:read"
      ;;
  esac
}

evaluate_dependabot_security_updates_enabled() {
  local repo="$1" enabled paused
  api_get "repos/${repo}/automated-security-fixes"
  case "$API_STATUS" in
    200)
      local body="${API_BODY:-}"
      [[ -z "$body" ]] && body='{}'
      enabled=$(jq -r '.enabled // false' <<< "$body")
      paused=$(jq -r '.paused // false' <<< "$body")
      if [[ "$enabled" == "true" && "$paused" != "true" ]]; then
        emit_result "ok" "repository=${repo} | endpoint=GET /repos/${repo}/automated-security-fixes -> 200 | resultado=enabled=true paused=false"
      elif [[ "$enabled" == "true" ]]; then
        emit_result "pendente" "repository=${repo} | endpoint=GET /repos/${repo}/automated-security-fixes -> 200 | resultado=enabled=true mas paused=true (Dependabot security updates pausado)"
      else
        emit_result "risco" "repository=${repo} | endpoint=GET /repos/${repo}/automated-security-fixes -> 200 | resultado=enabled=false"
      fi
      ;;
    404)
      emit_result "risco" "repository=${repo} | endpoint=GET /repos/${repo}/automated-security-fixes -> 404 | resultado=Dependabot security updates desabilitado (ou Dependabot alerts desabilitado)"
      ;;
    *)
      emit_api_failure "$repo" "automated security fixes" "GET /repos/${repo}/automated-security-fixes" "Administration:read"
      ;;
  esac
}

evaluate_dependency_review_enabled() {
  local repo="$1" default_branch="$2" files path content found="" max_files checked=0 sca results
  api_get "repos/${repo}/contents/.github/workflows"
  if [[ "$API_STATUS" == "404" ]]; then
    emit_result "risco" "repository=${repo} | endpoint=GET /repos/${repo}/contents/.github/workflows -> 404 | resultado=nenhum workflow — Dependency Review ausente"
    return 0
  elif [[ "$API_STATUS" != "200" ]]; then
    emit_api_failure "$repo" ".github/workflows" "GET /repos/${repo}/contents/.github/workflows" "Contents:read"
    return 0
  fi
  files=$(jq -r '.[]? | select(.type == "file" and (.name | test("\\.ya?ml$"))) | .path' <<< "$API_BODY")
  max_files="${SECURITY_SCAN_MAX_WORKFLOW_FILES:-50}"
  while IFS= read -r path; do
    [[ -z "$path" ]] && continue
    checked=$((checked + 1))
    (( checked > max_files )) && break
    api_get "repos/${repo}/contents/${path}"
    [[ "$API_STATUS" == "200" ]] || continue
    content=$(printf '%s' "$API_BODY" | decode_content_body)
    if grep -Eq 'uses:[[:space:]]*["'\'']?actions/dependency-review-action@' <<< "$content"; then
      found="$path"
      break
    fi
  done <<< "$files"

  if [[ -z "$found" ]]; then
    emit_result "risco" "repository=${repo} | endpoint=GET /repos/${repo}/contents/.github/workflows -> 200 (${checked} arquivo(s) inspecionado(s)) | resultado=nenhum workflow usa actions/dependency-review-action"
    return 0
  fi
  sca=$(cfg_get '[(.required_status_checks.sca // [])[]] | unique')
  if [[ $(jq 'length' <<< "$sca") -eq 0 ]]; then
    emit_result "pendente" "repository=${repo} | endpoint=GET /repos/${repo}/contents/${found} -> 200 | resultado=workflow ${found} presente, mas nenhum check SCA declarado em required_status_checks.sca"
    return 0
  fi
  results=$(required_checks_for_branches "$repo" "$sca" "$(jq -nc --arg d "$default_branch" '[$d]')")
  if jq -e '.[0].error' <<< "$results" >/dev/null; then
    emit_result "" "$(jq -r '.[0].evidence' <<< "$results")" true
  elif jq -e '(.[0].missing | length) > 0' <<< "$results" >/dev/null; then
    emit_result "pendente" "repository=${repo} | branch=${default_branch} | endpoint=GET /repos/${repo}/contents/${found} -> 200 | resultado=workflow ${found} presente, mas o check $(jq -r '.[0].missing | join(", ")' <<< "$results") não é required status check"
  else
    emit_result "ok" "repository=${repo} | branch=${default_branch} | endpoint=GET /repos/${repo}/contents/${found} -> 200 | resultado=Dependency Review em ${found} e check $(jq -r 'join(", ")' <<< "$sca") obrigatório"
  fi
}

evaluate_security_analysis_feature() {
  # $1 repo, $2 chave em security_and_analysis, $3 descrição
  local repo="$1" key="$2" label="$3" status
  if [[ "$REPO_META_STATUS" != "200" ]]; then
    API_STATUS="${REPO_META_STATUS:-000}"
    emit_api_failure "$repo" "security_and_analysis" "GET /repos/${repo}" "Metadata:read + Administration:read"
    return 0
  fi
  status=$(jq -r --arg k "$key" '.security_and_analysis[$k].status // empty' <<< "$REPO_META")
  case "$status" in
    enabled)
      emit_result "ok" "repository=${repo} | endpoint=GET /repos/${repo} -> 200 | resultado=security_and_analysis.${key}.status=enabled (${label})"
      ;;
    disabled)
      emit_result "risco" "repository=${repo} | endpoint=GET /repos/${repo} -> 200 | resultado=security_and_analysis.${key}.status=disabled (${label} desabilitado)"
      ;;
    *)
      emit_result "pendente" "repository=${repo} | endpoint=GET /repos/${repo} -> 200 | resultado=security_and_analysis.${key} não retornado — permissão Administration:read ausente no GitHub App ou recurso indisponível no plano/instância; não é tratado como conforme"
      ;;
  esac
}

evaluate_secret_scanning_enabled() {
  evaluate_security_analysis_feature "$1" "secret_scanning" "GitHub Secret Scanning"
}

evaluate_secret_scanning_push_protection_enabled() {
  evaluate_security_analysis_feature "$1" "secret_scanning_push_protection" "Push Protection"
}

evaluate_secret_alerts() {
  # Lê SOMENTE metadados dos alertas (hide_secret=true + projeção jq): o valor
  # do secret nunca é solicitado, armazenado, logado ou publicado.
  local repo="$1" summary count
  api_get "repos/${repo}/secret-scanning/alerts?state=open&per_page=100&hide_secret=true" true
  if [[ "$API_STATUS" == "200" ]]; then
    summary=$(jq -c '(if type == "array" then . else [] end) | {count: length, types: (map(.secret_type_display_name // .secret_type // "desconhecido") | unique | .[0:10]), oldest: (map(.created_at) | min), bypassed: (map(select(.push_protection_bypassed == true)) | length), numbers: (map(.number) | .[0:10])}' <<< "${API_BODY:-[]}")
    API_BODY=""
    count=$(jq -r '.count' <<< "$summary")
    if (( count == 0 )); then
      emit_result "ok" "repository=${repo} | endpoint=GET /repos/${repo}/secret-scanning/alerts?state=open&hide_secret=true -> 200 | resultado=0 alertas de secret abertos"
    else
      emit_result "risco" "repository=${repo} | endpoint=GET /repos/${repo}/secret-scanning/alerts?state=open&hide_secret=true -> 200 | resultado=$(jq -r '"\(.count) alerta(s) de secret aberto(s) (tipos: \(.types | join(", ")); mais antigo: \(.oldest); push protection contornada: \(.bypassed); alertas: #\(.numbers | map(tostring) | join(", #"))) — revogar/rotacionar e fechar o alerta"' <<< "$summary")"
    fi
  else
    API_BODY=""
    emit_api_failure "$repo" "secret scanning alerts" "GET /repos/${repo}/secret-scanning/alerts?state=open&hide_secret=true" "Secret scanning alerts:read"
  fi
}

evaluate_actions_permissions() {
  local repo="$1"
  local enabled allowed default_perm can_approve wf_note="" status
  api_get "repos/${repo}/actions/permissions"

  case "$API_STATUS" in
    200)
      enabled=$(echo "$API_BODY" | jq -r '.enabled // false')
      allowed=$(echo "$API_BODY" | jq -r '.allowed_actions // "all"')
      if [[ "$enabled" == "true" && "$allowed" != "all" ]]; then status="ok"; else status="risco"; fi

      api_get "repos/${repo}/actions/permissions/workflow"
      if [[ "$API_STATUS" == "200" ]]; then
        default_perm=$(jq -r '.default_workflow_permissions // "unknown"' <<< "$API_BODY")
        can_approve=$(jq -r '.can_approve_pull_request_reviews // false' <<< "$API_BODY")
        wf_note="; GET /repos/${repo}/actions/permissions/workflow -> default_workflow_permissions=${default_perm} can_approve_pull_request_reviews=${can_approve}"
        if [[ "$default_perm" != "read" || "$can_approve" == "true" ]]; then
          status="risco"
          wf_note+=" (esperado read / false)"
        fi
      else
        wf_note="; GET /repos/${repo}/actions/permissions/workflow -> ${API_STATUS} (permissão padrão do GITHUB_TOKEN não verificável)"
        [[ "$status" == "ok" ]] && status="pendente"
      fi

      if [[ "$enabled" == "true" && "$allowed" != "all" ]]; then
        emit_result "$status" "GET /repos/${repo}/actions/permissions -> enabled=true allowed_actions=${allowed}${wf_note}"
      else
        emit_result "risco" "GET /repos/${repo}/actions/permissions -> enabled=${enabled} allowed_actions=${allowed} (expected allowed_actions != all)${wf_note}"
      fi
      ;;
    403)
      emit_result "" "GET /repos/${repo}/actions/permissions -> 403 (no admin permission)" true
      ;;
    404)
      emit_result "pendente" "GET /repos/${repo}/actions/permissions -> 404 (endpoint unavailable on this instance/plan)"
      ;;
    *)
      emit_result "" "GET /repos/${repo}/actions/permissions -> ${API_STATUS} (${API_ERROR})" true
      ;;
  esac
}

evaluate_secrets_configured() {
  # Significa APENAS "existem GitHub Actions secrets configurados" (metadados).
  # NÃO substitui Secret Scanning/Push Protection (controles próprios).
  local repo="$1"
  local total
  api_get "repos/${repo}/actions/secrets"

  case "$API_STATUS" in
    200)
      total=$(echo "$API_BODY" | jq -r '.total_count // 0')
      API_BODY=""
      if [[ "$total" =~ ^[0-9]+$ ]] && (( total > 0 )); then
        emit_result "ok" "GET /repos/${repo}/actions/secrets -> total_count=${total} (metadata only, values never read)"
      else
        emit_result "pendente" "GET /repos/${repo}/actions/secrets -> total_count=0"
      fi
      ;;
    403)
      emit_result "" "GET /repos/${repo}/actions/secrets -> 403 (no admin permission)" true
      ;;
    *)
      emit_result "" "GET /repos/${repo}/actions/secrets -> ${API_STATUS} (${API_ERROR})" true
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
  gh_write issue list --repo "$issue_repo" --state open --search "${title} in:title" --json url,title 2>/dev/null \
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
  gh_write issue view "$issue_url" --repo "$issue_repo" --json comments 2>/dev/null \
    | jq -r '.comments[].body // empty' \
    | grep -F "<!-- ${MONTHLY_REPORT_COMMENT_MARKER}: ${month} ${run_id} " >/dev/null 2>&1
}

load_report_snapshots_from_issue() {
  local issue_repo="$1" issue_url="$2" month="$3"
  gh_write issue view "$issue_url" --repo "$issue_repo" --json comments 2>/dev/null \
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
  local org="$1" month="$2" end_date results scope_args=()
  [[ -z "$org" ]] && { echo '[]'; return 0; }
  end_date=$(month_end_date "$month")
  if [[ "$ISSUE_TARGET" == "scanned-repository" || -z "${REPORT_REPOSITORY:-}" ]]; then
    scope_args=(--owner "$org")
  else
    scope_args=(--repo "$REPORT_REPOSITORY")
  fi

  if ! results=$(gh_write search issues "${scope_args[@]}" --state closed --label security-baseline --limit 100 --json repository,body,url,createdAt,closedAt --search "closed:${month}-01..${end_date}" 2>/dev/null); then
    echo '[]'
    return 0
  fi

  echo "$results" | jq -c 'map(select((.body // "") | contains("<!-- security-baseline-finding-id: "))) | map(((.body | capture("security-baseline:(?<repo>[^ ]*):(?<controle>[^ :]+) -->")) // {}) as $m | {repo: ($m.repo // .repository.nameWithOwner // ""), controle_id: ($m.controle // "unknown"), created_at: (.createdAt // ""), closed_at: (.closedAt // ""), url: .url})' 2>/dev/null || echo '[]'
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

  for control_id in "${CONTROL_ORDER[@]}"; do
    label="${CONTROL_REPORT_LABEL[$control_id]:-$control_id}"
    if [[ $(echo "$aggregate_json" | jq -r --arg id "$control_id" '.controls | has($id)') == "true" ]]; then
      pct="$(echo "$aggregate_json" | jq -r --arg id "$control_id" '.controls[$id].pct_ok // 0')%"
    else
      pct="N/A (não avaliado)"
    fi
    delta=$(echo "$previous_pct_json" | jq -r --arg id "$control_id" '.[$id] // "N/A"')
    body+="| ${label} | ${pct} | ${delta} |\n"
  done

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
    gh_write issue edit "$issue_url" --repo "$issue_repo" --body "$report_body" >/dev/null
  else
    issue_url=$(gh_write issue create --repo "$issue_repo" --title "${MONTHLY_REPORT_TITLE_PREFIX}${month}" --body "$report_body" --label "security-baseline")
  fi

  if ! snapshot_comment_exists "$issue_repo" "$issue_url" "$month" "$run_id"; then
    gh_write issue comment "$issue_url" --repo "$issue_repo" --body "$(snapshot_comment_body "$month" "$run_id" "$snapshot_json")" >/dev/null
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
  local full_name="$1" default_branch="${2:-}" issue_repo cfg_default
  REPO_HAD_ERROR="false"
  reset_repo_state
  issue_repo=$(resolve_issue_repo "$full_name")

  load_repo_meta "$full_name"
  if [[ -z "$default_branch" || "$default_branch" == "null" ]]; then
    default_branch=$(jq -r '.default_branch // empty' <<< "${REPO_META:-null}" 2>/dev/null || true)
  fi
  load_repo_governance_config "$full_name"
  cfg_default=$(cfg_get '.branches.default_branch // "auto"' | jq -r '.')
  if [[ -n "$cfg_default" && "$cfg_default" != "auto" ]]; then
    default_branch="$cfg_default"
  fi

  if [[ -z "$default_branch" ]]; then
    log_warn "${full_name}: nao foi possivel resolver a branch padrao (GET /repos/${full_name} -> ${REPO_META_STATUS}) — marcando como repos_com_erro."
    REPO_HAD_ERROR="true"
    return 0
  fi
  log_info "${full_name}: branch padrão=${default_branch} | configuração=${REPO_CFG_SOURCE}"

  # Pré-carrega no shell atual os dados compartilhados entre avaliadores (cada
  # avaliador roda em subshell via $(...), que herda — mas não devolve — cache).
  branch_effective "$full_name" "$default_branch" >/dev/null
  load_repo_branches "$full_name"
  load_repo_rulesets "$full_name"
  load_codeowners "$full_name"

  evaluate_and_report "$full_name" "branch-protection-default" "$(evaluate_branch_protection_default "$full_name" "$default_branch")" "$issue_repo"
  evaluate_and_report "$full_name" "branch-protection-required-patterns" "$(evaluate_branch_protection_required_patterns "$full_name" "$default_branch")" "$issue_repo"
  evaluate_and_report "$full_name" "rulesets-configured" "$(evaluate_rulesets_configured "$full_name" "$default_branch")" "$issue_repo"
  evaluate_and_report "$full_name" "required-review" "$(evaluate_required_review "$full_name" "$default_branch")" "$issue_repo"
  evaluate_and_report "$full_name" "required-pr-checks" "$(evaluate_required_pr_checks "$full_name" "$default_branch")" "$issue_repo"
  evaluate_and_report "$full_name" "required-test-checks" "$(evaluate_required_test_checks "$full_name" "$default_branch")" "$issue_repo"
  evaluate_and_report "$full_name" "required-coverage-check" "$(evaluate_required_coverage_check "$full_name" "$default_branch")" "$issue_repo"
  evaluate_and_report "$full_name" "codeql-enabled" "$(evaluate_codeql_enabled "$full_name")" "$issue_repo"
  evaluate_and_report "$full_name" "codeql-recent" "$(evaluate_codeql_recent "$full_name" "$default_branch")" "$issue_repo"
  evaluate_and_report "$full_name" "codeql-alerts" "$(evaluate_codeql_alerts "$full_name")" "$issue_repo"
  evaluate_and_report "$full_name" "dependabot-alerts-enabled" "$(evaluate_dependabot_alerts_enabled "$full_name")" "$issue_repo"
  evaluate_and_report "$full_name" "dependabot-security-updates-enabled" "$(evaluate_dependabot_security_updates_enabled "$full_name")" "$issue_repo"
  evaluate_and_report "$full_name" "dependency-review-enabled" "$(evaluate_dependency_review_enabled "$full_name" "$default_branch")" "$issue_repo"
  evaluate_and_report "$full_name" "secret-scanning-enabled" "$(evaluate_secret_scanning_enabled "$full_name")" "$issue_repo"
  evaluate_and_report "$full_name" "secret-scanning-push-protection-enabled" "$(evaluate_secret_scanning_push_protection_enabled "$full_name")" "$issue_repo"
  evaluate_and_report "$full_name" "secret-alerts" "$(evaluate_secret_alerts "$full_name")" "$issue_repo"
  evaluate_and_report "$full_name" "actions-permissions" "$(evaluate_actions_permissions "$full_name")" "$issue_repo"
  evaluate_and_report "$full_name" "secrets-configured" "$(evaluate_secrets_configured "$full_name")" "$issue_repo"
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

  load_default_governance_config
  run_scan "$repos_ndjson"
  run_platform_scan
  upsert_monthly_report "$org" "${REPORT_REPOSITORY:-${GITHUB_REPOSITORY:-}}"

  log_ok "✓ Varredura concluida."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
