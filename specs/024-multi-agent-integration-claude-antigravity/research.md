# Research: Multi-Agent Integration (Claude Code + Antigravity)

## Objective

Resolver as decisões técnicas necessárias para levar os 12 comandos `/speckit-*`
e os 9 agentes `/nc-*` do Nimbus Code (hoje só em Copilot) para Claude Code e
Antigravity, sem alterar nada do que já existe para Copilot.

## Decisions

### 1) Os 12 comandos `/speckit-*` já são geridos automaticamente pelo `specify` CLI

**Decision**: não escrever nenhum script novo para os 12 comandos agnósticos —
usar `specify integration install claude` e `specify integration install agy`,
que já geram `.claude/skills/speckit-*/SKILL.md` e `.agents/skills/speckit-*/SKILL.md`
a partir da mesma fonte de templates do CLI, aplicando o pós-processamento
específico de cada integração automaticamente.

**Rationale**: investigação do código-fonte do `specify_cli` (instalado via
`uv`, em `~/.cache/uv/archive-v0/.../specify_cli/integrations/`) confirmou que
`ClaudeIntegration` e `AgyIntegration` são ambas subclasses de
`SkillsIntegration` — o mesmo mecanismo que já gera `.github/skills/` para
Copilot. Reescrever isso manualmente seria retrabalho puro e criaria uma
segunda fonte de verdade para os 12 comandos, divergindo do próprio CLI oficial.

**Alternatives considered**:
- Escrever manualmente os 12 `SKILL.md` para cada integração nova (rejeitado:
  duplica o que o CLI já resolve, e diverge silenciosamente a cada atualização
  do `specify`)
- Fazer fork do `specify_cli` para customizar a geração (rejeitado: overhead de
  manutenção desnecessário para um mecanismo que já funciona out-of-the-box)

### 2) Os 9 agentes `/nc-*` precisam de um script gerador próprio (não são geridos pelo CLI)

**Decision**: criar `scripts/sync-nc-agents-to-integrations.sh`, que lê
`.github/skills/nc-*/SKILL.md` (fonte única de verdade, mantida como está hoje)
e emite cópias transformadas para `.claude/skills/nc-*/SKILL.md` e
`.agents/skills/nc-*/SKILL.md`, replicando o mesmo pós-processamento que o
`specify` CLI aplica aos 12 comandos nativos:
- Claude: injeta `argument-hint:` no frontmatter YAML.
- Antigravity: injeta nota de conversão `.`→`-` em nomes de comando de hook
  (mesma função `_inject_hook_command_note` observada no `AgyIntegration`).

**Rationale**: os agentes `/nc-*` são customização institucional exclusiva
deste template — não existem no `specify_cli` upstream, então não há mecanismo
automático que os replique. Um script gerador único, seguindo o mesmo padrão
observado no CLI oficial, garante paridade de comportamento sem introduzir um
formato novo.

**Alternatives considered**:
- Symlinks entre `.github/skills/nc-*` e as outras pastas (rejeitado: alguns
  ambientes/CI não preservam symlinks de forma confiável entre diferentes SOs,
  e cada integração precisa de pós-processamento diferente no conteúdo, não só
  uma cópia idêntica)
- Manter os 9 agentes só em Copilot e não portá-los (rejeitado: contraria
  explicitamente o pedido do usuário de portar "todos os agentes também")

### 3) Antigravity exige validação isolada antes de ir para a branch principal

**Decision**: a instalação `specify integration install agy` roda primeiro em
um `git worktree` isolado; só após confirmar que nenhum arquivo de `.claude/`
ou `.github/skills/` foi alterado, e que a versão do CLI é `v1.20.5+`, os
artefatos resultantes são trazidos para a branch principal desta sessão.

**Rationale**: `AgyIntegration` não declara `multi_install_safe = True` (herda
`False` da classe base) — ao contrário de `ClaudeIntegration`, que declara
explicitamente `multi_install_safe = True`. O próprio `AgyIntegration.setup()`
emite um `click.secho` de aviso amarelo sobre a versão mínima exigida, mas não
bloqueia a execução — a responsabilidade de mitigar o risco é do processo, não
do CLI.

**Alternatives considered**:
- Instalar direto na branch principal e reverter se falhar (rejeitado: risco
  desnecessário de regressão temporária nas integrações já funcionais)
- Não suportar Antigravity nesta feature (rejeitado: contraria pedido explícito
  do usuário — mas o worktree isolado permite adiar apenas essa parte do
  escopo, sem bloquear a entrega de Claude Code, se a validação falhar)

### 4) Gate de paridade como mecanismo único de "observabilidade" desta feature

**Decision**: em vez de logs/métricas de runtime (que não fazem sentido para
tooling estático de dev), o controle de qualidade contínuo é um teste `bats`
(`tests/multi-agent-integration/nc-agents-parity.bats`) que compara o conteúdo
funcional dos 9 agentes `/nc-*` nas 3 pastas (`.github/skills/`,
`.claude/skills/`, `.agents/skills/`), rodando bloqueante no CI via
`.github/workflows/nc-agents-parity-check.yml`.

**Rationale**: reaproveita o padrão já usado por `tests/platform/*.bats` e
`tests/bootstrap/*.bats` (SPEC 008/020) — mesmo framework, mesma convenção de
nomeação de gate — em vez de inventar um mecanismo de observabilidade novo para
um domínio que não tem runtime.

**Alternatives considered**:
- Verificação manual periódica pelo Dev (rejeitado: não escalável, sujeito a
  esquecimento — exatamente o padrão de erro coberto por HRN-0003/HRN-0002)
- Hook de pre-commit local apenas (rejeitado: não bloqueia PRs de outras
  máquinas/CI, insuficiente como gate institucional)

## Open Questions

Nenhuma — a spec.md já resolveu o escopo (12 comandos + 9 agentes, Claude Code
+ Antigravity) e a investigação técnica documentada acima cobre as decisões de
implementação. Nenhum `[NEEDS CLARIFICATION]` pendente nesta fase.
