# graph.md — Feature 005: Epic/Feature/US Hierarchy no GHE com Spec Kit

> Gerado a partir de `graph.yaml` — manter os dois em sincronia após cada mudança de módulo.

---

## Diagrama por Código (fluxo de execução)

```mermaid
flowchart TD
    Dev["👤 Dev"]

    subgraph speckit["Spec Kit (.specify/)"]
        SpecifyCmd["/speckit-specify\n(create-new-feature.sh)"]
        TasksToIssuesCmd["/speckit-taskstoissues\n(workflow.yml)"]
        FeatureJSON[".specify/feature.json\n+ epic_issue"]
    end

    subgraph scripts["scripts/"]
        SetupProject["setup-github-project.sh\n+ Issue Types\n+ Views hierárquicas"]
        SetupLabels["setup-github-labels.sh\n+ type:epic\n+ type:feature\n+ type:user-story"]
    end

    subgraph docs["docs/"]
        DevGuide["developer-guide.md\n+ seção Hierarquia Agile"]
        ReuseCAT["reuse-catalog.yaml\n+ ghe-sub-issues-hierarchy\n+ speckit-dedup-by-id"]
    end

    GHEAPI["☁️ GHE GraphQL/REST API\n(sub-issues, Issue Types, Projects V2)"]

    Dev -->|"1. /speckit-specify EPIC_ISSUE=N"| SpecifyCmd
    SpecifyCmd -->|"persiste epic_issue"| FeatureJSON

    Dev -->|"2. /speckit-taskstoissues"| TasksToIssuesCmd
    TasksToIssuesCmd -->|"lê epic_issue"| FeatureJSON
    TasksToIssuesCmd -->|"cria Feature issue\ncomo sub-issue do Epic\n(dedup por T00N ID)\n(fallback: labels)"| GHEAPI

    Dev -->|"3. setup scripts (bootstrap)"| SetupProject
    SetupProject -->|"cria Issue Types + views\nhierárquicas no Project V2"| GHEAPI

    SetupLabels -->|"cria labels fallback"| GHEAPI

    DevGuide -.->|"documenta"| SpecifyCmd
    DevGuide -.->|"documenta"| TasksToIssuesCmd
    DevGuide -.->|"documenta"| SetupProject
```

---

## Diagrama por Business (hierarquia de artefatos)

```mermaid
flowchart TD
    subgraph ghe["GitHub Enterprise (GHE)"]
        Epic["🏛️ Issue: Epic\n(type:Epic)\n#N"]
        Feature["📦 Issue: Feature\n(type:Feature)\nsub-issue do Epic"]
        US1["📋 Issue: User Story 1\n(type:User Story)\nsub-issue da Feature"]
        US2["📋 Issue: User Story 2\n(type:User Story)\nsub-issue da Feature"]
        T001["🔧 Issue: T001\n(type:Task)\nsub-issue da US1"]
        T002["🔧 Issue: T002\n(type:Task)\nsub-issue da US1"]
        T003["🔧 Issue: T003\n(type:Task)\nsub-issue da US2"]
    end

    subgraph speckit_files["Spec Kit (artefatos locais)"]
        SpecMD["spec.md\n→ 1 Feature issue"]
        TasksMD["tasks.md\n→ [US1], [US2]…\n→ T001, T002…"]
        FeatureJSONFile[".specify/feature.json\n{ epic_issue: N }"]
    end

    FeatureJSONFile -->|"epic_issue = #N"| Epic
    SpecMD -->|"1:1 com"| Feature
    TasksMD -->|"[US1] →"| US1
    TasksMD -->|"[US2] →"| US2
    TasksMD -->|"T001, T002 →"| T001
    TasksMD -->|"T002 →"| T002
    TasksMD -->|"T003 →"| T003

    Epic -->|"sub-issue ↓"| Feature
    Feature -->|"sub-issue ↓"| US1
    Feature -->|"sub-issue ↓"| US2
    US1 -->|"sub-issue ↓"| T001
    US1 -->|"sub-issue ↓"| T002
    US2 -->|"sub-issue ↓"| T003
```

---

## Notas de Manutenção

- Atualizar `graph.yaml` e este arquivo se novos módulos forem adicionados
  durante a implementação (ex.: novo script de deduplicação separado)
- O campo `epic_issue` em `feature.json` é **opcional** — sem ele, o fluxo
  funciona normalmente sem criar vinculação hierárquica
- O fallback via labels é ativado automaticamente quando a consulta de Issue
  Types da org retorna lista vazia ou erro 404
