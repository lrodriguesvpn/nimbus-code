#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# tests/scripts/validate-security-governance.test.sh
#
# Issue #450 / T056: valida scripts/validate-security-governance.sh (check
# obrigatório `governance-config`) com a configuração real do repositório e
# com mutações que DEVEM falhar.
###############################################################################

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VALIDATOR="${ROOT_DIR}/scripts/validate-security-governance.sh"
[[ -f "$VALIDATOR" ]] || { echo "✗ ${VALIDATOR} não encontrado"; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
pass=0
fail=0

fresh_copy() {
  rm -rf "$WORK/root"
  mkdir -p "$WORK/root"
  cp -r "${ROOT_DIR}/.github" "$WORK/root/.github"
}
run_validator() {
  local status=0
  bash "$VALIDATOR" --root "$WORK/root" --today "${TODAY:-2026-09-22}" >"$WORK/out.txt" 2>&1 || status=$?
  echo "$status"
}
expect() {
  local description="$1" expected="$2" pattern="${3:-}" status
  status=$(run_validator)
  if [[ "$status" -eq "$expected" ]] && { [[ -z "$pattern" ]] || grep -Fq -- "$pattern" "$WORK/out.txt"; }; then
    echo "  ✓ ${description} (exit=${status})"; pass=$((pass + 1))
  else
    echo "  ✗ ${description} (esperado exit=${expected}${pattern:+ e '${pattern}'}, obtido=${status})"; sed 's/^/      /' "$WORK/out.txt" | grep -E 'error|✗|✓' | head -8; fail=$((fail + 1))
  fi
}
jq_edit() {
  local file="$1" filter="$2"
  jq "$filter" "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}

echo "== tests/scripts/validate-security-governance.test.sh =="

fresh_copy
expect "configuração versionada do repositório é válida" 0 "Governança de segurança válida"

fresh_copy
jq_edit "$WORK/root/.github/security-governance.json" '.branch_rules.required_approving_review_count = 0'
expect "0 aprovadores obrigatórios falha" 1 "required_approving_review_count deve ser inteiro >= 1"

fresh_copy
jq_edit "$WORK/root/.github/security-governance.json" '.branch_rules.block_force_push = false'
expect "force push liberado sem exceção falha" 1 "branch_rules.block_force_push deve ser true"

fresh_copy
jq_edit "$WORK/root/.github/security-governance.json" '.required_status_checks.coverage = ["coverage"]'
expect "coverage N/A listado como required check falha (sem check fictício)" 1 "coverage N/A não pode constar"

fresh_copy
jq_edit "$WORK/root/.github/security-governance.json" '.required_status_checks.integration_tests = ["integration-tests"]'
expect "etapa de integração N/A listada como obrigatória falha" 1 "um check N/A não pode ser obrigatório"

fresh_copy
jq_edit "$WORK/root/.github/security-governance.json" '.coverage.mode = "report" | .coverage.report_path = "coverage/lcov.info" | .required_status_checks.coverage = ["coverage"] | .coverage.global_min_percent = 60'
expect "cobertura mínima < 80% sem exceção falha" 1 "abaixo do mínimo de 80%"

fresh_copy
jq_edit "$WORK/root/.github/security-governance.json" '.required_status_checks.sast = []'
expect "SAST fora dos required checks falha" 1 "required_status_checks.sast não pode ser vazio"

fresh_copy
jq_edit "$WORK/root/.github/security-governance.json" '.dependency_review.unsupported_behavior = "advisory"'
expect "Dependency Review advisory sem exceção falha" 1 "exige exceção ativa 'dependency-review-enabled'"

fresh_copy
jq_edit "$WORK/root/.github/security-exceptions.json" '.exceptions = [{"id":"EXC-1","control":"dependency-review-enabled","owner":"@dono","justification":"GHAS em contratação","approved_by":"@seguranca","created_at":"2026-09-01","expires_at":"2026-10-01"}]'
jq_edit "$WORK/root/.github/security-governance.json" '.dependency_review.unsupported_behavior = "advisory"'
expect "Dependency Review advisory com exceção ativa é aceito" 0

fresh_copy
jq_edit "$WORK/root/.github/security-exceptions.json" '.exceptions = [{"id":"EXC-2","control":"codeql-alerts","owner":"@dono","justification":"falso positivo","approved_by":"@seguranca","created_at":"2026-06-01","expires_at":"2026-07-01"}]'
expect "exceção vencida falha o check" 1 "exceção EXPIRADA em 2026-07-01"

fresh_copy
jq_edit "$WORK/root/.github/security-exceptions.json" '.exceptions = [{"id":"EXC-3","control":"coverage","owner":"@dono","justification":"x","approved_by":"@seguranca","created_at":"2026-01-01","expires_at":"2026-12-31"}]'
expect "exceção acima de 90 dias falha" 1 "excede o máximo de 90"

fresh_copy
jq_edit "$WORK/root/.github/security-exceptions.json" '.exceptions = [{"id":"EXC-4","control":"coverage","owner":"@dono","created_at":"2026-09-01","expires_at":"2026-10-01"}]'
expect "exceção sem justificativa/aprovador falha" 1 "campos obrigatórios ausentes: justification, approved_by"

fresh_copy
sed -i 's#actions/checkout@d23441a48e516b6c34aea4fa41551a30e30af803 \# v6.1.0#actions/checkout@latest#' "$WORK/root/.github/workflows/codeql.yml"
expect "Action com @latest falha" 1 "referência móvel proibida"

fresh_copy
sed -i 's#actions/checkout@d23441a48e516b6c34aea4fa41551a30e30af803 \# v6.1.0#actions/checkout@v6#' "$WORK/root/.github/workflows/secret-scan.yml"
expect "workflow de governança fixado por tag (não SHA) falha" 1 "secret-scan.yml"

fresh_copy
sed -i '/^permissions:/,/^$/d' "$WORK/root/.github/workflows/pr-quality-gates.yml"
expect "workflow de governança sem permissions de topo falha" 1 "pr-quality-gates.yml: bloco 'permissions:' de topo ausente"

fresh_copy
sed -i 's/^fail-on-severity: high/fail-on-severity: critical/' "$WORK/root/.github/dependency-review-config.yml"
expect "Dependency Review mais permissivo que high falha" 1 "mais permissivo que 'high'"

fresh_copy
rm "$WORK/root/.github/dependabot.yml"
expect "dependabot.yml ausente falha" 1 "dependabot.yml: arquivo obrigatório ausente"

echo ""
echo "Resultado: ${pass} passaram, ${fail} falharam"
(( fail > 0 )) && exit 1
echo "✓ todos os testes passaram"
