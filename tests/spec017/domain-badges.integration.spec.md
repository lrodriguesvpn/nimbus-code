# test_AC6_domain_badges_defined

## Objetivo
Validar AC-6: badges por domínio possuem critérios objetivos e evidências auditáveis.

## Cenários
1. Publicar badge para domínio prioritário com nível e critérios.
2. Validar presença de evidências mínimas exigidas.
3. Verificar workflow de status `draft -> published -> deprecated`.

## Asserções
- Campo `domain` e `level` presentes.
- `eligibility_criteria` e `evidence_requirements` não vazios.
- Mudanças de status registradas com owner e racional.

