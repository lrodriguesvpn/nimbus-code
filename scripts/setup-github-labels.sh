#!/bin/bash

###############################################################################
# setup-github-labels.sh
#
# Cria (ou atualiza) no repositório do projeto a taxonomia padrão de labels da
# Nimbus-Code usada para PRIORIZAÇÃO/ORDENAMENTO de issues e PRs, para sinalizar
# quais issues são candidatas a DESENVOLVIMENTO AUTÔNOMO por agente (ex.:
# GitHub Copilot coding agent) e para correlacionar issues com os DOMÍNIOS DE
# MÉTRICAS DORA (deployment frequency, lead time, change failure rate, MTTR).
#
# Uso:
#   ./setup-github-labels.sh [--repo-owner owner] [--repo-name name]
#
# Exemplos:
#   ./setup-github-labels.sh --repo-owner venha-pra-nuvem --repo-name meu-novo-projeto
#   ./setup-github-labels.sh  # usa vars de env: GITHUB_REPOSITORY
#
# Variáveis de ambiente suportadas:
#   - GITHUB_REPOSITORY (automaticamente preenchida em GitHub Actions: owner/repo)
#   - GH_HOST (padrão: venha-pra-nuvem.ghe.com)
#
# Idempotente: usa `gh label create --force`, que cria o label se não existir
# ou atualiza cor/descrição se já existir — seguro para rodar de novo a cada
# atualização do bundle.
#
# Ver taxonomia completa e regras de ordenamento/autonomia em:
#   docs/label-taxonomy-and-autonomous-dev.md
###############################################################################

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

GH_HOST="${GH_HOST:-venha-pra-nuvem.ghe.com}"

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
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      exit 1
      ;;
  esac
done

if [[ -z "$REPO_OWNER" || -z "$REPO_NAME" ]]; then
  if [[ -n "${GITHUB_REPOSITORY:-}" ]]; then
    REPO_OWNER="${GITHUB_REPOSITORY%/*}"
    REPO_NAME="${GITHUB_REPOSITORY#*/}"
  else
    echo -e "${RED}Erro: --repo-owner e --repo-name são obrigatórios ou configure GITHUB_REPOSITORY${NC}"
    exit 1
  fi
fi

REPO="${GH_HOST}/${REPO_OWNER}/${REPO_NAME}"

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}GitHub Labels Setup — Priorização e Desenvolvimento Autônomo${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "Repository: ${GREEN}${REPO_OWNER}/${REPO_NAME}${NC}"
echo -e "Host: ${GH_HOST}"
echo ""

if ! gh repo view "$REPO" --json nameWithOwner >/dev/null 2>&1; then
  echo -e "${RED}✗ Repositório não encontrado: ${REPO}${NC}"
  exit 1
fi

# Taxonomia: name|color|description
# Ordem de leitura para priorização: primeiro priority:*, depois complexity:*,
# depois type:* e agent:*/status:* como metadados de fluxo.
declare -a LABELS=(
  # Prioridade — chave primária de ORDENAMENTO do backlog (P0 > P1 > P2 > P3)
  "priority:P0-blocker|b60205|Bloqueador — trata antes de qualquer outro item, inclusive fora da ordem normal do sprint"
  "priority:P1-high|d93f0b|Alta prioridade — próximo item a puxar do backlog após todo P0"
  "priority:P2-medium|fbca04|Prioridade média — planejado, sem urgência imediata"
  "priority:P3-low|0e8a16|Baixa prioridade — nice-to-have, entra quando não há P0/P1/P2 pendente"

  # Complexidade S0–S4 — já usado como gate obrigatório para S4 na constituição
  # e no copilot-instructions.md do preset nimbus-code-standards.
  "complexity:S0|c2e0c6|Documentação/texto — sem lógica de negócio"
  "complexity:S1|bfd4f2|Função isolada, sem dependência externa"
  "complexity:S2|fef2c0|Módulo completo, com testes — sem cruzar serviços"
  "complexity:S3|f9d0c4|Múltiplos módulos/serviços — exige graph.yaml/graph.md atualizados"
  "complexity:S4|b60205|Arquitetura, segurança ou dados sensíveis — impact-map.md + revisão humana obrigatórios"

  # Tipo — classificação padrão de issue/PR
  "type:epic|6f42c1|Epic — iniciativa macro; pai de Features"
  "type:bug|d73a4a|Comportamento incorreto em relação ao especificado"
  "type:feature|0075ca|Feature — entrega de funcionalidade"
  "type:user-story|0e8a16|User Story — fatia de valor do usuário"
  "type:task|cfd3d7|Task — unidade de implementação; sub-issue de User Story"
  "type:chore|cfd3d7|Manutenção, refactor ou débito técnico sem mudança de comportamento visível"
  "type:docs|0075ca|Somente documentação (specs, ADRs, README, guias)"
  "type:incident|b60205|Ocorrência de produção/cliente (ex.: N1 do CRM) — SEMPRE exige revisão humana, mesmo complexidade S0"

  # Desenvolvimento autônomo — sinal de decisão + gatilho do workflow
  # .github/workflows/agent-auto-assign.yml (ver docs/label-taxonomy-and-autonomous-dev.md)
  "agent:autonomous-ok|0e8a16|Seguro p/ agente (ex.: Copilot coding agent) implementar sozinho — dispara auto-assign"
  "agent:needs-human|e99695|Exige humano no loop antes/durante a implementação — NUNCA deve ser auto-atribuído a um agente"

  # Status — controle de fluxo/ordenamento do backlog
  "status:needs-triage|ededed|Issue nova, ainda sem priority:*/complexity:* definidos — não deve ser puxada por agente autônomo"
  "status:blocked|5319e7|Bloqueada por dependência externa — pular na fila mesmo com priority:P0-blocker"

  # DORA — domínio de métrica DevOps (Four Keys) que esta issue impacta.
  # Usado para correlacionar issues fechadas com os indicadores DORA da equipe
  # (ver docs/label-taxonomy-and-autonomous-dev.md, seção 5).
  "dora:deployment-frequency|0052cc|Impacta a frequência de deploy (pipeline, automação de release, cadência de entrega)"
  "dora:lead-time|1d76db|Impacta o lead time for changes (tempo do commit até produção)"
  "dora:change-failure-rate|d93f0b|Impacta a taxa de falha de mudança (bug introduzido por deploy, hotfix corretivo, rollback)"
  "dora:mttr|b60205|Impacta o tempo de restauração de serviço (incidente, correção emergencial, recovery)"
)

echo -e "${BLUE}[1/1]${NC} Criando/atualizando ${#LABELS[@]} labels..."
echo ""

CREATED=0
UPDATED=0
FAILED=0

for entry in "${LABELS[@]}"; do
  IFS='|' read -r NAME COLOR DESCRIPTION <<< "$entry"

  # `gh label create --force` cria se não existir, ou atualiza cor/descrição
  # se o label já existir — idempotente.
  if OUTPUT=$(gh label create "$NAME" --repo "$REPO" --color "$COLOR" --description "$DESCRIPTION" --force 2>&1); then
    if echo "$OUTPUT" | grep -qi "updated"; then
      echo -e "${YELLOW}  ↻ Atualizado: ${NAME}${NC}"
      UPDATED=$((UPDATED + 1))
    else
      echo -e "${GREEN}  ✓ Criado: ${NAME}${NC}"
      CREATED=$((CREATED + 1))
    fi
  else
    echo -e "${RED}  ✗ Falhou: ${NAME} — ${OUTPUT}${NC}"
    FAILED=$((FAILED + 1))
  fi
done

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "Labels processados: ${#LABELS[@]} (criados: ${CREATED}, atualizados: ${UPDATED}, falhas: ${FAILED})"
echo ""
echo -e "Próximos passos:"
echo -e "  1. Aplique priority:*/complexity:*/type:* ao triar novas issues"
echo -e "  2. Use agent:autonomous-ok para liberar o auto-assign do Copilot coding agent"
echo -e "     (requer o workflow .github/workflows/agent-auto-assign.yml e o secret"
echo -e "     COPILOT_AGENT_ASSIGN_TOKEN — ver docs/label-taxonomy-and-autonomous-dev.md)"
echo -e "  3. Use as views \"Board por Epic\", \"Board por Feature\" e \"Board por User Story\""
echo -e "     com labels type:* para visualizar hierarquia EPIC/FEATURE/US"
echo -e "  4. Use a view \"Board por Prioridade\" agrupada por priority:* para visualizar"
echo -e "     o ordenamento do backlog"
echo -e "  5. Aplique dora:* nas issues que impactam métricas DORA (deploy frequency,"
echo -e "     lead time, change failure rate, MTTR) para poder correlacioná-las depois"
echo ""
echo -e "Documentação: ${BLUE}docs/label-taxonomy-and-autonomous-dev.md${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"

if [[ $FAILED -gt 0 ]]; then
  exit 1
fi
