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

**Total Tasks**: 24 tasks across 5 phases
**MVP Scope**: Phase 1 (Setup) + Phase 2 (Foundational) + Phase 3 (User Story 1 — seleção de preset)

---

## Phase 1: Setup & Shared Validation

**Purpose**: Preparar a estrutura de testes/validação antes de alterar `bootstrap.sh` e os workflows.

- [ ] T001 [P] Criar diretório `tests/bootstrap/` para testes de integração shell (bats ou equivalente) desta feature
- [ ] T002 [P] Adicionar fixture de repositório de teste em `specs/008-bootstrap-governance-hardening/fixtures/` para validar o fluxo de bootstrap sem afetar repositórios reais
- [ ] T003 [P] Documentar em `docs/reuse-catalog.yaml` uma entrada preliminar (tag: `bootstrap-github-app-auth`) referenciando o precedente já existente em `docs/adr/0008-github-app-para-varredura-de-seguranca-org-wide.md`

**Checkpoint**: estrutura de validação existe antes de qualquer mudança em `bootstrap.sh`/workflows.

---

## Phase 2: Foundational — Contrato de Autenticação

**Purpose**: Estabelecer o padrão de autenticação (GitHub App vs. `GITHUB_TOKEN`) antes de migrar qualquer workflow individual — evita retrabalho se o padrão mudar no meio da implementação.

- [ ] T004 Documentar o contrato de emissão de token (ver [contracts/github-app-auth-contract.md](./contracts/github-app-auth-contract.md)) como um snippet reutilizável em `docs/github-app-auth-snippet.md`, para ser colado nos 4 workflows migrados
- [ ] T005 [Humano] Criar e instalar o GitHub App organizacional "Nimbus Bootstrap Automation" na organização `venha-pra-nuvem`, com permissões somente as necessárias (organization_projects, issues) — ação administrativa, ver `docs/adr/0008-github-app-para-varredura-de-seguranca-org-wide.md` como precedente de processo
- [ ] T006 Configurar `NIMBUS_APP_ID` e `NIMBUS_APP_PRIVATE_KEY` como GitHub Secrets deste repositório, documentando o processo em `docs/github-app-auth-snippet.md` (depende de T005)

**Checkpoint**: contrato de autenticação documentado e credenciais do GitHub App disponíveis para os workflows.

---

## Phase 3: User Story 1 — Selecionar o preset correto no bootstrap (Priority: P1)

**Goal**: `bootstrap.sh` pergunta explicitamente o tipo de repositório antes de instalar qualquer preset.

**Independent Test**: Rodar o bootstrap em um repositório novo e confirmar que ele pergunta o tipo antes de instalar qualquer preset.

- [ ] T007 [P] [US1] Adicionar prompt interativo "Plataforma/Cliente ou Dev Standards?" em `bootstrap.sh`, antes de qualquer instalação de preset, per [contracts/bootstrap-prompt-contract.md](./contracts/bootstrap-prompt-contract.md)
- [ ] T008 [US1] Adicionar flag `--repo-type <platform|dev_standards>` para uso não-interativo (CI) em `bootstrap.sh` (depende de T007)
- [ ] T009 [US1] Implementar falha explícita (nunca assumir padrão) quando `--repo-type` ausente em modo não-interativo, em `bootstrap.sh` (FR-009)
- [ ] T010 [US1] Atualizar a lógica de instalação de preset em `bootstrap.sh` para usar `nimbus-code-platform-standards` ou `nimbus-code-standards` conforme a resposta, removendo a instalação fixa atual de `nimbus-code-standards`
- [ ] T011 [US1] Validar o Cenário 1 do [quickstart.md](./quickstart.md) manualmente e registrar resultado

**Checkpoint**: bootstrap não instala mais um preset por padrão sem confirmação explícita.

---

## Phase 4: User Story 2 — Paridade entre presets de governança (Priority: P1)

**Goal**: Validador automatizado garante que os templates de issue dos dois presets sejam estruturalmente idênticos.

**Independent Test**: Gerar uma issue a partir de cada preset e comparar a lista de seções obrigatórias.

- [ ] T012 [P] [US2] Criar `presets/nimbus-code-platform-standards/templates/project-root/.github/ISSUE_TEMPLATE/nimbus-code-task.md`, copiando a estrutura de `presets/nimbus-code-standards/templates/project-root/.github/ISSUE_TEMPLATE/nimbus-code-task.md` (hoje ausente — bug confirmado nesta sessão)
- [ ] T013 [US2] Criar `scripts/validate-issue-template-parity.sh` per [contracts/issue-template-parity-contract.md](./contracts/issue-template-parity-contract.md)
- [ ] T014 [US2] Criar `.github/workflows/validate-issue-template-parity.yml` rodando o script acima em todo PR que altere qualquer um dos dois arquivos de template
- [ ] T015 [US2] Sincronizar o novo `ISSUE_TEMPLATE` também em `.specify/presets/nimbus-code-platform-standards/` (cópia ativa), seguindo o mesmo cuidado de paridade `.specify/presets/` ↔ `presets/` já corrigido nesta sessão para `nimbus-code-standards`
- [ ] T016 [US2] Validar o Cenário 2 do [quickstart.md](./quickstart.md), incluindo o caminho de falha (divergência proposital), e registrar resultado

**Checkpoint**: os dois presets de governança produzem issues estruturalmente idênticas, validado por CI.

---

## Phase 5: User Story 4 — Migrar automações cross-repo/org de PAT para GitHub App (Priority: P1)

**Goal**: `ensure-github-project.yml`, `add-to-repo-project.yml`, `sync-priority-field.yml` e `agent-auto-assign.yml` autenticam via GitHub App, com fallback para PAT durante o rollout.

**Independent Test**: Executar um workflow de escopo organizacional e confirmar autenticação via token de instalação, sem exigir PAT.

- [ ] T017 [P] [US4] Migrar `.github/workflows/ensure-github-project.yml` para usar `actions/create-github-app-token@v1` com fallback para `VPNDEV_PROJECT_TOKEN`, per [contracts/github-app-auth-contract.md](./contracts/github-app-auth-contract.md) (depende de T006)
- [ ] T018 [P] [US4] Migrar `.github/workflows/add-to-repo-project.yml` com o mesmo padrão (depende de T006)
- [ ] T019 [P] [US4] Migrar `.github/workflows/sync-priority-field.yml` com o mesmo padrão (depende de T006)
- [ ] T020 [P] [US4] Migrar `.github/workflows/agent-auto-assign.yml` com o mesmo padrão (depende de T006)
- [ ] T021 [US4] Confirmar que `.github/workflows/graph-guard.yml` (escopo do próprio repositório) **não** é migrado — continua usando `GITHUB_TOKEN` nativo, sem alteração (AC-5)
- [ ] T022 [US4] Validar o Cenário 3 do [quickstart.md](./quickstart.md) em repositório piloto: com e sem `NIMBUS_APP_ID`/`NIMBUS_APP_PRIVATE_KEY` configurados

**Checkpoint**: automações cross-repo/org migradas, com rollback seguro via fallback PAT durante o rollout.

---

## Phase 6: User Story 5 — Fonte oficial do Spec Kit e domínio GHE (Priority: P2)

**Goal**: `bootstrap.sh` sempre usa a fonte oficial do Spec Kit; todo conteúdo VPN aponta para GHE.

**Independent Test**: Revisar todas as URLs geradas/usadas pelo bootstrap e presets.

- [ ] T023 [P] [US5] Corrigir a mensagem de erro em `bootstrap.sh` linha 38 (`❌ 'specify' CLI não encontrado. Instale primeiro: https://github.com/github/nimbus-code#-get-started`) — hoje aponta para um caminho público inexistente (`github/nimbus-code`); corrigir para a fonte oficial real do Spec Kit CLI (`github.com/github/spec-kit`)
- [ ] T024 [P] [US5] Criar teste `tests/bootstrap/no-public-github-urls.bats` que falha se qualquer URL `github.com` aparecer em `bootstrap.sh`/`docs/`/`presets/` fora da exceção documentada (Spec Kit oficial)

**Checkpoint**: nenhuma referência incorreta a fonte pública; domínio GHE-only auditável por teste.

---

## Phase 7: User Story 6 — Manual de skills locais vs. remotas (Priority: P2)

**Goal**: Manual claro sobre quando uma skill é local vs. remota (VPN-SKILLS).

**Independent Test**: Consultar o manual para uma skill arbitrária e determinar corretamente local vs. remota.

- [ ] T025 [P] [US6] Criar `docs/skills-distribution-guide.md` listando todas as skills atuais em `.github/skills/` como `local`, com nota explícita de que VPN-SKILLS (`specs/003-vpn-skills-repo-governance/`) ainda está em fase de bootstrap (não implementado) — sem sugerir capacidade remota que ainda não existe
- [ ] T026 [US6] Validar o Cenário 5 do [quickstart.md](./quickstart.md) com um desenvolvedor real (medir tempo até identificar local vs. remoto)

**Checkpoint**: manual publicado e validado por tempo de leitura.

---

## Phase 8: Polish & Cross-Cutting Concerns

- [ ] T027 [P] Atualizar `docs/reuse-catalog.yaml` com a entrada final `bootstrap-github-app-auth` (completar o que foi iniciado em T003)
- [ ] T028 [P] Adicionar ADR em `docs/adr/` documentando a decisão de GitHub App vs. PAT para automações do bootstrap (referenciando ADR-0008 como precedente, não duplicando-o)
- [ ] T029 Atualizar `README.md` deste template mencionando a nova pergunta de tipo de repositório no bootstrap
- [ ] T030 [Humano] Obter aprovação humana explícita de segurança antes do merge (obrigatória por esta feature alterar mecanismo de autenticação em produção — ver `plan.md`)

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
