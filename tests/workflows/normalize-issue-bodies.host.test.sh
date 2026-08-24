#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

WORKFLOWS=(
  "$ROOT_DIR/.github/workflows/normalize-issue-bodies.yml"
  "$ROOT_DIR/presets/nimbus-code-standards/templates/project-root/.github/workflows/normalize-issue-bodies.yml"
  "$ROOT_DIR/.specify/presets/nimbus-code-standards/templates/project-root/.github/workflows/normalize-issue-bodies.yml"
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

echo "== tests/workflows/normalize-issue-bodies.host.test.sh =="

for workflow in "${WORKFLOWS[@]}"; do
  check "$(basename "$workflow") exporta GH_HOST a partir de GITHUB_SERVER_URL" "$(grep -Fq 'export GH_HOST="${GITHUB_SERVER_URL#https://}"' "$workflow" && echo true || echo false)"
  check "$(basename "$workflow") remove prefixo http:// de GH_HOST" "$(grep -Fq 'export GH_HOST="${GH_HOST#http://}"' "$workflow" && echo true || echo false)"
done

echo ""
echo "Resultado: ${pass} passaram, ${fail} falharam"
if (( fail > 0 )); then
  exit 1
fi
echo "✓ todos os testes passaram"
