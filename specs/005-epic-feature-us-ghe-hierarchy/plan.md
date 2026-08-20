# Implementation Plan: Epic/Feature/US Hierarchy no GHE com Spec Kit

**Branch**: `feature/005-epic-feature-us-ghe-hierarchy` | **Date**: 2026-08-18 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/005-epic-feature-us-ghe-hierarchy/spec.md`

## Summary

Estender o fluxo do Spec Kit (`.specify/`, `scripts/`, `docs/`) para criar e
vincular automaticamente uma hierarquia **Epic → Feature → User Story → Task**
no GHE. O fluxo deve:

1. Registrar o Epic Issue em `feature.json` ao rodar `/speckit-specify`
2. Criar Feature/US/Task como sub-issues com os `type:` corretos ao rodar
   `/speckit-taskstoissues`
3. Garantir deduplicação por ID de tarefa (`T00N`) em execuções repetidas
4. Degradar graciosamente para labels (`type:epic` etc.) quando Issue Types
   nativos da org não estiverem disponíveis
5. Fornecer views de Project V2 organizadas por nível hierárquico via
   `setup-github-project.sh`
6. Documentar o fluxo completo no `developer-guide.md`

## Technical Context

**Language/Version**: Bash 5 (scripts existentes), Markdown (docs/templates)

**Primary Dependencies**: `gh` CLI ≥ 2.40 (GraphQL sub-issues API), `jq` ≥ 1.6

**Storage**: `.specify/feature.json` (estendido com `epic_issue`)

**Testing**: Execução manual (`./scripts/setup-github-*.sh` contra repo de
sandbox); sem testes automatizados em CI para esta fase (scripts shell)

**Target Platform**: GitHub Enterprise Cloud (`venha-pra-nuvem.ghe.com`);
degradação graciosa para GHE Server sem Issue Types nativos

**Project Type**: Tooling / scripts de automação DevOps

**Performance Goals**: `setup-github-project.sh` concluído em < 60s (SC-004)

**Constraints**: Sub-issues API paginada; limite de 100 sub-issues por parent
(GHE); idempotência obrigatória (scripts podem ser re-executados)

**Scale/Scope**: Org `venha-pra-nuvem`, todos os repositórios usando Spec Kit

## Constitution Check

| Gate | Status | Observação |
|---|---|---|
| Backup & DR | N/A | Nenhum datastore de produção novo — apenas arquivos de config e issues no GHE |
| Segredos no código | ✅ | Scripts usam `gh` CLI com token do ambiente, sem hardcoded credentials |
| Branch/merge protegido | ✅ | PR obrigatório conforme regras da org |
| Isolamento de ambiente | ✅ | Scripts direcionados ao repo-owner/repo-name passado como argumento |
| Observabilidade | N/A | Scripts shell sem SLO formal; output de progresso via `echo` colorido |
| IaC | N/A | Sem infraestrutura provisionada nesta feature |

## Project Structure

### Documentation (this feature)

```text
specs/005-epic-feature-us-ghe-hierarchy/
├── spec.md              ✅ Completo
├── plan.md              # Este arquivo
├── graph.yaml           # Grafo de módulos
├── graph.md             # Diagramas Mermaid
├── impact-map.md        # Obrigatório (S3)
└── tasks.md             # Gerado por /speckit-tasks
```

### Arquivos alterados (fora da pasta de spec)

```text
.specify/
└── feature.json                   # + campo epic_issue (opcional)

scripts/
├── setup-github-labels.sh         # + labels type:epic/feature/user-story
└── setup-github-project.sh        # + Issue Types + views hierárquicas

docs/
└── developer-guide.md             # + seção "Hierarquia Agile"

docs/
└── reuse-catalog.yaml             # + entradas ghe-sub-issues-hierarchy,
                                   #   speckit-deduplication-by-id
```

---

## Nimbus-Code — Classificação de Complexidade (S0–S4)

| Campo | Valor |
|---|---|
| **Nível** | **S3** |
| **Justificativa** | Cruza múltiplos módulos: `.specify/feature.json`, `/speckit-specify`, `/speckit-taskstoissues`, `setup-github-project.sh`, `setup-github-labels.sh`, `developer-guide.md`. Integra com GHE GraphQL API (sub-issues, Issue Types, Projects v2) |
| **Modelo de IA** | Claude Sonnet (reasoning ativo) |
| **Revisão humana obrigatória** | Não (S3 — mas recomendada por impacto em tooling de toda a org) |
| **Padrão reutilizado encontrado?** | Não — `docs/reuse-catalog.yaml` está vazio. Esta feature introduz dois novos padrões que serão adicionados ao catálogo ao fechar |
| **Estimativa de tokens (input+output)** | ~35–55 mil tokens |

---

## Nimbus-Code — Rastreabilidade AC → Teste → Módulo

| ID AC | Critério (resumo) | Tipo de teste planejado | Arquivo/módulo do teste | Justificativa de ausência |
|---|---|---|---|---|
| SC-001 | Dev novo cria Epic+2 Features+4 US em < 30 min | Manual (smoke test) | `docs/developer-guide.md` — walkthrough | Teste automatizado inviável: requer interação humana real |
| SC-002 | 100% das Tasks como sub-issues da US correta | Manual (inspeção no GHE após execução) | `scripts/setup-github-project.sh` | Sem infra de teste de integração para GHE API em CI |
| SC-003 | Sub-issue progress roll-up automático no Project V2 | Manual (verificação na UI) | `scripts/setup-github-project.sh` | Comportamento nativo do GHE, não testável em CI |
| SC-004 | `setup-github-project.sh` idempotente e < 60s | Manual (executar 2x no mesmo repo) | `scripts/setup-github-project.sh` | Sem infra de teste de integração para GHE API em CI |
| SC-005 | Funciona sem erros em GHE Server (fallback labels) | Manual (rodar em repo de teste sem Issue Types) | `scripts/setup-github-labels.sh` | Requer GHE Server de teste, indisponível em CI |
| SC-006 | Deduplicação: sem duplicatas em re-execução | Manual (executar `/speckit-taskstoissues` 2x) | `.specify/` scripts | Sem infra de teste de integração para GHE API em CI |

**Critérios sem teste de integração automatizado:** Todos os critérios de aceite
dependem da GHE API real (sub-issues, Issue Types, Projects v2). A API não é
mockável de forma confiável em CI sem um servidor GHE de teste dedicado —
indisponível para esta fase. Todos os cenários serão validados manualmente
contra o repo `venha-pra-nuvem/nimbus-code-spec-kit-template`.

---

## Nimbus-Code — Module Dependency Graph

**Arquivos:**
- `specs/005-epic-feature-us-ghe-hierarchy/graph.yaml`
- `specs/005-epic-feature-us-ghe-hierarchy/graph.md`
- `specs/005-epic-feature-us-ghe-hierarchy/impact-map.md`

**Checklist de manutenção do grafo:**
- [x] `graph.yaml` criado com todos os nós e arestas desta feature
- [x] `graph.md` criado com diagrama por código e diagrama por business
- [x] `impact-map.md` criado (S3 — obrigatório)
- [x] Nenhum módulo/serviço novo criado falta no grafo
- [x] Dependências externas declaradas em `externals` no `graph.yaml`
- [ ] Grafo será atualizado após implementação se divergir do plano

---

## Nimbus-Code — Estratégia de Release

| Campo | Valor |
|---|---|
| **Estratégia** | `direct` |
| **Feature flag name** | N/A |
| **Flag provider** | N/A |
| **Critério de ativação** | N/A — scripts shell e documentação, sem serviço em produção |
| **Critério de rollback** | Reverter o PR; os scripts são idempotentes e o campo `epic_issue` em `feature.json` é opcional — sem breaking change |

**Justificativa para deploy `direct`:**
Esta feature é composta exclusivamente de scripts shell, templates Markdown e
documentação. Não há serviço exposto, dado persistido em datastore de produção
nem fluxo de usuário final. O impacto é restrito a quem executa os scripts
explicitamente. Deploy direto é adequado e proporcionado ao risco.

---

## Nimbus-Code — SLO Gate

| Componente | Latência p99 | Taxa de erro máx. | Disponibilidade | RTO | RPO |
|---|---|---|---|---|---|
| `setup-github-project.sh` | < 60s (execução local) | 0% (idempotente, sem side-effect parcial) | — | N/A | N/A |
| `setup-github-labels.sh` | < 30s | 0% | — | N/A | N/A |

**SLOs não definidos:** Todos os componentes são scripts shell de uso pontual
(não são serviços online), portanto sem SLO de disponibilidade ou RPO/RTO.
Monitoramento via saída colorida dos scripts e inspeção manual no GHE.

---

## Nimbus-Code — Security & DevSecOps Gate

| Domínio | Controles aplicáveis | Escapável via ADL? | Status | Observações |
|---|---|---|---|---|
| Backup & DR | N/A — sem datastore de produção | — | ✅ N/A | Issues no GHE são gerenciadas pela plataforma; backup institucional do GHE em responsabilidade da plataforma |
| Segredos no código | Scripts usam `$GH_TOKEN` / `gh` CLI auth — sem credencial hardcoded | Não — bloqueante | ✅ | Verificado: nenhum secret em texto plano nos scripts |
| Branch/merge protegido | PR obrigatório, CI não bloqueado (sem CI para scripts shell) | Não — bloqueante | ✅ | Sem CI automático para shell scripts — revisão humana no PR compensa |
| Isolamento de ambiente | Scripts direcionados ao `--repo-owner`/`--repo-name` passado como arg | Não — bloqueante | ✅ | Não há acesso cross-repo sem argumento explícito |
| Observabilidade | N/A para scripts CLI | Sim, com justificativa | ✅ N/A | Scripts de automação CLI sem SLO de observabilidade |
| IaC | N/A — sem infraestrutura provisionada | — | ✅ N/A | |
| Banco de dados / TLS | N/A | — | ✅ N/A | |
| Firewall | N/A | — | ✅ N/A | |

**Riscos identificados:** Nenhum risco de segurança relevante identificado.
Os scripts consomem a GHE API via `gh` CLI (TLS obrigatório no transport),
sem armazenar credenciais e sem side-effects em produção além de criar/atualizar
issues e views de Project no repositório alvo.

---

## Nimbus-Code — Qualidade de Código, Testes e Observabilidade Gate

| Domínio | Controles aplicáveis | Status | Observações |
|---|---|---|---|
| Revisão de código por IA | GitHub Copilot code review solicitado no PR | ✅ | PR desta feature incluirá revisão Copilot |
| Testes integrados | Testes manuais contra repo de sandbox (detalhados na tabela de rastreabilidade) | ⚠️ Manual | GHE API real não mockável em CI — todos os SC validados manualmente |
| Observabilidade | Output colorido nos scripts; sem serviço em produção | ✅ N/A | |
| Arquitetura distribuída | N/A — sem chamadas entre serviços próprios | ✅ N/A | |
| Gestão de bugs | Bugs fora do escopo serão abertos como Issue | ✅ | |

**Critérios sem teste de integração:** Todos — ver justificativa na tabela de
Rastreabilidade AC acima.

---

## Nimbus-Code — Architecture Decision Log

| Decisão | Alternativas consideradas | Opção escolhida | Trade-off assumido | Justificativa do desvio | Aprovado por |
|---|---|---|---|---|---|
| Estratégia de deploy | `flag` vs `direct` | `direct` | Sem rollout incremental — todos os usuários dos scripts recebem a mudança ao mesmo tempo | Feature é tooling/scripts, sem serviço online; risco mínimo e reversão trivial via git revert | — |
| Deduplicação por ID de tarefa | Por título vs por ID `T00N` | Por ID `T00N` | Título pode mudar após criação; ID é estável enquanto `tasks.md` não for regenerado | Evita duplicatas em re-execuções sem depender de texto mutável | — |
| Fallback para labels vs erro fatal | Abortar se Issue Types ausentes vs degradar com labels | Degradar com labels `type:epic`, `type:feature`, `type:user-story` | Hierarquia menos rica na UI mas o fluxo não quebra em GHE Server | Compatibilidade com instalações GHE Server legadas da org | — |
| Testes manuais vs CI automático | CI com mock vs manual | Manual contra sandbox GHE real | Cobertura menor em automação | GHE sub-issues API não possui mock confiável disponível; custo de manter mock > risco | — |
