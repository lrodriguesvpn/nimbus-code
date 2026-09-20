# Data Model: Process Recovery Flow for Existing Specs

## Entities

### ProcessCorrectionCase

Representa um caso concreto em que uma feature existente precisa de correção de
rota.

**Fields**
- `feature_reference`: caminho ou identificador da feature atual
- `problem_type`: implementation-error, specification-error, architecture-error, new-scope
- `plan_exists`: boolean indicando se o `plan.md` já existe para a feature
- `same_value_slice`: boolean indicando se o recorte de valor permanece o mesmo
- `business_outcome`: resultado de negócio entregue pela feature
- `actors`: conjunto de usuários/atores beneficiados
- `delivery_boundary`: fronteira de entrega, rollout e ownership
- `recommended_path`: clarify, update-spec, update-plan, update-tasks, implement, converge, new-spec

### SourceOfTruth

Representa o artefato normativo vigente da feature.

**Fields**
- `artifact_type`: spec, plan, tasks
- `path`
- `owns_intent`: boolean
- `can_be_changed_by_converge`: boolean (sempre `false` para spec/plan)

### DecisionRule

Representa uma regra operacional usada para escolher o caminho de correção.

**Fields**
- `trigger`
- `applies_when`
- `action`
- `must_update_artifacts`
- `must_not_do`

### NewSpecCriteria

Representa os critérios que justificam abrir uma nova spec.

**Fields**
- `new_value_delivery`
- `independent_rollout`
- `independent_owner`
- `independent_business_scope`

**Decision rule:** o recorte de valor permanece o mesmo somente quando
`business_outcome`, `actors` e `delivery_boundary` permanecem iguais. Uma
mudança independente em qualquer dimensão exige nova spec.

### AdoptionMeasurement

Representa a medição pós-release do SC-002.

**Fields**
- `baseline`
- `standardized_questionnaire`
- `sample_of_devs_and_bas`
- `measurement_window`: 30–90 dias após publicação
- `owner`: Governança Nimbus Code
- `target_correct_answers`: >= 90%

## Relationships

- Um `ProcessCorrectionCase` consulta um ou mais `DecisionRule`
- Um `ProcessCorrectionCase` referencia os `SourceOfTruth` afetados
- Um `ProcessCorrectionCase` pode ou não satisfazer os critérios de `NewSpecCriteria`

## Validation Rules

- Todo caso deve classificar se o problema está no código, na spec, no plan ou em novo escopo
- Se `plan_exists = false`, a recomendação não pode pular a atualização da `spec.md` antes do planejamento
- `converge` nunca pode ser descrito como mutação de `spec.md` ou `plan.md`
- Se `same_value_slice = true`, a recomendação padrão deve permanecer na mesma feature
- Nova spec exige pelo menos um critério positivo em `NewSpecCriteria`
- Alteração constitucional exige paridade validada entre constituição local,
  presets e cópias espelho antes do Go/No-Go
