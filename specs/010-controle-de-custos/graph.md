# Architecture Graphs: Controle de Custos (Feature 010)

---

## Technical Architecture

```mermaid
graph LR
    COLLECTOR["💾 cost-collector<br/>(Coleta Tokens + Horas)"]
    STORE["🗄️ cost-store<br/>(Persistência)"]
    AGGREGATOR["⚙️ cost-aggregator<br/>(Batch + Benchmarks)"]
    ALERT["🔔 budget-alert-engine<br/>(Motor de Alertas)"]
    DASHBOARD["📊 cost-dashboard<br/>(UI + API)"]
    TEMPLATE["📝 plan-template<br/>(Atualização)"]

    GH_API["GitHub Project API v2<br/>(Horas Humanas)"]
    SESSION["assistant_usage_events<br/>(Tokens)"]
    OF["OpenFeature SDK<br/>(Feature Toggle)"]
    GHE["GitHub Enterprise<br/>(Notificações)"]
    COST_REF["SPEC KIT COST<br/>(Referência Externa)"]

    GH_API -->|GraphQL| COLLECTOR
    SESSION -->|leitura| COLLECTOR
    COLLECTOR -->|CostRecord| STORE
    TEMPLATE -->|estimativas| COLLECTOR

    STORE -->|leitura| AGGREGATOR
    AGGREGATOR -->|CostBenchmark, CostSummary| STORE

    STORE -->|Budget, CostRecord| ALERT
    ALERT -->|CostAlert| STORE
    ALERT -->|notificação| GHE

    STORE -->|leitura| DASHBOARD
    AGGREGATOR -->|CostSummary, CostBenchmark| DASHBOARD

    COLLECTOR -->|flag| OF
    DASHBOARD -->|flag| OF

    COST_REF -.->|referência documental| DASHBOARD

    style COLLECTOR fill:#fff3e0
    style STORE fill:#e3f2fd
    style AGGREGATOR fill:#fff3e0
    style ALERT fill:#fce4ec
    style DASHBOARD fill:#e8f5e9
    style TEMPLATE fill:#f5f5f5
    style GH_API fill:#f3e5f5
    style SESSION fill:#f3e5f5
    style GHE fill:#f3e5f5
    style OF fill:#fce4ec
    style COST_REF fill:#f5f5f5
```

**Legend**:
- 🟧 **Orange**: Serviços de processamento (collector, aggregator)
- 🔵 **Blue**: Armazenamento (store)
- 🟥 **Pink/Red**: Motor de alertas, toggles
- 🟩 **Green**: Apresentação (dashboard)
- 🟪 **Purple**: Dependências externas (GitHub API, GHE)

---

## Data Flow: Coleta → Agregação → Dashboard → Alerta

```mermaid
sequenceDiagram
    participant Agent as Agente de IA
    participant Dev as Desenvolvedor Humano
    participant Collector as cost-collector
    participant Store as cost-store
    participant Aggregator as cost-aggregator
    participant AlertEngine as budget-alert-engine
    participant Dashboard as cost-dashboard
    participant Manager as Gestor

    Agent->>Collector: 1. Sessão concluída (tokens consumidos)
    Dev->>Collector: 2. Horas lançadas no GitHub Project
    Collector->>Store: Insere CostRecord (tokens + horas)

    Store->>AlertEngine: 3. Trigger: novo CostRecord inserido
    AlertEngine->>Store: Lê Budget do projeto
    AlertEngine->>Store: Calcula total acumulado
    alt Consumo >= 80% do orçamento
        AlertEngine->>Store: Registra CostAlert
        AlertEngine-->>Manager: Notificação de alerta
    end

    Aggregator->>Store: 4. Job batch (periódico): lê CostRecords
    Aggregator->>Store: Escreve CostBenchmark por complexidade

    Manager->>Dashboard: 5. Acessa dashboard
    Dashboard->>Store: GET /costs?scope=sprint&id=...
    Dashboard->>Aggregator: GET /costs/benchmarks?complexity=S2
    Dashboard-->>Manager: Exibe custo real vs. estimado + benchmarks
```

---

## Fluxo de Negócio: Do Plan.md ao Dashboard

```mermaid
graph TD
    PLAN["plan.md<br/>(Estimativas preenchidas)"]
    FEATURE_START["Feature iniciada<br/>(branch + sprint)"]
    AGENT_WORK["Trabalho do Agente<br/>(sessões de IA)"]
    HUMAN_WORK["Trabalho Humano<br/>(GitHub Project: Horas)"]
    COLLECTOR["cost-collector<br/>(coleta automática)"]
    STORE["cost-store<br/>(registro persistido)"]
    AGGREGATOR["cost-aggregator<br/>(consolidação batch)"]
    ALERT["Alerta de Orçamento<br/>(preventivo)"]
    DASHBOARD["Dashboard de Custos<br/>(visibilidade)"]
    REVIEW["Revisão de Estimativas<br/>(aprendizado contínuo)"]

    PLAN -->|estimativas registradas| FEATURE_START
    FEATURE_START --> AGENT_WORK
    FEATURE_START --> HUMAN_WORK
    AGENT_WORK -->|tokens por sessão| COLLECTOR
    HUMAN_WORK -->|horas por issue| COLLECTOR
    COLLECTOR --> STORE
    STORE --> AGGREGATOR
    STORE --> ALERT
    AGGREGATOR --> DASHBOARD
    ALERT -->|preventivo| DASHBOARD
    DASHBOARD -->|custo real vs. estimado| REVIEW
    REVIEW -->|calibra estimativas futuras| PLAN

    style PLAN fill:#e8f5e9
    style DASHBOARD fill:#e8f5e9
    style ALERT fill:#fce4ec
    style COLLECTOR fill:#fff3e0
    style STORE fill:#e3f2fd
    style AGGREGATOR fill:#fff3e0
    style REVIEW fill:#e8f5e9
```

---

## Modelo de Entidades

```mermaid
erDiagram
    CostRecord {
        uuid id
        string feature_id
        string dimension
        float amount
        string currency
        string period
        string source
        string model
        string session_id
        string correction_ref
        timestamp created_at
    }

    CostEstimate {
        uuid id
        string feature_id
        string dimension
        float estimated_amount
        string complexity_level
        timestamp recorded_at
    }

    Budget {
        uuid id
        string scope_type
        string scope_id
        float limit_amount
        string currency
        string period
        float alert_threshold_pct
        string owner
    }

    CostAlert {
        uuid id
        string budget_id
        timestamp triggered_at
        float consumption_at_trigger
        float threshold_pct
        string notified_to
    }

    CostBenchmark {
        uuid id
        string complexity_level
        float avg_tokens
        float avg_human_hours
        int sample_size
        string period
        timestamp updated_at
    }

    CostRecord ||--o| CostEstimate : "references"
    Budget ||--o{ CostAlert : "generates"
    CostRecord }o--|| Budget : "counted in"
    CostRecord }o--|| CostBenchmark : "aggregated into"
```

---

## Gate & Validation Checkpoints

```mermaid
graph TD
    COLLECT["CostRecord<br/>Coletado"]
    V1["Validação:<br/>feature_id válido?<br/>dimension conhecida?<br/>amount > 0?"]
    DLQ["Dead-Letter Queue<br/>(retry 3x)"]
    STORE_OK["cost-store<br/>(persiste)"]

    COLLECT --> V1
    V1 -->|✗ inválido| DLQ
    V1 -->|✓ válido| STORE_OK

    STORE_OK --> ALERT_CHECK["budget-alert-engine<br/>(threshold check)"]
    ALERT_CHECK -->|< 80%| NOOP["Nenhuma ação"]
    ALERT_CHECK -->|>= 80%| ALERT_FIRE["Dispara CostAlert<br/>+ Notificação"]
    ALERT_CHECK -->|>= 100%| ESTOURO["Alerta de Estouro<br/>(severidade alta)"]

    STORE_OK --> BATCH["cost-aggregator<br/>(batch periódico)"]
    BATCH --> BENCH["CostBenchmark<br/>atualizado"]
    BENCH --> DASH["Dashboard<br/>atualizado"]
```

---

## Dependency Module Layers

```mermaid
graph LR
    INFRA["Infrastructure Layer<br/>(PostgreSQL, Vault, CI/CD)"]
    DATA["Data Layer<br/>(cost-store)"]
    SERVICES["Service Layer<br/>(collector, aggregator, alert-engine)"]
    PRESENTATION["Presentation Layer<br/>(cost-dashboard API + UI)"]
    GOVERNANCE["Governance Layer<br/>(plan-template, OpenFeature)"]

    INFRA -->|sustenta| DATA
    DATA -->|alimenta| SERVICES
    SERVICES -->|expõe| PRESENTATION
    GOVERNANCE -->|controla ativação + estimativas| SERVICES
    GOVERNANCE -->|configura rollout| PRESENTATION

    style INFRA fill:#f5f5f5
    style DATA fill:#e3f2fd
    style SERVICES fill:#fff3e0
    style PRESENTATION fill:#e8f5e9
    style GOVERNANCE fill:#fce4ec
```
