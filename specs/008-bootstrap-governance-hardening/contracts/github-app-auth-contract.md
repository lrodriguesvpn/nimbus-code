# Contract: GitHub App Authentication

**Componentes afetados**: `.github/workflows/ensure-github-project.yml`,
`add-to-repo-project.yml`, `sync-priority-field.yml`, `agent-auto-assign.yml`

## Padrão de step de autenticação (todos os workflows migrados)

```yaml
- name: Generate GitHub App installation token
  id: app-token
  if: ${{ secrets.NIMBUS_APP_ID != '' && secrets.NIMBUS_APP_PRIVATE_KEY != '' }}
  uses: actions/create-github-app-token@v1
  with:
    app-id: ${{ secrets.NIMBUS_APP_ID }}
    private-key: ${{ secrets.NIMBUS_APP_PRIVATE_KEY }}
    # permissions explícitas por workflow — nunca herdar tudo do App

- name: Resolve auth token (App or PAT fallback)
  id: resolve-token
  run: |
    if [ -n "${{ steps.app-token.outputs.token }}" ]; then
      echo "token=${{ steps.app-token.outputs.token }}" >> "$GITHUB_OUTPUT"
      echo "::notice::Autenticado via GitHub App (instalação de curta duração)"
    else
      echo "token=${{ secrets.VPNDEV_PROJECT_TOKEN }}" >> "$GITHUB_OUTPUT"
      echo "::warning::GitHub App não configurado — usando PAT de fallback (rollout em andamento, ver ADL-2 do plan.md)"
    fi
```

Os passos seguintes do workflow usam `${{ steps.resolve-token.outputs.token }}`
em vez de referenciar `secrets.VPNDEV_PROJECT_TOKEN` diretamente.

## Regras

- **AC-4**: se `secrets.NIMBUS_APP_ID`/`NIMBUS_APP_PRIVATE_KEY` estiverem
  configurados, o token de instalação é sempre preferido sobre o PAT.
- **AC-5**: workflows de escopo restrito ao próprio repositório (ex.:
  `graph-guard.yml`, que só valida arquivos do próprio repo) **não** passam por
  este contrato — continuam usando `${{ github.token }}` nativo, sem nenhuma
  mudança.
- Nenhuma chave privada do App é logada ou exposta em nenhum passo.
- Permissões do token de instalação são restringidas ao mínimo necessário por
  workflow (ex.: `ensure-github-project.yml` só precisa de `organization_projects: write`,
  não de `contents: write`).
