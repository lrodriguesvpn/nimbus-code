# VPN-SKILLS Manifest Format (skills.yaml)

**Version**: 1.0  
**Created**: 2026-08-12

This document defines the structure and validation rules for `skills.yaml` manifests used by projects to declare their VPN-SKILLS dependencies.

---

## File Location

Projects should place `skills.yaml` in one of these locations:

- `./skills.yaml` (root, recommended for simple projects)
- `./infra/skills.yaml` (infrastructure folder, for larger projects)
- `.github/skills.yaml` (GitHub-specific, if using GitHub-native workflows)

The manifest file is versioned in Git alongside infrastructure-as-code and deployment configurations.

---

## Schema

**YAML Structure**:

```yaml
version: "1.0"
projectId: "order-service"
manifestVersion: "1"
createdAt: "2026-08-12T14:00:00Z"
updatedAt: "2026-08-12T14:00:00Z"

metadata:
  owner: "platform-team"
  description: "VPN and infrastructure skills for order-service"
  reviewedAt: "2026-08-01T10:00:00Z"
  reviewedBy: "@platform-lead"

skills:
  - skillId: "vpn-client-setup"
    version: "2.1.3"
    # Optional: limit to specific platforms
    platform: ["linux", "macos"]
    # Optional: limit to specific environments
    environment: ["dev", "staging", "prod"]
    # Optional: additional configuration per environment
    config:
      dev:
        autoRenew: false
      prod:
        autoRenew: true

  - skillId: "certificate-authority"
    version: "~1.2.0"  # Semver range: will accept 1.2.0, 1.2.1, 1.2.x but not 1.3.0
    platform: ["linux"]
    environment: ["prod"]
    
  - skillId: "vpn-advanced-setup"
    version: "^2.5.0"  # Semver range: will accept 2.5.0, 2.6.0, but not 3.0.0
    environment: ["prod"]
    # This skill is conditional (warning: recommended only for power users)
    optional: false  # If true, missing skill does not fail validation
    notes: "High-performance VPN for multi-region failover"

compliance:
  validateOnDeploy: true
  validateOnCI: true  # Run during GitHub Actions / CI/CD
  failOnDeprecated: false  # If true, fail if deprecated skills present
  failOnIncompatible: true  # If true, fail if incompatible versions
  reportFrequency: "daily"  # daily, weekly, on-demand
  notifyOnFindings: true  # Send notifications for compliance issues
  notificationChannels:  # Optional: where to send notifications
    - email: "platform-team@company.com"
    - slack: "#vpn-alerts"

# Optional: feature flags to gate skills (for gradual rollout)
featureFlags:
  - skillId: "vpn-advanced-setup"
    flagKey: "vpn.advanced-setup.enabled"
    environments: ["staging", "prod"]
```

---

## Validation Rules

### Required Fields

- `version`: Must be provided (Speckit requirement, cannot infer)
- `skillId`: Must exist in VPN-SKILLS catalog

### Optional Fields

- `platform`: If omitted, skill applies to all platforms
- `environment`: If omitted, skill applies to all environments
- `optional`: Defaults to `false` (hard dependency)
- `config`: Environment-specific overrides (implementation detail)
- `notes`: Free-text notes for operators

### Version Specification

Versions can be specified as:

1. **Exact version**: `"2.1.3"` — requires exact version
2. **Semver range (Caret)**: `"^2.1.3"` — allows `>=2.1.3 <3.0.0` (compatible minor/patch)
3. **Semver range (Tilde)**: `"~2.1.3"` — allows `>=2.1.3 <2.2.0` (compatible patch only)
4. **Range**: `">=2.0.0 <3.0.0"` — explicit range
5. **Latest**: `"*"` or `"latest"` — always fetch current version (use with caution; not recommended for prod)

**Best Practice**: Use exact versions or narrow ranges in production; use tilde (`~`) for minor flexibility.

---

## Validation via CLI

**Command**:
```bash
vpn-skills validate --manifest infra/skills.yaml --platform linux --environment prod
```

**Validation Checks**:

1. **Manifest syntax**: YAML is valid
2. **Required fields**: All required fields present
3. **Skill existence**: All skill IDs exist in VPN-SKILLS catalog
4. **Version resolution**: Version constraints can be satisfied (at least one version matches)
5. **Prerequisite satisfaction**: All transitive prerequisites can be satisfied
6. **Platform compatibility**: Selected platforms support the skills
7. **Deprecation check**: If `failOnDeprecated=true`, no deprecated skills are used
8. **Incompatibility check**: If `failOnIncompatible=true`, no incompatible versions are used

**Output on Success**:
```
✓ Manifest validation successful
  Skills: 3 | Validated: 3 | Warnings: 0 | Errors: 0
  Compliance: 100%
```

**Output on Failure**:
```
✗ Manifest validation failed
  Skills: 3 | Validated: 2 | Warnings: 0 | Errors: 1

Errors:
  1. Skill 'vpn-advanced-setup' version '^2.5.0' does not exist.
     Available versions: 3.0.0 (current), 2.5.1, 2.5.0 (deprecated)
     Recommendation: Update to '^3.0.0' or pin to '2.5.1'
```

---

## Example Manifests

### Example 1: Minimal (Dev Environment)

```yaml
version: "1.0"
projectId: "my-startup-api"

skills:
  - skillId: "vpn-client-setup"
    version: "latest"
```

### Example 2: Production (Multi-Environment)

```yaml
version: "1.0"
projectId: "order-service"
metadata:
  owner: "infrastructure-team"

skills:
  - skillId: "vpn-client-setup"
    version: "2.1.3"  # Pinned for reproducibility
    platform: ["linux"]
    environment: ["dev", "staging", "prod"]
    
  - skillId: "certificate-authority"
    version: "~1.2.0"
    platform: ["linux"]
    environment: ["staging", "prod"]  # Not in dev (uses self-signed)
    
  - skillId: "vpn-advanced-setup"
    version: "~2.5.0"
    platform: ["linux"]
    environment: ["prod"]  # Only in production
    optional: false
    notes: "High-availability VPN for multi-region failover"

compliance:
  validateOnCI: true
  failOnDeprecated: true
  failOnIncompatible: true
  reportFrequency: "daily"
```

### Example 3: Monorepo (Multiple Services)

```yaml
version: "1.0"
projectId: "platform"  # Monorepo identifier
metadata:
  description: "Shared VPN skills for all platform services"

skills:
  # Shared across all services
  - skillId: "vpn-client-setup"
    version: "2.1.3"
    platform: ["linux", "macos"]
    environment: ["dev", "staging", "prod"]

compliance:
  validateOnDeploy: true
  failOnIncompatible: true
```

---

## Integration with CI/CD

### GitHub Actions Example

```yaml
name: VPN Skills Compliance
on: [push, pull_request]

jobs:
  compliance:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install vpn-skills CLI
        run: |
          curl -sSL https://vpn-skills.org/install.sh | bash
          
      - name: Validate skills manifest
        run: |
          vpn-skills validate \
            --manifest infra/skills.yaml \
            --platform linux \
            --environment prod \
            --fail-on-deprecated
            
      - name: Generate compliance report
        if: success()
        run: |
          vpn-skills compliance \
            --project order-service \
            --output compliance-report.json
            
      - name: Upload compliance report
        uses: actions/upload-artifact@v3
        with:
          name: compliance-report
          path: compliance-report.json
```

---

## Migration from Old Practices

### Before (Ad-hoc, Local Copies)

```
project/
├── infra/
│   ├── vpn-client-setup/  # Local copy
│   │   ├── setup.sh
│   │   └── config.yaml
│   └── certificate-authority/  # Local copy
│       ├── ca.sh
│       └── config.yaml
```

**Problems**:
- Skills duplicated across projects
- Version synchronization manual
- No central deprecation tracking
- Compliance audits required manual inspection

### After (Remote Reference via skills.yaml)

```
project/
├── infra/
│   └── skills.yaml  # Single source of truth
└── .github/
    └── workflows/
        └── vpn-compliance.yml  # Automated validation
```

**Skills are fetched remotely from VPN-SKILLS on demand:**
- Validation: `vpn-skills validate`
- CI/CD: GitHub Actions runs validators
- Compliance: Automated daily scans

---

## Version Control Best Practices

1. **Commit skills.yaml with infrastructure code**:
   ```bash
   git add infra/skills.yaml
   git commit -m "Update VPN skills to v2.1.3 (fixes #123)"
   ```

2. **Link to release notes in commit message**:
   ```bash
   git commit -m "Update VPN skills to 2.1.3
   
   See release notes: https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/vpn-skills/releases/tag/v2.1.3
   Fixes: #123, #456"
   ```

3. **Use semantic commit messages**:
   ```
   feat: add vpn-advanced-setup for multi-region
   chore: upgrade vpn-client-setup from ~2.0 to ~2.1
   fix: pin certificate-authority to 1.2.1 (security fix)
   ```

4. **Tag deployments**:
   ```bash
   git tag -a v1.2.3-prod -m "Production release with VPN skills v2.1.3"
   ```

---

## FAQ

**Q: Can I use feature flags with skills?**

A: Yes, via the `featureFlags` section in the manifest. This allows gradual rollout of new skills to specific environments or user segments.

**Q: What if a skill has breaking changes?**

A: Use semver constraints (`^` vs `~`) to stay on compatible versions. The compliance report will flag breaking changes and provide migration paths.

**Q: Can I make a skill optional?**

A: Yes, set `optional: true` for soft dependencies. Validation will warn but not fail if the skill is unavailable.

**Q: How do I update a skill version?**

A: Edit `skills.yaml`, commit, and run `vpn-skills validate` in CI/CD. The compliance report will show the change and any warnings.

