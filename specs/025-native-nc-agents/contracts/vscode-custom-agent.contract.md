# VS Code Custom Agent Contract

## Required shape

- File extension: `.agent.md`
- Workspace directory: `.github/agents/`
- YAML frontmatter followed by Markdown instructions.
- `name` and `description` identify the agent to the picker.
- `tools` must be derived from the manifest allowlist and may not broaden it.

## Optional shape

- `handoffs` may be generated only from explicitly declared transitions.
- Platform-specific argument hints may be included without changing the
  functional body.

## Source

https://code.visualstudio.com/docs/agent-customization/custom-agents
