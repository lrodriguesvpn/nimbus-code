#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# harvest-patterns.sh
#
# Varre um repositório (ou subpasta) por metadados ESTRUTURAIS — nomes de
# arquivo, assinaturas de método/interface/classe, anotações/decoradores —
# e envia esses metadados (nunca corpo de método, strings literais ou dados
# de runtime) a um endpoint LLM configurável para identificar padrões
# arquiteturais reutilizáveis. Propõe entradas para docs/reuse-catalog.yaml,
# com checagem de duplicata por `tag`.
#
# Feature: specs/014-brownfield-multirepo-context-awareness/
# ADL-002: script vive em scripts/ (não em .specify/scripts/bash/).
# ADL-003: escreve direto em docs/reuse-catalog.yaml (git diff é o gate de
#          revisão), não num arquivo de candidatos separado.
# ADL-004: usa LLM (não análise estática determinística) — ver Security Gate
#          do plan.md: allowlist estrita de metadados estruturais.
#
# **NUNCA rodar em CI** (FR-011) — exclusivamente on-demand, iniciado por um
# humano. Este script não é referenciado por nenhum workflow em
# .github/workflows/ (verificado por T026).
#
# Uso:
#   scripts/harvest-patterns.sh <repo-path> [--subpath <dir>] [--output <arquivo>] [--dry-run]
#
# Variáveis de ambiente obrigatórias:
#   HARVEST_API_URL     Endpoint HTTP compatível com o formato descrito abaixo
#   HARVEST_API_TOKEN    Token Bearer para autenticação no endpoint
#
# Variável opcional:
#   BOUNDED_CONTEXTS_FILE  (default: docs/bounded-contexts.yaml)
#   HARVEST_CURL_BIN       (default: curl) — permite injeção de mock em testes
#
# Exit codes:
#   0 — sucesso (com ou sem padrões encontrados)
#   1 — erro (env vars ausentes, repo-path inválido, chamada LLM falhou)
###############################################################################

SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
BOUNDED_CONTEXTS_FILE="${BOUNDED_CONTEXTS_FILE:-docs/bounded-contexts.yaml}"
REUSE_CATALOG_FILE="${REUSE_CATALOG_FILE:-docs/reuse-catalog.yaml}"
CURL_BIN="${HARVEST_CURL_BIN:-curl}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

usage() {
  cat <<EOF
Uso: ${SCRIPT_NAME} <repo-path> [--subpath <dir>] [--output <arquivo>] [--dry-run]

Varre <repo-path> (ou <repo-path>/<subpath>, se informado) por metadados
estruturais e propõe entradas de padrão reutilizável para
\${REUSE_CATALOG_FILE} (default: docs/reuse-catalog.yaml).

Argumentos:
  <repo-path>         Obrigatório. Caminho local do repositório a varrer.
  --subpath <dir>      Opcional. Limita o harvest a um subdiretório (monorepos).
  --output <arquivo>   Opcional. Caminho do catálogo de saída (default: docs/reuse-catalog.yaml).
  --dry-run            Mostra os padrões detectados sem escrever no catálogo.
  --help               Mostra esta mensagem.

Variáveis de ambiente obrigatórias:
  HARVEST_API_URL      Endpoint LLM a chamar
  HARVEST_API_TOKEN     Token Bearer para autenticação

⚠ NUNCA rode este script em CI — é exclusivamente on-demand (FR-011).
EOF
}

REPO_PATH=""
SUBPATH=""
OUTPUT_FILE="$REUSE_CATALOG_FILE"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    --subpath)
      SUBPATH="$2"
      shift 2
      ;;
    --output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    *)
      if [[ -z "$REPO_PATH" ]]; then
        REPO_PATH="$1"
        shift
      else
        echo "Erro: argumento inesperado '$1'" >&2
        usage >&2
        exit 1
      fi
      ;;
  esac
done

if [[ -z "$REPO_PATH" ]]; then
  echo "Erro: <repo-path> é obrigatório." >&2
  usage >&2
  exit 1
fi

if [[ -z "${HARVEST_API_URL:-}" || -z "${HARVEST_API_TOKEN:-}" ]]; then
  echo -e "${RED}Erro: HARVEST_API_URL e HARVEST_API_TOKEN precisam estar configurados no ambiente.${NC}" >&2
  echo "Configure-os antes de rodar este script (exclusivamente on-demand, nunca em CI):" >&2
  echo '  export HARVEST_API_URL="https://..."' >&2
  echo '  export HARVEST_API_TOKEN="..."' >&2
  exit 1
fi

SCAN_DIR="$REPO_PATH"
if [[ -n "$SUBPATH" ]]; then
  SCAN_DIR="${REPO_PATH%/}/${SUBPATH}"
fi

if [[ ! -d "$SCAN_DIR" ]]; then
  echo -e "${RED}Erro: diretório '${SCAN_DIR}' não existe.${NC}" >&2
  exit 1
fi

echo "==> Fazendo harvest de padrões estruturais em '${SCAN_DIR}'..."

# ── Detecção de stack a partir do manifesto (T015) ─────────────────────────
detect_stack() {
  local dir="$1"
  if [[ -f "${dir}/pom.xml" ]] || find "$dir" -maxdepth 3 -iname "*.java" 2>/dev/null | grep -q .; then
    echo "java"
  elif [[ -f "${dir}/package.json" ]]; then
    echo "node"
  elif [[ -f "${dir}/go.mod" ]]; then
    echo "go"
  elif [[ -f "${dir}/requirements.txt" ]] || [[ -f "${dir}/pyproject.toml" ]]; then
    echo "python"
  else
    echo "unknown"
  fi
}

STACK="$(detect_stack "$SCAN_DIR")"
echo "==> Stack detectada: ${STACK}"

# ── Extração de metadados estruturais (ALLOWLIST — nunca corpo de método ou
#    string literal, ver Security Gate do plan.md / FR-004) ────────────────
# Cada linha extraída é "arquivo:linha:assinatura" — apenas a linha de
# declaração (assinatura), nunca o conteúdo do bloco que a segue.
METADATA_FILE="$(mktemp)"
trap 'rm -f "$METADATA_FILE"' EXIT

case "$STACK" in
  java)
    # Interfaces públicas (candidatos a Port & Adapter / pontos de extensão)
    # e anotações recorrentes — apenas a linha de assinatura.
    find "$SCAN_DIR" -iname "*.java" -print0 2>/dev/null | \
      xargs -0 grep -nE '^\s*(public\s+)?(interface|@interface)\s+\w+' 2>/dev/null \
      >> "$METADATA_FILE" || true
    find "$SCAN_DIR" -iname "*.java" -print0 2>/dev/null | \
      xargs -0 grep -nE '^\s*@[A-Z][A-Za-z0-9_]*' 2>/dev/null \
      >> "$METADATA_FILE" || true
    ;;
  node)
    # Factories recorrentes (funções/exports "createX")
    find "$SCAN_DIR" \( -iname "*.js" -o -iname "*.ts" \) -print0 2>/dev/null | \
      xargs -0 grep -nE '(export\s+)?(function|const)\s+create[A-Z][A-Za-z0-9_]*' 2>/dev/null \
      >> "$METADATA_FILE" || true
    ;;
  go)
    find "$SCAN_DIR" -iname "*.go" -print0 2>/dev/null | \
      xargs -0 grep -nE '^\s*type\s+\w+\s+interface' 2>/dev/null \
      >> "$METADATA_FILE" || true
    ;;
  python)
    find "$SCAN_DIR" -iname "*.py" -print0 2>/dev/null | \
      xargs -0 grep -nE '^\s*class\s+\w+\s*\(' 2>/dev/null \
      >> "$METADATA_FILE" || true
    ;;
  *)
    echo -e "${YELLOW}⚠ Stack não reconhecida — usando apenas nomes de arquivo como metadado.${NC}" >&2
    find "$SCAN_DIR" -type f -print0 2>/dev/null | xargs -0 -n1 basename >> "$METADATA_FILE" || true
    ;;
esac

METADATA_COUNT="$(wc -l < "$METADATA_FILE" | tr -d ' ')"

if [[ "$METADATA_COUNT" -eq 0 ]]; then
  echo -e "${YELLOW}Nenhum padrão estrutural detectável encontrado em '${SCAN_DIR}'.${NC}"
  echo "Nenhuma entrada será proposta — o catálogo não é poluído com entradas vazias/genéricas."
  exit 0
fi

echo "==> ${METADATA_COUNT} elementos estruturais encontrados. Preparando envio ao LLM..."

# ── Montagem do payload (apenas allowlist) ──────────────────────────────────
PAYLOAD_FILE="$(mktemp)"
trap 'rm -f "$METADATA_FILE" "$PAYLOAD_FILE"' EXIT

python3 - "$METADATA_FILE" "$STACK" "$REPO_PATH" > "$PAYLOAD_FILE" <<'PYEOF'
import json, sys

metadata_file, stack, repo_path = sys.argv[1], sys.argv[2], sys.argv[3]
entries = []
with open(metadata_file, encoding="utf-8", errors="replace") as f:
    for line in f:
        line = line.rstrip("\n")
        if not line:
            continue
        # formato do grep -n: "arquivo:linha:conteudo"
        parts = line.split(":", 2)
        if len(parts) == 3:
            entries.append({"file": parts[0], "line": parts[1], "signature": parts[2].strip()})
        else:
            entries.append({"file": line, "line": None, "signature": None})

prompt = (
    "Você recebe metadados ESTRUTURAIS (nomes de arquivo, assinaturas de "
    "método/interface/classe, anotações) de um repositório de código, stack "
    f"'{stack}'. Identifique padrões arquiteturais reutilizáveis (ex.: Port & "
    "Adapter, Factory, Repository). Nunca invente padrão sem evidência nos "
    "metadados. Responda como um array JSON de objetos com os campos: tag "
    "(kebab-case curto), description (1-2 frases), example (a assinatura mais "
    "representativa), source_file, source_line. Se nenhum padrão claro for "
    "identificável, responda com um array vazio []."
)

payload = {
    "repo": repo_path,
    "stack": stack,
    "prompt": prompt,
    "metadata": entries,
}
print(json.dumps(payload))
PYEOF

# ── Chamada ao endpoint LLM (T016) ──────────────────────────────────────────
RESPONSE_FILE="$(mktemp)"
trap 'rm -f "$METADATA_FILE" "$PAYLOAD_FILE" "$RESPONSE_FILE"' EXIT

HTTP_STATUS=$("$CURL_BIN" -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$HARVEST_API_URL" \
  -H "Authorization: Bearer ${HARVEST_API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data-binary "@${PAYLOAD_FILE}") || {
  echo -e "${RED}Erro: falha na chamada HTTP a HARVEST_API_URL.${NC}" >&2
  exit 1
}

if [[ "$HTTP_STATUS" != "200" ]]; then
  echo -e "${RED}Erro: HARVEST_API_URL retornou status ${HTTP_STATUS}.${NC}" >&2
  cat "$RESPONSE_FILE" >&2
  exit 1
fi

# ── Log de custo de tokens (T019) ───────────────────────────────────────────
python3 -c "
import json
try:
    with open('${RESPONSE_FILE}', encoding='utf-8') as f:
        resp = json.load(f)
    tokens_used = resp.get('tokens_used')
    estimated_cost = resp.get('estimated_cost')
    if tokens_used is not None:
        print(f'==> Custo desta execução: tokens_used={tokens_used}, estimated_cost={estimated_cost}')
except Exception:
    pass
"

# ── Extrai as entradas candidatas (aceita tanto {"entries": [...]} quanto um
#    array puro na raiz da resposta) ────────────────────────────────────────
CANDIDATES_FILE="$(mktemp)"
trap 'rm -f "$METADATA_FILE" "$PAYLOAD_FILE" "$RESPONSE_FILE" "$CANDIDATES_FILE"' EXIT

python3 -c "
import json
with open('${RESPONSE_FILE}', encoding='utf-8') as f:
    resp = json.load(f)
entries = resp.get('entries', resp) if isinstance(resp, dict) else resp
if not isinstance(entries, list):
    entries = []
with open('${CANDIDATES_FILE}', 'w', encoding='utf-8') as out:
    json.dump(entries, out)
"

CANDIDATE_COUNT="$(python3 -c "import json; print(len(json.load(open('${CANDIDATES_FILE}'))))")"

if [[ "$CANDIDATE_COUNT" -eq 0 ]]; then
  echo -e "${YELLOW}O LLM não identificou nenhum padrão reutilizável com evidência suficiente.${NC}"
  echo "Nenhuma entrada será proposta — o catálogo não é poluído com entradas vazias/genéricas."
  exit 0
fi

echo "==> ${CANDIDATE_COUNT} padrão(ões) candidato(s) identificado(s)."

# ── Deduplicação por tag + escrita idempotente no catálogo (T017, T020) ────
BOUNDED_CONTEXT_SLUG=""
if [[ -f "$BOUNDED_CONTEXTS_FILE" ]]; then
  BOUNDED_CONTEXT_SLUG="$(python3 -c "
import yaml
d = yaml.safe_load(open('${BOUNDED_CONTEXTS_FILE}'))
for c in d.get('contexts', []) or []:
    repo = c.get('repository', '')
    if repo and repo in '${REPO_PATH}':
        print(c.get('slug', ''))
        break
" 2>/dev/null || true)"
fi

python3 - "$CANDIDATES_FILE" "$OUTPUT_FILE" "$BOUNDED_CONTEXT_SLUG" "$REPO_PATH" "$DRY_RUN" <<'PYEOF'
import sys, yaml, os

candidates_file, catalog_file, bounded_context, repo_path, dry_run = sys.argv[1:6]
dry_run = dry_run == "true"

with open(candidates_file, encoding="utf-8") as f:
    import json
    candidates = json.load(f)

if os.path.exists(catalog_file):
    with open(catalog_file, encoding="utf-8") as f:
        catalog = yaml.safe_load(f) or {"version": 1, "entries": []}
else:
    catalog = {"version": 1, "entries": []}

existing_tags = {e.get("tag") for e in catalog.get("entries", [])}

added = []
skipped = []
for c in candidates:
    tag = c.get("tag")
    if not tag:
        continue
    if tag in existing_tags:
        skipped.append(tag)
        continue
    entry = {
        "tag": tag,
        "bounded_context": bounded_context or "unmapped",
        "description": c.get("description", ""),
        "source": f"{repo_path}:{c.get('source_file', '')}:{c.get('source_line', '')}",
        "example": c.get("example", ""),
        "reuse_count": 0,
    }
    catalog.setdefault("entries", []).append(entry)
    existing_tags.add(tag)
    added.append(tag)

for tag in skipped:
    print(f"⚠ Tag '{tag}' já existe no catálogo — pulando (aviso de duplicata, FR-006/T017)")

if dry_run:
    print(f"[--dry-run] {len(added)} entrada(s) seriam adicionadas: {', '.join(added) if added else '(nenhuma)'}")
else:
    if added:
        with open(catalog_file, "w", encoding="utf-8") as f:
            yaml.safe_dump(catalog, f, allow_unicode=True, sort_keys=False, default_flow_style=False)
        print(f"✓ {len(added)} entrada(s) adicionada(s) a {catalog_file}: {', '.join(added)}")
    else:
        print("Nenhuma entrada nova a adicionar (todas já existiam — execução idempotente).")
PYEOF

echo -e "${GREEN}✓ Harvest concluído.${NC}"
echo -e "${YELLOW}Revise o git diff de ${OUTPUT_FILE} antes de fazer commit (ADL-003 — o diff é o gate de revisão).${NC}"
