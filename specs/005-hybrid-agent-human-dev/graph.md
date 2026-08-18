# Architecture Graphs: Hybrid Agent-Human Delivery Templates

---

## Technical Architecture

```mermaid
graph LR
    USER["👤 Dev<br/>(Feature Author)"]
    SPECIFY["/speckit-specify<br/>Skill"]
    SPEC["spec.md<br/>(Output)"]
    
    PLAN["/speckit-plan<br/>Skill"]
    PLAN_OUT["plan.md<br/>research.md<br/>data-model.md"]
    CONTRACTS["contracts/<br/>graph.yaml<br/>graph.md"]
    
    TASKS["/speckit-tasks<br/>Skill"]
    TASKS_OUT["tasks.md<br/>(Output)"]
    GHE["GitHub Enterprise<br/>(Issues)"]
    
    DEV["👤 Dev<br/>(Executor)"]
    IMPL["Implementation<br/>Phase"]
    
    CONST["📋 Constitution.md<br/>(Principles)"]
    CATALOG["📚 Reuse Catalog<br/>(Patterns)"]
    COST["💰 SPEC KIT COST<br/>(URL Reference)"]
    
    USER -->|1. describe feature| SPECIFY
    SPECIFY -->|uses| SPEC_TEMPLATE["spec-template.md<br/>(Template)"]
    SPECIFY -->|generates| SPEC
    
    SPEC -->|2. read spec| PLAN
    PLAN -->|uses| PLAN_TEMPLATE["plan-template.md<br/>(Template)"]
    PLAN -->|reads| CONST
    PLAN -->|queries| CATALOG
    PLAN -->|embeds URL| COST
    PLAN -->|generates| PLAN_OUT
    PLAN -->|generates| CONTRACTS
    
    PLAN_OUT -->|3. read plan| TASKS
    TASKS -->|uses| TASK_TEMPLATE["task-template.md<br/>(Template)"]
    TASKS -->|reads| DATA_MODEL["data-model.md<br/>(Entities)"]
    TASKS -->|generates| TASKS_OUT
    TASKS -->|publishes| GHE
    COST -->|linked in| GHE
    
    GHE -->|4. assign tasks| DEV
    DEV -->|reads| GHE
    DEV -->|executes| IMPL
    
    IMPL -->|5. submit PR| USER
    
    style USER fill:#e1f5ff
    style DEV fill:#e1f5ff
    style SPECIFY fill:#fff3e0
    style PLAN fill:#fff3e0
    style TASKS fill:#fff3e0
    style GHE fill:#f3e5f5
    style IMPL fill:#c8e6c9
    style CONST fill:#fce4ec
    style CATALOG fill:#fce4ec
    style COST fill:#fce4ec
```

**Legend**:
- 🟦 **Blue**: Human actors (Dev/Author/Executor)
- 🟧 **Orange**: AI Skills (agent-driven)
- 🟪 **Purple**: Platform (GitHub Enterprise)
- 🟩 **Green**: Execution phase
- 🟥 **Red**: Governance/Reference documents

---

## Data Flow: Spec → Plan → Tasks → Execution

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant Spec as /speckit-specify
    participant Plan as /speckit-plan
    participant Tasks as /speckit-tasks
    participant GHE as GitHub Enterprise
    participant Exec as Executor (Human)

    Dev->>Spec: 1. Describe feature (natural language)
    Spec->>Spec: Load spec-template.md
    Spec->>Spec: Generate spec.md (+ quality checks)
    Spec-->>Dev: ✓ spec.md ready

    Dev->>Plan: 2. Request plan (/speckit-plan)
    Plan->>Plan: Read spec.md + constitution.md
    Plan->>Plan: Phase 0: Research unknowns
    Plan->>Plan: Phase 1: Generate plan.md, data-model.md, contracts/
    Plan-->>Dev: ✓ plan.md ready

    Dev->>Tasks: 3. Generate tasks (/speckit-tasks)
    Tasks->>Tasks: Read plan.md + data-model.md
    Tasks->>Tasks: Map AC → Tasks
    Tasks->>Tasks: Generate tasks.md
    Tasks->>GHE: Publish issues with operational steps
    Tasks-->>Dev: ✓ tasks.md + issues ready

    GHE->>Exec: 4. Assign tasks to executor
    Exec->>GHE: Read issue (context + objective + steps)
    Exec->>Exec: Execute task
    Exec->>GHE: PR + validation
    Exec-->>Dev: ✓ Task complete

    Note over Dev,Exec: Entire cycle tracks costs via SPEC KIT COST reference
```

---

## Hybrid Collaboration Model Flow

```mermaid
graph TD
    AGENT["🤖 AI Agent"]
    HUMAN["👤 Human (Tech Lead/Dev)"]
    
    SPEC_GEN["Generate spec.md<br/>(templates + LLM)"]
    SPEC_REV["Review & approve<br/>spec.md"]
    
    PLAN_GEN["Generate plan.md<br/>(research + design)"]
    PLAN_REV["Architecture review<br/>gates validation"]
    
    TASK_GEN["Generate tasks.md<br/>(breakdown + contracts)"]
    TASK_REV["Task clarity review<br/>(can human execute?)"]
    
    EXEC["Execute task<br/>(human or agent)"]
    TEST["Test & validate"]
    
    AGENT -->|generates| SPEC_GEN
    SPEC_GEN -->|awaits approval| SPEC_REV
    HUMAN -->|approve/reject| SPEC_REV
    SPEC_REV -->|approved| PLAN_GEN
    
    AGENT -->|generates| PLAN_GEN
    PLAN_GEN -->|awaits review| PLAN_REV
    HUMAN -->|review gates| PLAN_REV
    PLAN_REV -->|approved| TASK_GEN
    
    AGENT -->|generates| TASK_GEN
    TASK_GEN -->|awaits clarity check| TASK_REV
    HUMAN -->|verify clarity| TASK_REV
    TASK_REV -->|approved| EXEC
    
    EXEC -->|can be| AGENT
    EXEC -->|or| HUMAN
    EXEC -->|validate| TEST
    
    TEST -->|success| DONE["✓ Task Complete<br/>(PR merged)"]
    TEST -->|failure| REWORK["⚠️ Rework<br/>(feedback loop)"]
    REWORK -->|update| TASK_GEN
    
    style AGENT fill:#fff3e0
    style HUMAN fill:#e1f5ff
    style SPEC_GEN fill:#fff3e0
    style PLAN_GEN fill:#fff3e0
    style TASK_GEN fill:#fff3e0
    style SPEC_REV fill:#e1f5ff
    style PLAN_REV fill:#e1f5ff
    style TASK_REV fill:#e1f5ff
    style EXEC fill:#c8e6c9
    style DONE fill:#a5d6a7
    style REWORK fill:#ffb74d
```

---

## Module Composition Layers

```mermaid
graph LR
    BASE["Base Templates<br/>(.specify/templates/)"]
    PRESET["Preset Layer<br/>(.specify/presets/*/templates/)"]
    OUTPUT["Generated Output<br/>(spec.md, plan.md)"]
    
    BASE -->|lowest priority| COMPOSITION["Template<br/>Composition<br/>(via preset.yml)"]
    PRESET -->|prepend/append/replace| COMPOSITION
    COMPOSITION -->|resolve order| OUTPUT
    
    HEADER["Nimbus-Code Header<br/>(mandatory)"]
    BODY["Feature Content<br/>(varies)"]
    
    PRESET -->|provides| HEADER
    BASE -->|provides| BODY
    HEADER -->|prepended| OUTPUT
    BODY -->|appended| OUTPUT
    
    style BASE fill:#f5f5f5
    style PRESET fill:#fff3e0
    style OUTPUT fill:#e8f5e9
    style COMPOSITION fill:#e1f5ff
    style HEADER fill:#fff3e0
    style BODY fill:#f5f5f5
```

---

## Gate & Validation Checkpoints

```mermaid
graph TD
    SPEC["spec.md<br/>Generated"]
    QC1["Quality Checklist<br/>(spec template)"]
    AC1["AC Validation<br/>(BDD format)"]
    
    SPEC -->|validate| QC1
    SPEC -->|check| AC1
    QC1 -->|✓ pass| PLAN_READY["Ready for<br>/speckit-plan"]
    QC1 -->|✗ fail| REWORK1["Rework spec"]
    
    REWORK1 -->|resubmit| SPEC
    AC1 -->|✗ fail| REWORK1
    
    PLAN["plan.md<br/>Generated"]
    QC2["Constitution Check"]
    GATES["Security & DevSecOps<br/>Quality Gate<br/>Complexity Classification"]
    
    PLAN_READY -->|next phase| PLAN
    PLAN -->|validate| QC2
    PLAN -->|evaluate| GATES
    
    QC2 -->|✓ pass| TASK_READY["Ready for<br/>/speckit-tasks"]
    GATES -->|✓ pass| TASK_READY
    
    QC2 -->|✗ fail| REWORK2["Rework plan"]
    GATES -->|❌ violation| REWORK2
    GATES -->|⚠️ deviation| ADL["Document in<br/>Architecture Decision Log"]
    
    REWORK2 -->|resubmit| PLAN
    ADL -->|justified| TASK_READY
    
    TASKS["tasks.md<br/>Generated"]
    GHE_PUBLISH["Publish to GHE<br/>(Issues)"]
    
    TASK_READY -->|next phase| TASKS
    TASKS -->|publish| GHE_PUBLISH
    GHE_PUBLISH -->|assign| EXECUTION["Execution Phase<br/>(human/agent)"]
    
    style SPEC fill:#e8f5e9
    style PLAN fill:#e8f5e9
    style TASKS fill:#e8f5e9
    style QC1 fill:#e1f5ff
    style QC2 fill:#e1f5ff
    style GATES fill:#ffccbc
    style ADL fill:#fff9c4
    style TASK_READY fill:#a5d6a7
    style PLAN_READY fill:#a5d6a7
    style EXECUTION fill:#c8e6c9
