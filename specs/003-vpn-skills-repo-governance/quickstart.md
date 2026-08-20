# VPN-SKILLS Quickstart Validation Guide

**Version**: 1.0  
**Created**: 2026-08-12

This guide provides end-to-end test scenarios that validate each user story of the VPN-SKILLS feature.

---

## Prerequisites

- **Environment**: Linux or macOS
- **Tools**: Git, curl, Docker (optional for server testing)
- **Access**: GitHub credentials (to clone VPN-SKILLS repo)
- **Time**: ~30 minutes for all scenarios

### Setup

```bash
# 1. Clone VPN-SKILLS repository
git clone https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/vpn-skills.git
cd vpn-skills

# 2. Install CLI (if not already installed)
curl -sSL https://vpn-skills.org/install.sh | bash

# 3. Verify CLI is accessible
vpn-skills --version
# Expected output: vpn-skills version 1.0.0

# 4. Verify API server (if self-hosting)
# Skip if using SaaS https://vpn-skills.org/api/v1
export VPN_SKILLS_API="http://localhost:8080/api/v1"
```

---

## Scenario 1: Initialize and Configure a New Project (User Story P1-US1)

**Objective**: Verify that a developer can initialize a project with a `skills.yaml` manifest.

**Setup**:
```bash
mkdir test-project-1
cd test-project-1
git init
```

**Steps**:

### 1.1 Initialize manifest with default template

```bash
vpn-skills init --template empty
```

**Expected Output**:
```
✓ Created skills.yaml in current directory

To add skills, edit skills.yaml:
  
  skills:
    - skillId: "vpn-client-setup"
      version: "~2.1.0"
      environment: ["dev", "staging", "prod"]

Then run:
  vpn-skills validate

For help: vpn-skills --help
```

**Verification**:
```bash
ls -la skills.yaml
cat skills.yaml
# File should exist with basic template structure
```

### 1.2 Add first skill to manifest

```bash
cat > skills.yaml <<EOF
version: "1.0"
projectId: "test-project-1"

metadata:
  owner: "test-user"
  description: "Test project for VPN-SKILLS"

skills:
  - skillId: "vpn-client-setup"
    version: "2.1.3"
    environment: ["dev"]
EOF
```

### 1.3 Validate manifest

```bash
vpn-skills validate --manifest skills.yaml
```

**Expected Output**:
```
✓ Manifest validation successful

Skills checked: 1
✓ vpn-client-setup @ 2.1.3 (compatible)

Compliance Score: 100%
No warnings or errors detected.

Exit code: 0
```

**Verification**:
```bash
echo $?  # Should be 0 (success)
```

### 1.4 Commit to version control

```bash
git add skills.yaml
git commit -m "chore: initialize VPN skills manifest"
git log --oneline -n 1
# Should show: "chore: initialize VPN skills manifest"
```

**Outcome**: ✅ User can initialize a project and version-control a skills manifest.

---

## Scenario 2: Discover and Validate Available Skills (User Story P2a-US2)

**Objective**: Verify that operators can discover, inspect, and validate skill catalog.

**Setup**:
```bash
cd ../  # Back to parent directory
mkdir test-project-2
cd test-project-2
```

**Steps**:

### 2.1 List all active skills

```bash
vpn-skills list --status active
```

**Expected Output**:
```
ID                          | Name                      | Current | Status     | Category
vpn-client-setup           | VPN Client Setup          | 2.1.3   | active     | infrastructure
certificate-authority      | Certificate Authority     | 1.2.1   | active     | security
vpn-gateway-ha             | VPN Gateway HA            | 1.0.2   | active     | infrastructure
```

**Verification**:
- At least 2 active skills listed
- Each skill has ID, name, version, status, category

### 2.2 Show detailed info for a skill

```bash
vpn-skills show vpn-client-setup
```

**Expected Output** (sample):
```
Skill: VPN Client Setup
ID: vpn-client-setup
Description: Automated provisioning of VPN client with certificate management
Category: infrastructure
Status: active
Current Version: 2.1.3

Supported Versions:
  - 2.1.3
  - 2.1.2
  - 2.0.5

Maintainer: @vpn-squad
License: MIT

Prerequisites:
  - certificate-authority

External Dependencies:
  - OpenVPN >= 2.5.0 (required)

Tags: vpn, networking, security

Documentation: https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/vpn-skills/tree/main/docs/vpn-client-setup
```

**Verification**:
- Skill ID, description, and status match
- At least 2 versions available
- Maintainer info present
- Prerequisites listed

### 2.3 Check version history and deprecation

```bash
vpn-skills versions vpn-client-setup --limit 3
```

**Expected Output** (sample):
```
Skill: vpn-client-setup

Version 2.1.3 (2026-08-12)
  Status: active
  Breaking Change: no

Version 2.1.2 (2026-08-01)
  Status: active (deprecated as of 2026-10-12)
  Breaking Change: no
  Release Notes:
    - Security update: certificate validation hardening

Version 2.0.5 (2026-06-15)
  Status: active (supported)
  Breaking Change: yes
  Migration Guide: https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/vpn-skills/tree/main/docs/migrations/2.0-to-2.1.md
```

**Verification**:
- Current version marked as active
- Older versions show deprecation dates (if applicable)
- Breaking changes clearly labeled
- Migration guides referenced

### 2.4 Search for skills by keyword

```bash
vpn-skills search "certificate" --limit 5
```

**Expected Output** (sample):
```
Search Results for: "certificate"

ID                          | Name                      | Match
certificate-authority      | Certificate Authority     | Full match on ID, description
vpn-client-setup           | VPN Client Setup          | Partial match on description
```

**Verification**:
- At least one exact match
- Relevant partial matches included
- Result count reasonable

**Outcome**: ✅ Operators can discover, inspect, and understand skills and their lifecycle.

---

## Scenario 3: Declare Skill Dependencies with Validation (User Story P2b-US3)

**Objective**: Verify that a project can declare skill dependencies and validate compatibility.

**Setup**:
```bash
cd ../
mkdir test-project-3
cd test-project-3
git init
```

**Steps**:

### 3.1 Create multi-skill manifest

```bash
cat > skills.yaml <<EOF
version: "1.0"
projectId: "test-project-3"

metadata:
  owner: "integration-team"
  description: "Multi-skill VPN setup for production"

skills:
  - skillId: "vpn-client-setup"
    version: "2.1.3"
    platform: ["linux"]
    environment: ["dev", "staging", "prod"]

  - skillId: "certificate-authority"
    version: "~1.2.0"
    platform: ["linux"]
    environment: ["staging", "prod"]

  - skillId: "vpn-gateway-ha"
    version: "^1.0.0"
    platform: ["linux"]
    environment: ["prod"]

compliance:
  validateOnCI: true
  failOnDeprecated: false
  failOnIncompatible: true
EOF
```

### 3.2 Validate full manifest

```bash
vpn-skills validate --manifest skills.yaml --platform linux --environment prod
```

**Expected Output**:
```
✓ Manifest validation successful

Skills checked: 3
✓ vpn-client-setup @ 2.1.3 (compatible)
✓ certificate-authority @ ~1.2.0 (compatible, resolved to 1.2.1)
✓ vpn-gateway-ha @ ^1.0.0 (compatible, resolved to 1.0.2)

Compliance Score: 100%
No warnings or errors detected.

Dependency Resolution:
  vpn-client-setup v2.1.3
  ├── certificate-authority v1.2.1 ✓ (provided)
  └── openssl >= 1.1.1 ✓ (external)

Exit code: 0
```

**Verification**:
- All 3 skills validated
- Versions resolved correctly
- Transitive dependencies satisfied
- Exit code 0

### 3.3 Test validation failure scenario (incompatible version)

```bash
cat > skills-incompatible.yaml <<EOF
version: "1.0"
projectId: "test-project-3-bad"

skills:
  - skillId: "vpn-client-setup"
    version: "9.9.9"  # Non-existent version
    environment: ["prod"]
EOF

vpn-skills validate --manifest skills-incompatible.yaml --environment prod
```

**Expected Output**:
```
✗ Manifest validation failed

Skills checked: 1
✗ vpn-client-setup @ 9.9.9 (incompatible)

Compliance Score: 0%

Errors:
  1. vpn-client-setup v9.9.9 does not exist.
     Available versions: 2.1.3 (current), 2.1.2, 2.0.5
     Recommendation: Pin to an available version

Exit code: 1
```

**Verification**:
- Validation fails with exit code 1
- Clear error message showing available versions
- Recommendation provided

### 3.4 Commit validated manifest

```bash
git add skills.yaml
git commit -m "feat: add multi-skill VPN configuration for production"
```

**Outcome**: ✅ Projects can declare multi-skill dependencies with version constraints and validate compatibility.

---

## Scenario 4: Compliance Checking and Reporting (User Story P3-US4)

**Objective**: Verify that operators can generate and track compliance reports.

**Setup**:
```bash
cd ../test-project-3  # Use existing project
```

**Steps**:

### 4.1 Generate compliance report

```bash
vpn-skills compliance --project test-project-3 --output compliance-report.json
```

**Expected Output** (console):
```
VPN-SKILLS Compliance Report
Project: test-project-3
Generated: 2026-08-12T14:00:00Z

Summary:
  Total Skills: 3
  Active: 3
  Deprecated: 0
  Incompatible: 0
  Compliance Score: 100%

No findings. Full compliance.
```

**File Output** (compliance-report.json):
```json
{
  "projectId": "test-project-3",
  "generated": "2026-08-12T14:00:00Z",
  "summary": {
    "totalSkills": 3,
    "active": 3,
    "deprecated": 0,
    "incompatible": 0,
    "complianceScore": 100
  },
  "skills": [
    {
      "skillId": "vpn-client-setup",
      "version": "2.1.3",
      "status": "active",
      "finding": null
    },
    {
      "skillId": "certificate-authority",
      "version": "1.2.1",
      "status": "active",
      "finding": null
    },
    {
      "skillId": "vpn-gateway-ha",
      "version": "1.0.2",
      "status": "active",
      "finding": null
    }
  ],
  "findings": []
}
```

**Verification**:
- JSON report created and valid
- Compliance score 100% for all-active skills
- All skills accurately listed with resolved versions

### 4.2 Test deprecation detection

Create a manifest with a deprecated skill:

```bash
cat > skills-deprecated.yaml <<EOF
version: "1.0"
projectId: "test-project-3-deprecated"

skills:
  - skillId: "vpn-client-setup"
    version: "2.0.5"  # Deprecated version
    environment: ["prod"]
EOF

vpn-skills compliance --output compliance-deprecated.json <<< "$(cat skills-deprecated.yaml)"
```

**Expected Output** (with deprecation):
```
⚠ Compliance Report Generated

Summary:
  Total Skills: 1
  Active: 1
  Deprecated: 1
  Incompatible: 0
  Compliance Score: 0%  (due to deprecated skill usage)

Findings:

  [WARNING] Deprecated Skill
    Skill: vpn-client-setup v2.0.5
    Status: Deprecated (expires 2026-12-31)
    Environment: prod
    Action: Upgrade to v2.1.3 or later
    Migration Guide: https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/vpn-skills/tree/main/docs/migrations/2.0-to-2.1.md
```

**Verification**:
- Deprecation clearly flagged
- Compliance score reduced
- Migration path provided

### 4.3 Archive and share compliance report

```bash
tar -czf compliance-reports.tar.gz compliance-*.json
shasum compliance-reports.tar.gz > compliance-reports.tar.gz.sha256
cat compliance-reports.tar.gz.sha256
```

**Outcome**: ✅ Operators can generate, track, and audit compliance reports.

---

## Scenario 5: Integration with CI/CD (Advanced - Optional)

**Objective**: Verify that skills validation integrates into automated pipelines.

**Setup**:
```bash
cd ../test-project-3
```

**Steps**:

### 5.1 Create GitHub Actions workflow

```bash
mkdir -p .github/workflows
cat > .github/workflows/vpn-skills-validation.yml <<EOF
name: VPN Skills Compliance

on:
  push:
    branches: [main, develop]
    paths: ["skills.yaml"]
  pull_request:
    paths: ["skills.yaml"]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install VPN-SKILLS CLI
        run: curl -sSL https://vpn-skills.org/install.sh | bash
      
      - name: Validate manifest
        run: vpn-skills validate --fail-on-deprecated
      
      - name: Generate report
        run: vpn-skills compliance --output compliance.json
      
      - name: Upload artifact
        uses: actions/upload-artifact@v3
        with:
          name: compliance-report
          path: compliance.json
EOF

cat .github/workflows/vpn-skills-validation.yml
```

**Verification**:
- Workflow file created and valid YAML
- All required steps present
- Artifact upload configured

### 5.2 Simulate workflow run (local)

```bash
# Install CLI if needed
vpn-skills --version

# Run validation as CI would
vpn-skills validate --manifest skills.yaml --fail-on-deprecated
echo "Exit code: $?"
```

**Expected Output**:
```
✓ Manifest validation successful
Exit code: 0
```

**Outcome**: ✅ Skills validation can be integrated into automated CI/CD pipelines.

---

## Scenario 6: API Integration (Optional - For SaaS Users)

**Objective**: Verify that REST API can be used programmatically.

**Setup**:
```bash
# Ensure API server is accessible
export VPN_SKILLS_API="https://vpn-skills.org/api/v1"
```

**Steps**:

### 6.1 Query skills list via API

```bash
curl -s "${VPN_SKILLS_API}/skills?status=active&limit=3" | jq .
```

**Expected Output** (sample):
```json
{
  "skills": [
    {
      "id": "vpn-client-setup",
      "name": "VPN Client Setup",
      "currentVersion": "2.1.3",
      "status": "active",
      "category": "infrastructure"
    },
    {
      "id": "certificate-authority",
      "name": "Certificate Authority",
      "currentVersion": "1.2.1",
      "status": "active",
      "category": "security"
    }
  ],
  "total": 2,
  "limit": 3,
  "offset": 0
}
```

### 6.2 Validate manifest via API

```bash
curl -s -X POST "${VPN_SKILLS_API}/validate" \
  -H "Content-Type: application/json" \
  -d @skills.json | jq .
```

**Expected Output**:
```json
{
  "valid": true,
  "complianceScore": 100,
  "skills": [
    {
      "skillId": "vpn-client-setup",
      "version": "2.1.3",
      "status": "compatible",
      "resolved": true
    }
  ],
  "errors": [],
  "warnings": []
}
```

**Outcome**: ✅ REST API provides programmatic access to skills catalog and validation.

---

## Success Criteria Checklist

All scenarios above validate the following success criteria from the feature specification:

- [ ] **SC-001**: Projects can initialize skills.yaml manifest in under 1 minute
- [ ] **SC-002**: Skill discovery (list, show, search) completes in <2 seconds
- [ ] **SC-003**: Manifest validation (3+ skills) completes in <3 seconds
- [ ] **SC-004**: Compliance report generation (<50 skills) completes in <5 seconds
- [ ] **SC-005**: CI/CD integration (GitHub Actions) runs validation in <30 seconds
- [ ] **SC-006**: No manual intervention required after initial setup
- [ ] **SC-007**: Zero false positives on compatibility checks
- [ ] **SC-008**: All error messages reference documentation links

---

## Cleanup

After completing all scenarios:

```bash
cd ../..
rm -rf test-project-*
echo "Cleanup complete"
```

---

## Related Documentation

- **Data Model**: See [data-model.md](data-model.md) for entity definitions and relationships
- **REST API**: See [api-openapi.yaml](contracts/api-openapi.yaml) for endpoint specifications
- **CLI Reference**: See [cli-schema.md](contracts/cli-schema.md) for complete command documentation
- **Manifest Format**: See [skills-manifest-format.md](contracts/skills-manifest-format.md) for YAML schema
- **Feature Specification**: See [spec.md](../spec.md) for requirements and acceptance criteria

