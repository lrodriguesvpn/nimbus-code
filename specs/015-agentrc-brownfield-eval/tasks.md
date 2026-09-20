# Tasks: AgentRC Brownfield Evaluation

**Input**: Design docs from `/specs/015-agentrc-brownfield-eval/`  
**Prerequisites**: `plan.md` ✅, `spec.md` ✅, `research.md` ✅, `data-model.md` ✅, `quickstart.md` ✅, `graph.yaml` ✅, `graph.md` ✅  
**Organization**: Tasks grouped by user story for independent validation and recommendation closure.

**Fechamento documental ≠ aprovação (2026-09-20)**: as 22 tarefas marcadas
representam a entrega dos artefatos. A revisão #449 continua aberta e propõe
No-Go imediato, divergindo do Go local. Ver [recommendation.md](./recommendation.md).
A ata de decisão exigida por SC-003 não foi localizada; piloto e adoção
permanecem dependentes de revisão humana, sem nova execução nesta fase.

## Format: `[ID] [P?] [US?] Description with file path`

- `[P]`: Task can run in parallel (different file, no blocking dependency)
- `[US]`: User story label (`[US1]`, `[US2]`, `[US3]`)

---

## Phase 1: Setup (Shared Evaluation Scaffolding)

**Purpose**: Create the evaluation artifacts that all stories depend on.

- [x] T001 [P] Create comparison matrix scaffold in `specs/015-agentrc-brownfield-eval/comparison-matrix.md`
- [x] T002 [P] Create evidence register template in `specs/015-agentrc-brownfield-eval/evidence-register.md`
- [x] T003 [P] Create recommendation document template in `specs/015-agentrc-brownfield-eval/recommendation.md`

**Checkpoint**: Evaluation artifacts exist and are ready for structured analysis.

---

## Phase 2: Foundational (Blocking Rules and Traceability)

**Purpose**: Define classification rules and traceability before story execution.

- [x] T004 Define capability classification rubric (complementar/duplicada/conflitante/não aplicável) in `specs/015-agentrc-brownfield-eval/comparison-matrix.md`
- [x] T005 Define evidence quality criteria and source reliability fields in `specs/015-agentrc-brownfield-eval/evidence-register.md`
- [x] T006 Build AC/FR/SC traceability section for evaluation outputs in `specs/015-agentrc-brownfield-eval/recommendation.md`
- [x] T007 Align quickstart validation steps with AC-1..AC-4 and story-level independent tests in `specs/015-agentrc-brownfield-eval/quickstart.md`

**Checkpoint**: All later tasks follow a single evaluation contract.

---

## Phase 3: User Story 1 — Comparar ganho potencial (Priority: P1) 🎯

**Goal**: Produce an objective comparison showing where AgentRC adds value.

**Independent Test**: The matrix explicitly identifies what is new, duplicated, or missing, and each major claim has a traceable evidence source.

- [x] T008 [P] [US1] Map AgentRC capabilities from public documentation into `specs/015-agentrc-brownfield-eval/comparison-matrix.md`
- [x] T009 [P] [US1] Map current Nimbus brownfield capabilities into `specs/015-agentrc-brownfield-eval/comparison-matrix.md`
- [x] T010 [US1] Link each mapped capability to at least one evidence record in `specs/015-agentrc-brownfield-eval/evidence-register.md`
- [x] T011 [US1] Validate US1 completeness against FR-001/FR-004/SC-001 and record validation notes in `specs/015-agentrc-brownfield-eval/recommendation.md`

---

## Phase 4: User Story 2 — Proteger o que já fazemos (Priority: P1) 🎯

**Goal**: Identify conflicts and protect existing governance mechanisms.

**Independent Test**: The analysis lists explicit overlaps/conflicts with graph context, reuse catalog, harness controls, and template governance, with mitigation guidance.

- [x] T012 [P] [US2] Classify each overlapping capability as duplicada, conflitante ou complementar in `specs/015-agentrc-brownfield-eval/comparison-matrix.md`
- [x] T013 [P] [US2] Document impacted current-flow artifacts (spec/plan/tasks, graph, reuse-catalog, harness) in `specs/015-agentrc-brownfield-eval/recommendation.md`
- [x] T014 [US2] Define restriction and mitigation proposals for each conflict item in `specs/015-agentrc-brownfield-eval/recommendation.md`
- [x] T015 [US2] Validate US2 completeness against FR-002/FR-003/SC-002 and update validation notes in `specs/015-agentrc-brownfield-eval/recommendation.md`

---

## Phase 5: User Story 3 — Fechar recomendação de adoção (Priority: P2)

**Goal**: Deliver one clear decision with actionable next step.

**Independent Test**: The final report ends with exactly one recommendation (adotar, adotar com restrições, ou rejeitar) and, if applicable, a minimal pilot scope with exit criteria.

- [x] T016 [P] [US3] Draft the three recommendation options and trade-offs in `specs/015-agentrc-brownfield-eval/recommendation.md`
- [x] T017 [US3] Select and justify a single final recommendation in `specs/015-agentrc-brownfield-eval/recommendation.md`
- [x] T018 [US3] If recommendation is adoption-oriented, define minimal pilot scope and exit criteria in `specs/015-agentrc-brownfield-eval/recommendation.md`
- [x] T019 [US3] Validate US3 completeness against FR-005/FR-006/SC-003/SC-004 and update `specs/015-agentrc-brownfield-eval/quickstart.md`

---

## Phase 6: Polish & Cross-Cutting

**Purpose**: Consolidate final consistency and governance readiness.

- [x] T020 [P] Cross-check terminology consistency across `specs/015-agentrc-brownfield-eval/spec.md`, `specs/015-agentrc-brownfield-eval/plan.md`, and `specs/015-agentrc-brownfield-eval/recommendation.md`
- [x] T021 [P] Refresh references in `specs/015-agentrc-brownfield-eval/quickstart.md` to point to final `comparison-matrix.md`, `evidence-register.md`, and `recommendation.md`
- [x] T022 Consolidate executive-ready summary and decision handoff section in `specs/015-agentrc-brownfield-eval/recommendation.md`

---

## Dependencies & Execution Order

1. **Phase 1** → required before all other phases  
2. **Phase 2** → blocks US1/US2/US3 (common rubric and traceability)  
3. **US1 (Phase 3)** and **US2 (Phase 4)** can run partially in parallel after Phase 2  
4. **US3 (Phase 5)** depends on outputs from US1 + US2  
5. **Phase 6** depends on completion of all story phases

---

## Parallel Execution Examples

### US1
- Run T008 and T009 in parallel, then converge on T010.

### US2
- Run T012 and T013 in parallel, then converge on T014.

### US3
- Start T016 in parallel with final US2 verification; execute T017/T018/T019 sequentially.

---

## Human-Executable Operational Guidance (GHE Contract)

### T014 — Conflict Mitigation Review
**Contexto**: Existem conflitos/duplicações potenciais entre AgentRC e o fluxo Nimbus atual.  
**Objetivo**: Definir mitigação explícita para cada conflito identificado.  
**Resultado Esperado**: Seção de mitigação preenchida com decisão clara por conflito.  
**Critérios de Aceite**:
- [ ] Cada conflito possui uma mitigação proposta
- [ ] Cada mitigação indica impacto no fluxo atual
- [ ] Cada mitigação indica se exige aprovação humana adicional
**Passos Operacionais**:
1. Revisar conflitos em `comparison-matrix.md`.
2. Priorizar conflitos por severidade.
3. Registrar mitigação e restrição em `recommendation.md`.
4. Validar coerência com AC-2 e FR-003.
**Dependências**: T012, T013  
**Responsável**: Agente: sim | Humano: sim  
**Estimativa de Esforço**: Tokens (agente) ~0,5–1,0 mil | Horas (humano) ~0,5–1,0h  
**Referência**: AC-2, Feature `specs/015-agentrc-brownfield-eval`

### T018 — Pilot Scope and Exit Criteria Review
**Contexto**: A recomendação pode exigir piloto mínimo antes de adoção ampla.  
**Objetivo**: Definir escopo e critérios de saída sem interromper o fluxo atual.  
**Resultado Esperado**: Escopo de piloto com limites, métricas e critérios de sucesso/falha.  
**Critérios de Aceite**:
- [ ] Escopo de piloto é mínimo e delimitado
- [ ] Critérios de saída são mensuráveis
- [ ] Preservação do fluxo atual está explícita
**Passos Operacionais**:
1. Confirmar decisão preliminar em `recommendation.md`.
2. Definir limites de escopo (o que entra e o que fica fora).
3. Definir métricas de saída e prazo de avaliação.
4. Revisar aderência a AC-4 e FR-006.
**Dependências**: T017  
**Responsável**: Agente: sim | Humano: sim  
**Estimativa de Esforço**: Tokens (agente) ~0,4–0,8 mil | Horas (humano) ~0,5–1,0h  
**Referência**: AC-4, Feature `specs/015-agentrc-brownfield-eval`

### T022 — Executive Decision Handoff
**Contexto**: A avaliação precisa encerrar com decisão única e acionável.  
**Objetivo**: Consolidar o handoff para aprovação final de engenharia.  
**Resultado Esperado**: Resumo executivo com decisão, racional, riscos e próximo passo.  
**Critérios de Aceite**:
- [ ] Existe uma decisão única (adotar/adotar com restrições/rejeitar)
- [ ] Próximo passo está explícito
- [ ] Riscos residuais estão listados
**Passos Operacionais**:
1. Revisar completude de `recommendation.md`.
2. Consolidar resumo executivo final.
3. Validar alinhamento com AC-3.
4. Encaminhar para revisão humana final.
**Dependências**: T019, T020, T021  
**Responsável**: Agente: sim | Humano: sim  
**Estimativa de Esforço**: Tokens (agente) ~0,4–0,7 mil | Horas (humano) ~0,5–1,0h  
**Referência**: AC-3, Feature `specs/015-agentrc-brownfield-eval`

---

## Implementation Strategy

### MVP First (recommended)
1. Complete Phase 1 and Phase 2.
2. Deliver US1 (objective comparison baseline).
3. Deliver US2 (conflict/risk protection).
4. Close US3 with single recommendation.

### Incremental Delivery
1. Comparison baseline (US1) first.
2. Governance protection (US2) second.
3. Decision closure (US3) last.

### Validation Strategy
- Manual-document validation using `quickstart.md`.
- AC/FR/SC traceability recorded in `recommendation.md`.
- Human checkpoint required for decision closure tasks (T014, T018, T022).
