#!/usr/bin/env bash

###############################################################################
# apply-governance-labels.sh
#
# Resolve o gap descrito em docs/developer-guide.md ("De onde vêm os labels
# nas issues"): labels de governança (priority:*, complexity:*, agent:*,
# type:*) só são aplicados automaticamente quando a issue é criada pelo
# /speckit-taskstoissues (via ensure_governance_labels() em
# create-github-issue-hierarchy.sh). Issues criadas manualmente — pelo
# usuário direto no GHE, por integrações externas, ou por qualquer fluxo que
# não passe pelo taskstoissues — nunca recebem esses labels sozinhas.
#
# Este script varre as issues abertas do repositório, identifica quais estão
# sem algum desses labels e aplica um default sensato só no(s) que estiver(em)
# ausente(s) — nunca sobrescreve um label já presente (ex.: se alguém já
# ajustou a prioridade manualmente, esse valor é preservado). Sem prompts por
# issue: o objetivo é rodar uma vez e corrigir tudo de uma vez (modo "smart
# bulk fix" — varre e corrige com defaults automáticos, sem pedir valor por
# issue).
#
# Regras de default (iguais às de ensure_governance_labels(), generalizadas
# para qualquer tipo de issue, não só Feature/User Story):
#   - priority:* ausente  -> priority:P2-medium (--default-priority)
#   - complexity:* ausente -> complexity:S2 (--default-complexity)
#   - agent:* ausente     -> derivado da complexity resultante (existente ou
#                            recém-aplicada): S4 -> agent:needs-human, senão
#                            agent:autonomous-ok (regra constitucional "S4
#                            nunca é autônomo" — nunca aplica autonomous-ok
#                            numa issue S4, mesmo que a complexity já
#                            existisse antes de rodar este script)
#   - type:* ausente      -> type:task (--default-type) — heurística
#                            conservadora; corrija manualmente se a issue for
#                            na verdade um Epic/Feature/Bug/Chore/Docs/Incident
#   - Exceção: issues com type:incident nunca recebem agent:autonomous-ok
#     (incidentes sempre exigem revisão humana, independente da complexity —
#     ver docs/label-taxonomy-and-autonomous-dev.md)
#
# Também remove status:needs-triage quando presente, já que esse label
# significa exatamente "sem priority:*/complexity:* ainda" — depois que este
# script preenche esses labels, o marcador deixa de ser verdade (desligável
# com --keep-needs-triage).
#
# Uso:
#   scripts/apply-governance-labels.sh [opções]
#
# Opções:
#   --repo-owner <owner>       Obrigatório (ou GITHUB_REPOSITORY=owner/repo)
#   --repo-name  <name>        Obrigatório (ou GITHUB_REPOSITORY=owner/repo)
#   --include-closed           Também varre issues fechadas (default: só abertas)
#   --only <N,N,...>           Restringe a uma lista de números de issue
#                              específicos, em vez de varrer o repositório
#                              inteiro (ex.: --only 42,57,101)
#   --default-priority <P0-blocker|P1-high|P2-medium|P3-low>  Default: P2-medium
#   --default-complexity <S0|S1|S2|S3|S4>                      Default: S2
#   --default-type <epic|feature|user-story|task|bug|chore|docs|incident>
#                              Default: task
#   --keep-needs-triage        Não remove status:needs-triage mesmo após
#                              preencher os labels ausentes
#   --dry-run                  Só mostra o que seria feito, sem chamar mutations
#   --json                     Emite um resumo em JSON ao final (uma linha)
#   -h, --help                 Mostra esta ajuda
#
# Variáveis de ambiente suportadas:
#   - GH_HOST (padrão: venha-pra-nuvem.ghe.com)
#   - GITHUB_REPOSITORY (owner/repo — usado se --repo-owner/--repo-name
#     não forem passados)
#
# Pré-requisito: os labels da taxonomia precisam existir no repositório antes
# de rodar este script (rode scripts/setup-github-labels.sh primeiro se ainda
# não rodou).
#
# Idempotente: reexecutar não duplica nem sobrescreve labels já corretos —
# issues que já têm os 4 prefixos ficam intocadas (contam como "já ok" no
# resumo final).
#
###############################################################################

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

GH_HOST="${GH_HOST:-venha-pra-nuvem.ghe.com}"

REPO_OWNER=""
REPO_NAME=""
INCLUDE_CLOSED=false
ONLY_ISSUES=""
DEFAULT_PRIORITY="P2-medium"
DEFAULT_COMPLEXITY="S2"
DEFAULT_TYPE="task"
KEEP_NEEDS_TRIAGE=false
DRY_RUN=false
JSON_MODE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-owner) REPO_OWNER="$2"; shift 2 ;;
    --repo-name) REPO_NAME="$2"; shift 2 ;;
    --include-closed) INCLUDE_CLOSED=true; shift ;;
    --only) ONLY_ISSUES="$2"; shift 2 ;;
    --default-priority) DEFAULT_PRIORITY="$2"; shift 2 ;;
    --default-complexity) DEFAULT_COMPLEXITY="$2"; shift 2 ;;
    --default-type) DEFAULT_TYPE="$2"; shift 2 ;;
    --keep-needs-triage) KEEP_NEEDS_TRIAGE=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --json) JSON_MODE=true; shift ;;
    -h|--help)
      sed -n '3,74p' "$0" | sed 's/^# \{0,1\}//'
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

REPO_SLUG="${REPO_OWNER}/${REPO_NAME}"

# -----------------------------------------------------------------------------
# Deriva o label agent:* a partir da complexity resultante, honrando a regra
# constitucional "S4 nunca é autônomo" e a exceção de type:incident (sempre
# precisa de revisão humana, qualquer que seja a complexity).
# Args: $1 = complexity (ex.: S2), $2 = type (ex.: task, incident, ou "")
# -----------------------------------------------------------------------------
resolve_agent_label() {
  local complexity="$1" issue_type="$2"
  if [[ "$complexity" == "S4" || "$issue_type" == "incident" ]]; then
    echo "needs-human"
  else
    echo "autonomous-ok"
  fi
}

fetch_issue_numbers() {
  if [[ -n "$ONLY_ISSUES" ]]; then
    echo "$ONLY_ISSUES" | tr ',' '\n' | sed '/^$/d'
    return 0
  fi

  local state="open"
  [[ "$INCLUDE_CLOSED" == true ]] && state="all"

  GH_HOST="$GH_HOST" gh issue list --repo "$REPO_SLUG" --state "$state" --limit 500 \
    --json number -q '.[].number'
}

TOTAL=0
FIXED=0
ALREADY_OK=0
FAILED=0
FIXED_ISSUES_JSON="[]"

process_issue() {
  local issue_number="$1"
  TOTAL=$((TOTAL + 1))

  local issue_json
  issue_json=$(GH_HOST="$GH_HOST" gh issue view "$issue_number" --repo "$REPO_SLUG" --json labels 2>/dev/null) || {
    echo -e "${RED}  ✗ #$issue_number — falha ao ler a issue (ignorada)${NC}" >&2
    FAILED=$((FAILED + 1))
    return 0
  }

  local current_labels
  current_labels=$(echo "$issue_json" | jq -c '[.labels[].name]')

  local has_priority has_complexity has_agent has_type has_needs_triage
  has_priority=$(echo "$current_labels" | jq -e 'any(.[]; startswith("priority:"))' >/dev/null 2>&1 && echo true || echo false)
  has_complexity=$(echo "$current_labels" | jq -e 'any(.[]; startswith("complexity:"))' >/dev/null 2>&1 && echo true || echo false)
  has_agent=$(echo "$current_labels" | jq -e 'any(.[]; startswith("agent:"))' >/dev/null 2>&1 && echo true || echo false)
  has_type=$(echo "$current_labels" | jq -e 'any(.[]; startswith("type:"))' >/dev/null 2>&1 && echo true || echo false)
  has_needs_triage=$(echo "$current_labels" | jq -e 'any(.[]; . == "status:needs-triage")' >/dev/null 2>&1 && echo true || echo false)

  if [[ "$has_priority" == true && "$has_complexity" == true && "$has_agent" == true && "$has_type" == true ]]; then
    echo -e "${BLUE}  = #$issue_number já tem todos os labels de governança — sem mudanças${NC}"
    ALREADY_OK=$((ALREADY_OK + 1))
    return 0
  fi

  # Complexity/type efetivos (existentes ou os que serão aplicados agora) —
  # usados só para resolver o default de agent:* corretamente.
  local effective_complexity="$DEFAULT_COMPLEXITY"
  if [[ "$has_complexity" == true ]]; then
    effective_complexity=$(echo "$current_labels" | jq -r '.[] | select(startswith("complexity:")) | ltrimstr("complexity:")' | head -1)
  fi
  local effective_type="$DEFAULT_TYPE"
  if [[ "$has_type" == true ]]; then
    effective_type=$(echo "$current_labels" | jq -r '.[] | select(startswith("type:")) | ltrimstr("type:")' | head -1)
  fi

  local to_add=()
  [[ "$has_priority" == false ]] && to_add+=("priority:$DEFAULT_PRIORITY")
  [[ "$has_complexity" == false ]] && to_add+=("complexity:$DEFAULT_COMPLEXITY")
  [[ "$has_type" == false ]] && to_add+=("type:$DEFAULT_TYPE")
  if [[ "$has_agent" == false ]]; then
    local agent_label
    agent_label=$(resolve_agent_label "$effective_complexity" "$effective_type")
    to_add+=("agent:$agent_label")
  fi

  local to_remove=()
  if [[ "$KEEP_NEEDS_TRIAGE" == false && "$has_needs_triage" == true ]]; then
    to_remove+=("status:needs-triage")
  fi

  if [[ ${#to_add[@]} -eq 0 && ${#to_remove[@]} -eq 0 ]]; then
    echo -e "${BLUE}  = #$issue_number já tem todos os labels de governança — sem mudanças${NC}"
    ALREADY_OK=$((ALREADY_OK + 1))
    return 0
  fi

  local add_joined="" remove_joined=""
  [[ ${#to_add[@]} -gt 0 ]] && add_joined=$(IFS=,; echo "${to_add[*]}")
  [[ ${#to_remove[@]} -gt 0 ]] && remove_joined=$(IFS=,; echo "${to_remove[*]}")

  if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}  [dry-run] #$issue_number — adicionaria: [${add_joined:-nenhum}] removeria: [${remove_joined:-nenhum}]${NC}"
    FIXED=$((FIXED + 1))
    return 0
  fi

  local edit_args=(--repo "$REPO_SLUG")
  [[ -n "$add_joined" ]] && edit_args+=(--add-label "$add_joined")
  [[ -n "$remove_joined" ]] && edit_args+=(--remove-label "$remove_joined")

  if GH_HOST="$GH_HOST" gh issue edit "$issue_number" "${edit_args[@]}" >/dev/null 2>&1; then
    echo -e "${GREEN}  ✓ #$issue_number — adicionado: [${add_joined:-nenhum}] removido: [${remove_joined:-nenhum}]${NC}"
    FIXED=$((FIXED + 1))
    FIXED_ISSUES_JSON=$(echo "$FIXED_ISSUES_JSON" | jq -c --arg n "$issue_number" --arg add "$add_joined" --arg rm "$remove_joined" \
      '. + [{issue: ($n | tonumber), added: ($add | split(",") | map(select(length > 0))), removed: ($rm | split(",") | map(select(length > 0)))}]')
  else
    echo -e "${RED}  ✗ #$issue_number — falha ao aplicar labels (o label existe no repo? rode scripts/setup-github-labels.sh)${NC}" >&2
    FAILED=$((FAILED + 1))
  fi
}

echo -e "${BLUE}Varrendo issues de $REPO_SLUG (GH_HOST=$GH_HOST)...${NC}"
[[ "$DRY_RUN" == true ]] && echo -e "${YELLOW}Modo --dry-run: nenhuma alteração será aplicada.${NC}"

while IFS= read -r issue_number; do
  [[ -z "$issue_number" ]] && continue
  process_issue "$issue_number"
done < <(fetch_issue_numbers)

echo ""
echo -e "${BLUE}Resumo:${NC} $TOTAL issue(s) verificada(s), $FIXED corrigida(s)/pendente(s) de correção, $ALREADY_OK já ok, $FAILED falha(s)."

if [[ "$JSON_MODE" == true ]]; then
  jq -nc --arg repo "$REPO_SLUG" --argjson total "$TOTAL" --argjson fixed "$FIXED" \
    --argjson already_ok "$ALREADY_OK" --argjson failed "$FAILED" --argjson dry_run "$DRY_RUN" \
    --argjson issues "$FIXED_ISSUES_JSON" \
    '{repo: $repo, dry_run: $dry_run, total: $total, fixed: $fixed, already_ok: $already_ok, failed: $failed, issues: $issues}'
fi

[[ "$FAILED" -gt 0 ]] && exit 1
exit 0
