# Contract: Idle Governance Workflow

**Arquivo**: `.github/workflows/codespaces-idle-governance.yml` (referência)

## Comportamento esperado

```yaml
name: Codespaces Idle Governance (reference)
on:
  schedule:
    - cron: "0 * * * *"
jobs:
  check-idle-codespaces:
    runs-on: ubuntu-latest
    steps:
      - name: List and stop idle codespaces beyond threshold
        run: |
          gh api /user/codespaces --paginate | \
            jq -r '.codespaces[] | select(.state == "Available") | .name' | \
          while read -r name; do
            # Verificar last_used_at contra idle_timeout_minutes e parar se excedido
            echo "Avaliando Codespace: $name"
          done
```

## Regra (AC-3)

Todo Codespace ocioso além de `idle_timeout_minutes` (ver
`CodespaceIdleGovernancePolicy` em `data-model.md`) é parado automaticamente,
sem intervenção manual, com registro do evento para auditoria de custo.

**Nota**: este workflow é uma referência/fallback — a primeira linha de
governança é a configuração nativa do GitHub Codespaces a nível de organização
(ver `research.md`, Unknown 3).
