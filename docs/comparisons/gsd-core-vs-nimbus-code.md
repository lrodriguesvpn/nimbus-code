# Análise Comparativa: GSD Core vs. Nimbus Code

Este documento apresenta uma análise técnica e arquitetural comparando o framework **GSD Core (`open-gsd/gsd-core`)** com a plataforma **Nimbus Code**.

---

## 1. Visão Geral

### GSD Core (`open-gsd/gsd-core`)
O GSD Core (*Get Sh\*t Done Core*) é um framework leve de **Context Engineering & Spec-Driven Development** cujo foco principal é mitigar a degradação de respostas do LLM (*context rot*) durante longas sessões de desenvolvimento. Seu loop operacional organiza a execução de tarefas de código em subagentes com contexto limpo (200k tokens por onda).

**Ciclo de 5 etapas do GSD Core:**
1. **Discuss**: captura decisões de implementação preliminares.
2. **Plan**: decompõe e verifica a viabilidade do plano no contexto.
3. **Execute**: executa planos em ondas paralelas com subagentes limpos.
4. **Verify**: inspeciona o que foi construído e gera planos de correção antes do aceite.
5. **Ship**: cria o PR, arquiva o estado da fase e prepara o próximo ciclo.

### Nimbus Code
O Nimbus Code é uma **plataforma completa de Engenharia Digital e Governança SDD (Spec-Driven Development)**, projetada para ambientes corporativos que exigem conformidade, segurança rigorosa (DevSecOps), rastreabilidade de negócio e controle financeiro de IA (FinOps).

---

## 2. Matriz Comparativa

| Dimensão | GSD Core (`open-gsd/gsd-core`) | Nimbus Code |
|---|---|---|
| **Foco Central** | **Higiene de Contexto**: isolamento de subagentes, prevenção de degradação e execução rápida no terminal. | **Governança Empresarial Full-Cycle**: da ideia de negócio (Camada 0/1) à entrega observável em produção (DevSecOps, DORA, FinOps). |
| **Escopo do Ciclo de Vida** | Começa na **implementação de código** (`Discuss` → `Ship`). Não cobre discovery de produto ou compliance. | **Ciclo Completo**: <br>• **Camada 0**: Idea Assessment (`/nc-assess-*`)<br>• **Camada 1**: Descoberta, Entrevista 4 Blocos, SMART e Governança (`/nc-intake`, `/nc-spec`, `/nc-critic`, `/nc-governor`)<br>• **Camada 2**: Arquitetura, QA e Segurança (`/nc-arch`, `/nc-qa`, `/nc-shield`)<br>• **Camada 3**: Construção Autônoma e SRE (`/nc-builder`, `/nc-telemetry`) |
| **Modelo de Esquadrão** | Papéis genéricos de runtime (executor / planner / verifier). | **14 Agentes Especializados (`/nc-*`)** com responsabilidades formais (RACI), permissões granulares de arquivos e regras estritas de isolamento. |
| **Governança & Segurança** | Não possui regras de compliance ou segurança corporativa. | **6 Controles Não-Negociáveis** (TLS, secrets em cofre, DR, branch protection, DevSecOps gates), classificação de risco **S0 a S4**, matriz de aprovação humana e auditoria. |
| **Topologia Brownfield & Multi-Repo** | Projetado para repositório único (monorepo ou repo isolado). | **Multi-repo & Bounded Contexts**, grafo de dependência cross-repo (`graph.yaml`), Repo Central vs Repos Satélite com sincronização e auditoria semanal. |
| **Rastreabilidade e Backlog** | Arquivos locais de estado (`STATE.md`, `CONTEXT.md`). | **Hierarquia Nativa GHE (Project V2 / Sub-issues)**: Epic → Feature → User Story → Task, mais sincronização bidirecional com Jira e Azure DevOps. |
| **Custo & Telemetria** | Não possui rastreamento financeiro nativo. | **spec-kit-cost integrado**: precificação real por LLM, medição de custo financeiro por fase, DORA metrics e logs JSON estruturados com correlation-id. |
| **Base / Motor Subjacente** | Motor próprio em TypeScript/Node.js CLI. | Baseado no ecossistema do **GitHub Spec Kit** + **Presets / Extensões Nimbus Code** multiplataforma (Copilot, Claude Code, Antigravity). |

---

## 3. Conclusão e Posicionamento

- **Onde convergem**: Ambos reconhecem que atribuir tarefas complexas diretamente a um único agente sem decomposição e isolamento de contexto gera alucinações e falhas de compilação.
- **Onde o Nimbus Code se diferencia**: Enquanto o GSD Core atua como um assistente tático de terminal para o desenvolvedor individual, o Nimbus Code é um sistema operacional corporativo que conecta requisitos de negócio, arquitetura multi-repo, segurança inegociável e métricas organizacionais ao fluxo autônomo dos agentes.
