# Onde o TypeSafe/Jev pode reduzir custo no Nimbus Code

Este documento mapeia oportunidades concretas de uso do skill
[`typesafe-ai`](https://raw.githubusercontent.com/typesafe-ai/skills/main/skills/typesafe-ai/SKILL.md)
(modelo **Jev**, da **TypeSafe**) dentro do ciclo do **Nimbus Code**, e registra
uma correção importante de expectativa antes de qualquer decisão de adoção.

Ver também: [ADR 0010 — Adoção experimental do TypeSafe/Jev](../adr/0010-adocao-experimental-typesafe-jev-para-julgamentos-tipados.md).

---

## ⚠️ Correção de expectativa: Jev **não gera código**

A documentação oficial é explícita sobre isso
([Jev with coding agents](https://docs.typesafe.ai/introduction/coding-agents.md)):

> "Jev is **not** a drop-in replacement for the LLM behind Claude Code, Cursor,
> ... Copilot ... . It does not generate text, write code, or hold a
> conversation."

O Jev é um **"System One model"**: recebe um *state* (texto/JSON) e perguntas
tipadas (`Choice`, `Score`, `Noul`) e devolve **respostas estruturadas com
probabilidade e confiança** — nunca texto livre, nunca diffs de código.

**Portanto, o Jev não substitui o Copilot/GitHub Enterprise Copilot como motor
de geração de código do `/nc-builder`.** O ganho de custo não vem de "gerar
código mais barato", e sim de **tirar do LLM de reasoning caro (que gera
código) todo julgamento estruturado que hoje é feito com um prompt genérico**
— roteamento, classificação, priorização, verificação binária — e devolver
essas decisões a um modelo especializado, mais rápido e mais barato.

O ganho real de custo no Nimbus Code aparece de duas formas:

1. **Menos chamadas ao modelo de reasoning para decisões que não precisam de
   reasoning** (ex.: "essa issue é P0 ou P2?", "essa PR toca segredos?").
2. **Menos iterações de geração de código**, porque o Jev filtra/valida
   ambiguidade e completude *antes* de disparar o passo caro de geração
   (ex.: barra `/nc-spec`/`/nc-builder` até a spec estar completa o
   suficiente, em vez de gerar código sobre uma spec ambígua e ter que
   refazer).

---

## Onde encaixa em cada camada do Nimbus Code

### Camada 0 — Ideação (`/nc-assess-*`)

| Agente | Julgamento hoje (LLM genérico) | Primitiva Jev sugerida | Ganho |
|---|---|---|---|
| `NC-Assess-Intake` | Classificar tipo/qualidade da ideia bruta recebida (texto, URL, issue) | `Choice` (tipo de fonte) + `Noul` ("a ideia tem contexto de negócio suficiente?") | Pré-triagem antes do agente de reasoning escrever `intake.md` |
| `NC-Assess-Decide` | Gate formal Go / Needs Clarification / Kill | `Choice` (Go / Clarify / Kill) com probabilidade por opção + `confidence` | Ver [confidence-gated routing](https://docs.typesafe.ai/patterns/confidence-routing.md): decisões de alta confiança seguem automaticamente, baixa confiança escala para humano — mantém a regra "S3/S4 sempre exige aprovação humana" intacta, só reduz o custo do *primeiro* veredito |

### Camada 1 — Descoberta & Especificação (`/nc-intake`, `/nc-spec`, `/nc-critic`, `/nc-governor`)

| Agente | Julgamento hoje (LLM genérico) | Primitiva Jev sugerida | Ganho |
|---|---|---|---|
| `NC-Intake` | Verificar se os 4 blocos obrigatórios (Negócio/Infra/Segurança/LGPD) estão presentes/ambíguos na entrevista | `Noul` por bloco ("este bloco cobre LGPD de forma clara?") | Complementa (não substitui) o validador determinístico já existente; barato o suficiente para rodar a cada resposta do usuário, não só no fechamento |
| `NC-Critic` | Apontar ambiguidades e termos vagos na spec | `Score` (0–3: claro → muito ambíguo) por seção da spec | Pré-rankeia quais seções merecem a auditoria cara do LLM de reasoning primeiro |
| `NC-Governor` | Classificar complexidade S0–S4 da tarefa | `Choice` (S0/S1/S2/S3/S4) com probabilidade | Primeira triagem automática de complexidade — exatamente o padrão de [confidence-gated routing](https://docs.typesafe.ai/patterns/confidence-routing.md) já compatível com a regra do preset ("nunca use modelo mais forte do que o necessário"); baixa confiança ainda escala para o agente decidir |

### Camada 2 — Arquitetura, Segurança e QA (`/nc-arch`, `/nc-shield`, `/nc-designer`, `/nc-qa`)

| Agente | Julgamento hoje (LLM genérico) | Primitiva Jev sugerida | Ganho |
|---|---|---|---|
| `NC-Shield` | Checar se o plano/PR toca segredos, PII, TLS, IaC não-Terraform etc. | `Noul` por controle não-negociável ("este plano introduz segredo em texto puro?") | Pré-varredura barata antes da auditoria completa de DevSecOps — não substitui o gate humano dos itens Não-Negociáveis |
| `NC-QA` | Priorizar/ordenar tasks por dependência e risco | `Score` (severidade/risco por task) | Ajuda a ordenar `tasks.md` com `[P]` de forma mais barata que pedir ao LLM para "pensar" a ordem inteira |
| `NC-Arch` / `NC-Designer` | — | *(baixo encaixe: decisões aqui são geração de artefato/design, não classificação — Jev hoje só aceita texto, sem imagem, então não serve para auditoria visual do `NC-Designer`)* | — |

### Camada 3 — Construção e Sustentação (`/nc-builder`, `/nc-telemetry`)

| Agente / Processo | Julgamento hoje (LLM genérico ou manual) | Primitiva Jev sugerida | Ganho |
|---|---|---|---|
| Triagem de labels/prioridade (`priority:P0-blocker`…`P3-low`, `agent:autonomous-ok`) | Hoje é manual ou via workflow simples | `Choice` (prioridade) + `Noul` ("elegível para `agent:autonomous-ok`?") | Ver [intent routing](https://docs.typesafe.ai/patterns/intent-routing.md) — mapeia diretamente na tabela de priorização já descrita nestas instruções do projeto |
| `NC-Telemetry` | Classificar anomalias/custo fora do esperado nos logs | `Score` (severidade do desvio DORA/custo) | Barato o bastante para rodar em todo fechamento de feature, não só sob demanda |
| Catálogos (`docs/reuse-catalog.yaml`, `harness-catalog.yaml`, `success-catalog.yaml`) | Busca textual/manual por tag | `Choice` entre entradas candidatas do catálogo | Pré-seleciona candidatos de reuso/harness antes do agente confirmar com reasoning — mantém a regra de nunca decidir sozinho, só acelera a triagem |

---

## Regras de uso (derivadas do ADR 0010)

- **Nunca em substituição a** `NC-Governor`/`NC-Shield` em decisões S3/S4 —
  essas continuam exigindo o modelo de reasoning padrão e aprovação humana
  explícita.
- **Sempre declarar no `plan.md`** (Architecture Decision Log) quando uma
  feature usar Jev, apontando para o ADR 0010.
- **Nenhum dado sensível (PII, segredos)** deve compor o `state` enviado ao
  Jev sem passar pelas mesmas regras de classificação de dados já vigentes.
- Jev aceita hoje apenas texto (strings, JSON, arrays de texto) — sem imagem,
  áudio ou vídeo — o que limita o uso em `NC-Designer` (auditoria visual).

## Referências

- [System One (conceito)](https://docs.typesafe.ai/concepts/system-one.md)
- [Jev with coding agents](https://docs.typesafe.ai/introduction/coding-agents.md)
- [Confidence-gated routing](https://docs.typesafe.ai/patterns/confidence-routing.md)
- [Intent routing](https://docs.typesafe.ai/patterns/intent-routing.md)
- [Primitivas: Choice, Score, Noul](https://docs.typesafe.ai/primitives.md)
