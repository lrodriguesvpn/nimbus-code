# Implementation Plan: MultiRepo Support no Spec Kit Template

**Branch**: `feature/006-multirepo-support` | **Date**: 2026-08-18 | **Spec**: [spec.md](./spec.md)

## Summary

Estender o template Nimbus Code para suportar a estratégia **1 Repo Central de
Specs + N Repos por stack/microsserviço**. O fluxo `/speckit-specify` →
`/speckit-taskstoissues` passa a saber em quais repos criar cada tipo de issue:
Epics/Features/USs no repo central; Tasks nos repos dos serviços. O
`setup-github-project.sh` vincula todos os repos ao Project V2 central
automaticamente, criando um board cross-repo.

## Technical Context

**Language/Version**: Bash 5, YAML, Markdown

**Primary Dependencies**: `gh` CLI ≥ 2.40, `yq` v4 (com fallback para `python3 -c`)

**Storage**: `docs/bounded-contexts.yaml` (novo), `.specify/feature.json` (estendido)

**Testing**: Manual contra repo sandbox; sem CI automatizado para GHE API

**Target Platform**: GHE Cloud (`venha-pra-nuvem.ghe.com`); degradação graciosa para GHE Server < 3.10

**Constraint principal**: API `linkProjectV2ToRepository` disponível no GHE ≥ 3.8;
`yq` pode não estar disponível → fallback para `python3` ou `grep`/`awk`

**Compatibilidade retroativa**: Features sem `bounded_contexts` em `feature.json`
devem continuar funcionando exatamente como hoje (single-repo)

## Constitution Check

| Gate | Status | Observação |
|---|---|---|
| Backup & DR | N/A | Sem datastore de produção — apenas arquivos de configuração e issues no GHE |
| Segredos no código | ✅ | Scripts usam `gh` CLI com token do ambiente; `bounded-contexts.yaml` contém apenas metadados públicos |
| Branch/merge protegido | ✅ | PR obrigatório conforme regras da org |
| Isolamento de ambiente | ✅ | `--repo-owner`/`--repo-name` explícitos; sem variáveis hardcoded |
| Observabilidade | N/A | Scripts CLI sem SLO formal; output colorido via `echo` |
| IaC | N/A | Sem infraestrutura provisionada |

## Project Structure

### Artefatos de spec (nova pasta)

```text
specs/006-multirepo-support/
├── spec.md          ✅ Completo
├── plan.md          # Este arquivo
├── graph.yaml       # Grafo de módulos
├── graph.md         # Diagramas Mermaid
├── impact-map.md    # Obrigatório (S3)
└── tasks.md         # A criar por /speckit-tasks
```

### Arquivos alterados fora da spec

```text
docs/
├── bounded-contexts.yaml            ← NOVO — registro central de bounded contexts e repos
└── developer-guide.md               ← + seção "MultiRepo — Registrando Microsserviços"
docs/
└── reuse-catalog.yaml               ← + entrada multirepo-bounded-context-routing

.specify/presets/nimbus-code-standards/templates/project-root/
└── bounded-contexts.yaml            ← template atualizado com repository/stack/team/autonomous_ok

.specify/scripts/bash/
└── create-new-feature.sh            ← + flag --bounded-contexts + resolução de repos + persistência em feature.json

scripts/
└── setup-github-project.sh          ← + leitura de bounded-contexts.yaml + linkProjectV2ToRepository por repo
```

---

## Nimbus-Code — Classificação de Complexidade (S0–S4)

| Campo | Valor |
|---|---|
| **Nível** | **S3** |
| **Justificativa** | Cruza múltiplos módulos: `bounded-contexts.yaml` (novo artefato), `feature.json` (estendido), `create-new-feature.sh`, `setup-github-project.sh`, `developer-guide.md`, template de preset. Integra GHE GraphQL API `linkProjectV2ToRepository` e lógica de roteamento cross-repo |
| **Modelo de IA** | Claude Sonnet (reasoning ativo) |
| **Revisão humana obrigatória** | Não (S3) — recomendada por impacto em tooling da org toda |
| **Padrão reutilizado encontrado?** | Sim — `ghe-sub-issues-hierarchy` (tag: specs/005) para detecção de suporte da org; `speckit-deduplication-by-id` (tag: specs/005) para deduplicação cross-repo |
| **Estimativa de tokens (input+output)** | ~40–60 mil tokens (S3, múltiplos módulos; desconto ~15% por reuso de padrões da feature 005) |

---

## Nimbus-Code — Rastreabilidade AC → Teste → Módulo

| ID AC | Critério (resumo) | Tipo de teste | Módulo | Justificativa de ausência |
|---|---|---|---|---|
| AC-1 | Schema `bounded-contexts.yaml` validado pelos scripts | Manual | `setup-github-project.sh` | GHE API real necessária |
| AC-2 | Agente rejeita slug não cadastrado | Manual (sessão com slug inválido) | `docs/copilot-instructions.md` | Comportamento de agente não automatizável em CI |
| AC-3 | `autonomous_ok: false` → label `agent:needs-human` | Manual (inspeção da issue) | `taskstoissues` | GHE API real necessária |
| AC-4 | `--bounded-contexts` persiste em `feature.json` com repos resolvidos | Manual + inspeção JSON | `create-new-feature.sh` | Candidato a teste unitário bash (bats) em fase futura |
| AC-5 | Campo ausente = comportamento single-repo | Manual | `create-new-feature.sh` | GHE API real necessária |
| AC-6 | Slug inválido aborta com lista de válidos | Manual | `create-new-feature.sh` | Candidato a teste unitário bash futuro |
| AC-7 | Tasks roteadas para repos corretos por seção `[USN — slug]` | Manual (inspeção GHE) | `taskstoissues` | GHE API real necessária |
| AC-8 | Repo inacessível: erro isolado, não aborta outros | Manual | `taskstoissues` | GHE API real necessária |
| AC-9 | Deduplicação cross-repo na re-execução | Manual (2x) | `taskstoissues` | Reusa padrão `speckit-deduplication-by-id` |
| AC-10 | Feature single-repo = comportamento atual (retrocompatibilidade) | Manual | `taskstoissues` | Teste de regressão manual |
| AC-11 | `setup-github-project.sh` vincula repos ao Project V2 | Manual (verificar Linked Repos) | `setup-github-project.sh` | GHE GraphQL API real necessária |
| AC-12 | Vínculo idempotente | Manual (2x) | `setup-github-project.sh` | GHE API real necessária |
| AC-13 | `bounded-contexts.yaml` ausente → aviso, não aborta | Manual | `setup-github-project.sh` | Simples de testar manualmente |
| AC-14 | Documentação completa para novo colaborador | Manual (walkthrough) | `docs/developer-guide.md` | Validação humana |
| AC-15 | Template `bounded-contexts.yaml` com campos completos | Inspeção do arquivo | Template no preset | N/A — verificação de arquivo estático |

---

## Nimbus-Code — Module Dependency Graph

**Arquivos:**
- `specs/006-multirepo-support/graph.yaml` — fonte de verdade estruturada
- `specs/006-multirepo-support/graph.md` — diagramas Mermaid
- `specs/006-multirepo-support/impact-map.md` — **obrigatório (S3)**

**Checklist:**
- [x] `graph.yaml` criado com todos os nós e arestas desta feature
- [x] `graph.md` criado com diagrama por código e diagrama por business
- [x] `impact-map.md` criado com análise de risco e plano de rollback
- [x] Dependências externas (`gh CLI`, `yq/python3`, GHE GraphQL API) declaradas em `externals`
- [x] GHE GraphQL API `linkProjectV2ToRepository` declarada como external

---

## Nimbus-Code — Estratégia de Release

| Campo | Valor |
|---|---|
| **Estratégia** | `direct` |
| **Feature flag name** | N/A |
| **Justificativa** | Scripts shell e YAML de template — sem runtime de produção. "Deploy" = merge no branch principal do template. Rollback = reverter o commit. Não há usuários afetados em tempo real |

---

## Nimbus-Code — SLO Gate

| Componente | Latência p99 | Taxa de erro máx. | Disponibilidade | RTO | RPO |
|---|---|---|---|---|---|
| Scripts bash (setup/create-feature) | — | 0% (idempotentes) | — | — | — |

> Scripts CLI locais/CI — sem SLO de disponibilidade mensurável.

---

## Nimbus-Code — Security & DevSecOps Gate

| Domínio | Controles aplicáveis | Escapável via ADL? | Status | Observações |
|---|---|---|---|---|
| **Backup & Disaster Recovery** | Sem datastore novo de produção | N/A | ✅ N/A | Apenas arquivos de configuração e issues no GHE |
| Segredos no código | Scripts usam `gh` CLI com token do ambiente; `bounded-contexts.yaml` contém apenas nomes de repos (metadado público) | **Não — bloqueante** | ✅ | Nenhum secret hardcoded |
| Branch/merge protegido | PR obrigatório conforme regras da org | **Não — bloqueante** | ✅ | Já vigente |
| Isolamento de ambiente | `--repo-owner`/`--repo-name` explícitos; nenhuma variável de ambiente hardcoded | **Não — bloqueante** | ✅ | |
| IaC | Sem infra provisionada | N/A | ✅ N/A | |
| Observabilidade | Scripts CLI sem SLO formal; output colorido | Sim | ✅ N/A | Scripts locais/CI |

**Riscos identificados:**
- **Cross-repo permission scope**: o token `gh` precisa de `write:org` para `linkProjectV2ToRepository`. **Mitigação**: imprimir erro claro com instrução de escopo necessário; não abortar o restante do setup.
- **`yq` ausente no CI**: alguns runners não têm `yq`. **Mitigação**: fallback para `python3 -c`; se ambos ausentes, imprimir instrução de instalação e pular a etapa sem abortar.

---

## Nimbus-Code — Qualidade de Código, Testes e Observabilidade Gate

| Domínio | Controles | Status | Observações |
|---|---|---|---|
| Revisão de código por IA | Copilot Code Review em todos os PRs | ✅ | |
| Testes integrados | Manual — GHE API real necessária | Manual justificado | Sem ambiente de CI mockado disponível |
| Observabilidade | Output colorido por `echo` | ✅ N/A | Scripts CLI |
| Arquitetura distribuída | N/A — scripts locais/CI | N/A | |
| Gestão de bugs | Bugs fora do escopo → Issues abertas ao Copilot Agent | ✅ | |

---

## Nimbus-Code — Architecture Decision Log

| Decisão | Alternativas | Opção escolhida | Trade-off | Justificativa | Aprovado por |
|---|---|---|---|---|---|
| Parsing de `bounded-contexts.yaml` em bash | `yq` v4 · `python3 -c 'import yaml'` · `grep`/`awk` manual | **`yq` com fallback para `python3`** | `yq` não está em todos os ambientes; python3 está em macOS/Ubuntu modernos | Evita quebrar scripts em ambientes sem `yq` | — |
| Anotação de bounded context em `tasks.md` | Novo campo JSON · Anotação inline `[US1 — slug]` | **Anotação inline: `[US1 — auth]`** | Não requer mudança de schema; legível por humano; parsed por regex simples | Menor surface de mudança | — |
| Retrocompatibilidade | Quebrar / Campo opcional com default `[]` | **Campo opcional — default `[]`** | Zero breaking change; custo: lógica de branch no taskstoissues | Preservar features single-repo existentes | — |
