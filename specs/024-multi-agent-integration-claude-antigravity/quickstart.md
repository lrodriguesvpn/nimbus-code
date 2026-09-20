# Quickstart: Validar Multi-Agent Integration (Claude Code + Antigravity)

## Purpose

Validar que os 12 comandos `/speckit-*` e os 9 agentes `/nc-*` estão
disponíveis e funcionais em Claude Code e Antigravity, sem regressão no fluxo
Copilot já existente.

## Prerequisites

- [spec.md](./spec.md) completo
- [plan.md](./plan.md) completo
- [research.md](./research.md) completo
- [data-model.md](./data-model.md) completo
- [contracts/nc-agent-sync.contract.md](./contracts/nc-agent-sync.contract.md) completo
- [graph.yaml](./graph.yaml) e [graph.md](./graph.md) completos
- [impact-map.md](./impact-map.md) completo
- CLI `specify` instalado em versão `>= v1.20.5` (obrigatório para Antigravity)

## Validation Scenarios (AC-mapped)

### V1: Instalação de Claude Code não afeta Copilot (AC-1)

**Scenario**: Repositório já tem `.github/skills/` funcional (Copilot).

**Validation steps**:
1. Rodar `specify integration install claude`.
2. Confirmar que `.claude/skills/speckit-*/SKILL.md` existe para os 12 comandos.
3. Rodar `git diff --stat .github/skills/` — deve retornar vazio (nenhuma
   alteração).
4. **Assertion**: os 12 comandos existem em Claude com conteúdo funcional
   equivalente ao Copilot, e `.github/skills/` permanece intocado.

### V2: Sync dos 9 agentes NC-* para Claude Code (AC-2)

**Scenario**: os 9 agentes `/nc-*` existem hoje só em `.github/skills/`.

**Validation steps**:
1. Rodar `scripts/sync-nc-agents-to-integrations.sh --target claude`.
2. Confirmar que `.claude/skills/nc-*/SKILL.md` existe para os 9 agentes.
3. Verificar que cada arquivo gerado tem `argument-hint:` no frontmatter.
4. **Assertion**: os 9 agentes existem em Claude com o mesmo conteúdo
   institucional (incl. blocos de ALIAS) da fonte, mais o `argument-hint`.

### V3: Instalação isolada de Antigravity antes da branch principal (AC-3)

**Scenario**: Antigravity não é `multi_install_safe` e exige CLI `>= v1.20.5`.

**Validation steps**:
1. Criar um `git worktree` isolado: `git worktree add ../nimbus-agy-validation`.
2. Rodar `specify --version` — confirmar `>= v1.20.5`.
3. Rodar `specify integration install agy` **dentro do worktree isolado**.
4. Confirmar que o CLI emite o aviso de versão mínima (mesmo que já satisfeita).
5. Rodar `git diff --stat .claude/ .github/skills/` dentro do worktree — deve
   retornar vazio.
6. Só após essa validação, replicar os artefatos gerados (`.agents/skills/`)
   na branch principal da sessão.
7. **Assertion**: os 12 comandos existem em `.agents/skills/` após promoção, e
   nenhum arquivo de Claude/Copilot foi alterado em nenhum momento do processo.

### V4: Sync dos 9 agentes NC-* para Antigravity (AC-4)

**Validation steps**:
1. Rodar `scripts/sync-nc-agents-to-integrations.sh --target antigravity`.
2. Confirmar que `.agents/skills/nc-*/SKILL.md` existe para os 9 agentes.
3. Verificar a nota de conversão `.`→`-` em nomes de comando de hook no
   conteúdo gerado.
4. **Assertion**: os 9 agentes existem em Antigravity com a mesma
   transformação aplicada aos 12 comandos nativos.

### V5: Gate de paridade bloqueia drift entre as 3 pastas (AC-5)

**Validation steps**:
1. Editar manualmente `.github/skills/nc-shield/SKILL.md` (qualquer mudança de
   conteúdo).
2. **Sem** rodar o script gerador, executar `bats
   tests/multi-agent-integration/nc-agents-parity.bats`.
3. **Assertion**: o teste falha, apontando explicitamente `nc-shield` e o(s)
   destino(s) desatualizado(s) (`claude` e/ou `antigravity`).
4. Rodar `scripts/sync-nc-agents-to-integrations.sh --target all` e reexecutar
   o teste — deve passar.

### V6: Manual do dev documenta as 3 integrações (AC-6)

**Validation steps**:
1. Abrir `docs/developer-guide.md`.
2. Localizar a seção "Agentes disponíveis por integração".
3. **Assertion**: a seção lista os 12 comandos + 9 agentes para Copilot,
   Claude e Antigravity, e descreve explicitamente a diferença de risco
   (`multi_install_safe: true` para Claude vs `false` para Antigravity).

## Rollback Validation

Após qualquer cenário acima, confirmar que `git revert <commit>` remove
apenas os artefatos da integração afetada, sem impactar as demais — ver
"Plano de Rollback Global" em [impact-map.md](./impact-map.md).
