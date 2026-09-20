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
- presets e cópias espelho aplicáveis atualizados e comparados
- `impact-map.md` revisado

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
   - Confirme que resultado de negócio, atores e fronteira de entrega são avaliados
   - Confirme que qualquer mudança independente em uma dessas dimensões abre nova spec

5. **Política de idioma**
   - Abra [.specify/memory/constitution.md](../../.specify/memory/constitution.md)
   - Confirme que código/artefatos de código ficam em inglês
   - Confirme que documentação permanece em português

6. **Edge cases do fluxo**
   - Confirme que o caso “erro descoberto antes do `plan.md`” aponta atualização da mesma `spec.md` antes do planejamento
   - Confirme que o caso “erro descoberto depois do merge” mantém a correção de rota válida para artefatos
   - Confirme que o caso “parece nova feature, mas ainda é o mesmo valor” mantém a mesma spec

7. **Paridade e aprovação**
   - Compare a seção de idioma da constituição local com os templates e cópias espelho aplicáveis
   - Registre o resultado da comparação no PR
   - Confirme que o Architecture Board aprovou o pacote antes do Go/No-Go

8. **Medição pós-release do SC-002**
   - Registre o baseline antes da publicação
   - Aplique o questionário padronizado a uma amostra de Devs/BAs entre 30 e 90 dias
   - Registre owner, amostra, respostas corretas e percentual final
   - Considere aprovado somente resultado igual ou superior a 90%

## Expected Outcome

- O time consegue responder corretamente qual comando usar em cada cenário
- `converge` não é confundido com atualização de `spec.md` ou `plan.md`
- O corte entre “mesma spec” e “nova spec” fica explícito e reproduzível
