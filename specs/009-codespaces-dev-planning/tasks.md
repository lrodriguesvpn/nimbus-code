# Implementation Tasks: Codespaces para DEV e CI/CD

**Feature**: Codespaces para DEV e CI/CD
**Feature Branch**: `009-codespaces-dev-planning`
**Complexity**: S3 (sem revisão humana bloqueante — feature de planejamento/documentação)
**Created**: 2026-08-20

**Input**: Design docs from `specs/009-codespaces-dev-planning/` (plan.md, research.md, data-model.md, contracts/, quickstart.md, graph.yaml, impact-map.md)

---

## Overview

Feature de planejamento: o entregável é o devcontainer de referência e a
documentação de decisão, não um rollout em produção. Verificação confirma que
nenhum artefato (`.devcontainer/`, guias de adoção) existe ainda no repositório
— todas as tasks são trabalho novo.

**Total Tasks**: 14 tasks across 4 phases
**MVP Scope**: Phase 1 (Setup) + Phase 2 (US1 — devcontainer padrão)

---

## Phase 1: Setup

- [ ] T001 [P] Confirmar disponibilidade/licenciamento de GitHub Codespaces no GHE da organização (`venha-pra-nuvem.ghe.com`) — pré-requisito administrativo, registrar resposta em `research.md`
- [ ] T002 [P] Criar diretório `.devcontainer/` na raiz deste template

**Checkpoint**: pré-requisito de licenciamento confirmado antes de investir no restante do design.

---

## Phase 2: User Story 1 — Padronizar o ambiente de desenvolvimento via Codespaces (Priority: P1)

**Goal**: Devcontainer de referência funcional, zero-setup.

**Independent Test**: Abrir um Codespace num repositório-piloto e confirmar build/test/lint sem etapas manuais.

- [ ] T003 [US1] Criar `.devcontainer/devcontainer.json` com imagem base `mcr.microsoft.com/devcontainers/base:ubuntu` e features Python/Node/GitHub CLI, per [contracts/devcontainer-reference-contract.md](./contracts/devcontainer-reference-contract.md)
- [ ] T004 [US1] Criar `scripts/setup-dev-environment.sh` referenciado pelo `postCreateCommand` do devcontainer, instalando dependências específicas deste template (shellcheck, python3, jq)
- [ ] T005 [US1] Adicionar extensões VS Code recomendadas (GitHub Copilot, GitLens) em `.devcontainer/devcontainer.json`
- [ ] T006 [US1] Validar o Cenário 1 do [quickstart.md](./quickstart.md) — abrir Codespace de teste e confirmar `python3`/`node`/`gh` disponíveis sem setup manual

**Checkpoint**: devcontainer de referência validado em Codespace real.

---

## Phase 3: User Story 2 — Acelerar CI/CD com prebuilds e validação antecipada (Priority: P1)

**Goal**: Mapear quais etapas de pipeline podem ser validadas antecipadamente num Codespace.

**Independent Test**: Comparar tempo de feedback local (Codespace) vs. CI remoto para uma etapa mapeada.

- [ ] T007 [US2] Criar `docs/ci-cd-acceleration-map.md` listando cada etapa do pipeline atual (`validate-manifests.yml`, `graph-guard.yml`, `dependency-review.yml`) e se é executável antecipadamente num Codespace
- [ ] T008 [P] [US2] Avaliar e documentar em `docs/ci-cd-acceleration-map.md` o impacto esperado de tempo/custo de habilitar Codespaces prebuilds neste template
- [ ] T009 [US2] Validar o Cenário 2 do [quickstart.md](./quickstart.md) — rodar uma etapa mapeada localmente no Codespace e comparar com o resultado do CI

**Checkpoint**: mapeamento de aceleração de CI/CD documentado e validado para ao menos 1 etapa.

---

## Phase 4: User Story 3 — Sessões remotas de agentes de IA (Priority: P2)

**Goal**: Modelo de uso de Codespaces para sessões de agente com paridade de segurança do CI.

**Independent Test**: Executar uma sessão de agente num Codespace de teste e verificar escopo de segredos.

- [ ] T010 [US3] Criar `docs/codespaces-adoption-guide.md`, seção "Modelo de Sessão de Agente", definindo explicitamente o escopo de segredos permitido (igual à política de CI do repositório)
- [ ] T011 [US3] Validar o Cenário 4 do [quickstart.md](./quickstart.md) — revisar a política e confirmar ausência de ambiguidade

**Checkpoint**: modelo de segurança para sessões de agente documentado e revisado.

---

## Phase 5: User Story 4 — Governar custo e ociosidade (Priority: P2)

**Goal**: Política de parada automática de Codespaces ociosos e visibilidade de custo.

**Independent Test**: Deixar um Codespace ocioso além do limite e confirmar parada automática.

- [ ] T012 [P] [US4] Documentar em `docs/codespaces-adoption-guide.md` a configuração nativa recomendada de "Default idle timeout" e "Retention period" do GitHub Codespaces (nível de organização)
- [ ] T013 [US4] Criar `.github/workflows/codespaces-idle-governance.yml` (referência/fallback) per [contracts/idle-governance-contract.md](./contracts/idle-governance-contract.md)
- [ ] T014 [US4] Validar o Cenário 3 do [quickstart.md](./quickstart.md) — simular Codespace ocioso e confirmar parada automática

**Checkpoint**: política de governança de custo documentada e workflow de referência criado.

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

## Parallel Opportunities

Todas as 4 user stories (Phases 2–5) são independentes entre si e podem ser
executadas em paralelo por agentes/desenvolvedores diferentes, desde que
Phase 1 (confirmação de licenciamento) esteja concluída.

## Implementation Strategy

### MVP First

1. Completar Phase 1 (confirmar licenciamento — bloqueante para tudo mais fazer sentido).
2. Completar Phase 2 (US1) — devcontainer funcional é o valor mais direto e demonstrável.
3. Completar Phases 3–5 em paralelo — não há dependência técnica entre elas.

### Validation Strategy

- Cada user story tem cenário de validação correspondente no `quickstart.md`.
- Esta feature não bloqueia merge em revisão humana obrigatória (diferente da 008) — mas revisão é recomendada dado o impacto em todos os times.
