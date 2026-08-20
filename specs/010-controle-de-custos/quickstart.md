# Quickstart Validation Guide: Controle de Custos (Feature 010)

**Feature**: Controle de Custos  
**Date**: 2026-08-18

---

## Objetivo

Validar que o sistema de controle de custos funciona corretamente end-to-end, cobrindo todos os critérios de aceitação da spec (AC-1 a AC-5).

---

## Pré-requisitos

- [ ] Ambiente de desenvolvimento configurado com todos os módulos iniciados (`cost-store`, `cost-collector`, `cost-aggregator`, `budget-alert-engine`, `cost-dashboard`)
- [ ] Banco de dados inicializado com as migrations aplicadas
- [ ] GitHub Project de teste com o campo "Horas Humanas" configurado
- [ ] Variável de ambiente `COST_CONTROL_V1=true` definida
- [ ] Token GitHub com scope `project:read` configurado no vault / env

---

## Step 1 — Registrar estimativa de custo no plan.md (AC-4)

**Objetivo**: Verificar que o template de `plan.md` inclui campos obrigatórios de estimativa de custo.

**Ação**:
1. Criar uma nova feature de teste com `/speckit-specify "Feature de teste de custo"`
2. Executar `/speckit-plan feature-de-teste-custo`
3. Abrir o `plan.md` gerado

**Validação**:
- [ ] O arquivo `plan.md` contém a seção "Classificação de Complexidade"
- [ ] A seção contém o campo "Estimativa de tokens (input+output)" preenchido com faixa numérica
- [ ] A seção contém referência ao campo de "Horas Humanas" esperadas

**Resultado esperado**: `plan.md` gerado com campos de custo obrigatórios presentes.

---

## Step 2 — Coletar tokens de uma sessão simulada (AC-1)

**Objetivo**: Verificar que o `cost-collector` coleta tokens corretamente da tabela `assistant_usage_events`.

**Ação**:
1. Simular uma sessão de agente com `session_id=test-session-001` e `feature_id=test-feature-001`
2. Inserir manualmente em `assistant_usage_events`:
   ```sql
   INSERT INTO assistant_usage_events
     (session_id, model, input_tokens, output_tokens)
   VALUES
     ('test-session-001', 'claude-sonnet-4.6', 30000, 12000);
   ```
3. Acionar o `cost-collector` para processar a sessão

**Validação**:
- [ ] Um `CostRecord` é criado com `dimension=tokens`, `amount=42000`, `feature_id=test-feature-001`
- [ ] `model=claude-sonnet-4.6` está presente no registro
- [ ] `session_id=test-session-001` está presente no registro
- [ ] Nenhum erro no log do `cost-collector`

**Resultado esperado**: `CostRecord` persistido com dados corretos.

---

## Step 3 — Coletar horas humanas do GitHub Project (AC-1)

**Objetivo**: Verificar que o `cost-collector` lê corretamente o campo "Horas Humanas" do GitHub Project.

**Ação**:
1. No GitHub Project de teste, abrir uma issue vinculada ao `feature_id=test-feature-001`
2. Preencher o campo "Horas Humanas" com `4.0`
3. Acionar o `cost-collector` para processar o projeto

**Validação**:
- [ ] Um `CostRecord` é criado com `dimension=human_hours`, `amount=4.0`, `feature_id=test-feature-001`
- [ ] `source=github-project-api` está presente no registro
- [ ] Nenhum erro no log do `cost-collector`

**Resultado esperado**: `CostRecord` de horas humanas persistido corretamente.

---

## Step 4 — Verificar custo real vs. estimado no dashboard (AC-1)

**Objetivo**: Confirmar que o dashboard exibe a comparação entre estimativa e consumo real.

**Ação**:
1. Registrar uma `CostEstimate` para `test-feature-001`:
   - `dimension=tokens`, `estimated_min=40000`, `estimated_max=55000`, `complexity_level=S2`
2. Acessar o dashboard: `GET /costs?scope=feature&id=test-feature-001`

**Validação**:
- [ ] A resposta contém `estimated_min`, `estimated_max` e `actual_amount`
- [ ] A variação percentual é calculada: `(actual - estimated_mid) / estimated_mid * 100`
- [ ] A feature de teste aparece no dashboard com ambos os valores lado a lado

**Resultado esperado**: Dashboard exibe custo real (`42000 tokens`) vs. estimado (`40k–55k`) com variação `~-18%`.

---

## Step 5 — Testar alerta de orçamento ao atingir 80% (AC-2)

**Objetivo**: Confirmar que o `budget-alert-engine` dispara alerta preventivo no momento correto.

**Ação**:
1. Criar um `Budget` de teste:
   ```json
   {
     "scope_type": "sprint",
     "scope_id": "sprint-test-001",
     "limit_amount": 100.00,
     "currency": "BRL",
     "period": "2026-08",
     "alert_threshold_pct": 0.80,
     "owner": "test@venha-pra-nuvem.com.br"
   }
   ```
2. Inserir `CostRecord` que soma R$ 85,00 (= 85% do limite)
3. Aguardar execução do `budget-alert-engine`

**Validação**:
- [ ] Um `CostAlert` é criado com `threshold_pct=0.80`, `triggered_at` preenchido
- [ ] `notification_status=sent` (ou `retrying` em ambiente sem SMTP)
- [ ] O log do motor registra: "Alert triggered for budget sprint-test-001 at 85% consumption"
- [ ] Alerta criado em menos de 30 minutos após inserção do CostRecord

**Resultado esperado**: `CostAlert` criado e notificação enviada antes do estouro.

---

## Step 6 — Confirmar ausência de alerta duplicado (AC-2)

**Objetivo**: Verificar que o mecanismo de idempotência funciona corretamente.

**Ação**:
1. Inserir mais um `CostRecord` que eleva o total para R$ 87,00 (ainda acima de 80%)
2. Aguardar execução do `budget-alert-engine`

**Validação**:
- [ ] Nenhum novo `CostAlert` foi criado para o mesmo (budget_id, threshold_pct)
- [ ] O log registra: "Alert for threshold 0.80 already fired; skipping"

**Resultado esperado**: Apenas 1 alerta por (budget, threshold); sem spam.

---

## Step 7 — Verificar dashboard consolidado com drill-down (AC-3)

**Objetivo**: Confirmar que o dashboard consolida múltiplas dimensões com filtros funcionais.

**Ação**:
1. Garantir que `test-feature-001` tem CostRecords de `tokens` e `human_hours`
2. Acessar o dashboard: `GET /costs?scope=feature&id=test-feature-001`

**Validação**:
- [ ] A resposta inclui `dimensions: { tokens: {...}, human_hours: {...} }`
- [ ] O total consolidado é a soma das dimensões
- [ ] Filtro de período funciona: `GET /costs?scope=feature&id=test-feature-001&period=2026-08` retorna apenas dados de agosto
- [ ] Latência da resposta < 800ms (verificar no log ou header `X-Response-Time`)

**Resultado esperado**: Dashboard consolidado com drill-down e filtro de período funcionais.

---

## Step 8 — Verificar benchmarks históricos (AC-5)

**Objetivo**: Confirmar que o `cost-aggregator` produz benchmarks por complexidade com amostra suficiente.

**Ação**:
1. Inserir CostRecords e CostEstimates para pelo menos 10 features com `complexity_level=S2`
2. Acionar o `cost-aggregator` para recalcular benchmarks

**Validação**:
- [ ] `GET /costs/benchmarks?complexity=S2` retorna um `CostBenchmark` com `sample_size >= 10`
- [ ] Campos `avg_tokens`, `p50_tokens`, `p90_tokens`, `avg_human_hours` estão preenchidos
- [ ] Badge "amostra insuficiente" NÃO aparece (sample_size = 10 ≥ min_sample_for_display)

**Resultado esperado**: Benchmark de S2 disponível com dados plausíveis para uso em estimativas.

---

## Step 9 — Testar badge "amostra insuficiente" (AC-5)

**Objetivo**: Confirmar que benchmarks com poucas amostras são sinalizado corretamente.

**Ação**:
1. Consultar benchmarks para `S4` (não há features S4 inseridas nos passos anteriores)

**Validação**:
- [ ] `GET /costs/benchmarks?complexity=S4` retorna `sample_size=0` ou `null`
- [ ] A resposta inclui `confidence: "insufficient_sample"` ou campo equivalente
- [ ] Dashboard exibe badge "amostra insuficiente" ao tentar exibir benchmark de S4

**Resultado esperado**: Benchmark de S4 exibido com aviso de confiabilidade, não como dado confiável.

---

## Step 10 — Testar kill switch (Rollback Validation)

**Objetivo**: Confirmar que desabilitar a feature flag para a coleta imediatamente.

**Ação**:
1. Setar `COST_CONTROL_V1=false` no ambiente
2. Inserir sessão adicional em `assistant_usage_events`
3. Acionar o `cost-collector`

**Validação**:
- [ ] Nenhum novo `CostRecord` é criado para a sessão inserida
- [ ] Log do `cost-collector` registra: "Feature flag cost_control_v1 is disabled; skipping collection"
- [ ] Dashboard exibe banner "sistema em manutenção / coleta desativada"
- [ ] Dados históricos permanecem acessíveis no dashboard (somente leitura)

**Resultado esperado**: Kill switch funciona em < 5 minutos sem perda de dados históricos.

---

## Resumo dos Acceptance Criteria cobertos

| AC | Coberto nos Steps |
|---|---|
| AC-1: Custo real vs. estimado | Steps 2, 3, 4 |
| AC-2: Alerta ao atingir 80% | Steps 5, 6 |
| AC-3: Dashboard consolidado | Step 7 |
| AC-4: Campos de estimativa no template | Step 1 |
| AC-5: Benchmarks históricos | Steps 8, 9 |

---

## Troubleshooting

| Sintoma | Causa Provável | Ação |
|---|---|---|
| `CostRecord` não criado após Step 2 | `session_id` não mapeado para `feature_id` | Verificar metadata da sessão; usar mapeamento manual |
| Alerta não disparado no Step 5 | `budget-alert-engine` inativo ou processamento batch atrasado | Verificar health check; acompanhar log; aguardar até 30 min |
| Dashboard retorna 404 em `/costs/benchmarks` | `cost-aggregator` ainda não rodou | Acionar job batch manualmente; aguardar conclusão |
| Latência > 800ms no Step 7 | Índices ausentes ou volume alto de dados | Verificar índices em `feature_id` e `period`; analisar query plan |
| Kill switch (Step 10) não surtiu efeito | Cache da flag não expirou | Forçar reload do provider OpenFeature; aguardar TTL |
