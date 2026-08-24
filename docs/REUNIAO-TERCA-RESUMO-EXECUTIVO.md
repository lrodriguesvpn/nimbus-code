# NIMBUS CODE™ AI Delivery System — Resumo Executivo para o Time

**Data de envio:** Agosto/2026  
**Assunto:** 📌 Leitura obrigatória antes de terça-feira — NIMBUS CODE™ AI Delivery System

---

Pessoal,

Reservem um tempo até **terça-feira** para ler os documentos listados abaixo.
Teremos uma reunião para alinharmos a adoção do **NIMBUS CODE™ AI Delivery System**
e quero que todos cheguem com o contexto completo.

---

## O que é o NIMBUS CODE™ AI Delivery System

O **NIMBUS CODE™** é o sistema de entrega de software com IA adotado pela Venha Pra Nuvem.
Ele padroniza como projetos são criados, especificados, planejados, implementados e governados —
usando agentes de IA (GitHub Copilot) como co-autores, sem abrir mão de qualidade, segurança
e rastreabilidade.

O ciclo de trabalho segue 5 etapas operacionais:

```
specify → plan → tasks → implement → converge
```

Cada etapa produz artefatos vivos (`constitution.md`, `plan.md`, `tasks.md`) que registram
decisões, riscos e histórico de forma rastreável no Git.

---

## Os 2 Presets — qual usar em cada projeto

| Preset | Para qual tipo de repositório | Resumo |
|---|---|---|
| **`nimbus-code-standards`** | Projetos de software (features, APIs, apps) | Injeta padrões corporativos não-negociáveis: princípios de segurança, IaC, escala de complexidade S0–S4, grafo de módulos obrigatório, Security/DevSecOps Gate e Architecture Decision Log. Tudo de forma aditiva — nada do Nimbus Code nativo é removido. |
| **`nimbus-code-platform-standards`** | Repositórios de infraestrutura/ambiente real de cliente (cloud, M365, Azure, D365, legado) | Governa repositórios que **nunca** aplicam mudanças diretamente no ambiente — apenas documentam, inventariam e reconciliam estado. Pipeline de 5 fases: `discovery → imported → plan_diff_zero → landing_zone_generated → managed`. Suporta multi-nuvem (Azure/AWS/GCP/GWS/M365/D365) e sistemas legados. |

> ⚠️ **Regra simples:** um repositório usa **um dos dois presets — nunca os dois**.
> Software = `nimbus-code-standards`. Plataforma/cliente = `nimbus-code-platform-standards`.

---

## Bundle completo

Os dois presets fazem parte do **`nimbus-code-project-bundle`**, que inclui também:

- 🔌 **Extensão** `nimbus-code-backlog-sync` — sincronização automática com JIRA/Azure DevOps
- 🔁 **Workflow** `nimbus-code-full-cycle` — ciclo SDD completo com gate de DevSecOps entre plan e tasks
- 🤖 **Auto-assign** do Copilot Coding Agent via label `agent:autonomous-ok`
- 📊 **GitHub Project V2** criado automaticamente com views de board, prioridade e P0-blocker
- 💰 **Campos de custo real** (Horas Humanas + Oportunidade D365) para modelo híbrido agente + humano

Bootstrap em um único comando:

```bash
curl -fsSL https://raw.venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/refs/heads/main/bootstrap.sh | bash
```

---

## 📚 Os 5 documentos que você DEVE ler antes de terça

| # | Documento | O que você vai aprender |
|---|---|---|
| 1 | [**README principal**](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/blob/main/README.md) | Visão geral do sistema, componentes e como tudo se encaixa |
| 2 | [**Guia do Desenvolvedor**](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/blob/main/docs/developer-guide.md) | Como usar o Nimbus Code no dia a dia — greenfield, brownfield e importar card do Azure DevOps/JIRA |
| 3 | [**Boas Práticas Brownfield**](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/blob/main/docs/brownfield-best-practices.md) | Como adotar o Nimbus Code em repositórios existentes sem quebrar nada |
| 4 | [**Qualidade e Observabilidade de IA**](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/blob/main/docs/ai-code-quality-and-observability.md) | Como o PMO acompanha qualidade, custo real e métricas DORA |
| 5 | [**Taxonomia de Labels e Dev Autônomo**](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/blob/main/docs/label-taxonomy-and-autonomous-dev.md) | Como priorizar issues, acionar o Copilot agent automaticamente e evitar conflito com automações nativas do GitHub |

---

**Nos vemos na terça.** Venham preparados para discutir qual preset cada projeto ativo
deve usar e como faremos o bootstrap dos repositórios existentes.

Qualquer dúvida, respondam antes da reunião.

---

*Repositório base do sistema:*  
[https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template)
