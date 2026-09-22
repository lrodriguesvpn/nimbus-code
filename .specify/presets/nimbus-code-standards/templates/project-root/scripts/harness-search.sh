#!/usr/bin/env bash
# Busca literal, case-insensitive, em tags e bounded_context do Harness Catalog.
# Lê o schema do catálogo (scalars, listas block/flow e campos > ou |), não YAML genérico.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CATALOG_FILE="${SCRIPT_DIR}/../docs/harness/harness-catalog.yaml"

usage() {
  printf 'Uso: %s <tag-ou-bounded-context> [--file <caminho>]\n' "$(basename "$0")"
}

if [[ $# -eq 0 || -z "$1" ]]; then
  usage
  exit 1
fi
SEARCH_TERM="$1"
shift
while [[ $# -gt 0 ]]; do
  case "$1" in
    --file)
      if [[ $# -lt 2 || -z "$2" ]]; then
        printf 'Erro: --file exige um caminho.\n' >&2
        exit 1
      fi
      CATALOG_FILE="$2"
      shift 2
      ;;
    *)
      printf 'Argumento desconhecido: %s\n' "$1" >&2
      usage
      exit 1
      ;;
  esac
done
if [[ ! -f "$CATALOG_FILE" ]]; then
  printf 'Erro: catálogo não encontrado em "%s"\n' "$CATALOG_FILE" >&2
  exit 1
fi

printf '\n🔍 Harness Search — buscando por: %s\n   Catálogo: %s\n\n' "$SEARCH_TERM" "$CATALOG_FILE"

# ENVIRON preserva backslashes e evita interpretar o termo como regex ou código awk.
HARNESS_SEARCH_TERM="$SEARCH_TERM" awk '
function trim(s) { sub(/^[[:space:]]+/, "", s); sub(/[[:space:]]+$/, "", s); return s }
function scalar(s,    q,i,c,nextc,out) {
  s=trim(s); q=substr(s,1,1)
  if (q != "\"" && q != sq) {
    sub(/[[:space:]]+#.*$/, "", s)
    return trim(s)
  }
  out=""
  for (i=2; i<=length(s); i++) {
    c=substr(s,i,1); nextc=substr(s,i+1,1)
    if (c==q) {
      if (q==sq && nextc==sq) { out=out q; i++; continue }
      break
    }
    if (q=="\"" && c=="\\") {
      i++; c=nextc
      if (c=="n" || c=="r" || c=="t") c=" "
    }
    out=out c
  }
  return out
}
function tag(s) {
  if (index(tolower(scalar(s)),term)) matched=1
}
function tags(s,    i,c,q,token) {
  s=trim(s); q=""; token=""
  if (substr(s,1,1)!="[") { tag(s); return }
  for (i=2; i<=length(s); i++) {
    c=substr(s,i,1)
    if (q!="") {
      token=token c
      if (q=="\"" && c=="\\") { token=token substr(s,++i,1); continue }
      if (c==q) {
        if (q==sq && substr(s,i+1,1)==sq) { token=token substr(s,++i,1); continue }
        q=""
      }
    } else if (c=="\"" || c==sq) { q=c; token=token c }
    else if (c=="," || c=="]") {
      tag(token); token=""
      if (c=="]") return
    } else token=token c
  }
}
function emit() {
  if (!active || !(matched || index(tolower(value["bounded_context"]),term))) return
  printf "  %s  [%s]  %s\n", value["id"],value["complexity"],value["date"]
  printf "  Padrão:     %s\n  Prevenção:  %s\n\n",value["error_pattern"],value["prevention"]
  found++
}
function start() {
  emit()
  for (k in value) delete value[k]
  active=1; matched=0; field=""; block=0
}
BEGIN { sq=sprintf("%c",39); term=tolower(ENVIRON["HARNESS_SEARCH_TERM"]); found=0 }
{
  sub(/\r$/, "")
  if ($0 ~ /^[[:space:]]*$/) next
  indent=match($0,/[^ ]/)-1; line=trim($0)
  if (line ~ /^#/ && !(active && block && indent>entryindent+2)) next
  if (!inside) {
    if (line ~ /^entries:[[:space:]]*(#.*)?$/) { inside=1; rootindent=indent }
    next
  }
  if (indent<=rootindent && line !~ /^-[[:space:]]/) {
    emit(); active=0; inside=0; next
  }
  if (line ~ /^-[[:space:]]+[a-z_]+:/ && (!active || indent==entryindent)) {
    entryindent=indent; start()
    sub(/^-[[:space:]]+/, "", line); indent=entryindent+2
  }
  if (!active) next
  if (indent==entryindent+2 && line ~ /^[a-z_]+:/) {
    field=line; sub(/:.*/, "", field)
    sub(/^[^:]+:[[:space:]]*/, "", line)
    block=(line ~ /^[>|][-+0-9]*([[:space:]]+#.*)?$/)
    if (field=="tags") { if (line!="" && line !~ /^#/) tags(line) }
    else if (field ~ /^(id|date|complexity|bounded_context|error_pattern|prevention)$/)
      value[field]=(block ? "" : scalar(line))
    next
  }
  if (field=="tags" && indent>=entryindent+2 && line ~ /^-[[:space:]]+/) {
    sub(/^-[[:space:]]+/, "", line); tag(line)
  } else if (block && indent>entryindent+2 && field ~ /^(bounded_context|error_pattern|prevention)$/)
    value[field]=value[field] (value[field]=="" ? "" : " ") line
}
END {
  emit()
  if (found) printf "  %d entrada(s) encontrada(s).\n",found
  else printf "  Nenhum resultado encontrado para: %s\n",ENVIRON["HARNESS_SEARCH_TERM"]
}
' < "$CATALOG_FILE"
