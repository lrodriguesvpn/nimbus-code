# Contract: NC-Agent Sync (Claude Code + Antigravity)

**Script**: `scripts/sync-nc-agents-to-integrations.sh`

## Purpose

Contrato do script gerador que sincroniza os 9 agentes institucionais `/nc-*`
de `.github/skills/` (fonte única de verdade) para `.claude/skills/` e
`.agents/skills/`, aplicando o pós-processamento equivalente ao que o próprio
`specify` CLI já aplica aos 12 comandos `/speckit-*` nativos.

## Input

- **Fonte**: `.github/skills/nc-*/SKILL.md` (os 9 agentes: `nc-intake`,
  `nc-spec`, `nc-critic`, `nc-governor`, `nc-arch`, `nc-qa`, `nc-builder`,
  `nc-shield`, `nc-telemetry`)
- **Destinos**: `--target claude` (`.claude/skills/`), `--target antigravity`
  (`.agents/skills/`), ou `--target all` (ambos)
- Cada `SKILL.md` de entrada segue o formato Markdown com frontmatter YAML já
  usado pelos demais artefatos deste template

## Output

Para `--target claude`:
- `.claude/skills/nc-<agente>/SKILL.md` com o mesmo conteúdo funcional da
  fonte, mais o campo `argument-hint:` injetado no frontmatter (mesmo padrão
  aplicado pelo `ClaudeIntegration.post_process_skill_content` do `specify` CLI
  para os 12 comandos nativos)

Para `--target antigravity`:
- `.agents/skills/nc-<agente>/SKILL.md` com o mesmo conteúdo funcional da
  fonte, mais a nota de conversão `.`→`-` em nomes de comando de hook injetada
  (mesma função `_inject_hook_command_note` do `AgyIntegration` do `specify`
  CLI)

## Behavior Contract

1. **Idempotência**: rodar o script múltiplas vezes sem alterações na fonte
   produz saída idêntica (nenhum diff espúrio).
2. **Somente leitura na fonte**: o script nunca escreve em
   `.github/skills/nc-*/SKILL.md` — apenas lê.
3. **Falha explícita**: se um dos 9 agentes esperados não existir na fonte, o
   script falha com mensagem indicando qual agente está ausente (não falha
   silenciosamente nem gera saída parcial sem aviso).
4. **Isolamento por destino**: uma falha ao gerar para `--target antigravity`
   não impede nem corrompe a geração já feita para `--target claude` (e
   vice-versa).
5. **Exit codes**: `0` em sucesso completo; `1` se algum agente não pôde ser
   sincronizado para algum destino solicitado.

## Test Coverage (mapeado nos ACs de spec.md)

| AC | Comportamento validado |
|---|---|
| AC-2 | Saída para `--target claude` contém os 9 agentes com `argument-hint` aplicado |
| AC-4 | Saída para `--target antigravity` contém os 9 agentes com nota de conversão de hook aplicada |
| AC-5 | Se a fonte mudar sem re-rodar o script, o gate de paridade (`nc-agents-parity.bats`) detecta e falha |

## Non-Goals

- Este contrato **não** cobre os 12 comandos `/speckit-*` — esses são geridos
  integralmente por `specify integration install claude|agy`, sem script
  próprio deste template (ver `research.md`, decisão 1).
- Este contrato **não** cobre a instalação inicial do CLI `specify` em si, nem
  a validação de versão do Antigravity — isso é coberto pelo processo manual
  descrito no Security & DevSecOps Gate do `plan.md` (worktree isolado).
