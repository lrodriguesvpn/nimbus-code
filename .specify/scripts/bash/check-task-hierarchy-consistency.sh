#!/usr/bin/env bash

###############################################################################
# check-task-hierarchy-consistency.sh
#
# Gate de validação pós-execução determinístico (specs/005-epic-feature-us-ghe-hierarchy,
# T018/FR-009): confirma, via GraphQL (`parent`/`subIssuesSummary`), que toda
# issue de User Story e Task processada na execução atual de
# /speckit-taskstoissues está de fato vinculada ao parent correto no GHE —
# em vez de depender apenas da prosa do Outline do SKILL.md sendo seguida
# corretamente pelo agente a cada execução (mesmo racional de
# check-epic-issue-consistency.sh: uma checagem em bash puro não pode ser
# "esquecida" no meio de um fluxo longo).
#
# Este script NÃO reimplementa a mutation `addSubIssue` — quando encontra uma
# inconsistência, ele delega a correção para
# create-github-issue-hierarchy.sh link-task (mesmo helper já usado pelo
# Outline principal), evitando duplicar a lógica de resolução de node id e de
# limite de 100 sub-issues.
#
# Uso:
#   check-task-hierarchy-consistency.sh --repo-owner <owner> --repo-name <repo> \
#     --links "<child>:<parent>[,<child>:<parent>...]" [--json] [--dry-run] [--no-self-heal]
#
# Onde --links é a lista, coletada pelo próprio Outline durante a execução
# atual, de pares `child_issue:parent_issue` para cada User Story (parent =
# Feature issue) e cada Task (parent = User Story issue, ou Feature issue
# quando a task não tem tag [USN]) processadas nesta chamada.
#
# Comportamento (idempotente — seguro de rodar sempre, mesmo com uma lista
# vazia):
#   - Sem pares em --links: no-op, sai com sucesso.
#   - Par já com o parent correto: reportado como `ok`.
#   - Par com parent ausente ou divergente: tenta autocorrigir chamando
#     link-task (a menos que --dry-run ou --no-self-heal), reconsulta e
#     reporta `fixed` (sucesso) ou `failed` (ainda inconsistente — por
#     exemplo, já tem outro parent, ou o parent atingiu o limite de
#     sub-issues). `failed` nunca é engolido silenciosamente: o script sai
#     com código 1 se qualquer par permanecer inconsistente ao final.
#
# Variáveis de ambiente suportadas:
#   - GH_HOST (default: venha-pra-nuvem.ghe.com, mesmo default do restante do
#     bundle — não sobrescrever a menos que o remote aponte para outro host)
#
###############################################################################

set -euo pipefail

SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.specify/scripts/bash/common.sh
source "$SCRIPT_DIR/common.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

GH_HOST="${GH_HOST:-venha-pra-nuvem.ghe.com}"
REPO_OWNER=""
REPO_NAME=""
LINKS=""
JSON_MODE=false
DRY_RUN=false
SELF_HEAL=true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-owner) REPO_OWNER="$2"; shift 2 ;;
    --repo-name) REPO_NAME="$2"; shift 2 ;;
    --links) LINKS="$2"; shift 2 ;;
    --json) JSON_MODE=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --no-self-heal) SELF_HEAL=false; shift ;;
    --help|-h)
      cat <<'EOF'
Usage: check-task-hierarchy-consistency.sh --repo-owner <owner> --repo-name <repo> \
  --links "<child>:<parent>[,<child>:<parent>...]" [--json] [--dry-run] [--no-self-heal]

Deterministic post-execution gate (specs/005-epic-feature-us-ghe-hierarchy, T018):
confirms via GraphQL that every User Story/Task issue in --links is actually a
sub-issue of its expected parent, self-healing via
create-github-issue-hierarchy.sh link-task when it is not (unless --dry-run or
--no-self-heal). Exits non-zero if any pair remains inconsistent.

Safe to run unconditionally and repeatedly: it is idempotent and a no-op when
--links is empty.
EOF
      exit 0
      ;;
    *)
      echo -e "${RED}Erro: opção desconhecida: $1${NC}" >&2
      exit 1
      ;;
  esac
done

[[ -z "$REPO_OWNER" ]] && { echo -e "${RED}Erro: --repo-owner é obrigatório${NC}" >&2; exit 1; }
[[ -z "$REPO_NAME" ]] && { echo -e "${RED}Erro: --repo-name é obrigatório${NC}" >&2; exit 1; }

if [[ -z "$LINKS" ]]; then
  echo -e "${GREEN}✓ Nenhum par child:parent para verificar nesta execução — nada a validar${NC}"
  [[ "$JSON_MODE" == true ]] && echo '{"status":"no-op","reason":"empty --links","results":[]}'
  exit 0
fi

HIERARCHY_SCRIPT="$SCRIPT_DIR/create-github-issue-hierarchy.sh"
if [[ ! -x "$HIERARCHY_SCRIPT" ]]; then
  echo -e "${RED}Erro: $HIERARCHY_SCRIPT não encontrado ou não executável — não é possível autocorrigir vínculos${NC}" >&2
  exit 1
fi

# Mesma query usada por get_issue_parent_number em create-github-issue-hierarchy.sh
# — duplicada propositalmente (mesmo racional de check-epic-issue-consistency.sh):
# este script deve funcionar sozinho, sem depender de funções internas de outro
# arquivo. Unificar via common.sh se algum dia divergirem.
get_actual_parent() {
  local child="$1" response
  response=$(GH_HOST="$GH_HOST" gh api graphql \
    -f owner="$REPO_OWNER" -f name="$REPO_NAME" -F number="$child" \
    -f query='
    query($owner: String!, $name: String!, $number: Int!) {
      repository(owner: $owner, name: $name) {
        issue(number: $number) {
          parent { number }
        }
      }
    }' 2>&1) || { echo -e "${YELLOW}  ⚠ Falha ao consultar parent de #$child — tratando como ausente: $response${NC}" >&2; echo ""; return 0; }
  echo "$response" | jq -r '.data.repository.issue.parent.number // empty' 2>/dev/null
}

TOTAL=0
OK_COUNT=0
FIXED_COUNT=0
FAILED_COUNT=0
JSON_RESULTS=()

IFS=',' read -ra PAIRS <<< "$LINKS"
for pair in "${PAIRS[@]}"; do
  pair="$(echo "$pair" | xargs)"
  [[ -z "$pair" ]] && continue
  child="${pair%%:*}"
  expected_parent="${pair##*:}"
  if [[ -z "$child" || -z "$expected_parent" || "$child" == "$pair" ]]; then
    echo -e "${RED}  ✗ Par malformado (esperado child:parent): '$pair' — pulando${NC}" >&2
    FAILED_COUNT=$((FAILED_COUNT + 1))
    JSON_RESULTS+=("{\"pair\":\"$(json_escape "$pair")\",\"status\":\"malformed\"}")
    continue
  fi
  TOTAL=$((TOTAL + 1))

  actual_parent=$(get_actual_parent "$child")
  if [[ "$actual_parent" == "$expected_parent" ]]; then
    echo -e "${GREEN}  ✓ #$child já é sub-issue de #$expected_parent${NC}"
    OK_COUNT=$((OK_COUNT + 1))
    JSON_RESULTS+=("{\"child\":$child,\"expected_parent\":$expected_parent,\"status\":\"ok\"}")
    continue
  fi

  echo -e "${YELLOW}  ⚠ #$child esperava parent #$expected_parent, GraphQL retornou '${actual_parent:-<ausente>}'${NC}"

  if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}    [dry-run] corrigiria vinculando #$child a #$expected_parent${NC}"
    FAILED_COUNT=$((FAILED_COUNT + 1))
    JSON_RESULTS+=("{\"child\":$child,\"expected_parent\":$expected_parent,\"actual_parent\":${actual_parent:-null},\"status\":\"would-fix\"}")
    continue
  fi

  if [[ "$SELF_HEAL" != true ]]; then
    echo -e "${RED}    ✗ --no-self-heal ativo — não corrigindo automaticamente${NC}" >&2
    FAILED_COUNT=$((FAILED_COUNT + 1))
    JSON_RESULTS+=("{\"child\":$child,\"expected_parent\":$expected_parent,\"actual_parent\":${actual_parent:-null},\"status\":\"failed\"}")
    continue
  fi

  echo -e "${BLUE}    -> autocorrigindo via link-task...${NC}"
  "$HIERARCHY_SCRIPT" link-task \
    --repo-owner "$REPO_OWNER" --repo-name "$REPO_NAME" \
    --parent-issue "$expected_parent" --child-issue "$child" --json >/dev/null 2>&1 || true

  reconfirmed_parent=$(get_actual_parent "$child")
  if [[ "$reconfirmed_parent" == "$expected_parent" ]]; then
    echo -e "${GREEN}    ✓ #$child corrigido — agora é sub-issue de #$expected_parent${NC}"
    FIXED_COUNT=$((FIXED_COUNT + 1))
    JSON_RESULTS+=("{\"child\":$child,\"expected_parent\":$expected_parent,\"actual_parent_before\":${actual_parent:-null},\"status\":\"fixed\"}")
  else
    echo -e "${RED}    ✗ #$child continua inconsistente após tentativa de correção (parent atual: '${reconfirmed_parent:-<ausente>}') — verifique manualmente${NC}" >&2
    FAILED_COUNT=$((FAILED_COUNT + 1))
    JSON_RESULTS+=("{\"child\":$child,\"expected_parent\":$expected_parent,\"actual_parent\":${reconfirmed_parent:-null},\"status\":\"failed\"}")
  fi
done

echo ""
echo -e "${BLUE}Resumo: $TOTAL par(es) verificado(s) — $OK_COUNT ok, $FIXED_COUNT corrigido(s), $FAILED_COUNT com falha${NC}"

if [[ "$JSON_MODE" == true ]]; then
  results_joined=$(IFS=,; echo "${JSON_RESULTS[*]}")
  overall_status="ok"
  [[ $FIXED_COUNT -gt 0 ]] && overall_status="fixed"
  [[ $FAILED_COUNT -gt 0 ]] && overall_status="failed"
  printf '{"status":"%s","total":%d,"ok":%d,"fixed":%d,"failed":%d,"results":[%s]}\n' \
    "$overall_status" "$TOTAL" "$OK_COUNT" "$FIXED_COUNT" "$FAILED_COUNT" "$results_joined"
fi

if [[ $FAILED_COUNT -gt 0 ]]; then
  exit 1
fi
exit 0
