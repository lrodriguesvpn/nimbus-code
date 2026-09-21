# Native Agent Synchronization Contract

## Source

- Functional source: `.github/skills/nc-*/SKILL.md`
- Governance source: `.nimbus/agent-manifest.yaml`
- Source files are read-only inputs to generation.

## Outputs

| Platform | Destination | Contract |
|---|---|---|
| VS Code/Copilot | `.github/agents/nc-*.agent.md` | VS Code custom agent Markdown/frontmatter |
| Claude Code | `.claude/agents/nc-*.md` | Claude Code project subagent Markdown/frontmatter |
| Antigravity | `.agents/skills/nc-*/SKILL.md` | Existing verified skills bridge |
| Legacy bridge | `.github/skills/nc-*/SKILL.md` | Existing command/skill surface |

## Invariants

1. Every generated artifact maps to exactly one manifest role and source skill.
2. Functional body hashes are equal after documented normalization.
3. Platform-specific frontmatter may differ only where the platform contract
   requires it.
4. Missing, extra, stale, or unsupported destinations are errors.
5. Generation is deterministic and idempotent.
6. The generator never removes source skills or legacy bridges.

## Unsupported platform behavior

If an official Antigravity native-agent contract is not available, the generator
must retain the skills bridge and report that no native projection is attempted.
It must not create `.agents/agents/` speculatively.
