# Implementation Tasks: Codespaces para DEV e CI/CD

**Feature**: Codespaces para DEV e CI/CD
**Feature Branch**: `009-codespaces-dev-planning`
**Complexity**: S3 (planejamento/documentação; revisão humana de adoção pendente em #455/#436, ver estado verificável abaixo)
**Created**: 2026-08-20

**Input**: Design docs from `specs/009-codespaces-dev-planning/` (plan.md, research.md, data-model.md, contracts/, quickstart.md, graph.yaml, impact-map.md)

---

## Overview

Feature de planejamento: o entregável é o devcontainer de referência e a
documentação de decisão, não um rollout em produção. Na geração inicial das
tasks, os artefatos ainda não existiam; esse diagnóstico histórico foi superado
pelo registro de implementação de 2026-08-20 abaixo.

### Estado verificável — 2026-09-20

O devcontainer e os guias existem; JSON e sintaxe do script foram verificados
localmente, sem abrir Codespace. Os 11 marcadores concluídos não aprovam adoção:
[#455](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/issues/455)
e [#436](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/issues/436)
estavam abertas, solicitando decisão do Architecture Board, Platform Lead e
DevSecOps sobre Local First, Codespaces opcional, custos e segredos. Essas
propostas permanecem para decisão humana, não são uma arquitetura aprovada.

A narrativa de #455 diz "11/11" no checklist de qualidade e cita
`checklists/dev-environments-and-cicd-tradeoffs.md`, mas o checkout auditado
mantém os 11 itens de `checklists/requirements-quality.md` abertos e não contém
o checklist adicional. É uma divergência de evidência a reconciliar com #455,
não autorização para criar o artefato ou marcar itens sem revisão. T001,
T006 e T014 continuam pendentes; T009 registra execução em ambiente equivalente,
não teste em Codespace real nem comparação medida de tempo com CI.

**Total Tasks**: 17 tasks across 6 phases
**MVP Scope**: Phase 1 (Setup) + Phase 2 (US1 — devcontainer padrão) + Phase 6 (US5 — Matriz Comparativa e Decisão Go/No-Go)

### Status de Implementação (sessão de agente — 2026-09-20)

**13 de 17 tasks concluídas.** 4 tasks ficam **pendentes de execução/decisão humana**:
- **T001** — confirmação de licenciamento de Codespaces no GHE da organização (administrativo).
- **T006** — validação end-to-end do devcontainer em um Codespace real (validado estruturalmente nesta sessão; falta abertura real).
- **T014** — simulação de Codespace ocioso para confirmar parada automática (requer Codespace real provisionado).
- **T017** — aprovação formal do relatório de decisão Go/No-Go pelo Architecture Board e Platform Lead.

Todos os artefatos de documentação, matriz comparativa (`research.md`), configuração (`devcontainer.json`, `setup-dev-environment.sh`), aceleração de CI/CD (`ci-cd-acceleration-map.md`) e guia de governança com relatório de decisão (`codespaces-adoption-guide.md`) foram criados e validados estruturalmente.

---

## Phase 1: Setup

- [ ] T001 [P] **PENDENTE (fora do escopo de sessão de agente)** — Confirmar disponibilidade/licenciamento de GitHub Codespaces no GHE da organização (`venha-pra-nuvem.ghe.com`) — pré-requisito administrativo/comercial. `research.md` já documenta a decisão de prosseguir com o design técnico independentemente da confirmação (Unknown 1); a confirmação em si requer acesso administrativo ao GHE que este agente não possui — decisão humana necessária.
- [x] T002 [P] Criar diretório `.devcontainer/` na raiz deste template

**Checkpoint**: pré-requisito de licenciamento **pendente de confirmação humana** (ver T001); restante do design prosseguiu conforme decisão registrada em `research.md`.

---

## Phase 2: User Story 1 — Padronizar o ambiente de desenvolvimento via Codespaces (Priority: P1)

**Goal**: Devcontainer de referência funcional, zero-setup.

**Independent Test**: Abrir um Codespace num repositório-piloto e confirmar build/test/lint sem etapas manuais.

- [x] T003 [US1] Criar `.devcontainer/devcontainer.json` com imagem base `mcr.microsoft.com/devcontainers/base:ubuntu` e features Python/Node/GitHub CLI, per [contracts/devcontainer-reference-contract.md](./contracts/devcontainer-reference-contract.md)
- [x] T004 [US1] Criar `scripts/setup-dev-environment.sh` referenciado pelo `postCreateCommand` do devcontainer, instalando dependências específicas deste template (shellcheck, python3, jq)
- [x] T005 [US1] Adicionar extensões VS Code recomendadas (GitHub Copilot, GitLens) em `.devcontainer/devcontainer.json`
- [ ] T006 [US1] **PARCIAL** — Validar o Cenário 1 do [quickstart.md](./quickstart.md) — abrir Codespace de teste e confirmar `python3`/`node`/`gh` disponíveis sem setup manual. Validado estruturalmente nesta sessão (JSON válido, schema conforme `contracts/devcontainer-reference-contract.md`, script `setup-dev-environment.sh` sintaticamente correto via `bash -n`). A validação end-to-end em um Codespace real requer provisionamento de infraestrutura/billing fora do escopo desta sessão de agente — **pendente de execução humana**.

**Checkpoint**: devcontainer de referência validado estruturalmente; validação em Codespace real **pendente**.

---

## Phase 3: User Story 2 — Acelerar CI/CD com prebuilds e validação antecipada (Priority: P1)

**Goal**: Mapear quais etapas de pipeline podem ser validadas antecipadamente num Codespace.

**Independent Test**: Comparar tempo de feedback local (Codespace) vs. CI remoto para uma etapa mapeada.

- [x] T007 [US2] Criar `docs/ci-cd-acceleration-map.md` listando cada etapa do pipeline atual (`validate-manifests.yml`, `graph-guard.yml`, `dependency-review.yml`) e se é executável antecipadamente num Codespace
- [x] T008 [P] [US2] Avaliar e documentar em `docs/ci-cd-acceleration-map.md` o impacto esperado de tempo/custo de habilitar Codespaces prebuilds neste template
- [x] T009 [US2] Validar o Cenário 2 do [quickstart.md](./quickstart.md) — rodar uma etapa mapeada localmente no Codespace e comparar com o resultado do CI. Executado nesta sessão (ambiente Bash/Python equivalente ao devcontainer): `.specify/scripts/bash/validate-hybrid-contracts.sh` e o bloco de validação de schema de `validate-manifests.yml` rodaram com sucesso localmente, produzindo o mesmo resultado que o CI produziria — evidência registrada em `docs/ci-cd-acceleration-map.md`.

**Checkpoint**: mapeamento de aceleração de CI/CD documentado e validado para ao menos 1 etapa.

---

## Phase 4: User Story 3 — Sessões remotas de agentes de IA (Priority: P2)

**Goal**: Modelo de uso de Codespaces para sessões de agente com paridade de segurança do CI.

**Independent Test**: Executar uma sessão de agente num Codespace de teste e verificar escopo de segredos.

- [x] T010 [US3] Criar `docs/codespaces-adoption-guide.md`, seção "Modelo de Sessão de Agente", definindo explicitamente o escopo de segredos permitido (igual à política de CI do repositório)
- [x] T011 [US3] Validar o Cenário 4 do [quickstart.md](./quickstart.md) — revisar a política e confirmar ausência de ambiguidade. Revisão feita nesta sessão: seção 3 de `docs/codespaces-adoption-guide.md` declara explicitamente que o escopo de segredos de uma sessão de agente é sempre idêntico (nunca mais amplo) ao já configurado para o CI/CD do mesmo repositório, sem exceção.

**Checkpoint**: modelo de segurança para sessões de agente documentado e revisado.

---

## Phase 5: User Story 4 — Governar custo e ociosidade (Priority: P2)

**Goal**: Política de parada automática de Codespaces ociosos e visibilidade de custo.

**Independent Test**: Deixar um Codespace ocioso além do limite e confirmar parada automática.

- [x] T012 [P] [US4] Documentar em `docs/codespaces-adoption-guide.md` a configuração nativa recomendada de "Default idle timeout" e "Retention period" do GitHub Codespaces (nível de organização)
- [x] T013 [US4] Criar `.github/workflows/codespaces-idle-governance.yml` (referência/fallback) per [contracts/idle-governance-contract.md](./contracts/idle-governance-contract.md). **Nota**: gatilho configurado como `workflow_dispatch` (manual) em vez de `schedule` — ativar execução automática por cron é decisão de rollout por repositório, pendente de aprovação humana (documentado no próprio workflow e em `docs/codespaces-adoption-guide.md`).
- [ ] T014 [US4] **PENDENTE (requer infraestrutura real)** — Validar o Cenário 3 do [quickstart.md](./quickstart.md) — simular Codespace ocioso e confirmar parada automática. Requer um Codespace real provisionado (billing) e configuração de organização para observar o comportamento de "Default idle timeout" — fora do escopo desta sessão de agente; pendente de execução humana.

**Checkpoint**: política de governança de custo documentada; workflow de referência criado (modo manual); validação end-to-end em Codespace real **pendente**.

---

## Dependency Graph & Execution Order

```text
Phase 1 (Setup) [T001–T002]
  ↓
  ├─→ Phase 2 (US1 — devcontainer padrão) [T003–T006]
  ├─→ Phase 3 (US2 — aceleração CI/CD) [T007–T009] (pode rodar em paralelo com Phase 2)
  ├─→ Phase 4 (US3 — sessão de agente) [T010–T011] (independente)
  ├─→ Phase 5 (US4 — governança de custo) [T012–T014] (independente)
```

## Phase 6: User Story 5 — Avaliar alternativas de DEV local e na nuvem (Google Antigravity/IDX vs Devcontainer Local) (Priority: P1)

**Goal**: Matriz comparativa, análise de ROI e Relatório de Decisão Go/No-Go com recomendação formal.

**Independent Test**: Compilar a matriz de decisão em 8 dimensões e validar o racional de ROI.

- [x] T015 [US5] Pesquisar e compilar Matriz Comparativa (Codespaces vs Google Antigravity/IDX vs Devcontainers Locais) em `specs/009-codespaces-dev-planning/research.md`
- [x] T016 [US5] Estruturar Framework de Decisão Go/No-Go e Relatório de Decisão Arquitetural em `docs/codespaces-adoption-guide.md`
- [ ] T017 [US5] **PENDENTE DE APROVAÇÃO HUMANA** — Submeter o pacote de decisão e a recomendação de "Local First Padronizado (Docker/Colima)" para aprovação do Architecture Board e Platform Lead

---

## Parallel Opportunities

As 4 user stories (Phases 2–5) permitem trabalho documental em paralelo.
Conforme a decisão já registrada em `research.md` e T001, o design prosseguiu
sem confirmação de licenciamento. Provisionamento e validação hospedada
continuam dependendo da confirmação administrativa e dos gates de adoção.

## Implementation Strategy

### MVP First

1. Completar Phase 1 para provisionamento/validação hospedada; confirmação de licenciamento não bloqueia o design documental já autorizado em `research.md`.
2. Completar Phase 2 (US1) — devcontainer funcional é o valor mais direto e demonstrável.
3. Completar Phases 3–5 em paralelo — não há dependência técnica entre elas.

### Validation Strategy

- Cada user story tem cenário de validação correspondente no `quickstart.md`.
- O planejamento inicial não exigia revisão humana bloqueante para produzir os artefatos de referência. Em 2026-09-20, #455/#436 solicitam aprovação formal para a decisão arquitetural/adoção; este saneamento não a concede nem autoriza rollout.
