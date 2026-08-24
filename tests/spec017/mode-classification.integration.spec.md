# test_AC2_mode_classification

## Objetivo
Validar AC-2: classificação de modo com justificativa explícita e versionamento de política.

## Cenários
1. Demanda baixa criticidade, sem compliance -> `autonomous`.
2. Demanda média criticidade -> `semi_autonomous`.
3. Demanda alta criticidade ou compliance obrigatório -> `manual_approval`.

## Asserções
- Campo `selected_mode` coerente com política.
- Campo `justification` com texto mínimo.
- Campo `policy_version` presente.
- Campo `conflict_resolution` presente quando houver sinais conflitantes.

