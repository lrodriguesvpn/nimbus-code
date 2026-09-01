# Tasks: Template Composition Merge Fix

## Phase 1: Setup

- [x] T001 [P] Add isolated fixture helpers in `.specify/scripts/bash/tests/resolve-template-composition.bats` and `.specify/scripts/bash/tests/template-materialization-regression.bats`
- [x] T002 [P] Add golden extract helpers for the 021/022 regression slices in `.specify/scripts/bash/tests/template-materialization-regression.bats`

---

## Phase 2: Foundational

- [x] T003 [US1] Add `materialize_template_content` to `.specify/scripts/bash/common.sh` so composed template content can be written to disk without changing `resolve_template_content()`
- [x] T004 [US1] Update `.specify/scripts/bash/create-new-feature.sh` to write composed `spec-template` content into `$SPEC_FILE`
- [x] T005 [US1] Update `.specify/scripts/bash/setup-plan.sh` to write composed `plan-template` content into `$IMPL_PLAN`
- [x] T006 [US2] Update `.specify/scripts/bash/setup-tasks.sh` to materialize composed `tasks-template` content into a temp file and keep returning the path in `TASKS_TEMPLATE`

---

## Phase 3: User Story 1 - Composer os artefatos nativos já mesclados (Priority: P1)

**Goal**: `spec.md` e `plan.md` must be emitted with the preset appendix already merged into the native Spec Kit templates.

**Independent Test**: A fixture repo with core + preset layers returns composed content for `spec-template` and `plan-template` without using `cp` on a raw path.

- [x] T007 [P] [US1] Add wrap/append/prepend/replace assertions to `.specify/scripts/bash/tests/resolve-template-composition.bats`
- [x] T008 [P] [US1] Add the no-preset regression assertion to `.specify/scripts/bash/tests/resolve-template-composition.bats`
- [x] T009 [US1] Wire the helper-based file materialization checks into `.specify/scripts/bash/tests/resolve-template-composition.bats`

---

## Phase 4: User Story 2 - Preservar o contrato de caminho do tasks template (Priority: P1)

**Goal**: `setup-tasks.sh` must keep returning a file path while serving composed template content.

**Independent Test**: The JSON output still exposes `TASKS_TEMPLATE` as a readable absolute path, and the pointed file already contains the composed template body.

- [x] T010 [P] [US2] Add path-contract assertions for `TASKS_TEMPLATE` in `.specify/scripts/bash/tests/template-materialization-regression.bats`
- [x] T011 [US2] Add file-content assertions proving the temp file contains the composed `tasks-template` body in `.specify/scripts/bash/tests/template-materialization-regression.bats`

---

## Phase 5: User Story 3 - Provar regressão contra os merges manuais de 021/022 (Priority: P2)

**Goal**: The composed output must match the manual merge blocks preserved in specs 021 and 022.

**Independent Test**: Replaying the same layer stack in an isolated fixture reproduces the merged tail already present in the reference specs.

- [x] T012 [P] [US3] Add `plan-template` golden comparison against the merged block preserved in `specs/021-dora-metrics-governance/plan.md`
- [x] T013 [P] [US3] Add `tasks-template` golden comparison against the merged block preserved in `specs/022-nimbuscode-harvest-gateway/tasks.md`
- [x] T014 [US3] Run `bats .specify/scripts/bash/tests/` and fix any remaining regressions until the suite passes

---

## Dependencies & Execution Order

- Phase 1 can start immediately.
- Phase 2 blocks all user-story work.
- US1 depends on Phase 2.
- US2 depends on Phase 2.
- US3 depends on US1 and US2 being green.

## Parallel Opportunities

- T001 and T002 can run in parallel.
- T007, T008, T010, T012, and T013 can run in parallel once the foundational helper exists.
- T004 and T005 can run in parallel after T003.

## Implementation Strategy

1. Add the shared composition helper.
2. Switch the 2 file-writing call sites to composed content.
3. Materialize `tasks-template` to a temp file and preserve the path contract.
4. Lock the behavior with composition and regression tests.
