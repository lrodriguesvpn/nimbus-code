# Implementation Plan: Governança de Métricas DORA com Coleta Híbrida

**Branch**: `021-dora-metrics-governance` | **Date**: 2026-08-31 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/021-dora-metrics-governance/spec.md`

## Summary

Formalizar um padrão organizacional único para as métricas DORA (Deployment Frequency, Lead Time for Changes commit-to-production, Change Failure Rate, Failed Deployment Recovery Time / TTRS) e Confiabilidade Operacional (SLOs/Disponibilidade), alinhado ao padrão Google DORA (dora.dev).
A solução adota uma **arquitetura 100% nativa no GitHub Enterprise (GHE)**:
1. **Camada Local no Repositório**: Coleta automática via GitHub Events/Deployments/PRs/Labels e auditoria determinística de ajustes manuais (`dora-manual-adjustments-log.yaml`) via `scripts/process-metrics-report.sh`.
2. **Camada de Visibilidade e Portfólio**: Centralizada no **GitHub Projects V2 (GHE)**, dispensando dependências de ferramentas SaaS proprietárias de terceiros (como DevStats SaaS) e evitando quebras por secrets de organização ausentes.
3. **Governança de Processo**: Interpretação semanal/mensal combinada e conversão disciplinada de degradação em ações no backlog.

## Technical Context

**Language/Version**: Bash 3.2+ (scripts com `gh` CLI) e YAML/Markdown para documentação de processo — mesmo stack de `scripts/process-metrics-report.sh` (feature 012)

**Primary Dependencies**:
- [scripts/process-metrics-report.sh](../../scripts/process-metrics-report.sh) — já calcula os 4 indicadores a partir das labels `dora:*`; será estendido, não recriado
- [docs/playbooks/README.md](../../docs/playbooks/README.md) — já define cadência mensal e metas iniciais (feature 012); será estendido com cadência semanal para squads, regras de qualidade de dados e fluxo de ajuste manual auditável
- [docs/label-taxonomy-and-autonomous-dev.md](../../docs/label-taxonomy-and-autonomous-dev.md) — taxonomia `dora:*` já registrada (feature 002), reaproveitada sem alteração de semântica
- [docs/playbooks/retro-cadence-state.yaml](../../docs/playbooks/retro-cadence-state.yaml) — padrão de arquivo de estado simples versionado no Git a reaproveitar para o novo log de auditoria de ajustes manuais

**Storage**:
- Novo arquivo de estado versionado `docs/playbooks/dora-manual-adjustments-log.yaml` (trilha de auditoria de ajustes manuais — mesmo padrão de `retro-cadence-state.yaml`: YAML simples versionado no Git, não um banco de dados)
- Sem banco de dados novo; toda persistência via Git (YAML versionado) + GitHub Issues (labels `dora:*` já existentes desde a feature 002)

**Testing**: testes de integração bash (mesmo padrão de `tests/scripts/process-metrics-report.*.test.sh` já existentes), cobrindo regras de qualidade de dados, trilha de auditoria de ajustes manuais e gatilho de ação corretiva por degradação

**Target Platform**: repositórios GHE da organização com labels `dora:*` aplicadas e `gh` CLI autenticado

**Project Type**: governança de processo + extensão de tooling de scripting já existente (não é um serviço novo)

**Performance Goals**: consolidação semanal (squads) e mensal (portfólio/PMO) sem exigir intervenção manual além da revisão explícita já prevista (ver SLO Gate abaixo)

**Constraints**:
- Não recriar `scripts/process-metrics-report.sh` — estender o script existente
- Ajuste manual só é aceito com justificativa, autor, timestamp e evidência vinculada (FR-004)
- Revisão periódica não pode ser fechada com ajustes manuais sem justificativa completa (FR-006)
- Interpretação MUST ser combinada entre os 4 indicadores — nunca decisão baseada em indicador isolado (FR-007)

**Scale/Scope**: toda squad e visão de portfólio/PMO que já aplica labels `dora:*` (taxonomia da feature 002, consumida operacionalmente desde a feature 012)

## Constitution Check

*GATE: deve passar antes da pesquisa da Fase 0. Revalidar após o design da Fase 1.*

| Gate | Status | Observação |
|---|---|---|
| Backup & DR | ✅ N/A | Sem datastore novo de produção — apenas YAML versionado em Git, já coberto pelo backup do próprio repositório |
| Segredos no código | ✅ | Nenhum segredo novo; reaproveita `gh` CLI já autenticado pelos scripts existentes |
| Branch/merge protegido | ✅ | Entrega por PR revisado, mesma política já vigente no repositório |
| Isolamento de ambiente | ✅ N/A | Não usa credenciais de produção; opera sobre issues/PRs e labels do próprio GHE |
| Observabilidade | ✅ | Esta própria feature É a camada de observabilidade de processo (métricas DORA) — não introduz um componente de runtime que precise de observabilidade própria |
| IaC | ✅ N/A | Não provisiona infraestrutura |

**Gate: APROVADO** — sem violações bloqueantes identificadas nesta fase de planejamento.

## Project Structure

### Documentation (this feature)

```text
specs/021-dora-metrics-governance/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── graph.yaml
├── graph.md
├── impact-map.md
├── contracts/
│   └── dora-quality-and-audit.contract.md
└── checklists/
    └── requirements.md
```

### Arquivos candidatos a alteração fora da pasta da feature

```text
scripts/process-metrics-report.sh                # regras de qualidade de dados + trilha de auditoria + cadência semanal
docs/playbooks/README.md                         # estender cadência DORA (semanal squads / mensal portfólio), regras de qualidade, fluxo de ação corretiva
docs/playbooks/dora-manual-adjustments-log.yaml  # novo — estado versionado de ajustes manuais (trilha de auditoria)
tests/scripts/                                   # novos testes de integração (qualidade de dados, auditoria, gatilho de ação)
```

**Structure Decision**: Extensão direta da infraestrutura de scripting/documentação já entregue pela feature 012 (Loop de Melhoria Contínua), sem criar um segundo mecanismo paralelo de coleta ou um novo serviço/runtime. Toda a governança adicional (qualidade de dados, auditoria, cadência semanal, gatilho de ação) é modelada como extensão de arquivos já existentes mais um novo arquivo de estado versionado no mesmo padrão já em uso.

## Complexity Tracking

> Nenhuma violação do Constitution Check nesta fase — seção não aplicável.

---

## Nimbus-Code — Classificação de Complexidade (S0–S4)

| Campo | Valor |
|---|---|
| **Nível** | **S3** |
| **Justificativa** | Cruza múltiplos artefatos: script de coleta (`scripts/process-metrics-report.sh`), novo arquivo de estado de auditoria versionado, documentação operacional (`docs/playbooks/README.md`) e regra de gate que bloqueia fechamento de revisão periódica — mesmo nível já usado pela feature 012 que esta estende |
| **Modelo de IA** | Reasoning |
| **Revisão humana obrigatória** | Não (S0–S3), mas recomendada por alterar processo operacional de todas as squads que já usam `dora:*` |
| **Padrão reutilizado encontrado?** | Não em `docs/reuse-catalog.yaml` (nenhuma tag específica de governança DORA registrada ainda) — mas esta feature **estende diretamente por ponteiro** a implementação já entregue pela feature 012 (`scripts/process-metrics-report.sh` + `docs/playbooks/README.md`), em vez de re-derivar do zero |
| **Estimativa de tokens (input+output)** | ~20–30 mil tokens |

---

## Nimbus-Code — Harness Gate

| Harness consultado (ID) | Padrão de erro evitado | Mitigação preventiva aplicada nesta feature |
|---|---|---|
| HRN-0003 | Feature S3/S4 entregue sem consultar o reuse-catalog/implementação já existente, resultando em re-derivação de solução duplicada e incompatível | O plano estende explicitamente `scripts/process-metrics-report.sh` e `docs/playbooks/README.md` da feature 012 por ponteiro, em vez de criar um segundo script/documento de coleta DORA |

**Resultado da consulta:**
- [x] Match encontrado — padrão(ões) de erro relevante(s) declarado(s) acima e mitigado(s)
- [ ] Nenhum padrão de erro relevante encontrado para este domínio
- [ ] Catálogo vazio — nenhum padrão disponível para consulta

---

## Nimbus-Code — Playbook de Sucesso Gate

| Padrão consultado (ID) | O que funcionou | Como foi reaplicado nesta feature |
|---|---|---|
| Nenhum | — | `docs/playbooks/success-catalog.yaml` ainda não tem entrada específica de governança DORA — nada a reaplicar por esta via; a reutilização real desta feature é a extensão direta da implementação da feature 012 (ver Harness Gate acima) |

**Resultado da consulta:**
- [ ] Match encontrado — padrão(ões) de sucesso relevante(s) declarado(s) acima e reaplicado(s)
- [x] Nenhum padrão relevante encontrado para este domínio
- [ ] Catálogo vazio — nenhum padrão disponível para consulta

---

## Nimbus-Code — Rastreabilidade AC → Teste → Módulo

| ID AC | Critério (resumo) | Tipo de teste planejado | Arquivo/módulo do teste | Justificativa de ausência |
|---|---|---|---|---|
| AC-1 | Os 4 indicadores DORA ficam definidos com fórmula, evento de origem e janela padronizada | Documental / inspeção | `docs/playbooks/README.md` + `data-model.md` | Definição é regra de documentação, não código executável |
| AC-2 | Evento elegível para automação é capturado sem intervenção manual como caminho padrão | Integração | `tests/scripts/process-metrics-report.detect.test.sh` (já existente, será estendido) | — |
| AC-3 | Ajuste manual exige justificativa, responsável, timestamp e evidência vinculada | Integração | `tests/scripts/process-metrics-report.audit-trail.test.sh` (novo) | — |
| AC-4 | Revisão periódica avalia os 4 indicadores de forma combinada, sem decisão isolada | Integração / documental | `scripts/process-metrics-report.sh` + `docs/playbooks/README.md` | Parte da checagem é textual (checklist de revisão), parte é o cálculo combinado já testável |
| AC-5 | Degradação relevante gera ação priorizável no backlog com ownership e prazo | Integração | `tests/scripts/process-metrics-report.degradation-action.test.sh` (novo) | — |
| AC-6 | Framework permite comparar evolução relativa entre squads de maturidade diferente sem distorcer contexto | Manual / walkthrough | `docs/playbooks/README.md` (seção de cadência e leitura combinada) | Comparabilidade cross-squad depende de julgamento qualitativo de contexto de negócio, não é puramente mecânico |

> Linhas com **Tipo: Manual/documental** têm justificativa explícita de ausência de automação total — nenhuma cobertura ficou sem entrada nesta tabela.

---

## Nimbus-Code — Module Dependency Graph

**Arquivos:**
- [graph.yaml](./graph.yaml) — fonte de verdade estruturada
- [graph.md](./graph.md) — diagramas Mermaid
- [impact-map.md](./impact-map.md) — obrigatório (S3)

**Checklist de manutenção do grafo:**
- [x] `graph.yaml` criado/atualizado com todos os módulos desta feature
- [x] `graph.md` criado/atualizado com diagrama por código e por business
- [x] Para S3: `impact-map.md` criado com análise de risco e plano de rollback
- [x] Nenhum módulo novo ficou fora do grafo
- [x] Dependências externas declaradas no `graph.yaml`
- [x] Grafo será atualizado novamente após `/nimbus-code-implement` se a implementação divergir do plano

### Grafo do Contexto (Multi-Repo Brownfield)

| Campo | Valor |
|---|---|
| **Bounded context** | `spec-kit-workflow` |
| **Grafo do contexto** | N/A — esta feature não introduz dependência cross-repo; o `graph.yaml`/`graph.md` desta feature contém o **module dependency graph** (não o context graph auto-gerado por `/speckit-specify`, que foi substituído nesta fase de planejamento por não haver módulos multi-repo relevantes) |
| **Dependências relevantes para esta feature** | Nenhuma fora do repositório central — toda a extensão ocorre em `scripts/`, `docs/playbooks/` e `tests/` do próprio `nimbus-code-spec-kit-template` |
| **Padrões de harvest aplicáveis** | Nenhuma entrada de `docs/reuse-catalog.yaml` originada de `scripts/harvest-patterns.sh` é relevante a esta feature |

## Nimbus-Code — Estratégia de Release

| Campo | Valor |
|---|---|
| **Estratégia** | `direct` |
| **Feature flag name** | `N/A` |
| **Flag provider** | `N/A` |
| **Critério de ativação** | merge do PR após revisão |
| **Critério de rollback** | reverter o commit/PR se a extensão do script ou a nova regra de gate quebrar o fluxo de revisão periódica já em uso pela feature 012 |

**Justificativa para deploy `direct`**: a feature altera scripts de governança de processo e documentação operacional, sem runtime progressivo por usuário final e sem exposição pública. O controle de risco vem de revisão humana em PR, testes de integração e rollback simples por revert.

## Nimbus-Code — Cost Reference

| Campo | Valor |
|---|---|
| **Token estimate range** | ~20–30 mil tokens |
| **Human effort estimate range** | ~1–3 horas (revisão de PR + validação de quickstart) |
| **Tracking method** | tabela "Estimativa vs. Consumo Real" no `tasks.md` + campo "Horas Humanas" no GitHub Project |
| **Budget ceiling (optional)** | N/A |

## Nimbus-Code — SLO Gate

| Componente | Latência p99 | Taxa de erro máx. | Disponibilidade | RTO | RPO |
|---|---|---|---|---|---|
| Ingestão automática de eventos DORA | 5000 ms | 1,0% | 99,9% | 30 min | 5 min |
| Registro manual assistido com auditoria | 4000 ms | 1,0% | 99,9% | 30 min | 5 min |
| Consolidação semanal/mensal de indicadores | 8000 ms | 1,0% | 99,5% | 60 min | 15 min |

> Valores herdados diretamente do cabeçalho "SLO Alvo desta Feature" do `spec.md` — não redefinidos aqui.

**SLOs não definidos nesta feature e justificativa:**
Nenhum — todos os componentes desta feature têm SLO mensurável definido acima.

## Nimbus-Code — Security & DevSecOps Gate

| Domínio | Controles aplicáveis | Escapável via ADL? | Status | Observações |
|---|---|---|---|---|
| Backup & Disaster Recovery | N/A — sem datastore de produção novo | — | ✅ N/A | Estado persistido é YAML versionado em Git, já coberto pelo backup do repositório |
| Autenticação (SSO) | N/A — não introduz sistema novo com login | — | ✅ N/A | |
| Segredos no código/repositório | Nunca em texto plano; secret scanning bloqueia merge se detectar | **Não — bloqueante** | ✅ PASS | Nenhum segredo novo introduzido |
| Branch/merge protegido | PR obrigatório + revisão antes de merge | **Não — bloqueante** | ✅ PASS | Convenção já vigente |
| Isolamento de ambiente | Credencial de produção nunca usada em dev/test | **Não — bloqueante** | ✅ PASS | Scripts operam só sobre metadados de issues/PRs via `gh` CLI |
| Containers | N/A — nenhum container novo | — | ✅ N/A | |
| CI/CD | N/A — nenhuma pipeline nova introduzida | — | ✅ N/A | |
| IaC — provider(s) usado(s) | N/A — não provisiona infraestrutura | — | ✅ N/A | |
| Banco de dados | N/A — sem banco de dados novo | — | ✅ N/A | |
| Firewall / Segmentação de rede | N/A — sem componente de rede novo | — | ✅ N/A | |
| Observabilidade | Logs/registro de auditoria mínimos definidos (trilha de quem mediu/ajustou/aprovou) | Sim, com justificativa no ADL | ✅ PASS | Coberto por FR-012 (trilha de auditoria) |

**Riscos identificados e decisão:**
Nenhum risco de segurança relevante identificado — esta feature é puramente governança de processo sobre dados já públicos internamente (issues/PRs/labels do próprio GHE).

## Nimbus-Code — Qualidade de Código, Testes e Observabilidade Gate

| Domínio | Controles aplicáveis | Status | Observações |
|---|---|---|---|
| Revisão de código por IA | GitHub Copilot code review solicitado em todo PR desta feature; findings High/Critical bloqueiam merge | Pendente até abertura do PR | |
| Testes integrados | Cada AC do `spec.md` tem teste de integração correspondente, exceto AC-1 e AC-6 (documentais, ver Rastreabilidade acima) | ✅ Planejado | Ver tabela de Rastreabilidade AC → Teste → Módulo |
| Observabilidade | Trilha de auditoria (quem mediu, ajustou, aprovou) é o próprio artefato de observabilidade desta feature | ✅ Planejado | `docs/playbooks/dora-manual-adjustments-log.yaml` |
| Arquitetura distribuída / Microsserviços | N/A | N/A | Sem chamadas entre serviços — scripts bash standalone |
| Gestão de bugs | Bugs encontrados fora do escopo desta feature abertos como Issue e atribuídos ao Copilot coding agent | ✅ Regra padrão do bundle | |

**Critérios de aceitação sem teste de integração automatizado (se houver) — justificativa:**
AC-1 (definições dos indicadores) e AC-6 (comparabilidade cross-squad) são validados por inspeção documental/walkthrough — ambos dependem de julgamento textual/qualitativo, não de comportamento executável.

## Nimbus-Code — Architecture Decision Log

| Decisão | Alternativas consideradas | Opção escolhida | Trade-off assumido | Justificativa do desvio (se aplicável) | Aprovado por |
|---|---|---|---|---|---|
| Estender `scripts/process-metrics-report.sh` (feature 012) em vez de criar um novo script de coleta DORA | (a) novo script dedicado a governança/auditoria; (b) estender o script existente | (b) estender o script existente | Script existente cresce em responsabilidade, mas evita duplicar a lógica de cálculo dos 4 indicadores já testada | N/A — não é desvio de padrão, é reuso direto (ver Harness Gate, HRN-0003) | — |
| Novo estado de auditoria `docs/playbooks/dora-manual-adjustments-log.yaml` versionado no Git em vez de banco de dados | (a) banco de dados dedicado; (b) issues do GitHub como único registro; (c) YAML versionado no Git | (c) YAML versionado no Git, mesmo padrão de `retro-cadence-state.yaml` | Sem consultas complexas/agregação em escala, mas simples, auditável via `git log` e sem infraestrutura nova | N/A — não é desvio de padrão | — |
