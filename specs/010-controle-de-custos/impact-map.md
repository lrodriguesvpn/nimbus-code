# Impact Map & Risk Analysis: Controle de Custos (Feature 010)

**Feature Complexity**: S3 (múltiplos módulos + integrações com GitHub API e session store)  
**Risk Level**: Medium-High (dados financeiros; confiança do time depende de precisão)  
**Rollback Feasibility**: High (feature flag kill switch)

---

## 1. Dependency Impact Analysis

### Direct Dependencies

| Module | Role | Impact if Missing | Mitigation |
|---|---|---|---|
| `cost-collector` | Coleta tokens e horas humanas | Nenhum dado de custo coletado; dashboard vazio | Prioridade P0 de implementação; testado em piloto antes do prod |
| `cost-store` | Persistência de todos os registros | Perda total de dados de custo | Schema versionado + backup automático; rollback via feature flag |
| `cost-aggregator` | Benchmarks e consolidação | Dashboard sem benchmarks; sem drill-down por sprint/squad | Job batch com retry; falha não bloqueia coleta |
| `budget-alert-engine` | Alertas preventivos de orçamento | Nenhum alerta; gestores só sabem do estouro depois | Motor independente; falha não bloqueia coleta |
| `cost-dashboard` | Visibilidade para gestores | Gestores precisam consultar banco diretamente | Deploy separado do backend; beta pode usar API direta |
| `plan-template` (atualização) | Estimativas obrigatórias no plan.md | Features sem estimativa → nenhuma base de comparação | Campos sinalizados como obrigatórios; lint valida presença |

### Indirect Dependencies (External)

| System | Role | Impact if Unavailable | Mitigation |
|---|---|---|---|
| GitHub Project API v2 | Fonte de horas humanas | Dimension "human" sem dados; custo parcial | Fallback: marcador "custo humano não registrado" + alerta no dashboard |
| `assistant_usage_events` | Fonte de tokens por sessão | Dimension "tokens" sem dados; custo parcial | Fallback: estimativa manual; alerta de "dados de tokens ausentes" |
| SPEC KIT COST (referência) | Framework de rastreio de custo | Perda de referência documental; não impacta funcionalidade | URL monitorada em CI; fallback: repositório interno mirror |
| OpenFeature SDK | Feature toggle para rollout | Sem rollout gradual; deploy direto com risco maior | Fallback: env-var provider simples sem SDK |
| GitHub Enterprise | Notificações de alerta | Alertas não chegam aos gestores | Fallback: notificação por email direto (SMTP); webhook alternativo |

---

## 2. Risk Assessment Matrix

| Risk | Probability | Impact | Severity | Mitigation |
|---|---|---|---|---|
| **Dados de custo imprecisos**: tokens calculados incorretamente ou horas não lançadas | Medium | High | **High** | (1) Validação na coleta com limites razoáveis; (2) Dashboard sinaliza "dados incompletos" por feature; (3) Processo de curadoria mensal |
| **Adoção fraca de lançamento de horas**: devs não preenchem campo "Horas Humanas" | High | High | **High** | (1) Campo obrigatório no fluxo de fechamento de issue; (2) Dashboard exibe % de features com dados completos; (3) Eng. Manager recebe relatório semanal de cobertura |
| **Confiança negativa**: gestores veem dados errados e perdem confiança no sistema | Low | Critical | **High** | (1) Piloto interno antes de prod; (2) Período de calibração declarado (4 semanas); (3) Badge "dados em calibração" no dashboard inicial |
| **Performance**: dashboard lento com histórico grande | Low | Medium | **Medium** | (1) Índices em `feature_id`, `period`, `scope_id`; (2) Paginação obrigatória; (3) Benchmark p99 antes de prod |
| **Estouro silencioso**: alerta não disparado por falha no budget-alert-engine | Low | High | **Medium** | (1) Health check do motor; (2) Alerta de "motor inativo > 30 min" para ops; (3) Retry automático com backoff |
| **Âncora de estimativas ruins**: benchmarks baseados em poucas amostras | Medium | Medium | **Medium** | (1) Mínimo de 10 features por nível antes de ativar benchmarks; (2) Badge "amostra insuficiente" quando abaixo do mínimo |
| **Câmbio volátil**: custo em BRL distorcido por variação USD/BRL | Low | Low | **Low** | (1) Taxa de câmbio auditável por registro (ADR-5); (2) Filtros de período consistentes |
| **Tokens duplicados**: dois agentes executam na mesma feature em paralelo | Medium | Medium | **Medium** | (1) Deduplicação por `session_id` no cost-collector; (2) Relatório de "sessões paralelas" no dashboard |

---

## 3. Rollback Plan

### Scenario: Feature 010 Deployment Fails

**Trigger Conditions**:
- Dados de custo incorretos reportados por ≥ 2 gestores no piloto
- `cost-collector` falha em coletar tokens por > 5 min contínuos (health check red)
- Alerta de orçamento não disparado em 3 casos verificáveis
- Dashboard com latência p99 > 3s sustentada

**Rollback Steps** (estimativa: 15 min):

1. **Disable Feature Flag** (imediato, zero downtime)
   ```bash
   # Setar via OpenFeature provider / env var
   COST_CONTROL_V1=false
   ```
   → Coleta para; dashboard exibe banner "sistema em manutenção"

2. **Revert Template Changes** (se plan-template foi alterado)
   ```bash
   git revert <commit-hash-plan-template-update>
   ```
   → Novos plan.md não mais exigem campos de custo

3. **Preserve Data** (não dropar banco)
   ```bash
   # Banco permanece intacto para análise post-mortem
   # Apenas coleta é desativada via flag
   # NUNCA executar DROP TABLE ou DELETE em dados de custo
   ```

4. **Publish Incident** (GitHub Issue)
   ```markdown
   Title: Feature 010 Rollback — Controle de Custos Desativado
   Label: incident, feature:010
   Severity: P2
   
   Root cause: [breve motivo]
   Affected: [projetos piloto]
   Status: Flag desativada; análise em andamento
   Next: Post-mortem em 24h
   ```

5. **Validate Rollback**
   ```bash
   # Verificar que cost-collector não está emitindo novos registros
   # Verificar que dashboard exibe banner de manutenção
   # Verificar que plan-template não solicita mais campos de custo
   ```

**Estimated Time to Rollback**: ~10 min  
**Data Impact**: Dados coletados antes do rollback são preservados no banco; nenhuma perda

---

## 4. Release Strategy & Staged Rollout

| Stage | Audience | Duration | Flag Setting | Validation Criteria |
|---|---|---|---|---|
| **Dev** | Time interno (infra/plataforma) | Sempre ativo | `COST_CONTROL_V1=true` | Testes de integração passam; coleta funciona localmente |
| **Pilot HML** | 1–2 projetos internos | 1 semana | `COST_CONTROL_V1=true` (opt-in) | Dashboard exibe dados reais; alertas disparados corretamente em simulação |
| **Pilot Prod** | 1 projeto de produção | 2 semanas | `COST_CONTROL_V1=true` (opt-in) | Gestores confirmam dados plausíveis; % de cobertura de horas > 70%; nenhum alerta falso positivo |
| **GA (100%)** | Todos os projetos | Permanente | `COST_CONTROL_V1=true` | Rollback testado; métricas de adoção verdes; benchmarks com ≥ 10 amostras/nível |

### Kill Switch
```bash
COST_CONTROL_V1=false
```
Efeito imediato: coleta para, dashboard entra em modo somente-leitura com dados históricos.

---

## 5. Data Integrity & State Management

| Artifact | Behavior Before | Behavior After | State Risk |
|---|---|---|---|
| `cost-store` | Não existe | Banco com schema versionado e histórico imutável | **Medium** — schema novo; migração inicial sem dados históricos |
| `plan.md` (template) | Sem campos de custo obrigatórios | Campos de estimativa obrigatórios (tokens + horas) | **Low** — additive; não quebra specs antigas |
| Dashboard | Não existe | Exibe dados de custo por feature/sprint/squad | **Low** — novo sistema; não substitui nada existente |
| GitHub Project | Campo "Horas Humanas" já existe | Passa a ser lido automaticamente pelo cost-collector | **Low** — leitura only; não altera dados do projeto |

### Backward Compatibility

- **Specs e plans antigos**: não são afetados (campos de custo são novos; não removem nada)
- **GitHub Project**: campo lido de forma não-invasiva; nenhuma alteração estrutural no projeto
- **Features em andamento**: custo pode ser retroativamente registrado se dados de sessão ainda existirem

---

## 6. Critical Path & Success Milestones

```
Dia 0 (Hoje):    Plan.md aprovado
                   ↓
Dia 1–3:          Implementar cost-store (schema + migrations)
                   ↓
Dia 4–6:          Implementar cost-collector (GitHub API + session metadata)
                   ↓
Dia 7–9:          Implementar budget-alert-engine
                   ↓
Dia 10–12:        Implementar cost-aggregator + endpoints básicos do dashboard
                   ↓
Dia 13–14:        Piloto HML (1 projeto interno)
                   ↓
Dia 15–28:        Piloto Prod (1 projeto produção, 2 semanas)
                   ↓
Dia 29:           Decisão GA
                   - PASS: feature flag → prod 100%
                   - FAIL: kill switch + post-mortem
```

**Critical Gates**:
- [ ] Dia 6 EOD: cost-collector coleta dados reais (tokens + horas) sem erros
- [ ] Dia 14 EOD: piloto HML com dados plausíveis e alertas funcionando
- [ ] Dia 28 EOD: gestores confirmam confiança nos dados; % cobertura de horas ≥ 70%

---

## 7. Blast Radius & Affected Systems

### Tier 1 (Impacto Direto — Novos Componentes)

- **`cost-store`** (banco novo) — novo sistema; nenhum sistema existente depende dele
- **`cost-collector`** (novo serviço) — leitura de GitHub Project e session metadata; sem efeito colateral
- **`cost-aggregator`** (novo serviço batch) — apenas leitura e escrita no cost-store
- **`budget-alert-engine`** (novo motor) — dispara notificações; sobrecarga no canal de alerta se mal calibrado
- **`cost-dashboard`** (nova app) — novo sistema; não substitui nada

### Tier 2 (Impacto Indireto)

- **`plan-template`** — adição de campos de custo (additive); pode gerar friction em equipes que não querem preencher
- **GitHub Project** — leitura de "Horas Humanas"; se campo não existir, coleta parcial (não falha)
- **Gestores/Tech Leads** — recebem alertas novos; pode gerar ruído se mal calibrado no início

### Tier 3 (Sem Impacto)

- **Infraestrutura existente** (nenhuma mudança)
- **Features em andamento** (não são re-processadas automaticamente)
- **Pipelines de CI/CD existentes** (não são alterados por esta feature)

---

## 8. Cost & Effort Tracking

| Phase | Estimated Tokens | Actual Tokens | Variance |
|---|---|---|---|
| Specify (Feature 010) | ~10k | ~9.5k | -5% |
| Plan (Feature 010) | ~50–70k | TBD (após execução) | TBD |
| Tasks (Feature 010) | ~25–35k | TBD (após execução) | TBD |

**Referência**: [SPEC KIT COST](https://github.com/venha-pra-nuvem/spec-kit-cost)

---

## 9. Success Metrics

| Metric | Baseline | Target | Measurement |
|---|---|---|---|
| % features com dados de custo completos | 0% | ≥ 80% após 4 semanas GA | Cost-store: features com CostRecord em ambas as dimensions |
| % features com estimativa registrada | 0% | 100% após rollout de plan-template | plan.md: presença dos campos de custo |
| Variância estimativa vs. real (tokens) | N/A | ≤ ±30% (após 3 meses) | cost-aggregator: CostEstimate vs. CostRecord |
| Alertas disparados dentro do SLA (< 30 min) | N/A | ≥ 99% | budget-alert-engine: timestamp trigger vs. triggered_at |
| Latência dashboard p99 | N/A | < 800ms | cost-dashboard: logs de request duration |
| Adoção de lançamento de horas | 0% | ≥ 70% (devs lançando em ≥ 70% das issues) | GitHub Project: issues com "Horas Humanas" preenchido |

---

## 10. Post-Implementation Validation Checklist

- [ ] Piloto HML: coleta de tokens funcionando por 5 dias contínuos sem falha
- [ ] Piloto HML: alerta de 80% disparado em teste controlado dentro de 30 min
- [ ] Piloto Prod: gestor confirma "dados são plausíveis" para pelo menos 3 features
- [ ] Adoção de horas: ≥ 70% das issues do piloto com campo preenchido
- [ ] Performance: dashboard p99 < 800ms em carga simulada
- [ ] Rollback test: flag desativada → coleta para imediatamente (sem novos registros por 5 min)
- [ ] Reuse catalog atualizado com nova entrada (tag: `cost-control-hybrid`)
- [ ] Post-implementation ADR escrito para decisões restantes (ex.: provider OpenFeature em GA)

---

## References

- [Feature Spec](./spec.md)
- [Implementation Plan](./plan.md)
- [Module Dependency Graph](./graph.yaml)
- [Architecture Graphs](./graph.md)
- [Data Model](./data-model.md)
- [Quickstart Guide](./quickstart.md)
- [SPEC KIT COST](https://github.com/venha-pra-nuvem/spec-kit-cost)
