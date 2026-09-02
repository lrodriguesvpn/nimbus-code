#!/bin/bash

set -euo pipefail

ORG="${ORG:-venha-pra-nuvem}"
OLD_SLUG="${OLD_SLUG:-speckit-nimbus-code-standards}"
NEW_SLUG="${NEW_SLUG:-nimbus-code-spec-kit-template}"
GH_HOST="${GH_HOST:-venha-pra-nuvem.ghe.com}"
MODE="${MODE:-}"
OUTPUT="${OUTPUT:-}"

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
    --mode)
      MODE="$2"
      shift 2
      ;;
    --output)
      OUTPUT="$2"
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

# O modo padrão (varredura org-wide de referências ao slug antigo) e o modo
# --mode satellite-preset-audit são mutuamente exclusivos: o segundo não deve
# disparar as buscas de Code Search do primeiro (custo de API e ruído
# desnecessários).
if [[ "$MODE" != "satellite-preset-audit" ]]; then

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

fi # MODE != satellite-preset-audit

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

  # Fonte única de verdade: presets/nimbus-code-standards/preset.yml no repo
  # central. Nunca hardcodear a versão aqui — isso exigiria lembrar de
  # bumpar em dois lugares a cada release (aqui e no preset.yml), e
  # esquecer faria todo satélite já atualizado aparecer como "drift" contra
  # uma versão central desatualizada.
  PRESET_YML="presets/nimbus-code-standards/preset.yml"
  if [[ -f "$PRESET_YML" ]]; then
    CENTRAL_VERSION="$(grep -m1 -E '^[[:space:]]*version:' "$PRESET_YML" | sed -E 's/.*"([0-9.]+)".*/\1/')"
  else
    echo "❌ Não encontrei ${PRESET_YML} a partir do diretório atual — rode este script a partir da raiz do repositório central." >&2
    exit 1
  fi
  
  echo "repo,current_version,drift_status,last_updated" > "$OUTPUT_FILE"
  
  # Query GitHub API for all repos in org
  repos=$(gh repo list "$ORG" --limit 1000 --json nameWithOwner --jq '.[].nameWithOwner')
  
  for repo in $repos; do
    # Skip central repo (we're looking at satellites only)
    if [[ "$repo" == *"nimbus-code-spec-kit-template" ]]; then
      continue
    fi
    
    # Query preset version from satellite repo. Não usar "|| echo missing" aqui:
    # com pipefail, um estágio intermediário do pipe (ex.: base64 -d recebendo
    # entrada vazia) pode falhar mas o jq final ainda produzir saída válida —
    # checar se a variável ficou vazia no final é mais confiável do que
    # confiar no exit code do pipe inteiro.
    preset_version="$(gh api "repos/$repo/contents/.specify/presets/.registry" \
      --jq '.content' 2>/dev/null | base64 -d 2>/dev/null | \
      jq -r '.version // "unknown"' 2>/dev/null)" || preset_version=""
    if [[ -z "$preset_version" ]]; then
      preset_version="missing"
    fi
    
    # Determine drift status
    if [[ "$preset_version" == "$CENTRAL_VERSION" ]]; then
      drift_status="in_sync"
    elif [[ "$preset_version" == "missing" ]] || [[ "$preset_version" == "unknown" ]]; then
      drift_status="not_bootstrapped"
    else
      drift_status="drift"
    fi
    
    # Get last update time for .specify directory. Usar "if cmd; then ...
    # else ...; fi" em vez de "cmd || echo N/A": com $(...), a saída parcial
    # (ex.: corpo de erro JSON de um repo vazio/409) já foi capturada pela
    # substituição de comando mesmo quando o comando falha, então um "||"
    # simplesmente concatenaria o JSON de erro com "N/A" em vez de substituí-lo.
    if last_updated="$(gh api "repos/$repo/commits" \
      --jq 'map(select(.files[].path | startswith(".specify"))) | .[0].commit.committer.date // "N/A"' 2>/dev/null)" \
      && [[ -n "$last_updated" ]]; then
      :
    else
      last_updated="N/A"
    fi
    
    echo "$repo,$preset_version,$drift_status,$last_updated" >> "$OUTPUT_FILE"
  done
  
  echo "✓ Preset audit complete. Report saved to: $OUTPUT_FILE"
  echo "  Drifted repos:"
  # "|| true": nenhum repo em drift é o resultado esperado/de sucesso, não uma
  # falha do script — sem isso, o exit code 1 do grep (nenhum match) propagava
  # via pipefail e derrubava todo o job do workflow mesmo com auditoria OK.
  grep ",drift," "$OUTPUT_FILE" | cut -d',' -f1 || true
fi
