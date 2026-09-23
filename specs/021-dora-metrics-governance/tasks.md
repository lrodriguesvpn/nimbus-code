# Tasks: Governança de Métricas DORA com Coleta Híbrida

**Input**: Artefatos de design de [specs/021-dora-metrics-governance/](/Users/lrodrigues/projects/nimbus-code/specs/021-dora-metrics-governance)
**Prerequisites**: [plan.md](/Users/lrodrigues/projects/nimbus-code/specs/021-dora-metrics-governance/plan.md) ✅, [spec.md](/Users/lrodrigues/projects/nimbus-code/specs/021-dora-metrics-governance/spec.md) ✅, [research.md](/Users/lrodrigues/projects/nimbus-code/specs/021-dora-metrics-governance/research.md) ✅, [data-model.md](/Users/lrodrigues/projects/nimbus-code/specs/021-dora-metrics-governance/data-model.md) ✅, [quickstart.md](/Users/lrodrigues/projects/nimbus-code/specs/021-dora-metrics-governance/quickstart.md) ✅, [graph.yaml](/Users/lrodrigues/projects/nimbus-code/specs/021-dora-metrics-governance/graph.yaml) ✅, [graph.md](/Users/lrodrigues/projects/nimbus-code/specs/021-dora-metrics-governance/graph.md) ✅, [impact-map.md](/Users/lrodrigues/projects/nimbus-code/specs/021-dora-metrics-governance/impact-map.md) ✅, [contracts/](/Users/lrodrigues/projects/nimbus-code/specs/021-dora-metrics-governance/contracts) ✅

**Organização**: tarefas agrupadas por user story para permitir implementação incremental e validação independente. Todas as 4 User Stories do `spec.md` são Priority: P1.

## Format: `[ID] [P?] [Story] Description with file path`

- **[P]**: tarefa pode rodar em paralelo (arquivos diferentes, sem dependência bloqueante)
- **[Story]**: rótulo da user story (`[US1]`, `[US2]`, `[US3]`, `[US4]`)

## Path Conventions

- Scripts: `scripts/process-metrics-report.sh` (extensão, feature 012)
- Documentação de processo: `docs/playbooks/README.md`, `docs/playbooks/dora-manual-adjustments-log.yaml` (novo)
- Testes: `tests/scripts/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: preparar o arquivo de estado versionado que servirá de base para a trilha de auditoria antes de qualquer user story depender dele.

- [x] T001 Criar `docs/playbooks/dora-manual-adjustments-log.yaml` com header de schema comentado (`id`, `indicator`, `justification`, `author`, `timestamp`, `evidence_link`, `exception_category`, `approved_by` — ver `data-model.md`, entidade "Manual Adjustment") e lista inicial vazia

**Checkpoint**: arquivo de estado existe e está pronto para receber entradas validadas pelas próximas fases.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: infraestrutura de validação compartilhada por US3 e US4 — nenhuma delas pode ser implementada corretamente sem esta checagem.

- [x] T002 Adicionar em `scripts/process-metrics-report.sh` uma função de validação de entrada de `docs/playbooks/dora-manual-adjustments-log.yaml` que rejeita qualquer entrada sem os 7 campos obrigatórios (`justification`, `author`, `timestamp`, `evidence_link`, `exception_category`, `approved_by`, `review_cycle_period`), categoria controlada, URL HTTPS e período `YYYY-MM`/`YYYY-WNN` (FR-004, FR-012, AC-3, ver `contracts/dora-quality-and-audit.contract.md`)
- [x] T003 [P] Criar `tests/scripts/process-metrics-report.audit-trail.test.sh`: fixture cobrindo (a) ajuste manual completo aceito, (b) ajuste manual incompleto rejeitado com mensagem clara, (c) categoria de exceção registrada corretamente (test ref `test_AC3_manual_adjustment_audit_trail`)

**Checkpoint**: a validação de trilha de auditoria é determinística e testável antes de qualquer story consumi-la.

---

## Phase 3: User Story 1 — Padronizar a base de medição DORA (Priority: P1) 🎯 MVP

**Goal**: os 4 indicadores DORA ficam definidos com fórmula, evento de origem, janela de medição e regra de inclusão/exclusão — a mesma régua para todas as squads.

**Independent Test**: revisar um conjunto de repositórios e confirmar que todos aplicam a mesma definição de evento, janela e regra de cálculo para cada indicador (Independent Test do `spec.md`, US1).

- [x] T004 [US1] Formalizar em `docs/playbooks/README.md`, seção "Cadência de Revisão de Métricas de Processo (DORA)" já existente (feature 012), as definições fechadas de fórmula, evento de origem, janela de medição e regra de inclusão/exclusão para os 4 indicadores (FR-001, AC-1, test ref `test_AC1_dora_metric_definition`)
- [x] T005 [US1] Validar US1 contra AC-1, FR-001 e SC-001 em `specs/021-dora-metrics-governance/quickstart.md` (Cenário V1)

**Checkpoint**: definição única e não ambígua disponível — MVP entregável mesmo sem as demais stories.

---

## Phase 4: User Story 2 — Coletar automaticamente o máximo possível (Priority: P1)

**Goal**: a maior parte da medição é automática, com origem rastreável, reduzindo retrabalho manual e viés de captura.

**Independent Test**: acompanhar eventos de entrega durante um período e verificar que entradas elegíveis são capturadas sem edição humana (Independent Test do `spec.md`, US2).

- [x] T006 [US2] Adicionar em `scripts/process-metrics-report.sh` a checagem de qualidade de dados (completude, consistência temporal, ausência de duplicidade — FR-011) sobre os registros automáticos já calculados, marcando explicitamente indicadores com dado insuficiente (mesmo padrão já usado para "dados insuficientes" na feature 012)
- [x] T007 [P] [US2] Estender `tests/scripts/process-metrics-report.detect.test.sh` (já existente) com casos cobrindo as novas regras de qualidade de dados: item duplicado detectado, inconsistência temporal sinalizada (FR-011, AC-2, test ref `test_AC2_auto_collection_default`)
- [x] T008 [US2] Confirmar/documentar em `docs/playbooks/README.md` que a origem (`automatic`) de cada `Collection Record` já é rastreável até o issue/PR de origem (FR-003) — sem novo código se o comportamento atual já satisfaz, apenas registrar a evidência
- [x] T009 [US2] Validar US2 contra AC-2, FR-002, FR-003, FR-011 e SC-002 em `specs/021-dora-metrics-governance/quickstart.md` (Cenário V2)

**Checkpoint**: coleta automática continua sendo o caminho padrão, agora com qualidade de dados explícita e rastreável.

---

## Phase 5: User Story 3 — Tratar exceções sem perder auditabilidade (Priority: P1)

**Goal**: fluxo manual controlado para corrigir lacunas de captura sem comprometer a governança dos indicadores.

**Independent Test**: executar um ajuste manual e validar que justificativa, autor, data e evidência ficam vinculados (Independent Test do `spec.md`, US3).

- [x] T010 [US3] Adicionar em `scripts/process-metrics-report.sh` um subcomando/flag `--record-manual-adjustment` que grava uma nova entrada em `docs/playbooks/dora-manual-adjustments-log.yaml` usando a validação da T002, exigindo `exception_category` para classificação posterior (FR-004, FR-005, AC-3, test ref `test_AC3_manual_adjustment_audit_trail`)
- [x] T011 [US3] Adicionar em `scripts/process-metrics-report.sh` o gate de fechamento de revisão periódica: reporta a revisão como bloqueada (`open`) enquanto existir `Manual Adjustment` sem justificativa completa vinculado ao período (FR-006, ver `contracts/dora-quality-and-audit.contract.md`)
- [x] T012 [P] [US3] Estender `tests/scripts/process-metrics-report.audit-trail.test.sh` (T003) com o caso do gate de fechamento: revisão com ajuste pendente nunca reporta `closed` (FR-006, test ref `test_AC3_manual_adjustment_audit_trail`)
- [x] T013 [US3] Validar US3 contra AC-3, FR-004, FR-005, FR-006, FR-012 e SC-003 em `specs/021-dora-metrics-governance/quickstart.md` (Cenários V3 e V4)

**Checkpoint**: ajustes manuais são exceção controlada e auditável — nenhum ajuste incompleto passa despercebido.

---

## Phase 6: User Story 4 — Interpretar os indicadores para ação prática (Priority: P1)

**Goal**: cadência semanal (squads) e mensal (portfólio/PMO) de leitura combinada dos 4 indicadores, convertendo degradação relevante em ação de backlog rastreável.

**Independent Test**: executar uma rodada de revisão com dados reais e comprovar geração de ações priorizadas com dono e prazo (Independent Test do `spec.md`, US4).

- [x] T014 [US4] Adicionar em `docs/playbooks/README.md` a cadência **semanal para squads**, complementando a cadência mensal de portfólio/PMO já existente (feature 012) — formato de registro e metas iniciais por indicador já documentados permanecem válidos para ambas as cadências (FR-010, AC-4)
- [x] T015 [US4] Adicionar em `docs/playbooks/README.md` a exigência explícita de `combined_conclusion` (leitura combinada dos 4 indicadores, nunca decisão por indicador isolado) como critério de fechamento de toda `Review Cycle` (FR-007, AC-4, test ref `test_AC4_combined_metric_interpretation`)
- [x] T016 [US4] Definir em `docs/playbooks/README.md` os gatilhos objetivos de degradação (FR-008) que abrem/atualizam uma Issue de `Improvement Action` reaproveitando os labels `priority:*`/`dora:*` já existentes, exigindo `owner`, prioridade inicial e prazo de reavaliação (FR-009, AC-5, test ref `test_AC5_degradation_to_action_flow`)
- [x] T017 [P] [US4] Criar `tests/scripts/process-metrics-report.degradation-action.test.sh`: fixture cobrindo (a) gatilho de degradação atingido gera referência de ação esperada, (b) sem degradação nenhuma ação é sinalizada (FR-008, FR-009, test ref `test_AC5_degradation_to_action_flow`)
- [x] T018 [US4] Adicionar em `docs/playbooks/README.md` a orientação de comparabilidade cross-squad: evolução relativa por squad, nunca ranking absoluto entre squads de tamanho/escopo diferentes (FR — implícito no Objetivo do `spec.md`; AC-6, test ref `test_AC6_context_aware_comparison`)
- [x] T019 [US4] Validar US4 contra AC-4, AC-5, AC-6, FR-007, FR-008, FR-009, FR-010 e SC-004/SC-005 em `specs/021-dora-metrics-governance/quickstart.md` (Cenários V5, V6 e V7)

**Checkpoint**: leitura combinada é obrigatória, degradação relevante nunca fica sem ação de backlog, e comparação cross-squad respeita contexto.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: consolidar consistência final, cobertura de testes e artefatos de governança da feature.

- [x] T020 [P] Executar a validação final dos cenários V1 a V7 em `specs/021-dora-metrics-governance/quickstart.md`, registrando os comandos efetivamente executados na seção "Validação executada nesta sessão"
- [x] T021 [P] Confirmar que `graph.yaml`/`graph.md` continuam refletindo a implementação real (nenhum módulo novo criado fora do já mapeado)
- [x] T022 Adicionar entrada a `docs/reuse-catalog.yaml` (tag: `dora-governance-hybrid-collection`, bounded_context: `spec-kit-workflow`, description explicando a extensão de `scripts/process-metrics-report.sh` com qualidade de dados + auditoria + gate de fechamento, source: `specs/021-dora-metrics-governance/plan.md`)
- [ ] T023 Preencher a tabela "Nimbus-Code — Estimativa vs. Consumo Real de Tokens e Horas Humanas" abaixo no fechamento desta feature, comparando com a Classificação de Complexidade do `plan.md`. Reaberta na auditoria de 2026-09-20: a tabela ainda contém placeholders; valores medidos e horas humanas não foram apresentados. Revisão #446; gates operacionais #434.

## Phase 8: Remediation & Adoption Gates

**Purpose**: fechar as lacunas identificadas na análise cross-artifact sem misturar evidência de adoção pós-release com implementação local.

- [x] T024 [US3] Estender `tests/scripts/process-metrics-report.audit-trail.test.sh` e a documentação do contrato para provar que `approved_by` é obrigatório, que autoaprovação só ocorre sob regra explícita e que o gate de fechamento rejeita entradas sem aprovação em `scripts/process-metrics-report.sh` e `specs/021-dora-metrics-governance/contracts/dora-quality-and-audit.contract.md`
- [x] T025 [US4] Documentar em `docs/playbooks/README.md` a cadeia única `combined_conclusion` → gatilho objetivo → `Improvement Action` → `owner`/`priority`/`review_deadline` → reavaliação, mantendo a conversão de degradação dentro da US4 e sem criar US5
- [ ] T026 [P] Definir em `specs/021-dora-metrics-governance/quickstart.md` o protocolo de medição pós-release dos três componentes SLO (`automatic ingestion`, `manual audit registration`, `weekly/monthly consolidation`), incluindo fonte, janela, responsável e critério de conformidade
- [ ] T027 [P] Definir em `specs/021-dora-metrics-governance/quickstart.md` o protocolo de medição pós-adoção de SC-001, SC-002 e SC-003, incluindo população, período de observação, responsável e evidência esperada
- [x] T028 [US3] Definir o vocabulário controlado de `exception_category`, o período afetado, a precedência automático/manual e a preservação de registros substituídos em `specs/021-dora-metrics-governance/spec.md`, `data-model.md`, `contracts/dora-quality-and-audit.contract.md` e `scripts/process-metrics-report.sh`
- [x] T029 [US4] Definir limiares objetivos de degradação, baseline relativo, estados de `Review Cycle` e regra de não geração de ação com dados insuficientes em `specs/021-dora-metrics-governance/spec.md`, `docs/playbooks/README.md` e `contracts/dora-quality-and-audit.contract.md`
- [x] T030 [US4] Documentar deduplicação de `Improvement Action`, referência ao ciclo de origem e reavaliação por `review_deadline` em `docs/playbooks/README.md` e `data-model.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sem dependências — pode começar imediatamente
- **Foundational (Phase 2)**: depende de Phase 1 (T001) — a função de validação (T002) opera sobre o arquivo criado em T001
- **US1 (Phase 3)**: sem dependência técnica de Phase 2 — pode começar em paralelo com Phase 2
- **US2 (Phase 4)**: sem dependência técnica de Phase 2 — extensão independente do script já existente
- **US3 (Phase 5)**: depende de Phase 2 (T002) — o subcomando de registro (T010) usa a validação criada ali
- **US4 (Phase 6)**: depende de US3 (Phase 5) — o gate de fechamento (T015) referencia o mesmo mecanismo de `pending_manual_adjustments` criado em T011
- **Polish (Phase 7)**: depende de todas as User Stories completas

### User Story Dependencies

- **US1 (P1)**: Independente — pode começar após Setup
- **US2 (P1)**: Independente — pode começar em paralelo com US1
- **US3 (P1)**: Depende de Foundational (T002)
- **US4 (P1)**: Depende de US3 (T011, gate de fechamento)

### Parallel Opportunities

- T001 (Phase 1) não tem paralelo — é pré-requisito único
- T003 (Phase 2) pode começar assim que T002 estiver pronto
- Phase 3 (US1) inteira pode rodar em paralelo com Phase 4 (US2) — nenhuma depende da outra
- T007 (Phase 4) em paralelo com T006 (implementação vs. extensão de teste)
- T012 (Phase 5) em paralelo com T010/T011 assim que ambos estiverem prontos
- T017 (Phase 6) em paralelo com T014/T015/T016/T018
- T020, T021 (Phase 7) em paralelo

---

## Implementation Strategy

### MVP First (User Story 1 apenas)

1. Completar **Phase 1** e **Phase 2** (infraestrutura de auditoria)
2. Completar **Phase 3** (US1 — definições fechadas dos 4 indicadores)
3. Já é um incremento de valor entregável: toda squad passa a ter uma única régua de leitura, mesmo antes das demais stories

### Incremental Delivery

1. Setup + Foundational → arquivo de auditoria e validação prontos
2. US1 → definições únicas e não ambíguas (MVP)
3. US2 → qualidade de dados explícita na coleta automática já existente
4. US3 → ajustes manuais tornam-se exceção controlada e auditável
5. US4 → leitura combinada obrigatória + degradação vira ação de backlog rastreável
6. Polish → reuso catalogado, métricas fechadas

---

## Notes

- [P] = tasks sem dependência entre si (podem rodar em paralelo)
- [USN] = rastreabilidade da tarefa à User Story do `spec.md`
- Nenhum arquivo/script existente é removido nesta feature — apenas estendido (Estratégia de Release do `plan.md`: `direct`, sem toggle)
- Commits granulares recomendados: um por User Story completa
- Toda entrada em `docs/playbooks/dora-manual-adjustments-log.yaml` exige os 7 campos obrigatórios preenchidos, incluindo `approved_by` e `review_cycle_period` — nunca gravada parcialmente (FR-004, FR-012)

---

## Nimbus-Code — Checklist de Qualidade de Código, Testes e Observabilidade

- [x] `graph.yaml` e `graph.md` atualizados para refletir módulos adicionados ou
      alterados por esta tarefa (Graph Guard valida automaticamente na PR)
- [x] Para complexidade S3: `impact-map.md` criado e revisado antes do merge
- [x] Critérios de aceitação da `spec.md` cobertos com ID de teste rastreável
      (`test_AC1`..`test_AC6` — ver Rastreabilidade AC → Teste → Módulo do `plan.md`)
- [x] Estratégia de release: `direct` — justificada no `plan.md` (sem toggle)
- [ ] SLOs desta feature (ver SLO Gate do `plan.md`) medidos na primeira execução real
      _(pendente: testes usam mock de `gh`; medição real requer execução contra repositório real)_
- [ ] Revisão de código por IA (GitHub Copilot code review) solicitada no PR
      de implementação e sem findings High/Critical pendentes
      _(pendente: solicitar ao abrir o PR)_
- [x] Teste de integração cobrindo AC-2, AC-3, AC-5 — ver tabela de Rastreabilidade
      do `plan.md` (AC-1 e AC-6 são N/A justificado — validação documental/manual)
- [x] Observabilidade: trilha de auditoria (`docs/playbooks/dora-manual-adjustments-log.yaml`) é o próprio artefato de observabilidade desta feature
- [x] N/A — sem arquitetura de microsserviços nesta feature
- [x] Bugs encontrados durante a implementação que não foram corrigidos na
      própria tarefa foram abertos como Issue no GitHub e atribuídos ao
      Copilot coding agent
      _(nenhum bug fora do escopo encontrado — apenas o bug de grep -c/exit-code corrigido na própria task, ver commit)_
- [x] Entrada adicionada a `docs/reuse-catalog.yaml` (T022)
- [x] "O que deu certo aqui que vale a pena repetir?" — resposta desta própria
      feature registrada em `docs/playbooks/success-catalog.yaml` ou "Nada relevante a registrar"
      _(nada adicional a registrar — o próprio reuso de `scripts/process-metrics-report.sh`/`docs/playbooks/README.md` já está documentado via reuse-catalog tag `dora-governance-hybrid-collection`)_
- [x] `retro-template.md` preenchido em `specs/021-dora-metrics-governance/retro.md`
      apenas se a implementação divergir deste plano
      _(N/A — implementação seguiu o plano; único desvio foi o bug de tooling do preset, já registrado no commit da fase de planejamento)_

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
| Tokens (input+output) | ~20–30 mil | [preencher ao fechar] | — | Copilot Usage da organização |
| Horas humanas | ~1–3 horas | [total lançado no GitHub Project] | — | GitHub Project — campo "Horas Humanas" |
