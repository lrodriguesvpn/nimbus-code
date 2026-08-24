# Impact Map — 017-nimbus-digital-engineer-platform

## Objetivo de negócio
Reposicionar o Nimbus como plataforma de Digital Engineering assistida por IA com governança por modos operacionais.

## Impactos esperados
- Redução de lead time para demandas elegíveis.
- Aumento de previsibilidade de aprovação e auditoria.
- Transparência de custo operacional híbrido.

## Áreas impactadas
- Intake corporativo (M365/GitHub)
- Orquestração de modo e políticas de risco
- Gate de aprovação humana (RACI)
- Handoff e evidências para cliente
- Catálogo de badges por domínio

## Riscos principais e mitigação
1. **Classificação incorreta de modo**
   - Mitigação: política versionada + justificativa obrigatória + validação AC-2.
2. **Bloqueios operacionais por ausência de aprovador**
   - Mitigação: escalonamento definido no RACI + checkpoint explícito em AC-3.
3. **Inconsistência de custo em handoff**
   - Mitigação: obrigatoriedade de custo IA + humano em AC-4.
4. **Acoplamento a provider de flag**
   - Mitigação: OpenFeature obrigatório (AC-5).

## Plano de rollback (Go/No-Go)
- **Go**: erros <= 0,5%, sem bypass de aprovação obrigatória, handoff completo em 100% dos pilotos.
- **No-Go**: qualquer avanço sem aprovação mandatória, falha de trilha de auditoria, ou regressão severa em SLA.
- **Rollback**: kill switch via OpenFeature flag `nimbus.modes.autonomy-orchestration` e retorno ao fluxo anterior.

## Dependências indiretas
- Disponibilidade de conectores corporativos (M365/GitHub)
- Políticas de acesso e conformidade da organização
- Pipeline de evidências e observabilidade mínima

## Alinhamento final com artefatos de execução
- Política de modos: `mode-policy.md`
- SLA e escalonamento: `approval-sla.md`
- Matriz de evidências AC/FR/SC: `evidence-matrix.md`
- Handoff executivo: `implementation-log.md`
