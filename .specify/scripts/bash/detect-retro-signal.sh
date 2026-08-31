#!/usr/bin/env bash

###############################################################################
# detect-retro-signal.sh
#
# Detecção determinística de retrabalho causado por problemas em spec.md/
# plan.md — "o dev refez várias vezes várias tarefas e criou tarefas novas
# porque a spec e o plan tinham problemas". Reaproveita o mesmo padrão já
# estabelecido em docs/reuse-catalog.yaml, tag
# "skill-mid-flow-instruction-reliability-gate": em vez de depender de um
# agente LEMBRAR de preencher specs/<feature>/retro.md, este script usa o
# histórico git real da feature como evidência objetiva.
#
# Sinais:
#   1. spec.md ou plan.md foram modificados em algum commit POSTERIOR ao
#      commit que criou tasks.md — evidência concreta de que a spec/plano
#      precisou ser revisado no meio da implementação.
#   2. Novos IDs de task (TNNN) apareceram em tasks.md depois da primeira
#      geração — evidência de "criou tarefas novas".
#
# Qualquer um dos dois sinais, mesmo uma única ocorrência, já marca
# "signal_detected" (sensibilidade máxima, por decisão explícita do Dev —
# prioriza garantir captura sobre evitar falso-positivo).
#
# Uso:
#   detect-retro-signal.sh --feature-dir <path/specs/NNN-slug> [--json]
#
# Status possíveis:
#   not_applicable — tasks.md não existe ainda, ou não tem histórico git
#                    (specs ainda não commitadas) — nada a checar agora.
#   clean          — tasks.md existe, nenhuma revisão de spec/plan depois
#                    dele, nenhuma task nova.
#   signal_detected — pelo menos 1 revisão de spec/plan após tasks.md
#                    existir, OU pelo menos 1 task nova.
#
# Requer: git (repositório real, não worktree órfão)
###############################################################################

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

FEATURE_DIR=""
JSON_MODE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --feature-dir)
      FEATURE_DIR="$2"
      shift 2
      ;;
    --json)
      JSON_MODE=true
      shift
      ;;
    --help|-h)
      cat <<'EOF'
Usage: detect-retro-signal.sh --feature-dir <path/specs/NNN-slug> [--json]

Detecção determinística de sinais de retrabalho (spec/plan revisados depois
de tasks.md já existir, ou tasks novas adicionadas depois da primeira
geração) — usada por /speckit-implement para garantir que specs/<feature>/
retro.md seja criado e preenchido quando há evidência real de que a spec/
plano tiveram problemas, em vez de depender de um agente lembrar disso no
meio de um fluxo longo.

Seguro de rodar sempre, incondicionalmente: se tasks.md ainda não existe ou
não tem histórico git, retorna status "not_applicable" sem erro.
EOF
      exit 0
      ;;
    *)
      echo -e "${RED}Erro: opção desconhecida: $1${NC}" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$FEATURE_DIR" ]]; then
  echo -e "${RED}Erro: --feature-dir é obrigatório (ex.: specs/023-minha-feature)${NC}" >&2
  exit 1
fi

# Remove barra final para normalizar comparações de path abaixo.
FEATURE_DIR="${FEATURE_DIR%/}"

TASKS_FILE="$FEATURE_DIR/tasks.md"
SPEC_FILE="$FEATURE_DIR/spec.md"
PLAN_FILE="$FEATURE_DIR/plan.md"

emit_not_applicable() {
  local reason="$1"
  if $JSON_MODE; then
    printf '{"status":"not_applicable","reason":"%s"}\n' "$reason"
  else
    echo -e "${YELLOW}ℹ️  Não aplicável: ${reason}${NC}"
  fi
  exit 0
}

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  emit_not_applicable "não é um repositório git — nada a checar"
fi

if [[ ! -f "$TASKS_FILE" ]]; then
  emit_not_applicable "tasks.md não existe ainda em $FEATURE_DIR"
fi

# Primeiro commit que introduziu tasks.md (o mais antigo entre os que o
# adicionaram — --diff-filter=A restringe a commits que ADICIONARAM o
# arquivo, não qualquer modificação; tail -1 pega o mais antigo, já que
# git log lista do mais novo para o mais antigo por padrão).
TASKS_FIRST_COMMIT="$(git log --follow --diff-filter=A --format='%H' -- "$TASKS_FILE" 2>/dev/null | tail -1 || true)"

if [[ -z "$TASKS_FIRST_COMMIT" ]]; then
  emit_not_applicable "tasks.md existe mas ainda não foi commitado — nada a checar até o primeiro commit"
fi

# Commits que tocaram spec.md/plan.md estritamente DEPOIS do commit que
# introduziu tasks.md (range <commit>..HEAD é o mecanismo nativo do git para
# "o que mudou desde este ponto", robusto mesmo com merges).
count_revisions_after() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo 0
    return
  fi
  git log --format='%H' "${TASKS_FIRST_COMMIT}..HEAD" -- "$file" 2>/dev/null | wc -l | tr -d ' '
}

list_revisions_after() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    return
  fi
  git log --format='%H|%cI|%s' "${TASKS_FIRST_COMMIT}..HEAD" -- "$file" 2>/dev/null
}

SPEC_REVISIONS_AFTER="$(count_revisions_after "$SPEC_FILE")"
PLAN_REVISIONS_AFTER="$(count_revisions_after "$PLAN_FILE")"

# Contagem de IDs de task (TNNN) na versão de tasks.md do commit que a criou,
# comparada com o conteúdo atual em disco (não git show HEAD — propositalmente
# lê o working tree, para capturar também tasks adicionadas ainda não
# commitadas nesta mesma sessão de implementação).
FEATURE_DIR_REL="$FEATURE_DIR"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -n "$REPO_ROOT" && "$FEATURE_DIR" = /* ]]; then
  FEATURE_DIR_REL="${FEATURE_DIR#"$REPO_ROOT"/}"
fi
TASKS_FILE_REL="$FEATURE_DIR_REL/tasks.md"

FIRST_TASK_IDS="$(git show "${TASKS_FIRST_COMMIT}:${TASKS_FILE_REL}" 2>/dev/null | grep -oE '\bT[0-9]{3}\b' | sort -u || true)"
CURRENT_TASK_IDS="$(grep -oE '\bT[0-9]{3}\b' "$TASKS_FILE" 2>/dev/null | sort -u || true)"

NEW_TASK_IDS="$(comm -13 <(printf '%s\n' "$FIRST_TASK_IDS") <(printf '%s\n' "$CURRENT_TASK_IDS") 2>/dev/null || true)"
NEW_TASKS_COUNT="$(printf '%s\n' "$NEW_TASK_IDS" | grep -c . || true)"

STATUS="clean"
if [[ "$SPEC_REVISIONS_AFTER" -gt 0 || "$PLAN_REVISIONS_AFTER" -gt 0 || "$NEW_TASKS_COUNT" -gt 0 ]]; then
  STATUS="signal_detected"
fi

TASKS_FIRST_DATE="$(git show -s --format=%cI "$TASKS_FIRST_COMMIT" 2>/dev/null || echo "")"

if $JSON_MODE; then
  EVIDENCE_JSON="["
  FIRST=true
  while IFS='|' read -r sha date subject; do
    [[ -z "$sha" ]] && continue
    $FIRST || EVIDENCE_JSON+=","
    FIRST=false
    subject_escaped=$(printf '%s' "$subject" | sed 's/\\/\\\\/g; s/"/\\"/g')
    EVIDENCE_JSON+="{\"file\":\"spec.md\",\"commit\":\"$sha\",\"date\":\"$date\",\"subject\":\"$subject_escaped\"}"
  done < <(list_revisions_after "$SPEC_FILE")
  while IFS='|' read -r sha date subject; do
    [[ -z "$sha" ]] && continue
    $FIRST || EVIDENCE_JSON+=","
    FIRST=false
    subject_escaped=$(printf '%s' "$subject" | sed 's/\\/\\\\/g; s/"/\\"/g')
    EVIDENCE_JSON+="{\"file\":\"plan.md\",\"commit\":\"$sha\",\"date\":\"$date\",\"subject\":\"$subject_escaped\"}"
  done < <(list_revisions_after "$PLAN_FILE")
  EVIDENCE_JSON+="]"

  NEW_TASKS_JSON="[$(printf '%s\n' "$NEW_TASK_IDS" | grep . | sed 's/^/"/;s/$/"/' | paste -sd, - 2>/dev/null || echo "")]"

  printf '{"status":"%s","tasks_first_commit":"%s","tasks_first_commit_date":"%s","spec_revisions_after_tasks":%s,"plan_revisions_after_tasks":%s,"new_tasks_count":%s,"new_task_ids":%s,"evidence":%s}\n' \
    "$STATUS" "$TASKS_FIRST_COMMIT" "$TASKS_FIRST_DATE" \
    "$SPEC_REVISIONS_AFTER" "$PLAN_REVISIONS_AFTER" "$NEW_TASKS_COUNT" "$NEW_TASKS_JSON" "$EVIDENCE_JSON"
else
  echo "Feature dir: $FEATURE_DIR"
  echo "tasks.md criado em: $TASKS_FIRST_COMMIT ($TASKS_FIRST_DATE)"
  echo "Revisões de spec.md depois: $SPEC_REVISIONS_AFTER"
  echo "Revisões de plan.md depois: $PLAN_REVISIONS_AFTER"
  echo "Tasks novas adicionadas: $NEW_TASKS_COUNT"
  if [[ "$STATUS" == "signal_detected" ]]; then
    echo -e "${YELLOW}⚠ Sinal de retrabalho detectado — retro.md deve ser criado/preenchido.${NC}"
  else
    echo -e "${GREEN}✓ Nenhum sinal de retrabalho detectado.${NC}"
  fi
fi

exit 0
