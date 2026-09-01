#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# tests/scripts/process-metrics-report.detect.test.sh
#
# Teste de integração (T012, Feature 012, AC-2): valida o cálculo dos 4
# indicadores DORA implementados em scripts/process-metrics-report.sh
#
# Estendido (T007, Feature 021, FR-011): cobre também as regras de qualidade
# de dados (duplicidade e consistência temporal) adicionadas à coleta
# automática existente.
#
# Estratégia: sobrepõe `gh` com uma função bash que retorna fixtures JSON
# em memória (sem chamar a API real), depois executa o script real e valida
# a saída via grep/assert.
#
# Uso: bash tests/scripts/process-metrics-report.detect.test.sh
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

# --- Fixtures ----------------------------------------------------------------
# Data base para os testes: 2026-01-01 a 2026-01-31
SINCE="2026-01-01"
UNTIL="2026-01-31"

# Fixture: 3 PRs com dora:deployment-frequency, todos fechados dentro do período
DEPLOY_FIXTURE='[
  {"number":1,"createdAt":"2026-01-05T10:00:00Z","mergedAt":"2026-01-06T10:00:00Z"},
  {"number":2,"createdAt":"2026-01-12T10:00:00Z","mergedAt":"2026-01-13T10:00:00Z"},
  {"number":3,"createdAt":"2026-01-20T10:00:00Z","mergedAt":"2026-01-21T10:00:00Z"}
]'

# Fixture: 2 PRs com dora:lead-time (lead time ~1 dia e ~2 dias)
LEAD_FIXTURE='[
  {"number":1,"createdAt":"2026-01-05T10:00:00Z","mergedAt":"2026-01-06T10:00:00Z"},
  {"number":2,"createdAt":"2026-01-12T10:00:00Z","mergedAt":"2026-01-14T10:00:00Z"}
]'

# Fixture: 1 issue de change-failure-rate no período
FAILURE_FIXTURE='[
  {"number":10,"createdAt":"2026-01-10T10:00:00Z","closedAt":"2026-01-10T12:00:00Z"}
]'

# Fixture: 1 issue de mttr (2 horas de resolução)
MTTR_FIXTURE='[
  {"number":20,"createdAt":"2026-01-15T08:00:00Z","closedAt":"2026-01-15T10:00:00Z"}
]'

# Fixture vazia para caso sem dados
EMPTY_FIXTURE='[]'

# Fixture com item duplicado (mesmo number aparecendo duas vezes) — T007,
# feature 021, FR-011: checagem de ausência de duplicidade
DUPLICATE_FIXTURE='[
  {"number":1,"createdAt":"2026-01-05T10:00:00Z","mergedAt":"2026-01-06T10:00:00Z"},
  {"number":1,"createdAt":"2026-01-05T10:00:00Z","mergedAt":"2026-01-06T10:00:00Z"}
]'

# Fixture com inconsistência temporal (mergedAt antes de createdAt) — T007,
# feature 021, FR-011: checagem de consistência temporal
TEMPORAL_INCONSISTENCY_FIXTURE='[
  {"number":99,"createdAt":"2026-01-20T10:00:00Z","mergedAt":"2026-01-15T10:00:00Z"}
]'

# --- Mock do gh CLI ----------------------------------------------------------
# Intercepta `gh pr list` / `gh issue list` e retorna fixtures por label.
# O mock é exportado para que o sub-shell do script possa usá-lo via 'source'.
export MOCK_MODE="on"

run_with_mock() {
  local deploy_fixture="$1"
  local lead_fixture="$2"
  local failure_issue_fixture="$3"
  local failure_pr_fixture="$4"
  local mttr_fixture="$5"

  # Escreve fixtures em arquivos temporários
  local tmpdir
  tmpdir=$(mktemp -d)
  echo "$deploy_fixture" > "${tmpdir}/deploy.json"
  echo "$lead_fixture"   > "${tmpdir}/lead.json"
  echo "$failure_issue_fixture" > "${tmpdir}/failure_issues.json"
  echo "$failure_pr_fixture"    > "${tmpdir}/failure_prs.json"
  echo "$mttr_fixture"   > "${tmpdir}/mttr.json"

  # Cria script wrapper do gh que lê os fixtures
  cat > "${tmpdir}/gh" <<GHSCRIPT
#!/usr/bin/env bash
# Detecta qual label está sendo solicitado pelo argumento --label
args=("\$@")
label=""
for ((i=0; i<\${#args[@]}; i++)); do
  if [[ "\${args[i]}" == "--label" ]]; then
    label="\${args[i+1]}"
    break
  fi
done

subcommand="\${args[0]:-}"

case "\${label}" in
  "dora:deployment-frequency")
    if [[ "\$subcommand" == "pr" ]]; then
      cat "${tmpdir}/deploy.json"; exit 0
    fi
    echo "[]"; exit 0
    ;;
  "dora:lead-time")
    cat "${tmpdir}/lead.json"; exit 0
    ;;
  "dora:change-failure-rate")
    if [[ "\$subcommand" == "pr" ]]; then
      cat "${tmpdir}/failure_prs.json"; exit 0
    else
      cat "${tmpdir}/failure_issues.json"; exit 0
    fi
    ;;
  "dora:mttr")
    cat "${tmpdir}/mttr.json"; exit 0
    ;;
  *)
    echo "[]"; exit 0
    ;;
esac
GHSCRIPT
  chmod +x "${tmpdir}/gh"

  # Executa o script com o mock no PATH
  PATH="${tmpdir}:${PATH}" bash "$SCRIPT_PATH" \
    --repo-owner "test-org" \
    --repo-name "test-repo" \
    --since "$SINCE" \
    --until "$UNTIL" \
    2>/dev/null

  rm -rf "$tmpdir"
}

# --- Testes ------------------------------------------------------------------

echo ""
echo "=== process-metrics-report.detect.test.sh ==="
echo ""

# Teste 1: deployment_frequency conta corretamente itens com dora:deployment-frequency
OUTPUT=$(run_with_mock "$DEPLOY_FIXTURE" "$LEAD_FIXTURE" "$FAILURE_FIXTURE" "$EMPTY_FIXTURE" "$MTTR_FIXTURE" 2>/dev/null || true)
if echo "$OUTPUT" | grep -q "3 deploys"; then
  pass "deployment_frequency: conta 3 itens com dora:deployment-frequency"
else
  fail "deployment_frequency: esperava '3 deploys' na saída, obteve: $(echo "$OUTPUT" | grep -i deploy || echo '(nada)')"
fi

# Teste 2: indicador sem dado suficiente sinalizado como INSUFFICIENT_DATA
OUTPUT_EMPTY=$(run_with_mock "$EMPTY_FIXTURE" "$EMPTY_FIXTURE" "$EMPTY_FIXTURE" "$EMPTY_FIXTURE" "$EMPTY_FIXTURE" 2>/dev/null || true)
if echo "$OUTPUT_EMPTY" | grep -q "INSUFFICIENT_DATA"; then
  pass "INSUFFICIENT_DATA: sinaliza corretamente quando não há itens no período"
else
  fail "INSUFFICIENT_DATA: esperava sinalização de dados insuficientes, obteve: $(echo "$OUTPUT_EMPTY" | head -5)"
fi

# Teste 3: change_failure_rate calculado como proporção correta (1 falha / 3 deploys = 33.3%)
OUTPUT=$(run_with_mock "$DEPLOY_FIXTURE" "$LEAD_FIXTURE" "$FAILURE_FIXTURE" "$EMPTY_FIXTURE" "$MTTR_FIXTURE" 2>/dev/null || true)
if echo "$OUTPUT" | grep -q "33.3%\|33,3%"; then
  pass "change_failure_rate: 33.3% (1 falha / 3 deploys)"
else
  fail "change_failure_rate: esperava '33.3%', obteve: $(echo "$OUTPUT" | grep -i "failure\|falha" || echo '(nada)')"
fi

# Teste 4: MTTR calculado (2 horas)
OUTPUT=$(run_with_mock "$DEPLOY_FIXTURE" "$LEAD_FIXTURE" "$FAILURE_FIXTURE" "$EMPTY_FIXTURE" "$MTTR_FIXTURE" 2>/dev/null || true)
if echo "$OUTPUT" | grep -qi "2.00 horas\|2,00 horas\|2.0 horas"; then
  pass "MTTR: 2.00 horas calculado corretamente"
else
  fail "MTTR: esperava ~2.00 horas, obteve: $(echo "$OUTPUT" | grep -i "mttr\|hora" || echo '(nada)')"
fi

# Teste 5: qualidade de dados detecta item duplicado (T007, FR-011)
OUTPUT=$(run_with_mock "$DUPLICATE_FIXTURE" "$EMPTY_FIXTURE" "$EMPTY_FIXTURE" "$EMPTY_FIXTURE" "$EMPTY_FIXTURE" 2>/dev/null || true)
if echo "$OUTPUT" | grep -qi "duplicidade detectada.*#1"; then
  pass "qualidade de dados: duplicidade detectada corretamente (item #1 repetido)"
else
  fail "qualidade de dados: esperava alerta de duplicidade para #1, obteve: $(echo "$OUTPUT" | grep -i "duplicidade\|qualidade" || echo '(nada)')"
fi

# Teste 6: qualidade de dados detecta inconsistência temporal (T007, FR-011)
OUTPUT=$(run_with_mock "$TEMPORAL_INCONSISTENCY_FIXTURE" "$EMPTY_FIXTURE" "$EMPTY_FIXTURE" "$EMPTY_FIXTURE" "$EMPTY_FIXTURE" 2>/dev/null || true)
if echo "$OUTPUT" | grep -qi "inconsistência temporal.*#99"; then
  pass "qualidade de dados: inconsistência temporal detectada corretamente (item #99 fechado antes de criado)"
else
  fail "qualidade de dados: esperava alerta de inconsistência temporal para #99, obteve: $(echo "$OUTPUT" | grep -i "inconsistência\|qualidade" || echo '(nada)')"
fi

# Teste 7: sem duplicidade/inconsistência, nenhum alerta de qualidade é emitido
OUTPUT=$(run_with_mock "$DEPLOY_FIXTURE" "$LEAD_FIXTURE" "$FAILURE_FIXTURE" "$EMPTY_FIXTURE" "$MTTR_FIXTURE" 2>/dev/null || true)
if echo "$OUTPUT" | grep -q "nenhuma duplicidade ou inconsistência"; then
  pass "qualidade de dados: nenhum alerta falso-positivo com dados limpos"
else
  fail "qualidade de dados: esperava confirmação de dados limpos, obteve: $(echo "$OUTPUT" | grep -i "qualidade" || echo '(nada)')"
fi

# Resumo
echo ""
echo "Resultado: ${PASS} passou(aram), ${FAIL} falhou(aram)"
echo ""

[[ "$FAIL" -eq 0 ]] && exit 0 || exit 1
