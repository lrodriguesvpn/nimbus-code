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
# 2. Cria um ProjectV2 com o nome: "{repo-name} — Nimbus Code Roadmap"
# 3. Cria 5 views padrão (copiadas do IOX-CROWDFUNDINGPAAS):
#    - "Board por Epic" (board layout, filtro por type:epic)
#    - "Board por Feature" (board layout, filtro por type:feature)
#    - "Board por User Story" (board layout, filtro por type:user-story)
#    - "Board por Prioridade" (board layout, sem filtro inicial — dev personaliza)
#    - "Tabela — P0 Blocker" (table layout, filtro para P0-blocker)
# 4. Cria o campo customizado numérico "Horas Humanas", usado para controle de
#    custo real em tarefas de modelo híbrido (agente + humano) — ver
#    docs/ai-code-quality-and-observability.md seção 8
# 5. Cria o campo customizado de texto "Oportunidade D365", usado para colar a
#    URL da Oportunidade no Dynamics 365 e vincular a issue/PR à venda de origem
# 6. Cria o campo customizado de texto "Ocorrência CRM (N1)", usado para colar
#    a URL/ID do atendimento N1 do CRM quando a issue vier de uma
#    ocorrência/incidente (usar junto com o label type:incident) — ver
#    docs/label-taxonomy-and-autonomous-dev.md
# 7. Retorna o link do projeto para referência
#
# Idempotente: pode ser rodado múltiplas vezes no mesmo repo — se o Project ou
# um campo já existir, o script reaproveita/avisa em vez de duplicar ou falhar.
# É isso que permite este script ser chamado tanto pelo bootstrap.sh (uma vez,
# na criação do repo) quanto pelo workflow periódico
# .github/workflows/ensure-github-project.yml (auto-cura caso o Project seja
# apagado ou não tenha sido criado no bootstrap original, ex.: `gh` CLI
# indisponível na máquina de quem rodou o bootstrap).
#
# MultiRepo: lê docs/bounded-contexts.yaml (se existir) e vincula cada repo
# listado ao Project V2 via GraphQL (mutation linkProjectV2ToRepository).
# Requer escopo write:org no token. Se o arquivo não existir ou a API não
# estiver disponível, o passo é pulado com aviso — o restante do setup não é
# afetado.
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
echo -e "${BLUE}GitHub Project Setup — Nimbus Code${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "Repository: ${GREEN}${REPO_OWNER}/${REPO_NAME}${NC}"
echo -e "Host: ${REPO_OWNER}@${GH_HOST}"
echo -e "Template: ${TEMPLATE_PROJECT_NAME}"
echo ""

# 1. Validar que o repo existe
echo -e "${BLUE}[1/7]${NC} Validando repositório..."
if ! GH_HOST="$GH_HOST" gh repo view "${REPO_OWNER}/${REPO_NAME}" --json nameWithOwner >/dev/null 2>&1; then
  echo -e "${RED}✗ Repositório não encontrado: ${REPO_OWNER}/${REPO_NAME}${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Repositório encontrado${NC}"

# 2. Criar (ou reaproveitar) o ProjectV2
echo ""
echo -e "${BLUE}[2/7]${NC} Verificando se o project já existe..."

PROJECT_TITLE="${REPO_NAME} — Nimbus Code Roadmap"

# IMPORTANTE: checar existência ANTES de criar. createProjectV2 sempre tem
# sucesso mesmo com título duplicado (a API não impõe unicidade de título) —
# checar só depois de uma falha de criação não é suficiente e gera projects
# duplicados a cada execução do script.
# NOTA: `gh api ... -q` não aceita `--arg` (isso é uma flag do `jq`, não do
# `gh api`) — buscar o JSON completo e filtrar com `jq` separadamente.
EXISTING_PROJECT=$(GH_HOST="$GH_HOST" gh api graphql \
  -f owner="$REPO_OWNER" \
  -f name="$REPO_NAME" \
  -f query='
query($owner:String!, $name:String!) {
  repository(owner:$owner, name:$name) {
    projectsV2(first:20) {
      nodes {
        id
        title
        url
      }
    }
  }
}' 2>/dev/null | jq -r --arg t "$PROJECT_TITLE" '.data.repository.projectsV2.nodes[] | select(.title == $t)')

if [[ -n "$EXISTING_PROJECT" ]]; then
  PROJECT_ID=$(echo "$EXISTING_PROJECT" | jq -r '.id')
  PROJECT_URL=$(echo "$EXISTING_PROJECT" | jq -r '.url')
  echo -e "${YELLOW}  ℹ Project já existe (reutilizando): $PROJECT_URL${NC}"
else
  echo -e "${BLUE}  Nenhum project com este título — criando...${NC}"

  # Buscar o repo ID E o owner ID via GraphQL. NOTA (bug encontrado em
  # validação real): `createProjectV2` exige `ownerId` (obrigatório — o
  # project é criado sob um usuário/organização, não sob um repositório).
  # `repositoryId` é OPCIONAL e serve só para vincular o project ao repo na
  # UI — passar os dois.
  REPO_INFO=$(GH_HOST="$GH_HOST" gh api graphql -f owner="$REPO_OWNER" -f name="$REPO_NAME" -f query='
query($owner:String!, $name:String!) {
  repository(owner:$owner, name:$name) {
    id
    owner { id }
  }
}' 2>&1)

  REPO_ID=$(echo "$REPO_INFO" | jq -r '.data.repository.id // empty' 2>/dev/null)
  OWNER_ID=$(echo "$REPO_INFO" | jq -r '.data.repository.owner.id // empty' 2>/dev/null)

  if [[ -z "$REPO_ID" || -z "$OWNER_ID" ]]; then
    echo -e "${RED}✗ Não consegui obter o ID do repositório/owner: $(echo "$REPO_INFO" | jq -r '.errors[0].message // "erro desconhecido"' 2>/dev/null)${NC}"
    exit 1
  fi

  echo -e "${YELLOW}  Repo ID: $REPO_ID / Owner ID: $OWNER_ID${NC}"

  # Criar o project via GraphQL mutation (ownerId obrigatório, repositoryId opcional)
  PROJECT_RESPONSE=$(GH_HOST="$GH_HOST" gh api graphql \
    -f ownerId="$OWNER_ID" \
    -f repoId="$REPO_ID" \
    -f title="$PROJECT_TITLE" \
    -f query='
mutation($ownerId:ID!, $repoId:ID!, $title:String!) {
  createProjectV2(input: {
    ownerId: $ownerId
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
    echo -e "${RED}✗ Erro ao criar project: $(echo "$PROJECT_RESPONSE" | jq -r '.errors[0].message // "erro desconhecido"')${NC}"
    exit 1
  fi
  echo -e "${GREEN}✓ Project criado: $PROJECT_URL${NC}"
fi


# 3. Criar as VIEWS padrão (views hierárquicas + views existentes)
echo ""
echo -e "${BLUE}[3/9]${NC} Criando views padrão..."

# Views: nome, layout, filter
# Inclui as views originais (Board por Epic, Board por Prioridade, Tabela P0 Blocker)
# mais as novas views hierárquicas Agile introduzidas pela feature 005.
declare -a VIEWS=(
  "Board de Epics|BOARD_LAYOUT|type:\"Epic\""
  "Board de Features|BOARD_LAYOUT|type:\"Feature\""
  "Board de User Stories|BOARD_LAYOUT|type:\"User Story\""
  "Sprint Ativo|BOARD_LAYOUT|"
  "Backlog Completo|TABLE_LAYOUT|"
  "Board por Epic|BOARD_LAYOUT|"
  "Board por Prioridade|BOARD_LAYOUT|"
  "Tabela — P0 Blocker|TABLE_LAYOUT|label:\"priority:P0-blocker\""
)

# Buscar views já existentes ANTES de criar (idempotência — mesma lógica do
# passo 2: sem essa checagem, rodar o script de novo no mesmo project
# duplica as views a cada execução, já que createProjectV2View não impõe
# nome único).
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
# suporte via API (ajuste manual na UI).
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

# 4. Configurar Issue Types da org para hierarquia Agile (Epic, Feature, User Story, Task, Bug)
# NOTA: Issue Types são configurados na ORG, não no repositório. A query de
# verificação e a mutation de criação usam o owner (org) como contexto.
# Em orgs sem suporte a Issue Types (GHE Server < 3.10), este passo imprime
# aviso e ativa automaticamente o modo degradado via labels (type:epic etc.).
echo ""
echo -e "${BLUE}[4/9]${NC} Configurando Issue Types da org (hierarquia Agile)..."

# Definir os 5 Issue Types padrão: nome, cor, descrição
# Cores suportadas pela API: RED, ORANGE, YELLOW, GREEN, BLUE, PURPLE, PINK, GRAY
declare -a ISSUE_TYPES=(
  "Epic|PURPLE|Iniciativa de negócio — pai de Features; rastreia progresso de múltiplas Features no board"
  "Feature|BLUE|Entrega de funcionalidade — sub-issue de Epic; tem correspondência 1:1 com specs/NNN-slug/"
  "User Story|GREEN|Requisito de usuário — sub-issue de Feature; corresponde a seção [USN] do spec.md"
  "Task|GRAY|Unidade de implementação — sub-issue de User Story; gerada pelo /speckit-taskstoissues a partir de T00N"
  "Bug|RED|Comportamento incorreto em relação ao especificado — pode ser sub-issue de qualquer nível"
)

# Verificar se a org suporta Issue Types antes de tentar criar
ISSUE_TYPES_SUPPORT=$(GH_HOST="$GH_HOST" gh api graphql \
  -f owner="$REPO_OWNER" \
  -f query='
query($owner:String!) {
  organization(login:$owner) {
    issueTypes(first: 20) {
      nodes { id name }
    }
  }
}' 2>/dev/null || echo "ERROR")

if echo "$ISSUE_TYPES_SUPPORT" | grep -q '"issueTypes"'; then
  EXISTING_ISSUE_TYPES_JSON=$(echo "$ISSUE_TYPES_SUPPORT" | jq -c '.data.organization.issueTypes.nodes // []' 2>/dev/null)
  echo -e "${GREEN}  ✓ Org suporta Issue Types nativos — verificando/criando tipos...${NC}"

  for type_config in "${ISSUE_TYPES[@]}"; do
    IFS='|' read -r TYPE_NAME TYPE_COLOR TYPE_DESC <<< "$type_config"

    ALREADY_EXISTS=$(echo "$EXISTING_ISSUE_TYPES_JSON" | jq -r --arg n "$TYPE_NAME" '.[] | select(.name == $n) | .name' | head -1)
    if [[ -n "$ALREADY_EXISTS" ]]; then
      echo -e "${YELLOW}    ℹ Issue Type já existe (pulando): $TYPE_NAME${NC}"
      continue
    fi

    TYPE_RESPONSE=$(GH_HOST="$GH_HOST" gh api graphql \
      -f owner="$REPO_OWNER" \
      -f typeName="$TYPE_NAME" \
      -f typeColor="$TYPE_COLOR" \
      -f typeDesc="$TYPE_DESC" \
      -f query='
mutation($owner:String!, $typeName:String!, $typeColor:IssueTypeColor!, $typeDesc:String!) {
  createIssueType(input: {
    organizationLogin: $owner
    name: $typeName
    color: $typeColor
    description: $typeDesc
  }) {
    issueType { id name }
  }
}' 2>&1) || true

    TYPE_RESULT=$(echo "$TYPE_RESPONSE" | jq -r '.data.createIssueType.issueType.name // empty' 2>/dev/null)
    if [[ -n "$TYPE_RESULT" ]]; then
      echo -e "${GREEN}    ✓ Issue Type criado: $TYPE_NAME${NC}"
    else
      echo -e "${YELLOW}    ⚠ Falha ao criar Issue Type: $TYPE_NAME — $(echo "$TYPE_RESPONSE" | jq -r '.errors[0].message // "erro desconhecido"' 2>/dev/null)${NC}"
      echo -e "${YELLOW}      Crie manualmente em: Org Settings → Planning → Issue types${NC}"
    fi
  done
else
  echo -e "${YELLOW}  ⚠ [MODO DEGRADADO] Org não suporta Issue Types nativos (GHE Server legado).${NC}"
  echo -e "${YELLOW}    Issue Types não serão criados. O fluxo do /speckit-taskstoissues usará${NC}"
  echo -e "${YELLOW}    labels type:epic, type:feature, type:user-story, type:task como fallback.${NC}"
  echo -e "${YELLOW}    Execute setup-github-labels.sh para garantir que os labels existem.${NC}"
fi

# Buscar campos já existentes ANTES de criar (idempotência — o mesmo motivo
# das views acima: sem essa checagem, rodar de novo falha com "Name has
# already been taken" e, por causa do `set -e`, aborta o script inteiro em
# vez de reportar "já existe" e seguir para o próximo passo).
EXISTING_FIELDS_JSON=$(GH_HOST="$GH_HOST" gh api graphql -f projectId="$PROJECT_ID" -f query='
query($projectId:ID!) {
  node(id: $projectId) {
    ... on ProjectV2 {
      fields(first: 50) { nodes { ... on ProjectV2FieldCommon { id name } } }
    }
  }
}' 2>/dev/null | jq -c '.data.node.fields.nodes // []')

field_already_exists() {
  echo "$EXISTING_FIELDS_JSON" | jq -e --arg n "$1" 'any(.[]; .name == $n)' >/dev/null 2>&1
}

# 5. Criar campo customizado "Horas Humanas" (controle de custo em modelo híbrido)
echo ""
echo -e "${BLUE}[5/9]${NC} Criando campo customizado \"Horas Humanas\"..."

if field_already_exists "Horas Humanas"; then
  echo -e "${YELLOW}  ℹ Campo já existe (pulando): Horas Humanas${NC}"
else
  FIELD_RESPONSE=$(GH_HOST="$GH_HOST" gh api graphql \
    -f projectId="$PROJECT_ID" \
    -f fieldName="Horas Humanas" \
    -f query='
mutation($projectId:ID!, $fieldName:String!) {
  createProjectV2Field(input: {
    projectId: $projectId
    dataType: NUMBER
    name: $fieldName
  }) {
    projectV2Field {
      ... on ProjectV2Field {
        id
        name
      }
    }
  }
}' 2>&1) || true

  FIELD_NAME_RESULT=$(echo "$FIELD_RESPONSE" | jq -r '.data.createProjectV2Field.projectV2Field.name // empty' 2>/dev/null)

  if [[ -n "$FIELD_NAME_RESULT" ]]; then
    echo -e "${GREEN}  ✓ Campo criado: Horas Humanas (número)${NC}"
  else
    echo -e "${YELLOW}  ⚠ Campo pode já existir ou erro ao criar (crie manualmente se necessário): Horas Humanas${NC}"
  fi
fi

# 6. Criar campo customizado "Oportunidade D365" (link para o CRM)
echo ""
echo -e "${BLUE}[6/9]${NC} Criando campo customizado \"Oportunidade D365\"..."

if field_already_exists "Oportunidade D365"; then
  echo -e "${YELLOW}  ℹ Campo já existe (pulando): Oportunidade D365${NC}"
else
  D365_FIELD_RESPONSE=$(GH_HOST="$GH_HOST" gh api graphql \
    -f projectId="$PROJECT_ID" \
    -f fieldName="Oportunidade D365" \
    -f query='
mutation($projectId:ID!, $fieldName:String!) {
  createProjectV2Field(input: {
    projectId: $projectId
    dataType: TEXT
    name: $fieldName
  }) {
    projectV2Field {
      ... on ProjectV2Field {
        id
        name
      }
    }
  }
}' 2>&1) || true

  D365_FIELD_NAME_RESULT=$(echo "$D365_FIELD_RESPONSE" | jq -r '.data.createProjectV2Field.projectV2Field.name // empty' 2>/dev/null)

  if [[ -n "$D365_FIELD_NAME_RESULT" ]]; then
    echo -e "${GREEN}  ✓ Campo criado: Oportunidade D365 (texto)${NC}"
  else
    echo -e "${YELLOW}  ⚠ Campo pode já existir ou erro ao criar (crie manualmente se necessário): Oportunidade D365${NC}"
  fi
fi

# 7. Criar campo customizado "Ocorrência CRM (N1)" (link para incidentes/recorrência)
echo ""
echo -e "${BLUE}[7/9]${NC} Criando campo customizado \"Ocorrência CRM (N1)\"..."

if field_already_exists "Ocorrência CRM (N1)"; then
  echo -e "${YELLOW}  ℹ Campo já existe (pulando): Ocorrência CRM (N1)${NC}"
else
  CRM_FIELD_RESPONSE=$(GH_HOST="$GH_HOST" gh api graphql \
    -f projectId="$PROJECT_ID" \
    -f fieldName="Ocorrência CRM (N1)" \
    -f query='
mutation($projectId:ID!, $fieldName:String!) {
  createProjectV2Field(input: {
    projectId: $projectId
    dataType: TEXT
    name: $fieldName
  }) {
    projectV2Field {
      ... on ProjectV2Field {
        id
        name
      }
    }
  }
}' 2>&1) || true

  CRM_FIELD_NAME_RESULT=$(echo "$CRM_FIELD_RESPONSE" | jq -r '.data.createProjectV2Field.projectV2Field.name // empty' 2>/dev/null)

  if [[ -n "$CRM_FIELD_NAME_RESULT" ]]; then
    echo -e "${GREEN}  ✓ Campo criado: Ocorrência CRM (N1) (texto)${NC}"
  else
    echo -e "${YELLOW}  ⚠ Campo pode já existir ou erro ao criar (crie manualmente se necessário): Ocorrência CRM (N1)${NC}"
  fi
fi

# 8. Criar campo customizado "Priority" (single-select sincronizado com labels priority:*)
echo ""
echo -e "${BLUE}[8/9]${NC} Criando campo customizado \"Priority\" (single-select)..."

if field_already_exists "Priority"; then
  echo -e "${YELLOW}  ℹ Campo já existe (pulando): Priority${NC}"
else
  PRIORITY_FIELD_RESPONSE=$(GH_HOST="$GH_HOST" gh api graphql \
    -f projectId="$PROJECT_ID" \
    -f query='
mutation($projectId:ID!) {
  createProjectV2Field(input: {
    projectId: $projectId
    dataType: SINGLE_SELECT
    name: "Priority"
    singleSelectOptions: [
      {name: "P0-blocker", color: RED,    description: "Bloqueador — trata antes de qualquer outro item"},
      {name: "P1-high",    color: ORANGE, description: "Próximo item a puxar após todo P0"},
      {name: "P2-medium",  color: YELLOW, description: "Planejado, sem urgência imediata"},
      {name: "P3-low",     color: GREEN,  description: "Nice-to-have"}
    ]
  }) {
    projectV2Field {
      ... on ProjectV2SingleSelectField {
        id
        name
      }
    }
  }
}' 2>&1) || true

  PRIORITY_FIELD_NAME_RESULT=$(echo "$PRIORITY_FIELD_RESPONSE" | jq -r '.data.createProjectV2Field.projectV2Field.name // empty' 2>/dev/null)

  if [[ -n "$PRIORITY_FIELD_NAME_RESULT" ]]; then
    echo -e "${GREEN}  ✓ Campo criado: Priority (single-select: P0-blocker/P1-high/P2-medium/P3-low)${NC}"
  else
    echo -e "${YELLOW}  ⚠ Campo pode já existir ou erro ao criar (crie manualmente se necessário): Priority${NC}"
  fi
fi

# 9. Vincular repos de serviço ao Project V2 (MultiRepo — bounded-contexts.yaml)
# Lê docs/bounded-contexts.yaml relativo à raiz git do diretório de CHAMADA
# ($PWD via `git rev-parse --show-toplevel`, sem -C) — não ao diretório físico
# do script — com fallback para o clone do próprio script apenas se o chamador
# não estiver dentro de um repo git com esse arquivo (ver issue #21). Extrai o
# campo repository e vincula ao Project V2 via GraphQL (mutation
# linkProjectV2ToRepository).
# Requer escopo write:org no token. Erros isolados por repo não abortam o setup.
echo ""
echo -e "${BLUE}[9/10]${NC} Vinculando repos de serviço ao Project V2 (MultiRepo)..."

# Locate bounded-contexts.yaml relative to the caller's working directory
# first (the consumer project — see issue #21: resolving via BASH_SOURCE made
# the script read the template's own bounded-contexts.yaml when invoked by
# absolute path from another clone). Only fall back to the script's own clone
# when the caller isn't inside a git repo (or that repo has no such file) —
# e.g. when developing the template itself from within its own clone.
_SCRIPT_DIR_SGP="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
_BC_FILE=""
_BC_CANDIDATES=()
[[ -n "$_GIT_ROOT" ]] && _BC_CANDIDATES+=("${_GIT_ROOT}/docs/bounded-contexts.yaml")
_BC_CANDIDATES+=("${_SCRIPT_DIR_SGP}/../docs/bounded-contexts.yaml")
for _candidate in "${_BC_CANDIDATES[@]}"; do
    if [[ -f "$_candidate" ]]; then
        _BC_FILE="$_candidate"
        break
    fi
done

if [[ -z "$_BC_FILE" ]]; then
    echo -e "${YELLOW}  ℹ docs/bounded-contexts.yaml não encontrado — pulando vínculo de repos.${NC}"
    echo -e "    Crie o arquivo para habilitar o board cross-repo (ver docs/developer-guide.md)."
else
    # Parse YAML: prefer yq, then python3, then skip with instructions
    _parse_bc_repos() {
        local file="$1"
        if command -v yq >/dev/null 2>&1; then
            yq e '.contexts[].repository' "$file" 2>/dev/null | grep -v '^null$' | grep -v '^$'
        elif python3 -c "import yaml" 2>/dev/null; then
            python3 - "$file" <<'PYEOF'
import sys, yaml
with open(sys.argv[1]) as f:
    data = yaml.safe_load(f) or {}
for ctx in (data.get("contexts") or []):
    if isinstance(ctx, dict) and ctx.get("repository"):
        print(ctx["repository"])
PYEOF
        else
            grep -E '^\s+repository:' "$file" | sed 's/.*repository:[[:space:]]*"*//; s/"*[[:space:]]*//'
        fi
    }

    # Get the project's owner node ID (for linkProjectV2ToRepository)
    _ORG_NODE_ID=$(GH_HOST="$GH_HOST" gh api graphql -f login="$REPO_OWNER" -f query='
    query($login:String!) {
      organization(login: $login) { id }
    }' 2>/dev/null | jq -r '.data.organization.id // empty')

    REPOS_LINKED=0
    REPOS_ALREADY=0
    REPOS_FAILED=0

    while IFS= read -r _REPO_FULL; do
        _REPO_FULL="${_REPO_FULL%$'\r'}"
        [[ -z "$_REPO_FULL" ]] && continue
        _REPO_OWNER_SVC="${_REPO_FULL%%/*}"
        _REPO_NAME_SVC="${_REPO_FULL##*/}"

        # Get repo node ID (guarded with `|| true`: a repo not found or
        # inaccessible must not abort the whole script under set -e/pipefail —
        # errors are isolated per-repo per the function's own contract above)
        _REPO_NODE_ID=$( { GH_HOST="$GH_HOST" gh api graphql \
            -f owner="$_REPO_OWNER_SVC" -f name="$_REPO_NAME_SVC" -f query='
        query($owner:String!, $name:String!) {
          repository(owner: $owner, name: $name) { id }
        }' 2>/dev/null || true; } | jq -r '.data.repository.id // empty')

        if [[ -z "$_REPO_NODE_ID" ]]; then
            echo -e "${YELLOW}  ⚠ Repo não encontrado ou sem acesso: ${_REPO_FULL} — pulando${NC}"
            REPOS_FAILED=$((REPOS_FAILED + 1))
            continue
        fi

        # Try to link; linkProjectV2ToRepository is idempotent on GHE ≥ 3.8
        _LINK_RESPONSE=$(GH_HOST="$GH_HOST" gh api graphql \
            -f projectId="$PROJECT_ID" -f repositoryId="$_REPO_NODE_ID" -f query='
        mutation($projectId:ID!, $repositoryId:ID!) {
          linkProjectV2ToRepository(input: {projectId: $projectId, repositoryId: $repositoryId}) {
            repository { nameWithOwner }
          }
        }' 2>&1) || true

        _LINKED_NAME=$(echo "$_LINK_RESPONSE" | jq -r '.data.linkProjectV2ToRepository.repository.nameWithOwner // empty' 2>/dev/null)

        if [[ -n "$_LINKED_NAME" ]]; then
            echo -e "${GREEN}  ✓ Vinculado: ${_REPO_FULL}${NC}"
            REPOS_LINKED=$((REPOS_LINKED + 1))
        else
            _ERR_MSG=$(echo "$_LINK_RESPONSE" | jq -r '.errors[0].message // empty' 2>/dev/null)
            if echo "$_ERR_MSG" | grep -qi "already\|existe\|linked"; then
                echo -e "${YELLOW}  ↻ Já vinculado: ${_REPO_FULL}${NC}"
                REPOS_ALREADY=$((REPOS_ALREADY + 1))
            else
                echo -e "${YELLOW}  ⚠ Falha ao vincular: ${_REPO_FULL}${NC}"
                if [[ -n "$_ERR_MSG" ]]; then
                    echo -e "    Erro: ${_ERR_MSG}" >&2
                fi
                echo -e "    Verifique se o token tem escopo write:org e se a API linkProjectV2ToRepository"
                echo -e "    está disponível (requer GHE ≥ 3.8). Para vincular manualmente:"
                echo -e "    Project → Settings → Linked Repositories → Add repository"
                REPOS_FAILED=$((REPOS_FAILED + 1))
            fi
        fi
    done < <(_parse_bc_repos "$_BC_FILE")

    echo -e "  Repos processados: vinculados=${REPOS_LINKED} já-vinculados=${REPOS_ALREADY} falhas=${REPOS_FAILED}"
fi

# 10. Resumo final
echo ""
echo -e "${BLUE}[10/10]${NC} Setup concluído!"
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "GitHub Project configurado com sucesso!"
echo -e "${GREEN}URL:${NC} ${PROJECT_URL}"
echo -e "${GREEN}ID:${NC}  ${PROJECT_ID}"
echo ""
echo -e "Issue Types da org (hierarquia Agile):"
echo -e "  • Epic (roxo) — iniciativa de negócio, pai de Features"
echo -e "  • Feature (azul) — entrega de funcionalidade, sub-issue de Epic"
echo -e "  • User Story (verde) — requisito de usuário, sub-issue de Feature"
echo -e "  • Task (cinza) — unidade de implementação, sub-issue de User Story"
echo -e "  • Bug (vermelho) — comportamento incorreto"
echo -e "  ℹ Em modo degradado (org sem Issue Types): use labels type:epic/"
echo -e "    type:feature/type:user-story/type:task criados pelo setup-github-labels.sh"
echo ""
echo -e "Views criadas:"
echo -e "  • Board de Epics (filtro: type:Epic)"
echo -e "  • Board de Features (filtro: type:Feature)"
echo -e "  • Board de User Stories (filtro: type:User Story)"
echo -e "  • Sprint Ativo (sem filtro — configure 'group by' e 'iteration' manualmente na UI)"
echo -e "  • Backlog Completo (tabela, sem filtro)"
echo -e "  • Board por Epic (sem filtro — configure 'group by' manualmente)"
echo -e "  • Board por Prioridade (sem filtro — configure 'group by' manualmente)"
echo -e "  • Tabela — P0 Blocker (filtro: priority:P0-blocker)"
echo -e "  ℹ NOTA: 'Group by' não é configurável via API — ajuste manualmente na UI"
echo -e "    de cada view após a criação."
echo ""
echo -e "Campos customizados criados:"
echo -e "  • Horas Humanas (número) — para lançar horas de trabalho humano em"
echo -e "    tarefas de modelo híbrido (agente + humano) e compor custo real"
echo -e "    (tokens + horas × custo/hora). Ver docs/ai-code-quality-and-observability.md"
echo -e "    seção 8."
echo -e "  • Oportunidade D365 (texto) — cole a URL completa da Oportunidade no"
echo -e "    Dynamics 365 para vincular a issue/PR à venda/negócio de origem."
echo -e "  • Ocorrência CRM (N1) (texto) — cole a URL/ID do atendimento N1 no CRM"
echo -e "    quando a issue vier de uma ocorrência/incidente (use com o label"
echo -e "    type:incident). Ver docs/label-taxonomy-and-autonomous-dev.md."
echo -e "  • Priority (single-select) — espelha o label priority:* como campo nativo,"
echo -e "    para permitir \"Group by Priority\" sem misturar outras famílias de label."
echo -e "    Preenchido automaticamente por .github/workflows/sync-priority-field.yml"
echo -e "    (template em templates/workflows/) sempre que o label priority:* mudar —"
echo -e "    instale esse workflow no repositório para manter o campo sincronizado."
echo ""
echo -e "Próximos passos:"
echo -e "  1. Abra o projeto acima e customize as views conforme necessário"
echo -e "  2. Configure 'group by' e 'iteration' em Sprint Ativo e Board de Epics na UI"
echo -e "  3. Referencie o project no README do seu projeto"
echo -e "  4. Preencha o campo \"Oportunidade D365\" nas issues vinculadas a uma"
echo -e "     venda/oportunidade específica (opcional para trabalho interno/técnico)"
echo -e "  5. Preencha \"Ocorrência CRM (N1)\" + label type:incident nas issues"
echo -e "     originadas de uma ocorrência/atendimento tratado inicialmente no CRM"
echo -e "  6. MultiRepo: preencha docs/bounded-contexts.yaml com os repos de serviço"
echo -e "     e rode este script novamente para vinculá-los ao board cross-repo"
echo -e "     (ver docs/developer-guide.md — seção 'MultiRepo — Registrando Microsserviços')"
echo -e ""
echo -e "Documentação: ${BLUE}docs/developer-guide.md${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
