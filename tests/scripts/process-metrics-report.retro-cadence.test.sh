#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# tests/scripts/process-metrics-report.retro-cadence.test.sh
#
# Teste de integração (T016, Feature 012, AC-4): valida a sinalização
# proativa de retrospectiva via --check-retro-cadence em
# scripts/process-metrics-report.sh
#
# Uso: bash tests/scripts/process-metrics-report.retro-cadence.test.sh
###############################################################################

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_PATH="${ROOT_DIR}/scripts/process-metrics-report.sh"
PASS=0
FAIL=0

pass() { echo "✓ $1"; PASS=$((PASS+1)); }
fail() { echo "✗ $1"; FAIL=$((FAIL+1)); }

if [[ ! -f "$SCRIPT_PATH" ]]; then
  echo "✗ ${SCRIPT_PATH} não encontrado"
  exit 1
fi

# Helper: cria estado temporário do retro-cadence e executa o script
run_with_state() {
  local features_since="$1"
  local cadence_n="$2"
  local last_retro="$3"

  local tmpdir
  tmpdir=$(mktemp -d)

  # Cria mock gh que retorna listas vazias (não testamos DORA aqui)
  cat > "${tmpdir}/gh" <<'GHSCRIPT'
#!/usr/bin/env bash
echo "[]"
exit 0
GHSCRIPT
  chmod +x "${tmpdir}/gh"

  # Cria estado de cadência temporário
  mkdir -p "${tmpdir}/docs/playbooks"
  cat > "${tmpdir}/docs/playbooks/retro-cadence-state.yaml" <<YAMLEOF
features_since_last_retro: ${features_since}
retro_cadence_n: ${cadence_n}
last_retro_date: ${last_retro}
YAMLEOF

  # Executa o script a partir do tmpdir para que ele leia o state file correto
  (
    cd "${tmpdir}"
    PATH="${tmpdir}:${PATH}" bash "$SCRIPT_PATH" \
      --repo-owner "test-org" \
      --repo-name "test-repo" \
      --since "2026-01-01" \
      --until "2026-01-31" \
      --check-retro-cadence \
      2>/dev/null
  )

  rm -rf "$tmpdir"
}

echo ""
echo "=== process-metrics-report.retro-cadence.test.sh ==="
echo ""

# Teste 1: contador atinge limiar (features_since=5, cadence_n=5) — deve sinalizar
OUTPUT=$(run_with_state 5 5 "2026-01-01" 2>/dev/null || true)
if echo "$OUTPUT" | grep -qi "retrospectiva\|retro"; then
  pass "Sinalização quando features_since_last_retro >= retro_cadence_n (5 >= 5)"
else
  fail "Esperava sinalização de retro devida (5>=5), obteve: $(echo "$OUTPUT" | tail -5)"
fi

# Teste 2: contador abaixo do limiar (features_since=3, cadence_n=5) — não deve sinalizar
OUTPUT=$(run_with_state 3 5 "2026-01-01" 2>/dev/null || true)
if echo "$OUTPUT" | grep -qi "retrospectiva proativa\|retro.*devida"; then
  fail "Não devia sinalizar retro com features_since=3 < cadence_n=5"
else
  pass "Sem sinalização quando features_since_last_retro < retro_cadence_n (3 < 5)"
fi

# Teste 3: atraso acumulado (features_since=10, cadence_n=5) — sinaliza sem bloquear
EXIT_CODE=0
OUTPUT=$(run_with_state 10 5 "2025-12-01" 2>/dev/null) || EXIT_CODE=$?
if echo "$OUTPUT" | grep -qi "retrospectiva\|retro"; then
  pass "Sinaliza atraso acumulado (features_since=10 > cadence_n=5)"
else
  fail "Esperava sinalização de atraso acumulado (10>5), obteve: $(echo "$OUTPUT" | tail -5)"
fi
# Verifica que não bloqueou (exit code 0)
if [[ "$EXIT_CODE" -eq 0 ]]; then
  pass "Atraso acumulado reportado sem bloquear (exit code 0)"
else
  fail "Script saiu com código não-zero ($EXIT_CODE) para atraso acumulado — devia ser não-bloqueante"
fi

# Resumo
echo ""
echo "Resultado: ${PASS} passou(aram), ${FAIL} falhou(aram)"
echo ""

[[ "$FAIL" -eq 0 ]] && exit 0 || exit 1
