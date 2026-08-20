# Implementation Tasks: MultiRepo Support no Spec Kit Template

**Feature**: MultiRepo Support no Spec Kit Template
**Feature Branch**: `006-multirepo-support`
**Complexity**: S3
**Created**: 2026-08-20

---

## Overview

**Nota de geração (2026-08-20)**: Ao gerar este `tasks.md`, uma verificação
contra o estado atual do código revelou que **grande parte da infraestrutura
desta feature já está implementada** (`docs/bounded-contexts.yaml`,
`create-new-feature.sh --bounded-contexts`, `setup-github-project.sh`
vinculação MultiRepo, `developer-guide.md` seção 5, entrada no
`reuse-catalog.yaml`) — provavelmente entregue na mesma sessão que publicou
`spec.md`/`plan.md`/`graph.yaml` na `main`. As tasks abaixo já nascem marcadas
`[x]` onde a verificação confirmou implementação real, e `[ ]` onde a lógica
ainda falta — principalmente nos **skills que orientam o agente**
(`speckit-specify`, `speckit-taskstoissues`), que nunca foram atualizados para
validar bounded context ou rotear/deduplicar tasks entre repos.

**Total Tasks**: 20 tasks (13 já concluídas na verificação, 7 pendentes)

---

## Phase 1: Setup & Schema

- [x] T001 Criar `docs/bounded-contexts.yaml` com schema `repository`/`stack`/`team`/`autonomous_ok` e exemplo do próprio repositório template
- [x] T002 [P] Atualizar `presets/nimbus-code-standards/templates/project-root/bounded-contexts.yaml` (e cópia ativa em `.specify/presets/`) com o schema completo e exemplos comentados (AC-15)
- [x] T003 [P] Adicionar entrada `multirepo-bounded-context-routing` em `docs/reuse-catalog.yaml` com tag, bounded context e source

**Checkpoint**: schema de bounded contexts existe e está documentado no preset.

---

## Phase 2: Foundational — Resolução de Repos

- [x] T004 Implementar flag `--bounded-contexts <slug1,slug2>` em `.specify/scripts/bash/create-new-feature.sh` (parsing de argumento)
- [x] T005 Implementar resolução de slugs → repositórios via leitura de `docs/bounded-contexts.yaml` em `create-new-feature.sh`
- [x] T006 Persistir `bounded_contexts` e `repos` resolvidos em `.specify/feature.json` (AC-4)
- [x] T007 Implementar comportamento de compatibilidade retroativa: `feature.json` sem `bounded_contexts` = `[]`/`[]`, sem erro (AC-5, AC-10)
- [x] T008 Implementar validação de slug inválido: abortar com lista de slugs válidos disponíveis (AC-6)

**Checkpoint**: `create-new-feature.sh` resolve e persiste bounded contexts corretamente.

---

## Phase 3: User Story — Validação de Bounded Context pelo Agente (AC-2)

**Goal**: O agente, ao preencher o campo "Bounded Context" de uma spec nova,
valida contra os slugs cadastrados em `docs/bounded-contexts.yaml` e rejeita
slugs não cadastrados em vez de aceitar nome ad-hoc.

**Independent Test**: Rodar `/speckit-specify` com um "Bounded Context" que não
existe em `docs/bounded-contexts.yaml` e confirmar que o agente sinaliza a
divergência e propõe adicionar a entrada em vez de prosseguir silenciosamente.

- [ ] T009 [US-AC2] Adicionar instrução em `.github/skills/speckit-specify/SKILL.md` para ler `docs/bounded-contexts.yaml` e validar o campo "Bounded Context" contra os slugs cadastrados antes de finalizar a spec
- [ ] T010 [US-AC2] Adicionar instrução para, quando o slug não existir, o agente propor a adição de uma nova entrada (não usar nome ad-hoc silenciosamente) em `.github/skills/speckit-specify/SKILL.md`

**Checkpoint**: `/speckit-specify` não aceita mais um Bounded Context não cadastrado sem alertar o Dev.

---

## Phase 4: User Story — Roteamento e Deduplicação de Tasks Cross-Repo (AC-7, AC-8, AC-9)

**Goal**: `/speckit-taskstoissues` cria Tasks no repositório correto por seção
`[USN — slug]` do `tasks.md`, sem duplicar issues já criadas em execuções
anteriores, e sem abortar o processamento inteiro se um repo estiver
inacessível.

**Independent Test**: Gerar um `tasks.md` com duas seções `[US1 — auth]` e
`[US2 — frontend-web]` e confirmar que as Tasks de cada seção são criadas no
repositório correto; rodar `/speckit-taskstoissues` novamente e confirmar que
nenhuma issue é duplicada.

- [ ] T011 [P] [US-AC7] Adicionar instrução em `.github/skills/speckit-taskstoissues/SKILL.md` para identificar o repositório de destino de cada task a partir da seção `[USN — slug]` e do `bounded_contexts`/`repos` em `feature.json`
- [ ] T012 [US-AC8] Adicionar tratamento de erro isolado por repositório em `.github/skills/speckit-taskstoissues/SKILL.md`: se um repo estiver inacessível, reportar erro claro e continuar processando os demais, sem abortar tudo
- [ ] T013 [US-AC9] Adicionar instrução de deduplicação por ID de task (`T00N`) em `.github/skills/speckit-taskstoissues/SKILL.md`, reaproveitando o padrão já usado para o repo único (reuse-catalog tag `speckit-deduplication-by-id`), estendido para múltiplos repos

**Checkpoint**: `/speckit-taskstoissues` roteia e deduplica corretamente entre múltiplos repos.

---

## Phase 5: Polish & Verificação

- [x] T014 [P] Adicionar seção "MultiRepo — Registrando Microsserviços" em `docs/developer-guide.md` com passos: preencher `bounded-contexts.yaml`, declarar `bounded_contexts` numa feature, como `/speckit-taskstoissues` roteia Tasks, como verificar o board cross-repo (AC-14)
- [x] T015 [P] Implementar vinculação de repos ao Project V2 via GraphQL `linkProjectV2ToRepository` em `scripts/setup-github-project.sh`, lendo `docs/bounded-contexts.yaml` (AC-11)
- [x] T016 Implementar idempotência da vinculação em `scripts/setup-github-project.sh` — não duplicar vínculo, imprimir "✓ já vinculado" (AC-12)
- [x] T017 Implementar aviso (não abort) quando `bounded-contexts.yaml` está ausente em `scripts/setup-github-project.sh` (AC-13)
- [ ] T018 [P] Corrigir o bug de resolução de `$GIT_ROOT` relatado na [issue #21](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/issues/21) em `scripts/setup-github-project.sh` — hoje usa o diretório do script (`BASH_SOURCE`) em vez do diretório de chamada (`$PWD`) para localizar `docs/bounded-contexts.yaml`, causando vínculo incorreto quando o script é chamado por caminho absoluto de outro clone
- [ ] T019 Validar manualmente os 15 ACs do `spec.md` contra a implementação atual (a maioria já implementada — ver notas de status acima) e registrar resultado em um `quickstart.md` para esta feature (hoje ausente)
- [ ] T020 Adicionar teste unitário bash (`bats`) para a resolução de `--bounded-contexts` em `create-new-feature.sh` (candidato identificado no `plan.md`, AC-4/AC-6), cobrindo caso de slug válido e slug inválido

**Checkpoint**: gaps reais de comportamento do agente fechados; bug conhecido de resolução de path corrigido.

---

## Dependency Graph & Execution Order

```text
Phase 1 (Setup) [T001–T003] — ✅ já concluído
  ↓
Phase 2 (Foundational) [T004–T008] — ✅ já concluído
  ↓
  ├─→ Phase 3 (Validação de Bounded Context) [T009–T010] — pendente
  ├─→ Phase 4 (Roteamento/Dedup Cross-Repo) [T011–T013] — pendente
  ↓
Phase 5 (Polish & Verificação) [T014–T020] — parcialmente pendente (T018–T020)
```

## Parallel Opportunities

- T009–T010 (Phase 3) e T011–T013 (Phase 4) podem ser feitas em paralelo — arquivos diferentes (`speckit-specify/SKILL.md` vs. `speckit-taskstoissues/SKILL.md`)
- T018, T019, T020 (Phase 5) são independentes entre si

## Implementation Strategy

### Escopo restante real (não repetir trabalho já feito)

1. **Prioridade 1**: T009–T010 (validação de bounded context no `/speckit-specify`) — fecha o AC-2, hoje o gap mais visível para o Dev.
2. **Prioridade 2**: T011–T013 (roteamento/dedup no `/speckit-taskstoissues`) — sem isso, a promessa central da feature (Tasks no repo certo) não é cumprida pelo agente, mesmo com os scripts prontos.
3. **Prioridade 3**: T018 (bug já relatado na issue #21) — correção pontual, não bloqueia as demais.
4. **Prioridade 4**: T019–T020 — validação e teste, fecham o ciclo de qualidade.

### Validation Strategy

- Usar o `quickstart.md` a ser criado em T019 como checklist de validação E2E, no mesmo padrão das demais specs (002, 003, 005, 007, 008, 009).
