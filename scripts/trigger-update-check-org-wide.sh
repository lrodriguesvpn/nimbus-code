#!/bin/bash

###############################################################################
# trigger-update-check-org-wide.sh
#
# Varre todos os repositórios de uma organização no GHE procurando por quais
# já têm o workflow update-speckit-and-bundle.yml instalado (só repos
# bootstrapados via bundle Nimbus-Code o têm) e dispara uma execução manual
# (workflow_dispatch) em cada um.
#
# IMPORTANTE — o que este script NÃO faz:
#   update-speckit-and-bundle.yml, por desenho, NUNCA aplica nenhuma mudança
#   de arquivo sozinho — ele apenas compara a versão instalada com a mais
#   recente publicada e abre/atualiza uma Issue com uma tabela comparativa e
#   os comandos manuais (`specify self upgrade`, `specify bundle update`)
#   que um humano precisa rodar. Rodar este script garante que toda Issue de
#   aviso esteja atualizada em todos os repositórios elegíveis — não atualiza
#   nenhum arquivo automaticamente em lugar nenhum.
#
# Uso:
#   ./trigger-update-check-org-wide.sh [--org <org>] [--dry-run]
#
# Requer: gh CLI autenticado com permissão de leitura de código (Code Search)
# e de execução de workflow (Actions: write) nos repositórios encontrados.
###############################################################################

set -euo pipefail

ORG="${ORG:-venha-pra-nuvem}"
WORKFLOW_FILE="update-speckit-and-bundle.yml"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --org)
      ORG="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --help|-h)
      cat <<'EOF'
Usage: trigger-update-check-org-wide.sh [--org <org>] [--dry-run]

Varre todos os repositórios da organização procurando por
.github/workflows/update-speckit-and-bundle.yml já instalado, e dispara uma
execução manual (workflow_dispatch) em cada um encontrado.

NÃO aplica nenhuma atualização de arquivo — o workflow disparado apenas abre/
atualiza uma Issue de diagnóstico em cada repositório, com instruções
manuais para o Dev responsável aplicar a atualização real depois.

--dry-run lista os repositórios encontrados sem disparar nada.
EOF
      exit 0
      ;;
    *)
      echo "Argumento desconhecido: $1" >&2
      exit 1
      ;;
  esac
done

if ! command -v gh >/dev/null 2>&1; then
  echo "❌ gh CLI não encontrado." >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "❌ jq não encontrado." >&2
  exit 1
fi

echo "→ Buscando repositórios de ${ORG} com ${WORKFLOW_FILE} instalado..."

REPOS_JSON="$(gh api -X GET search/code \
  -f q="org:${ORG} filename:${WORKFLOW_FILE} path:.github/workflows" \
  --jq '[.items[].repository.full_name] | unique' 2>&1)" || {
  echo "❌ Falha ao consultar GitHub Code Search." >&2
  echo "$REPOS_JSON" >&2
  exit 1
}

REPO_COUNT="$(echo "$REPOS_JSON" | jq 'length')"

if [[ "$REPO_COUNT" -eq 0 ]]; then
  echo "✅ Nenhum repositório com ${WORKFLOW_FILE} encontrado em ${ORG}."
  exit 0
fi

echo "→ ${REPO_COUNT} repositório(s) encontrado(s):"
echo "$REPOS_JSON" | jq -r '.[]' | sed 's/^/  - /'
echo ""

if $DRY_RUN; then
  echo "ℹ️  --dry-run: nada foi disparado. Rode sem --dry-run para executar de fato."
  exit 0
fi

SUCCESS=0
FAILED=0

while IFS= read -r repo; do
  [[ -z "$repo" ]] && continue
  if gh workflow run "$WORKFLOW_FILE" --repo "$repo" 2>/tmp/trigger-update-err.log; then
    echo "  ✅ Disparado: ${repo}"
    SUCCESS=$((SUCCESS + 1))
  else
    echo "  ❌ Falhou: ${repo} — $(cat /tmp/trigger-update-err.log)"
    FAILED=$((FAILED + 1))
  fi
done < <(echo "$REPOS_JSON" | jq -r '.[]')

rm -f /tmp/trigger-update-err.log

echo ""
echo "→ Resumo: ${SUCCESS} disparado(s) com sucesso, ${FAILED} falha(s)."
echo ""
echo "Cada repositório com disparo bem-sucedido terá a Issue \"Verificação"
echo "semanal — Nimbus Code / Bundle Nimbus-Code\" aberta ou atualizada em"
echo "alguns segundos/minutos (após a execução do workflow completar) — a"
echo "aplicação real da atualização continua manual, feita pelo Dev de cada"
echo "repositório a partir das instruções nessa Issue."

[[ "$FAILED" -eq 0 ]]
