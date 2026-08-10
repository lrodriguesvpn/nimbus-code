# nimbus-code-backlog-sync (extension)

## Propósito

Complementa o fluxo nativo do Nimbus Code (`specs/<feature>/*.md` como fonte da
verdade) com sincronização opcional para JIRA ou Azure DevOps, para times que
ainda dependem de um backlog externo visível para stakeholders não-técnicos.

Substitui a lógica de escrita em backlog que antes vivia embutida nas skills
internas `po-interview`, `dev-architect`, `dev-refinement` e `devops-planning` —
essas skills continuam existindo para a parte de *interview*/raciocínio técnico,
mas a parte de "gravar no JIRA/ADO" fica centralizada e reaproveitável aqui.

## Hooks registrados

| Hook | Quando dispara | Obrigatório? |
|---|---|---|
| `after_specify` | Depois de `/nimbus-code-specify` gerar `spec.md` | Não — pergunta antes |
| `after_tasks` | Depois de `/nimbus-code-tasks` gerar `tasks.md` | Não — pergunta antes |

Ambos são opcionais por padrão: projetos que não usam backlog externo (a maioria,
já que `specs/` é a fonte formal) simplesmente recusam o prompt.

## Instalação isolada (sem o bundle completo)

```bash
specify extension add nimbus-code-backlog-sync --from https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/releases/download/vX.Y.Z/nimbus-code-backlog-sync-X.Y.Z.zip
```

Ou em modo desenvolvimento:

```bash
specify extension add --dev ./nimbus-code-spec-kit-template/extensions/nimbus-code-backlog-sync
```

Depois, copiar o template de configuração:

```bash
cp .specify/extensions/nimbus-code-backlog-sync/config-template.yml \
   .specify/extensions/nimbus-code-backlog-sync/nimbus-code-backlog-sync-config.yml
```

E preencher `jira.project_key` ou `azure_devops.organization`/`project`, conforme
a ferramenta usada pelo projeto.

## Servidor(es) MCP necessários

Esta extensão **não instala nem configura** o servidor MCP — apenas assume que um
dos dois já está disponível no ambiente do agente:

- **JIRA**: MCP Atlassian Rovo (autenticação interativa na primeira execução)
- **Azure DevOps**: MCP `ado` (Boards habilitado no work item tracking)

O campo `requires.mcp` em `extension.yml` é apenas informativo — o comando
`specify extension add` exibe um aviso, mas não bloqueia a instalação nem verifica
a presença do servidor.

## Versionamento

Segue [SemVer](https://semver.org/). Ver a política de versionamento do bundle em
[`../../README.md`](../../README.md).
