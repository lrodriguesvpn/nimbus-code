#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# tests/scripts/run-quality-gate.test.sh
#
# Issue #450 / T058: valida scripts/run-quality-gate.sh (executor extensível
# dos checks build/unit-tests/integration-tests/coverage):
#   - comando que falha => check falha (teste obrigatório falhando bloqueia);
#   - comando que passa => check passa;
#   - etapa sem comando só é aceita com justificativa, e é reportada como
#     NÃO APLICÁVEL (nunca como teste executado);
#   - configuração ausente falha.
###############################################################################

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RUNNER="${ROOT_DIR}/scripts/run-quality-gate.sh"
[[ -f "$RUNNER" ]] || { echo "✗ ${RUNNER} não encontrado"; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
pass=0
fail=0

run_stage() {
  local config="$1" stage="$2" status=0
  : > "$WORK/summary.md"
  GOVERNANCE_CONFIG="$config" GITHUB_STEP_SUMMARY="$WORK/summary.md" bash "$RUNNER" "$stage" >"$WORK/out.txt" 2>&1 || status=$?
  echo "$status"
}
expect() {
  local description="$1" expected="$2" actual="$3" pattern="${4:-}"
  if [[ "$actual" -eq "$expected" ]] && { [[ -z "$pattern" ]] || grep -Fq -- "$pattern" "$WORK/out.txt" "$WORK/summary.md"; }; then
    echo "  ✓ ${description} (exit=${actual})"; pass=$((pass + 1))
  else
    echo "  ✗ ${description} (esperado exit=${expected}${pattern:+ e '${pattern}'}, obtido=${actual})"; cat "$WORK/out.txt"; fail=$((fail + 1))
  fi
}

cat > "$WORK/cfg.json" <<'JSON'
{"quality_gates":{
  "build":{"command":"true"},
  "unit_tests":{"setup_command":"echo setup-ok","command":"echo executando; exit 3"},
  "integration_tests":{"command":"","not_applicable_reason":"sem estágio de integração separado"}
},
 "coverage":{"command":""}}
JSON

echo "== tests/scripts/run-quality-gate.test.sh =="
expect "comando de build que passa => check passa" 0 "$(run_stage "$WORK/cfg.json" build)" "build — ✓ aprovado"
expect "teste obrigatório falhando => check falha com o exit code do comando" 3 "$(run_stage "$WORK/cfg.json" unit_tests)" "Etapa 'unit_tests' falhou (exit 3)"
expect "setup_command executa antes do comando" 3 "$(run_stage "$WORK/cfg.json" unit_tests)" "setup-ok"
expect "etapa N/A com justificativa => reportada como NÃO APLICÁVEL" 0 "$(run_stage "$WORK/cfg.json" integration_tests)" "NÃO APLICÁVEL"
expect "etapa sem comando e sem justificativa => falha" 1 "$(run_stage "$WORK/cfg.json" coverage)" "sem command e sem not_applicable_reason"
expect "etapa desconhecida => falha" 1 "$(run_stage "$WORK/cfg.json" deploy)" "Etapa inválida"
expect "configuração ausente => falha" 1 "$(run_stage "$WORK/nao-existe.json" build)" "não encontrado"

echo ""
echo "Resultado: ${pass} passaram, ${fail} falharam"
(( fail > 0 )) && exit 1
echo "✓ todos os testes passaram"
