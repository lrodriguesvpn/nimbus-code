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

elif python3 -c "import yaml" &>/dev/null; then
  # ── python3 com PyYAML disponível ─────────────────────────────
  OUTPUT=$(python3 -c "
import yaml, sys

catalog = sys.argv[1]
term = sys.argv[2].lower()

try:
    with open(catalog, 'r', encoding='utf-8') as f:
        data = yaml.safe_load(f)
except Exception as e:
    sys.exit(1)

found = 0
for entry in (data.get('entries', []) or []):
    tags = [str(t).lower() for t in entry.get('tags', [])]
    context = str(entry.get('bounded_context', '')).lower()
    pattern = str(entry.get('error_pattern', '')).lower()
    eid = str(entry.get('id', '')).lower()
    
    if term in tags or term in context or term in pattern or term in eid or any(term in t for t in tags):
        found += 1
        id_str = entry.get('id', 'HRN-????')
        comp_str = entry.get('complexity', 'S?')
        date_str = entry.get('date', '')
        pat_str = ' '.join(str(entry.get('error_pattern', '')).split())
        prev_str = ' '.join(str(entry.get('prevention', '')).split())
        print(f'MATCH::{id_str}::{comp_str}::{date_str}::{pat_str}::{prev_str}')
" "${CATALOG_FILE}" "${SEARCH_TERM}" 2>/dev/null || true)

  while IFS= read -r match_line; do
    if [[ -n "${match_line}" && "${match_line}" =~ ^MATCH:: ]]; then
      ID=$(echo "${match_line}" | awk -F'::' '{print $2}')
      COMPLEXITY=$(echo "${match_line}" | awk -F'::' '{print $3}')
      DATE=$(echo "${match_line}" | awk -F'::' '{print $4}')
      PATTERN=$(echo "${match_line}" | awk -F'::' '{print $5}')
      PREVENTION=$(echo "${match_line}" | awk -F'::' '{print $6}')

      echo -e "  ${BOLD}${GREEN}${ID}${NC}  ${YELLOW}[${COMPLEXITY}]${NC}  ${DATE}"
      echo -e "  ${BOLD}Padrão:${NC}     ${PATTERN}"
      echo -e "  ${BOLD}Prevenção:${NC}  ${PREVENTION}"
      echo ""
      FOUND=$((FOUND + 1))
    fi
  done <<< "${OUTPUT}"

else
  # ── Fallback: grep/awk sem yq nem python3 ─────────────────────
  MATCHING_IDS=$(awk "/${SEARCH_TERM}/{ found=1 } found && /^  - id:/{print; found=0} /^  - id:/{id=\$0} /${SEARCH_TERM}/{print id}" "${CATALOG_FILE}" 2>/dev/null | grep "id:" | sed 's/.*id: *//;s/\"//g;s/'\''//g' | sort -u)
  for BLOCK_ID in ${MATCHING_IDS}; do
    echo -e "  ${BOLD}${GREEN}${BLOCK_ID}${NC}"
    echo -e "  ${YELLOW}(instale yq ou python3 com pyyaml para saída formatada completa)${NC}"
    echo ""
    FOUND=$((FOUND + 1))
  done
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
