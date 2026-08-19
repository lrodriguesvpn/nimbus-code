---
description: "Cria ou atualiza, no backlog externo configurado (JIRA ou Azure DevOps), o item correspondente à spec/tasks da feature ativa."
---

## Contexto

Este comando roda tipicamente como hook (`after_specify`/`after_tasks`) dos comandos
nativos `nimbus-code.specify`/`nimbus-code.tasks`, mas também pode ser invocado manualmente
a qualquer momento sobre a feature ativa (`.specify/feature.json`).

## Pré-condições

1. Ler `nimbus-code-backlog-sync-config.yml` (se existir) para determinar `backlog.tool`
   (`jira` ou `azure-devops`) e o projeto/organização alvo.
2. Se não existir configuração, perguntar ao usuário uma única vez qual ferramenta
   usar e oferecer salvar a resposta em `nimbus-code-backlog-sync-config.yml` para as
   próximas execuções.
3. Se nenhuma ferramenta for configurada e o usuário optar por não configurar,
   encerrar silenciosamente (o hook é opcional; specs/ continua sendo a fonte da
   verdade sem isso).

## Passos

1. Ler `specs/<feature>/spec.md` (título, descrição, critérios de aceite) e, se
   existir, `specs/<feature>/tasks.md`.
2. **Se `backlog.tool == "jira"`**:
   - Autenticar via MCP Atlassian Rovo, se ainda não autenticado.
   - Perguntar/reutilizar a chave do projeto JIRA.
   - Garantir a hierarquia **EPIC → FEATURE → US** no projeto:
     - `EPIC`: guarda o contexto macro da iniciativa.
     - `FEATURE`: representa a feature ativa do `spec.md` (usar issue type "Feature" se
       existir; caso contrário, usar a própria Epic como nível da feature no JIRA).
     - `US`: criar/atualizar uma Story vinculada ao nível imediatamente acima.
   - Para cada tarefa em `tasks.md` ainda não sincronizada, criar uma Sub-task
     vinculada à Story (US).
3. **Se `backlog.tool == "azure-devops"`**:
   - Confirmar projeto e tipos de work item disponíveis (`wit_get_work_item_type`).
   - Garantir a hierarquia **EPIC → FEATURE → US**:
     - Criar/atualizar Epic da iniciativa.
     - Criar/atualizar Feature da `spec.md` como filha da Epic.
     - Criar/atualizar User Story(s) como filhas da Feature.
   - Para cada tarefa em `tasks.md` ainda não sincronizada, criar um work item
     "Task" filho da User Story via `wit_add_child_work_items`.
4. Gravar, em `specs/<feature>/.backlog-sync.json` (não versionado — adicionar a
   `.gitignore` do projeto se ainda não estiver), o mapeamento local
   `{ tarefa/critério → id do item externo }` para evitar duplicar itens em
   sincronizações futuras.
5. Reportar ao usuário os links dos itens criados/atualizados.

## O que este comando explicitamente NÃO faz

- Não substitui `specs/<feature>/spec.md`/`tasks.md` como fonte da verdade — o
  backlog externo é sempre uma *cópia derivada*, nunca a origem.
- Não apaga itens no backlog externo que não existam mais na spec — apenas cria/
  atualiza; remoções são manuais.
