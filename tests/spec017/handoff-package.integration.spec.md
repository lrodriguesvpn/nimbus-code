# test_AC4_delivery_handoff_package

## Objetivo
Validar AC-4: handoff final inclui qualidade, aceite, custo híbrido e responsáveis.

## Cenários
1. Concluir demanda com evidências completas.
2. Gerar `DeliveryHandoff`.
3. Avaliar presença de pendências e owners.

## Asserções
- `quality_evidence` e `acceptance_evidence` não vazios.
- `cost_ai_tokens` e `cost_human_hours` >= 0.
- `pending_items` e `pending_owners` coerentes.
- `final_decision` preenchido.

