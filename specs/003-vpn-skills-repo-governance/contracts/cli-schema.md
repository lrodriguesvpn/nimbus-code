# VPN-SKILLS CLI Command Schema

**Version**: 1.0  
**Created**: 2026-08-12

This document defines the CLI interface for VPN-SKILLS tooling, used by developers and CI/CD pipelines.

---

## Command: `vpn-skills list`

**Description**: List all available skills in VPN-SKILLS repository.

**Usage**:
```bash
vpn-skills list [OPTIONS]
```

**Options**:

```yaml
options:
  --status:
    type: "string"
    enum: ["active", "beta", "deprecated"]
    optional: true
    description: "Filter by skill status"
    example: "--status active"
    
  --category:
    type: "string"
    enum: ["infrastructure", "security", "compliance", "deployment", "documentation"]
    optional: true
    description: "Filter by category"
    example: "--category infrastructure"
    
  --tag:
    type: "array"
    optional: true
    description: "Filter by tag (repeatable)"
    example: "--tag vpn --tag security"
    
  --format:
    type: "string"
    enum: ["table", "json", "yaml"]
    default: "table"
    optional: true
    description: "Output format"
    
  --limit:
    type: "integer"
    default: 50
    optional: true
    description: "Limit number of results"
```

**Output (table)**:
```
ID                          | Name                      | Current | Status     | Category
vpn-client-setup           | VPN Client Setup          | 2.1.3   | active     | infrastructure
certificate-authority      | Certificate Authority     | 1.2.1   | active     | security
vpn-advanced-setup         | VPN Advanced Setup        | 2.5.0   | deprecated | infrastructure
```

**Output (json)**:
```json
{
  "skills": [
    {
      "id": "vpn-client-setup",
      "name": "VPN Client Setup",
      "currentVersion": "2.1.3",
      "status": "active",
      "category": "infrastructure"
    }
  ],
  "total": 1,
  "limit": 50,
  "offset": 0
}
```

---

## Command: `vpn-skills show`

**Description**: Display detailed information about a specific skill.

**Usage**:
```bash
vpn-skills show <skillId> [OPTIONS]
```

**Arguments**:
- `<skillId>` (required): Skill identifier (e.g., `vpn-client-setup`)

**Options**:
```yaml
  --version:
    type: "string"
    optional: true
    description: "Show specific version (default: current)"
    example: "--version 2.1.3"
    
  --format:
    type: "string"
    enum: ["text", "json", "yaml"]
    default: "text"
    optional: true
```

**Output (text)**:
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

Documentation: https://github.com/org/vpn-skills/tree/main/docs/vpn-client-setup
```

---

## Command: `vpn-skills versions`

**Description**: Show version history and release notes for a skill.

**Usage**:
```bash
vpn-skills versions <skillId> [OPTIONS]
```

**Options**:
```yaml
  --limit:
    type: "integer"
    default: 10
    optional: true
    description: "Limit number of versions shown"
```

**Output**:
```
Skill: vpn-client-setup

Version 2.1.3 (2026-08-12)
  Status: active
  Breaking Change: no
  Release Notes:
    - Added multi-protocol support (OpenVPN, WireGuard)
    - Improved certificate auto-renewal
    - Fixed config parsing on Windows (#234)

Version 2.1.2 (2026-08-01)
  Status: active (deprecated as of 2026-10-12)
  Breaking Change: no
  Release Notes:
    - Security update: certificate validation hardening

Version 2.0.5 (2026-06-15)
  Status: active (supported)
  Breaking Change: yes
  Migration Guide: https://github.com/org/vpn-skills/tree/main/docs/migrations/2.0-to-2.1.md
```

---

## Command: `vpn-skills validate`

**Description**: Validate a skills.yaml manifest against VPN-SKILLS catalog.

**Usage**:
```bash
vpn-skills validate [OPTIONS]
```

**Options**:
```yaml
  --manifest:
    type: "string"
    default: "skills.yaml"
    optional: true
    description: "Path to skills manifest file"
    
  --platform:
    type: "array"
    optional: true
    description: "Project platforms (repeatable)"
    example: "--platform linux --platform macos"
    
  --environment:
    type: "array"
    optional: true
    description: "Deployment environments (repeatable)"
    example: "--environment dev --environment prod"
    
  --fail-on-deprecated:
    type: "boolean"
    default: false
    optional: true
    description: "Exit with error if deprecated skills found"
    
  --format:
    type: "string"
    enum: ["text", "json"]
    default: "text"
    optional: true
```

**Output (success)**:
```
✓ Manifest validation successful

Skills checked: 2
✓ vpn-client-setup @ 2.1.3 (compatible)
✓ certificate-authority @ ~1.2.0 (compatible, resolved to 1.2.1)

Compliance Score: 100%
No warnings or errors detected.

Exit code: 0
```

**Output (with warnings)**:
```
⚠ Manifest validation completed with warnings

Skills checked: 3
✓ vpn-client-setup @ 2.1.3 (compatible)
✓ certificate-authority @ ~1.2.0 (compatible, resolved to 1.2.1)
⚠ vpn-advanced-setup @ 2.5.0 (deprecated as of 2026-10-12, grace period ends 2026-10-12)

Compliance Score: 66%

Warnings:
  1. vpn-advanced-setup v2.5.0 is deprecated. Upgrade to 3.0.0 or later.
     Migration guide: https://github.com/org/vpn-skills/tree/main/docs/migrations/2.5-to-3.0.md

Exit code: 0 (or 1 if --fail-on-deprecated)
```

**Output (with errors)**:
```
✗ Manifest validation failed

Skills checked: 2
✓ vpn-client-setup @ 2.1.3 (compatible)
✗ certificate-authority @ 2.0.0 (incompatible)

Compliance Score: 0%

Errors:
  1. certificate-authority v2.0.0 requires platform 'linux' but project has 'windows'.
     Recommended action: Remove skill or update project platform requirements.

Exit code: 1
```

---

## Command: `vpn-skills compliance`

**Description**: Generate compliance report for current project.

**Usage**:
```bash
vpn-skills compliance [OPTIONS]
```

**Options**:
```yaml
  --project:
    type: "string"
    optional: true
    description: "Project ID (default: infer from current directory)"
    
  --output:
    type: "string"
    optional: true
    description: "Save report to file (JSON/YAML)"
    example: "--output compliance-report.json"
    
  --format:
    type: "string"
    enum: ["text", "json"]
    default: "text"
    optional: true
```

**Output (text)**:
```
VPN-SKILLS Compliance Report
Project: order-service
Generated: 2026-08-12T14:00:00Z

Summary:
  Total Skills: 3
  Active: 2
  Deprecated: 1
  Incompatible: 0
  Compliance Score: 66%

Findings:

  [WARNING] Deprecated Skill
    Skill: vpn-advanced-setup v2.5.0
    Status: Deprecated (expires 2026-10-12)
    Environment: prod
    Action: Upgrade to v3.0.0 or later within 60 days
    Guide: https://github.com/org/vpn-skills/tree/main/docs/migrations/2.5-to-3.0.md

No critical errors. Compliance within acceptable parameters.
```

---

## Command: `vpn-skills search`

**Description**: Search for skills by keyword.

**Usage**:
```bash
vpn-skills search <query> [OPTIONS]
```

**Arguments**:
- `<query>` (required): Search query (searches ID, name, description, tags)

**Options**:
```yaml
  --limit:
    type: "integer"
    default: 20
    optional: true
```

**Output**:
```
Search Results for: "VPN"

ID                          | Name                      | Match
vpn-client-setup           | VPN Client Setup          | Full match on ID, description
vpn-advanced-setup         | VPN Advanced Setup        | Full match on ID
certificate-authority      | Certificate Authority     | Partial match on tags (vpn)
```

---

## Command: `vpn-skills init`

**Description**: Initialize a new project with a skills.yaml manifest.

**Usage**:
```bash
vpn-skills init [OPTIONS]
```

**Options**:
```yaml
  --template:
    type: "string"
    enum: ["empty", "minimal", "standard"]
    default: "empty"
    optional: true
    description: "Template for initial manifest"
```

**Output**:
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

---

## Global Options

All commands support:

```yaml
  --help, -h:
    type: "boolean"
    description: "Show command help"
    
  --version:
    type: "boolean"
    description: "Show CLI version"
    
  --config:
    type: "string"
    optional: true
    description: "Path to config file"
    example: "--config ~/.vpn-skills/config.yaml"
    
  --api-url:
    type: "string"
    optional: true
    description: "VPN-SKILLS API endpoint"
    default: "https://vpn-skills.org/api/v1"
    example: "--api-url http://localhost:8080/api/v1"
    
  --verbose:
    type: "boolean"
    optional: true
    description: "Enable verbose output"
    
  --json:
    type: "boolean"
    optional: true
    description: "Output as JSON (shorthand for --format json)"
```

---

## Exit Codes

- `0`: Success
- `1`: Validation failed / incompatibility detected
- `2`: File not found / input error
- `3`: API unreachable
- `4`: Configuration error
- `5`: Unexpected error

---

## Config File Format

**Location**: `~/.vpn-skills/config.yaml` or `$VPN_SKILLS_CONFIG`

```yaml
# VPN-SKILLS CLI Configuration

api:
  url: "https://vpn-skills.org/api/v1"
  timeout: 30  # seconds
  retries: 3

defaults:
  format: "table"  # table, json, yaml
  limit: 50
  
compliance:
  failOnDeprecated: false
  reportFrequency: "daily"
  platforms: ["linux"]
  environments: ["dev", "staging", "prod"]
  
auth:
  token: "${VPN_SKILLS_TOKEN}"  # Environment variable
  tokenFile: "~/.vpn-skills/token"  # Or file

cache:
  enabled: true
  ttl: 3600  # seconds (1 hour)
  path: "~/.vpn-skills/cache"
```

