# Feature Specification: Nimbus Agent Process Q&A and Direct Intake

**Feature Branch**: `018-nimbus-agent-intake`
**Created**: 2026-08-24
**Status**: Draft
**Input**: User description: "inciiar nova SPEC para NIMBUS AGENT REPO https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-agent.git mas a SPEC fica aqui, para que o NIMBUS seja capaz de responder perguntas sobre como o processo NIMBUS CODE funciona. E junto com a SPEC 017 fazer o INTAKE direto pro projeto."

## Nimbus-Code — Cabeçalho Obrigatório da Spec

| Campo | Valor |
|---|---|
| **Feature slug** | `018-nimbus-agent-intake` |
| **Complexidade estimada** | S3 |
| **Bounded Context** | `spec-kit-workflow` |
| **PR de referência / Issue** | novo |
| **Data alvo de entrega** | sem data |

> S0 = doc · S1 = função isolada · S2 = módulo · S3 = múltiplos módulos · S4 = arquitetura, segurança, dados ou integração crítica

## Nimbus-Code — SLO Alvo desta Feature

| Componente | Latência p99 (ms) | Taxa de erro máx. (%) | Disponibilidade alvo | RTO | RPO |
|---|---|---|---|---|---|
| Respostas sobre processo Nimbus Code | 2500 | 1,0% | 99,9% | 30 min | 5 min |
| Intake direto satélite → projeto | 3000 | 1,0% | 99,9% | 30 min | 5 min |
| Classificação de modo para intake da spec 017 | 2000 | 0,5% | 99,9% | 15 min | 1 min |

## Nimbus-Code — Objetivo e Contexto

**Objetivo:** permitir que o Nimbus responda perguntas operacionais sobre o processo Nimbus Code com rastreabilidade e execute intake direto do repositório satélite `nimbus-agent` para o projeto de governança central, alinhado ao modelo da spec 017.

**Motivação:** hoje existe documentação e automações parciais, mas falta uma capacidade unificada de suporte conversacional do processo e um fluxo padronizado de intake direto para o dashboard de projeto, sem depender de execução manual por sessão.

**Critério de done (alto nível):** perguntas sobre o processo recebem respostas consistentes e verificáveis, e uma demanda criada no satélite entra no fluxo de intake governado (com visibilidade no projeto e classificação de modo da spec 017).

## Nimbus-Code — Hybrid Collaboration Model

| Papel | Responsabilidades | Critério de handoff | Escalação |
|---|---|---|---|
| Agente Nimbus | Interpretar perguntas sobre o processo, gerar respostas com referência e iniciar intake direto para o projeto | Escala para humano em caso de conflito de regra, baixa confiança ou ausência de contexto mínimo | Architecture board |
| Agent Delivery Engineer | Validar qualidade das respostas e acompanhar intake automático no projeto | Escala para BA/PO quando houver impacto de escopo de negócio | Tech lead |
| Business Analyst | Confirmar que respostas e intake preservam a intenção de negócio e critérios de aceite | Aprova continuidade para execução técnica | Product owner |
| Digital Engineering | Ajustar integrações e automações entre repo satélite e projeto central | Retorna ao ADE após correções implementadas | Engineering manager |

## Nimbus-Code — Critérios de Aceitação (formato BDD)

> **AC-1**
> **Given** uma pergunta sobre o fluxo Nimbus Code,
> **When** o usuário solicitar explicação operacional,
> **Then** o Nimbus responde com passo a passo alinhado aos artefatos oficiais (spec/plan/tasks/implement/converge) e com linguagem adequada para BA e engenharia.
> **Test ref:** `test_AC1_process_qa_response`

> **AC-2**
> **Given** uma pergunta ambígua ou fora do escopo do processo,
> **When** o Nimbus não tiver evidência suficiente para responder com segurança,
> **Then** ele solicita esclarecimento objetivo em vez de inventar regra de processo.
> **Test ref:** `test_AC2_safe_clarification`

> **AC-3**
> **Given** uma nova demanda registrada no repositório `nimbus-agent`,
> **When** o evento de intake for disparado,
> **Then** a demanda é refletida no projeto central com metadados mínimos (tipo, prioridade, contexto e vínculo da feature).
> **Test ref:** `test_AC3_direct_project_intake`

> **AC-4**
> **Given** uma demanda de intake ligada ao escopo da spec 017,
> **When** o intake for classificado,
> **Then** o modo de execução (autônomo, semi-autônomo, manual) é definido com justificativa rastreável.
> **Test ref:** `test_AC4_spec017_mode_alignment`

> **AC-5**
> **Given** uma demanda classificada como semi-autônoma ou manual,
> **When** o fluxo alcançar checkpoint de aprovação,
> **Then** a continuidade depende de decisão humana registrada (Go/No-Go).
> **Test ref:** `test_AC5_human_gate_on_intake`

> **AC-6**
> **Given** necessidade de ativar/desativar intake direto por ambiente,
> **When** a política de rollout for aplicada,
> **Then** a spec declara OpenFeature como abstração para toggles, independente do provider.
> **Test ref:** `test_AC6_openfeature_intake_toggle`

## Nimbus-Code — Backlog Hierarchy (EPIC/FEATURE/US)

| Nível | Valor | Observação |
|---|---|---|
| **EPIC** | Nimbus Agent Operável no Ecossistema Nimbus Code | Consolida autonomia, governança e integração multi-repo |
| **FEATURE** | Q&A de processo + intake direto satélite → projeto | Entrega desta spec |
| **US1** | Responder perguntas sobre processo Nimbus Code | Suporte operacional para BA e engenharia |
| **US2** | Ingestão direta de demanda do `nimbus-agent` | Reduz passos manuais de abertura e sincronização |
| **US3** | Classificação de modo conforme spec 017 | Aplica governança de autonomia com justificativa |
| **US4** | Gate de aprovação humana para casos mandatórios | Mantém controle de risco e compliance |

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Suporte conversacional do processo Nimbus Code (Priority: P1)

Como Business Analyst, quero perguntar ao Nimbus como o processo funciona para orientar a abertura e evolução de demandas sem depender de interpretação informal.

**Why this priority**: sem orientação consistente, aumenta retrabalho e desalinhamento entre negócio e engenharia.

**Independent Test**: enviar perguntas típicas de BA sobre etapas e confirmar que a resposta mantém sequência correta, critérios de decisão e linguagem objetiva.

**Acceptance Scenarios**:

1. **Given** uma pergunta sobre fluxo end-to-end, **When** o BA consultar o Nimbus, **Then** recebe resposta estruturada com passos claros do processo.
2. **Given** uma pergunta fora do escopo, **When** o Nimbus detectar incerteza, **Then** ele pede clarificação antes de orientar ação.

---

### User Story 2 - Intake direto do repositório satélite (Priority: P1)

Como Agent Delivery Engineer, quero que demandas criadas no `nimbus-agent` entrem direto no projeto central para evitar duplicidade de cadastro.

**Why this priority**: o intake manual é ponto recorrente de atraso e inconsistência.

**Independent Test**: criar uma demanda de teste no satélite e validar entrada no projeto com os campos obrigatórios.

**Acceptance Scenarios**:

1. **Given** uma demanda aberta no satélite, **When** o fluxo de intake rodar, **Then** a demanda aparece no projeto central com os metadados mínimos.
2. **Given** um intake sem campos obrigatórios, **When** o sistema processar a entrada, **Then** a demanda é sinalizada para correção sem avançar para execução.

---

### User Story 3 - Governança de modo e aprovação (Priority: P1)

Como Digital Engineer, quero que o intake herdado da spec 017 seja classificado por modo com gate humano quando necessário, para manter velocidade sem perder controle.

**Why this priority**: autonomia sem regra de aprovação pode gerar execução em contexto inadequado.

**Independent Test**: enviar demandas de diferentes criticidades e verificar classificação de modo e bloqueio quando aprovação humana for mandatória.

**Acceptance Scenarios**:

1. **Given** uma demanda de baixa criticidade, **When** for classificada, **Then** segue fluxo autônomo com justificativa registrada.
2. **Given** uma demanda de alta criticidade, **When** atingir checkpoint, **Then** não prossegue sem decisão humana registrada.

### Edge Cases

- Duplicidade de intake para a mesma demanda no satélite deve resultar em deduplicação idempotente no projeto.
- Ausência de token/permissão de projeto deve gerar falha explícita e rastreável, sem “sucesso silencioso”.
- Perguntas sobre processo com referências desatualizadas devem ser respondidas com aviso de confiança reduzida e pedido de atualização de contexto.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O Nimbus MUST responder perguntas sobre o processo Nimbus Code cobrindo as etapas principais do ciclo (specify, plan, tasks, implement, converge).
- **FR-002**: O Nimbus MUST diferenciar pergunta respondível de pergunta ambígua/fora de escopo e MUST pedir clarificação quando faltar contexto.
- **FR-003**: O intake originado no `nimbus-agent` MUST criar ou atualizar item correspondente no projeto central com metadados mínimos obrigatórios.
- **FR-004**: O fluxo de intake MUST registrar vínculo entre demanda do satélite e referência da feature no repositório central.
- **FR-005**: Demandas de intake relacionadas à spec 017 MUST ser classificadas nos modos autônomo, semi-autônomo ou manual com justificativa.
- **FR-006**: Demandas em modo semi-autônomo ou manual MUST exigir registro de aprovação humana antes de continuidade.
- **FR-007**: O fluxo MUST ser idempotente para evitar criação duplicada de itens de projeto para o mesmo intake.
- **FR-008**: Falhas de integração no intake MUST ser explícitas e observáveis, sem mascaramento de erro.
- **FR-009**: A feature MUST declarar OpenFeature como padrão de abstração para toggles de rollout de intake direto.
- **FR-010**: A solução MUST permitir auditoria de quem iniciou o intake, qual modo foi definido e qual decisão de aprovação foi tomada.

### Key Entities *(include if feature involves data)*

- **Process Question**: pergunta operacional sobre o fluxo Nimbus Code feita por BA, ADE ou engenharia.
- **Intake Demand**: demanda criada no repositório satélite com metadados mínimos para triagem.
- **Project Item**: representação da demanda no projeto central para gestão de backlog.
- **Mode Decision**: decisão de modo (autônomo, semi-autônomo, manual) com justificativa.
- **Approval Decision**: decisão humana Go/No-Go quando o gate de aprovação é obrigatório.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Em uma amostra de perguntas frequentes do processo, pelo menos 90% devem ser respondidas de forma considerada correta por revisão humana.
- **SC-002**: Pelo menos 95% dos intakes válidos abertos no satélite devem aparecer no projeto central em até 2 minutos.
- **SC-003**: 100% das demandas classificadas como semi-autônomas ou manuais devem conter decisão humana registrada antes de execução.
- **SC-004**: Taxa de duplicidade de itens de projeto para o mesmo intake deve permanecer abaixo de 1%.
- **SC-005**: Em auditoria de amostra, 100% dos casos devem permitir rastrear origem da demanda, modo definido e decisão de aprovação.

## Assumptions

- O repositório satélite `venha-pra-nuvem/nimbus-agent` permanece a fonte de criação inicial das demandas operacionais.
- O projeto central já está configurado para receber itens automatizados via integração existente.
- A spec 017 segue como contrato de governança de modo, e esta feature foca em conectar intake e suporte conversacional ao contrato.
