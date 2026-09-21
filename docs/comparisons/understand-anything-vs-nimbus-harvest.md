# Análise Comparativa: Understand-Anything vs. Harvest / Catálogo de Reuso (Nimbus Code)

Este documento apresenta uma análise comparativa entre o projeto **Understand-Anything (`Egonex-AI/Understand-Anything`)** e a ferramenta **Harvest (`scripts/harvest-patterns.sh`) / Catálogo de Reuso (`docs/reuse-catalog.yaml`)** do **Nimbus Code**.

---

## 1. Visão Geral

### Understand-Anything (`Egonex-AI/Understand-Anything`)
O Understand-Anything é uma ferramenta voltada para a **compreensão e exploração visual de código legado ou desconhecido**. Utiliza análise estática (AST) e LLMs para converter bases de código em grafos conceituais interativos navegáveis pelo navegador ("*graphs that teach > graphs that impress*").

**Focos principais:**
- Construção de grafos de dependência e relacionamentos entre componentes em tempo real.
- Interface visual interativa para desenvolvedores explorarem código complexo durante o onboarding.
- Geração de explicações contextuais baseadas em nós do grafo.

### Harvest & Catálogo de Reuso (Nimbus Code)
O mecanismo de **Harvest** (`scripts/harvest-patterns.sh`) do Nimbus Code é uma esteira de **mineração e catalogação de padrões arquiteturais e técnicos reaproveitáveis** em projetos corporativos. Ele alimenta o `docs/reuse-catalog.yaml` e as seções de design do `plan.md`.

**Focos principais:**
- **Mineração On-Demand de Padrões**: extração de esqueletos semânticos estruturais (AST de classes, métodos e assinaturas) sem envio de corpo de código, regras de negócio ou segredos.
- **FinOps & Economia de Tokens**: substituição de explicações redundantes por referências via ponteiro nos prompts de planejamento arquitetural (`/nc-arch` e `/speckit-plan`).
- **Governança Multi-Repo**: mapeamento de componentes por Bounded Contexts em topologias corporativas.

---

## 2. Matriz Comparativa

| Dimensão | Understand-Anything | Nimbus Harvest / Catálogo de Reuso |
|---|---|---|
| **Objetivo Primário** | **Visualização e Onboarding Humano**: transformar código em grafos interativos explicativos para desenvolvedores humanos. | **Mineração de Reuso e Governança de IA**: extrair componentes técnicos e padrões para reutilização estruturada por agentes e humanos. |
| **Público-Alvo Principal** | Desenvolvedores explorando e aprendendo sobre uma nova base de código. | Agentes de IA (`/nc-arch`, `/nc-builder`) e arquitetos corporativos planejando novas features. |
| **Modo de Operação** | Aplicação interativa com interface Web e visualização de grafos. | Script CLI on-demand (`scripts/harvest-patterns.sh`) integrado ao versionamento Git e arquivos Markdown/YAML. |
| **Proteção de Dados & Sigilo** | Pode enviar trechos substanciais de código para o LLM gerar as explicações dos nós. | **Extração Restrita de Assinaturas (Sem PII/Segredos)**: extrai apenas nomes de classes, anotações de framework e assinaturas públicas; nunca envia corpos de métodos ou credenciais. |
| **Impacto em Tokens / FinOps** | Consome tokens para gerar resumos descritivos e ensinar o humano. | **Reduz o consumo de tokens**: evita que agentes gastem milhares de tokens reinventando arquiteturas ao apontar diretamente para tags do `docs/reuse-catalog.yaml`. |
| **Integração com Bounded Contexts** | Focado no repositório individual analisado. | Integrado com `docs/bounded-contexts.yaml` e `specs/<feature>/graph.yaml` para rastreamento multi-repositório. |

---

## 3. Conclusão e Oportunidades de Sinergia

- **Diferenciação essencial**: O **Understand-Anything** prioriza a *experiência humana de aprendizado visual*, enquanto o **Nimbus Harvest** prioriza a *governança automatizada de reuso e economia de tokens em fluxos autônomos de IA*.
- **Potencial de Sinergia**: Em ecossistemas corporativos complexos, ferramentas como o Understand-Anything podem ser utilizadas na etapa de descoberta e inspeção humana preliminar, enquanto o Nimbus Harvest consolida os padrões identificados no catálogo oficial de engenharia do repositório.
