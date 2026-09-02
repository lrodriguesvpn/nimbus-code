# GitHub App Auth Snippet — Bootstrap Automation

Este documento consolida o contrato de autenticação para as automações
cross-repo/org do bootstrap. O padrão é:

1. tentar `actions/create-github-app-token@v1` com `NIMBUS_APP_ID` +
   `NIMBUS_APP_PRIVATE_KEY`;
2. registrar `::notice::` quando a autenticação usar o GitHub App;
3. cair explicitamente para o secret legado do workflow quando o App ainda não
   estiver configurado;
4. falhar com erro claro apenas quando **nenhuma** credencial estiver disponível.

## Snippet reutilizável

```yaml
- name: Generate GitHub App installation token
  id: app-token
  if: ${{ secrets.NIMBUS_APP_ID != '' && secrets.NIMBUS_APP_PRIVATE_KEY != '' }}
  uses: actions/create-github-app-token@v1
  with:
    app-id: ${{ secrets.NIMBUS_APP_ID }}
    private-key: ${{ secrets.NIMBUS_APP_PRIVATE_KEY }}
    owner: ${{ github.repository_owner }}
    github-api-url: ${{ github.api_url }}
    # permission-* explícitas por workflow

- name: Resolve auth token (App or PAT fallback)
  id: resolve-token
  run: |
    if [ -n "${{ steps.app-token.outputs.token }}" ]; then
      echo "token=${{ steps.app-token.outputs.token }}" >> "$GITHUB_OUTPUT"
      echo "mode=github-app" >> "$GITHUB_OUTPUT"
      echo "::notice::Autenticado via GitHub App (instalação de curta duração)."
    elif [ -n "${{ secrets.VPNDEV_PROJECT_TOKEN }}" ]; then
      echo "token=${{ secrets.VPNDEV_PROJECT_TOKEN }}" >> "$GITHUB_OUTPUT"
      echo "mode=pat-fallback" >> "$GITHUB_OUTPUT"
      echo "::warning::GitHub App não configurado — usando PAT de fallback (rollout em andamento; ver docs/github-app-auth-snippet.md)."
    else
      echo "::error::Nenhuma credencial configurada. Defina NIMBUS_APP_ID/NIMBUS_APP_PRIVATE_KEY ou o secret legado de fallback deste workflow."
      exit 1
    fi
```

## Matriz por workflow

| Workflow | Token preferido | Fallback legado | Permissões mínimas do GitHub App |
|---|---|---|---|
| `ensure-github-project.yml` | GitHub App | `VPNDEV_PROJECT_TOKEN` | `metadata:read`, `repository-projects:write`, `organization-projects:write` |
| `add-to-repo-project.yml` | GitHub App | `VPNDEV_PROJECT_TOKEN` | `metadata:read`, `issues:read`, `pull-requests:read`, `repository-projects:write`, `organization-projects:write` |
| `sync-priority-field.yml` | GitHub App | `ADD_TO_PROJECT_PAT` | `metadata:read`, `issues:write`, `pull-requests:write`, `repository-projects:write`, `organization-projects:write` |
| `agent-auto-assign.yml` | GitHub App | `COPILOT_AGENT_ASSIGN_TOKEN` | `metadata:read`, `issues:write` |
| `satellite-preset-audit.yml` | GitHub App | `VPNDEV_STANDARDS_READ_TOKEN` | `metadata:read`, `contents:read` (leitura entre 34+ repos privados/internos da org, não apenas o repo atual) |

## Secrets esperados

- `NIMBUS_APP_ID` — ID do GitHub App organizacional **Nimbus Bootstrap Automation**
- `NIMBUS_APP_PRIVATE_KEY` — chave privada PEM do App
- secret legado de fallback específico de cada workflow (mantido durante o rollout)

## T005 e T006 — ações humanas obrigatórias

T005 e T006 permanecem fora do escopo do agente nesta implementação:

1. **T005 [Humano]** — criar/instalar o GitHub App organizacional
   `Nimbus Bootstrap Automation` na organização `venha-pra-nuvem`.
2. **T006 [Humano]** — configurar `NIMBUS_APP_ID` e
   `NIMBUS_APP_PRIVATE_KEY` como GitHub Secrets após o App existir.

Enquanto essas duas tasks não forem concluídas, os workflows migrados continuam
funcionando via fallback (`VPNDEV_PROJECT_TOKEN`, `ADD_TO_PROJECT_PAT` ou
`COPILOT_AGENT_ASSIGN_TOKEN`) e registram um `::warning::` explícito no log.

## Checklist manual para concluir T006 depois do rollout administrativo

```bash
gh secret set NIMBUS_APP_ID --repo venha-pra-nuvem/nimbus-code-spec-kit-template
gh secret set NIMBUS_APP_PRIVATE_KEY --repo venha-pra-nuvem/nimbus-code-spec-kit-template < caminho/para/chave.pem
```

> Observação: o segundo comando acima é apenas um lembrete operacional para o
> reviewer humano. Ele **não** foi executado nesta sessão porque T005/T006 são
> dependências administrativas bloqueadas.
