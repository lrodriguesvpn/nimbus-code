# Data Model: Multi-Agent Integration (Claude Code + Antigravity)

## Entities

### SkillArtifact

Representa um único artefato `SKILL.md` (comando `/speckit-*` ou agente `/nc-*`)
em uma integração específica.

**Fields**
- `artifact_id`: identificador do comando/agente (ex.: `nc-builder`, `speckit-plan`)
- `artifact_type`: `speckit-command` ou `nc-agent`
- `source_path`: caminho da fonte de verdade (`.github/skills/<artifact_id>/SKILL.md` para `nc-agent`; gerido pelo `specify` CLI para `speckit-command`)
- `integration`: `copilot` · `claude` · `antigravity`
- `output_path`: caminho gerado (`.github/skills/`, `.claude/skills/` ou `.agents/skills/`)
- `post_processing_applied`: lista de transformações aplicadas (ex.: `argument-hint-injection`, `hook-command-dot-to-dash-note`)
- `content_hash`: hash do conteúdo funcional (usado pelo gate de paridade para detectar drift)

### IntegrationProfile

Representa as características de uma integração suportada.

**Fields**
- `integration_id`: `copilot` · `claude` · `antigravity`
- `root_folder`: `.github/skills/` · `.claude/skills/` · `.agents/skills/`
- `multi_install_safe`: boolean (`true` para copilot/claude, `false` para antigravity)
- `minimum_cli_version`: versão mínima do `specify` CLI exigida (ex.: `v1.20.5+` para antigravity, N/A para os demais)
- `managed_by`: `specify-cli` (para os 12 comandos `/speckit-*`) ou `sync-nc-agents-to-integrations.sh` (para os 9 agentes `/nc-*`)

### ParityCheckResult

Representa o resultado de uma execução do gate de paridade (`nc-agents-parity.bats`).

**Fields**
- `checked_at`: timestamp da execução
- `artifacts_compared`: contagem de agentes `/nc-*` comparados (esperado: 9)
- `integrations_compared`: lista das integrações comparadas (`copilot`, `claude`, `antigravity`)
- `drift_detected`: boolean
- `drift_details`: lista de `{artifact_id, integration, expected_hash, actual_hash}` quando `drift_detected = true`
- `status`: `pass` · `fail`

### WorktreeValidationRecord

Representa a validação isolada obrigatória da instalação do Antigravity antes
da promoção à branch principal (mitigação do risco R001 do `impact-map.md`).

**Fields**
- `worktree_path`: caminho do `git worktree` temporário usado
- `cli_version_confirmed`: versão do `specify` CLI validada (deve ser `>= v1.20.5`)
- `claude_files_unaffected`: boolean (confirmação de que `.claude/skills/` não foi alterado)
- `copilot_files_unaffected`: boolean (confirmação de que `.github/skills/` não foi alterado)
- `validated_by`: quem executou a validação (Dev responsável, conforme RACI do `spec.md`)
- `approved_for_main_branch`: boolean — só `true` após confirmação humana explícita

## Relationships

- Um `IntegrationProfile` possui N `SkillArtifact` (12 `speckit-command` + 9 `nc-agent` no total, quando totalmente sincronizado)
- Um `ParityCheckResult` referencia N `SkillArtifact` de diferentes `IntegrationProfile` para comparação
- Um `WorktreeValidationRecord` é obrigatório antes de qualquer `SkillArtifact` com `integration = antigravity` ser promovido para a branch principal

## Validation Rules

- Para todo `nc-agent`, o `content_hash` funcional (ignorando apenas o pós-processamento esperado por integração) deve ser idêntico entre `copilot`, `claude` e `antigravity` — divergência é `drift_detected = true`
- `WorktreeValidationRecord.approved_for_main_branch` nunca é `true` sem `claude_files_unaffected = true` **e** `copilot_files_unaffected = true` **e** `cli_version_confirmed` satisfazendo `>= v1.20.5`
- Nenhum `SkillArtifact` com `source_path` apontando para `.github/skills/nc-*` pode ser modificado por este fluxo — é somente leitura (fonte única de verdade)
