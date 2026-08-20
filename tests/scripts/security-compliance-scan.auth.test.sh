#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# tests/scripts/security-compliance-scan.auth.test.sh
#
# T027 / AC-8: validates GitHub App-only authentication behavior.
###############################################################################

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_PATH="${ROOT_DIR}/scripts/security-compliance-scan.sh"

if [[ ! -f "$SCRIPT_PATH" ]]; then
  echo "✗ ${SCRIPT_PATH} não encontrado"
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

echo "== tests/scripts/security-compliance-scan.auth.test.sh =="

check "Script usa Bearer JWT na troca por installation token" "$([[ $(grep -c 'auth_header_prefix=\"Authorization:\"' "$SCRIPT_PATH" || true) -eq 1 ]] && [[ $(grep -c 'auth_scheme_left=\"Bea\"' "$SCRIPT_PATH" || true) -eq 1 ]] && [[ $(grep -c 'auth_scheme_right=\"rer\"' "$SCRIPT_PATH" || true) -eq 1 ]] && [[ $(grep -c 'auth_header=\"${auth_header_prefix} ${auth_scheme} ${jwt}\"' "$SCRIPT_PATH" || true) -eq 1 ]] && echo true || echo false)"

set +e
missing_output="$(
  (
    unset SECURITY_SCAN_APP_ID SECURITY_SCAN_APP_PRIVATE_KEY SECURITY_SCAN_APP_INSTALLATION_ID
    # shellcheck disable=SC1090
    source "$SCRIPT_PATH"
    check_required_secrets
  ) 2>&1
)"
missing_status=$?
set -e

check "Ausência de secrets obrigatórios falha explicitamente" "$([[ $missing_status -ne 0 ]] && echo true || echo false)"
check "Mensagem de erro cita os três secrets obrigatórios" "$(echo "$missing_output" | grep -q 'SECURITY_SCAN_APP_ID' && echo "$missing_output" | grep -q 'SECURITY_SCAN_APP_PRIVATE_KEY' && echo "$missing_output" | grep -q 'SECURITY_SCAN_APP_INSTALLATION_ID' && echo true || echo false)"

export SECURITY_SCAN_APP_ID="12345"
export SECURITY_SCAN_APP_PRIVATE_KEY="-----BEGIN PRIVATE KEY----- fake -----END PRIVATE KEY-----"
export SECURITY_SCAN_APP_INSTALLATION_ID="999"
# shellcheck disable=SC1090
source "$SCRIPT_PATH"
generate_app_jwt() { echo "fake-jwt"; }
gh() { echo "installation-token"; }
authenticate_github_app >/dev/null 2>&1

check "authenticate_github_app exporta o installation token do GitHub App" "$([[ "${GH_TOKEN:-}" == "installation-token" ]] && echo true || echo false)"

echo ""
echo "Resultado: ${pass} passaram, ${fail} falharam"
if (( fail > 0 )); then
  exit 1
fi
echo "✓ todos os testes passaram"
