#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# run-tests.sh
#
# Ponto de entrada único para a suíte de testes mandatória deste bundle
# (feature specs/013-governanca-testes-pr/). Descobre e executa:
#   (a) todo arquivo tests/**/*.bats  — via `bats`
#   (b) todo arquivo tests/**/*.test.sh — via `bash`
#   (c) .specify/scripts/bash/tests/*.bats — via `bats`
#
# Usado tanto localmente (contribuidor, antes de abrir PR) quanto pelo
# .github/workflows/test-suite.yml (CI) — o mesmo script, garantindo
# paridade local/CI por construção (AC-4, FR-008), não por manutenção
# paralela de duas listas de comandos.
#
# Saída: resultado consolidado (quantos grupos/arquivos passaram/falharam) e,
# em caso de falha, identifica explicitamente o primeiro segmento
# (bootstrap/docs/scripts/workflows) que falhou (FR-011, AC-3) — sem exigir
# inspeção de múltiplos logs separados.
#
# Exit code: 0 se tudo passar, 1 se qualquer grupo falhar.
#
# Uso:
#   ./scripts/run-tests.sh
###############################################################################

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TOTAL_FILES=0
FAILED_FILES=0
FAILED_SEGMENT=""
declare -a FAILED_LIST=()

# ── Aviso de compatibilidade de bash (macOS) ────────────────────────────────
# scripts/security-compliance-scan.sh usa arrays associativos (`declare -A`),
# não suportados pelo bash 3.2 que vem pré-instalado no macOS. Avisar cedo
# evita que o contribuidor confunda essa incompatibilidade local com uma
# falha real de teste (ver docs/testing-policy.md, seção 8).
if [[ -z "${BASH_VERSINFO:-}" ]] || (( BASH_VERSINFO[0] < 4 )); then
  echo -e "${YELLOW}⚠ Você está rodando bash ${BASH_VERSION:-desconhecido}. Este bundle usa arrays" >&2
  echo -e "  associativos (declare -A) em alguns scripts, não suportados em bash < 4." >&2
  echo -e "  No macOS, o /bin/bash padrão é 3.2 (limitação de licenciamento da Apple)." >&2
  echo -e "  Instale um bash mais novo antes de continuar: 'brew install bash' e rode" >&2
  echo -e "  este script novamente com '/opt/homebrew/bin/bash scripts/run-tests.sh'" >&2
  echo -e "  (Apple Silicon) ou '/usr/local/bin/bash scripts/run-tests.sh' (Intel).${NC}" >&2
  echo "" >&2
fi

echo "==> Nimbus-Code: executando a suíte de testes mandatória..."
echo ""

run_bats_group() {
  local dir="$1"
  local segment
  segment="${2:-$(basename "$dir")}"
  local files=()
  while IFS= read -r -d '' f; do
    files+=("$f")
  done < <(find "$dir" -maxdepth 1 -type f -name '*.bats' -print0 | sort -z)

  if [[ "${#files[@]}" -eq 0 ]]; then
    return 0
  fi

  if ! command -v bats >/dev/null 2>&1; then
    echo -e "${RED}✗ [${segment}] 'bats' não encontrado no PATH — instale via" \
      "scripts/setup-dev-environment.sh ou 'npm install -g bats-core'.${NC}"
    FAILED_FILES=$((FAILED_FILES + ${#files[@]}))
    TOTAL_FILES=$((TOTAL_FILES + ${#files[@]}))
    if [[ -z "$FAILED_SEGMENT" ]]; then FAILED_SEGMENT="$segment"; fi
    for f in "${files[@]}"; do FAILED_LIST+=("$f"); done
    return 1
  fi

  for f in "${files[@]}"; do
    TOTAL_FILES=$((TOTAL_FILES + 1))
    echo "--- [${segment}] bats $f ---"
    if bats "$f"; then
      echo -e "${GREEN}✓ ${f}${NC}"
    else
      echo -e "${RED}✗ ${f}${NC}"
      FAILED_FILES=$((FAILED_FILES + 1))
      FAILED_LIST+=("$f")
      if [[ -z "$FAILED_SEGMENT" ]]; then FAILED_SEGMENT="$segment"; fi
    fi
    echo ""
  done
}

run_shell_test_group() {
  local dir="$1"
  local segment
  segment="$(basename "$dir")"
  local files=()
  while IFS= read -r -d '' f; do
    files+=("$f")
  done < <(find "$dir" -maxdepth 1 -type f -name '*.test.sh' -print0 | sort -z)

  if [[ "${#files[@]}" -eq 0 ]]; then
    return 0
  fi

  for f in "${files[@]}"; do
    TOTAL_FILES=$((TOTAL_FILES + 1))
    echo "--- [${segment}] bash $f ---"
    if bash "$f"; then
      echo -e "${GREEN}✓ ${f}${NC}"
    else
      echo -e "${RED}✗ ${f}${NC}"
      FAILED_FILES=$((FAILED_FILES + 1))
      FAILED_LIST+=("$f")
      if [[ -z "$FAILED_SEGMENT" ]]; then FAILED_SEGMENT="$segment"; fi
    fi
    echo ""
  done
}

# Descoberta por subpasta de tests/, em ordem estável (bootstrap, docs,
# scripts, workflows — ordem alfabética já corresponde à ordem de introdução
# histórica das features 007/008).
for dir in "$ROOT_DIR"/tests/*/; do
  [[ -d "$dir" ]] || continue
  run_bats_group "$dir" || true
  run_shell_test_group "$dir" || true
done

run_bats_group "$ROOT_DIR/.specify/scripts/bash/tests" templates || true

echo "============================================================"
PASSED_FILES=$((TOTAL_FILES - FAILED_FILES))
echo "Resultado consolidado: ${PASSED_FILES}/${TOTAL_FILES} arquivos de teste passaram."

if (( FAILED_FILES > 0 )); then
  echo -e "${RED}✗ Segmento com falha: ${FAILED_SEGMENT}${NC}"
  echo "Arquivos que falharam:"
  for f in "${FAILED_LIST[@]}"; do
    echo "  - ${f}"
  done
  exit 1
fi

echo -e "${GREEN}✓ Todos os grupos passaram (bootstrap, docs, scripts, workflows, templates).${NC}"
