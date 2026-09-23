#!/usr/bin/env bash
# shellcheck disable=SC2034,SC2155  # variáveis globais lidas pelo script importado; mktemp não falha
set -euo pipefail

###############################################################################
# tests/scripts/security-compliance-scan.detect.test.sh
#
# Teste de integração (T012, User Story 1, AC-2; atualizado pela issue #450 /
# T052): valida a detecção dos controles de baseline de repositório
# implementados em scripts/security-compliance-scan.sh
# (branch-protection-default, required-review, actions-permissions,
# secrets-configured) contra repositórios FIXTURE — nunca chamadas reais à
# API do GitHub nem credenciais.
#
# Estratégia: sobrepõe `gh` com o mock compartilhado
# (tests/scripts/fixtures/security-scan-gh-mock.sh), que responde com JSON
# fixo para cada `gh api <path>` esperado, depois carrega (`source`) o script
# real (a guarda de entry-point impede que `main()` rode ao ser importado) e
# chama as funções avaliadoras diretamente.
#
# Uso: bash tests/scripts/security-compliance-scan.detect.test.sh
###############################################################################

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_PATH="${ROOT_DIR}/scripts/security-compliance-scan.sh"

if [[ ! -f "$SCRIPT_PATH" ]]; then
  echo "✗ ${SCRIPT_PATH} não encontrado"
  exit 1
fi

export SECURITY_SCAN_SCRATCH_DIR="$(mktemp -d)"
export SECURITY_SCAN_GOVERNANCE_CONFIG="${SECURITY_SCAN_SCRATCH_DIR}/missing.json"

# shellcheck source=tests/scripts/fixtures/security-scan-gh-mock.sh
source "${ROOT_DIR}/tests/scripts/fixtures/security-scan-gh-mock.sh"

# --- Fixtures -----------------------------------------------------------------
CONFORME_PROTECTION='{"required_pull_request_reviews":{"required_approving_review_count":2,"dismiss_stale_reviews":true,"require_code_owner_reviews":true},"required_status_checks":{"strict":true,"contexts":["build","unit-tests"]},"allow_force_pushes":{"enabled":false},"allow_deletions":{"enabled":false},"required_conversation_resolution":{"enabled":true}}'
gh_fixture "repos/org/repo-conforme/branches/main/protection" 200 "$CONFORME_PROTECTION"
gh_fixture "repos/org/repo-conforme/rules/branches/main" 200 '[]'
gh_fixture "repos/org/repo-conforme/contents/.github/CODEOWNERS" 200 '{"content":""}'
gh_fixture "repos/org/repo-conforme/actions/permissions" 200 '{"enabled":true,"allowed_actions":"selected"}'
gh_fixture "repos/org/repo-conforme/actions/permissions/workflow" 200 '{"default_workflow_permissions":"read","can_approve_pull_request_reviews":false}'
gh_fixture "repos/org/repo-conforme/actions/secrets" 200 '{"total_count":3,"secrets":[{"name":"NPM_TOKEN"},{"name":"DEPLOY_KEY"},{"name":"SLACK_WEBHOOK"}]}'

gh_fixture "repos/org/repo-sem-protecao/branches/main/protection" 404 "" "Branch not protected"
gh_fixture "repos/org/repo-sem-protecao/rules/branches/main" 200 '[]'

gh_fixture "repos/org/repo-revisao-zero/branches/main/protection" 200 '{"required_pull_request_reviews":{"required_approving_review_count":0,"dismiss_stale_reviews":true},"required_status_checks":{"contexts":["build"]},"allow_force_pushes":{"enabled":false},"allow_deletions":{"enabled":false}}'
gh_fixture "repos/org/repo-revisao-zero/rules/branches/main" 200 '[]'

gh_fixture "repos/org/repo-force-push/branches/main/protection" 200 '{"required_pull_request_reviews":{"required_approving_review_count":1},"required_status_checks":{"contexts":["build"]},"allow_force_pushes":{"enabled":true},"allow_deletions":{"enabled":false}}'
gh_fixture "repos/org/repo-force-push/rules/branches/main" 200 '[]'

for p in "repos/org/repo-sem-admin/branches/main/protection" "repos/org/repo-sem-admin/rules/branches/main" \
         "repos/org/repo-sem-admin/actions/permissions" "repos/org/repo-sem-admin/actions/secrets"; do
  gh_fixture "$p" 403 "" "Resource not accessible by integration"
done

gh_fixture "repos/org/repo-actions-liberado/actions/permissions" 200 '{"enabled":true,"allowed_actions":"all"}'
gh_fixture "repos/org/repo-actions-liberado/actions/permissions/workflow" 200 '{"default_workflow_permissions":"read","can_approve_pull_request_reviews":false}'
gh_fixture "repos/org/repo-token-write/actions/permissions" 200 '{"enabled":true,"allowed_actions":"selected"}'
gh_fixture "repos/org/repo-token-write/actions/permissions/workflow" 200 '{"default_workflow_permissions":"write","can_approve_pull_request_reviews":true}'

gh_fixture "repos/org/repo-sem-secrets/actions/secrets" 200 '{"total_count":0,"secrets":[]}'

# shellcheck disable=SC1090
source "$SCRIPT_PATH"
REPO_CFG="$BUILTIN_GOVERNANCE_CONFIG"

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
    echo "  ✗ ${description} (esperado=${expected}, obtido=${actual}) :: $(echo "$actual_json" | jq -r '.evidencia')"
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

check_contains() {
  local description="$1" pattern="$2" text="$3"
  if grep -Fq -- "$pattern" <<< "$text"; then
    echo "  ✓ ${description}"
    pass=$((pass + 1))
  else
    echo "  ✗ ${description} (padrão ausente: ${pattern}) :: ${text}"
    fail=$((fail + 1))
  fi
}

fresh() { reset_repo_state; REPO_CFG="$BUILTIN_GOVERNANCE_CONFIG"; }

echo "== tests/scripts/security-compliance-scan.detect.test.sh =="

echo "-- branch-protection-default --"
fresh; r=$(evaluate_branch_protection_default "org/repo-conforme" "main")
check_status "repo com branch protection completa => ok" "ok" "$r"
check_contains "evidência cita repository, branch, endpoint e fonte clássica" "repository=org/repo-conforme | branch=main (padrão) | endpoint=GET /repos/org/repo-conforme/branches/main/protection -> 200" "$(jq -r .evidencia <<< "$r")"
check_contains "evidência declara proteção clássica como compatibilidade" "fonte=classic (compatibilidade)" "$(jq -r .evidencia <<< "$r")"
fresh; check_status "repo sem branch protection (404) => risco" "risco" "$(evaluate_branch_protection_default "org/repo-sem-protecao" "main")"
fresh; check_status "force push permitido => risco" "risco" "$(evaluate_branch_protection_default "org/repo-force-push" "main")"
fresh; check_erro "repo sem permissão administrativa (403) => erro=true" "true" "$(evaluate_branch_protection_default "org/repo-sem-admin" "main")"
fresh; check_status "alias legado evaluate_branch_protection continua funcionando" "ok" "$(evaluate_branch_protection "org/repo-conforme" "main")"

echo "-- required-review --"
fresh; check_status "repo com >=1 aprovador, dismiss stale e CODEOWNERS => ok" "ok" "$(evaluate_required_review "org/repo-conforme" "main")"
fresh; check_status "repo com required_approving_review_count=0 => risco" "risco" "$(evaluate_required_review "org/repo-revisao-zero" "main")"
fresh; check_status "repo sem branch protection (404) => risco" "risco" "$(evaluate_required_review "org/repo-sem-protecao" "main")"
fresh; check_erro "repo sem permissão administrativa (403) => erro=true" "true" "$(evaluate_required_review "org/repo-sem-admin" "main")"

echo "-- actions-permissions --"
check_status "allowed_actions=selected + token read => ok" "ok" "$(evaluate_actions_permissions "org/repo-conforme")"
check_status "allowed_actions=all (excesso de permissão) => risco" "risco" "$(evaluate_actions_permissions "org/repo-actions-liberado")"
check_status "default_workflow_permissions=write => risco" "risco" "$(evaluate_actions_permissions "org/repo-token-write")"
check_erro "repo sem permissão administrativa (403) => erro=true" "true" "$(evaluate_actions_permissions "org/repo-sem-admin")"

echo "-- secrets-configured --"
r=$(evaluate_secrets_configured "org/repo-conforme")
check_status "repo com secrets configurados => ok" "ok" "$r"
check_contains "evidência deixa claro que só metadados são lidos" "values never read" "$(jq -r .evidencia <<< "$r")"
if grep -Eq 'NPM_TOKEN|DEPLOY_KEY|SLACK_WEBHOOK' <<< "$r"; then
  echo "  ✗ evidência não deve listar nomes/valores de secrets"; fail=$((fail + 1))
else
  echo "  ✓ evidência não lista nomes/valores de secrets"; pass=$((pass + 1))
fi
check_status "repo sem nenhum secret configurado => pendente" "pendente" "$(evaluate_secrets_configured "org/repo-sem-secrets")"
check_erro "repo sem permissão administrativa (403) => erro=true" "true" "$(evaluate_secrets_configured "org/repo-sem-admin")"

rm -rf "$SECURITY_SCAN_SCRATCH_DIR"
echo ""
echo "Resultado: ${pass} passaram, ${fail} falharam"
if (( fail > 0 )); then
  exit 1
fi
echo "✓ todos os testes passaram"
