# Tasks: Hybrid Agent-Human Delivery Templates

**Input**: Design docs from `/specs/016-hybrid-agent-human-dev/`
**Prerequisites**: [plan.md](/Users/lrodrigues/projects/nimbus-code-spec-kit-template.worktrees/vpn-skills-repo-governance-specs/specs/016-hybrid-agent-human-dev/plan.md), [spec.md](/Users/lrodrigues/projects/nimbus-code-spec-kit-template.worktrees/vpn-skills-repo-governance-specs/specs/016-hybrid-agent-human-dev/spec.md), [research.md](/Users/lrodrigues/projects/nimbus-code-spec-kit-template.worktrees/vpn-skills-repo-governance-specs/specs/016-hybrid-agent-human-dev/research.md), [data-model.md](/Users/lrodrigues/projects/nimbus-code-spec-kit-template.worktrees/vpn-skills-repo-governance-specs/specs/016-hybrid-agent-human-dev/data-model.md), [contracts/](/Users/lrodrigues/projects/nimbus-code-spec-kit-template.worktrees/vpn-skills-repo-governance-specs/specs/016-hybrid-agent-human-dev/contracts/)
**Organization**: Tasks are ordered to make the template rollout safe, reviewable, and independently testable.

## Format: `[ID] [P?] [US?] Description`

- **[P]**: Can run in parallel (different files, no dependency)
- **[US]**: User story phase label, when applicable
- Include exact file paths in every task description

---

## Phase 1: Setup & Shared Validation

**Purpose**: Add guardrails so template changes can be validated before rollout.

- [x] T001 [P] Create a contract validation script for generated spec/plan/tasks output in `.specify/scripts/bash/validate-hybrid-contracts.sh`
- [x] T002 [P] Create reusable fixture samples for template-output verification in `specs/016-hybrid-agent-human-dev/fixtures/`
- [x] T003 [P] Wire the contract validation script into CI so PRs can fail fast on malformed template output in `.github/workflows/validate-manifests.yml`

**Checkpoint**: validation scaffolding exists before template changes land.

---

## Phase 2: Foundational Template Contracts

**Purpose**: Update the core template files and skill prompts that power the flow.

- [x] T004 [P] Add the Hybrid Collaboration Model, SLO table, and Assumptions guidance to `.specify/presets/nimbus-code-standards/templates/spec-template.md`
- [x] T005 [P] Add complexity classification, AC traceability, graph references, release strategy, and toggle guidance to `.specify/presets/nimbus-code-standards/templates/plan-template.md`
- [x] T006 [P] Expand the task output contract with Context, Objective, Result, Acceptance Criteria, Operational Steps, Dependencies, Responsible, Estimate, and Reference sections in `.specify/presets/nimbus-code-standards/templates/tasks-template.md`
- [x] T007 [P] Update the generation rules for `/speckit-specify` in `.github/skills/speckit-specify/SKILL.md` so the new spec contract is enforced consistently
- [x] T008 [P] Update the generation rules for `/speckit-plan` in `.github/skills/speckit-plan/SKILL.md` so graph, impact-map, and contract artifacts are always produced
- [x] T009 [P] Update the generation rules for `/speckit-tasks` in `.github/skills/speckit-tasks/SKILL.md` so GHE tasks are human-executable and story-grouped

**Checkpoint**: the three Speckit layers speak the same contract language.

---

## Phase 3: User Story 1 - Definir execucao hibrida clara (Priority: P1)

**Goal**: Make the spec template explicitly describe how agents and humans share the work.

**Independent Test**: Generate one new spec from the template and confirm that the hybrid guidance, SLO section, and assumptions are present without extra prompting.

- [x] T010 [P] [US1] Prepend the hybrid collaboration section to generated spec output in `.specify/presets/nimbus-code-standards/templates/spec-template.md`
- [x] T011 [P] [US1] Make `/speckit-specify` populate the BDD acceptance criteria and success criteria consistently in `.github/skills/speckit-specify/SKILL.md`
- [x] T012 [US1] Validate a sample generated spec against the contract and record any gaps in `specs/016-hybrid-agent-human-dev/quickstart.md`

---

## Phase 4: User Story 2 - Executar tasks detalhadas no GHE (Priority: P1)

**Goal**: Make GHE tasks executable by a human from the issue body alone.

**Independent Test**: Generate one task issue and verify that a developer can execute it using only the issue text, without opening the spec or plan.

- [x] T013 [P] [US2] Expand the task blueprint sections and field order in `.specify/presets/nimbus-code-standards/templates/tasks-template.md`
- [x] T014 [P] [US2] Make `/speckit-tasks` emit explicit operational steps, dependencies, and responsibility fields in `.github/skills/speckit-tasks/SKILL.md`
- [x] T015 [US2] Validate one sample task body for human executability and capture the review checklist in `specs/016-hybrid-agent-human-dev/quickstart.md`

---

## Phase 5: User Story 3 - Rastrear custo do modelo hibrido (Priority: P2)

**Goal**: Embed the SPEC KIT COST reference into the generated artifacts so hybrid delivery cost is visible from day one.

**Independent Test**: Generate the target artifacts and confirm that the public SPEC KIT COST URL appears in the expected template sections.

- [x] T016 [P] [US3] Add the Cost Reference block and SPEC KIT COST URL to `.specify/presets/nimbus-code-standards/templates/plan-template.md`
- [x] T017 [P] [US3] Add the SPEC KIT COST reference and human-hour guidance to `.specify/presets/nimbus-code-standards/templates/tasks-template.md`
- [x] T018 [P] [US3] Add cost-tracking and pilot rollout validation steps to `specs/016-hybrid-agent-human-dev/quickstart.md`
- [x] T019 [US3] Add the reusable `hybrid-dev-templates` pattern entry to `docs/reuse-catalog.yaml` with tag, bounded context, description, and source

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Keep governance artifacts, rollout artifacts, and operational docs in sync.

- [x] T024 [P] Add explicit WEB design standard guidance using Impeccable in `.specify/presets/nimbus-code-standards/templates/spec-template.md` and `.github/skills/speckit-specify/SKILL.md`
- [x] T025 [P] Add explicit OpenFeature standard guidance for rollout/toggles in `.specify/presets/nimbus-code-standards/templates/plan-template.md` and `.github/skills/speckit-plan/SKILL.md`
- [x] T026 [P] Add validation checks in `specs/016-hybrid-agent-human-dev/quickstart.md` confirming Impeccable (WEB) and OpenFeature sections are generated in spec/plan
- [x] T027 [P] Update `specs/016-hybrid-agent-human-dev/contracts/spec-contract.md` and `specs/016-hybrid-agent-human-dev/contracts/plan-contract.md` with the new mandatory governance blocks
- [x] T020 [P] Refresh `specs/016-hybrid-agent-human-dev/graph.yaml` and `specs/016-hybrid-agent-human-dev/graph.md` so the final template and skill wiring is explicit
- [x] T021 [P] Refresh `specs/016-hybrid-agent-human-dev/impact-map.md` so the rollout, rollback, and risk sections match the final implementation
- [x] T022 [P] Add or update ADRs in `docs/adr/` to capture the final decisions on markdown templates, feature-flag rollout, and SPEC KIT COST reference strategy
- [x] T023 [P] Confirm the PR gate uses the new template contract checks by validating `.github/workflows/validate-manifests.yml` against the added script

---

## Implementation Strategy

### MVP First

1. Complete Phase 1 validation scaffolding.
2. Complete Phase 2 foundational template contracts.
3. Complete Phase 3 for spec clarity.
4. Complete Phase 4 for human-executable tasks.
5. Complete Phase 5 for cost visibility.
6. Complete Phase 6 for Impeccable/OpenFeature governance alignment.

### Incremental Delivery

1. Spec contract first so future features start with explicit hybrid guidance.
2. Plan contract next so traceability and rollout are visible.
3. Task contract next so GHE issues become human-friendly.
4. Cost reference last so the public SPEC KIT COST link is consistently embedded.
5. Add Impeccable (WEB) and OpenFeature standards to contracts/templates.
6. Polish only after the generated outputs are stable.

### Validation Strategy

- Each user story has one independent sample-output validation task.
- Template contract failures are blocked in CI.
- The quickstart should prove a human can execute a task from issue text alone.
- The cost reference must be present in every generated artifact where it applies.
- WEB specs must show Impeccable as design standard when context is WEB.
- Plans with toggles must show OpenFeature as abstraction standard.

---

## Parallel Opportunities

### Phase 1

```text
T001: Create contract validation script
T002: Create fixture samples
T003: Wire validation into CI
```

### Phase 2

```text
T004: Update spec template
T005: Update plan template
T006: Update tasks template
T007: Update speckit-specify skill
T008: Update speckit-plan skill
T009: Update speckit-tasks skill
```

### Phase 3

```text
T010: Update spec template for hybrid model
T011: Update specify skill for BDD enforcement
```

### Phase 4

```text
T013: Update tasks template for GHE issues
T014: Update tasks skill for human execution
```

### Phase 5

```text
T016: Update plan template with cost reference
T017: Update tasks template with cost reference
T018: Update quickstart cost validation
T019: Update reuse catalog
```

### Phase 6

```text
T024: Add Impeccable WEB design standard to templates/skills
T025: Add OpenFeature toggle standard to templates/skills
T026: Add quickstart validation for Impeccable/OpenFeature
T027: Update contracts with mandatory governance blocks
```

---

## Delivery Notes

- This feature is intentionally template-heavy: most tasks modify shared generators rather than product code.
- Human review is still required for the final PR because the changes affect every future feature.
- Keep all generated examples aligned with the contracts in `contracts/` and the expectations in `quickstart.md`.
