# Governance Validation Contract (Terraform Advisory)

## Purpose

Definir o contrato funcional para validacao de infraestrutura em modo advisory no MVP.

## Inputs

- contexto de execucao autenticada (SSO);
- referencia do ambiente/tenant/provedor;
- artefatos de infraestrutura para validacao;
- snapshot atual do CMDB consolidado;
- baseline/politicas vigentes.

## Output

Relatorio advisory com:

- conformidades;
- nao conformidades por severidade;
- recomendacoes de remediacao;
- exigencia de registro de excecao para itens nao conformes.

## Severity mapping

- `critical`: risco imediato de seguranca/compliance;
- `high`: risco relevante com necessidade de remediacao prioritaria;
- `medium`: ajuste recomendado com prazo definido;
- `low`: melhoria incremental.

## MVP rule

No MVP, o contrato **nao bloqueia** aplicacao automaticamente.  
Ele produz evidencia obrigatoria para governanca e follow-up.
