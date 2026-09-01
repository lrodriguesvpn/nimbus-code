# Implementation Tasks: Bootstrap Governance & Repo Provisioning Hardening

**Feature**: Bootstrap Governance & Repo Provisioning Hardening
**Feature Branch**: `008-bootstrap-governance-hardening`
**Complexity**: S3 (revisão humana obrigatória — mudança de mecanismo de autenticação)
**Created**: 2026-08-20

**Input**: Design docs from `specs/008-bootstrap-governance-hardening/` (plan.md, research.md, data-model.md, contracts/, quickstart.md, graph.yaml, impact-map.md)

---

## Overview

Verificação contra o código atual confirma que **nenhum item do escopo desta
feature existe hoje** — `bootstrap.sh` não pergunta tipo de repositório, não
há validador de paridade de templates, nenhum workflow usa GitHub App, o
preset `nimbus-code-platform-standards` não tem `ISSUE_TEMPLATE`, e não existe
manual de skills. Todas as tasks abaixo são trabalho novo.

**Total Tasks**: 30 tasks across 8 phases
**MVP Scope**: Phase 1 (Setup) + Phase 2 (Foundational) + Phase 3 (User Story 1 — seleção de preset)

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
- [ ] T005 [Humano] Criar e instalar o GitHub App organizacional "Nimbus Bootstrap Automation" na organizacao `venha-pra-nuvem`, com permissoes somente as necessarias (organization_projects, issues) - acao administrativa, ver `docs/adr/0008-github-app-para-varredura-de-seguranca-org-wide.md` como precedente de processo _(bloqueada: requer criacao administrativa real do GitHub App; decisao consolidada em [issue #72](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/issues/72) junto com specs 003/007 — aguardar decisao de App unico antes de criar um App isolado)_
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

**Goal**: `ensure-github-project.yml`, `add-to-repo-project.yml`, `sync-priority-field.yml` e `agent-auto-assign.yml` autenticam via GitHub App, com fallback para PAT durante o rollout.

**Independent Test**: Executar um workflow de escopo organizacional e confirmar autenticação via token de instalação, sem exigir PAT.

- [x] T017 [P] [US4] Migrar `.github/workflows/ensure-github-project.yml` para usar `actions/create-github-app-token@v1` com fallback para `VPNDEV_PROJECT_TOKEN`, per [contracts/github-app-auth-contract.md](./contracts/github-app-auth-contract.md) (depende de T006)
- [x] T018 [P] [US4] Migrar `.github/workflows/add-to-repo-project.yml` com o mesmo padrao (depende de T006)
- [x] T019 [P] [US4] Migrar `.github/workflows/sync-priority-field.yml` com o mesmo padrao (depende de T006)
- [x] T020 [P] [US4] Migrar `.github/workflows/agent-auto-assign.yml` com o mesmo padrao (depende de T006)
- [x] T021 [US4] Confirmar que `.github/workflows/graph-guard.yml` (escopo do proprio repositorio) **nao** e migrado - continua usando `GITHUB_TOKEN` nativo, sem alteracao (AC-5)
- [ ] T022 [US4] Validar o Cenario 3 do [quickstart.md](./quickstart.md) em repositorio piloto: com e sem `NIMBUS_APP_ID`/`NIMBUS_APP_PRIVATE_KEY` configurados _(bloqueada: depende do GitHub App real e dos secrets da T005/T006; fallback foi implementado e validado por inspecao/lint)_

**Checkpoint**: automações cross-repo/org migradas, com rollback seguro via fallback PAT durante o rollout.

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
