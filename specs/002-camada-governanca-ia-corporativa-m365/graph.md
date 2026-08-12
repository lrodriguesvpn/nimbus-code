# Feature Graph: Camada de Governanca IA Corporativa M365

## Artifact view

```mermaid
flowchart TD
    PLAN[plan.md] --> SPEC[spec.md]
    PLAN --> RESEARCH[research.md]
    PLAN --> DATA[data-model.md]
    PLAN --> QUICK[quickstart.md]
    PLAN --> GRAPH[graph.yaml]
    PLAN --> IMPACT[impact-map.md]
    PLAN --> CHECK[checklists/requirements.md]

    SPEC --> CONST[Corporate AI Constitution]
    RESEARCH --> M365[M365 AI Governance Guide]
    QUICK --> LEGACY[Legacy AI Usage Guide]
    DATA --> ALIAS[Nimbus Command Alias Map]

    M365 --> CONST
    LEGACY --> CONST
    ALIAS --> PLAN
```

## Business view

```mermaid
flowchart LR
    COMPANY[Company AI Policy] --> CONST[One Corporate AI Constitution]
    CONST --> M365[M365 Copilot Governance]
    CONST --> LEGACY[Claude Enterprise / ChatGPT Guide]
    CONST --> ALIAS[Nimbus Alias Naming]
    M365 --> OFFICIAL1[Microsoft 365 Copilot]
    M365 --> OFFICIAL2[M365 Copilot CoWork]
    LEGACY --> LEGACYTOOLS[Legacy AI Tools]
    ALIAS --> SPECKIT[Original Spec Kit Commands]
```

## Notes

- This feature is documentation-only in v1.
- The graph is intentionally centered on artifact coherence instead of runtime services.
- The external AI platforms are represented only as governance references.
