# Module Dependency Graph — 027-cliente-plataforma-cmdb-iac

Fonte estruturada: [graph.yaml](./graph.yaml)

## Diagrama por Código (módulos e dependências técnicas)

```mermaid
graph TD
    MIG["005_iac_link_model.sql<br/>(migration)"]
    LDS["link-decision-service.js<br/>(domain)"]
    CMDB["cmdb-consolidation-service.js<br/>(domain, estendido)"]
    CLI["main.js<br/>(cli, estendido)"]
    ADR["docs/adr/0011-repo-first-company.md<br/>(documentação)"]
    EXT["venha-pra-nuvem-client-platform<br/>(repo externo, fora do workspace)"]

    MIG --> LDS
    LDS --> CMDB
    CMDB --> CLI
    CMDB -.consumido por.-> EXT
    MIG -.consumido por.-> EXT

    style EXT fill:#f9f9f9,stroke:#999,stroke-dasharray: 5 5
    style ADR fill:#eef,stroke:#66c
```

> A caixa `EXT` (repositório externo) é representada com borda tracejada para
> deixar explícito que está **fora do escopo de escrita** desta sessão — é um
> consumidor do modelo de referência, não um módulo implementado aqui.

## Diagrama por Negócio (User Stories e valor entregue)

```mermaid
graph LR
    US1["US1 (P1)<br/>Vínculo com repo IaC dedicado"]
    US2["US2 (P1)<br/>Registro como inventário inline"]
    US3["US3 (P2)<br/>Critério objetivo consistente"]
    US4["US4 (P2)<br/>Réplica em 2º cliente"]
    US5["US5 (P3)<br/>ADR 'Repo First Company'"]

    US1 --> US3
    US2 --> US3
    US3 --> US4
    US1 --> US5
    US2 --> US5

    style US4 fill:#fee,stroke:#c66
```

> US4 é destacada (borda vermelha) porque sua execução completa depende do
> repositório externo `venha-pra-nuvem-client-platform` — nesta sessão, apenas
> o **processo documentado de instanciação** (parte da US4) pode ser preparado
> como artefato de referência; a execução real fica fora de alcance.

## Resumo de Dependências Externas

| Dependência | Tipo | Relação | Bloqueia o quê nesta sessão |
|---|---|---|---|
| `venha-pra-nuvem/venha-pra-nuvem-client-platform` | Repositório externo (fora do workspace) | Consumidor do modelo de referência (`cmdb-consolidation-service-ext`, `iac-link-model-migration`) | Aplicação real de US1, US2 e US4 em clientes de Managed Services; medição real de SC-001 a SC-005 |
