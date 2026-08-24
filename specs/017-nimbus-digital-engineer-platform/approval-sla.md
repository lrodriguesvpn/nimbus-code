# Approval SLA — 017-nimbus-digital-engineer-platform

## Gates mandatórios por etapa

| Stage | Gate mandatória | Aprovador mínimo | Decisão permitida |
|---|---|---|---|
| Qualificação de intake | Não | ADE | `go` |
| Classificação final de modo | Sim (modo manual) | BA/PO | `go`/`no_go` |
| Handoff para cliente | Sim | BA + Engenharia | `go`/`approved_with_conditions`/`no_go` |

## Mapeamento RACI (checkpoint stages)

| Stage | Responsible | Accountable | Consulted | Informed |
|---|---|---|---|---|
| Intake | ADE | ADE Lead | BA | Engineering |
| Classificação | ADE | BA/PO | Security/Quality | Engineering |
| Aprovação final | BA + Digital Engineering | Product Owner | Security/Quality | Stakeholders |

## SLA de aprovação por criticidade

| Criticidade | Tempo máximo para decisão | Ação ao estourar prazo |
|---|---|---|
| Baixa | 8h úteis | Escalar para accountable da etapa |
| Média | 4h úteis | Escalar para PO + lead técnico |
| Alta/Crítica | 1h útil | Escalar imediato para owner executivo |

## Timeout e escalonamento (US3)
1. Ao atingir 80% do SLA sem decisão, enviar alerta ao aprovador e accountable.
2. Ao estourar SLA, abrir escalonamento para próximo nível RACI.
3. Se persistir sem decisão no segundo nível, bloquear definitivamente a etapa e registrar `no_go` operacional.

## Regras de autorização
- Apenas papéis designados em RACI podem registrar decisão final.
- Decisão fora do papel autorizado é inválida e deve ser rejeitada.
- Toda decisão deve conter justificativa textual mínima e timestamp.

