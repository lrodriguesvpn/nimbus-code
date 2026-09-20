# Tasks: Governança de Testes em PR — Política E2E, Padrão Executável e Gate Unificado

**Input**: Design documents from `/specs/013-governanca-testes-pr/`

**Prerequisites**: `plan.md` ✅, `spec.md` ✅, `research.md` ✅, `data-model.md` ✅, `quickstart.md` ✅, `graph.yaml` ✅, `graph.md` ✅, `impact-map.md` ✅ (S3 — obrigatório)

**Organization**: Tasks agrupadas por User Story (P1, P1, P2, P2) para entrega incremental e teste independente, conforme `spec.md`.

**Estado auditado em 2026-09-20**: revisão #439 aberta; T009/#222 e T015/#223
continuam bloqueadas por decisão humana. O runner/workflow existem em modo
relatório, mas configuração de branch protection e execução real de PR não
foram verificadas. T014 permanece parcial, agora aberta; T027 foi reaberta por
ausência de medições. O checklist `checklists/requirements-quality.md` citado
em #439 não existe neste checkout; o existente é `checklists/requirements.md`
(21 itens), não comprovação dos 12 itens alegados. O teste documental local
teve 17/17 checks aprovados na auditoria, não a suíte completa relatada na issue.

**Tests**: Não solicitados explicitamente no `spec.md` além dos próprios testes de conteúdo da política (`tests/docs/testing-policy.test.sh`) — incluídos como parte da implementação de cada User Story, não como fase separada de TDD.

---

## Phase 1: Setup

**Purpose**: Levantamento factual real da suíte existente — base para todas as User Stories

- [x] T001 Executar `git ls-tree -r --name-only HEAD -- tests/` e confirmar o inventário real: 10 arquivos de teste em 4 subpastas (`tests/bootstrap/*.bats` ×2, `tests/docs/*.test.sh` ×2, `tests/scripts/*.test.sh` ×4, `tests/workflows/*.test.sh` ×2) — registrar o resultado real (não assumir) como insumo para `docs/testing-policy.md`
- [x] T002 [P] Rodar cada um dos 10 arquivos de teste existentes individualmente (`bats tests/bootstrap/*.bats`; `bash tests/docs/*.test.sh`; etc.) e confirmar que todos passam hoje, antes de qualquer mudança — baseline necessária para não introduzir falso-positivo no gate novo
- [x] T003 [P] Confirmar se `bats` já está instalado por `scripts/setup-dev-environment.sh`; se não estiver, anotar a lacuna para a Task T012 (US3)

**Checkpoint**: Inventário real e baseline de testes passando confirmados — implementação pode começar.

---

## Phase 2: User Story 1 — Definir um padrão único de testes executáveis (Priority: P1) 🎯 MVP

**Goal**: `docs/testing-policy.md` existe com taxonomia, inventário e matriz de decisão de formato completos e aprovados

**Independent Test**: Ler apenas `docs/testing-policy.md` e verificar que um mantenedor consegue decidir, sem consulta externa, qual formato usar para um novo teste e quando uma exceção é aceitável (Independent Test do `spec.md`, US1)

- [x] T004 [US1] Criar `docs/testing-policy.md` com seção "Inventário da Suíte Atual", usando o resultado real de T001 — declarar explicitamente que nenhum workflow de CI hoje roda essa suíte completa em toda PR (AC-1, FR-001, FR-002)
- [x] T005 [US1] Adicionar seção "Taxonomia de Testes" a `docs/testing-policy.md` definindo unitário/integração/e2e para este bundle, com critério de enquadramento por tipo de artefato (script, workflow, preset, documentação) — usar `data-model.md`, entidade "Test Category" como base (AC-5, FR-005)
- [x] T006 [US1] Adicionar seção "Matriz de Decisão de Formato" a `docs/testing-policy.md` comparando Bats-core vs. `.test.sh` vs. `shellspec` (prós/contras/critério de uso) — transcrever a decisão já registrada em `research.md`, Decisão 1 (AC-2, FR-003, FR-003a, FR-004)
- [x] T007 [US1] Adicionar seção "Convenções de Localização e Nomenclatura" a `docs/testing-policy.md` — onde colocar um novo teste por categoria e como nomeá-lo (FR-006)
- [x] T008 [P] [US1] Criar `tests/docs/testing-policy.test.sh` que confirma via `grep`/parsing que as seções obrigatórias acima existem em `docs/testing-policy.md` (test ref `test_AC1_inventario_e_gap_atual`, `test_AC2_matriz_de_decisao`, `test_AC5_taxonomia_de_testes` do `plan.md`)
- [ ] T009 [US1] **[Humano]** Revisar e aprovar a recomendação de padrão principal (Bats-core) e a matriz de decisão — sem essa aprovação explícita, a US2 (gate obrigatório) não deve prosseguir para o estado "required" _(pendente: requer aprovação humana explícita, ver PR desta feature)_

**Checkpoint**: A política já responde sozinha "qual formato eu uso para um novo teste?" — MVP entregável mesmo sem o gate de CI ainda existir.

---

## Phase 3: User Story 2 — Tornar a suíte existente obrigatória em toda PR (Priority: P1)

**Goal**: Toda PR contra `main` roda a suíte mandatória de forma consolidada, com resultado único e identificação clara do segmento que falhar

**Independent Test**: Abrir uma PR de exemplo e verificar que o resultado do merge depende de um resultado consolidado de teste (Independent Test do `spec.md`, US2)

- [x] T010 [US2] Criar `scripts/run-tests.sh` que descobre e executa: (a) todo `tests/**/*.bats` via `bats`, (b) todo `tests/**/*.test.sh` via `bash`; agregar resultado consolidado (grupos executados, quais passaram/falharam) e retornar exit code não-zero se qualquer grupo falhar (FR-007, FR-012)
- [x] T011 [US2] Garantir que a saída de `scripts/run-tests.sh` identifica explicitamente qual segmento (`bootstrap`, `docs`, `scripts`, `workflows`) falhou primeiro, sem exigir inspeção de múltiplos arquivos de log (AC-3, FR-011 — test ref `test_AC3_gate_obrigatorio_em_pr`)
- [x] T012 [P] [US2] Criar `.github/workflows/test-suite.yml` que faz checkout, instala `bats`/dependências (via `scripts/setup-dev-environment.sh` ou passo equivalente) e invoca `scripts/run-tests.sh` em todo `pull_request` contra `main` — configurar em **modo relatório** (sem marcar como required check ainda), conforme Estratégia de Release do `plan.md`
- [x] T013 [US2] Adicionar seção "Gate Obrigatório de PR" a `docs/testing-policy.md` documentando o funcionamento de `test-suite.yml`, o estado atual (modo relatório) e o critério de promoção para "required" (FR-007)
- [ ] T014 [US2] **PARCIAL — evidência externa pendente**: `test-suite.yml` está configurado para `pull_request` contra `main`. O registro histórico de execução local não comprova que o check executou ou apareceu como informativo na UI da PR; anexar evidência da execução real, sem promover o gate automaticamente.
- [ ] T015 [US2] **[Humano]** Após o período de observação definido no PR de implementação, decidir e executar a promoção de `test-suite.yml` para "required status check" na proteção de branch de `main` — ver contrato de task executável abaixo (T015) _(pendente: `test-suite.yml` está deliberadamente em modo relatório nesta entrega; promoção exige decisão humana após período de observação)_

**Checkpoint**: A suíte existente já roda de forma consolidada em toda PR (mesmo que ainda em modo relatório) — segundo incremento de valor entregável.

---

## Phase 4: User Story 3 — Rodar localmente a mesma validação exigida em PR (Priority: P2)

**Goal**: Um contribuidor descobre e executa localmente exatamente a mesma validação mandatória exigida em PR

**Independent Test**: Pedir a um contribuidor que não conhece a suíte para encontrar e executar o caminho oficial apenas com a documentação produzida (Independent Test do `spec.md`, US3)

- [x] T016 [US3] Adicionar instalação de `bats` a `scripts/setup-dev-environment.sh` (via `npm install -g bats` ou feature equivalente do devcontainer) caso a lacuna tenha sido confirmada em T003
- [x] T017 [US3] Adicionar seção "Executando a Suíte Localmente" a `docs/testing-policy.md` com o comando único (`./scripts/run-tests.sh`) e pré-requisitos — documentar que este é o mesmo caminho usado por `test-suite.yml` (paridade por construção, não por manutenção paralela) (AC-4, FR-008 — test ref `test_AC4_execucao_local_paritaria`)
- [x] T018 [P] [US3] Validar o Cenário 1 do `quickstart.md` — rodar `./scripts/run-tests.sh` num ambiente limpo (Codespace ou clone local) e confirmar que reproduz o mesmo resultado do gate de CI
- [x] T019 [P] [US3] Validar o Cenário 3 do `quickstart.md` — introduzir uma falha proposital, confirmar que a saída identifica o segmento correto, reverter a falha após validar

**Checkpoint**: Paridade local/CI comprovada — contribuidor não depende mais de memória manual para saber o que rodar antes de abrir PR.

---

## Phase 5: User Story 4 — Evitar nova fragmentação da suíte (Priority: P2)

**Goal**: Novos formatos, bypasses ou remoções de suíte exigem exceção formal aprovada, não adoção silenciosa

**Independent Test**: Avaliar uma proposta de novo teste fora do padrão e verificar que a política exige justificativa e decisão explícita (Independent Test do `spec.md`, US4)

- [x] T020 [US4] Adicionar seção "Governança de Exceções" a `docs/testing-policy.md`, formalizando o `Exception Record` (`data-model.md`) — motivo, formato alternativo aceito, duração (permanente/temporária) e aprovador — reaproveitando o Architecture Decision Log já existente no `plan.md` de cada feature como o local de registro (AC-6, FR-009 — test ref `test_AC6_governanca_de_excecoes`)
- [x] T021 [US4] Adicionar seção "Tratamento de Testes Legados" a `docs/testing-policy.md`, classificando explicitamente os `.test.sh` existentes como formato **aceito e permanente** (não um legado a migrar) — ver `research.md`, Decisão 4 (FR-010)
- [x] T022 [P] [US4] Estender `tests/docs/testing-policy.test.sh` (criado em T008) para confirmar via `grep` a presença das seções "Governança de Exceções" e "Tratamento de Testes Legados"

**Checkpoint**: Todas as 4 User Stories entregues — política completa, gate consolidado, paridade local/CI e governança de exceções.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Fechamento da feature — validação completa, catalogação de reuso, métricas

- [x] T023 [P] Validar os 6 cenários completos do `quickstart.md` (não apenas os já cobertos em T018/T019) — Cenários 2, 4, 5 e 6
- [x] T024 [P] Confirmar que `graph.yaml`/`graph.md` continuam refletindo a implementação real (nenhum módulo novo criado fora do já mapeado) — Graph Guard valida automaticamente na PR
- [x] T025 Avaliar se o padrão de "gate único de suíte existente" resultante é reutilizável por outros repositórios do bundle; se sim, adicionar entrada a `docs/reuse-catalog.yaml` (`tag`, `bounded_context: "spec-kit-workflow"`, `description`, `source: "specs/013-governanca-testes-pr/plan.md"`) conforme FR-004
- [x] T026 Abrir Issue recomendando entrada formal em `docs/harness/harness-catalog.yaml` para o padrão de risco "código diz X, produção nunca recebeu X" identificado no Harness Gate do `plan.md` (fora do escopo direto desta feature, mas registrado como acompanhamento)
- [ ] T027 Preencher a tabela "Estimativa vs. Consumo Real de Tokens e Horas Humanas" com dados reais do Copilot Usage e do GitHub Project — estrutura disponível, medições ainda indisponíveis; não inferir valores da estimativa.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sem dependências — pode começar imediatamente
- **User Story 1 (Phase 2)**: Depende de Phase 1 (precisa do inventário real de T001)
- **User Story 2 (Phase 3)**: Depende de Phase 1; **recomendado** (não obrigatório) esperar T004-T007 (US1) para que `docs/testing-policy.md` já tenha a matriz de decisão antes de documentar o gate — mas `run-tests.sh`/`test-suite.yml` podem ser implementados em paralelo
- **User Story 3 (Phase 4)**: Depende de Phase 3 (T010, `run-tests.sh` precisa existir antes de documentar/validar execução local)
- **User Story 4 (Phase 5)**: Depende de Phase 2 (T004, `docs/testing-policy.md` precisa existir para receber as novas seções) — independente de Phases 3/4
- **Polish (Phase 6)**: Depende de todas as User Stories completas

### User Story Dependencies

- **US1 (P1)**: Pode começar após Setup — sem dependência de outras stories
- **US2 (P1)**: Pode começar após Setup — integra com US1 (referencia a matriz de decisão) mas o script/workflow em si são independentes
- **US3 (P2)**: Depende tecnicamente de US2 (`run-tests.sh` precisa existir)
- **US4 (P2)**: Depende tecnicamente de US1 (`docs/testing-policy.md` precisa existir), independente de US2/US3

### Parallel Opportunities

- T002, T003 (Phase 1) em paralelo
- T008 (Phase 2) em paralelo com T009 (revisão humana pode ocorrer enquanto o teste de conteúdo é escrito)
- T012 (Phase 3) em paralelo com T013 (documentação da seção pode ser escrita enquanto o workflow é testado)
- T018, T019 (Phase 4) em paralelo
- T022 (Phase 5) pode ocorrer em paralelo com Phase 4 completa, já que ambas dependem apenas de US1
- T023, T024 (Phase 6) em paralelo

---

## Parallel Example: User Story 1

```bash
# Após T004-T007 completos, rodar em paralelo:
Task: "Criar tests/docs/testing-policy.test.sh confirmando seções obrigatórias (T008)"
Task: "Revisão humana da recomendação de padrão principal (T009)"
```

---

## Implementation Strategy

### MVP First (User Story 1 apenas)

1. Completar Phase 1: Setup (inventário real)
2. Completar Phase 2: User Story 1 — `docs/testing-policy.md` com taxonomia + matriz de decisão
3. **PARAR e VALIDAR**: revisão humana (T009) aprova a recomendação de formato
4. Já é um incremento de valor entregável mesmo sem o gate de CI existir ainda

### Incremental Delivery

1. Setup → base factual pronta
2. US1 → política existe e responde "qual formato eu uso?" (MVP)
3. US2 → gate obrigatório existe (modo relatório) → validação real → promoção humana a "required"
4. US3 → paridade local/CI documentada e validada
5. US4 → governança de exceções fecha o ciclo, evita nova fragmentação
6. Polish → reuso catalogado, métricas fechadas

---

## Notes

- [P] = tasks sem dependência entre si (podem rodar em paralelo)
- [USN] = rastreabilidade da tarefa à User Story do `spec.md`
- **[Humano]** = tarefa que exige decisão/aprovação humana explícita, não apenas revisão de PR (T009, T015)
- Nenhum arquivo de teste existente (`tests/bootstrap/`, `tests/docs/`, `tests/scripts/`, `tests/workflows/`) é removido ou migrado nesta feature — ver `research.md`, Decisão 4
- Commits granulares recomendados: um por User Story completa
- Antes do merge: confirmar que `scripts/run-tests.sh` roda com sucesso os 10 arquivos de teste reais (baseline de T002) sem introduzir falso-positivo

---

## Nimbus-Code — Contrato de Task Executável no GHE

```markdown
## Contexto
Feature 013 — Governança de Testes em PR. Tarefa T015: promover
`.github/workflows/test-suite.yml` de modo relatório (informativo) para
"required status check" na proteção de branch de `main`, após o período de
observação definido no PR de implementação (T012/T014).

## Objetivo
Decidir, com base na evidência coletada durante o período de observação
(nenhum falso-positivo relevante), se o gate obrigatório de testes deve
passar a bloquear merges de PRs que falharem a suíte mandatória.

## Resultado Esperado
`test-suite.yml` aparece como "required" na configuração de proteção de
branch de `main` (Settings → Branches → Branch protection rules), ou a
decisão de adiar é registrada com nova data de reavaliação.

## Critérios de Aceite
- [ ] Período de observação (definido no PR de T012/T014) transcorrido sem
      falso-positivo relevante documentado
- [ ] Decisão de promover (ou adiar) registrada como comentário no PR original
      ou como entrada no Architecture Decision Log do `plan.md`
- [ ] Se promovido: `gh api repos/{owner}/{repo}/branches/main/protection` confirma
      `test-suite` na lista de `required_status_checks`

## Passos Operacionais
1. Revisar o histórico de execuções de `test-suite.yml` desde sua criação (T012)
2. Confirmar ausência de falso-positivo relevante (ou documentar os encontrados)
3. Acessar `Settings → Branches → Branch protection rules` para `main`
4. Adicionar `test-suite` à lista de required status checks
5. Registrar a decisão (data, evidência, aprovador) no PR ou no ADL do `plan.md`

## Dependências
T012, T014 (workflow criado e validado em modo relatório)

## Responsável
Agente: não (decisão explicitamente reservada a humano — ver Estratégia de
Release do `plan.md`)
Humano: sim

## Estimativa de Esforço
- Tokens (agente): N/A — tarefa 100% humana
- Horas (humano): ~0,5–1 hora (revisão de histórico + configuração de branch protection)

## Referência
- AC-ID: AC-3
- Feature: specs/013-governanca-testes-pr
```

- [ ] T009 concluído (revisão humana da matriz de decisão de formato)
- [ ] T015 concluído (promoção do gate, ou decisão de adiar registrada)

## Nimbus-Code — Checklist de Qualidade de Código, Testes e Observabilidade

- [x] `graph.yaml` e `graph.md` atualizados para refletir módulos adicionados ou
      alterados por esta tarefa (Graph Guard valida automaticamente na PR) — confirmado em T024, nenhum módulo novo fora do já mapeado
- [x] Para complexidade S3: `impact-map.md` criado e revisado antes do merge
- [x] Critérios de aceitação da `spec.md` cobertos com ID de teste rastreável
      (`test_AC1`...`test_AC6`, ver Rastreabilidade AC → Teste → Módulo do `plan.md`)
- [x] Estratégia de release: `direct` com rollout faseado manual — justificada
      no `plan.md` (Estratégia de Release + ADL)
- [ ] SLO do `test-suite.yml` (< 15 min) medido na primeira execução real (T014) _(pendente: medir na primeira execução real do Actions após abrir a PR)_
- [ ] Revisão de código por IA (GitHub Copilot code review) solicitada no PR
      de implementação e sem findings High/Critical pendentes _(pendente: solicitar ao abrir a PR)_
- [x] Teste de integração cobrindo os 6 AC do `spec.md` — ver tabela de
      Rastreabilidade do `plan.md` (todos cobertos, nenhuma exceção)
- [x] Observabilidade: saída de `run-tests.sh`/`test-suite.yml` identifica o
      segmento que falhou (FR-011) — já é a instrumentação mínima exigida
- [x] N/A — sem arquitetura de microsserviços nesta feature
- [x] Bugs encontrados durante a implementação que não foram corrigidos na
      própria tarefa foram abertos como Issue no GitHub e atribuídos ao
      Copilot coding agent — único achado (incompatibilidade bash 3.2/macOS com
      `declare -A`) foi resolvido no próprio escopo (aviso em `run-tests.sh` +
      seção 8 de `docs/testing-policy.md`), não requer Issue separada
- [x] Se o padrão de gate único se mostrar reutilizável (T025): entrada
      adicionada a `docs/reuse-catalog.yaml`
- [x] Recomendação de harness (T026) avaliada — Issue aberta se o mantenedor concordar — Issue #191
- [x] `retro-template.md` preenchido em `specs/013-governanca-testes-pr/retro.md`
      apenas se a implementação divergir deste plano — N/A, implementação seguiu o plano sem divergência

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
| Tokens (input+output) | ~40–70 mil | Não disponível — T027 pendente | Não calculável | A obter do Copilot Usage da organização |
| Horas humanas | ~3–6 horas | Não disponível — T027 pendente | Não calculável | A confirmar no GitHub Project — campo "Horas Humanas" |

## Nimbus-Code — Checklist de Qualidade para Tarefas de Infraestrutura/Deploy

*Aplicável a T012 (`.github/workflows/test-suite.yml`), único artefato desta feature com característica de pipeline/CI.*

- [x] Sem segredo hardcoded — usa apenas `GITHUB_TOKEN` padrão do runner
- [x] N/A — sem provisionamento de infraestrutura via IaC nesta feature (workflow YAML de CI, não infraestrutura)
- [x] Versão de `bats` pinada em `scripts/setup-dev-environment.sh` (não `latest` implícito) — ver `research.md`, Decisão 3 (risco R003 do `impact-map.md`) — `1.13.0`, mesma versão pinada em `test-suite.yml`
- [x] Permissões do workflow seguem least privilege (sem `permissions: write-all` sem justificativa) — `permissions: contents: read`
- [x] N/A — sem health checks/readiness aplicável (workflow de CI, não serviço long-running)
- [x] N/A — sem build de container nesta feature
- [ ] Execução real em modo relatório comprovada (T014); estado live de required status checks não verificado nesta auditoria
- [ ] `docs/testing-policy.md` atualizado se o comportamento do gate mudar após o merge inicial
