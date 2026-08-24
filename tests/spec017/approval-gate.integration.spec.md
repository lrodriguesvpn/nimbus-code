# test_AC3_human_approval_gate

## Objetivo
Validar AC-3: fluxo não avança sem aprovação mandatória registrada por papel autorizado.

## Cenários
1. Iniciar demanda em `manual_approval` sem decisão -> fluxo bloqueado.
2. Registrar decisão `go` por papel não autorizado -> decisão rejeitada.
3. Registrar decisão `go` por papel autorizado -> fluxo liberado.

## Asserções
- Estado inicial do checkpoint: `pending`.
- Transição permitida apenas para `go`/`no_go` por aprovador válido.
- Trilha de auditoria contém decisão, papel e timestamp.

