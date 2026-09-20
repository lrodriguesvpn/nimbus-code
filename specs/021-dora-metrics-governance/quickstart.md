# Quickstart: Validar Governança de Métricas DORA com Coleta Híbrida

## Purpose

Validar que a feature cobre corretamente definição, coleta automática,
ajuste manual auditável, interpretação combinada e conversão de degradação em
ação de backlog para os 4 indicadores DORA.

## Prerequisites

- [spec.md](./spec.md) completo
- [plan.md](./plan.md) completo
- [research.md](./research.md) completo
- [data-model.md](./data-model.md) completo
- [contracts/dora-quality-and-audit.contract.md](./contracts/dora-quality-and-audit.contract.md) completo
- [graph.yaml](./graph.yaml) e [graph.md](./graph.md) completos
- [impact-map.md](./impact-map.md) completo
- `scripts/process-metrics-report.sh` (feature 012) já instalado e funcional

## Validation Scenarios (AC-mapped)

### V1: Definições Fechadas dos 4 Indicadores (AC-1)

**Scenario**: Uma squad consulta a documentação oficial de métricas DORA pela primeira vez.

**Validation steps**:
1. Abrir `docs/playbooks/README.md`, seção "Cadência de Revisão de Métricas de Processo (DORA)"
2. Confirmar que os 4 indicadores têm fórmula, evento de origem e janela de medição explícitos (ver `data-model.md`, entidade `Metric Definition`)
3. **Assertion**: Duas squads diferentes, lendo a mesma seção, chegam à mesma regra de cálculo sem ambiguidade

**Files involved**: `docs/playbooks/README.md`, `data-model.md`

---

### V2: Coleta Automática como Caminho Padrão (AC-2)

**Scenario**: Um PR rotulado `dora:deployment-frequency` é mergeado.

**Validation steps**:
1. Rodar `scripts/process-metrics-report.sh --repo-owner <org> --repo-name <repo> --since <data> --until <data>`
2. Confirmar que o indicador é contado sem qualquer intervenção manual
3. Rodar `bash tests/scripts/process-metrics-report.detect.test.sh`
4. **Assertion**: suíte de teste passa e o indicador é rastreável até o evento de origem

**Files involved**: `scripts/process-metrics-report.sh`, `tests/scripts/process-metrics-report.detect.test.sh`

---

### V3: Ajuste Manual com Trilha de Auditoria Completa (AC-3)

**Scenario**: Um evento não foi capturado automaticamente por indisponibilidade temporária da fonte.

**Validation steps**:
1. Registrar um ajuste manual em `docs/playbooks/dora-manual-adjustments-log.yaml` com os 7 campos obrigatórios, incluindo `approved_by` e `review_cycle_period`
2. Tentar registrar um segundo ajuste **sem** um dos campos obrigatórios
3. Rodar o teste de integração correspondente (`tests/scripts/process-metrics-report.audit-trail.test.sh`)
4. **Assertion**: o ajuste completo é aceito; o ajuste incompleto é rejeitado com mensagem clara

**Files involved**: `docs/playbooks/dora-manual-adjustments-log.yaml`, `tests/scripts/process-metrics-report.audit-trail.test.sh`, `contracts/dora-quality-and-audit.contract.md`

---

### V4: Gate de Fechamento Bloqueado por Ajuste Incompleto (AC-3/FR-006)

**Scenario**: Uma revisão periódica está para ser fechada com um ajuste manual pendente de justificativa.

**Validation steps**:
1. Simular uma `Review Cycle` com um `Manual Adjustment` sem `evidence_link` preenchido
2. Confirmar que o gate de fechamento reporta o ciclo como `open` (nunca `closed`) enquanto o ajuste estiver incompleto
3. **Assertion**: nenhuma revisão fecha silenciosamente com ajuste incompleto

**Files involved**: `scripts/process-metrics-report.sh`, `data-model.md` (entidade `Review Cycle`)

---

### V5: Interpretação Combinada dos 4 Indicadores (AC-4)

**Scenario**: Uma revisão mensal analisa os 4 indicadores do período.

**Validation steps**:
1. Executar a rodada de revisão mensal com dados reais/simulados dos 4 indicadores
2. Confirmar que a conclusão (`combined_conclusion`) considera os 4 indicadores em conjunto, não isoladamente
3. **Assertion**: a conclusão documentada aponta causa provável considerando mais de um indicador quando relevante

**Files involved**: `docs/playbooks/README.md`, `data-model.md` (entidade `Review Cycle`)

---

### V6: Degradação Vira Ação de Backlog Rastreável (AC-5)

**Scenario**: Uma degradação relevante é identificada em uma revisão.

**Validation steps**:
1. Confirmar que o gatilho objetivo de degradação (FR-008) é atingido
2. Confirmar que uma Issue de `Improvement Action` é aberta/atualizada com `owner`, `priority` e `review_deadline`
3. **Assertion**: nenhuma degradação relevante fica sem ação de backlog correspondente, dentro do prazo de 5 dias úteis (SC-005)

**Files involved**: backlog/Issues do repositório, `data-model.md` (entidade `Improvement Action`)

---

### V7: Comparabilidade entre Squads de Maturidade Diferente (AC-6)

**Scenario**: Duas squads com tamanhos/escopos diferentes comparam evolução DORA.

**Validation steps**:
1. Revisar a seção de cadência/leitura combinada em `docs/playbooks/README.md`
2. Confirmar que a orientação trata comparação como evolução relativa (tendência própria de cada squad), não ranking absoluto entre squads de contextos diferentes
3. **Assertion**: a documentação deixa explícito que contexto de tamanho/escopo deve ser considerado antes de comparar squads diretamente

**Files involved**: `docs/playbooks/README.md`

## Validação executada nesta sessão

- **Cenário V1 (AC-1)**: validado por inspeção estrutural — `docs/playbooks/README.md` seção "Definições Oficiais dos Indicadores" contém fórmula, evento de origem, janela de medição e regra de inclusão/exclusão para os 4 indicadores.
- **Cenário V2 (AC-2)**: validado com suíte de integração estendida:
  - `bash tests/scripts/process-metrics-report.detect.test.sh` ✅ (7/7, incluindo os 3 novos casos de qualidade de dados — FR-011)
- **Cenário V3/V4 (AC-3, FR-006)**: validado com suíte de auditoria:
  - `bash tests/scripts/process-metrics-report.audit-trail.test.sh` ✅ (6/6 — ajuste completo aceito, incompleto rejeitado, aprovação obrigatória, IDs sequenciais, gate de fechamento bloqueado/aprovado)
- **Cenário V5 (AC-4)**: validado por inspeção estrutural — `docs/playbooks/README.md` seção "Leitura Combinada" exige `combined_conclusion` antes de fechar qualquer revisão.
- **Cenário V6 (AC-5)**: validado com suíte de degradação nova:
  - `bash tests/scripts/process-metrics-report.degradation-action.test.sh` ✅ (4/4 — sinal de degradação para deployment_frequency/lead_time, ausência de sinal quando saudável, orientação de ação de backlog)
- **Cenário V7 (AC-6)**: validado por inspeção estrutural — `docs/playbooks/README.md` seção "Comparabilidade entre Squads" orienta evolução relativa, não ranking absoluto.
- **Regressão**: `bash tests/scripts/process-metrics-report.retro-cadence.test.sh` ✅ (4/4, sem regressão da feature 012).
- **Grafo**: `graph.yaml`/`graph.md` conferidos — 5 módulos desta feature mapeados, nenhum módulo novo fora do grafo.

Total: **20/20 testes de integração passando** (7 detect + 4 retro-cadence + 5 audit-trail + 4 degradation-action).

## Protocolo de medição pós-release

Os resultados abaixo são gates de adoção e devem ser preenchidos após o
primeiro ciclo real; a execução local dos testes não os substitui.

| Medição | População/janela | Fonte | Responsável | Critério |
|---|---|---|---|---|
| Ingestão automática | Todos os eventos DORA de 4 ciclos semanais | Logs/eventos do GHE | Platform owner | ≥99% dos eventos esperados ingeridos |
| Registro de ajustes | 100% dos ajustes do período | `dora-manual-adjustments-log.yaml` | Quality owner | 100% com 7 campos, categoria válida e aprovação |
| Consolidação | 4 ciclos semanais ou 1 mensal | Review Cycles versionados | DORA owner | 100% com `combined_conclusion` e estado aprovado antes de fechar |

Para SC-001–SC-003, registrar população, ciclos completos, evidências e
responsável. SC-001 exige ingestão ≥99%; SC-002 exige zero fechamento com
pendência; SC-003 exige 100% dos ajustes com aprovação. Ausência da fonte deve
ser registrada como `data_insufficient`, nunca como sucesso.
