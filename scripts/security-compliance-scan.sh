#!/usr/bin/env bash

###############################################################################
# security-compliance-scan.sh
#
# Varredura semanal de conformidade de segurança no GHE, para repositórios de
# projeto e para o Projeto Plataforma (Project V2 consolidado). Detecta e
# reporta (NUNCA corrige automaticamente) desvios dos controles obrigatórios
# documentados em docs/security-baseline-ghe.md.
#
# Feature: specs/007-controle-seguranca-ghe-projetos-plataforma/
# Contratos: specs/007-controle-seguranca-ghe-projetos-plataforma/contracts/
#
# Escopo desta versão (MVP — Setup + Foundational + User Story 1):
#   - Autenticação via GitHub App dedicado (JWT + installation access token).
#   - Descoberta paginada de repositórios (piloto ou org-wide).
#   - 4 avaliadores de controle de repositório: branch-protection,
#     required-review, actions-permissions, secrets-configured.
#   - Criação/atualização idempotente de Issue de não conformidade por finding.
# Fora do escopo desta versão (US2/US3 — sessões futuras): avaliador da matriz
# de permissões do Project V2 (plataforma) e agregação do relatório mensal.
#
# Uso:
#   ./security-compliance-scan.sh [--dry-run] [--scope=pilot|org-wide] [--org NAME]
#
# Exemplos:
#   ./security-compliance-scan.sh --dry-run --scope=pilot
#   ./security-compliance-scan.sh --scope=org-wide
#
# Variáveis de ambiente:
#   - GH_HOST (padrão: venha-pra-nuvem.ghe.com)
#   - GITHUB_REPOSITORY (org/repo, usada para resolver a organização-alvo)
#   - SECURITY_SCAN_APP_ID / SECURITY_SCAN_APP_PRIVATE_KEY /
#     SECURITY_SCAN_APP_INSTALLATION_ID: credenciais do GitHub App dedicado
#     (ver ADR-0008). OBRIGATÓRIAS — o script falha explicitamente
#     (`::error::`) se qualquer uma estiver ausente, sem simular autenticação.
#   - SECURITY_BASELINE_SCAN_ORG_WIDE_ENABLED: override do flag (provider env,
#     abstração OpenFeature) — "true"/"false". `--scope` tem precedência sobre
#     o flag quando informado explicitamente.
#   - SECURITY_SCAN_FLAG_FILE: caminho alternativo para o provider de flag
#     baseado em arquivo (padrão: .github/feature-flags/security-baseline-scan.json)
#
# Este script é SOMENTE LEITURA + RELATÓRIO: nunca aplica/corrige configuração
# nos repositórios avaliados (decisão de clarificação registrada no spec.md).
###############################################################################

set -euo pipefail

# Cores para output (mesmo padrão de scripts/setup-github-project.sh)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ---------------------------------------------------------------------------
# Configuração / constantes
# ---------------------------------------------------------------------------
GH_HOST="${GH_HOST:-venha-pra-nuvem.ghe.com}"
export GH_HOST

PILOT_BOUNDED_CONTEXT="spec-kit-workflow"
BOUNDED_CONTEXTS_FILE="${BOUNDED_CONTEXTS_FILE:-docs/bounded-contexts.yaml}"
FEATURE_FLAG_KEY="security.baseline_scan.org_wide_enabled"
FEATURE_FLAG_FILE="${SECURITY_SCAN_FLAG_FILE:-.github/feature-flags/security-baseline-scan.json}"
DOC_REFERENCE_PATH="docs/security-baseline-ghe.md"

# Metadados dos controles de segurança avaliados nesta versão (User Story 1).
# `bloqueante=true` eleva não conformidade a "risco"; caso contrário, "pendente"
# (regra de validação de data-model.md).
declare -A CONTROL_NAME=(
  [branch-protection]="Proteção de branch"
  [required-review]="Revisão obrigatória de Pull Request"
  [actions-permissions]="Permissões de GitHub Actions"
  [secrets-configured]="Secrets configurados via GitHub Secrets"
)
declare -A CONTROL_BLOQUEANTE=(
  [branch-protection]="true"
  [required-review]="true"
  [actions-permissions]="true"
  [secrets-configured]="false"
)
declare -A CONTROL_REMEDIATION=(
  [branch-protection]="Configure a proteção da branch padrão em Settings → Branches → Add branch protection rule: exigir Pull Request antes de merge, exigir status checks e bloquear force-push/deleção. Ver seção 1 de docs/security-baseline-ghe.md."
  [required-review]="Na regra de proteção da branch padrão, habilite 'Require a pull request before merging' com pelo menos 1 aprovador (idealmente reforçado por CODEOWNERS). Ver seção 1 de docs/security-baseline-ghe.md."
  [actions-permissions]="Em Settings → Actions → General → Workflow permissions, restrinja 'Allowed actions' para 'Selected actions' (nunca usar 'All actions'). Ver seção 1 de docs/security-baseline-ghe.md."
  [secrets-configured]="Configure os secrets necessários pelos workflows deste repositório em Settings → Secrets and variables → Actions — nunca hardcode credenciais no código. Ver seção 4 de docs/security-baseline-ghe.md."
)

# Estado global preenchido pelas funções auxiliares (bash não tem retorno
# múltiplo nativo sem output em stdout — usado só para os detalhes de API/erro
# que não fazem parte do payload JSON retornado pelas funções).
API_STATUS=""
API_BODY=""
API_ERROR=""
REPO_HAD_ERROR="false"

DRY_RUN="false"
SCOPE_ARG=""
ORG_ARG=""

# ---------------------------------------------------------------------------
# Utilitários de log (compatíveis com anotações do GitHub Actions)
# ---------------------------------------------------------------------------
# IMPORTANTE: todas as funções de log escrevem em stderr, nunca em stdout —
# várias funções do script (ex.: discover_org_repositories, os avaliadores de
# controle) retornam dados (NDJSON) via stdout capturado por `$(...)` no
# chamador; misturar log ali corromperia o payload retornado.
log_notice() { echo -e "::notice::$*" >&2; }
log_warn() { echo -e "::warning::$*" >&2; }
log_error() { echo -e "::error::$*" >&2; }
log_info() { echo -e "${BLUE}$*${NC}" >&2; }
log_ok() { echo -e "${GREEN}$*${NC}" >&2; }

usage() {
  cat <<EOF
Uso: $(basename "$0") [--dry-run] [--scope=pilot|org-wide] [--org NAME]

  --dry-run              Roda a varredura sem criar/atualizar issues (modo log-only)
  --scope=pilot|org-wide  Força o escopo da varredura (ignora resolução do flag)
  --org NAME              Organização alvo (padrão: owner de GITHUB_REPOSITORY)
  -h, --help              Mostra esta ajuda
EOF
}

# ---------------------------------------------------------------------------
# Parsing de argumentos
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# Autenticação via GitHub App (JWT + installation access token)
# ---------------------------------------------------------------------------
check_required_secrets() {
  local missing=()
  [[ -z "${SECURITY_SCAN_APP_ID:-}" ]] && missing+=("SECURITY_SCAN_APP_ID")
  [[ -z "${SECURITY_SCAN_APP_PRIVATE_KEY:-}" ]] && missing+=("SECURITY_SCAN_APP_PRIVATE_KEY")
  [[ -z "${SECURITY_SCAN_APP_INSTALLATION_ID:-}" ]] && missing+=("SECURITY_SCAN_APP_INSTALLATION_ID")

  if (( ${#missing[@]} > 0 )); then
    log_error "Secrets obrigatórios ausentes: ${missing[*]}. O GitHub App \"Nimbus Code Security Auditor\" precisa existir e estar instalado na organização (task T004, manual — ver ADR-0008 e quickstart.md) antes de configurar estes secrets em Settings → Secrets and variables → Actions. Este script NÃO simula autenticação — a execução é interrompida."
    exit 1
  fi
}

base64_url_encode() {
  # -w0 é GNU coreutils (ubuntu-latest); ambientes sem suporte devem usar `tr` p/ remover quebras.
  base64 -w0 2>/dev/null || base64 | tr -d '\n'
}

generate_app_jwt() {
  local app_id="$1" pem_file="$2"
  local now iat exp header payload header_b64 payload_b64 signing_input signature

  now=$(date +%s)
  iat=$((now - 60))
  exp=$((now + 540)) # máximo permitido pela API do GitHub é 10 min; usamos 9 min de folga
  header='{"alg":"RS256","typ":"JWT"}'
  payload=$(printf '{"iat":%s,"exp":%s,"iss":"%s"}' "$iat" "$exp" "$app_id")

  header_b64=$(printf '%s' "$header" | base64_url_encode | tr '+/' '-_' | tr -d '=')
  payload_b64=$(printf '%s' "$payload" | base64_url_encode | tr '+/' '-_' | tr -d '=')
  signing_input="${header_b64}.${payload_b64}"
  signature=$(printf '%s' "$signing_input" | openssl dgst -sha256 -sign "$pem_file" -binary | base64_url_encode | tr '+/' '-_' | tr -d '=')

  printf '%s.%s' "$signing_input" "$signature"
}

authenticate_github_app() {
  check_required_secrets

  local pem_file jwt token auth_err_file
  pem_file=$(mktemp)
  auth_err_file=$(mktemp)
  # Chave privada nunca é logada nem escrita fora de um arquivo temporário com
  # permissão restrita, removido logo após o uso.
  printf '%s\n' "$SECURITY_SCAN_APP_PRIVATE_KEY" > "$pem_file"
  chmod 600 "$pem_file"

  jwt=$(generate_app_jwt "$SECURITY_SCAN_APP_ID" "$pem_file")

  if token=$(gh api \
    -X POST \
    -H "Authorization: Bearer ${jwt}" \
    -H "Accept: application/vnd.github+json" \
    "app/installations/${SECURITY_SCAN_APP_INSTALLATION_ID}/access_tokens" \
    --jq '.token' 2>"$auth_err_file"); then
    :
  else
    log_error "Falha ao gerar installation access token do GitHub App: $(cat "$auth_err_file" 2>/dev/null). Verifique SECURITY_SCAN_APP_ID, SECURITY_SCAN_APP_PRIVATE_KEY e SECURITY_SCAN_APP_INSTALLATION_ID (ver ADR-0008)."
    rm -f "$pem_file" "$auth_err_file"
    exit 1
  fi

  rm -f "$pem_file" "$auth_err_file"

  if [[ -z "$token" || "$token" == "null" ]]; then
    log_error "Installation access token vazio — verifique se o GitHub App está instalado na organização e se o Installation ID está correto."
    exit 1
  fi

  export GH_TOKEN="$token"
  log_ok "✓ Autenticado via GitHub App (installation access token de curta duração)."
}

# ---------------------------------------------------------------------------
# Resolução de flag (abstração OpenFeature — provider env > provider arquivo > default)
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# Descoberta de repositórios (paginada, com backoff exponencial em rate limit)
# ---------------------------------------------------------------------------
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
with open(path, encoding="utf-8") as fh:
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

  err_tmp=$(mktemp)
  while :; do
    if response=$(gh api --paginate "orgs/${org}/repos" --jq '.[] | {full_name, default_branch, visibility}' 2>"$err_tmp"); then
      rm -f "$err_tmp"
      printf '%s\n' "$response"
      return 0
    fi

    status=$(grep -oE 'HTTP [0-9]{3}' "$err_tmp" | grep -oE '[0-9]{3}' | tail -1 || true)
    if [[ "$status" == "403" || "$status" == "429" ]]; then
      attempt=$((attempt + 1))
      if (( attempt > max_attempts )); then
        log_error "Rate limit persistente ao descobrir repositórios da organização '${org}' após ${max_attempts} tentativas; abortando descoberta."
        rm -f "$err_tmp"
        return 1
      fi
      wait_s=$(( 2 ** attempt ))
      log_warn "Rate limit (HTTP ${status}) ao listar repositórios da organização — aguardando ${wait_s}s antes de tentar novamente (tentativa ${attempt}/${max_attempts})."
      sleep "$wait_s"
      continue
    fi

    log_error "Falha ao descobrir repositórios da organização '${org}': $(cat "$err_tmp" 2>/dev/null)"
    rm -f "$err_tmp"
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

# ---------------------------------------------------------------------------
# Compliance Finding: construção do payload e criação/atualização idempotente
# de Issue (dedup por marcador `<!-- security-baseline-finding-id -->`,
# reaproveitando o padrão speckit-deduplication-by-id — docs/reuse-catalog.yaml)
# ---------------------------------------------------------------------------
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

find_existing_issue_url() {
  local repo="$1" finding_id="$2"
  local marker="<!-- security-baseline-finding-id: ${finding_id} -->"
  gh issue list --repo "$repo" --state open --search "${finding_id} in:body" --json url,body 2>/dev/null \
    | jq -r --arg marker "$marker" '.[] | select((.body // "") | contains($marker)) | .url' \
    | head -n1
}

create_or_update_issue() {
  local repo="$1" control_id="$2" status="$3" evidencia="$4" finding_id="$5"
  local control_name bloqueante priority remediation marker title body existing_url detected_at doc_link

  control_name="${CONTROL_NAME[$control_id]}"
  bloqueante="${CONTROL_BLOQUEANTE[$control_id]}"
  remediation="${CONTROL_REMEDIATION[$control_id]}"
  detected_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  doc_link="https://${GH_HOST}/${repo%%/*}/nimbus-code-spec-kit-template/blob/main/${DOC_REFERENCE_PATH}"

  if [[ "$bloqueante" == "true" ]]; then
    priority="priority:P0-blocker"
  else
    priority="priority:P2-medium"
  fi

  marker="<!-- security-baseline-finding-id: ${finding_id} -->"
  title="🔴 Não conformidade de segurança — ${control_name} (${repo})"
  body=$(cat <<ISSUE_BODY
## 🔴 Não conformidade de segurança — ${control_name}

**Repositório**: ${repo}
**Controle**: ${control_id} — ${control_name}
**Status**: ${status}
**Detectado em**: ${detected_at}
**Evidência**: ${evidencia}

${marker}

### O que fazer

${remediation}

### Critério de validação da correção

A próxima execução semanal da varredura (\`security-compliance-scan.yml\`) deve
reportar \`status: ok\` para este controle neste repositório. Esta issue será
fechada automaticamente quando isso ocorrer (ou deve ser fechada manualmente
após validação).

---
_Gerado automaticamente pela varredura semanal de conformidade de segurança —
ver [docs/security-baseline-ghe.md](${doc_link})._
ISSUE_BODY
)

  existing_url=$(find_existing_issue_url "$repo" "$finding_id" || true)

  if [[ "$DRY_RUN" == "true" ]]; then
    log_notice "[dry-run] Issue seria criada/atualizada para '${finding_id}' (status=${status}) — nenhuma escrita realizada."
    echo "${existing_url:-}"
    return 0
  fi

  ensure_label "$repo" "security-baseline" "b60205" "Não conformidade detectada pela varredura automatizada de segurança (feature 007)"
  ensure_label "$repo" "$priority" "fbca04" "Prioridade aplicada automaticamente pela varredura de conformidade de segurança"

  if [[ -n "$existing_url" ]]; then
    gh issue edit "$existing_url" --repo "$repo" --body "$body" >/dev/null
    echo "$existing_url"
  else
    gh issue create --repo "$repo" --title "$title" --body "$body" \
      --label "security-baseline" --label "$priority"
  fi
}

# ---------------------------------------------------------------------------
# Wrapper de chamada de API (captura status HTTP a partir da saída do `gh`)
# ---------------------------------------------------------------------------
api_get() {
  local path="$1"
  local out_tmp err_tmp
  out_tmp=$(mktemp)
  err_tmp=$(mktemp)

  if gh api "$path" >"$out_tmp" 2>"$err_tmp"; then
    API_STATUS="200"
  else
    API_STATUS=$(grep -oE 'HTTP [0-9]{3}' "$err_tmp" | grep -oE '[0-9]{3}' | tail -1 || true)
    API_STATUS="${API_STATUS:-000}"
  fi
  API_BODY=$(cat "$out_tmp")
  API_ERROR=$(cat "$err_tmp")
  rm -f "$out_tmp" "$err_tmp"
}

# ---------------------------------------------------------------------------
# Avaliadores de controle — User Story 1
#
# Cada avaliador imprime em stdout um JSON `{status, evidencia, erro}`:
#   - status: "ok" | "pendente" | "risco" | null (null quando erro=true)
#   - evidencia: texto suficiente para validação humana sem re-executar a consulta
#   - erro: true quando a API indicou falta de permissão administrativa (edge
#     case "repositório sem permissões administrativas" — não gera finding,
#     apenas contabiliza repos_com_erro no chamador)
# ---------------------------------------------------------------------------
evaluate_branch_protection() {
  local repo="$1" branch="$2"
  api_get "repos/${repo}/branches/${branch}/protection"

  case "$API_STATUS" in
    200)
      jq -n --arg ev "GET /repos/${repo}/branches/${branch}/protection -> 200 (branch protection configurada)" \
        '{status:"ok", evidencia:$ev, erro:false}'
      ;;
    404)
      jq -n --arg ev "GET /repos/${repo}/branches/${branch}/protection -> 404 (não configurado)" \
        '{status:"risco", evidencia:$ev, erro:false}'
      ;;
    403)
      jq -n --arg ev "GET /repos/${repo}/branches/${branch}/protection -> 403 (sem permissão administrativa para ler proteção de branch)" \
        '{status:null, evidencia:$ev, erro:true}'
      ;;
    *)
      jq -n --arg ev "GET /repos/${repo}/branches/${branch}/protection -> ${API_STATUS} (${API_ERROR})" \
        '{status:null, evidencia:$ev, erro:true}'
      ;;
  esac
}

evaluate_required_review() {
  local repo="$1" branch="$2"
  api_get "repos/${repo}/branches/${branch}/protection"

  case "$API_STATUS" in
    200)
      local count
      count=$(echo "$API_BODY" | jq -r '.required_pull_request_reviews.required_approving_review_count // 0')
      if [[ "$count" =~ ^[0-9]+$ ]] && (( count >= 1 )); then
        jq -n --arg ev "GET /repos/${repo}/branches/${branch}/protection -> required_approving_review_count=${count} (>=1)" \
          '{status:"ok", evidencia:$ev, erro:false}'
      else
        jq -n --arg ev "GET /repos/${repo}/branches/${branch}/protection -> required_pull_request_reviews ausente ou required_approving_review_count=0" \
          '{status:"risco", evidencia:$ev, erro:false}'
      fi
      ;;
    404)
      jq -n --arg ev "GET /repos/${repo}/branches/${branch}/protection -> 404 (sem branch protection, revisão obrigatória não pode estar configurada)" \
        '{status:"risco", evidencia:$ev, erro:false}'
      ;;
    403)
      jq -n --arg ev "GET /repos/${repo}/branches/${branch}/protection -> 403 (sem permissão administrativa)" \
        '{status:null, evidencia:$ev, erro:true}'
      ;;
    *)
      jq -n --arg ev "GET /repos/${repo}/branches/${branch}/protection -> ${API_STATUS} (${API_ERROR})" \
        '{status:null, evidencia:$ev, erro:true}'
      ;;
  esac
}

evaluate_actions_permissions() {
  local repo="$1"
  api_get "repos/${repo}/actions/permissions"

  case "$API_STATUS" in
    200)
      local enabled allowed
      enabled=$(echo "$API_BODY" | jq -r '.enabled // false')
      allowed=$(echo "$API_BODY" | jq -r '.allowed_actions // "all"')
      if [[ "$enabled" == "true" && "$allowed" != "all" ]]; then
        jq -n --arg ev "GET /repos/${repo}/actions/permissions -> enabled=true allowed_actions=${allowed} (least privilege)" \
          '{status:"ok", evidencia:$ev, erro:false}'
      else
        jq -n --arg ev "GET /repos/${repo}/actions/permissions -> enabled=${enabled} allowed_actions=${allowed} (esperado allowed_actions != 'all')" \
          '{status:"risco", evidencia:$ev, erro:false}'
      fi
      ;;
    403)
      jq -n --arg ev "GET /repos/${repo}/actions/permissions -> 403 (sem permissão administrativa)" \
        '{status:null, evidencia:$ev, erro:true}'
      ;;
    404)
      jq -n --arg ev "GET /repos/${repo}/actions/permissions -> 404 (endpoint indisponível nesta instância/plano)" \
        '{status:"pendente", evidencia:$ev, erro:false}'
      ;;
    *)
      jq -n --arg ev "GET /repos/${repo}/actions/permissions -> ${API_STATUS} (${API_ERROR})" \
        '{status:null, evidencia:$ev, erro:true}'
      ;;
  esac
}

evaluate_secrets_configured() {
  local repo="$1"
  api_get "repos/${repo}/actions/secrets"

  case "$API_STATUS" in
    200)
      local total
      total=$(echo "$API_BODY" | jq -r '.total_count // 0')
      if [[ "$total" =~ ^[0-9]+$ ]] && (( total > 0 )); then
        jq -n --arg ev "GET /repos/${repo}/actions/secrets -> total_count=${total} (secrets geridos via GitHub Secrets; valores nunca lidos)" \
          '{status:"ok", evidencia:$ev, erro:false}'
      else
        jq -n --arg ev "GET /repos/${repo}/actions/secrets -> total_count=0 (nenhum secret configurado via GitHub Secrets)" \
          '{status:"pendente", evidencia:$ev, erro:false}'
      fi
      ;;
    403)
      jq -n --arg ev "GET /repos/${repo}/actions/secrets -> 403 (sem permissão administrativa)" \
        '{status:null, evidencia:$ev, erro:true}'
      ;;
    *)
      jq -n --arg ev "GET /repos/${repo}/actions/secrets -> ${API_STATUS} (${API_ERROR})" \
        '{status:null, evidencia:$ev, erro:true}'
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Integração dos avaliadores ao loop principal (T018)
# ---------------------------------------------------------------------------
evaluate_and_report() {
  local repo="$1" control_id="$2" eval_json="$3"
  local status evidencia erro finding_id issue_url

  status=$(echo "$eval_json" | jq -r '.status')
  evidencia=$(echo "$eval_json" | jq -r '.evidencia')
  erro=$(echo "$eval_json" | jq -r '.erro')

  if [[ "$erro" == "true" ]]; then
    log_warn "${repo}: erro ao avaliar '${control_id}' — ${evidencia}"
    REPO_HAD_ERROR="true"
    return 0
  fi

  log_notice "${repo}: controle '${control_id}' => ${status}"

  if [[ "$status" != "ok" ]]; then
    finding_id="security-baseline:${repo}:${control_id}"
    issue_url=$(create_or_update_issue "$repo" "$control_id" "$status" "$evidencia" "$finding_id")
    log_notice "${repo}: issue de não conformidade (${control_id}) -> ${issue_url:-<dry-run: sem URL>}"
  fi
}

scan_single_repo() {
  local full_name="$1" default_branch="${2:-}"
  REPO_HAD_ERROR="false"

  if [[ -z "$default_branch" || "$default_branch" == "null" ]]; then
    default_branch=$(gh api "repos/${full_name}" --jq '.default_branch' 2>/dev/null || true)
  fi

  if [[ -z "$default_branch" ]]; then
    # Edge case do spec.md: "Repositório sem permissões administrativas para
    # aplicar branch protection no momento da auditoria" — marca repos_com_erro
    # e NÃO falha a execução inteira.
    log_warn "${full_name}: não foi possível resolver a branch padrão — marcando como repos_com_erro (sem acesso administrativo suficiente)."
    REPO_HAD_ERROR="true"
    return 0
  fi

  evaluate_and_report "$full_name" "branch-protection" "$(evaluate_branch_protection "$full_name" "$default_branch")"
  evaluate_and_report "$full_name" "required-review" "$(evaluate_required_review "$full_name" "$default_branch")"
  evaluate_and_report "$full_name" "actions-permissions" "$(evaluate_actions_permissions "$full_name")"
  evaluate_and_report "$full_name" "secrets-configured" "$(evaluate_secrets_configured "$full_name")"
}

run_scan() {
  local repos_ndjson="$1"
  local repos_avaliados=0 repos_com_erro=0
  local full_name default_branch

  if [[ -z "$repos_ndjson" ]]; then
    log_warn "Nenhum repositório retornado pela descoberta — nada a varrer neste escopo."
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

  log_notice "Scan Run concluído: repos_avaliados=${repos_avaliados} repos_com_erro=${repos_com_erro}"

  if (( repos_avaliados > 0 )); then
    if awk -v erro="$repos_com_erro" -v total="$repos_avaliados" 'BEGIN { exit !(erro/total > 0.05) }'; then
      log_warn "Taxa de repos_com_erro (${repos_com_erro}/${repos_avaliados}) acima do SLO de 5% — revisar permissões do GitHub App 'Nimbus Code Security Auditor' (não bloqueia a execução, ver plan.md SLO Gate)."
    fi
  fi
}

# ---------------------------------------------------------------------------
# Orquestração principal
# ---------------------------------------------------------------------------
resolve_org() {
  if [[ -n "$ORG_ARG" ]]; then
    echo "$ORG_ARG"
    return 0
  fi
  if [[ -n "${GITHUB_REPOSITORY:-}" ]]; then
    echo "${GITHUB_REPOSITORY%/*}"
    return 0
  fi
  log_error "Não foi possível resolver a organização alvo. Informe --org NAME ou configure GITHUB_REPOSITORY."
  exit 1
}

main() {
  parse_args "$@"

  log_info "═══════════════════════════════════════════════════════════════"
  log_info "Varredura de Conformidade de Segurança — Nimbus Code"
  log_info "═══════════════════════════════════════════════════════════════"

  authenticate_github_app

  local org scope repos_ndjson
  org=$(resolve_org)
  scope=$(resolve_scope)

  log_notice "Organização: ${org} | Escopo resolvido: ${scope} | dry-run: ${DRY_RUN} (flag ${FEATURE_FLAG_KEY})"

  repos_ndjson=$(discover_repositories "$scope" "$org") || {
    log_error "Descoberta de repositórios falhou — abortando execução."
    exit 1
  }

  run_scan "$repos_ndjson"

  log_ok "✓ Varredura concluída."
}

# Guarda de entry-point: permite `source` deste arquivo em testes (ex.:
# tests/scripts/security-compliance-scan.detect.test.sh) sem disparar main().
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
