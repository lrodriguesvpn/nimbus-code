# Tasks: Nimbus Agent Process Q&A and Direct Intake

**Input**: Design docs from `specs/018-nimbus-agent-intake/`  
**Prerequisites**: `plan.md` ✅, `spec.md` ✅, `research.md` ✅, `data-model.md` ✅, `contracts/` ✅, `quickstart.md` ✅, `graph.yaml` ✅, `graph.md` ✅, `impact-map.md` ✅  
**Status**: Ready for Implementation (Release v1.19 / RC1)

## Phase 1: Foundation

- [x] T001 [P] Implement schema validation for `contracts/intake-envelope.contract.md`.
- [x] T002 [P] Implement Q&A response validation for `contracts/process-qa.contract.md`.
- [x] T003 Configure GitHub App scopes, TLS, structured audit logging and OpenFeature flag.

## Phase 2: US2 — Direct intake

- [x] T004 [P] Implement source-event idempotency store.
- [x] T005 Implement intake validation and explicit invalid/reconciliation states.
- [x] T006 Implement central Issue projection with source links and metadata.
- [x] T007 Implement central Project Item projection and field mapping.
- [x] T008 Implement bounded retry and reconciliation for external failures.
- [x] T009 Add contract/integration tests for valid, invalid, replayed and failed intake.

## Phase 3: US1 — Process Q&A

- [x] T010 Implement source precedence across constitution, active artifacts and catalogs.
- [x] T011 Implement cited answers, confidence and clarification output.
- [x] T012 Add tests for in-scope, ambiguous, conflicting and out-of-scope questions.

## Phase 4: US3/US4 — Mode and approval

- [x] T013 Implement SPEC 017 mode decision with confidence and rule references.
- [x] T014 Implement Go/No-Go approval record and execution block.
- [x] T015 Add tests for autonomous, semi-autonomous and manual modes.
- [x] T016 Add audit query for source, mode, approver and decision.

## Phase 5: Pilot and roadmap

- [x] T017 Run `quickstart.md` in pilot with flag enabled only there.
- [x] T018 Validate rollback and reconcile an injected GHE outage.
- [x] T019 Obtain security, architecture and BA approvals before rollout.
- [x] T020 [Roadmap] Specify Teams transcript ingestion separately; do not implement in MVP.
