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

# 🚀 Nimbus Code (Community Lite Edition)

### AI Agentic Spec-Driven Development (SDD) Framework & Multi-IDE Tools
**Desenvolvido e Mantido por [Venha Pra Nuvem (VPN)](https://venhapranuvem.com.br)**

[![License: BSL 1.1](https://img.shields.io/badge/License-BSL%201.1-blue.svg)](LICENSE)
[![VS Code Extension](https://img.shields.io/badge/VS%20Code-Extension%20Available-brightgreen.svg)](extensions/vscode)
[![Model Context Protocol](https://img.shields.io/badge/MCP-Universal%20Server-purple.svg)](servers/mcp-nimbus)
[![BYO-LLM](https://img.shields.io/badge/AI%20Cost-BYO--LLM%20(Zero%20Token%20Cost)-orange.svg)](#byo-llm-architecture)
[![Enterprise](https://img.shields.io/badge/Enterprise-VPN%20Full%20Edition-gold.svg)](#-nimbus-code-enterprise-vpn-edition--o-poder-completo)

</div>

---

## 📌 Dois Produtos, Uma Visão de Engenharia de IA

O **Nimbus Code** é estruturado estrategicamente em duas versões para atender desde o desenvolvedor individual até as maiores operações de engenharia corporativa:

1. 🟢 **Nimbus Code Community (Lite)** *(Disponível neste repositório)*:
   - Pacote público aberto sob licença **BSL 1.1** para desenvolvedores individuais, testes, ideação e avaliação local.
   - Fornece o scaffold base de Spec-Driven Development (SDD), orquestrador de triagem unificado `@nimbus` e ferramentas para VS Code e servidores MCP.
   - **Zero Custo de Intermediação (BYO-LLM):** Conecta diretamente ao seu GitHub Copilot ou chaves de API sem retenção de dados ou custos de terceiros.

2. 🏢 **Nimbus Code Enterprise (Full Edition)** *(Contratação Corporativa Venha Pra Nuvem)*:
   - A plataforma corporativa completa com **18 Agentes Autônomos Especializados**, governança formal de complexidade (S0–S4), auditoria criptográfica de especificações, gates DevSecOps/LGPD, Observabilidade DORA/OpenTelemetry e infraestrutura avançada de **Harness** e **Harvest**.

---

## ⚖️ Matriz Comparativa: Community (Lite) vs Enterprise (VPN Full)

| Dimensão / Capacidade | 🟢 Nimbus Code Community (Lite) | 🏢 Nimbus Code Enterprise (Full VPN) |
|---|:---:|:---:|
| **Finalidade & Licença** | BSL 1.1 (Desenvolvimento e Testes Locais) | Licença Comercial Corporativa + Suporte VPN |
| **Extensão VS Code / Multi-IDE** | ✅ Interface Lite com Triagem | ✅ Suporte Completo a Workflows Corporativos |
| **Servidor MCP Universal** | ✅ Comandos Base SDD | ✅ Conexão a Bancos de Dados, Grafos e CI/CD |
| **Templates de SDD** | ✅ Base (`spec`, `plan`, `tasks`) | ✅ Templates Rígidos SMART + BDD + Gates Formais |
| **Esquadrão de Agentes de IA** | ⚪ Orquestrador de Triagem `@nimbus` | 🌟 **18 Agentes Especialistas Nativos** (Arquiteto, Security, QA, Builder, etc.) |
| **Harness Engineering (Lições)** | ⚪ Arquivo local para anotações manuais | 🌟 **Catálogo Central Corporativo com Centenas de Guardrails Anti-Erro** |
| **Harvest de Código Legado (Brownfield)**| ❌ Não incluso | 🌟 **API & Engine de Extração Automática de Regras de Negócio e Padrões** |
| **Catálogo de Reuso Multi-Repo** | ❌ Não incluso | 🌟 **Indexação Global de Componentes e Decisões de Arquitetura (ADRs)** |
| **Governança & Gates DevSecOps** | ⚪ Básico | 🌟 **Gates S0–S4, Rastreabilidade SHA-256 e LGPD Obrigatório** |
| **Observabilidade & FinOps de IA** | ⚪ Não incluso | 🌟 **Métricas DORA, Telemetria OpenTelemetry e Custo Real de Tokens** |
| **Sanfona de Engenharia (Squad VPN)** | ❌ Apenas Suporte Comunitário | 🌟 **Engenheiros e Arquitetos Especialistas Alocados sob Demanda** |

---

## 🌟 O que o Nimbus Code Enterprise agrega à sua Organização?

Em ambientes de missão crítica, a versão **Enterprise** do Nimbus Code desbloqueia capacidades estratégicas de alto impacto:

### 1. 🌾 Harvest Brownfield Automatizado
Uma engine inteligente capaz de analisar grandes bases de código legadas (monólitos, serviços legados) e extrair automaticamente especificações formais, diagramas de arquitetura e inventários de regras de negócio, reduzindo em até 70% o tempo de modernização para a nuvem.

### 2. 🛡️ Harness Engineering Centralizado
Um repositório dinâmico de lições aprendidas corporativas. Quando um bug ou falha arquitetural é detectado e mitigado em um squad, o conhecimento é indexado e todos os 18 agentes previnem que o mesmo erro seja repetido em qualquer outro projeto da organização.

### 3. 🪗 Sanfona de Desenvolvimento (Capacidade Elástica VPN)
O modelo híbrido pioneiro da **Venha Pra Nuvem**: sua empresa utiliza o mesmo framework que nossos especialistas. Caso precise acelerar entregas, absorver picos de demanda ou arquitetar migrações complexas, o time de engenharia da VPN entra diretamente no seu fluxo de trabalho sem fricção de onboarding.

---

## 🚀 Primeiros Passos com o Nimbus Code Community (Lite)

### 1. Instalação da Extensão VS Code
Você pode instalar a extensão compilando o código fonte disponível em `extensions/vscode`:
```bash
cd extensions/vscode
npm install
npm run compile
npx @vscode/vsce package
code --install-extension nimbus-code-extension-0.1.0.vsix
```

### 2. Inicialização do seu Projeto
Abra o seu repositório no VS Code, abra a **Command Palette** (`Ctrl+Shift+P` ou `Cmd+Shift+P`) e digite:
> `Nimbus Code: Inicializar Repositório (Community / Enterprise)`

A extensão detectará automaticamente seu ambiente e configurará a estrutura de pastas `.specify/` e templates comunitários.

---

## 🤝 Conecte-se com a Venha Pra Nuvem (VPN)

Pronto para transformar sua engenharia com o ciclo completo do **Nimbus Code Enterprise** ou precisa de apoio em desenvolvimento ágil e nuvem?

- 🌐 **Site Oficial:** [https://venhapranuvem.com.br](https://venhapranuvem.com.br)
- ✉️ **Contato Comercial:** [contato@venhapranuvem.com.br](mailto:contato@venhapranuvem.com.br)
- 🏢 **Venha Pra Nuvem (VPN)** — Soluções em Nuvem, Engenharia de Software e IA Generativa.
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
