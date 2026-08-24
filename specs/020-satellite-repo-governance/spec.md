# Feature Specification: Governança de Repos Satélite e Intake Greenfield MultiRepo

**Feature Branch**: `020-satellite-repo-governance`
**Created**: 2026-08-24
**Status**: Draft
**Input**: Solicitação formalizada do usuário: "Formalizar a governança de repositórios satélite no processo Nimbus Code, mantendo a correção do bootstrap como bugfix separado. Para novos projetos greenfield, o bootstrap deve identificar automaticamente se o repositório é brownfield ou greenfield com base na presença de código, perguntar se a topologia desejada é monorepo ou multirepo, registrar a justificativa da decisão e, no caso multirepo, orientar a criação de repositórios satélite por domínio após a primeira spec, sugerindo como ponto de partida os domínios FRONT, BACK, DESIGN, DATA e JOBS, sem impedir variações aprovadas pelo time."

## Nimbus-Code — Cabeçalho Obrigatório da Spec

| Campo | Valor |
|---|---|
| **Feature slug** | `020-satellite-repo-governance` |
| **Complexidade estimada** | S3 |
| **Bounded Context** | `spec-kit-workflow` |
| **PR de referência / Issue** | novo |
| **Data alvo de entrega** | sem data |

> S0 = doc · S1 = função isolada · S2 = módulo · S3 = múltiplos módulos · S4 = arquitetura, segurança, dados ou integração crítica

## Nimbus-Code — SLO Alvo desta Feature

| Componente | Latência p99 (ms) | Taxa de erro máx. (%) | Disponibilidade alvo | RTO | RPO |
|---|---|---|---|---|---|
| Decisão greenfield vs brownfield no bootstrap | 3000 | 1,0% | 99,9% | 30 min | 5 min |
| Intake de topologia mono vs multirepo | 4000 | 1,0% | 99,9% | 30 min | 5 min |
| Governança central → satélites | 5000 | 1,0% | 99,9% | 60 min | 15 min |

## Nimbus-Code — Objetivo e Contexto

**Objetivo:** padronizar como o Nimbus Code inicia projetos greenfield com decisão explícita de topologia de repositórios e como governa repositórios satélite sem permitir que eles virem uma segunda fonte de verdade para specs.

**Motivação:** hoje o processo multi-repo já existe conceitualmente, mas ainda depende de interpretação manual sobre quando criar satélites, como classificá-los, qual repositório hospeda a spec e como manter o bundle central sincronizado entre repo central e satélites.

**Critério de done (alto nível):** o bootstrap orienta claramente greenfield vs brownfield, registra a decisão mono vs multirepo com justificativa, sugere uma topologia inicial de domínios para multirepo e formaliza que toda spec permanece no repo central, com satélites consumindo código, tasks e atualizações do bundle.

**Fora de escopo:** correções técnicas pontuais do bootstrap já identificadas como bugfix operacional (ex.: URL quebrada, leitura interativa via pipe, regressões de execução). Esta feature trata apenas da regra de processo e da experiência formal de intake/topologia.

## Nimbus-Code — Hybrid Collaboration Model

| Papel | Responsabilidades | Critério de handoff | Escalação |
|---|---|---|---|
| Agente | Conduzir o intake inicial do projeto, classificar o cenário greenfield/brownfield, coletar decisão mono vs multirepo e orientar a topologia sugerida | Repassa quando a decisão exigir trade-off organizacional ou criação de novos domínios fora do padrão sugerido | Architecture board |
| Dev | Validar a viabilidade técnica da topologia escolhida e confirmar impacto em bootstrap, board e roteamento de tasks | Repassa ao BA/PO quando a decisão alterar modelo operacional do produto | Tech lead |
| Business Analyst | Confirmar que a decomposição por domínio preserva ownership e legibilidade do backlog | Repassa para produto quando a divisão afetar fluxo de entrega ou KPIs | Product owner |
| Digital Engineering | Garantir que repo central, satélites e automações de atualização permaneçam alinhados ao bundle oficial | Repassa para platform team quando houver mudança estrutural no bundle ou no board cross-repo | Engineering manager |

## Nimbus-Code — Critérios de Aceitação (formato BDD)

> **AC-1**
> **Given** um repositório recém-criado sem código de aplicação relevante,
> **When** o bootstrap Nimbus Code for iniciado,
> **Then** o fluxo o trata como greenfield e apresenta a decisão de topologia mono vs multirepo antes de orientar a estrutura inicial.
> **Test ref:** `test_AC1_greenfield_detection`

> **AC-2**
> **Given** um repositório já contendo código de aplicação relevante,
> **When** o bootstrap Nimbus Code for iniciado,
> **Then** o fluxo o trata como brownfield e evita orientar criação de satélites como passo padrão de abertura.
> **Test ref:** `test_AC2_brownfield_detection`

> **AC-3**
> **Given** um projeto greenfield,
> **When** o responsável optar por monorepo ou multirepo,
> **Then** o bootstrap exige o registro do motivo da decisão em linguagem clara para posterior rastreabilidade.
> **Test ref:** `test_AC3_topology_reason_capture`

> **AC-4**
> **Given** um projeto greenfield classificado como multirepo,
> **When** a primeira spec do produto for criada,
> **Then** o processo sugere uma topologia inicial de domínios satélite com referência explícita a FRONT, BACK, DESIGN, DATA e JOBS como baseline recomendada, sem tratá-la como lista obrigatória.
> **Test ref:** `test_AC4_default_domain_suggestions`

> **AC-5**
> **Given** a necessidade de adaptar a topologia sugerida,
> **When** o time optar por domínios diferentes dos sugeridos,
> **Then** o processo permite a variação desde que a justificativa e o ownership fiquem registrados na própria feature.
> **Test ref:** `test_AC5_custom_domain_topology`

> **AC-6**
> **Given** um ecossistema com repo central e repositórios satélite,
> **When** o time operar o fluxo normal do Nimbus Code,
> **Then** a documentação deixa explícito que `spec.md`, `plan.md`, `tasks.md` e demais artefatos de spec vivem apenas no repo central do produto.
> **Test ref:** `test_AC6_central_spec_source_of_truth`

> **AC-7**
> **Given** um repo satélite já bootstrapado,
> **When** o bundle oficial do repo central evoluir,
> **Then** o processo documenta que o satélite deve permanecer alinhado pelo mesmo mecanismo oficial de atualização, sempre via PR revisado.
> **Test ref:** `test_AC7_satellite_update_governance`

## Nimbus-Code — Backlog Hierarchy (EPIC/FEATURE/US)

| Nível | Valor | Observação |
|---|---|---|
| **EPIC** | Governança MultiRepo do Nimbus Code | Estrutura como produtos greenfield e satélites entram no ecossistema |
| **FEATURE** | Governança de repos satélite e intake greenfield multi-repo | Escopo desta spec |
| **US1** | Classificar automaticamente greenfield vs brownfield | Melhora a entrada correta no bootstrap |
| **US2** | Registrar decisão mono vs multirepo com justificativa | Evita escolha implícita e não rastreada |
| **US3** | Sugerir domínios padrão para satélites em greenfield multirepo | Cria aceleração com flexibilidade |
| **US4** | Formalizar repo central como fonte única de specs | Elimina drift entre central e satélites |
| **US5** | Garantir alinhamento contínuo do bundle entre central e satélites | Mantém governança operacional |

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Classificar corretamente a entrada do projeto (Priority: P1)

Como Digital Engineer, quero que o bootstrap diferencie greenfield e brownfield logo no início para evitar orientar o projeto pelo fluxo errado.

**Why this priority**: se a classificação inicial estiver errada, todo o restante do onboarding segue uma trilha inadequada.

**Independent Test**: iniciar o fluxo em um repositório vazio e em um repositório com código pré-existente e verificar que as orientações divergem conforme o cenário.

**Acceptance Scenarios**:

1. **Given** um repositório sem código de aplicação relevante, **When** o bootstrap começar, **Then** ele apresenta o fluxo greenfield.
2. **Given** um repositório com código de aplicação relevante, **When** o bootstrap começar, **Then** ele apresenta o fluxo brownfield.

---

### User Story 2 - Registrar a decisão de topologia do produto (Priority: P1)

Como Tech Lead, quero que a escolha entre monorepo e multirepo seja explícita e justificada para que a arquitetura organizacional do produto não fique implícita.

**Why this priority**: a maioria dos problemas de ownership e roteamento entre repos nasce de uma decisão estrutural tomada sem contexto registrado.

**Independent Test**: conduzir o bootstrap greenfield e confirmar que a decisão mono vs multirepo não pode ser concluída sem justificativa legível.

**Acceptance Scenarios**:

1. **Given** um projeto greenfield, **When** o responsável escolher monorepo, **Then** o fluxo registra o motivo da escolha.
2. **Given** um projeto greenfield, **When** o responsável escolher multirepo, **Then** o fluxo registra o motivo da escolha antes de sugerir a topologia inicial.

---

### User Story 3 - Sugerir satélites por domínio sem engessar o produto (Priority: P1)

Como Business Analyst, quero que o processo sugira uma decomposição inicial por domínio para projetos multirepo, sem transformar essa sugestão em regra fixa para todos os produtos.

**Why this priority**: o time precisa de aceleração na largada, mas com liberdade para adaptar a topologia ao contexto de negócio.

**Independent Test**: seguir o fluxo greenfield multirepo e verificar que FRONT, BACK, DESIGN, DATA e JOBS aparecem como baseline recomendada, com espaço para substituição ou expansão.

**Acceptance Scenarios**:

1. **Given** um projeto greenfield multirepo, **When** a primeira spec estrutural for concluída, **Then** o processo sugere os domínios FRONT, BACK, DESIGN, DATA e JOBS como ponto de partida.
2. **Given** um produto que exija outra decomposição, **When** o time ajustar a lista sugerida, **Then** a mudança é aceita desde que a justificativa permaneça registrada.

---

### User Story 4 - Preservar a fonte única de verdade no repo central (Priority: P1)

Como Agent Delivery Engineer, quero que os repositórios satélite recebam código e tasks, mas nunca virem repositórios paralelos de spec, para manter rastreabilidade centralizada.

**Why this priority**: sem uma regra explícita, o ecossistema multi-repo tende a duplicar `specs/` e criar drift de processo.

**Independent Test**: revisar a documentação do fluxo multi-repo e confirmar que ela separa claramente o papel do repo central do papel do satélite.

**Acceptance Scenarios**:

1. **Given** um produto multi-repo, **When** o time consultar a documentação operacional, **Then** encontrará a regra de que toda spec reside apenas no repo central.
2. **Given** uma mudança nascida em um satélite, **When** ela precisar virar feature governada, **Then** o fluxo orienta abrir ou atualizar a spec no repo central antes do roteamento.

---

### User Story 5 - Manter satélites alinhados ao bundle oficial (Priority: P2)

Como Digital Engineering, quero que os satélites usem o mesmo mecanismo oficial de atualização do bundle para evitar divergência silenciosa entre central e satélites.

**Why this priority**: a governança multi-repo perde valor rapidamente se cada satélite ficar numa versão operacional diferente.

**Independent Test**: validar que a documentação do satélite inclui atualização contínua via mecanismo oficial e nunca por mudança manual não rastreada.

**Acceptance Scenarios**:

1. **Given** um repo satélite bootstrapado, **When** houver nova versão do bundle oficial, **Then** o processo orienta atualização por PR revisado no próprio satélite.

### Edge Cases

- Um repositório contendo apenas README, licença e arquivos de setup mínimo não deve ser automaticamente tratado como brownfield real.
- Um projeto greenfield pode começar em monorepo e migrar depois para multirepo; o processo deve registrar a mudança como decisão consciente, não como exceção silenciosa.
- Um produto pode precisar de domínios diferentes do baseline sugerido (por exemplo, MOBILE, AI, INTEGRATIONS ou PLATFORM); isso não invalida o padrão desde que ownership e justificativa estejam explícitos.
- Um satélite não deve receber uma pasta `specs/` local apenas para “facilitar” documentação temporária.
- Atualizações do bundle em satélite não devem ocorrer diretamente em branch principal sem PR revisado.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O processo de bootstrap MUST distinguir orientação greenfield de orientação brownfield a partir da presença ou ausência de código de aplicação relevante no repositório.
- **FR-002**: O fluxo greenfield MUST exigir que o responsável escolha explicitamente entre monorepo e multirepo antes de concluir o intake inicial.
- **FR-003**: O fluxo greenfield MUST capturar o motivo da decisão mono vs multirepo em formato legível por humanos e reutilizável nos artefatos seguintes.
- **FR-004**: Quando a decisão for multirepo, o processo MUST sugerir uma topologia inicial de domínios satélite após a primeira spec estrutural do produto.
- **FR-005**: A topologia sugerida MUST incluir FRONT, BACK, DESIGN, DATA e JOBS como baseline recomendada, deixando explícito que a lista pode ser adaptada ao contexto do produto.
- **FR-006**: O processo MUST registrar que a adaptação da topologia sugerida depende de justificativa e definição clara de ownership por domínio.
- **FR-007**: O processo multi-repo MUST declarar o repo central do produto como fonte única de verdade para `spec.md`, `plan.md`, `tasks.md`, checklists, pesquisas e grafos da feature.
- **FR-008**: O processo MUST declarar que repositórios satélite recebem código, testes, IaC, PRs e tasks roteadas, mas não mantêm artefatos locais de spec como prática padrão.
- **FR-009**: O processo MUST orientar que todo repo satélite permaneça alinhado ao mesmo bundle oficial do repo central por mecanismo contínuo e auditável de atualização.
- **FR-010**: O processo MUST declarar que atualizações do bundle em satélite ocorrem por PR revisado, nunca por mudança silenciosa direta em branch principal.
- **FR-011**: A documentação resultante MUST separar claramente o escopo desta feature de bugfixes operacionais do bootstrap, para evitar que regras permanentes de processo se confundam com correções pontuais.

### Key Entities *(include if feature involves data)*

- **Projeto Greenfield**: novo produto ou iniciativa ainda sem código de aplicação relevante, elegível a decidir a topologia inicial de repositórios.
- **Projeto Brownfield**: produto já existente com código de aplicação relevante, que deve entrar no fluxo de descoberta e adaptação do legado.
- **Decisão de Topologia**: registro da escolha entre monorepo e multirepo, incluindo motivo, contexto e responsáveis.
- **Domínio Satélite**: recorte de responsabilidade do produto que pode ganhar repo próprio em uma topologia multirepo.
- **Repo Central**: repositório que concentra specs, planos, tasks, grafos e board cross-repo.
- **Repo Satélite**: repositório especializado por domínio que recebe código e backlog roteado a partir do repo central.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% dos novos projetos iniciados com o bootstrap registram explicitamente se são greenfield ou brownfield antes de seguir para a próxima etapa.
- **SC-002**: 100% dos projetos greenfield registram a decisão mono vs multirepo com justificativa legível no primeiro ciclo da feature estrutural.
- **SC-003**: Pelo menos 90% dos projetos greenfield multirepo conseguem definir a topologia inicial de domínios na primeira spec sem necessidade de documentação paralela fora do fluxo Nimbus Code.
- **SC-004**: 100% da documentação operacional multi-repo passa a indicar o repo central como única fonte de verdade para specs.
- **SC-005**: O número de variações manuais não rastreadas na criação de satélites é reduzido em pelo menos 80% nas próximas ativações greenfield do processo.

## Assumptions

- O produto terá um repo central de governança mesmo quando a implementação final usar múltiplos repositórios satélite.
- A primeira spec estrutural do produto é o lugar adequado para confirmar ou adaptar a lista inicial de domínios satélite.
- FRONT, BACK, DESIGN, DATA e JOBS são um baseline organizacional recomendado, não uma taxonomia rígida universal.
- A definição de “código de aplicação relevante” pode usar heurísticas operacionais do próprio bootstrap, desde que o comportamento final seja explicado de forma compreensível ao usuário.
- O mecanismo oficial de atualização do bundle já existe e será reutilizado como base de alinhamento entre central e satélites.
