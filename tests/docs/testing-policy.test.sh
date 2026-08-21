#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# tests/docs/testing-policy.test.sh
#
# Teste de conteúdo (T008/T022, User Stories 1 e 4): valida que
# docs/testing-policy.md contém todas as seções obrigatórias definidas em
# specs/013-governanca-testes-pr/data-model.md (entidade "Test Policy") — o
# inventário/gap atual, a taxonomia de testes, a matriz de decisão de formato,
# a governança de exceções e o tratamento de testes legados. Não depende de
# credenciais/API — apenas leitura de arquivo.
#
# Test ref: test_AC1_inventario_e_gap_atual, test_AC2_matriz_de_decisao,
# test_AC5_taxonomia_de_testes, test_AC6_governanca_de_excecoes
#
# Uso: bash tests/docs/testing-policy.test.sh
###############################################################################

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC_FILE="${ROOT_DIR}/docs/testing-policy.md"

if [[ ! -f "$DOC_FILE" ]]; then
  echo "✗ ${DOC_FILE} não encontrado"
  exit 1
fi

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

contains() {
  # $1 = texto a inspecionar, $2 = padrão (case-insensitive, extended regex)
  echo "$1" | grep -qiE -- "$2"
}

extract_section() {
  # Extrai o conteúdo de uma seção "## <heading_regex>" até o próximo "## "
  local heading_regex="$1"
  awk -v h="$heading_regex" '
    $0 ~ "^## " h { capture=1; next }
    /^## / { if (capture) exit }
    capture { print }
  ' "$DOC_FILE"
}

echo "== tests/docs/testing-policy.test.sh =="

# test_AC1_inventario_e_gap_atual (FR-001, FR-002)
section1=$(extract_section "1[.] Invent")
check "Seção 'Inventário da Suíte Atual' existe" "$([[ -n "$section1" ]] && echo true || echo false)"
check "Inventário lista os 4 subgrupos existentes (bootstrap/docs/scripts/workflows)" "$(contains "$section1" "bootstrap" && contains "$section1" "docs" && contains "$section1" "scripts" && contains "$section1" "workflows" && echo true || echo false)"
check "Inventário declara que nenhum workflow roda a suíte completa em toda PR hoje" "$(contains "$section1" "nenhum workflow" && echo true || echo false)"

# test_AC5_taxonomia_de_testes (FR-005)
section2=$(extract_section "2[.] Taxonomia")
check "Seção 'Taxonomia de Testes' existe" "$([[ -n "$section2" ]] && echo true || echo false)"
check "Taxonomia define Unitário, Integração e End-to-end" "$(contains "$section2" "Unit" && contains "$section2" "Integra" && contains "$section2" "nd-to-end|E2E" && echo true || echo false)"

# test_AC2_matriz_de_decisao (FR-003, FR-003a, FR-004)
section3=$(extract_section "3[.] Matriz")
check "Seção 'Matriz de Decisão de Formato' existe" "$([[ -n "$section3" ]] && echo true || echo false)"
check "Matriz compara Bats-core e script .test.sh" "$(contains "$section3" "Bats-core" && contains "$section3" "\.test\.sh" && echo true || echo false)"
check "Matriz exige Exception Record para qualquer outro formato" "$(contains "$section3" "Exception Record" && echo true || echo false)"

# Convenções de localização/nomenclatura (FR-006)
section4=$(extract_section "4[.] Conven")
check "Seção 'Convenções de Localização e Nomenclatura' existe" "$([[ -n "$section4" ]] && echo true || echo false)"

# Gate obrigatório de PR (FR-007, FR-008, FR-011)
section5=$(extract_section "5[.] Gate Obrigat")
check "Seção 'Gate Obrigatório de PR' existe" "$([[ -n "$section5" ]] && echo true || echo false)"
check "Seção do gate referencia scripts/run-tests.sh e test-suite.yml" "$(contains "$section5" "run-tests\.sh" && contains "$section5" "test-suite\.yml" && echo true || echo false)"

# test_AC6_governanca_de_excecoes (FR-009)
section6=$(extract_section "6[.] Governan")
check "Seção 'Governança de Exceções' existe" "$([[ -n "$section6" ]] && echo true || echo false)"
check "Governança de Exceções exige motivo, formato alternativo, duração e aprovador" "$(contains "$section6" "Motivo" && contains "$section6" "alternativo" && contains "$section6" "prova" && echo true || echo false)"

# Tratamento de testes legados (FR-010)
section7=$(extract_section "7[.] Tratamento")
check "Seção 'Tratamento de Testes Legados' existe" "$([[ -n "$section7" ]] && echo true || echo false)"
check "Testes legados classificados como aceitos e permanentes (não migração forçada)" "$(contains "$section7" "aceito" && contains "$section7" "permanente" && echo true || echo false)"

# Execução local (FR-008, AC-4)
section8=$(extract_section "8[.] Executando")
check "Seção 'Executando a Suíte Localmente' existe" "$([[ -n "$section8" ]] && echo true || echo false)"
check "Execução local documenta o comando único ./scripts/run-tests.sh" "$(contains "$section8" "\./scripts/run-tests\.sh" && echo true || echo false)"

echo ""
echo "Resultado: ${pass} passaram, ${fail} falharam"
if (( fail > 0 )); then
  exit 1
fi
echo "✓ todos os testes passaram"
