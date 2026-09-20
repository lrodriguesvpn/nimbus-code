# Contract: Process Correction Decision

## Purpose

Definir o contrato operacional mínimo para decidir como tratar uma feature já
existente quando surgir um erro funcional, arquitetural ou novo escopo.

## Inputs

| Field | Description | Required |
|---|---|---|
| `feature_reference` | Caminho ou identificador da feature atual | Yes |
| `problem_type` | `implementation-error`, `specification-error`, `architecture-error`, `new-scope` | Yes |
| `plan_exists` | Indica se o `plan.md` já existe para a feature | Yes |
| `same_value_slice` | Indica se o recorte de valor continua o mesmo | Yes |
| `business_outcome` | Resultado de negócio que a feature entrega | Yes |
| `actors` | Usuários/atores beneficiados pela entrega | Yes |
| `delivery_boundary` | Fronteira de entrega e rollout da feature | Yes |
| `acceptance_changed` | Indica se critérios de aceite mudaram | Yes |
| `architecture_changed` | Indica se o plano técnico vigente deixou de servir | Yes |

## Decision Rules

| Condition | Required Action | Forbidden Action |
|---|---|---|
| `plan_exists = false` e `same_value_slice = true` | Atualizar a mesma `spec.md` antes de criar ou refazer o `plan.md` | Pular direto para `converge` ou abrir nova spec sem novo valor |
| `problem_type = implementation-error` e `acceptance_changed = false` | Corrigir código e usar `converge` no fechamento | Reabrir spec sem necessidade |
| `problem_type = specification-error` ou `acceptance_changed = true` | Atualizar a mesma `spec.md`; usar `clarify` se houver ambiguidade real | Usar `converge` para reescrever intenção |
| `problem_type = architecture-error` e `same_value_slice = true` | Atualizar o mesmo `plan.md` e refletir em `tasks.md` | Abrir nova spec por reflexo |
| `problem_type = new-scope` e `same_value_slice = false` | Abrir nova spec | Esconder nova entrega dentro da spec antiga |
| `business_outcome`, `actors` e `delivery_boundary` permanecem iguais | Manter a mesma feature, mesmo com mudança técnica ou refinamento de aceite | Abrir nova spec apenas por esforço ou dificuldade técnica |
| Qualquer uma das três dimensões muda de forma independente | Abrir nova spec e registrar a decisão | Ocultar a mudança como correção da feature atual |

## Outputs

| Output | Description |
|---|---|
| `recommended_path` | Caminho operacional escolhido |
| `artifacts_to_update` | Lista de artefatos que precisam ser atualizados |
| `follow_up_command` | Próximo comando recomendado no fluxo Nimbus Code |

## Invariants

- `converge` é append-only em `tasks.md`
- `spec.md` continua sendo a fonte de verdade para intenção da feature
- `plan.md` continua sendo a fonte de verdade para desenho técnico da feature
- abrir nova spec exige novo recorte de valor, não apenas dificuldade de implementação
- o recorte de valor só é o mesmo quando resultado de negócio, atores e fronteira de entrega permanecem iguais
- alterações normativas devem atualizar a constituição local e os templates aplicáveis no mesmo PR, com paridade validada
