# Feature Specification: Governança de Testes em PR — Política E2E, Padrão Executável e Gate Unificado

**Feature Branch**: `013-governanca-testes-pr`

**Created**: 2026-08-20

**Status**: Draft

**Input**: User description: "Política de Teste E2E, incluindo melhores práticas, frameworks possíveis, testes em cada PR, olhando tudo que já estamos fazendo." A feature também precisa padronizar a convenção hoje fragmentada entre `tests/bootstrap/*.bats` e `tests/**/*.test.sh`, explicitar os prós e contras das opções viáveis para este repositório e transformar a execução da suíte já existente em gate obrigatório de CI para toda PR.

---

## Nimbus-Code — Cabeçalho Obrigatório da Spec

| Campo | Valor |
|---|---|
| **Feature slug** | `013-governanca-testes-pr` |
| **Complexidade estimada** | **S3** *(cruza múltiplos módulos do bundle — política de testes, estrutura de `tests/`, documentação para contribuidores e governança de CI em PRs obrigatórias — e exige convergir padrões hoje dispersos sem quebrar o fluxo atual de trabalho)* |
| **Bounded Context** | `spec-kit-workflow` |
| **PR de referência / Issue** | novo |
| **Data alvo de entrega** | sem data |

> S0 = doc · S1 = função isolada · S2 = módulo · S3 = múltiplos módulos ·
> S4 = arquitetura, segurança, dados ou integração crítica

## Nimbus-Code — SLO Alvo desta Feature

| Componente | Latência p99 (ms) | Taxa de erro máx. (%) | Disponibilidade alvo | RTO | RPO |
|---|---|---|---|---|---|
| Política oficial de testes do bundle (consulta e uso por contribuidores) | — | 0% (artefato versionado) | — | — | — |
| Gate obrigatório de testes em PR | < 900000 | 1% de falha espúria máxima | 99% das PRs recebem resultado conclusivo na primeira execução | 1 dia útil | — |

> A feature combina documentação versionada e automação de CI. Apenas o gate de PR
> expõe SLO operacional mensurável; a política em si é um artefato estático.

## Nimbus-Code — Objetivo e Contexto

**Objetivo:** Definir uma política única e verificável de testes para este bundle Nimbus-Code, cobrindo o que conta como teste unitário, de integração e end-to-end neste tipo de repositório, quais princípios de boas práticas orientam a suíte oficial, qual convenção executável passa a ser o padrão oficial, quando exceções são permitidas e como a suíte obrigatória deve ser executada localmente e em toda PR.

**Motivação:** Hoje o repositório já possui testes executáveis reais, porém em formatos e pontos de entrada heterogêneos: `tests/bootstrap/issue-template-parity.bats` e `tests/bootstrap/no-public-github-urls.bats` usam Bats; `tests/docs/security-baseline-checklist.test.sh` e `tests/docs/security-baseline-tokens.test.sh` usam scripts shell executáveis; `tests/scripts/security-compliance-scan.*.test.sh` e `tests/workflows/security-compliance-scan.*.test.sh` seguem o mesmo padrão shell. Ao mesmo tempo, os workflows de CI atuais (`validate-manifests.yml`, `graph-guard.yml`, `dependency-review.yml`, `validate-issue-template-parity.yml` e outros correlatos) validam preocupações isoladas, mas não há um workflow único que invoque automaticamente a suíte existente em `tests/` a cada PR. O resultado é um gap de governança: a cobertura já existe, mas depende de memória manual e não de um gate obrigatório e consolidado.

**Critério de done (alto nível):** Existe uma política oficial que (1) inventaria e classifica toda a suíte atual, (2) explicita os princípios de boa prática que a suíte do bundle deve seguir, (3) compara as opções de formato executável viáveis para este repositório e recomenda um padrão principal com critérios de exceção, (4) define o gate obrigatório de testes para toda PR e (5) deixa claro como qualquer contribuidor executa a mesma validação antes de abrir a PR.

## Nimbus-Code — Hybrid Collaboration Model

| Papel | Responsabilidades | Critério de handoff | Escalação |
|---|---|---|---|
| Agente | Levantar a suíte atual e os gaps reais de CI; rascunhar a política com taxonomia, matriz comparativa das opções de formato e proposta inicial de gate obrigatório; transformar o inventário em critérios verificáveis para futura implementação | O agente entrega uma proposta completa quando a política já deixa explícitos padrão principal, exceções, cobertura mínima da suíte e impacto esperado no fluxo de PR | Tech lead / maintainers do bundle |
| Humano | Validar a recomendação final de padrão executável, aprovar trade-offs de ergonomia vs. simplicidade, decidir exceções permanentes e arbitrar mudanças que afetem a experiência de contribuição ou o tempo aceitável do gate | A revisão humana encerra quando a política aprovada puder ser usada como fonte de verdade para `/speckit-plan` sem novas ambiguidades | Tech lead / architecture board |

> O agente consolida evidências e propõe a política; o humano decide o padrão
> definitivo e o nível de rigidez de governança aplicado ao repositório.

## Nimbus-Code — Critérios de Aceitação (formato BDD)

> **AC-1**
> **Given** que o repositório já possui testes executáveis distribuídos entre `tests/bootstrap/`, `tests/docs/`, `tests/scripts/` e `tests/workflows/`,
> **When** a política de testes for consultada,
> **Then** ela inventaria explicitamente esses grupos existentes, identifica o propósito de cada um e registra de forma inequívoca que nenhum workflow atual de PR executa a suíte completa de `tests/` automaticamente.
> **Test ref:** `test_AC1_inventario_e_gap_atual`

> **AC-2**
> **Given** que o bundle precisa deixar de depender de convenções ad-hoc,
> **When** um mantenedor consultar a política para decidir como escrever um novo teste,
> **Then** encontrará uma comparação explícita entre as opções viáveis para este repositório, a recomendação de um formato principal, os prós e contras de cada alternativa avaliada e os critérios objetivos para uso de exceções.
> **Test ref:** `test_AC2_matriz_de_decisao`

> **AC-3**
> **Given** qualquer pull request aberta contra `main`,
> **When** o gate obrigatório de testes for executado,
> **Then** toda a suíte mandatória definida pela política roda de forma consolidada e o merge fica bloqueado se qualquer teste obrigatório falhar.
> **Test ref:** `test_AC3_gate_obrigatorio_em_pr`

> **AC-4**
> **Given** um contribuidor preparando alterações localmente,
> **When** ele seguir a documentação oficial de testes desta feature,
> **Then** conseguirá descobrir um único caminho oficial para rodar a mesma validação mandatória exigida em PR, sem depender de lembrar manualmente quais arquivos de teste existem.
> **Test ref:** `test_AC4_execucao_local_paritaria`

> **AC-5**
> **Given** que o repositório contém testes de naturezas diferentes,
> **When** a política classificar a suíte,
> **Then** ela define de forma testável o que conta como teste unitário, de integração e end-to-end neste bundle, bem como convenções mínimas de localização, nomenclatura e expectativa de cobertura para cada categoria.
> **Test ref:** `test_AC5_taxonomia_de_testes`

> **AC-6**
> **Given** que alguém queira introduzir um novo formato executável de teste, ignorar o padrão oficial ou retirar uma suíte obrigatória do gate de PR,
> **When** a mudança for proposta,
> **Then** a política exige uma exceção explícita, com justificativa e aprovador definidos, em vez de permitir proliferação silenciosa de novos padrões.
> **Test ref:** `test_AC6_governanca_de_excecoes`

> **AC de governança para rollout/toggle**
> N/A — a feature trata de política interna de testes e gate de PR; não define
> rollout progressivo de software em produção.

---

## Nimbus-Code — Backlog Hierarchy (EPIC/FEATURE/US)

| Nível | Valor | Observação |
|---|---|---|
| **EPIC** | Governança de Qualidade e Confiabilidade do Bundle Nimbus-Code | Tema macro de padronização de qualidade do próprio template, incluindo validações automatizadas, contratos e guardrails de contribuição |
| **FEATURE** | Governança de Testes em PR | Recorte desta entrega: padronização da política de testes executáveis + obrigatoriedade em toda PR |
| **US1** | Política e matriz de decisão de formatos | Define taxonomia, compara alternativas e escolhe o padrão principal |
| **US2** | Gate obrigatório de suíte completa em PR | Consolida a execução mandatória do que já existe em `tests/` |
| **US3** | Experiência local e manutenção futura | Garante descoberta simples, paridade local/CI e controle de exceções |

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Definir um padrão único de testes executáveis (Priority: P1)

Como **maintainer do bundle**, eu quero uma política que compare explicitamente
as opções de formato de teste compatíveis com este repositório e recomende um
padrão principal com exceções bem definidas, para que novas features não
continuem adicionando testes em formatos arbitrários.

**Why this priority**: Sem uma decisão explícita de padrão, o repositório
continua acumulando convenções paralelas e qualquer automação de PR nasce já
ambígua.

**Independent Test**: Ler apenas a política final e verificar se ela permite a
um mantenedor decidir, sem consulta externa, qual formato usar para um novo
teste e em que casos uma exceção ainda é aceitável.

**Acceptance Scenarios**:

1. **Given** que existem hoje testes em `.bats` e em `.test.sh`, **When** a
   política for publicada, **Then** ela compara explicitamente essas abordagens
   e documenta a recomendação final para o bundle.
2. **Given** que uma nova necessidade de teste surgir, **When** o autor consultar
   a política, **Then** ele consegue classificar o teste na categoria correta e
   escolher o formato permitido sem recorrer a convenção oral.

---

### User Story 2 — Tornar a suíte existente obrigatória em toda PR (Priority: P1)

Como **revisor de pull requests**, eu quero que toda PR receba um gate único e
obrigatório com a suíte de testes definida pela política, para que eu saiba se
o bundle continua íntegro sem depender de alguém lembrar de rodar verificações
manualmente.

**Why this priority**: É o principal gap operacional atual: testes já existem,
mas sua execução não está consolidada nem obrigatória no fluxo real de PR.

**Independent Test**: Abrir uma PR de exemplo e verificar que a decisão de
merge depende de um resultado consolidado de teste, não de memória manual nem
de workflows desconectados.

**Acceptance Scenarios**:

1. **Given** uma PR qualquer para `main`, **When** a validação obrigatória for
   acionada, **Then** a suíte mandatória completa roda e produz um resultado
   único, claro e bloqueante.
2. **Given** que um segmento da suíte falhou, **When** o gate reportar o erro,
   **Then** o revisor identifica qual grupo de testes falhou sem inspecionar
   vários workflows independentes.

---

### User Story 3 — Rodar localmente a mesma validação exigida em PR (Priority: P2)

Como **contribuidor do repositório**, eu quero descobrir rapidamente como rodar
localmente a mesma validação obrigatória da PR, para reduzir retrabalho e evitar
submeter mudanças sem saber qual é a barra mínima de qualidade.

**Why this priority**: Sem um caminho oficial de execução local, o gate em PR
vira caixa-preta e aumenta a fricção para contribuir.

**Independent Test**: Pedir a um contribuidor que ainda não conhece a suíte
atual para encontrar e executar o caminho oficial apenas com a documentação
produzida pela feature.

**Acceptance Scenarios**:

1. **Given** um clone limpo do repositório, **When** o contribuidor consultar a
   documentação oficial, **Then** ele encontra um único ponto de entrada para a
   validação mandatória.
2. **Given** que a política define a suíte mandatória, **When** ela for executada
   localmente, **Then** o conjunto validado corresponde ao mínimo exigido em PR.

---

### User Story 4 — Evitar nova fragmentação da suíte (Priority: P2)

Como **responsável por governança do template**, eu quero que a política trate
novos formatos ou bypasses como exceção aprovada, para que a padronização não
se deteriore logo após a adoção.

**Why this priority**: O problema atual nasceu justamente da ausência de regra
de entrada para novas suites; sem governança, o padrão volta a divergir.

**Independent Test**: Avaliar uma proposta de novo teste fora do padrão e
verificar se a política exige justificativa e decisão explícita antes da adoção.

**Acceptance Scenarios**:

1. **Given** uma proposta de teste em formato não previsto, **When** o autor a
   submeter, **Then** a política exige justificativa, aprovador e tratamento da
   exceção antes de aceitar o novo padrão.
2. **Given** uma proposta para retirar um grupo da suíte obrigatória, **When** a
   mudança for analisada, **Then** a política exige motivo explícito e definição
   de impacto na cobertura de PR.

### Edge Cases

- O que acontece se uma PR alterar apenas documentação ou metadados, mas ainda
  assim puder quebrar contratos do bundle? A política deve deixar claro se o
  gate completo continua obrigatório mesmo nesses casos, para evitar falsos
  "atalhos seguros".
- O que acontece se um teste depender de credenciais reais, APIs externas ou
  estado de organização? A política deve separá-lo do caminho mandatório de PR
  ou exigir forma hermética equivalente, para não transformar o gate em processo
  frágil ou impossível de reproduzir.
- O que acontece se um grupo de testes ficar lento demais para ser executado em
  toda PR? A política deve definir o limite aceitável de tempo e o processo para
  reclassificar a suíte sem reduzir cobertura silenciosamente.
- O que acontece com testes legados que não se encaixarem no padrão escolhido?
  A política deve defini-los como migração explícita, exceção temporária ou
  remoção planejada — nunca deixar o status indefinido.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A feature DEVE produzir um inventário explícito dos testes
  executáveis já existentes em `tests/bootstrap/`, `tests/docs/`,
  `tests/scripts/` e `tests/workflows/`, incluindo o propósito de cada grupo e
  sua classificação inicial na taxonomia oficial.
- **FR-002**: A feature DEVE registrar que os workflows atuais de CI validam
  preocupações pontuais, mas não executam automaticamente a suíte completa de
  `tests/` em toda PR.
- **FR-003**: A política DEVE comparar, no mínimo, as duas abordagens hoje já
  presentes no repositório e pelo menos uma terceira alternativa plausível para
  este tipo de bundle, descrevendo prós, contras e critérios de decisão.
- **FR-003a**: A política DEVE declarar explicitamente os princípios de boa
  prática esperados para testes deste bundle, incluindo reprodutibilidade,
  baixa dependência de ambiente externo, falhas legíveis e descoberta simples
  da suíte mandatória.
- **FR-004**: A política DEVE recomendar um formato executável principal para
  novos testes do bundle e definir em que circunstâncias um formato alternativo
  ainda pode ser aceito como exceção aprovada.
- **FR-005**: A política DEVE definir o que conta como teste unitário, de
  integração e end-to-end neste repositório, incluindo a fronteira entre essas
  categorias para scripts, workflows, presets e documentação validável.
- **FR-006**: A política DEVE definir convenções mínimas de localização,
  nomenclatura e descoberta para cada categoria de teste aceita no bundle.
- **FR-007**: O processo alvo DEVE exigir um gate obrigatório de PR que execute,
  de forma consolidada, toda a suíte mandatória definida pela política.
- **FR-008**: O processo alvo DEVE oferecer um caminho oficial e documentado
  para executar localmente a mesma validação mínima exigida em PR.
- **FR-009**: A política DEVE impedir a introdução de novos formatos ad-hoc,
  bypasses silenciosos do gate ou testes sem classificação declarada, exigindo
  justificativa e aprovação explícitas para exceções.
- **FR-010**: A política DEVE definir como tratar testes legados que não
  coincidirem com o padrão principal: migração planejada, exceção temporária ou
  remoção justificada.
- **FR-011**: O resultado do gate obrigatório DEVE permitir identificar, na
  primeira leitura, qual segmento da suíte falhou, para reduzir tempo de triagem.
- **FR-012**: A política DEVE deixar explícito que a validação mandatória não
  pode depender de memória manual do revisor ou do autor da PR para lembrar
  quais testes executar.

### Key Entities

- **Test Policy**: Documento normativo da feature que define taxonomia, padrão
  principal, exceções permitidas e expectativas de execução em PR/local.
- **Test Category**: Classificação oficial de um teste no bundle
  (unitário, integração ou end-to-end), com critérios claros de enquadramento.
- **Test Entry Point**: Forma oficial de descoberta e execução de um conjunto
  de testes, tanto localmente quanto no gate de PR.
- **Mandatory PR Gate**: Resultado consolidado que informa se a suíte mínima
  obrigatória passou ou falhou para uma PR.
- **Exception Record**: Registro explícito de um desvio autorizado do padrão de
  testes, com justificativa, duração esperada e aprovador.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% das PRs abertas contra `main` passam a receber um resultado
  obrigatório de validação para a suíte mandatória antes de serem consideradas
  aptas a merge.
- **SC-002**: 100% dos testes executáveis já existentes sob `tests/` ficam
  mapeados para uma categoria oficial e para um status declarado
  (mandatório, exceção temporária ou fora de escopo justificado).
- **SC-003**: Um contribuidor consegue identificar o caminho oficial de
  execução local da validação mandatória em até 5 minutos de leitura da
  documentação do repositório.
- **SC-004**: Após a adoção da política, 0 novas PRs aprovadas introduzem
  formatos executáveis de teste fora do padrão sem exceção documentada.
- **SC-005**: 100% dos gates obrigatórios falhos informam, na primeira saída,
  qual segmento da suíte precisa de atenção, reduzindo o tempo de triagem do
  revisor para no máximo 10 minutos.

---

## Assumptions

- O escopo desta feature é o bundle/template em si — scripts, workflows,
  presets, documentação e contratos versionados — e não testes de interface web
  tradicional ou ambientes de produção.
- A suíte atual em `tests/` é o ponto de partida obrigatório da política; a
  feature não pressupõe descartar esses testes existentes antes de classificá-los.
- O gate mandatório de PR deve priorizar execução reproduzível e segura em CI;
  testes dependentes de credenciais reais, rede externa ou estado organizacional
  não entram no caminho padrão sem tratamento explícito.
- Workflows pontuais já existentes podem continuar coexistindo se ainda
  agregarem valor especializado, mas deixam de ser substituto para o gate único
  de suíte completa.
- A feature busca padronizar a governança de testes do repositório inteiro; ela
  não depende de escolher uma stack de aplicação web nem de introduzir
  infraestrutura externa de teste.
