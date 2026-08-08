#!/bin/bash

###############################################################################
# setup-github-project.sh
#
# Cria automaticamente um GitHub Project V2 para o repositório do projeto
# com as mesmas VIEWS do IOX-CROWDFUNDINGPAAS como template.
#
# Uso:
#   ./setup-github-project.sh [--repo-owner owner] [--repo-name name] [--template-project-name name]
#
# Exemplos:
#   ./setup-github-project.sh --repo-owner venha-pra-nuvem --repo-name meu-novo-projeto
#   ./setup-github-project.sh  # usa vars de env: GITHUB_REPOSITORY
#
# Variáveis de ambiente suportadas:
#   - GITHUB_REPOSITORY (automaticamente preenchida em GitHub Actions: owner/repo)
#   - GH_HOST (padrão: venha-pra-nuvem.ghe.com)
#
# O script:
# 1. Valida que o repo existe
# 2. Cria um ProjectV2 com o nome: "{repo-name} — Spec Kit Roadmap"
# 3. Cria 3 views padrão (copiadas do IOX-CROWDFUNDINGPAAS):
#    - "Board por Epic" (board layout, sem filtro inicial — dev personaliza)
#    - "Board por Prioridade" (board layout, sem filtro inicial — dev personaliza)
#    - "Tabela — P0 Blocker" (table layout, filtro para P0-blocker)
# 4. Retorna o link do projeto para referência
#
###############################################################################

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Defaults
GH_HOST="${GH_HOST:-venha-pra-nuvem.ghe.com}"
TEMPLATE_PROJECT_NAME="IOX-CROWDFUNDINGPAAS — DevOps & DevSecOps Roadmap"
TEMPLATE_REPO_OWNER="venha-pra-nuvem"
TEMPLATE_REPO_NAME="IOX-CROWDFUNDINGPAAS"

# Parse arguments
REPO_OWNER=""
REPO_NAME=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --repo-owner)
      REPO_OWNER="$2"
      shift 2
      ;;
    --repo-name)
      REPO_NAME="$2"
      shift 2
      ;;
    --template-project-name)
      TEMPLATE_PROJECT_NAME="$2"
      shift 2
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      exit 1
      ;;
  esac
done

# Se repo-owner ou repo-name não foram passados, tenta GITHUB_REPOSITORY (GitHub Actions)
if [[ -z "$REPO_OWNER" || -z "$REPO_NAME" ]]; then
  if [[ -n "${GITHUB_REPOSITORY:-}" ]]; then
    REPO_OWNER="${GITHUB_REPOSITORY%/*}"
    REPO_NAME="${GITHUB_REPOSITORY#*/}"
  else
    echo -e "${RED}Erro: --repo-owner e --repo-name são obrigatórios ou configure GITHUB_REPOSITORY${NC}"
    exit 1
  fi
fi

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}GitHub Project Setup — Spec Kit${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "Repository: ${GREEN}${REPO_OWNER}/${REPO_NAME}${NC}"
echo -e "Host: ${REPO_OWNER}@${GH_HOST}"
echo -e "Template: ${TEMPLATE_PROJECT_NAME}"
echo ""

# 1. Validar que o repo existe
echo -e "${BLUE}[1/4]${NC} Validando repositório..."
if ! GH_HOST="$GH_HOST" gh repo view "${REPO_OWNER}/${REPO_NAME}" --json nameWithOwner >/dev/null 2>&1; then
  echo -e "${RED}✗ Repositório não encontrado: ${REPO_OWNER}/${REPO_NAME}${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Repositório encontrado${NC}"

# 2. Criar o ProjectV2
echo ""
echo -e "${BLUE}[2/4]${NC} Criando GitHub Project V2..."

PROJECT_TITLE="${REPO_NAME} — Spec Kit Roadmap"

# Buscar o repo ID via GraphQL
REPO_ID=$(GH_HOST="$GH_HOST" gh api graphql -f owner="$REPO_OWNER" -f name="$REPO_NAME" -f query='
query($owner:String!, $name:String!) {
  repository(owner:$owner, name:$name) {
    id
  }
}' -q '.data.repository.id' 2>&1)

if [[ -z "$REPO_ID" || "$REPO_ID" == "null" ]]; then
  echo -e "${RED}✗ Não consegui obter o ID do repositório${NC}"
  exit 1
fi

echo -e "${YELLOW}  Repo ID: $REPO_ID${NC}"

# Criar o project via GraphQL mutation (requer o repositoryId correto)
PROJECT_RESPONSE=$(GH_HOST="$GH_HOST" gh api graphql \
  -f repoId="$REPO_ID" \
  -f title="$PROJECT_TITLE" \
  -f query='
mutation($repoId:ID!, $title:String!) {
  createProjectV2(input: {
    repositoryId: $repoId
    title: $title
  }) {
    projectV2 {
      id
      title
      url
    }
  }
}' 2>&1)

PROJECT_ID=$(echo "$PROJECT_RESPONSE" | jq -r '.data.createProjectV2.projectV2.id // empty' 2>/dev/null)
PROJECT_URL=$(echo "$PROJECT_RESPONSE" | jq -r '.data.createProjectV2.projectV2.url // empty' 2>/dev/null)

if [[ -z "$PROJECT_ID" ]]; then
  # Projeto pode já existir, tenta buscar
  echo -e "${YELLOW}  Project pode já existir, buscando...${NC}"
  EXISTING_PROJECT=$(GH_HOST="$GH_HOST" gh api graphql \
    -f owner="$REPO_OWNER" \
    -f name="$REPO_NAME" \
    -f query='
query($owner:String!, $name:String!) {
  repository(owner:$owner, name:$name) {
    projectsV2(first:1) {
      nodes {
        id
        title
        url
      }
    }
  }
}' -q '.data.repository.projectsV2.nodes[0] | select(.title | startswith("'"$REPO_NAME"'")) // empty' 2>/dev/null)
  
  if [[ -n "$EXISTING_PROJECT" ]]; then
    PROJECT_ID=$(echo "$EXISTING_PROJECT" | jq -r '.id')
    PROJECT_URL=$(echo "$EXISTING_PROJECT" | jq -r '.url')
    echo -e "${YELLOW}  ℹ Project já existe (reutilizando)${NC}"
  else
    echo -e "${RED}✗ Erro ao criar project: $(echo "$PROJECT_RESPONSE" | jq -r '.errors[0].message // "erro desconhecido"')${NC}"
    exit 1
  fi
else
  echo -e "${GREEN}✓ Project criado: $PROJECT_URL${NC}"
fi

# 3. Criar as VIEWS padrão (3 views, sem "View 1")
echo ""
echo -e "${BLUE}[3/4]${NC} Criando views padrão..."

# Definir as 3 views (nome, layout, filter)
declare -a VIEWS=(
  "Board por Epic|BOARD_LAYOUT|"
  "Board por Prioridade|BOARD_LAYOUT|"
  "Tabela — P0 Blocker|TABLE_LAYOUT|label:\"priority:P0-blocker\""
)

for view_config in "${VIEWS[@]}"; do
  IFS='|' read -r VIEW_NAME VIEW_LAYOUT VIEW_FILTER <<< "$view_config"
  
  # GraphQL mutation para criar uma view
  VIEW_RESPONSE=$(GH_HOST="$GH_HOST" gh api graphql \
    -f projectId="$PROJECT_ID" \
    -f viewName="$VIEW_NAME" \
    -f layout="$VIEW_LAYOUT" \
    -f filter="$VIEW_FILTER" \
    -f query='
mutation($projectId:ID!, $viewName:String!, $layout:ProjectV2ViewLayout!, $filter:String!) {
  addProjectV2View(input: {
    projectId: $projectId
    title: $viewName
    layout: $layout
    filters: [$filter]
  }) {
    view {
      id
      name
    }
  }
}' 2>&1)
  
  VIEW_NAME_RESULT=$(echo "$VIEW_RESPONSE" | jq -r '.data.addProjectV2View.view.name // empty' 2>/dev/null)
  
  if [[ -n "$VIEW_NAME_RESULT" ]]; then
    echo -e "${GREEN}  ✓ View criada: $VIEW_NAME ($VIEW_LAYOUT)${NC}"
  else
    # Pode ser que a view já exista ou que o formato do filtro seja diferente
    # Tenta sem o filtro se houver erro
    VIEW_RESPONSE=$(GH_HOST="$GH_HOST" gh api graphql \
      -f projectId="$PROJECT_ID" \
      -f viewName="$VIEW_NAME" \
      -f layout="$VIEW_LAYOUT" \
      -f query='
mutation($projectId:ID!, $viewName:String!, $layout:ProjectV2ViewLayout!) {
  addProjectV2View(input: {
    projectId: $projectId
    title: $viewName
    layout: $layout
  }) {
    view {
      id
      name
    }
  }
}' 2>&1)
    
    VIEW_NAME_RESULT=$(echo "$VIEW_RESPONSE" | jq -r '.data.addProjectV2View.view.name // empty' 2>/dev/null)
    if [[ -n "$VIEW_NAME_RESULT" ]]; then
      echo -e "${GREEN}  ✓ View criada: $VIEW_NAME ($VIEW_LAYOUT)${NC}"
      if [[ -n "$VIEW_FILTER" ]]; then
        echo -e "${YELLOW}    ℹ Filtro a aplicar manualmente: $VIEW_FILTER${NC}"
      fi
    else
      echo -e "${YELLOW}  ⚠ View pode já existir ou erro ao criar: $VIEW_NAME${NC}"
    fi
  fi
done

# 4. Resumo final
echo ""
echo -e "${BLUE}[4/4]${NC} Setup concluído!"
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "GitHub Project configurado com sucesso!"
echo -e "${GREEN}URL:${NC} ${PROJECT_URL}"
echo -e "${GREEN}ID:${NC}  ${PROJECT_ID}"
echo ""
echo -e "Views criadas:"
echo -e "  • Board por Epic"
echo -e "  • Board por Prioridade"
echo -e "  • Tabela — P0 Blocker"
echo ""
echo -e "Próximos passos:"
echo -e "  1. Abra o projeto acima e customize as views conforme necessário"
echo -e "  2. Configure os filtros e grupos para cada view"
echo -e "  3. Referencie o project no README do seu projeto"
echo -e ""
echo -e "Documentação: ${BLUE}docs/developer-guide.md${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
