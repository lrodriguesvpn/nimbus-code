# Tasks: Controle de Custos

> **Backlog:** estas tarefas não serão executadas agora. Retomar somente após
> nova priorização e revisão dos achados documentais da SPEC.

## Phase 1: Setup e decisões

- [ ] T001 [P] Criar contrato de evento de sessão em `contracts/session-cost-event.contract.md`.
- [ ] T002 [P] Criar contrato de leitura do GitHub Project em `contracts/human-hours-source.contract.md`.
- [ ] T003 [P] Atualizar `plan.md`, `data-model.md` e `api-contract.md` com moeda, fontes, retenção e escopo do MVP.

## Phase 2: Fundação

- [ ] T004 Criar migrations para `CostRecord`, `CostEstimate`, `Budget`, `CostAlert` e `CostBenchmark`.
- [ ] T005 Implementar validação de `feature_id`, `session_id`, moeda, período, correções e rejeição de `dimension=cloud`.
- [ ] T006 Implementar autenticação por papel, TLS, correlação e logs sem prompt/PII.
- [ ] T007 [P] Criar testes de schema e idempotência em `tests/cost-control/`.

## Phase 3: US1/US5 — coleta e comparação

- [ ] T008 [P] Implementar ingestão de eventos de sessão com deduplicação por sessão/evento.
- [ ] T009 Implementar leitura do campo `Horas Humanas`, distinguindo ausência de zero.
- [ ] T010 Implementar conversão USD→BRL com taxa e origem imutáveis.
- [ ] T011 Criar testes de integração para custo real vs. estimado e horas ausentes.

## Phase 4: US2 — budgets e alertas

- [ ] T012 Implementar budgets por sprint/projeto/squad e validação de unicidade.
- [ ] T013 Implementar alertas 80%/100%, deduplicação, retry e falha observável.
- [ ] T014 Criar testes de alerta preventivo, estouro, retry e não duplicação.

## Phase 5: US3/US4 — consulta e benchmarks

- [ ] T015 Implementar endpoints de custos, benchmarks, budget status e exportação.
- [ ] T016 Implementar filtros por período, projeto, squad e complexidade.
- [ ] T017 Implementar benchmarks com limiar mínimo de 10 amostras.
- [ ] T018 Criar testes de contrato, autorização, filtros e exportação.

## Phase 6: Governança e rollout

- [ ] T019 Atualizar templates de `plan.md` com tokens e horas humanas obrigatórios.
- [ ] T020 Configurar rollout com OpenFeature e ativação no projeto piloto.
- [ ] T021 Validar retenção de 12 meses, acesso por papel, backup/restore e ausência de PII.
- [ ] T022 Executar `quickstart.md`, medir SLOs e registrar custo da feature.
- [ ] T023 Obter revisão humana e decisão Go/No-Go antes do rollout.

T004–T007 bloqueiam as histórias; T008–T011 precedem T012–T018;
T019–T023 dependem da implementação funcional e do piloto.
