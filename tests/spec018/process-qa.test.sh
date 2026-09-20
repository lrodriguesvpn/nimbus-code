#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# tests/spec018/process-qa.test.sh
#
# Valida T002, T010, T011, T012 da SPEC 018:
#   - Precedência de fontes e respostas baseadas em evidências
#   - Respostas para as fases do ciclo de vida (specify, plan, tasks, implement, etc.)
#   - Identificação de perguntas fora de escopo
#   - Detecção de ambiguidades gerando needs_clarification e clarification_question
#   - Validação de schema do contrato de resposta (process-qa.contract.md)
###############################################################################

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
QA_SCRIPT="${ROOT_DIR}/scripts/nimbus-process-qa.sh"

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

echo "=== tests/spec018/process-qa.test.sh ==="

TMP_DIR="$(mktemp -d /tmp/nimbus-qa-test-XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

# 1. Pergunta no escopo sobre Descoberta / Entrevista
q1_out="$("$QA_SCRIPT" query --question "Como funciona a entrevista de descoberta e quais os 4 blocos?")"
check "Pergunta sobre entrevista cita NC-Intake e 4 blocos" "$([[ $(echo "$q1_out" | jq -r '.answer') =~ "NC-Intake" ]] && [[ $(echo "$q1_out" | jq -r '.answer') =~ "4 blocos" ]] && echo true || echo false)"
check "Fontes válidas são retornadas" "$([[ $(echo "$q1_out" | jq -r '.sources | length') -gt 0 ]] && echo true || echo false)"

# 2. Pergunta no escopo sobre Governança e Complexidade S4
q2_out="$("$QA_SCRIPT" query --question "Qual a regra para tarefas de complexidade S4 e governança?")"
check "Pergunta sobre S4 cita aprovação humana obrigatória" "$([[ $(echo "$q2_out" | jq -r '.answer') =~ "aprovação humana obrigatória" ]] && echo true || echo false)"

# 3. Pergunta no escopo sobre Segurança e DevSecOps
q3_out="$("$QA_SCRIPT" query --question "Quais são os itens não-negociáveis de segurança verificados pelo NC-Shield?")"
check "Pergunta sobre segurança cita NC-Shield e itens não-negociáveis" "$([[ $(echo "$q3_out" | jq -r '.answer') =~ "NC-Shield" ]] && [[ $(echo "$q3_out" | jq -r '.answer') =~ "Não-Negociáveis" ]] && echo true || echo false)"

# 4. Pergunta Fora de Escopo
q4_out="$("$QA_SCRIPT" query --question "Qual a melhor receita de bolo de cenoura?")"
check "Pergunta fora de escopo retorna out_of_scope" "$([[ $(echo "$q4_out" | jq -r '.scope_status') == "out_of_scope" ]] && echo true || echo false)"

# 5. Pergunta Ambígua (Curta / sem contexto)
q5_out="$("$QA_SCRIPT" query --question "como faz?")"
check "Pergunta ambígua retorna needs_clarification" "$([[ $(echo "$q5_out" | jq -r '.scope_status') == "needs_clarification" ]] && echo true || echo false)"
check "Pergunta ambígua inclui clarification_question" "$([[ $(echo "$q5_out" | jq -r '.clarification_question') != "null" ]] && echo true || echo false)"

# 6. Validador de Contrato de Resposta
echo "$q1_out" > "$TMP_DIR/resp1.json"
val_res="$("$QA_SCRIPT" validate-response --response "$TMP_DIR/resp1.json")"
check "Resposta gerada está em conformidade com o contrato JSON" "$([[ $(echo "$val_res" | jq -r '.valid') == "true" ]] && echo true || echo false)"

echo "Resultado: ${pass} passou(aram), ${fail} falhou(aram)"
if [[ "$fail" -gt 0 ]]; then
  exit 1
fi
