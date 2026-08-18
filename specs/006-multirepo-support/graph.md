# graph.md — Feature 006: MultiRepo Support no Spec Kit Template

> Gerado a partir de `graph.yaml`. Atualizar ambos se a implementação divergir do plano.

---

## Diagrama por Código (módulos e dependências técnicas)

```mermaid
graph TD
    subgraph "Repo Central — docs/"
        BC["bounded-contexts.yaml<br/>(NOVO — registro de repos)"]
        DG["developer-guide.md<br/>(+ seção MultiRepo)"]
        RC["reuse-catalog.yaml<br/>(+ entrada multirepo-...)"]
    end

    subgraph "Preset Template"
        BCT[".specify/presets/.../project-root/<br/>bounded-contexts.yaml<br/>(template atualizado)"]
    end

    subgraph "Scripts — .specify/"
        CNF["create-new-feature.sh<br/>(+ --bounded-contexts flag)"]
        FJ[".specify/feature.json<br/>(+ bounded_contexts + repos)"]
    end

    subgraph "Scripts — scripts/"
        SGP["setup-github-project.sh<br/>(+ linkProjectV2ToRepository)"]
    end

    subgraph "Externos"
        GHE["GHE GraphQL API<br/>linkProjectV2ToRepository"]
        YQ["yq v4 / python3<br/>(YAML parser)"]
    end

    CNF -->|"lê slugs → resolve repos"| BC
    CNF -->|"persiste bounded_contexts + repos"| FJ
    CNF -->|"subprocess"| YQ

    SGP -->|"lê lista de repos"| BC
    SGP -->|"GraphQL/HTTPS"| GHE
    SGP -->|"subprocess"| YQ

    BCT -.->|"template instantiation"| BC

    DG -.->|"documenta"| BC
    DG -.->|"documenta"| CNF
    DG -.->|"documenta"| SGP

    style BC fill:#d4edda,stroke:#28a745
    style FJ fill:#fff3cd,stroke:#ffc107
    style GHE fill:#f8d7da,stroke:#dc3545
    style YQ fill:#d1ecf1,stroke:#17a2b8
```

---

## Diagrama por Business (fluxo do ponto de vista do usuário)

```mermaid
sequenceDiagram
    actor Dev
    participant "bounded-contexts.yaml" as BC
    participant "create-new-feature.sh" as CNF
    participant "feature.json" as FJ
    participant "setup-github-project.sh" as SGP
    participant "GHE Project V2" as GHE

    Note over Dev,GHE: Setup inicial (uma vez por projeto)

    Dev->>BC: 1. Cadastra repos de serviço<br/>(slug, repository, stack, team, autonomous_ok)
    Dev->>SGP: 2. ./setup-github-project.sh
    SGP->>BC: lê lista de repos
    SGP->>GHE: linkProjectV2ToRepository<br/>(para cada repo do bounded-contexts.yaml)
    GHE-->>SGP: ✓ repos vinculados ao board cross-repo
    SGP-->>Dev: ✓ Project V2 configurado com N repos vinculados

    Note over Dev,GHE: Por feature (ciclo de desenvolvimento)

    Dev->>CNF: 3. /speckit-specify --bounded-contexts "auth,orders"
    CNF->>BC: resolve "auth" → org/svc-auth<br/>resolve "orders" → org/svc-orders
    CNF->>FJ: persiste bounded_contexts + repos
    CNF-->>Dev: feature criada com contexto multi-repo

    Note over Dev,GHE: Criação de issues (/speckit-taskstoissues)

    Dev->>GHE: 4. /speckit-taskstoissues
    Note right of GHE: Epics/Features/USs → Repo Central<br/>Tasks [US1 — auth] → org/svc-auth<br/>Tasks [US2 — orders] → org/svc-orders
    GHE-->>Dev: ✓ Board cross-repo exibe tudo
```

---

## Legenda de riscos

| Cor | Significado |
|---|---|
| 🟢 Verde | Novo artefato — sem risco de regressão em código existente |
| 🟡 Amarelo | Artefato existente modificado — risco baixo (campo opcional) |
| 🔴 Vermelho | Dependência externa crítica — com fallback documentado |
| 🔵 Azul | Ferramenta utilitária — com fallback (python3/grep-awk) |
