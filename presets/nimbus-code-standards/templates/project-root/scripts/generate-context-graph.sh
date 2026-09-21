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

# Bloco de contexto multi-repo gerado por este script (YAML)
_emit_context_yaml_block() {
  echo "# Grafo de contexto multi-repo (gerado por scripts/generate-context-graph.sh"
  echo "# — specs/014-brownfield-multirepo-context-awareness/)"
  echo "context_graph:"
  echo "  bounded_context: \"${CONTEXT_SLUG}\""
  echo "  generated_at: \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\""
  echo "  nodes:"
  for i in "${!NODE_IDS[@]}"; do
    echo "    - id: \"${NODE_IDS[$i]}\""
    echo "      type: \"repo\""
    echo "      repository: \"${NODE_REPOS[$i]}\""
    echo "      cross_repo: ${NODE_CROSS_REPO[$i]}"
    echo "      manifest_source: \"${NODE_MANIFEST_SOURCE[$i]}\""
  done
  echo "  edges:"
  if [[ "${#EDGES_SRC[@]}" -eq 0 ]]; then
    echo "    []"
  else
    for i in "${!EDGES_SRC[@]}"; do
      echo "    - src: \"${EDGES_SRC[$i]}\""
      echo "      dst: \"${EDGES_DST[$i]}\""
      echo "      type: \"dependency\""
    done
  fi
  echo "  unanalyzed_repos:"
  if [[ "${#UNANALYZED_REPOS[@]}" -eq 0 ]]; then
    echo "    []"
  else
    for r in "${UNANALYZED_REPOS[@]}"; do
      echo "    - \"${r}\""
    done
  fi
}

# Determina se graph.yaml já existe com grafo de módulos internos (i.e., tem
# chaves de nível raiz como feature:/externals:/complexity: que são de autoria
# manual — não geradas por este script).
_has_module_graph() {
  local f="$1"
  [[ -f "$f" ]] || return 1
  grep -qE '^(feature|externals|complexity|spec_ref):[[:space:]]' "$f"
}

if _has_module_graph "$GRAPH_YAML"; then
  # ── Modo merge: preserva grafo de módulos, atualiza apenas context_graph ──
  # Remove o bloco context_graph: pré-existente (todas as linhas desde a
  # linha "context_graph:" até o fim do arquivo, ou até a próxima chave de
  # nível raiz que não seja um comentário ou linha em branco).
  GRAPH_YAML_TMP="$(mktemp)"
  python3 - "$GRAPH_YAML" "$GRAPH_YAML_TMP" <<'PYEOF'
import sys, re

src_path, dst_path = sys.argv[1], sys.argv[2]
with open(src_path, encoding='utf-8') as f:
    lines = f.readlines()

# Remove trailing blank lines at end of file
while lines and lines[-1].strip() == '':
    lines.pop()

# Find the start of the context_graph block (top-level key, not indented)
context_start = None
for i, line in enumerate(lines):
    if re.match(r'^context_graph\s*:', line):
        context_start = i
        break

if context_start is not None:
    lines = lines[:context_start]
    # Also remove any trailing comment lines that belong to the context_graph
    # header (lines starting with '#' followed immediately by context_graph:)
    while lines and lines[-1].strip().startswith('#'):
        lines.pop()

# Remove trailing blank lines again after stripping context_graph
while lines and lines[-1].strip() == '':
    lines.pop()

with open(dst_path, 'w', encoding='utf-8') as f:
    f.writelines(lines)
    f.write('\n')
PYEOF
  {
    cat "$GRAPH_YAML_TMP"
    _emit_context_yaml_block
  } > "$GRAPH_YAML"
  rm -f "$GRAPH_YAML_TMP"
elif [[ -f "$GRAPH_YAML" ]]; then
  # ── Arquivo existe mas só tem conteúdo do script anterior: substituir ──
  {
    echo "# graph.yaml — Bounded Context: ${CONTEXT_SLUG}"
    echo "# Gerado automaticamente por scripts/generate-context-graph.sh — specs/014-brownfield-multirepo-context-awareness/"
    echo
    echo "bounded_context: \"${CONTEXT_SLUG}\""
    echo "version: 1"
    echo
    _emit_context_yaml_block
  } > "$GRAPH_YAML"
else
  # ── Arquivo novo: criar do zero ──────────────────────────────────────────
  {
    echo "# graph.yaml — Bounded Context: ${CONTEXT_SLUG}"
    echo "# Gerado automaticamente por scripts/generate-context-graph.sh — specs/014-brownfield-multirepo-context-awareness/"
    echo
    echo "bounded_context: \"${CONTEXT_SLUG}\""
    echo "version: 1"
    echo
    _emit_context_yaml_block
  } > "$GRAPH_YAML"
fi

# ── Bloco Mermaid do grafo de contexto multi-repo ────────────────────────────
# Delimitado por marcadores HTML para permitir merge não-destrutivo em graph.md
CONTEXT_MD_MARKER_START="<!-- generate-context-graph:start -->"
CONTEXT_MD_MARKER_END="<!-- generate-context-graph:end -->"

_emit_context_md_block() {
  echo "${CONTEXT_MD_MARKER_START}"
  echo "## Grafo de Contexto Multi-Repo: ${CONTEXT_SLUG}"
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
    echo "### ⚠ Dependências circulares detectadas"
    echo
    for c in "${CYCLES_FOUND[@]}"; do
      echo "- \`${c}\`"
    done
    echo
  fi
  if [[ "${#UNANALYZED_REPOS[@]}" -gt 0 ]]; then
    echo "### Repositórios não analisados"
    echo
    echo "Os seguintes repositórios não puderam ser acessados (nem localmente, nem via \`gh api\`):"
    echo
    for r in "${UNANALYZED_REPOS[@]}"; do
      echo "- \`${r}\`"
    done
    echo
  fi
  echo "${CONTEXT_MD_MARKER_END}"
}

# ── Emitir graph.md (diagrama Mermaid) ──────────────────────────────────────
if [[ -f "$GRAPH_MD" ]] && grep -qF "${CONTEXT_MD_MARKER_START}" "$GRAPH_MD"; then
  # ── Modo merge: substituir apenas o bloco delimitado por marcadores ───────
  GRAPH_MD_TMP="$(mktemp)"
  python3 - "$GRAPH_MD" "$GRAPH_MD_TMP" \
      "${CONTEXT_MD_MARKER_START}" "${CONTEXT_MD_MARKER_END}" <<'PYEOF'
import sys

src_path, dst_path, marker_start, marker_end = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
with open(src_path, encoding='utf-8') as f:
    content = f.read()

before = content[:content.index(marker_start)]
after_marker = content[content.index(marker_end) + len(marker_end):]

# Strip one leading newline from the trailing part (marker was on its own line)
if after_marker.startswith('\n'):
    after_marker = after_marker[1:]

with open(dst_path, 'w', encoding='utf-8') as f:
    f.write(before)
PYEOF
  {
    cat "$GRAPH_MD_TMP"
    _emit_context_md_block
    # Append any content that was after the end marker
    python3 - "$GRAPH_MD" "${CONTEXT_MD_MARKER_START}" "${CONTEXT_MD_MARKER_END}" <<'PYEOF'
import sys
src_path, marker_start, marker_end = sys.argv[1], sys.argv[2], sys.argv[3]
with open(src_path, encoding='utf-8') as f:
    content = f.read()
after = content[content.index(marker_end) + len(marker_end):]
if after.startswith('\n'):
    after = after[1:]
sys.stdout.write(after)
PYEOF
  } > "$GRAPH_MD"
  rm -f "$GRAPH_MD_TMP"
elif [[ -f "$GRAPH_MD" ]]; then
  # ── Arquivo existe sem marcadores: adicionar seção de contexto no final ───
  # Remove trailing newline then append the context block
  {
    # Preserve existing content, trim trailing blank lines
    python3 - "$GRAPH_MD" <<'PYEOF'
import sys
with open(sys.argv[1], encoding='utf-8') as f:
    content = f.read()
print(content.rstrip(), end='\n\n')
PYEOF
    _emit_context_md_block
  } > "${GRAPH_MD}.tmp" && mv "${GRAPH_MD}.tmp" "$GRAPH_MD"
else
  # ── Arquivo novo: criar do zero ──────────────────────────────────────────
  {
    echo "# Grafo do Bounded Context: ${CONTEXT_SLUG}"
    echo
    _emit_context_md_block
  } > "$GRAPH_MD"
fi

echo -e "${GREEN}✓ ${GRAPH_YAML} gerado (${#NODE_IDS[@]} nós, ${#EDGES_SRC[@]} arestas)${NC}"
echo -e "${GREEN}✓ ${GRAPH_MD} gerado${NC}"
if [[ "${#UNANALYZED_REPOS[@]}" -gt 0 ]]; then
  echo -e "${YELLOW}⚠ ${#UNANALYZED_REPOS[@]} repo(s) não puderam ser analisados — ver ${GRAPH_MD}${NC}"
fi
if [[ "${#CYCLES_FOUND[@]}" -gt 0 ]]; then
  echo -e "${YELLOW}⚠ Dependência(s) circular(es) detectada(s) — ver ${GRAPH_MD}${NC}"
fi
