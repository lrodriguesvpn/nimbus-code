#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# tests/docs/security-baseline-tokens.test.sh
#
# T020 / AC-4: validates the documentation for Project workflows and tokens.
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
  echo "$1" | grep -qi -- "$2"
}

extract_section() {
  local heading_regex="$1"
  awk -v h="$heading_regex" '
    $0 ~ "^## " h { capture=1; next }
    /^## / { if (capture) exit }
    capture { print }
  ' "$DOC_FILE"
}

echo "== tests/docs/security-baseline-tokens.test.sh =="

section2=$(extract_section "2[.] Governança do Projeto Plataforma")
section3=$(extract_section "3[.] Modelo de Acesso por Papéis")
section8=$(extract_section "8[.] Dependências de Workflows com Projects")

check "Seção 2 diferencia repositório de projeto vs. Projeto Plataforma" "$(contains "$section2" "Repositório de projeto" && contains "$section2" "Projeto Plataforma" && echo true || echo false)"
check "Seção 2 exige Project V2 privado e viewerCanUpdate=false" "$(contains "$section2" "privado" && contains "$section2" "viewerCanUpdate=false" && echo true || echo false)"
check "Seção 3 documenta os cinco papéis" "$(contains "$section3" "owner" && contains "$section3" "admin" && contains "$section3" "maintainer" && contains "$section3" "contributor" && contains "$section3" "leitor" && echo true || echo false)"
check "Seção 8 orienta PAT mínimo para workflows que escrevem em Projects" "$(contains "$section8" "VPNDEV_PROJECT_TOKEN" && contains "$section8" "repo" && contains "$section8" "project" && echo true || echo false)"
check "Seção 8 mantém GitHub App para varredura org-wide" "$(contains "$section8" "GitHub App" && contains "$section8" "SECURITY_SCAN_APP_ID" && echo true || echo false)"
check "Seção 8 explica que GITHUB_TOKEN não substitui PAT/App" "$(contains "$section8" "GITHUB_TOKEN" && contains "$section8" "não substitui" && echo true || echo false)"
check "Seção 8 exige GitHub Secrets e rotação" "$(contains "$section8" "Secrets and variables" && contains "$section8" "trimestral" && echo true || echo false)"

echo ""
echo "Resultado: ${pass} passaram, ${fail} falharam"
if (( fail > 0 )); then
  exit 1
fi
echo "✓ todos os testes passaram"
