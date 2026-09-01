# Module Graph — 021-dora-metrics-governance

## Grafo por Código

```mermaid
graph LR
  MD[dora-metric-definitions]
  AC[dora-auto-collector]
  MA[dora-manual-adjustment-audit]
  RC[dora-review-cadence]
  DA[dora-degradation-to-action]

  AC --> MD
  MA --> AC
  RC --> AC
  RC --> MA
  DA --> RC
```

## Grafo por Business

```mermaid
graph TD
  A[Evento de entrega ocorre] --> B{Elegível para coleta automática?}
  B -->|Sim| C[Registro automático com origem rastreável]
  B -->|Não / lacuna detectada| D[Ajuste manual com justificativa + autor + evidência]
  C --> E[Revisão semanal - squad]
  D --> E
  E --> F[Revisão mensal - portfólio/PMO]
  F --> G{Leitura combinada dos 4 indicadores}
  G -->|Degradação relevante| H[Ação de backlog com owner e prazo]
  G -->|Sem degradação| I[Ciclo segue sem ação corretiva]
```

## Notas

- `dora-metric-definitions` é a fonte única de verdade consultada por todo o restante do grafo — evita leitura divergente entre squads.
- `dora-auto-collector` estende `scripts/process-metrics-report.sh` (feature 012); não é um script novo e paralelo.
- `dora-manual-adjustment-audit` é o módulo novo desta feature: garante que exceções manuais nunca fiquem sem trilha de auditoria.
- `dora-review-cadence` é o que transforma dado coletado em rotina operacional (semanal/mensal).
- `dora-degradation-to-action` fecha o loop de melhoria contínua, reaproveitando o backlog já existente (labels de prioridade do bundle).
