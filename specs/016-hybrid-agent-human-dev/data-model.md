# Data Model & Entity Design

**Feature**: Hybrid Agent-Human Delivery Templates  
**Phase**: 1 — Design  
**Date**: 2026-08-18

---

## Core Entities

### 1. HybridCollaborationModel

*Define estrutura de responsabilidades e handoffs entre agentes e humanos.*

| Field | Type | Description | Constraints |
|---|---|---|---|
| `id` | UUID | Identificador único | Obrigatório |
| `role` | enum | `agent` \| `human` \| `tech-lead` | Obrigatório |
| `responsibilities` | array[string] | Lista de atividades esperadas | Min 1 item |
| `decision_authority` | string | Quem aprova/valida | Obrigatório |
| `handoff_criteria` | object | Condições para passar responsabilidade | Obrigatório |
| `escalation_path` | array[string] | Cadeia de escalação se bloqueio | Opcional |

**Example**:
```yaml
HybridCollaborationModel:
  id: "hcm-001"
  role: "agent"
  responsibilities:
    - "Gerar spec inicial com templates padrão"
    - "Preencher Technical Context"
    - "Preparar plano de design"
  decision_authority: "tech-lead"
  handoff_criteria:
    condition: "plan.md completo com Constitution Check passando"
    next_role: "human"
    trigger_event: "PR criada para revisão"
  escalation_path:
    - "tech-lead"
    - "architecture-board"
```

**Validation**:
- Cada role (agent, human, tech-lead) deve ter pelo menos 1 responsabilidade definida
- Decision authority deve ser um role válido
- Handoff criteria deve referenciar campo mensurável do artefato anterior

---

### 2. DetailedTaskBlueprint

*Contrato estrutural para tasks publicadas no GHE.*

| Field | Type | Description | Constraints |
|---|---|---|---|
| `id` | string | AC-N ou task ID no GHE | Obrigatório |
| `title` | string | Título curto e acionável | Max 80 chars |
| `context` | string | Informação necessária para entender | Obrigatório; max 500 chars |
| `objective` | string | O que fazer (ação) | Obrigatório; max 300 chars |
| `acceptance_criteria` | array[string] | Como validar resultado | Min 1, Max 5 items |
| `operational_steps` | array[object] | Passos passo-a-passo | Obrigatório se target_audience inclui "human" |
| `dependencies` | array[object] | Pré-requisitos e bloqueadores | Opcional |
| `assigned_to` | enum | `agent` \| `human` \| `both` | Obrigatório |
| `estimated_effort_tokens` | string | "~X–Y mil tokens" (agente) | Se assigned_to inclui "agent" |
| `estimated_effort_hours` | string | "~X–Y horas" (humano) | Se assigned_to inclui "human" |
| `created_from_ac_id` | string | Referência ao AC da spec | Obrigatório |

**Example**:
```yaml
DetailedTaskBlueprint:
  id: "AC-1"
  title: "Atualizar spec-template.md com seção de Hybrid Collaboration"
  context: |
    Feature 005 requer que todo novo spec.md inclua orientação explícita
    de colaboração entre agente e humano desde o cabeçalho.
  objective: |
    Modificar `.specify/presets/nimbus-code-standards/templates/spec-template.md`
    para prepend seção "Hybrid Collaboration Model" antes de "User Scenarios".
  acceptance_criteria:
    - "Novo cabeçalho aparece em todas as specs geradas após merge"
    - "Cabeçalho inclui campos: role, responsibilities, handoff_criteria"
    - "Nenhum conflito com template base (não cria duplicação)"
  operational_steps:
    - step: 1
      instruction: "Abrir arquivo `.specify/presets/nimbus-code-standards/templates/spec-template.md`"
    - step: 2
      instruction: "Adicionar novo section 'Hybrid Collaboration Model' com tabela estruturada"
    - step: 3
      instruction: "Validar em 2 projetos piloto que seção aparece quando spec é criada"
    - step: 4
      instruction: "Fazer commit com mensagem: 'Add hybrid collaboration model to spec-template'"
  dependencies:
    - id: "setup-env"
      type: "prerequisite"
      description: "Ter acesso ao repositório e branch feature/005"
  assigned_to: "both"
  estimated_effort_tokens: "~8–12 mil tokens"
  estimated_effort_hours: "~0.5 horas"
  created_from_ac_id: "AC-1"
```

**Validation**:
- assigned_to = "agent" → estimated_effort_tokens obrigatório
- assigned_to = "human" → estimated_effort_tokens opcional, estimated_effort_hours recomendado
- Se operational_steps vazio e assigned_to inclui "human" → ERROR
- Cada step deve ter instruction clara (não vaga)

---

### 3. CostReferenceBlock

*Bloco de referência para rastreio de custo do modelo híbrido.*

| Field | Type | Description | Constraints |
|---|---|---|---|
| `spec_kit_cost_url` | URL | Link ao projeto SPEC KIT COST | Obrigatório; deve ser HTTPS |
| `token_estimate_range` | string | "~X–Y mil tokens" | Obrigatório; inspirado em estimativa do plan.md |
| `human_effort_estimate_range` | string | "~X–Y horas" | Recomendado; agregado de tasks humanas |
| `cost_tracking_method` | string | Como registrar custo real | Obrigatório |
| `cost_tracking_issue_id` | string | Issue no GitHub para tracking | Recomendado; facilita busca |
| `budget_ceiling` | string | Orçamento máximo estimado | Opcional; para governança |

**Example**:
```yaml
CostReferenceBlock:
  spec_kit_cost_url: "https://github.com/venha-pra-nuvem/spec-kit-cost"
  token_estimate_range: "~45–65 mil tokens"
  human_effort_estimate_range: "~8–12 horas"
  cost_tracking_method: |
    Preencher tabela "Estimativa vs. Consumo Real de Tokens" no plan.md.
    Registrar horas humanas no GitHub Project "Developer Velocity".
  cost_tracking_issue_id: "#[issue-number-TBD]"
  budget_ceiling: "~$150 USD (custo estimado combinado)"
```

**Validation**:
- URL deve retornar HTTP 200
- Token/hour ranges devem estar em formato numérico reconhecível
- cost_tracking_method deve ser preenchido em linguagem clara (não deixar como placeholder)

---

### 4. WebDesignStandardPolicy

*Política para garantir padrão de design em features de contexto WEB.*

| Field | Type | Description | Constraints |
|---|---|---|---|
| `applies_to` | enum | Escopo da política | Obrigatório; `web` |
| `required_skill` | string | Skill oficial de design | Obrigatório; `impeccable` |
| `enforcement_level` | enum | Nível de obrigatoriedade | Obrigatório; `required` |
| `exception_process` | string | Como tratar exceções | Obrigatório |
| `validation_hint` | string | Evidência esperada no artefato | Obrigatório |

**Example**:
```yaml
WebDesignStandardPolicy:
  applies_to: "web"
  required_skill: "impeccable"
  enforcement_level: "required"
  exception_process: "Registrar desvio no Architecture Decision Log com aprovação de Tech Lead"
  validation_hint: "Spec deve mencionar explicitamente Impeccable como padrão de design WEB"
```

**Validation**:
- Se contexto = web e `required_skill` ausente → ERROR
- Se exceção for usada sem ADL → ERROR

---

### 5. FeatureToggleStandardPolicy

*Política para padronizar feature toggles com abstração portável.*

| Field | Type | Description | Constraints |
|---|---|---|---|
| `standard` | string | Camada de abstração oficial | Obrigatório; `OpenFeature` |
| `provider_strategy` | string | Estratégia de provider | Obrigatório; pluggable por ambiente |
| `flag_lifecycle` | array[string] | Regras de criação, rollout e remoção | Min 3 itens |
| `kill_switch_rule` | string | Regra de desligamento emergencial | Obrigatório |
| `owner_role` | string | Papel dono da governança da flag | Obrigatório |

**Example**:
```yaml
FeatureToggleStandardPolicy:
  standard: "OpenFeature"
  provider_strategy: "Provider configurável por ambiente, sem lock-in"
  flag_lifecycle:
    - "Criar flag com owner e data de limpeza"
    - "Rollout progressivo por ambiente/segmento"
    - "Remover flag após estabilização"
  kill_switch_rule: "Desabilitar flag via provider OpenFeature e registrar incidente"
  owner_role: "architecture-board"
```

**Validation**:
- Se `standard` diferente de OpenFeature → ERROR
- Se `flag_lifecycle` não incluir remoção de flag → ERROR

---

## Relationship Diagrams

### Entity Flow in Feature Lifecycle

```
spec.md (User Scenarios) 
  ↓
Agente enche "Hybrid Collaboration Model" no cabeçalho
  ↓
plan.md (Classification + "AC → Test" table + "Complexity Tracking" + "Release Strategy")
  ↓
Agente associa cada AC a um DetailedTaskBlueprint
  ↓
tasks.md / GHE Issues (DetailedTaskBlueprint instanciado)
  ↓
Humano executa task com "operational_steps" como guia
  ↓
Plan incluir "CostReferenceBlock" para rastreio
```

### Dependency Graph

```
HybridCollaborationModel
  ├─ roles (agent, human, tech-lead)
  └─ handoff_criteria → references DetailedTaskBlueprint.assigned_to

DetailedTaskBlueprint
  ├─ created_from_ac_id → references AC na spec
  ├─ assigned_to → consults HybridCollaborationModel
  ├─ dependencies → references outras DetailedTaskBlueprints
  └─ estimated_effort_* → consultado por CostReferenceBlock

CostReferenceBlock
  ├─ token_estimate_range ← aggregated from all DetailedTaskBlueprints
  ├─ human_effort_estimate_range ← aggregated from DetailedTaskBlueprints (assigned_to includes "human")
  └─ spec_kit_cost_url → external reference (read-only)

WebDesignStandardPolicy
  └─ required_skill = impeccable → referenced by spec/plan in WEB context

FeatureToggleStandardPolicy
  └─ standard = OpenFeature → referenced by release/toggle sections in plan
```

---

## State Transitions & Validation Rules

### Task Lifecycle

```
DRAFT → ASSIGNED → IN_PROGRESS → REVIEW → DONE → ARCHIVED
         ↓            ↓            ↓                    ↓
      (assigned_to  (code change  (PR created)   (after 90 days
       updated)      made)         for review)    or explicit close)
```

### Validation Rules

1. **Template Consistency**: Se um DetailedTaskBlueprint referenciar AC da spec, essa AC deve existir e estar em formato BDD
2. **Cost Accuracy**: Sum(all DetailedTaskBlueprints.estimated_effort_tokens) deve estar próximo de plan.md token_estimate_range (within ±20%)
3. **Role Coverage**: Cada role em HybridCollaborationModel deve ter ao menos 1 DetailedTaskBlueprint com assigned_to = role
4. **URL Validity**: CostReferenceBlock.spec_kit_cost_url deve retornar HTTP 200 em CI/CD
5. **No Circular Dependencies**: DetailedTaskBlueprints não podem ter circular dependency graph
6. **WEB Design Enforcement**: Se feature context = WEB, WebDesignStandardPolicy.required_skill deve ser `impeccable`
7. **Toggle Standard Enforcement**: FeatureToggleStandardPolicy.standard deve ser `OpenFeature` em todos os plans com rollout

---

## Implementation Notes

- Entidades são representadas em YAML/JSON no plan.md e artefatos de design
- Cada skill (speckit-specify, speckit-plan, speckit-tasks) valida um subconjunto dessas entidades
- Rastreabilidade AC → Blueprint → Task é auditável via IDs
- Custo é rastreado no SPEC KIT COST framework (não centralizado aqui)
