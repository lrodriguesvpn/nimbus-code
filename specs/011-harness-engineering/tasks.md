# Tasks: Harness Engineering — Aprendizado Organizacional com Erros

**Input**: Design documents from `/specs/011-harness-engineering/`

**Prerequisites**: `plan.md` ✅, `spec.md` ✅, `graph.yaml` ✅, `graph.md` ✅, `impact-map.md` ✅

**Organization**: Tasks agrupadas por User Story para entrega incremental e teste independente.

---

## Phase 1: Setup (Artefatos de planejamento)

**Purpose**: Artefatos de grafo, plan.md e spec.md exigidos pelo preset antes de qualquer implementação

- [x] T001 Criar `specs/011-harness-engineering/spec.md` com critérios de aceitação no formato BDD
- [x] T002 [P] Criar `specs/011-harness-engineering/plan.md` com todos os gates preenchidos
- [x] T003 [P] Criar `specs/011-harness-engineering/graph.yaml` com nós, arestas e externals
- [x] T004 [P] Criar `specs/011-harness-engineering/graph.md` com diagramas Mermaid (por código e por business)
- [x] T005 [P] Criar `specs/011-harness-engineering/impact-map.md` com análise de risco e plano de rollback (S3 — obrigatório)

**Checkpoint**: Artefatos de planejamento completos — implementação pode começar.

---

## Phase 2: User Story 1 — Catálogo e documentação base (P1) 🎯

**Goal**: `docs/harness/` existe com catálogo populado, template de post-mortem e guia de uso completos

**Independent Test**: Ler cada arquivo do diretório; validar YAML com `python3 -c "import yaml; yaml.safe_load(open('docs/harness/harness-catalog.yaml'))"` sem erro; verificar que o harness-catalog tem ao menos 3 entradas de exemplo com todos os campos obrigatórios preenchidos.

- [x] T006 [US1] Criar `docs/harness/harness-catalog.yaml` com:
  - Header com schema comentado (id, date, complexity, bounded_context, error_pattern, root_cause, impact, fix_applied, prevention, tags, source_pr, similar_contexts)
  - 3 entradas de exemplo representando padrões de erro reais do NIMBUS CODE:
    - HRN-0001: `agent-scope-creep` (agente editou fora do escopo da sessão)
    - HRN-0002: `silent-architecture-decision` (decisão arquitetural imposta sem ADL)
    - HRN-0003: `reuse-catalog-skip` (feature S3 sem consultar catálogo de reuso)
- [x] T007 [US1] Criar `docs/harness/README.md` com:
  - Conceito de Harness Engineering no contexto NIMBUS CODE
  - Fluxo de uso em ASCII/texto (consultar → mitigar → catalogar)
  - Tabela de arquivos do diretório com propósito de cada um
  - Integração com o ciclo NIMBUS CODE (quando consultar, quando catalogar)
  - Tabela de labels relacionados
- [x] T008 [US1] Criar `docs/harness/harness-guide.md` com:
  - Protocolo de consulta obrigatória para agentes (passo a passo)
  - Protocolo de escrita de entrada de qualidade (princípios + exemplo bem escrito)
  - Exemplos de busca CLI (`grep`, `harness-search.sh`)
  - Ciclo de vida de uma entrada (pending → cataloged)
  - Diferença entre Harness Catalog e Reuse Catalog (tabela comparativa)
  - FAQ
- [x] T009 [US1] Criar `docs/harness/incident-template.md` com:
  - Metadados (ID Harness, data, severity, bounded context, duração, autor)
  - Resumo executivo (1 parágrafo)
  - Timeline (tabela horário × evento)
  - 5 Whys completo (5 perguntas com campo de resposta)
  - Síntese da causa raiz
  - Fix applied (curto prazo + longo prazo)
  - Tabela de ações preventivas (ação, responsável, prazo, issue)
  - Gates que falharam
  - Tags sugeridas (checklist)
  - Checklist de encerramento

**Checkpoint**: `docs/harness/` completo e YAML válido.

---

## Phase 3: User Story 2 — Script de busca (P1) 🎯

**Goal**: `scripts/harness-search.sh` permite busca rápida no catálogo por tags e bounded_context

**Independent Test**: Executar `./scripts/harness-search.sh agent-scope-creep` e verificar que retorna HRN-0001 em < 5s. Executar sem argumentos e verificar mensagem de uso. Executar com tag inexistente e verificar mensagem "Nenhum resultado encontrado".

- [x] T010 [US2] Criar `scripts/harness-search.sh`
  - Argumento posicional: `<tag-ou-bounded-context>` (obrigatório)
  - Argumento opcional: `--file <caminho>` (default: `docs/harness/harness-catalog.yaml`)
  - Lógica de busca: `yq` quando disponível, fallback para `grep`/`awk`
  - Output: ID, error_pattern e prevention de cada entrada que faz match
  - Mensagem de uso quando executado sem argumentos
  - Mensagem "Nenhum resultado encontrado para: <tag>" quando sem match
  - Mensagem de erro quando arquivo de catálogo não existe
  - `chmod +x` no próprio script

**Checkpoint**: Script executável, busca em < 5s, fallback funciona sem `yq`.

---

## Phase 4: User Story 3 — Integração com templates do preset (P1) 🎯

**Goal**: `plan-template.md` tem seção "Harness Gate"; `tasks-template.md` tem passo de catalogação no checklist de fechamento

**Independent Test**: Verificar que `plan-template.md` contém título "Harness Gate". Verificar que `tasks-template.md` contém referência a `harness:pending` no checklist de fechamento. Garantir que nenhuma seção existente foi removida ou alterada nos dois templates.

- [x] T011 [US3] Atualizar `presets/nimbus-code-standards/templates/plan-template.md`
  - Adicionar seção **"Nimbus-Code — Harness Gate"** imediatamente após a seção de Classificação de Complexidade
  - Conteúdo da seção:
    - Instrução: consultar `docs/harness/harness-catalog.yaml` antes de preencher
    - Tabela: `Harnesses consultados | IDs | Padrão de erro evitado | Mitigação aplicada`
    - Campo: `Resultado da consulta` (Sim — match encontrado / Não — nenhum padrão relevante)
    - Nota sobre declaração obrigatória mesmo quando sem match
  - Não remover ou alterar nenhuma seção existente

- [x] T012 [US3] Atualizar `presets/nimbus-code-standards/templates/tasks-template.md`
  - Adicionar item ao checklist de fechamento existente (seção "Checklist de Qualidade de Código, Testes e Observabilidade"):
    - `[ ] Se esta feature gerou retrabalho > 20% ou incidente: Issue aberta com harness:pending, entrada adicionada ao docs/harness/harness-catalog.yaml e Issue fechada com harness:cataloged`

**Checkpoint**: Templates atualizados sem quebrar conteúdo existente.

---

## Phase 5: User Story 4 — Instrução no copilot-instructions.md (P1) 🎯

**Goal**: `copilot-instructions.md` instrui o agente a consultar o harness antes de qualquer `/nimbus-code-plan`

**Independent Test**: Grep por "harness-catalog" em `.github/copilot-instructions.md` retorna resultado. Verificar que a instrução usa linguagem imperativa (DEVE, SEMPRE, ANTES DE). Verificar que nenhuma instrução existente foi removida.

- [x] T013 [US4] Atualizar `.github/copilot-instructions.md`
  - Localizar a seção de instrução sobre o `reuse-catalog.yaml`
  - Adicionar, imediatamente após, instrução explícita sobre o harness:
    - "**Passo obrigatório antes de qualquer `/nimbus-code-plan`**: consulte também `docs/harness/harness-catalog.yaml` buscando por tags e bounded_context relacionados ao domínio da feature."
    - "Se encontrar match, declare na seção 'Harness Gate' do `plan.md`: IDs dos harnesses, padrão de erro evitado e como foi mitigado preventivamente."
    - "Se não encontrar match, declare explicitamente 'Nenhum padrão de erro relevante encontrado' — não deixar em branco."
    - "Se o catálogo estiver vazio, declare 'Catálogo vazio — nenhum padrão disponível para consulta'."
  - Não remover ou alterar instruções existentes

**Checkpoint**: Instrução clara, imperativa e sem ambiguidade no copilot-instructions.

---

## Phase 6: User Story 5 — Labels harness:* no setup-github-labels.sh (P2)

**Goal**: `setup-github-labels.sh` cria os labels `harness:pending`, `harness:cataloged` e `harness:blocking` de forma idempotente

**Independent Test**: Rodar `./scripts/setup-github-labels.sh` 2x num repo de sandbox; verificar que os 3 labels existem após a primeira execução e não são duplicados na segunda. Verificar cores e descrições.

- [x] T014 [US5] Atualizar `scripts/setup-github-labels.sh`
  - Adicionar bloco de labels `harness:*` ao array `LABELS` com comentário explicativo:
    - `harness:pending` — cor `d93f0b` (laranja-vermelho) — "Lição identificada, aguardando catalogação no harness-catalog.yaml"
    - `harness:cataloged` — cor `0e8a16` (verde) — "Lição registrada no docs/harness/harness-catalog.yaml"
    - `harness:blocking` — cor `b60205` (vermelho) — "Padrão de erro crítico — bloqueia merge até revisão explícita do harness"
  - Não alterar labels existentes no array

**Checkpoint**: Labels criados sem erro, idempotentes, cores corretas.

---

## Phase 7: Fechamento e Catálogo de Reuso

**Purpose**: Registrar padrão reutilizável introduzido por esta feature

- [x] T015 Adicionar entrada ao `docs/reuse-catalog.yaml`
  - `tag: "harness-engineering-pattern"`
  - `bounded_context: "spec-kit-workflow"`
  - `description`: padrão de catálogo de erros curatorial (YAML estático + consulta obrigatória pré-plan + labels de rastreabilidade) — reaproveitar sempre que um novo projeto precisar adicionar memória organizacional de falhas
  - `source: "specs/011-harness-engineering/plan.md"`

---

## Dependencies & Execution Order

- **Phase 1 (Setup)**: Sem dependências. ✅ Concluída
- **Phase 2 (US1 — Docs base)**: Depende de Phase 1. ✅ Concluída
- **Phase 3 (US2 — Script)**: Depende de Phase 2 (catálogo precisa existir para teste)
- **Phase 4 (US3 — Templates)**: Pode ser executada em paralelo com Phase 3
- **Phase 5 (US4 — copilot-instructions)**: Pode ser executada em paralelo com Phases 3 e 4
- **Phase 6 (US5 — Labels)**: Pode ser executada em paralelo com Phases 3, 4 e 5
- **Phase 7 (Fechamento)**: Depende de todas as fases anteriores

### Parallel Opportunities

- T010 (Phase 3), T011-T012 (Phase 4), T013 (Phase 5), T014 (Phase 6): paralelos entre si após Phase 2

---

## Notes

- [P] = tasks sem dependência entre si (podem rodar em paralelo)
- [USN] = rastreabilidade da tarefa à User Story do spec.md
- Cada US pode ser testada independentemente antes de seguir para a próxima
- Commits granulares: um por fase concluída
- Antes do merge: validar YAML do `harness-catalog.yaml` e verificar que nenhuma seção existente foi removida dos templates

---

## Nimbus-Code — Contrato de Task Executável no GHE

```markdown
## Contexto
Feature 010 — Harness Engineering: incorporação do conceito de memória
organizacional de erros ao workflow NIMBUS CODE.

## Objetivo
Criar `scripts/harness-search.sh` e atualizar templates e copilot-instructions
para integrar consulta obrigatória ao harness antes do planejamento.

## Resultado Esperado
- harness-search.sh executável, retorna resultado em < 5s
- plan-template.md contém seção "Harness Gate"
- copilot-instructions.md instrui consulta ao harness
- Labels harness:* disponíveis via setup-github-labels.sh

## Critérios de Aceite
- [ ] harness-search.sh retorna HRN-0001 ao buscar "agent-scope-creep"
- [ ] plan-template.md tem título "Nimbus-Code — Harness Gate"
- [ ] copilot-instructions.md contém "harness-catalog.yaml"
- [ ] gh label list mostra harness:pending, harness:cataloged, harness:blocking

## Responsável
Agente: sim
Humano: revisão de PR

## Estimativa de Esforço
- Tokens (agente): ~15–25 mil
- Horas (humano): ~1–2 horas (revisão)

## Referência
- AC-ID: AC-1, AC-2, AC-3, AC-4, AC-5
- Feature: specs/011-harness-engineering
```

- [x] T006-T009 concluídos (Phase 2)
- [ ] T010 (`harness-search.sh`) concluído
- [ ] T011-T012 (templates) concluídos sem quebrar conteúdo existente
- [ ] T013 (copilot-instructions) concluído com instrução imperativa
- [ ] T014 (labels) concluído e idempotente
- [ ] T015 (reuse-catalog) concluído

## Nimbus-Code — Checklist de Qualidade de Código, Testes e Observabilidade

- [ ] `graph.yaml` e `graph.md` atualizados para refletir módulos adicionados ou
      alterados por esta tarefa
- [x] Para complexidade S3: `impact-map.md` criado e revisado antes do merge
- [ ] Critérios de aceitação da `spec.md` cobertos (AC-1 a AC-7) com validação manual documentada
- [ ] Estratégia de release: `direct` — justificada no `plan.md`
- [ ] SLO: `harness-search.sh` < 5s — validado manualmente
- [ ] Revisão de código por IA (GitHub Copilot code review) solicitada no PR
- [ ] Nenhuma seção existente removida de `plan-template.md`, `tasks-template.md` ou `copilot-instructions.md`
- [ ] `harness-catalog.yaml` válido: `python3 -c "import yaml; yaml.safe_load(open('docs/harness/harness-catalog.yaml'))"`
- [ ] Se esta feature gerou retrabalho > 20% ou incidente: Issue aberta com `harness:pending`,
      entrada adicionada ao `docs/harness/harness-catalog.yaml` e Issue fechada com `harness:cataloged`

## Nimbus-Code — Métricas de Branches e Saúde do Repositório (PMO)

| Métrica | Esta semana | Semana anterior | Tendência |
|---|---|---|---|
| Branches ativas (com PR aberto) | | | |
| **Branches perdidas** (sem PR, inativas ≥ 3 dias) | | | ↑ / ↓ / = |
| Branches mergeadas e não-deletadas | | | |
| PRs abertos por agente há > 5 dias sem revisão | | | |

## Nimbus-Code — Estimativa vs. Consumo Real de Tokens e Horas Humanas

| Métrica | Estimado (`plan.md`) | Real | Variância | Fonte da medição |
|---|---|---|---|---|
| Tokens (input+output) | ~25–40 mil | [preencher ao fechar] | — | Copilot Usage da organização |
| Horas humanas | — | [total lançado no GitHub Project] | — | GitHub Project — campo "Horas Humanas" |
