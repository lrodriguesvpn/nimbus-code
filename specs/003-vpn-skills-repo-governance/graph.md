# VPN-SKILLS Module Dependency Graph

**Version**: 1.0  
**Created**: 2026-08-12

This document provides visual representations of the VPN-SKILLS architecture and module dependencies.

---

## 1. Code-Level Module Dependency Graph

### Diagram: Module Connections and Data Flow

```mermaid
graph TB
    CLI["vpn-skills-cli<br/>(Go/Cobra)<br/>Layer: client"]
    API["vpn-skills-api<br/>(Node.js/Express)<br/>Layer: api<br/>Port: 8080"]
    REPO["vpn-skills-repo-core<br/>(GitHub)<br/>Layer: data"]
    DB["vpn-skills-db<br/>(PostgreSQL)<br/>Layer: data<br/>Port: 5432"]
    CACHE["vpn-skills-cache<br/>(Redis)<br/>Layer: data<br/>Port: 6379"]
    COMP["vpn-skills-compliance-engine<br/>(Python/FastAPI)<br/>Layer: backend<br/>Port: 8081"]
    QUEUE["vpn-skills-queue<br/>(Kafka)<br/>Layer: messaging<br/>Port: 9092"]
    NOTIF["vpn-skills-notifier<br/>(Python/Celery)<br/>Layer: backend"]
    DASH["vpn-skills-discovery-dashboard<br/>(React)<br/>Layer: frontend<br/>Port: 3000"]
    
    EXT_GITHUB["GitHub API<br/>(External)"]
    EXT_SLACK["Slack API<br/>(External)"]
    EXT_MAIL["SendGrid<br/>(External)"]
    EXT_NPM["npm Registry<br/>(External)"]
    EXT_DOCKER["Docker Registry<br/>(External)"]
    
    %% CLI connections (orange: https)
    CLI -->|https/request-response| API
    CLI -->|https/git-token| REPO
    
    %% API connections (red: critical)
    API -->|tcp/tls<br/>PostgreSQL| DB
    API -->|tcp<br/>Redis| CACHE
    API -->|https/api-key| REPO
    
    %% Compliance Engine connections (red: critical)
    COMP -->|https| API
    COMP -->|tcp/tls<br/>PostgreSQL| DB
    COMP -->|tcp/tls<br/>Kafka| QUEUE
    
    %% Dashboard connections
    DASH -->|https/oauth2<br/>REST| API
    DASH -->|tcp<br/>Redis| CACHE
    
    %% Notifier connections
    NOTIF -->|tcp/tls<br/>Kafka| QUEUE
    NOTIF -->|https/webhook| EXT_SLACK
    NOTIF -->|https/api-key| EXT_MAIL
    
    %% External integrations
    API -->|https/token| EXT_GITHUB
    CLI -->|https| EXT_NPM
    API -->|registry| EXT_DOCKER
    
    style CLI fill:#e1f5ff
    style API fill:#ff1744
    style REPO fill:#ff9800
    style DB fill:#ff6f00
    style CACHE fill:#ff9800
    style COMP fill:#ff1744
    style QUEUE fill:#ff9800
    style NOTIF fill:#ff9800
    style DASH fill:#e1f5ff
    style EXT_GITHUB fill:#d0d0d0
    style EXT_SLACK fill:#d0d0d0
    style EXT_MAIL fill:#d0d0d0
    style EXT_NPM fill:#d0d0d0
    style EXT_DOCKER fill:#d0d0d0
```

**Legend**:
- 🔴 **Red**: Critical dependencies (high availability required)
- 🟠 **Orange**: Important but non-critical
- 🔵 **Blue**: Client/frontend components
- ⚫ **Gray**: External third-party services

---

## 2. Business Context Diagram

### High-Level Feature Flows

```mermaid
graph LR
    subgraph "Users"
        DEV["Developer"]
        OPS["Operator"]
        AUDIT["Auditor"]
    end
    
    subgraph "VPN-SKILLS Platform"
        INIT["1. Initialize<br/>skills.yaml"]
        DISCOVER["2. Discover<br/>Skills"]
        VALIDATE["3. Validate<br/>Manifest"]
        COMPLY["4. Check<br/>Compliance"]
        REPORT["5. Generate<br/>Report"]
    end
    
    subgraph "Integration Points"
        BOOTSTRAP["Bootstrap<br/>Templates"]
        CI_CD["CI/CD<br/>Pipelines"]
        SLACK["Slack<br/>Notifications"]
    end
    
    DEV -->|initialize| INIT
    INIT -->|get catalog| DISCOVER
    DISCOVER -->|add skills| VALIDATE
    
    OPS -->|trigger validation| VALIDATE
    VALIDATE -->|check status| COMPLY
    COMPLY -->|schedule scan| REPORT
    
    AUDIT -->|fetch report| REPORT
    
    INIT -.->|integrate| BOOTSTRAP
    VALIDATE -.->|integrate| CI_CD
    COMPLY -.->|notify| SLACK
    REPORT -.->|archive| SLACK
```

---

## 3. Deployment Topology

### Multi-Environment Architecture

```mermaid
graph TB
    subgraph "Development"
        DEVNS["Namespace: vpn-skills-dev"]
        DEVAPI["API Server<br/>(1 replica)"]
        DEVDB["PostgreSQL<br/>(1 replica)"]
        DEVAPI --> DEVDB
        DEVNS -.-> DEVAPI
    end
    
    subgraph "Staging"
        STGNS["Namespace: vpn-skills-staging"]
        STGAPI["API Server<br/>(2 replicas)"]
        STGDB["PostgreSQL<br/>(2 replicas)"]
        STGCOMP["Compliance<br/>(1 replica)"]
        STGAPI --> STGDB
        STGAPI --> STGCOMP
        STGNS -.-> STGAPI
    end
    
    subgraph "Production"
        PRODNS["Namespace: vpn-skills-prod"]
        PRODAPI["API Server<br/>(3+ replicas)"]
        PRODDB["PostgreSQL<br/>(3 replicas)<br/>Multi-AZ"]
        PRODCOMP["Compliance<br/>(3 replicas)"]
        PRODQUEUE["Kafka<br/>(3 brokers)"]
        PRODNOTIF["Notifier<br/>(3 replicas)"]
        PRODDASH["Dashboard<br/>(2+ replicas)"]
        PRODAPI --> PRODDB
        PRODAPI --> PRODCOMP
        PRODAPI --> PRODQUEUE
        PRODQUEUE --> PRODNOTIF
        PRODAPI --> PRODDASH
        PRODNS -.-> PRODAPI
    end
    
    CDK["Container Registry<br/>(ghcr.io/org/vpn-skills)"]
    REGIONS["us-east-1, us-west-2<br/>eu-west-1"]
    
    STGAPI -.->|pull images| CDK
    PRODAPI -.->|pull images| CDK
    PRODNS -.->|deployed across| REGIONS
    
    style DEVNS fill:#c8e6c9
    style STGNS fill:#fff9c4
    style PRODNS fill:#ffcdd2
```

---

## 4. Data Flow Diagram

### Skill Lifecycle and Compliance Tracking

```mermaid
graph LR
    subgraph "Sourcing"
        SOURCE["Skill Author<br/>(in VPN-SKILLS repo)"]
        DRAFT["Draft<br/>Status"]
        VERSION["Create<br/>Semver Release"]
        SOURCE -->|commit| DRAFT
        DRAFT -->|tag release| VERSION
    end
    
    subgraph "Indexing & Discovery"
        INDEX["GitHub Webhook<br/>triggers"]
        FETCH["Fetch Metadata<br/>from Manifest"]
        STORE["Store in DB"]
        CACHE_UPDATE["Invalidate Cache"]
        INDEX -->|new release| FETCH
        FETCH -->|write| STORE
        STORE -->|clear| CACHE_UPDATE
    end
    
    subgraph "Validation & Compliance"
        PROJECTS["Downstream<br/>Projects"]
        MANIFEST["skills.yaml<br/>Manifest"]
        VALIDATE["Validate via API<br/>or CLI"]
        RESOLVE["Resolve<br/>Dependencies"]
        REPORT_SCAN["Generate<br/>Compliance<br/>Report"]
        PROJECTS -->|declare| MANIFEST
        MANIFEST -->|submit| VALIDATE
        VALIDATE -->|check| RESOLVE
        RESOLVE -->|scan| REPORT_SCAN
    end
    
    subgraph "Notifications"
        QUEUE_EMIT["Emit to<br/>Kafka Queue"]
        NOTIF_WORKER["Notification<br/>Worker<br/>(Celery)"]
        CHANNELS["Slack | Email<br/>| GitHub Issues"]
        QUEUE_EMIT -->|async| NOTIF_WORKER
        NOTIF_WORKER -->|send to| CHANNELS
    end
    
    VERSION -->|webhook| INDEX
    REPORT_SCAN -->|findings| QUEUE_EMIT
    
    style SOURCE fill:#c3e9ff
    style DRAFT fill:#fff3e0
    style VERSION fill:#e1f5fe
    style INDEX fill:#e0f2f1
    style FETCH fill:#f1f8e9
    style STORE fill:#fce4ec
    style CACHE_UPDATE fill:#f3e5f5
    style PROJECTS fill:#e3f2fd
    style MANIFEST fill:#fff9c4
    style VALIDATE fill:#f0f4c3
    style RESOLVE fill:#ffe0b2
    style REPORT_SCAN fill:#ffccbc
    style QUEUE_EMIT fill:#e1f5fe
    style NOTIF_WORKER fill:#f1f8e9
    style CHANNELS fill:#fce4ec
```

---

## 5. Communication Protocols

### API & Integration Patterns

```mermaid
graph TB
    subgraph "REST API Endpoints"
        SKILLS_LIST["GET /skills<br/>POST /skills/search"]
        SKILL_DETAIL["GET /skills/:id<br/>GET /skills/:id/versions"]
        VALIDATE_EP["POST /validate<br/>POST /validate/batch"]
        COMPLIANCE_EP["GET /compliance/:projectId<br/>POST /compliance/scan"]
    end
    
    subgraph "CLI Commands"
        CLI_LIST["vpn-skills list"]
        CLI_SHOW["vpn-skills show"]
        CLI_SEARCH["vpn-skills search"]
        CLI_VALIDATE["vpn-skills validate"]
        CLI_COMPLIANCE["vpn-skills compliance"]
    end
    
    subgraph "GitHub Actions"
        GHA_SETUP["Setup VPN-SKILLS"]
        GHA_VALIDATE["Run Validation"]
        GHA_REPORT["Upload Report"]
    end
    
    subgraph "Async Events (Kafka)"
        EVENT_NEW["skill.version.created"]
        EVENT_DEPRECATE["skill.deprecated"]
        EVENT_COMPLIANCE["compliance.scan.completed"]
        EVENT_ALERT["compliance.alert.threshold"]
    end
    
    CLI_LIST -->|https| SKILLS_LIST
    CLI_SHOW -->|https| SKILL_DETAIL
    CLI_SEARCH -->|https| SKILLS_LIST
    CLI_VALIDATE -->|https| VALIDATE_EP
    CLI_COMPLIANCE -->|https| COMPLIANCE_EP
    
    GHA_SETUP -.->|download| CLI_LIST
    GHA_VALIDATE -.->|invoke| CLI_VALIDATE
    GHA_REPORT -.->|fetch| COMPLIANCE_EP
    
    VALIDATE_EP -.->|publish| EVENT_NEW
    SKILL_DETAIL -.->|publish| EVENT_DEPRECATE
    COMPLIANCE_EP -.->|publish| EVENT_COMPLIANCE
    EVENT_COMPLIANCE -.->|trigger| EVENT_ALERT
    
    style SKILLS_LIST fill:#ffecb3
    style SKILL_DETAIL fill:#ffecb3
    style VALIDATE_EP fill:#ffecb3
    style COMPLIANCE_EP fill:#ffecb3
    style CLI_LIST fill:#c8e6c9
    style CLI_SHOW fill:#c8e6c9
    style CLI_SEARCH fill:#c8e6c9
    style CLI_VALIDATE fill:#c8e6c9
    style CLI_COMPLIANCE fill:#c8e6c9
    style GHA_SETUP fill:#bbdefb
    style GHA_VALIDATE fill:#bbdefb
    style GHA_REPORT fill:#bbdefb
    style EVENT_NEW fill:#f8bbd0
    style EVENT_DEPRECATE fill:#f8bbd0
    style EVENT_COMPLIANCE fill:#f8bbd0
    style EVENT_ALERT fill:#f8bbd0
```

---

## 6. Dependency Chain Analysis

### Critical Paths (Red = Blocking Sequence)

```mermaid
graph LR
    subgraph "Critical Path 1: Skill Publishing"
        S1["1. Skill Author<br/>commits to repo"]
        S2["2. CI validates<br/>manifest"]
        S3["3. Release tag<br/>created"]
        S4["4. GitHub webhook<br/>fired"]
        S5["5. API indexes<br/>skill"]
        S6["6. Cache<br/>invalidated"]
        S1 -->|git push| S2
        S2 -->|git tag| S3
        S3 -->|webhook| S4
        S4 -->|http| S5
        S5 -->|redis| S6
    end
    
    subgraph "Critical Path 2: Project Validation"
        P1["1. Project adds<br/>skills.yaml"]
        P2["2. CI runs<br/>vpn-skills validate"]
        P3["3. API resolves<br/>versions"]
        P4["4. Check deps<br/>compatibility"]
        P5["5. Return result<br/>to CI"]
        P1 -->|git push| P2
        P2 -->|http| P3
        P3 -->|query| P4
        P4 -->|json| P5
    end
    
    subgraph "Critical Path 3: Compliance Scan"
        C1["1. Scheduled job<br/>or manual trigger"]
        C2["2. API fetches<br/>all projects"]
        C3["3. Compliance<br/>engine processes"]
        C4["4. Emit events<br/>to queue"]
        C5["5. Notifier sends<br/>alerts"]
        C1 -->|cron| C2
        C2 -->|db query| C3
        C3 -->|kafka| C4
        C4 -->|async| C5
    end
    
    style S1 fill:#ff6b6b
    style S2 fill:#ff6b6b
    style S3 fill:#ff6b6b
    style S4 fill:#ff6b6b
    style S5 fill:#ff6b6b
    style S6 fill:#ff6b6b
    style P1 fill:#ff6b6b
    style P2 fill:#ff6b6b
    style P3 fill:#ff6b6b
    style P4 fill:#ff6b6b
    style P5 fill:#ff6b6b
    style C1 fill:#ff6b6b
    style C2 fill:#ff6b6b
    style C3 fill:#ff6b6b
    style C4 fill:#ff6b6b
    style C5 fill:#ff6b6b
```

---

## 7. Network Security Topology

### Firewalling and Access Control

```mermaid
graph TB
    subgraph "Public Internet"
        USERS["Users & CI/CD<br/>Pipelines"]
    end
    
    subgraph "Ingress Layer"
        LB["Load Balancer<br/>(TLS Termination)"]
        WAF["WAF<br/>(Rate limiting)"]
    end
    
    subgraph "K8s Cluster"
        subgraph "vpn-skills-prod Namespace"
            APIPOD["API Server<br/>Pods"]
            DASHPOD["Dashboard<br/>Pods"]
        end
        
        subgraph "Data Layer (Private)"
            DBPOD["PostgreSQL<br/>Pods"]
            CACHEPOD["Redis<br/>Pods"]
            QUEUEPOD["Kafka<br/>Pods"]
        end
    end
    
    subgraph "External Services"
        GITHUB["GitHub<br/>(via GitHub App)"]
        SLACK["Slack<br/>(via Webhook)"]
    end
    
    USERS -->|https:443| LB
    LB -->|rate-limit| WAF
    WAF -->|forward| APIPOD
    WAF -->|forward| DASHPOD
    
    APIPOD -->|internal<br/>PostgreSQL| DBPOD
    APIPOD -->|internal<br/>Redis| CACHEPOD
    APIPOD -->|internal<br/>Kafka| QUEUEPOD
    
    APIPOD -->|https<br/>via OAuth| GITHUB
    APIPOD -.->|https<br/>via webhook| SLACK
    
    style USERS fill:#e1f5ff
    style LB fill:#ffccbc
    style WAF fill:#ffccbc
    style APIPOD fill:#c8e6c9
    style DASHPOD fill:#c8e6c9
    style DBPOD fill:#ffebee
    style CACHEPOD fill:#ffebee
    style QUEUEPOD fill:#ffebee
    style GITHUB fill:#d0d0d0
    style SLACK fill:#d0d0d0
```

**Network Policies**:
- ✅ Ingress: Only HTTPS on port 443 (TLS 1.2+)
- ✅ API → Database: Internal TCP only, TLS encryption required
- ✅ CLI → API: HTTPS with API key authentication
- ✅ Notifier → External: HTTPS with signed webhook tokens
- 🚫 Database: No direct external access
- 🚫 Cache: Internal only, no public access

---

## Summary

| Layer | Components | Technology | Status |
|-------|-----------|-----------|--------|
| **Frontend** | Discovery Dashboard | React/TypeScript | Planned |
| **API** | REST Server | Node.js/Express | Planned |
| **CLI** | Command-line Tool | Go/Cobra | Planned |
| **Backend** | Compliance Engine, Notifier | Python/FastAPI, Celery | Planned |
| **Data** | PostgreSQL, Redis, Kafka | PostgreSQL 14, Redis 7, Kafka | Planned |
| **Repository** | Skills Storage | GitHub | Existing |
| **Registry** | Package Distribution | npm, PyPI, Docker Hub | Existing |

---

## References

- **graph.yaml**: Detailed module configuration and dependencies
- **api-openapi.yaml**: REST API contract specification
- **data-model.md**: Entity relationships and schemas
- **spec.md**: Feature requirements and acceptance criteria

