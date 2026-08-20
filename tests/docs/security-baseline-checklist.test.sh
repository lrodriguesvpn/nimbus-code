#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# tests/docs/security-baseline-checklist.test.sh
#
# Teste de integração (T011, User Story 1, AC-1): valida que
# docs/security-baseline-ghe.md contém as seções 1 (Baseline de Repositório de
# Projeto) e 4 (Padrão de Tokens e Secrets de Automação) exigidas por
# contracts/documentation-contract.md, com o conteúdo mínimo obrigatório de
# cada uma. Não depende de credenciais/API — apenas leitura de arquivo.
#
# Uso: bash tests/docs/security-baseline-checklist.test.sh
###############################################################################

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC_FILE="${ROOT_DIR}/docs/security-baseline-ghe.md"

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
  # $1 = texto a inspecionar, $2 = padrão (case-insensitive)
  echo "$1" | grep -qi -- "$2"
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

echo "== tests/docs/security-baseline-checklist.test.sh =="

# Seção 1 — Baseline de Repositório de Projeto (FR-001)
section1=$(extract_section "1[.] Baseline de Repositório de Projeto")
if [[ -n "$section1" ]]; then
  check "Seção '1. Baseline de Repositório de Projeto' existe" "true"
else
  check "Seção '1. Baseline de Repositório de Projeto' existe" "false"
fi
check "Seção 1 documenta Acesso/papéis e menor privilégio" "$(contains "$section1" "Acesso" && contains "$section1" "menor privil" && echo true || echo false)"
check "Seção 1 documenta Branch protection" "$(contains "$section1" "Branch protection" && echo true || echo false)"
check "Seção 1 documenta regras de revisão de PR" "$(contains "$section1" "revis" && contains "$section1" "aprovador" && echo true || echo false)"
check "Seção 1 documenta permissões de GitHub Actions" "$(contains "$section1" "Actions" && contains "$section1" "allowed_actions\|Allowed actions" && echo true || echo false)"
check "Seção 1 documenta Secrets de repositório vs. organização" "$(contains "$section1" "Secrets" && contains "$section1" "organiza" && echo true || echo false)"
check "Seção 1 referencia o critério objetivo do controle branch-protection" "$(contains "$section1" "branch-protection" && echo true || echo false)"
check "Seção 1 referencia o critério objetivo do controle required-review" "$(contains "$section1" "required-review" && echo true || echo false)"
check "Seção 1 referencia o critério objetivo do controle actions-permissions" "$(contains "$section1" "actions-permissions" && echo true || echo false)"
check "Seção 1 referencia o critério objetivo do controle secrets-configured" "$(contains "$section1" "secrets-configured" && echo true || echo false)"

# Seção 4 — Padrão de Tokens e Secrets de Automação (FR-004, FR-004a)
section4=$(extract_section "4[.] Padrão de Tokens e Secrets de Automação")
if [[ -n "$section4" ]]; then
  check "Seção '4. Padrão de Tokens e Secrets de Automação' existe" "true"
else
  check "Seção '4. Padrão de Tokens e Secrets de Automação' existe" "false"
fi
check "Seção 4 diferencia escopo mínimo por tipo de credencial (PAT vs. GitHub App)" "$(contains "$section4" "PAT" && contains "$section4" "GitHub App" && echo true || echo false)"
check "Seção 4 declara que a varredura org-wide usa GitHub App dedicado (nunca PAT de usuário)" "$(contains "$section4" "nunca.*PAT\|PAT de usu" && echo true || echo false)"
check "Seção 4 referencia o ADR-0008" "$(contains "$section4" "ADR-0008" && echo true || echo false)"
check "Seção 4 documenta rotação, armazenamento e revogação" "$(contains "$section4" "Rota" && contains "$section4" "revoga" && contains "$section4" "armazenamento\|Armazenamento" && echo true || echo false)"

# Estrutura geral: as 8 seções (mesmo que parcialmente pendentes) devem estar
# presentes como headings "## " para estabilidade do contrato de documentação.
all_headings=$(grep -c "^## " "$DOC_FILE" || true)
check "Documento contém pelo menos as 8 seções obrigatórias como headings '## '" "$([[ "$all_headings" -ge 8 ]] && echo true || echo false)"

echo ""
echo "Resultado: ${pass} passaram, ${fail} falharam"
if (( fail > 0 )); then
  exit 1
fi
echo "✓ todos os testes passaram"
