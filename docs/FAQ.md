# FAQ — Operação Nimbus Code

## O que é uma "issue perdida"?

É uma issue que permanece aberta mesmo após a implementação já ter sido
mergeada.

## Por que isso acontece?

Porque a PR foi mergeada sem keyword de fechamento no formato reconhecido pelo
GitHub (`Closes #<n>`, `Fixes #<n>`, `Resolves #<n>`). Menção solta `#<n>` em
texto ou tabela não garante fechamento automático.

## Como evitamos esse problema daqui para frente?

1. Regra de PR no time: toda issue implementada deve aparecer no corpo da PR com
   `Closes #<n>` (ou `Fixes #<n>`).
2. Fallback automático: workflow
   [close-referenced-issues-fallback.yml](/Users/lrodrigues/projects/nimbus-code-spec-kit-template/.github/workflows/close-referenced-issues-fallback.yml)
   tenta fechar issues abertas referenciadas em PR mergeada quando o vínculo
   padrão falhar.

## Prompt padrão para triagem e correção

```text
Faça triagem de issues abertas e identifique "issues perdidas" (implementadas, mas ainda abertas).

Objetivo:
1) Listar issues `type:task` abertas cujo T-ID esteja marcado como [x] no `tasks.md` da mesma feature.
2) Para cada issue perdida, validar evidência em PR mergeada (arquivos alterados + descrição da PR).
3) Fechar somente casos de alta confiança com comentário padrão:
   "Fechada por triagem: implementação já mergeada em PR #<n>, porém sem auto-close keyword."
4) Para os casos não conclusivos, comentar com pendência e manter aberta.
5) No final, gerar relatório: fechadas, pendentes, risco/ambiguidade e ações recomendadas.

Regras obrigatórias:
- Em toda PR futura, incluir `Closes #<n>` ou `Fixes #<n>` para cada issue resolvida.
- Não usar apenas menções soltas `#<n>` em tabela/texto.
```

## Como o time decide se deve publicar nova versão do bundle/preset?

Use labels por PR (`release:major`, `release:minor`, `release:patch`,
`release:skip`) e consolide na issue `Release Candidate: develop`, alimentada
pelo workflow
[release-impact-advisor.yml](/Users/lrodrigues/projects/nimbus-code-spec-kit-template/.github/workflows/release-impact-advisor.yml).

## O PR `develop` -> `main` pode ser automático com aprovador?

Sim. O workflow
[promote-develop-to-main.yml](/Users/lrodrigues/projects/nimbus-code-spec-kit-template/.github/workflows/promote-develop-to-main.yml)
cria/atualiza esse PR e pede review para os aprovadores configurados nas vars:

- `NIMBUS_MAIN_PR_REVIEWERS` (CSV de usuários)
- `NIMBUS_MAIN_PR_REVIEW_TEAMS` (CSV de times)

## A publicação da versão pode acontecer antes do merge em `main`?

Não. A tag `vX.Y.Z` deve ser criada só depois do merge em `main`. O workflow
[release.yml](/Users/lrodrigues/projects/nimbus-code-spec-kit-template/.github/workflows/release.yml)
valida isso e falha se a tag não estiver em commit da `main`.
