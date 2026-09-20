# Tasks: Brownfield MultiRepo Context Awareness — Harvest Automático de Padrões e Grafo de Repositórios por Bounded Context

**Estado auditado em 2026-09-20**: implementação e testes locais presentes;
revisão humana #440 permanece aberta. O `checklists/requirements-quality.md`
alegado como 10/10 em #440 não existe neste checkout. Execução de testes,
harvest via LLM e integrações reais não são comprovadas pela narrativa da
issue. T033 foi reaberta: tabela estrutural não equivale a consumo medido.

**Input**: Design documents from `/specs/014-brownfield-multirepo-context-awareness/`

**Prerequisites**: `plan.md` ✅, `spec.md` ✅, `graph.yaml` ✅, `graph.md` ✅, `impact-map.md` ✅ (S3 — obrigatório)

**Organization**: Tasks agrupadas por User Story (P1, P1, P1, P2) para entrega incremental e teste independente, conforme `spec.md`.

**Tests**: Testes `.bats` (bats-core) para os scripts bash (AC-1, AC-3, AC-5, AC-6); testes manuais para comportamentos de agente (AC-2, AC-4) — justificativas no `plan.md`.

---

## Phase 1: Setup

**Purpose**: Verificação do ambiente e baseline — condição de entrada para todas as User Stories

- [x] T001 Verificar que `docs/bounded-contexts.yaml` existe e tem ao menos um bounded context com ≥2 repos mapeados (insumo real para os testes de AC-1 e AC-5) — registrar o resultado como pré-condição dos testes
- [x] T002 [P] Verificar que `docs/reuse-catalog.yaml` existe e anotar o número de entradas atuais (baseline para validar idempotência dos scripts em FR-010)
- [x] T003 [P] Confirmar se `bats-core` já está instalado ou disponível em `scripts/setup-dev-environment.sh`; se não estiver, anotar a lacuna para T012
- [x] T004 [P] Listar os arquivos de manifesto de dependência presentes nos repos de teste declarados em `bounded-contexts.yaml` (`pom.xml`, `package.json`, `go.mod`, `requirements.txt`, `build.gradle`) para calibrar os fixtures dos testes bats

**Checkpoint**: Ambiente e artefatos-base confirmados — implementação pode começar.

---

## Phase 2: User Story 1 — Script `generate-context-graph.sh` (Priority: P1) 🎯 MVP

**Goal**: Dado um `bounded-contexts.yaml` com repos mapeados, `generate-context-graph.sh <context-slug> [--feature <slug>]` gera `specs/<feature>/graph.yaml` e `graph.md` com nós e arestas corretos.

**Independent Test**: Dado um `bounded-contexts.yaml` com 3 repos mapeados num mesmo contexto, executar `generate-context-graph.sh context-slug` e verificar que `graph.yaml` contém 3 nós e que `graph.md` renderiza um diagrama Mermaid válido com as arestas de dependência (Independent Test do `spec.md`, US1).

- [x] T005 [US1] Criar `scripts/generate-context-graph.sh` com a assinatura `<context-slug> [--feature <slug>]` — estrutura de ajuda (`--help`), leitura de `docs/bounded-contexts.yaml` via `yq` com fallback `python3 -c`, e scaffold do output (`graph.yaml` + `graph.md`) (FR-001, FR-002)
- [x] T006 [US1] Implementar a lógica de análise de manifestos de dependência para cada repo do contexto: prioridade `pom.xml` → `package.json` → `go.mod` → `requirements.txt` → `build.gradle`; gerar nós com campo `cross_repo: true` para repos externos (ADL-001 do `plan.md`) e arestas direcionadas (FR-001, AC-1)
- [x] T007 [US1] Implementar fallback via `gh api` para repos não acessíveis por clone (FR-003, AC-6) — documentar no output quais repos foram analisados localmente vs. via API; detectar e representar dependências circulares sem loop infinito (edge case do `spec.md`)
- [x] T008 [US1] Implementar tratamento de manifest corrompido/inválido isolado por repo — registrar a falha de parse para aquele repo sem abortar os demais (edge case do `spec.md`)
- [x] T009 [US1] Implementar detecção de bounded context sem repos mapeados: emitir aviso e sair com código não-bloqueante (AC-5, FR-001)
- [x] T010 [US1] Garantir idempotência: duas execuções com os mesmos inputs NÃO devem sobrescrever um grafo mais recente com um mais antigo (FR-010, SC-005)
- [x] T011 [P] [US1] Criar `tests/scripts/generate-context-graph.bats` cobrindo: `test_AC1_generate_context_graph_output`, `test_AC5_graceful_fallback_no_repos`, `test_AC6_ci_api_fallback` — usar fixtures de `bounded-contexts.yaml` e mock de `gh api` (plan.md — Rastreabilidade AC → Teste → Módulo)
- [x] T012 [P] [US1] Instalar `bats-core` em `scripts/setup-dev-environment.sh` se a lacuna foi confirmada em T003

**Checkpoint**: `generate-context-graph.sh` funcional e testes passando — MVP entregável como script standalone antes mesmo da integração ao `/speckit-specify`.

---

## Phase 3: User Story 2 — Script `harvest-patterns.sh` (Priority: P1)

**Goal**: `harvest-patterns.sh <repo-path> [--subpath <dir>] [--output <arquivo>]` produz entradas no formato `reuse-catalog.yaml` com `tag`, `bounded_context`, `description`, `source` e `example` preenchidos, via LLM.

**Independent Test**: Apontar `harvest-patterns.sh` para um repo Java com interfaces públicas em pacotes de domínio e verificar que a saída contém ao menos uma entrada com `tag` relacionada a interfaces/extensão, `source` apontando para um arquivo real do repo, e `description` que um Dev reconheceria como correto (Independent Test do `spec.md`, US2).

- [x] T013 [US2] Criar `scripts/harvest-patterns.sh` com a assinatura `<repo-path> [--subpath <dir>] [--output <arquivo>]` — estrutura de ajuda (`--help`), validação de `HARVEST_API_URL` / `HARVEST_API_TOKEN` (FR-004)
- [x] T014 [US2] Implementar extração de metadados estruturais: nomes de arquivo, assinaturas de método/interface/classe, anotações/decoradores — **nunca** corpo de métodos, strings literais ou dados de runtime (FR-004, Security Gate do `plan.md`)
- [x] T015 [US2] Implementar detecção de stack a partir do manifesto (Java/Maven → interfaces em `domain/port`; Node.js → factories recorrentes; etc.) e adaptar os metadados enviados ao LLM (FR-005, AC-3)
- [x] T016 [US2] Implementar chamada ao endpoint LLM via `curl` com prompt estruturado solicitando identificação de padrões arquiteturais reutilizáveis e retornando entradas no formato `reuse-catalog.yaml` (FR-004, FR-005)
- [x] T017 [US2] Implementar detecção de duplicata por `tag` antes de propor novas entradas ao `reuse-catalog.yaml` — emitir aviso explícito quando a tag já existe (FR-006, edge case do `spec.md`)
- [x] T018 [US2] Implementar suporte a `--subpath <dir>` para limitar o harvest em monorepos grandes (edge case do `spec.md`)
- [x] T019 [US2] Implementar log de custo de tokens (`tokens_used`, `estimated_cost`) a cada execução (FR-004a, Constitution Check do `plan.md`)
- [x] T020 [US2] Garantir idempotência: execução dupla com os mesmos inputs não duplica entradas no catálogo (FR-010, SC-005)
- [x] T021 [US2] Tratar o caso de repo sem padrões detectáveis — informar explicitamente que nenhum padrão foi encontrado; não gerar entradas vazias ou genéricas (US2 — Acceptance Scenario 3)
- [x] T022 [P] [US2] Criar `tests/scripts/harvest-patterns.bats` cobrindo: `test_AC3_harvest_patterns_java_interfaces` (fixture Java), `test_AC10_idempotency` (execução dupla) — usar fixture de repo Java com interfaces públicas em `domain/port/` (plan.md — Rastreabilidade AC → Teste → Módulo)

**Checkpoint**: `harvest-patterns.sh` funcional com testes passando — Tech Lead pode executar harvest em qualquer repo do bounded context.

---

## Phase 4: User Story 3 — Integração ao `/speckit-specify` (Priority: P1)

**Goal**: Ao executar `/speckit-specify` para uma feature em bounded context com repos mapeados, `generate-context-graph.sh` é invocado automaticamente antes da abertura do template `spec.md`.

**Independent Test**: Executar `/speckit-specify` num projeto com `bounded-contexts.yaml` preenchido e verificar que `specs/<feature>/graph.yaml` existe e está preenchido antes de o template `spec.md` ser aberto para edição (Independent Test do `spec.md`, US3).

- [x] T023 [US3] Atualizar `.github/skills/speckit-specify/SKILL.md` com instrução de invocar `generate-context-graph.sh` automaticamente quando o bounded context declarado existir em `bounded-contexts.yaml` com ao menos um repo mapeado — antes de abrir o template `spec.md` (FR-007, AC-2)
- [x] T024 [US3] Adicionar tratamento de bounded context não mapeado no SKILL.md: emitir aviso e prosseguir sem bloquear (AC-5, US3 — Acceptance Scenario 2)
- [x] T025 [US3] Criar `.github/workflows/context-graph-refresh.yml` que faz checkout e invoca `generate-context-graph.sh` automaticamente para os bounded contexts afetados quando `bounded-contexts.yaml` é alterado em PR — permissão mínima `contents: write` (FR-012, Constitution Check do `plan.md`)
- [x] T026 [P] [US3] Verificar por inspeção estática de todos os `.github/workflows/*.yml` que `harvest-patterns.sh` não está referenciado em nenhum deles (AC-governance do `plan.md`, FR-011)

**Checkpoint**: Integração transparente — Dev não precisa lembrar de rodar o script ao abrir nova spec em contexto brownfield.

---

## Phase 5: User Story 4 — Documentação e instrução ao agente (Priority: P2)

**Goal**: `copilot-instructions.md`, `plan-template.md` e `docs/module-graphs.md` refletem o novo passo obrigatório de consultar `graph.yaml` e `reuse-catalog.yaml` antes de iniciar qualquer `/speckit-plan`.

**Independent Test**: Verificar que `copilot-instructions.md` tem um passo explícito de "consultar `graph.yaml` do contexto ativo antes de iniciar o plan" e que `plan-template.md` tem uma seção "Grafo do Contexto" que o agente deve preencher com o link para o `graph.yaml` gerado (Independent Test do `spec.md`, US4).

- [x] T027 [US4] Atualizar `presets/nimbus-code-standards/templates/project-root/copilot-instructions.md` com instrução explícita para o agente consultar `specs/<feature>/graph.yaml` e o `reuse-catalog.yaml` (filtrado pelo `bounded_context` ativo) antes de iniciar qualquer `/speckit-plan` (FR-008, AC-4)
- [x] T028 [US4] Atualizar `presets/nimbus-code-standards/templates/plan-template.md` adicionando seção "Grafo do Contexto" onde o agente registra o link para o `graph.yaml` gerado e descreve as dependências relevantes para a feature (FR-009)
- [x] T029 [US4] Atualizar `docs/module-graphs.md` adicionando seção "Grafos Multi-Repo e campo `cross_repo`" explicando o schema estendido do ADL-001 e como distinguir módulos locais de repos externos no Graph Guard

**Checkpoint**: O agente tem instruções explícitas para usar os novos artefatos — o ciclo specify→plan brownfield está completo.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Fechamento da feature — validação completa, catalogação de reuso, métricas

- [x] T030 [P] Validar os 5 Success Criteria do `spec.md` (SC-001 a SC-005) após todas as fases anteriores concluídas
- [x] T031 [P] Confirmar que `graph.yaml`/`graph.md` de `specs/014-brownfield-multirepo-context-awareness/` continuam refletindo a implementação real — Graph Guard valida automaticamente na PR
- [x] T032 Adicionar entrada a `docs/reuse-catalog.yaml` com `tag: brownfield-multirepo-context-graph`, `bounded_context: spec-kit-workflow`, `description` e `source: specs/014-brownfield-multirepo-context-awareness/plan.md` ao fechar a feature (plan.md — Arquivos alterados)
- [ ] T033 Preencher a tabela "Estimativa vs. Consumo Real de Tokens e Horas Humanas" com medições do Copilot Usage e GitHub Project — indisponíveis nesta auditoria, não estimar como se fossem consumo real.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sem dependências — pode começar imediatamente
- **US1 (Phase 2)**: Depende de Phase 1 (fixtures reais de `bounded-contexts.yaml` de T001/T004)
- **US2 (Phase 3)**: Independente de US1 — pode rodar em paralelo após Phase 1
- **US3 (Phase 4)**: Depende de Phase 2 (`generate-context-graph.sh` precisa existir para ser integrado ao SKILL.md)
- **US4 (Phase 5)**: Independente de US2/US3 — depende apenas de Phase 1 estar concluída
- **Polish (Phase 6)**: Depende de todas as User Stories completas

### Parallel Opportunities

- T001, T002, T003, T004 (Phase 1) em paralelo
- T011, T012 (Phase 2) em paralelo com T005–T010
- T013–T021 (Phase 3) em paralelo com T005–T010 (Phase 2)
- T022 (Phase 3) em paralelo com T013–T021
- T025, T026 (Phase 4) em paralelo com T023–T024
- T027, T028, T029 (Phase 5) em paralelo entre si
- T030, T031 (Phase 6) em paralelo

---

## Implementation Strategy

### MVP First (User Story 1 apenas)

1. Completar Phase 1: Setup (baseline do ambiente)
2. Completar Phase 2: US1 — `generate-context-graph.sh` funcional com testes bats
3. **PARAR e VALIDAR**: `graph.yaml` gerado para um repo de teste real aprovado pelo Dev
4. Já é um incremento de valor entregável — o Dev pode rodar o script manualmente mesmo sem a integração ao `/speckit-specify`

### Incremental Delivery

1. Setup → ambiente e baseline confirmados
2. US1 → grafo gerado automaticamente por bounded context (MVP)
3. US2 → harvest de padrões disponível on-demand para Tech Lead
4. US3 → integração transparente no fluxo `/speckit-specify` + CI para mudanças em `bounded-contexts.yaml`
5. US4 → instrução ao agente fecha o ciclo: artefatos gerados e referenciados antes do plan
6. Polish → reuso catalogado, métricas fechadas

---

## Notes

- [P] = tasks sem dependência entre si (podem rodar em paralelo)
- [USN] = rastreabilidade da tarefa à User Story do `spec.md`
- AC-2 e AC-4 não têm testes automatizados — comportamento de agente IA não automatizável em CI; validados manualmente em sessão real de spec/plan (ver justificativa no `plan.md`)
- `harvest-patterns.sh` nunca deve aparecer em nenhum workflow de CI — verificado estaticamente em T026
- Commits granulares recomendados: um por User Story completa
- Todos os scripts devem ser idempotentes (FR-010) — verificado nos testes de T011 e T022

---

## Nimbus-Code — Contrato de Task Executável no GHE

*Task T026 — Verificação de Governança: `harvest-patterns.sh` não deve estar em nenhum workflow de CI*

```markdown
## Contexto
Feature 014 — Brownfield MultiRepo Context Awareness. O script `harvest-patterns.sh`
é estritamente on-demand (FR-011) — nunca em CI automático — para evitar custo de
tokens não controlado. Esta tarefa verifica por inspeção estática que nenhum
workflow de CI referencia o script.

## Objetivo
Confirmar que `harvest-patterns.sh` não está referenciado em nenhum arquivo
`.github/workflows/*.yml` do repositório.

## Resultado Esperado
Inspeção estática confirma zero ocorrências de `harvest-patterns.sh` nos workflows
de CI — ou, se alguma ocorrência for encontrada, ela é removida antes do merge.

## Critérios de Aceite
- [x] `grep -r "harvest-patterns" .github/workflows/` retorna zero resultados
- [x] Resultado documentado como comentário no PR desta feature

## Passos Operacionais
1. Executar: `grep -r "harvest-patterns" .github/workflows/`
2. Se retornar resultados: remover as referências e documentar no PR
3. Registrar o resultado (zero ocorrências confirmadas) como comentário no PR

## Dependências
T025 (context-graph-refresh.yml criado — verificar que harvest não foi acidentalmente incluído)

## Responsável
Agente: sim
Humano: não

## Estimativa de Esforço
- Tokens (agente): ~1–2 mil
- Horas (humano): N/A

## Referência
- AC-ID: AC-governance
- Feature: specs/014-brownfield-multirepo-context-awareness
```

- [x] Toda task com `Responsável.Humano = sim` inclui `Passos Operacionais` completos
- [x] `Dependências` está preenchido com `Nenhuma` quando não existir bloqueador
- [x] `Referência` inclui AC-ID e link da feature de origem

---

## Nimbus-Code — Checklist de Qualidade de Código, Testes e Observabilidade

- [x] `graph.yaml` e `graph.md` atualizados para refletir módulos adicionados ou
      alterados por esta tarefa (Graph Guard valida automaticamente na PR) — caminhos dos testes bats corrigidos para `tests/scripts/` (T031)
- [x] Para complexidade S3: `impact-map.md` criado e revisado antes do merge
- [x] Critérios de aceitação da `spec.md` cobertos com ID de teste rastreável
      (AC-1, AC-3, AC-5, AC-6 — testes bats; AC-2, AC-4 — manuais com justificativa no `plan.md`; AC-governance — inspeção estática T026)
- [x] Feature flag: N/A — deploy `direct` justificado no `plan.md` (ADL-005)
- [x] SLO: scripts CLI/CI sem SLO de latência; critérios binários de erro definidos no `plan.md`
- [ ] Revisão de código por IA (GitHub Copilot code review) solicitada no PR
      de implementação e sem findings High/Critical pendentes _(pendente: solicitar ao abrir a PR)_
- [x] Testes de integração cobrindo AC-1, AC-3, AC-5, AC-6 via bats-core — testes manuais para AC-2 e AC-4 documentados
- [x] Observabilidade: log de custo de tokens por execução do harvest (FR-004a); output colorido com resumo de repos analisados no `generate-context-graph.sh`
- [x] N/A — scripts CLI sem arquitetura de microsserviços
- [x] Bugs encontrados durante a implementação que não foram corrigidos na
      própria tarefa foram abertos como Issue no GitHub e atribuídos ao
      Copilot coding agent — nenhum bug fora do escopo encontrado
- [x] Ao fechar: entrada adicionada a `docs/reuse-catalog.yaml` (`tag: brownfield-multirepo-context-graph`) — T032
- [x] Se retrabalho > 20% ou incidente: Issue com `harness:pending` + entrada em `docs/harness/harness-catalog.yaml` — N/A, sem retrabalho/incidente significativo
- [x] `retro-template.md` preenchido em `specs/014-brownfield-multirepo-context-awareness/retro.md`
      apenas se a implementação divergir deste plano — divergências registradas na nota de fechamento (2 desvios de detalhe: localização dos testes bats em `tests/scripts/` em vez de `scripts/tests/`, e `permissions: contents: read` em vez de `contents: write` no workflow, já que não há commit automático); não configuram divergência de escopo

## Nimbus-Code — Métricas de Branches e Saúde do Repositório (PMO)

| Métrica | Esta semana | Semana anterior | Tendência |
|---|---|---|---|
| Branches ativas (com PR aberto) | | | |
| **Branches perdidas** (sem PR, inativas ≥ 3 dias) | | | ↑ / ↓ / = |
| Branches mergeadas e não-deletadas | | | |
| PRs abertos por agente há > 5 dias sem revisão | | | |

## Nimbus-Code — Estimativa vs. Consumo Real de Tokens e Horas Humanas

| Métrica | Estimado (`plan.md`) | Real | Variância | Fonte da medição |
|---|---|---|---|---|
| Tokens (input+output) | ~45–65 mil tokens | Não disponível — T033 pendente | Não calculável | A obter do Copilot Usage da organização |
| Horas humanas | ~2–4 horas | Não disponível — T033 pendente | Não calculável | A confirmar no GitHub Project — campo "Horas Humanas" |

## Nimbus-Code — Checklist de Qualidade para Tarefas de Infraestrutura/Deploy

*Aplicável a T025 (`.github/workflows/context-graph-refresh.yml`), único artefato desta feature com característica de pipeline/CI.*

- [x] Sem segredo hardcoded — usa apenas `GITHUB_TOKEN` padrão do runner
- [x] N/A — sem provisionamento de infraestrutura via IaC (workflow YAML de CI)
- [x] Versões de actions pinadas (`actions/checkout@v4`, `actions/upload-artifact@v4`) — sem `latest` implícito
- [x] Permissões do workflow seguem least privilege — `permissions: contents: read` (mais restritivo que o `contents: write` originalmente previsto no `plan.md`: o workflow publica o grafo gerado como artefato via `actions/upload-artifact`, nunca commita automaticamente — ver nota de fechamento)
- [x] N/A — sem health checks/readiness aplicável (workflow de CI, não serviço long-running)
- [x] N/A — sem build de container nesta feature
- [x] Testado localmente (T030) antes de qualquer merge
- [x] `docs/module-graphs.md` atualizado se o comportamento do workflow mudar após o merge inicial (T029)
