# Module Graph — Platform Preset CMDB + Baselines + DSC

## Code Dependency Graph

```mermaid
flowchart LR
  idp[corporate-idp]
  az[azure-control-plane]
  aws[aws-control-plane]
  gcp[gcp-control-plane]
  m365[m365-admin-apis]
  tf[terraform-pipelines]

  iag[identity-access-gateway]
  disco[multi-cloud-discovery-orchestrator]
  cmdb[cmdb-core]
  base[baseline-engine]
  dsc[dsc-composer]
  gov[governance-validation-api]

  iag --> idp
  disco --> iag
  disco --> az
  disco --> aws
  disco --> gcp
  disco --> cmdb
  base --> m365
  base --> cmdb
  dsc --> cmdb
  dsc --> base
  gov --> cmdb
  gov --> tf
```

## Business Flow Graph

```mermaid
flowchart TD
  A[Operador autenticado por SSO] --> B[Execucao multi-cloud]
  B --> C[CMDB consolidado orientado a IA]
  C --> D[Comparacao baseline e politicas]
  D --> E[Achados e customizacoes]
  E --> F[Perfil DSC versionado]
  C --> G[Validacao Terraform advisory]
  G --> H[Relatorio + trilha de excecao]
```

## Critical Path

```mermaid
sequenceDiagram
  participant U as Operador
  participant SSO as Corporate SSO
  participant ORQ as Discovery Orchestrator
  participant CMDB as CMDB Core
  participant POL as Baseline Engine
  participant DSC as DSC Composer

  U->>SSO: autentica
  SSO-->>ORQ: contexto autorizado
  ORQ->>CMDB: escreve inventario consolidado
  POL->>CMDB: compara baseline e registra achados
  DSC->>CMDB: publica nova versao DSC
```

## Implementation Trace

- scaffold self-contained under `platform-governance/`
- runtime factories back shared models, services, routes and CLI
