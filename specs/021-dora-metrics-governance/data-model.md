# Data Model: Governança de Métricas DORA com Coleta Híbrida

## Entities

### Metric Definition

Especifica o significado oficial de cada indicador DORA. Vive em
`docs/playbooks/README.md` (não é um objeto persistido em arquivo próprio —
é documentação estruturada consultada por squads e pelo script de coleta).

**Fields**
- `indicator`: `deployment_frequency` | `lead_time_for_changes` | `change_failure_rate` | `mttr`
- `formula`: descrição textual da fórmula de cálculo
- `source_event`: evento de origem que dispara a contagem (ex.: merge de PR rotulado)
- `measurement_window`: início/fim da janela de medição
- `inclusion_exclusion_rule`: regra textual do que conta ou não para o indicador

### Collection Record

Representa cada captura de dado de métrica, com origem e vínculo de
evidência. Para coleta automática, é implícito no cálculo de
`scripts/process-metrics-report.sh` a partir de issues/PRs rotulados
`dora:*`; para ajustes manuais, é complementado por uma `Manual Adjustment`
(ver abaixo).

**Fields**
- `indicator`: mesmo enum de `Metric Definition`
- `source_type`: `automatic` | `manual`
- `timestamp`: data/hora do registro
- `evidence_reference`: link do issue/PR/evento de origem

### Manual Adjustment

Representa alteração excepcional em registro de métrica. Persistido em
`docs/playbooks/dora-manual-adjustments-log.yaml` (novo arquivo desta
feature, mesmo padrão de `docs/playbooks/retro-cadence-state.yaml`).

**Fields**
- `id`: identificador estável do ajuste (ex.: `ADJ-0001`)
- `indicator`: mesmo enum de `Metric Definition`
- `justification`: motivo objetivo do ajuste (texto curto, legível por humano)
- `author`: responsável identificado (handle/GitHub username)
- `timestamp`: data/hora do ajuste
- `evidence_link`: link da evidência (issue, PR, comentário, log)
- `exception_category`: categoria da exceção (ex.: `fonte_indisponivel`, `evento_duplicado`, `correcao_retroativa`)
- `approved_by`: quem aprovou o ajuste (pode coincidir com `author` se auto-aprovado por regra explícita — registrar mesmo assim)

### Review Cycle

Representa rodada semanal (squad) ou mensal (portfólio/PMO) de análise
combinada dos 4 indicadores.

**Fields**
- `cycle_type`: `weekly_squad` | `monthly_portfolio`
- `period_start` / `period_end`
- `indicators_snapshot`: valores dos 4 indicadores no período
- `combined_conclusion`: texto de conclusão sobre tendência e impacto cruzado entre indicadores (FR-007)
- `pending_manual_adjustments`: lista de `Manual Adjustment.id` sem justificativa completa — se não vazia, o ciclo **não pode ser fechado** (FR-006)

### Improvement Action

Representa item de backlog aberto por degradação relevante de métrica.
Reaproveita o backlog/Issues já existentes — não é um objeto persistido em
arquivo próprio desta feature.

**Fields**
- `trigger_indicator`: qual indicador disparou a ação
- `trigger_rule`: qual gatilho objetivo foi atingido (FR-008)
- `owner`: responsável pela ação
- `priority`: label `priority:*` aplicado
- `review_deadline`: prazo de reavaliação (FR-009)
- `backlog_reference`: link da Issue criada/atualizada

## Relationships

- Uma `Review Cycle` referencia N `Collection Record` (automáticos e/ou manuais) do período
- Um `Collection Record` do tipo `manual` sempre tem exatamente um `Manual Adjustment` correspondente
- Uma `Review Cycle` só pode ser fechada (marcada como concluída) quando `pending_manual_adjustments` está vazio
- Uma `Review Cycle` pode gerar zero ou mais `Improvement Action` quando `combined_conclusion` identifica degradação relevante

## Validation Rules

- `Manual Adjustment.justification`, `author`, `timestamp` e `evidence_link` são **todos obrigatórios** — nenhum ajuste manual é aceito com qualquer um desses campos vazio (FR-004)
- `Review Cycle.combined_conclusion` MUST estar preenchido antes de a rodada ser considerada concluída (FR-007)
- `Review Cycle` com `pending_manual_adjustments` não vazio MUST permanecer aberta (FR-006)
- `Improvement Action.owner`, `priority` e `review_deadline` são obrigatórios em toda ação gerada por degradação (FR-009)
- `Metric Definition` é imutável durante um ciclo de revisão em andamento — mudanças de definição só valem a partir do próximo ciclo (evita comparação inconsistente dentro do mesmo período)
