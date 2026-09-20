# Retrospectiva da Feature — `020-satellite-repo-governance`

## O que divergiu do plano?

*Liste apenas divergências relevantes — não registrar pequenos ajustes de
implementação. Foque no que mudou em relação ao `plan.md` aprovado.*

| Artefato / área | O que estava planejado | O que aconteceu de fato |
|---|---|---|
| `spec.md` | A fase inicial focava a governança manual entre repositório central e satélites. | Em `2be44b6e85be641511db130cf17858424d7fb04c` (2026-09-20), a spec foi revisada para incorporar explicitamente a automação da Fase 2 e a régua de qualidade padronizada aplicada às SPECS 007–023. |
| `plan.md` | O plano original não previa executar imediatamente a automação semanal de auditoria nem o auto-PR de sincronização. | O `plan.md` recebeu três revisões após a primeira geração do `tasks.md` (`3cbc6e831c648559495499a870c9d5c6f378e3c4`, `ddc3062647a959e8e2af90724dee1f4b6beeda83` e `2be44b6e85be641511db130cf17858424d7fb04c`) para acomodar a trilha de automação contínua dos satélites. |
| `tasks.md` | A quebra inicial não continha a trilha de automação de sincronização de preset. | Foram adicionadas as tasks `T036` a `T045` depois da primeira geração do backlog, expandindo o escopo para cobrir detecção de drift, auditoria semanal, auto-PR e documentação operacional. |

## Causa raiz da(s) divergência(s)

*Uma linha por causa. Seja específico — "especificação incompleta" não é
causa raiz; "bounded context do serviço X não estava mapeado no graph.yaml
antes do plan" é.*

- [x] A automação de governança da Fase 2 só foi explicitada depois da primeira geração de `tasks.md`, quando o time consolidou a necessidade de auditar drift de preset entre o repositório central e os satélites como parte da própria feature 020.
- [x] A padronização posterior das SPECS 007–023 trouxe revisões tardias em `spec.md` e `plan.md`, fazendo a implementação absorver requisitos que não estavam presentes na fotografia original do plano.

## Ação para o próximo ciclo

*O que muda no processo ou nos artefatos para evitar esta divergência na
próxima feature semelhante? Pode ser uma atualização no `reuse-catalog.yaml`,
uma regra nova na constituição ou um ajuste no template de plan.*

| Ação | Responsável | Data alvo | Issue/PR |
|---|---|---|---|
| Incluir no `plan.md` um checkpoint explícito para decidir, antes do primeiro `tasks.md`, se a feature terá apenas governança manual ou também automação contínua entre repositórios. | Digital Engineering | 2026-10-15 | PR desta implementação |
| Revisar o roteiro de convergência das SPECS 007–023 para que bumps de qualidade e versionamento sejam aplicados antes da fase de implementação, e não no meio dela. | Architecture board | 2026-10-15 | PR desta implementação |

## Padrões aprendidos elegíveis para o catálogo de reuso

*Se esta divergência revelou um padrão (positivo ou negativo) reaproveitável,
registre aqui e adicione ao `docs/reuse-catalog.yaml`.*

- [x] Padrão identificado: `governance-phase2-needs-early-scope-lock` — features de governança multi-repo que podem evoluir para automação contínua precisam congelar esse escopo antes da primeira geração de `tasks.md`.
- [ ] Entrada adicionada ao `docs/reuse-catalog.yaml`
