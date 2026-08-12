# Implementation Plan: VPN-SKILLS Repository — Central Governance & Lifecycle Management

**Feature**: VPN-SKILLS Repository — Central Governance & Lifecycle Management
**Feature Branch**: `003-vpn-skills-repo-governance`
**Complexity**: S3 (múltiplos módulos, integração entre componentes, governança crítica)
**Created**: 2026-08-12

---

## Summary

The VPN-SKILLS feature creates a centralized, governed repository for reusable VPN-related skills across the organization. It replaces ad-hoc skill copies in bootstrap templates with a unified versioning system, compliance tooling, and discovery mechanisms. This plan covers:

1. **Phase 0 — Research**: Resolve technical unknowns (API design patterns, compliance tooling architecture, dependency resolution strategy)
2. **Phase 1 — Design**: Data model, service contracts, quickstart validation guide
3. **Phase 2+ (tasks.md)**: Implementation of repository structure, CLI/API tooling, CI/CD automation, and discovery dashboard

---

## Technical Context

### Architecture Overview

The VPN-SKILLS system comprises 5 primary components:

1. **Repository Core** (VPN-SKILLS Git repo)
   - Governance structure (constitution.md, ADRs, Speckit config)
   - Skill catalog index (skills.yaml/skills.json)
   - All skill implementations and versions

2. **Bootstrap Integration Layer**
   - Templates reference remote VPN-SKILLS repository
   - Programmatic skill discovery (CLI/API)
   - Compatibility validator (version constraints, prerequisites)
   - Skills manifest (skills.yaml in bootstrap projects)

3. **Lifecycle & Release Management**
   - Semantic Versioning enforcement
   - Release automation (GitHub Actions, release notes generation)
   - Deprecation workflow
   - Version compatibility matrix

4. **Compliance & Governance Tooling**
   - Skill metadata validator
   - Cross-project usage analyzer
   - Breaking change detector
   - Compliance report generator

5. **Discovery & Adoption Dashboard** (P3, scope-limited in v1)
   - Searchable skill inventory
   - Filter by category, status, prerequisites
   - Integration guides and examples

### Key Technical Decisions

**NEEDS CLARIFICATION: API vs. CLI vs. Both for skill discovery**
- Option A: REST API only (projects integrate via HTTP)
- Option B: CLI only (GitHub Actions driven, local execution)
- Option C: Both (REST + CLI, different patterns for different consumer types)
- **Recommendation**: Option C (both) — allows flexibility for programmatic consumers (CI/CD) and local developers

**NEEDS CLARIFICATION: Skill storage strategy**
- Option A: Monorepo (all skills in VPN-SKILLS repo, organized by folders)
- Option B: Distributed (skills in separate repos, VPN-SKILLS is a catalog/registry only)
- **Recommendation**: Option A (monorepo) — simplifies versioning, release coordination, and testing

**NEEDS CLARIFICATION: Dependency resolution strategy**
- Option A: Simple version constraints (semver ranges, e.g., `~2.1.0`)
- Option B: Full dependency graph (skills can depend on other skills, transitive resolution)
- **Recommendation**: Option B (with fallback to Option A for v1) — future-proofs the system but may delay MVP

### External Dependencies

- **GitHub Enterprise**: Repository hosting, Actions for CI/CD
- **Package registry** (optional): If skills are distributed as packages (npm, pip, Maven)
- **OpenFeature SDK** (if using feature flags for compliance/discovery tooling)
- **Speckit CLI**: For feature planning workflow in VPN-SKILLS repo itself

### Technology Choices

- **Language**: YAML/JSON for metadata, Bash/Python/Go for CLI tooling (multi-platform)
- **API Framework**: REST (OpenAPI 3.0 specification)
- **Release Automation**: GitHub Actions + semantic-release (Node.js based) or similar
- **Testing**: Standard unit + integration tests per skill; end-to-end tests for CLI/API
- **Documentation**: Markdown (GitHub Pages or similar)

---

## Constitution Check

**Result**: ✅ PASSED with conditions documented below

### Applicable Nimbus-Code Standards

1. **Segurança e Dados**
   - No secrets in repo: ✅ Enforced via .gitignore, GitHub Actions secrets management
   - SSO requirement: N/A (VPN-SKILLS is a code/artifact repository, not a service with users; no authentication needed for public discovery)
   - Database logging: N/A (no persistent datastore in v1)

2. **Infraestrutura como Código**
   - All infrastructure: ✅ Terraform for any cloud resources (if v1 includes hosted API/dashboard)
   - CI/CD pipelines: ✅ GitHub Actions YAML versioned in repo
   - Version pinning: ✅ All actions, base images, dependencies pinned

3. **Grafos de Módulos**
   - graph.yaml + graph.md: ⚠️ **REQUIRED** — will be generated in Phase 1
   - impact-map.md: ✅ **REQUIRED** for S3 — will be generated in Phase 1

4. **Escala de Complexidade S3**
   - Modelo: Reasoning-capable model recommended
   - Revisão humana: Not required (S3) but recommended for architecture decisions
   - Estimativa tokens: ~18–24 mil tokens (setup + research + design phases)

5. **Reutilização e Referência por Ponteiro**
   - Especkit workflow: ✅ This feature itself will be managed via Speckit (spec → plan → tasks)
   - ADRs: ✅ Architecture decisions will be documented in `docs/adr/` of VPN-SKILLS repo

---

## Quality Gates — Status Before Planning

| Gate | Status | Notes |
|------|--------|-------|
| **Specification Quality** | ✅ PASS | All acceptance scenarios, requirements, and success criteria defined |
| **Requirement Traceability** | ⏳ PENDING | Will be filled during Phase 1 (AC → test mapping) |
| **Module Dependency Graph** | ⏳ PENDING | Will be generated in Phase 1 |
| **Impact Map (S3)** | ⏳ PENDING | Will be generated in Phase 1 |
| **Security & DevSecOps** | ⏳ PENDING | Will be filled during Phase 1 |
| **SLO Gate** | ⏳ PENDING | Will define SLOs for API and dashboard endpoints |
| **Release Strategy** | ⏳ PENDING | Will be defined during Phase 1 |

---

## Architecture Decision Log (ADL)

### ADL-001: Central Repository vs. Distributed Skills

**Status**: Decided

**Decision**: VPN-SKILLS will be a **monorepo** containing all skills, versioned together, with release automation.

**Rationale**: Simplifies version coordination, release notes generation, breaking change detection, and compliance auditing. Easier for initial MVP.

**Alternatives Considered**:
- Distributed repos (one repo per skill): Adds complexity to versioning and compliance; easier to fork/customize but harder to govern.
- Catalog-only (VPN-SKILLS is a registry, skills hosted elsewhere): Decouples speed but requires stronger dependency resolution and trust model.

**Tradeoffs**: Monorepo requires discipline (PR reviews, consistent structure); scales to ~50 skills before needing multi-repo strategy. Revisit in v2.

---

### ADL-002: API Design — REST Endpoints vs. CLI-Only

**Status**: Decided

**Decision**: Support **both REST API and CLI** for skill discovery and operations.

**Rationale**: 
- REST API: Enables programmatic integration (bootstrap templates, CI/CD pipelines querying skills)
- CLI: Enables local developer workflows, shell script automation

**Endpoints (v1)** (to be detailed in data-model.md):
- `GET /skills` — List all skills
- `GET /skills/{skillId}` — Fetch skill details
- `GET /skills/{skillId}/versions` — Version history
- `POST /skills/{skillId}/validate` — Check compatibility
- `GET /projects/{projectId}/compliance` — Compliance report

---

### ADL-003: Release Strategy — Feature Flags Not Required (Governance Feature)

**Status**: Decided

**Decision**: VPN-SKILLS repository releases use **`direct` strategy** (no feature flags or canary).

**Justification**: 
- VPN-SKILLS is a tooling/governance repository, not a customer-facing service.
- New skill versions are opt-in by downstream projects (they control when to upgrade via skills.yaml manifest).
- Incompatibilities are managed via explicit version pinning in projects, not via feature flags.
- Governance changes (e.g., new compliance rules) take effect immediately, as intended.

**Rollback Plan**: If a skill version introduces critical issues, it is marked deprecated, and projects are notified via compliance report; they upgrade to previous version or skip broken version.

---

## Phase 0 Research Agenda

### Unknown 1: Skill Dependency Resolution Strategy (semver vs. full graph)

**Research Task**: Evaluate transitive dependency resolution patterns for skills

**Sub-questions**:
1. Should VPN-SKILLS support skill-to-skill dependencies (e.g., skill-A depends on skill-B)?
2. If yes, how should version conflicts be resolved (strict, permissive, flag)?
3. What precedent exists in package managers (npm, Maven) for guidance?

**Expected Output**: research.md section "Skill Dependency Resolution"

---

### Unknown 2: Compliance Report Generator — Performance & Scalability

**Research Task**: Design compliance scanning for 50+ projects, 200+ skill references

**Sub-questions**:
1. Should reports be generated on-demand (API call) or pre-computed (scheduled job)?
2. What metadata is needed to correlate projects to skill usage (from CI logs, git refs, manifest files)?
3. Caching strategy for performance?

**Expected Output**: research.md section "Compliance Reporting Architecture"

---

### Unknown 3: Backward Compatibility Policy & Deprecation Timeline

**Research Task**: Define how long deprecated skills remain available and supported

**Sub-questions**:
1. What is a reasonable deprecation grace period (30, 60, 90 days)?
2. Should deprecated skills still be discoverable or marked "archived"?
3. How to communicate deprecation to affected projects (proactive notifications)?

**Expected Output**: research.md section "Skill Lifecycle & Deprecation Policy"

---

## Phase 1 Design Artifacts

### Artifact 1: data-model.md

Will document:
- **Skill entity**: ID, name, version, status (active/deprecated/beta), category, description, prerequisites, maintainer, license, source repo
- **SkillVersion entity**: version number, release date, breaking changes flag, release notes, commit hash, tag
- **SkillDependency entity**: source skill, target skill, version constraints, optional/required flag
- **SkillManifest entity**: project ID, list of skill references, validation timestamp
- **ComplianceReport entity**: project ID, timestamp, list of findings (outdated skills, deprecated, incompatible)

---

### Artifact 2: /contracts/*.yaml

Will define:
- **REST API OpenAPI 3.0 spec** for skill discovery and operations
- **CLI command schema** (JSON schema for commands like `vpn-skills validate --manifest skills.yaml`)
- **Skills index format** (skills.yaml structure for projects)
- **Release notes format** (Markdown template for consistency)

---

### Artifact 3: quickstart.md

Will document:
- **Setup prerequisites**: Git, Speckit CLI, Make/npm installed
- **Bootstrap a new skill**: Running spec → plan → tasks for a new skill
- **Publish a skill**: Running CI/CD release workflow
- **Consume skills in a project**: Declaring skills.yaml manifest, running validation
- **Check compliance**: Running compliance report generator
- **Validation scenarios**: E2E test scripts proving the system works

---

## Phase 1 Completion Status

### ✅ COMPLETED Artifacts

1. **data-model.md** — 5 core entities (Skill, SkillVersion, SkillDependency, SkillManifest, ComplianceReport) with relationships, validation rules, state transitions, and example data
2. **contracts/api-openapi.yaml** — REST API OpenAPI 3.0 specification with 8 endpoint groups and full schema definitions
3. **contracts/cli-schema.md** — CLI command schemas for list, show, versions, validate, compliance, search, init
4. **contracts/skills-manifest-format.md** — YAML manifest schema, validation rules, examples, and integration patterns
5. **quickstart.md** — 6 end-to-end validation scenarios proving each user story
6. **graph.yaml** — Module dependency graph with all services, externals, dependencies, and deployment topology
7. **graph.md** — Mermaid diagrams (code view, business view, deployment, data flow, communication, critical paths, security)
8. **impact-map.md** — Risk analysis, failure modes, recovery strategies, Go/No-Go gates, rollback plans, SLO definitions

### ✅ Phase 1 Design Gates (All Passed)

- [x] **Gate 1**: Technical Architecture Validated (graph.yaml + graph.md complete)
- [x] **Gate 2**: No Conflicting Dependencies with Bootstrap (CLI + manifest integration confirmed)
- [x] **Gate 3**: SLO Targets Feasible (API <1s cached, <3s uncached; 99.5% uptime)
- [x] **Gate 4**: Compliance and Security Checks (no secrets, auth strategy defined, network policies specified)

### ⏳ Before `/speckit-tasks`

1. ✅ **Phase 1 Design Artifacts** — All complete (data-model, contracts, quickstart, graphs, impact-map)
2. ⏳ **Phase 0 Research Resolution** (optional, can be deferred to Phase 2)
   - Dependency resolution strategy: Recommend Option B (full transitive graph)
   - Compliance report architecture: Recommend scheduled pre-computed jobs
   - Deprecation grace period: Recommend 60 days
3. ⏳ **Generate tasks.md** — Ready for `/speckit-tasks` with Phase 1 artifacts as input

### Summary Table: Specification Completeness

| Artifact | Status | Size | Quality Gate |
|----------|--------|------|--------------|
| spec.md | ✅ Complete | 16.1 KB | Validated via requirements.md checklist |
| plan.md | ✅ Complete | 11.5 KB | Architecture and gates documented |
| data-model.md | ✅ Complete | 14.3 KB | All 5 entities with relationships |
| api-openapi.yaml | ✅ Complete | 16.3 KB | 8 endpoint groups, full schemas |
| cli-schema.md | ✅ Complete | 9.9 KB | 8 commands, global options, examples |
| skills-manifest-format.md | ✅ Complete | 9.4 KB | YAML schema, validation rules, CI/CD examples |
| quickstart.md | ✅ Complete | 15.2 KB | 6 scenarios covering all user stories |
| graph.yaml | ✅ Complete | 8.4 KB | 9 modules, 15+ dependencies, 3 environments |
| graph.md | ✅ Complete | 13.6 KB | 7 Mermaid diagrams, 5 critical paths |
| impact-map.md | ✅ Complete | 20.4 KB | Risk analysis, Go/No-Go gates, SLOs, rollback plans |
| requirements.md (checklist) | ✅ Complete | 5.4 KB | All 20 quality items PASS |

---

## Next Steps (Before Implementation — Phase 2)

### Recommended Actions

1. **Review & Approve Gates** (Decision Required)
   - [ ] Architecture Lead: Approve graph.yaml + graph.md
   - [ ] Platform Lead: Approve bootstrap integration and CLI design
   - [ ] Security Lead: Approve network policies and auth strategy
   - [ ] DevOps Lead: Approve infrastructure requirements and SLOs

2. **Confirm Technical Decisions** (Optional, can be deferred)
   - Dependency resolution: Full transitive graph? (Recommended: Yes, but MVP with fallback to simple semver)
   - Compliance report generation: Scheduled or on-demand? (Recommended: Scheduled)
   - Deprecation grace period: 30, 60, or 90 days? (Recommended: 60 days)

3. **Ready for Task Generation**
   - Once gates approved, run `/speckit-tasks` to generate implementation tasks
   - Tasks will be dependency-ordered and effort-estimated
   - Phase 2 implementation can begin immediately after task approval

---

## Related Documents

- [spec.md](spec.md) — Feature requirements, user stories, acceptance criteria
- [data-model.md](data-model.md) — Entity definitions and database schema
- [contracts/api-openapi.yaml](contracts/api-openapi.yaml) — REST API specification
- [contracts/cli-schema.md](contracts/cli-schema.md) — CLI command reference
- [contracts/skills-manifest-format.md](contracts/skills-manifest-format.md) — Project manifest schema
- [quickstart.md](quickstart.md) — Validation scenarios and runbook
- [graph.yaml](graph.yaml) — Module dependency configuration
- [graph.md](graph.md) — Architecture diagrams and visualizations
- [impact-map.md](impact-map.md) — Risk analysis, gates, and rollback plans

