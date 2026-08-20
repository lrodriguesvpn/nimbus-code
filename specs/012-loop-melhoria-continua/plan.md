# Implementation Plan: Loop de Melhoria Contínua Nimbus-Code — Playbooks de Sucesso, Retrospectiva e Métricas DORA

**Branch**: `012-loop-melhoria-continua` | **Date**: 2026-08-20 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/012-loop-melhoria-continua/spec.md`

## Summary

Fechar o ciclo de aprendizado organizacional do Nimbus-Code adicionando o lado
que falta ao Harness Engineering (feature 011, que só cataloga **erros**):
(1) um catálogo irmão de **sucessos** (`docs/playbooks/success-catalog.yaml`)
para registrar o que funcionou bem e merece ser repetido; (2) um script
(`scripts/process-metrics-report.sh`) que calcula os 4 indicadores DORA a
partir dos labels `dora:*` já aplicados, hoje inertes; (3) uma cadência de
revisão periódica desses indicadores com meta e ação de melhoria; e (4) uma
sinalização proativa de retrospectiva por número de features concluídas, não
apenas reativa a divergência/incidente. Tudo com o agente propondo/coletando
e o humano validando — reforço explícito do Modelo Híbrido já vigente.

## Technical Context

**Language/Version**: Bash 5 (scripts, mesmo padrão de `scripts/harness-search.sh` e demais scripts do bundle)

**Primary Dependencies**: `gh` CLI ≥ 2.40 (leitura de issues/PRs e labels via `gh api`/`gh issue list`/`gh pr list`), `jq` ≥ 1.6

**Storage**: `docs/playbooks/success-catalog.yaml` (arquivo estático versionado, mesmo padrão de `docs/reuse-catalog.yaml` e `docs/harness/harness-catalog.yaml`)

**Testing**: Execução manual/scripted (`bash -n`, parse YAML) — sem testes automatizados de integração contra a API real do GHE em CI, mesmo racional já documentado nas features 001/005/011

**Target Platform**: GitHub Enterprise Cloud (`venha-pra-nuvem.ghe.com`) — leitura de metadados (labels, datas de merge/close) via `gh` CLI

**Project Type**: Tooling / convenção de processo — scripts CLI + documentação, sem serviço em produção

**Performance Goals**: `scripts/process-metrics-report.sh` conclui em < 10s para o período analisado (SC-002)

**Constraints**: Cálculo de DORA depende inteiramente de labels já aplicados manualmente (esta feature não automatiza a aplicação do label `dora:*` em si — ver Assumptions do `spec.md`); sem infraestrutura de observabilidade externa

**Scale/Scope**: Org `venha-pra-nuvem`, todos os repositórios usando o preset `nimbus-code-standards`

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Status | Observação |
|---|---|---|
| Backup & DR | N/A | Nenhum datastore de produção — apenas arquivo YAML estático versionado no Git |
| Segredos no código | ✅ | Script usa `gh` CLI com token do ambiente, sem credenciais hardcoded |
| Branch/merge protegido | ✅ | PR obrigatório conforme regras da org |
| Isolamento de ambiente | ✅ | Script aponta ao repo passado como argumento/contexto do `gh` CLI atual |
| Observabilidade | N/A | Scripts CLI locais, sem componente em runtime contínuo |
| IaC | N/A | Sem infraestrutura provisionada |

**Gate: PASS** (sem exceções a justificar em Complexity Tracking).

## Project Structure

### Documentation (this feature)

```text
specs/012-loop-melhoria-continua/
├── spec.md              ✅ Completo
├── plan.md              # Este arquivo
├── research.md          # Gerado nesta sessão
├── data-model.md        # Gerado nesta sessão
├── quickstart.md        # Gerado nesta sessão
├── graph.yaml           # Gerado nesta sessão
├── graph.md             # Gerado nesta sessão
├── impact-map.md        # Obrigatório (S3) — gerado nesta sessão
└── tasks.md             # Gerado por /speckit-tasks (próxima fase)
```

### Artefatos alterados (fora da pasta de spec)

```text
docs/
├── playbooks/
│   └── success-catalog.yaml       # novo — catálogo irmão do harness-catalog.yaml
└── reuse-catalog.yaml              # + entrada apontando para esta feature (FR-008)

scripts/
└── process-metrics-report.sh       # novo — calcula os 4 indicadores DORA via gh api

presets/nimbus-code-standards/templates/
├── plan-template.md                 # + seção "Playbook de Sucesso Gate" (espelha o Harness Gate da 011)
└── tasks-template.md                # + item de checklist "o que deu certo aqui?"

.specify/presets/nimbus-code-standards/templates/
├── plan-template.md                 # cópia espelhada — mesma adição (paridade)
└── tasks-template.md                # cópia espelhada — mesma adição (paridade)

.github/
└── copilot-instructions.md          # + seção "Playbook de Sucesso" ao lado da seção "Harness Engineering" (011)
```

---

## Nimbus-Code — Classificação de Complexidade (S0–S4)

| Campo | Valor |
|---|---|
| **Nível** | **S3** |
| **Justificativa** | Cruza múltiplos módulos: novo `docs/playbooks/`, novo script `scripts/process-metrics-report.sh`, 2 templates de preset (`plan-template.md`, `tasks-template.md`) em 2 cópias cada (paridade), `copilot-instructions.md`, `docs/reuse-catalog.yaml`. Não é integração entre serviços externos, mas cruza convenção + script + templates de preset — mesmo nível já usado pela feature-irmã 011 (Harness Engineering) |
| **Modelo de IA** | Claude Sonnet (reasoning ativo) |
| **Revisão humana obrigatória** | Não (S3 — mas recomendada por alterar templates de preset usados por todo o portfólio) |
| **Padrão reutilizado encontrado?** | Sim (tag: `speckit-deduplication-by-id` para a lógica de dedup de entradas do catálogo; e a própria feature 011 `docs/harness/*` como precedente estrutural direto — catálogo YAML + guia + script de busca) |
| **Estimativa de tokens (input+output)** | ~30–45 mil tokens (S3, com desconto por reaproveitar a estrutura já validada do Harness Engineering em vez de desenhar um catálogo novo do zero) |

---

## Nimbus-Code — Rastreabilidade AC → Teste → Módulo

| ID AC | Critério (resumo) | Tipo de teste planejado | Arquivo/módulo do teste | Justificativa de ausência |
|---|---|---|---|---|
| AC-1 | Checklist de fechamento pergunta "o que deu certo?" | Manual (inspeção do `tasks-template.md` + walkthrough) | `presets/nimbus-code-standards/templates/tasks-template.md` | Convenção de processo/prosa — sem lógica executável a testar automaticamente |
| AC-2 | `process-metrics-report.sh` calcula os 4 indicadores DORA | Integração (script real contra fixture de issues/PRs rotulados) | `tests/scripts/process-metrics-report.detect.test.sh` | — |
| AC-3 | Revisão periódica de DORA com meta e ação de melhoria | Manual (validação de processo/registro, não de código) | Registro documentado (Issue/retro) | Cadência organizacional, não testável em CI |
| AC-4 | Sinalização proativa de retrospectiva por cadência de N features | Integração (simular contador e verificar sinalização) | `tests/scripts/process-metrics-report.retro-cadence.test.sh` | — |
| AC-5 | `plan-template.md` tem seção "Playbook de Sucesso Gate" | Manual (inspeção do template) | `presets/nimbus-code-standards/templates/plan-template.md` | Convenção de template — sem lógica executável |

**Critérios sem teste de integração automatizado:** AC-1, AC-3 e AC-5 são
convenções de processo/template sem comportamento executável — mesmo racional
já aplicado às features 001 e 011.

## Nimbus-Code — Module Dependency Graph

**Arquivos:**
- `specs/012-loop-melhoria-continua/graph.yaml` — gerado nesta sessão
- `specs/012-loop-melhoria-continua/graph.md` — gerado nesta sessão
- `specs/012-loop-melhoria-continua/impact-map.md` — **obrigatório (S3)** — gerado nesta sessão

**Checklist de manutenção do grafo:**
- [x] `graph.yaml` criado com todos os nós e arestas desta feature
- [x] `graph.md` criado com diagrama por código e diagrama por business
- [x] `impact-map.md` criado com análise de risco e plano de rollback (S3)
- [x] Nenhum módulo/serviço novo criado nesta feature está faltando no grafo
- [x] Dependências externas (GHE API via `gh` CLI) declaradas em `externals`
- [ ] Grafo será atualizado novamente após `/nimbus-code-implement` se a implementação divergir do plano

## Nimbus-Code — Estratégia de Release

| Campo | Valor |
|---|---|
| **Estratégia** | `direct` |
| **Feature flag name** | N/A |
| **Flag provider** | N/A |
| **Critério de ativação** | N/A |
| **Critério de rollback** | `git revert` do PR; catálogo de sucesso e script de métricas são aditivos e não quebram nenhum fluxo existente se removidos |

**Justificativa para deploy `direct`:**
Mudança de convenção/documentação + script CLI local sem componente em
produção com ativação gradual — mesmo racional já usado nas features 001 e
011 (catálogos estáticos consumidos por leitura, sem rollout incremental
aplicável).

## Nimbus-Code — Plano de Toggle e Rollout

N/A — não há toggle envolvido (ver Estratégia de Release acima e AC de
governança "N/A" no `spec.md`).

## Nimbus-Code — Cost Reference

| Campo | Valor |
|---|---|
| **Token estimate range** | ~30–45 mil tokens (ver Classificação de Complexidade acima) |
| **Human effort estimate range** | ~2–4 horas (revisão de templates de preset + validação de 1ª entrada real no success-catalog.yaml) |
| **Tracking method** | Tabela "Estimativa vs. Consumo Real de Tokens" no `tasks.md` + campo "Horas Humanas" no GitHub Project |
| **Budget ceiling (optional)** | N/A |

## Nimbus-Code — SLO Gate

| Componente | Latência p99 | Taxa de erro máx. | Disponibilidade | RTO | RPO |
|---|---|---|---|---|---|
| `docs/playbooks/success-catalog.yaml` (leitura) | — | 0% (arquivo estático) | — | — | — |
| `scripts/process-metrics-report.sh` | < 10s | 0% (idempotente, somente leitura) | — | — | — |

**SLOs não definidos nesta feature e justificativa:**
Ambos os componentes são arquivo estático e script CLI local — sem serviço
em execução contínua, logo sem SLO de disponibilidade mensurável (mesmo
racional das features 001 e 011).

## Nimbus-Code — Security & DevSecOps Gate

| Domínio | Controles aplicáveis | Escapável via ADL? | Status | Observações |
|---|---|---|---|---|
| Backup & Disaster Recovery | N/A — sem datastore de produção | Não — bloqueante | N/A | Arquivo versionado no Git |
| Segredos no código/repositório | Nenhum segredo — script usa token de sessão do `gh` CLI já autenticado | Não — bloqueante | ✅ OK | — |
| Branch/merge protegido | PR obrigatório + revisão antes de merge | Não — bloqueante | ✅ OK | Convenção já vigente |
| Isolamento de ambiente | N/A — script somente leitura, sem escrita em produção | Não — bloqueante | N/A | `process-metrics-report.sh` não grava nada, só lê e imprime |
| Observabilidade | N/A — sem componente em runtime | Sim, com justificativa no ADL | N/A | Script CLI local sem execução contínua |

**Riscos identificados e decisão:**
Nenhum risco de segurança identificado — script é somente-leitura (`gh api`/`gh issue list`/`gh pr list`), sem escrita em issues/PRs nem acesso a dado sensível.

## Nimbus-Code — Qualidade de Código, Testes e Observabilidade Gate

| Domínio | Controles aplicáveis | Status | Observações |
|---|---|---|---|
| Revisão de código por IA | GitHub Copilot code review no PR desta feature | | |
| Testes integrados | AC-2 e AC-4 cobertos por teste de integração com fixture; AC-1, AC-3, AC-5 são N/A justificado (convenção/processo) | | |
| Observabilidade | N/A — scripts CLI locais sem execução contínua | | |
| Arquitetura distribuída / Microsserviços | N/A — sem chamadas entre serviços, apenas `gh` CLI → GHE API | | |
| Gestão de bugs | Nenhum bug identificado relacionado a esta feature | | |

**Critérios de aceitação sem teste de integração automatizado — justificativa:**
AC-1 (checklist de template), AC-3 (cadência organizacional de revisão) e
AC-5 (seção de template) são convenções de processo/documentação, sem
comportamento executável a testar — ver Rastreabilidade AC → Teste → Módulo
acima.

## Nimbus-Code — Architecture Decision Log

| Decisão | Alternativas consideradas | Opção escolhida | Trade-off assumido | Justificativa do desvio (se aplicável) | Aprovado por |
|---|---|---|---|---|---|
| Estrutura do catálogo de sucesso | Reaproveitar o mesmo arquivo `harness-catalog.yaml` (com um campo `type: success\|error`) vs. arquivo irmão separado (`success-catalog.yaml`) | Arquivo irmão separado | Ganha clareza semântica e evita que uma consulta por erro traga sucesso junto (e vice-versa); perde um pouco de "single source" | N/A — decisão de design desta feature, não desvio de padrão institucional | A confirmar em revisão humana do PR |
| Fonte dos indicadores DORA | Ferramenta externa de observabilidade (ex.: dashboards de engineering metrics) vs. cálculo local a partir de labels já aplicados no GHE | Cálculo local via `gh` CLI | Ganha zero infraestrutura nova/custo adicional; perde granularidade/precisão de uma ferramenta dedicada | N/A — consistente com o racional "sem infraestrutura adicional" já usado nas features 001/011 | A confirmar em revisão humana do PR |
| Cadência de retrospectiva proativa | Cadência por tempo calendário (ex.: mensal) vs. por número de features concluídas | Por número de features concluídas (N configurável) | Ganha relevância (não depende de quão ativo o repo está no calendário); perde previsibilidade de data fixa | N/A — decisão de design registrada em Assumptions do `spec.md` | A confirmar em revisão humana do PR |
