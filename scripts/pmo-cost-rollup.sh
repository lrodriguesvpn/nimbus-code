#!/bin/bash

###############################################################################
# pmo-cost-rollup.sh
#
# Gera um relatório CONSOLIDADO (multi-repositório) de custo humano real e
# vínculo com Oportunidades D365 e Ocorrências CRM (N1), lendo diretamente os
# campos "Horas Humanas", "Oportunidade D365" e "Ocorrência CRM (N1)" de cada
# Project V2 por-repositório (criados por scripts/setup-github-project.sh).
#
# Por que este script existe (e o Project de portfólio sozinho não resolve):
#   O GitHub Projects V2 trata valores de campo customizado como
#   POR-PROJETO — mesmo que a mesma issue apareça no project do repositório
#   E no project de portfólio do PMO (scripts/setup-pmo-org-project.sh), os
#   valores desses campos preenchidos no project do repositório NÃO aparecem
#   somados no project de portfólio. Este script contorna isso lendo via
#   GraphQL direto de cada repositório e somando aqui.
#
# Uso:
#   ./pmo-cost-rollup.sh --repo owner/repo1 --repo owner/repo2 ...
#   ./pmo-cost-rollup.sh --repos-file lista-de-repos.txt   # 1 "owner/repo" por linha
#   PMO_REPOS="owner/repo1,owner/repo2" ./pmo-cost-rollup.sh
#
# Opções:
#   --output arquivo.md   Salva o relatório em arquivo além de imprimir no stdout
#
# Variáveis de ambiente:
#   - GH_HOST (padrão: venha-pra-nuvem.ghe.com)
#
# Saída: tabela Markdown com total de "Horas Humanas" e contagem de itens
# vinculados a "Oportunidade D365" por repositório, mais o total geral.
#
###############################################################################

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

GH_HOST="${GH_HOST:-venha-pra-nuvem.ghe.com}"
REPOS=()
OUTPUT_FILE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --repo)
      REPOS+=("$2")
      shift 2
      ;;
    --repos-file)
      while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        REPOS+=("$line")
      done < "$2"
      shift 2
      ;;
    --output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      exit 1
      ;;
  esac
done

if [[ -n "${PMO_REPOS:-}" ]]; then
  IFS=',' read -ra ENV_REPOS <<< "$PMO_REPOS"
  REPOS+=("${ENV_REPOS[@]}")
fi

if [[ ${#REPOS[@]} -eq 0 ]]; then
  echo -e "${RED}Erro: informe pelo menos um --repo owner/name, --repos-file, ou PMO_REPOS${NC}"
  exit 1
fi

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}" >&2
echo -e "${BLUE}PMO Cost Rollup — Custo Real e Oportunidades D365 consolidados${NC}" >&2
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}" >&2
echo -e "Repositórios: ${GREEN}${#REPOS[@]}${NC}" >&2
echo "" >&2

REPORT_ROWS=""
GRAND_TOTAL_HORAS=0
GRAND_TOTAL_ITENS=0
GRAND_TOTAL_D365=0
GRAND_TOTAL_CRM=0

for REPO in "${REPOS[@]}"; do
  OWNER="${REPO%/*}"
  NAME="${REPO#*/}"
  echo -e "${BLUE}→${NC} Lendo $REPO..." >&2

  # Paginação simples: busca até 500 itens (5 páginas de 100) do primeiro
  # Project V2 do repositório cujo título termine em "Spec Kit Roadmap".
  CURSOR="null"
  ITEMS_JSON="[]"
  for _ in 1 2 3 4 5; do
    PAGE=$(GH_HOST="$GH_HOST" gh api graphql \
      -f owner="$OWNER" -f name="$NAME" -F cursor="$CURSOR" \
      -f query='
query($owner:String!, $name:String!, $cursor:String) {
  repository(owner:$owner, name:$name) {
    projectsV2(first: 5) {
      nodes {
        title
        items(first: 100, after: $cursor) {
          pageInfo { hasNextPage endCursor }
          nodes {
            horas: fieldValueByName(name: "Horas Humanas") {
              ... on ProjectV2ItemFieldNumberValue { number }
            }
            d365: fieldValueByName(name: "Oportunidade D365") {
              ... on ProjectV2ItemFieldTextValue { text }
            }
            crm: fieldValueByName(name: "Ocorrência CRM (N1)") {
              ... on ProjectV2ItemFieldTextValue { text }
            }
          }
        }
      }
    }
  }
}' 2>&1)

    PROJECT_NODE=$(echo "$PAGE" | jq -c '.data.repository.projectsV2.nodes[]? | select(.title | test(" — Spec Kit Roadmap$"))' 2>/dev/null | head -1)

    if [[ -z "$PROJECT_NODE" ]]; then
      echo -e "${YELLOW}  ⚠ Nenhum Project V2 encontrado em $REPO (pulando)${NC}" >&2
      break
    fi

    PAGE_ITEMS=$(echo "$PROJECT_NODE" | jq -c '.items.nodes')
    ITEMS_JSON=$(jq -c -s '.[0] + .[1]' <(echo "$ITEMS_JSON") <(echo "$PAGE_ITEMS"))

    HAS_NEXT=$(echo "$PROJECT_NODE" | jq -r '.items.pageInfo.hasNextPage')
    CURSOR=$(echo "$PROJECT_NODE" | jq -r '.items.pageInfo.endCursor // empty')
    [[ "$HAS_NEXT" == "true" && -n "$CURSOR" ]] || break
    CURSOR="\"$CURSOR\""
  done

  REPO_HORAS=$(echo "$ITEMS_JSON" | jq '[.[] | .horas.number // 0] | add // 0')
  REPO_ITENS=$(echo "$ITEMS_JSON" | jq 'length')
  REPO_D365=$(echo "$ITEMS_JSON" | jq '[.[] | select(.d365.text // "" | length > 0)] | length')
  REPO_CRM=$(echo "$ITEMS_JSON" | jq '[.[] | select(.crm.text // "" | length > 0)] | length')

  REPORT_ROWS="${REPORT_ROWS}| ${REPO} | ${REPO_ITENS} | ${REPO_HORAS} | ${REPO_D365} | ${REPO_CRM} |
"
  GRAND_TOTAL_HORAS=$(echo "$GRAND_TOTAL_HORAS + $REPO_HORAS" | bc)
  GRAND_TOTAL_ITENS=$((GRAND_TOTAL_ITENS + REPO_ITENS))
  GRAND_TOTAL_D365=$((GRAND_TOTAL_D365 + REPO_D365))
  GRAND_TOTAL_CRM=$((GRAND_TOTAL_CRM + REPO_CRM))
done

REPORT=$(cat <<EOF
# PMO Cost Rollup — $(date -u +"%Y-%m-%d %H:%M UTC")

| Repositório | Itens no Project | Horas Humanas (total) | Itens c/ Oportunidade D365 | Itens c/ Ocorrência CRM (N1) |
|---|---|---|---|---|
${REPORT_ROWS}| **TOTAL GERAL** | **${GRAND_TOTAL_ITENS}** | **${GRAND_TOTAL_HORAS}** | **${GRAND_TOTAL_D365}** | **${GRAND_TOTAL_CRM}** |

> Custo humano estimado = Horas Humanas (total) × taxa do perfil (ver
> \`docs/cost-profiles-and-rates.md\` de cada projeto — este rollup soma horas
> "cruas", não aplica taxa, pois times diferentes podem ter perfis/taxas
> diferentes). Itens com "Ocorrência CRM (N1)" preenchido são issues
> originadas de incidentes/recorrência (label \`type:incident\`) — cruze com
> \`dora:mttr\` para acompanhar tempo de restauração.
EOF
)

echo "$REPORT"

if [[ -n "$OUTPUT_FILE" ]]; then
  echo "$REPORT" > "$OUTPUT_FILE"
  echo -e "${GREEN}✓ Relatório salvo em: $OUTPUT_FILE${NC}" >&2
fi
