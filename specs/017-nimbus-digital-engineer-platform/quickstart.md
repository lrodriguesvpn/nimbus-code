# Quickstart — 017-nimbus-digital-engineer-platform

## Objetivo
Validar ponta a ponta o fluxo da plataforma Nimbus em modos governados, desde intake até handoff.

## Pré-requisitos
- Acesso ao repositório de governança (`nimbus-code-spec-kit-template`)
- Ambiente com integrações de origem simuladas (M365/GitHub)
- Política de classificação de modo configurada
- Papel de aprovador habilitado para checkpoints

## Cenários de validação

### Cenário 1 — Intake corporativo (AC-1)
1. Simular entrada de reunião M365 com `title`, `objective`, `owner`, `priority`.
2. Simular entrada SharePoint para mesma demanda.
3. Validar criação de um único `IntakeEntry` consolidado em status `qualified` ou `ready`.

**Resultado esperado**: demanda registrada com metadados mínimos completos e pronta para classificação.

### Cenário 2 — Classificação de modo (AC-2)
1. Enviar demanda de baixo risco.
2. Enviar demanda de risco médio.
3. Enviar demanda crítica com requisito de compliance.

**Resultado esperado**:
- baixa criticidade -> `autonomous`
- média criticidade -> `semi_autonomous`
- crítica/compliance -> `manual_approval`

### Cenário 3 — Gate de aprovação (AC-3)
1. Executar demanda classificada como `manual_approval`.
2. Não registrar decisão do aprovador.
3. Reexecutar com decisão `go`.

**Resultado esperado**:
- sem decisão: fluxo bloqueado
- com `go`: avanço liberado com trilha de auditoria

### Cenário 4 — Handoff com custo e qualidade (AC-4)
1. Concluir demanda piloto.
2. Gerar `DeliveryHandoff`.
3. Conferir presença de evidências de qualidade, aceite e custos.

**Resultado esperado**: handoff inclui custo IA + humano, decisão final e pendências.

### Cenário 5 — Toggle de rollout (AC-5)
1. Configurar `nimbus.modes.autonomy-orchestration` via OpenFeature.
2. Ativar em segmento piloto.
3. Desativar pelo kill switch.

**Resultado esperado**: mudança de modo ocorre por abstração OpenFeature sem acoplamento direto ao provider.

### Cenário 6 — Badges por domínio (AC-6)
1. Publicar 1 badge por domínio priorizado.
2. Validar critérios e evidências mínimas por badge.

**Resultado esperado**: badges auditáveis e publicados antes do rollout geral.

## Critérios mínimos de elegibilidade de badges (US5)
- Cada badge deve incluir:
  - domínio;
  - nível (`foundational`, `intermediate`, `advanced`);
  - critérios objetivos de elegibilidade;
  - evidências mínimas verificáveis.

## Matriz rápida de validação AC-1..AC-6 (Polish)

| AC | Cenário quickstart | Resultado esperado |
|---|---|---|
| AC-1 | Cenário 1 | Intake consolidado e completo |
| AC-2 | Cenário 2 | Modo classificado com justificativa |
| AC-3 | Cenário 3 | Bloqueio sem aprovação válida |
| AC-4 | Cenário 4 | Handoff com custo e qualidade |
| AC-5 | Cenário 5 | Rollout via OpenFeature e kill switch |
| AC-6 | Cenário 6 | Badges publicados com critérios |

## Referências
- Modelo de dados: [data-model.md](./data-model.md)
- Contratos: [contracts/](./contracts/)
- Plano: [plan.md](./plan.md)
