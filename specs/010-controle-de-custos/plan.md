# Implementation Plan: Controle de Custos

**Branch**: `010-controle-de-custos`

**Created**: 2026-08-18

**Status**: Backlog — design documental preservado; implementação adiada

> Este plano não está autorizado para execução neste ciclo. As decisões e
> contratos servem como referência até a retomada formal da SPEC.

**Spec**: [spec.md](./spec.md)

## Summary

Feature que implementa um sistema centralizado de controle de custos para o modelo de desenvolvimento híbrido (agentes de IA + humanos), consolidando consumo de tokens, horas humanas e recursos de nuvem numa visão unificada por feature/sprint/projeto, com alertas de orçamento e benchmarks históricos para estimativas.

---

## Technical Context

### Architecture Overview

A feature envolve **quatro camadas de implementação** interdependentes:

1. **Camada de Coleta** (`cost-collector`): integração com fontes de dados (eventos de sessão de agente para tokens; GitHub Project API para horas humanas)
2. **Camada de Armazenamento** (`cost-store`): persistência de `CostRecord`, `CostEstimate`, `Budget` e `CostAlert` com histórico auditável
3. **Camada de Agregação** (`cost-aggregator`): jobs batch que produzem `CostBenchmark` por complexidade e consolidam view por feature/sprint/squad
4. **Camada de Apresentação** (`cost-dashboard`): API REST interna e GitHub
   Projects v2 como superfície inicial; UI web dedicada fica fora do MVP

**Fluxo principal:**
```
Sessão agente → cost-collector (tokens) → cost-store
GitHub Project → cost-collector (horas) → cost-store
                                              ↓
                                   cost-aggregator (batch)
                                              ↓
                                   cost-dashboard (read)
                                              ↓
                                 Budget alert engine → notificação
```

### Dependencies

- **GitHub Project API** — leitura do campo "Horas Humanas" por feature/issue
- **Agent session metadata** — consumo de tokens por sessão (via `assistant_usage_events` ou equivalente)
- **`docs/ai-code-quality-and-observability.md`** (seção 8) — define o modelo híbrido e o campo "Horas Humanas" no GitHub Project
- **SPEC KIT COST** — framework público de referência para rastreio de custo híbrido: https://github.com/venha-pra-nuvem/spec-kit-cost
- **OpenFeature SDK** — abstração de feature toggle para rollout gradual do dashboard

### Technology Choices

- **Backend / Coleta**: implementação livre por projeto consumidor; interface
  normativa declarada via contratos Markdown/YAML
- **Storage**: banco relacional (PostgreSQL recomendado); schema versionado via migrations
- **Dashboard**: API REST interna + GitHub Projects v2 no MVP; UI web dedicada é posterior
- **Alertas**: webhook + notificação via GitHub Issues/Slack (provider configurável)
- **Feature toggle**: OpenFeature SDK com env-var provider no bootstrap; migração para provider dedicado em GA

**Language/Version**: A definir por projeto consumidor (templates agnósticos de linguagem)  
**Storage**: PostgreSQL 15+ (ou compatível)  
**Testing**: testes de integração para coleta + alertas; testes unitários para agregações  
**Target Platform**: servidor (Linux), API REST interna  
**Performance Goals**: dashboard p99 < 800ms; alertas em < 30 min do trigger  
**Constraints**: custo de nuvem fora do MVP (ver FR-010 em spec.md); sem PII em registros de custo  
**Scale/Scope**: ~100 features ativas simultaneamente; ~500 registros/dia estimados

**Retention/Privacy**: 12 meses; acesso por papel; histórico append-only; sem
conteúdo de prompt ou PII.

---

## Constitution Check

| Princípio | Status | Notas |
|---|---|---|
| Segurança — nenhum segredo em texto plano | ✓ Pass | Tokens de API e credenciais do GitHub Project armazenados em cofre (ex.: GitHub Secrets); não expostos em templates |
| Backup & DR | ✓ Pass | Dados de custo em banco com backup; histórico imutável (append-only); rollback via feature flag |
| Branch protegida | ✓ Pass | Alterações requerem PR + revisão antes de merge em `develop` |
| TLS | ✓ Pass | Todas as integrações (GitHub API, dashboard) sobre HTTPS/TLS |
| Isolamento de ambiente | ✓ Pass | Feature flag `cost_control_v1` ativa módulo por ambiente; dev/hml/prod isolados |
| Grafos de Módulos (S3+) | ✓ Pass | `graph.yaml` e `graph.md` presentes neste artefato Phase 1 |
| Escala de Complexidade (S3, não S4) | ✓ Pass | Cruza 2+ módulos sem dados sensíveis PII; sem integração financeira crítica externa |
| Reutilização (catálogo) | ✓ Pass | `docs/reuse-catalog.yaml` consultado; nenhum match. Padrão será adicionado após conclusão (tag: `cost-control-hybrid`) |

**Desvio identificado — FR-010 (custo de nuvem)**:  
Recurso de custo de nuvem marcado como `NEEDS CLARIFICATION` na spec. Decisão: **fora do MVP**. Registrado no ADR-3 abaixo.

---

## Nimbus-Code — Classificação de Complexidade (S0–S4)

| Campo | Valor |
|---|---|
| **Nível** | **S3** — múltiplos módulos interdependentes (coleta, armazenamento, agregação, apresentação) |
| **Justificativa** | Integra 2+ serviços externos (GitHub Project API, agent session metadata); requer schema de banco, job batch, dashboard e motor de alertas; impacto em fluxo de governança de custo |
| **Modelo de IA** | Reasoning (Claude Sonnet 4.6+) — design de schema, análise de integrações e gates |
| **Revisão humana obrigatória** | Não (S3) — porém recomendada pelo impacto em governança financeira |
| **Padrão reutilizado encontrado?** | Não — `docs/reuse-catalog.yaml` consultado; nenhuma entrada com match. Adicionar ao catálogo após conclusão (tag: `cost-control-hybrid`) |
| **Estimativa de tokens (input+output)** | ~50–70 mil tokens — multiplicador S3 sobre base de 12kt; inclui pesquisa Phase 0, design Phase 1, geração de todos os artefatos |

## Cost Reference

Estimated delivery is 50–70k agent tokens and 8–16 human hours. Record actual
tokens in the session ledger and human time in the GitHub Project field
`Horas Humanas`; compare both at feature closure.

---

## Nimbus-Code — Rastreabilidade AC → Teste → Módulo

| ID AC | Critério (resumo) | Tipo de teste planejado | Arquivo/módulo do teste | Justificativa de ausência (se N/A) |
|---|---|---|---|---|
| AC-1 | Custo real vs. estimado por feature | integração | `cost-aggregator/tests/test_AC1_custo_real_vs_estimado.py` | — |
| AC-2 | Alerta ao atingir 80% do orçamento | integração | `cost-alerts/tests/test_AC2_alerta_orcamento_80pct.py` | — |
| AC-3 | Dashboard consolidado com drill-down | integração (E2E) | `cost-dashboard/tests/test_AC3_dashboard_consolidado.spec.ts` | — |
| AC-4 | Campos de estimativa obrigatórios no plan.md | integração (template) | `.specify/presets/nimbus-code-standards/templates/plan-template.md` (validar campos de custo) | — |
| AC-5 | Benchmarks históricos por complexidade | integração | `cost-aggregator/tests/test_AC5_benchmarks_historicos.py` | — |

---

## Nimbus-Code — Module Dependency Graph

**Status**: Gerado como artefato Phase 1 (`graph.yaml` + `graph.md` + `impact-map.md`).

**Módulos envolvidos:**
- `cost-collector`: integração GitHub Project API + agent session metadata
- `cost-store`: schema de banco, migrations, modelos de entidade
- `cost-aggregator`: jobs batch (CostBenchmark, view por feature/sprint/squad)
- `cost-dashboard`: API REST + frontend (dashboard, filtros, exportação)
- `budget-alert-engine`: motor de alertas, triggers, notificações
- `plan-template` (atualização): campos obrigatórios de estimativa de custo
- External: GitHub Project API, SPEC KIT COST, OpenFeature SDK

Checklist:
- [x] `graph.yaml` criado com todos os nós e arestas
- [x] `graph.md` criado com diagramas Mermaid (arquitetura técnica e fluxo de dados)
- [x] `impact-map.md` criado com análise de risco e plano de rollback
- [x] Todos os módulos cobertos; dependências externas declaradas em `externals`

---

## Nimbus-Code — Estratégia de Release

| Campo | Valor |
|---|---|
| **Estratégia** | `flag` — ativar módulos de coleta e dashboard gradualmente por ambiente |
| **Feature flag name** | `cost_control_v1` |
| **Flag provider** | OpenFeature (env-var provider no bootstrap; Flagsmith/LaunchDarkly em GA) |
| **Critério de ativação** | Coleta funcionando em 1 projeto piloto; dashboard exibe dados reais sem erro por 5 dias contínuos |
| **Critério de rollback** | Falha em coleta de tokens em >5% das sessões; alerta duplicado ou não disparado em >3 casos; dashboard com dados incorretos reportados por gestores |

**Justificativa**: Dados financeiros exigem rollout conservador — erros de coleta geram confiança negativa imediata. Feature flag permite reverter sem impacto em projetos em andamento.

---

## Nimbus-Code — Plano de Toggle e Rollout

| Campo | Valor |
|---|---|
| **Flag key** | `cost_control_v1` |
| **Tipo de flag** | `release` |
| **Owner da flag** | FinOps Architecture Board |
| **Ambiente(s)** | dev · hml · prod |
| **Default por ambiente** | dev=on, hml=off, prod=off |
| **Segmentos de ativação** | `internal-pilot` → `venha-pra-nuvem-clients` |
| **Estratégia de rollout** | dev (sempre) → hml (piloto interno, 1 semana) → prod (piloto 1 projeto, 2 semanas) → prod 100% |
| **Kill switch definido?** | Sim — desativar flag via OpenFeature provider; coleta para imediatamente |
| **Critério de limpeza** | Remover flag 30 dias após GA estável (criar Issue de tracking no merge) |

---

## Phase 0: Research & Clarifications

**Status**: Concluído. Ver `research.md` para detalhes.

**Clarificações resolvidas**:
- **FR-010 (custo de nuvem)**: fora do MVP — ver ADR-3
- **Moeda base**: BRL; custo de tokens em USD convertido pela taxa do dia de coleta
- **Fonte de tokens**: `assistant_usage_events` (tabela local do session store) ou API de uso do modelo (fallback)
- **Acesso ao dashboard**: Tech Leads, gestores e diretores; devs veem apenas suas próprias features

**Research tasks**:
- [x] Validar disponibilidade da GitHub Project API v2 para leitura de campos customizados
- [x] Confirmar estrutura de `assistant_usage_events` como fonte de tokens
- [x] Confirmar referência ao SPEC KIT COST como ponto de rastreio externo
- [x] Validar que OpenFeature SDK está disponível para as linguagens alvo
- [x] Verificar que campo "Horas Humanas" já existe conforme `docs/ai-code-quality-and-observability.md` seção 8

---

## Phase 1: Design & Contracts

### Data Model

Ver `data-model.md` para especificação completa. Entidades principais:

1. **CostRecord** — custo real por feature por dimensão (tokens, horas humanas)
2. **CostEstimate** — estimativa registrada no plan.md antes da execução
3. **Budget** — orçamento configurado por sprint/projeto/squad
4. **CostAlert** — alerta disparado ao atingir limite de orçamento
5. **CostBenchmark** — agregado histórico por complexidade (S0–S4)

### Contracts

Ver `contracts/` para schemas completos.

**`cost-collector` output contract**:
- Emite `CostRecord` com: `feature_id`, `dimension`, `amount`, `currency`, `period`, `source`, `model` (se tokens), `session_id` (se tokens)
- Emite via evento ou job batch; idempotente (re-run seguro)

**`budget-alert-engine` contract**:
- Trigger: `CostRecord` inserido → recalcula total por budget scope
- Ação: se `(total / limit) >= threshold_pct` → dispara `CostAlert` e notifica owner
- SLA: < 30 min entre trigger e notificação entregue

**`cost-dashboard` API contract**:
- `GET /costs?scope={feature|sprint|squad}&id={id}&period={from}&{to}` → `CostSummary`
- `GET /costs/benchmarks?complexity={S0|S1|S2|S3|S4}` → `CostBenchmark[]`
- `GET /budgets/{id}/status` → `BudgetStatus`
- Latência p99 < 800ms

### Quickstart Validation Guide

Ver `quickstart.md` para guia E2E completo.

---

## Security & DevSecOps Gate

### Não-Negociáveis (zero exceção):

- [x] **Backup & DR**: Dados de custo em banco com backup automático; histórico append-only (imutável); rollback via feature flag sem perda de dados
- [x] **Segredos em cofre**: `GITHUB_TOKEN` para GitHub Project API em GitHub Secrets; credenciais de banco em vault; nunca em variáveis de ambiente expostas
- [x] **Branch protegida**: Alterações em coleta e armazenamento requerem PR com revisão antes de merge em `develop`
- [x] **TLS**: Dashboard exposto apenas por HTTPS; GitHub API via HTTPS; notificações via HTTPS webhook
- [x] **Isolamento de ambiente**: Feature flag `cost_control_v1` separa dev/hml/prod; banco de dados por ambiente

### Escapáveis via Architecture Decision Log:

- **Firewall/VPC**: não aplicável ao MVP (serviços internos sem exposição pública); ADR não necessário
- **SSO**: dashboard interno; autenticação via GitHub OAuth (já padrão organizacional); não exige ADR separado
- **IaC**: infraestrutura do banco e dashboard versionados como IaC (Terraform recomendado); desvio exige ADL

**Status**: Todos os itens não-negociáveis atendidos. Nenhum item escapável ativo sem justificativa.

---

## Quality Gate — Code, Tests, Observability

| Critério | Status | Detalhes |
|---|---|---|
| Code coverage planejada | ≥ 80% (integração) | Coleta, alertas e agregação cobertos por testes integração; dashboard por testes E2E |
| Observability (logs) | Planejado | JSON estruturado com `trace_id`, `span_id`, `service=cost-control`, `level`; propagação de `X-Correlation-Id` |
| Métricas | Planejado | `cost_records_collected_total`, `alerts_triggered_total`, `dashboard_request_duration_p99` |
| Alertas operacionais | Planejado | Alerta se `cost-collector` falha por > 5 min; alerta se `budget-alert-engine` atrasado > 30 min |
| Performance SLO | Dashboard p99 < 800ms; alertas < 30 min | Testado em load test antes do piloto prod |
| Error handling | Definido | Falha na coleta → registro em dead-letter queue com retry 3x; falha de alerta → re-enfileirado com backoff |
| Data retention | 12 meses online; 24 meses archival | Registros de custo são financeiros — retenção mínima de 1 ano por política padrão |

---

## Architecture Decision Log

**ADR-1: Modelo append-only para CostRecord**

- **Decision**: `CostRecord` é imutável (append-only); correções criam novo registro com `correction_ref`
- **Rationale**: Dados financeiros requerem trilha de auditoria completa; mutabilidade cria risco de adulteração acidental
- **Alternatives considered**: Soft delete + update (perda de histórico); event sourcing (over-engineering para MVP)
- **Implications**: Queries de total agregam todos os registros não-corrigidos; UI deve filtrar `correction_ref`

**ADR-2: GitHub Project API v2 como fonte de horas humanas**

- **Decision**: Ler campo "Horas Humanas" via GraphQL da GitHub Project API v2
- **Rationale**: Reutiliza infra já configurada (conforme docs/ai-code-quality-and-observability.md seção 8); sem ferramenta adicional
- **Alternatives considered**: Integração com sistema de timesheet dedicado (atraso de adoção e custo extra); planilha manual (não escalável)
- **Implications**: Se GitHub Project não estiver configurado com o campo, feature é sinalizada como "custo humano não registrado"

**ADR-3: Custo de nuvem fora do escopo do MVP**

- **Decision**: FR-010 (integração com provedores de nuvem) adiado para fase 2
- **Rationale**: Custo de nuvem requer integração com AWS Cost Explorer / Azure Cost Management, o que eleva a feature para S4 (integração crítica externa financeira); MVP já entrega valor sem isso
- **Alternatives considered**: Incluir no MVP (aumentaria complexidade para S4 e exigiria revisão humana obrigatória + label `complexity:S4`)
- **Implications**: Dashboard v1 exibe apenas tokens + horas humanas; campo "nuvem" reservado na UI com badge "em breve"

**ADR-4: OpenFeature como padrão de toggle para rollout gradual**

- **Decision**: Usar OpenFeature SDK com env-var provider no bootstrap; migrar para provider dedicado em GA
- **Rationale**: Consistência com padrão arquitetural estabelecido na feature 005; portabilidade entre providers
- **Alternatives considered**: Rollout direto sem flag (arriscado para dados financeiros); provider proprietário (lock-in)
- **Implications**: Bootstrap usa `COST_CONTROL_V1=true/false`; GA migra para Flagsmith ou LaunchDarkly via OpenFeature

**ADR-5: Moeda base BRL com conversão USD no momento da coleta**

- **Decision**: Armazenar custo de tokens em BRL usando taxa de câmbio do dia da coleta; guardar `usd_amount` e `exchange_rate` no registro
- **Rationale**: Relatórios são consumidos por gestores brasileiros; consolidação em USD criaria ruído de câmbio nos relatórios históricos
- **Alternatives considered**: Armazenar somente USD (confusão para gestores BRL); converter somente na exibição (inconsistência em períodos de câmbio volátil)
- **Implications**: Registros antigos não são recalculados com câmbio atual; taxa de câmbio é auditável por registro

---

## Next Steps (Readiness for `/speckit-tasks`)

- [x] `graph.yaml`, `graph.md`, `impact-map.md` gerados (Phase 1)
- [x] `research.md` gerado (Phase 0)
- [x] `data-model.md` com entidades e validações completas
- [x] `contracts/` com schemas de API e entidades
- [x] `quickstart.md` com guia de validação E2E
- [x] Todos os gates passando (Security, Quality, Constitution Check)
- [x] ADL completo com 5 decisões arquiteturais
- [ ] Aprovação humana via PR review antes de `/speckit-tasks`

---

## Completion Checklist

- [x] Plan.md preenchido com Technical Context, Constitution Check, Gates
- [x] Phase 0 Research consolidado (`research.md`)
- [x] Phase 1 Design artifacts gerados:
  - [x] `graph.yaml` — módulos, dependências, externos
  - [x] `graph.md` — diagramas Mermaid (arquitetura técnica e fluxo de dados)
  - [x] `impact-map.md` — análise de risco e plano de rollback
  - [x] `data-model.md` — entidades com validação completa
  - [x] `contracts/` — API contract e entity contracts
  - [x] `quickstart.md` — guia de validação E2E
- [x] Todos os gates passando (Security, Quality, Constitution)
- [x] ADL completo (5 decisões arquiteturais)
- [ ] Aprovação humana → pronto para `/speckit-tasks`
