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

- **GitHub Enterprise** (`venha-pra-nuvem.ghe.com`): Repository hosting, Actions para CI/CD —
  **exclusivamente** este domínio para todo conteúdo próprio da Venha Pra Nuvem; nenhuma URL
  `github.com` público é aceitável aqui (ver `specs/006-bootstrap-governance-hardening/`, FR-007).
- **GitHub App organizacional** (`venha-pra-nuvem`): identidade de autenticação única para
  automações server-to-server e login humano no dashboard — ver ADL-004. Substitui qualquer
  necessidade de PAT clássico ou esquemas de auth ad-hoc por integração.
- **Spec Kit CLI**: única exceção deliberada à regra acima — obtido sempre da fonte oficial
  pública do GitHub (`github.com/github/spec-kit`), por ser a ferramenta open source mantida
  publicamente pelo GitHub (ver `specs/006-bootstrap-governance-hardening/`, FR-006).
- **Package registry** (optional): If skills are distributed as packages (npm, pip, Maven)
- **OpenFeature SDK** (if using feature flags for compliance/discovery tooling)

### Technology Choices

- **Language**: YAML/JSON for metadata, Bash/Python/Go for CLI tooling (multi-platform)
- **API Framework**: REST (OpenAPI 3.0 specification) com autenticação via GitHub App (ADL-004)
- **Release Automation**: GitHub Actions + semantic-release (Node.js based) or similar
- **Testing**: Standard unit + integration tests per skill; end-to-end tests for CLI/API
- **Documentation**: Markdown (GitHub Pages, hospedado dentro do GHE da organização)

---

## Constitution Check

**Result**: ✅ PASSED with conditions documented below

### Applicable Nimbus-Code Standards

1. **Segurança e Dados**
   - No secrets in repo: ✅ Enforced via .gitignore, GitHub Actions secrets management
   - SSO requirement: ✅ Não se aplica SSO tradicional (não é um sistema com login/senha próprio), mas o
     dashboard de descoberta E a API têm, sim, autenticação — via GitHub App organizacional (user-to-server
     OAuth para humanos, installation token para automações). A afirmação anterior ("no authentication
     needed") estava incorreta e foi corrigida — ver ADL-004.
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

## Quality Gates — Status (atualizado após revisão de convergência com specs/006)

> **Nota de revisão (2026-08-20)**: esta tabela estava desatualizada — dizia "PENDING" para
> itens que a seção "Phase 1 Completion Status" (mais abaixo, já existente) mostra como
> completos desde a fase de design. Corrigida abaixo para refletir o estado real, e revisada
> contra as decisões de `specs/006-bootstrap-governance-hardening/` (GitHub App, domínio GHE).

| Gate | Status | Notes |
|------|--------|-------|
| **Specification Quality** | ✅ PASS | All acceptance scenarios, requirements, and success criteria defined |
| **Requirement Traceability** | ✅ PASS | AC → test mapping presente em `quickstart.md` |
| **Module Dependency Graph** | ✅ PASS | `graph.yaml` + `graph.md` completos; edges de autenticação unificados sob GitHub App (ADL-004) |
| **Impact Map (S3)** | ✅ PASS | `impact-map.md` completo; itens de auth reconciliados com ADL-004 |
| **Security & DevSecOps** | ✅ PASS (com ressalva) | Estratégia de auth unificada via ADL-004; **pendente**: alinhar `spec.md`/`tasks.md` desta feature ao contrato híbrido obrigatório introduzido por `specs/005-hybrid-agent-human-dev/` (cabeçalho Nimbus-Code, AC-N formal, tabela de SLO, Cost Reference) — ver "Known Gaps" abaixo |
| **SLO Gate** | ✅ PASS | SLOs definidos em `impact-map.md` (API <1s cached, <3s uncached; 99.5% uptime) |
| **Release Strategy** | ✅ PASS | ADL-003 (`direct` strategy, sem feature flag) |

---

## Architecture Decision Log (ADL)

### ADL-001: Central Repository vs. Distributed Skills

**Status**: Decided — **Executado em 2026-08-20**

**Execução**: Repositório próprio criado em
**[venha-pra-nuvem/vpn-skills](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/vpn-skills)**
(privado, branch `main` protegida — PR obrigatório + 1 revisão). Histórico do
subdiretório `vpn-skills/` (implementação completa das 113 tasks) extraído via
`git subtree split -P vpn-skills` a partir da branch `copilot/controle-de-custos`
e publicado como `main` do novo repositório, preservando o commit original.
Labels (taxonomia Nimbus-Code) e GitHub Project V2 aplicados via
`scripts/setup-github-labels.sh`/`scripts/setup-github-project.sh` deste
template. Bounded context registrado em `docs/bounded-contexts.yaml`
(slug `vpn-skills`). Ver `tasks.md` desta feature para o pointer de status
completo — não duplicado aqui.

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

### ADL-004: Authentication Strategy — GitHub App (organizacional) em vez de PAT ou esquemas ad-hoc

**Status**: Decided (2026-08-20, revisão de convergência)

**Contexto**: A versão anterior deste plano deixava a estratégia de autenticação indefinida e
inconsistente — o Gate 4 afirmava "auth strategy defined", mas `graph.yaml` misturava 5
mecanismos diferentes (`github-token`, `api-key`, `git-token`, `webhook-token`, `oauth2`) sem
critério único, `contracts/api-openapi.yaml` declarava um `bearerAuth`/JWT genérico não
relacionado a nenhum deles, e `tasks.md` (T095) tratava a camada de auth como "optional for
v1, placeholder". Nenhum desses artefatos referenciava PAT nem GitHub App explicitamente de
forma coerente.

**Decision**: Toda comunicação que envolva acesso a repositórios/organização no GitHub
(API → Repositório, CLI → Repositório, login humano no dashboard de descoberta) usa um único
**GitHub App instalado a nível de organização** (`venha-pra-nuvem`):
- **Automações server-to-server** (API, CLI, compliance report generator lendo/escrevendo em
  repositórios ou fazendo scanning cross-repo): token de instalação de curta duração, emitido
  dinamicamente por execução — nunca um PAT clássico de longa duração vinculado a uma pessoa.
- **Login humano no dashboard de descoberta**: fluxo user-to-server OAuth do mesmo GitHub App
  (não é um provider OAuth genérico de terceiros).
- **Chamadas puramente internas ao próprio serviço VPN-SKILLS** (ex.: CLI → API do próprio
  VPN-SKILLS): permanecem com API key de serviço — esse tráfego não é acesso a GitHub e,
  portanto, está fora do escopo desta política (mas continua exigindo segredo em cofre, nunca
  hardcoded).

**Rationale**: Alinha esta feature com a política definida em
`specs/006-bootstrap-governance-hardening/spec.md` (FR-004/FR-005/AC-4/AC-5), decidida com o
Dev para eliminar PAT clássico de qualquer automação de escopo organizacional/cross-repo em
toda a Nimbus-Code — VPN-SKILLS é exatamente esse tipo de automação (o compliance report
generator precisa ler manifestos e status de 10+ projetos em repositórios distintos).

**Alternatives Considered**:
- PAT clássico dedicado ao serviço: rejeitado — vinculado a uma identidade, sem expiração,
  sem escopo fino; era o problema original que motivou a spec 006.
- Fine-grained PAT de conta de serviço: mais seguro que PAT clássico, mas ainda é uma
  identidade "humana/bot" com rotação manual — GitHub App resolve isso de forma superior
  (rotação automática do token de instalação, escopo por repositório/permissão).
- Esquemas ad-hoc por integração (a situação anterior — `github-token`, `git-token`,
  `webhook-token`, `oauth2` misturados): rejeitado — gera superfície de auditoria fragmentada
  e nenhuma garantia de consistência entre os componentes do próprio VPN-SKILLS.

**Implications**:
- `graph.yaml`: edges `vpn-skills-api → vpn-skills-repo-core`,
  `vpn-skills-cli → vpn-skills-repo-core` e `vpn-skills-discovery-dashboard → vpn-skills-api`
  atualizados para `github-app-installation-token` / `github-app-user-oauth` respectivamente.
- `contracts/api-openapi.yaml`: security scheme substituído de `bearerAuth` (JWT genérico) por
  `githubAppInstallationToken` (server-to-server) e `githubAppUserOAuth` (dashboard).
- `impact-map.md`: critérios de Gate 4 e checklist de produção atualizados para citar
  explicitamente GitHub App em vez de "API keys or OAuth" genéricos.
- `tasks.md` (T095 e correlatas): precisam ser revisadas numa próxima passagem de
  `/speckit-tasks` ou `/speckit-converge` para deixar de tratar a camada de auth como
  "optional/placeholder" — está definida e é obrigatória.

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

3. **`tasks.md` Already Generated — Ready for Implementation**
   - `tasks.md` already exists (113 original tasks + 3 convergence tasks T114–T116, T115/T116 now resolved)
   - Once gates approved, run `/speckit-implement` to begin Phase 2 implementation
   - T114 (GitHub App auth middleware) should be prioritized early given ADL-004

---

## Known Gaps (registrados na revisão de convergência de 2026-08-20, atualizados no replanejamento de 2026-08-20)

*Esta seção documenta lacunas identificadas ao comparar este plano com as decisões de
`specs/008-bootstrap-governance-hardening/` (renumerada de `006` após colisão com
`specs/006-multirepo-support`, publicada por outra sessão — ver nota de renumeração
naquela spec). As correções de URL (GHE) e de estratégia de autenticação (ADL-004)
já foram aplicadas na primeira revisão. Status atualizado abaixo:*

1. **`tasks.md` já existe mas não reflete o ADL-004** — **ainda em aberto**: um
   `tasks.md` foi gerado anteriormente (113 tasks) antes da aprovação formal dos
   gates recomendada na seção "Next Steps" acima. A task T095 trata a camada de
   autenticação como "optional for v1, placeholder" — isso está desatualizado; a
   autenticação via GitHub App é obrigatória e definida (ADL-004). **Já existe uma
   task de convergência (T114, `## Phase 8: Convergence` em `tasks.md`) cobrindo
   exatamente esta substituição** — não requer nova ação de planejamento, apenas
   `/speckit-implement` executar T114 quando a fase de implementação começar.
2. **Contrato híbrido obrigatório (feature 005) não aplicado a esta spec** — **✅
   RESOLVIDO nesta revisão (2026-08-20)**: `spec.md` foi retrofitado com o
   cabeçalho Nimbus-Code (slug/complexidade/bounded context), tabela de SLO,
   critérios de aceitação em formato `AC-N` (4 ACs formalizando os cenários mais
   críticos já existentes nas User Stories) e bloco de Cost Reference. A task
   T115 (`## Phase 8: Convergence`) que pedia esse retrofit pode ser marcada
   como concluída em `tasks.md`. **Nota**: o retrofit do Cost Reference
   deliberadamente **não** reintroduziu a URL externa "SPEC KIT COST" — essa
   referência foi identificada como incorreta (repositório não pertence à
   organização) e removida do padrão da Nimbus-Code em 2026-08-20; o rastreio de
   custo desta feature usa apenas os mecanismos internos já existentes
   (`docs/cost-profiles-and-rates.md`, `docs/ai-code-quality-and-observability.md`).
3. **Topologia multi-repo não conectada à consolidação de board** — **esclarecido
   nesta revisão**: `graph.yaml` referencia `vpn-skills-infrastructure` como
   dependência externa (repositório companheiro). O padrão correto para esse
   cenário (repo central + repo(s) de serviço/infraestrutura correlatos, com
   board consolidado) é agora **formalmente especificado em
   `specs/006-multirepo-support/`** (15 ACs detalhados: `bounded-contexts.yaml`,
   roteamento de Tasks via `/speckit-taskstoissues`, vínculo cross-repo via
   `setup-github-project.sh`) — publicada por outra sessão em paralelo e
   descoberta durante este replanejamento. **Ação restante**: se/quando
   `vpn-skills-infrastructure` for de fato criado como repositório separado,
   aplicar o modelo de `006-multirepo-support` a ele (declarar como bounded
   context correlato no `bounded-contexts.yaml` do VPN-SKILLS) — tratado como
   tarefa incremental fora do escopo desta feature, não bloqueia `tasks.md` atual
   porque T116 (`## Phase 8: Convergence`) já cobre "documentar e decidir" esse
   modelo; T116 pode agora apontar diretamente para `006-multirepo-support` em
   vez de reinventar o padrão.

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

