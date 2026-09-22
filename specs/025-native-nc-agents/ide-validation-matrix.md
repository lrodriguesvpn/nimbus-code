# Matriz de Validação Real por IDE Agêntica — Spec 025 (reabertura)

Evidência exigida pelo AC-8: em cada IDE, o orquestrador ou um agente NC-* foi
iniciado de fato, listou suas ferramentas e leu um arquivo do repositório.
Checagem estrutural (arquivo existe, hash bate) **não** conta como evidência.

| IDE | Versão | Superfície testada | Data | Quem testou | Resultado | Evidência |
|---|---|---|---|---|---|---|
| Claude Code | | subagente `nc-critic`; skill `/nimbus` | | | ⏳ pendente (T031) | |
| Kiro IDE | | custom agent `nc-critic` | | | ❌ defeito conhecido (T032/T033) | research.md, Decision 5 |
| Kiro CLI | | custom agent `nc-critic` | | | ⏳ pendente (T033) | |
| Cursor | | skill `/nc-critic`; `.cursor/agents/` | | | ⏳ pendente (T034) | |
| Antigravity | | skill `/nc-critic` | | | ⏳ pendente (T035) | |
| VS Code / Copilot | | agente `@nimbus` | | | ⏳ pendente (T036) | |

## Registro de 2026-09-22 (antes da correção)

- **Claude Code 2.1.x**: iniciar `nc-critic` retornou `Agent 'nc-critic' would be
  spawned with zero tools — refusing ... unrecognized [view, rg, glob, bash,
  apply_patch, skill:nc-critic]`. Corrigido pela T028; falta a confirmação em
  sessão nova (T031).
