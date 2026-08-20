#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# tests/scripts/security-compliance-scan.platform-access.test.sh
#
# T019 / AC-3: validates the Project V2 governance evaluator without calling
# the real GitHub API.
###############################################################################

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_PATH="${ROOT_DIR}/scripts/security-compliance-scan.sh"

if [[ ! -f "$SCRIPT_PATH" ]]; then
  echo "✗ ${SCRIPT_PATH} não encontrado"
  exit 1
fi

export SECURITY_SCAN_PLATFORM_ALLOWED_TEAM_SLUGS="platform-admins"
export SECURITY_SCAN_PLATFORM_REQUIRED_VIEWS="Board por Prioridade,Tabela — P0 Blocker"
export SECURITY_SCAN_PLATFORM_REQUIRED_FIELDS="Status,Repository"

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

check_contains() {
  local description="$1" pattern="$2" text="$3"
  if echo "$text" | grep -q -- "$pattern"; then
    echo "  ✓ ${description}"
    pass=$((pass + 1))
  else
    echo "  ✗ ${description}"
    fail=$((fail + 1))
  fi
}

echo "== tests/scripts/security-compliance-scan.platform-access.test.sh =="

compliant_project='{"title":"plataforma — Nimbus Code Roadmap","url":"https://ghe.example/project/1","public":false,"closed":false,"viewerCanUpdate":false,"team_slugs":["platform-admins"],"view_names":["Board por Prioridade","Tabela — P0 Blocker"],"field_names":["Status","Repository"],"repositories":["org/repo-a","org/repo-b"]}'
unapproved_team_project='{"title":"plataforma — Nimbus Code Roadmap","url":"https://ghe.example/project/1","public":false,"closed":false,"viewerCanUpdate":false,"team_slugs":["platform-admins","outsiders"],"view_names":["Board por Prioridade","Tabela — P0 Blocker"],"field_names":["Status","Repository"],"repositories":["org/repo-a","org/repo-b"]}'
writer_credential_project='{"title":"plataforma — Nimbus Code Roadmap","url":"https://ghe.example/project/1","public":false,"closed":false,"viewerCanUpdate":true,"team_slugs":["platform-admins"],"view_names":["Board por Prioridade","Tabela — P0 Blocker"],"field_names":["Status","Repository"],"repositories":["org/repo-a","org/repo-b"]}'
missing_view_project='{"title":"plataforma — Nimbus Code Roadmap","url":"https://ghe.example/project/1","public":false,"closed":false,"viewerCanUpdate":false,"team_slugs":["platform-admins"],"view_names":["Board por Prioridade"],"field_names":["Status","Repository"],"repositories":["org/repo-a","org/repo-b"]}'

result_ok="$(evaluate_platform_project_access "$compliant_project")"
check_status "Projeto privado + allowlist aprovada + credencial read-only => ok" "ok" "$result_ok"
check_contains "Evidência inclui os repositórios vinculados" "org/repo-a, org/repo-b" "$(echo "$result_ok" | jq -r '.evidencia')"

result_unapproved="$(evaluate_platform_project_access "$unapproved_team_project")"
check_status "Grant direto fora da allowlist => risco" "risco" "$result_unapproved"

result_writer="$(evaluate_platform_project_access "$writer_credential_project")"
check_status "viewerCanUpdate=true para a credencial da varredura => risco" "risco" "$result_writer"

result_missing="$(evaluate_platform_project_access "$missing_view_project")"
check_status "View crítica ausente => pendente" "pendente" "$result_missing"
check_contains "Evidência cita a view ausente" "Tabela — P0 Blocker" "$(echo "$result_missing" | jq -r '.evidencia')"

echo ""
echo "Resultado: ${pass} passaram, ${fail} falharam"
if (( fail > 0 )); then
  exit 1
fi
echo "✓ todos os testes passaram"
