#!/bin/bash

###############################################################################
# setup-pmo-org-project.sh
#
# Cria (uma única vez, por organização) o GitHub Project V2 de PORTFÓLIO do
# PMO — o board que agrega itens de MÚLTIPLOS repositórios num único lugar,
# para visão consolidada de backlog/prioridade entre projetos.
#
# Diferente de scripts/setup-github-project.sh (que cria 1 project POR
# REPOSITÓRIO), este script cria 1 project a nível de ORGANIZAÇÃO — rode uma
# única vez por organização, não por repositório.
#
# Uso:
#   ./setup-pmo-org-project.sh --org venha-pra-nuvem [--project-title "VPN Dev — Portfólio PMO"]
#
# Requer um usuário com permissão de owner/admin na organização (criar
# ProjectV2 a nível de organização exige isso) e `gh auth login --scopes project`.
#
# O script:
# 1. Valida que a organização existe
# 2. Cria um ProjectV2 na organização (ou reaproveita se já existir com o
#    mesmo título)
# 3. Cria 4 views padrão, seguindo as mesmas boas práticas do project por
#    repositório (scripts/setup-github-project.sh), adaptadas para múltiplos
#    repos:
#    - "Board por Repositório" (board layout — agrupe manualmente por
#      "Repository" na UI; a API pública de Projects V2 (createProjectV2View)
#      não expõe "group by", por isso este passo fica documentado, não automático)
#    - "Board por Prioridade" (board layout — agrupe manualmente por Labels,
#      prefixo priority:*)
#    - "Tabela — Backlog Consolidado" (table layout, todos os itens de todos
#      os repos conectados)
#    - "Tabela — P0 Blocker" (table layout, filtro para priority:P0-blocker
#      em qualquer repositório)
# 4. Retorna o link do project para referência
#
# IMPORTANTE — o que este project NÃO faz sozinho:
#   - Não conecta repositórios automaticamente. Cada repo precisa instalar
#     .github/workflows/add-to-pmo-project.yml (template em
#     templates/workflows/add-to-pmo-project.yml) apontando para a URL deste
#     project, para que suas issues/PRs sejam adicionadas automaticamente.
#   - Os campos "Horas Humanas" e "Oportunidade D365" (criados por
#     setup-github-project.sh em cada repo) NÃO aparecem somados aqui — são
#     campos por-projeto no modelo de dados do GitHub Projects V2 (o mesmo
#     item pode estar em 2 projects com valores de campo independentes em
#     cada um). Para custo/oportunidade consolidados entre repos, use
#     scripts/pmo-cost-rollup.sh, que lê os valores direto de cada
#     repositório via GraphQL e gera um relatório único.
#
###############################################################################

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

GH_HOST="${GH_HOST:-venha-pra-nuvem.ghe.com}"
PROJECT_TITLE="VPN Dev — Portfólio PMO"
ORG=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --org)
      ORG="$2"
      shift 2
      ;;
    --project-title)
      PROJECT_TITLE="$2"
      shift 2
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      exit 1
      ;;
  esac
done

if [[ -z "$ORG" ]]; then
  echo -e "${RED}Erro: --org é obrigatório (ex.: --org venha-pra-nuvem)${NC}"
  exit 1
fi

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}GitHub Project (Portfólio PMO) — Spec Kit${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "Organização: ${GREEN}${ORG}${NC}"
echo -e "Título: ${PROJECT_TITLE}"
echo ""

# 1. Validar organização e obter o node ID
echo -e "${BLUE}[1/4]${NC} Validando organização..."
ORG_ID=$(GH_HOST="$GH_HOST" gh api graphql -f org="$ORG" -f query='
query($org:String!) {
  organization(login:$org) { id }
}' -q '.data.organization.id' 2>&1)

if [[ -z "$ORG_ID" || "$ORG_ID" == "null" ]]; then
  echo -e "${RED}✗ Organização não encontrada ou sem permissão: ${ORG}${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Organização encontrada${NC} (ID: $ORG_ID)"

# 2. Criar (ou reaproveitar) o ProjectV2 da organização
echo ""
echo -e "${BLUE}[2/4]${NC} Verificando se o project já existe..."

# IMPORTANTE: checar existência ANTES de criar. createProjectV2 sempre tem
# sucesso mesmo com título duplicado (a API não impõe unicidade de título) —
# checar só depois de uma falha de criação não é suficiente e gera projects
# duplicados a cada execução do script.
# NOTA: `gh api ... -q` não aceita `--arg` (isso é uma flag do `jq`, não do
# `gh api`) — buscar o JSON completo e filtrar com `jq` separadamente.
EXISTING_PROJECT=$(GH_HOST="$GH_HOST" gh api graphql \
  -f org="$ORG" \
  -f query='
query($org:String!) {
  organization(login:$org) {
    projectsV2(first: 50) { nodes { id title url number } }
  }
}' 2>/dev/null | jq -r --arg t "$PROJECT_TITLE" '.data.organization.projectsV2.nodes[] | select(.title == $t)')

if [[ -n "$EXISTING_PROJECT" ]]; then
  PROJECT_ID=$(echo "$EXISTING_PROJECT" | jq -r '.id')
  PROJECT_URL=$(echo "$EXISTING_PROJECT" | jq -r '.url')
  echo -e "${YELLOW}  ℹ Project já existe (reutilizando): $PROJECT_URL${NC}"
else
  echo -e "${BLUE}  Nenhum project com este título — criando...${NC}"
  PROJECT_RESPONSE=$(GH_HOST="$GH_HOST" gh api graphql \
    -f orgId="$ORG_ID" \
    -f title="$PROJECT_TITLE" \
    -f query='
mutation($orgId:ID!, $title:String!) {
  createProjectV2(input: {
    ownerId: $orgId
    title: $title
  }) {
    projectV2 { id title url number }
  }
}' 2>&1)

  PROJECT_ID=$(echo "$PROJECT_RESPONSE" | jq -r '.data.createProjectV2.projectV2.id // empty' 2>/dev/null)
  PROJECT_URL=$(echo "$PROJECT_RESPONSE" | jq -r '.data.createProjectV2.projectV2.url // empty' 2>/dev/null)

  if [[ -z "$PROJECT_ID" ]]; then
    echo -e "${RED}✗ Erro ao criar project: $(echo "$PROJECT_RESPONSE" | jq -r '.errors[0].message // "erro desconhecido"')${NC}"
    exit 1
  fi
  echo -e "${GREEN}✓ Project criado: $PROJECT_URL${NC}"
fi

# 3. Criar as views padrão (4 views, agregando múltiplos repositórios)
echo ""
echo -e "${BLUE}[3/4]${NC} Criando views padrão..."

declare -a VIEWS=(
  "Board por Repositório|BOARD_LAYOUT|"
  "Board por Prioridade|BOARD_LAYOUT|"
  "Tabela — Backlog Consolidado|TABLE_LAYOUT|"
  "Tabela — P0 Blocker|TABLE_LAYOUT|label:\"priority:P0-blocker\""
)

# Buscar views já existentes ANTES de criar (idempotência — sem essa
# checagem, rodar o script de novo no mesmo project duplica as views a cada
# execução, já que createProjectV2View não impõe nome único).
EXISTING_VIEWS_JSON=$(GH_HOST="$GH_HOST" gh api graphql -f projectId="$PROJECT_ID" -f query='
query($projectId:ID!) {
  node(id: $projectId) {
    ... on ProjectV2 {
      views(first: 20) { nodes { id name } }
    }
  }
}' 2>/dev/null | jq -c '.data.node.views.nodes // []')

# NOTA: a mutation correta da API pública é `createProjectV2View` (campo
# `name`, não `title`) — `addProjectV2View` NÃO existe no schema e sempre
# falha. Filtro não é aceito na criação; precisa de uma 2ª chamada
# (`updateProjectV2View`) depois que a view existe. "Group by" continua sem
# suporte via API (documentado nos próximos passos, ajuste manual na UI).
for view_config in "${VIEWS[@]}"; do
  IFS='|' read -r VIEW_NAME VIEW_LAYOUT VIEW_FILTER <<< "$view_config"

  ALREADY_EXISTS=$(echo "$EXISTING_VIEWS_JSON" | jq -r --arg n "$VIEW_NAME" '.[] | select(.name == $n) | .id' | head -1)
  if [[ -n "$ALREADY_EXISTS" ]]; then
    echo -e "${YELLOW}  ℹ View já existe (pulando): $VIEW_NAME${NC}"
    continue
  fi

  VIEW_RESPONSE=$(GH_HOST="$GH_HOST" gh api graphql \
    -f projectId="$PROJECT_ID" -f viewName="$VIEW_NAME" -f layout="$VIEW_LAYOUT" \
    -f query='
mutation($projectId:ID!, $viewName:String!, $layout:ProjectV2ViewLayout!) {
  createProjectV2View(input: { projectId: $projectId, name: $viewName, layout: $layout }) {
    projectV2View { id name }
  }
}' 2>&1) || true

  VIEW_ID=$(echo "$VIEW_RESPONSE" | jq -r '.data.createProjectV2View.projectV2View.id // empty' 2>/dev/null)
  VIEW_NAME_RESULT=$(echo "$VIEW_RESPONSE" | jq -r '.data.createProjectV2View.projectV2View.name // empty' 2>/dev/null)

  if [[ -n "$VIEW_NAME_RESULT" ]]; then
    echo -e "${GREEN}  ✓ View criada: $VIEW_NAME ($VIEW_LAYOUT)${NC}"
    if [[ -n "$VIEW_FILTER" && -n "$VIEW_ID" ]]; then
      FILTER_RESPONSE=$(GH_HOST="$GH_HOST" gh api graphql \
        -f viewId="$VIEW_ID" -f filter="$VIEW_FILTER" \
        -f query='
mutation($viewId:ID!, $filter:String!) {
  updateProjectV2View(input: { viewId: $viewId, filter: $filter }) {
    projectV2View { id }
  }
}' 2>&1) || true
      if echo "$FILTER_RESPONSE" | jq -e '.data.updateProjectV2View.projectV2View.id' >/dev/null 2>&1; then
        echo -e "${GREEN}    ✓ Filtro aplicado: $VIEW_FILTER${NC}"
      else
        echo -e "${YELLOW}    ⚠ Falha ao aplicar filtro — aplicar manualmente na UI: $VIEW_FILTER${NC}"
      fi
    fi
  else
    echo -e "${YELLOW}  ⚠ View pode já existir ou erro ao criar: $VIEW_NAME${NC}"
    echo -e "${YELLOW}    Detalhe: $(echo "$VIEW_RESPONSE" | jq -r '.errors[0].message // "erro desconhecido"' 2>/dev/null)${NC}"
  fi
done

# 4. Resumo final
echo ""
echo -e "${BLUE}[4/4]${NC} Setup concluído!"
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "GitHub Project (Portfólio PMO) configurado com sucesso!"
echo -e "${GREEN}URL:${NC} ${PROJECT_URL}"
echo -e "${GREEN}ID:${NC}  ${PROJECT_ID}"
echo ""
echo -e "Views criadas (ajuste \"group by\" manualmente na UI — não exposto pela API):"
echo -e "  • Board por Repositório  → agrupar por campo nativo \"Repository\""
echo -e "  • Board por Prioridade   → agrupar por Labels (prefixo priority:*)"
echo -e "  • Tabela — Backlog Consolidado"
echo -e "  • Tabela — P0 Blocker"
echo ""
echo -e "Próximos passos (por repositório que deve alimentar este board):"
echo -e "  1. cp templates/workflows/add-to-pmo-project.yml <repo>/.github/workflows/"
echo -e "  2. Editar o 'project-url' no arquivo copiado para: ${PROJECT_URL}"
echo -e "  3. Configurar o secret ADD_TO_PROJECT_PAT (PAT com escopo project) em cada repo"
echo ""
echo -e "Para custo real (Horas Humanas) e Oportunidades D365 consolidados entre"
echo -e "repositórios, rode periodicamente: scripts/pmo-cost-rollup.sh"
echo ""
echo -e "Documentação: ${BLUE}docs/ai-code-quality-and-observability.md${NC} seção 8"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
