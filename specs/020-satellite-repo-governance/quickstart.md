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

## Fase 2 — Sincronização Automatizada de Preset

**Visão geral da Fase 2**: após a Fase 1 documentar a governança entre repositório
central e satélites, a Fase 2 automatiza a detecção de drift, a auditoria semanal
e a abertura controlada de PRs de sincronização.

### V8: Auditoria semanal detecta drift de preset

**Cenário**: toda segunda-feira, às 09:00 UTC, o repositório central executa uma
varredura organizacional para descobrir quais satélites estão atrás da versão
corrente do preset.

**Validation steps**:
1. Confirmar em `.github/workflows/satellite-preset-audit.yml` que o gatilho é:
   - `schedule: cron: '0 9 * * 1'`
   - `workflow_dispatch`
2. Confirmar em `scripts/scan-org-rename-references.sh --mode satellite-preset-audit`
   que a versão central é lida de `presets/catalog.json`.
3. Verificar que o CSV de saída contém as colunas:
   - `repo`
   - `current_version`
   - `drift_status`
   - `last_updated`
4. Verificar que os status previstos incluem pelo menos:
   - `in_sync`
   - `drift`
   - `ahead`
   - `not_bootstrapped`
5. Confirmar que, quando `drift > 0`, o workflow cria/atualiza uma issue com o
   título `Satellite repos out of sync with vX.Y.Z: N repos need upgrade`.
6. Confirmar que o artifact `preset-audit-report` é anexado ao run.

**Assertion**: a auditoria semanal transforma drift em evidência rastreável,
com issue + artifact, sem depender de inspeção manual repo a repo.

**Files involved**:
- `.github/workflows/satellite-preset-audit.yml`
- `scripts/scan-org-rename-references.sh`
- `presets/catalog.json`

---

### V9: Fluxo de auto-PR para satélites com drift

**Cenário**: ao encontrar um satélite atrás da versão central, o repositório
central pode abrir automaticamente um PR de sincronização — desde que o satélite
não esteja em desenvolvimento ativo.

**Validation steps**:
1. Confirmar em `.github/workflows/auto-sync-preset.yml` que o workflow recebe:
   - `repo`
   - `target_version`
   - `audit_issue_number` (opcional)
2. Verificar que o workflow consulta `gh pr list` no repositório satélite.
3. Confirmar o guardrail:
   - se houver qualquer PR aberto → **não criar** PR automático
   - se já existir branch/PR `fix/preset-sync-to-vX.Y.Z` → **não duplicar**
4. Verificar que, quando liberado, o workflow:
   - cria branch `fix/preset-sync-to-vX.Y.Z`
   - executa `bootstrap.sh --refresh-preset`
   - abre PR com título `fix(preset): sync to vX.Y.Z`
   - aplica a label `sync:preset-version`
   - referencia a issue da auditoria no corpo do PR (quando informada)
5. Confirmar o override manual documentado:
   - variável `NIMBUS_DISABLE_PRESET_AUTO_SYNC=true` desabilita o auto-dispatch
     mantendo a auditoria semanal ativa
   - PR aberto no satélite bloqueia o auto-sync daquela janela
   - o time ainda pode rodar `bootstrap.sh --refresh-preset` manualmente

**Assertion**: a automação respeita o contexto de trabalho do satélite e não abre
PR em paralelo quando já existe desenvolvimento ativo.

**Files involved**:
- `.github/workflows/satellite-preset-audit.yml`
- `.github/workflows/auto-sync-preset.yml`
- `bootstrap.sh`

---

### V10: Validação de preset em PRs que alteram `.specify/`

**Cenário**: um PR em repositório satélite altera arquivos dentro de `.specify/`.
A CI deve bloquear merge quando o registry estiver defasado em relação à origem
central do preset.

**Validation steps**:
1. Confirmar em `.github/workflows/validate-bootstrap.yml` que o gatilho é
   `pull_request` com path `.specify/**`.
2. Confirmar que o workflow faz checkout do repositório central e executa:
   `./.specify/scripts/bash/detect-preset-version-mismatch.sh --json`
3. Verificar o comportamento por status:
   - `ok` → passa sem comentário de erro
   - `mismatch` → comenta no PR e falha o job
   - `warn` → comenta aviso, mas **não** falha
   - `error` → comenta erro operacional e falha o job
4. Validar o conteúdo do comentário de mismatch:
   - arquivo afetado (`.specify/presets/.registry`)
   - versão esperada
   - versão atual
   - instrução explícita para rodar `bootstrap.sh --refresh-preset`

**Assertion**: drift de preset é detectado cedo, no próprio PR que mexe em
`.specify/`, com mensagem objetiva de correção.

**Files involved**:
- `.github/workflows/validate-bootstrap.yml`
- `.specify/scripts/bash/detect-preset-version-mismatch.sh`
- `bootstrap.sh`

---

### V11: Cobertura de testes para a lógica de detecção

**Cenário**: a função de detecção precisa tratar match, ausência de `.specify/`,
registry defasado e registry mais novo que a origem central.

**Validation steps**:
1. Confirmar em `tests/bootstrap/bootstrap-preset-detection.bats` os cenários:
   - versão exata → `status == "ok"`
   - `.specify/` ausente → `status == "error"`
   - registry desatualizado → `status == "mismatch"`
   - registry mais novo → `status == "warn"` com exit code 0
2. Rodar:
   ```bash
   bats tests/bootstrap/bootstrap-preset-detection.bats
   ```
3. Confirmar que a suíte passa sem depender de `/tmp`, usando diretórios locais
   do próprio repositório para fixtures temporárias.

**Assertion**: a detecção possui cobertura determinística para match, drift,
erro estrutural e aviso de versão à frente.

**Files involved**:
- `tests/bootstrap/bootstrap-preset-detection.bats`
- `.specify/scripts/bash/detect-preset-version-mismatch.sh`
- `bootstrap.sh`

---

## Integração Fase 1 + Fase 2

Com a Fase 2 implementada, o modelo completo fica assim:

1. **Fase 1 (governança)**: o bootstrap classifica greenfield/brownfield,
   registra a decisão mono vs multirepo, reforça o repositório central como
   fonte única de `spec.md`/`plan.md`/`tasks.md` e documenta o fluxo oficial de
   atualização central → satélite.
2. **Fase 2 (automação)**: a auditoria semanal detecta drift, cria/atualiza a
   issue de acompanhamento, despacha o auto-sync quando permitido, e a CI de PR
   barra merges com preset defasado.

**Resultado esperado**: os satélites permanecem próximos da versão central do
preset com rastreabilidade formal (issue, artifact, label e PR revisado), sem
perder o controle humano sobre conflitos ou janelas de desenvolvimento ativo.
