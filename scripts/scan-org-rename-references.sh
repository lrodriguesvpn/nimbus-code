#!/bin/bash

set -euo pipefail

ORG="${ORG:-venha-pra-nuvem}"
OLD_SLUG="${OLD_SLUG:-speckit-vpndev-standards}"
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

declare -A HITS=()

collect_query() {
  local query="$1"
  local page=1
  while true; do
    local response
    response="$(gh api search/code -f q="$query" -F per_page=100 -F page="$page")"

    local count
    count="$(echo "$response" | jq '.items | length')"
    if [[ "$count" -eq 0 ]]; then
      break
    fi

    while IFS=$'\t' read -r repo path; do
      [[ -z "$repo" || -z "$path" ]] && continue
      HITS["$repo|$path"]=1
    done < <(echo "$response" | jq -r '.items[] | [.repository.full_name, .path] | @tsv')

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

if [[ "${#HITS[@]}" -eq 0 ]]; then
  echo "✅ Nenhuma referência encontrada."
  exit 0
fi

echo ""
echo "## Resultado da varredura"
echo "| Criticidade | Repositório | Arquivo | Mudar manualmente |"
echo "|---|---|---|---|"

{
  for key in "${!HITS[@]}"; do
    repo="${key%%|*}"
    path="${key#*|}"
    level="$(classify_path "$path")"
    printf "%s\t%s\t%s\n" "$level" "$repo" "$path"
  done
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
