# Contract: DORA Quality and Manual Adjustment Audit

## Purpose

Definir o contrato operacional mínimo para (1) qualidade de dados dos 4
indicadores DORA, (2) trilha de auditoria de ajustes manuais e (3) gate de
fechamento de revisão periódica — sem alterar o contrato de cálculo já
existente em `scripts/process-metrics-report.sh` (feature 012).

## Inputs

| Field | Description | Required |
|---|---|---|
| `repo_owner` / `repo_name` | Repositório-alvo da coleta | Yes |
| `since` / `until` | Janela de medição (YYYY-MM-DD) | Yes |
| `manual_adjustment.indicator` | Indicador sendo ajustado | Yes, quando houver ajuste manual |
| `manual_adjustment.justification` | Motivo objetivo do ajuste | Yes, quando houver ajuste manual |
| `manual_adjustment.author` | Responsável identificado | Yes, quando houver ajuste manual |
| `manual_adjustment.evidence_link` | Link da evidência | Yes, quando houver ajuste manual |
| `manual_adjustment.exception_category` | Categoria da exceção | Yes, quando houver ajuste manual |
| `review_cycle.combined_conclusion` | Conclusão da leitura combinada dos 4 indicadores | Yes, para fechar qualquer `Review Cycle` |

## Decision Rules

| Condition | Required Action | Forbidden Action |
|---|---|---|
| Evento elegível para coleta automática ocorre | Registrar automaticamente via labels `dora:*`, sem intervenção manual | Exigir confirmação manual para eventos já elegíveis à automação |
| Ajuste manual solicitado | Exigir `justification` + `author` + `timestamp` + `evidence_link` + `exception_category` completos antes de aceitar o ajuste | Aceitar ajuste manual com qualquer campo obrigatório ausente |
| Fechamento de `Review Cycle` solicitado | Verificar que não há `Manual Adjustment` pendente sem justificativa completa no período | Permitir fechamento de `Review Cycle` com ajuste manual incompleto (viola FR-006) |
| Análise de indicadores do período | Produzir `combined_conclusion` considerando os 4 indicadores em conjunto | Basear decisão de melhoria em um único indicador isolado (viola FR-007) |
| Degradação relevante identificada (gatilho objetivo atingido) | Abrir/atualizar Issue de `Improvement Action` com owner, prioridade e prazo de reavaliação | Registrar degradação sem gerar item de backlog correspondente |

## Outputs

| Output | Description |
|---|---|
| `data_quality_report` | Resultado da checagem de completude, consistência temporal e ausência de duplicidade (FR-011) |
| `manual_adjustments_pending` | Lista de ajustes manuais sem justificativa completa que bloqueiam o fechamento do ciclo |
| `review_cycle_status` | `open` \| `closed` — `closed` só é possível quando `manual_adjustments_pending` está vazio |
| `improvement_actions_opened` | Lista de Issues de `Improvement Action` criadas/atualizadas nesta rodada |

## Invariants

- Coleta automática é sempre o caminho padrão para eventos elegíveis — ajuste manual é sempre exceção, nunca rota primária
- Toda entrada em `docs/playbooks/dora-manual-adjustments-log.yaml` tem os 5 campos obrigatórios preenchidos (nenhuma entrada parcial é aceita)
- Nenhuma `Review Cycle` é reportada como `closed` com `manual_adjustments_pending` não vazio
- Toda `Improvement Action` aberta por degradação tem `owner`, `priority` e `review_deadline` — nunca uma Issue sem responsável e prazo

## Operational Notes

- A checagem de qualidade de dados (`data_quality_report`) e o gate de fechamento (`review_cycle_status`) seguem o mesmo padrão determinístico já usado por `.specify/scripts/bash/check-epic-issue-consistency.sh`/`check-task-hierarchy-consistency.sh` (reuse-catalog tag `skill-mid-flow-instruction-reliability-gate`): bash puro, idempotente, nunca dependente apenas de prosa seguida corretamente pelo agente/operador.
- `exception_category` não tem lista fechada nesta versão — squads podem introduzir novas categorias, desde que a categoria seja registrada de forma consistente (mesmo motivo repetido deve usar a mesma categoria).
