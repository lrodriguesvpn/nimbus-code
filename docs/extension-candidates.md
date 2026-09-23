# Extensões candidatas a repositório próprio

Análise de quais extensões (oficiais do Nimbus Code + customizadas da Nimbus-Code)
fazem sentido como **repositório independente** vs. viver dentro deste
monorepo (`nimbus-code`).

## Extensões oficiais do Nimbus Code (`bundled: true`) — não recriar

Já vêm com o próprio `specify` CLI, mantidas pelo GitHub. Só precisam ser
declaradas como dependência do bundle (`requires`/instalação padrão), nunca
copiadas para este repositório:

| Extensão | Uso |
| --- | --- |
| `git` | Criação/numeração de branch de feature, detecção de remote. **A mais usada** — praticamente todo projeto deveria instalá-la (`specify extension add git`). |
| `agent-context` | Mantém `copilot-instructions.md`/`CLAUDE.md` sincronizados com referências ao plano ativo. |
| `assess` | Pipeline de avaliação de ideia antes do `/nimbus-code-specify` (intake → research → define → shape → decide). |
| `bug` | Fluxo de triagem de bugs com relatório por bug em `.specify/bugs/<slug>/`. |
| `selftest` | Autoteste do próprio Nimbus Code — uso interno/CI do Nimbus Code, não do projeto. |

**Recomendação**: incluir `git` e `agent-context` como dependência padrão do
`nimbus-code-project-bundle` (hoje não estão declaradas — considerar acrescentar na
próxima versão do bundle, sujeita à mesma aprovação formal de qualquer mudança
de política).

## Extensões customizadas da Nimbus-Code

| Extensão | Onde vive hoje | Repo próprio? |
| --- | --- | --- |
| `nimbus-code-backlog-sync` | Neste monorepo (`extensions/nimbus-code-backlog-sync/`) | **Não, por enquanto.** Só passa a fazer sentido como repo próprio se precisar de release cadence independente do preset/workflow, ou se crescer a ponto de justificar múltiplos mantenedores dedicados. |

## Critério para decidir "repo próprio" vs. monorepo

Promover uma extensão/preset/workflow para repositório próprio quando:

1. **Cadence de release diverge** do resto do bundle (ex.: a integração com
   JIRA muda toda semana, mas a constituição da empresa muda uma vez por
   trimestre).
2. **Time responsável é diferente** do time de padrões/governança (ex.: um
   time de Segurança quer manter sua própria extensão de scanning, sem
   depender de aprovação do time de Plataforma para cada release).
3. **Reuso fora do bundle**: outra organização/bundle quer instalar só aquela
   peça, sem as demais.

Nenhum dos três critérios se aplica hoje a `nimbus-code-backlog-sync` — manter no
monorepo enquanto isso for verdade simplifica versionamento e review.
