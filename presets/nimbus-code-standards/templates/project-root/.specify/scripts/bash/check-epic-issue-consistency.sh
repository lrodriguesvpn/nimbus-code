#!/usr/bin/env bash

###############################################################################
# check-epic-issue-consistency.sh
#
# Camada 2 da correção de confiabilidade descrita em
# specs/005-epic-feature-us-ghe-hierarchy: uma checagem determinística (bash
# puro, sem depender de um LLM "lembrar" de seguir uma instrução no meio de um
# fluxo longo) que garante que o campo `epic_issue` de `.specify/feature.json`
# está consistente com um token `EPIC_ISSUE=<N>` presente na descrição bruta
# originalmente passada ao `/speckit-specify` — e se autocorrige quando não
# está, em vez de apenas reportar o problema.
#
# Motivação: o SKILL.md de /speckit-specify instrui o agente a extrair e
# persistir EPIC_ISSUE=<N> no meio de um passo a passo de várias etapas. Isso
# é prosa interpretada por um LLM a cada execução — pode ser esquecido sem que
# ninguém perceba. Este script é a "rede de segurança" final: é chamado
# incondicionalmente (não "se você lembrar") como último passo do Outline do
# SKILL.md (ver .github/skills/speckit-specify/SKILL.md, seção Post-Execution
# Validation) e corrige o campo sozinho se estiver ausente ou divergente.
#
# Uso:
#   check-epic-issue-consistency.sh --description "<texto bruto original>" \
#     [--repo-root <path>] [--json] [--dry-run]
#
# Comportamento (idempotente — seguro de rodar sempre, mesmo sem nenhum
# EPIC_ISSUE envolvido):
#   - Sem token EPIC_ISSUE=<N> na descrição: no-op, sai com sucesso.
#   - Com token e feature.json já com o mesmo epic_issue: no-op, sai com sucesso.
#   - Com token e feature.json ausente/divergente: corrige feature.json
#     (merge via jq, ou fallback manual sem jq) e reporta a correção.
#
# Variáveis de ambiente suportadas:
#   - SPECIFY_INIT_DIR (ver common.sh — override explícito da raiz do projeto)
#
###############################################################################

set -euo pipefail

SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.specify/scripts/bash/common.sh
source "$SCRIPT_DIR/common.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

DESCRIPTION=""
REPO_ROOT_OVERRIDE=""
JSON_MODE=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --description)
      DESCRIPTION="$2"
      shift 2
      ;;
    --repo-root)
      REPO_ROOT_OVERRIDE="$2"
      shift 2
      ;;
    --json)
      JSON_MODE=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --help|-h)
      cat <<'EOF'
Usage: check-epic-issue-consistency.sh --description "<raw feature description>" [--repo-root <path>] [--json] [--dry-run]

Deterministic self-healing check (specs/005-epic-feature-us-ghe-hierarchy):
scans the raw feature description for an EPIC_ISSUE=<N> token and makes sure
.specify/feature.json's epic_issue field matches it, fixing it automatically
if a prior step in /speckit-specify forgot to persist it.

Safe to run unconditionally and repeatedly: it is idempotent and a no-op when
already consistent or when no EPIC_ISSUE token is present.
EOF
      exit 0
      ;;
    *)
      echo -e "${RED}Erro: opção desconhecida: $1${NC}" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$DESCRIPTION" ]]; then
  echo -e "${RED}Erro: --description é obrigatório (texto original passado ao /speckit-specify, antes de qualquer strip)${NC}" >&2
  exit 1
fi

REPO_ROOT="${REPO_ROOT_OVERRIDE:-$(get_repo_root)}"
FEATURE_JSON="$REPO_ROOT/.specify/feature.json"

# Mesma extração usada em create-new-feature.sh (Camada 1) — mantida em
# duplicidade proposital: este script deve funcionar sozinho, sem depender de
# ninguém já ter rodado o outro. Se algum dia divergirem, unificar via um
# helper compartilhado em common.sh.
INLINE_EPIC_ISSUE=$(printf '%s' "$DESCRIPTION" | grep -ioE 'EPIC_ISSUE[[:space:]]*=[[:space:]]*[0-9]+' | head -1 | grep -oE '[0-9]+$' || true)

if [[ -z "$INLINE_EPIC_ISSUE" ]]; then
  echo -e "${GREEN}✓ Nenhum token EPIC_ISSUE=<N> na descrição — nada a verificar${NC}"
  [[ "$JSON_MODE" == true ]] && echo '{"status":"no-op","reason":"no EPIC_ISSUE token in description"}'
  exit 0
fi

if [[ ! -f "$FEATURE_JSON" ]]; then
  echo -e "${RED}✗ $FEATURE_JSON não existe — rode este script depois que /speckit-specify já tiver criado feature.json${NC}" >&2
  exit 1
fi

CURRENT_EPIC_ISSUE=""
if command -v jq >/dev/null 2>&1; then
  CURRENT_EPIC_ISSUE=$(jq -r '.epic_issue // empty' "$FEATURE_JSON" 2>/dev/null || echo "")
else
  CURRENT_EPIC_ISSUE=$(grep -oE '"epic_issue"[[:space:]]*:[[:space:]]*[0-9]+' "$FEATURE_JSON" 2>/dev/null | grep -oE '[0-9]+$' | head -1 || echo "")
fi

if [[ "$CURRENT_EPIC_ISSUE" == "$INLINE_EPIC_ISSUE" ]]; then
  echo -e "${GREEN}✓ epic_issue já consistente (#$INLINE_EPIC_ISSUE) em $FEATURE_JSON${NC}"
  if [[ "$JSON_MODE" == true ]]; then
    if command -v jq >/dev/null 2>&1; then
      jq -cn --arg n "$INLINE_EPIC_ISSUE" '{status:"ok", epic_issue: ($n|tonumber)}'
    else
      printf '{"status":"ok","epic_issue":%s}\n' "$INLINE_EPIC_ISSUE"
    fi
  fi
  exit 0
fi

echo -e "${YELLOW}⚠ epic_issue inconsistente: descrição menciona EPIC_ISSUE=$INLINE_EPIC_ISSUE mas feature.json tem '${CURRENT_EPIC_ISSUE:-<ausente>}' — autocorrigindo...${NC}"

if [[ "$DRY_RUN" == true ]]; then
  echo -e "${YELLOW}  [dry-run] corrigiria $FEATURE_JSON para epic_issue=$INLINE_EPIC_ISSUE${NC}"
  if [[ "$JSON_MODE" == true ]]; then
    if command -v jq >/dev/null 2>&1; then
      jq -cn --arg n "$INLINE_EPIC_ISSUE" '{status:"would-fix", epic_issue: ($n|tonumber)}'
    else
      printf '{"status":"would-fix","epic_issue":%s}\n' "$INLINE_EPIC_ISSUE"
    fi
  fi
  exit 0
fi

if command -v jq >/dev/null 2>&1; then
  TMP=$(jq --arg n "$INLINE_EPIC_ISSUE" '. + {epic_issue: ($n | tonumber)}' "$FEATURE_JSON")
  printf '%s\n' "$TMP" > "$FEATURE_JSON"
else
  # Fallback sem jq: remove qualquer "epic_issue" existente (com ou sem vírgula
  # precedente) e reinsere o valor correto antes da chave de fechamento.
  EXISTING=$(cat "$FEATURE_JSON")
  EXISTING=$(printf '%s' "$EXISTING" | sed -E 's/,[[:space:]]*"epic_issue"[[:space:]]*:[[:space:]]*[0-9]+//g; s/"epic_issue"[[:space:]]*:[[:space:]]*[0-9]+,?//g')
  EXISTING="${EXISTING%\}}"
  EXISTING="${EXISTING%,}"
  printf '%s,"epic_issue":%s}\n' "$EXISTING" "$INLINE_EPIC_ISSUE" > "$FEATURE_JSON"
fi

echo -e "${GREEN}✓ epic_issue corrigido para #$INLINE_EPIC_ISSUE em $FEATURE_JSON${NC}"
if [[ "$JSON_MODE" == true ]]; then
  if command -v jq >/dev/null 2>&1; then
    jq -cn --arg n "$INLINE_EPIC_ISSUE" '{status:"fixed", epic_issue: ($n|tonumber)}'
  else
    printf '{"status":"fixed","epic_issue":%s}\n' "$INLINE_EPIC_ISSUE"
  fi
fi
