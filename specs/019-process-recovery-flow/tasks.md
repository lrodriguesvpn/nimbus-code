# Tasks: Fluxo de Correção de Rota para Specs Existentes

> Auditoria 2026-09-20: as 26 tarefas marcadas registram entrega documental,
> não aprovação humana. Revisão e validação operacional continuam em #435/#444.
> Essas issues descrevem remediação S3/impact-map; o conteúdo publicado auditado
> permanece S2 e não contém esse mapa. Localizar a branch/evidência da remediação
> antes de declarar integração ou alterar a classificação. Contratos humanos
> abertos abaixo não foram aprovados por esta auditoria.

**Entrada**: Artefatos de design de `/specs/019-process-recovery-flow/`  
**Pré-requisitos**: `plan.md` ✅, `spec.md` ✅, `research.md` ✅, `data-model.md` ✅, `quickstart.md` ✅, `graph.yaml` ✅, `graph.md` ✅, `contracts/` ✅  
**Organização**: Tarefas agrupadas por user story para validação independente do fluxo operacional de decisão.

## Format: `[ID] [P?] [US?] Description with file path`

- `[P]`: tarefa pode rodar em paralelo (arquivos diferentes, sem dependência bloqueante)
- `[US]`: rótulo da user story (`[US1]`, `[US2]`, `[US3]`, `[US4]`)

---

## Phase 1: Setup (Base Compartilhada do Fluxo de Correção)

**Objetivo**: Preparar os artefatos da feature e os pontos de rastreabilidade compartilhados por todas as stories.

- [X] T001 Consolidate feature references and recovery-flow scope in `specs/019-process-recovery-flow/plan.md`
- [X] T002 [P] Align `specs/019-process-recovery-flow/research.md` with the final operational vocabulary (`clarify`, `converge`, `same spec`, `new spec`)
- [X] T003 [P] Align `specs/019-process-recovery-flow/data-model.md` and `specs/019-process-recovery-flow/contracts/process-correction-decision.contract.md` so entities, fields and decision rules use the same terms

**Checkpoint**: Linguagem compartilhada e rastreabilidade estabilizadas antes de alterar as saídas documentais das stories.

---

## Phase 2: Foundational (Pré-requisitos Normativos e Transversais)

**Objetivo**: Estabelecer as regras normativas das quais todas as user stories dependem antes de refinar a orientação por cenário.

- [ ] T004 Update `.specify/memory/constitution.md` with the final policy wording for code-in-English and docs-in-Portuguese, replicate it to the applicable presets/copies, and obtain Architecture Board approval
- [X] T005 Refresh `specs/019-process-recovery-flow/graph.yaml`, `specs/019-process-recovery-flow/graph.md` and `specs/019-process-recovery-flow/impact-map.md` with distributed-template dependencies
- [X] T006 Build the final AC/FR/SC traceability notes for manual validation in `specs/019-process-recovery-flow/quickstart.md`

**Checkpoint**: Regra constitucional, grafo e baseline de validação prontos para todas as user stories.

## Phase 2A: S3 Remediation — Impact, Parity and Human Gate

**Objetivo**: Fechar os gates transversais introduzidos pela reclassificação S3
antes de considerar a documentação pronta para publicação.

- [X] T027 [P] Create `specs/019-process-recovery-flow/impact-map.md` with affected modules, risks, owners, rollback and Go/No-Go criteria
- [X] T028 [P] Update `specs/019-process-recovery-flow/plan.md` from S2 to S3, including the Architecture Board approval gate and adoption metrics
- [ ] T029 [P] Compare `.specify/memory/constitution.md` with the applicable constitution templates and record any intentional scope difference in the ADL
- [X] T030 [P] Synchronize `presets/nimbus-code-standards/templates/constitution-template.md`, `presets/nimbus-code-platform-standards/templates/constitution-template.md` and mirror copies when the normative rule applies
- [X] T031 [P] Synchronize applicable `presets/*/templates/project-root/copilot-instructions.md` copies without creating a competing normative rule
- [ ] T032 Validate template parity and attach the comparison evidence to the PR
- [ ] T033 Record Architecture Board approval and Go/No-Go decision in the plan and PR evidence

---

## Phase 3: User Story 1 — Corrigir erro de implementação sem reescrever a intenção (Priority: P1) 🎯

**Objetivo**: Tornar o guia inequívoco quando o problema está apenas na implementação e a fonte de verdade continua válida.

**Independent Test**: Lendo o guia, um desenvolvedor conclui corretamente que erros apenas de implementação pedem correção de código mais `converge`, e não reescrita de spec.

- [X] T007 [P] [US1] Refine the decision matrix for implementation-only errors in `docs/developer-guide.md`
- [X] T008 [US1] Add or adjust the Mermaid flow for implementation-error handling in `docs/developer-guide.md`
- [X] T009 [US1] Align `specs/019-process-recovery-flow/contracts/process-correction-decision.contract.md` with the implementation-error rule and forbidden actions
- [X] T010 [US1] Validate US1 coverage against AC-1, FR-001, FR-002 and SC-001 in `specs/019-process-recovery-flow/quickstart.md`

---

## Phase 4: User Story 2 — Corrigir ambiguidade da spec existente (Priority: P1) 🎯

**Objetivo**: Tornar o processo explícito quando a ambiguidade está na `spec.md` atual e `clarify` deve ser usado apenas quando realmente necessário.

**Independent Test**: Um BA ou Dev, lendo o guia, distingue “ambiguidade da spec” de “bug de implementação” e sabe que a mesma `spec.md` é o alvo padrão de atualização.

- [X] T011 [P] [US2] Refine the decision matrix rows for ambiguous/incomplete acceptance criteria in `docs/developer-guide.md`
- [X] T012 [US2] Expand the FAQ answers for “quando atualizar a mesma spec” and “quando usar clarify” in `docs/developer-guide.md`
- [X] T013 [US2] Add or adjust the Mermaid flow for spec-ambiguity handling in `docs/developer-guide.md`
- [X] T014 [US2] Synchronize `specs/019-process-recovery-flow/research.md`, `specs/019-process-recovery-flow/data-model.md` and `specs/019-process-recovery-flow/quickstart.md` with the clarified source-of-truth rule and related edge cases

---

## Phase 5: User Story 3 — Replanejar arquitetura sem perder o recorte da feature (Priority: P1) 🎯

**Objetivo**: Documentar o caminho de correção para falha arquitetural preservando a mesma feature quando a intenção de negócio não muda.

**Independent Test**: Um tech lead consegue ler o guia e concluir corretamente que correções de arquitetura normalmente atualizam o mesmo `plan.md`, e só atualizam a mesma `spec.md` se o comportamento esperado mudar.

- [X] T015 [P] [US3] Refine the architecture-replan decision row and narrative in `docs/developer-guide.md`
- [X] T016 [US3] Adjust the Mermaid flow for architecture-error handling in `docs/developer-guide.md`
- [X] T017 [US3] Align `specs/019-process-recovery-flow/contracts/process-correction-decision.contract.md` and `specs/019-process-recovery-flow/data-model.md` with the architecture-replan path
- [X] T018 [US3] Validate US3 coverage against AC-3, FR-004 and SC-001 in `specs/019-process-recovery-flow/quickstart.md`

---

## Phase 6: User Story 4 — Identificar quando o caso virou nova spec (Priority: P2)

**Objetivo**: Tornar o limiar para abrir uma nova spec objetivo e reproduzível, em vez de intuitivo ou ad hoc.

**Independent Test**: Um BA consegue ler o guia e explicar quando um trabalho ainda é correção da mesma feature versus quando vira uma nova entrega de valor.

- [X] T019 [P] [US4] Refine the “critério oficial para abrir nova spec” section in `docs/developer-guide.md`
- [X] T020 [US4] Align `specs/019-process-recovery-flow/contracts/process-correction-decision.contract.md` and `specs/019-process-recovery-flow/data-model.md` with the new-spec criteria
- [X] T021 [US4] Expand the decision guidance and examples in `docs/developer-guide.md` so edge cases that still belong to the same value slice do not open a new spec by mistake
- [X] T022 [US4] Validate US4 coverage against AC-4, AC-5, FR-005 and SC-002 in `specs/019-process-recovery-flow/quickstart.md`

---

## Phase 7: Polish & Cross-Cutting Concerns

**Objetivo**: Fazer a passagem final de consistência em todo o conjunto documental e nos artefatos de governança.

- [X] T023 [P] Cross-check terminology consistency across `specs/019-process-recovery-flow/spec.md`, `specs/019-process-recovery-flow/plan.md`, `specs/019-process-recovery-flow/research.md`, and `specs/019-process-recovery-flow/contracts/process-correction-decision.contract.md`
- [X] T024 [P] Refresh references, links and edge-case coverage in `docs/developer-guide.md` and `specs/019-process-recovery-flow/quickstart.md`
- [X] T025 Consolidate final implementation notes and executive-ready summary in `specs/019-process-recovery-flow/plan.md`
- [X] T026 Add reusable-pattern entry for this process decision model in `docs/reuse-catalog.yaml`
- [X] T034 Define the standardized post-release questionnaire, baseline, sample and owner for SC-002 in `specs/019-process-recovery-flow/quickstart.md`
- [X] T035 Add the three-dimensional value-slice test (business outcome, actors/users, delivery boundary) to the contract, data model and decision matrix
- [ ] T036 Validate all recovery and post-merge edge cases, including wrong-artifact work, rollback and cross-repository impact

---

## Dependencies & Execution Order

1. **Phase 1** → required before all later work
2. **Phase 2** → blocks all user stories (shared constitutional and graph baseline)
3. **Phase 2A** → blocks Go/No-Go and publication because it closes the S3 impact/parity/human gates
4. **US1 (Phase 3)** and **US2 (Phase 4)** can run in parallel after Phase 2A
5. **US3 (Phase 5)** depends on the vocabulary stabilized in US1/US2
6. **US4 (Phase 6)** depends on the decision model consolidated in US1–US3
7. **Phase 7** depends on completion of all story phases and Phase 2A

---

## Parallel Execution Examples

### US1
- Run T007 and T009 in parallel, then converge on T008 and T010.

### US2
- Run T011 and T013 in parallel, then converge on T012 and T014.

### US3
- Run T015 and T017 in parallel, then converge on T016 and T018.

### US4
- Run T019 and T020 in parallel, then converge on T021 and T022.

---

## Implementation Strategy

### MVP First (Recommended)
1. Complete **Phase 1** and **Phase 2**
2. Deliver **US1** first to lock the most common correction path (`implement` + `converge`)
3. Deliver **US2** and **US3** next to cover spec and architecture corrections
4. Finish with **US4** to close the “new spec vs same spec” threshold
5. Run final consistency pass in **Phase 7**

### Incremental Delivery
- After US1, the guide already resolves the most frequent operational doubt
- After US2 + US3, the process becomes safe for both BA and tech lead decisions
- After US4, the process is complete for correction-of-route governance

---

## Human-Executable Operational Guidance (GHE Contract)

### T004 — Confirmar política normativa de idioma
**Contexto**: A constituição passa a carregar a regra oficial de idioma para código e documentação.  
**Objetivo**: Validar que a regra ficou clara, aplicável e sem conflito com artefatos existentes.  
**Resultado Esperado**: Política publicada em `.specify/memory/constitution.md` com distinção objetiva entre artefatos de código e artefatos de documentação.  
**Critérios de Aceite**:
- [ ] A regra exige inglês para artefatos de código
- [ ] A regra exige português para documentação versionada
- [ ] Exceções estão descritas de forma explícita
**Passos Operacionais**:
1. Abrir `.specify/memory/constitution.md`.
2. Revisar a seção “Idioma dos Artefatos”.
3. Confirmar que a redação cobre arquivos de código, símbolos, contratos e documentação.
4. Registrar ajuste textual se houver ambiguidade normativa.
**Dependências**: T001  
**Responsável**: Agente: sim | Humano: sim  
**Estimativa de Esforço**:
- Tokens (agente): ~0,4–0,8 mil
- Horas (humano): ~0,2–0,5 horas
**Referência**:
- FR-008
- SC-004
- Feature: `specs/019-process-recovery-flow`

### T021 — Reforçar o critério de nova spec com exemplos de borda
**Contexto**: O time ainda pode confundir “mudou bastante” com “virou nova feature”, mesmo quando o recorte de valor continua o mesmo.  
**Objetivo**: Tornar a decisão de abrir nova spec objetiva também nos casos de borda descritos na feature.  
**Resultado Esperado**: O guia passa a trazer exemplos claros do que continua na mesma feature e do que realmente exige nova spec.  
**Critérios de Aceite**:
- [ ] O texto cobre pelo menos um caso de “parece nova feature, mas ainda não é”
- [ ] O texto cobre pelo menos um caso que realmente exige nova spec
- [ ] O texto fica consistente com os edge cases da feature 019
**Passos Operacionais**:
1. Revisar os edge cases em `specs/019-process-recovery-flow/spec.md`.
2. Atualizar a seção correspondente em `docs/developer-guide.md`.
3. Incluir exemplos que diferenciem expansão de escopo de correção da mesma feature.
4. Validar consistência com os critérios de abertura de nova spec.
**Dependências**: T019, T020  
**Responsável**: Agente: sim | Humano: sim  
**Estimativa de Esforço**:
- Tokens (agente): ~0,5–1,0 mil
- Horas (humano): ~0,3–0,6 horas
**Referência**:
- AC-ID: AC-5
- FR-005
- Feature: `specs/019-process-recovery-flow`

### T026 — Catalogar o padrão reutilizável desta feature
**Contexto**: A feature introduz uma regra organizacional reaproveitável para correção de rota de specs existentes.  
**Objetivo**: Registrar o padrão no catálogo de reuso para que futuros planos apontem para ele em vez de rederivar a lógica do zero.  
**Resultado Esperado**: Nova entrada em `docs/reuse-catalog.yaml` apontando para esta feature.  
**Critérios de Aceite**:
- [ ] A entrada tem `tag`, `bounded_context`, `description` e `source`
- [ ] A descrição permite entender quando reutilizar o padrão
- [ ] O `source` aponta para a feature 019
**Passos Operacionais**:
1. Abrir `docs/reuse-catalog.yaml`.
2. Identificar a posição consistente para inserir a nova entrada.
3. Registrar a nova tag com descrição curta e acionável.
4. Validar se a entrada não duplica tag já existente.
**Dependências**: T023, T024, T025  
**Responsável**: Agente: sim | Humano: sim  
**Estimativa de Esforço**:
- Tokens (agente): ~0,3–0,6 mil
- Horas (humano): ~0,2–0,4 horas
**Referência**:
- AC-ID: AC-4, AC-5
- Feature: `specs/019-process-recovery-flow`
