# Tasks: Camada de Governanca IA Corporativa M365

**Input**: Design artifacts from `specs/002-camada-governanca-ia-corporativa-m365/`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `quickstart.md`

## Implementation Strategy

Deliver the documentation layer in thin slices:
1. Establish a central governance index and shared entry points.
2. Update the corporate constitution and company-wide guidance first.
3. Add the M365-specific guidance, then the legacy-tool guide.
4. Add the Nimbus alias map last so it references the finalized wording.
5. Finish with cross-link and validation cleanup.

## Task Dependencies

- **Foundation first**: T001-T005 must land before user-story work.
- **US1** unlocks the shared constitution and is the reference point for the other stories.
- **US2, US3, and US4** may proceed in parallel after the foundational updates, but each should reuse the constitution wording from US1.
- **Polish** runs after all user-story tasks are complete.

## Phase 1: Setup

**Goal**: create a single navigation point for the new governance layer.

**Independent test**: a reader can open one index file and discover every governance artifact for this feature.

- [x] T001 [P] Create `docs/ai-governance/README.md` as the central index for the corporate AI constitution, the M365 governance guide, the legacy-tool guide, and the Nimbus alias map.

## Phase 2: Foundational

**Goal**: align the repository-wide docs and templates with the new company-wide AI governance model.

**Independent test**: the README, developer guide, constitution template, and Copilot instructions all point to the same official-tool stance and governance index.

- [x] T002 [P] Update `README.md` and `docs/developer-guide.md` with the new governance index, the official AI tool positioning, and the instruction to reuse the single corporate constitution.
- [x] T003 [P] Update `presets/nimbus-code-standards/templates/constitution-template.md` so the constitution is clearly a single company-wide AI policy, not a tool-specific policy.
- [x] T004 [P] Update `presets/nimbus-code-standards/templates/project-root/copilot-instructions.md` with the official-tool statement and the compatibility note for Nimbus aliases.
- [x] T005 [P] Update `docs/ai-code-quality-and-observability.md` with a short cross-reference explaining how the constitution applies across Microsoft 365 Copilot, GitHub Enterprise Copilot, Claude Enterprise, and ChatGPT.

## Phase 3: User Story 1 - Constituição única de IA (Priority: P1)

**Goal**: define one corporate AI constitution that applies to every AI usage path in the company.

**Independent test**: a reviewer can confirm that the constitution is the single source of policy and that no alternative AI policy is introduced elsewhere.

- [x] T006 [P] [US1] Create `docs/ai-governance/corporate-constitution.md` as the canonical company-wide AI constitution with scope, ownership, approved tools, and shared rules.
- [x] T007 [US1] Link `docs/ai-governance/corporate-constitution.md` from `docs/ai-governance/README.md` and `README.md`, making the constitution the canonical source of truth.

## Phase 4: User Story 2 - Governança para M365 (Priority: P1)

**Goal**: document how the single constitution applies to Microsoft 365 Copilot, M365 Copilot CoWork, and company-created agents in M365.

**Independent test**: a M365 owner can read one document and understand creation, sharing, publishing, and governance expectations.

- [x] T008 [P] [US2] Create `docs/ai-governance/m365-governance.md` covering Microsoft 365 Copilot, M365 Copilot CoWork, agent creation, sharing scope, publishing, and admin governance expectations.
- [x] T009 [US2] Update `docs/developer-guide.md` with the M365 governance workflow, the admin/governance surface, and the official Microsoft Copilot positioning.

## Phase 5: User Story 3 - Uso da mesma constituição em Claude Enterprise e ChatGPT (Priority: P2)

**Goal**: show legacy-tool users how to reuse the same constitution without creating a separate policy.

**Independent test**: a legacy-tool user can follow one guide and understand the shared constitution plus the official-tool statement.

- [x] T010 [P] [US3] Create `docs/ai-governance/legacy-tool-guidance.md` explaining how Claude Enterprise and ChatGPT users follow the same corporate constitution.
- [x] T011 [US3] Update `docs/developer-guide.md` and `docs/ai-governance/README.md` to point legacy-tool users to the shared constitution and the official-tool guidance.

## Phase 6: User Story 4 - Aliases Nimbus para Spec Kit (Priority: P2)

**Goal**: document Nimbus command names as an alias layer while preserving the original Spec Kit commands.

**Independent test**: a reader can map every Nimbus alias back to the original command and confirm compatibility is preserved.

- [x] T012 [P] [US4] Create `docs/ai-governance/nimbus-aliases.md` documenting the alias map from Spec Kit commands to Nimbus names.
- [x] T013 [US4] Update `README.md` and `docs/agent-session-manual.md` with the Nimbus naming convention and the explicit statement that original Spec Kit commands remain valid.

## Phase 7: Polish & Cross-Cutting Concerns

**Goal**: make the documentation set internally consistent and easy to validate.

**Independent test**: the quickstart checklist can be followed end-to-end without finding missing links, inconsistent names, or unresolved scope gaps.

- [x] T014 [P] Normalize cross-links, headings, and terminology across `README.md`, `docs/developer-guide.md`, `docs/ai-governance/*.md`, and the updated preset templates.
- [x] T015 [P] Validate the final documentation set against `specs/002-camada-governanca-ia-corporativa-m365/quickstart.md` and update any filenames or references that drifted during implementation.

## Parallel Execution Examples

### US1
- T006 and T007 can run in parallel after T001-T005 are complete.

### US2
- T008 can run independently once the foundational docs are in place; T009 can follow in parallel with US3 or US4.

### US3
- T010 can run independently once the foundational docs are in place; T011 can proceed after the legacy guide draft exists.

### US4
- T012 can run independently once the foundational docs are in place; T013 can proceed after the alias map draft exists.

## Task Count Summary

- Total tasks: 15
- Phase 1 (Setup): 1
- Phase 2 (Foundational): 4
- Phase 3 (US1): 2
- Phase 4 (US2): 2
- Phase 5 (US3): 2
- Phase 6 (US4): 2
- Phase 7 (Polish): 2
