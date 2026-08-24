# Data Model — 017-nimbus-digital-engineer-platform

## Entity: IntakeEntry
**Purpose**: Representar a demanda normalizada recebida de M365/GitHub.  
**Fields**:
- `id` (string, uuid)
- `source` (enum: `m365_meeting`, `sharepoint`, `github`)
- `title` (string, obrigatório)
- `objective` (string, obrigatório)
- `owner` (string, obrigatório)
- `priority` (enum: `low`, `medium`, `high`, `critical`)
- `deadline` (datetime, opcional)
- `attachments` (array<string>)
- `correlation_key` (string, obrigatório para deduplicação)
- `source_ref` (string, opcional)
- `status` (enum: `received`, `qualified`, `blocked`, `ready`)
- `duplicate_of` (string, opcional)
- `blocked_reason` (string, opcional)
- `created_at` (datetime)
- `updated_at` (datetime)

## Entity: ExecutionModePolicy
**Purpose**: Definir regras de classificação de modo operacional.  
**Fields**:
- `id` (string)
- `risk_level` (enum: `low`, `medium`, `high`)
- `criticality` (enum: `business_low`, `business_high`)
- `compliance_required` (boolean)
- `selected_mode` (enum: `autonomous`, `semi_autonomous`, `manual_approval`)
- `justification_template` (string)
- `active` (boolean)

## Entity: ApprovalCheckpoint
**Purpose**: Registrar gates de decisão humana por etapa.  
**Fields**:
- `id` (string)
- `intake_entry_id` (fk -> IntakeEntry.id)
- `stage` (string)
- `required` (boolean)
- `approver_role` (string)
- `decision` (enum: `pending`, `go`, `no_go`)
- `decision_reason` (string)
- `decided_at` (datetime, opcional)

## Checkpoint state transitions (US3)
- `pending -> go` (somente por papel autorizado no RACI)
- `pending -> no_go` (somente por papel autorizado no RACI)
- `go/no_go` são estados terminais para o checkpoint

## Entity: RACIProfile
**Purpose**: Estruturar responsabilidade por etapa.  
**Fields**:
- `id` (string)
- `stage` (string)
- `responsible` (array<string>)
- `accountable` (array<string>)
- `consulted` (array<string>)
- `informed` (array<string>)
- `escalation_path` (array<string>)

## Entity: DeliveryHandoff
**Purpose**: Consolidar saída final da demanda com evidências.  
**Fields**:
- `id` (string)
- `intake_entry_id` (fk -> IntakeEntry.id)
- `result_summary` (string)
- `acceptance_evidence` (array<string>)
- `quality_evidence` (array<string>)
- `cost_ai_tokens` (number)
- `cost_human_hours` (number)
- `pending_items` (array<string>)
- `next_steps` (array<string>)
- `final_decision` (enum: `approved`, `approved_with_conditions`, `rejected`)
- `published_at` (datetime)

## Entity: DomainBadge
**Purpose**: Definir badge por domínio de Digital Engineering.  
**Fields**:
- `id` (string)
- `domain` (string)
- `level` (enum: `foundational`, `intermediate`, `advanced`)
- `eligibility_criteria` (array<string>)
- `evidence_requirements` (array<string>)
- `status` (enum: `draft`, `published`, `deprecated`)

## Domain badge taxonomy (US5)
- Dimensão de domínio: `delivery`, `arquitetura`, `qualidade`, `segurança`, `governança`
- Níveis mínimos: `foundational`, `intermediate`, `advanced`
- Cada combinação `domínio + nível` exige critérios e evidências explícitas

## Duplicate detection strategy (US1)
- Janela de correlação: 24h
- Chave principal: `correlation_key`
- Fallback: combinação de `title + owner + priority + source_ref`
- Regra: se detectar duplicidade, manter registro canônico e apontar `duplicate_of`

## Relationships
- `IntakeEntry 1:N ApprovalCheckpoint`
- `IntakeEntry 1:1 DeliveryHandoff`
- `ExecutionModePolicy 1:N IntakeEntry` (por decisão aplicada)
- `RACIProfile 1:N ApprovalCheckpoint` (por stage)
- `DomainBadge` é independente, mas referenciado no framework de competências da plataforma
