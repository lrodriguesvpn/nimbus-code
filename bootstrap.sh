#!/usr/bin/env bash
# Bootstrap: aplica o bundle vpndev-project-bundle num repositório novo ou existente.
#
# Uso:
#   curl -fsSL https://raw.venha-pra-nuvem.ghe.com/venha-pra-nuvem/speckit-vpndev-standards/main/bootstrap.sh | bash
# ou, com o repo já clonado localmente:
#   ./bootstrap.sh --local /caminho/para/speckit-vpndev-standards
#
# Este script existe porque, hoje, o bundle ainda não está publicado num catálogo
# (specify preset/extension/workflow catalogs) — ver "Publicação e Catálogo" no
# README.md raiz. Enquanto isso, o bootstrap usa `--dev`/paths locais diretamente.
# Quando o catálogo estiver publicado, este script pode ser trocado por:
#   specify bundle install vpndev-project-bundle --integration copilot
set -euo pipefail

STANDARDS_REPO="https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/speckit-vpndev-standards"
LOCAL_PATH=""
INTEGRATION="${SPECKIT_INTEGRATION_DEFAULT:-copilot}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --local)
      LOCAL_PATH="$2"
      shift 2
      ;;
    --integration)
      INTEGRATION="$2"
      shift 2
      ;;
    *)
      echo "Argumento desconhecido: $1" >&2
      exit 1
      ;;
  esac
done

if ! command -v specify >/dev/null 2>&1; then
  echo "❌ 'specify' CLI não encontrado. Instale primeiro: https://github.com/github/spec-kit#-get-started" >&2
  exit 1
fi

WORKDIR="$(pwd)"

if [[ -z "$LOCAL_PATH" ]]; then
  TMP_CLONE="$(mktemp -d)"
  trap 'rm -rf "$TMP_CLONE"' EXIT
  echo "→ Clonando $STANDARDS_REPO..."
  git clone --depth 1 "$STANDARDS_REPO" "$TMP_CLONE" >/dev/null
  LOCAL_PATH="$TMP_CLONE"
fi

echo "→ Inicializando projeto Spec Kit em $WORKDIR (integração: $INTEGRATION)..."
specify init --here --integration "$INTEGRATION" --force

echo "→ Instalando preset vpndev-standards..."
specify preset add --dev "$LOCAL_PATH/presets/vpndev-standards" --priority 5 \
  || echo "  (preset já instalado — pulei; use 'specify preset remove vpndev-standards' antes para reinstalar)"

echo "→ Instalando extensão vpndev-backlog-sync..."
specify extension add --dev "$LOCAL_PATH/extensions/vpndev-backlog-sync" \
  || echo "  (extensão já instalada — pulei; use 'specify extension remove vpndev-backlog-sync' antes para reinstalar)"

echo "→ Instalando workflow vpndev-full-cycle..."
specify workflow add "$LOCAL_PATH/workflows/vpndev-full-cycle" \
  || echo "  (workflow já instalado — pulei; use 'specify workflow remove vpndev-full-cycle' antes para reinstalar)"

BUNDLE_VERSION="$(grep -A4 '^bundle:' "$LOCAL_PATH/bundles/vpndev-project-bundle/bundle.yml" | grep -E '^\s*version:' | head -1 | sed -E 's/.*"([0-9.]+)".*/\1/')"
echo ""
echo "✅ Bundle vpndev-project-bundle v${BUNDLE_VERSION} aplicado com sucesso."
echo "   Registre a versão instalada no README do projeto (ver seção 'Bundle VPN Dev' do template de README)."
