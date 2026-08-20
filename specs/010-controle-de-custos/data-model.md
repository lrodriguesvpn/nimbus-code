# Data Model & Entity Design

**Feature**: Controle de Custos  
**Phase**: 1 — Design  
**Date**: 2026-08-18

---

## Core Entities

### 1. CostRecord

*Representa o custo real de uma feature em uma dimensão específica. Imutável (append-only).*

| Field | Type | Description | Constraints |
|---|---|---|---|
| `id` | UUID | Identificador único | Obrigatório; gerado na inserção |
| `feature_id` | string | Identificador da feature (ex.: `010-controle-de-custos`) | Obrigatório |
| `dimension` | enum | `tokens` \| `human_hours` \| `cloud` | Obrigatório; `cloud` reservado para fase 2 |
| `amount` | float | Quantidade real consumida (tokens ou horas) | Obrigatório; > 0 |
| `currency` | string | Moeda de referência (`BRL`) | Obrigatório |
| `usd_amount` | float | Valor original em USD (para tokens) | Opcional; preenchido quando dimension = `tokens` |
| `exchange_rate` | float | Taxa USD/BRL no momento da coleta | Opcional; preenchido quando `usd_amount` presente |
| `period` | string | Período do registro (YYYY-MM ou sprint-id) | Obrigatório |
| `source` | string | Origem do dado (`github-project-api`, `session-store`, `manual`) | Obrigatório |
| `model` | string | Modelo de IA utilizado (ex.: `claude-sonnet-4.6`) | Opcional; quando dimension = `tokens` |
| `session_id` | string | ID da sessão de agente | Opcional; quando dimension = `tokens` |
| `correction_ref` | UUID | Referência ao registro corrigido (se este é uma correção) | Opcional; para trilha de auditoria |
| `created_at` | timestamp | Timestamp de inserção | Obrigatório; imutável |

**Example**:
```yaml
CostRecord:
  id: "c1a2b3c4-0000-0000-0000-000000000001"
  feature_id: "010-controle-de-custos"
  dimension: "tokens"
  amount: 52000
  currency: "BRL"
  usd_amount: 1.04
  exchange_rate: 5.00
  period: "2026-08"
  source: "session-store"
  model: "claude-sonnet-4.6"
  session_id: "sess-abc123"
  correction_ref: null
  created_at: "2026-08-18T17:00:00Z"
```

**Validation**:
- `amount` > 0; nunca negativo
- `dimension: cloud` → criar Issue de bloqueio (fora do MVP); rejeitar registro
- Se `dimension: tokens` e `usd_amount` ausente → aceitar mas sinalizar como "câmbio não registrado"
- `correction_ref` → o registro referenciado deve existir; ciclos não permitidos
- Registro é imutável; atualizações criam novo CostRecord com `correction_ref` apontando ao original

---

### 2. CostEstimate

*Representa a estimativa registrada no `plan.md` antes da execução da feature.*

| Field | Type | Description | Constraints |
|---|---|---|---|
| `id` | UUID | Identificador único | Obrigatório |
| `feature_id` | string | Identificador da feature | Obrigatório |
| `dimension` | enum | `tokens` \| `human_hours` | Obrigatório |
| `estimated_min` | float | Faixa mínima estimada | Obrigatório; > 0 |
| `estimated_max` | float | Faixa máxima estimada | Obrigatório; ≥ estimated_min |
| `complexity_level` | enum | `S0` \| `S1` \| `S2` \| `S3` \| `S4` | Obrigatório |
| `recorded_by` | string | Quem registrou (agente, humano, ou ID) | Obrigatório |
| `recorded_at` | timestamp | Timestamp do registro | Obrigatório |

**Example**:
```yaml
CostEstimate:
  id: "e1a2b3c4-0000-0000-0000-000000000001"
  feature_id: "010-controle-de-custos"
  dimension: "tokens"
  estimated_min: 50000
  estimated_max: 70000
  complexity_level: "S3"
  recorded_by: "agent:copilot-coding"
  recorded_at: "2026-08-18T14:00:00Z"
```

**Validation**:
- `estimated_max` ≥ `estimated_min`
- `complexity_level` deve estar no enum (S0–S4)
- Uma feature deve ter ao menos uma CostEstimate para dimension `tokens` e uma para `human_hours` antes de ser executada (lint no plan.md valida presença)

---

### 3. Budget

*Orçamento configurado para um sprint, projeto ou squad.*

| Field | Type | Description | Constraints |
|---|---|---|---|
| `id` | UUID | Identificador único | Obrigatório |
| `scope_type` | enum | `sprint` \| `project` \| `squad` | Obrigatório |
| `scope_id` | string | ID do sprint, projeto ou squad | Obrigatório |
| `limit_amount` | float | Limite máximo de gasto (em BRL) | Obrigatório; > 0 |
| `currency` | string | Moeda (`BRL`) | Obrigatório |
| `period` | string | Período de vigência (YYYY-MM ou sprint-id) | Obrigatório |
| `alert_threshold_pct` | float | % que dispara alerta preventivo (ex.: 0.80) | Obrigatório; entre 0 e 1 |
| `owner` | string | Responsável a ser notificado | Obrigatório; email ou GitHub login |
| `created_at` | timestamp | Timestamp de criação | Obrigatório |

**Example**:
```yaml
Budget:
  id: "b1a2b3c4-0000-0000-0000-000000000001"
  scope_type: "sprint"
  scope_id: "sprint-2026-08"
  limit_amount: 5000.00
  currency: "BRL"
  period: "2026-08"
  alert_threshold_pct: 0.80
  owner: "tech-lead@venha-pra-nuvem.com.br"
  created_at: "2026-08-01T00:00:00Z"
```

**Validation**:
- `alert_threshold_pct` entre 0.01 e 0.99 (nunca 0 ou 1)
- `limit_amount` > 0
- `owner` deve ser um email ou GitHub login válido
- Deve existir apenas 1 Budget ativo por (scope_type, scope_id, period); duplicatas são rejeitadas

---

### 4. CostAlert

*Alerta disparado quando o consumo atinge um limiar do orçamento.*

| Field | Type | Description | Constraints |
|---|---|---|---|
| `id` | UUID | Identificador único | Obrigatório |
| `budget_id` | UUID | Referência ao Budget que gerou o alerta | Obrigatório |
| `triggered_at` | timestamp | Quando o alerta foi criado | Obrigatório |
| `consumption_at_trigger` | float | Valor total consumido no momento do trigger | Obrigatório; > 0 |
| `threshold_pct` | float | % do orçamento que disparou o alerta | Obrigatório |
| `notified_to` | string | Canal/destinatário efetivamente notificado | Obrigatório |
| `notification_status` | enum | `sent` \| `failed` \| `retrying` | Obrigatório |
| `resolved_at` | timestamp | Quando o alerta foi reconhecido pelo owner | Opcional |

**Example**:
```yaml
CostAlert:
  id: "a1a2b3c4-0000-0000-0000-000000000001"
  budget_id: "b1a2b3c4-0000-0000-0000-000000000001"
  triggered_at: "2026-08-15T10:30:00Z"
  consumption_at_trigger: 4010.00
  threshold_pct: 0.80
  notified_to: "tech-lead@venha-pra-nuvem.com.br"
  notification_status: "sent"
  resolved_at: null
```

**Validation**:
- `consumption_at_trigger` > 0
- `threshold_pct` deve corresponder ao `alert_threshold_pct` do Budget referenciado
- Idempotência: se um alerta já foi disparado para (budget_id, threshold_pct), não disparar novamente
- Alerta de 100% (estouro) é disparado mesmo que o de 80% já tenha sido enviado

---

### 5. CostBenchmark

*Agregado histórico de custo por nível de complexidade para uso como referência de estimativas.*

| Field | Type | Description | Constraints |
|---|---|---|---|
| `id` | UUID | Identificador único | Obrigatório |
| `complexity_level` | enum | `S0` \| `S1` \| `S2` \| `S3` \| `S4` | Obrigatório |
| `avg_tokens` | float | Média de tokens consumidos (por feature) | Obrigatório; ≥ 0 |
| `p50_tokens` | float | Mediana de tokens | Obrigatório; ≥ 0 |
| `p90_tokens` | float | Percentil 90 de tokens | Obrigatório; ≥ avg_tokens |
| `avg_human_hours` | float | Média de horas humanas (por feature) | Obrigatório; ≥ 0 |
| `p50_human_hours` | float | Mediana de horas humanas | Obrigatório; ≥ 0 |
| `sample_size` | int | Número de features no cálculo | Obrigatório; ≥ 1 |
| `min_sample_for_display` | int | Mínimo de amostras para exibir (badge de confiança) | Obrigatório; default 10 |
| `period` | string | Período de referência do cálculo | Obrigatório |
| `updated_at` | timestamp | Última vez que o benchmark foi recalculado | Obrigatório |

**Example**:
```yaml
CostBenchmark:
  id: "bm1a2b3c-0000-0000-0000-000000000001"
  complexity_level: "S3"
  avg_tokens: 55000
  p50_tokens: 52000
  p90_tokens: 75000
  avg_human_hours: 8.5
  p50_human_hours: 7.0
  sample_size: 12
  min_sample_for_display: 10
  period: "2026-08"
  updated_at: "2026-08-18T00:00:00Z"
```

**Validation**:
- `sample_size` ≥ 1; se < `min_sample_for_display` → exibir com badge "amostra insuficiente"
- `p90_tokens` ≥ `avg_tokens` ≥ `p50_tokens` não é garantido matematicamente mas valores invertidos devem gerar warning
- Recalculado por job batch periódico (mínimo diário)

---

## Relationship Diagrams

### Entity Flow no Ciclo de Vida de Custo

```
plan.md (campos de estimativa preenchidos)
  ↓
CostEstimate (registrada antes da execução)
  ↓
Feature executada (agente + humano trabalham)
  ↓
CostRecord (tokens via session-store; horas via GitHub Project API)
  ↓
Budget (verifica limites periodicamente)
  ↓
CostAlert (disparado quando threshold atingido)
  ↓
Dashboard (exibe CostRecord vs. CostEstimate + CostBenchmark)
  ↓
CostBenchmark (agregado por job batch → alimenta estimativas futuras)
```

### Dependency Graph

```
CostEstimate
  └─ feature_id → feature (externo; não entidade neste sistema)
  └─ complexity_level → referenciado por CostBenchmark

CostRecord
  ├─ feature_id → mesma feature de CostEstimate
  ├─ correction_ref → outro CostRecord (opcional; auditoria)
  └─ session_id → sessão de agente (externo)

Budget
  ├─ scope_type + scope_id → projeto/sprint/squad (externo)
  └─ owner → notificado em CostAlert

CostAlert
  └─ budget_id → Budget

CostBenchmark
  └─ aggregated from CostRecord WHERE dimension='tokens' OR 'human_hours'
     grouped by complexity_level (de CostEstimate da mesma feature)
```

---

## State Transitions & Validation Rules

### CostRecord Lifecycle

```
PENDING → VALIDATED → PERSISTED → [CORRECTED]
           ↓              ↓
         (validação    (imutável;
          na coleta)    append-only)
```

### Budget Alert State Machine

```
WATCHING → ALERT_80 → ALERT_100 → ACKNOWLEDGED
              ↓
           (se consumo volta para < 80% no mesmo período → permanece ALERT_80 sem re-disparar)
```

### Validation Rules

1. **Append-only para CostRecord**: Nunca atualizar ou deletar; correção = novo registro com `correction_ref`
2. **Idempotência de alerta**: Um alerta por (budget_id, threshold_pct, period); re-insert do mesmo threshold é ignorado
3. **Benchmark mínimo**: `CostBenchmark` só é exibido como referência confiável quando `sample_size >= min_sample_for_display`
4. **Estimativa obrigatória**: Features sem `CostEstimate` são sinalizadas no dashboard como "sem baseline de estimativa"
5. **Deduplicação de tokens**: CostRecord com mesmo `session_id` e `feature_id` é rejeitado (evita duplicação por re-run)
6. **Câmbio auditável**: Se `usd_amount` presente, `exchange_rate` é obrigatório; taxa histórica nunca é recalculada retroativamente

---

## Implementation Notes

- Entidades são persistidas em PostgreSQL 15+; schema versionado via migrations
- `cost-collector` produz eventos; `cost-store` é o consumidor e responsável pela persistência
- `cost-aggregator` roda como job batch (mínimo diário); pode ser on-demand para recalcular período específico
- Dashboard consome via API REST; entidades não são expostas diretamente ao frontend (sempre via agregações)
- Dados de custo são tratados como financeiros: retenção mínima de 12 meses online, 24 meses archival
