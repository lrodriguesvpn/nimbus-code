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

Além disso, o gate
[release-readiness-gate.yml](/Users/lrodrigues/projects/nimbus-code-spec-kit-template/.github/workflows/release-readiness-gate.yml)
bloqueia PR para `develop` sem classificação correta de `release:*`.

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

## Quem cria a tag agora?

Após merge em `main`, o workflow
[tag-release-on-main.yml](/Users/lrodrigues/projects/nimbus-code-spec-kit-template/.github/workflows/tag-release-on-main.yml)
cria/pusha a tag automaticamente usando a versão definida em
`bundles/nimbus-code-project-bundle/bundle.yml`. Se a tag já existir, ele não duplica.

## Como atualizo um projeto criado com uma versão antiga do bundle/preset com segurança?

O workflow `update-speckit-and-bundle.yml` (instalado pelo `bootstrap.sh` em
todo projeto consumidor) só **avisa** que há versão nova via issue semanal —
ele nunca aplica a atualização sozinho. Use o prompt abaixo com o agente de
Copilot **dentro do repositório do projeto consumidor** (não neste repositório)
para atualizar sem perder customização local nem pular o fluxo normal de PR.
Detalhamento completo em
[`docs/developer-guide.md`, seção 6.7](developer-guide.md#67-atualizando-um-projeto-consumidor-para-a-versão-mais-recente-do-bundle).

```text
Você está atualizando este projeto para a versão mais recente do bundle
`nimbus-code-project-bundle` da Nimbus-Code (fonte: nimbus-code-spec-kit-template).
Siga este roteiro sem pular etapas:

1. Diagnóstico
   - Leia .specify/integration.json e a tabela de versão no README (seção
     "Nimbus Code — Padrões Nimbus-Code") para descobrir as versões
     instaladas hoje (Nimbus Code CLI, bundle, preset, extensão, workflow).
   - Compare com a versão mais recente publicada nos catalog.json de
     nimbus-code-spec-kit-template (registre os catálogos primeiro se ainda
     não estiverem registrados, com os comandos da seção "Publicação e
     Catálogo" do README de nimbus-code-spec-kit-template).
   - Se a versão instalada já for a mais recente, pare aqui e informe — não
     há nada para atualizar.

2. Branch e escopo
   - Crie uma branch dedicada (ex.: `chore/update-nimbus-code-bundle-vX.Y.Z`).
   - Nunca faça commit direto em `main`/`develop` — esta atualização segue a
     mesma regra de qualquer outra mudança de dependência.

3. Aplicar a atualização sem destruir customização local
   - Rode `specify bundle install nimbus-code-project-bundle` (ou
     `specify preset add`/`extension add`/`workflow add` individualmente, se
     o projeto não usa o bundle consolidado).
   - **Nunca sobrescreva cegamente** `copilot-instructions.md`,
     `.specify/memory/constitution.md`, `docs/bounded-contexts.yaml`,
     `docs/reuse-catalog.yaml`, `docs/cost-profiles-and-rates.md`, nem
     qualquer arquivo em `docs/harness/` ou `docs/playbooks/` que já exista
     neste projeto com conteúdo próprio — faça diff seção por seção contra o
     template novo e mescle apenas o que é aditivo (novas seções, novas
     regras), preservando 100% do conteúdo específico deste projeto.
   - Se um arquivo novo do template (ex.: `docs/harness/`, `docs/playbooks/`,
     `scripts/generate-context-graph.sh`, `scripts/harvest-patterns.sh`,
     `scripts/process-metrics-report.sh`) ainda não existir neste projeto,
     copie-o integralmente — são artefatos aditivos, seguros de criar.
   - Se este projeto ainda não tiver a seção "Idioma dos Artefatos" na
     constituição, ou não tiver "Harness Engineering"/"Playbook de Sucesso"
     no `copilot-instructions.md`, adicione-as (são regras aditivas desta
     versão) sem remover nada que já existia.

4. Atualizar a documentação de versão
   - Atualize a tabela de versões no README (modelo em
     `templates/README-bundle-section.md` do repositório-fonte).
   - `.specify/integration.json` normalmente é reescrito por
     `specify init --here --force`, não editado à mão — confirme antes de
     alterá-lo manualmente.

5. Validar antes de abrir o PR
   - Rode qualquer suíte de testes/lint já existente neste projeto (ex.:
     `./scripts/run-tests.sh`, se existir).
   - Valide sintaticamente todo arquivo novo/alterado (YAML: parseia sem
     erro; shell: `bash -n`).
   - Confirme que nenhuma seção pré-existente de `copilot-instructions.md`/
     `constitution.md` foi removida — apenas adicionada.

6. Abrir o PR
   - Título: "chore: atualizar bundle nimbus-code-project-bundle para vX.Y.Z".
   - Corpo do PR deve listar: versão anterior → nova, o que é novo nesta
     versão (seções/artefatos adicionados) e confirmação de que nenhuma
     customização local foi perdida.
   - Classifique a complexidade como S1 ou S2 (atualização de dependência
     aditiva); se alterar comportamento de autenticação, segurança ou
     branch/merge, reclassifique para S3/S4 e peça revisão humana antes de
     prosseguir.
   - Peça revisão humana normal antes do merge — nunca faça merge sozinho.

Se em qualquer etapa encontrar conflito real entre o conteúdo específico
deste projeto e o novo conteúdo do template (não um caso puramente aditivo),
pare, documente o conflito no PR e peça decisão explícita do Dev — nunca
resolva um conflito de conteúdo escolhendo um lado silenciosamente.
```
