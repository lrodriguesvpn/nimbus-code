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
