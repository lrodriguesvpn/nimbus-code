# Grafo do Bounded Context: spec-kit-workflow

```mermaid
graph LR
  A[venha-pra-nuvem/nimbus-agent] -->|intake envelope| B[central spec-kit template]
  B --> C[Issue + Project Item]
  B --> D[Mode Decision]
  D --> E{Human Gate}
  B --> F[Process Q&A]
```

The Teams interview path is roadmap-only and is not an edge in the MVP flow.

> Gerado automaticamente por `scripts/generate-context-graph.sh` — não editar manualmente.

```mermaid
graph LR
  venha-pra-nuvem-nimbus-code["venha-pra-nuvem/nimbus-code"]
```

## Repositórios não analisados

Os seguintes repositórios não puderam ser acessados (nem localmente, nem via `gh api`):

- `venha-pra-nuvem/nimbus-code`
