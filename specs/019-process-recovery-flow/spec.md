# Feature Specification: Fluxo de Correção de Rota para Specs Existentes

**Branch da feature**: `019-process-recovery-flow`
**Criado em**: 2026-08-24
**Status**: Rascunho
**Entrada**: Descrição do usuário: "Formalizar o tratamento operacional de features Nimbus Code quando a implementacao apresentar erros funcionais ou de arquitetura apos a spec ja existir: definir quando usar clarify, quando atualizar a mesma spec/plan/tasks, quando usar converge, quando abrir uma nova spec e como documentar isso no developer guide, FAQ e constituicao, com fluxo ilustrado para BA, Dev e agente."

## Nimbus-Code — Cabeçalho Obrigatório da Spec

| Campo | Valor |
|---|---|
| **Feature slug** | `019-process-recovery-flow` |
| **Complexidade estimada** | S2 |
| **Bounded Context** | `spec-kit-workflow` |
| **PR de referência / Issue** | novo |
| **Data alvo de entrega** | sem data |

> S0 = doc · S1 = função isolada · S2 = módulo · S3 = múltiplos módulos · S4 = arquitetura, segurança, dados ou integração crítica

## Nimbus-Code — SLO Alvo desta Feature

| Componente | Latência p99 (ms) | Taxa de erro máx. (%) | Disponibilidade alvo | RTO | RPO |
|---|---|---|---|---|---|
| Documentação operacional de correção de rota | — | — | — | — | — |
| Regra de decisão clarify vs converge | — | — | — | — | — |

## Nimbus-Code — Objetivo e Contexto

**Objetivo:** padronizar como o time Nimbus Code reage quando uma feature já especificada ou parcialmente implementada apresenta erro funcional, erro arquitetural ou mudança de entendimento da intenção original.

**Motivação:** hoje o time pode hesitar entre reabrir clarificação, rodar converge ou abrir uma nova spec, gerando correções inconsistentes e risco de divergência entre artefato e implementação.

**Critério de done (alto nível):** o time consegue decidir de forma repetível quando corrigir código, quando atualizar a mesma spec, quando atualizar o mesmo plano e quando criar uma nova spec, com documentação operacional clara para Dev, BA e agente.

## Nimbus-Code — Hybrid Collaboration Model

| Papel | Responsabilidades | Critério de repasse | Escalação |
|---|---|---|---|
| Agente | Propor fluxo de correção, atualizar documentação operacional e manter rastreabilidade entre comandos do processo | Encaminha para revisão humana quando a regra impactar governança organizacional | Comitê de arquitetura |
| Dev | Validar consistência do processo, aplicar a regra correta em features reais e revisar mudanças na constituição | Devolve ao agente se houver lacuna documental ou ambiguidade | Tech lead |
| Business Analyst | Confirmar que o fluxo preserva entendimento de negócio e que “nova spec vs mesma spec” está claro | Escala quando houver dúvida de escopo/valor | Product owner |

## Nimbus-Code — Critérios de Aceitação (formato BDD)

> **AC-1**
> **Dado** uma feature com `spec.md`, `plan.md` e `tasks.md` já existentes,
> **Quando** surgir um erro funcional apenas na implementação,
> **Então** a documentação orienta a manter a mesma spec e usar correção de código seguida de `converge`.
> **Referência de teste:** `test_AC1_implementation_error_flow`

> **AC-2**
> **Dado** uma feature existente com critério de aceite ambíguo ou incompleto,
> **Quando** o time consultar o fluxo operacional,
> **Então** a documentação orienta a atualizar a mesma `spec.md` e a usar `clarify` apenas quando houver ambiguidade real.
> **Referência de teste:** `test_AC2_spec_ambiguity_flow`

> **AC-3**
> **Dado** uma feature existente cuja arquitetura planejada não atende mais ao objetivo,
> **Quando** o time consultar o processo,
> **Então** a documentação orienta a atualizar o mesmo `plan.md`, ajustar `tasks.md` e voltar ao ciclo de implementação.
> **Referência de teste:** `test_AC3_architecture_replan_flow`

> **AC-4**
> **Dado** um problema descoberto em uma feature em andamento,
> **Quando** a correção continuar pertencendo ao mesmo recorte de valor,
> **Então** a documentação deixa explícito que a regra padrão é atualizar os artefatos da mesma feature, e não abrir nova spec.
> **Referência de teste:** `test_AC4_same_feature_default`

> **AC-5**
> **Dado** um novo escopo independente surgido durante a correção,
> **Quando** o time avaliar se deve continuar na mesma feature,
> **Então** a documentação lista critérios objetivos para abrir uma nova spec.
> **Referência de teste:** `test_AC5_new_spec_criteria`

> **AC-6**
> **Dado** a necessidade de consultar rapidamente o processo,
> **Quando** o time abrir o guia do desenvolvedor,
> **Então** encontra FAQ e fluxos visuais cobrindo os cenários de erro de implementação, ambiguidade da spec e replanejamento arquitetural.
> **Referência de teste:** `test_AC6_faq_and_flowcharts`

## Nimbus-Code — Backlog Hierarchy (EPIC/FEATURE/US)

| Nível | Valor | Observação |
|---|---|---|
| **EPIC** | Governança Operacional do Processo Nimbus Code | Regras organizacionais para operar specs, planos e execução |
| **FEATURE** | Correção de rota para features já existentes | Decisão entre clarify, replanejamento, converge e nova spec |
| **US1** | Corrigir erro de implementação sem reescrever intenção | Preserva a fonte de verdade atual |
| **US2** | Corrigir ambiguidade da spec existente | Atualiza a mesma feature com clareza |
| **US3** | Replanejar arquitetura sem perder o recorte da feature | Atualiza o mesmo plano e tarefas |
| **US4** | Identificar quando o caso virou nova spec | Evita uso indevido da spec antiga |

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Corrigir erro de implementação sem reescrever a intenção (Priority: P1)

Como Dev, quero saber se o problema está no código ou na fonte de verdade para aplicar o comando correto sem bagunçar os artefatos.

**Why this priority**: essa é a decisão mais frequente e a mais fácil de desviar incorretamente para reescrita de artefatos.

**Independent Test**: revisar a documentação e confirmar que ela orienta correção de código seguida de `converge`, sem reabrir `spec.md` ou `plan.md`.

**Acceptance Scenarios**:

1. **Dado** um bug funcional com requisitos ainda válidos, **Quando** o time consulta o fluxo, **Então** encontra a orientação de corrigir código e usar `converge` no fechamento.

---

### User Story 2 - Corrigir ambiguidade da spec existente (Priority: P1)

Como Dev ou BA, quero saber quando a ambiguidade está na `spec.md` para corrigir a fonte de verdade sem tratar o problema como bug de implementação.

**Why this priority**: sem esse corte, o time mistura erro de código com erro de intenção e toma decisões inconsistentes.

**Independent Test**: verificar que a documentação explica quando atualizar a mesma `spec.md` e quando `clarify` realmente se aplica.

**Acceptance Scenarios**:

1. **Dado** um critério de aceite ambíguo, **Quando** o time consulta o fluxo, **Então** encontra a orientação de atualizar a mesma `spec.md` antes de continuar.
2. **Dado** uma dúvida legítima sobre a intenção da feature, **Quando** o fluxo é seguido, **Então** a documentação aponta `clarify` apenas como ferramenta de resolução de ambiguidade real.

---

### User Story 3 - Replanejar arquitetura sem abrir nova spec por reflexo (Priority: P1)

Como arquiteto/tech lead, quero replanejar a solução quando a arquitetura falhar sem criar ruído administrativo desnecessário.

**Why this priority**: muitos erros de arquitetura não mudam a feature, apenas o caminho técnico para entregá-la.

**Independent Test**: verificar que a documentação explica quando atualizar o mesmo `plan.md` e quando isso pode impactar também a `spec.md`.

**Acceptance Scenarios**:

1. **Dado** um plano arquitetural inválido com objetivo de negócio preservado, **Quando** o fluxo for seguido, **Então** ele aponta atualização do mesmo `plan.md`.
2. **Dado** uma mudança de arquitetura que altera comportamento esperado, **Quando** o fluxo for seguido, **Então** ele aponta atualização conjunta de plano e spec na mesma feature.

---

### User Story 4 - Saber quando abrir nova spec (Priority: P2)

Como Business Analyst, quero saber quando um problema virou nova feature para não esconder escopo novo dentro da spec antiga.

**Why this priority**: abrir uma nova spec cedo demais gera fragmentação; abrir tarde demais gera escopo inchado e rastreabilidade ruim.

**Independent Test**: revisar os critérios e confirmar que eles separam “correção da feature” de “nova entrega de valor”.

**Acceptance Scenarios**:

1. **Dado** um desdobramento independente do problema original, **Quando** o time consulta a documentação, **Então** ele encontra critérios objetivos para abrir nova spec.
2. **Dado** uma correção ainda pertencente ao mesmo recorte de valor, **Quando** o time consulta a documentação, **Então** ele encontra orientação para manter a mesma spec.

### Edge Cases

- O erro foi descoberto antes de existir `plan.md`: o processo deve orientar atualização da mesma `spec.md` e só depois o planejamento.
- O erro foi descoberto depois de merge em produção: a documentação deve continuar válida para correção operacional, mas a decisão de hotfix/rollback segue o processo de release vigente.
- A mudança parece nova feature para engenharia, mas é apenas refinamento de aceite para negócio: a documentação deve priorizar o critério de valor entregue, não apenas esforço técnico.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O processo DEVE diferenciar explicitamente erro de implementação, erro de especificação e erro de arquitetura.
- **FR-002**: O processo DEVE estabelecer que `converge` não altera `spec.md` nem `plan.md`, apenas anexa tarefas em `tasks.md`.
- **FR-003**: O processo DEVE estabelecer que ambiguidades na intenção da feature são tratadas na mesma `spec.md`, com `clarify` apenas quando necessário.
- **FR-004**: O processo DEVE estabelecer que falhas arquiteturais com o mesmo objetivo de negócio são tratadas no mesmo `plan.md`.
- **FR-005**: O processo DEVE definir critérios objetivos para abertura de nova spec.
- **FR-006**: A documentação DEVE incluir um FAQ operacional cobrindo o cenário de correção de rota.
- **FR-007**: A documentação DEVE incluir fluxos visuais para os cenários principais de decisão.
- **FR-008**: A constituição DEVE registrar a política organizacional de idioma para artefatos de código e documentação.

### Key Entities *(include if feature involves data)*

- **Fonte de Verdade**: artefato que define a intenção vigente da feature (`spec.md` e, por derivação, `plan.md`/`tasks.md`).
- **Erro de Implementação**: falha no código frente a artefatos que continuam corretos.
- **Erro de Especificação**: ambiguidade, omissão ou contradição na intenção da feature.
- **Erro de Arquitetura**: falha no desenho técnico ou nas decisões do plano para atender a intenção vigente.
- **Caminho de Correção do Processo**: caminho operacional escolhido (`clarify`, atualização da mesma spec/plan/tasks, `implement`, `converge` ou nova spec).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Em revisão interna, 100% dos cenários documentados devem indicar claramente se a ação correta é clarificar, replanejar, convergir ou abrir nova spec.
- **SC-002**: Pelo menos 90% dos devs/analistas que lerem o guia devem conseguir responder corretamente a pergunta “o converge altera a spec?” sem consulta adicional.
- **SC-003**: O guia deve cobrir ao menos três cenários visuais distintos: erro de implementação, erro de especificação e erro de arquitetura.
- **SC-004**: A política de idioma deve ficar explícita em um único ponto normativo da constituição, sem depender de instrução informal em prompts.

## Assumptions

- O fluxo oficial continua sendo `specify -> plan -> tasks -> implement -> converge`.
- `clarify` segue sendo um instrumento de resolução de ambiguidade, não um substituto de correção de código.
- O time prefere atualizar a mesma feature sempre que o recorte de valor permanecer o mesmo.
