# VS Code Custom Agent Contract

> **ADL — Single-orchestrator pivot (post-#479 review):** VS Code's Copilot
> Chat agent picker becomes cluttered when it lists all 15 NC roles as
> separate `@agent` entries. For this platform only, the generator emits a
> **single** orchestrator agent, `@nimbus` (`.github/agents/nimbus.agent.md`),
> whose body is rendered from a static template
> (`scripts/lib/templates/nimbus-agent.template.md`) plus a generated coverage
> table listing every NC role and its `/nc-*` command. `@nimbus` triages the
> developer into Bug/Fix, Nova Spec, or Ideação and internally delegates to
> the 15 `/nc-*` skills — it does not replace them. Claude Code and
> Antigravity are unaffected: they continue to receive one native
> file per role (see `claude-subagent.contract.md`). No `nc-*.agent.md`
> files may exist under `.github/agents/`; the generator actively removes
> stale ones and `check --target vscode` fails if any are found.

## Required shape

- File extension: `.agent.md`
- Workspace directory: `.github/agents/`
- Exactly one file: `nimbus.agent.md` (`name: nimbus`).
- YAML frontmatter followed by Markdown instructions.
- `name` and `description` identify the agent to the picker.
- `tools` must be a subset of the **union** of every NC role's manifest
  allowlist (the orchestrator can delegate to any of the 15 roles) and may
  not broaden that union.
- The body must reference every NC role's `/nc-*` command at least once
  (coverage check), so the triage menu never silently drops a role.

## Optional shape

- `handoffs` may be generated only from explicitly declared transitions.
- Platform-specific argument hints may be included without changing the
  functional body.

## Source

https://code.visualstudio.com/docs/agent-customization/custom-agents
