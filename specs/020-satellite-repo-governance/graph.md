# Module Graph — 020-satellite-repo-governance

## Grafo por Código

```mermaid
graph LR
  VB[validate-bootstrap workflow] --> VD[preset-version-detector]
  AU[satellite-preset-audit workflow] --> SC[scan-org-rename-references]
  AU --> CSV[preset-audit-report helper]
  SY[auto-sync manual opt-in] --> SH[sync-satellite-preset helper]
  SH --> RF[bootstrap managed refresh]
  SH --> VD
  SH --> PR[PR para revisão humana]
  TT[testes locais com mocks] --> VB
  TT --> SC
  TT --> CSV
  TT --> SH
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
  AUD[Auditoria somente leitura] --> REP[CSV e erros explícitos]
  REP --> HUM[Aprovação humana piloto 433/445]
  HUM --> FLAG{Opt-in explícito?}
  FLAG -->|Não| STOP[Sync desligado]
  FLAG -->|Sim| DIS[Dispatch repo e versão validados]
  DIS --> REF[Refresh sem provisionamento]
  REF --> VER{Versão verificada?}
  VER -->|Não| ERR[Erro bloqueia escrita remota]
  VER -->|Sim| REV[PR revisado sem merge automático]
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

- `preset-version-detector` infere `nimbus-code-standards` ou
  `nimbus-code-platform-standards` da registry nomeada; ambiguidade exige `--preset`.
  O wrapper instalado e `validate-bootstrap` usam a mesma interface `--repo-root`.
- `bootstrap-context-classifier` evita que repositórios quase vazios sejam tratados como brownfield real.
- `topology-decision-intake` transforma mono vs multirepo em decisão rastreável e persistida em `.specify/feature.json`.
- `domain-topology-guide` acelera a primeira decomposição sem engessar produtos diferentes.
- `central-spec-governance` reforça o repo central como fonte única de verdade para specs.
- `satellite-sync-policy` reaproveita o mecanismo oficial de alinhamento do bundle entre central e satélites.
