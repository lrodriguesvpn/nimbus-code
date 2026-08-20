# Feature Specification: Loop de Melhoria Contínua Nimbus-Code — Playbooks de Sucesso, Retrospectiva e Métricas DORA

**Feature Branch**: `012-loop-melhoria-continua`

**Created**: 2026-08-20

**Status**: Draft

**Input**: Fechar o ciclo de aprendizado organizacional do Nimbus-Code: hoje o
Harness Engineering (feature 011, recém-recuperada de um branch órfão) só
captura **erros** (o que deu errado). Esta feature adiciona o lado que falta —
capturar **o que deu certo** e transformar em playbook reutilizável — mais uma
cadência de revisão de métricas de processo (DORA) e retrospectiva que não
dependa de algo já ter dado errado para acontecer. Tudo isso preservando o
princípio já vigente de **Modelo Híbrido** (agente + humano) como forma de
colaboração, não como automação sozinha nem como processo 100% manual.

---

## Nimbus-Code — Cabeçalho Obrigatório da Spec

| Campo | Valor |
|---|---|
| **Feature slug** | `012-loop-melhoria-continua` |
| **Complexidade estimada** | **S3** *(cruza múltiplos módulos: `docs/harness/` — extensão —, novo `docs/playbooks/`, constituição, `plan-template.md`, `tasks-template.md`, labels, e a cadência de revisão de métricas DORA já rotuladas mas nunca revisadas)* |
| **Bounded Context** | `spec-kit-workflow` *(registrado em `docs/bounded-contexts.yaml` — mesmo bounded context de outras features meta do próprio Spec Kit, ex.: 001, 005-epic-feature-us-ghe-hierarchy, 011-harness-engineering)* |
| **PR de referência / Issue** | novo |
| **Data alvo de entrega** | sem data |

> S0 = doc · S1 = função isolada · S2 = módulo · S3 = múltiplos módulos ·
> S4 = arquitetura, segurança, dados ou integração crítica

## Nimbus-Code — SLO Alvo desta Feature

| Componente | Latência p99 (ms) | Taxa de erro máx. (%) | Disponibilidade alvo | RTO | RPO |
|---|---|---|---|---|---|
| `docs/playbooks/success-catalog.yaml` (leitura) | — | 0% (arquivo estático) | — | — | — |
| `scripts/process-metrics-report.sh` (cálculo de DORA a partir de labels) | < 10s | 0% (idempotente, somente leitura via `gh api`) | — | — | — |

> Componentes são arquivos estáticos e um script CLI de relatório local — sem
> SLO de disponibilidade mensurável (mesmo racional já usado em
> `specs/011-harness-engineering/spec.md`).

## Nimbus-Code — Objetivo e Contexto

**Objetivo:** Fechar o ciclo de aprendizado organizacional do Nimbus-Code com
três mecanismos complementares ao Harness Engineering (que só cobre erros):

1. **Playbook de Sucesso** (`docs/playbooks/success-catalog.yaml`) — catálogo
   irmão do `harness-catalog.yaml`, mas para capturar decisões, padrões e
   abordagens que **funcionaram bem** e merecem ser repetidos (não apenas
   evitados). Mesma disciplina de curadoria manual/curatorial do catálogo de
   reuso (feature 001) e do harness (feature 011).
2. **Cadência de revisão de métricas de processo (DORA)** — os labels
   `dora:deployment-frequency`, `dora:lead-time`, `dora:change-failure-rate`
   e `dora:mttr` já existem e já são aplicados a issues/PRs desde a feature
   001/002, mas **nunca são efetivamente calculados nem revisados** — viram
   apenas metadado passivo. Esta feature adiciona um script de relatório e
   uma cadência periódica (não reativa) de revisão com meta e ação de melhoria
   registrada.
3. **Retrospectiva proativa** — o `retro-template.md` já existe, mas hoje só
   é acionado **quando algo divergiu do plano** (reativo). Esta feature
   adiciona uma cadência fixa (ex.: a cada N features concluídas) que não
   depende de nada ter dado errado — capturando também o que deu certo o
   suficiente para virar playbook.

**Motivação:** O Harness Engineering (011) resolve "não repetir o erro", mas
uma organização que só olha para falhas tem um viés de sobrevivência: decisões
boas que funcionaram por sorte ou por um contexto específico nunca são
revisitadas, e a métrica de processo (DORA) fica bonita no papel (label
aplicado) sem nunca virar sinal real de melhoria. Esta feature completa o
ciclo: aprender com o que deu errado **e** com o que deu certo, numa cadência
que não depende de incidente para acontecer — sempre com o Modelo Híbrido
(agente propõe/coleta, humano valida/decide) como forma de execução, nunca
substituindo o julgamento humano por automação silenciosa.

**Critério de done (alto nível):** `docs/playbooks/success-catalog.yaml`
existe e tem entradas de exemplo; `scripts/process-metrics-report.sh` calcula
os 4 indicadores DORA a partir dos labels já aplicados no GHE; a cadência de
revisão (DORA + retro proativa) está documentada com dono e periodicidade
definidos; o `plan-template.md` referencia o playbook de sucesso ao lado do
Harness Gate; e o checklist de fechamento do `tasks.md` passa a perguntar
também "o que deu certo aqui que vale a pena repetir?", não só "o que deu
errado".

## Nimbus-Code — Hybrid Collaboration Model

| Papel | Responsabilidades | Critério de handoff | Escalação |
|---|---|---|---|
| Agente | Calcular os 4 indicadores DORA a partir dos labels via `scripts/process-metrics-report.sh`; propor rascunho de entrada no `success-catalog.yaml` ao fechar uma feature com sinal de sucesso (ex.: zero retrabalho, entregue abaixo da estimativa, reuso comprovado do catálogo); lembrar a cadência de retrospectiva quando o contador de features desde a última rodar | Toda entrada de playbook e toda meta/ação de melhoria de DORA precisa de validação humana antes de virar registro definitivo — o agente nunca fecha o ciclo sozinho | Tech lead |
| Humano | Validar/editar o rascunho de playbook proposto pelo agente; definir a meta de cada indicador DORA e a ação de melhoria quando a meta não é atingida; conduzir a retrospectiva periódica (o agente prepara os dados, o humano facilita a conversa) | Quando o rascunho do agente estiver claro o suficiente para decisão — geralmente na mesma sessão em que a feature foi fechada | Tech lead / product owner |

> Este modelo reforça o princípio já vigente de Modelo Híbrido (ver
> `docs/ai-code-quality-and-observability.md` seção 8): o agente reduz o
> custo de **coletar e lembrar**, o humano mantém o julgamento sobre **o que
> significa** e **o que fazer a respeito**.

## Nimbus-Code — Critérios de Aceitação (formato BDD)

> **AC-1**
> **Given** que uma feature foi concluída com sinal de sucesso (ex.: zero
> retrabalho, entrega dentro ou abaixo da estimativa de tokens/horas, ou reuso
> comprovado de uma entrada do `docs/reuse-catalog.yaml`),
> **When** o checklist de fechamento do `tasks.md` é executado,
> **Then** existe um passo explícito perguntando "o que deu certo aqui que
> vale a pena repetir?" e, se houver resposta, um rascunho de entrada é
> proposto em `docs/playbooks/success-catalog.yaml` para validação humana.
> **Test ref:** `test_AC1_success_catalog_checklist`

> **AC-2**
> **Given** que `scripts/process-metrics-report.sh` é executado num repositório
> com issues/PRs rotulados com `dora:*`,
> **When** o script termina,
> **Then** ele imprime os 4 indicadores DORA (deployment frequency, lead time,
> change failure rate, MTTR) calculados a partir dos labels e datas das
> issues/PRs, sem exigir nenhuma ferramenta externa de observabilidade.
> **Test ref:** `test_AC2_dora_metrics_calculadas`

> **AC-3**
> **Given** que uma cadência de revisão de métricas de processo está definida
> (ex.: mensal),
> **When** o ciclo se completa,
> **Then** existe um registro (Issue ou entrada em documento) com os 4
> indicadores DORA do período, a meta de cada um, e — quando a meta não foi
> atingida — uma ação de melhoria explícita com dono e prazo.
> **Test ref:** `test_AC3_revisao_periodica_dora`

> **AC-4**
> **Given** que N features foram concluídas desde a última retrospectiva
> (N definido no `plan.md` desta feature),
> **When** o contador atinge N,
> **Then** o agente sinaliza proativamente que uma retrospectiva está devida —
> sem esperar por uma divergência de plano ou incidente para isso acontecer.
> **Test ref:** `test_AC4_retro_proativa_por_cadencia`

> **AC-5**
> **Given** que o `plan-template.md` já tem a seção "Harness Gate" (feature 011),
> **When** um novo `plan.md` é gerado,
> **Then** ele também contém uma seção "Playbook de Sucesso Gate" análoga,
> consultando `docs/playbooks/success-catalog.yaml` por padrões reaplicáveis
> — mesmo nível de obrigatoriedade do Harness Gate (nunca deixar em branco).
> **Test ref:** `test_AC5_playbook_gate_no_plan`

> **AC de governança para rollout/toggle**
> N/A — nenhuma feature de rollout progressivo/toggle está envolvida (mudança
> de convenção/documentação e um script de relatório local, sem componente em
> produção com ativação gradual).

---

## Nimbus-Code — Backlog Hierarchy (EPIC/FEATURE/US)

| Nível | Valor | Observação |
|---|---|---|
| **EPIC** | Governança e Aprendizado Organizacional do Nimbus-Code | Tema macro que também abrange a feature 001 (Catálogo de Reuso) e a 011 (Harness Engineering) — as três compõem o mesmo eixo de "memória organizacional" |
| **FEATURE** | Loop de Melhoria Contínua (esta spec) | Entrega única, sem sub-features previstas nesta fase |
| **US1** | Playbook de Sucesso | Capturar e reaproveitar o que deu certo (AC-1, AC-5) |
| **US2** | Métricas de Processo (DORA) sob demanda e em cadência | Calcular e revisar periodicamente os 4 indicadores DORA (AC-2, AC-3) |
| **US3** | Retrospectiva Proativa | Cadência de retrospectiva que não depende de incidente (AC-4) |

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Capturar um Playbook de Sucesso (Priority: P1)

Como **tech lead que acabou de fechar uma feature que saiu muito bem**, eu
quero que o agente me pergunte explicitamente "o que deu certo aqui?" no
checklist de fechamento, para que essa decisão/abordagem fique registrada e
outras features possam reaproveitá-la — em vez de o conhecimento morrer na
memória de quem participou.

**Why this priority**: É o núcleo desta feature — sem ele, o "aprender com o
que deu certo" continua sem mecanismo, exatamente o gap que motivou a spec.

**Independent Test**: Fechar uma feature de exemplo com um sinal de sucesso
claro (ex.: zero retrabalho) e confirmar que o checklist de `tasks.md` pergunta
sobre isso e que uma entrada aparece em `docs/playbooks/success-catalog.yaml`
após validação humana.

**Acceptance Scenarios**:

1. **Given** que uma feature foi concluída sem nenhuma task revertida ou
   retrabalhada, **When** o checklist de fechamento é executado, **Then** o
   agente propõe um rascunho de entrada de playbook citando o padrão que
   funcionou bem.
2. **Given** que o rascunho foi proposto, **When** o humano revisa, **Then**
   ele pode aprovar (a entrada é gravada), editar (a entrada gravada reflete
   a versão editada) ou descartar (nada é gravado) — a decisão final é sempre
   humana.

---

### User Story 2 — Calcular e Revisar Métricas DORA em Cadência (Priority: P1)

Como **tech lead**, eu quero um script que calcule os 4 indicadores DORA a
partir dos labels `dora:*` já aplicados, e uma cadência definida para revisar
esses números com metas, para que "medir performance de entrega" pare de ser
só um label decorativo e vire sinal real de melhoria de processo.

**Why this priority**: Sem isso, os labels DORA já existentes (desde a feature
002) continuam sendo esforço sem retorno — aplicados, nunca lidos de volta.

**Independent Test**: Rodar `scripts/process-metrics-report.sh` num
repositório com histórico de issues/PRs rotulados com `dora:*` e confirmar que
os 4 indicadores são impressos corretamente, comparáveis a uma meta definida.

**Acceptance Scenarios**:

1. **Given** que existem PRs mergeados com labels `dora:deployment-frequency`,
   **When** o script é executado, **Then** ele reporta a frequência de deploy
   do período analisado.
2. **Given** que existe uma meta definida para cada indicador, **When** a
   revisão periódica acontece, **Then** cada indicador é comparado à meta e,
   se abaixo, uma ação de melhoria é registrada com dono e prazo.

---

### User Story 3 — Retrospectiva Proativa por Cadência (Priority: P2)

Como **time usando o Nimbus-Code**, eu quero que uma retrospectiva seja
sinalizada automaticamente a cada N features concluídas — não apenas quando
algo deu errado — para que a melhoria de processo aconteça mesmo quando tudo
"parece" estar indo bem.

**Why this priority**: Complementa US1/US2 fechando o ciclo — sem uma cadência
proativa, a retrospectiva continua dependendo de um gatilho negativo
(divergência/incidente), perdendo os ciclos "silenciosamente bons" que também
têm o que ensinar.

**Independent Test**: Simular N features concluídas em sequência e confirmar
que o agente sinaliza a retrospectiva devida no fechamento da N-ésima, mesmo
sem nenhuma divergência de plano registrada.

**Acceptance Scenarios**:

1. **Given** que N features foram concluídas desde a última retrospectiva
   registrada, **When** a N-ésima é fechada, **Then** o agente sinaliza
   proativamente que uma retrospectiva está devida, referenciando
   `retro-template.md`.
2. **Given** que a retrospectiva proativa acontece, **When** ela é concluída,
   **Then** tanto aprendizados de erro (harness) quanto de sucesso (playbook)
   identificados na conversa são registrados nos catálogos correspondentes.

### Edge Cases

- O que acontece se nenhum sinal de sucesso claro existir ao fechar uma
  feature (nem bom nem ruim, só "normal")? O checklist permite declarar
  explicitamente "Nada relevante a registrar" — nunca fica em branco, mesmo
  princípio já usado no Harness Gate (feature 011).
- O que acontece se o repositório não tiver histórico suficiente de PRs
  rotulados com `dora:*` para calcular um indicador (ex.: repositório novo)?
  O script reporta "dados insuficientes" para aquele indicador específico, em
  vez de falhar ou inventar um número.
- O que acontece se a cadência de retrospectiva "atrasar" (ex.: ninguém rodou
  o comando por várias features)? O agente sinaliza o atraso acumulado na
  próxima interação, sem se tornar bloqueante — a decisão de quando
  efetivamente parar para retrospectiva continua sendo humana.
- Qual a diferença entre esta feature e o Harness Engineering (011)? Harness
  cataloga **erros** (o que evitar); esta feature cataloga **sucessos** (o que
  repetir) e adiciona a camada de métricas/cadência que nenhuma das duas
  tinha antes. Os dois catálogos são irmãos, não duplicatas.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema DEVE fornecer um catálogo estruturado
  (`docs/playbooks/success-catalog.yaml`) para registrar padrões/decisões
  bem-sucedidas, com schema análogo ao `harness-catalog.yaml` da feature 011
  (id, data, complexidade, bounded_context, o que funcionou, por que, como
  reaplicar, tags, PR de origem).
- **FR-002**: O checklist de fechamento em `tasks-template.md` DEVE incluir um
  passo explícito perguntando se há um sinal de sucesso digno de virar
  playbook — nunca deixado implícito ou opcional silencioso.
- **FR-003**: O sistema DEVE fornecer um script
  (`scripts/process-metrics-report.sh`) que calcule os 4 indicadores DORA
  (deployment frequency, lead time for changes, change failure rate, MTTR) a
  partir de labels `dora:*` já aplicados a issues/PRs via `gh api`, sem exigir
  ferramenta externa de observabilidade.
- **FR-004**: O processo DEVE definir uma cadência de revisão periódica (ex.:
  mensal) dos indicadores DORA, com meta por indicador e ação de melhoria
  obrigatória registrada quando a meta não é atingida.
- **FR-005**: O processo DEVE sinalizar proativamente quando uma
  retrospectiva estiver devida por cadência de número de features concluídas
  — não apenas de forma reativa a divergências (comportamento já existente,
  reaproveitado do `retro-template.md`/checklist do `tasks-template.md`).
- **FR-006**: O `plan-template.md` DEVE incluir uma seção "Playbook de Sucesso
  Gate", espelhando a obrigatoriedade já aplicada ao "Harness Gate" da feature
  011 (nunca deixar em branco: match encontrado, nenhum match relevante, ou
  catálogo vazio).
- **FR-007**: Toda entrada nova em `success-catalog.yaml` e toda meta/ação de
  melhoria de DORA DEVE passar por validação humana explícita antes de virar
  registro definitivo — o agente propõe, nunca fecha o ciclo sozinho
  (princípio de Modelo Híbrido).
- **FR-008**: `docs/reuse-catalog.yaml` DEVE ganhar uma entrada referenciando
  o padrão introduzido por esta feature, para que futuras features encontrem
  o mecanismo por ponteiro em vez de recriá-lo.

### Key Entities

- **Success Catalog Entry**: Registro estruturado de um padrão/decisão que
  funcionou bem — id, data, bounded_context, o que funcionou, por que, como
  reaplicar, tags, feature/PR de origem.
- **DORA Metrics Report**: Saída do `process-metrics-report.sh` — os 4
  indicadores calculados para um período, junto da meta definida (quando
  houver) e do resultado da comparação.
- **Retro Cadence Counter**: Contador de features concluídas desde a última
  retrospectiva registrada, usado para disparar o sinal proativo do FR-005.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Toda feature concluída a partir da adoção desta spec passa pelo
  checklist de "o que deu certo" — 100% de cobertura, mesmo quando a resposta
  é "nada relevante".
- **SC-002**: Os 4 indicadores DORA são calculáveis sob demanda em menos de
  10 segundos, sem dependência de ferramenta externa de observabilidade.
- **SC-003**: Uma cadência de revisão de métricas de processo existe e é
  seguida — validável perguntando "quando foi a última revisão de DORA?" e
  obtendo uma resposta dentro do período de cadência definido, não "nunca".
- **SC-004**: Uma retrospectiva proativa (não motivada por incidente/desvio)
  acontece ao menos uma vez por cada N features concluídas (N definido no
  `plan.md`).
- **SC-005**: `docs/playbooks/success-catalog.yaml` acumula ao menos 1 entrada
  validada por humano dentro do primeiro ciclo de cadência após a adoção
  desta feature — evidência de que o mecanismo está sendo usado de verdade,
  não só existindo no papel.

---

## Assumptions

- Os labels `dora:*` já existentes (features 001/002) continuam sendo
  aplicados manualmente pelo agente/dev nas issues/PRs relevantes — esta
  feature não automatiza a aplicação do label em si, só o cálculo/revisão a
  partir dele.
- O valor de N (features por ciclo de retrospectiva) é uma decisão de time,
  não uma constante fixa do bundle — será definido no `plan.md` desta feature
  com um valor inicial sugerido, ajustável por projeto.
- `docs/playbooks/success-catalog.yaml` reaproveita a mesma disciplina de
  curadoria manual/curatorial já validada por `docs/reuse-catalog.yaml`
  (feature 001) e `docs/harness/harness-catalog.yaml` (feature 011) — sem
  automação de preenchimento nesta fase.
- Esta feature não introduz nenhuma ferramenta de observabilidade externa
  (Grafana, Datadog etc.) — os indicadores DORA são calculados a partir de
  metadados já existentes no próprio GHE (labels, datas de merge/close),
  consistente com o escopo "sem infraestrutura adicional" já usado em
  features anteriores deste eixo (001, 011).
