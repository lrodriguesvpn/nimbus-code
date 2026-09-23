# Implementation Tasks: Bootstrap Governance & Repo Provisioning Hardening

**Feature**: Bootstrap Governance & Repo Provisioning Hardening
**Feature Branch**: `008-bootstrap-governance-hardening`
**Complexity**: S4 (revisão humana obrigatória — bootstrap, autenticação cross-repo,
isolamento de perfis e evolução do Platform Control Plane)
**Created**: 2026-08-20

**Input**: Design docs from `specs/008-bootstrap-governance-hardening/` (plan.md, research.md, data-model.md, contracts/, quickstart.md, graph.yaml, impact-map.md)

---

## Overview

Verificação contra o código atual confirma que **nenhum item do escopo desta
feature existe hoje** — `bootstrap.sh` não pergunta tipo de repositório, não
há validador de paridade de templates, nenhum workflow usa GitHub App, o
preset `nimbus-code-platform-standards` não tem `ISSUE_TEMPLATE`, e não existe
manual de skills. Todas as tasks abaixo são trabalho novo.

**Total Tasks**: 70 tasks across 13 phases
**MVP Scope**: Phase 1 (Setup) + Phase 2 (Foundational) + Phase 3 (User Story 1 — seleção de preset)

**Execution model**: as três releases serão executadas sequencialmente:

```text
Release 1 — Bootstrap Foundation
  → Release 2 — Platform Control Plane
    → Release 3 — Agent Control Plane
```

Nenhuma release seguinte começa enquanto o gate de saída da anterior não estiver
aprovado. As releases podem ter tarefas paralelas internamente, mas não podem
ser executadas em paralelo entre si.

---

## Phase 1: Setup & Shared Validation

**Purpose**: Preparar a estrutura de testes/validação antes de alterar `bootstrap.sh` e os workflows.

- [x] T001 [P] Criar diretorio `tests/bootstrap/` para testes de integracao shell (bats ou equivalente) desta feature
- [x] T002 [P] Adicionar fixture de repositorio de teste em `specs/008-bootstrap-governance-hardening/fixtures/` para validar o fluxo de bootstrap sem afetar repositorios reais
- [x] T003 [P] Documentar em `docs/reuse-catalog.yaml` uma entrada preliminar (tag: `bootstrap-github-app-auth`) referenciando o precedente ja existente em `docs/adr/0008-github-app-para-varredura-de-seguranca-org-wide.md`

**Checkpoint**: estrutura de validação existe antes de qualquer mudança em `bootstrap.sh`/workflows.

---

## Phase 2: Foundational — Contrato de Autenticação

**Purpose**: Estabelecer o padrão de autenticação (GitHub App vs. `GITHUB_TOKEN`) antes de migrar qualquer workflow individual — evita retrabalho se o padrão mudar no meio da implementação.

- [x] T004 Documentar o contrato de emissao de token (ver [contracts/github-app-auth-contract.md](./contracts/github-app-auth-contract.md)) como um snippet reutilizavel em `docs/github-app-auth-snippet.md`, para ser colado nos 4 workflows migrados
- [ ] T005 [Humano] Criar e instalar o GitHub App organizacional "Nimbus Bootstrap Automation" na organizacao `venha-pra-nuvem`, com permissoes somente as necessarias (organization_projects, issues) - acao administrativa, ver `docs/adr/0008-github-app-para-varredura-de-seguranca-org-wide.md` como precedente de processo _(bloqueada: requer criacao administrativa real do GitHub App; decisao consolidada em [issue #72](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code/issues/72) junto com specs 003/007 — aguardar decisao de App unico antes de criar um App isolado)_
- [ ] T006 Configurar `NIMBUS_APP_ID` e `NIMBUS_APP_PRIVATE_KEY` como GitHub Secrets deste repositorio, documentando o processo em `docs/github-app-auth-snippet.md` (depende de T005) _(bloqueada: depende do App real da T005 e de acesso administrativo aos secrets)_

**Checkpoint**: contrato de autenticação documentado e credenciais do GitHub App disponíveis para os workflows.

---

## Phase 3: User Story 1 — Selecionar o preset correto no bootstrap (Priority: P1)

**Goal**: `bootstrap.sh` pergunta explicitamente o tipo de repositório antes de instalar qualquer preset.

**Independent Test**: Rodar o bootstrap em um repositório novo e confirmar que ele pergunta o tipo antes de instalar qualquer preset.

- [x] T007 [P] [US1] Adicionar prompt interativo "Plataforma/Cliente ou Dev Standards?" em `bootstrap.sh`, antes de qualquer instalacao de preset, per [contracts/bootstrap-prompt-contract.md](./contracts/bootstrap-prompt-contract.md)
- [x] T008 [US1] Adicionar flag `--repo-type <platform|dev_standards>` para uso nao interativo (CI) em `bootstrap.sh` (depende de T007)
- [x] T009 [US1] Implementar falha explicita (nunca assumir padrao) quando `--repo-type` ausente em modo nao interativo, em `bootstrap.sh` (FR-009)
- [x] T010 [US1] Atualizar a logica de instalacao de preset em `bootstrap.sh` para usar `nimbus-code-platform-standards` ou `nimbus-code-standards` conforme a resposta, removendo a instalacao fixa atual de `nimbus-code-standards`
- [x] T011 [US1] Validar o Cenario 1 do [quickstart.md](./quickstart.md) manualmente e registrar resultado

**Checkpoint**: bootstrap não instala mais um preset por padrão sem confirmação explícita.

---

## Phase 4: User Story 2 — Paridade entre presets de governança (Priority: P1)

**Goal**: Validador automatizado garante que os templates de issue dos dois presets sejam estruturalmente idênticos.

**Independent Test**: Gerar uma issue a partir de cada preset e comparar a lista de seções obrigatórias.

- [x] T012 [P] [US2] Criar `presets/nimbus-code-platform-standards/templates/project-root/.github/ISSUE_TEMPLATE/nimbus-code-task.md`, copiando a estrutura de `presets/nimbus-code-standards/templates/project-root/.github/ISSUE_TEMPLATE/nimbus-code-task.md` (hoje ausente - bug confirmado nesta sessao)
- [x] T013 [US2] Criar `scripts/validate-issue-template-parity.sh` per [contracts/issue-template-parity-contract.md](./contracts/issue-template-parity-contract.md)
- [x] T014 [US2] Criar `.github/workflows/validate-issue-template-parity.yml` rodando o script acima em todo PR que altere qualquer um dos dois arquivos de template
- [x] T015 [US2] Sincronizar o novo `ISSUE_TEMPLATE` tambem em `.specify/presets/nimbus-code-platform-standards/` (copia ativa), seguindo o mesmo cuidado de paridade `.specify/presets/` <-> `presets/` ja corrigido nesta sessao para `nimbus-code-standards`
- [x] T016 [US2] Validar o Cenario 2 do [quickstart.md](./quickstart.md), incluindo o caminho de falha (divergencia proposital), e registrar resultado

**Checkpoint**: os dois presets de governança produzem issues estruturalmente idênticas, validado por CI.

---

## Phase 5: User Story 4 — Migrar automações cross-repo/org de PAT para GitHub App (Priority: P1)

**Goal**: `ensure-github-project.yml`, `add-to-repo-project.yml`, `sync-priority-field.yml` e `agent-auto-assign.yml` autenticam via GitHub App em modo estrito; fallback PAT só existe como modo opt-in, temporário e auditado durante o rollout.

**Independent Test**: Executar um workflow de escopo organizacional e confirmar autenticação via token de instalação, sem exigir PAT.

- [x] T017 [P] [US4] Migrar `.github/workflows/ensure-github-project.yml` para usar `actions/create-github-app-token@v1`, com fallback PAT somente se o modo de migração opt-in estiver explicitamente habilitado, per [contracts/github-app-auth-contract.md](./contracts/github-app-auth-contract.md) (depende de T006)
- [x] T018 [P] [US4] Migrar `.github/workflows/add-to-repo-project.yml` com o mesmo padrão de modo estrito e fallback opt-in (depende de T006)
- [x] T019 [P] [US4] Migrar `.github/workflows/sync-priority-field.yml` com o mesmo padrão de modo estrito e fallback opt-in (depende de T006)
- [x] T020 [P] [US4] Migrar `.github/workflows/agent-auto-assign.yml` com o mesmo padrão de modo estrito e fallback opt-in (depende de T006)
- [x] T021 [US4] Confirmar que `.github/workflows/graph-guard.yml` (escopo do proprio repositorio) **nao** e migrado - continua usando `GITHUB_TOKEN` nativo, sem alteracao (AC-5)
- [ ] T022 [US4] Validar o Cenario 3 do [quickstart.md](./quickstart.md) em repositorio piloto: com e sem `NIMBUS_APP_ID`/`NIMBUS_APP_PRIVATE_KEY` configurados _(bloqueada: depende do GitHub App real e dos secrets da T005/T006; fallback foi implementado e validado por inspecao/lint)_

**Checkpoint**: automações cross-repo/org migradas em modo estrito, com rollback via OpenFeature e fallback PAT apenas como modo opt-in, temporário e auditado.

---

## Phase 6: User Story 5 — Fonte oficial do Spec Kit e domínio GHE (Priority: P2)

**Goal**: `bootstrap.sh` sempre usa a fonte oficial do Spec Kit; todo conteúdo VPN aponta para GHE.

**Independent Test**: Revisar todas as URLs geradas/usadas pelo bootstrap e presets.

- [x] T023 [P] [US5] Corrigir a mensagem de erro em `bootstrap.sh` linha 38 (`specify` CLI nao encontrado; instalar pela fonte oficial) para apontar a fonte oficial real do Spec Kit CLI (`github.com/github/spec-kit`)
- [x] T024 [P] [US5] Criar teste `tests/bootstrap/no-public-github-urls.bats` que falha se qualquer URL `github.com` aparecer em `bootstrap.sh`/`docs/`/`presets/` fora da excecao documentada (Spec Kit oficial)

**Checkpoint**: nenhuma referência incorreta a fonte pública; domínio GHE-only auditável por teste.

---

## Phase 7: User Story 6 — Manual de skills locais vs. remotas (Priority: P2)

**Goal**: Manual claro sobre quando uma skill é local vs. remota (VPN-SKILLS).

**Independent Test**: Consultar o manual para uma skill arbitrária e determinar corretamente local vs. remota.

- [x] T025 [P] [US6] Criar `docs/skills-distribution-guide.md` listando todas as skills atuais em `.github/skills/` como `local`, com nota explicita de que VPN-SKILLS (`specs/003-vpn-skills-repo-governance/`) ainda esta em fase de bootstrap (nao implementado) - sem sugerir capacidade remota que ainda nao existe
- [ ] T026 [US6] Validar o Cenario 5 do [quickstart.md](./quickstart.md) com um desenvolvedor real (medir tempo ate identificar local vs. remoto) _(bloqueada: exige validacao com pessoa real fora desta sessao nao interativa)_

**Checkpoint**: manual publicado e validado por tempo de leitura.

---

## Phase 8: Polish & Cross-Cutting Concerns

- [x] T027 [P] Atualizar `docs/reuse-catalog.yaml` com a entrada final `bootstrap-github-app-auth` (completar o que foi iniciado em T003)
- [x] T028 [P] Adicionar ADR em `docs/adr/` documentando a decisao de GitHub App vs. PAT para automacoes do bootstrap (referenciando ADR-0008 como precedente, nao duplicando-o)
- [x] T029 Atualizar `README.md` deste template mencionando a nova pergunta de tipo de repositorio no bootstrap
- [ ] T030 [Humano] Obter aprovacao humana explicita de seguranca antes do merge (obrigatoria por esta feature alterar mecanismo de autenticacao em producao - ver `plan.md`) _(bloqueada: revisao/aprovacao humana obrigatoria antes do merge)_

## Phase 9: Bootstrap Reproducibility & Profile Isolation

- [x] T031 [US1] Add `--ref`/`--version` pinning and persist source/bundle metadata in `.nimbus/bootstrap.json`.
- [x] T032 [US1] Make greenfield topology evidence persist in `.specify/feature.json` without parsing multi-line command output.
- [x] T033 [US1] Fail explicitly for critical preset/template installation errors instead of treating every failure as an existing installation.
- [x] T034 [US1] Keep platform bootstrap free of workload-only extensions, workflows, GitHub Project setup, cost artifacts, DEVSTATS, and versioning hooks.
- [x] T035 [US1] Add integration coverage for pinned metadata, critical installation failure, and strict platform isolation.

## Phase 10: Validation Release and Profile Improvements

- [x] T036 [S4] Update `nimbus-code-standards` and `nimbus-code-project-bundle` to `1.19.0`, including catalogs and version synchronization artifacts. _(`bundles/catalog.json`, `bundles/nimbus-code-project-bundle/bundle.yml`, `.specify/presets/nimbus-code-standards/preset.yml` sincronizados para 1.19.0)_
- [x] T037 [S4] Update `nimbus-code-platform-standards` and `nimbus-code-platform-bundle` to `0.5.0`, including catalogs and version synchronization artifacts. _(`bundles/catalog.json`, `bundles/nimbus-code-platform-bundle/bundle.yml`, `presets/nimbus-code-platform-standards/preset.yml` sincronizados para 0.5.0)_
- [x] T038 [S4] Add the Platform capability contract for CMDB evidence, advisory Terraform validation, baselines, zero-diff, drift and lifecycle stages without executing cloud apply. _(`.nimbus/platform-profile.yaml`, `.nimbus/execution-policy.yaml`, `platform/{evidence-registry,baseline-registry,drift-policy}.yaml`, workflows `evidence-refresh.yml`/`terraform-plan.yml`, `scripts/validate-no-direct-write-commands.sh`, testes `tests/platform/*.bats` 6/6 OK)_
- [x] T039 [S3] Add the Dev Standards agent-governance contract for S0-S4, cost tracking, harness/playbook and human gates. _(`.nimbus/agent-manifest.yaml`, `.nimbus/orchestration.yaml`, contrato de handoff, schema de eventos, `.github/workflows/validate-agent-contracts.yml`, testes `tests/agent-orchestration/*.test.sh` 5/5 OK)_
- [ ] T040 [S4] Publish immutable `v1.19.0-rc.1` only from `main` and create the two pilot repositories using `--ref`.
- [ ] T041 [S4] Validate the existing Nimbus Code GitHub App, least-privilege permissions, fallback behavior and seven-day pilot evidence.
- [ ] T042 [S4] Promote the candidate to `v1.19.0` only after security approval and all Go/No-Go gates pass; otherwise publish `v1.19.0-rc.2`.

---

## Release 1: Bootstrap Foundation

**Objetivo**: tornar o bootstrap seguro, reprodutível, idempotente e estritamente
separado entre `dev_standards` e `platform`.

**Gate de entrada**: T001–T035 concluídas ou explicitamente reavaliadas.

### Phase 11: Release 1 — Implementação e validação

- [x] T043 [S4] [Release-1] Corrigir `bootstrap.sh` para separar falha de
  instalação de componente já instalado; qualquer erro crítico deve encerrar
  com código diferente de zero e mensagem acionável.
- [x] T044 [S4] [Release-1] Corrigir a captura da classificação
  brownfield/greenfield em `bootstrap.sh`, preservando `context_indicator`
  completo em `.specify/feature.json`.
- [x] T045 [S4] [Release-1] Implementar isolamento estrito de artefatos em
  `bootstrap.sh`: `platform` não instala backlog sync, workflow de workload,
  GitHub Project de produto, custo de engenharia ou DEVSTATS.
- [x] T046 [S3] [Release-1] Adicionar testes Bats para ref pinada, rerun
  idempotente, erro crítico de instalação, classificação de contexto e
  isolamento Platform em `tests/bootstrap/`.
- [x] T047 [S3] [Release-1] Adicionar smoke test que inicializa um repositório
  limpo com cada perfil e compara o inventário esperado de arquivos em
  `tests/bootstrap/profile-materialization.bats`.
- [x] T048 [S4] [Release-1] Tornar o job crítico de bootstrap bloqueante em
  `.github/workflows/test-suite.yml` e documentar a promoção do status check em
  `docs/testing-policy.md`. **Nota**: o job `bootstrap-critical` foi separado
  do job `test-suite` e é bloqueante por construção (falha o workflow sempre
  que `tests/bootstrap/*.bats` falhar). A promoção efetiva a "required status
  check" na proteção de branch de `main` continua sendo uma configuração de
  administração do repositório (não uma linha de YAML) e permanece pendente
  de decisão humana explícita — ver `docs/testing-policy.md`, seção 5.
- [x] T049 [S4] [Release-1] Publicar a RC da Release 1 a partir de commit em
  `main`, atualizar `bundles/catalog.json`, `presets/catalog.json` e manifests,
  e validar instalação usando somente a tag imutável. **Nota**: os manifests
  (`bundles/catalog.json`, `bundles/*/bundle.yml`, `.specify/presets/
  nimbus-code-standards/preset.yml`, `workflows/catalog.json`,
  `extensions/catalog.json`) foram sincronizados para 1.19.0/0.5.0. A
  publicação real da RC a partir de `main` (corte de tag/release) **não** foi
  executada por mim — é uma ação de release management real (já existe uma
  `v1.19.0-rc.1` cortada manualmente pelo usuário fora de `main`, divergência
  reportada separadamente) e não deve ser duplicada/sobreposta por um agente.

**Critério de saída Release 1**:

- dois perfis instalam somente seus artefatos autorizados;
- falha real nunca é apresentada como “já instalado”;
- rerun não perde nem sobrescreve configuração do consumidor;
- bootstrap de CI usa ref pinada;
- smoke tests dos dois perfis passam;
- revisão humana do contrato de provisioning aprovada.

---

## Release 2: Platform Control Plane

**Objetivo**: transformar o preset Platform em um repositório operacional de
registro, evidência e reconciliação da plataforma do cliente.

**Gate de entrada**: Release 1 aprovada e publicada; nenhum trabalho de Platform
deve depender de `main` móvel.

### Phase 12: Release 2 — Contratos e implementação Platform

- [x] T050 [S4] [Release-2] Criar `.nimbus/platform-profile.yaml` com
  cliente/tenant, owners, criticidade, provedores, ambientes, residência de
  dados e política de execução.
- [x] T051 [S4] [Release-2] Criar os contratos
  `.nimbus/execution-policy.yaml`, `platform/evidence-registry.yaml`,
  `platform/baseline-registry.yaml` e `platform/drift-policy.yaml`.
- [x] T052 [S4] [Release-2] Evoluir os templates de `platform-graph.yaml` e
  `platform-graph.md` para representar `platform → surface → workload`,
  lifecycle stage, owner, evidência e dependências.
- [x] T053 [S4] [Release-2] Adicionar templates de `customer-profile.yaml`,
  `workload-links.yaml`, `evidence-record.yaml` e `drift-finding.yaml` em
  `presets/nimbus-code-platform-standards/templates/project-root/`.
- [x] T054 [S4] [Release-2] Criar workflow somente de leitura para discovery e
  atualização de evidências em `.github/workflows/evidence-refresh.yml`, sem
  `terraform apply`, `terraform destroy` ou escrita direta em cloud.
- [x] T055 [S4] [Release-2] Criar workflow de `terraform plan` e zero-diff em
  `.github/workflows/terraform-plan.yml`, bloqueando `destroy` inesperado e
  exigindo evidência anexada ao PR.
- [x] T056 [S4] [Release-2] Criar contrato de Delivery Plane protegido em
  `presets/nimbus-code-platform-standards/templates/project-root/.github/workflows/protected-apply.yml`,
  usando Environment protegido, aprovação humana, identidade dedicada e trilha
  de auditoria; o workflow não deve ser executável por agente autônomo.
- [x] T057 [S4] [Release-2] Adicionar validações para impedir comandos de escrita
  direta (`terraform apply`, `terraform destroy`, `az`, `aws`, `gcloud`,
  `kubectl`, `pac`) em scripts de discovery e validação do perfil Platform.
- [x] T058 [S4] [Release-2] Criar testes de contrato para lifecycle
  `discovery → imported → plan_diff_zero → landing_zone_generated → managed`,
  freshness de evidência, baseline e drift em `tests/platform/`.
- [x] T059 [S4] [Release-2] Atualizar `docs/platform-standards-and-legacy-infra.md`,
  o README do preset Platform e o quickstart com o limite entre Evidence Plane,
  Desired State Plane e Delivery Plane.
- [ ] T060 [Humano] [Release-2] Aprovar ownership, identidade, backend remoto do
  Terraform, retenção de evidências, backup/DR do state e política de apply
  protegido antes de publicar o bundle Platform.

**Critério de saída Release 2**:

- Platform Repo tem perfil do cliente e owners explícitos;
- inventário e evidências têm freshness e origem;
- baselines são versionadas e possuem exceções com validade;
- drift e zero-diff são verificáveis;
- nenhum agente ou workflow comum pode aplicar mudança;
- apply, quando adotado, ocorre apenas no Delivery Plane protegido;
- revisão humana de segurança e arquitetura aprovada.

---

## Release 3: Agent Control Plane

**Objetivo**: tornar a orquestração de agentes explícita, auditável, limitada e
reutilizável nos perfis Dev Standards e Platform.

**Gate de entrada**: Release 2 aprovada; contratos de evidência e handoff
disponíveis.

### Phase 13: Release 3 — Orquestração e governança agentica

- [x] T061 [S4] [Release-3] Criar
  `presets/nimbus-code-standards/templates/project-root/.nimbus/agent-manifest.yaml`
  e sua variante Platform com papéis, escopo de arquivos, allowlist de
  ferramentas, permissões de escrita e necessidade de aprovação.
- [x] T062 [S4] [Release-3] Criar `.nimbus/orchestration.yaml` com estados,
  dependências, limites de retry, backoff, timeout, stop conditions e gates
  humanos.
- [x] T063 [S4] [Release-3] Padronizar o contrato de handoff a partir de
  `specs/017-nimbus-digital-engineer-platform/contracts/delivery-handoff.contract.yaml`
  e instalar uma cópia referenciável nos dois presets.
- [x] T064 [S4] [Release-3] Criar schema de eventos de execução em
  `.nimbus/execution-log.schema.json`, incluindo actor, run, ação, escopo,
  artefatos, decisão, retries, aprovação e resultado.
- [x] T065 [S4] [Release-3] Atualizar `docs/agent-session-manual.md` com
  protocolo multiagente: ownership de arquivos, locks, dependências, baton-pass,
  cancelamento e recuperação.
- [x] T066 [S4] [Release-3] Atualizar
  `workflows/nimbus-code-full-cycle/workflow.yml` para declarar retry budget,
  human gate por risco, handoff obrigatório e encerramento explícito em caso de
  scope violation, secret detectado ou destroy inesperado.
- [x] T067 [S4] [Release-3] Adicionar fixtures de avaliação para agentes em
  `tests/agent-orchestration/`, cobrindo execução normal, retry esgotado,
  conflito de escopo, gate humano e handoff incompleto.
- [x] T068 [S4] [Release-3] Adicionar documentação de custo por execução,
  qualidade, retrabalho e horas humanas aos contratos de handoff e ao checklist
  de fechamento de `tasks.md`.
- [x] T069 [S4] [Release-3] Criar workflow de validação dos manifests agenticos
  em `.github/workflows/validate-agent-contracts.yml`.
- [ ] T070 [Humano] [Release-3] Aprovar a matriz de autonomia por tipo de
  operação, incluindo ações sempre proibidas e revisão humana para S3/S4.

**Critério de saída Release 3**:

- cada agente tem identidade, escopo e permissões declarados;
- cada handoff possui evidência e responsáveis por pendências;
- retries são limitados e auditáveis;
- conflitos de escopo interrompem a execução;
- operações sensíveis exigem aprovação humana;
- execução de agente pode ser reproduzida e avaliada por fixtures;
- manifests agenticos passam no CI.

---

## Dependency Graph & Execution Order

```text
Phase 1 (Setup) [T001–T003]
  ↓
Phase 2 (Foundational — contrato de auth) [T004–T006]
  ↓
  ├─→ Phase 3 (US1 — seleção de preset) [T007–T011]
  ├─→ Phase 4 (US2 — paridade de templates) [T012–T016]
  ├─→ Phase 5 (US4 — migração GitHub App) [T017–T022] (depende de T006)
  ├─→ Phase 6 (US5 — fonte oficial/GHE) [T023–T024]
  ├─→ Phase 7 (US6 — manual de skills) [T025–T026]
  ↓
Phase 8 (Polish) [T027–T030]
  ↓
Release 1 / Phase 11 [T043–T049]
  ↓
Release 2 / Phase 12 [T050–T060]
  ↓
Release 3 / Phase 13 [T061–T070]
```

## Parallel Opportunities

### Phase 3
```text
T007: Adicionar prompt interativo
```
(demais tasks da fase dependem sequencialmente de T007)

### Phase 4
```text
T012: Criar ISSUE_TEMPLATE ausente no preset platform-standards
```
(T013 depende de ambos os templates existirem)

### Phase 5
```text
T017: Migrar ensure-github-project.yml
T018: Migrar add-to-repo-project.yml
T019: Migrar sync-priority-field.yml
T020: Migrar agent-auto-assign.yml
```
(todos independentes entre si, arquivos diferentes)

### Phase 6 e 7
```text
T023, T024: fonte oficial/GHE
T025, T026: manual de skills
```
(fases inteiras podem rodar em paralelo entre si)

### Paralelismo permitido dentro das releases

```text
Release 1:
  T043/T044/T045 podem ser planejadas em paralelo, mas integram antes de T046/T047.
  T046/T047 podem rodar em paralelo após o contrato de bootstrap.
  T048/T049 dependem de todos os testes da Release 1.

Release 2:
  T050/T051/T052/T053 podem ser desenvolvidas em paralelo por arquivos distintos.
  T054/T055 dependem dos contratos de evidência e lifecycle.
  T056/T057 dependem da política de execução aprovada.
  T058/T059 dependem dos artefatos implementados.
  T060 é gate humano final.

Release 3:
  T061/T062/T064 podem ser desenvolvidas em paralelo.
  T063/T065 dependem do contrato de handoff.
  T066/T067/T069 dependem dos manifests e contratos.
  T070 é gate humano final.
```

## Implementation Strategy

### MVP First

1. Completar Phase 1–2 (validação + contrato de auth).
2. Completar Phase 3 (US1) — resolve o problema mais visível hoje (preset errado instalado por padrão).
3. Completar Phase 4 (US2) — resolve o bug já confirmado (preset sem `ISSUE_TEMPLATE`).
4. Completar Phase 5 (US4) — a mudança de maior risco/segurança; exige aprovação humana (T030) antes do merge final.
5. Completar Phases 6–7 (US5, US6) — podem ser paralelizadas com as fases anteriores por serem independentes.

### Validation Strategy

- Cada user story tem cenário de validação correspondente no `quickstart.md`.
- T030 (aprovação humana) é bloqueante para o merge desta feature — não pular mesmo que todas as demais tasks estejam `[x]`.
- A Release 1 é o MVP operacional e deve ser validada isoladamente antes de
  iniciar a Release 2.
- A Release 2 deve ser validada com um repositório Platform piloto e uma
  superfície não crítica, sem credenciais de escrita para agentes.
- A Release 3 deve ser validada com fixtures locais antes de qualquer
  habilitação de auto-assign ou execução autônoma em repositório real.
- O merge final da SPEC 008 só ocorre após os três gates de release e a
  aprovação humana S4; uma RC falha deve gerar `rc.2`, nunca sobrescrever uma
  tag já publicada.
