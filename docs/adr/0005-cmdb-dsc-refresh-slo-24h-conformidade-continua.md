# 0005 — CMDB + DSC Refresh SLO de 24h para Conformidade Contínua

- **Status:** Aceita
- **Data:** 2026-08-12
- **Autores:** @nimbus-code-platform-team
- **Contexto:** feature 004 (Platform Preset CMDB + Baselines de Segurança e Compliance)
- **Revisores:** @nimbus-code-arch-board

---

## Contexto e Problema

Conformidade e segurança exigem que o estado de plataforma seja conhecido e atualizado.
A pergunta operacional é: **com que frequência é aceitável que CMDB e DSC fiquem
"desatualizados"?**

Opções:

1. **Real-time (streaming)**: coleta contínua de eventos
   - ✅ Sempre atualizado
   - ❌ Custo altíssimo (API calls constantes, processamento 24/7)
   - ❌ Complexo (requer event sourcing, Kafka, etc.)

2. **24h (diário)**: coleta completa 1x por dia (à noite ou early morning)
   - ✅ Balanço entre freshness e custo
   - ✅ Compatível com SLA de compliance regulatória
   - ✅ Batch processing simples (scheduler + cron job)
   - ❌ Desvios descobertos até 24h depois

3. **On-demand**: coleta manual quando operador dispara
   - ✅ Zero overhead automático
   - ❌ Não há conformidade contínua (só point-in-time)
   - ❌ Não atende compliance requirement de "continuous monitoring"

A escolha define SLA, custo operacional e capacidade de atender requisitos regulatórios.

## Drivers de Decisão

- **Compliance regulatória**: maioria de frameworks (ISO27001, SOC2, HIPAA) exige
  "continuous monitoring" — 24h é considerado contínuo em prática.
- **Custo operacional**: real-time streaming é 5-10x mais caro que batch diário.
- **Escalabilidade**: batch é mais fácil de escalar (paralelizar 3 providers).
- **Tempo de detecção aceitável**: 24h é tempo razoável para detectar desvios
  (anomalias críticas têm alertas em tempo real por outras ferramentas).
- **Simplicidade operacional**: scheduler cron é muito mais simples que event sourcing.

## Opções Consideradas

- **Opção A** — Real-time (streaming events)
- **Opção B** — 24h (batch diário)
- **Opção C** — On-demand (manual, sem schedule)
- **Opção D** — Híbrido (baseline 24h, alertas em tempo real para anomalias críticas)

## Análise das Opções

### Opção A — Real-time (Streaming)

Coleta contínua via Event Grid/EventBridge/Pub/Sub.

- ✅ Sempre atualizado
- ✅ Detecção imediata de anomalias
- ❌ Custo muito alto (1000s de eventos/sec → processamento constante)
- ❌ Complexidade: requer Kafka/RabbitMQ, event schema versioning
- ❌ Não necessário para MVP (overkill)

### Opção B — 24h (Batch Diário)

Scheduler roda coleta completa 1x/24h (ex.: 2am UTC).

- ✅ Custo operacional baixo (processamento ~30min, 23.5h idle)
- ✅ Escalável: fácil paralelizar discovery dos 3 providers
- ✅ Atende compliance "continuous monitoring" (daily = contínuo em regulatório)
- ✅ Simples operacionalmente (cron job + webhook)
- ✅ CMDB record tem `lastConsolidatedAt` atualizado consistentemente
- ✅ DSC profile versionado 1x/dia (histórico bem definido)
- ❌ Desvios detectados até 24h depois
- ❌ SLA: se coleta falha, falha silenciosa por até 24h (mitigado com alertas)

### Opção C — On-Demand (Manual)

Operador roda coleta quando necessário.

- ✅ Zero overhead automático
- ✅ Flexível (pode disparar a qualquer momento)
- ❌ Não há conformidade "contínua" (só ponto-a-ponto)
- ❌ Não alinha com compliance requirement
- ❌ Fácil esquecer de rodar (sem sinal de alerta)

### Opção D — Híbrido (Baseline 24h + Real-time Alertas)

Batch diário para CMDB/DSC + event stream para anomalias críticas.

- ✅ Confiabilidade: baseline atualizada 24h
- ✅ Alertas imediatos para mudanças críticas (autenticação, security groups)
- ✅ Custo balanceado (batch barato + poucos eventos críticos)
- ✅ Máxima compliance
- ❌ Complexidade aumenta (2 fluxos ao invés de 1)
- ❌ Não necessário para MVP (pode ser phase 2)

## Decisão

**Opção escolhida: Opção B (24h Batch Diário)**, porque:

1. **MVP Pragmatismo**: suporta compliance sem over-engineering
2. **Custo efetivo**: processamento baixo, operação simples
3. **Escalabilidade**: fácil adicionar mais provedores sem custo exponencial
4. **Compliance**: "daily" é aceito como "continuous monitoring" em regulatória
5. **Simplicidade**: cron job é infraestrutura bem conhecida

**Corolários**:

- Refresh schedule: 02:00 UTC (noite para maiorias das timezones)
- Timeout: 30 min (se não completar, alertar)
- Retry: 3 attempts se falha (backoff exponencial)
- Scope: sempre usa `executionScope` salvo (não recoleta por novo scope)
- Artifacts:
  - CMDB records: `lastConsolidatedAt` atualizado se sucesso
  - DSC profile: nova versão criada (v1.0.0 → v1.0.1)
  - Baseline: comparação executada, findings registrados
- Monitoring: SLO = "coleta completa 95% das vezes dentro da janela 24h"

## Consequências

### Positivas

- Custo operacional baixo: ~30min processamento/dia, resto idle
- Compliance: "daily refresh" aceito como contínuo em ISO/SOC2/HIPAA
- Previsibilidade: CMDB sempre fresco dentro de 24h (SLA claro)
- Histórico limpo: DSC profile versionado 1x/dia (não inflacionário)
- Simplicidade: scheduler cron é low-ops

### Negativas / Trade-offs Assumidos

- **Latência de detecção**: desvios descobertos até 24h depois
  (aceitável; anomalias críticas têm alertas em tempo real por outras ferramentas)
- **Janela de vulnerabilidade**: se alguém muda config no min 23:50 antes da coleta
  02:00 UTC, teremos 7h de estado desatualizado
  (aceitável para MVP; futuro: mais refresh windows ou hybrid)
- **Falha silenciosa**: se scheduler falha, falta de alerta pode deixar CMDB
  desatualizado por 24h+ (mitigado com alertas de freshness)

### Ações derivadas

- [x] Implementar `refresh-scheduler.ts` com cron-based dispatch
- [x] Implementar retry com backoff exponencial (3 attempts)
- [x] Implementar `freshness-alerts.ts` para detectar missed refreshes
- [x] Adicionar SLO monitoring (p50, p95, p99 refresh latency)
- [x] Criar log/audit trail para cada refresh execution
- [ ] Documentar refresh schedule e SLA no GOVERNANCE.md
- [ ] Implementar manual trigger endpoint (POST `/executions/refresh-now`)
  para operadores por demanda
- [ ] Criar dashboard de freshness (quando última coleta, tempo até próxima)
- [ ] Planejar fase 2: adicionar refresh windows extras (2x/dia ou 4x/dia) se demanda
- [ ] Planejar híbrido (batch + real-time alertas) para fase 2

## Links

- Feature spec: `specs/004-platform-cmdb-dsc-model/spec.md` (AC-2, AC-4)
- Runtime scheduler: `platform-governance/src/scheduler/refresh-scheduler.ts`
- Freshness alerts: `platform-governance/src/observability/freshness-alerts.ts`
- Tests: `tests/performance/governance-benchmarks.test.ts`
- Related: ADR-0002 (Preset + Runtime), ADR-0004 (Advisory mode)
