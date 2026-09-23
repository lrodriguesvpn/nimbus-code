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

👉 **Contato Comercial & Parcerias:** [venhapranuven.com.br](https://venhapranuven.com.br) | **E-mail:** contato@venhapranuven.com.br
