---

description: "Task list for Multi-Agent Integration (Claude Code + Antigravity)"
---

# Tasks: Multi-Agent Integration (Claude Code + Antigravity)

**Input**: Design documents from `specs/024-multi-agent-integration-claude-antigravity/`
**Prerequisites**: [plan.md](./plan.md) (completo), [spec.md](./spec.md) (6 ACs), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/nc-agent-sync.contract.md](./contracts/nc-agent-sync.contract.md), [quickstart.md](./quickstart.md), [impact-map.md](./impact-map.md)

**Tests**: Incluídos — o gate de paridade (bats) é um requisito funcional explícito (FR-004, AC-5), não opcional.

**Organization**: Tasks agrupadas por User Story (P1 Claude → P2 Antigravity isolado → P3 gate de paridade contínuo), permitindo entrega incremental.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode rodar em paralelo (arquivos diferentes, sem dependência de tasks incompletas)
- **[Story]**: US1 (Claude), US2 (Antigravity isolado), US3 (gate de paridade)
- Caminhos de arquivo exatos incluídos em cada descrição

## Path Conventions

Projeto de automação/tooling de repositório (não app com camadas model/service/API) — segue a estrutura já usada por SPEC 008/SPEC 020:
- `scripts/` — script gerador novo
- `.claude/skills/`, `.agents/skills/` — saída gerada
- `tests/multi-agent-integration/` — teste de paridade novo
- `.github/workflows/` — gate de CI novo
- `docs/developer-guide.md` — atualização de documentação

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Preparar a estrutura de diretórios e dependências de ferramenta compartilhadas por todas as user stories

- [ ] T001 Confirmar versão do CLI `specify` instalada (`specify --version`) e documentar o resultado no início do log de execução da feature; se `< v1.20.5`, atualizar antes de prosseguir (bloqueante apenas para US2/Antigravity, não para US1/Claude)
- [ ] T002 [P] Criar diretório `tests/multi-agent-integration/` (novo, paralelo a `tests/platform/` e `tests/bootstrap/` já existentes)
- [ ] T003 [P] Criar esqueleto do script `scripts/sync-nc-agents-to-integrations.sh` com shebang, `set -euo pipefail`, parsing de `--target claude|antigravity|all` e mensagem de uso (`--help`), sem lógica de sync ainda

**Checkpoint**: Estrutura básica pronta — nenhuma user story ainda implementada

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Infraestrutura central que TODAS as user stories dependem (leitura da fonte única, helpers de hash/paridade)

**⚠️ CRITICAL**: Nenhuma user story pode começar antes desta fase estar completa

- [ ] T004 Implementar em `scripts/sync-nc-agents-to-integrations.sh` a função de descoberta da fonte única: listar os 9 agentes em `.github/skills/nc-*/SKILL.md` (`nc-intake`, `nc-spec`, `nc-critic`, `nc-governor`, `nc-arch`, `nc-qa`, `nc-builder`, `nc-shield`, `nc-telemetry`) e falhar explicitamente (exit `1`) se algum estiver ausente (contrato: "Falha explícita")
- [ ] T005 Implementar em `scripts/sync-nc-agents-to-integrations.sh` a função de cópia de conteúdo funcional (frontmatter + corpo) da fonte para um caminho de destino genérico, preservando o conteúdo institucional (blocos de ALIAS, reforços de governança) sem modificação
- [ ] T006 [P] Implementar helper de hash de conteúdo funcional (ex.: `sha256sum` do corpo normalizado, ignorando apenas o pós-processamento esperado por integração) reutilizável tanto pelo script de sync quanto pelo teste de paridade — usado para popular `content_hash` de `SkillArtifact` ([data-model.md](./data-model.md))
- [ ] T007 Garantir que `scripts/sync-nc-agents-to-integrations.sh` nunca escreve em `.github/skills/nc-*/SKILL.md` (contrato: "Somente leitura na fonte") — adicionar guard/comentário explícito e teste manual de verificação (`git diff --stat .github/skills/` vazio após qualquer execução)

**Checkpoint**: Fundação pronta — leitura da fonte única, hashing e escrita segura disponíveis para as user stories

---

## Phase 3: User Story 1 - Dev usa Claude Code com paridade total ao Copilot (Priority: P1) 🎯 MVP

**Goal**: Um dev consegue instalar a integração Claude Code e usar os 12 comandos `/speckit-*` + os 9 agentes `/nc-*` sem alterar nada do Copilot.

**Independent Test**: Rodar `specify integration install claude` em um clone do template, confirmar que os 12 comandos e os 9 agentes NC-* aparecem em `.claude/skills/`, e que `.github/skills/` permanece intocado ([quickstart.md](./quickstart.md) V1/V2).

### Tests for User Story 1 ⚠️

- [ ] T008 [P] [US1] Escrever teste `test_AC1_claude_speckit_commands_installed` em `tests/multi-agent-integration/nc-agents-parity.bats` (bloco inicial do arquivo): após `specify integration install claude`, os 12 `.claude/skills/speckit-*/SKILL.md` existem e `git diff --stat .github/skills/` é vazio
- [ ] T009 [P] [US1] Escrever teste `test_AC2_nc_agents_synced_to_claude` em `tests/multi-agent-integration/nc-agents-parity.bats`: após `scripts/sync-nc-agents-to-integrations.sh --target claude`, os 9 `.claude/skills/nc-*/SKILL.md` existem, contêm `argument-hint:` no frontmatter, e têm `content_hash` funcional idêntico à fonte

### Implementation for User Story 1

- [ ] T010 [US1] Rodar `specify integration install claude` no repositório e confirmar instalação dos 12 comandos `/speckit-*` em `.claude/skills/` (gerenciado nativamente pelo CLI — nenhum código novo aqui, apenas execução e verificação, conforme `research.md` decisão 1)
- [ ] T011 [US1] Implementar em `scripts/sync-nc-agents-to-integrations.sh` a lógica específica de `--target claude`: para cada um dos 9 agentes, gerar `.claude/skills/nc-<agente>/SKILL.md` injetando o campo `argument-hint:` no frontmatter (mesmo padrão do `ClaudeIntegration.post_process_skill_content` do `specify` CLI, conforme `contracts/nc-agent-sync.contract.md`)
- [ ] T012 [US1] Rodar `scripts/sync-nc-agents-to-integrations.sh --target claude` e confirmar manualmente (via `quickstart.md` V2) que os 9 `.claude/skills/nc-*/SKILL.md` foram gerados corretamente, preservando os blocos de ALIAS e reforços de governança do conteúdo institucional
- [ ] T013 [US1] Rodar `bats tests/multi-agent-integration/nc-agents-parity.bats -f "AC1|AC2"` e confirmar que T008/T009 passam
- [ ] T014 [P] [US1] Commitar `.claude/skills/` (12 comandos + 9 agentes) no repositório

**Checkpoint**: US1 completa — Claude Code tem paridade total com Copilot (comandos + agentes), sem alterar nenhum arquivo do Copilot. MVP entregável.

---

## Phase 4: User Story 2 - Dev avalia Antigravity de forma isolada e segura (Priority: P2)

**Goal**: Antigravity instalado e validado em worktree isolado, com promoção à branch principal só após aprovação humana explícita — sem risco para Copilot/Claude.

**Independent Test**: Rodar `specify integration install agy` em worktree isolado, confirmar aviso de versão mínima e que nenhum arquivo de outra integração muda ([quickstart.md](./quickstart.md) V3/V4).

### Tests for User Story 2 ⚠️

- [ ] T015 [P] [US2] Escrever teste `test_AC3_agy_isolated_install_validated` em `tests/multi-agent-integration/nc-agents-parity.bats`: após instalação em worktree isolado, os 12 `.agents/skills/speckit-*/SKILL.md` existem e `git diff --stat .claude/ .github/skills/` (dentro do worktree) é vazio
- [ ] T016 [P] [US2] Escrever teste `test_AC4_nc_agents_synced_to_agy` em `tests/multi-agent-integration/nc-agents-parity.bats`: após `scripts/sync-nc-agents-to-integrations.sh --target antigravity`, os 9 `.agents/skills/nc-*/SKILL.md` existem e contêm a nota de conversão `.`→`-` em nomes de comando de hook

### Implementation for User Story 2

- [ ] T017 [US2] Criar worktree isolado (`git worktree add ../nimbus-agy-validation`) e, dentro dele, confirmar `specify --version >= v1.20.5` (bloqueia com aviso claro se a versão for insuficiente, conforme Edge Case do `spec.md` e `WorktreeValidationRecord.cli_version_confirmed`)
- [ ] T018 [US2] Dentro do worktree isolado, rodar `specify integration install agy` e confirmar que emite aviso claro de versão mínima e instala os 12 comandos `/speckit-*` em `.agents/skills/`
- [ ] T019 [US2] Implementar em `scripts/sync-nc-agents-to-integrations.sh` a lógica específica de `--target antigravity`: para cada um dos 9 agentes, gerar `.agents/skills/nc-<agente>/SKILL.md` injetando a nota de conversão `.`→`-` em nomes de comando de hook (mesma função `_inject_hook_command_note` do `AgyIntegration` do `specify` CLI, conforme `contracts/nc-agent-sync.contract.md`)
- [ ] T020 [US2] Dentro do worktree isolado, rodar `scripts/sync-nc-agents-to-integrations.sh --target antigravity` e confirmar (via `quickstart.md` V3/V4) que `.claude/` e `.github/skills/` permanecem intocados durante todo o processo
- [ ] T021 [US2] Preencher um `WorktreeValidationRecord` (conforme `data-model.md`): `worktree_path`, `cli_version_confirmed`, `claude_files_unaffected=true`, `copilot_files_unaffected=true`, `validated_by` — e obter aprovação humana explícita (`approved_for_main_branch=true`) antes do próximo passo (RACI do `spec.md`: Tech lead)
- [ ] T022 [US2] Após aprovação humana, promover os artefatos `.agents/skills/` (12 comandos + 9 agentes) gerados no worktree isolado para a branch principal da sessão; remover o worktree temporário (`git worktree remove`)
- [ ] T023 [US2] Rodar `bats tests/multi-agent-integration/nc-agents-parity.bats -f "AC3|AC4"` na branch principal e confirmar que T015/T016 passam
- [ ] T024 [P] [US2] Commitar `.agents/skills/` (12 comandos + 9 agentes) no repositório

**Checkpoint**: US2 completa — Antigravity disponível na branch principal, validado com segurança em ambiente isolado e aprovação humana registrada.

---

## Phase 5: User Story 3 - CI impede drift entre as três integrações (Priority: P3)

**Goal**: Nenhuma edição futura de um agente NC-* pode ficar desalinhada entre `.github/skills/`, `.claude/skills/` e `.agents/skills/` sem ser detectada.

**Independent Test**: Editar um `SKILL.md` de agente NC-* em apenas uma pasta e confirmar que o teste de paridade falha, apontando exatamente o agente/destino divergente ([quickstart.md](./quickstart.md) V5).

### Tests for User Story 3 ⚠️

- [ ] T025 [US3] Escrever teste `test_AC5_nc_agents_parity_gate` em `tests/multi-agent-integration/nc-agents-parity.bats`: compara `content_hash` dos 9 agentes entre as 3 pastas e falha apontando explicitamente `{artifact_id, integration}` divergente quando há drift (usa o helper de hash de T006 e a estrutura `ParityCheckResult` de `data-model.md`)

### Implementation for User Story 3

- [ ] T026 [US3] Validar manualmente o cenário de drift (`quickstart.md` V5): editar `.github/skills/nc-shield/SKILL.md`, rodar o teste de paridade sem re-sincronizar e confirmar falha bloqueante apontando `nc-shield` e o(s) destino(s) desatualizado(s); depois rodar `scripts/sync-nc-agents-to-integrations.sh --target all` e confirmar que o teste volta a passar
- [ ] T027 [US3] Criar `.github/workflows/nc-agents-parity-check.yml`: workflow de CI que roda `bats tests/multi-agent-integration/nc-agents-parity.bats` em todo PR que altera `.github/skills/nc-*/`, `.claude/skills/nc-*/`, `.agents/skills/nc-*/` ou `scripts/sync-nc-agents-to-integrations.sh`, bloqueando o merge em caso de falha (gate de paridade, FR-004)
- [ ] T028 [P] [US3] Commitar `tests/multi-agent-integration/nc-agents-parity.bats` (completo, com os 5 testes AC1-AC5) e `.github/workflows/nc-agents-parity-check.yml`

**Checkpoint**: US3 completa — drift entre as 3 integrações é detectado automaticamente e bloqueia merge no CI.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Documentação, validação final e fechamento institucional da feature

- [ ] T029 Atualizar `docs/developer-guide.md` com a seção "Agentes disponíveis por integração": tabela com os 12 comandos `/speckit-*` + 9 agentes `/nc-*` para Copilot/Claude/Antigravity, e a diferença de risco `multi_install_safe` (`true` para Copilot/Claude, `false` para Antigravity) — `test_AC6_developer_guide_documents_integrations` (AC-6, FR-005)
- [ ] T030 [P] Rodar `bash -n scripts/sync-nc-agents-to-integrations.sh` (lint de sintaxe) e validar idempotência manualmente: rodar o script duas vezes seguidas sem alterar a fonte e confirmar `git diff --stat` vazio na segunda execução (contrato: "Idempotência")
- [ ] T031 Rodar a suíte completa `bats tests/multi-agent-integration/nc-agents-parity.bats` (todos os AC1-AC5) e confirmar 100% de sucesso
- [ ] T032 Atualizar `docs/reuse-catalog.yaml` com uma nova entrada para o padrão "sync de fonte única para múltiplos destinos com gate de drift" (tag sugerida: `single-source-multi-target-sync`), referenciando esta feature como origem — fecha o gap identificado no Harness/Reuse Gate do `plan.md`
- [ ] T033 Validar todos os 6 ACs de `spec.md` contra os testes/execuções realizados (checklist final) e atualizar `impact-map.md` com o resultado real dos critérios Go/No-Go (esperado: todos "Go")

**Checkpoint final**: Feature 024 completa — 3 integrações (Copilot, Claude, Antigravity) com paridade total nos 12 comandos + 9 agentes, gate de paridade ativo no CI, documentação atualizada.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sem dependências — pode começar imediatamente
- **Foundational (Phase 2)**: depende do Setup — bloqueia todas as user stories
- **User Story 1 (Phase 3)**: depende do Foundational — nenhuma dependência de outra story (MVP, pode ser entregue sozinha)
- **User Story 2 (Phase 4)**: depende do Foundational — tecnicamente independente de US1, mas reaproveita o mesmo script gerador (T003-T007), portanto na prática roda depois de US1 estar estável
- **User Story 3 (Phase 5)**: depende de US1 **e** US2 estarem completas (o gate de paridade só faz sentido comparando as 3 pastas já povoadas)
- **Polish (Phase 6)**: depende de todas as user stories completas

### User Story Dependency Graph

```text
Setup (P1) → Foundational (P2)
                  ├── US1 Claude (P3, MVP) ──┐
                  └── US2 Antigravity (P4) ──┴──> US3 Gate de Paridade (P5) → Polish (P6)
```

### Within Each User Story

- Tests (quando presentes) antes da implementação equivalente
- Implementação do script antes da execução/validação manual
- Commit do artefato gerado por último

### Parallel Opportunities

- T002 e T003 (Setup) podem rodar em paralelo
- T006 (Foundational) pode rodar em paralelo a T004/T005 (helper de hash é independente da lógica de cópia)
- T008 e T009 (testes US1) podem ser escritos em paralelo
- T015 e T016 (testes US2) podem ser escritos em paralelo
- T014, T024, T028 (commits) podem rodar em paralelo entre si se as stories forem finalizadas em momentos diferentes
- T030 (lint/idempotência) pode rodar em paralelo a T029 (documentação)

---

## Implementation Strategy

### MVP First (User Story 1 apenas)

1. Completar Phase 1: Setup
2. Completar Phase 2: Foundational
3. Completar Phase 3: User Story 1 (Claude Code)
4. **STOP and VALIDATE**: rodar `quickstart.md` V1/V2, confirmar `test_AC1_*` e `test_AC2_*` passando
5. Entregar/demonstrar o MVP (Claude Code com paridade total) antes de avançar

### Incremental Delivery

1. Setup + Foundational → base pronta
2. Adicionar US1 (Claude) → testar independentemente → **MVP entregável**
3. Adicionar US2 (Antigravity isolado) → testar independentemente → entregar incremento
4. Adicionar US3 (gate de paridade) → testar independentemente → entregar incremento final
5. Cada história adiciona valor sem quebrar as anteriores

### Suggested MVP Scope

**User Story 1 (Claude Code)** — menor risco (`multi_install_safe: true`), maior demanda imediata, e demonstra o mecanismo central (script gerador de sync) que será reaproveitado por US2.
