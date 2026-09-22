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

## Decision 5 — Reabertura: nomes de ferramenta por plataforma (2026-09-22)

**Decision:** o gerador traduz `tool_allowlist` (nomes do Copilot) para os nomes
de cada plataforma. Claude já traduzido nesta reabertura; Kiro pendente (T032).

**Evidência — Claude Code:** iniciar `nc-critic` retornou
`Agent 'nc-critic' would be spawned with zero tools — refusing ... unrecognized
[view, rg, glob, bash, apply_patch, skill:nc-critic]`.

**Evidência — Kiro** (pesquisa de 2026-09-22, sem teste em instalação real):

- Custom agents: `.kiro/agents/<name>.md` ou `.json`, mesmos campos
  (https://kiro.dev/docs/custom-agents/configuration-reference/).
- Na IDE, um único nome de ferramenta não reconhecido descarta o agente inteiro
  sem aviso visível; só aparece `profile.load.failed reasonCode: "invalid_config"`
  em log de debug (https://github.com/kirodotdev/Kiro/issues/11411).
- A IDE 1.1.14 aceita `fs_read`, `fs_write`, `shell`, `web_fetch`, `web_search`,
  `subagent`, `skill`, entre outros, e recusa `read`, `write`, `glob`, `grep`,
  embora documentados (mesma issue; documentação em
  https://kiro.dev/docs/reference/built-in-tools/).
- Skills no Kiro ficam em `.kiro/skills/<nome>/SKILL.md` e precisam ser
  referenciadas em `resources: ["skill://..."]` do agente; não existe
  `skill:<nome>` em `tools` (https://kiro.dev/docs/skills/).
- O registro da CLI v3 ignora agente sem `permissions.rules`; basta um array
  vazio (https://github.com/kirodotdev/Kiro/issues/10733).

| Copilot | Kiro proposto | Confiança |
|---|---|---|
| `view` | `fs_read` | Alta |
| `rg`, `glob` | omitir (coberto por `fs_read` na IDE) | Média |
| `bash` | `shell` | Alta |
| `apply_patch` | `fs_write` | Alta |
| `web_fetch` | `web_fetch` | Alta |
| `sql` | remover | Alta |
| `skill:<nome>` | `resources: ["skill://.kiro/skills/<nome>/SKILL.md"]` (exige gerar `.kiro/skills/`) | Média |

**Não confirmado:** se a CLI 3.x derruba o agente inteiro ou só a ferramenta; se
a IDE atual lê `.md`; se `fs_read`/`fs_write` seguem válidos após o conserto da
#11411. Por isso T032 exige teste em instalação real.

**Cursor:** tem subagentes nativos em `.cursor/agents/*.md` (campos `name`,
`description`, `model`, `readonly`, `is_background`, sem `tools`) e também lê
`.claude/agents/` (https://cursor.com/docs/subagents). Hoje o repo projeta os
NC-* para o Cursor só como skills. Avaliar em T034.

