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
1. Registrar um ajuste manual em `docs/playbooks/dora-manual-adjustments-log.yaml` com `justification`, `author`, `timestamp`, `evidence_link`, `exception_category`
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

Esta seção deve ser preenchida ao final da implementação (fase de Polish),
registrando os comandos efetivamente executados e seus resultados — mesmo
padrão já usado em `specs/012-loop-melhoria-continua/quickstart.md`.
