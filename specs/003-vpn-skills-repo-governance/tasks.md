# Implementation Tasks: VPN-SKILLS Repository — Central Governance & Lifecycle Management

**Feature**: VPN-SKILLS Repository — Central Governance & Lifecycle Management  
**Feature Branch**: `003-vpn-skills-repo-governance`  
**Complexity**: S3 (múltiplos módulos, integração entre serviços, governança crítica)  
**Created**: 2026-08-12

---

## Overview

This tasks.md outlines the implementation plan for the VPN-SKILLS feature, organized by phase and mapped to 4 user stories (P1–P3). All tasks follow the checklist format: `- [ ] [TaskID] [P?] [Story?] Description with file path`.

**Total Tasks**: 78 tasks across 7 phases  
**MVP Scope**: Phase 1 (Setup) + Phase 2 (Foundational) + Phase 3 (User Story P1 — Repository Initialization)  
**Extended Scope**: Phases 4–6 (User Stories P2.1, P2.2, P3)  
**Polish**: Phase 7 (Cross-Cutting Concerns)

---

## Phase 1: Setup & Repository Initialization

**Goal**: Bootstrap the VPN-SKILLS repository with governance artifacts, CI/CD pipelines, and Speckit integration.

**Independent Test Criteria**:
- Repository cloned successfully
- All governance files present (constitution.md, ADRs, .specify/ config)
- bootstrap.sh executable and validates dependencies
- GitHub Actions workflows trigger on push

### Phase 1 Tasks

- [ ] T001 Create VPN-SKILLS repository structure per architecture decision log in `vpn-skills/` root
- [ ] T002 [P] Create constitution.md with Nimbus-Code principles in `vpn-skills/docs/constitution.md`
- [ ] T003 [P] Create initial ADR-001 (Monorepo Strategy) in `vpn-skills/docs/adr/0001-monorepo-strategy.md`
- [ ] T004 [P] Create ADR-002 (API + CLI Design) in `vpn-skills/docs/adr/0002-api-cli-design.md`
- [ ] T005 [P] Create ADR-003 (Direct Release, No Feature Flags) in `vpn-skills/docs/adr/0003-release-strategy.md`
- [ ] T006 Initialize .specify/ directory with configuration files in `vpn-skills/.specify/config.yml`
- [ ] T007 [P] Create .github/workflows/ci.yml for linting, testing, and validation in `vpn-skills/.github/workflows/ci.yml`
- [ ] T008 [P] Create .github/workflows/release.yml for semantic versioning and release automation in `vpn-skills/.github/workflows/release.yml`
- [ ] T009 [P] Create .github/workflows/graph-guard.yml for module dependency validation in `vpn-skills/.github/workflows/graph-guard.yml`
- [ ] T010 Create bootstrap.sh script that installs Speckit CLI, Git hooks, and dependencies in `vpn-skills/bootstrap.sh`
- [ ] T011 [P] Create .gitignore with appropriate exclusions in `vpn-skills/.gitignore`
- [ ] T012 [P] Create LICENSE file (MIT) in `vpn-skills/LICENSE`
- [ ] T013 Create README.md with feature overview, quick start, and architecture summary in `vpn-skills/README.md`
- [ ] T014 [P] Create CONTRIBUTING.md with governance model and PR checklist in `vpn-skills/CONTRIBUTING.md`
- [ ] T015 Create CODE_OF_CONDUCT.md in `vpn-skills/CODE_OF_CONDUCT.md`

---

## Phase 2: Foundational Infrastructure & Contracts

**Goal**: Build foundational modules, data models, and API/CLI contracts that all user stories depend on.

**Independent Test Criteria**:
- Database schema deployed and validated
- API server starts and responds to health check
- CLI tool installs and --version returns expected output
- Skill manifest YAML schema validates against spec

### Phase 2 Tasks

- [ ] T016 Create vpn-skills-db module with PostgreSQL schema in `vpn-skills/src/database/schema.sql`
- [ ] T017 [P] Create Skill, SkillVersion, SkillDependency, SkillManifest, ComplianceReport table definitions in `vpn-skills/src/database/migrations/001-initial-schema.sql`
- [ ] T018 [P] Create database migration runner script in `vpn-skills/scripts/run-migrations.sh`
- [ ] T019 Create Redis cache configuration in `vpn-skills/config/redis.conf`
- [ ] T020 [P] Create Kafka queue configuration for async compliance scanning in `vpn-skills/config/kafka.conf`
- [ ] T021 Create data-model types/interfaces in TypeScript in `vpn-skills/src/types/skill.ts`
- [ ] T022 [P] Create SkillValidator utility class for entity validation in `vpn-skills/src/utils/skill-validator.ts`
- [ ] T023 [P] Create StateTransitionValidator for skill lifecycle state management in `vpn-skills/src/utils/state-transition-validator.ts`
- [ ] T024 Create DependencyResolver utility for transitive skill dependency resolution in `vpn-skills/src/utils/dependency-resolver.ts`
- [ ] T025 [P] Implement API contract from contracts/api-openapi.yaml — create Express.js app scaffold in `vpn-skills/src/api/server.ts`
- [ ] T026 [P] Create API middleware (auth, error handling, CORS, logging) in `vpn-skills/src/api/middleware/index.ts`
- [ ] T027 Create vpn-skills-api GET /health endpoint in `vpn-skills/src/api/routes/health.ts`
- [ ] T028 [P] Create CLI tool scaffold (Cobra-based Go CLI) in `vpn-skills/cmd/vpn-skills/main.go`
- [ ] T029 [P] Create CLI --version and --help commands in `vpn-skills/cmd/vpn-skills/commands/root.go`
- [ ] T030 Create skills-manifest-format.md validation schema in `vpn-skills/schemas/skills-manifest-v1.schema.json`
- [ ] T031 [P] Create manifest YAML parser and validator in `vpn-skills/src/utils/manifest-parser.ts`
- [ ] T032 [P] Create test suite for validation utilities in `vpn-skills/src/utils/__tests__/skill-validator.test.ts`
- [ ] T033 Create integration test setup (test database, fixtures) in `vpn-skills/tests/setup.ts`
- [ ] T034 [P] Create Docker Compose setup for local development in `vpn-skills/docker-compose.yml`
- [ ] T035 Create environment configuration (.env.example, .env.test) in `vpn-skills/.env.example`

---

## Phase 3: User Story P1 — Repository Initialization and Governance Setup

**User Story**: As a Platform Architect, I need to initialize the VPN-SKILLS repository with governance structure, CI/CD pipelines, and bootstrap tooling.

**Acceptance Scenarios**:
1. Clone repo → verify governance files present
2. Run bootstrap.sh → dependencies installed, environment validated
3. Push code → CI/CD workflows trigger, all checks pass
4. Run /nimbus-code-specify → feature directory created with pre-filled spec

**Parallel Opportunities**: T036–T039 (governance files), T040–T043 (CI/CD workflows), T044–T046 (bootstrap validation)

### Phase 3 Tasks: US1

- [ ] T036 [P] [US1] Create GOVERNANCE.md documenting skill review process, versioning policy, approval gates in `vpn-skills/docs/GOVERNANCE.md`
- [ ] T037 [P] [US1] Create SECURITY.md with vulnerability reporting, access controls, secrets management in `vpn-skills/docs/SECURITY.md`
- [ ] T038 [P] [US1] Create ARCHITECTURE.md with system overview, module descriptions, deployment topology in `vpn-skills/docs/ARCHITECTURE.md`
- [ ] T039 [P] [US1] Create skills.yaml template for repository index in `vpn-skills/skills.yaml.template`
- [ ] T040 [P] [US1] Implement CI workflow: lint Node.js/Go code, run unit tests in `vpn-skills/.github/workflows/ci.yml` (lines 20–60)
- [ ] T041 [P] [US1] Add security scanning (SAST, dependency scanning) to CI workflow in `vpn-skills/.github/workflows/ci.yml` (lines 61–85)
- [ ] T042 [P] [US1] Implement release workflow: semantic versioning, changelog generation, tag creation in `vpn-skills/.github/workflows/release.yml` (lines 30–80)
- [ ] T043 [P] [US1] Add graph-guard validation workflow (validates graph.yaml changes) in `vpn-skills/.github/workflows/graph-guard.yml`
- [ ] T044 [US1] Enhance bootstrap.sh: detect OS, install Speckit CLI, validate environment in `vpn-skills/bootstrap.sh` (full implementation)
- [ ] T045 [P] [US1] Create bootstrap validation tests in `vpn-skills/tests/bootstrap.test.sh`
- [ ] T046 [P] [US1] Add Speckit feature template integration to bootstrap.sh in `vpn-skills/bootstrap.sh` (lines 80–120)
- [ ] T047 [US1] Create skills-repo-bootstrap script to initialize new skill scaffolds in `vpn-skills/scripts/skill-scaffold.sh`
- [ ] T048 [P] [US1] Implement graph.yaml generation for repository modules in `vpn-skills/graph.yaml` (full structure)
- [ ] T049 [P] [US1] Create graph.md with Mermaid diagrams for module dependencies in `vpn-skills/graph.md`
- [ ] T050 [US1] Test end-to-end initialization: clone → bootstrap → verify all governance artifacts in `vpn-skills/tests/e2e/initialization.test.ts`

---

## Phase 4: User Story P2.1 — Centralized Skill Sourcing and Dynamic Reference

**User Story**: As a Project Bootstrap Template Maintainer, I need to reference VPN-SKILLS as remote skill source in templates.

**Acceptance Scenarios**:
1. Bootstrap template references VPN-SKILLS repository
2. Project discovers available skills via remote API/CLI
3. Skills validated before use (version constraints, prerequisites)
4. Skill updates automatically reflected in projects

**Parallel Opportunities**: T051–T053 (API endpoints), T054–T056 (CLI commands), T057–T059 (validators)

### Phase 4 Tasks: US2

- [ ] T051 [P] [US2] Implement API GET /skills endpoint (list all skills with filtering) in `vpn-skills/src/api/routes/skills.ts`
- [ ] T052 [P] [US2] Implement API GET /skills/{skillId} endpoint (fetch skill details) in `vpn-skills/src/api/routes/skills.ts` (lines 40–80)
- [ ] T053 [P] [US2] Implement API POST /skills/{skillId}/validate endpoint (validate compatibility) in `vpn-skills/src/api/routes/skills.ts` (lines 120–180)
- [ ] T054 [P] [US2] Implement CLI command `vpn-skills list` in `vpn-skills/cmd/vpn-skills/commands/list.go`
- [ ] T055 [P] [US2] Implement CLI command `vpn-skills show {skillId}` in `vpn-skills/cmd/vpn-skills/commands/show.go`
- [ ] T056 [P] [US2] Implement CLI command `vpn-skills validate [--file skills.yaml]` in `vpn-skills/cmd/vpn-skills/commands/validate.go`
- [ ] T057 [US2] Create CompatibilityValidator for version constraints and prerequisites in `vpn-skills/src/utils/compatibility-validator.ts`
- [ ] T058 [P] [US2] Implement version constraint resolver (semver ranges: ~2.1.0, ^2.1.0, >=2.0) in `vpn-skills/src/utils/semver-resolver.ts`
- [ ] T059 [P] [US2] Create PrerequisiteValidator to check skill-to-skill and external dependencies in `vpn-skills/src/utils/prerequisite-validator.ts`
- [ ] T060 [US2] Create SDK/client library for bootstrap templates to call VPN-SKILLS API in `vpn-skills/src/client/index.ts`
- [ ] T061 [P] [US2] Document VPN-SKILLS integration in bootstrap templates in `vpn-skills/docs/BOOTSTRAP_INTEGRATION.md`
- [ ] T062 [P] [US2] Create example bootstrap template referencing VPN-SKILLS in `vpn-skills/examples/bootstrap-template-example/` directory
- [ ] T063 [US2] Test API/CLI skill discovery and validation end-to-end in `vpn-skills/tests/e2e/skill-discovery.test.ts`
- [ ] T064 [P] [US2] Implement remote skill fetching (download from VPN-SKILLS, cache locally) in `vpn-skills/src/utils/remote-skill-fetcher.ts`

---

## Phase 5: User Story P2.2 — Skill Versioning, Release, and Lifecycle Management

**User Story**: As a VPN-SKILLS Repository Owner, I need to manage versioning, releases, and deprecation cycles.

**Acceptance Scenarios**:
1. Create new skill version → tag with semver, generate release notes
2. Deprecate skill → add notice, notify projects, mark as deprecated
3. Release cycle → scan for breaking changes, generate summary report
4. Project references deprecated skill → compliance warning generated

**Parallel Opportunities**: T065–T068 (release workflows), T069–T071 (deprecation), T072–T074 (compliance)

### Phase 5 Tasks: US3

- [ ] T065 [P] [US3] Implement skill versioning utility (parse semver, validate format) in `vpn-skills/src/utils/versioning.ts`
- [ ] T066 [P] [US3] Create release notes generator from commit history in `vpn-skills/src/utils/release-notes-generator.ts`
- [ ] T067 [P] [US3] Implement breaking change detector in `vpn-skills/src/utils/breaking-change-detector.ts`
- [ ] T068 [P] [US3] Create migration path generator for breaking changes in `vpn-skills/src/utils/migration-path-generator.ts`
- [ ] T069 [US3] Create deprecation workflow script in `vpn-skills/scripts/deprecate-skill.sh`
- [ ] T070 [P] [US3] Implement API endpoint POST /skills/{skillId}/deprecate (mark skill deprecated) in `vpn-skills/src/api/routes/deprecation.ts`
- [ ] T071 [P] [US3] Implement CLI command `vpn-skills deprecate {skillId} --target-date YYYY-MM-DD` in `vpn-skills/cmd/vpn-skills/commands/deprecate.go`
- [ ] T072 [US3] Create DeprecationNotifier to alert projects using deprecated skills in `vpn-skills/src/services/deprecation-notifier.ts`
- [ ] T073 [P] [US3] Implement version lifecycle state machine (draft → active → beta → deprecated → archived) in `vpn-skills/src/utils/version-lifecycle.ts`
- [ ] T074 [P] [US3] Create test suite for versioning and deprecation workflows in `vpn-skills/tests/versioning.test.ts`
- [ ] T075 [US3] Document skill release process in `vpn-skills/docs/SKILL_RELEASE_PROCESS.md`
- [ ] T076 [P] [US3] Test end-to-end release workflow: create version → tag → generate notes in `vpn-skills/tests/e2e/release-workflow.test.ts`

---

## Phase 6: User Story P3 — Cross-Project Skill Discovery and Consumption Dashboard

**User Story**: As a VPN Skills Consumer, I need to discover, filter, and explore available skills in a dashboard.

**Acceptance Scenarios**:
1. Navigate to dashboard → see searchable skill list grouped by category
2. Search/filter by keyword, status, prerequisites
3. Click skill → display details (version, requirements, examples)
4. Navigate links → access documentation and samples

**Parallel Opportunities**: T077–T078 (frontend components), T079–T080 (backend APIs)

### Phase 6 Tasks: US4

- [ ] T077 [P] [US4] Create React TypeScript project scaffold for dashboard in `vpn-skills/web/dashboard/` directory
- [ ] T078 [P] [US4] Implement SkillCard and SkillList React components in `vpn-skills/web/dashboard/src/components/SkillCard.tsx`
- [ ] T079 [US4] Create search and filter UI components in `vpn-skills/web/dashboard/src/components/SearchFilters.tsx`
- [ ] T080 [P] [US4] Implement SkillDetail page with versions, prerequisites, usage examples in `vpn-skills/web/dashboard/src/pages/SkillDetail.tsx`
- [ ] T081 [P] [US4] Create API GET /dashboard/summary endpoint (stats, top skills, recent updates) in `vpn-skills/src/api/routes/dashboard.ts`
- [ ] T082 [P] [US4] Implement dashboard frontend API client in `vpn-skills/web/dashboard/src/api/client.ts`
- [ ] T083 [US4] Create dashboard styling and theme in `vpn-skills/web/dashboard/src/styles/theme.css`
- [ ] T084 [P] [US4] Test dashboard UI components and integration tests in `vpn-skills/web/dashboard/src/__tests__/` directory
- [ ] T085 [US4] Deploy dashboard to staging environment and validate rendering in `vpn-skills/docs/DASHBOARD_DEPLOYMENT.md`

---

## Phase 7: Polish & Cross-Cutting Concerns

**Goal**: Implement observability, security, performance optimization, and documentation hardening.

**Independent Test Criteria**:
- Logs structured and queryable
- Metrics collection verified
- Security scanning passes
- Performance benchmarks meet SLO targets
- Documentation complete and links valid

### Phase 7 Tasks

- [ ] T086 Implement structured logging (JSON format) across all modules in `vpn-skills/src/utils/logger.ts`
- [ ] T087 [P] Create logging middleware for API server in `vpn-skills/src/api/middleware/logger.ts`
- [ ] T088 [P] Implement correlation-id/trace-id propagation in `vpn-skills/src/utils/tracing.ts`
- [ ] T089 [P] Create metrics collection (Prometheus format) in `vpn-skills/src/utils/metrics.ts`
- [ ] T090 Add Prometheus scrape endpoints for API and CLI tools in `vpn-skills/src/api/routes/metrics.ts`
- [ ] T091 [P] Create alerting rules (SLO violations) in `vpn-skills/config/alerting-rules.yaml`
- [ ] T092 [P] Implement API rate limiting middleware in `vpn-skills/src/api/middleware/rate-limiter.ts`
- [ ] T093 [P] Add request validation middleware (OpenAPI validation) in `vpn-skills/src/api/middleware/openapi-validator.ts`
- [ ] T094 Implement CORS configuration for dashboard access in `vpn-skills/src/api/middleware/cors.ts`
- [ ] T095 [P] Create authentication/authorization layer (optional for v1, placeholder) in `vpn-skills/src/api/middleware/auth.ts`
- [ ] T096 [P] Implement input sanitization and XSS prevention in `vpn-skills/src/api/middleware/sanitizer.ts`
- [ ] T097 Create comprehensive API documentation (OpenAPI HTML) in `vpn-skills/docs/API.md`
- [ ] T098 [P] Create CLI tool documentation and man pages in `vpn-skills/docs/CLI.md`
- [ ] T099 [P] Create troubleshooting guide in `vpn-skills/docs/TROUBLESHOOTING.md`
- [ ] T100 [P] Create deployment guide (Docker, Kubernetes) in `vpn-skills/docs/DEPLOYMENT.md`
- [ ] T101 Create runbook for common operations (backup, restore, scaling) in `vpn-skills/docs/RUNBOOK.md`
- [ ] T102 [P] Create example skill implementations in `vpn-skills/examples/skills/vpn-client-setup/` directory
- [ ] T103 [P] Add example skill documentation in `vpn-skills/examples/skills/vpn-client-setup/README.md`
- [ ] T104 [P] Implement compliance scanning utility (deprecated versions, incompatibilities) in `vpn-skills/src/utils/compliance-scanner.ts`
- [ ] T105 [P] Create compliance report generator and PDF export in `vpn-skills/src/utils/compliance-report-generator.ts`
- [ ] T106 Add compliance reporting API endpoint GET /projects/{projectId}/compliance in `vpn-skills/src/api/routes/compliance.ts`
- [ ] T107 [P] Implement Kafka consumer for async compliance scanning in `vpn-skills/src/services/compliance-worker.ts`
- [ ] T108 [P] Create performance benchmarks and SLO validation tests in `vpn-skills/tests/performance/benchmarks.test.ts`
- [ ] T109 [P] Add integration tests for API error scenarios and edge cases in `vpn-skills/tests/e2e/error-handling.test.ts`
- [ ] T110 Create setup guide for CI/CD integration (GitHub Actions, Jenkins, GitLab) in `vpn-skills/docs/CI_CD_INTEGRATION.md`
- [ ] T111 [P] Implement upgrade/migration path for existing projects in `vpn-skills/scripts/migrate-to-vpn-skills.sh`
- [ ] T112 [P] Create FAQ and known issues document in `vpn-skills/docs/FAQ.md`
- [ ] T113 Create impact-map.md finalization and SLO validation in `vpn-skills/impact-map.md` (reference from plan.md)

---

## Dependency Graph & Execution Order

```
Phase 1 (Setup) [T001–T015]
  ↓
Phase 2 (Foundational) [T016–T035]
  ↓
  ├─→ Phase 3 (US1 — Initialization) [T036–T050]
  │    ↓
  │    └─→ Phase 4 (US2.1 — Skill Sourcing) [T051–T064]
  │    ↓
  │    └─→ Phase 5 (US2.2 — Versioning) [T065–T076]
  │    ↓
  │    └─→ Phase 6 (US4 — Dashboard) [T077–T085]
  │
  └─→ Phase 7 (Polish) [T086–T113]
```

**Parallel Execution Examples**:
- **Phase 1**: All tasks except T006 (depends on T001–T005) can run in parallel (T002–T015)
- **Phase 2**: Modules can be developed in parallel: DB schema (T016–T020), types (T021–T024), API (T025–T027), CLI (T028–T029), validation (T030–T033)
- **Phase 4**: API endpoints (T051–T053) and CLI commands (T054–T056) can be implemented in parallel
- **Phase 7**: Observability (T086–T095), documentation (T097–T103), and compliance (T104–T107) can be parallelized

---

## MVP Scope (Recommended)

**Phase 1** (Setup) + **Phase 2** (Foundational) + **Phase 3** (User Story P1):
- ✅ Repository initialization with governance and CI/CD
- ✅ Database schema and data models
- ✅ API health endpoint
- ✅ CLI tool bootstrap
- ✅ End-to-end initialization test

**Estimated Effort**: ~40–50 tasks, ~2–3 weeks for a small team

---

## Extended Scope (v1 Full Feature)

**Phases 1–7** (all user stories):
- ✅ Repository initialization (P1)
- ✅ Centralized skill sourcing with API/CLI (P2.1)
- ✅ Versioning and lifecycle management (P2.2)
- ✅ Discovery dashboard (P3)
- ✅ Observability, security, documentation

**Estimated Effort**: ~110 tasks total, ~4–6 weeks for a team of 2–3

---

## Implementation Strategy

### Recommended Sequence:
1. **Start with Phase 1 + Phase 2** (weeks 1–2): Foundation, database, API/CLI scaffolds
2. **Parallel Phase 3 + Phase 4**: Governance + discovery (weeks 2–3)
3. **Phase 5 + Phase 6**: Versioning + dashboard (weeks 3–4)
4. **Phase 7**: Polish, documentation, observability (weeks 4–5)

### Testing Strategy:
- Unit tests for each utility/service (T032, T045, T074, T084)
- Integration tests per phase (T050, T063, T076, T085)
- End-to-end tests validating all user stories (T050, T063, T076)
- Performance benchmarks (T108)
- Security scanning in CI (T041)

### Release Strategy:
- **v0.1**: Phase 1 + Phase 2 (bootstrap and foundation)
- **v0.2**: Phase 3 (initialization governance)
- **v0.3**: Phase 4 + Phase 5 (discovery and versioning)
- **v1.0**: Phase 6 + Phase 7 (dashboard, full feature set)

---

## Checklist: Quality & Observability Gates (Nimbus-Code)

For each task that modifies or creates code files, validate:

- [ ] `graph.yaml` updated if modules added/changed
- [ ] `impact-map.md` updated for S3 concerns
- [ ] Test coverage for acceptance criteria (AC → test mapping)
- [ ] Feature flag strategy documented (or "N/A — direct release")
- [ ] SLO measured in staging environment
- [ ] Logs structured (JSON format) and correlation-id propagated
- [ ] Alerts configured for SLO violations
- [ ] No secrets hardcoded (uses env vars or secrets vault)
- [ ] All versions pinned (no `latest` tags)
- [ ] Least privilege permissions applied
- [ ] Health checks and readiness/liveness probes defined
- [ ] Multi-stage Docker builds used where applicable
- [ ] Bug issues opened for out-of-scope findings
- [ ] Reusable patterns added to `docs/reuse-catalog.yaml`
- [ ] Retro notes captured in `specs/003-vpn-skills-repo-governance/retro.md` if plan diverges

---

## Notes for Task Execution

1. **Each task is independently testable**: Do not assume tasks from other phases are complete
2. **Use file paths explicitly**: Every task references exact file locations for clarity
3. **Parallelization is encouraged**: Mark tasks with `[P]` where parallel execution is safe
4. **Acceptance criteria from spec.md** drive test creation; maintain traceability with `test_AC#_<desc>` naming
5. **After task completion**: Update graph.yaml and impact-map.md as modules/risks change
6. **Documentation**: Each phase should produce user-facing docs (README updates, deployment guides)
7. **Review & approval**: Each completed phase should pass code review before the next phase starts

---

## Extension Hooks (Post-Execution)

After this tasks.md is fully accepted, the following optional extension hook is available:

**Optional Hook**: `speckit-nimbus-code-backlog-sync`  
**Command**: `speckit.nimbus-code-backlog-sync.sync`  
**Description**: Synchronize generated tasks with JIRA/Azure DevOps backlog

To execute: `/speckit-nimbus-code-backlog-sync`

