# Quickstart: Validar o Fluxo de Correção de Rota

## Purpose

Validar que a documentação da feature cobre corretamente os cenários de
correção de rota em features já existentes.

## Prerequisites

- [spec.md](./spec.md) completo
- [plan.md](./plan.md) completo
- [research.md](./research.md) completo
- [data-model.md](./data-model.md) completo
- [contracts/process-correction-decision.contract.md](./contracts/process-correction-decision.contract.md) completo
- [docs/developer-guide.md](../../docs/developer-guide.md) atualizado
- [.specify/memory/constitution.md](../../.specify/memory/constitution.md) atualizado

## Validation Scenarios

1. **Erro só na implementação**
   - Abra [docs/developer-guide.md](../../docs/developer-guide.md)
   - Vá para a seção “Manual operacional — quando a feature já existe...”
   - Confirme que o fluxo orienta correção de código + `converge`

2. **Erro na intenção/aceite**
   - Confirme que a matriz de decisão aponta atualização da mesma `spec.md`
   - Confirme que `clarify` é descrito como opcional para resolver ambiguidade real

3. **Erro de arquitetura com mesma feature**
   - Confirme que o fluxo orienta atualização do mesmo `plan.md`
   - Confirme que `tasks.md` é tratado como derivado do plan/spec atualizados

4. **Caso que virou nova feature**
   - Confirme que existe critério explícito para abrir nova spec
   - Confirme que “novo recorte de valor” aparece como condição de corte

5. **Política de idioma**
   - Abra [.specify/memory/constitution.md](../../.specify/memory/constitution.md)
   - Confirme que código/artefatos de código ficam em inglês
   - Confirme que documentação permanece em português

6. **Edge cases do fluxo**
   - Confirme que o caso “erro descoberto antes do `plan.md`” aponta atualização da mesma `spec.md` antes do planejamento
   - Confirme que o caso “erro descoberto depois do merge” mantém a correção de rota válida para artefatos
   - Confirme que o caso “parece nova feature, mas ainda é o mesmo valor” mantém a mesma spec

## Expected Outcome

- O time consegue responder corretamente qual comando usar em cada cenário
- `converge` não é confundido com atualização de `spec.md` ou `plan.md`
- O corte entre “mesma spec” e “nova spec” fica explícito e reproduzível
