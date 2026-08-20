#!/usr/bin/env bash
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

echo ""
echo "Resultado: ${pass} passaram, ${fail} falharam"
if (( fail > 0 )); then
  exit 1
fi
echo "✓ todos os testes passaram"
