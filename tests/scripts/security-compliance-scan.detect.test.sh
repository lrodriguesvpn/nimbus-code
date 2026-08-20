#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# tests/scripts/security-compliance-scan.detect.test.sh
#
# Teste de integração (T012, User Story 1, AC-2): valida a detecção dos 4
# avaliadores de controle implementados em scripts/security-compliance-scan.sh
# (branch-protection, required-review, actions-permissions,
# secrets-configured) contra repositórios FIXTURE — nunca chamadas reais à
# API do GitHub nem credenciais.
#
# Estratégia: sobrepõe `gh` com uma função bash que responde com JSON fixture
# fixo para cada `gh api <path>` esperado, depois carrega (`source`) o script
# real (a guarda de entry-point em security-compliance-scan.sh impede que
# `main()` seja executado ao ser importado) e chama as funções avaliadoras
# diretamente.
#
# Uso: bash tests/scripts/security-compliance-scan.detect.test.sh
###############################################################################

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_PATH="${ROOT_DIR}/scripts/security-compliance-scan.sh"

if [[ ! -f "$SCRIPT_PATH" ]]; then
  echo "✗ ${SCRIPT_PATH} não encontrado"
  exit 1
fi

# --- Mock do `gh` CLI --------------------------------------------------------
# Intercepta `gh api <path>` e responde com fixtures em memória, simulando
# respostas reais da API REST do GitHub (200/403/404) sem tocar a rede.
gh() {
  if [[ "${1:-}" != "api" ]]; then
    echo "mock gh: subcomando não suportado neste teste: ${1:-}" >&2
    return 1
  fi
  shift
  local path="$1"
  case "$path" in
    "repos/org/repo-conforme/branches/main/protection")
      cat <<'JSON'
{"required_pull_request_reviews":{"required_approving_review_count":2},"required_status_checks":{"strict":true}}
JSON
      return 0
      ;;
    "repos/org/repo-sem-protecao/branches/main/protection")
      echo "gh: Not Found (HTTP 404)" >&2
      return 1
      ;;
    "repos/org/repo-revisao-zero/branches/main/protection")
      cat <<'JSON'
{"required_pull_request_reviews":{"required_approving_review_count":0}}
JSON
      return 0
      ;;
    "repos/org/repo-sem-admin/branches/main/protection" | \
    "repos/org/repo-sem-admin/actions/permissions" | \
    "repos/org/repo-sem-admin/actions/secrets")
      echo "gh: Forbidden (HTTP 403)" >&2
      return 1
      ;;
    "repos/org/repo-conforme/actions/permissions")
      cat <<'JSON'
{"enabled":true,"allowed_actions":"selected"}
JSON
      return 0
      ;;
    "repos/org/repo-actions-liberado/actions/permissions")
      cat <<'JSON'
{"enabled":true,"allowed_actions":"all"}
JSON
      return 0
      ;;
    "repos/org/repo-conforme/actions/secrets")
      cat <<'JSON'
{"total_count":3,"secrets":[{"name":"NPM_TOKEN"},{"name":"DEPLOY_KEY"},{"name":"SLACK_WEBHOOK"}]}
JSON
      return 0
      ;;
    "repos/org/repo-sem-secrets/actions/secrets")
      cat <<'JSON'
{"total_count":0,"secrets":[]}
JSON
      return 0
      ;;
    *)
      echo "mock gh: fixture não definida para path: ${path}" >&2
      return 1
      ;;
  esac
}
export -f gh

# shellcheck disable=SC1090
source "$SCRIPT_PATH"

pass=0
fail=0

check_status() {
  local description="$1" expected="$2" actual_json="$3"
  local actual
  actual=$(echo "$actual_json" | jq -r '.status')
  if [[ "$actual" == "$expected" ]]; then
    echo "  ✓ ${description} (status=${actual})"
    pass=$((pass + 1))
  else
    echo "  ✗ ${description} (esperado=${expected}, obtido=${actual})"
    fail=$((fail + 1))
  fi
}

check_erro() {
  local description="$1" expected="$2" actual_json="$3"
  local actual
  actual=$(echo "$actual_json" | jq -r '.erro')
  if [[ "$actual" == "$expected" ]]; then
    echo "  ✓ ${description} (erro=${actual})"
    pass=$((pass + 1))
  else
    echo "  ✗ ${description} (esperado erro=${expected}, obtido=${actual})"
    fail=$((fail + 1))
  fi
}

echo "== tests/scripts/security-compliance-scan.detect.test.sh =="

echo "-- branch-protection --"
check_status "repo com branch protection configurada => ok" "ok" "$(evaluate_branch_protection "org/repo-conforme" "main")"
check_status "repo sem branch protection (404) => risco" "risco" "$(evaluate_branch_protection "org/repo-sem-protecao" "main")"
check_erro "repo sem permissão administrativa (403) => erro=true" "true" "$(evaluate_branch_protection "org/repo-sem-admin" "main")"

echo "-- required-review --"
check_status "repo com >=1 aprovador obrigatório => ok" "ok" "$(evaluate_required_review "org/repo-conforme" "main")"
check_status "repo com required_approving_review_count=0 => risco" "risco" "$(evaluate_required_review "org/repo-revisao-zero" "main")"
check_status "repo sem branch protection (404) => risco" "risco" "$(evaluate_required_review "org/repo-sem-protecao" "main")"
check_erro "repo sem permissão administrativa (403) => erro=true" "true" "$(evaluate_required_review "org/repo-sem-admin" "main")"

echo "-- actions-permissions --"
check_status "allowed_actions=selected (least privilege) => ok" "ok" "$(evaluate_actions_permissions "org/repo-conforme")"
check_status "allowed_actions=all (excesso de permissão) => risco" "risco" "$(evaluate_actions_permissions "org/repo-actions-liberado")"
check_erro "repo sem permissão administrativa (403) => erro=true" "true" "$(evaluate_actions_permissions "org/repo-sem-admin")"

echo "-- secrets-configured --"
check_status "repo com secrets configurados => ok" "ok" "$(evaluate_secrets_configured "org/repo-conforme")"
check_status "repo sem nenhum secret configurado => pendente" "pendente" "$(evaluate_secrets_configured "org/repo-sem-secrets")"
check_erro "repo sem permissão administrativa (403) => erro=true" "true" "$(evaluate_secrets_configured "org/repo-sem-admin")"

echo ""
echo "Resultado: ${pass} passaram, ${fail} falharam"
if (( fail > 0 )); then
  exit 1
fi
echo "✓ todos os testes passaram"
