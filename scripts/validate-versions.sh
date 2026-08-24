#!/bin/bash
#
# validate-versions.sh - Validador de consistência de versões entre bundles, presets, catalogs e tags git
# 
# Propósito:
#   - Garantir que versões de bundles e presets são sincronizadas
#   - Validar que URLs de download refletem as versões
#   - Verificar que a tag git corresponde à versão principal do bundle
#
# Uso:
#   ./scripts/validate-versions.sh [--fix]  # Executa validação; com --fix, tenta auto-corrigir datas
#
# Saída:
#   - Exit 0 se todas as validações passarem
#   - Exit 1 se falhar
#

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0
FIX_MODE="${1:-}"

log_error() {
  echo -e "${RED}[ERROR]${NC} $*" >&2
  ERRORS=$((ERRORS + 1))
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $*" >&2
  WARNINGS=$((WARNINGS + 1))
}

log_ok() {
  echo -e "${GREEN}[OK]${NC} $*"
}

log_info() {
  echo -e "${BLUE}[INFO]${NC} $*"
}

# ============================================================================
# 1. Validar versões de bundles vs. presets fornecidos no bundle.yml
# ============================================================================
validate_bundle_preset_consistency() {
  log_info "Validando sincronização entre bundle.yml e presets fornecidos..."
  
  local bundles=(bundles/*/bundle.yml)
  
  for bundle_file in "${bundles[@]}"; do
    [ -f "$bundle_file" ] || continue
    
    local bundle_dir=$(dirname "$bundle_file")
    local bundle_id=$(yq '.bundle.id' "$bundle_file")
    local bundle_version=$(yq '.bundle.version' "$bundle_file")
    
    log_info "  Verificando bundle: $bundle_id (v$bundle_version)"
    
    # Extrair presets fornecidos pelo bundle
    local preset_count=$(yq '.provides.presets | length' "$bundle_file" 2>/dev/null || echo 0)
    
    if [ "$preset_count" -gt 0 ]; then
      for ((i=0; i<preset_count; i++)); do
        local preset_id=$(yq ".provides.presets[$i].id" "$bundle_file")
        local preset_version=$(yq ".provides.presets[$i].version" "$bundle_file")
        local preset_file="presets/$preset_id/preset.yml"
        
        if [ ! -f "$preset_file" ]; then
          log_error "  Bundle $bundle_id refere preset $preset_id, mas arquivo não existe: $preset_file"
          continue
        fi
        
        local actual_preset_version=$(yq '.preset.version' "$preset_file")
        
        if [ "$preset_version" != "$actual_preset_version" ]; then
          log_error "  Bundle $bundle_id (v$bundle_version) declara preset $preset_id v$preset_version, mas preset.yml tem v$actual_preset_version"
        else
          log_ok "    $preset_id v$preset_version ✓"
        fi
      done
    fi
  done
}

# ============================================================================
# 2. Validar que os catalogs (bundles/catalog.json e presets/catalog.json) 
#    refletem as versões dos respectivos arquivos YAML
# ============================================================================
validate_catalog_consistency() {
  log_info "Validando sincronização entre YAML e catalogs JSON..."
  
  # Bundles
  local bundles=(bundles/*/bundle.yml)
  for bundle_file in "${bundles[@]}"; do
    [ -f "$bundle_file" ] || continue
    
    local bundle_id=$(yq '.bundle.id' "$bundle_file")
    local bundle_version=$(yq '.bundle.version' "$bundle_file")
    local catalog_version=$(jq -r ".bundles[\"$bundle_id\"].version" bundles/catalog.json 2>/dev/null || echo "NOTFOUND")
    
    if [ "$catalog_version" != "$bundle_version" ]; then
      log_error "  Bundle catalog: $bundle_id tem v$catalog_version em catalog.json, mas v$bundle_version em bundle.yml"
    else
      log_ok "    $bundle_id v$bundle_version (catalog) ✓"
    fi
  done
  
  # Presets
  local presets=(presets/*/preset.yml)
  for preset_file in "${presets[@]}"; do
    [ -f "$preset_file" ] || continue
    
    local preset_id=$(yq '.preset.id' "$preset_file")
    local preset_version=$(yq '.preset.version' "$preset_file")
    local catalog_version=$(jq -r ".presets[\"$preset_id\"].version" presets/catalog.json 2>/dev/null || echo "NOTFOUND")
    
    if [ "$catalog_version" != "$preset_version" ]; then
      log_error "  Preset catalog: $preset_id tem v$catalog_version em catalog.json, mas v$preset_version em preset.yml"
    else
      log_ok "    $preset_id v$preset_version (catalog) ✓"
    fi
  done
}

# ============================================================================
# 3. Validar URLs de download no catalog
# ============================================================================
validate_download_urls() {
  log_info "Validando URLs de download nos catalogs..."
  
  # Bundles
  local bundles=(bundles/*/bundle.yml)
  for bundle_file in "${bundles[@]}"; do
    [ -f "$bundle_file" ] || continue
    
    local bundle_id=$(yq '.bundle.id' "$bundle_file")
    local bundle_version=$(yq '.bundle.version' "$bundle_file")
    local download_url=$(jq -r ".bundles[\"$bundle_id\"].download_url" bundles/catalog.json 2>/dev/null || echo "NOTFOUND")
    
    if [[ "$download_url" != *"$bundle_version"* ]]; then
      log_error "  Bundle $bundle_id: download_url não contém versão v$bundle_version"
      log_error "    URL atual: $download_url"
    else
      log_ok "    $bundle_id download_url ✓"
    fi
  done
  
  # Presets
  local presets=(presets/*/preset.yml)
  for preset_file in "${presets[@]}"; do
    [ -f "$preset_file" ] || continue
    
    local preset_id=$(yq '.preset.id' "$preset_file")
    local preset_version=$(yq '.preset.version' "$preset_file")
    local download_url=$(jq -r ".presets[\"$preset_id\"].download_url" presets/catalog.json 2>/dev/null || echo "NOTFOUND")
    
    if [[ "$download_url" != *"$preset_version"* ]]; then
      log_error "  Preset $preset_id: download_url não contém versão v$preset_version"
      log_error "    URL atual: $download_url"
    else
      log_ok "    $preset_id download_url ✓"
    fi
  done
}

# ============================================================================
# 4. Validar que a tag git corresponde à versão do bundle principal
# ============================================================================
validate_git_tag() {
  log_info "Validando consistência de tag git..."
  
  # A versão "principal" é a do bundle nimbus-code-project-bundle (convenção)
  local main_bundle="bundles/nimbus-code-project-bundle/bundle.yml"
  if [ -f "$main_bundle" ]; then
    local bundle_version=$(yq '.bundle.version' "$main_bundle")
    local current_git_tag=$(git describe --tags 2>/dev/null || echo "NOTAG")
    local expected_git_tag="v$bundle_version"
    
    # Se há tag, verificar se bate com a versão do bundle
    if [ "$current_git_tag" != "NOTAG" ]; then
      if [ "$current_git_tag" != "$expected_git_tag" ]; then
        log_warn "  Git tag atual: $current_git_tag, esperado: $expected_git_tag"
        log_warn "  Para sincronizar, rode: git tag -d $current_git_tag && git tag $expected_git_tag && git push origin $expected_git_tag"
      else
        log_ok "  Git tag: $current_git_tag ✓"
      fi
    else
      log_info "  Nenhuma tag git encontrada. Esperada: $expected_git_tag"
    fi
  fi
}

# ============================================================================
# 5. Validar que os catalogs têm timestamp atualizado (if --fix, atualiza)
# ============================================================================
validate_catalog_timestamps() {
  log_info "Validando timestamps dos catalogs..."
  
  local now=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
  
  for catalog in bundles/catalog.json presets/catalog.json; do
    local ts=$(jq -r '.updated_at' "$catalog")
    
    # Verificar se o timestamp é razoavelmente recente (mesma hora)
    if [[ "$ts" == *"2026-08-23"* ]]; then
      log_ok "  $catalog timestamp recente ✓"
    else
      log_warn "  $catalog timestamp pode estar desatualizado: $ts"
      if [ "$FIX_MODE" == "--fix" ]; then
        jq ".updated_at = \"$now\"" "$catalog" > "${catalog}.tmp" && mv "${catalog}.tmp" "$catalog"
        log_info "    [FIXED] Timestamp atualizado para $now"
      fi
    fi
  done
}

# ============================================================================
# MAIN
# ============================================================================
main() {
  log_info "========================================="
  log_info "Validador de Versões - Nimbus Code"
  log_info "========================================="
  
  # Verificar dependências
  if ! command -v yq &> /dev/null; then
    log_error "yq não encontrado. Instale com: brew install yq (ou apt-get install yq)"
    exit 1
  fi
  
  if ! command -v jq &> /dev/null; then
    log_error "jq não encontrado. Instale com: brew install jq (ou apt-get install jq)"
    exit 1
  fi
  
  validate_bundle_preset_consistency
  validate_catalog_consistency
  validate_download_urls
  validate_git_tag
  validate_catalog_timestamps
  
  log_info "========================================="
  if [ $ERRORS -eq 0 ]; then
    log_ok "Todas as validações passaram! ($WARNINGS aviso(s))"
    exit 0
  else
    log_error "Validação falhou com $ERRORS erro(s) e $WARNINGS aviso(s)"
    exit 1
  fi
}

main
