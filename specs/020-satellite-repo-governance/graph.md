# Module Graph — 020-satellite-repo-governance

## Grafo por Código

```mermaid
graph LR
  BCC[bootstrap-context-classifier] --> TDI[topology-decision-intake]
  TDI --> DTG[domain-topology-guide]
  TDI --> CSG[central-spec-governance]
  CSG --> SSP[satellite-sync-policy]
  OBD[onboarding-documentation] --> BCC
  OBD --> DTG
  OBD --> CSG
```

## Grafo por Business

```mermaid
graph TD
  A[Bootstrap iniciado] --> B{Existe código de aplicação relevante?}
  B -->|Não| C[Fluxo Greenfield]
  B -->|Sim| D[Fluxo Brownfield]
  C --> E{Monorepo ou MultiRepo?}
  E -->|Monorepo| F[Registrar motivo da decisão]
  E -->|MultiRepo| G[Registrar motivo da decisão]
  G --> H[Sugerir FRONT / BACK / DESIGN / DATA / JOBS]
  H --> I[Adaptar domínios com justificativa]
  I --> J[Repo central mantém specs]
  F --> J
  D --> J
  J --> K[Satélites recebem código e tasks]
  K --> L[Atualização do bundle via PR revisado]
```

## Notas

- `bootstrap-context-classifier` evita que repositórios quase vazios sejam tratados como brownfield real.
- `topology-decision-intake` transforma mono vs multirepo em decisão rastreável.
- `domain-topology-guide` acelera a primeira decomposição sem engessar produtos diferentes.
- `central-spec-governance` reforça o repo central como fonte única de verdade para specs.
- `satellite-sync-policy` reaproveita o mecanismo oficial de alinhamento do bundle entre central e satélites.
