# graph.md — Feature 010: Harness Engineering — Aprendizado Organizacional com Erros

> Gerado a partir de `graph.yaml` — manter os dois em sincronia após cada mudança de módulo.

---

## Diagrama por Código (fluxo de execução)

```mermaid
flowchart TD
    Dev["👤 Dev / Agente"]

    subgraph harness["docs/harness/"]
        HCatalog["harness-catalog.yaml\n(catálogo de erros)"]
        HGuide["harness-guide.md"]
        HReadme["README.md"]
        HIncident["incident-template.md"]
    end

    subgraph scripts["scripts/"]
        HSearch["harness-search.sh\n(busca por tag/context)"]
        SetupLabels["setup-github-labels.sh\n+ harness:pending\n+ harness:cataloged\n+ harness:blocking"]
    end

    subgraph templates["presets/nimbus-code-standards/templates/"]
        PlanTemplate["plan-template.md\n+ seção 'Harness Gate'"]
        TasksTemplate["tasks-template.md\n+ passo de catalogação"]
    end

    CopilotInstr[".github/copilot-instructions.md\n+ instrução de consulta ao harness"]
    ReuseCatalog["docs/reuse-catalog.yaml\n(catálogo de soluções — complementar)"]
    GHEAPI["☁️ GHE REST API\n(labels)"]

    Dev -->|"1. antes do /nimbus-code-plan"| CopilotInstr
    CopilotInstr -->|"instrui consultar"| HCatalog

    Dev -->|"busca rápida"| HSearch
    HSearch -->|"filtra por tag/context"| HCatalog

    Dev -->|"redige plan.md"| PlanTemplate
    PlanTemplate -->|"seção Harness Gate\nreferencia"| HCatalog

    Dev -->|"fecha feature com retrabalho/incidente"| TasksTemplate
    TasksTemplate -->|"checklist instrui preencher"| HCatalog

    Dev -->|"post-mortem S3/S4"| HIncident
    HIncident -->|"gera entrada para"| HCatalog

    HReadme -->|"documenta"| HCatalog
    HReadme -->|"linka"| HGuide
    HReadme -->|"linka"| HIncident
    HGuide -->|"explica como usar"| HCatalog

    HCatalog -. "complementar" .-> ReuseCatalog

    SetupLabels -->|"cria labels"| GHEAPI
```

---

## Diagrama por Business (fluxo de aprendizado organizacional)

```mermaid
flowchart TD
    subgraph ciclo["Ciclo de Aprendizado Organizacional"]
        P1["📋 PLANEJAR\nAgente/Dev inicia\nnova feature"]
        P2["🔍 CONSULTAR\nHarness Catalog\n(por tags + bounded_context)"]
        P3{"Match\nencontrado?"}
        P4["✅ MITIGAR\nDeclarar no plan.md\nseção 'Harness Gate'\nAplicar prevenção"]
        P5["📝 DECLARAR\n'Nenhum padrão\nencontrado'"]
        P6["🛠️ IMPLEMENTAR\nFeature entregue"]
        P7{"Retrabalho > 20%\nou incidente?"}
        P8["📊 CATALOGAR\nIssue harness:pending\nPreenchimento do catálogo\nharness:cataloged"]
        P9["🔄 FECHAR\nFeature encerrada\nnormalmente"]
    end

    subgraph artefatos["Artefatos Envolvidos"]
        A1["harness-catalog.yaml"]
        A2["plan.md\n(seção Harness Gate)"]
        A3["incident-template.md\n(post-mortem)"]
        A4["Labels GitHub\nharness:pending\nharness:cataloged"]
    end

    P1 --> P2
    P2 --> P3
    P3 -->|"Sim"| P4
    P3 -->|"Não"| P5
    P4 --> P6
    P5 --> P6
    P6 --> P7
    P7 -->|"Sim"| P8
    P7 -->|"Não"| P9
    P8 -->|"alimenta"| A1
    P8 -->|"usa"| A3
    P8 -->|"aplica"| A4
    P4 -->|"declara em"| A2
    P2 -->|"lê"| A1

    style P4 fill:#0e8a16,color:#fff
    style P8 fill:#d93f0b,color:#fff
    style A1 fill:#0052cc,color:#fff
```

---

## Módulos impactados por esta feature

| Módulo | Tipo de mudança | Descrição |
|---|---|---|
| `docs/harness/harness-catalog.yaml` | **Novo** | Catálogo central de lições aprendidas |
| `docs/harness/README.md` | **Novo** | Conceito, fluxo e navegação |
| `docs/harness/harness-guide.md` | **Novo** | Guia detalhado para devs e agentes |
| `docs/harness/incident-template.md` | **Novo** | Template de post-mortem |
| `scripts/harness-search.sh` | **Novo** | Script CLI de busca no catálogo |
| `presets/nimbus-code-standards/templates/plan-template.md` | **Estendido** | + seção "Harness Gate" |
| `.github/copilot-instructions.md` | **Estendido** | + instrução de consulta obrigatória |
| `scripts/setup-github-labels.sh` | **Estendido** | + labels `harness:*` |
| `presets/nimbus-code-standards/templates/tasks-template.md` | **Estendido** | + passo de catalogação no checklist de fechamento |
