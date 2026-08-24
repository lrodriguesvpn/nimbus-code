#!/usr/bin/env bash
# harness-search.sh
#
# Busca no harness-catalog.yaml por tag ou bounded_context e retorna
# ID, error_pattern e prevention das entradas que fazem match.
#
# Uso:
#   ./scripts/harness-search.sh <tag-ou-bounded-context>
#   ./scripts/harness-search.sh <tag> --file <caminho-para-catalog>
#
# Exemplos:
#   ./scripts/harness-search.sh agent-scope-creep
#   ./scripts/harness-search.sh spec-kit-workflow
#   ./scripts/harness-search.sh database-migration --file /outro/harness-catalog.yaml

set -euo pipefail

# ──────────────────────────────────────────────────────────────
# Cores
# ──────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

# ──────────────────────────────────────────────────────────────
# Defaults
# ──────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DEFAULT_CATALOG="${REPO_ROOT}/docs/harness/harness-catalog.yaml"
CATALOG_FILE="${DEFAULT_CATALOG}"
SEARCH_TERM=""

# ──────────────────────────────────────────────────────────────
# Argumentos
# ──────────────────────────────────────────────────────────────
usage() {
  echo ""
  echo -e "${BOLD}Uso:${NC} $(basename "$0") <tag-ou-bounded-context> [--file <caminho>]"
  echo ""
  echo -e "${BOLD}Exemplos:${NC}"
  echo "  $(basename "$0") agent-scope-creep"
  echo "  $(basename "$0") spec-kit-workflow"
  echo "  $(basename "$0") database-migration --file /path/to/harness-catalog.yaml"
  echo ""
  echo -e "${BOLD}Descrição:${NC}"
  echo "  Busca no harness-catalog.yaml por entradas cujas tags ou bounded_context"
  echo "  contenham o termo informado. Retorna ID, error_pattern e prevention."
  echo ""
}

if [[ $# -eq 0 ]]; then
  usage
  exit 1
fi

SEARCH_TERM="$1"
shift

while [[ $# -gt 0 ]]; do
  case "$1" in
    --file)
      CATALOG_FILE="$2"
      shift 2
      ;;
    *)
      echo -e "${RED}Argumento desconhecido: $1${NC}"
      usage
      exit 1
      ;;
  esac
done

# ──────────────────────────────────────────────────────────────
# Validações
# ──────────────────────────────────────────────────────────────
if [[ ! -f "${CATALOG_FILE}" ]]; then
  echo -e "${RED}Erro: catálogo não encontrado em '${CATALOG_FILE}'${NC}"
  echo -e "Verifique se o arquivo existe ou use --file para especificar outro caminho."
  exit 1
fi

# ──────────────────────────────────────────────────────────────
# Busca — usa yq se disponível, fallback para grep/awk
# ──────────────────────────────────────────────────────────────
echo ""
echo -e "${BLUE}🔍 Harness Search${NC} — buscando por: ${BOLD}${SEARCH_TERM}${NC}"
echo -e "   Catálogo: ${CATALOG_FILE}"
echo ""

FOUND=0

if command -v yq &>/dev/null; then
  # ── yq disponível: parse estruturado ──────────────────────────
  COUNT=$(yq e '.entries | length' "${CATALOG_FILE}" 2>/dev/null || echo 0)

  for i in $(seq 0 $((COUNT - 1))); do
    TAGS=$(yq e ".entries[${i}].tags[]" "${CATALOG_FILE}" 2>/dev/null | tr '\n' ' ')
    CONTEXT=$(yq e ".entries[${i}].bounded_context" "${CATALOG_FILE}" 2>/dev/null)

    if echo "${TAGS} ${CONTEXT}" | grep -qi "${SEARCH_TERM}"; then
      ID=$(yq e ".entries[${i}].id" "${CATALOG_FILE}")
      PATTERN=$(yq e ".entries[${i}].error_pattern" "${CATALOG_FILE}" | tr -s ' \n' ' ' | sed 's/^ //;s/ $//')
      PREVENTION=$(yq e ".entries[${i}].prevention" "${CATALOG_FILE}" | tr -s ' \n' ' ' | sed 's/^ //;s/ $//')
      DATE=$(yq e ".entries[${i}].date" "${CATALOG_FILE}")
      COMPLEXITY=$(yq e ".entries[${i}].complexity" "${CATALOG_FILE}")

      echo -e "  ${BOLD}${GREEN}${ID}${NC}  ${YELLOW}[${COMPLEXITY}]${NC}  ${DATE}"
      echo -e "  ${BOLD}Padrão:${NC}     ${PATTERN}"
      echo -e "  ${BOLD}Prevenção:${NC}  ${PREVENTION}"
      echo ""
      FOUND=$((FOUND + 1))
    fi
  done

else
  # ── Fallback: grep/awk sem yq ─────────────────────────────────
  # Estratégia: encontrar linhas com o termo buscado e, para cada bloco
  # de entrada (delimitado por "- id:"), extrair os campos relevantes.

  # Capturar blocos que contêm o search term
  while IFS= read -r line; do
    if echo "${line}" | grep -qi "${SEARCH_TERM}"; then
      # Encontrou uma linha com o termo — navegar para o início do bloco
      # (linha com "- id:") mais próxima acima
      BLOCK_ID=$(grep -n "^  - id:" "${CATALOG_FILE}" | awk -F: -v lineno="$(grep -n "${SEARCH_TERM}" "${CATALOG_FILE}" | grep -m1 "" | cut -d: -f1)" '
        BEGIN { best=0 }
        {
          if ($1 <= lineno && $1 > best) { best=$1; id_line=$0 }
        }
        END { print id_line }
      ' | awk -F'"' '{print $2}')

      if [[ -n "${BLOCK_ID}" && "${BLOCK_ID}" != "null" ]]; then
        # Extrair campos do bloco via awk
        PATTERN=$(awk "/^  - id: \"${BLOCK_ID}\"/,/^  - id:/" "${CATALOG_FILE}" | grep "error_pattern" | head -1 | sed 's/.*error_pattern: *//;s/^ *>//;s/^ *//')
        PREVENTION=$(awk "/^  - id: \"${BLOCK_ID}\"/,/^  - id:/" "${CATALOG_FILE}" | grep "prevention" | head -1 | sed 's/.*prevention: *//;s/^ *>//;s/^ *//')
        DATE=$(awk "/^  - id: \"${BLOCK_ID}\"/,/^  - id:/" "${CATALOG_FILE}" | grep "date:" | head -1 | awk '{print $2}')
        COMPLEXITY=$(awk "/^  - id: \"${BLOCK_ID}\"/,/^  - id:/" "${CATALOG_FILE}" | grep "complexity:" | head -1 | awk '{print $2}')

        echo -e "  ${BOLD}${GREEN}${BLOCK_ID}${NC}  ${YELLOW}[${COMPLEXITY}]${NC}  ${DATE}"
        [[ -n "${PATTERN}" ]] && echo -e "  ${BOLD}Padrão:${NC}     ${PATTERN}"
        [[ -n "${PREVENTION}" ]] && echo -e "  ${BOLD}Prevenção:${NC}  ${PREVENTION}"
        echo ""
        FOUND=$((FOUND + 1))
      fi
      break  # fallback encontra o primeiro match
    fi
  done < <(grep -i "${SEARCH_TERM}" "${CATALOG_FILE}")

  if [[ $FOUND -eq 0 ]]; then
    # Segunda tentativa: grep direto para padrões mais simples
    MATCHING_IDS=$(awk "/${SEARCH_TERM}/{ found=1 } found && /^  - id:/{print; found=0} /^  - id:/{id=\$0} /${SEARCH_TERM}/{print id}" "${CATALOG_FILE}" 2>/dev/null | grep "id:" | awk -F'"' '{print $2}' | sort -u)
    for BLOCK_ID in ${MATCHING_IDS}; do
      echo -e "  ${BOLD}${GREEN}${BLOCK_ID}${NC}"
      echo -e "  ${YELLOW}(instale yq para detalhes completos: https://github.com/mikefarah/yq)${NC}"
      echo ""
      FOUND=$((FOUND + 1))
    done
  fi
fi

# ──────────────────────────────────────────────────────────────
# Resultado final
# ──────────────────────────────────────────────────────────────
if [[ $FOUND -eq 0 ]]; then
  echo -e "  ${YELLOW}Nenhum resultado encontrado para: ${BOLD}${SEARCH_TERM}${NC}"
  echo -e "  Dica: consulte as tags disponíveis no catálogo ou use um termo mais amplo."
  echo ""
  exit 0
else
  echo -e "  ${GREEN}${FOUND} entrada(s) encontrada(s).${NC}"
  echo -e "  Catálogo completo: ${CATALOG_FILE}"
  echo ""
fi
