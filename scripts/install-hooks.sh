#!/bin/bash
#
# install-hooks.sh - Instala git hooks localmente
#
# Propósito:
#   - Instalar o hook de pré-commit para validação de versões
#   - Garantir que developers tenham proteção local contra desalinhamentos de versão
#
# Uso:
#   ./scripts/install-hooks.sh
#

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOKS_DIR="$(git rev-parse --git-dir)/hooks"

echo "📦 Instalando git hooks em: $HOOKS_DIR"

mkdir -p "$HOOKS_DIR"

# Criar pre-commit hook
cat > "$HOOKS_DIR/pre-commit" << 'EOF'
#!/bin/bash
#
# Pre-commit hook: validate-versions
# Garante que versões de bundles, presets e tags git permaneçam sincronizados
#

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if [ -x "$REPO_ROOT/scripts/validate-versions.sh" ]; then
  "$REPO_ROOT/scripts/validate-versions.sh"
  RESULT=$?
  
  if [ $RESULT -ne 0 ]; then
    echo ""
    echo "❌ Validação de versões falhou. Commit bloqueado."
    echo ""
    echo "Para corrigir timestamps automaticamente, rode:"
    echo "  ./scripts/validate-versions.sh --fix"
    echo ""
    echo "Para sincronizar a tag git com a versão do bundle, rode:"
    echo "  BUNDLE_VERSION=\$(yq '.bundle.version' bundles/nimbus-code-project-bundle/bundle.yml)"
    echo "  git tag -d v\$BUNDLE_VERSION 2>/dev/null || true"
    echo "  git tag v\$BUNDLE_VERSION"
    echo "  git push origin v\$BUNDLE_VERSION"
    exit 1
  fi
else
  echo "⚠️  Script de validação não encontrado em $REPO_ROOT/scripts/validate-versions.sh"
  echo "   Hook de pré-commit não pode rodar."
fi

exit 0
EOF

chmod +x "$HOOKS_DIR/pre-commit"

echo "✅ Hook de pré-commit instalado com sucesso!"
echo ""
echo "O hook vai validar a consistência de versões antes de cada commit."
echo "Para desabilitar temporariamente, use: git commit --no-verify"
