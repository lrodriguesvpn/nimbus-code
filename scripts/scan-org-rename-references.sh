#!/bin/bash

set -euo pipefail

ORG="${ORG:-venha-pra-nuvem}"
OLD_SLUG="${OLD_SLUG:-speckit-nimbus-code-standards}"
NEW_SLUG="${NEW_SLUG:-nimbus-code}"
GH_HOST="${GH_HOST:-venha-pra-nuvem.ghe.com}"
MODE="${MODE:-}"
OUTPUT="${OUTPUT:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

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

compare_semver_versions() {
  local left="$1"
  local right="$2"
  local IFS='.'
  local left_parts right_parts idx
  read -r -a left_parts <<< "$left"
  read -r -a right_parts <<< "$right"

  for idx in 0 1 2; do
    local left_segment="${left_parts[$idx]:-0}"
    local right_segment="${right_parts[$idx]:-0}"
    left_segment="${left_segment//[^0-9]/}"
    right_segment="${right_segment//[^0-9]/}"
    [[ -n "$left_segment" ]] || left_segment=0
    [[ -n "$right_segment" ]] || right_segment=0

    if (( 10#$left_segment > 10#$right_segment )); then
      echo 1
      return 0
    fi
    if (( 10#$left_segment < 10#$right_segment )); then
      echo -1
      return 0
    fi
  done

  echo 0
}

fetch_repo_file() {
  local repo="$1"
  local path="$2"

  gh api "repos/$repo/contents/$path" --jq '.content' 2>/dev/null | tr -d '\n' | python3 -c 'import base64, sys; data = sys.stdin.read().strip(); sys.stdout.write(base64.b64decode(data).decode("utf-8") if data else "")'
}

parse_registry_summary() {
  python3 -c 'import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    print("\\t\\t")
    raise SystemExit(0)
presets = data.get("presets", {}) if isinstance(data, dict) else {}
preset_id = next(iter(presets.keys()), "") if isinstance(presets, dict) else ""
current = ""
updated = ""
if preset_id:
    preset = presets.get(preset_id, {}) or {}
    current = preset.get("version", "") or data.get("version", "")
    updated = preset.get("installed_at", "")
else:
    current = data.get("version", "") if isinstance(data, dict) else ""
print("\\t".join([preset_id, current, updated]))'
}

run_default_slug_audit() {
  local raw_old web_old raw_new web_new hits_file

  raw_old="raw.${GH_HOST}/${ORG}/${OLD_SLUG}"
  web_old="${GH_HOST}/${ORG}/${OLD_SLUG}"
  raw_new="raw.${GH_HOST}/${ORG}/${NEW_SLUG}"
  web_new="${GH_HOST}/${ORG}/${NEW_SLUG}"
  hits_file="$REPO_ROOT/.scan-org-rename-references.hits.$$"
  trap 'rm -f "$hits_file"' EXIT

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

      echo "$response" | jq -r '.items[] | [.repository.full_name, .path] | @tsv' >> "$hits_file"

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
  : > "$hits_file"
  collect_query "org:${ORG} ${OLD_SLUG}"
  collect_query "org:${ORG} raw.${GH_HOST}/${ORG}/${OLD_SLUG}"
  collect_query "org:${ORG} ${GH_HOST}/${ORG}/${OLD_SLUG}"
  collect_query "org:${ORG} ./${OLD_SLUG}"

  sort -u -t $'\t' -k1,2 "$hits_file" -o "$hits_file"

  if [[ ! -s "$hits_file" ]]; then
    echo "✅ Nenhuma referência encontrada."
    return 0
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
    done < "$hits_file"
  } | sort | while IFS=$'\t' read -r level repo path; do
    echo "| ${level} | \`${repo}\` | \`${path}\` | substituir \`${OLD_SLUG}\` por \`${NEW_SLUG}\`; trocar \`${raw_old}\` → \`${raw_new}\`; trocar \`${web_old}\` → \`${web_new}\` |"
  done

  echo ""
  echo "## Próximo passo obrigatório por repositório"
  echo "1) abrir branch"
  echo "2) aplicar as trocas de URL/slug"
  echo "3) abrir PR"
  echo "4) validar CI"
  echo "5) mergear e só então seguir para o próximo lote"
}

run_satellite_preset_audit() {
  local output_file central_repo repos repo preset_version last_updated drift_status errors
  local report_helper script_root central_version

  output_file="${OUTPUT:-preset-audit-$(date +%Y%m%d-%H%M%S).csv}"
  central_repo="${ORG}/${NEW_SLUG}"
  script_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  report_helper="$script_root/scripts/preset-audit-report.py"
  central_version="$(python3 "$report_helper" version "$script_root/presets/nimbus-code-standards/preset.yml")"

  export GH_HOST
  [[ "$ORG" =~ ^[A-Za-z0-9][A-Za-z0-9-]*$ ]] || { echo "Invalid organization" >&2; exit 2; }

  echo "repo,current_version,drift_status,last_updated" > "$output_file"
  repos="$(gh api --paginate "orgs/$ORG/repos?per_page=100" --jq '.[].full_name')"
  errors=0

  for repo in $repos; do
    [[ "$repo" =~ ^[A-Za-z0-9][A-Za-z0-9-]*/[A-Za-z0-9][A-Za-z0-9_.-]*$ ]] || {
      echo "Invalid repository returned by API" >&2
      exit 2
    }

    if [[ "$repo" == "$central_repo" ]]; then
      continue
    fi

    if ! preset_version="$(gh api "repos/$repo/contents/.specify/presets/.registry" | \
      python3 "$report_helper" registry)"; then
      printf '%s,unknown,error,N/A\n' "$repo" >> "$output_file"
      echo "ERROR: unable to read preset registry for $repo" >&2
      errors=$((errors + 1))
      continue
    elif [[ "$preset_version" == "$central_version" ]]; then
      drift_status="in_sync"
    else
      drift_status="drift"
    fi

    if ! last_updated="$(gh api --method GET "repos/$repo/commits" \
      -f path=.specify -F per_page=1 --jq '.[0].commit.committer.date // "N/A"')"; then
      echo "ERROR: unable to read preset commit date for $repo" >&2
      last_updated="N/A"
      drift_status="error"
      errors=$((errors + 1))
    fi

    if [[ "$last_updated" != "N/A" && ! "$last_updated" =~ ^[0-9TZ:+.-]+$ ]]; then
      last_updated="N/A"
      drift_status="error"
      errors=$((errors + 1))
    fi

    printf '%s,%s,%s,%s\n' "$repo" "$preset_version" "$drift_status" "$last_updated" >> "$output_file"
  done

  echo "Preset audit report: $output_file (read errors: $errors)"
  [[ "$errors" == 0 ]] || exit 2
}

if [[ "$MODE" == "satellite-preset-audit" ]]; then
  run_satellite_preset_audit
else
  run_default_slug_audit
fi
