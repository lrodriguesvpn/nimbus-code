#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

WORKFLOWS=(
  "$ROOT_DIR/.github/workflows/add-to-repo-project.yml"
  "$ROOT_DIR/templates/workflows/add-to-repo-project.yml"
)

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

echo "== tests/workflows/add-to-repo-project.auth-fallback.test.sh =="

for workflow in "${WORKFLOWS[@]}"; do
  check "$(basename "$workflow") marca configured=false quando não há credencial" "$(grep -Fq 'echo "configured=false" >> "$GITHUB_OUTPUT"' "$workflow" && echo true || echo false)"
  check "$(basename "$workflow") zera token quando não há credencial" "$(grep -Fq 'echo "token=" >> "$GITHUB_OUTPUT"' "$workflow" && echo true || echo false)"
  check "$(basename "$workflow") registra warning em vez de falhar" "$(grep -Fq '::warning::Nenhuma credencial de Projects configurada; automação ignorada neste repositório até definir GitHub App ou fallback PAT.' "$workflow" && echo true || echo false)"
  check "$(basename "$workflow") remove o erro antigo do fallback sem credencial" "$(grep -Fq 'echo "::warning::Nenhuma credencial de Projects configurada; automação ignorada neste repositório até definir GitHub App ou fallback PAT."' "$workflow" && ! grep -Fq 'GitHub App não configurado; etapa cross-repo bloqueada.' "$workflow" && echo true || echo false)"
done

echo ""
echo "Resultado: ${pass} passaram, ${fail} falharam"
if (( fail > 0 )); then
  exit 1
fi
echo "✓ todos os testes passaram"
