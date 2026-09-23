# ADR 0007: Governança de Templates Híbridos (Agente + Humano)

- **Status:** Aprovado
- **Data:** 2026-08-18
- **Decisores:** Tech Lead + Dev Platform
- **Relacionada à feature:** `specs/016-hybrid-agent-human-dev`

## Contexto

O template base precisava evoluir para suportar execução híbrida entre agentes de IA
e pessoas desenvolvedoras sem perda de clareza operacional. O fluxo anterior permitia
saídas válidas, mas não padronizava suficientemente:

- contrato de task executável por humano no GHE;
- referência de custo da operação híbrida;
- padrão obrigatório de design para WEB;
- padrão de abstração de toggle para rollout progressivo.

## Decisão

Adotar o padrão `hybrid-dev-templates` com as seguintes regras:

1. **Spec template** deve incluir bloco explícito de colaboração híbrida.
2. **Tasks/Issues** devem seguir contrato com Contexto, Objetivo, Resultado, Critérios,
   Passos Operacionais, Dependências, Responsável, Estimativa e Referência.
3. **Plan template** deve incluir `Cost Reference` com URL do SPEC KIT COST.
4. **WEB context** deve declarar **Impeccable** como padrão oficial de design.
5. **Rollout/toggle context** deve declarar **OpenFeature** como padrão de abstração.
6. CI deve validar contrato mínimo dos artefatos de exemplo via script dedicado.

## Consequências

### Positivas

- Reduz handoff implícito entre agente e humano.
- Aumenta previsibilidade de execução de tasks no GHE.
- Padroniza governança de design e rollout em todos os projetos bootstrapados.
- Melhora rastreabilidade de custo e compliance com gates do bundle.

### Trade-offs

- Incrementa manutenção de templates e skills.
- Exige disciplina para manter fixtures e script de validação atualizados.

## Alternativas consideradas

1. Manter templates atuais e orientar via documentação externa.
   - Rejeitada por baixo enforcement.
2. Criar validação apenas em review humano.
   - Rejeitada por feedback tardio.
3. Fixar provider de feature flag em vez de OpenFeature.
   - Rejeitada por lock-in.

## Rollout

- Aplicar em `nimbus-code`.
- Validar em projetos piloto.
- Expandir para bootstrap padrão após validação.
