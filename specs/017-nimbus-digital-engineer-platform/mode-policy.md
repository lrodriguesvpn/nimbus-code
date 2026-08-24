# Mode Policy — 017-nimbus-digital-engineer-platform

## Baseline
- Modos suportados:
  - `autonomous`
  - `semi_autonomous`
  - `manual_approval`
- Chave de rollout: `nimbus.modes.autonomy-orchestration`
- Abstração obrigatória: OpenFeature

## Critérios de classificação (US2)

| Critério | Valor | Resultado padrão |
|---|---|---|
| Risco | baixo | `autonomous` |
| Risco | médio | `semi_autonomous` |
| Risco | alto | `manual_approval` |
| Criticality | `business_high` | no mínimo `semi_autonomous` |
| Compliance required | `true` | `manual_approval` |

## Precedência para sinais conflitantes
1. `compliance_required=true` sempre vence e força `manual_approval`.
2. Em empate de risco vs criticidade, usar o modo mais restritivo.
3. Se houver dados insuficientes, classificar como `manual_approval` até saneamento.

## Guardrails de rollout (OpenFeature)
- Sem bypass da abstração OpenFeature em ambiente algum.
- Ativação gradual: interno -> piloto -> canário -> geral.
- Cada ativação deve registrar:
  - versão da policy;
  - segmento habilitado;
  - responsável;
  - timestamp.

## Kill-switch operacional
- Trigger imediato se:
  - erro de classificação > 0,5% por 5 min; ou
  - bloqueio indevido em demanda crítica; ou
  - avanço sem aprovação mandatória detectado.
- Ação:
  1. Desabilitar `nimbus.modes.autonomy-orchestration`.
  2. Reverter para fluxo anterior.
  3. Abrir incidente com causa raiz e plano de correção.

