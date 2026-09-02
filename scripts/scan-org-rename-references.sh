#!/bin/bash

set -euo pipefail

ORG="${ORG:-venha-pra-nuvem}"
OLD_SLUG="${OLD_SLUG:-speckit-nimbus-code-standards}"
NEW_SLUG="${NEW_SLUG:-nimbus-code-spec-kit-template}"
GH_HOST="${GH_HOST:-venha-pra-nuvem.ghe.com}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --org)
      ORG="$2"
      shift 2
      ;;
    --old-slug)
      OLD_SLUG="$2"
      shift 2
      ;;
    --new-slug)
      NEW_SLUG="$2"
      shift 2
      ;;
    --gh-host)
      GH_HOST="$2"
      shift 2
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

RAW_OLD="raw.${GH_HOST}/${ORG}/${OLD_SLUG}"
WEB_OLD="${GH_HOST}/${ORG}/${OLD_SLUG}"
RAW_NEW="raw.${GH_HOST}/${ORG}/${NEW_SLUG}"
WEB_NEW="${GH_HOST}/${ORG}/${NEW_SLUG}"

HITS_FILE="$(mktemp)"
trap 'rm -f "$HITS_FILE"' EXIT

collect_query() {
  local query="$1"
  local page=1
  while true; do
    local response
    if ! response="$(gh api -X GET search/code -f q="$query" -F per_page=100 -F page="$page" 2>&1)"; then
      echo "❌ Falha ao consultar GitHub Code Search para query: $query" >&2
      echo "$response" >&2
      if echo "$response" | grep -q "HTTP 403"; then
        echo "🔐 Verifique permissões do token do gh (Code Search/leitura na organização)." >&2
      fi
      exit 1
    fi

    local count
    count="$(echo "$response" | jq '.items | length')"
    if [[ "$count" -eq 0 ]]; then
      break
    fi

    echo "$response" | jq -r '.items[] | [.repository.full_name, .path] | @tsv' >> "$HITS_FILE"

    if [[ "$count" -lt 100 ]]; then
      break
    fi
    page=$((page + 1))
  done
}

classify_path() {
  local path="$1"
  if [[ "$path" =~ (^|/)bootstrap\.sh$ ]] \
    || [[ "$path" =~ (^|/)catalog\.json$ ]] \
    || [[ "$path" =~ (^|/)\.github/workflows/ ]] \
    || [[ "$path" =~ (^|/)templates/workflows/ ]] \
    || [[ "$path" =~ (^|/)(bundle|preset|extension)\.yml$ ]]; then
    echo "CRITICO"
  elif [[ "$path" =~ (^|/)docs/ ]] || [[ "$path" =~ (^|/)README ]] || [[ "$path" =~ \.md$ ]]; then
    echo "MEDIO"
  else
    echo "BAIXO"
  fi
}

echo "→ Varredura org-wide em ${ORG} para slug antigo: ${OLD_SLUG}"
collect_query "org:${ORG} ${OLD_SLUG}"
collect_query "org:${ORG} raw.${GH_HOST}/${ORG}/${OLD_SLUG}"
collect_query "org:${ORG} ${GH_HOST}/${ORG}/${OLD_SLUG}"
collect_query "org:${ORG} ./${OLD_SLUG}"

# Dedup por repo+path — usa sort -u em vez de chaves de array associativo, já
# que `declare -A` (bash 4+) não existe no bash 3.2 padrão do macOS (preso
# nessa versão por licenciamento GPLv2 da Apple), causando erro imediato
# ("declare: -A: invalid option") antes mesmo da primeira consulta rodar.
sort -u -t $'\t' -k1,2 "$HITS_FILE" -o "$HITS_FILE"

if [[ ! -s "$HITS_FILE" ]]; then
  echo "✅ Nenhuma referência encontrada."
  exit 0
fi

echo ""
echo "## Resultado da varredura"
echo "| Criticidade | Repositório | Arquivo | Mudar manualmente |"
echo "|---|---|---|---|"

{
  while IFS=$'\t' read -r repo path; do
    [[ -z "$repo" || -z "$path" ]] && continue
    level="$(classify_path "$path")"
    printf "%s\t%s\t%s\n" "$level" "$repo" "$path"
  done < "$HITS_FILE"
} | sort | while IFS=$'\t' read -r level repo path; do
  echo "| ${level} | \`${repo}\` | \`${path}\` | substituir \`${OLD_SLUG}\` por \`${NEW_SLUG}\`; trocar \`${RAW_OLD}\` → \`${RAW_NEW}\`; trocar \`${WEB_OLD}\` → \`${WEB_NEW}\` |"
done

echo ""
echo "## Próximo passo obrigatório por repositório"
echo "1) abrir branch"
echo "2) aplicar as trocas de URL/slug"
echo "3) abrir PR"
echo "4) validar CI"
echo "5) mergear e só então seguir para o próximo lote"

# ============================================================================
# Mode: satellite-preset-audit (added by T-046)
# ============================================================================
# Usage: ./scan-org-rename-references.sh --mode satellite-preset-audit [--org ORG] [--output OUTPUT]
#
# Scans all satellite repos and checks preset version alignment with central repo.
# Outputs CSV report: repo,current_version,drift_status,last_updated
# ============================================================================

if [[ "$MODE" == "satellite-preset-audit" ]]; then
  ORG="${ORG:-venha-pra-nuvem}"
  OUTPUT_FILE="${OUTPUT:-preset-audit-$(date +%Y%m%d-%H%M%S).csv}"
  CENTRAL_VERSION="1.18.0"  # From specs/020-satellite-repo-governance/tasks.md
  
  echo "repo,current_version,drift_status,last_updated" > "$OUTPUT_FILE"
  
  # Query GitHub API for all repos in org
  repos=$(gh repo list "$ORG" --limit 1000 --json nameWithOwner --jq '.[].nameWithOwner')
  
  for repo in $repos; do
    # Skip central repo (we're looking at satellites only)
    if [[ "$repo" == *"nimbus-code-spec-kit-template" ]]; then
      continue
    fi
    
    # Query preset version from satellite repo
    preset_version=$(gh api "repos/$repo/contents/.specify/presets/.registry" \
      --jq '.content' 2>/dev/null | base64 -d | \
      jq -r '.version // "unknown"' 2>/dev/null || echo "missing")
    
    # Determine drift status
    if [[ "$preset_version" == "$CENTRAL_VERSION" ]]; then
      drift_status="in_sync"
    elif [[ "$preset_version" == "missing" ]] || [[ "$preset_version" == "unknown" ]]; then
      drift_status="not_bootstrapped"
    else
      drift_status="drift"
    fi
    
    # Get last update time for .specify directory
    last_updated=$(gh api "repos/$repo/commits" \
      --jq 'map(select(.files[].path | startswith(".specify"))) | .[0].commit.committer.date // "N/A"' 2>/dev/null || echo "N/A")
    
    echo "$repo,$preset_version,$drift_status,$last_updated" >> "$OUTPUT_FILE"
  done
  
  echo "✓ Preset audit complete. Report saved to: $OUTPUT_FILE"
  echo "  Drifted repos:"
  grep ",drift," "$OUTPUT_FILE" | cut -d',' -f1
fi
