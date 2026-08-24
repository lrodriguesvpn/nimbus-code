#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# generate-context-graph.sh
#
# Lê docs/bounded-contexts.yaml, analisa os manifestos de dependência dos
# repos de um bounded context (localmente, quando disponíveis como siblings
# no disco, ou via `gh api` como fallback) e gera graph.yaml + graph.md
# refletindo os repos do contexto como nós e as dependências detectadas entre
# eles como arestas.
#
# Feature: specs/014-brownfield-multirepo-context-awareness/
# ADL-001: nós de repos externos ao repo atual recebem `cross_repo: true`.
# ADL-002: script vive em scripts/ (não em .specify/scripts/bash/).
#
# Uso:
#   scripts/generate-context-graph.sh <context-slug> [--feature <slug>] [--out-dir <dir>]
#
# Exit codes:
#   0 — grafo gerado com sucesso, OU contexto sem repos mapeados (aviso, não bloqueia)
#   1 — erro real (docs/bounded-contexts.yaml ausente/inválido, contexto inexistente)
#
# Variáveis de ambiente:
#   BOUNDED_CONTEXTS_FILE  (default: docs/bounded-contexts.yaml)
#   GH_HOST                (default: venha-pra-nuvem.ghe.com)
###############################################################################

SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
BOUNDED_CONTEXTS_FILE="${BOUNDED_CONTEXTS_FILE:-docs/bounded-contexts.yaml}"
GH_HOST="${GH_HOST:-venha-pra-nuvem.ghe.com}"
export GH_HOST

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

usage() {
  cat <<EOF
Uso: ${SCRIPT_NAME} <context-slug> [--feature <slug>] [--out-dir <dir>]

Gera graph.yaml + graph.md para o bounded context informado, a partir dos
repos declarados em \${BOUNDED_CONTEXTS_FILE} (default: docs/bounded-contexts.yaml).

Argumentos:
  <context-slug>       Obrigatório. Slug do bounded context (campo 'slug' em
                        docs/bounded-contexts.yaml).
  --feature <slug>      Opcional. Escreve em specs/<slug>/graph.yaml e
                        specs/<slug>/graph.md em vez de --out-dir.
  --out-dir <dir>       Opcional. Diretório de saída (default: diretório atual).
  --help                Mostra esta mensagem.

Exit codes:
  0  Grafo gerado, OU contexto sem repos mapeados (aviso — não bloqueia o fluxo de spec)
  1  Erro real (arquivo ausente/inválido, contexto não encontrado)
EOF
}

CONTEXT_SLUG=""
FEATURE_SLUG=""
OUT_DIR="."

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    --feature)
      FEATURE_SLUG="$2"
      shift 2
      ;;
    --out-dir)
      OUT_DIR="$2"
      shift 2
      ;;
    *)
      if [[ -z "$CONTEXT_SLUG" ]]; then
        CONTEXT_SLUG="$1"
        shift
      else
        echo "Erro: argumento inesperado '$1'" >&2
        usage >&2
        exit 1
      fi
      ;;
  esac
done

if [[ -z "$CONTEXT_SLUG" ]]; then
  echo "Erro: <context-slug> é obrigatório." >&2
  usage >&2
  exit 1
fi

if [[ -n "$FEATURE_SLUG" ]]; then
  OUT_DIR="specs/${FEATURE_SLUG}"
fi

if [[ ! -f "$BOUNDED_CONTEXTS_FILE" ]]; then
  echo -e "${RED}Erro: ${BOUNDED_CONTEXTS_FILE} não encontrado.${NC}" >&2
  exit 1
fi

# ── Parsing de bounded-contexts.yaml (yq com fallback python3) ─────────────
have_yq() { command -v yq >/dev/null 2>&1; }

# Emite um bloco de linhas "slug|description|repository|stack" (um por
# contexto) para permitir o resto do script trabalhar sem depender de
# jq/yq no caminho crítico de leitura repetida.
list_contexts() {
  if have_yq; then
    yq -o=json '.contexts' "$BOUNDED_CONTEXTS_FILE" 2>/dev/null
  else
    python3 -c "
import yaml, json, sys
d = yaml.safe_load(open('${BOUNDED_CONTEXTS_FILE}'))
print(json.dumps(d.get('contexts', []) or []))
"
  fi
}

CONTEXTS_JSON_FILE="$(mktemp)"
trap 'rm -f "$CONTEXTS_JSON_FILE"' EXIT

list_contexts > "$CONTEXTS_JSON_FILE" || {
  echo -e "${RED}Erro: falha ao parsear ${BOUNDED_CONTEXTS_FILE} (YAML inválido?).${NC}" >&2
  exit 1
}

# Repos do contexto pedido, um por linha "repository<TAB>stack"
# Lê o JSON de um arquivo (em vez de interpolar como string literal em
# python3 -c) para evitar que sequências de escape do JSON (\n, \uXXXX) sejam
# reinterpretadas pelo parser de string do próprio Python antes do json.loads.
REPOS_TSV="$(CONTEXTS_JSON_FILE="$CONTEXTS_JSON_FILE" CONTEXT_SLUG="$CONTEXT_SLUG" python3 -c "
import json, os
with open(os.environ['CONTEXTS_JSON_FILE'], encoding='utf-8') as f:
    contexts = json.load(f)
match = [c for c in contexts if c.get('slug') == os.environ['CONTEXT_SLUG']]
if not match:
    raise SystemExit(10)
repos = match[0].get('repos') or ([match[0]['repository']] if match[0].get('repository') else [])
for r in repos:
    stack = match[0].get('stack', '')
    print(f'{r}\t{stack}')
" 2>/dev/null)" || {
  rc=$?
  if [[ $rc -eq 10 ]]; then
    echo -e "${RED}Erro: bounded context '${CONTEXT_SLUG}' não encontrado em ${BOUNDED_CONTEXTS_FILE}.${NC}" >&2
    exit 1
  fi
  echo -e "${RED}Erro inesperado ao resolver repos do contexto '${CONTEXT_SLUG}'.${NC}" >&2
  exit 1
}

if [[ -z "$REPOS_TSV" ]]; then
  echo -e "${YELLOW}⚠ Bounded context '${CONTEXT_SLUG}' não tem nenhum repositório mapeado em ${BOUNDED_CONTEXTS_FILE}.${NC}" >&2
  echo -e "${YELLOW}  O fluxo de spec pode prosseguir sem o grafo — mapeie o contexto depois, se necessário.${NC}" >&2
  exit 0
fi

echo "==> Gerando grafo do bounded context '${CONTEXT_SLUG}'..."

# ── Descoberta de manifesto por repo (local ou via gh api) ─────────────────
MANIFEST_PRIORITY=("pom.xml" "package.json" "go.mod" "requirements.txt" "build.gradle")

CURRENT_REPO_SLUG=""
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  remote_url="$(git config --get remote.origin.url 2>/dev/null || true)"
  # Normaliza para owner/repo a partir de URLs https ou ssh
  CURRENT_REPO_SLUG="$(echo "$remote_url" | sed -E 's#^(https://[^/]+/|git@[^:]+:)##; s#\.git$##')"
fi

# Encontra manifesto local (sibling directory com nome igual ao basename do repo)
find_local_manifest() {
  local repo="$1"
  local basename_repo
  basename_repo="$(basename "$repo")"
  local candidates=("./${basename_repo}" "../${basename_repo}")
  if [[ "$repo" == "$CURRENT_REPO_SLUG" ]]; then
    candidates=("." "${candidates[@]}")
  fi
  for dir in "${candidates[@]}"; do
    if [[ -d "$dir" ]]; then
      for m in "${MANIFEST_PRIORITY[@]}"; do
        if [[ -f "${dir}/${m}" ]]; then
          echo "${dir}/${m}"
          return 0
        fi
      done
    fi
  done
  return 1
}

# Fallback via gh api: busca o conteúdo do primeiro manifesto encontrado no
# root do repo. Retorna o texto decodificado (ou vazio) via stdout.
fetch_manifest_via_api() {
  local repo="$1"
  for m in "${MANIFEST_PRIORITY[@]}"; do
    if content="$(gh api "repos/${repo}/contents/${m}" --jq '.content' 2>/dev/null)"; then
      if [[ -n "$content" ]]; then
        echo "$content" | tr -d '\n' | base64 --decode 2>/dev/null && return 0
      fi
    fi
  done
  return 1
}

declare -a NODE_IDS=()
declare -a NODE_REPOS=()
declare -a NODE_CROSS_REPO=()
declare -a NODE_MANIFEST_SOURCE=()
declare -a EDGES_SRC=()
declare -a EDGES_DST=()
UNANALYZED_REPOS=()

node_id_for() {
  # Converte "owner/repo" em um id kebab-case estável para o grafo
  printf '%s' "$1" | tr '/[:upper:]' '-[:lower:]' | tr -cs 'a-z0-9-' '-'
}

while IFS=$'\t' read -r repo stack; do
  [[ -z "$repo" ]] && continue
  nid="$(node_id_for "$repo")"
  NODE_IDS+=("$nid")
  NODE_REPOS+=("$repo")
  if [[ "$repo" == "$CURRENT_REPO_SLUG" ]]; then
    NODE_CROSS_REPO+=("false")
  else
    NODE_CROSS_REPO+=("true")
  fi

  manifest_content=""
  manifest_source="none"
  if manifest_path="$(find_local_manifest "$repo")"; then
    manifest_content="$(cat "$manifest_path" 2>/dev/null || true)"
    manifest_source="local:${manifest_path}"
  elif manifest_content="$(fetch_manifest_via_api "$repo")"; then
    manifest_source="gh-api"
  else
    manifest_source="unavailable"
    UNANALYZED_REPOS+=("$repo")
  fi
  NODE_MANIFEST_SOURCE+=("$manifest_source")

  # Guarda o conteúdo em arquivo temporário indexado por posição para a
  # segunda passada (detecção de arestas entre repos do mesmo contexto)
  idx=$((${#NODE_IDS[@]} - 1))
  printf '%s' "$manifest_content" > "/tmp/.gcg-manifest-${idx}.txt"
done <<< "$REPOS_TSV"

# ── Segunda passada: detectar arestas (repo A depende de repo B do mesmo
#    contexto se o manifesto de A menciona o nome do repo B) ────────────────
for i in "${!NODE_IDS[@]}"; do
  content_i="$(cat "/tmp/.gcg-manifest-${i}.txt" 2>/dev/null || true)"
  [[ -z "$content_i" ]] && continue
  repo_i_basename="$(basename "${NODE_REPOS[$i]}")"
  for j in "${!NODE_IDS[@]}"; do
    [[ "$i" == "$j" ]] && continue
    repo_j_basename="$(basename "${NODE_REPOS[$j]}")"
    if echo "$content_i" | grep -qi -- "$repo_j_basename"; then
      EDGES_SRC+=("${NODE_IDS[$i]}")
      EDGES_DST+=("${NODE_IDS[$j]}")
    fi
  done
  rm -f "/tmp/.gcg-manifest-${i}.txt"
done

# ── Detecção de ciclos (apenas para aviso — não aborta) ─────────────────────
CYCLES_FOUND=()
for i in "${!EDGES_SRC[@]}"; do
  for j in "${!EDGES_SRC[@]}"; do
    if [[ "${EDGES_SRC[$i]}" == "${EDGES_DST[$j]}" && "${EDGES_DST[$i]}" == "${EDGES_SRC[$j]}" ]]; then
      # Normaliza o par ordenando os dois IDs, para não listar A<->B e B<->A
      # como dois ciclos distintos.
      if [[ "${EDGES_SRC[$i]}" < "${EDGES_DST[$i]}" ]]; then
        pair="${EDGES_SRC[$i]}<->${EDGES_DST[$i]}"
      else
        pair="${EDGES_DST[$i]}<->${EDGES_SRC[$i]}"
      fi
      if [[ ! " ${CYCLES_FOUND[*]:-} " == *" ${pair} "* ]]; then
        CYCLES_FOUND+=("$pair")
      fi
    fi
  done
done

# ── Emitir graph.yaml ────────────────────────────────────────────────────────
mkdir -p "$OUT_DIR"
GRAPH_YAML="${OUT_DIR}/graph.yaml"
GRAPH_MD="${OUT_DIR}/graph.md"

{
  echo "# graph.yaml — Bounded Context: ${CONTEXT_SLUG}"
  echo "# Gerado automaticamente por scripts/generate-context-graph.sh — specs/014-brownfield-multirepo-context-awareness/"
  echo
  echo "bounded_context: \"${CONTEXT_SLUG}\""
  echo "version: 1"
  echo "generated_at: \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\""
  echo
  echo "nodes:"
  for i in "${!NODE_IDS[@]}"; do
    echo "  - id: \"${NODE_IDS[$i]}\""
    echo "    type: \"repo\""
    echo "    repository: \"${NODE_REPOS[$i]}\""
    echo "    cross_repo: ${NODE_CROSS_REPO[$i]}"
    echo "    manifest_source: \"${NODE_MANIFEST_SOURCE[$i]}\""
  done
  echo
  echo "edges:"
  if [[ "${#EDGES_SRC[@]}" -eq 0 ]]; then
    echo "  []"
  else
    for i in "${!EDGES_SRC[@]}"; do
      echo "  - src: \"${EDGES_SRC[$i]}\""
      echo "    dst: \"${EDGES_DST[$i]}\""
      echo "    type: \"dependency\""
    done
  fi
  echo
  echo "unanalyzed_repos:"
  if [[ "${#UNANALYZED_REPOS[@]}" -eq 0 ]]; then
    echo "  []"
  else
    for r in "${UNANALYZED_REPOS[@]}"; do
      echo "  - \"${r}\""
    done
  fi
} > "$GRAPH_YAML"

# ── Emitir graph.md (diagrama Mermaid) ──────────────────────────────────────
{
  echo "# Grafo do Bounded Context: ${CONTEXT_SLUG}"
  echo
  echo "> Gerado automaticamente por \`scripts/generate-context-graph.sh\` — não editar manualmente."
  echo
  echo "\`\`\`mermaid"
  echo "graph LR"
  for i in "${!NODE_IDS[@]}"; do
    echo "  ${NODE_IDS[$i]}[\"${NODE_REPOS[$i]}\"]"
  done
  for i in "${!EDGES_SRC[@]}"; do
    echo "  ${EDGES_SRC[$i]} --> ${EDGES_DST[$i]}"
  done
  echo "\`\`\`"
  echo
  if [[ "${#CYCLES_FOUND[@]}" -gt 0 ]]; then
    echo "## ⚠ Dependências circulares detectadas"
    echo
    for c in "${CYCLES_FOUND[@]}"; do
      echo "- \`${c}\`"
    done
    echo
  fi
  if [[ "${#UNANALYZED_REPOS[@]}" -gt 0 ]]; then
    echo "## Repositórios não analisados"
    echo
    echo "Os seguintes repositórios não puderam ser acessados (nem localmente, nem via \`gh api\`):"
    echo
    for r in "${UNANALYZED_REPOS[@]}"; do
      echo "- \`${r}\`"
    done
    echo
  fi
} > "$GRAPH_MD"

echo -e "${GREEN}✓ ${GRAPH_YAML} gerado (${#NODE_IDS[@]} nós, ${#EDGES_SRC[@]} arestas)${NC}"
echo -e "${GREEN}✓ ${GRAPH_MD} gerado${NC}"
if [[ "${#UNANALYZED_REPOS[@]}" -gt 0 ]]; then
  echo -e "${YELLOW}⚠ ${#UNANALYZED_REPOS[@]} repo(s) não puderam ser analisados — ver ${GRAPH_MD}${NC}"
fi
if [[ "${#CYCLES_FOUND[@]}" -gt 0 ]]; then
  echo -e "${YELLOW}⚠ Dependência(s) circular(es) detectada(s) — ver ${GRAPH_MD}${NC}"
fi
