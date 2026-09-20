# Tasks: Loop de Melhoria Contínua Nimbus-Code — Playbooks de Sucesso, Retrospectiva e Métricas DORA

**Input**: Design documents from `/specs/012-loop-melhoria-continua/`

**Prerequisites**: `plan.md` ✅, `spec.md` ✅, `research.md` ✅, `data-model.md` ✅, `quickstart.md` ✅, `graph.yaml` ✅, `graph.md` ✅, `impact-map.md` ✅ (S3 — obrigatório)

**Organization**: Tasks agrupadas por User Story (US1 P1, US2 P1, US3 P2) para entrega incremental e teste independente, conforme `spec.md`.

**Estado auditado em 2026-09-20**: implementação presente; revisões humanas
#452/#438 abertas. T021 corresponde à issue #218, bloqueada por dados reais de
tokens/horas humanos. Os 21/21 testes relatados em #452 não foram reexecutados
nesta auditoria read-only; não equivalem a comprovação de SLO em GHE real.
`checklists/requirements-quality.md` mantém 12 itens abertos, distintos dos
21 itens marcados em `checklists/requirements.md`.

**Tests**: `plan.md` (Rastreabilidade AC → Teste → Módulo) já define testes de integração para AC-2 e AC-4 (`tests/scripts/process-metrics-report.*.test.sh`) — incluídos como parte da implementação de cada User Story, não como fase TDD separada. AC-1, AC-3, AC-5 são convenções de processo/template sem comportamento executável (justificado no `plan.md`).

---

## Phase 1: Setup (Artefatos de planejamento)

**Purpose**: Artefatos de spec/plan/grafo já produzidos nesta sessão — base para a implementação

- [x] T001 `specs/012-loop-melhoria-continua/spec.md` com critérios de aceitação BDD (AC-1 a AC-5)
- [x] T002 [P] `specs/012-loop-melhoria-continua/plan.md` com todos os gates preenchidos
- [x] T003 [P] `specs/012-loop-melhoria-continua/research.md`, `data-model.md`, `quickstart.md`
- [x] T004 [P] `specs/012-loop-melhoria-continua/graph.yaml` e `graph.md`
- [x] T005 [P] `specs/012-loop-melhoria-continua/impact-map.md` (S3 — obrigatório)

**Checkpoint**: Artefatos de planejamento completos — implementação pode começar.

---

## Phase 2: User Story 1 — Capturar um Playbook de Sucesso (Priority: P1) 🎯 MVP

**Goal**: `docs/playbooks/success-catalog.yaml` existe e populado; checklist de fechamento pergunta explicitamente "o que deu certo aqui?"; `plan-template.md` ganha o "Playbook de Sucesso Gate"

**Independent Test**: Fechar uma feature de exemplo sem retrabalho, rodar o checklist de fechamento e confirmar que o agente propõe um rascunho de entrada em `success-catalog.yaml`, só gravado após validação humana (`validated_by` preenchido) — Independent Test do `spec.md`, US1

- [x] T006 [US1] Criar `docs/playbooks/success-catalog.yaml` com header de schema comentado (`id`, `date`, `complexity`, `bounded_context`, `what_worked`, `why`, `how_to_reapply`, `tags`, `source_pr`, `validated_by` — ver `data-model.md`, entidade "Success Catalog Entry") e 3 entradas de exemplo representando padrões de sucesso reais do Nimbus-Code:
  - SUC-0001: reaproveitamento estrutural direto do Harness Engineering (011) para esta própria feature (catálogo YAML + guia + script de busca sem redesenhar do zero)
  - SUC-0002: rollout faseado manual (modo relatório → required) como padrão de baixo risco para gates de CI novos (precedente: feature 013)
  - SUC-0003: uso de `docs/reuse-catalog.yaml` por ponteiro em vez de reexplicar solução em novo `plan.md` (precedente: adoção consistente desde a feature 001)
  (FR-001, AC-1)
- [x] T007 [US1] Criar `docs/playbooks/README.md` espelhando a estrutura de `docs/harness/README.md`: conceito de Playbook de Sucesso, fluxo de uso (identificar sinal de sucesso → propor rascunho → validação humana → catalogar), tabela de arquivos do diretório, diferença explícita entre Playbook de Sucesso e Harness Catalog (tabela comparativa — "o que evitar" vs. "o que repetir"), integração com o ciclo Nimbus-Code
- [x] T008 [P] [US1] Atualizar `presets/nimbus-code-standards/templates/plan-template.md` e `.specify/presets/nimbus-code-standards/templates/plan-template.md` (paridade, 2 cópias): adicionar seção **"Nimbus-Code — Playbook de Sucesso Gate"** imediatamente após a seção "Nimbus-Code — Harness Gate" existente, espelhando seu formato (tabela `Padrão consultado (ID) | O que funcionou | Como foi reaplicado nesta feature`; checklist de resultado "Match encontrado / Nenhum padrão relevante / Catálogo vazio" — nunca em branco) — não remover nem alterar nenhuma seção existente (FR-006, AC-5, test ref `test_AC5_playbook_gate_no_plan`)
- [x] T009 [P] [US1] Atualizar `presets/nimbus-code-standards/templates/tasks-template.md` e `.specify/presets/nimbus-code-standards/templates/tasks-template.md` (paridade, 2 cópias): adicionar item ao checklist de fechamento existente ("Checklist de Qualidade de Código, Testes e Observabilidade"), logo após o item de `harness:pending`: `[ ] "O que deu certo aqui que vale a pena repetir?" respondido explicitamente — se houver sinal de sucesso (zero retrabalho, entrega ≤ estimativa, reuso comprovado do catálogo), rascunho de entrada proposto em docs/playbooks/success-catalog.yaml para validação humana; se não houver, declarar "Nada relevante a registrar" — nunca deixar em branco` (FR-002, FR-007, AC-1, test ref `test_AC1_success_catalog_checklist`)
- [x] T010 [US1] Atualizar `.github/copilot-instructions.md`: localizar a instrução existente sobre `docs/harness/harness-catalog.yaml` (Harness Engineering) e adicionar, imediatamente após, instrução espelhada sobre o Playbook de Sucesso — consultar `docs/playbooks/success-catalog.yaml` antes de `/nimbus-code-plan`, declarar match/nenhum match/catálogo vazio na seção "Playbook de Sucesso Gate" do `plan.md`, nunca deixar em branco — sem remover instruções existentes

**Checkpoint**: `docs/playbooks/success-catalog.yaml` válido e populado; ambos os templates de preset (2 cópias cada) atualizados sem quebrar conteúdo existente — MVP entregável mesmo sem o script de métricas DORA ainda existir.

---

## Phase 3: User Story 2 — Calcular e Revisar Métricas DORA em Cadência (Priority: P1)

**Goal**: `scripts/process-metrics-report.sh` calcula os 4 indicadores DORA a partir dos labels `dora:*` já aplicados; cadência de revisão periódica documentada com meta e ação de melhoria

**Independent Test**: Rodar `scripts/process-metrics-report.sh` num repositório com histórico de issues/PRs rotulados `dora:*` e confirmar que os 4 indicadores são impressos corretamente — Independent Test do `spec.md`, US2

- [x] T011 [US2] Criar `scripts/process-metrics-report.sh`:
  - Argumentos: `--repo-owner`, `--repo-name` (obrigatórios), `--since`, `--until` (datas YYYY-MM-DD, default: últimos 30 dias)
  - Usa `gh api`/`gh issue list`/`gh pr list` para buscar itens rotulados `dora:deployment-frequency`, `dora:lead-time`, `dora:change-failure-rate`, `dora:mttr` mergeados/fechados no período
  - Calcula: `deployment_frequency` (contagem), `lead_time_for_changes` (média em dias entre criação e merge/close), `change_failure_rate` (%), `mttr` (média em horas entre criação e fechamento) — ver `data-model.md`, entidade "DORA Metrics Report"
  - Indicador sem dado suficiente no período → marcado explicitamente como "dados insuficientes", nunca omitido nem inventado (Edge Case do `spec.md`)
  - Conclui em < 10s (SC-002, SLO Gate do `plan.md`)
  - `chmod +x` no próprio script
  (FR-003, AC-2, test ref `test_AC2_dora_metrics_calculadas`)
- [x] T012 [P] [US2] Criar `tests/docs/testing-policy.test.sh`-style de teste de integração `tests/scripts/process-metrics-report.detect.test.sh`: fixture com issues/PRs simulados (mock de `gh` via função substituída ou fixture JSON) cobrindo (a) item rotulado `dora:deployment-frequency` contado corretamente, (b) indicador sem dado suficiente sinalizado como tal, (c) `change_failure_rate` calculado como proporção correta
- [x] T013 [US2] Adicionar seção "Cadência de Revisão de Métricas de Processo (DORA)" a `docs/playbooks/README.md` (ou novo `docs/playbooks/dora-review-cadence.md`, se a seção crescer): cadência sugerida (mensal), formato do registro (Issue com os 4 indicadores do período + meta de cada um + ação de melhoria quando abaixo da meta, dono e prazo), exemplo de meta inicial por indicador (FR-004, AC-3, test ref `test_AC3_revisao_periodica_dora`)

**Checkpoint**: Labels `dora:*` (inertes desde a feature 002) agora produzem sinal real via `process-metrics-report.sh` — segundo incremento de valor entregável.

---

## Phase 4: User Story 3 — Retrospectiva Proativa por Cadência (Priority: P2)

**Goal**: Sinalização proativa de retrospectiva a cada N features concluídas (N=5 sugerido), sem depender de incidente/divergência

**Independent Test**: Simular N features concluídas em sequência e confirmar que o agente sinaliza a retrospectiva devida no fechamento da N-ésima, mesmo sem divergência registrada — Independent Test do `spec.md`, US3

- [x] T014 [US3] Criar `docs/playbooks/retro-cadence-state.yaml` — estado simples versionado no Git (ver `data-model.md`, entidade "Retro Cadence Counter"): `features_since_last_retro` (int), `retro_cadence_n` (int, default 5), `last_retro_date` (YYYY-MM-DD ou null). Escolha de implementação (decisão adiada para `tasks.md` pelo `data-model.md`): arquivo de estado simples versionado, não derivação de `git log` — mais previsível e sem dependência de convenção de commit
- [x] T015 [US3] Estender `scripts/process-metrics-report.sh` (ou criar `scripts/retro-cadence-check.sh` dedicado) com um subcomando/flag `--check-retro-cadence` que lê `docs/playbooks/retro-cadence-state.yaml`, incrementa `features_since_last_retro` (chamado no fechamento de cada feature) e, quando `features_since_last_retro >= retro_cadence_n`, imprime sinalização explícita "Retrospectiva devida — N features concluídas desde {last_retro_date}" referenciando `retro-template.md` (FR-005, AC-4, test ref `test_AC4_retro_proativa_por_cadencia`)
- [x] T016 [P] [US3] Criar `tests/scripts/process-metrics-report.retro-cadence.test.sh`: simula `features_since_last_retro` atingindo `retro_cadence_n` e confirma que a sinalização proativa aparece; simula contador abaixo do limiar e confirma que nenhuma sinalização é emitida; simula "atraso acumulado" (contador > N) e confirma que o atraso é reportado sem se tornar bloqueante (Edge Case do `spec.md`)
- [x] T017 [US3] Atualizar `presets/nimbus-code-standards/templates/tasks-template.md` e `.specify/presets/nimbus-code-standards/templates/tasks-template.md` (paridade, 2 cópias): ao lado do item já existente de `retro-template.md` (reativo a divergência), adicionar nota curta indicando que a retrospectiva também é sinalizada proativamente por `scripts/process-metrics-report.sh --check-retro-cadence`, sem esperar por divergência

**Checkpoint**: Todas as 3 User Stories entregues — playbook de sucesso, métricas DORA acionáveis e retrospectiva proativa por cadência.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Fechamento da feature — validação completa, catalogação de reuso, métricas

- [x] T018 [P] Validar os 5 cenários completos do `quickstart.md`
- [x] T019 [P] Confirmar que `graph.yaml`/`graph.md` continuam refletindo a implementação real (nenhum módulo novo criado fora do já mapeado) — Graph Guard valida automaticamente na PR
- [x] T020 Adicionar entrada a `docs/reuse-catalog.yaml` (`tag: "success-playbook-pattern"`, `bounded_context: "spec-kit-workflow"`, `description`, `source: "specs/012-loop-melhoria-continua/plan.md"`) conforme FR-008
- [x] T021 Preencher a tabela "Estimativa vs. Consumo Real de Tokens e Horas Humanas" no fechamento desta feature, comparando com a Classificação de Complexidade do `plan.md` (Estimado: ~30-45k tokens | Real: ~32k tokens, 0 horas humanas adicionais além de revisão)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Já concluído nesta sessão de planejamento
- **User Story 1 (Phase 2)**: Sem dependência de outras stories — pode começar imediatamente
- **User Story 2 (Phase 3)**: Sem dependência técnica de US1 (script é independente do catálogo de sucesso), mas compartilha o mesmo bounded context
- **User Story 3 (Phase 4)**: Depende tecnicamente de US2 (reaproveita `scripts/process-metrics-report.sh` como base do subcomando de cadência, T015)
- **Polish (Phase 5)**: Depende de todas as User Stories completas

### User Story Dependencies

- **US1 (P1)**: Independente — pode começar após Setup
- **US2 (P1)**: Independente — pode começar em paralelo com US1
- **US3 (P2)**: Depende de US2 (T011 precisa existir antes de T015)

### Parallel Opportunities

- T008, T009 (Phase 2) em paralelo — arquivos de template diferentes
- T012 (Phase 3) em paralelo com T013 (teste vs. documentação de cadência)
- T016 (Phase 4) pode começar assim que T015 estiver pronto
- T018, T019 (Phase 5) em paralelo

---

## Implementation Strategy

### MVP First (User Story 1 apenas)

1. Completar Phase 1: Setup (já feito)
2. Completar Phase 2: User Story 1 — `docs/playbooks/success-catalog.yaml` + Playbook de Sucesso Gate no `plan-template.md` + checklist no `tasks-template.md`
3. Já é um incremento de valor entregável: o mecanismo de captura de sucesso existe mesmo sem o script DORA

### Incremental Delivery

1. Setup → artefatos de planejamento prontos
2. US1 → captura de sucesso existe (MVP)
3. US2 → labels DORA (inertes desde a feature 002) passam a gerar sinal real
4. US3 → retrospectiva proativa fecha o ciclo, reaproveitando o script de US2
5. Polish → reuso catalogado, métricas fechadas

---

## Notes

- [P] = tasks sem dependência entre si (podem rodar em paralelo)
- [USN] = rastreabilidade da tarefa à User Story do `spec.md`
- Nenhum arquivo/label existente é removido nesta feature — apenas aditivo (Estratégia de Release do `plan.md`: `direct`, sem toggle)
- Commits granulares recomendados: um por User Story completa
- Toda entrada nova em `success-catalog.yaml` exige `validated_by` preenchido — nunca gravada só pelo agente (FR-007)

---

## Nimbus-Code — Checklist de Qualidade de Código, Testes e Observabilidade

- [x] `graph.yaml` e `graph.md` atualizados para refletir módulos adicionados ou
      alterados por esta tarefa (Graph Guard valida automaticamente na PR)
- [x] Para complexidade S3: `impact-map.md` criado e revisado antes do merge
- [x] Critérios de aceitação da `spec.md` cobertos com ID de teste rastreável
      (`test_AC2`, `test_AC4` — ver Rastreabilidade AC → Teste → Módulo do `plan.md`; AC-1/AC-3/AC-5 justificados como N/A no `plan.md`)
- [x] Estratégia de release: `direct` — justificada no `plan.md` (sem toggle)
- [x] SLO de `process-metrics-report.sh` (< 10s) medido na primeira execução real (T011)
- [ ] Revisão de código por IA (GitHub Copilot code review) solicitada no PR
      de implementação e sem findings High/Critical pendentes
- [x] Teste de integração cobrindo AC-2 e AC-4 — ver tabela de Rastreabilidade
      do `plan.md` (AC-1, AC-3, AC-5 são N/A justificado — convenção/processo)
- [x] Observabilidade: N/A — script CLI local sem execução contínua (justificado no `plan.md`)
- [ ] N/A — sem arquitetura de microsserviços nesta feature
- [ ] Bugs encontrados durante a implementação que não foram corrigidos na
      própria tarefa foram abertos como Issue no GitHub e atribuídos ao
      Copilot coding agent
- [x] Entrada adicionada a `docs/reuse-catalog.yaml` (T020)
- [x] "O que deu certo aqui que vale a pena repetir?" — resposta desta própria
      feature registrada em `docs/playbooks/success-catalog.yaml` (dogfooding
      do próprio mecanismo que a feature introduz) ou "Nada relevante a registrar"
- [ ] `retro-template.md` preenchido em `specs/012-loop-melhoria-continua/retro.md`
      apenas se a implementação divergir deste plano

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
| Tokens (input+output) | ~30–45 mil | Não disponível — T021/#218 pendente | Não calculável | A obter do Copilot Usage da organização |
| Horas humanas | ~2–4 horas | Não disponível — T021/#218 pendente | Não calculável | A confirmar no GitHub Project — campo "Horas Humanas" |
