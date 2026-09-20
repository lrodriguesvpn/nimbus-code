# API Contract: Cost Dashboard

**Module**: `cost-dashboard`  
**Version**: 1.0 (MVP)  
**Date**: 2026-08-18

---

## Base URL

```
/api/v1
```

Autenticação: GitHub OAuth/OIDC corporativo, com sessão validada pelo gateway.
Tokens não são aceitos em query string nem persistidos em respostas. RBAC:
Tech Leads e gestores consultam o próprio escopo; diretores consultam todos os
escopos; devs consultam apenas as próprias features. Exportação exige o mesmo
escopo e é auditada.

---

## Endpoints

### GET /costs

Retorna resumo de custo real vs. estimado para um escopo específico.

**Query Parameters**:

| Param | Type | Required | Description |
|---|---|---|---|
| `scope` | enum | ✓ | `feature` \| `sprint` \| `squad` \| `project` |
| `id` | string | ✓ | ID do escopo selecionado |
| `period` | string | ✗ | Filtro de período no formato `YYYY-MM` ou `sprint-id` |
| `from` | date | ✗ | Início do intervalo (YYYY-MM-DD); alternativa ao `period` |
| `to` | date | ✗ | Fim do intervalo (YYYY-MM-DD) |

**Response 200**:

```json
{
  "scope": "feature",
  "id": "010-controle-de-custos",
  "period": "2026-08",
  "summary": {
    "total_brl": 285.50,
    "has_estimate": true,
    "estimated_min_brl": 250.00,
    "estimated_max_brl": 350.00,
    "variance_pct": 14.2
  },
  "dimensions": {
    "tokens": {
      "amount": 52000,
      "cost_brl": 260.00,
      "model": "claude-sonnet-4.6",
      "sessions": 3
    },
    "human_hours": {
      "amount": 5.5,
      "cost_brl": 25.50,
      "source": "github-project-api"
    },
    "cloud": null
  },
  "data_quality": {
    "tokens_complete": true,
    "human_hours_complete": true,
    "missing_dimensions": [],
    "statuses": []
  }
}
```

**Response 404**: escopo não encontrado  
**Response 422**: parâmetros inválidos (ex.: `scope` sem valor válido)
**Response 503**: fonte de custo indisponível; a resposta não deve parecer sucesso

**SLA**: p99 < 800ms

---

### GET /costs/benchmarks

Retorna benchmarks históricos por nível de complexidade para uso em estimativas.

**Query Parameters**:

| Param | Type | Required | Description |
|---|---|---|---|
| `complexity` | enum | ✗ | `S0` \| `S1` \| `S2` \| `S3` \| `S4`; se omitido, retorna todos |
| `period` | string | ✗ | Período do benchmark; padrão: últimos 90 dias |

**Response 200**:

```json
{
  "benchmarks": [
    {
      "complexity_level": "S3",
      "avg_tokens": 55000,
      "p50_tokens": 52000,
      "p90_tokens": 75000,
      "avg_human_hours": 8.5,
      "p50_human_hours": 7.0,
      "sample_size": 12,
      "confidence": "sufficient",
      "period": "2026-08",
      "updated_at": "2026-08-18T00:00:00Z"
    },
    {
      "complexity_level": "S4",
      "avg_tokens": null,
      "p50_tokens": null,
      "p90_tokens": null,
      "avg_human_hours": null,
      "p50_human_hours": null,
      "sample_size": 2,
      "confidence": "insufficient_sample",
      "period": "2026-08",
      "updated_at": "2026-08-18T00:00:00Z"
    }
  ]
}
```

**Response 422**: parâmetros inválidos

**SLA**: p99 < 800ms

---

### GET /budgets/{id}/status

Retorna o status atual de um orçamento, incluindo consumo acumulado e alertas ativos.

**Path Parameters**:

| Param | Type | Required | Description |
|---|---|---|---|
| `id` | UUID | ✓ | ID do Budget |

**Response 200**:

```json
{
  "budget_id": "b1a2b3c4-0000-0000-0000-000000000001",
  "scope_type": "sprint",
  "scope_id": "sprint-2026-08",
  "limit_amount": 5000.00,
  "consumed_amount": 4200.00,
  "consumed_pct": 0.84,
  "currency": "BRL",
  "period": "2026-08",
  "status": "alert_80",
  "alerts": [
    {
      "alert_id": "a1a2b3c4-0000-0000-0000-000000000001",
      "threshold_pct": 0.80,
      "triggered_at": "2026-08-15T10:30:00Z",
      "notification_status": "sent"
    }
  ],
  "owner": "tech-lead@venha-pra-nuvem.com.br"
}
```

**`status` values**:
- `watching`: < threshold_pct consumido
- `alert_80`: alerta de 80% disparado; ainda abaixo do limite
- `overbudget`: limite ultrapassado

**Response 404**: budget não encontrado

**SLA**: p99 < 800ms

---

### GET /costs/export

Exporta dados de custo em CSV para um escopo e período.

**Query Parameters**: mesmos de `GET /costs` + `format` (`csv` somente no MVP)

**Response 200**: `Content-Type: text/csv`

```csv
feature_id,dimension,amount,currency,period,model,session_id,created_at
010-controle-de-custos,tokens,52000,BRL,2026-08,claude-sonnet-4.6,sess-abc123,2026-08-18T17:00:00Z
010-controle-de-custos,human_hours,5.5,BRL,2026-08,,, 2026-08-18T18:00:00Z
```

**SLA**: p99 < 3000ms (pode ser assíncrono para exportações grandes)

---

## Error Format (padrão)

```json
{
  "error": {
    "code": "INVALID_SCOPE",
    "message": "Scope 'department' is not supported. Valid values: feature, sprint, squad, project",
    "request_id": "req-abc123"
  }
}
```

---

## Headers Obrigatórios

| Header | Direction | Description |
|---|---|---|
| `Authorization: Bearer <gateway-session>` | Request | Sessão validada pelo gateway |
| `X-Correlation-Id` | Request + Response | Propagado de serviço em serviço; gerado se ausente |
| `X-Response-Time` | Response | Tempo de resposta em ms (para monitoramento de SLA) |
