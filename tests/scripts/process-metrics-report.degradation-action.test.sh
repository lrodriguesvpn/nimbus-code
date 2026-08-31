#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# tests/scripts/process-metrics-report.degradation-action.test.sh
#
# Teste de integração (T017, Feature 021, FR-008/FR-009, AC-5): valida os
# gatilhos objetivos de degradação implementados em
# scripts/process-metrics-report.sh, que sinalizam quando um indicador cruza
# a meta inicial já documentada em docs/playbooks/README.md.
#
# Estratégia: mesmo mock de `gh` usado em process-metrics-report.detect.test.sh
# — fixtures controladas para forçar cada indicador acima/abaixo da meta.
#
# Uso: bash tests/scripts/process-metrics-report.degradation-action.test.sh
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

SINCE="2026-01-01"
UNTIL="2026-01-31"
EMPTY_FIXTURE='[]'

# Fixture: apenas 1 deploy no mês inteiro (~0.23/semana) — abaixo da meta (>= 1/semana)
LOW_DEPLOY_FIXTURE='[
  {"number":1,"createdAt":"2026-01-05T10:00:00Z","mergedAt":"2026-01-06T10:00:00Z"}
]'

# Fixture: 4 deploys/semana (bem acima da meta) — não deve gerar sinal
HEALTHY_DEPLOY_FIXTURE='[
  {"number":1,"createdAt":"2026-01-02T10:00:00Z","mergedAt":"2026-01-02T12:00:00Z"},
  {"number":2,"createdAt":"2026-01-05T10:00:00Z","mergedAt":"2026-01-05T12:00:00Z"},
  {"number":3,"createdAt":"2026-01-08T10:00:00Z","mergedAt":"2026-01-08T12:00:00Z"},
  {"number":4,"createdAt":"2026-01-12T10:00:00Z","mergedAt":"2026-01-12T12:00:00Z"},
  {"number":5,"createdAt":"2026-01-15T10:00:00Z","mergedAt":"2026-01-15T12:00:00Z"},
  {"number":6,"createdAt":"2026-01-19T10:00:00Z","mergedAt":"2026-01-19T12:00:00Z"},
  {"number":7,"createdAt":"2026-01-22T10:00:00Z","mergedAt":"2026-01-22T12:00:00Z"},
  {"number":8,"createdAt":"2026-01-26T10:00:00Z","mergedAt":"2026-01-26T12:00:00Z"}
]'

# Fixture: lead time de 10 dias (acima da meta de <= 7 dias)
HIGH_LEAD_TIME_FIXTURE='[
  {"number":1,"createdAt":"2026-01-05T10:00:00Z","mergedAt":"2026-01-15T10:00:00Z"}
]'

run_with_mock() {
  local deploy_fixture="$1"
  local lead_fixture="$2"
  local failure_issue_fixture="$3"
  local failure_pr_fixture="$4"
  local mttr_fixture="$5"

  local tmpdir
  tmpdir=$(mktemp -d)
  echo "$deploy_fixture" > "${tmpdir}/deploy.json"
  echo "$lead_fixture"   > "${tmpdir}/lead.json"
  echo "$failure_issue_fixture" > "${tmpdir}/failure_issues.json"
  echo "$failure_pr_fixture"    > "${tmpdir}/failure_prs.json"
  echo "$mttr_fixture"   > "${tmpdir}/mttr.json"

  cat > "${tmpdir}/gh" <<GHSCRIPT
#!/usr/bin/env bash
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

  PATH="${tmpdir}:${PATH}" bash "$SCRIPT_PATH" \
    --repo-owner "test-org" \
    --repo-name "test-repo" \
    --since "$SINCE" \
    --until "$UNTIL" \
    2>/dev/null

  rm -rf "$tmpdir"
}

echo ""
echo "=== process-metrics-report.degradation-action.test.sh ==="
echo ""

# --- Teste 1: gatilho de degradação atingido (deployment_frequency baixo) ---
OUTPUT=$(run_with_mock "$LOW_DEPLOY_FIXTURE" "$EMPTY_FIXTURE" "$EMPTY_FIXTURE" "$EMPTY_FIXTURE" "$EMPTY_FIXTURE" 2>/dev/null || true)
if echo "$OUTPUT" | grep -qi "deployment_frequency abaixo da meta"; then
  pass "gatilho de degradação atingido gera sinal esperado (deployment_frequency abaixo da meta)"
else
  fail "esperava sinal de degradação para deployment_frequency baixo, obteve: $(echo "$OUTPUT" | grep -i "degrada\|meta" || echo '(nada)')"
fi

# --- Teste 2: gatilho de degradação atingido (lead_time_for_changes alto) ---
OUTPUT=$(run_with_mock "$EMPTY_FIXTURE" "$HIGH_LEAD_TIME_FIXTURE" "$EMPTY_FIXTURE" "$EMPTY_FIXTURE" "$EMPTY_FIXTURE" 2>/dev/null || true)
if echo "$OUTPUT" | grep -qi "lead_time_for_changes acima da meta"; then
  pass "gatilho de degradação atingido gera sinal esperado (lead_time_for_changes acima da meta)"
else
  fail "esperava sinal de degradação para lead time alto, obteve: $(echo "$OUTPUT" | grep -i "degrada\|meta" || echo '(nada)')"
fi

# --- Teste 3: sem degradação, nenhuma ação é sinalizada ---
OUTPUT=$(run_with_mock "$HEALTHY_DEPLOY_FIXTURE" "$EMPTY_FIXTURE" "$EMPTY_FIXTURE" "$EMPTY_FIXTURE" "$EMPTY_FIXTURE" 2>/dev/null || true)
if echo "$OUTPUT" | grep -qi "nenhum indicador abaixo/acima da meta"; then
  pass "sem degradação, nenhuma ação de backlog é sinalizada"
else
  fail "esperava confirmação de ausência de degradação, obteve: $(echo "$OUTPUT" | grep -i "meta\|degrada" || echo '(nada)')"
fi

# --- Teste 4: sinal orienta a ação de backlog (owner/priority/prazo) ---
OUTPUT=$(run_with_mock "$LOW_DEPLOY_FIXTURE" "$EMPTY_FIXTURE" "$EMPTY_FIXTURE" "$EMPTY_FIXTURE" "$EMPTY_FIXTURE" 2>/dev/null || true)
if echo "$OUTPUT" | grep -qi "owner.*priority.*prazo\|Abra/atualize uma Issue"; then
  pass "sinal de degradação orienta explicitamente a ação de backlog (owner/priority/prazo)"
else
  fail "esperava orientação de ação de backlog junto ao sinal, obteve: $(echo "$OUTPUT" | grep -i "issue\|owner" || echo '(nada)')"
fi

echo ""
echo "Resultado: ${PASS} passou(aram), ${FAIL} falhou(aram)"
echo ""

[[ "$FAIL" -eq 0 ]]
