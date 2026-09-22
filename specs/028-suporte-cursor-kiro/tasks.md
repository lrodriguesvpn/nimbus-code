---

description: "Task list for Suporte a Cursor e Kiro como Integrações Agênticas"
---

# Tasks: Suporte a Cursor e Kiro como Integrações Agênticas

**Input**: Design documents from `specs/028-suporte-cursor-kiro/`
**Prerequisites**: [plan.md](./plan.md) (completo, gates de segurança e governança aprovados), [spec.md](./spec.md) (7 ACs, 10 FRs)

**Tests**: Incluídos — o gate de paridade (bats) é requisito funcional explícito (FR-005, AC-5), não opcional.

**Organization**: Tasks agrupadas por fase fundacional (descoberta dinâmica, bloqueante e transversal aos 5 alvos) e depois por User Story (P1 Cursor → P1 Kiro → P2 regressão VS Code → P3 documentação), permitindo entrega incremental.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode rodar em paralelo (arquivos diferentes, sem dependência de tasks incompletas)
- **[Story]**: US1 (Cursor), US2 (Kiro), US3 (regressão VS Code), US4 (documentação)
- Caminhos de arquivo exatos incluídos em cada descrição

## Path Conventions

Projeto de automação/tooling de repositório (mesma convenção da spec 024/025):
- `scripts/lib/nc-agent-sync.py`, `scripts/sync-nc-agents-to-integrations.sh` — scripts existentes a estender
- `tests/multi-agent-integration/` — suítes bats existentes a estender
- `.github/workflows/nc-agents-parity-check.yml` — CI existente a estender
- `docs/developer-guide.md` — documentação a atualizar

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirmar pré-requisitos de ferramenta antes de qualquer mudança de código

- [x] T001 Confirmar `specify integration list` mostra `cursor-agent` e `kiro-cli` com `multi_install_safe: yes` no ambiente de desenvolvimento (já confirmado na auditoria `/nc-critic`; apenas reconfirmar no início da execução)
- [x] T002 [P] Criar snapshot do estado atual de `.claude/skills/nc-*`, `.agents/skills/nc-*`, `.claude/agents/*.md`, `.github/agents/nimbus.agent.md` (ex.: `git stash`/branch de referência) para permitir diff exato pré/pós refatoração da descoberta dinâmica (T004–T006)

**Checkpoint**: Baseline capturado — qualquer regressão nos 3 alvos existentes pode ser comparada byte-a-byte

---

## Phase 2: Foundational (Blocking Prerequisites) — Descoberta Dinâmica (HRN-0006)

**Purpose**: Substituir as listas hardcoded (`AGENTS` em `nc-agent-sync.py`, `EXPECTED_AGENTS`/`EXTRA_SPECKIT_SKILLS` em `sync-nc-agents-to-integrations.sh`) por descoberta via glob, aplicada aos 5 alvos — decisão aprovada explicitamente pelo usuário no `/nc-arch` (ver ADL do `plan.md`)

**⚠️ CRITICAL**: Nenhuma User Story pode começar antes desta fase estar completa e validada sem regressão

- [x] T003 Em `scripts/lib/nc-agent-sync.py`, substituir a tupla hardcoded `AGENTS` por descoberta via `sorted(p.name for p in (root / ".github/skills").glob("nc-*") if (p / "SKILL.md").is_file())`
- [x] T003b **[Descoberta durante implementação, fora do planejamento original]** Adicionar 3 novas entradas em `.nimbus/agent-manifest.yaml` (`NC-Bug-Assess`, `NC-Bug-Fix`, `NC-Bug-Test`) — a descoberta dinâmica (T003) só funciona se todo agente descoberto tiver papel de governança correspondente; `nc-bug-*` nunca tiveram essa entrada (achado registrado em `docs/harness/harness-catalog.yaml` HRN-0007). Confirmado explicitamente com o usuário antes de prosseguir.
- [x] T004 Em `scripts/sync-nc-agents-to-integrations.sh`, substituir o array `EXPECTED_AGENTS` por descoberta equivalente via `find "${SOURCE_DIR}" -maxdepth 1 -type d -name 'nc-*'`
- [x] T005 Em `scripts/sync-nc-agents-to-integrations.sh`, substituir o array `EXTRA_SPECKIT_SKILLS` por descoberta dos comandos `speckit-*` proprietários: todo diretório `speckit-*` em `.github/skills/` que NÃO esteja na lista dos 10 comandos oficiais instalados pelo `specify` CLI (constitution, specify, clarify, plan, tasks, implement, converge, analyze, checklist, taskstoissues)
- [x] T006 [P] Rodar `bash scripts/sync-nc-agents-to-integrations.sh --check --target all` e `python3 scripts/lib/nc-agent-sync.py check --target all` e confirmar que os 3 alvos existentes (vscode, claude, antigravity) continuam idênticos ao snapshot de T002, **exceto** pela adição esperada de `nc-bug-assess`/`nc-bug-fix`/`nc-bug-test` e `speckit-bug-*` (efeito colateral aprovado)
- [x] T007 [P] Estender `tests/multi-agent-integration/nc-agent-foundation.bats` com um novo teste que confirma a contagem de agentes descobertos via glob é `>= 18` (não um número fixo desatualizado) e que `.github/agents/` continua contendo exclusivamente `nimbus.agent.md` (regressão spec 025)

**Checkpoint**: Descoberta dinâmica funcionando para os 5 alvos (3 existentes sem regressão indevida + preparado para os 2 novos) — fundação pronta para as User Stories

---

## Phase 3: User Story 1 - Dev usa Cursor com paridade total (Priority: P1) 🎯 MVP

**Goal**: Um dev consegue instalar a integração Cursor e usar os 12 comandos `/speckit-*` + os agentes `/nc-*` sem alterar nenhuma integração existente.

**Independent Test**: Rodar `specify integration install cursor-agent` em um clone do template, confirmar que os 12 comandos aparecem em `.cursor/skills/` e que `.github/skills/`, `.claude/`, `.agents/` permanecem intocados; rodar o gerador com destino `cursor` e confirmar os agentes NC-*.

### Tests for User Story 1 ⚠️

- [x] T008 [P] [US1] Escrever teste `test_AC1_cursor_speckit_commands_installed` em `tests/multi-agent-integration/nc-agents-parity.bats`: após `specify integration install cursor-agent`, os 12 `.cursor/skills/speckit-*/SKILL.md` existem e `git diff --stat .github/skills/ .claude/ .agents/` é vazio
- [x] T009 [P] [US1] Escrever teste `test_AC2_nc_agents_synced_to_cursor` em `tests/multi-agent-integration/nc-agents-parity.bats`: após o gerador rodar com destino `cursor`, os agentes NC-* existem em `.cursor/skills/nc-<agente>/SKILL.md`, com frontmatter `name`/`description`/`compatibility`/`metadata` e hash funcional idêntico à fonte
- [x] T010 [P] [US1] Estender `tests/multi-agent-integration/nc-agent-contracts.bats` com validação de contrato para o alvo `cursor` (campos obrigatórios do frontmatter, sem o campo `tools` usado por Claude)

### Implementation for User Story 1

- [x] T011 [US1] Rodar `specify integration install cursor-agent` no repositório e confirmar instalação dos 12 comandos `/speckit-*` em `.cursor/skills/` (gerenciado nativamente pelo `specify` CLI — nenhum código novo aqui, apenas execução e verificação)
- [x] T012 [US1] Em `scripts/lib/nc-agent-sync.py`, adicionar `"cursor"` a `TARGETS` e `GENERATED_ROOTS["cursor"] = Path(".cursor/skills")`
- [x] T013 [US1] Em `scripts/lib/nc-agent-sync.py`, estender `render()` com ramo para `target == "cursor"`: gerar frontmatter `{name, description, compatibility, metadata}` (não `tools`)
- [x] T014 [US1] Em `scripts/lib/nc-agent-sync.py`, estender `destination()` para `cursor` → `.cursor/skills/<agent>/SKILL.md`
- [x] T015 [US1] Em `scripts/lib/nc-agent-sync.py`, estender `validate_contract()` para exigir os campos `name`/`description`/`compatibility`/`metadata` no destino `cursor`
- [x] T016 [US1] Em `scripts/sync-nc-agents-to-integrations.sh`, implementar `process_for_cursor()` (mesmo padrão de `process_for_claude()`) para sincronizar os comandos `speckit-*` proprietários (descobertos em T005) para `.cursor/skills/`
- [x] T017 [US1] Rodar `python3 scripts/lib/nc-agent-sync.py generate --target cursor` e `bash scripts/sync-nc-agents-to-integrations.sh --target cursor` (ou equivalente `--target all`) e confirmar geração correta
- [x] T018 [US1] Rodar `bats tests/multi-agent-integration/*.bats -f "cursor"` e confirmar que T008–T010 passam
- [x] T019 [P] [US1] Commitar `.cursor/skills/` (12 comandos + agentes NC-*) no repositório

**Checkpoint**: US1 completa — Cursor tem paridade total, sem alterar nenhuma integração existente. MVP entregável.

---

## Phase 4: User Story 2 - Dev usa Kiro com paridade total (Priority: P1)

**Goal**: Um dev consegue instalar a integração Kiro e usar os 12 comandos `/speckit-*` + os agentes `/nc-*` (via mecanismo nativo Custom agents) sem alterar nenhuma integração existente.

**Independent Test**: Rodar `specify integration install kiro-cli` (com `--ignore-agent-tools` se o binário `kiro-cli` não estiver instalado localmente para fins de teste), confirmar `.kiro/prompts/speckit.*.md`; rodar o gerador com destino `kiro` e confirmar `.kiro/agents/nc-*.md`.

### Tests for User Story 2 ⚠️

- [x] T020 [P] [US2] Escrever teste `test_AC3_kiro_speckit_commands_installed` em `tests/multi-agent-integration/nc-agents-parity.bats`: após `specify integration install kiro-cli`, os 12 `.kiro/prompts/speckit.*.md` existem (nomenclatura dot-separada) e nenhum arquivo das demais integrações muda
- [x] T021 [P] [US2] Escrever teste `test_AC4_nc_agents_synced_to_kiro` em `tests/multi-agent-integration/nc-agents-parity.bats`: após o gerador rodar com destino `kiro`, os agentes NC-* existem em `.kiro/agents/nc-<agente>.md` (não em `.kiro/prompts/`), com campos `name`/`description`/`tools`/`prompt`
- [x] T022 [P] [US2] Estender `tests/multi-agent-integration/nc-agent-contracts.bats` com validação de contrato para o alvo `kiro` (mecanismo nativo Custom agents, distinto do formato `SKILL.md`)

### Implementation for User Story 2

- [x] T023 [US2] Rodar `specify integration install kiro-cli` (com `--ignore-agent-tools` se necessário em CI/ambiente sem o binário) e confirmar instalação dos 12 comandos `/speckit-*` em `.kiro/prompts/`
- [x] T024 [US2] Em `scripts/lib/nc-agent-sync.py`, adicionar `"kiro"` a `TARGETS` e `GENERATED_ROOTS["kiro"] = Path(".kiro/agents")`
- [x] T025 [US2] Em `scripts/lib/nc-agent-sync.py`, estender `render()` com ramo para `target == "kiro"`: gerar o formato nativo de Custom agents (`name`, `description`, `tools`, `prompt`), distinto do `SKILL.md` usado por claude/antigravity/cursor
- [x] T026 [US2] Em `scripts/lib/nc-agent-sync.py`, estender `destination()` para `kiro` → `.kiro/agents/<agent>.md` (sem subpasta, diferente do padrão `SKILL.md`)
- [x] T027 [US2] Em `scripts/lib/nc-agent-sync.py`, estender `validate_contract()` para exigir os campos nativos do Kiro no destino `kiro`
- [x] T028 [US2] Em `scripts/sync-nc-agents-to-integrations.sh`, implementar `process_for_kiro_prompts()` para sincronizar os comandos `speckit-*` proprietários (descobertos em T005) para `.kiro/prompts/speckit.<nome>.md` (dot-separado)
- [x] T029 [US2] Rodar `python3 scripts/lib/nc-agent-sync.py generate --target kiro` e a extensão do sync script para `kiro` e confirmar geração correta
- [x] T030 [US2] Rodar `bats tests/multi-agent-integration/*.bats -f "kiro"` e confirmar que T020–T022 passam
- [x] T031 [P] [US2] Commitar `.kiro/prompts/` (12 comandos) e `.kiro/agents/` (agentes NC-*) no repositório

**Checkpoint**: US2 completa — Kiro tem paridade total, usando o mecanismo nativo de Custom agents corretamente.

---

## Phase 5: User Story 3 - VS Code continua expondo só o `@nimbus` (Priority: P2)

**Goal**: Confirmar que a extensão do gerador para 5 alvos não reintroduz poluição de menu no VS Code.

**Independent Test**: Rodar `python3 scripts/lib/nc-agent-sync.py check --target vscode` após toda a extensão e confirmar que `.github/agents/` contém exclusivamente `nimbus.agent.md`.

### Tests for User Story 3 ⚠️

- [x] T032 [US3] Confirmar que o teste de regressão de T007 (`.github/agents/` só `nimbus.agent.md`) passa após T003–T031 completas — não requer novo código de teste, apenas reexecução com o gerador totalmente estendido

### Implementation for User Story 3

- [x] T033 [US3] Rodar `python3 scripts/lib/nc-agent-sync.py check --target vscode` isoladamente e confirmar `Parity OK`
- [x] T034 [US3] Rodar a suíte completa `bats tests/multi-agent-integration/*.bats` (todos os 5 alvos) e confirmar 100% verde

**Checkpoint**: Nenhuma regressão da spec 025 — VS Code permanece com o orquestrador único.

---

## Phase 6: User Story 4 - Documentação reflete as cinco integrações (Priority: P3)

**Goal**: `docs/developer-guide.md` documenta as 5 integrações suportadas e seus perfis de risco.

**Independent Test**: Revisar a seção "Agentes disponíveis por integração" e confirmar que lista as 5 integrações com `multi_install_safe` e exigência de CLI de cada uma.

### Implementation for User Story 4

- [x] T035 [US4] Atualizar a seção "Agentes disponíveis por integração" em `docs/developer-guide.md` para incluir Cursor (`multi_install_safe: yes`, sem CLI) e Kiro (`multi_install_safe: yes`, exige `kiro-cli` no PATH)
- [x] T036 [P] [US4] Documentar em `docs/developer-guide.md` a distinção de formato entre alvos: `SKILL.md` (claude, antigravity, cursor) vs. Custom agents nativo (`kiro`) vs. orquestrador único (`vscode`)

**Checkpoint**: Documentação completa e revisável por qualquer dev novo.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Fechar a esteira de CI e o registro de reuso

- [x] T037 Estender `.github/workflows/nc-agents-parity-check.yml` com paths de trigger `.cursor/skills/nc-*/**` e `.kiro/agents/nc-*.md`
- [x] T038 [P] Atualizar `docs/reuse-catalog.yaml`: incrementar `reuse_count` de `single-source-multi-target-sync` de 0 para 1
- [x] T039 [P] Registrar, na descrição do PR, o efeito colateral aprovado (T006: `nc-bug-*`/`speckit-bug-*` agora sincronizados também para Claude/Antigravity) para revisão humana explícita
- [x] T040 Rodar a suíte completa `bats tests/multi-agent-integration/*.bats` uma última vez antes do merge e confirmar 100% verde nos 5 alvos

**Checkpoint**: Feature completa, CI verde, reuso registrado.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: sem dependências — pode começar imediatamente
- **Phase 2 (Foundational)**: depende da Phase 1; **BLOQUEIA** todas as User Stories
- **Phase 3 (US1 Cursor)**: depende da Phase 2
- **Phase 4 (US2 Kiro)**: depende da Phase 2 — pode rodar em paralelo com a Phase 3 (arquivos/alvos diferentes)
- **Phase 5 (US3 regressão VS Code)**: depende de Phase 3 e Phase 4 estarem completas
- **Phase 6 (US4 documentação)**: depende de Phase 3 e Phase 4 (precisa saber o resultado final para documentar corretamente) — pode começar em paralelo com Phase 5
- **Phase 7 (Polish)**: depende de todas as fases anteriores

### User Story Dependency Graph

```
Phase 2 (Foundational, bloqueante)
    ├──> Phase 3 (US1 Cursor) ──┐
    └──> Phase 4 (US2 Kiro)   ──┼──> Phase 5 (US3 regressão)
                                 └──> Phase 6 (US4 docs)
                                          │
                                          v
                                    Phase 7 (Polish)
```

### Parallel Opportunities

- T008/T009/T010 (testes US1) podem ser escritos em paralelo com T020/T021/T022 (testes US2) — arquivos/casos de teste diferentes dentro do mesmo arquivo bats, sem dependência mútua de execução.
- Phase 3 (US1) e Phase 4 (US2) podem ser implementadas em paralelo por dois desenvolvedores/agentes distintos, já que tocam ramos separados de `render()`/`destination()`/`validate_contract()` (branches `if target == "cursor"` vs. `if target == "kiro"`).
- T035/T036 (documentação) podem rodar em paralelo com T037 (CI).

## Implementation Strategy

### MVP First (User Story 1 apenas — Cursor)

1. Completar Phase 1 (Setup) + Phase 2 (Foundational)
2. Completar Phase 3 (US1 Cursor)
3. **PARAR e validar**: Cursor funciona de ponta a ponta, testado independentemente
4. Entregar/demonstrar se necessário antes de continuar

### Incremental Delivery

1. Setup + Foundational → base pronta (inclui a correção de HRN-0006 para os 5 alvos)
2. Adicionar US1 (Cursor) → testar independentemente → MVP entregável
3. Adicionar US2 (Kiro) → testar independentemente → 2 integrações novas completas
4. Adicionar US3 (regressão) → confirmar VS Code intocado
5. Adicionar US4 (documentação) → feature completa e documentada
6. Cada história adiciona valor sem quebrar as anteriores

### Suggested MVP Scope

Se o tempo for restrito, entregar apenas **Phase 1 + Phase 2 + Phase 3 (US1
Cursor)** já constitui um incremento de valor completo e testável
independentemente — Kiro (US2) pode ser uma entrega separada subsequente,
já que ambas as User Stories P1 são independentes uma da outra.
