#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# setup-dev-environment.sh
#
# postCreateCommand do devcontainer de referência Nimbus-Code
# (.devcontainer/devcontainer.json). Instala as dependências específicas deste
# template que não vêm cobertas pelas features do devcontainer (python, node,
# github-cli), deixando o Codespace pronto para rodar os scripts de
# scripts/*.sh e os workflows locais (validate-manifests.yml, graph-guard.yml)
# sem nenhum passo manual adicional (AC-1 de
# specs/009-codespaces-dev-planning/spec.md).
#
# Idempotente: seguro para rodar mais de uma vez (ex.: rebuild do Codespace).
###############################################################################

echo "==> Nimbus-Code: configurando ambiente de desenvolvimento (Codespaces)..."

# ── Dependências de sistema (shellcheck, jq) ────────────────────────────────
if command -v apt-get >/dev/null 2>&1; then
  echo "==> Instalando shellcheck e jq via apt-get..."
  sudo apt-get update -y
  sudo apt-get install -y --no-install-recommends shellcheck jq
else
  echo "==> apt-get indisponível — pulando instalação de shellcheck/jq (ambiente não-Debian/Ubuntu)."
fi

# ── Dependências Python usadas pelos workflows/scripts deste template ──────
if command -v python3 >/dev/null 2>&1; then
  echo "==> Instalando dependências Python (pyyaml) usadas por validate-manifests.yml..."
  python3 -m pip install --user --quiet pyyaml
else
  echo "::warning::python3 não encontrado no PATH — verifique a feature 'python' do devcontainer."
fi

# ── Sanidade do toolchain esperado (AC-1) ───────────────────────────────────
echo "==> Verificando toolchain disponível no PATH..."
for bin in bash python3 node gh jq shellcheck git; do
  if command -v "$bin" >/dev/null 2>&1; then
    printf '  ✓ %s: %s\n' "$bin" "$("$bin" --version 2>&1 | head -n1)"
  else
    printf '  ✗ %s: NÃO ENCONTRADO\n' "$bin"
  fi
done

echo "==> Ambiente de desenvolvimento Nimbus-Code pronto."
