# Contract: Greenfield Topology Intake and Satellite Governance

## Purpose

Definir o contrato operacional mínimo para classificar a entrada de um
repositório no bootstrap, registrar a decisão mono vs multirepo e governar a
relação entre repo central e satélites.

## Inputs

| Field | Description | Required |
|---|---|---|
| `repository_reference` | Identificador do repositório atual | Yes |
| `has_relevant_application_code` | Indica se o repo já contém código de aplicação relevante | Yes |
| `requested_delivery_model` | `monorepo` ou `multirepo` | Yes, quando greenfield |
| `decision_reason` | Justificativa explícita para a decisão de topologia | Yes, quando greenfield |
| `decision_owner` | Papel ou responsável que confirmou a decisão estrutural | Yes, quando greenfield |
| `satellite_domains` | Lista inicial de domínios propostos para satélites | Required when `requested_delivery_model = multirepo` |
| `custom_domain_justifications` | Justificativas para domínios além da baseline sugerida | Required when custom domains exist |
| `custom_domain_ownership` | Time, papel ou repo responsável por cada domínio customizado | Required when custom domains exist |

## Decision Rules

| Condition | Required Action | Forbidden Action |
|---|---|---|
| `has_relevant_application_code = false` | Tratar o fluxo como greenfield e coletar a decisão de topologia | Mandar diretamente para o fluxo brownfield |
| `has_relevant_application_code = true` | Tratar o fluxo como brownfield | Oferecer criação padrão de satélites como se o produto estivesse nascendo agora |
| `requested_delivery_model = monorepo` | Registrar a justificativa e encerrar o intake estrutural sem sugerir satélites | Assumir que satélites serão criados depois sem decisão registrada |
| `requested_delivery_model = multirepo` | Registrar a justificativa, registrar `decision_owner` e orientar explicitamente que a baseline FRONT/BACK/DESIGN/DATA/JOBS será revisada após a primeira spec estrutural | Criar ou sugerir specs locais nos satélites |
| `custom_domain_justifications` presentes | Aceitar a adaptação da baseline e registrar ownership | Rejeitar domínios alternativos apenas por divergirem da baseline |

## Outputs

| Output | Description |
|---|---|
| `detected_mode` | `greenfield` ou `brownfield` |
| `topology_decision_recorded` | Confirmação de que a decisão mono vs multirepo foi registrada |
| `recommended_domain_baseline` | Lista sugerida de domínios satélite para multirepo |
| `repository_governance_rule` | Regra formal sobre repo central e satélites |
| `satellite_update_rule` | Regra oficial de alinhamento central → satélite |

## Invariants

- `spec.md`, `plan.md`, `tasks.md`, grafos, contratos e pesquisas vivem no repo central
- Repositórios satélite não mantêm `specs/` como prática padrão
- A decisão mono vs multirepo exige justificativa explícita
- A baseline FRONT/BACK/DESIGN/DATA/JOBS é recomendação inicial, não taxonomia obrigatória
- Atualizações do bundle em satélites acontecem por PR revisado, nunca por mudança direta em branch principal

## Operational Notes

- Considerar `relevant application code` apenas quando houver implementação real do produto, como `src/`, `app/`, `packages/`, `services/`, `frontend/`, `backend/`, testes de aplicação e manifests de build/runtime conectados a esses artefatos.
- Não considerar, sozinhos, `README`, `LICENSE`, `.gitignore`, workflows, templates, scripts de setup ou pastas vazias como sinal suficiente de brownfield.
- O campo `decision_reason` deve registrar, em texto curto, o motivo principal da escolha e o trade-off esperado.
- O campo `custom_domain_ownership` deve identificar claramente o time, papel ou repo responsável por cada domínio fora da baseline.
