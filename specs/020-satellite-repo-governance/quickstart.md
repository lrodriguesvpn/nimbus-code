# Quickstart: Validar Governança de Repos Satélite e Intake Greenfield MultiRepo

## Purpose

Validar que a feature cobre corretamente a entrada greenfield/brownfield, a
decisão mono vs multirepo e a relação operacional entre repo central e
satélites.

## Prerequisites

- [spec.md](./spec.md) completo
- [plan.md](./plan.md) completo
- [research.md](./research.md) completo
- [data-model.md](./data-model.md) completo
- [contracts/topology-intake.contract.md](./contracts/topology-intake.contract.md) completo
- [graph.yaml](./graph.yaml) e [graph.md](./graph.md) completos
- [impact-map.md](./impact-map.md) completo

## Validation Scenarios (AC-mapped)

### V1: Detecção de Greenfield Real (AC-1)

**Scenario**: Considere um repositório recém-criado contendo apenas `README.md`, `LICENSE`, `.gitignore`, um workflow inicial e script de setup mínimo — nenhum código de aplicação relevante.

**Validation steps**:
1. Abra [spec.md](./spec.md) e localize **AC-1** (linhas 49–53)
2. Confirme em [research.md](./research.md) linhas 11–24 que a decisão greenfield baseia-se apenas em presença de `relevant application code` (definido em [plan.md](./plan.md) linhas 47–48)
3. Verifique em [contracts/topology-intake.contract.md](./contracts/topology-intake.contract.md) linhas 52–53 que esses artefatos isolados NÃO contam como brownfield
4. Confirme que o campo `has_relevant_application_code = false` leva o intake para greenfield (Decision Rules, linha 26)
5. **Assertion**: O fluxo bootstrap apresenta explicitamente a classificação greenfield e a interpretação de ausência de código relevante antes de qualquer sugestão de topologia
6. **Assertion**: A validação cobre FR-001 e SC-001 porque o bootstrap registra a classificação antes de avançar

**Files involved**: 
- `bootstrap.sh` (detector de `relevant application code` no intake)
- `README.md` (orientação de onboarding greenfield/brownfield)
- `docs/developer-guide.md` (seção "Greenfield Intake")
- `spec.md` (AC-1)
- `research.md` (Decision 1)
- `contracts/topology-intake.contract.md` (Operational Notes, lines 52–53)

---

### V2: Detecção de Brownfield Real (AC-2)

**Scenario**: Considere um repositório já contendo `src/`, `app/`, `services/`, testes de aplicação e manifests de build (package.json, pom.xml, Dockerfile, etc.) — código de aplicação existente.

**Validation steps**:
1. Abra [spec.md](./spec.md) e localize **AC-2** (linhas 55–59)
2. Confirme em [data-model.md](./data-model.md) linhas 67–68 que `has_relevant_application_code = true` implica brownfield
3. Verifique em [contracts/topology-intake.contract.md](./contracts/topology-intake.contract.md) linha 26 que esse fluxo segue para "Mandar diretamente para o fluxo brownfield"
4. Confirme que a sugestão padrão de satélites NÃO é feita neste fluxo
5. **Assertion**: O fluxo bootstrap apresenta explicitamente a classificação brownfield e a interpretação de presença de código relevante
6. **Assertion**: A validação continua cobrindo FR-001 e SC-001, agora no caminho brownfield, antes de qualquer orientação estrutural adicional

**Files involved**:
- `bootstrap.sh` (detector de código em `src/`, `app/`, `services/`)
- `README.md` (orientação de onboarding greenfield/brownfield)
- `docs/developer-guide.md` (seção "Brownfield Intake")
- `spec.md` (AC-2)
- `research.md` (Decision 1, lines 13–24)
- `data-model.md` (BootstrapContext fields)

---

### V3: Captura de Razão Topológica (AC-3)

**Scenario**: Um projeto greenfield precisa decidir entre monorepo (um repositório único) e multirepo (múltiplos repositórios por domínio).

**Validation steps**:
1. Abra [spec.md](./spec.md) e localize **AC-3** (linhas 61–65)
2. Verifique em [research.md](./research.md) linhas 31–44 que a decisão mono vs multirepo exige justificativa em formato mínimo legível
3. Confirme em [data-model.md](./data-model.md) linhas 23 e 70–71 que `decision_reason` é obrigatório e deve incluir motivo principal + trade-off esperado
4. Abra [contracts/topology-intake.contract.md](./contracts/topology-intake.contract.md) linhas 15–17 e confirme que `decision_reason` e `decision_owner` são campos Yes (Required) quando greenfield
5. Verifique em [plan.md](./plan.md) linhas 46–50 (Operational Definitions) que `decision_reason` está formalmente definido
6. **Assertion**: O bootstrap captura justificativa estruturada; sem justificativa, a decisão não é aceita

**Files involved**:
- `bootstrap.sh` (prompt de razão topológica com validação)
- `docs/developer-guide.md` (seção "Topology Decision & Justification")
- `docs/bounded-contexts.yaml` (registro de decisões de topologia anteriores)
- `spec.md` (AC-3)
- `research.md` (Decision 2)
- `data-model.md` (TopologyDecision entity)
- `contracts/topology-intake.contract.md` (Decision Rules, line 28)

---

### V4: Sugestão de Baseline de Domínios (AC-4)

**Scenario**: Após a primeira spec estrutural de um projeto greenfield multirepo, o processo sugere uma topologia inicial de domínios.

**Validation steps**:
1. Abra [spec.md](./spec.md) e localize **AC-4** (linhas 67–71)
2. Verifique em [research.md](./research.md) linhas 49–77 que a sugestão ocorre *após* a primeira spec estrutural, com handoff explícito
3. Confirme em [research.md](./research.md) linhas 67–77 que a baseline FRONT/BACK/DESIGN/DATA/JOBS é recomendada, não rígida
4. Abra [data-model.md](./data-model.md) e verifique a entidade `SatelliteDomainProposal` (linhas 26–35)
5. Confirme em [contracts/topology-intake.contract.md](./contracts/topology-intake.contract.md) linha 18 que `satellite_domains` é obrigatório quando `requested_delivery_model = multirepo`
6. Verifique em [docs/developer-guide.md](../../docs/developer-guide.md) (se existente) que a documentação pós-primeira-spec materializa essa baseline
7. **Assertion**: O bootstrap/guia documenta que o time pode adaptar a baseline com justificativa

**Files involved**:
- `bootstrap.sh` (handoff após primeira spec)
- `docs/developer-guide.md` (seção "Post-First-Spec: Domain Baseline Suggestion")
- `docs/bounded-contexts.yaml` (referência de domínios anteriores)
- `spec.md` (AC-4)
- `research.md` (Decision 3)
- `data-model.md` (SatelliteDomainProposal entity)
- `contracts/topology-intake.contract.md` (Input fields, line 18)

---

### V5: Adaptação de Topologia com Ownership (AC-5)

**Scenario**: O time opta por domínios diferentes da baseline sugerida (ex: INFRA, MOBILE em vez de FRONT/BACK).

**Validation steps**:
1. Abra [spec.md](./spec.md) e localize **AC-5** (linhas 73–77)
2. Confirme em [research.md](./research.md) linhas 67–77 que variação é permitida com justificativa + ownership
3. Abra [data-model.md](./data-model.md) e verifique a entidade `SatelliteDomainProposal` linhas 26–35, especialmente o campo `ownership`
4. Confirme em [data-model.md](./data-model.md) linhas 72–73 que domínios `custom` requerem `justification` e `ownership`
5. Abra [contracts/topology-intake.contract.md](./contracts/topology-intake.contract.md) linha 55 e confirme que `custom_domain_ownership` deve identificar claramente a responsabilidade
6. Verifique em [plan.md](./plan.md) linhas 46–50 que `domain ownership` está definido como "team/role/repo responsible"
7. **Assertion**: Cada domínio fora da baseline tem razão + proprietário documentados

**Files involved**:
- `bootstrap.sh` (captura de domínios customizados + justificativa + ownership)
- `docs/developer-guide.md` (seção "Custom Domain Topology")
- `spec.md` (AC-5)
- `research.md` (Decision 4, lines 49–77)
- `data-model.md` (SatelliteDomainProposal entity + Validation Rules)
- `contracts/topology-intake.contract.md` (Custom domain ownership requirement)

---

### V6: Repo Central como Fonte Única de Verdade (AC-6)

**Scenario**: Um ecossistema com repo central e múltiplos repos satélite precisa manter alinhamento de documentação.

**Validation steps**:
1. Abra [spec.md](./spec.md) e localize **AC-6** (linhas 79–83)
2. Confirme em [research.md](./research.md) linhas 79–105 (Decision 5) que repo central é única fonte de verdade para specs
3. Abra [data-model.md](./data-model.md) linhas 50–54 e confirme a entidade `SyncGovernanceRule` define a origem central
4. Verifique em [contracts/topology-intake.contract.md](./contracts/topology-intake.contract.md) linhas 44–45 que specs, plans, tasks e grafos vivem apenas no central
5. Confirme em [data-model.md](./data-model.md) linhas 75–76 que satélites têm `stores_specs = false` como padrão
6. Abra [docs/developer-guide.md](../../docs/developer-guide.md) e confirme que a operação normal proíbe specs locais em satélites
7. **Assertion**: Satélite recebe código, testes, IaC e tasks roteadas, mas nunca specs como default

**Files involved**:
- `bootstrap.sh` (validação no intake)
- `docs/developer-guide.md` (seção "Central Repo Governance")
- `docs/bounded-contexts.yaml` (registro de repos satélite autorizado)
- `spec.md` (AC-6)
- `research.md` (Decision 5)
- `data-model.md` (RepositoryRole + SyncGovernanceRule)
- `contracts/topology-intake.contract.md` (Operational Notes, lines 44–45)

---

### V7: Alinhamento Contínuo Central → Satélite (AC-7)

**Scenario**: O bundle oficial do repo central evoluiu (nova version de bootstrap, templates, ou policies). Um repo satélite precisa atualizar-se.

**Validation steps**:
1. Abra [spec.md](./spec.md) e localize **AC-7** (linhas 85–89)
2. Confirme em [research.md](./research.md) linhas 79–105 (Decision 6) que o mecanismo de alinhamento é contínuo e auditável
3. Abra [data-model.md](./data-model.md) linhas 50–54 (SyncGovernanceRule) e confirme que updates vêm do bundle oficial, não direto
4. Verifique em [contracts/topology-intake.contract.md](./contracts/topology-intake.contract.md) linha 40 que `satellite_update_rule` define o mecanismo
5. Confirme em [data-model.md](./data-model.md) linha 79 (Validation Rules) que `direct_main_update_allowed = false` sempre
6. Abra [docs/developer-guide.md](../../docs/developer-guide.md) (seção "Satellite Update Governance") e confirme que atualizações satélite sempre passam por PR revisado
7. **Assertion**: Satélite NÃO recebe commits diretos no main; bootstrap updates vêm via workflow e revisão

**Files involved**:
- `bootstrap.sh` (mecanismo de update check)
- `docs/developer-guide.md` (seção "Satellite Update & Alignment")
- `docs/bounded-contexts.yaml` (registro de satélites ativos)
- `spec.md` (AC-7)
- `research.md` (Decision 6)
- `data-model.md` (SyncGovernanceRule + Validation Rules)
- `contracts/topology-intake.contract.md` (Satellite Update Rule, line 40)

---

### V8: Separação entre Governança e Bugfix (Cross-AC)

**Scenario**: Distinguir entre regras permanentes de processo (feature 020) e correcções técnicas pontuais do bootstrap.

**Validation steps**:
1. Abra [spec.md](./spec.md) e confirme que FR-011 (linhas 199+) exige separação explícita
2. Abra [plan.md](./plan.md) linhas 46–90 (seção "Escopo Consolidado") e confirme que há seção dedicada separando Governança Permanente de Bugfix Operacional
3. Confirme em [tasks.md](./tasks.md) que a task "Consolidate plan.md scope/separation" foi concluída com essa seção
4. Verifique que cada PR referencia claramente se a mudança é Governança (permanente) ou Bugfix (operacional)
5. **Assertion**: Ninguém confunde processo estruturante com correção técnica pontual

## Expected Outcome

After completing all 8 validation scenarios above, the implementation **must satisfy**:

### For Greenfield Intake (V1, V3, V4, V5)
- ✓ `relevant_application_code` is correctly detected (README/LICENSE/workflows excluded)
- ✓ Mono vs multirepo decision is captured with explicit `decision_reason` (motivo principal + trade-off + responsável)
- ✓ Multirepo projects receive domain baseline (FRONT/BACK/DESIGN/DATA/JOBS) as suggestion, not mandate
- ✓ Custom domains are allowed with `justification` + `domain_ownership` in feature spec

### For Brownfield Intake (V2)
- ✓ `has_relevant_application_code = true` is detected correctly
- ✓ Brownfield flow skips default satellite creation
- ✓ Developer can still create satellites intentionally with full governance

### For Repo Central / Satellite Governance (V6, V7)
- ✓ Repo central is single source of truth for `spec.md`, `plan.md`, `tasks.md`, graphs, impact-maps
- ✓ Satellite receives code, tests, IaC, and task routing — NOT specs by default
- ✓ Satellite updates are always via official bundle mechanism + PR review
- ✓ Direct main commits on satellite are prevented by governance

### For Governance/Bugfix Separation (V8)
- ✓ Feature 020 documentation explicitly separates permanent governance rules from operational bugfixes
- ✓ Every PR is tagged as "Governance" or "Bugfix Operacional" in commit message
- ✓ Process rules are never confused with point fixes

### AC Traceability
- ✓ All 7 ACs (AC-1 through AC-7) are referenced in corresponding validation scenarios
- ✓ Each AC has explicit test reference (e.g., `test_AC1_greenfield_detection`) in `spec.md`
- ✓ Implementation can be validated by running all 8 scenarios end-to-end

### Team Alignment
- ✓ Team can distinguish greenfield from brownfield in real onboarding scenarios
- ✓ Topology decisions are no longer implicit or ad-hoc
- ✓ Domain baseline accelerates decomposition without rigidity
- ✓ Central repo consolidation is now documented and enforced
- ✓ Satellite alignment mechanism is clear and auditable

## Validation Execution Log (2026-08-24)

- ✅ V1 + V2 (AC-1/AC-2): heurística greenfield/brownfield confirmada em `bootstrap.sh` e testes `tests/bootstrap/bootstrap-entrypoints.bats`.
- ✅ V3 (AC-3): captura de `delivery_model`, `decision_reason` e `decision_owner` implementada no bootstrap com persistência em `.specify/feature.json`.
- ✅ V4 + V5 (AC-4/AC-5): handoff explícito para baseline FRONT/BACK/DESIGN/DATA/JOBS adaptável com justificativa + ownership registrado.
- ✅ V6 (AC-6): regra de fonte única no Repo Central reforçada em `docs/developer-guide.md`, `docs/bounded-contexts.yaml` e template brownfield.
- ✅ V7 (AC-7): processo central → satélite via workflow oficial de update reforçado em `docs/developer-guide.md`, `README.md` e `templates/workflows/update-speckit-and-bundle.yml`.
- ✅ V8 (FR-011): separação governança permanente vs bugfix operacional preservada e consolidada nos arquivos de processo.

**Comando executado (evidência):**

```bash
bats tests/bootstrap/bootstrap-entrypoints.bats
```

---

## Phase 2: Automated Preset Synchronization

**Phase 2 Overview**: After Phase 1 establishes the governance model, Phase 2 automates 
ongoing validation and synchronization so satellite repos stay aligned with the central 
preset version without manual intervention.

### V8: Weekly Audit Detects Preset Drift (Phase 2)

**Scenario**: A satellite repository's `.specify/presets/.registry` version lags behind 
the central `preset.yml` version due to delayed PR merges or administrative oversight.

**Validation steps**:

1. Confirm in `.github/workflows/satellite-preset-audit.yml` that:
   - Trigger: Weekly on Monday 09:00 UTC
   - Runs `scripts/scan-org-rename-references.sh --mode satellite-preset-audit`
   - Generates CSV report: `repo,current_version,drift_status,last_updated`

2. Verify in `scripts/scan-org-rename-references.sh` (satellite-preset-audit mode) that:
   - It queries `.specify/presets/.registry` version from each satellite
   - Compares against central `preset.yml` version (1.16.0)
   - Reports: `in_sync`, `drift`, or `not_bootstrapped`

3. Confirm in `.github/workflows/satellite-preset-audit.yml` that:
   - If drifted repos found: Creates issue with title "Satellite repos out of sync with v1.16.0: N repos need upgrade"
   - Attaches CSV report as artifact
   - Labels issue: `type:automation`, `area:preset-sync`, `priority:P2`

**Assertion**: Weekly audit runs automatically and creates actionable issue if drift detected.

**Files involved**:
- `.github/workflows/satellite-preset-audit.yml` (T-047)
- `scripts/scan-org-rename-references.sh` (T-046, satellite-preset-audit mode)
- `.specify/scripts/bash/detect-preset-version-mismatch.sh` (T-043)

### V9: Auto-PR Flow for Drifted Repos (Phase 2)

**Scenario**: The audit detects a drifted satellite repo and attempts to create a PR 
automatically if the repo is not in active development.

**Validation steps**:

1. Confirm in `.github/workflows/auto-sync-preset.yml` that:
   - Trigger: On audit issue creation (`issue opened` event)
   - Also supports: `workflow_dispatch` for manual override

2. Verify workflow logic:
   - Parse drifted repos from audit issue
   - For each repo:
     - Check if there are open PRs (if yes, skip to avoid conflicts)
     - Create branch: `fix/preset-sync-to-vX.Y.Z`
     - Run `bootstrap.sh --refresh-preset`
     - Create PR with title: `fix(preset): sync to vX.Y.Z`
     - Label: `sync:preset-version`, `type:automation`
     - Link to audit issue in PR body

3. Confirm in `bootstrap.sh` that:
   - Supports flag `--refresh-preset` to update preset without full re-initialization
   - Detects version mismatch via `.specify/scripts/bash/detect-preset-version-mismatch.sh`

**Assertion**: Auto-PR creation respects active development (skips repos with open PRs) 
and creates linked PRs for drifted repos.

**Files involved**:
- `.github/workflows/auto-sync-preset.yml` (T-048)
- `bootstrap.sh` (extended with `--refresh-preset` support)
- `.specify/scripts/bash/detect-preset-version-mismatch.sh` (T-043)

### V10: Preset Detection in Validation Workflow (Phase 2)

**Scenario**: A developer opens a PR to a satellite repo touching `.specify/` files. 
The validation workflow should detect if preset version drift exists.

**Validation steps**:

1. Confirm in `.github/workflows/validate-bootstrap.yml` that:
   - Trigger: On PR touching `.specify/`, `bootstrap.sh`, or the workflow itself
   - Runs `.specify/scripts/bash/detect-preset-version-mismatch.sh --json`

2. Verify workflow behavior:
   - Parses JSON output from detection script
   - If `status: "mismatch"` found: Comments on PR with mismatch details
   - Exits with failure code to block merge if drift detected

3. Confirm comment format includes:
   - `⚠️ Preset Version Mismatch Detected`
   - Expected version vs. Actual version
   - Recovery instruction: "Please run bootstrap.sh --refresh-preset"

**Assertion**: PR validation catches preset drift early and provides guidance to fix it.

**Files involved**:
- `.github/workflows/validate-bootstrap.yml` (T-044)
- `.specify/scripts/bash/detect-preset-version-mismatch.sh` (T-043)

### V11: Test Coverage for Detection Logic (Phase 2)

**Scenario**: Verify that the detection function handles all edge cases correctly.

**Validation steps**:

1. Confirm in `tests/bootstrap/bootstrap-preset-detection.bats` that:
   - Test AC-1: Exact version match → exit code 0, status "ok"
   - Test AC-2: Stale registry (e.g., 1.15.0 vs 1.16.0) → exit code 1, status "mismatch"
   - Test AC-3: Missing .registry file → exit code 1, status "error"
   - Test AC-4: JSON output is valid and parseable

2. Run tests:
   ```bash
   bats tests/bootstrap/bootstrap-preset-detection.bats
   ```

3. Verify all tests pass and cover the detection scenarios.

**Assertion**: Detection function is thoroughly tested for matching, drift, and error cases.

**Files involved**:
- `tests/bootstrap/bootstrap-preset-detection.bats` (T-045)
- `.specify/scripts/bash/detect-preset-version-mismatch.sh` (T-043)

---

## Phase 1 + Phase 2 Integration

After Phase 2 implementation, the full governance model is:

1. **Phase 1 (Manual)**: Bootstrap classifies greenfield/brownfield, records topology decision, suggests baseline domains, enforces central repo as source of specs, documents central → satélite update flow.

2. **Phase 2 (Automated)**: Weekly audit detects preset drift, auto-PRs refresh drifted repos, validation workflow catches drift on PR, test coverage ensures detection reliability.

**Expected Outcome**: Satellite repos stay synchronized with central preset version without manual intervention, while governance rules remain explicit and traceable.
