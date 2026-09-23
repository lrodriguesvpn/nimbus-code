#!/usr/bin/env bash
# shellcheck disable=SC2034,SC2155  # variáveis globais lidas pelo script importado; mktemp não falha
set -euo pipefail

###############################################################################
# tests/scripts/security-compliance-scan.issue-lifecycle.test.sh
#
# Issue #450 / T054: ciclo de vida das issues de não conformidade, sem API real:
#   - criação idempotente (1ª execução cria; 2ª atualiza, não duplica);
#   - migração do id legado `branch-protection` -> `branch-protection-default`;
#   - fechamento automático quando o controle volta para `ok`;
#   - modo dry-run: nenhuma escrita (create/edit/close/label/comment);
#   - escrita SEMPRE com SECURITY_SCAN_ISSUES_TOKEN, nunca com o token do App;
#   - issues centralizadas no repositório de relatório (App read-only);
#   - varredura completa de um repositório (scan_single_repo) em dry-run
#     avaliando os 18 controles.
###############################################################################

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_PATH="${ROOT_DIR}/scripts/security-compliance-scan.sh"
[[ -f "$SCRIPT_PATH" ]] || { echo "✗ ${SCRIPT_PATH} não encontrado"; exit 1; }

export SECURITY_SCAN_SCRATCH_DIR="$(mktemp -d)"
export SECURITY_SCAN_GOVERNANCE_CONFIG="${ROOT_DIR}/.github/security-governance.json"
export GITHUB_REPOSITORY="org/report"
export SECURITY_SCAN_REPORT_REPOSITORY="org/report"
export SECURITY_SCAN_ISSUES_TOKEN="workflow-issues-token"
export GH_TOKEN="app-installation-token-readonly"

# shellcheck source=tests/scripts/fixtures/security-scan-gh-mock.sh
source "${ROOT_DIR}/tests/scripts/fixtures/security-scan-gh-mock.sh"
# shellcheck disable=SC1090
source "$SCRIPT_PATH"

pass=0
fail=0
check() {
  local description="$1" condition="$2"
  if [[ "$condition" == "true" ]]; then
    echo "  ✓ ${description}"; pass=$((pass + 1))
  else
    echo "  ✗ ${description}"; fail=$((fail + 1))
  fi
}
calls() { gh_calls_matching "$1"; }
risco='{"status":"risco","evidencia":"repository=org/app | branch=main | endpoint=GET ... -> 404 | resultado=sem proteção","erro":false}'
ok='{"status":"ok","evidencia":"repository=org/app | branch=main | resultado=ok","erro":false}'

echo "== tests/scripts/security-compliance-scan.issue-lifecycle.test.sh =="

echo "-- destino das issues e token de escrita --"
check "issues centralizadas no repositório de relatório por padrão" "$([[ $(resolve_issue_repo "org/app") == "org/report" ]] && echo true || echo false)"
ISSUE_TARGET="scanned-repository"
check "modo scanned-repository direciona ao repositório avaliado (exige credencial writer aprovada)" "$([[ $(resolve_issue_repo "org/app") == "org/app" ]] && echo true || echo false)"
ISSUE_TARGET="report-repository"

echo "-- 1ª execução: cria issue --"
gh_fixtures_reset
DRY_RUN="false"; GH_MOCK_ISSUE_LIST='[]'
evaluate_and_report "org/app" "branch-protection-default" "$risco" "org/report"
check "cria exatamente 1 issue" "$([[ $(calls 'issue create') -eq 1 ]] && echo true || echo false)"
check "issue criada no repositório de relatório" "$([[ $(calls 'issue create --repo org/report') -eq 1 ]] && echo true || echo false)"
check "escrita usa SECURITY_SCAN_ISSUES_TOKEN" "$([[ $(calls '^token=workflow-issues-token issue create') -eq 1 ]] && echo true || echo false)"
check "token do GitHub App nunca é usado em issue/label" "$([[ $(calls '^token=app-installation-token-readonly (issue|label)') -eq 0 ]] && echo true || echo false)"
check "finding não-ok recebe issue_url" "$(grep -q 'issues/999' <<< "$RUN_NON_OK_FINDINGS_NDJSON" && echo true || echo false)"

echo "-- 2ª execução: atualiza (idempotente) --"
gh_fixtures_reset
GH_MOCK_ISSUE_LIST='[{"url":"https://ghe.example/org/report/issues/10","body":"x <!-- security-baseline-finding-id: security-baseline:org/app:branch-protection-default --> y"}]'
evaluate_and_report "org/app" "branch-protection-default" "$risco" "org/report"
check "não cria issue duplicada" "$([[ $(calls 'issue create') -eq 0 ]] && echo true || echo false)"
check "edita a issue existente" "$([[ $(calls 'issue edit https://ghe.example/org/report/issues/10') -eq 1 ]] && echo true || echo false)"

echo "-- migração do id legado branch-protection --"
gh_fixtures_reset
GH_MOCK_ISSUE_LIST='[{"url":"https://ghe.example/org/report/issues/3","body":"<!-- security-baseline-finding-id: security-baseline:org/app:branch-protection -->"}]'
evaluate_and_report "org/app" "branch-protection-default" "$risco" "org/report"
check "reaproveita a issue legada em vez de criar nova" "$([[ $(calls 'issue create') -eq 0 && $(calls 'issue edit https://ghe.example/org/report/issues/3') -eq 1 ]] && echo true || echo false)"
gh_fixtures_reset
evaluate_and_report "org/app" "branch-protection-default" "$ok" "org/report"
check "controle ok fecha a issue legada" "$([[ $(calls 'issue close https://ghe.example/org/report/issues/3') -eq 1 ]] && echo true || echo false)"

echo "-- controle volta para ok: fecha finding --"
gh_fixtures_reset
GH_MOCK_ISSUE_LIST='[{"url":"https://ghe.example/org/report/issues/10","body":"<!-- security-baseline-finding-id: security-baseline:org/app:codeql-enabled -->"}]'
evaluate_and_report "org/app" "codeql-enabled" "$ok" "org/report"
check "issue aberta é fechada automaticamente" "$([[ $(calls 'issue close https://ghe.example/org/report/issues/10') -eq 1 ]] && echo true || echo false)"
check "fechamento usa o token de issues" "$([[ $(calls '^token=workflow-issues-token issue close') -eq 1 ]] && echo true || echo false)"

echo "-- dry-run: nenhuma escrita --"
gh_fixtures_reset
DRY_RUN="true"
GH_MOCK_ISSUE_LIST='[]'
evaluate_and_report "org/app" "secret-alerts" "$risco" "org/report" 2>/dev/null
GH_MOCK_ISSUE_LIST='[{"url":"https://ghe.example/org/report/issues/10","body":"<!-- security-baseline-finding-id: security-baseline:org/app:codeql-enabled -->"}]'
evaluate_and_report "org/app" "codeql-enabled" "$ok" "org/report" 2>/dev/null
check "dry-run não cria, edita, fecha, comenta nem cria label" "$([[ $(calls 'issue (create|edit|close|comment)|label create') -eq 0 ]] && echo true || echo false)"

echo "-- prazo por severidade --"
body=$(build_issue_body "org/app" "secret-alerts" "risco" "ev" "security-baseline:org/app:secret-alerts")
check "secret exposto: P0 com prazo de 1 dia" "$(grep -q 'priority:P0-blocker' <<< "$body" && grep -q '1 dias corridos' <<< "$body" && echo true || echo false)"
body=$(build_issue_body "org/app" "rulesets-configured" "pendente" "ev" "security-baseline:org/app:rulesets-configured")
check "rulesets-configured (não bloqueante): P2 com 30 dias" "$(grep -q 'priority:P2-medium' <<< "$body" && grep -q '30 dias corridos' <<< "$body" && echo true || echo false)"

echo "-- varredura completa de um repositório (dry-run) --"
gh_fixtures_reset
DRY_RUN="true"; GH_MOCK_ISSUE_LIST='[]'
RUN_FINDINGS_NDJSON=""; RUN_NON_OK_FINDINGS_NDJSON=""
gh_fixture "repos/org/app" 200 '{"default_branch":"main","security_and_analysis":{"secret_scanning":{"status":"enabled"},"secret_scanning_push_protection":{"status":"disabled"}}}'
gh_fixture "repos/org/app/branches/main/protection" 404 "" "Branch not protected"
gh_fixture "repos/org/app/rules/branches/main" 200 '[]'
gh_fixture "repos/org/app/branches?per_page=100" 200 '[{"name":"main"}]'
gh_fixture "repos/org/app/rulesets?includes_parents=true&per_page=100" 200 '[]'
gh_fixture "repos/org/app/actions/secrets" 200 '{"total_count":0,"secrets":[]}'
scan_single_repo "org/app" "" 2>/dev/null
evaluated=$(printf '%s\n' "$RUN_FINDINGS_NDJSON" | grep -c 'controle_id' || true)
check "18 controles de repositório avaliados/registrados (${evaluated})" "$([[ "$evaluated" -eq 18 ]] && echo true || echo false)"
check "REPO_HAD_ERROR=false quando todos os endpoints respondem" "$([[ "$REPO_HAD_ERROR" == "false" ]] && echo true || echo false)"
check "branch padrão resolvida via GET /repos quando a descoberta não informa" "$([[ $(calls 'repos/org/app/rules/branches/main') -ge 1 ]] && echo true || echo false)"
check "push protection desabilitado aparece como risco" "$(printf '%s\n' "$RUN_FINDINGS_NDJSON" | jq -s -e 'any(.[]; .controle_id == "secret-scanning-push-protection-enabled" and .status == "risco")' >/dev/null && echo true || echo false)"
check "nenhum controle ausente é reportado como ok" "$(printf '%s\n' "$RUN_FINDINGS_NDJSON" | jq -s -e '[.[] | select(.controle_id == "codeql-enabled" or .controle_id == "branch-protection-default" or .controle_id == "dependency-review-enabled") | .status] | all(. != "ok")' >/dev/null && echo true || echo false)"
check "dry-run da varredura completa não escreve nada" "$([[ $(calls 'issue (create|edit|close|comment)|label create') -eq 0 ]] && echo true || echo false)"
check "a varredura não chama nenhum endpoint de escrita (-X POST/PUT/PATCH/DELETE)" "$([[ $(calls 'api .*-X (POST|PUT|PATCH|DELETE)|api -X (POST|PUT|PATCH|DELETE)') -eq 0 ]] && echo true || echo false)"

rm -rf "$SECURITY_SCAN_SCRATCH_DIR"
echo ""
echo "Resultado: ${pass} passaram, ${fail} falharam"
(( fail > 0 )) && exit 1
echo "✓ todos os testes passaram"
