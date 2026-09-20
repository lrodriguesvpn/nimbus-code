#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# tests/scripts/process-metrics-report.audit-trail.test.sh
#
# Teste de integração (T003/T012, Feature 021, AC-3, FR-004/FR-005/FR-006):
# valida o subcomando --record-manual-adjustment (trilha de auditoria de
# ajustes manuais) e o gate de fechamento --check-review-cycle-closure
# implementados em scripts/process-metrics-report.sh.
#
# Estratégia: roda o script real dentro de um diretório temporário isolado
# (contendo apenas o arquivo docs/playbooks/dora-manual-adjustments-log.yaml
# necessário), sem precisar mockar `gh` — estes modos não chamam a API do
# GitHub.
#
# Uso: bash tests/scripts/process-metrics-report.audit-trail.test.sh
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

setup_workdir() {
  local tmpdir
  tmpdir=$(mktemp -d)
  mkdir -p "${tmpdir}/docs/playbooks"
  cat > "${tmpdir}/docs/playbooks/dora-manual-adjustments-log.yaml" <<'EOF'
adjustments:
EOF
  echo "$tmpdir"
}

echo ""
echo "=== process-metrics-report.audit-trail.test.sh ==="
echo ""

# --- Teste 1: ajuste manual completo é aceito -------------------------------
WORKDIR=$(setup_workdir)
if (cd "$WORKDIR" && "$SCRIPT_PATH" \
      --record-manual-adjustment \
      --indicator deployment_frequency \
      --justification "Fonte GitHub Actions indisponível por 6h" \
      --author testuser \
      --evidence-link "https://example.com/incident/1" \
      --exception-category fonte_indisponivel \
      --approved-by approver \
      --review-cycle-period "2026-08" >/tmp/audit_test_out_1.log 2>&1); then
  if grep -q "ADJ-0001 registrado" /tmp/audit_test_out_1.log \
     && grep -q "^  - id: ADJ-0001" "${WORKDIR}/docs/playbooks/dora-manual-adjustments-log.yaml"; then
    pass "ajuste manual completo é aceito e registrado com ID sequencial (ADJ-0001)"
  else
    fail "ajuste manual completo não foi registrado como esperado"
  fi
else
  fail "ajuste manual completo foi rejeitado indevidamente (exit != 0)"
fi
rm -rf "$WORKDIR"

# --- Teste 2: ajuste manual incompleto é rejeitado --------------------------
WORKDIR=$(setup_workdir)
if (cd "$WORKDIR" && "$SCRIPT_PATH" \
      --record-manual-adjustment \
      --indicator mttr \
      --author testuser >/tmp/audit_test_out_2.log 2>&1); then
  fail "ajuste manual incompleto (sem justification/evidence-link/exception-category) foi aceito indevidamente"
else
  if grep -q "REJEITADO" /tmp/audit_test_out_2.log \
     && grep -q -- "--justification" /tmp/audit_test_out_2.log \
     && grep -q -- "--evidence-link" /tmp/audit_test_out_2.log \
     && grep -q -- "--exception-category" /tmp/audit_test_out_2.log \
     && grep -q -- "--approved-by" /tmp/audit_test_out_2.log; then
    pass "ajuste manual incompleto é rejeitado com mensagem clara dos campos ausentes"
  else
    fail "ajuste manual incompleto foi rejeitado, mas a mensagem não lista os campos ausentes corretamente"
  fi
fi
rm -rf "$WORKDIR"

# --- Teste 3: aprovação é obrigatória mesmo com os demais campos completos --
WORKDIR=$(setup_workdir)
if (cd "$WORKDIR" && "$SCRIPT_PATH" \
      --record-manual-adjustment \
      --indicator mttr \
      --justification "Sem aprovador" \
      --author testuser \
      --evidence-link "https://example.com/incident/2" \
      --exception-category fonte_indisponivel >/tmp/audit_test_out_3.log 2>&1); then
  fail "ajuste manual sem approved_by foi aceito indevidamente"
else
  if grep -q -- "--approved-by" /tmp/audit_test_out_3.log; then
    pass "ajuste manual sem approved_by é rejeitado"
  else
    fail "ajuste manual sem approved_by foi rejeitado sem mensagem específica"
  fi
fi
rm -rf "$WORKDIR"

# --- Teste 4: IDs sequenciais em registros consecutivos ---------------------
WORKDIR=$(setup_workdir)
(cd "$WORKDIR" && "$SCRIPT_PATH" \
    --record-manual-adjustment --indicator deployment_frequency \
    --justification "Motivo 1" --author user1 \
    --evidence-link "https://example.com/1" --exception-category fonte_indisponivel --approved-by approver \
    --review-cycle-period "2026-08" \
    >/dev/null 2>&1)
(cd "$WORKDIR" && "$SCRIPT_PATH" \
    --record-manual-adjustment --indicator lead_time_for_changes \
    --justification "Motivo 2" --author user2 \
    --evidence-link "https://example.com/2" --exception-category evento_duplicado --approved-by approver \
    --review-cycle-period "2026-08" \
    >/dev/null 2>&1)
if grep -q "^  - id: ADJ-0001" "${WORKDIR}/docs/playbooks/dora-manual-adjustments-log.yaml" \
   && grep -q "^  - id: ADJ-0002" "${WORKDIR}/docs/playbooks/dora-manual-adjustments-log.yaml"; then
  pass "IDs sequenciais (ADJ-0001, ADJ-0002) gerados corretamente em registros consecutivos"
else
  fail "IDs sequenciais não foram gerados corretamente"
fi

# --- Teste 5: gate de fechamento bloqueia com ajuste incompleto no período --
# Injeta uma entrada com campo obrigatório vazio, simulando edição manual
# direta do arquivo (não via subcomando --record-manual-adjustment).
cat >> "${WORKDIR}/docs/playbooks/dora-manual-adjustments-log.yaml" <<'EOF'
  - id: ADJ-0003
    indicator: change_failure_rate
    justification: "Correção retroativa"
    author: "user3"
    timestamp: "2026-08-31T00:00:00Z"
    evidence_link: ""
    exception_category: "correcao_retroativa"
    approved_by: "user3"
    review_cycle_period: "2026-08"
EOF

if (cd "$WORKDIR" && "$SCRIPT_PATH" --check-review-cycle-closure --review-cycle-period "2026-08" >/tmp/audit_test_out_4.log 2>&1); then
  fail "gate de fechamento reportou CLOSURE_OK indevidamente com ajuste incompleto (ADJ-0003 sem evidence_link)"
else
  if grep -q "CLOSURE_BLOCKED: ADJ-0003" /tmp/audit_test_out_4.log; then
    pass "gate de fechamento bloqueia corretamente (CLOSURE_BLOCKED) com ajuste incompleto (FR-006)"
  else
    fail "gate de fechamento bloqueou, mas não identificou o ID do ajuste pendente corretamente"
  fi
fi

# --- Teste 6: gate de fechamento aprova período sem ajustes pendentes ------
if (cd "$WORKDIR" && "$SCRIPT_PATH" --check-review-cycle-closure --review-cycle-period "2026-09" >/tmp/audit_test_out_5.log 2>&1); then
  if grep -q "CLOSURE_OK" /tmp/audit_test_out_5.log; then
    pass "gate de fechamento aprova (CLOSURE_OK) período sem nenhum ajuste manual pendente"
  else
    fail "gate de fechamento não reportou CLOSURE_OK para período sem ajustes"
  fi
else
  fail "gate de fechamento retornou exit != 0 para período sem ajustes pendentes"
fi

rm -rf "$WORKDIR" /tmp/audit_test_out_*.log

echo ""
echo "Resultado: ${PASS} passou(aram), ${FAIL} falhou(aram)"
echo ""

[[ "$FAIL" -eq 0 ]]
