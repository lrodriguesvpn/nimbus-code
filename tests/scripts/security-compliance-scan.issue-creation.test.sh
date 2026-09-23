#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# tests/scripts/security-compliance-scan.issue-creation.test.sh
#
# T025 / AC-6: validates the required issue fields for non-compliance findings.
###############################################################################

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_PATH="${ROOT_DIR}/scripts/security-compliance-scan.sh"

if [[ ! -f "$SCRIPT_PATH" ]]; then
  echo "✗ ${SCRIPT_PATH} não encontrado"
  exit 1
fi

export GITHUB_REPOSITORY="venha-pra-nuvem/nimbus-code"

# shellcheck disable=SC1090
source "$SCRIPT_PATH"

pass=0
fail=0

check_contains() {
  local description="$1" pattern="$2" text="$3"
  if echo "$text" | grep -Fq -- "$pattern"; then
    echo "  ✓ ${description}"
    pass=$((pass + 1))
  else
    echo "  ✗ ${description}"
    fail=$((fail + 1))
  fi
}

echo "== tests/scripts/security-compliance-scan.issue-creation.test.sh =="

body_blocker="$(build_issue_body "org/repo-demo" "branch-protection" "risco" "GET /repos/org/repo-demo/branches/main/protection -> 404" "security-baseline:org/repo-demo:branch-protection")"
body_medium="$(build_issue_body "org/repo-demo" "secrets-configured" "pendente" "GET /repos/org/repo-demo/actions/secrets -> total_count=0" "security-baseline:org/repo-demo:secrets-configured")"

check_contains "Issue bloqueante recebe prioridade P0" "**Prioridade**: priority:P0-blocker" "$body_blocker"
check_contains "Issue inclui responsável inicial" "**Responsavel inicial**:" "$body_blocker"
check_contains "Issue inclui prazo sugerido" "**Prazo sugerido para correcao**:" "$body_blocker"
check_contains "Issue inclui critério de validação" "### Criterio de validacao da correcao" "$body_blocker"
check_contains "Issue inclui marcador de deduplicação" "<!-- security-baseline-finding-id: security-baseline:org/repo-demo:branch-protection -->" "$body_blocker"
check_contains "Issue não bloqueante recebe prioridade P2" "**Prioridade**: priority:P2-medium" "$body_medium"

echo ""
echo "Resultado: ${pass} passaram, ${fail} falharam"
if (( fail > 0 )); then
  exit 1
fi
echo "✓ todos os testes passaram"
