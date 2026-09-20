# Tasks: Nimbus Digital Engineer Platform

**Input**: Design docs from `specs/017-nimbus-digital-engineer-platform/`  
**Prerequisites**: `plan.md` ✅, `spec.md` ✅, `research.md` ✅, `data-model.md` ✅, `contracts/` ✅, `quickstart.md` ✅, `graph.yaml` ✅, `graph.md` ✅, `impact-map.md` ✅  
**Organization**: Tasks grouped by user story for independent implementation and validation.

**Estado auditado em 2026-09-20**: artefatos documentais presentes; revisão S4
#442 aberta. Os testes `tests/spec017/*.integration.spec.md` especificam cenários,
não são executáveis. `quickstart.md` define passos/resultados esperados, sem
log de simulação executada. T040 é parcial e T041 não possui medições verificáveis;
ambas reabertas. #276 continua aberta/bloqueada até rollout estável e critério
D+21; criar a issue não comprova ativação ou remoção da flag.

## Format: `[ID] [P?] [US?] Description with file path`

- `[P]`: Task can run in parallel (different file, no blocking dependency)
- `[US]`: User story label (`[US1]`, `[US2]`, `[US3]`, `[US4]`, `[US5]`)

---

## Phase 1: Setup (Shared Governance Scaffolding)

**Purpose**: Prepare cross-story structure and execution baseline.

- [x] T001 [P] Create implementation execution log in `specs/017-nimbus-digital-engineer-platform/implementation-log.md`
- [x] T002 [P] Create AC-to-evidence matrix scaffold in `specs/017-nimbus-digital-engineer-platform/evidence-matrix.md`
- [x] T003 [P] Create mode-policy baseline file in `specs/017-nimbus-digital-engineer-platform/mode-policy.md`
- [x] T004 [P] Create human-approval SLA and escalation draft in `specs/017-nimbus-digital-engineer-platform/approval-sla.md`

**Checkpoint**: Shared artifacts exist and are ready for story execution.

---

## Phase 2: Foundational (Blocking Rules and Traceability)

**Purpose**: Establish constraints that all stories depend on.

- [x] T005 Define AC-1..AC-6 traceability entries in `specs/017-nimbus-digital-engineer-platform/evidence-matrix.md`
- [x] T006 Define OpenFeature rollout guardrails and kill-switch procedure in `specs/017-nimbus-digital-engineer-platform/mode-policy.md`
- [x] T007 Define approval authority mapping (RACI roles vs checkpoint stages) in `specs/017-nimbus-digital-engineer-platform/approval-sla.md`
- [x] T008 Align validation flow and expected outcomes with `quickstart.md` in `specs/017-nimbus-digital-engineer-platform/quickstart.md`

**Checkpoint**: Foundational governance contract is complete and consistent.

---

## Phase 3: User Story 1 — Receber e qualificar intake corporativo (Priority: P1) 🎯

**Goal**: Normalize M365/GitHub intake into consistent, ready-to-execute demand records.

**Independent Test**: Two simulated intake sources generate one complete IntakeEntry with required metadata.

- [x] T009 [P] [US1] Define unified intake mapping rules from M365/GitHub in `specs/017-nimbus-digital-engineer-platform/contracts/intake-entry.contract.yaml`
- [x] T010 [P] [US1] Define duplicate-detection strategy for cross-source intake in `specs/017-nimbus-digital-engineer-platform/data-model.md`
- [x] T011 [US1] Define mandatory-field validation and blocked-status behavior in `specs/017-nimbus-digital-engineer-platform/contracts/intake-entry.contract.yaml`
- [x] T012 [US1] Document US1 validation evidence links (AC-1, FR-001) in `specs/017-nimbus-digital-engineer-platform/evidence-matrix.md`

---

## Phase 4: User Story 2 — Operar com modos de autonomia governados (Priority: P1) 🎯

**Goal**: Route demands into autonomous, semi-autonomous, or manual mode with explicit rationale.

**Independent Test**: Low/medium/high risk demands are consistently routed with policy justification.

- [x] T013 [P] [US2] Define classification criteria by risk, criticality, and compliance in `specs/017-nimbus-digital-engineer-platform/mode-policy.md`
- [x] T014 [P] [US2] Define classification contract outputs and policy versioning in `specs/017-nimbus-digital-engineer-platform/contracts/mode-classification.contract.yaml`
- [x] T015 [US2] Define conflict-resolution precedence for contradictory classification signals in `specs/017-nimbus-digital-engineer-platform/mode-policy.md`
- [x] T016 [US2] Document US2 validation evidence links (AC-2, FR-002, FR-009) in `specs/017-nimbus-digital-engineer-platform/evidence-matrix.md`

---

## Phase 5: User Story 3 — Aprovar com RACI claro antes do handoff (Priority: P1) 🎯

**Goal**: Enforce mandatory human approval checkpoints with auditable RACI ownership.

**Independent Test**: Mandatory checkpoints block flow until authorized approver records a decision.

- [x] T017 [P] [US3] Define mandatory approval gates and stage-level approver roles in `specs/017-nimbus-digital-engineer-platform/approval-sla.md`
- [x] T018 [P] [US3] Define checkpoint state model (`pending/go/no_go`) and transition constraints in `specs/017-nimbus-digital-engineer-platform/data-model.md`
- [x] T019 [US3] Define escalation path and timeout handling for missing approvers in `specs/017-nimbus-digital-engineer-platform/approval-sla.md`
- [x] T020 [US3] Document US3 validation evidence links (AC-3, FR-003, FR-004) in `specs/017-nimbus-digital-engineer-platform/evidence-matrix.md`

---

## Phase 6: User Story 4 — Entregar valor com transparência de custo e qualidade (Priority: P2)

**Goal**: Produce an auditable handoff package with quality, ownership, and hybrid cost evidence.

**Independent Test**: Completed demand outputs a DeliveryHandoff containing mandatory quality/cost/responsibility fields.

- [x] T021 [P] [US4] Define mandatory handoff payload fields and evidence requirements in `specs/017-nimbus-digital-engineer-platform/contracts/delivery-handoff.contract.yaml`
- [x] T022 [P] [US4] Define hybrid cost calculation rules (tokens + human hours) in `specs/017-nimbus-digital-engineer-platform/plan.md`
- [x] T023 [US4] Define unresolved-pendencies and ownership disclosure rules in `specs/017-nimbus-digital-engineer-platform/contracts/delivery-handoff.contract.yaml`
- [x] T024 [US4] Document US4 validation evidence links (AC-4, FR-005, FR-006, SC-004) in `specs/017-nimbus-digital-engineer-platform/evidence-matrix.md`

---

## Phase 7: User Story 5 — Framework de badges por domínio (Priority: P2)

**Goal**: Define publishable and auditable domain badges for Digital Engineering tracks.

**Independent Test**: Each prioritized domain has badge criteria, level, and required evidence ready for publication.

- [x] T025 [P] [US5] Define domain badge taxonomy and levels in `specs/017-nimbus-digital-engineer-platform/data-model.md`
- [x] T026 [P] [US5] Define badge eligibility criteria and evidence requirements in `specs/017-nimbus-digital-engineer-platform/quickstart.md`
- [x] T027 [US5] Define badge governance workflow (draft/published/deprecated) in `specs/017-nimbus-digital-engineer-platform/plan.md`
- [x] T028 [US5] Document US5 validation evidence links (AC-6, FR-008, SC-006) in `specs/017-nimbus-digital-engineer-platform/evidence-matrix.md`

---

## Phase 8: Polish & Cross-Cutting

**Purpose**: Consolidate consistency, governance readiness, and handoff quality.

- [x] T029 [P] Cross-check terminology consistency across `specs/017-nimbus-digital-engineer-platform/spec.md`, `specs/017-nimbus-digital-engineer-platform/plan.md`, and `specs/017-nimbus-digital-engineer-platform/tasks.md`
- [x] T030 [P] Refresh graph and impact alignment in `specs/017-nimbus-digital-engineer-platform/graph.yaml`, `specs/017-nimbus-digital-engineer-platform/graph.md`, and `specs/017-nimbus-digital-engineer-platform/impact-map.md`
- [x] T031 Validate final quickstart end-to-end scenarios against AC-1..AC-6 in `specs/017-nimbus-digital-engineer-platform/quickstart.md`
- [x] T032 Create executive handoff summary for BA/Digital Engineering in `specs/017-nimbus-digital-engineer-platform/implementation-log.md`

---

## Dependencies & Execution Order

1. **Phase 1** must complete first.
2. **Phase 2** blocks all user story phases.
3. **US1 (Phase 3)**, **US2 (Phase 4)**, and **US3 (Phase 5)** can start after Phase 2.
4. **US4 (Phase 6)** depends on US1–US3 outputs.
5. **US5 (Phase 7)** can run in parallel with US4 after Phase 2.
6. **Phase 8** depends on completion of all story phases.

---

## Parallel Execution Examples

### US1
- Run T009 and T010 in parallel, then converge on T011.

### US2
- Run T013 and T014 in parallel, then converge on T015.

### US3
- Run T017 and T018 in parallel, then converge on T019.

### US4
- Run T021 and T022 in parallel, then converge on T023.

### US5
- Run T025 and T026 in parallel, then converge on T027.

---

## Human-Executable Operational Guidance (GHE Contract)

### T019 — Escalation Path Validation
**Contexto**: Gates mandatórios podem travar entregas quando aprovadores não respondem no prazo.  
**Objetivo**: Definir e validar rota de escalonamento operacional para evitar bloqueio indefinido.  
**Resultado Esperado**: Regra de escalonamento com prazo, responsável e ação de contingência publicada.  
**Critérios de Aceite**:
- [x] SLA de aprovação definido por criticidade
- [x] Escalonamento possui responsável e prazo de resposta
- [x] Regra está alinhada ao AC-3
**Passos Operacionais**:
1. Revisar checkpoints críticos em `approval-sla.md`.
2. Definir tempo máximo por etapa.
3. Definir próximo aprovador por escalonamento.
4. Validar aderência com BA/PO e registrar no documento.
**Dependências**: T017, T018  
**Responsável**: Agente: sim | Humano: sim  
**Estimativa de Esforço**: Tokens (agente) ~0,6–1,2 mil | Horas (humano) ~1,0–1,5h  
**Referência**: AC-3, Feature `specs/017-nimbus-digital-engineer-platform`

### T022 — Hybrid Cost Rule Review
**Contexto**: O handoff deve sempre apresentar custo de IA e esforço humano para decisão de escala.  
**Objetivo**: Validar fórmula e campos mínimos do custo híbrido no plano e no contrato de handoff.  
**Resultado Esperado**: Regra de custo documentada, consistente entre plan e contrato.  
**Critérios de Aceite**:
- [x] Fórmula de custo híbrido explícita
- [x] Campo de horas humanas obrigatório
- [x] Rastreabilidade com AC-4 e SC-004
**Passos Operacionais**:
1. Revisar seção Cost Reference em `plan.md`.
2. Revisar contrato em `delivery-handoff.contract.yaml`.
3. Ajustar divergências de nomenclatura/unidade.
4. Aprovar com BA e ADE.
**Dependências**: T021  
**Responsável**: Agente: sim | Humano: sim  
**Estimativa de Esforço**: Tokens (agente) ~0,5–0,9 mil | Horas (humano) ~0,5–1,0h  
**Referência**: AC-4, Feature `specs/017-nimbus-digital-engineer-platform`

### T032 — Executive Handoff Approval
**Contexto**: O fechamento da feature exige síntese executiva para decisão de rollout.  
**Objetivo**: Consolidar resultado final para aprovação Go/No-Go por BA e Digital Engineering.  
**Resultado Esperado**: Resumo executivo com decisão, riscos residuais e próximos passos.  
**Critérios de Aceite**:
- [x] Decisão final explícita
- [x] Riscos residuais listados
- [x] Próximo passo com owner definido
**Passos Operacionais**:
1. Consolidar evidências em `implementation-log.md`.
2. Revisar atendimento dos ACs na `evidence-matrix.md`.
3. Validar decisão final com BA e liderança técnica.
4. Publicar handoff final e registrar aprovação.
**Dependências**: T031  
**Responsável**: Agente: sim | Humano: sim  
**Estimativa de Esforço**: Tokens (agente) ~0,6–1,0 mil | Horas (humano) ~1,0–2,0h  
**Referência**: AC-4, AC-6, Feature `specs/017-nimbus-digital-engineer-platform`

---

## Nimbus-Code — Checklist de Qualidade de Código, Testes e Observabilidade

- [x] `graph.yaml` e `graph.md` atualizados para refletir módulos adicionados/alterados
- [ ] Para complexidade S4: revisão humana do `impact-map.md` comprovada (#442 aberta)
- [x] Critérios de aceitação da `spec.md` cobertos com ID de teste rastreável
- [ ] Feature flag configurada em runtime conforme estratégia de release do `plan.md` (fase atual documental)
- [x] Desenho de testes contempla caminhos ON/OFF; execução runtime não comprovada
- [ ] Estratégia de rollout progressivo executada em homologação com evidência anexada
- [x] Tarefa/issue de remoção da flag criada com prazo e owner definidos
- [ ] SLO medido em staging (não aplicável à execução desta fase documental; sem medição real)
- [ ] Revisão de código por IA comprovada no PR sem findings High/Critical pendentes
- [x] Desenhos de integração rastreiam os critérios de aceitação; não constituem testes executados
- [ ] Observabilidade instrumentada em runtime (não aplicável à execução desta fase documental)
- [x] Correlation-id/trace-id propagado entre serviços (ou N/A justificado)
- [x] Bugs fora de escopo encontrados durante execução abertos como issue

**Evidências / N-A justificados**
- Rollout progressivo: cenário 5 de `quickstart.md` é um roteiro de simulação controlada, não evidência de execução; manter T040 parcial.
- Issue de remoção da flag: #276 (owner: Squad ADE Platform, prazo D+21 após estabilização).
- SLO e observabilidade: N/A em ambiente de staging real nesta fase documental; critérios e pontos de medição definidos em `plan.md`.
- Revisão de código por IA: será executada no PR final desta feature (N/A no workspace local).
- Bugs fora de escopo: nenhum encontrado nesta rodada.

## Nimbus-Code — Estimativa vs. Consumo Real de Tokens e Horas Humanas

| Métrica | Estimado (`plan.md`) | Real | Variância | Fonte da medição |
|---|---|---|---|---|
| Tokens (input+output) | ~120–220 mil | não disponível (sem telemetria local de tokens) | N/A | execução local via Copilot CLI sem medidor de token por feature |
| Horas humanas | ~28–44 horas | Não disponível — ~6h foi relatado sem fonte verificável | Não calculável | A confirmar no GitHub Project/registro humano, sem inferir tempo de sessão como trabalho humano |

- [ ] Consumo real registrado e comparado com estimativa (T041 pendente)
- [ ] Horas humanas lançadas no campo "Horas Humanas" do GitHub Project (sem comprovação)
- [ ] Variância analisada quando houver medições; não calculável com dados indisponíveis

---

## Phase 9: Convergence

- [x] T033 Create integration test spec for intake registration in `tests/spec017/intake-registration.integration.spec.md` per AC-1 (missing)
- [x] T034 Create integration test spec for mode classification in `tests/spec017/mode-classification.integration.spec.md` per AC-2 (missing)
- [x] T035 Create integration test spec for approval gate behavior in `tests/spec017/approval-gate.integration.spec.md` per AC-3 (missing)
- [x] T036 Create integration test spec for handoff package validation in `tests/spec017/handoff-package.integration.spec.md` per AC-4 (missing)
- [x] T037 Create integration test spec for OpenFeature toggle coverage (ON/OFF) in `tests/spec017/openfeature-toggle.integration.spec.md` per AC-5 (missing)
- [x] T038 Create integration test spec for domain badges validation in `tests/spec017/domain-badges.integration.spec.md` per AC-6 (missing)
- [x] T039 Update quality checklist statuses with concrete evidence or justified N/A entries in `specs/017-nimbus-digital-engineer-platform/tasks.md` per plan: Qualidade de Código, Testes e Observabilidade Gate (partial)
- [ ] T040 **PARTIAL**: flag-removal issue #276 exists and is blocked; runtime rollout evidence is not available. Attach actual evidence before closing; `quickstart.md` is only the procedure.
- [ ] T041 Fill real token/human-hours consumption table with measured source data in `specs/017-nimbus-digital-engineer-platform/tasks.md` per plan: Cost Reference — unavailable, not inferred from estimates.
