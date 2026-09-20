# Implementation Plan: Brownfield MultiRepo Context Awareness

**Branch**: `feature/014-brownfield-multirepo-context-awareness` | **Date**: 2026-08-21 | **Spec**: [spec.md](./spec.md)

## Summary

Criar dois scripts de automação (`generate-context-graph.sh` e `harvest-patterns.sh`)
e integrá-los ao workflow `/speckit-specify` do bundle. O objetivo é garantir que toda
nova Spec gerada em contexto brownfield multirepo: (1) tenha o grafo de dependências
entre repos do Bounded Context gerado automaticamente antes do plan, e (2) tenha os
padrões técnicos reutilizáveis dos repos existentes refletidos no `reuse-catalog.yaml`
antes que qualquer agente comece a propor soluções.

## Technical Context

**Language/Version**: Bash 5, YAML, Markdown; harvest usa LLM via API HTTP

**Primary Dependencies**: `gh` CLI ≥ 2.40, `yq` v4 (com fallback `python3 -c`), `curl` para chamadas LLM

**Storage**: `docs/bounded-contexts.yaml` (já implementado, feature 006), `docs/reuse-catalog.yaml` (atualizado pelo harvest)

**Testing**: `.bats` (bats-core) para scripts bash; testes manuais de integração contra repo sandbox

**Target Platform**: GHE Cloud (`venha-pra-nuvem.ghe.com`)

**Constraints**:
- `generate-context-graph.sh`: repos externos podem não estar disponíveis para clone → fallback via `gh api` obrigatório
- `harvest-patterns.sh`: exclusivamente on-demand (nunca em CI); envia apenas metadados estruturais (nomes de arquivo, assinaturas, anotações — nunca corpos de métodos)
- Endpoint e token LLM do harvest configuráveis via `HARVEST_API_URL` / `HARVEST_API_TOKEN`
- Ambos os scripts devem ser idempotentes

**Compatibilidade retroativa**: Features sem `bounded_contexts` em `feature.json` e specs sem `bounded-contexts.yaml` com repos mapeados continuam funcionando sem alteração.

## Constitution Check

| Gate | Status | Observação |
|---|---|---|
| Backup & DR | ✅ N/A | Sem datastore de produção — arquivos YAML e issues no GHE |
| Segredos no código | ✅ | `HARVEST_API_TOKEN` via env var; nunca hardcoded. `bounded-contexts.yaml` contém apenas metadados públicos |
| Branch/merge protegido | ✅ | PR obrigatório conforme regras da org |
| Isolamento de ambiente | ✅ | Todos os scripts usam parâmetros explícitos; sem variáveis hardcoded |
| Observabilidade | ✅ N/A | Scripts CLI sem SLO formal; output colorido + log de custo de tokens |
| IaC | ✅ N/A | Sem infraestrutura provisionada |

## Project Structure

### Artefatos de spec

```text
specs/014-brownfield-multirepo-context-awareness/
├── spec.md          ✅ Completo (clarify encerrado)
├── plan.md          # Este arquivo
├── graph.yaml       ✅ A criar
├── graph.md         ✅ A criar
├── impact-map.md    ✅ A criar (obrigatório S3)
└── tasks.md         # A criar por /speckit-tasks
```

### Arquivos novos

```text
scripts/
├── generate-context-graph.sh    ← NOVO — gera graph.yaml + graph.md para um bounded context
└── harvest-patterns.sh          ← NOVO — harvest de padrões via LLM; atualiza reuse-catalog.yaml

.github/workflows/
└── context-graph-refresh.yml    ← NOVO — CI: roda generate-context-graph.sh quando bounded-contexts.yaml muda

scripts/tests/
├── generate-context-graph.bats  ← NOVO — testes unitários bats-core (AC-1, AC-5, AC-6)
└── harvest-patterns.bats        ← NOVO — testes unitários bats-core (AC-3, AC-10 idempotência)
```

### Arquivos alterados

```text
.github/skills/speckit-specify/SKILL.md    ← + instrução de invocar generate-context-graph.sh (AC-2, AC-5)
presets/nimbus-code-standards/templates/project-root/copilot-instructions.md
                                           ← + passo obrigatório: consultar graph.yaml + reuse-catalog.yaml antes de /speckit-plan
presets/nimbus-code-standards/templates/plan-template.md
                                           ← + seção "Grafo do Contexto" (FR-009)
docs/module-graphs.md                      ← + seção "Grafos Multi-Repo e campo cross_repo"
docs/reuse-catalog.yaml                    ← + entrada brownfield-multirepo-context-graph ao fechar
```

---

## Nimbus-Code — Classificação de Complexidade (S0–S4)

| Campo | Valor |
|---|---|
| **Nível** | **S3** |
| **Justificativa** | Cruza múltiplos módulos: dois scripts novos com lógica de parsing multi-stack e chamada LLM, integração ao SKILL.md do speckit-specify, novo workflow de CI, atualização de template de preset e dois docs principais. Define nova etapa obrigatória no ciclo specify→plan que não existe hoje |
| **Modelo de IA** | Claude Sonnet (reasoning ativo) |
| **Revisão humana obrigatória** | Não (S3) — recomendada por impacto em tooling da org |
| **Padrão reutilizado encontrado?** | Sim — `multirepo-bounded-context-routing` (tag: feature 006) para schema de `bounded-contexts.yaml` e parsing `yq`/`python3`; `bootstrap-github-app-auth` (tag: feature 008) para padrão de autenticação via `GITHUB_TOKEN` |
| **Estimativa de tokens (input+output)** | ~45–65 mil tokens (S3, dois scripts novos com lógica de fallback + integração; desconto ~15% por reuso de padrões da feature 006) |

---

## Nimbus-Code — Harness Gate

| Harness consultado (ID) | Padrão de erro evitado | Mitigação preventiva aplicada nesta feature |
|---|---|---|
| HRN-0001 | Agent scope creep — editar arquivos fora do escopo declarado | Lista de arquivos em escopo declarada explicitamente no início de cada sessão de implement; bugs fora do escopo → Issue com `type:bug` |
| HRN-0002 | Decisão arquitetural imposta silenciosamente pelo agente | Todas as decisões arquiteturais desta feature registradas no ADL abaixo com alternativas consideradas; deploy `direct` justificado explicitamente |
| HRN-0003 | Feature S3 implementada sem consultar reuse-catalog.yaml | Consulta ao catálogo realizada antes deste plan — padrões `multirepo-bounded-context-routing` e `bootstrap-github-app-auth` identificados e referenciados |

**Resultado da consulta:**
- [x] Match encontrado — padrões HRN-0001, HRN-0002, HRN-0003 relevantes declarados acima e mitigados

---

## Nimbus-Code — Rastreabilidade AC → Teste → Módulo

| ID AC | Critério (resumo) | Tipo de teste | Arquivo/módulo do teste | Justificativa de ausência |
|---|---|---|---|---|
| AC-1 | `generate-context-graph.sh` lê `bounded-contexts.yaml` e gera `graph.yaml` + `graph.md` com nós e arestas | Unitário (bats) | `tests/scripts/generate-context-graph.bats` | — |
| AC-2 | `/speckit-specify` invoca o script automaticamente antes de abrir `spec.md` | Manual (instrução no SKILL.md validada numa sessão real de spec) | `SKILL.md` (inspeção) | Comportamento de agente não automatizável em CI |
| AC-3 | `harvest-patterns.sh` apontado para repo Java produz entradas com `tag`, `source`, `description` | Unitário (bats) com fixture Java | `tests/scripts/harvest-patterns.bats` | — |
| AC-4 | Após harvest, agente referencia entrada do catálogo no plan da próxima feature | Manual (sessão de plan com catálogo populado) | — | Comportamento de agente não automatizável em CI |
| AC-5 | Bounded context sem repos → aviso + prossegue sem bloqueio | Unitário (bats) | `tests/scripts/generate-context-graph.bats` | — |
| AC-6 | Em CI sem clone: fallback via `gh api` + log de repos não analisados | Unitário (bats) com mock de `gh api` | `tests/scripts/generate-context-graph.bats` | — |
| AC-governance | `harvest-patterns.sh` não aparece em nenhum workflow de CI | Inspeção estática dos `.github/workflows/*.yml` | — | Verificação de arquivo estático |

---

## Nimbus-Code — Module Dependency Graph

**Arquivos:**
- `specs/014-brownfield-multirepo-context-awareness/graph.yaml` — fonte de verdade estruturada
- `specs/014-brownfield-multirepo-context-awareness/graph.md` — diagramas Mermaid
- `specs/014-brownfield-multirepo-context-awareness/impact-map.md` — **obrigatório (S3)**

**Checklist:**
- [x] `graph.yaml` criado com todos os nós e arestas desta feature
- [x] `graph.md` criado com diagrama por código e diagrama por business
- [x] `impact-map.md` criado com análise de risco e plano de rollback
- [x] Nodes `cross_repo: true` usados para repos externos (schema estendido — ADL-001 abaixo)
- [x] Dependências externas (LLM API, `gh` CLI, GHE GraphQL API, `yq`/`python3`) declaradas em `externals`

---

## Nimbus-Code — Estratégia de Release

| Campo | Valor |
|---|---|
| **Estratégia** | `direct` |
| **Feature flag name** | N/A |
| **Justificativa** | Scripts shell, YAML de template e docs — sem runtime de produção. "Deploy" = merge no branch principal do template. Rollback = reverter o commit. Os dois scripts novos são adicionais (não substituem nada existente) — impacto zero em features não-brownfield |

---

## Nimbus-Code — Cost Reference

| Campo | Valor |
|---|---|
| **Token estimate range** | ~45–65 mil tokens |
| **Human effort estimate range** | ~2–4 horas (revisão dos scripts e validação manual dos ACs) |
| **Tracking method** | Tabela "Estimativa vs. Consumo Real" no tasks.md + campo "Horas Humanas" no GitHub Project |
| **Budget ceiling** | N/A |

---

## Nimbus-Code — SLO Gate

| Componente | Latência p99 | Taxa de erro máx. | Disponibilidade | RTO | RPO |
|---|---|---|---|---|---|
| `generate-context-graph.sh` | — | 0% de grafo vazio quando bounded context tem ≥2 repos mapeados | — | — | — |
| `harvest-patterns.sh` | — | 0% de saída sem conteúdo quando repo tem código elegível | — | — | — |
| `context-graph-refresh.yml` (CI) | — | 0% de falha silenciosa (falhas devem ser reportadas no log do workflow) | — | — | — |

> Scripts CLI on-demand e CI sem SLO de latência de usuário mensurável. Os critérios de erro acima são binários.

---

## Nimbus-Code — Security & DevSecOps Gate

| Domínio | Controles aplicáveis | Escapável via ADL? | Status | Observações |
|---|---|---|---|---|
| **Backup & Disaster Recovery** | Sem datastore novo de produção | N/A | ✅ N/A | Apenas arquivos YAML e issues no GHE |
| Autenticação (SSO) | N/A — sem sistema com login de usuário | N/A | ✅ N/A | Scripts CLI/CI |
| Segredos no código | `HARVEST_API_TOKEN` via env var; `GITHUB_TOKEN` via `gh` CLI; nenhum secret hardcoded | **Não — bloqueante** | ✅ | Verificado: nenhum secret em texto plano nos scripts |
| Branch/merge protegido | PR obrigatório + revisão antes de merge | **Não — bloqueante** | ✅ | Vigente no bundle |
| Isolamento de ambiente | Parâmetros explícitos em todos os scripts; sem variáveis globais com credenciais | **Não — bloqueante** | ✅ | |
| Privacidade de código-fonte no harvest | Apenas metadados estruturais enviados ao LLM (nomes, assinaturas, anotações) — nunca corpo de métodos, strings literais ou dados de runtime | **Não — bloqueante** | ✅ | Definido em FR-004; mitigação documentada no ADL |
| Containers | N/A — scripts shell | N/A | ✅ N/A | |
| CI/CD | `GITHUB_TOKEN` via secrets do CI; least privilege | Sim | ✅ configuração local | Workflow `context-graph-refresh.yml` usa `contents: read` e publica artefatos; não commita o grafo automaticamente |
| IaC | N/A — sem infra provisionada | N/A | ✅ N/A | |
| Observabilidade | Log de custo de tokens a cada execução do harvest; output colorido nos scripts | Sim | ✅ | Scripts CLI/CI |

**Riscos identificados:**

- **Vazamento de código proprietário via harvest**: se o script não filtrar corretamente os metadados. **Mitigação**: implementar allowlist de campos extraídos (nomes de arquivo, assinaturas de método/interface, anotações/decoradores) com rejeição explícita de qualquer campo que contenha literais de string ou corpo de método. Coberto por FR-004.
- **Custo de tokens descontrolado**: harvest rodando inadvertidamente em CI. **Mitigação**: FR-011 proíbe explicitamente; `harvest-patterns.sh` não é referenciado em nenhum workflow de CI (verificado por inspeção estática no AC-governance).
- **Dependência circular no grafo**: dois repos com dependência mútua. **Mitigação**: `generate-context-graph.sh` detecta ciclos, representa no grafo sem loop infinito e emite aviso visual no `graph.md` (coberto pelo edge case da spec).

---

## Nimbus-Code — Qualidade de Código, Testes e Observabilidade Gate

| Domínio | Controles | Status | Observações |
|---|---|---|---|
| Revisão de código por IA | Copilot Code Review em todos os PRs | ✅ | |
| Testes integrados | AC-1, AC-3, AC-5, AC-6 com testes bats-core; AC-2, AC-4 manuais com justificativa | ✅ | Ver tabela Rastreabilidade acima |
| Observabilidade | Log de tokens a cada execução do harvest; saída colorida com resumo de repos analisados | ✅ | |
| Arquitetura distribuída | N/A — scripts CLI/CI sem chamadas entre serviços (harvest chama LLM API de forma unidirecional) | ✅ N/A | |
| Gestão de bugs | Bugs fora do escopo → Issues com `type:bug` atribuídas ao Copilot Agent | ✅ | |

**Critérios sem teste automatizado:**
- AC-2: invocação do script pelo agente — comportamento de agente IA não automatizável em CI; validado manualmente em sessão de spec com `bounded-contexts.yaml` preenchido.
- AC-4: referência ao catálogo pelo agente no plan — idem.

---

## Nimbus-Code — Architecture Decision Log

| Decisão | Alternativas consideradas | Opção escolhida | Trade-off assumido | Justificativa | Aprovado por |
|---|---|---|---|---|---|
| **ADL-001**: Campo `cross_repo: true` no `graph.yaml` para nodes de repos externos | (A) Reusar schema atual sem mudança · **(B) Estender com `cross_repo: true`** | **Estender com `cross_repo: true`** | Leve extensão de schema que deve ser retrocompatível (campo opcional); benefício: Graph Guard pode distinguir módulo local de repo externo e aplicar regras diferentes | Sem o campo, o Graph Guard não consegue saber se um node é um módulo do repo atual ou um repo externo — o que pode gerar falsos positivos de "módulo não encontrado" | Dev (sessão clarify 2026-08-21) |
| **ADL-002**: Localização dos scripts | (A) `scripts/` · (B) `.specify/scripts/bash/` | **`scripts/`** | Scripts em `scripts/` são mais visíveis e alinhados com `setup-github-project.sh`; `.specify/scripts/bash/` é reservado para scripts do workflow interno de spec | Consistência com a estrutura existente do bundle | Dev (sessão clarify 2026-08-21) |
| **ADL-003**: Output do harvest direto no catálogo vs. arquivo candidato | (A) Direto no `reuse-catalog.yaml` · (B) Arquivo `reuse-catalog.candidates.yaml` separado | **Direto no `reuse-catalog.yaml`** com aviso de duplicata e `git diff` como gate de revisão | Menor fricção para o Dev; risco de entrada ruim no catálogo mitigado pela revisão obrigatória via `git diff` antes de commit | O arquivo candidato separado adiciona uma etapa manual de mesclagem que pode ser esquecida; o `git diff` já é o gate natural de revisão no fluxo Git | Dev (sessão clarify 2026-08-21) |
| **ADL-004**: Harvest via LLM vs. análise estática determinística | (A) LLM via API · (B) Análise estática (AST/grep) | **LLM via API** com metadados estruturais apenas | LLM detecta padrões semânticos (ex.: "este é o padrão Port & Adapter") que análise estática não consegue nomear; risco: custo de tokens e privacidade. Mitigações: on-demand apenas + apenas metadados estruturais | Análise estática é mais barata mas produz heurísticas sem contexto arquitetural (ex.: "há muitas interfaces" mas não "isso é o padrão Port & Adapter do DDD") | Dev (sessão clarify 2026-08-21) |
| **ADL-005**: Deploy `direct` para feature S3 | `flag` / `canary` / `direct` | **`direct`** | Sem runtime de produção — apenas scripts shell e templates. Rollback = `git revert`. Sem usuários afetados em tempo real | Scripts adicionais sem substituição de código existente; impacto zero em features não-brownfield. Exigir flag para scripts CLI seria overhead sem benefício de segurança | Dev (sessão clarify 2026-08-21) |
