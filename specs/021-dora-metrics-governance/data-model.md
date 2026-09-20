# Data Model: Governança de Métricas DORA com Coleta Híbrida

## Entities

### Metric Definition

Especifica o significado oficial de cada indicador DORA (alinhado a dora.dev). Vive em
`docs/playbooks/README.md` (não é um objeto persistido em arquivo próprio —
é documentação estruturada consultada por squads e pelo script de coleta).

**Fields**
- `indicator`: `deployment_frequency` | `lead_time_for_changes` | `change_failure_rate` | `failed_deployment_recovery_time` | `operational_reliability`
- `formula`: descrição textual da fórmula de cálculo
- `source_event`: evento de origem que dispara a contagem no GHE (ex.: deploy em produção, merge de PR rotulado, incidente)
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
- `exception_category`: `fonte_indisponivel` | `evento_duplicado` | `correcao_retroativa` | `outro_justificado`
- `approved_by`: quem aprovou o ajuste; obrigatório em toda entrada aceita, podendo coincidir com `author` somente quando uma regra explícita de autoaprovação se aplicar
- `review_cycle_period`: período semanal/mensal afetado pelo ajuste
- `supersedes_id`: ID do registro anterior quando o ajuste corrige um evento já registrado

### Review Cycle

Representa rodada semanal (squad) ou mensal (portfólio/PMO) de análise
combinada dos 4 indicadores.

**Fields**
- `cycle_type`: `weekly_squad` | `monthly_portfolio`
- `period_start` / `period_end`
- `indicators_snapshot`: valores dos 4 indicadores no período
- `combined_conclusion`: texto de conclusão sobre tendência e impacto cruzado entre indicadores (FR-007)
- `pending_manual_adjustments`: lista de `Manual Adjustment.id` sem justificativa completa — se não vazia, o ciclo **não pode ser fechado** (FR-006)
- `status`: `open` | `data_insufficient` | `reconciliation_pending` | `approved` | `closed`

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
- `source_review_cycle`: referência ao ciclo que originou a ação

## Relationships

- Uma `Review Cycle` referencia N `Collection Record` (automáticos e/ou manuais) do período
- Um `Collection Record` do tipo `manual` sempre tem exatamente um `Manual Adjustment` correspondente
- Uma `Review Cycle` só pode ser fechada quando `pending_manual_adjustments` está vazio, `combined_conclusion` está preenchida e o estado anterior é `approved`
- Uma `Review Cycle` pode gerar zero ou mais `Improvement Action` quando `combined_conclusion` identifica degradação relevante

## Validation Rules

- `Manual Adjustment.justification`, `author`, `timestamp`, `evidence_link`, `exception_category`, `approved_by` e `review_cycle_period` são **todos obrigatórios** — nenhum ajuste manual é aceito com qualquer um desses campos vazio (FR-004, FR-012)
- `exception_category` MUST pertencer ao vocabulário controlado definido acima
- Um ajuste que substitui outro MUST preencher `supersedes_id`; o registro anterior permanece imutável
- `Review Cycle.combined_conclusion` MUST estar preenchido antes de a rodada ser considerada concluída (FR-007)
- `Review Cycle.status` MUST seguir a ordem `open` → `data_insufficient`/`reconciliation_pending` → `approved` → `closed`, sem saltar diretamente para `closed`
- `Review Cycle` com `pending_manual_adjustments` não vazio MUST permanecer aberta (FR-006)
- `Improvement Action.owner`, `priority` e `review_deadline` são obrigatórios em toda ação gerada por degradação (FR-009)
- `Metric Definition` é imutável durante um ciclo de revisão em andamento — mudanças de definição só valem a partir do próximo ciclo (evita comparação inconsistente dentro do mesmo período)
