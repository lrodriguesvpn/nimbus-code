# Quickstart: Validar Governança de Repos Satélite e Intake Greenfield MultiRepo

## Purpose

Validar que a feature cobre corretamente a entrada greenfield/brownfield, a
decisão mono vs multirepo e a relação operacional entre repo central e
satélites.

## Prerequisites

- [spec.md](./spec.md) completo
- [plan.md](./plan.md) completo
- [research.md](./research.md) completo
- [data-model.md](./data-model.md) completo
- [contracts/topology-intake.contract.md](./contracts/topology-intake.contract.md) completo
- [graph.yaml](./graph.yaml) e [graph.md](./graph.md) completos
- [impact-map.md](./impact-map.md) completo

## Validation Scenarios

1. **Greenfield real**
   - Considere um repo com apenas README, licença, `.gitignore`, workflow e setup mínimo
   - Confirme em [spec.md](./spec.md) e [research.md](./research.md) que isso não é tratado automaticamente como brownfield
   - Confirme no [contracts/topology-intake.contract.md](./contracts/topology-intake.contract.md) que a decisão segue para o fluxo greenfield
   - Confirme que a definição operacional de `relevant application code` exclui esses artefatos isolados

2. **Brownfield real**
   - Considere um repo já contendo `src/`, `app/`, `services/` ou código executável equivalente com manifest de runtime/build
   - Confirme que [spec.md](./spec.md) e [data-model.md](./data-model.md) tratam esse caso como brownfield
   - Confirme que a criação padrão de satélites não é sugerida como passo imediato

3. **Decisão mono vs multirepo**
   - Abra [spec.md](./spec.md)
   - Verifique AC-3 e FR-002/FR-003
   - Confirme que a escolha exige justificativa explícita com motivo principal, trade-off esperado e responsável

4. **Baseline de domínios satélite**
   - Verifique em [spec.md](./spec.md) e [research.md](./research.md) que FRONT, BACK, DESIGN, DATA e JOBS aparecem como baseline recomendada após a primeira spec estrutural
   - Verifique em [docs/developer-guide.md](../../docs/developer-guide.md) que a orientação operacional pós-primeira-spec materializa essa baseline e documenta como adaptá-la
   - Confirme que o bootstrap apenas faz o handoff para essa etapa, sem tentar materializar a topologia completa antes da spec
   - Confirme que a documentação também permite domínios alternativos com justificativa e ownership explícitos

5. **Fonte única de verdade**
   - Verifique em [contracts/topology-intake.contract.md](./contracts/topology-intake.contract.md) e [data-model.md](./data-model.md) que o repo central concentra os artefatos de spec
   - Confirme que o satélite recebe código e tasks roteadas, mas não `specs/`

6. **Alinhamento contínuo central → satélite**
   - Verifique em [spec.md](./spec.md) AC-7 e FR-009/FR-010
   - Confirme que o caminho oficial de atualização do satélite é via mecanismo oficial do bundle e PR revisado

7. **Separação entre governança e bugfix**
   - Verifique em [spec.md](./spec.md), [plan.md](./plan.md) e [tasks.md](./tasks.md) que a feature trata regras permanentes de processo
   - Confirme que correções operacionais pontuais do bootstrap permanecem fora do escopo desta feature

## Expected Outcome

- O time consegue distinguir corretamente greenfield de brownfield no onboarding
- A decisão mono vs multirepo deixa de ser implícita
- A baseline de domínios acelera a decomposição inicial sem engessar o produto
- O repo central fica consolidado como fonte única de verdade para specs
- O satélite permanece alinhado ao bundle oficial sem criar fluxo paralelo
