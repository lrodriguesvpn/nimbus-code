---

description: "Tasks for native NC agent projections"
---

# Tasks: Native NC Agents

> **Pivot pós-implementação (ADL-025-04):** as tarefas abaixo descrevem o
> desenho original (`.github/agents/nc-*.agent.md`, 15 arquivos). Após
> revisão de UX do PR #479, o destino VS Code foi consolidado em um único
> orquestrador `.github/agents/nimbus.agent.md` (`@nimbus`), gerado a partir
> de `scripts/lib/templates/nimbus-agent.template.md`. Claude Code e
> Antigravity permanecem exatamente como descrito (15 arquivos/skills). Ver
> `plan.md` (ADL-025-04) e `contracts/vscode-custom-agent.contract.md` para o
> contrato atualizado. Este arquivo é mantido como registro histórico das
> tarefas originalmente executadas.

**Input**: Design documents from `specs/025-native-nc-agents/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`,
`contracts/`, `quickstart.md`, and `.nimbus/agent-manifest.yaml`

**Execution mode**: Nimbus Code S3. The agent may implement the bounded tasks
below, but the Dev/architecture board must approve the ADLs and native
contracts before implementation begins. No task removes the `/nc-*` bridge.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Establish the generated-output contract and fixtures without
changing source skills or legacy bridges.

- [x] T001 [P] Add native destination directories and generation-output markers in `.github/agents/` and `.claude/agents/`; Contexto: the generator needs explicit repository-local destinations; Objetivo: prepare safe output roots; Resultado Esperado: directories are available without modifying `.github/skills/` or `/nc-*`; Critérios de Aceite: [ ] paths match `specs/025-native-nc-agents/contracts/`; [ ] no source skill is changed; Passos Operacionais: create only the approved directories and document generated ownership; Dependências: Nenhuma; Responsável: Agente; Estimativa: 1k tokens / 15 min; Referência: FR-003, FR-010, feature `025-native-nc-agents`.
- [x] T002 [P] Define fixture inputs for one representative read-only, one read-write, and one approval-gated NC role in `tests/multi-agent-integration/fixtures/025-native-nc-agents/`; Contexto: platform adapters require deterministic test inputs; Objetivo: isolate generation tests from the full repository; Resultado Esperado: fixtures cover manifest controls and frontmatter differences; Critérios de Aceite: [ ] fixtures contain no secrets; [ ] each fixture maps to a manifest role; Passos Operacionais: copy minimal normalized role/skill samples and annotate expected outputs; Dependências: Nenhuma; Responsável: Agente; Estimativa: 1.5k tokens / 20 min; Referência: AC-2, data-model.md.
- [x] T003 [P] Record implementation approval for ADL-025-01, ADL-025-02, and ADL-025-03 in `specs/025-native-nc-agents/plan.md`; Contexto: S3 implementation is gated by human review; Objetivo: make the approved architecture auditable; Resultado Esperado: each ADL has approver and date/status; Critérios de Aceite: [ ] no ADL remains implicitly approved; [ ] Antigravity remains bridge-only; Passos Operacionais: obtain Dev/architecture-board review, update only the approval fields, and preserve rationale; Dependências: Nenhuma; Responsável: Humano; Estimativa: 1k tokens / 30 min; Referência: AC-6, plan.md.

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Build the shared manifest parser, normalization rules, and failure
behavior required by every user story.

- [x] T004 [P] [Foundation] Implement a manifest/source inventory validator in `scripts/lib/nc-agent-sync.py`; Contexto: roles and source skills must be one-to-one; Objetivo: validate every manifest role has exactly one source skill and reject extras; Resultado Esperado: deterministic inventory with actionable errors; Critérios de Aceite: [ ] missing source fails non-zero; [ ] extra generated role is reported; [ ] source files remain read-only; Passos Operacionais: parse `.nimbus/agent-manifest.yaml`, enumerate `.github/skills/nc-*/SKILL.md`, and emit structured diagnostics; Dependências: T003; Responsável: Agente; Estimativa: 3k tokens / 45 min; Referência: FR-001, FR-002, FR-005.
- [x] T005 [P] [Foundation] Implement normalized functional-body hashing in `scripts/lib/nc-agent-sync.py`; Contexto: frontmatter differs per platform but functional content must not drift; Objetivo: provide one hash algorithm for generation and parity; Resultado Esperado: equal hashes for semantically identical bodies; Critérios de Aceite: [ ] frontmatter is excluded; [ ] documented integration notes are normalized; [ ] hash output is stable across runs; Passos Operacionais: port the current hash behavior from `scripts/sync-nc-agents-to-integrations.sh`, add explicit normalization cases, and expose a CLI subcommand; Dependências: T003; Responsável: Agente; Estimativa: 2.5k tokens / 35 min; Referência: AgentArtifact.functional_body_hash, FR-004, FR-006.
- [x] T006 [Foundation] Refactor `scripts/sync-nc-agents-to-integrations.sh` to call the shared Python inventory/hash helper while preserving existing Claude/Antigravity skill behavior; Contexto: current logic is embedded in Bash and must gain native outputs without regressions; Objetivo: centralize validation while retaining existing flags; Resultado Esperado: `--target claude|antigravity|agy|all` remains compatible; Critérios de Aceite: [ ] existing custom `speckit-*` sync remains available; [ ] invalid target fails explicitly; [ ] source skills and legacy bridges are never deleted; Passos Operacionais: add helper invocation, preserve current post-processing, and update help text for new targets; Dependências: T004, T005; Responsável: Agente; Estimativa: 4k tokens / 60 min; Referência: FR-003, FR-005, FR-007.
- [x] T007 [Foundation] Add shared contract-validation helpers in `scripts/lib/nc-agent-sync.py`; Contexto: VS Code and Claude have different frontmatter contracts; Objetivo: reject unsupported metadata or broadened tools before publishing; Resultado Esperado: validation identifies platform, role, field, and reason; Critérios de Aceite: [ ] VS Code requires `.agent.md`, name, description, and constrained tools; [ ] Claude requires project subagent path and constrained permissions; [ ] Antigravity native output is not attempted; Passos Operacionais: encode only fields documented in `contracts/` and return non-zero for unsupported surfaces; Dependências: T004, T005; Responsável: Agente; Estimativa: 3k tokens / 45 min; Referência: AC-5, contracts/.
- [x] T008 [Foundation] Add focused foundational tests in `tests/multi-agent-integration/nc-agent-foundation.bats`; Contexto: shared validators block all stories; Objetivo: prove deterministic inventory, hashing, and explicit failures; Resultado Esperado: tests fail before implementation and pass after it; Critérios de Aceite: [ ] missing role test; [ ] hash normalization test; [ ] unsupported target test; [ ] no silent success; Passos Operacionais: create isolated temp fixtures, invoke helper/script, assert exit codes and diagnostics; Dependências: T004, T005, T007; Responsável: Agente; Estimativa: 3k tokens / 45 min; Referência: AC-2, AC-5, FR-005.

**Checkpoint**: Foundation ready — native story work may proceed in parallel.

## Phase 3: User Story 1 - Usar NC-* como agente nativo (Priority: P1) 🎯 MVP

**Goal**: Generate selectable/delegable native agents for VS Code/Copilot and
Claude while retaining Antigravity's verified skills bridge.

**Independent Test**: Run the generator in a clean fixture and verify every
manifest NC role produces valid `.github/agents/*.agent.md` and
`.claude/agents/*.md` artifacts, while `.agents/skills/` remains available.

### Tests for User Story 1

- [x] T009 [P] [US1] Add native artifact generation tests in `tests/multi-agent-integration/nc-agents-native.bats`; Contexto: AC-1 requires all supported projections; Objetivo: prove one generator pass creates valid outputs; Resultado Esperado: all expected roles and destinations are present; Critérios de Aceite: [ ] VS Code extension and directory are correct; [ ] Claude directory is correct; [ ] Antigravity bridge remains present; Passos Operacionais: run generator against fixture, enumerate outputs, and assert frontmatter/body presence; Dependências: T008; Responsável: Agente; Estimativa: 3k tokens / 45 min; Referência: AC-1, US1.
- [x] T010 [P] [US1] Add native contract assertions in `tests/multi-agent-integration/nc-agent-contracts.bats`; Contexto: each platform requires distinct frontmatter; Objetivo: prevent invalid native discovery files; Resultado Esperado: contract violations fail with platform-specific diagnostics; Critérios de Aceite: [ ] VS Code `.agent.md` fields validated; [ ] Claude frontmatter/path validated; [ ] no Antigravity speculative agent directory; Passos Operacionais: create malformed fixture variants and assert failure messages; Dependências: T007; Responsável: Agente; Estimativa: 3k tokens / 45 min; Referência: AC-1, AC-5, contracts/.

### Implementation for User Story 1

- [x] T011 [P] [US1] Implement VS Code/Copilot adapter generation in `scripts/lib/nc-agent-sync.py`; Contexto: VS Code discovers workspace agents under `.github/agents/`; Objetivo: map manifest identity, tools, and functional body into `.agent.md`; Resultado Esperado: deterministic `.github/agents/nc-*.agent.md` files; Critérios de Aceite: [ ] name/description are present; [ ] tools never exceed manifest allowlist; [ ] body hash matches source; Passos Operacionais: render frontmatter from manifest, append normalized source body, and write only approved destination paths; Dependências: T004, T005, T007; Responsável: Agente; Estimativa: 4k tokens / 60 min; Referência: FR-003, FR-004, US1.
- [x] T012 [P] [US1] Implement Claude Code subagent adapter generation in `scripts/lib/nc-agent-sync.py`; Contexto: Claude discovers project subagents under `.claude/agents/`; Objetivo: map role metadata and permissions without broadening authority; Resultado Esperado: deterministic `.claude/agents/nc-*.md` files; Critérios de Aceite: [ ] project-local path is used; [ ] permissions/tools are constrained; [ ] S3/S4 approval policy remains visible; Passos Operacionais: render Claude frontmatter, append normalized source body, and validate each generated file; Dependências: T004, T005, T007; Responsável: Agente; Estimativa: 4k tokens / 60 min; Referência: FR-003, FR-004, US1.
- [x] T013 [US1] Wire native targets into `scripts/sync-nc-agents-to-integrations.sh`; Contexto: developers need one documented command; Objetivo: support `--target vscode|claude|antigravity|all` with backward-compatible aliases; Resultado Esperado: one idempotent command generates native outputs and existing bridges; Critérios de Aceite: [ ] repeated runs produce no diff; [ ] `all` does not create `.agents/agents/`; [ ] failures stop the run; Passos Operacionais: add target parsing, call adapters, preserve existing post-processing, and report generated paths; Dependências: T006, T011, T012; Responsável: Agente; Estimativa: 3k tokens / 45 min; Referência: FR-003, FR-005, FR-008, US1.
- [x] T014 [US1] Add governance preservation tests in `tests/multi-agent-integration/nc-agent-manifest.bats`; Contexto: native projections must preserve identity, scope, tools, and approval policy; Objetivo: verify manifest controls survive adaptation; Resultado Esperado: control loss or tool broadening fails; Critérios de Aceite: [ ] read-only and read-write roles covered; [ ] allowed file scope preserved; [ ] approval policy preserved; Passos Operacionais: compare parsed manifest controls with generated frontmatter/body markers; Dependências: T011, T012; Responsável: Agente; Estimativa: 3k tokens / 45 min; Referência: AC-2, US1.

**Checkpoint**: US1 is the MVP and must pass independently before proceeding.

## Phase 4: User Story 2 - Atualizar uma definição sem drift (Priority: P1)

**Goal**: Detect missing, extra, stale, or functionally divergent outputs across
all supported integration surfaces.

**Independent Test**: Modify a source fixture, run parity without regeneration,
observe an identified failure, regenerate once, and observe a clean pass.

### Tests for User Story 2

- [x] T015 [P] [US2] Extend `tests/multi-agent-integration/nc-agents-parity.bats` for native destinations; Contexto: existing suite covers skill bridges but not native files; Objetivo: detect source/destination drift; Resultado Esperado: missing, extra, stale, and hash mismatch cases fail; Critérios de Aceite: [ ] failure names role and platform; [ ] clean generated fixture passes; [ ] source edits do not get silently overwritten; Passos Operacionais: add fixture scenarios and assert non-zero parity results; Dependências: T013; Responsável: Agente; Estimativa: 4k tokens / 60 min; Referência: AC-3, FR-006, US2.
- [x] T016 [P] [US2] Add deterministic/idempotency tests in `tests/multi-agent-integration/nc-agents-parity.bats`; Contexto: generation must be reproducible and safe; Objetivo: ensure repeated runs and ordering changes do not create noise; Resultado Esperado: second run is byte-identical and source files remain unchanged; Critérios de Aceite: [ ] output hashes are stable; [ ] timestamps/order do not alter files; [ ] source checksum is unchanged; Passos Operacionais: run generation twice in a temp clone, compare checksums, and assert no source diff; Dependências: T013; Responsável: Agente; Estimativa: 2.5k tokens / 35 min; Referência: FR-005, FR-010, US2.

### Implementation for User Story 2

- [x] T017 [US2] Implement parity inventory and drift reporting in `scripts/lib/nc-agent-sync.py`; Contexto: parity must cover every generated platform; Objetivo: report missing, extra, stale, functional, and governance drift; Resultado Esperado: one non-zero result per invalid condition with actionable diagnostics; Critérios de Aceite: [ ] no false success for absent destinations; [ ] extra files are reported without deletion; [ ] hash and manifest controls are compared; Passos Operacionais: inventory approved outputs, compare normalized hashes and controls, and return a summarized error list; Dependências: T005, T007, T013; Responsável: Agente; Estimativa: 4k tokens / 60 min; Referência: FR-006, AgentArtifact state transitions.
- [x] T018 [US2] Add a `--check`/parity mode to `scripts/sync-nc-agents-to-integrations.sh`; Contexto: CI needs validation without rewriting artifacts; Objetivo: expose generation and verification as explicit operations; Resultado Esperado: check mode never mutates destinations and exits non-zero on drift; Critérios de Aceite: [ ] `--check` is documented; [ ] drift identifies exact files; [ ] generation mode remains idempotent; Passos Operacionais: parse mode, invoke parity helper, and test mutation boundaries; Dependências: T017; Responsável: Agente; Estimativa: 2.5k tokens / 35 min; Referência: AC-3, FR-005, FR-006.
- [x] T019 [US2] Update `.github/workflows/nc-agents-parity-check.yml` to run generation in a temporary fixture and parity validation; Contexto: CI is the promotion gate; Objetivo: prevent stale native artifacts from merging; Resultado Esperado: workflow validates all supported surfaces without network access; Critérios de Aceite: [ ] workflow runs shell/YAML/parity checks; [ ] failure is explicit; [ ] unrelated workflows are unchanged; Passos Operacionais: add only the feature-specific steps, use a temp directory, and preserve existing triggers/permissions; Dependências: T015, T018; Responsável: Agente; Estimativa: 3k tokens / 45 min; Referência: AC-3, plan.md parity gate.

**Checkpoint**: US2 is independently testable as the drift-prevention gate.

## Phase 5: User Story 3 - Fazer transição sem quebrar usuários atuais (Priority: P1)

**Goal**: Keep `/nc-*`, `.github/skills`, and Antigravity bridge behavior
available while native agents roll out.

**Independent Test**: Compare bridge inventories before and after generation and
verify that no source skill, command bridge, or supported Antigravity skill is
removed or semantically changed.

### Tests for User Story 3

- [x] T020 [P] [US3] Add bridge-preservation tests in `tests/multi-agent-integration/nc-agents-bridge.bats`; Contexto: existing users depend on `/nc-*`; Objetivo: prove native rollout is non-breaking; Resultado Esperado: bridge inventory and hashes remain stable; Critérios de Aceite: [ ] all NC bridge skills remain; [ ] custom `speckit-*` commands remain; [ ] no source deletion occurs; Passos Operacionais: snapshot inventories, run generation, compare normalized hashes, and assert paths; Dependências: T013; Responsável: Agente; Estimativa: 3k tokens / 45 min; Referência: AC-4, FR-007, US3.
- [x] T021 [P] [US3] Add unsupported-Antigravity behavior tests in `tests/multi-agent-integration/nc-agent-contracts.bats`; Contexto: no native Antigravity contract is confirmed; Objetivo: guarantee explicit bridge-only behavior; Resultado Esperado: generator reports bridge retention and never creates `.agents/agents/`; Critérios de Aceite: [ ] unsupported native target is explicit; [ ] existing `.agents/skills` output remains; [ ] no silent success claim of native support; Passos Operacionais: run target checks in a temp fixture and assert paths/messages; Dependências: T007, T013; Responsável: Agente; Estimativa: 2k tokens / 30 min; Referência: AC-5, FR-008, ADL-025-02.

### Implementation for User Story 3

- [x] T022 [US3] Add safe generated-file ownership and rollback handling in `scripts/lib/nc-agent-sync.py`; Contexto: rollback must remove/revert only known generated destinations; Objetivo: prevent accidental deletion of legitimate files; Resultado Esperado: rollback manifest lists exact generated paths and source remains untouched; Critérios de Aceite: [ ] arbitrary files are never deleted; [ ] rollback is per platform; [ ] missing generated files are reported; Passos Operacionais: write a generated inventory metadata file, validate paths against approved roots, and implement explicit rollback/check behavior; Dependências: T017, T018; Responsável: Agente; Estimativa: 3.5k tokens / 50 min; Referência: FR-010, impact-map.md.
- [x] T023 [US3] Update `docs/developer-guide.md` with native-agent selection, delegation, bridge usage, and rollback instructions; Contexto: new developers must choose the right surface in under five minutes; Objetivo: document VS Code/Copilot, Claude, and Antigravity behavior; Resultado Esperado: manual explains native agents, `/nc-*` compatibility, and unsupported native Antigravity contract; Critérios de Aceite: [ ] selection/delegation examples exist; [ ] bridge use case is explicit; [ ] no claim of unsupported native format; Passos Operacionais: add the feature section, link contracts/quickstart, and document `--check`; Dependências: T013, T022; Responsável: Agente; Estimativa: 3k tokens / 45 min; Referência: FR-009, SC-005, US3.

**Checkpoint**: US3 proves the transition is reversible and backward-compatible.

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Complete validation, governance traceability, and release readiness.

- [x] T024 [P] Add governance artifact validation in `tests/multi-agent-integration/nc-agent-governance.bats`; Contexto: S3 requires graph, impact map, contracts, and ADL traceability; Objetivo: block incomplete feature packaging; Resultado Esperado: validation catches missing required artifacts and unresolved gates; Critérios de Aceite: [ ] graph YAML parses; [ ] impact map exists; [ ] contracts are present; [ ] approval fields are non-empty before implementation; Passos Operacionais: validate required files and key sections with Ruby/Python/Bash assertions; Dependências: T003, T019; Responsável: Agente; Estimativa: 2.5k tokens / 35 min; Referência: AC-6, plan.md.
- [x] T025 [P] Run `bash -n scripts/sync-nc-agents-to-integrations.sh`, `ruby` YAML validation, and all Bats suites; Contexto: final quality gate must cover syntax, contracts, parity, bridges, and governance; Objetivo: verify the complete feature; Resultado Esperado: all targeted checks pass with no hidden failures; Critérios de Aceite: [ ] all tests pass; [ ] `git diff --check` passes; [ ] quickstart commands are reproducible; Passos Operacionais: execute checks from repository root, capture failures, fix only in-scope issues, and rerun; Dependências: T020, T021, T023, T024; Responsável: Agente; Estimativa: 2k tokens / 30 min; Referência: quickstart.md, SLO Gate.
- [x] T026 [P] Reconcile generated artifacts and source ownership in `.github/agents/`, `.claude/agents/`, `.agents/skills/`, and `.github/skills/`; Contexto: final diff must contain only deterministic outputs and approved changes; Objetivo: ensure no manual edits or unrelated files are included; Resultado Esperado: clean feature-scoped diff and stable generated outputs; Critérios de Aceite: [ ] no secrets; [ ] no unexpected destinations; [ ] source/bridge unchanged except approved generator metadata; Passos Operacionais: run inventory/parity, inspect status/diff, and remove only explicitly generated stale files if validator identifies them; Dependências: T025; Responsável: Agente; Estimativa: 2k tokens / 30 min; Referência: FR-010, impact-map.md.
- [x] T027 Record implementation results, human review hours, and release/rollback decision in `specs/025-native-nc-agents/plan.md`; Contexto: Nimbus requires traceability and real human effort for hybrid work; Objetivo: close gates with evidence; Resultado Esperado: plan records test results, approvers, hours, and final Go/No-Go; Critérios de Aceite: [ ] S3 review is recorded; [ ] rollback path is verified; [ ] no bridge removal is implied; Passos Operacionais: update only completion/status sections after validation and obtain final Dev review; Dependências: T025, T026; Responsável: Humano; Estimativa: 1.5k tokens / 30 min; Referência: plan.md, impact-map.md.

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: T001 and T002 can run in parallel; T003 requires human approval.
- **Foundational (Phase 2)**: T004, T005, and T007 depend on T003; T006 depends on T004/T005; T008 depends on all foundational validators.
- **User Stories (Phases 3–5)**: begin only after Phase 2. US1 is the MVP. US2 depends on the generation path from US1. US3 depends on the stable generation path but can run in parallel with the final US2 tests.
- **Polish (Phase 6)**: depends on all intended stories and their validation.

### User Story Dependencies

- **US1 (P1)**: depends on Foundation; no other story dependency.
- **US2 (P1)**: depends on US1 generation outputs and extends the parity gate.
- **US3 (P1)**: depends on US1 generation outputs; bridge tests can run in parallel with US2 parity work.

### Parallel Opportunities

- T001 and T002 are parallel setup work; T003 is human-gated.
- T004, T005, and T007 can proceed in parallel after T003.
- T009 and T010 can proceed in parallel after foundational validation.
- T011 and T012 can proceed in parallel because they write separate adapter logic.
- T015 and T016 can proceed in parallel after T013.
- T020 and T021 can proceed in parallel after T013.
- T024 and T025 can proceed in parallel once implementation is complete.

## Parallel Example: MVP (User Story 1)

```text
After Phase 2:
  Agent A: T009 + T011 (VS Code native adapter and tests)
  Agent B: T010 + T012 (Claude contract tests and adapter)
  Agent C: T014 (manifest-control assertions after adapters exist)
Then:
  Agent A: T013 (wire targets)
  All agents: rerun T009–T014 and validate the US1 checkpoint
```

## Phase 7: Reabertura — Validação real por IDE agêntica (2026-09-22)

**Purpose**: a entrega original validou só estrutura (arquivo existe, hash do
corpo bate). Esta fase corrige os defeitos encontrados e exige evidência de
teste real em cada IDE agêntica suportada. Ver o aviso de reabertura em
`spec.md` e ADL-025-05 em `plan.md`.

- [x] T028 [US1] Traduzir `tool_allowlist` para nomes do Claude Code em `scripts/lib/nc-agent-sync.py` (`CLAUDE_TOOL_MAP`, `claude_tools()`) e fazer `validate_contract()` comparar com a lista traduzida; Referência: AC-7, ADL-025-05.
- [x] T029 [P] [US2] Adicionar guarda de regressão em `tests/multi-agent-integration/nc-agent-manifest.bats`, que falha se `.claude/agents/nc-*.md` tiver ferramenta não reconhecida pelo Claude ou lista vazia (rejeita os 18 arquivos antigos); Referência: AC-7.
- [x] T030 [US1] Gerar o orquestrador para Claude como skill `.claude/skills/nimbus/SKILL.md` a partir do mesmo template (placeholders `{{ENTRYPOINT}}`/`{{RUNTIME}}`), com checagem de drift; a saída do VS Code continua idêntica; Referência: ADL-025-05.
- [ ] T031 [Humano] Teste real no **Claude Code**, em sessão nova (os agentes são carregados no início da sessão): iniciar `nc-critic` como subagente, confirmar que lista `Read`/`Grep`/`Glob`/`Bash`/`Edit`/`Write`/`Skill` e lê um arquivo; rodar `/nimbus` e confirmar o diagnóstico do repositório. Registrar em `ide-validation-matrix.md`; Referência: AC-8.
- [ ] T032 [US1] Traduzir as ferramentas para **Kiro** conforme `research.md` Decision 5 (`fs_read`, `fs_write`, `shell`, `web_fetch`; skills via `resources: skill://` e geração de `.kiro/skills/`; `permissions: {rules: []}`), com guarda equivalente à T029; Dependências: pesquisa da Decision 5; Referência: AC-7.
- [ ] T033 [Humano] Teste real no **Kiro IDE e Kiro CLI**: o agente aparece no seletor, lista ferramentas, lê arquivo. Confirmar os três pontos marcados como "não confirmado" na Decision 5; Dependências: T032; Referência: AC-8.
- [ ] T034 [Humano] Teste real no **Cursor**: `/nc-*` como skill funciona; avaliar gerar subagentes nativos em `.cursor/agents/` e verificar como o Cursor trata `.claude/agents/` (ele também lê essa pasta; o campo `tools` com nomes do Claude pode ser ignorado ou causar erro); Referência: AC-8, research.md Decision 5.
- [ ] T035 [Humano] Teste real no **Antigravity**: `/nc-*` como skill funciona a partir de `.agents/skills/`; Referência: AC-8.
- [ ] T036 [Humano] Teste real no **VS Code / Copilot**: `@nimbus` aparece no seletor e as ferramentas declaradas (`view`, `rg`, `glob`, `bash`, `apply_patch`, `web_fetch`, `sql`, `skill:*`) são reconhecidas pelo Copilot no VS Code; esses nomes vêm do Copilot CLI e podem não ser os mesmos do VS Code; Referência: AC-8.
- [ ] T037 [US3] Decidir e implementar a paridade de skills de terceiros aprovadas por ADR, começando por `typesafe-ai` (ADR 0010): hoje está só em `.agents/skills/` (Antigravity) e em symlink em `.claude/skills/` (Claude), porque `npx skills add` não passa por `.github/skills/`, a fonte do sync. Copilot, Cursor e Kiro não a recebem. Opções: estender o sync para ler `skills-lock.json`, ou documentar a instalação por IDE; Referência: AC-9.
- [x] T038 [P] Corrigir o teste `foundation helper fails when a generated source is missing` em `tests/multi-agent-integration/nc-agent-foundation.bats`, que sumia do relatório do Bats ("Executed 2 instead of expected 3") e derrubava o job `parity-check` no `develop` e no `main`. Havia duas causas: o `trap ... EXIT` dentro do teste sequestrava o relatório do Bats (a limpeza foi para `teardown()`, também em `nc-agent-contracts.bats`), e `discover_agents()` ignorava sem aviso uma pasta `nc-*` sem `SKILL.md`, regressão da HRN-0006 (agora falha com `source skills missing`).
- [ ] T038b Corrigir `tests/agent-orchestration/happy-path.test.sh`, que falha no `main` por exigir exatamente 15 papéis no manifesto, que hoje tem 18 (com os `nc-bug-*`).
- [ ] T039 [Humano] Consolidar `specs/025-native-nc-agents/ide-validation-matrix.md` (IDE, versão, data, quem testou, resultado, evidência) e só então marcar a reabertura como concluída; Dependências: T031, T033, T034, T035, T036; Referência: AC-8.

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 and obtain S3 ADL approval.
2. Complete Phase 2 validators and shared hash logic.
3. Implement VS Code and Claude native adapters plus Antigravity bridge retention.
4. Run the US1 independent test and stop for human review.

### Incremental Delivery

1. Add US2 parity/drift detection and CI promotion gate.
2. Add US3 bridge preservation and rollback safety.
3. Complete documentation, governance validation, and final Go/No-Go.
4. Never remove `/nc-*` in this feature.

## Extension Hook

The configured `nimbus-code-backlog-sync` `after_tasks` hook is optional. If
backlog synchronization is desired, invoke the equivalent
`/speckit-nimbus-code-backlog-sync-sync` flow explicitly after reviewing this
task list; task generation itself does not create external issues.
