# Module Dependency Graph — 028-suporte-cursor-kiro

Fonte estruturada: [graph.yaml](./graph.yaml)

## Diagrama por Código (módulos e dependências técnicas)

```mermaid
graph TD
    DISC["dynamic-agent-discovery<br/>(nc-agent-sync.py)"]
    EDISC["extra-speckit-discovery<br/>(sync-nc-agents-to-integrations.sh)"]
    CUR["cursor-target-renderer<br/>(nc-agent-sync.py)"]
    CURX["cursor-extra-skills-sync<br/>(sync script)"]
    KIRO["kiro-target-renderer<br/>(nc-agent-sync.py)"]
    KIROX["kiro-extra-skills-sync<br/>(sync script)"]
    PARITY["parity-tests-5-targets<br/>(nc-agents-parity.bats)"]
    FOUND["foundation-regression-test<br/>(nc-agent-foundation.bats)"]
    CI["ci-workflow-triggers"]
    DOC["developer-guide-update"]
    SPECIFY_CUR["specify integration install cursor-agent<br/>(externo, já existente)"]
    SPECIFY_KIRO["specify integration install kiro-cli<br/>(externo, já existente)"]

    DISC --> CUR
    DISC --> KIRO
    DISC --> FOUND
    EDISC --> CURX
    EDISC --> KIROX
    CUR --> PARITY
    KIRO --> PARITY
    PARITY --> CI
    SPECIFY_CUR -.independente.-> CUR
    SPECIFY_KIRO -.independente.-> KIRO

    style SPECIFY_CUR fill:#f9f9f9,stroke:#999,stroke-dasharray: 5 5
    style SPECIFY_KIRO fill:#f9f9f9,stroke:#999,stroke-dasharray: 5 5
    style DISC fill:#fee,stroke:#c66
    style EDISC fill:#fee,stroke:#c66
```

> `dynamic-agent-discovery` e `extra-speckit-discovery` são destacados (borda
> vermelha) porque são mudanças arquiteturais **transversais aos 5 alvos**,
> não apenas aos 2 novos — mitigação do HRN-0006, aprovada explicitamente
> pelo usuário durante o `/nc-arch`.

## Diagrama por Negócio (User Stories e valor entregue)

```mermaid
graph LR
    US1["US1 (P1)<br/>Cursor com paridade total"]
    US2["US2 (P1)<br/>Kiro com paridade total"]
    US3["US3 (P2)<br/>VS Code continua só @nimbus"]
    US4["US4 (P3)<br/>Documentação das 5 integrações"]

    US1 --> US3
    US2 --> US3
    US1 --> US4
    US2 --> US4

    style US3 fill:#eef,stroke:#66c
```

> US3 é uma história de **regressão** — não introduz comportamento novo, mas
> garante que a extensão para 2 alvos não quebre a garantia já conquistada na
> spec 025.

## Resumo de Dependências Externas

| Dependência | Tipo | Relação | Observação |
|---|---|---|---|
| `specify` CLI (`cursor-agent`, `kiro-cli`) | Ferramenta externa, já instalada no catálogo | Fornece os 12 comandos `/speckit-*` de forma independente do gerador NC-* | Não reimplementado; apenas invocado |
| `kiro-cli` (binário) | Ferramenta externa, requer instalação local | Necessário para o dev usar Kiro na prática | Sem versão mínima exigida pelo `specify` CLI (confirmado nesta auditoria) |
