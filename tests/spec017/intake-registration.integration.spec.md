# test_AC1_m365_intake_registration

## Objetivo
Validar AC-1: intake de M365/SharePoint gera demanda com contexto mínimo completo e pronta para classificação.

## Pré-condições
- Pipeline de intake habilitado.
- Fontes simuladas para reunião M365 e pasta SharePoint.

## Cenários
1. Enviar intake vindo de reunião M365 com `objective`, `owner`, `priority`, `source_ref`, `correlation_key`.
2. Enviar intake de SharePoint para a mesma demanda (mesmo `correlation_key`).
3. Verificar consolidação em um único `IntakeEntry`.

## Asserções
- `status` final em `qualified` ou `ready`.
- Campos obrigatórios presentes.
- `duplicate_of` preenchido quando consolidado.

