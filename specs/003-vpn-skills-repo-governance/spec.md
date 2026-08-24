# Feature Specification: VPN-SKILLS Repository — Central Governance & Lifecycle Management

**Feature Branch**: `003-vpn-skills-repo-governance`

**Created**: 2026-08-12

**Status**: Draft

**Input**: User description: Creation and governance of the VPN-SKILLS repository by organization; centralized remote skills management (without project copies); rigorous CI/CD, versioning, and evolution cycle control; reference of this repository in code/platform templates; bootstrap initialization to support the SPECKIT workflow in this new repository.

> **Retrofit de contrato híbrido (2026-08-20)**: esta spec foi criada em 2026-08-12,
> antes de `specs/016-hybrid-agent-human-dev/` tornar obrigatório o cabeçalho
> Nimbus-Code, os critérios de aceitação em formato `AC-N` (BDD) e o bloco de
> Cost Reference. Os blocos abaixo foram retrofitados durante a revisão de
> convergência/replanejamento desta feature — ver `plan.md`, seção "Known Gaps",
> item 2 (agora resolvido).

## Nimbus-Code — Cabeçalho Obrigatório da Spec

| Campo | Valor |
|---|---|
| **Feature slug** | `vpn-skills-repo-governance` |
| **Complexidade estimada** | S3 |
| **Bounded Context** | Developer Experience & Governance (skill distribution) |
| **PR de referência / Issue** | novo |
| **Data alvo de entrega** | sem data |

> S0 = doc · S1 = função isolada · S2 = módulo · S3 = múltiplos módulos ·
> S4 = arquitetura, segurança, dados ou integração crítica

## Nimbus-Code — SLO Alvo desta Feature

| Componente | Latência p99 (ms) | Taxa de erro máx. (%) | Disponibilidade alvo | RTO | RPO |
|---|---|---|---|---|---|
| API de descoberta de skills (`GET /skills`, cacheado) | 1000 | 1,0% | 99,5% | 30 min | 24 h |
| API de descoberta de skills (não cacheado) | 3000 | 1,0% | 99,5% | 30 min | 24 h |
| Compliance report generator (10+ projetos) | 60000 | 2,0% | 99,0% | 1 h | 24 h |

> Valores herdados de `impact-map.md` (Gate 3 — SLO Targets Feasible), já
> aprovados na Phase 1 desta feature.

## Nimbus-Code — Critérios de Aceitação (formato BDD)

*Os critérios abaixo formalizam, em BDD, os cenários de aceitação mais críticos
já detalhados nos Acceptance Scenarios de cada User Story abaixo — não
duplicam o conteúdo, apenas o tornam rastreável por ID único.*

> **AC-1**
> **Given** o repositório VPN-SKILLS inicializado com o template padrão
> **When** o workflow de inicialização rodar
> **Then** `constitution.md`, pasta `ADR/` com ao menos um ADR fundacional, `.specify/` configurado e `.github/workflows/` com CI/CD existem
> **Test ref:** `test_AC1_repo_governance_scaffold` (US1)

> **AC-2**
> **Given** um bootstrap template referenciando o VPN-SKILLS remotamente
> **When** o processo de bootstrap rodar num projeto novo
> **Then** a ferramenta de descoberta consegue listar skills disponíveis, versões, prerequisites e timestamp de última atualização, sem copiar arquivos localmente
> **Test ref:** `test_AC2_remote_skill_discovery_no_copy` (US2)

> **AC-3**
> **Given** uma nova versão de skill publicada com breaking change
> **When** o workflow de release rodar
> **Then** uma tag semver é criada, release notes são geradas automaticamente, e projetos pinados na versão anterior continuam funcionando sem alteração
> **Test ref:** `test_AC3_semver_release_backward_compat` (US3)

> **AC-4**
> **Given** uma automação (API, CLI ou compliance report generator) precisando acessar repositórios/organização no GitHub
> **When** a automação executar
> **Then** ela autentica via token de instalação do GitHub App organizacional (server-to-server) ou via OAuth do mesmo App (login humano no dashboard) — nunca via PAT clássico
> **Test ref:** `test_AC4_github_app_auth` (ADL-004, ver plan.md)

## Nimbus-Code — Cost Reference

| Campo | Valor |
|---|---|
| **Estimativa de tokens (agente)** | ~18–24 mil (Phase 0+1, já consumidos) — ver `plan.md`, seção "Escala de Complexidade S3" |
| **Estimativa de horas (humano)** | A definir em `tasks.md` por task, seguindo `docs/cost-profiles-and-rates.md` |
| **Metodologia de rastreio** | `docs/ai-code-quality-and-observability.md`, seção 6 (estimativa vs. consumo real) |

> Nota: uma versão anterior deste retrofit referenciava um "SPEC KIT COST"
> como projeto GitHub público externo — essa referência foi identificada como
> incorreta (repositório não pertence à organização) e removida do padrão em
> 2026-08-20 (ver `scripts/normalize-github-issues.sh` e
> `.github/ISSUE_TEMPLATE/nimbus-code-task.md`). O rastreio de custo desta
> feature usa exclusivamente os mecanismos internos acima.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Repository Initialization and Governance Setup (Priority: P1)

As a **Platform Architect / DevOps Lead**, I need to **initialize the VPN-SKILLS repository** with proper governance structure, CI/CD pipelines, and bootstrap tooling so that **the repository becomes the single source of truth for all VPN-related skills** across the organization.

**Why this priority**: P1 is the foundation — without proper repository initialization, governance, and automation, downstream adoption by projects and skill evolution management is impossible. This directly enables all other stories.

**Independent Test**: Can be fully tested by: (1) cloning the initialized repository, (2) verifying all governance files (constitution.md, ADRs, policy files) are present and valid, (3) confirming CI/CD pipelines trigger correctly on push, (4) running bootstrap.sh and confirming spec-kit environment is ready for feature planning.

**Acceptance Scenarios**:

1. **Given** the VPN-SKILLS repository is created with default template, **When** the initialization workflow runs, **Then** the following governance artifacts exist: `constitution.md`, `ADR/` folder with at least one foundational ADR, `.specify/` directory with extensions and templates configured, and `.github/workflows/` with CI/CD pipelines.

2. **Given** a new user clones the VPN-SKILLS repository, **When** they execute `./bootstrap.sh`, **Then** all dependencies (Speckit CLI, Git hooks, tooling) are installed, the environment is validated, and a confirmation message is displayed with next steps.

3. **Given** a developer pushes code to the repository, **When** the GitHub Actions CI workflow runs, **Then** all checks pass: linting, tests, security scans, and graph validation (if applicable).

4. **Given** the repository is initialized, **When** a developer runs `/nimbus-code-specify` to create a new skill spec, **Then** the feature directory is created with the correct naming convention (NNNN-slug) and a pre-filled spec.md based on the project template.

---

### User Story 2 — Centralized Skill Sourcing and Dynamic Reference (Priority: P2)

As a **Project Bootstrap Template Maintainer**, I need to **reference VPN-SKILLS as a remote skill source** in code/platform templates so that **new projects can discover, validate, and reference VPN skills without copying them locally**.

**Why this priority**: P2 enables the core value proposition — projects don't maintain local copies of skills. Instead, they dynamically reference the remote repository, reducing duplication and ensuring consistency. This is critical for adoption but depends on P1 (repository foundation).

**Independent Test**: Can be fully tested by: (1) creating a bootstrap template that references the VPN-SKILLS repository, (2) verifying a project can discover available skills via remote API/CLI, (3) confirming projects can validate skill compatibility (versioning, prerequisites) before using them, (4) testing that skill updates in VPN-SKILLS are automatically reflected in projects (without re-copying).

**Acceptance Scenarios**:

1. **Given** a bootstrap template includes a reference to the VPN-SKILLS repository, **When** the bootstrap process runs in a new project, **Then** the project's skill-discovery tool can query VPN-SKILLS, list available skills, and display their versions, prerequisites, and last-updated timestamp.

2. **Given** a project wants to use a specific VPN skill (e.g., version 2.1.0), **When** the project's build/initialization process runs, **Then** the system fetches the skill from the remote VPN-SKILLS repository, validates compatibility (version constraints, prerequisites), and either confirms readiness or raises a compatibility error with remediation steps.

3. **Given** a skill in VPN-SKILLS is updated to a new version (e.g., 2.2.0 with a breaking change), **When** projects run their dependency validation, **Then** projects pinned to version 2.1.0 continue to work unchanged, and only projects explicitly configured to track `latest` or a version range are notified of the update.

4. **Given** a developer needs to know which projects are using a specific VPN skill, **When** they query the VPN-SKILLS governance tooling, **Then** a report is generated listing all projects, their pinned versions, and when they last validated compatibility.

---

### User Story 3 — Skill Versioning, Release, and Lifecycle Management (Priority: P2)

As a **VPN-SKILLS Repository Owner**, I need to **manage skill versioning, releases, and deprecation cycles** so that **skills evolve in a controlled manner** and downstream projects can plan upgrades.

**Why this priority**: P2 because lifecycle management is essential to the governance model, but it's not required for the initial repository to function. Without it, however, coordination and breaking changes become chaos.

**Independent Test**: Can be fully tested by: (1) creating a new skill version, (2) tagging it with a semantic version, (3) running release workflow, (4) generating release notes automatically, (5) verifying that deprecation notices are propagated to projects, and (6) confirming that old versions remain available but marked as unsupported.

**Acceptance Scenarios**:

1. **Given** a skill has been updated and tested, **When** the release workflow runs (manual trigger or automated via semver tag), **Then** a new version tag is created (e.g., v2.2.0), release notes are generated from commit history, the skill is marked as "current" in the repository index, and prior version is marked as "supported".

2. **Given** a skill is being deprecated, **When** the deprecation workflow runs with a target removal date, **Then** a deprecation notice is added to the skill's documentation, affected projects are notified via a compliance report, and the skill remains available but marked as "deprecated" for a grace period.

3. **Given** the VPN-SKILLS repository is configured with a release schedule, **When** a release cycle begins, **Then** all skills are scanned for breaking changes, and a summary report is generated listing: new versions, deprecations, breaking changes, and migration paths.

4. **Given** a project references a deprecated skill, **When** the project runs its compliance check, **Then** a warning is displayed with: deprecation date, migration path, and available alternative skills (if any).

---

### User Story 4 — Cross-Project Skill Discovery and Consumption Dashboard (Priority: P3)

As a **VPN Skills Consumer (Platform Team)**, I need to **discover, filter, and explore available VPN skills** in a centralized dashboard so that **I can quickly find the right skill for my use case and understand its requirements**.

**Why this priority**: P3 because while valuable for usability, this is not blocking — skills can be discovered via documentation and CLI. However, it significantly improves adoption and reduces support burden.

**Independent Test**: Can be fully tested by: (1) building a dashboard UI/API that queries VPN-SKILLS metadata, (2) filtering skills by category/tag, (3) searching by keyword, (4) displaying skill details (version, prerequisites, usage examples, license), and (5) confirming navigation links to documentation and usage samples work.

**Acceptance Scenarios**:

1. **Given** the VPN-SKILLS discovery dashboard is deployed, **When** a user navigates to it, **Then** they see a searchable list of all available skills, grouped by category, with filtering options by version, status (deprecated/supported/beta), and prerequisites.

2. **Given** a user searches for a skill (e.g., "Authentication"), **When** the search completes, **Then** matching skills are displayed with: name, description, current version, supported platforms, and a link to the full documentation.

3. **Given** a user clicks on a skill, **When** the detail view loads, **Then** they see: usage examples, integration steps, version history, known issues, and a "copy to clipboard" option for the dependency declaration.

4. **Given** a user wants to integrate a skill, **When** they click "Get Started", **Then** they are guided through a step-by-step integration checklist with links to the appropriate bootstrap template and validation commands.

---

### Edge Cases

- What happens if a skill has a hard dependency on a platform-specific tool (e.g., Windows PowerShell) and a project runs on Linux? **Expected behavior**: The skill discovery tool flags this incompatibility and suggests alternative skills.

- How does the system handle a skill that references another skill that has been deprecated? **Expected behavior**: Transitive dependency validation flags the issue and requires explicit override or migration.

- What happens if two versions of the same skill are pinned in different projects, and one has a critical security vulnerability? **Expected behavior**: The governance tooling generates an impact report showing which projects are affected, and initiates an escalation workflow.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: VPN-SKILLS repository MUST be initialized with a complete governance structure including `constitution.md` (project-specific principles and policies), Architecture Decision Log (ADR folder), and Speckit configuration files (`.specify/`, templates, extensions).

- **FR-002**: The repository MUST include a working bootstrap script (`bootstrap.sh`) that installs all required dependencies (Speckit CLI, Git hooks, linters, testing frameworks) and validates the development environment.

- **FR-003**: The repository MUST have automated CI/CD pipelines (GitHub Actions or equivalent) that validate: linting, unit tests, security scans (SAST/dependency checks), and spec/graph integrity on every push.

- **FR-004**: The repository MUST expose skill metadata via a structured API/CLI interface so that external projects can query: skill name, version, status (supported/deprecated/beta), prerequisites, and last-updated timestamp.

- **FR-005**: Each skill in VPN-SKILLS MUST be versioned using Semantic Versioning (MAJOR.MINOR.PATCH) and tagged in Git; release notes MUST be generated automatically from commit history.

- **FR-006**: The repository MUST maintain a skill index/catalog (YAML or JSON) that lists all available skills with: name, current version, supported versions (backward compatibility), deprecation status, and linked documentation.

- **FR-007**: The repository MUST include a compliance/governance report generator that scans all pinned skill references in external projects and produces: version status (current/supported/deprecated), breaking change alerts, and recommended upgrade paths.

- **FR-008**: The repository MUST support feature planning via Speckit (`/nimbus-code-specify`, `/nimbus-code-plan`, `/nimbus-code-tasks`) — all new skill features must follow this workflow and produce a spec, plan, and task list.

- **FR-009**: Bootstrap templates that reference VPN-SKILLS MUST include: automated skill discovery, compatibility validation against project requirements, and a declarative skills manifest (e.g., `skills.yaml`).

- **FR-010**: The repository MUST include documentation: README (quick start), CONTRIBUTING (development workflow), ADR/index.md (architecture decisions), and FAQ/troubleshooting guide.

### Key Entities

- **Skill**: A reusable, versioned component (code, configuration, or documentation bundle) that solves a specific domain problem (e.g., VPN setup, security hardening, compliance validation). Attributes: name, version, status, prerequisites, category, documentation link, release date.

- **Skill Version**: A tagged release of a skill with Semantic Versioning. Attributes: version number, release date, breaking changes flag, deprecation status, supported-until date (if applicable), migration path (if breaking).

- **Skill Dependency**: A relationship between a skill and a prerequisite (another skill, tool, platform, or configuration). Attributes: dependency type (hard/soft), version constraints, error message if unsatisfied.

- **Governance Policy**: A rule or standard that all skills in VPN-SKILLS must follow (e.g., "all skills must include tests", "all breaking changes must be documented in migration guide"). Attributes: policy ID, description, enforcement method (automated check or manual review).

- **Skill Manifest**: A declarative file (e.g., `skills.yaml` in a bootstrap template or project) that specifies which skills a project depends on and at what versions. Attributes: list of skill references, version constraints, platform/environment filters.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Repository is initialized and publicly accessible with complete governance documentation; developers can clone, bootstrap, and run CI/CD checks in under 5 minutes.

- **SC-002**: At least 3 foundational skills are published in VPN-SKILLS with full documentation, version tags, and release notes by the end of the feature's initial release.

- **SC-003**: Bootstrap templates can discover and validate VPN-SKILLS skills programmatically; skill compatibility checks complete in under 10 seconds per skill.

- **SC-004**: Compliance report generator can scan and report on skill usage across 10+ downstream projects in under 1 minute.

- **SC-005**: 100% of new skill additions follow Speckit workflow (spec → plan → tasks) and produce validated specs, plans, and task lists before merge.

- **SC-006**: Deprecation and lifecycle management processes are documented and tested; at least one skill is successfully deprecated and projects are notified without errors.

- **SC-007**: All CI/CD pipelines pass consistently; security scans detect no critical vulnerabilities; test coverage is at minimum 70% for any code changes.

- **SC-008**: Team adoption: At least 50% of downstream projects reference VPN-SKILLS within 6 months of launch; support tickets related to skill setup decrease by 40%.

---

## Assumptions

- **Assumption 1**: The organization has an existing GitHub Enterprise or Azure DevOps environment where the VPN-SKILLS repository can be created and managed.

- **Assumption 2**: Downstream projects will be willing to adopt remote skill references and update their bootstrap templates to support centralized versioning.

- **Assumption 3**: The Speckit CLI and all required tooling (Git hooks, linters, testing frameworks) are already available in the development environment or can be easily installed via package managers.

- **Assumption 4**: Breaking changes in skills are acceptable if they follow a clear deprecation policy and provide migration paths; projects will be expected to upgrade within a grace period.

- **Assumption 5**: The VPN-SKILLS repository will be the sole source of truth for VPN-related skills; projects must not maintain local skill copies (this is a governance policy, not a technical requirement).

- **Assumption 6**: Skill metadata (versions, status, dependencies) can be automatically extracted from Git tags, release notes, and a centralized index file; no manual catalog maintenance is required beyond curating the initial index.

- **Assumption 7**: Compliance and discovery tooling can be built using standard APIs (GitHub API, REST endpoints, or CLI) without requiring deep integrations into project build systems (v1 scope).

- **Assumption 8**: Mobile/frontend-specific skills are out of scope for the initial VPN-SKILLS repository — focus is on infrastructure, security, and DevOps-related skills.
