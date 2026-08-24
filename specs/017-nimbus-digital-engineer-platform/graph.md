# Module Graph — 017-nimbus-digital-engineer-platform

## Grafo por Código

```mermaid
graph LR
  NA[nimbus-agent] --> II[intake-ingestion]
  II --> MCE[mode-classification-engine]
  MCE --> AGS[approval-gate-service]
  AGS --> HA[handoff-assembler]
  HA --> ATS[audit-trail-store]
  HA --> GE[governance-evidence]
  AGS --> GE
  BCS[badge-catalog-service] --> ATS
  M365[m365] --> II
  GH[github] --> II
  OF[openfeature-provider] --> MCE
```

## Grafo por Business

```mermaid
graph TD
  A[Intake corporativo] --> B[Classificação de modo]
  B --> C[Gate de aprovação]
  C --> D[Execução e handoff]
  D --> E[Evidência de custo e qualidade]
  E --> F[Governança e trilha auditável]
  F --> G[Badges por domínio]
```

## Notas
- `nimbus-agent` é o orquestrador principal multi-repo.
- OpenFeature é obrigatório como abstração para toggle de modos.
- Fluxos críticos persistem decisões em `audit-trail-store`.
