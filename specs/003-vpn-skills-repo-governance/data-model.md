# VPN-SKILLS Data Model

**Feature**: VPN-SKILLS Repository — Central Governance & Lifecycle Management
**Version**: 1.0
**Created**: 2026-08-12

---

## Overview

The VPN-SKILLS data model defines the core entities, their relationships, and validation rules that enable centralized skill management, versioning, and compliance across the organization.

---

## Core Entities

### 1. Skill

**Description**: A versioned, reusable component (code, configuration, or documentation) that solves a specific domain problem.

**Attributes**:

| Attribute | Type | Required | Validation | Example |
|-----------|------|----------|-----------|---------|
| `id` | string | Yes | Kebab-case, unique | `vpn-client-setup` |
| `name` | string | Yes | 1–100 chars | `VPN Client Setup` |
| `description` | string | Yes | 1–500 chars | `Automated provisioning of VPN client with certificate management` |
| `category` | enum | Yes | infrastructure, security, compliance, deployment, documentation | `infrastructure` |
| `status` | enum | Yes | active, beta, deprecated | `active` |
| `currentVersion` | string | Yes | Semver (MAJOR.MINOR.PATCH) | `2.1.3` |
| `supportedVersions` | array[string] | Yes | List of semver tags | `["2.1.3", "2.1.2", "2.0.5"]` |
| `maintainer` | string | Yes | GitHub/LDAP username or team | `@vpn-squad` |
| `license` | string | Yes | SPDX identifier | `MIT` or `Apache-2.0` |
| `prerequisiteSkills` | array[string] | No | List of skill IDs | `["base-infrastructure", "certificate-authority"]` |
| `externalDependencies` | array[object] | No | See below | — |
| `tags` | array[string] | No | 1–20 tags | `["vpn", "networking", "security"]` |
| `documentation` | string | Yes | URL or relative path | `docs/skills/vpn-client-setup/README.md` |
| `createdAt` | timestamp | Auto | ISO-8601 | `2026-01-15T10:30:00Z` |
| `updatedAt` | timestamp | Auto | ISO-8601 | `2026-08-12T14:00:00Z` |

**External Dependencies**:

```yaml
externalDependencies:
  - name: "OpenVPN"
    type: "tool"
    minVersion: "2.5.0"
    url: "https://openvpn.net"
    required: true
  - name: "Ubuntu 20.04+"
    type: "platform"
    required: true
```

**State Transitions**:

```
[Draft] → [Active] ⇄ [Beta] ↓ [Deprecated] → [Archived]
```

- **Draft → Active**: Approved by maintainer, all tests pass, documented
- **Active ↔ Beta**: Explicitly transitioned (e.g., new major feature, stabilization)
- **Active/Beta → Deprecated**: Announced via release notes, grace period (60 days recommended)
- **Deprecated → Archived**: Grace period elapsed, no active references

---

### 2. SkillVersion

**Description**: A specific release of a skill, tagged with Semantic Versioning.

**Attributes**:

| Attribute | Type | Required | Validation | Example |
|-----------|------|----------|-----------|---------|
| `skillId` | string | Yes | Foreign key to Skill | `vpn-client-setup` |
| `version` | string | Yes | Semver (MAJOR.MINOR.PATCH) | `2.1.3` |
| `releaseDate` | timestamp | Auto | ISO-8601 | `2026-08-12T14:00:00Z` |
| `isBreakingChange` | boolean | Yes | — | `true` or `false` |
| `breakingChangeDescription` | string | If breaking | 1–1000 chars | `Dropped support for OpenVPN < 2.5.0; config format changed` |
| `migrationPath` | string | If breaking | Markdown link/path | `docs/migrations/2.0-to-2.1.md` |
| `releaseNotes` | string | Yes | Markdown formatted | `## Features\n- Added multi-protocol support...` |
| `commitHash` | string | Yes | Git SHA-1 | `abc123def456...` |
| `tag` | string | Yes | Git tag | `v2.1.3` |
| `deprecationDate` | timestamp | If deprecated | ISO-8601 or null | `2026-10-12T00:00:00Z` |
| `deprecationReason` | string | If deprecated | 1–500 chars | `Superseded by VPN 3.0 with native multi-cloud support` |
| `deprecationNotice` | string | If deprecated | Markdown link | `https://github.com/org/vpn-skills/releases/tag/v2.1.3` |

**Validation Rules**:

- Version number must follow Semver strictly (e.g., no `v` prefix in data; `v` added only in Git tags)
- `releaseNotes` must reference commit history (e.g., "Fixes #123, Closes #456")
- If `isBreakingChange=true`, both `breakingChangeDescription` and `migrationPath` are required
- `commitHash` must be verifiable in Git history

---

### 3. SkillDependency

**Description**: A directed edge representing one skill depending on another (or on external tooling).

**Attributes**:

| Attribute | Type | Required | Validation | Example |
|-----------|------|----------|-----------|---------|
| `sourceSkillId` | string | Yes | Foreign key to Skill | `vpn-advanced-setup` |
| `targetSkillId` | string | Yes | Foreign key to Skill (or external ID) | `vpn-client-setup` or `openssl@1.1` |
| `versionConstraint` | string | Yes | Semver range (npm syntax) | `~2.1.0`, `>=2.0.0 <3.0.0`, `*` |
| `isRequired` | boolean | Yes | — | `true` (hard) or `false` (optional) |
| `reason` | string | Yes | 1–200 chars | `Requires base VPN client setup and certificate handling` |
| `installationOrder` | integer | No | 1–100 (lower = earlier) | `1` (install first) |

**Validation Rules**:

- `versionConstraint` must be valid semver range (parseable by semver libraries)
- Self-dependencies are forbidden (source ≠ target)
- Circular dependencies are flagged as warnings; validation should detect and report
- For external dependencies (target not in Skill table), `targetSkillId` is prefixed with namespace (e.g., `tool:openssl@1.1`)

---

### 4. SkillManifest

**Description**: A declarative file (YAML/JSON) that a project uses to declare its skill dependencies.

**Attributes (File Format)**:

```yaml
# skills.yaml (location: root or ./infra/skills.yaml in projects)
version: "1.0"
projectId: "order-service"
manifestVersion: "1"
createdAt: "2026-08-12T14:00:00Z"
updatedAt: "2026-08-12T14:00:00Z"

skills:
  - skillId: "vpn-client-setup"
    version: "2.1.3"  # Pinned version
    platform: ["linux"]  # Optional: limit to platforms
    environment: ["dev", "staging", "prod"]  # Environments where active
    
  - skillId: "certificate-authority"
    version: "~1.2.0"  # Semver range
    platform: ["linux", "windows"]
    environment: ["prod"]
    
compliance:
  validateOnDeploy: true  # Run validation before deployment
  failOnDeprecated: true  # Fail if using deprecated skills
  reportFrequency: "daily"  # Compliance scan frequency
```

**Entity Attributes (Database)**:

| Attribute | Type | Required | Validation | Example |
|-----------|------|----------|-----------|---------|
| `projectId` | string | Yes | Project identifier (GitHub repo slug or internal ID) | `order-service` |
| `manifestPath` | string | Yes | File path in project repo | `infra/skills.yaml` |
| `skills` | array[SkillReference] | Yes | Non-empty list | — |
| `complianceConfig` | object | Yes | See above | — |
| `lastValidationAt` | timestamp | Auto | ISO-8601 | `2026-08-12T14:00:00Z` |
| `lastValidationStatus` | enum | Auto | success, warning, error | `success` |
| `validationMessages` | array[string] | Auto | Warnings/errors | `["Warning: vpn-client-setup 2.1.2 is deprecated as of 2026-10-12"]` |

---

### 5. ComplianceReport

**Description**: A snapshot of skill usage and governance status across a project or organization.

**Attributes**:

| Attribute | Type | Required | Validation | Example |
|-----------|------|----------|-----------|---------|
| `reportId` | string | Auto | UUID | `550e8400-e29b-41d4-a716-446655440000` |
| `reportType` | enum | Yes | project, organization | `project` |
| `scopeId` | string | Yes | Project ID or "org-wide" | `order-service` |
| `generatedAt` | timestamp | Auto | ISO-8601 | `2026-08-12T14:00:00Z` |
| `scanTimestamp` | timestamp | Auto | ISO-8601 | `2026-08-12T14:00:00Z` |
| `findings` | array[Finding] | Yes | See below | — |
| `summary` | object | Yes | Counts and metrics | — |

**Finding Object**:

```yaml
findings:
  - id: "SKILL-DEPRECATED"
    severity: "warning"  # info, warning, error, critical
    skill: "vpn-client-setup"
    version: "2.1.2"
    message: "Skill version 2.1.2 is deprecated as of 2026-10-12"
    recommendation: "Upgrade to 2.1.3 or later; see migration guide: ..."
    affectedEnvironments: ["dev", "staging"]
    
  - id: "SKILL-INCOMPATIBLE"
    severity: "error"
    skill: "vpn-advanced-setup"
    version: "3.0.0"
    message: "Requires platform 'linux' but project is 'windows-only'"
    recommendation: "Remove skill or update project platform requirements"
    
  - id: "TRANSITIVE-DEPRECATED"
    severity: "warning"
    skill: "vpn-advanced-setup"
    version: "2.5.0"
    message: "Depends on deprecated skill: vpn-client-setup v2.1.2"
    recommendation: "Transitive deprecation: upgrade parent skill version"
```

**Summary Metrics**:

```yaml
summary:
  totalSkillReferences: 12
  activeSkills: 10
  deprecatedSkills: 1
  incompatibleSkills: 1
  criticalFindings: 0
  errorFindings: 1
  warningFindings: 2
  infoFindings: 3
  complianceScore: "85%"  # (total - findings.critical - findings.error) / total
  lastSuccessfulValidation: "2026-08-11T10:00:00Z"
```

---

## Relationships (ER Diagram)

```
Skill (1) ─── (many) SkillVersion
  │
  └─── (many) SkillDependency (as source or target)

SkillManifest (many) ─── (1) Project
  │
  └─ contains list of SkillReferences
    (maps to Skill + version constraint)

ComplianceReport (many) ─── (1) Project
  │
  └─ snapshots state of SkillManifest at point-in-time
```

---

## Validation Rules

### Skill Validation

1. **Unique ID**: Each skill ID is globally unique in VPN-SKILLS
2. **Version Sequence**: Versions must follow Semver strictly; `currentVersion` must be in `supportedVersions`
3. **Prerequisite Chain**: Prerequisite skills must exist; no circular dependencies
4. **Status Consistency**: If `status=deprecated`, `deprecationDate` must be set

### SkillVersion Validation

1. **No Duplicate Tags**: Each (skillId, version) pair has exactly one tag
2. **Breaking Change Declaration**: If `isBreakingChange=true`, migration path must be provided
3. **Release Notes**: Must reference at least one commit hash or issue #

### SkillManifest Validation

1. **Valid References**: All skill IDs in manifest must exist in VPN-SKILLS catalog
2. **Version Compatibility**: Version constraints must satisfy at least one available version
3. **Transitive Dependencies**: All transitive dependencies (skill A depends on B, B depends on C) must be satisfiable
4. **Platform/Environment Consistency**: Skills required for platforms/environments must be compatible

### ComplianceReport Generation

1. **Freshness**: Report is current if generated within last 24 hours (configurable)
2. **Completeness**: Must include all references from current SkillManifest
3. **Breaking Change Detection**: Automatic scan for:
   - Deprecated versions in use
   - Incompatible versions (breaking changes not addressed)
   - Transitive deprecation (dependency chain contains deprecated skill)

---

## State Management

### Skill Lifecycle

```
Creation:
  Skill created → status="active" (or "beta" if new pattern)

Evolution:
  Skill v1.0.0 → v1.1.0 (patch/minor) → v2.0.0 (breaking)
  Each version tagged in Git, released via GitHub Actions

Deprecation Announcement:
  → status="deprecated", deprecationDate set in SkillVersion
  → Release notes include deprecation notice

Deprecation Grace Period:
  60 days (default, configurable per Skill)
  → Compliance reports flag as warnings
  → Projects notified; deadline for upgrade

End of Life:
  Grace period elapsed → status="archived"
  → Skill still available for reference, but not recommended
  → Warning escalated in compliance reports
```

### Manifest Lifecycle

```
Creation:
  Project creates skills.yaml → describes current skill dependencies

Validation (on every deploy or manual trigger):
  System reads skills.yaml
  → Resolves versions against VPN-SKILLS catalog
  → Checks compatibility (semver ranges, prerequisites, platform)
  → Generates ComplianceReport (findings + summary)

Update:
  Project changes skills.yaml (pins version, adds skill, removes skill)
  → Next validation run detects changes
  → New ComplianceReport issued with diffs

Compliance:
  Report stored (audit trail)
  → Aggregated for organization-wide compliance dashboard
  → Alerts triggered if violations detected (e.g., critical deprecation)
```

---

## API Mapping

This data model maps to REST API endpoints:

| Entity | Create | Read | Update | Delete |
|--------|--------|------|--------|--------|
| Skill | N/A | `GET /skills/{id}` | Release workflow | N/A |
| SkillVersion | Release workflow | `GET /skills/{id}/versions/{version}` | N/A | N/A |
| SkillDependency | N/A | Implicit in Skill | N/A | N/A |
| SkillManifest | Project init | `GET /projects/{id}/manifest` | `PUT /projects/{id}/manifest` | N/A |
| ComplianceReport | Trigger scan | `GET /reports/{id}`, `GET /projects/{id}/compliance` | N/A | N/A |

---

## Example Data Instances

### Example Skill: VPN Client Setup

```yaml
id: "vpn-client-setup"
name: "VPN Client Setup"
description: "Automated provisioning of VPN client with certificate management"
category: "infrastructure"
status: "active"
currentVersion: "2.1.3"
supportedVersions:
  - "2.1.3"
  - "2.1.2"
  - "2.0.5"
maintainer: "@vpn-squad"
license: "MIT"
prerequisiteSkills:
  - "certificate-authority"
externalDependencies:
  - name: "OpenVPN"
    type: "tool"
    minVersion: "2.5.0"
    required: true
tags:
  - "vpn"
  - "networking"
  - "security"
documentation: "docs/skills/vpn-client-setup/README.md"
createdAt: "2026-01-15T10:30:00Z"
updatedAt: "2026-08-12T14:00:00Z"
```

### Example SkillVersion: VPN Client Setup v2.1.3

```yaml
skillId: "vpn-client-setup"
version: "2.1.3"
releaseDate: "2026-08-12T14:00:00Z"
isBreakingChange: false
releaseNotes: |
  ## Features
  - Added multi-protocol support (OpenVPN, WireGuard)
  - Improved certificate auto-renewal
  
  ## Fixes
  - Fixed config parsing on Windows (#234)
  
  ## Closes
  - Closes #234, #235
commitHash: "abc123def456..."
tag: "v2.1.3"
```

---

## Future Enhancements (Out of Scope for v1)

- Skill versioning via package registries (npm, pip, Maven)
- Advanced dependency resolution (resolver algorithm for complex constraints)
- Skill composition (higher-order skills built from multiple base skills)
- Role-based access control (RBAC) for skill publishing/modification
- Automated skill testing in CI/CD before release

