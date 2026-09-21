# Claude Code Subagent Contract

## Required shape

- File location: `.claude/agents/`
- Markdown file with Claude Code subagent frontmatter.
- `name`/description identify the delegation target.
- Tool and permission fields must be constrained by `.nimbus/agent-manifest.yaml`.

## Invariants

- The subagent body remains functionally equivalent to the source NC skill.
- Project-local artifacts are generated in-repository, not in a developer home
  directory.
- No subagent may bypass the S3/S4 human approval policy.

## Source

https://code.claude.com/docs/en/sub-agents
