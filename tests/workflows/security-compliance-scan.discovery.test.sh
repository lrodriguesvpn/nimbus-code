#!/usr/bin/env bash
# shellcheck disable=SC2034  # SCOPE_ARG/FEATURE_FLAG_FILE são lidos pelo script importado
set -euo pipefail

###############################################################################
# tests/workflows/security-compliance-scan.discovery.test.sh
#
# T026 / AC-7: validates workflow triggers and scope resolution (pilot vs.
# org-wide) without calling the real API.
###############################################################################

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_PATH="${ROOT_DIR}/scripts/security-compliance-scan.sh"
WORKFLOW_PATH="${ROOT_DIR}/.github/workflows/security-compliance-scan.yml"

if [[ ! -f "$SCRIPT_PATH" || ! -f "$WORKFLOW_PATH" ]]; then
  echo "✗ Arquivos obrigatórios não encontrados"
  exit 1
fi

pass=0
fail=0

check() {
  local description="$1" condition="$2"
  if [[ "$condition" == "true" ]]; then
    echo "  ✓ ${description}"
    pass=$((pass + 1))
  else
    echo "  ✗ ${description}"
    fail=$((fail + 1))
  fi
}

check_equals() {
  local description="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo "  ✓ ${description} (${actual})"
    pass=$((pass + 1))
  else
    echo "  ✗ ${description} (esperado=${expected}, obtido=${actual})"
    fail=$((fail + 1))
  fi
}

echo "== tests/workflows/security-compliance-scan.discovery.test.sh =="

check "Workflow mantém o cron semanal" "$(grep -Fq 'cron: "0 13 * * 1"' "$WORKFLOW_PATH" && echo true || echo false)"
check "Workflow mantém workflow_dispatch" "$([[ $(grep -c 'workflow_dispatch:' "$WORKFLOW_PATH" || true) -ge 1 ]] && echo true || echo false)"
check "Workflow oferece opção de escopo auto" "$([[ $(grep -c 'default: \"auto\"' "$WORKFLOW_PATH" || true) -eq 1 ]] && echo true || echo false)"
check "Workflow usa o input/resolução do flag em vez de forçar pilot no comando" "$(grep -Fq 'ARGS+=("--scope=${SCOPE_INPUT}")' "$WORKFLOW_PATH" && echo true || echo false)"

unset SECURITY_BASELINE_SCAN_ORG_WIDE_ENABLED
# shellcheck disable=SC1090
source "$SCRIPT_PATH"

SCOPE_ARG=""
check_equals "Flag ausente => piloto" "pilot" "$(resolve_scope)"

export SECURITY_BASELINE_SCAN_ORG_WIDE_ENABLED="true"
SCOPE_ARG=""
check_equals "Flag true => org-wide" "org-wide" "$(resolve_scope)"

SCOPE_ARG="pilot"
check_equals "Argumento explícito continua tendo precedência" "pilot" "$(resolve_scope)"

# --- Rollout piloto vs. org-wide preservado (gate S4, issue #450) -------------
unset SECURITY_BASELINE_SCAN_ORG_WIDE_ENABLED
SCOPE_ARG=""
FEATURE_FLAG_FILE="${ROOT_DIR}/.github/feature-flags/security-baseline-scan.json"
check_equals "Sem flag versionado nem env => continua piloto" "pilot" "$(resolve_scope)"
check "Flag org-wide não está versionado como habilitado" "$( { [[ ! -f "$FEATURE_FLAG_FILE" ]] || [[ "$(jq -r '."security.baseline_scan.org_wide_enabled".enabled // false' "$FEATURE_FLAG_FILE")" != "true" ]]; } && echo true || echo false)"
check "Workflow não força SECURITY_BASELINE_SCAN_ORG_WIDE_ENABLED" "$(grep -q 'SECURITY_BASELINE_SCAN_ORG_WIDE_ENABLED' "$WORKFLOW_PATH" && echo false || echo true)"
check "Workflow não força --scope=org-wide no comando (fora de comentários)" "$(grep -Ev '^[[:space:]]*#' "$WORKFLOW_PATH" | grep -Eq 'scope=org-wide|--scope org-wide' && echo false || echo true)"
check "Workflow não troca o default do input de escopo" "$([[ $(grep -c 'default: "auto"' "$WORKFLOW_PATH" || true) -eq 1 ]] && echo true || echo false)"
check "Workflow documenta o gate S4 (T038)" "$(grep -q 'gate S4' "$WORKFLOW_PATH" && grep -q 'T038' "$WORKFLOW_PATH" && echo true || echo false)"
check "Workflow usa GITHUB_TOKEN só para issues (App permanece read-only)" "$(grep -q 'SECURITY_SCAN_ISSUES_TOKEN: ${{ github.token }}' "$WORKFLOW_PATH" && grep -q 'issues: write' "$WORKFLOW_PATH" && echo true || echo false)"
check "Workflow não concede escrita em contents/administration/security-events" "$(grep -Eq '(contents|administration|security-events|actions): write' "$WORKFLOW_PATH" && echo false || echo true)"

echo ""
echo "Resultado: ${pass} passaram, ${fail} falharam"
if (( fail > 0 )); then
  exit 1
fi
echo "✓ todos os testes passaram"
