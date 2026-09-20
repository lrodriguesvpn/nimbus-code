# Research: Controle de Custos (Feature 010)

**Feature**: Controle de Custos  
**Phase**: 0 — Research & Clarifications  
**Date**: 2026-08-18

---

## Objective

Resolver todos os marcadores `NEEDS CLARIFICATION` da spec.md e levantar contexto técnico necessário para o design da Phase 1.

---

## NEEDS CLARIFICATION Resolutions

### FR-010: Custo de recursos de nuvem no MVP?

**Pergunta**: O custo de recursos de nuvem (compute, storage) entra no escopo desta fase ou é uma fase futura?

**Resolução**: **Fora do escopo do MVP.**

**Justificativa**:
- Integração com AWS Cost Explorer / Azure Cost Management eleva a complexidade para S4 (integração financeira crítica com sistema externo)
- S4 exige revisão humana obrigatória e label `complexity:S4` — o que aumentaria o lead time desta feature
- O valor central do MVP (tokens + horas humanas) já representa a maior parte do custo do modelo híbrido nos projetos atuais
- Campo "nuvem" será reservado na UI com badge "em breve" para sinalizar a intenção sem criar expectativa não atendida

**Decisão documentada**: ADR-3 em `plan.md`.

---

## Technical Research Findings

### 1. GitHub Project API v2 — Disponibilidade para leitura de campos customizados

**Status**: ✓ Disponível

**Findings**:
- GitHub Projects v2 expõe campos customizados via GraphQL API
- Query principal: `projectV2Item.fieldValueByName("Horas Humanas")`
- Autenticação: `GITHUB_TOKEN` com scope `project:read` (ou `read:project`)
- Documentação oficial: https://docs.github.com/en/graphql/reference/objects#projectv2

**Considerações**:
- Se o campo "Horas Humanas" não existir no projeto, a query retorna `null` (não erro); cost-collector deve tratar esse caso sinalizando "custo humano não registrado"
- Rate limits da API: 5000 requests/hora por token autenticado — suficiente para o volume projetado (~500 registros/dia)
- O campo já existe conforme `docs/ai-code-quality-and-observability.md` (seção 8); não é necessário criá-lo

**Sample query**:
```graphql
query GetHumanHours($projectId: ID!, $after: String) {
  node(id: $projectId) {
    ... on ProjectV2 {
      items(first: 100, after: $after) {
        nodes {
          id
          fieldValueByName(name: "Horas Humanas") {
            ... on ProjectV2ItemFieldNumberValue {
              number
            }
          }
          content {
            ... on Issue {
              number
              title
            }
          }
        }
        pageInfo { hasNextPage endCursor }
      }
    }
  }
}
```

---

### 2. Fonte de tokens por sessão — `assistant_usage_events`

**Status**: ✓ Disponível

**Findings**:
- A tabela `assistant_usage_events` no session store local contém: `session_id`, `turn_index`, `model`, `input_tokens`, `output_tokens`, `total_nano_aiu`, `duration_ms`
- Disponível para query via SQLite (local) ou cloud session store
- Permite calcular custo por sessão: `total_tokens = input_tokens + output_tokens`

**Considerações**:
- Mapeamento `session_id → feature_id` precisa ser feito via metadata da sessão ou via branch name (convenção: `010-controle-de-custos`)
- Se sessão não contiver feature_id, cost-collector registra como "feature não mapeada" para curadoria manual
- Custo em USD pode ser calculado com pricing por modelo (ex.: claude-sonnet-4.6 = ~$3/M tokens input, ~$15/M output)

---

### 3. SPEC KIT COST — Disponibilidade e estrutura

**Status**: ✓ Referência confirmada

**Findings**:
- Repositório público: https://github.com/venha-pra-nuvem/spec-kit-cost
- Referenciado em `docs/ai-code-quality-and-observability.md` (seção 8) como framework de rastreio de custo
- No MVP, a integração é documental (URL embebida no plan.md e no dashboard); não há API técnica a consumir
- Futuras versões podem consumir SPEC KIT COST como SDK ou CLI

---

### 4. OpenFeature SDK — Disponibilidade

**Status**: ✓ Disponível

**Findings**:
- SDKs disponíveis para Node.js, Python, Go, Java e .NET: https://openfeature.dev/docs/reference/technologies/
- Provider env-var disponível como provider minimalista para bootstrap
- Providers de produção (Flagsmith, LaunchDarkly, etc.) plugáveis sem mudança de código de negócio
- Padrão já adotado como referência arquitetural na feature 016 (ADR-5 de 016-hybrid-agent-human-dev)

---

### 5. Campo "Horas Humanas" no GitHub Project — Existência confirmada

**Status**: ✓ Confirmado

**Findings**:
- Conforme `docs/ai-code-quality-and-observability.md` (seção 8), o campo já deve estar configurado nos projetos que adotam o modelo híbrido
- O cost-collector deve tratar ausência do campo como não-conformidade sinalizável, não como erro fatal
- Se o projeto não estiver configurado, a Feature 010 sinaliza "projeto sem configuração de rastreio de horas"

---

## Open Questions (Não Bloqueadoras)

| Questão | Impacto | Decisão tomada |
|---|---|---|
| Provider OpenFeature em GA (Flagsmith vs. LaunchDarkly vs. outro) | Baixo (detalhes de implementação) | A ser decidido no `/speckit-tasks`; bootstrap usa env-var |
| UI do dashboard: GitHub Projects v2 nativo vs. web app dedicado | Médio (esforço de implementação) | MVP usa GitHub Projects v2; UI dedicada fica fora do primeiro incremento |
| Frequência do job batch do cost-aggregator | Baixo | Padrão: diário; configurável via cron |
| Política de retenção de dados além de 12 meses | Baixo | MVP retém 12 meses; extensão posterior exige nova decisão de governança |

---

## Research Summary

Todos os pré-requisitos técnicos do MVP estão disponíveis e confirmados:
- ✓ GitHub Project API v2 acessível e retorna horas por issue
- ✓ `assistant_usage_events` disponível como fonte de tokens
- ✓ OpenFeature SDK disponível para as linguagens alvo
- ✓ SPEC KIT COST confirmado como referência
- ✓ FR-010 (custo de nuvem) postergado para fase 2 — sem bloqueio

Feature pronta para Phase 1 (Design & Contracts).
