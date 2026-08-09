# Modelo Visual do Bundle (diagramas Mermaid)

Este documento traduz em diagramas o que já está descrito em texto no
[README.md](../README.md) e nos manifestos `*.yml` de cada componente — para
consulta rápida por devs que preferem um modelo visual.

Se a renderização Mermaid mudar de comportamento (novo componente, nova
estratégia, novo step de workflow), **atualize este arquivo junto** com o PR
que muda o `.yml` correspondente — ele não é gerado automaticamente.

## 1. Composição do bundle

O `vpndev-project-bundle` não contém lógica própria: ele só **amarra três
componentes independentes**, cada um publicado e versionado separadamente
(ver [`bundle.yml`](../bundles/vpndev-project-bundle/bundle.yml)).

```mermaid
flowchart TB
    subgraph BUNDLE["📦 bundle: vpndev-project-bundle (v1.0.0)"]
        direction TB
        PRESET["🧩 preset: vpndev-standards (v1.0.0)\nrole: governança/DevSecOps"]
        EXT["🔌 extension: vpndev-backlog-sync (v1.0.0)\nrole: integração JIRA/Azure DevOps"]
        WF["🔁 workflow: vpndev-full-cycle (v1.0.0)\nrole: orquestra o ciclo SDD"]
    end

    BUNDLE -->|"specify bundle install\nvpndev-project-bundle"| PROJ["📁 Projeto consumidor\n(specs/, .specify/, .github/)"]

    PRESET -. "usado pelos steps plan/tasks" .-> WF
    EXT -. "hooks after_specify/after_tasks\nchamados pelos steps" .-> WF

    style BUNDLE fill:#eef,stroke:#446,stroke-width:2px
    style PROJ fill:#efe,stroke:#484
```

**Leitura**: instalar o bundle é equivalente a instalar preset + extensão +
workflow nas versões exatas pinadas no `bundle.yml` (nunca ranges — ver
[Versionamento](../README.md#versionamento)). O workflow **consome** o preset
(templates alterados) e a extensão (hooks) em tempo de execução, mas os três
são artefatos versionados de forma independente.

## 2. Como o preset altera os templates nativos do Spec Kit

O preset `vpndev-standards` nunca substitui os templates do Spec Kit por
inteiro — ele aplica duas estratégias diferentes, item por item (ver
[`preset.yml`](../presets/vpndev-standards/preset.yml)):

```mermaid
flowchart LR
    subgraph NATIVO["Spec Kit nativo"]
        CT["constitution-template.md"]
        PT["plan-template.md"]
        TT["tasks-template.md"]
    end

    subgraph PRESET["preset vpndev-standards"]
        CTP["constitution-template.md\n(wrap)"]
        PTP["plan-template.md\n(append)"]
        TTP["tasks-template.md\n(append)"]
    end

    CT -->|"strategy: wrap\n{CORE_TEMPLATE} preservado por baixo"| CTP
    CTP --> CTOUT["constitution.md final\nprincípios VPN Dev + projeto"]

    PT -->|"strategy: append\nseções nativas intactas"| PTP
    PTP --> PTOUT["plan.md final\n+ Security/DevSecOps Gate\n+ Architecture Decision Log"]

    TT -->|"strategy: append"| TTP
    TTP --> TTOUT["tasks.md final\n+ checklist de qualidade\ninfra/deploy por tarefa"]
```

**Leitura**: `wrap` envolve o conteúdo nativo (que continua existindo, só que
"por dentro"); `append` só acrescenta seções novas ao final. Em nenhum caso o
preset remove algo que o Spec Kit já oferece nativamente.

## 3. Fluxo do workflow `vpndev-full-cycle`

Ciclo SDD completo com dois gates humanos explícitos, um deles específico de
DevSecOps (ver [`workflow.yml`](../workflows/vpndev-full-cycle/workflow.yml)):

```mermaid
flowchart TD
    START(["Início: inputs.spec"]) --> SPECIFY["speckit.specify"]
    SPECIFY --> HOOK1{{"extensão vpndev-backlog-sync\nhook after_specify (opcional)"}}
    HOOK1 --> GATE1{"Gate: review-spec\napprove/reject"}
    GATE1 -- reject --> ABORT1(["abort"])
    GATE1 -- approve --> PLAN["speckit.plan\n(preset injeta Security/DevSecOps Gate\n+ Architecture Decision Log no plan.md)"]
    PLAN --> GATE2{"Gate: devsecops-gate\nroteiro de implantação\navaliado e aprovado?"}
    GATE2 -- reject --> ABORT2(["abort"])
    GATE2 -- approve --> TASKS["speckit.tasks\n(preset anexa checklist\nde qualidade infra/deploy)"]
    TASKS --> HOOK2{{"extensão vpndev-backlog-sync\nhook after_tasks (opcional)"}}
    HOOK2 --> GATE3{"Gate: review-tasks\napprove/reject"}
    GATE3 -- reject --> ABORT3(["abort"])
    GATE3 -- approve --> IMPLEMENT["speckit.implement"]
    IMPLEMENT --> END(["Fim"])

    style GATE1 fill:#ffd,stroke:#a90
    style GATE2 fill:#fdd,stroke:#a00,stroke-width:2px
    style GATE3 fill:#ffd,stroke:#a90
```

**Leitura**: os hooks da extensão (`after_specify`/`after_tasks`) são
**opcionais** — se o projeto não usa JIRA/Azure DevOps, o dev simplesmente
recusa o prompt e o ciclo segue normalmente usando só `specs/` como fonte da
verdade. O `devsecops-gate` (em vermelho) é o ponto que distingue este
workflow do ciclo padrão do Spec Kit.

## 4. Instalação e política de atualização

```mermaid
sequenceDiagram
    actor Dev as Dev (projeto novo)
    participant Boot as bootstrap.sh
    participant Cat as Catálogos (presets/extensions/workflows/bundles)
    participant CLI as specify CLI
    participant Repo as nimbus-code-spec-kit-template

    Dev->>Boot: curl bootstrap.sh | bash
    Boot->>CLI: specify init (se necessário)
    Boot->>Repo: instala preset + extensão + workflow\n(versão mais recente da main)
    Note over Dev,Repo: alternativa: specify bundle install<br/>vpndev-project-bundle (requer catálogos registrados)

    loop Semanalmente
        Repo->>Dev: issue automática (update-speckit-and-bundle.yml)\ncompara versão instalada vs. publicada
    end

    Dev->>Repo: PR revisado aplica a atualização\n(nunca automático)
```

**Leitura**: a issue semanal **nunca aplica** a atualização sozinha — toda
mudança de versão do bundle vira um PR revisado, seguindo a mesma política de
aprovação formal usada para mudar a versão do próprio Spec Kit CLI (ver
[Versão do Bundle em uso — Política de Atualização](../README.md#versão-do-bundle-em-uso--política-de-atualização)).

## 5. Ecossistema de MCP servers candidatos

O Spec Kit **nunca instala** servidores MCP — `requires.mcp` é só um aviso em
texto na hora da instalação (ver
[`docs/mcp-and-bundles.md`](mcp-and-bundles.md)). O diagrama abaixo situa a
declaração atual da extensão (`atlassian-rovo`/`azure-devops`) ao lado de outros
servidores MCP relevantes por plataforma, pesquisados como candidatos para
futuras extensões da VPN Dev — nenhum deles provisionado pelo bundle:

```mermaid
flowchart LR
    EXT["🔌 extension: vpndev-backlog-sync\nrequires.mcp (aviso informativo)"]

    subgraph HOJE["Declarado hoje"]
        JIRA["Atlassian Rovo (JIRA)"]
        ADO["azure-devops (Boards)"]
    end

    subgraph CANDIDATOS["Candidatos por plataforma (não declarados)"]
        direction TB
        GH["GitHub MCP Server\n(oficial: github/github-mcp-server)\nIssues/PRs/Actions"]
        M365["Microsoft 365 MCP\n(comunidade: softeria/ms-365-mcp-server)\nOutlook/Teams/Planner/SharePoint"]
        AZ["Azure MCP Server\n(oficial: microsoft/mcp)\n40+ serviços Azure"]
        GWS["Workspace MCP\n(comunidade: taylorwilsdon/google_workspace_mcp)\nGmail/Drive/Calendar/Chat"]
        GCP["MCP Toolbox + Cloud Run MCP\n(oficial: googleapis, GoogleCloudPlatform)\nBigQuery/AlloyDB/Cloud Run"]
    end

    EXT --> JIRA
    EXT --> ADO
    EXT -. "avaliação futura\n(PR revisado, política de bundle)" .-> CANDIDATOS

    style HOJE fill:#efe,stroke:#484
    style CANDIDATOS fill:#eef,stroke:#446,stroke-dasharray: 5 5
```

**Leitura**: mudar `requires.mcp` da extensão para incluir qualquer um destes é
uma **mudança de política organizacional** — segue o mesmo fluxo de PR revisado
descrito em [Versionamento](../README.md#versionamento), igual a qualquer
alteração em `presets/`, `extensions/` ou `workflows/`. A tabela completa com
links, status oficial/comunidade e escopo de cada servidor está em
[`docs/mcp-and-bundles.md`](mcp-and-bundles.md#servidores-mcp-relevantes-por-plataforma-referência-para-requiresmcp).
