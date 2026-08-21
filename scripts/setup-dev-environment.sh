#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# setup-dev-environment.sh
#
# postCreateCommand do devcontainer de referência Nimbus-Code
# (.devcontainer/devcontainer.json). Instala as dependências específicas deste
# template que não vêm cobertas pelas features do devcontainer (python, node,
# github-cli), deixando o Codespace pronto para rodar os scripts de
# scripts/*.sh e os workflows locais (validate-manifests.yml, graph-guard.yml,
# test-suite.yml) sem nenhum passo manual adicional (AC-1 de
# specs/009-codespaces-dev-planning/spec.md; instalação do bats-core para
# scripts/run-tests.sh adicionada por specs/013-governanca-testes-pr/).
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

# ── bats-core (suíte de testes mandatória — specs/013-governanca-testes-pr) ─
# Versão pinada (não 'latest' implícito) — ver docs/testing-policy.md, seção 8,
# e research.md da feature 013, Decisão 1.
BATS_VERSION="1.13.0"
if command -v npm >/dev/null 2>&1; then
  if command -v bats >/dev/null 2>&1 && bats --version | grep -q "Bats ${BATS_VERSION}"; then
    echo "==> bats ${BATS_VERSION} já instalado — pulando."
  else
    echo "==> Instalando bats-core ${BATS_VERSION} via npm (usado por scripts/run-tests.sh)..."
    npm install -g "bats@${BATS_VERSION}"
  fi
else
  echo "::warning::npm não encontrado no PATH — não foi possível instalar bats. Verifique a feature 'node' do devcontainer."
fi

# ── Sanidade do toolchain esperado (AC-1) ───────────────────────────────────
echo "==> Verificando toolchain disponível no PATH..."
for bin in bash python3 node gh jq shellcheck git bats; do
  if command -v "$bin" >/dev/null 2>&1; then
    printf '  ✓ %s: %s\n' "$bin" "$("$bin" --version 2>&1 | head -n1)"
  else
    printf '  ✗ %s: NÃO ENCONTRADO\n' "$bin"
  fi
done

echo "==> Ambiente de desenvolvimento Nimbus-Code pronto."
