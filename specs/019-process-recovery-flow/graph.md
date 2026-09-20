# Module Graph — 019-process-recovery-flow

## Grafo por Código

```mermaid
graph LR
  DG[developer-guide] --> PDG[process-decision-guide]
  PDG --> PCC[process-correction-contract]
  PDG --> LP[language-policy]
  LP --> DT[distributed-templates]
  IA[impact-assessment] --> DT
  QV[quickstart-validation] --> PDG
```

## Grafo por Business

```mermaid
graph TD
  A[Erro descoberto em feature existente] --> B{Onde está o problema?}
  B -->|Código| C[Corrigir implementação]
  B -->|Spec/Aceite| D[Atualizar mesma spec]
  B -->|Arquitetura| E[Atualizar mesmo plan]
  B -->|Novo escopo| F[Avaliar nova spec]
  C --> G[Converge]
  D --> H[Atualizar tasks]
  E --> H
  H --> I[Implement]
  I --> G
  F --> J[Nova spec + novo ciclo]
  J --> K[Architecture Board quando houver impacto normativo]
```

## Notas

- `developer-guide` é o ponto operacional central da decisão.
- `process-correction-contract` reduz ambiguidade entre times e agentes.
- `language-policy` torna a regra de idioma normativa, não opcional.
- `distributed-templates` representa os presets e cópias espelho que distribuem
  a regra sem criar uma segunda fonte normativa.
- `impact-assessment` registra impacto, rollback, owners e critérios de Go/No-Go.
- `quickstart-validation` garante que edge cases e cenários principais possam ser validados de forma repetível.
