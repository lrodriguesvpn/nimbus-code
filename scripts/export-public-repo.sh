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
mkdir -p "$TARGET_DIR"/{extensions/vscode,servers/mcp-nimbus,presets/nimbus-code-community,docs}

echo "📦 1. Copiando Extensão VS Code / Multi-IDE..."
cp -R "$REPO_ROOT/extensions/vscode"/* "$TARGET_DIR/extensions/vscode/" 2>/dev/null || cp -R "$REPO_ROOT/extensions/vscode" "$TARGET_DIR/extensions/"
# Remover artefatos locais desnecessários
rm -rf "$TARGET_DIR/extensions/vscode/node_modules" "$TARGET_DIR/extensions/vscode/.vsce"

echo "🔌 2. Copiando Servidor MCP Universal..."
cp -R "$REPO_ROOT/servers/mcp-nimbus"/* "$TARGET_DIR/servers/mcp-nimbus/" 2>/dev/null || cp -R "$REPO_ROOT/servers/mcp-nimbus" "$TARGET_DIR/servers/"
rm -rf "$TARGET_DIR/servers/mcp-nimbus/node_modules"

echo "🧩 3. Copiando Preset Comunitário (Scaffold SDD)..."
cp -R "$REPO_ROOT/presets/nimbus-code-community"/* "$TARGET_DIR/presets/nimbus-code-community/" 2>/dev/null || true

echo "📄 4. Gerando Licença BSL 1.1 Pública..."
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

echo "📝 5. Gerando README Público Oficial com Matriz Community vs Enterprise..."
cat << 'EOF' > "$TARGET_DIR/README.md"
<div align="center">

# 🚀 Nimbus Code

### AI Agentic Spec-Driven Development (SDD) Framework & Multi-IDE Tools
**Desenvolvido e Mantido por [Venha Pra Nuvem (VPN)](https://venhapranuvem.com.br)**

[![License: BSL 1.1](https://img.shields.io/badge/License-BSL%201.1-blue.svg)](LICENSE)
[![VS Code Extension](https://img.shields.io/badge/VS%20Code-Extension%20Available-brightgreen.svg)](extensions/vscode)
[![Model Context Protocol](https://img.shields.io/badge/MCP-Universal%20Server-purple.svg)](servers/mcp-nimbus)
[![BYO-LLM](https://img.shields.io/badge/AI%20Cost-BYO--LLM%20(Zero%20Token%20Cost)-orange.svg)](#byo-llm-architecture)

</div>

---

## 🌟 O que é o Nimbus Code?

O **Nimbus Code** é um framework de engenharia de software orientado a agentes de IA que implementa o ciclo completo de **Spec-Driven Development (SDD)**: da ideia bruta à entrega de código testado e auditado.

Distribuímos o framework em dois modelos:
1. **Nimbus Code Community (Lite)** — Gratuito sob licença **BSL 1.1** para desenvolvedores, avaliação e testes locais.
2. **Nimbus Code Enterprise (VPN Edition)** — Solução corporativa completa com governança S0–S4, squad de 18 especialistas, Harvest de código legado (*Brownfield*) e apoio de engenharia da **Venha Pra Nuvem**.

---

## ⚖️ Matriz Comparativa: Community vs Enterprise

| Capacidade / Funcionalidade | 🟢 Community (Lite) | 🏢 Enterprise (VPN) |
|---|:---:|:---:|
| **Modelo de Licença** | BSL 1.1 (Dev & Testes Gratuito) | Licença Corporativa / Consultoria VPN |
| **Extensão VS Code / Multi-IDE** | ✅ Inclusa | ✅ Inclusa |
| **Scaffold SDD (`spec`, `plan`, `tasks`)** | ✅ Templates Base | ✅ Avançado com BDD & SMART rígidos |
| **Orquestrador `@nimbus`** | ✅ Triagem Lite (Bug, Spec, Ideação) | ✅ Squad Completo de 18 Agentes Nativos |
| **Harness Engineering (Lições Aprendidas)** | ⚪ Local manual | 🌟 **Catálogo Central Corporativo da VPN** |
| **Harvest de Código Legado (Brownfield)** | ❌ Não incluso | 🌟 **Gateway & API de Harvest Automatizado** |
| **Catálogo de Reuso Multi-Repo** | ❌ Não incluso | 🌟 **Indexação Global de Padrões e ADRs** |
| **Governança RACI e DevSecOps Gate** | ⚪ Básico | 🌟 **Gates S0–S4 com Auditoria Criptográfica** |
| **Sanfona de Desenvolvimento (Time VPN)** | ❌ Apenas Comunidade | 🌟 **Engenheiros Especialistas sob Demanda** |

---

## 🏛️ Filosofia BYO-LLM (Bring Your Own LLM)

- **Zero Custo de Intermediação de Tokens:** Você utiliza seu próprio GitHub Copilot corporativo, chaves de API Claude/OpenAI ou modelos locais.
- **Privacidade Total:** Seu código nunca trafega por servidores intermediários do Nimbus Code.

---

## 🚀 Como Começar (Community Edition)

### 1. Extensão VS Code
Instale o pacote `.vsix` em `extensions/vscode` ou compile localmente:
```bash
cd extensions/vscode
npm install
npm run compile
npx @vscode/vsce package
code --install-extension nimbus-code-extension-0.1.0.vsix
```

### 2. Inicializar Repositório
No VS Code, abra a **Command Palette** (`Ctrl+Shift+P` ou `Cmd+Shift+P`) e execute:
> `Nimbus Code: Inicializar Repositório (Community / Enterprise)`

---

## 🏢 Desbloqueie o Nimbus Code Enterprise com a VPN

Precisa de aceleração de entrega, modernização de sistemas legados ou governança corporativa de IA?

- 🌾 **Harvest Brownfield:** Automatize a extração de regras de negócio de bases legadas e migrações para nuvem.
- 🛡️ **Harness Corporativo:** Compartilhe guardrails e lições aprendidas entre todos os times de desenvolvimento da empresa.
- 🪗 **Sanfona de Dev:** Expanda temporariamente sua capacidade de engenharia com os especialistas da Venha Pra Nuvem que dominam o framework.

👉 **Contato Comercial & Parcerias:** [venhapranuvem.com.br](https://venhapranuvem.com.br) | **E-mail:** contato@venhapranuvem.com.br
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
