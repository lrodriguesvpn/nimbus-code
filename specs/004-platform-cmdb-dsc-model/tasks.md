# Tasks: Plataforma CMDB + Baselines de Segurança e Compliance

**Input**: Design documents from `/specs/004-platform-cmdb-dsc-model/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Estado verificável — 2026-09-20

Os 80 marcadores concluídos abaixo são preservados como registro histórico,
não como comprovação de prontidão de produção. A implementação encontrada é
JavaScript/CommonJS: os caminhos `.ts` foram corrigidos para arquivos `.js`
existentes, e a CLI e os grafos apontam para suas localizações reais.

- **Verificado:** 16/16 testes de contrato, integração, e2e e performance passaram
  com `node --test` nos respectivos diretórios de `platform-governance/tests/`.
  O harness usa fixtures; esse resultado não demonstra integração cloud/IdP real.
- **Limites concretos:** `platform-governance/src/discovery/azure-discovery.js`
  usa `createFixtureDiscoveryAdapter`; em
  `platform-governance/src/runtime/platform-governance.js`, `createSsoClient`
  valida campos do contexto, `createGovernanceRepository` mantém dados em memória
  e `createRefreshScheduler` avalia atraso, sem executar coletas periódicas.
  O teste `platform-governance/tests/performance/governance-benchmarks.test.js`
  verifica timestamps de freshness, não latência nem execução operacional por 24h.
- **Entrega não localizada:** T005 permanece marcada no histórico, mas
  `platform-governance/.env.example` não existe no checkout auditado.
- **Lacunas de evidência:** SSO real, descoberta cloud real, persistência durável,
  atualização operacional em 24h e aprovação S4 não foram comprovados. A issue
  [#458](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code/issues/458)
  foi criada em 2026-09-20 para acompanhar a prontidão operacional e os gates S4,
  após a auditoria inicial não identificar issue aberta para essas lacunas.
  O fechamento da feature #147 não comprova prontidão operacional. As lacunas
  não foram implementadas nem tiveram gates aprovados durante o saneamento documental.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Initialize platform-governance workspace, shared tooling, and project scaffolding.

- [X] T001 Create top-level project structure for platform-governance components in `platform-governance/`
- [X] T002 [P] Create repository README for the platform preset and CMDB scope in `platform-governance/README.md`
- [X] T003 [P] Create contribution and operating model docs in `platform-governance/docs/CONTRIBUTING.md`
- [X] T004 [P] Create governance overview doc describing SSO, CMDB, baseline, and DSC scope in `platform-governance/docs/GOVERNANCE.md`
- [X] T005 [P] Create environment variable template for tenant/provider settings in `platform-governance/.env.example`
- [X] T006 [P] Create base CI workflow for lint, tests, and security checks in `platform-governance/.github/workflows/ci.yml`
- [X] T007 [P] Create release workflow with canary rollout and rollback gates in `platform-governance/.github/workflows/release.yml`
- [X] T008 [P] Create graph guard workflow for `graph.yaml` and `graph.md` validation in `platform-governance/.github/workflows/graph-guard.yml`
- [X] T009 [P] Create bootstrap script for local setup and validation in `platform-governance/bootstrap.sh`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared identity, data, validation, and observability building blocks.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T010 [P] Define shared execution context and identity model in `platform-governance/src/shared/models/execution-context.js`
- [X] T011 [P] Define shared CMDB asset primitives in `platform-governance/src/shared/models/cmdb-record.js`
- [X] T012 [P] Define shared compliance finding primitives in `platform-governance/src/shared/models/compliance-finding.js`
- [X] T013 [P] Create SSO session bootstrap client in `platform-governance/src/shared/auth/sso-client.js`
- [X] T014 [P] Create tenant/provider discovery interfaces in `platform-governance/src/shared/discovery/provider-registry.js`
- [X] T015 [P] Create audit logging helper with correlation metadata in `platform-governance/src/shared/observability/audit-logger.js`
- [X] T016 [P] Create shared error taxonomy for auth, discovery, baseline, and DSC flows in `platform-governance/src/shared/errors/index.js`
- [X] T017 Create persistence schema and migration set for executions, assets, findings, exceptions, and DSC profiles in `platform-governance/db/migrations/001_initial.sql`
- [X] T018 [P] Create data access layer for CMDB and baseline records in `platform-governance/src/shared/storage/governance-repository.js`
- [X] T019 [P] Create validation utilities for scope, freshness, and versioning rules in `platform-governance/src/shared/validation/governance-rules.js`
- [X] T020 Create API server scaffold and health endpoint in `platform-governance/src/api/server.js`
- [X] T021 [P] Create API middleware stack for auth, request validation, and structured errors in `platform-governance/src/api/middleware/index.js`
- [X] T022 [P] Create CLI scaffold for operational validation commands in `platform-governance/src/cli/main.js`
- [X] T023 Create contract test harness and shared fixtures in `platform-governance/tests/setup.js`
- [X] T024 [P] Create sample tenant/provider fixture set for Azure, AWS, GCP, and M365 in `platform-governance/tests/fixtures/`

**Checkpoint**: Foundation ready - all user stories can now proceed independently.

---

## Phase 3: User Story 1 - Onboarding de Plataforma com Autenticação Governada (Priority: P1) 🎯 MVP

**Goal**: Allow an operator to select a platform scope and authenticate via corporate SSO before any collection occurs.

**Independent Test**: A user can create an execution, authenticate, and see an auditable scope record without starting discovery yet.

### Tests for User Story 1 (OPTIONAL - included because acceptance criteria require verification)

- [X] T025 [P] [US1] Contract test for SSO session bootstrap in `platform-governance/tests/contract/auth-session.contract.test.js`
- [X] T026 [P] [US1] Integration test for execution creation and scope persistence in `platform-governance/tests/integration/execution-scope.test.js`
- [X] T027 [P] [US1] End-to-end test for authentication failure and authorization rejection in `platform-governance/tests/e2e/auth-rejection.test.js`

### Implementation for User Story 1

- [X] T028 [P] [US1] Implement execution creation endpoint in `platform-governance/src/api/routes/executions.js`
- [X] T029 [P] [US1] Implement SSO session validation endpoint in `platform-governance/src/api/routes/auth.js`
- [X] T030 [P] [US1] Implement platform selection and scope persistence in `platform-governance/src/domain/execution-service.js`
- [X] T031 [US1] Implement authorization enforcement for selected platforms in `platform-governance/src/domain/authorization-service.js`
- [X] T032 [P] [US1] Implement audit trail writes for authentication and scope selection in `platform-governance/src/shared/observability/audit-trail.js`
- [X] T033 [P] [US1] Add user-facing error messages for invalid identity and insufficient scope in `platform-governance/src/api/errors/auth-errors.js`
- [X] T034 [US1] Wire UI/CLI prompt flow for platform selection and SSO handoff in `platform-governance/src/cli/commands/start-execution.js`
- [X] T035 [P] [US1] Add telemetry for onboarding completion and rejection events in `platform-governance/src/shared/observability/metrics.js`

**Checkpoint**: User Story 1 should now be independently functional.

---

## Phase 4: User Story 2 - CMDB para IA com Inventário de Recursos e Dados (Priority: P1)

**Goal**: Consolidate multicloud assets, relationships, and evidence into an AI-friendly CMDB.

**Independent Test**: An authenticated execution can collect assets from multiple clouds and persist normalized CMDB records with provenance and history.

### Tests for User Story 2

- [X] T036 [P] [US2] Contract test for CMDB record retrieval in `platform-governance/tests/contract/cmdb.contract.test.js`
- [X] T037 [P] [US2] Integration test for multicloud ingestion and normalization in `platform-governance/tests/integration/cmdb-ingestion.test.js`
- [X] T038 [P] [US2] End-to-end test for repeat collection preserving history in `platform-governance/tests/e2e/cmdb-history.test.js`

### Implementation for User Story 2

- [X] T039 [P] [US2] Implement Azure discovery adapter in `platform-governance/src/discovery/azure-discovery.js`
- [X] T040 [P] [US2] Implement AWS discovery adapter in `platform-governance/src/discovery/aws-discovery.js`
- [X] T041 [P] [US2] Implement GCP discovery adapter in `platform-governance/src/discovery/gcp-discovery.js`
- [X] T042 [P] [US2] Implement discovery orchestrator for parallel provider collection in `platform-governance/src/domain/discovery-orchestrator.js`
- [X] T043 [US2] Implement CMDB consolidation service and normalization rules in `platform-governance/src/domain/cmdb-consolidation-service.js`
- [X] T044 [P] [US2] Implement asset relationship inference and confidence scoring in `platform-governance/src/domain/asset-relationship-service.js`
- [X] T045 [P] [US2] Implement evidence ingestion and provenance tracking in `platform-governance/src/domain/evidence-service.js`
- [X] T046 [US2] Implement CMDB query API for IA/governance consumers in `platform-governance/src/api/routes/cmdb.js`
- [X] T047 [P] [US2] Implement freshness and completeness checks for CMDB records in `platform-governance/src/shared/validation/cmdb-freshness.js`
- [X] T048 [P] [US2] Add storage indexing for provider, criticality, and scope queries in `platform-governance/db/migrations/002_cmdb_indexes.sql`
- [X] T049 [US2] Add inventory export support for governance reports in `platform-governance/src/domain/export/cmdb-export-service.js`

**Checkpoint**: User Story 2 should now be independently functional.

---

## Phase 5: User Story 3 - Baselines de M365, Políticas Aplicadas e Customizações (Priority: P2)

**Goal**: Compare M365 state against corporate baselines and surface policy drift, customization, and compliance findings.

**Independent Test**: Baseline comparison returns per-domain compliance status, customizations, and severity-ranked findings.

### Tests for User Story 3

- [X] T050 [P] [US3] Contract test for baseline comparison output in `platform-governance/tests/contract/baseline.contract.test.js`
- [X] T051 [P] [US3] Integration test for M365 policy comparison in `platform-governance/tests/integration/m365-baseline.test.js`
- [X] T052 [P] [US3] End-to-end test for customization classification and reporting in `platform-governance/tests/e2e/customization-report.test.js`

### Implementation for User Story 3

- [X] T053 [P] [US3] Implement M365 baseline import service in `platform-governance/src/baseline/m365-baseline-importer.js`
- [X] T054 [P] [US3] Implement policy state collector for tenant controls in `platform-governance/src/baseline/policy-state-collector.js`
- [X] T055 [P] [US3] Implement baseline comparison engine by domain and control in `platform-governance/src/baseline/baseline-comparison-engine.js`
- [X] T056 [US3] Implement customization classification service with approval status in `platform-governance/src/baseline/customization-classifier.js`
- [X] T057 [P] [US3] Implement compliance finding generator with severity ranking in `platform-governance/src/baseline/compliance-finding-generator.js`
- [X] T058 [P] [US3] Implement compliance reporting API in `platform-governance/src/api/routes/compliance.js`
- [X] T059 [US3] Add evidence links from baseline findings to CMDB records in `platform-governance/src/baseline/baseline-evidence-linker.js`
- [X] T060 [P] [US3] Add storage tables/indexes for baselines, applied states, and findings in `platform-governance/db/migrations/003_baseline_tables.sql`

**Checkpoint**: User Story 3 should now be independently functional.

---

## Phase 6: User Story 4 - Modelo DSC para Segurança e Compliance Contínuos (Priority: P2)

**Goal**: Generate versioned DSC profiles from consolidated platform state and keep them updated within the 24h window.

**Independent Test**: A consolidated environment produces a versioned DSC profile, and a newer refresh preserves history and delta summary.

### Tests for User Story 4

- [X] T061 [P] [US4] Contract test for DSC profile schema validation in `platform-governance/tests/contract/dsc-profile.contract.test.js`
- [X] T062 [P] [US4] Integration test for DSC profile generation and versioning in `platform-governance/tests/integration/dsc-profile-generation.test.js`
- [X] T063 [P] [US4] End-to-end test for advisory Terraform validation in `platform-governance/tests/e2e/terraform-advisory.test.js`

### Implementation for User Story 4

- [X] T064 [P] [US4] Implement DSC profile composer from CMDB and baseline inputs in `platform-governance/src/dsc/dsc-profile-composer.js`
- [X] T065 [P] [US4] Implement DSC versioning and monotonic history checks in `platform-governance/src/dsc/dsc-version-service.js`
- [X] T066 [P] [US4] Implement desired-control rendering for security/compliance domains in `platform-governance/src/dsc/dsc-control-renderer.js`
- [X] T067 [US4] Implement advisory Terraform validation adapter in `platform-governance/src/governance/terraform-advisory-validator.js`
- [X] T068 [P] [US4] Implement advisory validation report API in `platform-governance/src/api/routes/terraform-validation.js`
- [X] T069 [P] [US4] Implement 24h refresh scheduler for CMDB and DSC in `platform-governance/src/scheduler/refresh-scheduler.js`
- [X] T070 [US4] Persist DSC profile versions and delta summaries in `platform-governance/db/migrations/004_dsc_profiles.sql`
- [X] T071 [P] [US4] Add freshness alerting for environments that miss the 24h refresh window in `platform-governance/src/observability/freshness-alerts.js`

**Checkpoint**: All user stories should now be independently functional.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories, release readiness, and operational hardening.

- [X] T072 [P] Add structured logging and correlation IDs across all modules in `platform-governance/src/shared/observability/`
- [X] T073 [P] Add security hardening for secret management and least privilege in `platform-governance/docs/SECURITY.md`
- [X] T074 [P] Add backup and restore runbook for CMDB and DSC data in `platform-governance/docs/RUNBOOK.md`
- [X] T075 [P] Add observability dashboards and alert thresholds in `platform-governance/ops/observability/dashboards/`
- [X] T076 [P] Add release and rollback guide for canary rollout in `platform-governance/docs/RELEASE.md`
- [X] T077 [P] Add example quickstart scenarios to match `quickstart.md` in `platform-governance/docs/QUICKSTART.md`
- [X] T078 [P] Add end-to-end smoke test covering auth → CMDB → baseline → DSC flow in `platform-governance/tests/e2e/smoke-test.test.js`
- [X] T079 [P] Add performance benchmark for 24h freshness window and query latency in `platform-governance/tests/performance/governance-benchmarks.test.js`
- [X] T080 [P] Update graph and impact artifacts after implementation in `specs/004-platform-cmdb-dsc-model/{graph.yaml,graph.md,impact-map.md}` (caminho corrigido em 2026-09-20; presença dos arquivos não comprova aprovação nem atualização do grafo de runtime)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - blocks all user stories
- **User Stories (Phases 3+)**: Depend on Foundational completion
- **Polish (Phase 7)**: Depends on target user stories being complete

### User Story Dependencies

- **US1 (P1)**: Can start after Foundational phase
- **US2 (P1)**: Can start after Foundational phase
- **US3 (P2)**: Can start after Foundational phase and consumes CMDB outputs
- **US4 (P2)**: Can start after Foundational phase and consumes CMDB + baseline outputs

### Within Each User Story

- Tests before implementation
- Shared models/utilities before services
- Services before API routes/CLI commands
- Integration before polish

### Parallel Opportunities

- Setup tasks marked [P] can run in parallel
- Foundational tasks marked [P] can run in parallel
- US1, US2, US3, and US4 can be assigned in parallel after foundation
- All test tasks in a story marked [P] can run in parallel
- Cross-cutting polish tasks marked [P] can run in parallel

---

## Parallel Example: User Story 2

```bash
# Discovery adapters can be built in parallel
Task: "Implement Azure discovery adapter in platform-governance/src/discovery/azure-discovery.js"
Task: "Implement AWS discovery adapter in platform-governance/src/discovery/aws-discovery.js"
Task: "Implement GCP discovery adapter in platform-governance/src/discovery/gcp-discovery.js"
Task: "Implement discovery orchestrator for parallel provider collection in platform-governance/src/domain/discovery-orchestrator.js"
```

---

## Implementation Strategy

### MVP First

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1
4. Validate SSO onboarding and auditable scope
5. Proceed to Phase 4 for CMDB consolidation

### Incremental Delivery

1. US1 establishes trusted entry and scope
2. US2 provides CMDB and discovery backbone
3. US3 adds baseline/compliance intelligence
4. US4 adds DSC versioning and advisory governance
5. Polish hardens observability, rollout, and operations

### Validation Strategy

- Each story has at least one contract/integration/e2e test
- Story completion is independent and demonstrable
- Advisory Terraform validation stays non-blocking in MVP
- Historical target: enforce and benchmark the 24h refresh window. The 2026-09-20 verification covers only freshness evaluation with fixtures; operational refresh and latency remain unverified.
