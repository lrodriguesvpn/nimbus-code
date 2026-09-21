<!--
  Este bloco é inserido pelo preset `nimbus-code-standards` (estratégia `prepend`) antes
  do spec-template.md nativo do Nimbus Code, adicionando campos obrigatórios da Nimbus-Code:
  classificação de complexidade S0–S4 já na spec, bounded context, SLO alvo e critérios
  de aceitação no formato BDD. O restante da spec (contexto técnico, objetivo etc.)
  continua sendo preenchido normalmente pelo /nimbus-code-specify.
-->

## Nimbus-Code — Cabeçalho Obrigatório da Spec

*Preencher ANTES dos critérios de aceitação. Alimenta o plan.md, o graph.yaml e
a seleção de modelo do agente.*

| Campo | Valor |
|---|---|
| **Feature slug** | `<kebab-case-slug>` — usado como nome da pasta em `specs/` |
| **Complexidade estimada** | S0 · S1 · S2 · S3 · S4 *(marcar um; pode ser revisado no plan.md)* |
| **Bounded Context** | [ex.: Order Management, Identity, Billing, Notification] |
| **PR de referência / Issue** | [link — ou "novo" se não existir] |
| **Data alvo de entrega** | [YYYY-MM-DD — ou "sem data"] |

> S0 = doc · S1 = função isolada · S2 = módulo · S3 = múltiplos módulos ·
> S4 = arquitetura, segurança, dados ou integração crítica

## Nimbus-Code — SLO Alvo desta Feature

*Preencher para componentes novos ou alterados. Alimenta o Observability Gate do
plan.md — alertas serão configurados com base nesses valores.*

| Componente | Latência p99 (ms) | Taxa de erro máx. (%) | Disponibilidade alvo | RTO | RPO |
|---|---|---|---|---|---|
| `<serviço>` | [ex.: 200ms] | [ex.: 0,1%] | [ex.: 99,9%] | [ex.: 5 min] | [ex.: 1 min] |

> Deixar vazio (`—`) apenas se o componente não expõe SLO mensurável (ex.: job
> batch interno sem SLA contratual). Omissão sem justificativa é tratada como
> "não definido" — o Observability Gate bloqueará o plan.md.

## Nimbus-Code — Objetivo e Contexto

*Descreva de forma objetiva o que esta feature entrega e por que ela é necessária.
Sem formato fixo — use parágrafos curtos ou tópicos. Substituiu o campo "User Story"
do modelo anterior: foque no objetivo de negócio/técnico, não numa narrativa de papel.*

**Objetivo:** [o que será construído ou alterado]

**Motivação:** [por que é necessário agora — problema que resolve ou oportunidade]

**Critério de done (alto nível):** [como saber que está feito — sem detalhar testes aqui]

## Nimbus-Code — Hybrid Collaboration Model

*Defina explicitamente como agente e humano se dividem na execução desta feature.
Use este bloco para reduzir handoff implícito e eliminar ambiguidade operacional.*

| Papel | Responsabilidades | Critério de handoff | Escalação |
|---|---|---|---|
| Agente | [geração inicial de artefatos, validações automatizadas] | [quando deve pedir revisão humana] | [tech lead / architecture board] |
| Humano | [revisão de negócio, validação final, ajustes finos] | [quando retorna ao agente para correções] | [tech lead / product owner] |

> Para contexto **WEB**, declarar explicitamente: *"Impeccable é o padrão oficial de design"*.  
> Exceções só são aceitas com justificativa no Architecture Decision Log do `plan.md`.

## Nimbus-Code — Critérios de Aceitação (formato BDD)

*Todo critério de aceitação deve estar no formato Given/When/Then para permitir
rastreabilidade direta com testes de integração. Cada item recebe um ID único
(AC-N) que será referenciado no `tasks.md` e nos testes.*

> **AC-1**
> **Given** [contexto inicial / pré-condição]
> **When** [ação do usuário ou evento do sistema]
> **Then** [resultado esperado e verificável]
> **Test ref:** `test_AC1_<descricao>` *(preenchido durante /nimbus-code-tasks)*

> **AC-2**
> **Given** …
> **When** …
> **Then** …
> **Test ref:** `test_AC2_<descricao>`

> **AC de governança para rollout/toggle (se aplicável)**
> - Feature com rollout progressivo deve declarar OpenFeature como padrão de abstração
> - Provider específico é decisão de ambiente, não de template

> *(Adicionar AC-N conforme necessário. Mínimo: 1 critério por feature.)*

{CORE_TEMPLATE}


# Feature Specification: [FEATURE NAME]

**Feature Branch**: `[###-feature-name]`

**Created**: [DATE]

**Status**: Draft

**Input**: User description: "$ARGUMENTS"

## User Scenarios & Testing *(mandatory)*

<!--
  IMPORTANT: User stories should be PRIORITIZED as user journeys ordered by importance.
  Each user story/journey must be INDEPENDENTLY TESTABLE - meaning if you implement just ONE of them,
  you should still have a viable MVP (Minimum Viable Product) that delivers value.

  Assign priorities (P1, P2, P3, etc.) to each story, where P1 is the most critical.
  Think of each story as a standalone slice of functionality that can be:
  - Developed independently
  - Tested independently
  - Deployed independently
  - Demonstrated to users independently
-->

### User Story 1 - [Brief Title] (Priority: P1)

[Describe this user journey in plain language]

**Why this priority**: [Explain the value and why it has this priority level]

**Independent Test**: [Describe how this can be tested independently - e.g., "Can be fully tested by [specific action] and delivers [specific value]"]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]
2. **Given** [initial state], **When** [action], **Then** [expected outcome]

---

### User Story 2 - [Brief Title] (Priority: P2)

[Describe this user journey in plain language]

**Why this priority**: [Explain the value and why it has this priority level]

**Independent Test**: [Describe how this can be tested independently]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]

---

### User Story 3 - [Brief Title] (Priority: P3)

[Describe this user journey in plain language]

**Why this priority**: [Explain the value and why it has this priority level]

**Independent Test**: [Describe how this can be tested independently]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]

---

[Add more user stories as needed, each with an assigned priority]

### Edge Cases

<!--
  ACTION REQUIRED: The content in this section represents placeholders.
  Fill them out with the right edge cases.
-->

- What happens when [boundary condition]?
- How does system handle [error scenario]?

## Requirements *(mandatory)*

<!--
  ACTION REQUIRED: The content in this section represents placeholders.
  Fill them out with the right functional requirements.
-->

### Functional Requirements

- **FR-001**: System MUST [specific capability, e.g., "allow users to create accounts"]
- **FR-002**: System MUST [specific capability, e.g., "validate email addresses"]
- **FR-003**: Users MUST be able to [key interaction, e.g., "reset their password"]
- **FR-004**: System MUST [data requirement, e.g., "persist user preferences"]
- **FR-005**: System MUST [behavior, e.g., "log all security events"]

*Example of marking unclear requirements:*

- **FR-006**: System MUST authenticate users via [NEEDS CLARIFICATION: auth method not specified - email/password, SSO, OAuth?]
- **FR-007**: System MUST retain user data for [NEEDS CLARIFICATION: retention period not specified]

### Key Entities *(include if feature involves data)*

- **[Entity 1]**: [What it represents, key attributes without implementation]
- **[Entity 2]**: [What it represents, relationships to other entities]

## Success Criteria *(mandatory)*

<!--
  ACTION REQUIRED: Define measurable success criteria.
  These must be technology-agnostic and measurable.
-->

### Measurable Outcomes

- **SC-001**: [Measurable metric, e.g., "Users can complete account creation in under 2 minutes"]
- **SC-002**: [Measurable metric, e.g., "System handles 1000 concurrent users without degradation"]
- **SC-003**: [User satisfaction metric, e.g., "90% of users successfully complete primary task on first attempt"]
- **SC-004**: [Business metric, e.g., "Reduce support tickets related to [X] by 50%"]

## Assumptions

<!--
  ACTION REQUIRED: The content in this section represents placeholders.
  Fill them out with the right assumptions based on reasonable defaults
  chosen when the feature description did not specify certain details.
-->

- [Assumption about target users, e.g., "Users have stable internet connectivity"]
- [Assumption about scope boundaries, e.g., "Mobile support is out of scope for v1"]
- [Assumption about data/environment, e.g., "Existing authentication system will be reused"]
- [Dependency on existing system/service, e.g., "Requires access to the existing user profile API"]
