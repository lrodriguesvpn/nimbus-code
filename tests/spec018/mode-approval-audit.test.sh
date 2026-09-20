#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# tests/spec018/mode-approval-audit.test.sh
#
# Valida T003, T013, T014, T015, T016 da SPEC 018:
#   - Classificação de modos de autonomia conforme SPEC 017:
#     * Autônomo (P2/P3 sem risco crítico)
#     * Semiautônomo (P1 / múltiplos módulos / integração)
#     * Manual (P0 / segurança / auth / destruição de dados)
#   - Checkpoints de aprovação humana Go / No-Go
#   - Registro e consulta de auditoria estruturada
###############################################################################

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENGINE="${ROOT_DIR}/scripts/nimbus-intake-engine.sh"

pass=0
fail=0

check() {
  local description="$1" condition="$2"
  if [[ "$condition" == "true" ]]; then
    echo "  ✓ ${description}"
    pass=$((pass + 1))
  else
    echo "  ✗ ${description}"
    fail=$((fail + 1))
  fi
}

echo "=== tests/spec018/mode-approval-audit.test.sh ==="

TMP_DIR="$(mktemp -d /tmp/nimbus-mode-test-XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

audit_file="$TMP_DIR/audit.log"

# 1. Classificação Modo Autônomo
cat << 'EOF' > "$TMP_DIR/intake-auto.json"
{
  "source_event_id": "evt-001",
  "title": "Ajuste de documentação e README",
  "description": "Atualizar texto explicativo",
  "priority": "P3"
}
EOF

mode_auto="$("$ENGINE" decide-mode --envelope "$TMP_DIR/intake-auto.json")"
check "Demanda P3 simples é classificada como autonomous" "$([[ $(echo "$mode_auto" | jq -r '.mode') == "autonomous" ]] && echo true || echo false)"
check "Classificação autônoma inclui regras avaliadas" "$([[ $(echo "$mode_auto" | jq -r '.rules_evaluated | length') -gt 0 ]] && echo true || echo false)"

# 2. Classificação Modo Semiautônomo (P1 ou multi-repo)
cat << 'EOF' > "$TMP_DIR/intake-semi.json"
{
  "source_event_id": "evt-002",
  "title": "Integração multi-repo com satélite",
  "description": "Orquestração entre serviços",
  "priority": "P1"
}
EOF

mode_semi="$("$ENGINE" decide-mode --envelope "$TMP_DIR/intake-semi.json")"
check "Demanda P1 multi-repo é classificada como semi-autonomous" "$([[ $(echo "$mode_semi" | jq -r '.mode') == "semi-autonomous" ]] && echo true || echo false)"

# 3. Classificação Modo Manual (Segurança, Auth, P0, S4)
cat << 'EOF' > "$TMP_DIR/intake-manual.json"
{
  "source_event_id": "evt-003",
  "title": "Refatoração crítica de Auth e Segurança",
  "description": "Alteração de tokens e regras de segurança",
  "priority": "P0"
}
EOF

mode_man="$("$ENGINE" decide-mode --envelope "$TMP_DIR/intake-manual.json")"
check "Demanda P0 / Segurança é classificada como manual" "$([[ $(echo "$mode_man" | jq -r '.mode') == "manual" ]] && echo true || echo false)"

# 4. Registro de Aprovação Go
appr_go="$("$ENGINE" record-approval --id "evt-003" --decision "go" --approver "tech-lead-user" --reason "Aprovado em Architecture Board" --audit "$audit_file")"
check "Aprovação Go resulta em status approved_ready_for_execution" "$([[ $(echo "$appr_go" | jq -r '.status') == "approved_ready_for_execution" ]] && echo true || echo false)"

# 5. Registro de Aprovação No-Go
appr_nogo="$("$ENGINE" record-approval --id "evt-004" --decision "no-go" --approver "security-officer" --reason "Risco excessivo de compliance" --audit "$audit_file")"
check "Decisão No-Go resulta em status rejected_execution_blocked" "$([[ $(echo "$appr_nogo" | jq -r '.status') == "rejected_execution_blocked" ]] && echo true || echo false)"

# 6. Verificação do Audit Trail
check "Trilha de auditoria gerou registros com timestamp" "$([[ $(grep -c 'audit_timestamp' "$audit_file") -ge 2 ]] && echo true || echo false)"
check "Auditoria identifica o aprovador e motivo" "$([[ $(grep -c 'tech-lead-user' "$audit_file") -ge 1 ]] && echo true || echo false)"

echo "Resultado: ${pass} passou(aram), ${fail} falhou(aram)"
if [[ "$fail" -gt 0 ]]; then
  exit 1
fi
