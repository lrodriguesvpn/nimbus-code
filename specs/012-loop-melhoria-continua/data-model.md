# data-model.md — Feature 012: Loop de Melhoria Contínua Nimbus-Code

## Entidades

### Success Catalog Entry

Registro de um padrão/decisão que funcionou bem, gravado em
`docs/playbooks/success-catalog.yaml`. Schema espelha
`docs/harness/harness-catalog.yaml` (feature 011) para consistência de
curadoria.

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `id` | string | Sim | Identificador único, formato `SUC-NNNN` (paralelo ao `HRN-NNNN` do harness) |
| `date` | string (YYYY-MM-DD) | Sim | Data do registro |
| `complexity` | enum (S0–S4) | Sim | Complexidade da feature/decisão de origem |
| `bounded_context` | string | Sim | Slug do bounded context (ver `docs/bounded-contexts.yaml`) |
| `what_worked` | string (texto livre) | Sim | O que foi feito e funcionou bem |
| `why` | string (texto livre) | Sim | Por que funcionou — contexto/condições relevantes |
| `how_to_reapply` | string (texto livre) | Sim | Instrução acionável para reaplicar em outra feature |
| `tags` | array\<string\> | Sim | Tags para busca (mesmo padrão do `harness-catalog.yaml`/`reuse-catalog.yaml`) |
| `source_pr` | string (link) | Sim | PR/feature de origem |
| `validated_by` | string | Sim | Handle/nome do humano que validou a entrada (FR-007 — nunca gravado sem validação humana) |

**Regras de validação**:
- Nenhuma entrada é gravada sem `validated_by` preenchido (reforça FR-007 —
  Modelo Híbrido: agente propõe, humano valida).
- `id` deve ser único e sequencial dentro do arquivo.

### DORA Metrics Report

Saída (não persistida em arquivo por padrão — impressa no terminal/registrada
manualmente na Issue de revisão periódica) de `scripts/process-metrics-report.sh`.

| Campo | Tipo | Descrição |
|---|---|---|
| `period_start` / `period_end` | string (YYYY-MM-DD) | Janela analisada |
| `deployment_frequency` | number | Contagem de itens rotulados `dora:deployment-frequency` mergeados/fechados no período |
| `lead_time_for_changes` | number (dias, média) | Calculado a partir da diferença entre criação e merge/close de itens rotulados `dora:lead-time` |
| `change_failure_rate` | number (%) | Proporção de itens rotulados `dora:change-failure-rate` sobre o total de deploys do período |
| `mttr` | number (horas, média) | Calculado a partir da diferença entre criação e fechamento de itens rotulados `dora:mttr` |
| `insufficient_data_flags` | array\<string\> | Indicadores que não puderam ser calculados por falta de dados (ver Edge Case do `spec.md`) |

### Retro Cadence Counter

Estado simples rastreado para disparar o AC-4 (retrospectiva proativa).

| Campo | Tipo | Descrição |
|---|---|---|
| `features_since_last_retro` | number | Contador incrementado a cada feature concluída |
| `retro_cadence_n` | number | Valor de N configurado (sugestão inicial: 5) |
| `last_retro_date` | string (YYYY-MM-DD) | Data da última retrospectiva registrada |

> Implementação de armazenamento deste contador é detalhe de `tasks.md`
> (candidatos: arquivo de estado simples em `docs/playbooks/`, ou contagem
> derivada diretamente de `git log`/PRs mergeados desde a última entrada de
> retro — decisão de implementação, não de modelo de dados).

## Relações

```text
Success Catalog Entry  ──registra──> padrão reaplicável (consultado pelo Playbook de Sucesso Gate no plan.md)
DORA Metrics Report     ──alimenta──> decisão de ação de melhoria (revisão periódica, AC-3)
Retro Cadence Counter   ──dispara──>  sinalização proativa de retrospectiva (AC-4)
Retrospectiva           ──pode gerar──> nova Success Catalog Entry OU nova Harness Catalog Entry (feature 011)
```
