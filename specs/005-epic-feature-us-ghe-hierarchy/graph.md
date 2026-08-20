# graph.md — Feature 005: Epic/Feature/US Hierarchy no GHE com Spec Kit

> Gerado a partir de `graph.yaml` — manter os dois em sincronia após cada mudança de módulo.

---

## Diagrama por Código (fluxo de execução)

```mermaid
flowchart TD
    Dev["👤 Dev"]

    subgraph speckit["Spec Kit (.specify/)"]
        SpecifyCmd["/speckit-specify\n(SKILL.md — cria feature.json direto)"]
        ConsistencyCheck["check-epic-issue-consistency.sh\ngate final incondicional\n(autocorrige epic_issue)"]
        TasksToIssuesCmd["/speckit-taskstoissues\n(SKILL.md)"]
        HierarchyScript["create-github-issue-hierarchy.sh\nensure-feature / ensure-user-story\nlink-task / set-type"]
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
    SpecifyCmd -->|"persiste epic_issue\n(extração inline via prosa)"| FeatureJSON
    SpecifyCmd -->|"2. gate obrigatório,\nsempre executado"| ConsistencyCheck
    ConsistencyCheck -->|"lê descrição bruta,\ncompara e autocorrige"| FeatureJSON

    Dev -->|"3. /speckit-taskstoissues"| TasksToIssuesCmd
    TasksToIssuesCmd -->|"lê epic_issue"| FeatureJSON
    TasksToIssuesCmd -->|"invoca (ensure-feature,\nensure-user-story, link-task)"| HierarchyScript
    HierarchyScript -->|"cria Feature/US issues,\naddSubIssue, updateIssueIssueType\n(dedup por marcador oculto)\n(fallback: labels)"| GHEAPI

    Dev -->|"4. setup scripts (bootstrap)"| SetupProject
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
  durante a implementação
- `create-github-issue-hierarchy.sh` foi adicionado nesta sessão (2026-08-20)
  como o script de deduplicação/vinculação mencionado nesta nota — ver nó
  `create-github-issue-hierarchy` em `graph.yaml`
- **Confiabilidade da extração de `epic_issue`** (mesma sessão, follow-up): o
  `/speckit-specify` não invoca `create-new-feature.sh` no caminho principal
  (ele mesmo cria `feature.json` via prosa do SKILL.md) — então a extração de
  `EPIC_ISSUE=<N>` dependia de o agente LLM seguir uma instrução no meio de um
  fluxo longo, sem verificação. Corrigido com defesa em profundidade: (1)
  `create-new-feature.sh` também extrai o token para quem chama via CLI/hook;
  (2) novo `check-epic-issue-consistency.sh` faz a checagem determinística e
  se autocorrige; (3) o SKILL.md ganhou um gate "Mandatory Post-Execution
  Validation" **incondicional** que sempre roda esse script como último passo,
  em vez de confiar apenas na prosa do meio do fluxo.
- O campo `epic_issue` em `feature.json` é **opcional** — sem ele, o fluxo
  funciona normalmente sem criar vinculação hierárquica
- O fallback via labels é ativado automaticamente quando a consulta de Issue
  Types da org retorna lista vazia ou erro 404
