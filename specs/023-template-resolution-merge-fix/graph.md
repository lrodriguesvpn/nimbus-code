# Grafo do Bounded Context: spec-kit-workflow

## Módulos da remediação (2026-09-20)

```mermaid
flowchart LR
  bootstrap --> managed["sync-bundle-artifacts.py"]
  managed --> consumers["create-new-feature / setup-plan / setup-tasks"]
  managed --> resolver["common.sh"]
  consumers --> resolver
  suite["run-tests.sh"] --> fixtures["Regressões isoladas de CLI e bootstrap"]
  fixtures --> consumers
  fixtures --> bootstrap
```

## Fluxo de negócio

```mermaid
flowchart LR
  install["Instalar ou atualizar bundle explicitamente"] --> check["Verificar customizações"]
  check -->|Sem conflito| deliver["Entregar scripts e preset"]
  check -->|Conflito| human["Interromper e solicitar reconciliação humana"]
  deliver --> compose["Gerar artefato com core e preset"]
  compose --> review["Revisar diff e PR; sem merge automático"]
```

<!-- generate-context-graph:start -->
## Grafo de Contexto Multi-Repo: spec-kit-workflow

> Gerado automaticamente por `scripts/generate-context-graph.sh` — não editar manualmente.

```mermaid
graph LR
  venha-pra-nuvem-nimbus-code-spec-kit-template["venha-pra-nuvem/nimbus-code-spec-kit-template"]
```

### Repositórios não analisados

Os seguintes repositórios não puderam ser acessados (nem localmente, nem via `gh api`):

- `venha-pra-nuvem/nimbus-code-spec-kit-template`

<!-- generate-context-graph:end -->
