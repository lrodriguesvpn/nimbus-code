# Retrospectiva da Feature — `<feature-slug>`

<!--
  Preencher quando a implementação divergiu do plano de forma relevante:
  grafo mudou, SLO não atingido, bug inesperado encontrado, escopo expandido.
  Referenciado pelo checklist de fechamento do tasks-template.md.
  Localização: specs/<feature-slug>/retro.md
-->

## O que divergiu do plano?

*Liste apenas divergências relevantes — não registrar pequenos ajustes de
implementação. Foque no que mudou em relação ao `plan.md` aprovado.*

| Artefato / área | O que estava planejado | O que aconteceu de fato |
|---|---|---|
| [ex.: graph.yaml] | [módulos X e Y] | [foi necessário incluir módulo Z não previsto] |
| [ex.: SLO Gate] | [p99 < 200ms] | [p99 real em staging: 340ms — investigado e corrigido antes do merge] |
| [ex.: testes de integração] | [AC-2 coberto por teste] | [dependência externa indisponível em CI — teste adiado, Issue aberta] |

## Causa raiz da(s) divergência(s)

*Uma linha por causa. Seja específico — "especificação incompleta" não é
causa raiz; "bounded context do serviço X não estava mapeado no graph.yaml
antes do plan" é.*

- [ ] [causa raiz 1]
- [ ] [causa raiz 2]

## Ação para o próximo ciclo

*O que muda no processo ou nos artefatos para evitar esta divergência na
próxima feature semelhante? Pode ser uma atualização no `reuse-catalog.yaml`,
uma regra nova na constituição ou um ajuste no template de plan.*

| Ação | Responsável | Data alvo | Issue/PR |
|---|---|---|---|
| [ex.: adicionar módulo X ao bounded-contexts.yaml] | [nome] | [YYYY-MM-DD] | [link] |

## Padrões aprendidos elegíveis para o catálogo de reuso

*Se esta divergência revelou um padrão (positivo ou negativo) reaproveitável,
registre aqui e adicione ao `docs/reuse-catalog.yaml`.*

- [ ] Padrão identificado: `[tag]` — `[descrição em 1–2 frases]`
- [ ] Entrada adicionada ao `docs/reuse-catalog.yaml`
