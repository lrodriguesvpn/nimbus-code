<!--
  impact-map.md — Mapa de impacto e análise de risco por feature
  OBRIGATÓRIO para complexidade S3 e S4.
  RECOMENDADO para S2 quando a feature toca módulos compartilhados ou dados sensíveis.
  Criado junto com graph.yaml e revisado antes de /nimbus-code-tasks.
-->

# Mapa de Impacto — `<feature-slug>`

> **Complexidade:** S3 — Múltiplos Módulos  
> **Última atualização:** YYYY-MM-DD  
> **Grafo:** [graph.md](./graph.md) · [graph.yaml](./graph.yaml)

---

## 1. Módulos/serviços afetados

| Módulo | Tipo de mudança | Impacto estimado | Owner |
|---|---|---|---|
| `order-service` | Alteração de lógica de negócio | Alto — fluxo principal de pedidos | @squad-commerce |
| `api-gateway` | Adição de rota | Baixo — rota isolada | @squad-platform |
| `order-db` | Migration de schema | Médio — downtime possível em deploy | @squad-data |
| `payment-api` (ext) | Versão nova do contrato | Alto — quebra de compatibilidade | Stripe (externo) |

---

## 2. Dependências impactadas indiretamente

Módulos **não modificados por esta feature** que podem ser afetados por efeito colateral:

| Módulo | Razão do impacto indireto | Ação necessária |
|---|---|---|
| `billing-service` | Consome eventos de `order.created` — novo campo no payload | Validar contrato de evento (schema registry) |
| `analytics-pipeline` | Lê direto na `order-db` via replica | Garantir que migration não quebra queries existentes |

---

## 2.1 Conflitos entre homologações (quando houver frentes concorrentes)

| Item | Descrição |
|---|---|
| Branches/homologações concorrentes | [listar branches que tocam arquivos sobrepostos] |
| Estratégia de coexistência | [ex.: feature flag default OFF + ativação progressiva por segmento] |
| Decisor de conflito funcional | [Product/Arquitetura responsável por decisão de precedência] |
| Critério de limpeza da flag | [data/condição para remoção definitiva] |

> Se não houver frentes concorrentes, preencher com `N/A`.

---

## 3. Análise de risco

| Risco | Probabilidade | Severidade | Score | Mitigação |
|---|---|---|---|---|
| Migration `order-db` com lock de tabela em produção | Média | Alta | 🔴 Alto | Usar migração compatível (nullable + backfill + not-null em fase separada) |
| Incompatibilidade do contrato Stripe v2 | Baixa | Alta | 🟡 Médio | Testes de contrato (Pact) antes do deploy |
| Latência no `order-service` com novo step de validação | Média | Média | 🟡 Médio | Benchmark local; definir SLO no Architecture Decision Log |
| Falha em cascata se `payment-api` ficar indisponível | Baixa | Alta | 🟡 Médio | Fila de retry + DLQ + alerta de backlog |

> **Score:** 🔴 Alto (prob. ≥ Média **e** sev. Alta) · 🟡 Médio · 🟢 Baixo

---

## 4. Plano de rollback

```
1. Feature flag desativada imediatamente (se disponível) — zero downtime.
2. Se migration já aplicada: manter schema compatível (coluna nova nullable)
   permite reverter o código sem reverter a migration.
3. Se dados corrompidos: restaurar replica de leitura mais recente e acionar
   runbook de recuperação de dados (link: <runbook-url>).
4. Comunicar @squad-commerce e @squad-data antes de qualquer rollback em produção.
```

---

## 5. Critérios de Go/No-Go para deploy

- [ ] Todos os testes de integração passando em CI
- [ ] Migration testada em ambiente de staging com volume representativo de dados
- [ ] Contrato de evento com `billing-service` validado (Pact ou equivalente)
- [ ] SLO de latência do `order-service` medido e dentro do limite definido no ADL
- [ ] Plano de rollback revisado e comunicado ao time

---

> _Substitua todos os exemplos acima pelos módulos e riscos reais desta feature._
> _Para features S3/S4, este arquivo é revisado pelo tech lead antes de /nimbus-code-tasks._
