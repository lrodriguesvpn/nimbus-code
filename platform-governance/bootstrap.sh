#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "== Platform Governance bootstrap =="
if ! command -v node >/dev/null 2>&1; then
  echo "node nao encontrado" >&2
  exit 1
fi

node --version
echo "Validando estrutura..."
test -f "$ROOT_DIR/package.json"
test -d "$ROOT_DIR/src"
test -d "$ROOT_DIR/tests"
echo "Estrutura pronta."
