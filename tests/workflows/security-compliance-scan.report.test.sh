#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# tests/workflows/security-compliance-scan.report.test.sh
#
# T024 / AC-5: validates the monthly report markdown contract.
###############################################################################

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_PATH="${ROOT_DIR}/scripts/security-compliance-scan.sh"

if [[ ! -f "$SCRIPT_PATH" ]]; then
  echo "✗ ${SCRIPT_PATH} não encontrado"
  exit 1
fi

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

echo "== tests/workflows/security-compliance-scan.report.test.sh =="

aggregate='{"runs":4,"total_repos":12,"controls":{"branch-protection":{"pct_ok":75},"required-review":{"pct_ok":83.33},"actions-permissions":{"pct_ok":91.67},"secrets-configured":{"pct_ok":66.67},"platform-project-access":{"pct_ok":100}},"open_findings":[{"repo":"org/repo-a","controle_id":"branch-protection","timestamp":"2026-08-05T12:00:00Z","issue_url":"https://ghe.example/org/repo-a/issues/1"}]}'
closed='[{"repo":"org/repo-b","controle_id":"required-review","created_at":"2026-08-02T10:00:00Z","closed_at":"2026-08-09T11:30:00Z","url":"https://ghe.example/org/repo-b/issues/2"}]'

report="$(build_monthly_report_markdown "2026-08" "$aggregate" '{}' "$closed")"

check_contains "Título do relatório mensal" "## Relatorio de Conformidade - 2026-08" "$report"
check_contains "Inclui total de repositórios avaliados" "**Total de repositorios avaliados**: 12" "$report"
check_contains "Tabela de conformidade lista o controle do Projeto Plataforma" "| Matriz de acesso do Projeto Plataforma | 100% | N/A |" "$report"
check_contains "Tabela de desvios abertos inclui issue atual" "| org/repo-a | branch-protection | 2026-08-05 | https://ghe.example/org/repo-a/issues/1 |" "$report"
check_contains "Tabela de desvios corrigidos inclui issue fechada" "| org/repo-b | required-review | 2026-08-02 | 2026-08-09 | https://ghe.example/org/repo-b/issues/2 |" "$report"

echo ""
echo "Resultado: ${pass} passaram, ${fail} falharam"
if (( fail > 0 )); then
  exit 1
fi
echo "✓ todos os testes passaram"
