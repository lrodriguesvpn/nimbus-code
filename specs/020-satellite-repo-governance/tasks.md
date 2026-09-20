# Tasks: Governança de Repos Satélite e Intake Greenfield MultiRepo

**Entrada**: Artefatos de design de [specs/020-satellite-repo-governance/](/Users/lrodrigues/projects/nimbus-code-spec-kit-template/specs/020-satellite-repo-governance)  
**Pré-requisitos**: [plan.md](/Users/lrodrigues/projects/nimbus-code-spec-kit-template/specs/020-satellite-repo-governance/plan.md) ✅, [spec.md](/Users/lrodrigues/projects/nimbus-code-spec-kit-template/specs/020-satellite-repo-governance/spec.md) ✅, [research.md](/Users/lrodrigues/projects/nimbus-code-spec-kit-template/specs/020-satellite-repo-governance/research.md) ✅, [data-model.md](/Users/lrodrigues/projects/nimbus-code-spec-kit-template/specs/020-satellite-repo-governance/data-model.md) ✅, [quickstart.md](/Users/lrodrigues/projects/nimbus-code-spec-kit-template/specs/020-satellite-repo-governance/quickstart.md) ✅, [graph.yaml](/Users/lrodrigues/projects/nimbus-code-spec-kit-template/specs/020-satellite-repo-governance/graph.yaml) ✅, [graph.md](/Users/lrodrigues/projects/nimbus-code-spec-kit-template/specs/020-satellite-repo-governance/graph.md) ✅, [impact-map.md](/Users/lrodrigues/projects/nimbus-code-spec-kit-template/specs/020-satellite-repo-governance/impact-map.md) ✅, [contracts/](/Users/lrodrigues/projects/nimbus-code-spec-kit-template/specs/020-satellite-repo-governance/contracts) ✅  
**Organização**: tarefas agrupadas por user story para permitir implementação incremental, validação independente e separação explícita entre governança permanente e bugfix operacional do bootstrap.

## Format: `[ID] [P?] [US?] Description with file path`

- `[P]`: tarefa pode rodar em paralelo (arquivos diferentes, sem dependência bloqueante)
- `[US]`: rótulo da user story (`[US1]`, `[US2]`, `[US3]`, `[US4]`, `[US5]`)

---

## Phase 1: Setup (Base Compartilhada da Feature)

**Objetivo**: preparar os artefatos e pontos de entrada compartilhados antes de alterar o comportamento do bootstrap e a documentação operacional.

- [x] T001 Consolidar o escopo final e a separação formal entre governança permanente e bugfix operacional em `specs/020-satellite-repo-governance/plan.md`
- [x] T002 [P] Alinhar `specs/020-satellite-repo-governance/research.md`, `specs/020-satellite-repo-governance/data-model.md` e `specs/020-satellite-repo-governance/contracts/topology-intake.contract.md` para usar a mesma terminologia de `greenfield`, `brownfield`, `monorepo`, `multirepo`, `repo central` e `repo satélite`
- [x] T003 [P] Preparar a baseline de validação em `specs/020-satellite-repo-governance/quickstart.md` com os cenários AC-1 a AC-7 e referências aos arquivos candidatos de implementação

**Checkpoint**: artefatos da feature usam a mesma linguagem e deixam claro que esta entrega não absorve bugfixes técnicos paralelos.

---

## Phase 2: Foundational (Pré-requisitos Transversais)

**Objetivo**: estabelecer a infraestrutura mínima de implementação e rastreabilidade antes das user stories.

- [x] T004 Atualizar `bootstrap.sh` para introduzir uma etapa explícita de classificação `greenfield` vs `brownfield` baseada em presença de código de aplicação relevante
- [x] T005 [P] Adicionar fixtures e asserções iniciais de teste para classificação de contexto em `tests/bootstrap/bootstrap-entrypoints.bats`
- [x] T006 [P] Atualizar `specs/020-satellite-repo-governance/graph.yaml`, `specs/020-satellite-repo-governance/graph.md` e `specs/020-satellite-repo-governance/impact-map.md` se a implementação final exigir refinamento nos módulos planejados

**Checkpoint**: o bootstrap já tem o gancho estrutural da classificação inicial, e a feature tem lastro de teste/traçabilidade antes de avançar por user story.

---

## Phase 3: User Story 1 — Classificar corretamente a entrada do projeto (Priority: P1) 🎯

**Objetivo**: fazer o bootstrap distinguir greenfield de brownfield de forma legível, previsível e validável.

**Independent Test**: executar os cenários com um repositório quase vazio e com um repositório contendo código de aplicação relevante e confirmar que o fluxo diverge corretamente.

- [x] T007 [P] [US1] Implementar a heurística de “código de aplicação relevante” em `bootstrap.sh`
- [x] T008 [US1] Adicionar mensagens operacionais explícitas para explicar a classificação `greenfield` ou `brownfield` em `bootstrap.sh`
- [x] T009 [P] [US1] Cobrir os cenários AC-1 e AC-2 com fixtures/asserções shell em `tests/bootstrap/bootstrap-entrypoints.bats`
- [x] T010 [US1] Atualizar a documentação do onboarding inicial em `README.md` para refletir a distinção entre greenfield e brownfield
- [x] T011 [US1] Validar US1 contra AC-1, AC-2, FR-001 e SC-001 em `specs/020-satellite-repo-governance/quickstart.md`

---

## Phase 4: User Story 2 — Registrar a decisão de topologia do produto (Priority: P1) 🎯

**Objetivo**: transformar mono vs multirepo em decisão explícita e rastreável, não em escolha implícita.

**Independent Test**: percorrer o fluxo greenfield e confirmar que não é possível concluir a escolha estrutural sem registrar o motivo.

- [x] T012 [P] [US2] Implementar o prompt e a captura da decisão `monorepo` vs `multirepo` em `bootstrap.sh`
- [x] T013 [US2] Exigir e persistir a justificativa da decisão estrutural no fluxo operacional descrito em `bootstrap.sh` e `.specify/feature.json`
- [x] T014 [P] [US2] Atualizar `specs/020-satellite-repo-governance/contracts/topology-intake.contract.md` e `specs/020-satellite-repo-governance/data-model.md` para refletir o formato final do registro da decisão
- [x] T015 [US2] Cobrir AC-3 com testes shell/asserções em `tests/bootstrap/bootstrap-entrypoints.bats`
- [x] T016 [US2] Validar US2 contra AC-3, FR-002, FR-003 e SC-002 em `specs/020-satellite-repo-governance/quickstart.md`

---

## Phase 5: User Story 3 — Sugerir domínios padrão para satélites em greenfield multirepo (Priority: P1) 🎯

**Objetivo**: oferecer uma baseline organizacional de satélites sem engessar a decomposição do produto.

**Independent Test**: seguir o fluxo greenfield multirepo e confirmar que FRONT, BACK, DESIGN, DATA e JOBS aparecem como baseline recomendada, com espaço explícito para adaptação.

- [x] T017 [P] [US3] Atualizar `bootstrap.sh` para fazer o handoff explícito do fluxo multirepo para a definição de domínios após a primeira spec estrutural
- [x] T018 [US3] Implementar em `docs/developer-guide.md` a sugestão da baseline FRONT/BACK/DESIGN/DATA/JOBS na orientação pós-primeira-spec, exigindo justificativa e ownership explícitos em domínios adaptados
- [x] T019 [P] [US3] Atualizar `docs/bounded-contexts.yaml` para registrar a baseline adaptável e a exigência de ownership por domínio
- [x] T020 [P] [US3] Atualizar `README.md` com a recomendação de baseline de domínios satélite e o momento correto de aplicação em projetos greenfield multirepo
- [x] T021 [US3] Sincronizar `specs/020-satellite-repo-governance/research.md`, `specs/020-satellite-repo-governance/data-model.md` e `specs/020-satellite-repo-governance/contracts/topology-intake.contract.md` com a regra final de baseline adaptável, formato mínimo de justificativa e definição de ownership
- [x] T022 [US3] Validar US3 contra AC-4, AC-5, FR-004, FR-005, FR-006 e SC-003 em `specs/020-satellite-repo-governance/quickstart.md`

---

## Phase 6: User Story 4 — Formalizar repo central como fonte única de specs (Priority: P1) 🎯

**Objetivo**: impedir que repositórios satélite virem fonte paralela de `specs/`.

**Independent Test**: revisar a documentação e confirmar que ela separa claramente o papel do repo central do papel do satélite, inclusive quando uma demanda nasce no satélite.

- [x] T023 [P] [US4] Expandir a seção MultiRepo em `docs/developer-guide.md` para declarar explicitamente que `spec.md`, `plan.md`, `tasks.md`, grafos, contratos e checklists vivem apenas no repo central
- [x] T024 [US4] Atualizar `docs/bounded-contexts.yaml` com a formulação final da política “specs só no repo central”
- [x] T025 [P] [US4] Atualizar `README.md` para refletir o papel do repo central versus satélites no onboarding greenfield
- [x] T026 [US4] Atualizar `templates/BROWNFIELD-SETUP-CHECKLIST.md` para evitar que o fluxo brownfield sugira `specs/` locais em satélites
- [ ] T027 [US4] Obter aprovação humana da regra “specs só no repo central” contra AC-6, FR-007 e FR-008 em `specs/020-satellite-repo-governance/quickstart.md`

---

## Phase 7: User Story 5 — Garantir alinhamento contínuo do bundle entre central e satélites (Priority: P2)

**Objetivo**: reaproveitar o mecanismo oficial de update do bundle como regra de governança central → satélite.

**Independent Test**: verificar que a documentação e os templates deixam inequívoco que o satélite se atualiza pelo mecanismo oficial e sempre por PR revisado.

- [x] T028 [P] [US5] Atualizar `docs/developer-guide.md` com o processo operacional central → satélite baseado no workflow oficial de update
- [x] T029 [US5] Atualizar `templates/workflows/update-speckit-and-bundle.yml` para reforçar, via comentários/documentação inline, o papel do workflow no alinhamento entre repo central e satélites
- [x] T030 [P] [US5] Atualizar `README.md` para explicar quando e como o workflow oficial deve ser usado em satélites bootstrapados
- [x] T031 [US5] Validar US5 contra AC-7, FR-009, FR-010 e SC-004 em `specs/020-satellite-repo-governance/quickstart.md`

---

## Phase 8: Polish & Cross-Cutting Concerns

**Objetivo**: concluir a consistência final, cobertura de testes e artefatos de governança da feature.

- [x] T032 [P] Consolidar a consistência terminológica e a separação FR-011 entre governança permanente e bugfix operacional em `bootstrap.sh`, `README.md`, `docs/developer-guide.md`, `docs/bounded-contexts.yaml` e `templates/BROWNFIELD-SETUP-CHECKLIST.md`
- [x] T033 [P] Atualizar `specs/020-satellite-repo-governance/plan.md`, `specs/020-satellite-repo-governance/graph.yaml`, `specs/020-satellite-repo-governance/graph.md` e `specs/020-satellite-repo-governance/impact-map.md` para refletir a implementação final
- [x] T034 Adicionar entrada reutilizável de governança greenfield multi-repo em `docs/reuse-catalog.yaml`
- [ ] T035 Obter Go/No-Go humano para os cenários AC-1 a AC-7 e a separação FR-011 em `specs/020-satellite-repo-governance/quickstart.md`
- [ ] T045 Definir o plano de adoção pós-release do SC-005, incluindo baseline histórica, janela de medição, owner, fonte de evidência e cálculo da redução de 80% em `specs/020-satellite-repo-governance/quickstart.md`

---

## Dependencies & Execution Order

1. **Phase 1** → prepara a linguagem e os artefatos compartilhados  
2. **Phase 2** → cria os pré-requisitos técnicos transversais  
3. **US1 (Phase 3)** depende de Phase 2  
4. **US2 (Phase 4)** depende de US1, porque a escolha mono vs multirepo só faz sentido após a classificação inicial  
5. **US3 (Phase 5)** depende de US2  
6. **US4 (Phase 6)** pode avançar em paralelo com US3 após US2, porque governa documentação central/satélite  
7. **US5 (Phase 7)** depende de US4  
8. **Phase 8** depende da conclusão de todas as user stories

---

## Parallel Execution Examples

### US1
- Rodar T007 e T009 em paralelo; depois consolidar com T008, T010 e T011.

### US2
- Rodar T012 e T014 em paralelo; depois consolidar com T013, T015 e T016.

### US3
- Rodar T017 e T020 em paralelo; depois consolidar com T018, T021 e T022.

### US4
- Rodar T023, T024, T025 e T026 em paralelo; depois consolidar com T027.

### US5
- Rodar T028 e T030 em paralelo; depois consolidar com T029 e T031.

### Polish
- Rodar T032 e T033 em paralelo; depois concluir com T034 e T035.

---

## Implementation Strategy

### MVP First (Recommended)
1. Completar **Phase 1** e **Phase 2**
2. Entregar **US1** primeiro para fechar a classificação greenfield/brownfield
3. Entregar **US2** logo em seguida para tornar a decisão estrutural rastreável
4. Entregar **US4** para fixar a regra de fonte única de verdade
5. Fechar com **US3**, **US5** e a fase de polish

### Incremental Delivery
- Após **US1**, o bootstrap já deixa de tratar todo repo não vazio como brownfield automaticamente.
- Após **US2**, o fluxo já registra a decisão mono vs multirepo com motivo.
- Após **US3**, greenfield multirepo já recebe baseline organizacional de domínios.
- Após **US4**, a governança central/satélite fica explícita nos artefatos principais.
- Após **US5**, o fluxo central → satélite fica alinhado ao mecanismo oficial de update.

### Suggested MVP Scope
- **MVP recomendado**: **US1 + US2 + US4**
- Justificativa: esse recorte já corrige a entrada estrutural do projeto, torna a decisão de topologia explícita e elimina a ambiguidade sobre onde vivem as specs.

---

## Nimbus-Code — Contrato de Task Executável no GHE

### T027 — Validação humana da regra “specs só no repo central”

## Contexto
Esta tarefa confirma que a documentação final da feature deixa inequívoco que o repo central é a fonte única de `spec.md`, `plan.md`, `tasks.md`, grafos, contratos e checklists, e que repositórios satélite não devem manter `specs/` locais como prática padrão.

## Objetivo
Executar uma revisão humana curta sobre os artefatos operacionais alterados para garantir que não exista ambiguidade de governança entre central e satélites.

## Resultado Esperado
Confirmação documentada de que a regra está clara para um novo integrante do time sem precisar de explicação oral complementar.

## Critérios de Aceite
- [ ] [AC-6] A regra “specs só no repo central” aparece explicitamente em [docs/developer-guide.md](/Users/lrodrigues/projects/nimbus-code-spec-kit-template/docs/developer-guide.md)
- [ ] [AC-6] A regra aparece de forma coerente em [docs/bounded-contexts.yaml](/Users/lrodrigues/projects/nimbus-code-spec-kit-template/docs/bounded-contexts.yaml)
- [ ] [AC-6] O fluxo brownfield não incentiva `specs/` locais em [templates/BROWNFIELD-SETUP-CHECKLIST.md](/Users/lrodrigues/projects/nimbus-code-spec-kit-template/templates/BROWNFIELD-SETUP-CHECKLIST.md)

## Passos Operacionais
1. Ler as seções alteradas de [docs/developer-guide.md](/Users/lrodrigues/projects/nimbus-code-spec-kit-template/docs/developer-guide.md), [docs/bounded-contexts.yaml](/Users/lrodrigues/projects/nimbus-code-spec-kit-template/docs/bounded-contexts.yaml) e [templates/BROWNFIELD-SETUP-CHECKLIST.md](/Users/lrodrigues/projects/nimbus-code-spec-kit-template/templates/BROWNFIELD-SETUP-CHECKLIST.md).
2. Verificar se um novo integrante do time conseguiria responder, sem contexto adicional, onde vivem os artefatos de spec e o que um satélite deve ou não armazenar.
3. Se houver ambiguidade, devolver feedback no PR ou abrir issue de ajuste antes do merge.

## Dependências
T023, T024, T025, T026

## Responsável
Agente: não
Humano: sim

## Estimativa de Esforço
- Tokens (agente): ~0 mil
- Horas (humano): ~0,5–1 hora

## Referência
- AC-ID: AC-6
- Feature: `specs/020-satellite-repo-governance`

### T035 — Validação humana final dos cenários da feature

## Contexto
A feature altera governança e onboarding do bootstrap. Antes de concluir, é necessário executar um walkthrough final dos cenários definidos em [quickstart.md](/Users/lrodrigues/projects/nimbus-code-spec-kit-template/specs/020-satellite-repo-governance/quickstart.md).

## Objetivo
Confirmar que os cenários AC-1 a AC-7 permanecem coerentes entre spec, plan, quickstart, documentação e implementação.

## Resultado Esperado
Checklist final aprovado, com confirmação de que a feature pode seguir para implementação/PR sem lacunas de processo.

## Critérios de Aceite
- [ ] [AC-1] O walkthrough distingue greenfield de brownfield
- [ ] [AC-3] A decisão mono vs multirepo exige justificativa
- [ ] [AC-4] A baseline FRONT/BACK/DESIGN/DATA/JOBS aparece como recomendação adaptável
- [ ] [AC-6] A fonte única de verdade do repo central está clara
- [ ] [AC-7] O alinhamento satélite → bundle oficial por PR revisado está claro

## Passos Operacionais
1. Abrir [quickstart.md](/Users/lrodrigues/projects/nimbus-code-spec-kit-template/specs/020-satellite-repo-governance/quickstart.md).
2. Executar a leitura sequencial dos 6 cenários de validação.
3. Conferir os arquivos referenciados em cada cenário.
4. Registrar no PR qualquer divergência encontrada entre documentação, contrato e implementação.

## Dependências
T011, T016, T022, T027, T031, T032, T033, T034

## Responsável
Agente: não
Humano: sim

## Estimativa de Esforço
- Tokens (agente): ~0 mil
- Horas (humano): ~0,5–1 hora

## Referência
- AC-ID: AC-1, AC-3, AC-4, AC-6, AC-7
- Feature: `specs/020-satellite-repo-governance`

---

## ROADMAP — Phase 2: Bootstrap Detection & Satellite Monitoring Automation

*Status*: Backlog — não executar nesta fase
**Estimated Duration**: 1–2 weeks  
**Parallelizable with**: SPEC 022 implementation  
**Complexity**: S2 (build-time scripts, no new service)

### Phase 2 Overview

Phase 1 establishes the governance model and applies it through the documented
workflow. This roadmap item may later automate validation and monitoring so
satellite repos stay synchronized with the central preset version.

### User Stories & Tasks

#### LS-008: Bootstrap Detection & Validation Framework

**Description**: Implement automated detection of mismatched preset versions 
and provide tooling to validate bootstraps.

- [x] **T036**: Implement `detect_preset_version_mismatch()` in bootstrap.sh
  - Compare `.specify/presets/.registry` version with `preset.yml` source version
  - Return exit code 0 if matched, 1 if diverged
  - Output JSON report of mismatches (file, expected, actual)

- [x] **T037**: Add GitHub Actions workflow `validate-bootstrap.yml`
  - Trigger on: PR to any satellite repo touching `.specify/`
  - Run detection logic, fail if version drift detected
  - Comment on PR with version mismatch details

- [x] **T038**: Add test coverage for detection logic
  - Test: exact version match → pass
  - Test: missing .specify/ directory → error
  - Test: stale registry version → detection
  - Test: newer registry than source → warn

#### LS-009: Continuous Satellite Monitoring

**Description**: Extend org-wide audit to run on schedule and report preset 
version drift across all satellite repos.

- [x] **T039**: Extend `scripts/scan-org-rename-references.sh`
  - Add mode: `--mode satellite-preset-audit`
  - Check each repo's `.specify/presets/.registry` vs central v1.16.0
  - Output: CSV report (repo, current version, drift status, last updated)

- [x] **T040**: Create CI job `.github/workflows/satellite-preset-audit.yml`
  - Trigger: Weekly (Monday 09:00 UTC)
  - Run extended audit script
  - Create issue if >0 repos are drifted: 
    "Satellite repos out of sync with v1.16.0: N repos need upgrade"
  - Attach report as artifact

- [x] **T041**: Implement auto-PR creation for drifted repos
  - On audit detection of drift, automatically:
    - Fork branch: `fix/preset-sync-to-vX.Y.Z`
    - Run `bootstrap.sh --refresh-preset`
    - Create PR with title: "fix(preset): sync to v1.16.0"
    - Link to audit issue
  - Only if repo is not already in active development (check for open PRs)

#### LS-010: Phase 2 Quickstart & Documentation

**Description**: Update quickstart and docs to reflect Phase 2 automation.

- [x] **T042**: Update `specs/020-satellite-repo-governance/quickstart.md`
  - Document: "After Phase 1, satellite repos receive automated preset sync"
  - Include: Weekly audit schedule, auto-PR flow, manual override steps

- [x] **T043**: Add section to `docs/developer-guide.md`
  - Title: "Automated Preset Synchronization (Phase 2)"
  - Explain: How weekly audit works, how auto-PRs are created, how to disable

- [x] **T044**: Document in `docs/label-taxonomy-and-autonomous-dev.md`
  - Add label: `sync:preset-version` (auto-applied by audit-generated PRs)
  - Add: How to override auto-sync, coordination with feature work

---

**End of roadmap scope. Estimated future effort: 1–2 weeks.**
