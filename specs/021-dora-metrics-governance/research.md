# Research: Governança de Métricas DORA com Coleta Híbrida

## Objective

Resolver as decisões de processo necessárias para formalizar definição,
coleta híbrida (automática + manual auditável), interpretação combinada e
conversão de degradação em ação de backlog para os 4 indicadores DORA,
reaproveitando ao máximo a infraestrutura já entregue pela feature
[012-loop-melhoria-continua](../012-loop-melhoria-continua/).

## Decisions

### 1) Definições dos 4 indicadores devem ser textuais, fechadas e centralizadas

**Decision**: manter as definições oficiais (fórmula, evento de origem, janela
de medição) em `docs/playbooks/README.md`, seção já existente "Cadência de
Revisão de Métricas de Processo (DORA)" (feature 012), estendida com a
formalização exigida por FR-001 — em vez de criar um novo documento paralelo.

**Rationale**: a seção já existe e já é referenciada operacionalmente; criar
um segundo documento de definição geraria duas fontes de verdade divergentes.

**Alternatives considered**:
- Criar `docs/dora-metrics-definitions.md` dedicado — descartado por duplicar
  conteúdo já presente em `docs/playbooks/README.md`.
- Definir apenas no `spec.md` desta feature — descartado por não ser um local
  operacional consultado no dia a dia pelas squads.

### 2) Coleta automática continua sendo o caminho padrão via labels `dora:*` já existentes

**Decision**: reaproveitar a taxonomia `dora:*` (feature 002) e o script
`scripts/process-metrics-report.sh` (feature 012) como mecanismo de coleta
automática; a origem de cada métrica (automática) já é implícita no próprio
mecanismo de cálculo baseado em issues/PRs rotulados.

**Rationale**: evita reconstruir um pipeline de coleta que já funciona e já
tem testes de integração (`tests/scripts/process-metrics-report.detect.test.sh`).

**Alternatives considered**:
- Novo pipeline de eventos (webhook dedicado) — rejeitado por complexidade
  desproporcional ao escopo desta feature (governança de processo, não
  infraestrutura de telemetria nova, ver "Fora de escopo" do `spec.md`).

### 3) Ajustes manuais exigem uma trilha de auditoria própria, ainda inexistente

**Decision**: criar `docs/playbooks/dora-manual-adjustments-log.yaml` — um
novo arquivo de estado simples versionado no Git, no mesmo padrão já usado por
`docs/playbooks/retro-cadence-state.yaml` (feature 012) — para registrar cada
ajuste manual com `justification`, `author`, `timestamp`, `evidence_link` e
`exception_category` (ver `data-model.md`, entidade "Manual Adjustment").

**Rationale**: hoje não existe nenhum mecanismo de auditoria para correções
manuais de métricas DORA; sem ele, FR-004/FR-005/FR-012 ficam sem suporte
técnico algum.

**Alternatives considered**:
- Registrar ajustes apenas como comentário em Issue — rejeitado por não ser
  estruturado/consultável programaticamente para o gate de fechamento (FR-006).
- Banco de dados dedicado — rejeitado por desproporção de complexidade frente
  ao volume esperado de ajustes manuais (exceção, não regra).

### 4) O gate de fechamento de revisão periódica precisa ser determinístico, não apenas prosa

**Decision**: estender `scripts/process-metrics-report.sh` com uma checagem
que impede reportar a revisão periódica como concluída caso existam entradas
em `docs/playbooks/dora-manual-adjustments-log.yaml` sem os campos
obrigatórios preenchidos (mesmo padrão de gate determinístico já usado por
`check-epic-issue-consistency.sh`/`check-task-hierarchy-consistency.sh`,
reuse-catalog tag `skill-mid-flow-instruction-reliability-gate`).

**Rationale**: prosa isolada ("lembre-se de exigir justificativa") é frágil;
uma checagem bash determinística não pode ser esquecida.

**Alternatives considered**:
- Confiar apenas em revisão humana do checklist — rejeitado pelo mesmo motivo
  que motivou o padrão `skill-mid-flow-instruction-reliability-gate`.

### 5) Cadência semanal (squads) é nova; cadência mensal (portfólio/PMO) já existe

**Decision**: adicionar cadência semanal para squads em
`docs/playbooks/README.md`, mantendo a cadência mensal já documentada para a
visão de portfólio/PMO (FR-010 exige ambas, a feature 012 só entregou a
mensal).

**Rationale**: FR-010 exige explicitamente as duas cadências; a mensal já
está coberta, restando formalizar a semanal.

**Alternatives considered**:
- Unificar tudo em cadência mensal — rejeitado por não atender FR-010
  explicitamente ("cadência mínima semanal para squads").

### 6) Degradação vira ação de backlog usando os labels de prioridade já existentes

**Decision**: gatilhos de degradação (FR-008) abrem/atualizam uma Issue no
backlog já existente, usando a taxonomia de prioridade (`priority:*`) e labels
`dora:*` já em vigor — sem criar uma nova taxonomia de labels específica para
ações corretivas DORA.

**Rationale**: reaproveita o backlog e a taxonomia de labels já adotados
organizacionalmente (feature 002), mantendo rastreabilidade num único board.

**Alternatives considered**:
- Board dedicado a ações DORA — rejeitado por fragmentar o backlog e duplicar
  o mecanismo de priorização já existente.
