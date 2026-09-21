# Data Model — Native NC Agents

## AgentRole

Source: `.nimbus/agent-manifest.yaml`.

| Field | Type | Required | Validation |
|---|---|---:|---|
| `id` | string | yes | Stable NC role identifier |
| `name` | string | yes | Human-readable display name |
| `layer` | string | yes | Governance/architecture/delivery layer |
| `write_permission` | enum | yes | `read-only` or `read-write` |
| `allowed_file_scope` | list[string] | yes | At least one bounded path |
| `tool_allowlist` | list[string] | yes | No undeclared write tool |
| `human_approval_policy` | object | yes | References complexity approval matrix |

## AgentArtifact

Generated platform projection.

| Field | Type | Required | Validation |
|---|---|---:|---|
| `agent_id` | string | yes | Matches an `AgentRole` |
| `platform` | enum | yes | `vscode`, `claude`, `antigravity-bridge` |
| `path` | string | yes | Within approved destination |
| `frontmatter` | mapping | yes | Valid for target platform |
| `functional_body_hash` | SHA-256 | yes | Equal to source normalized body |

## State transitions

`source-updated -> generated -> parity-validated -> publishable`.

Any missing destination, invalid contract, or hash mismatch transitions the run
to `blocked`; it must not be represented as publishable.

## Relationships

- One `AgentRole` maps to zero or one artifact per supported platform.
- One source `SKILL.md` is the functional body input for its projections.
- One parity run validates all generated `AgentArtifact` projections.
