#!/usr/bin/env bash
# shellcheck disable=SC2034,SC2155  # variáveis globais lidas pelo script importado; mktemp não falha
set -euo pipefail

###############################################################################
# tests/scripts/security-compliance-scan.governance-controls.test.sh
#
# Issue #450 / T053: valida os controles de governança adicionados ao
# scripts/security-compliance-scan.sh contra fixtures de API (nunca a API real):
#   - Rulesets vs. proteção clássica, branch padrão e padrões release/* e
#     hotfix/* (branches existentes e futuras);
#   - required status checks (ausência de check obrigatório), checks de teste
#     e cobertura (report vs. not-applicable);
#   - CodeQL ausente, desatualizado e com alertas high/critical;
#   - Dependabot alerts/security updates e Dependency Review ausentes;
#   - Secret Scanning e Push Protection ausentes; alertas de secret abertos
#     sem jamais expor o valor do secret;
#   - API indisponível (404/plano), 403 por permissão insuficiente e rate
#     limit com retry.
###############################################################################

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_PATH="${ROOT_DIR}/scripts/security-compliance-scan.sh"
[[ -f "$SCRIPT_PATH" ]] || { echo "✗ ${SCRIPT_PATH} não encontrado"; exit 1; }

export SECURITY_SCAN_SCRATCH_DIR="$(mktemp -d)"
export SECURITY_SCAN_GOVERNANCE_CONFIG="${SECURITY_SCAN_SCRATCH_DIR}/missing.json"
export SECURITY_SCAN_RETRY_BASE_SECONDS=0

# shellcheck source=tests/scripts/fixtures/security-scan-gh-mock.sh
source "${ROOT_DIR}/tests/scripts/fixtures/security-scan-gh-mock.sh"
# shellcheck disable=SC1090
source "$SCRIPT_PATH"

TEST_CFG='{"schema_version":1,"branches":{"default_branch":"auto","production_branches":["main"],"protected_patterns":["release/*","hotfix/*"],"additional_branches":[]},"branch_rules":{"required_approving_review_count":1,"require_code_owner_review":true,"dismiss_stale_reviews":true,"require_up_to_date_branch":true,"require_conversation_resolution":true},"required_status_checks":{"build":["build"],"unit_tests":["unit-tests"],"integration_tests":[],"coverage":["coverage"],"sast":["CodeQL"],"sca":["dependency-review"],"secret_scanning":["secret-scan"]},"coverage":{"mode":"report","global_min_percent":80},"codeql":{"max_analysis_age_days":8,"blocking_security_severities":["critical","high"]}}'
ALL_CHECKS='[{"context":"build"},{"context":"unit-tests"},{"context":"coverage"},{"context":"CodeQL"},{"context":"dependency-review"},{"context":"secret-scan"}]'
full_rules() {
  # $1 = ruleset_id, $2 = required_status_checks JSON
  printf '[{"type":"pull_request","ruleset_id":%s,"parameters":{"required_approving_review_count":1,"dismiss_stale_reviews_on_push":true,"require_code_owner_review":true,"required_review_thread_resolution":true}},{"type":"non_fast_forward","ruleset_id":%s},{"type":"deletion","ruleset_id":%s},{"type":"required_status_checks","ruleset_id":%s,"parameters":{"strict_required_status_checks_policy":true,"required_status_checks":%s}}]' "$1" "$1" "$1" "$1" "$2"
}
b64() { printf '%s' "$1" | base64 | tr -d '\n'; }
iso_days_ago() { python3 -c 'import datetime as d,sys; print((d.datetime.now(d.timezone.utc)-d.timedelta(days=int(sys.argv[1]))).strftime("%Y-%m-%dT%H:%M:%SZ"))' "$1"; }

pass=0
fail=0
check_status() {
  local description="$1" expected="$2" json="$3" actual
  actual=$(jq -r '.status' <<< "$json")
  if [[ "$actual" == "$expected" ]]; then
    echo "  ✓ ${description} (status=${actual})"; pass=$((pass + 1))
  else
    echo "  ✗ ${description} (esperado=${expected}, obtido=${actual}) :: $(jq -r '.evidencia' <<< "$json")"; fail=$((fail + 1))
  fi
}
check_erro() {
  local description="$1" json="$2"
  if [[ $(jq -r '.erro' <<< "$json") == "true" && $(jq -r '.status' <<< "$json") == "null" ]]; then
    echo "  ✓ ${description} (erro=true, status=null — nunca mascarado como ok)"; pass=$((pass + 1))
  else
    echo "  ✗ ${description} :: $(jq -c . <<< "$json")"; fail=$((fail + 1))
  fi
}
check_contains() {
  local description="$1" pattern="$2" text="$3"
  if grep -Fq -- "$pattern" <<< "$text"; then
    echo "  ✓ ${description}"; pass=$((pass + 1))
  else
    echo "  ✗ ${description} (padrão ausente: ${pattern}) :: ${text}"; fail=$((fail + 1))
  fi
}
check_not_contains() {
  local description="$1" pattern="$2" text="$3"
  if grep -Fq -- "$pattern" <<< "$text"; then
    echo "  ✗ ${description} (padrão proibido presente: ${pattern})"; fail=$((fail + 1))
  else
    echo "  ✓ ${description}"; pass=$((pass + 1))
  fi
}
ev() { jq -r '.evidencia' <<< "$1"; }
fresh() { reset_repo_state; REPO_CFG="$TEST_CFG"; REPO_CFG_SOURCE="teste"; }

echo "== tests/scripts/security-compliance-scan.governance-controls.test.sh =="

# --- Fixtures: repositório 100% em Rulesets ---------------------------------
gh_fixture "repos/org/rs/branches/main/protection" 404 "" "Branch not protected"
gh_fixture "repos/org/rs/rules/branches/main" 200 "$(full_rules 7 "$ALL_CHECKS")"
gh_fixture "repos/org/rs/branches?per_page=100" 200 '[{"name":"main"},{"name":"release/1.0"},{"name":"release/2.0"},{"name":"feature/x"}]'
gh_fixture "repos/org/rs/rulesets?includes_parents=true&per_page=100" 200 '[{"id":7,"target":"branch","enforcement":"active"},{"id":8,"target":"branch","enforcement":"active"},{"id":9,"target":"branch","enforcement":"disabled"}]'
gh_fixture "repos/org/rs/rulesets/7?includes_parents=true" 200 '{"id":7,"name":"default","enforcement":"active","target":"branch","conditions":{"ref_name":{"include":["~DEFAULT_BRANCH"],"exclude":[]}},"rules":[{"type":"pull_request"},{"type":"non_fast_forward"},{"type":"deletion"},{"type":"required_status_checks"}]}'
gh_fixture "repos/org/rs/rulesets/8?includes_parents=true" 200 '{"id":8,"name":"release-hotfix","enforcement":"active","target":"branch","conditions":{"ref_name":{"include":["refs/heads/release/*","refs/heads/hotfix/*"],"exclude":[]}},"rules":[{"type":"pull_request"},{"type":"non_fast_forward"},{"type":"deletion"},{"type":"required_status_checks"}]}'
for b in release/1.0 release/2.0; do
  gh_fixture "repos/org/rs/branches/${b}/protection" 404 "" "Branch not protected"
  gh_fixture "repos/org/rs/rules/branches/${b}" 200 "$(full_rules 8 "$ALL_CHECKS")"
done

echo "-- Rulesets e branch padrão --"
fresh; r=$(evaluate_branch_protection_default "org/rs" "main")
check_status "branch padrão protegida por Ruleset => ok" "ok" "$r"
check_contains "evidência identifica a fonte Ruleset" "fonte=ruleset" "$(ev "$r")"
fresh; r=$(evaluate_rulesets_configured "org/rs" "main")
check_status "Ruleset ativo na branch padrão => rulesets-configured ok" "ok" "$r"
check_contains "evidência cita endpoint de rules/branches" "GET /repos/org/rs/rules/branches/main -> 200" "$(ev "$r")"

gh_fixture "repos/org/classic/branches/main/protection" 200 '{"required_pull_request_reviews":{"required_approving_review_count":1,"dismiss_stale_reviews":true},"required_status_checks":{"contexts":["build"]},"allow_force_pushes":{"enabled":false},"allow_deletions":{"enabled":false}}'
gh_fixture "repos/org/classic/rules/branches/main" 200 '[]'
fresh; check_status "somente proteção clássica => rulesets-configured pendente (compatibilidade)" "pendente" "$(evaluate_rulesets_configured "org/classic" "main")"

gh_fixture "repos/org/none/branches/main/protection" 404 "" "Branch not protected"
gh_fixture "repos/org/none/rules/branches/main" 200 '[]'
fresh; check_status "sem ruleset e sem proteção => rulesets-configured risco" "risco" "$(evaluate_rulesets_configured "org/none" "main")"

gh_fixture "repos/org/norules/branches/main/protection" 404 "" "Branch not protected"
gh_fixture "repos/org/norules/rules/branches/main" 404 "" "Not Found"
fresh; r=$(evaluate_rulesets_configured "org/norules" "main")
check_status "API de Rulesets indisponível (404) => pendente, nunca ok" "pendente" "$r"
check_contains "evidência explica indisponibilidade da API" "API indisponível" "$(ev "$r")"

gh_fixture "repos/org/rules403/branches/main/protection" 403 "" "Resource not accessible by integration"
gh_fixture "repos/org/rules403/rules/branches/main" 403 "" "Resource not accessible by integration"
fresh; check_erro "403 por permissão insuficiente em Rulesets => erro explícito" "$(evaluate_rulesets_configured "org/rules403" "main")"
fresh; check_erro "403 em ambas as fontes de proteção => branch-protection-default erro" "$(evaluate_branch_protection_default "org/rules403" "main")"

echo "-- Padrões release/* e hotfix/* --"
fresh; r=$(evaluate_branch_protection_required_patterns "org/rs" "main")
check_status "release/* e hotfix/* cobertos por Ruleset e branches existentes protegidas => ok" "ok" "$r"
check_contains "evidência avalia release/*" "release/* → ruleset(s) 8 (release-hotfix) cobrem com baseline" "$(ev "$r")"
check_contains "evidência avalia branch existente release/1.0" "release/1.0: ok [ruleset]" "$(ev "$r")"
check_contains "evidência avalia hotfix/* sem branches existentes" "hotfix/* → nenhuma branch existente; ruleset(s) 8 (release-hotfix) cobrem com baseline" "$(ev "$r")"
check_not_contains "branches fora dos padrões (feature/x) não são avaliadas" "feature/x" "$(ev "$r")"
check_not_contains "ruleset desabilitado (id 9) é ignorado" "9 (" "$(ev "$r")"

gh_fixture "repos/org/unprot/branches?per_page=100" 200 '[{"name":"main"},{"name":"release/1.0"},{"name":"hotfix/9"}]'
gh_fixture "repos/org/unprot/rulesets?includes_parents=true&per_page=100" 200 '[]'
gh_fixture "repos/org/unprot/branches/release/1.0/protection" 404 "" "Branch not protected"
gh_fixture "repos/org/unprot/rules/branches/release/1.0" 200 '[]'
gh_fixture "repos/org/unprot/branches/hotfix/9/protection" 200 '{"required_pull_request_reviews":{"required_approving_review_count":1,"dismiss_stale_reviews":true},"required_status_checks":{"contexts":["build"]},"allow_force_pushes":{"enabled":false},"allow_deletions":{"enabled":false}}'
gh_fixture "repos/org/unprot/rules/branches/hotfix/9" 200 '[]'
fresh; r=$(evaluate_branch_protection_required_patterns "org/unprot" "main")
check_status "branch release/1.0 existente sem proteção => risco" "risco" "$r"
check_contains "evidência aponta a branch desprotegida" "release/1.0: RISCO" "$(ev "$r")"
check_contains "hotfix/9 com proteção clássica aparece como compatibilidade" "hotfix/9: ok [classic (compatibilidade)]" "$(ev "$r")"

gh_fixture "repos/org/future/branches?per_page=100" 200 '[{"name":"main"}]'
gh_fixture "repos/org/future/rulesets?includes_parents=true&per_page=100" 200 '[]'
fresh; r=$(evaluate_branch_protection_required_patterns "org/future" "main")
check_status "padrões sem Ruleset e sem branches => pendente (branches futuras desprotegidas)" "pendente" "$r"

gh_fixture "repos/org/nobranches/branches?per_page=100" 403 "" "Resource not accessible by integration"
fresh; check_erro "403 ao listar branches => erro explícito" "$(evaluate_branch_protection_required_patterns "org/nobranches" "main")"

echo "-- Required status checks, testes e cobertura --"
fresh; check_status "todos os checks esperados obrigatórios => required-pr-checks ok" "ok" "$(evaluate_required_pr_checks "org/rs" "main")"
fresh; check_status "check de teste obrigatório => required-test-checks ok" "ok" "$(evaluate_required_test_checks "org/rs" "main")"
fresh; check_status "check coverage obrigatório => required-coverage-check ok" "ok" "$(evaluate_required_coverage_check "org/rs" "main")"

gh_fixture "repos/org/missing/branches/main/protection" 404 "" "Branch not protected"
gh_fixture "repos/org/missing/rules/branches/main" 200 "$(full_rules 3 '[{"context":"build"}]')"
fresh; r=$(evaluate_required_pr_checks "org/missing" "main")
check_status "check obrigatório ausente => required-pr-checks risco" "risco" "$r"
check_contains "evidência lista os checks faltantes" "FALTAM CodeQL, coverage, dependency-review, secret-scan, unit-tests" "$(ev "$r")"
fresh; check_status "unit-tests não obrigatório => required-test-checks risco" "risco" "$(evaluate_required_test_checks "org/missing" "main")"
fresh; r=$(evaluate_required_coverage_check "org/missing" "main")
check_status "cobertura (mode=report) não obrigatória => risco" "risco" "$r"
check_contains "evidência explica que cobertura abaixo do mínimo não bloquearia" "cobertura abaixo do mínimo ou relatório ausente não bloqueia merge" "$(ev "$r")"

fresh; REPO_CFG=$(jq -c '.coverage = {"mode":"not-applicable","not_applicable_reason":"repositório shell sem ferramenta de cobertura"} | .required_status_checks.coverage = []' <<< "$TEST_CFG")
r=$(evaluate_required_coverage_check "org/rs" "main")
check_status "coverage not-applicable justificado + testes obrigatórios => ok explícito" "ok" "$r"
check_contains "evidência declara N/A e ausência de métrica" "Nenhuma métrica de cobertura calculada" "$(ev "$r")"
fresh; REPO_CFG=$(jq -c '.coverage = {"mode":"not-applicable","not_applicable_reason":""}' <<< "$TEST_CFG")
check_status "coverage not-applicable sem justificativa => risco" "risco" "$(evaluate_required_coverage_check "org/rs" "main")"
fresh; REPO_CFG=$(jq -c '.required_status_checks.unit_tests = [] | .required_status_checks.integration_tests = []' <<< "$TEST_CFG")
check_status "nenhum check de teste declarado => required-test-checks risco" "risco" "$(evaluate_required_test_checks "org/rs" "main")"
fresh; REPO_CFG=$(jq -c '.required_status_checks = {}' <<< "$TEST_CFG")
check_status "nenhum check esperado declarado => required-pr-checks pendente" "pendente" "$(evaluate_required_pr_checks "org/rs" "main")"

echo "-- CodeQL --"
gh_fixture "repos/org/cq-default/code-scanning/default-setup" 200 '{"state":"configured","languages":["python","actions"]}'
fresh; check_status "CodeQL default setup configurado => ok" "ok" "$(evaluate_codeql_enabled "org/cq-default")"
gh_fixture "repos/org/cq-adv/code-scanning/default-setup" 200 '{"state":"not-configured"}'
gh_fixture "repos/org/cq-adv/code-scanning/analyses?tool_name=CodeQL&per_page=1" 200 "[{\"created_at\":\"$(iso_days_ago 1)\"}]"
fresh; check_status "CodeQL advanced setup com análises => ok" "ok" "$(evaluate_codeql_enabled "org/cq-adv")"
gh_fixture "repos/org/cq-none/code-scanning/default-setup" 200 '{"state":"not-configured"}'
gh_fixture "repos/org/cq-none/code-scanning/analyses?tool_name=CodeQL&per_page=1" 404 "" "no analysis found"
fresh; check_status "CodeQL ausente => codeql-enabled risco" "risco" "$(evaluate_codeql_enabled "org/cq-none")"
gh_fixture "repos/org/cq-ghas/code-scanning/default-setup" 403 "" "Advanced Security must be enabled for this repository to use code scanning."
fresh; r=$(evaluate_codeql_enabled "org/cq-ghas")
check_status "GHAS/Code Security indisponível no plano => pendente (não ok)" "pendente" "$r"
check_contains "evidência cita a limitação de plano" "recurso desabilitado ou indisponível no plano/instância" "$(ev "$r")"
gh_fixture "repos/org/cq-perm/code-scanning/default-setup" 403 "" "Resource not accessible by integration"
fresh; check_erro "403 por permissão (Code scanning alerts:read ausente) => erro" "$(evaluate_codeql_enabled "org/cq-perm")"

gh_fixture "repos/org/cq-adv/code-scanning/analyses?tool_name=CodeQL&ref=refs/heads/main&per_page=1" 200 "[{\"created_at\":\"$(iso_days_ago 2)\"}]"
fresh; check_status "análise CodeQL de 2 dias => codeql-recent ok" "ok" "$(evaluate_codeql_recent "org/cq-adv" "main")"
gh_fixture "repos/org/cq-old/code-scanning/analyses?tool_name=CodeQL&ref=refs/heads/main&per_page=1" 200 "[{\"created_at\":\"$(iso_days_ago 30)\"}]"
fresh; r=$(evaluate_codeql_recent "org/cq-old" "main")
check_status "análise CodeQL de 30 dias => codeql-recent risco (desatualizado)" "risco" "$r"
check_contains "evidência mostra idade e limite" "30 dias > limite 8" "$(ev "$r")"
gh_fixture "repos/org/cq-empty/code-scanning/analyses?tool_name=CodeQL&ref=refs/heads/main&per_page=1" 200 '[]'
fresh; check_status "nenhuma análise na branch padrão => risco" "risco" "$(evaluate_codeql_recent "org/cq-empty" "main")"

gh_fixture "repos/org/cq-alerts/code-scanning/alerts?state=open&tool_name=CodeQL&per_page=100" 200 '[{"number":11,"created_at":"2026-08-01T00:00:00Z","rule":{"security_severity_level":"critical"}},{"number":12,"created_at":"2026-08-10T00:00:00Z","rule":{"security_severity_level":"high"}},{"number":13,"created_at":"2026-08-10T00:00:00Z","rule":{"security_severity_level":"medium"}}]'
fresh; r=$(evaluate_codeql_alerts "org/cq-alerts")
check_status "alertas CodeQL high/critical abertos => risco" "risco" "$r"
check_contains "evidência conta critical e high separadamente" "critical=1, high=1" "$(ev "$r")"
gh_fixture "repos/org/cq-medium/code-scanning/alerts?state=open&tool_name=CodeQL&per_page=100" 200 '[{"number":1,"created_at":"2026-08-01T00:00:00Z","rule":{"security_severity_level":"medium"}}]'
fresh; check_status "somente alertas medium => codeql-alerts ok" "ok" "$(evaluate_codeql_alerts "org/cq-medium")"

echo "-- Dependabot e Dependency Review --"
gh_fixture "repos/org/dep/vulnerability-alerts" 204 ""
gh_fixture "repos/org/dep/dependabot/alerts?state=open&severity=critical,high&per_page=100" 200 '[{"number":1},{"number":2}]'
fresh; r=$(evaluate_dependabot_alerts_enabled "org/dep")
check_status "Dependabot alerts habilitado (204) => ok" "ok" "$r"
check_contains "evidência informa alertas critical/high abertos" "alertas Dependabot critical/high abertos: 2" "$(ev "$r")"
gh_fixture "repos/org/nodep/vulnerability-alerts" 404 "" "Not Found"
fresh; check_status "Dependabot alerts desabilitado (404) => risco" "risco" "$(evaluate_dependabot_alerts_enabled "org/nodep")"
gh_fixture "repos/org/dep/automated-security-fixes" 200 '{"enabled":true,"paused":false}'
fresh; check_status "Dependabot security updates habilitado => ok" "ok" "$(evaluate_dependabot_security_updates_enabled "org/dep")"
gh_fixture "repos/org/nodep/automated-security-fixes" 200 '{"enabled":false,"paused":false}'
fresh; check_status "Dependabot security updates desabilitado => risco" "risco" "$(evaluate_dependabot_security_updates_enabled "org/nodep")"
gh_fixture "repos/org/paused/automated-security-fixes" 200 '{"enabled":true,"paused":true}'
fresh; check_status "Dependabot security updates pausado => pendente" "pendente" "$(evaluate_dependabot_security_updates_enabled "org/paused")"

gh_fixture "repos/org/rs/contents/.github/workflows" 200 '[{"type":"file","name":"ci.yml","path":".github/workflows/ci.yml"},{"type":"file","name":"dependency-review.yml","path":".github/workflows/dependency-review.yml"}]'
gh_fixture "repos/org/rs/contents/.github/workflows/ci.yml" 200 "{\"content\":\"$(b64 'jobs: {}')\"}"
gh_fixture "repos/org/rs/contents/.github/workflows/dependency-review.yml" 200 "{\"content\":\"$(b64 '      - uses: actions/dependency-review-action@2031cfc080254a8a887f58cffee85186f0e49e48')\"}"
fresh; check_status "workflow de Dependency Review + check obrigatório => ok" "ok" "$(evaluate_dependency_review_enabled "org/rs" "main")"
gh_fixture "repos/org/missing/contents/.github/workflows" 200 '[{"type":"file","name":"dependency-review.yml","path":".github/workflows/dependency-review.yml"}]'
gh_fixture "repos/org/missing/contents/.github/workflows/dependency-review.yml" 200 "{\"content\":\"$(b64 'uses: actions/dependency-review-action@2031cfc080254a8a887f58cffee85186f0e49e48')\"}"
fresh; check_status "Dependency Review presente mas não obrigatório => pendente" "pendente" "$(evaluate_dependency_review_enabled "org/missing" "main")"
gh_fixture "repos/org/nodr/contents/.github/workflows" 200 '[{"type":"file","name":"ci.yml","path":".github/workflows/ci.yml"}]'
gh_fixture "repos/org/nodr/contents/.github/workflows/ci.yml" 200 "{\"content\":\"$(b64 'jobs: {}')\"}"
fresh; check_status "nenhum workflow de Dependency Review => risco" "risco" "$(evaluate_dependency_review_enabled "org/nodr" "main")"
fresh; check_status "sem diretório de workflows (404) => risco" "risco" "$(evaluate_dependency_review_enabled "org/semworkflows" "main")"

echo "-- Secret Scanning e Push Protection --"
fresh; REPO_META_STATUS="200"; REPO_META='{"security_and_analysis":{"secret_scanning":{"status":"enabled"},"secret_scanning_push_protection":{"status":"enabled"}}}'
check_status "Secret Scanning habilitado => ok" "ok" "$(evaluate_secret_scanning_enabled "org/ss")"
check_status "Push Protection habilitado => ok" "ok" "$(evaluate_secret_scanning_push_protection_enabled "org/ss")"
REPO_META='{"security_and_analysis":{"secret_scanning":{"status":"disabled"},"secret_scanning_push_protection":{"status":"disabled"}}}'
check_status "Secret Scanning desabilitado => risco" "risco" "$(evaluate_secret_scanning_enabled "org/ss")"
check_status "Push Protection desabilitado => risco" "risco" "$(evaluate_secret_scanning_push_protection_enabled "org/ss")"
REPO_META='{"security_and_analysis":null}'
r=$(evaluate_secret_scanning_enabled "org/ss")
check_status "security_and_analysis não retornado (permissão/plano) => pendente, nunca ok" "pendente" "$r"
check_contains "evidência explica a causa provável" "não é tratado como conforme" "$(ev "$r")"
REPO_META_STATUS="403"; REPO_META='{}'; API_ERROR="Resource not accessible by integration"
check_erro "GET /repos 403 => secret-scanning-enabled erro" "$(evaluate_secret_scanning_enabled "org/ss")"

FAKE_VALUE="FAKE-SECRET-VALUE-NOT-REAL-000"
gh_fixture "repos/org/leak/secret-scanning/alerts?state=open&per_page=100&hide_secret=true" 200 "[{\"number\":5,\"secret_type\":\"github_personal_access_token\",\"secret_type_display_name\":\"GitHub Personal Access Token\",\"secret\":\"${FAKE_VALUE}\",\"created_at\":\"2026-09-01T00:00:00Z\",\"push_protection_bypassed\":true}]"
fresh; r=$(evaluate_secret_alerts "org/leak")
check_status "alerta de secret aberto => risco" "risco" "$r"
check_contains "evidência traz tipo e bypass de push protection" "GitHub Personal Access Token" "$(ev "$r")"
check_not_contains "evidência NUNCA contém o valor do secret" "$FAKE_VALUE" "$r"
check_contains "consulta usa hide_secret=true" "hide_secret=true" "$(cat "$GH_CALL_LOG")"
gh_fixture "repos/org/clean/secret-scanning/alerts?state=open&per_page=100&hide_secret=true" 200 '[]'
fresh; check_status "sem alertas de secret => ok" "ok" "$(evaluate_secret_alerts "org/clean")"
gh_fixture "repos/org/ssoff/secret-scanning/alerts?state=open&per_page=100&hide_secret=true" 404 "" "Secret scanning is disabled on this repository."
fresh; check_status "secret scanning desabilitado => secret-alerts pendente" "pendente" "$(evaluate_secret_alerts "org/ssoff")"
gh_fixture "repos/org/ssperm/secret-scanning/alerts?state=open&per_page=100&hide_secret=true" 403 "" "Resource not accessible by integration"
fresh; check_erro "403 (Secret scanning alerts:read ausente) => erro" "$(evaluate_secret_alerts "org/ssperm")"

echo "-- Rate limit --"
gh_fixtures_reset
gh_fixture "repos/org/rl/code-scanning/default-setup" 403 "" "API rate limit exceeded for installation"
fresh; r=$(evaluate_codeql_enabled "org/rl")
check_erro "rate limit persistente => erro explícito (não ok)" "$r"
calls=$(gh_calls_matching 'api repos/org/rl/code-scanning/default-setup')
if [[ "$calls" -eq 4 ]]; then
  echo "  ✓ rate limit faz 1 chamada + 3 retries com backoff (${calls})"; pass=$((pass + 1))
else
  echo "  ✗ esperado 4 chamadas com retry, obtido ${calls}"; fail=$((fail + 1))
fi

echo "-- Configuração por repositório --"
gh_fixtures_reset
gh_fixture "repos/org/custom/contents/.github/security-governance.json" 200 "{\"content\":\"$(b64 '{"branches":{"production_branches":["prod"],"protected_patterns":["releases/*"]}}')\"}"
DEFAULT_GOVERNANCE_CONFIG="$BUILTIN_GOVERNANCE_CONFIG"
reset_repo_state; load_repo_governance_config "org/custom"
check_contains "config do repositório sobrepõe padrões (production_branches)" '["prod"]' "$(cfg_get '.branches.production_branches')"
check_contains "config do repositório sobrepõe padrões (protected_patterns)" '["releases/*"]' "$(cfg_get '.branches.protected_patterns')"
check_contains "fonte da configuração registrada" "repositório (.github/security-governance.json)" "$REPO_CFG_SOURCE"
reset_repo_state; load_repo_governance_config "org/semconfig"
check_contains "sem config no repositório => padrão da varredura (release/*, hotfix/*)" '["release/*","hotfix/*"]' "$(cfg_get '.branches.protected_patterns')"

rm -rf "$SECURITY_SCAN_SCRATCH_DIR"
echo ""
echo "Resultado: ${pass} passaram, ${fail} falharam"
(( fail > 0 )) && exit 1
echo "✓ todos os testes passaram"
