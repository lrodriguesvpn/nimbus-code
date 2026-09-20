# Tasks: Nimbus Agent Process Q&A and Direct Intake

**Input**: Design docs from `specs/018-nimbus-agent-intake/`  
**Prerequisites**: `plan.md` ✅, `spec.md` ✅, `research.md` ✅, `data-model.md` ✅, `contracts/` ✅, `quickstart.md` ✅, `graph.yaml` ✅, `graph.md` ✅, `impact-map.md` ✅  
**Status**: Ready for Implementation (Release v1.19 / RC1)

## Phase 1: Foundation

- [ ] T001 [P] Implement schema validation for `contracts/intake-envelope.contract.md`.
- [ ] T002 [P] Implement Q&A response validation for `contracts/process-qa.contract.md`.
- [ ] T003 Configure GitHub App scopes, TLS, structured audit logging and OpenFeature flag.

## Phase 2: US2 — Direct intake

- [ ] T004 [P] Implement source-event idempotency store.
- [ ] T005 Implement intake validation and explicit invalid/reconciliation states.
- [ ] T006 Implement central Issue projection with source links and metadata.
- [ ] T007 Implement central Project Item projection and field mapping.
- [ ] T008 Implement bounded retry and reconciliation for external failures.
- [ ] T009 Add contract/integration tests for valid, invalid, replayed and failed intake.

## Phase 3: US1 — Process Q&A

- [ ] T010 Implement source precedence across constitution, active artifacts and catalogs.
- [ ] T011 Implement cited answers, confidence and clarification output.
- [ ] T012 Add tests for in-scope, ambiguous, conflicting and out-of-scope questions.

## Phase 4: US3/US4 — Mode and approval

- [ ] T013 Implement SPEC 017 mode decision with confidence and rule references.
- [ ] T014 Implement Go/No-Go approval record and execution block.
- [ ] T015 Add tests for autonomous, semi-autonomous and manual modes.
- [ ] T016 Add audit query for source, mode, approver and decision.

## Phase 5: Pilot and roadmap

- [ ] T017 Run `quickstart.md` in pilot with flag enabled only there.
- [ ] T018 Validate rollback and reconcile an injected GHE outage.
- [ ] T019 Obtain security, architecture and BA approvals before rollout.
- [ ] T020 [Roadmap] Specify Teams transcript ingestion separately; do not implement in MVP.
