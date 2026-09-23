#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# validate-repo-static.sh
#
# Etapa "build" deste repositório (predominantemente shell + YAML + Markdown,
# sem compilação). Publicada como o check obrigatório `build` pelo workflow
# .github/workflows/pr-quality-gates.yml, via
# `quality_gates.build.command` de .github/security-governance.json.
#
# Validações (todas reais — nenhuma é simulada):
#   1. `bash -n` em todo scripts/**/*.sh e tests/**/*.sh (sintaxe).
#   2. `shellcheck -S error` em scripts/*.sh (quando o shellcheck existir; em
#      CI ele é pré-instalado no runner ubuntu — ausência falha a etapa).
#   3. Parse de todo JSON versionado em .github/ e .nimbus/.
#   4. Parse YAML de .github/**/*.yml (PyYAML).
#   5. actionlint nos workflows (quando o binário existir; o workflow instala
#      versão pinada com checksum SHA-256).
#
# Uso: bash scripts/validate-repo-static.sh [--allow-missing-tools]
#   --allow-missing-tools  uso local: pula (com aviso explícito) ferramentas
#                          ausentes em vez de falhar.
###############################################################################

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ALLOW_MISSING="false"
[[ "${1:-}" == "--allow-missing-tools" ]] && ALLOW_MISSING="true"

failures=0
fail() { echo "::error::$*"; failures=$((failures + 1)); }
missing_tool() {
  if [[ "$ALLOW_MISSING" == "true" ]]; then
    echo "::warning::$1 não encontrado — validação '$2' NÃO executada (modo --allow-missing-tools)."
  else
    fail "$1 não encontrado — validação '$2' é obrigatória no check build."
  fi
}

echo "==> [1/5] bash -n"
while IFS= read -r -d '' f; do
  bash -n "$f" 2>/tmp/validate-repo-static.err || fail "sintaxe bash inválida: $f ($(tr '\n' ' ' </tmp/validate-repo-static.err))"
done < <(find scripts tests -type f -name '*.sh' -print0 2>/dev/null | sort -z)
rm -f /tmp/validate-repo-static.err

echo "==> [2/5] shellcheck -S error"
if command -v shellcheck >/dev/null 2>&1; then
  mapfile -t sc_files < <(find scripts -maxdepth 1 -type f -name '*.sh' | sort)
  if (( ${#sc_files[@]} > 0 )); then
    shellcheck -S error "${sc_files[@]}" || fail "shellcheck encontrou erros em scripts/*.sh"
  fi
else
  missing_tool "shellcheck" "shellcheck"
fi

echo "==> [3/5] JSON"
while IFS= read -r -d '' f; do
  python3 -m json.tool "$f" >/dev/null 2>&1 || fail "JSON inválido: $f"
done < <(find .github .nimbus -type f -name '*.json' -print0 2>/dev/null | sort -z)

echo "==> [4/5] YAML"
if python3 -c 'import yaml' >/dev/null 2>&1; then
  python3 - <<'PY' || fail "YAML inválido em .github/"
import glob
import sys
import yaml

bad = 0
for path in sorted(glob.glob('.github/**/*.yml', recursive=True) + glob.glob('.github/**/*.yaml', recursive=True)):
    try:
        with open(path, encoding='utf-8') as fh:
            yaml.safe_load(fh)
    except yaml.YAMLError as exc:
        print(f"::error::{path}: {exc}")
        bad += 1
sys.exit(1 if bad else 0)
PY
else
  missing_tool "PyYAML" "yaml"
fi

echo "==> [5/5] actionlint"
if command -v actionlint >/dev/null 2>&1; then
  actionlint -shellcheck= -pyflakes= || fail "actionlint encontrou problemas nos workflows"
else
  missing_tool "actionlint" "actionlint"
fi

if (( failures > 0 )); then
  echo "✗ validate-repo-static: ${failures} falha(s)."
  exit 1
fi
echo "✓ validate-repo-static: todas as validações passaram."
