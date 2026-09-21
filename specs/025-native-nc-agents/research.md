# Research — Native NC Agents

## Decision 1 — VS Code/Copilot native custom agents

**Decision:** Generate Markdown custom agent files with `.agent.md` extension
under `.github/agents/`.

**Rationale:** Current VS Code documentation defines custom agents as Markdown
files, supports workspace agents in `.github/agents`, and documents frontmatter
for description, name, tools and handoffs. This matches the requested native
picker/delegation experience.

**Alternatives considered:** Keep only `.github/skills/` (backward-compatible
but not native); generate `AGENTS.md` (repository instructions, not a selectable
custom agent).

**Source:** VS Code custom agents documentation:
https://code.visualstudio.com/docs/agent-customization/custom-agents

## Decision 2 — Claude Code native subagents

**Decision:** Generate Markdown subagents under `.claude/agents/`, with Claude
frontmatter adapted from the same source content and manifest controls.

**Rationale:** Claude Code documents project subagents in `.claude/agents` with
independent context, descriptions and tool/permission controls. A native
subagent is materially different from a skill, so the adapter must preserve
functional content while mapping metadata explicitly.

**Alternatives considered:** Copy only `.claude/skills/` (does not provide native
subagent delegation); put agents in user-level `~/.claude/agents` (not
repository-portable).

**Source:** Claude Code subagents documentation:
https://code.claude.com/docs/en/sub-agents

## Decision 3 — Antigravity surface

**Decision:** Keep `.agents/skills/nc-*/SKILL.md` as the supported bridge until a
repository-verifiable native agent contract is available.

**Rationale:** The repository has an existing tested Antigravity skills
integration but no verified `.agents/agents` contract. Inventing a directory or
frontmatter format would produce false success and violate the explicit failure
requirement.

**Alternatives considered:** Generate `.agents/agents` speculatively (rejected);
remove Antigravity support (rejected because it breaks existing users).

## Decision 4 — Canonical governance manifest

**Decision:** Extend `.nimbus/agent-manifest.yaml` rather than add
`.nimbus/agents.yaml`.

**Rationale:** The existing manifest already contains role identity, scopes,
tool allowlists and approval matrices. Duplicating it would create exactly the
drift this feature is intended to prevent.

**Alternatives considered:** Separate platform metadata manifest (rejected until
the existing manifest cannot represent a required field; any such gap becomes a
new ADL).

