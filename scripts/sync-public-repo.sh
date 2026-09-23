#!/usr/bin/env bash
# ==============================================================================
# Script: sync-public-repo.sh
# Descrição: Sincroniza os componentes públicos (Extensão VS Code, Servidor MCP, Docs)
#            com o repositório público do GitHub (github.com/lrodriguesvpn/nimbus-code).
#            Suporta branches 'develop' e 'main' e realiza verificação estrita de segredos.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DIST_DIR="$REPO_ROOT/dist/nimbus-code-public"
TARGET_REPO="https://github.com/lrodriguesvpn/nimbus-code.git"

TARGET_BRANCH="develop"
DO_PUSH=true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --branch)
      TARGET_BRANCH="$2"
      shift 2
      ;;
    --no-push)
      DO_PUSH=false
      shift
      ;;
    --repo)
      TARGET_REPO="$2"
      shift 2
      ;;
    *)
      echo "Argumento desconhecido: $1"
      exit 1
      ;;
  esac
done

echo "============================================================"
echo "🚀 Sincronizando Nimbus Code com Repositório Público"
echo "   Branch Destino: $TARGET_BRANCH"
echo "   Repositório:    $TARGET_REPO"
echo "============================================================"

# 1. Exportar arquivos limpos
bash "$SCRIPT_DIR/export-public-repo.sh" "$DIST_DIR"

# 2. Verificação de Segurança (Secret & Token Scan)
echo "🛡️ Executando varredura de segurança contra vazamento de segredos..."
if grep -riE "(ghp_|gho_|github_pat_|eyJ[a-zA-Z0-9_\-]{20,}|-----BEGIN (RSA|OPENSSH|PRIVATE) KEY-----)" "$DIST_DIR" > /tmp/secret_scan.log 2>&1; then
  echo "❌ ERRO: Segredo ou token detectado no pacote público!"
  cat /tmp/secret_scan.log
  exit 1
fi
echo "✅ Nenhum segredo ou chave privada encontrado."

if [ "$DO_PUSH" = true ]; then
  echo "📤 Preparando push para branch '$TARGET_BRANCH' do repositório público..."
  TEMP_CLONE_DIR=$(mktemp -d /tmp/nimbus-code-sync-XXXXXX)
  trap 'rm -rf "$TEMP_CLONE_DIR"' EXIT

  # Se houver token via env var (CI), usar autenticação com token
  if [ -n "${PUBLIC_REPO_TOKEN:-}" ]; then
    AUTH_REPO_URL="https://${PUBLIC_REPO_TOKEN}@github.com/lrodriguesvpn/nimbus-code.git"
  else
    AUTH_REPO_URL="$TARGET_REPO"
  fi

  git clone "$AUTH_REPO_URL" "$TEMP_CLONE_DIR"
  cd "$TEMP_CLONE_DIR"

  # Checar se a branch existe no remote
  if git ls-remote --heads origin "$TARGET_BRANCH" | grep -q "$TARGET_BRANCH"; then
    git checkout "$TARGET_BRANCH"
  else
    git checkout -b "$TARGET_BRANCH"
  fi

  # Sincronizar arquivos removendo o que foi deletado
  rsync -av --delete --exclude='.git' "$DIST_DIR/" "$TEMP_CLONE_DIR/"

  # Commit e Push se houver mudanças
  git config user.name "${GIT_USER_NAME:-Leonardo Rodrigues (VPN)}"
  git config user.email "${GIT_USER_EMAIL:-leonardo@venhapranuvem.com.br}"

  if [[ -n $(git status --porcelain) ]]; then
    git add -A
    git commit -m "sync(release): auto-sync from internal repository [$TARGET_BRANCH]"
    git push origin "$TARGET_BRANCH"
    echo "🎉 Sincronização e push concluídos com sucesso na branch '$TARGET_BRANCH'!"
  else
    echo "ℹ️ Nenhuma alteração detectada. Repositório público já está atualizado."
  fi
fi
