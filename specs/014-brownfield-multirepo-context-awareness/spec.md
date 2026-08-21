# Feature Specification: Brownfield MultiRepo Context Awareness — Harvest Automático de Padrões e Grafo de Repositórios por Bounded Context

**Feature Branch**: `014-brownfield-multirepo-context-awareness`

**Created**: 2026-08-21

**Status**: Draft

**Input**: Em projetos brownfield multirepo, toda nova Spec precisa obrigatoriamente considerar os repositórios já existentes no Bounded Context — tanto para identificar padrões técnicos reutilizáveis (ex.: uso de interfaces Java entre backend e conectores) quanto para gerar o grafo de dependências entre os repos do contexto antes que qualquer plan ou task seja iniciado. Hoje o bundle tem a estrutura de dados (`reuse-catalog.yaml`, `bounded-contexts.yaml`, `graph.yaml`) mas não tem os scripts que as populam automaticamente. O resultado é que padrões existentes no código só são respeitados se o Dev colar exemplos explicitamente no prompt — caso contrário o agente pode propor soluções incompatíveis com o que já existe.

---

## Nimbus-Code — Cabeçalho Obrigatório da Spec

| Campo | Valor |
|---|---|
| **Feature slug** | `014-brownfield-multirepo-context-awareness` |
| **Complexidade estimada** | **S3** *(cruza múltiplos módulos do bundle — `bounded-contexts.yaml`, `reuse-catalog.yaml`, `graph.yaml`/`graph.md`, skills `speckit-specify` e `speckit-plan`, scripts de automação — e define nova etapa obrigatória no ciclo specify→plan que não existe hoje)* |
| **Bounded Context** | `spec-kit-workflow` |
| **PR de referência / Issue** | novo |
| **Data alvo de entrega** | sem data |

> S0 = doc · S1 = função isolada · S2 = módulo · S3 = múltiplos módulos ·
> S4 = arquitetura, segurança, dados ou integração crítica

---

## Nimbus-Code — SLO Alvo desta Feature

| Componente | Latência p99 (ms) | Taxa de erro máx. (%) | Disponibilidade alvo | RTO | RPO |
|---|---|---|---|---|---|
| `scripts/harvest-patterns.sh` (harvest de um repo) | — | 0% de saída sem conteúdo quando repo possui código elegível | — | — | — |
| `scripts/generate-context-graph.sh` (grafo de um bounded context) | — | 0% de grafo vazio quando `bounded-contexts.yaml` possui ≥2 repos no contexto | — | — | — |
| Gate de grafo em `/speckit-specify` | — | 0% de specs abertas sem `graph.yaml` quando `bounded-contexts.yaml` tem o contexto mapeado | — | — | — |

> Os três componentes são automações de CLI / CI sem SLA contratual exposto ao usuário final.
> Os critérios de erro são binários: o artefato é gerado ou não — não há latência de usuário mensurável.

---

## Nimbus-Code — Objetivo e Contexto

**Objetivo:** Criar dois scripts de automação (`harvest-patterns.sh` e `generate-context-graph.sh`) e integrá-los ao workflow `/speckit-specify` do bundle, garantindo que toda nova Spec gerada em contexto brownfield multirepo: (1) já tenha o grafo de dependências dos repositórios do Bounded Context disponível antes do plan, e (2) tenha os padrões técnicos reutilizáveis dos repos existentes refletidos no `reuse-catalog.yaml` antes que qualquer agente comece a propor soluções.

**Motivação:** Hoje o gap é estrutural: o bundle exige que `graph.yaml` exista antes de `plan.md` (regra do Graph Guard), mas não fornece nenhum mecanismo para gerá-lo automaticamente a partir dos repos declarados em `bounded-contexts.yaml`. Da mesma forma, o `reuse-catalog.yaml` é preenchido manualmente e só cresce quando um Dev disciplinado adiciona entradas ao fechar uma feature. Em projetos brownfield com dezenas de repos, padrões críticos de código — como o uso de interfaces Java entre backend e conectores — ficam invisíveis ao agente porque nunca foram catalogados. O agente então propõe soluções funcionalmente corretas mas arquiteturalmente inconsistentes com o que o time já estabeleceu.

**Critério de done (alto nível):** Dado um `bounded-contexts.yaml` com repos mapeados, qualquer execução de `/speckit-specify` para um contexto brownfield: (1) gera automaticamente `specs/<feature>/graph.yaml` e `graph.md` refletindo as dependências entre repos do contexto, e (2) o `reuse-catalog.yaml` pode ser atualizado pelo script de harvest apontado a qualquer repo do contexto, sem depender de preenchimento manual.

---

## Nimbus-Code — Hybrid Collaboration Model

| Papel | Responsabilidades | Critério de handoff | Escalação |
|---|---|---|---|
| Agente | Implementar os dois scripts (`harvest-patterns.sh` e `generate-context-graph.sh`), integrar a chamada ao `/speckit-specify`, atualizar `copilot-instructions.md` e `plan-template.md` para refletir o novo passo obrigatório | O agente entrega quando os scripts estão funcionando com repos de teste e a integração ao `speckit-specify` está documentada e com gate de CI verde | Tech lead do bundle |
| Humano | Validar que a saída do harvest faz sentido semanticamente para o domínio do projeto brownfield real; aprovar o formato de saída do `graph.yaml`; decidir se o harvest IA deve rodar em CI ou apenas on-demand | A revisão humana encerra quando o formato de saída dos dois scripts foi aprovado e a integração no fluxo de Spec não quebra o workflow existente | Tech lead / architecture board |

---

## Nimbus-Code — Critérios de Aceitação (formato BDD)

> **AC-1**
> **Given** que `docs/bounded-contexts.yaml` possui ao menos dois repos registrados no mesmo bounded context,
> **When** o script `generate-context-graph.sh <context-slug>` for executado,
> **Then** ele gera `specs/<feature>/graph.yaml` com os nós (um por repo) e as arestas (dependências inferidas dos arquivos de manifesto: `pom.xml`, `package.json`, `go.mod`, `requirements.txt`) e gera `specs/<feature>/graph.md` com diagrama Mermaid correspondente.
> **Test ref:** `test_AC1_generate_context_graph_output`

> **AC-2**
> **Given** que `/speckit-specify` é executado para uma feature em um bounded context com repos mapeados,
> **When** o fluxo de especificação for iniciado,
> **Then** o script `generate-context-graph.sh` é invocado automaticamente antes da abertura do template `spec.md`, e o caminho `specs/<feature>/graph.yaml` já existe quando o agente preenche o cabeçalho da spec.
> **Test ref:** `test_AC2_speckit_specify_triggers_graph`

> **AC-3**
> **Given** que um repo brownfield com código Java está declarado em `bounded-contexts.yaml`,
> **When** o script `harvest-patterns.sh <repo-path>` for executado apontado para esse repo,
> **Then** ele produz uma ou mais entradas no formato `reuse-catalog.yaml` identificando padrões estruturais recorrentes (ex.: uso de interfaces em pacotes de domínio, anotações recorrentes, herança de classe base), com `tag`, `bounded_context`, `description`, `source` (arquivo:linha de exemplo) e `example` preenchidos.
> **Test ref:** `test_AC3_harvest_patterns_java_interfaces`

> **AC-4**
> **Given** que o harvest foi executado em ao menos um repo do contexto,
> **When** o agente iniciar o `/speckit-plan` para uma feature desse contexto,
> **Then** a consulta obrigatória ao `reuse-catalog.yaml` (definida no `copilot-instructions.md`) retorna ao menos uma entrada relevante ao domínio — sinalizando que o catálogo está populado antes do plan, não depois.
> **Test ref:** `test_AC4_catalog_populated_before_plan`

> **AC-5**
> **Given** que `bounded-contexts.yaml` não possui repos mapeados para o contexto declarado na spec,
> **When** `/speckit-specify` tentar gerar o grafo,
> **Then** o script falha com mensagem clara informando que o contexto não tem repos registrados e o fluxo de spec pode prosseguir sem o grafo (com aviso, não com bloqueio).
> **Test ref:** `test_AC5_graceful_fallback_no_repos`

> **AC-6**
> **Given** que o bundle rodando em CI não tem acesso de clone aos repos externos do bounded context,
> **When** o `generate-context-graph.sh` for executado em modo CI sem acesso aos repos,
> **Then** ele tenta ler os manifestos de dependências via GitHub API (usando `gh api`) como fallback, e documenta quais repos não puderam ser analisados sem encerrar o pipeline com erro.
> **Test ref:** `test_AC6_ci_api_fallback`

> **AC de governança**
> - O harvest de padrões IA (`harvest-patterns.sh`) DEVE ser executável on-demand pelo Dev e NÃO deve rodar automaticamente em toda PR (risco de custo de tokens em larga escala).
> - O grafo estático (`generate-context-graph.sh`) PODE rodar em CI a cada PR que altere `bounded-contexts.yaml`.

---

## Nimbus-Code — Backlog Hierarchy (EPIC/FEATURE/US)

| Nível | Valor | Observação |
|---|---|---|
| **EPIC** | Governança de Contexto em Projetos Brownfield MultiRepo | Tema macro de garantir que o agente sempre produza soluções consistentes com o código já existente nos repos do bounded context |
| **FEATURE** | Brownfield MultiRepo Context Awareness | Esta entrega: harvest automático de padrões + geração de grafo de repos por bounded context integrados ao `/speckit-specify` |
| **US1** | Script `generate-context-graph.sh` | Lê `bounded-contexts.yaml`, acessa manifestos de dependências e gera `graph.yaml` + `graph.md` por bounded context |
| **US2** | Script `harvest-patterns.sh` | Varre um repo de código e produz entradas para `reuse-catalog.yaml` identificando padrões reutilizáveis |
| **US3** | Integração ao `/speckit-specify` | Invoca `generate-context-graph.sh` automaticamente ao iniciar uma nova spec, garantindo que o grafo exista antes do plan |
| **US4** | Documentação e gates de uso | Atualiza `copilot-instructions.md`, `plan-template.md` e `docs/module-graphs.md` para refletir o novo passo obrigatório |

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Gerar grafo de repos do bounded context ao abrir nova Spec (Priority: P1)

Como **Dev em projeto brownfield multirepo**, eu quero que ao iniciar `/speckit-specify` o grafo de dependências entre os repositórios do bounded context seja gerado automaticamente, para que o agente que fará o `/speckit-plan` já saiba quais repos existem, como se relacionam e quais padrões técnicos compartilham.

**Why this priority**: Sem o grafo gerado antes do plan, o agente inicia o planejamento sem saber que outros repos existem no contexto — o que pode resultar em uma solução tecnicamente correta mas incompatível com a arquitetura brownfield já estabelecida (ex.: propor comunicação direta entre serviços quando o contexto já usa um message broker).

**Independent Test**: Dado um `bounded-contexts.yaml` com 3 repos mapeados num mesmo contexto, executar `generate-context-graph.sh context-slug` e verificar que `graph.yaml` contém 3 nós e que `graph.md` renderiza um diagrama Mermaid válido com as arestas de dependência.

**Acceptance Scenarios**:

1. **Given** dois repos no mesmo bounded context com dependências mútuas declaradas em `pom.xml`, **When** o script rodar, **Then** o `graph.yaml` reflete a direção correta das dependências (A→B, não B→A).
2. **Given** um repo sem arquivo de manifesto de dependências reconhecido, **When** o script rodar, **Then** ele registra o nó no grafo com arestas vazias e um aviso — não falha silenciosamente nem exclui o repo do grafo.

---

### User Story 2 — Harvest de padrões técnicos em repositórios existentes (Priority: P1)

Como **Tech Lead de projeto brownfield**, eu quero executar `harvest-patterns.sh` apontado para um repo existente e obter entradas prontas para inserir no `reuse-catalog.yaml`, para que o agente saiba, já no plan da próxima feature, que padrões como "usar interfaces Java em pontos de extensão" estão estabelecidos no código existente.

**Why this priority**: É a causa raiz do problema descrito: padrões técnicos críticos — que o time humano conhece de cor — são invisíveis ao agente porque nunca foram catalogados. Um único harvest inicial por repo pode eliminar esse gap para todas as features futuras.

**Independent Test**: Apontar `harvest-patterns.sh` para um repo Java com interfaces públicas em pacotes de domínio e verificar que a saída contém ao menos uma entrada com `tag` relacionada a interfaces/extensão, `source` apontando para um arquivo real do repo, e `description` que um Dev reconheceria como correto.

**Acceptance Scenarios**:

1. **Given** um repo Java com 5 interfaces em `domain/port/`, **When** o harvest rodar, **Then** ele gera ao menos uma entrada com `tag: java-port-interface` ou similar, com `source` apontando para um desses arquivos.
2. **Given** um repo Node.js com factories recorrentes, **When** o harvest rodar, **Then** ele identifica o padrão mesmo sem ser um projeto Java — o script é agnóstico à stack e adapta a detecção ao manifesto de stack encontrado.
3. **Given** um repo sem padrões estruturais recorrentes detectáveis, **When** o harvest rodar, **Then** ele informa explicitamente que nenhum padrão foi encontrado — não gera entradas vazias ou genéricas que polueriam o catálogo.

---

### User Story 3 — Integração transparente no fluxo `/speckit-specify` (Priority: P1)

Como **Dev usando o bundle no dia a dia**, eu quero que a geração do grafo aconteça automaticamente ao abrir uma nova spec, sem que eu precise lembrar de rodar um script separado, para que o processo Nimbus Code em projeto brownfield continue tendo a mesma ergonomia do projeto greenfield.

**Why this priority**: A automação só resolve o problema se ela for obrigatória e transparente. Se depender de o Dev lembrar de rodar o script, volta ao mesmo problema de dependência de memória manual que o bundle já identificou como antipadrão.

**Independent Test**: Executar `/speckit-specify` num projeto com `bounded-contexts.yaml` preenchido e verificar que `specs/<feature>/graph.yaml` existe e está preenchido antes de o template `spec.md` ser aberto para edição.

**Acceptance Scenarios**:

1. **Given** `bounded-contexts.yaml` com repos do contexto mapeados, **When** `/speckit-specify` rodar, **Then** o grafo é gerado sem nenhuma ação adicional do Dev além do comando normal de spec.
2. **Given** que o bounded context declarado na spec não existe em `bounded-contexts.yaml`, **When** `/speckit-specify` rodar, **Then** o fluxo emite um aviso de contexto não mapeado e prossegue sem bloquear — o Dev pode mapear o contexto depois.

---

### User Story 4 — Documentação e instrução ao agente para consultar grafo e catálogo antes do plan (Priority: P2)

Como **agente IA iniciando um `/speckit-plan`**, eu preciso de instruções explícitas no `copilot-instructions.md` e no `plan-template.md` para consultar tanto o `reuse-catalog.yaml` quanto o `graph.yaml` do contexto da feature antes de propor qualquer solução técnica, para que eu nunca derive uma arquitetura ignorando padrões já estabelecidos nos repos brownfield.

**Why this priority**: Mesmo com os scripts funcionando e os artefatos gerados, o agente só vai usá-los se for instruído explicitamente a fazê-lo no momento certo do fluxo. Sem a instrução, os artefatos ficam disponíveis mas ignorados.

**Independent Test**: Verificar que `copilot-instructions.md` tem um passo explícito de "consultar `graph.yaml` do contexto ativo antes de iniciar o plan" e que `plan-template.md` tem uma seção "Grafo do Contexto" que o agente deve preencher com o link para o `graph.yaml` gerado.

**Acceptance Scenarios**:

1. **Given** um agente iniciando um plan com `graph.yaml` disponível, **When** ele seguir as instruções do `copilot-instructions.md`, **Then** ele referencia o grafo no ADL do `plan.md` antes de propor qualquer decisão arquitetural que afete mais de um repo do contexto.
2. **Given** um agente iniciando um plan com entradas de harvest no `reuse-catalog.yaml` para o contexto, **When** ele seguir as instruções, **Then** ele declara na seção "Padrão reutilizado encontrado?" quais padrões do catálogo se aplicam à feature em andamento.

---

### Edge Cases

- O que acontece se dois repos do mesmo bounded context declaram dependência circular entre si (A→B e B→A)? O script deve representar o ciclo no grafo sem gerar loop infinito, e `graph.md` deve tornar o ciclo visível ao Dev.
- O que acontece se um repo tem o arquivo de manifesto de dependências corrompido ou com sintaxe inválida? O script deve registrar a falha de parse isoladamente para aquele repo sem abortar a geração do grafo dos demais.
- O que acontece se o repo não está acessível via clone no momento da geração do grafo (ex.: CI sem credenciais para repo privado)? O AC-6 cobre esse caso via fallback para GitHub API — o teste de edge case deve cobrir o cenário de API também indisponível.
- O que acontece se o harvest IA for executado em um repo muito grande (ex.: monorepo com 500k LOC)? O script deve permitir passar um path de subdiretório para limitar o escopo do harvest e documentar essa opção.
- O que acontece se uma entrada de harvest duplicar uma entrada já existente no `reuse-catalog.yaml`? O script deve detectar a tag duplicada e emitir aviso antes de inserir — nunca duplicar silenciosamente.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O script `generate-context-graph.sh <context-slug> [--feature <slug>]` DEVE ler `docs/bounded-contexts.yaml`, identificar os repos do contexto declarado, analisar os arquivos de manifesto de dependências de cada repo (prioridade: `pom.xml` → `package.json` → `go.mod` → `requirements.txt` → `build.gradle`) e gerar `specs/<feature>/graph.yaml` com nós e arestas.
- **FR-002**: O script `generate-context-graph.sh` DEVE gerar `specs/<feature>/graph.md` com diagrama Mermaid correspondente ao `graph.yaml` gerado, legível sem ferramentas externas (renderizável pelo GitHub).
- **FR-003**: O script `generate-context-graph.sh` DEVE aceitar os repos diretamente por clone local (quando disponíveis) ou via GitHub API (`gh api`) como fallback — e documentar claramente quais repos foram analisados localmente vs. via API.
- **FR-004**: O script `harvest-patterns.sh <repo-path> [--subpath <dir>] [--output <arquivo>]` DEVE analisar o código do repo/subpath informado e produzir entradas no formato `reuse-catalog.yaml` para padrões estruturais recorrentes encontrados, agnóstico à stack mas com detecção especializada para Java, Node.js, Go e Python.
- **FR-005**: O script `harvest-patterns.sh` DEVE identificar como padrões candidatos, no mínimo: interfaces/protocolos públicos em pacotes de domínio ou extensão, classes base abstratas com múltiplas implementações, anotações/decoradores recorrentes em mais de 30% dos arquivos de um pacote, e convenções de nomenclatura recorrentes em pontos de integração.
- **FR-006**: O script `harvest-patterns.sh` DEVE verificar duplicatas por `tag` antes de propor novas entradas ao `reuse-catalog.yaml` e emitir aviso quando uma tag já existe.
- **FR-007**: O skill `/speckit-specify` (`SKILL.md`) DEVE invocar `generate-context-graph.sh` automaticamente quando o bounded context declarado existir em `bounded-contexts.yaml` com ao menos um repo mapeado, antes de abrir o template `spec.md`.
- **FR-008**: O `copilot-instructions.md` DEVE incluir instrução explícita para o agente consultar `specs/<feature>/graph.yaml` e o `reuse-catalog.yaml` (filtrado pelo `bounded_context` ativo) antes de iniciar qualquer `/speckit-plan`.
- **FR-009**: O `plan-template.md` DEVE ter uma seção "Grafo do Contexto" onde o agente registra o link para o `graph.yaml` gerado e descreve as dependências relevantes para a feature em andamento.
- **FR-010**: Ambos os scripts DEVEM ser idempotentes: executar duas vezes com os mesmos inputs NÃO deve duplicar entradas no catálogo nem sobrescrever um grafo mais recente com um mais antigo.
- **FR-011**: O script `harvest-patterns.sh` NÃO DEVE ser adicionado a nenhum workflow de CI automático — ele é estritamente on-demand para evitar custo de tokens não controlado.
- **FR-012**: O script `generate-context-graph.sh` PODE ser adicionado a um workflow de CI que roda quando `bounded-contexts.yaml` é alterado, regenerando o grafo dos contextos afetados.

### Key Entities

- **Context Graph**: Grafo YAML + Mermaid que representa os repos de um bounded context como nós e suas dependências declaradas como arestas direcionadas.
- **Pattern Entry**: Entrada do `reuse-catalog.yaml` gerada automaticamente pelo harvest, com `tag`, `bounded_context`, `description`, `source` e `example`.
- **Harvest Run**: Execução do `harvest-patterns.sh` em um repo específico, produzindo candidatos de entrada para o catálogo — sujeita a revisão humana antes de merge.
- **Graph Refresh**: Execução do `generate-context-graph.sh` para um bounded context, podendo ser on-demand (Dev) ou automática (CI ao alterar `bounded-contexts.yaml`).

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% das novas specs abertas para bounded contexts com repos mapeados em `bounded-contexts.yaml` têm `specs/<feature>/graph.yaml` gerado automaticamente antes do plan.
- **SC-002**: Um Dev consegue executar `harvest-patterns.sh` em um repo brownfield e obter ao menos uma entrada candidata para `reuse-catalog.yaml` em uma única execução, sem precisar editar manualmente o YAML.
- **SC-003**: O `graph.md` gerado é renderizável pelo GitHub Markdown sem ferramentas externas e legível por um Dev que nunca viu o repo antes.
- **SC-004**: Após o harvest inicial de um repo com padrões conhecidos, o agente referencia ao menos um desses padrões no `plan.md` da próxima feature do mesmo bounded context — sem que o Dev precise colar o código de exemplo no prompt.
- **SC-005**: Ambos os scripts passam nos testes automatizados do bundle (`.test.sh` ou `.bats`) com 0 falhas de idempotência (execução dupla não produz output diferente).

---

## Assumptions

- Os repos declarados em `bounded-contexts.yaml` podem não estar disponíveis para clone local no ambiente do agente — o fallback via GitHub API é obrigatório para o `generate-context-graph.sh`.
- O harvest IA requer acesso de leitura ao código do repo — em repos privados, o `GITHUB_TOKEN` ou GitHub App com permissão de leitura deve estar disponível.
- A detecção de padrões pelo `harvest-patterns.sh` é heurística e nunca exaustiva — o Dev é responsável por revisar as entradas candidatas antes de fazer merge no `reuse-catalog.yaml`. O script não substitui revisão humana de padrões arquiteturais.
- Esta feature não resolve o problema de acesso de leitura ao código-fonte dos outros repos durante a execução do agente (quando ele está redigindo o plan ou as tasks) — ela resolve o problema de memória organizacional: cataloga o padrão antes, para que o agente o encontre no catálogo sem precisar acessar o repo em tempo real.
- A integração ao `/speckit-specify` depende da estrutura atual do `SKILL.md` do speckit-specify — qualquer mudança estrutural no skill deve ser feita de forma backward-compatible.
