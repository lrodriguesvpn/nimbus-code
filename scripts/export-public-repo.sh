#!/usr/bin/env bash
# ==============================================================================
# Script: export-public-repo.sh
# Descrição: Exporta e empacota os componentes públicos (Extensão VS Code, Servidor MCP,
#            Documentação e Licença BSL 1.1) para publicação no GitHub Público (github.com),
#            com atribuição oficial da Venha Pra Nuvem (VPN).
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_DIR="${1:-$REPO_ROOT/dist/nimbus-code-public}"

echo "============================================================"
echo "🚀 Exportando Nimbus Code — Distribuição Pública (GitHub)"
echo "   Origem: $REPO_ROOT"
echo "   Destino: $TARGET_DIR"
echo "============================================================"

# Limpar e criar diretório de destino
rm -rf "$TARGET_DIR"
mkdir -p "$TARGET_DIR"/{extensions/vscode,servers/mcp-nimbus,docs}

echo "📦 1. Copiando Extensão VS Code / Multi-IDE..."
cp -R "$REPO_ROOT/extensions/vscode"/* "$TARGET_DIR/extensions/vscode/" 2>/dev/null || cp -R "$REPO_ROOT/extensions/vscode" "$TARGET_DIR/extensions/"
# Remover artefatos locais desnecessários
rm -rf "$TARGET_DIR/extensions/vscode/node_modules" "$TARGET_DIR/extensions/vscode/.vsce"

echo "🔌 2. Copiando Servidor MCP Universal..."
cp -R "$REPO_ROOT/servers/mcp-nimbus"/* "$TARGET_DIR/servers/mcp-nimbus/" 2>/dev/null || cp -R "$REPO_ROOT/servers/mcp-nimbus" "$TARGET_DIR/servers/"
rm -rf "$TARGET_DIR/servers/mcp-nimbus/node_modules"

echo "📄 3. Gerando Licença BSL 1.1 Pública..."
cat << 'EOF' > "$TARGET_DIR/LICENSE"
Business Source License 1.1 (BSL 1.1)

Parameters:
Licensor: Venha Pra Nuvem (VPN) - Tecnologia e Consultoria em Nuvem
Licensed Work: Nimbus Code Extension and MCP Server
Change Date: 2030-01-01
Change License: Apache License, Version 2.0

TERMS AND CONDITIONS

1. Grant of License.
Licensor grants you a non-exclusive, non-transferable license to copy, modify,
and use the Licensed Work for non-commercial, development, evaluation, and test purposes.

2. Production Use.
Use of the Licensed Work in production environments or for commercial distribution
requires a valid Commercial Entitlement Agreement from Venha Pra Nuvem (VPN).

3. Conversion to Open Source.
On the Change Date, the Licensed Work converts automatically to the Change License.
EOF

echo "📝 4. Gerando README Público Oficial..."
cat << 'EOF' > "$TARGET_DIR/README.md"
<div align="center">

# 🚀 Nimbus Code

### AI Agentic Spec-Driven Development (SDD) Framework & Multi-IDE Tools
**Desenvolvido e Mantido por [Venha Pra Nuvem (VPN)](https://venhapranuven.com.br)**

[![License: BSL 1.1](https://img.shields.io/badge/License-BSL%201.1-blue.svg)](LICENSE)
[![VS Code Extension](https://img.shields.io/badge/VS%20Code-Extension%20Available-brightgreen.svg)](extensions/vscode)
[![Model Context Protocol](https://img.shields.io/badge/MCP-Universal%20Server-purple.svg)](servers/mcp-nimbus)
[![BYO-LLM](https://img.shields.io/badge/AI%20Cost-BYO--LLM%20(Zero%20Token%20Cost)-orange.svg)](#byo-llm-architecture)

</div>

---

## 🌟 O que é o Nimbus Code?

O **Nimbus Code** é um framework de engenharia de software orientado a agentes de inteligência artificial construído sobre o paradigma de **Spec-Driven Development (SDD)**. 

Ele orquestra um esquadrão de agentes especializados (`@nimbus`, `/nc-spec`, `/nc-arch`, `/nc-qa`, `/nc-builder`, `/nc-critic`, `/nc-shield`) para transformar intenções de negócio em software testado, seguro e governado.

---

## 🏛️ Filosofia Open-Core & BYO-LLM

1. **Zero Custo de Tokens (BYO-LLM):** Você traz seu próprio provedor de IA (GitHub Copilot corporativo, chaves Claude/OpenAI, ou modelos locais). O Nimbus Code nunca intermedia suas chaves de API nem armazena seu código.
2. **Uso Local Gratuito:** O uso para desenvolvimento individual, testes e avaliação é totalmente gratuito sob a licença **BSL 1.1**.
3. **Enterprise & Squad VPN:** Para governança centralizada, esteiras de conformidade LGPD/DevSecOps e o modelo **Sanfona de Dev (Staff Augmentation com Nimbus Code)**, [entre em contato com a Venha Pra Nuvem](https://venhapranuven.com.br).

---

## 📦 Componentes Públicos neste Repositório

* **[`extensions/vscode`](extensions/vscode):** Extensão para VS Code, Cursor e Antigravity com menus do esquadrão, Command Palette e participante de chat nativo (`@nimbus`).
* **[`servers/mcp-nimbus`](servers/mcp-nimbus):** Servidor universal compatível com o [Model Context Protocol (MCP)](https://modelcontextprotocol.io), permitindo o uso do Nimbus Code no Claude Code, Cursor e IDEs agenticas.

---

## 🚀 Como Iniciar

### 1. Extensão VS Code
Abra a pasta `extensions/vscode`, compile e empacote:
```bash
cd extensions/vscode
npm install
npm run compile
npx @vscode/vsce package
code --install-extension nimbus-code-extension-0.1.0.vsix
```

### 2. Servidor MCP (Claude Code / Cursor / Windsurf)
Configure no seu arquivo de MCP (ex: `~/.claude/mcp.json` ou `.vscode/mcp.json`):
```json
{
  "mcpServers": {
    "nimbus-code": {
      "command": "node",
      "args": ["/caminho/para/servers/mcp-nimbus/dist/index.js"]
    }
  }
}
```

---

## 🏢 Sobre a Venha Pra Nuvem (VPN)

A **Venha Pra Nuvem** é especialista em modernização de aplicações, arquiteturas em nuvem resilientes e aceleração de engenharia orientada a IA.

- **Website:** [venhapranuven.com.br](https://venhapranuven.com.br)
- **Licenciamento Comercial:** contato@venhapranuven.com.br
EOF

chmod +x "$TARGET_DIR"/*.sh 2>/dev/null || true

echo "✅ Exportação concluída com sucesso em: $TARGET_DIR"
echo ""
echo "📌 Para publicar no seu GitHub público (github.com):"
echo "   1. Crie o repositório no github.com (ex: nimbus-code)"
echo "   2. cd $TARGET_DIR"
echo "   3. git init && git add . && git commit -m 'feat: initial public release of Nimbus Code (VPN)'"
echo "   4. git branch -M main"
echo "   5. git remote add origin https://github.com/<SEU-USUARIO>/nimbus-code.git"
echo "   6. git push -u origin main"
echo "============================================================"
