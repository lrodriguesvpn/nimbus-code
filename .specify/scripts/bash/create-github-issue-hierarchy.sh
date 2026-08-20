#!/usr/bin/env bash

###############################################################################
# create-github-issue-hierarchy.sh
#
# Helper de automação usado por /speckit-taskstoissues (feature
# specs/005-epic-feature-us-ghe-hierarchy) para criar e vincular a hierarquia
# Epic -> Feature -> User Story -> Task no GHE via sub-issues nativos
# (GraphQL: addSubIssue / updateIssueIssueType).
#
# Este script NÃO cria as issues de Task em si (isso continua sendo feito
# pelo próprio /speckit-taskstoissues via GitHub MCP, que já sabe calcular
# labels de prioridade/complexidade/agente a partir do texto da task). Ele
# cuida da parte estrutural que faltava:
#   - Criar (ou reaproveitar) a issue de Feature e vinculá-la ao Epic
#   - Criar (ou reaproveitar) cada issue de User Story e vinculá-la à Feature
#   - Vincular uma issue de Task já criada como sub-issue da User Story certa
#   - Aplicar o Issue Type nativo correto (Epic/Feature/User Story/Task) com
#     fallback gracioso para labels type:* quando a org não suporta Issue
#     Types nativos
#   - Alertar/abortar quando um parent se aproxima do limite de 100 sub-issues
#
# Uso:
#   create-github-issue-hierarchy.sh <comando> [opções]
#
# Comandos:
#   check-issue-types   Imprime "native" ou "labels" conforme suporte da org
#   ensure-feature      Cria/reaproveita a issue de Feature e a vincula ao Epic
#   ensure-user-story   Cria/reaproveita a issue de User Story e a vincula à Feature
#   link-task           Vincula uma issue de Task existente como sub-issue da User Story
#   set-type            Aplica o Issue Type (nativo ou label) numa issue existente
#
# Opções comuns:
#   --repo-owner <owner>     Obrigatório (ou GITHUB_REPOSITORY=owner/repo)
#   --repo-name  <name>      Obrigatório (ou GITHUB_REPOSITORY=owner/repo)
#   --feature-dir <path>     Caminho de specs/NNN-slug (obrigatório em
#                            ensure-feature/ensure-user-story, usado para
#                            derivar o slug do marcador de deduplicação)
#   --json                   Emite o resultado em JSON de uma linha
#   --dry-run                Só mostra o que seria feito, sem chamar mutations
#
# Opções específicas:
#   ensure-feature:
#     --epic-issue <N>       Número da Epic issue pai (opcional; sem ela a
#                             Feature é criada/reaproveitada sem vínculo)
#     --title <texto>        Título da feature (default: primeiro H1 do spec.md)
#   ensure-user-story:
#     --us-id <USN>          Ex.: US1, US2 (obrigatório)
#     --title <texto>        Título da User Story (obrigatório)
#     --parent-issue <N>     Número da issue de Feature pai (obrigatório)
#   link-task:
#     --parent-issue <N>     Número da issue de User Story pai (obrigatório)
#     --child-issue <N>      Número da issue de Task já criada (obrigatório)
#   set-type:
#     --issue <N>            Número da issue a receber o tipo (obrigatório)
#     --type <TypeName>      Epic | Feature | "User Story" | Task | Bug
#
# Variáveis de ambiente suportadas:
#   - GH_HOST (padrão: venha-pra-nuvem.ghe.com)
#   - GITHUB_REPOSITORY (owner/repo — usado se --repo-owner/--repo-name
#     não forem passados)
#
# Idempotente: reexecutar com os mesmos parâmetros não cria duplicatas —
# tanto as issues (deduplicação por marcador oculto no corpo, no padrão já
# usado por outras automações deste repositório — ver
# docs/reuse-catalog.yaml, tag speckit-deduplication-by-id) quanto os
# vínculos de sub-issue (checa o parent atual antes de vincular de novo).
#
###############################################################################

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

GH_HOST="${GH_HOST:-venha-pra-nuvem.ghe.com}"
SUB_ISSUE_WARN_THRESHOLD=90
SUB_ISSUE_HARD_LIMIT=100

COMMAND="${1:-}"
[[ $# -gt 0 ]] && shift || true

REPO_OWNER=""
REPO_NAME=""
FEATURE_DIR=""
EPIC_ISSUE=""
US_ID=""
TITLE=""
PARENT_ISSUE=""
CHILD_ISSUE=""
ISSUE_NUMBER=""
ISSUE_TYPE_NAME=""
JSON_MODE=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-owner) REPO_OWNER="$2"; shift 2 ;;
    --repo-name) REPO_NAME="$2"; shift 2 ;;
    --feature-dir) FEATURE_DIR="$2"; shift 2 ;;
    --epic-issue) EPIC_ISSUE="$2"; shift 2 ;;
    --us-id) US_ID="$2"; shift 2 ;;
    --title) TITLE="$2"; shift 2 ;;
    --parent-issue) PARENT_ISSUE="$2"; shift 2 ;;
    --child-issue) CHILD_ISSUE="$2"; shift 2 ;;
    --issue) ISSUE_NUMBER="$2"; shift 2 ;;
    --type) ISSUE_TYPE_NAME="$2"; shift 2 ;;
    --json) JSON_MODE=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --help|-h)
      sed -n '3,60p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo -e "${RED}Opção desconhecida: $1${NC}" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$REPO_OWNER" || -z "$REPO_NAME" ]]; then
  if [[ -n "${GITHUB_REPOSITORY:-}" ]]; then
    REPO_OWNER="${GITHUB_REPOSITORY%/*}"
    REPO_NAME="${GITHUB_REPOSITORY#*/}"
  else
    echo -e "${RED}Erro: --repo-owner e --repo-name são obrigatórios (ou configure GITHUB_REPOSITORY)${NC}" >&2
    exit 1
  fi
fi

if [[ -z "$COMMAND" ]]; then
  echo -e "${RED}Erro: comando obrigatório (check-issue-types | ensure-feature | ensure-user-story | link-task | set-type)${NC}" >&2
  exit 1
fi

REPO_SLUG="${REPO_OWNER}/${REPO_NAME}"

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr -d '\n'
}

# -----------------------------------------------------------------------------
# Detecção de suporte a Issue Types nativos (mesma query usada em
# scripts/setup-github-project.sh — mantida consistente de propósito para que
# os dois scripts nunca discordem sobre o modo (nativo vs. degradado)).
# -----------------------------------------------------------------------------
ISSUE_TYPES_JSON="[]"
ISSUE_TYPES_MODE=""

detect_issue_types_support() {
  [[ -n "$ISSUE_TYPES_MODE" ]] && return 0

  local support
  support=$(GH_HOST="$GH_HOST" gh api graphql \
    -f owner="$REPO_OWNER" \
    -f query='
query($owner:String!) {
  organization(login:$owner) {
    issueTypes(first: 20) {
      nodes { id name }
    }
  }
}' 2>/dev/null || echo "ERROR")

  if echo "$support" | grep -q '"issueTypes"'; then
    ISSUE_TYPES_JSON=$(echo "$support" | jq -c '.data.organization.issueTypes.nodes // []' 2>/dev/null)
    ISSUE_TYPES_MODE="native"
  else
    ISSUE_TYPES_MODE="labels"
  fi
}

# Mapeia o nome do Issue Type para o label de fallback equivalente
type_name_to_label() {
  case "$1" in
    "Epic") echo "type:epic" ;;
    "Feature") echo "type:feature" ;;
    "User Story") echo "type:user-story" ;;
    "Task") echo "type:task" ;;
    "Bug") echo "type:bug" ;;
    *) echo "" ;;
  esac
}

get_issue_type_id() {
  echo "$ISSUE_TYPES_JSON" | jq -r --arg n "$1" '.[] | select(.name == $n) | .id' | head -1
}

# -----------------------------------------------------------------------------
# Aplica o Issue Type correto numa issue (nativo, com fallback para label).
# Args: $1 = número da issue, $2 = nome do tipo (Epic|Feature|User Story|Task|Bug)
# -----------------------------------------------------------------------------
apply_issue_type() {
  local issue_number="$1" type_name="$2"
  detect_issue_types_support

  if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}  [dry-run] aplicaria Issue Type '$type_name' (modo: $ISSUE_TYPES_MODE) em #$issue_number${NC}"
    return 0
  fi

  if [[ "$ISSUE_TYPES_MODE" == "native" ]]; then
    local type_id
    type_id=$(get_issue_type_id "$type_name")
    if [[ -z "$type_id" ]]; then
      echo -e "${YELLOW}  ⚠ Issue Type '$type_name' não encontrado na org — aplicando label de fallback${NC}" >&2
      local label
      label=$(type_name_to_label "$type_name")
      [[ -n "$label" ]] && GH_HOST="$GH_HOST" gh issue edit "$issue_number" --repo "$REPO_SLUG" --add-label "$label" >/dev/null 2>&1 || true
      return 0
    fi

    local issue_node_id
    issue_node_id=$(get_issue_node_id "$issue_number")
    GH_HOST="$GH_HOST" gh api graphql \
      -f issueId="$issue_node_id" -f issueTypeId="$type_id" \
      -f query='
mutation($issueId:ID!, $issueTypeId:ID!) {
  updateIssueIssueType(input: { issueId: $issueId, issueTypeId: $issueTypeId }) {
    issue { id number }
  }
}' >/dev/null 2>&1 || echo -e "${YELLOW}  ⚠ Falha ao aplicar Issue Type nativo '$type_name' em #$issue_number — aplique manualmente${NC}" >&2
    echo -e "${GREEN}  ✓ Issue Type '$type_name' aplicado em #$issue_number${NC}"
  else
    echo -e "${YELLOW}  [MODO DEGRADADO] Issue Types não disponíveis — usando label como fallback${NC}"
    local label
    label=$(type_name_to_label "$type_name")
    if [[ -n "$label" ]]; then
      GH_HOST="$GH_HOST" gh issue edit "$issue_number" --repo "$REPO_SLUG" --add-label "$label" >/dev/null 2>&1 \
        && echo -e "${GREEN}  ✓ Label '$label' aplicado em #$issue_number${NC}" \
        || echo -e "${YELLOW}  ⚠ Falha ao aplicar label '$label' em #$issue_number — o label existe? rode scripts/setup-github-labels.sh${NC}" >&2
    fi
  fi
}

get_issue_node_id() {
  GH_HOST="$GH_HOST" gh issue view "$1" --repo "$REPO_SLUG" --json id -q '.id'
}

get_issue_parent_number() {
  local response
  response=$(GH_HOST="$GH_HOST" gh api graphql \
    -f owner="$REPO_OWNER" -f name="$REPO_NAME" -F number="$1" \
    -f query='
query($owner:String!, $name:String!, $number:Int!) {
  repository(owner:$owner, name:$name) {
    issue(number:$number) {
      parent { number }
    }
  }
}' 2>&1) || { echo -e "${YELLOW}  ⚠ Falha ao consultar parent de #$1 — assumindo sem parent (verifique manualmente se persistir): $response${NC}" >&2; echo ""; return 0; }
  echo "$response" | jq -r '.data.repository.issue.parent.number // empty' 2>/dev/null
}

get_sub_issue_count() {
  local response
  response=$(GH_HOST="$GH_HOST" gh api graphql \
    -f owner="$REPO_OWNER" -f name="$REPO_NAME" -F number="$1" \
    -f query='
query($owner:String!, $name:String!, $number:Int!) {
  repository(owner:$owner, name:$name) {
    issue(number:$number) {
      subIssuesSummary { total }
    }
  }
}' 2>&1) || { echo -e "${YELLOW}  ⚠ Falha ao consultar sub-issues de #$1 — assumindo 0 (verifique manualmente se persistir): $response${NC}" >&2; echo "0"; return 0; }
  echo "$response" | jq -r '.data.repository.issue.subIssuesSummary.total // 0' 2>/dev/null
}

# -----------------------------------------------------------------------------
# Vincula child_number como sub-issue de parent_number, com deduplicação
# (não vincula de novo se já é o parent atual) e alerta de limite de
# sub-issues (T012 — aviso em >=90, abort em >=100).
# -----------------------------------------------------------------------------
link_sub_issue() {
  local parent_number="$1" child_number="$2"

  if [[ "$parent_number" == "$child_number" ]]; then
    echo -e "${RED}  ✗ Parent e child são a mesma issue (#$parent_number) — pulando vínculo${NC}" >&2
    return 1
  fi

  local current_parent
  current_parent=$(get_issue_parent_number "$child_number")
  if [[ "$current_parent" == "$parent_number" ]]; then
    echo -e "${GREEN}  ✓ #$child_number já é sub-issue de #$parent_number — vínculo já existe${NC}"
    return 0
  fi
  if [[ -n "$current_parent" && "$current_parent" != "$parent_number" ]]; then
    echo -e "${YELLOW}  ⚠ #$child_number já tem outro parent (#$current_parent) — não reparentando automaticamente. Verifique manualmente.${NC}" >&2
    return 1
  fi

  local sub_count
  sub_count=$(get_sub_issue_count "$parent_number")
  if [[ "$sub_count" -ge "$SUB_ISSUE_HARD_LIMIT" ]]; then
    echo -e "${RED}  ✗ Parent #$parent_number já tem $sub_count sub-issues (limite do GHE: $SUB_ISSUE_HARD_LIMIT). Abortando vínculo — divida a Feature/User Story em partes menores.${NC}" >&2
    return 2
  elif [[ "$sub_count" -ge "$SUB_ISSUE_WARN_THRESHOLD" ]]; then
    echo -e "${YELLOW}  ⚠ Parent #$parent_number tem $sub_count sub-issues — aproximando do limite de $SUB_ISSUE_HARD_LIMIT. Considere dividir em breve.${NC}" >&2
  fi

  if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}  [dry-run] vincularia #$child_number como sub-issue de #$parent_number${NC}"
    return 0
  fi

  local parent_id child_id
  parent_id=$(get_issue_node_id "$parent_number")
  child_id=$(get_issue_node_id "$child_number")

  local response
  response=$(GH_HOST="$GH_HOST" gh api graphql \
    -f issueId="$parent_id" -f subIssueId="$child_id" \
    -f query='
mutation($issueId:ID!, $subIssueId:ID!) {
  addSubIssue(input: { issueId: $issueId, subIssueId: $subIssueId }) {
    issue { number }
    subIssue { number }
  }
}' 2>&1) || true

  if echo "$response" | jq -e '.data.addSubIssue.subIssue.number' >/dev/null 2>&1; then
    echo -e "${GREEN}  ✓ #$child_number vinculada como sub-issue de #$parent_number${NC}"
  else
    echo -e "${RED}  ✗ Falha ao vincular #$child_number a #$parent_number: $(echo "$response" | jq -r '.errors[0].message // "erro desconhecido"' 2>/dev/null)${NC}" >&2
    return 1
  fi
}

# -----------------------------------------------------------------------------
# Deduplicação por marcador oculto no corpo da issue (mesmo padrão de
# `<!-- marker-id: valor -->` + `gh issue list --search` já usado em outras
# automações deste repositório — reuse-catalog tag speckit-deduplication-by-id).
# search do GHE é tokenizado (não é substring exato), então o resultado do
# `gh issue list --search` é apenas uma pré-filtragem; a confirmação final é
# feita conferindo o marcador EXATO no corpo via jq.
# -----------------------------------------------------------------------------
find_issue_by_marker() {
  local marker_prefix="$1" marker_exact="$2"
  local candidates
  candidates=$(GH_HOST="$GH_HOST" gh issue list --repo "$REPO_SLUG" \
    --search "${marker_prefix} in:body" --state all \
    --json number,body --limit 100 2>/dev/null || echo "[]")
  echo "$candidates" | jq -r --arg m "$marker_exact" \
    '[.[] | select(.body != null and (.body | contains($m)))] | first.number // empty'
}

slug_from_feature_dir() {
  basename "$1"
}

spec_title_from_feature_dir() {
  local feature_dir="$1" spec_file title
  spec_file="$feature_dir/spec.md"
  if [[ -f "$spec_file" ]]; then
    title=$(grep -m1 '^# ' "$spec_file" | sed -E 's/^#\s*//; s/^Feature Specification:\s*//')
    [[ -n "$title" ]] && { echo "$title"; return 0; }
  fi
  slug_from_feature_dir "$feature_dir"
}

# -----------------------------------------------------------------------------
# ensure-feature: cria/reaproveita a issue de Feature e a vincula ao Epic
# -----------------------------------------------------------------------------
cmd_ensure_feature() {
  [[ -z "$FEATURE_DIR" ]] && { echo -e "${RED}Erro: --feature-dir é obrigatório para ensure-feature${NC}" >&2; exit 1; }

  local slug marker_exact marker_prefix feature_title body existing_number feature_number feature_url
  slug=$(slug_from_feature_dir "$FEATURE_DIR")
  marker_prefix="speckit-feature-id"
  marker_exact="<!-- speckit-feature-id: ${slug} -->"
  feature_title="${TITLE:-$(spec_title_from_feature_dir "$FEATURE_DIR")}"

  echo -e "${BLUE}[ensure-feature]${NC} slug=$slug epic_issue=${EPIC_ISSUE:-<none>}"

  existing_number=$(find_issue_by_marker "$marker_prefix" "$marker_exact")

  if [[ -n "$existing_number" ]]; then
    feature_number="$existing_number"
    echo -e "${YELLOW}  ℹ Feature já existe (#$feature_number) — reaproveitando${NC}"
  else
    body=$(printf 'Feature gerada automaticamente por /speckit-taskstoissues a partir de `%s`.\n\n%s\n' \
      "$FEATURE_DIR" "$marker_exact")

    if [[ "$DRY_RUN" == true ]]; then
      echo -e "${YELLOW}  [dry-run] criaria issue de Feature: 'Feature: $feature_title'${NC}"
      feature_number="0"
    else
      feature_url=$(GH_HOST="$GH_HOST" gh issue create --repo "$REPO_SLUG" \
        --title "Feature: ${feature_title}" \
        --body "$body" \
        --label "type:feature" 2>&1) || {
          echo -e "${RED}  ✗ Falha ao criar issue de Feature: $feature_url${NC}" >&2
          exit 1
        }
      feature_number="${feature_url##*/}"
      echo -e "${GREEN}  ✓ Feature criada: $feature_url${NC}"
    fi
  fi

  apply_issue_type "$feature_number" "Feature"

  if [[ -n "$EPIC_ISSUE" ]]; then
    link_sub_issue "$EPIC_ISSUE" "$feature_number" || true
  else
    echo -e "${YELLOW}  ℹ Nenhum epic_issue definido em feature.json — Feature criada sem Epic pai${NC}"
  fi

  if [[ "$JSON_MODE" == true ]]; then
    jq -cn --arg n "$feature_number" '{feature_issue: ($n|tonumber)}'
  else
    echo "FEATURE_ISSUE=$feature_number"
  fi
}

# -----------------------------------------------------------------------------
# ensure-user-story: cria/reaproveita a issue de User Story e a vincula à Feature
# -----------------------------------------------------------------------------
cmd_ensure_user_story() {
  [[ -z "$FEATURE_DIR" ]] && { echo -e "${RED}Erro: --feature-dir é obrigatório para ensure-user-story${NC}" >&2; exit 1; }
  [[ -z "$US_ID" ]] && { echo -e "${RED}Erro: --us-id é obrigatório para ensure-user-story (ex.: US1)${NC}" >&2; exit 1; }
  [[ -z "$TITLE" ]] && { echo -e "${RED}Erro: --title é obrigatório para ensure-user-story${NC}" >&2; exit 1; }
  [[ -z "$PARENT_ISSUE" ]] && { echo -e "${RED}Erro: --parent-issue (issue de Feature) é obrigatório para ensure-user-story${NC}" >&2; exit 1; }

  local slug marker_prefix marker_exact body existing_number us_number us_url
  slug=$(slug_from_feature_dir "$FEATURE_DIR")
  marker_prefix="speckit-us-id"
  marker_exact="<!-- speckit-us-id: ${slug}#${US_ID} -->"

  echo -e "${BLUE}[ensure-user-story]${NC} slug=$slug us_id=$US_ID parent_feature=#$PARENT_ISSUE"

  existing_number=$(find_issue_by_marker "$marker_prefix" "$marker_exact")

  if [[ -n "$existing_number" ]]; then
    us_number="$existing_number"
    echo -e "${YELLOW}  ℹ User Story já existe (#$us_number) — reaproveitando${NC}"
  else
    body=$(printf 'User Story gerada automaticamente por /speckit-taskstoissues a partir da seção `%s` de `%s/spec.md`.\n\n%s\n' \
      "$US_ID" "$FEATURE_DIR" "$marker_exact")

    if [[ "$DRY_RUN" == true ]]; then
      echo -e "${YELLOW}  [dry-run] criaria issue de User Story: 'User Story: $TITLE'${NC}"
      us_number="0"
    else
      us_url=$(GH_HOST="$GH_HOST" gh issue create --repo "$REPO_SLUG" \
        --title "User Story: ${TITLE}" \
        --body "$body" \
        --label "type:user-story" 2>&1) || {
          echo -e "${RED}  ✗ Falha ao criar issue de User Story: $us_url${NC}" >&2
          exit 1
        }
      us_number="${us_url##*/}"
      echo -e "${GREEN}  ✓ User Story criada: $us_url${NC}"
    fi
  fi

  apply_issue_type "$us_number" "User Story"
  link_sub_issue "$PARENT_ISSUE" "$us_number" || true

  if [[ "$JSON_MODE" == true ]]; then
    jq -cn --arg n "$us_number" '{user_story_issue: ($n|tonumber)}'
  else
    echo "USER_STORY_ISSUE=$us_number"
  fi
}

# -----------------------------------------------------------------------------
# link-task: vincula uma Task issue já criada (pelo fluxo MCP existente) como
# sub-issue da User Story correspondente, e opcionalmente aplica o Issue Type.
# -----------------------------------------------------------------------------
cmd_link_task() {
  [[ -z "$PARENT_ISSUE" ]] && { echo -e "${RED}Erro: --parent-issue (issue de User Story) é obrigatório para link-task${NC}" >&2; exit 1; }
  [[ -z "$CHILD_ISSUE" ]] && { echo -e "${RED}Erro: --child-issue (issue de Task) é obrigatório para link-task${NC}" >&2; exit 1; }

  echo -e "${BLUE}[link-task]${NC} parent=#$PARENT_ISSUE child=#$CHILD_ISSUE"
  local rc=0
  link_sub_issue "$PARENT_ISSUE" "$CHILD_ISSUE" || rc=$?
  apply_issue_type "$CHILD_ISSUE" "Task"

  if [[ "$JSON_MODE" == true ]]; then
    jq -cn --arg p "$PARENT_ISSUE" --arg c "$CHILD_ISSUE" --arg rc "$rc" \
      '{parent_issue: ($p|tonumber), child_issue: ($c|tonumber), status: (if $rc == "0" then "linked" else "warning" end)}'
  fi
  return 0
}

cmd_set_type() {
  [[ -z "$ISSUE_NUMBER" ]] && { echo -e "${RED}Erro: --issue é obrigatório para set-type${NC}" >&2; exit 1; }
  [[ -z "$ISSUE_TYPE_NAME" ]] && { echo -e "${RED}Erro: --type é obrigatório para set-type${NC}" >&2; exit 1; }
  apply_issue_type "$ISSUE_NUMBER" "$ISSUE_TYPE_NAME"
}

cmd_check_issue_types() {
  detect_issue_types_support
  if [[ "$JSON_MODE" == true ]]; then
    jq -cn --arg m "$ISSUE_TYPES_MODE" '{mode: $m}'
  else
    echo "$ISSUE_TYPES_MODE"
  fi
  if [[ "$ISSUE_TYPES_MODE" == "labels" ]]; then
    echo -e "${YELLOW}[MODO DEGRADADO] Issue Types não disponíveis na org — usando labels type:epic/feature/user-story/task como fallback.${NC}" >&2
  fi
}

case "$COMMAND" in
  check-issue-types) cmd_check_issue_types ;;
  ensure-feature) cmd_ensure_feature ;;
  ensure-user-story) cmd_ensure_user_story ;;
  link-task) cmd_link_task ;;
  set-type) cmd_set_type ;;
  *)
    echo -e "${RED}Comando desconhecido: $COMMAND${NC}" >&2
    echo "Comandos válidos: check-issue-types | ensure-feature | ensure-user-story | link-task | set-type" >&2
    exit 1
    ;;
esac
