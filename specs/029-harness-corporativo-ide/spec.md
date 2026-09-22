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
| **Feature slug** | `029-harness-corporativo-ide` |
| **Complexidade estimada** | S4 |
| **Bounded Context** | `harness-corporativo` |
| **PR de referência / Issue** | novo |
| **Data alvo de entrega** | 2026-09-30 (fim do trimestre atual — piloto restrito ao esquadrão/mantenedores do Nimbus Code) |

> S0 = doc · S1 = função isolada · S2 = módulo · S3 = múltiplos módulos ·
> S4 = arquitetura, segurança, dados ou integração crítica

**Justificativa da complexidade S4**: esta feature (a) lê e processa texto livre pessoal
(`~/.claude/CLAUDE.md`, `.cursor/rules`) que pode conter dados de clientes, propriedade
intelectual e segredos colados acidentalmente em prompts — uma categoria de dado
potencialmente sensível sob LGPD, distinta e de maior risco do que os metadados
estruturais de código que `scripts/harvest-patterns.sh` processa hoje; (b) envia
conteúdo (ainda que pós-anonimização) a um LLM externo via `HARVEST_API_URL`,
repetindo a mesma classe de risco de integração/segurança já reconhecida no
precedente direto `specs/022-nimbuscode-harvest-gateway/` (também S4, "revisão humana
obrigatória antes de qualquer implementação" por processar dados enviados a provedor de
IA externo); e (c) introduz um novo repositório institucional central (GHE dedicado),
compartilhado por toda a organização, com modelo de governança e retenção próprios —
decisão de arquitetura/segurança/dados com impacto organizacional, não uma mudança
isolada de módulo. A diferença relevante em relação ao precedente 022 é que ali o
risco é mitigado por uma allowlist estrita de metadados estruturais (nunca corpo de
método, string literal ou texto livre); aqui a fonte é, por definição, exatamente o
texto livre que aquele precedente evita capturar — o que eleva, não reduz, o risco
em relação ao precedente já classificado S4. Exige revisão humana obrigatória (Comitê
Nimbus Code + Jurídico/DPO) antes de qualquer execução contra dados reais, conforme a
escala S0–S4 da constituição.

## Nimbus-Code — SLO Alvo desta Feature

*Preencher para componentes novos ou alterados. Alimenta o Observability Gate do
plan.md — alertas serão configurados com base nesses valores.*

| Componente | Latência p99 (ms) | Taxa de erro máx. (%) | Disponibilidade alvo | RTO | RPO |
|---|---|---|---|---|---|
| Execução local do harvester estendido (CLI on-demand) | — | — | — | — | — |
| Repositório central dedicado (GHE) | — | — | herda o SLA do GHE corporativo já existente (sem SLA adicional nesta v1) | — | — |
| Anonimização/redação + envio a `HARVEST_API_URL` (LLM externo) | 20000 | 2,0% | 99,5% (herdado do precedente `specs/022-nimbuscode-harvest-gateway/`) | 30 min | N/A (sem persistência de dados de negócio nesta chamada) |

> As duas primeiras linhas ficam intencionalmente como "—": o harvester é um job
> local disparado sob demanda por um humano (nunca residente/CI), sem contrato de
> disponibilidade tradicional; e o repositório central é consumido de forma
> assíncrona/manual (captura, triagem), não como serviço com SLA próprio nesta v1.
> Isso não é omissão — é a natureza do desenho on-demand da Opção A, conforme
> fechado no gate de decisão do assessment. A terceira linha (chamada ao LLM externo)
> herda o mesmo perfil de SLO já aprovado para o Gateway multicloud (precedente S4
> mais próximo), por ser a única etapa desta feature que efetivamente atravessa a
> rede para um serviço de terceiros.

## Nimbus-Code — Objetivo e Contexto

*Descreva de forma objetiva o que esta feature entrega e por que ela é necessária.
Sem formato fixo — use parágrafos curtos ou tópicos. Substituiu o campo "User Story"
do modelo anterior: foque no objetivo de negócio/técnico, não numa narrativa de papel.*

**Objetivo:** estender `scripts/harvest-patterns.sh` (Opção A do assessment
`harness-consolidacao-corporativa`) para também aceitar, como fonte adicional de
captura, os arquivos de Harness Agêntico IDE pessoal do colaborador
(`~/.claude/CLAUDE.md`, `.cursor/rules`), sempre sob invocação manual e explícita de
um humano (nunca CI/residente), redirecionando a escrita sempre para um novo
repositório GHE central dedicado (ex.: `nimbus-code-harness-corporativo`) — nunca
para o repositório de trabalho do dev. O material bruto ali agregado passa por
triagem manual humana obrigatória do Comitê Nimbus Code (4 pessoas) antes de
qualquer promoção a Harness Corporativo institucional; itens promovidos e
classificados pelo Comitê como específicos de um bounded context podem, de forma
opcional, ser redistribuídos pontualmente de volta ao(s) repositório(s) satélite
daquele contexto, reaproveitando o mecanismo idempotente já existente no
`bootstrap.sh`.

**Motivação:** hoje, cada um dos ~60 colaboradores (60 usam Claude Code, ~10 também
usam Cursor.AI) constrói, ao longo do tempo, um relacionamento pessoal e tácito com
o LLM — convenções, prompts recorrentes, regras próprias — que fica preso à
máquina/conta de cada um. Esse conhecimento se perde na saída ou troca de time/
ferramenta do colaborador, gera reinvenção redundante de soluções já resolvidas por
colegas, produz inconsistência de qualidade entre quem tem harness pessoal maduro e
quem não tem, e não alimenta nenhum *feedback loop* para evoluir o próprio Nimbus
Code como processo de engenharia corporativo. Nenhum artefato institucional hoje
(`docs/harness/harness-catalog.yaml`, `docs/playbooks/success-catalog.yaml`,
`docs/reuse-catalog.yaml`) cobre esse relacionamento tácito dev↔agente no nível
individual — o gap foi confirmado por pesquisa direta (`research.md`, seção 2.4) e
o assessment recebeu GO condicional restrito a esta Opção A (`decision.md`, ciclo 2).

**Critério de done (alto nível):** o piloto v1, restrito ao esquadrão/mantenedores do
Nimbus Code, está em produção até o fim do trimestre atual, demonstrando de forma
qualitativa "melhoria de processo por ter o Harness Corporativo em produção"
(critério de sucesso primário — não uma meta de quantidade), com 5 promoções/mês
mantido como sinal auxiliar de acompanhamento (não como critério único), e com os
7 critérios de aceite da entrevista de descoberta (C1–C7, refletidos nos AC-1 a
AC-7 abaixo) satisfeitos.

**Fora de escopo nesta entrega:** Opção B (pipeline paralelo dedicado) e Opção C
(agente residente com varredura automática de endpoint) do `concept.md` — ambas
descartadas para o v1 pelo gate de decisão; qualquer execução automática/agendada/
residente ou em CI; envio de texto livre cru (sem anonimização) ao LLM externo;
rollout aos 60 colaboradores nesta entrega (a v1 é o piloto restrito); definição do
formato exato de autenticação/RBAC fino e da trilha de auditoria detalhada do
repositório central (fica para `plan.md`); parecer formal de Jurídico/DPO sobre a
cláusula do NDA ampliado e a política de retenção do Harness Corporativo já
promovido (gate de **execução**, não bloqueia esta spec, mas bloqueia
`/nimbus-code-plan` iniciar construção contra dados reais).

## Nimbus-Code — Hybrid Collaboration Model

*Defina explicitamente como agente e humano se dividem na execução desta feature.
Use este bloco para reduzir handoff implícito e eliminar ambiguidade operacional.*

| Papel | Responsabilidades | Critério de handoff | Escalação |
|---|---|---|---|
| Agente | Estruturar spec/plan/tasks; desenhar a extensão da allowlist de `harvest-patterns.sh` para aceitar Harness Agêntico IDE como fonte; propor esquema de anonimização/redação e o modelo de dados do repositório central | Repassa quando houver decisão de nomenclatura/estrutura final do repositório central, de RBAC fino, ou de política de retenção do já promovido | Architecture board |
| Dev | Validar viabilidade técnica da extensão do script; implementar o passo de anonimização/redação; implementar a rotina de expurgo automático (3 meses) e a redistribuição idempotente via `bootstrap.sh` | Repassa a Segurança/`nc-shield` antes de qualquer execução contra dados reais (gate S4 obrigatório) | Tech lead |
| Comitê Nimbus Code (4 pessoas) | Administrar acesso ao repositório central; realizar a triagem manual de promoção item a item; classificar itens promovidos como genéricos vs. específicos de bounded context | Repassa a Jurídico/DPO quando houver dúvida sobre classificação de dado sensível de cliente | Patrocinador (Leonardo Rodrigues) |
| Jurídico/DPO | Validar formalmente a redação da cláusula do NDA ampliado e a política de retenção/expurgo antes de qualquer execução contra dados reais | Devolve ao Comitê/patrocinador quando o parecer estiver concluído (gate de execução, não de especificação) | Patrocinador / Diretoria |

> Contexto **WEB**: não aplicável nesta v1 — a feature não expõe superfície web/UI
> própria (interação via CLI local + repositório Git); qualquer futura UI de triagem
> do Comitê deve, se construída, seguir o padrão institucional Impeccable e seria
> tratada como extensão fora deste ciclo.

## Nimbus-Code — Critérios de Aceitação (formato BDD)

*Todo critério de aceitação deve estar no formato Given/When/Then para permitir
rastreabilidade direta com testes de integração. Cada item recebe um ID único
(AC-N) que será referenciado no `tasks.md` e nos testes.*

> **AC-1 — Captura sempre on-demand, nunca CI/residente**
> **Given** um colaborador com Harness Agêntico IDE local (`~/.claude/CLAUDE.md` e/ou `.cursor/rules`),
> **When** ele invoca manualmente o harvester estendido apontando para esses arquivos,
> **Then** a captura só ocorre nesse instante, por ação humana explícita — nenhum agendamento, workflow de CI ou processo residente executa essa captura automaticamente.
> **Test ref:** `test_AC1_captura_sempre_on_demand` *(preenchido durante /nimbus-code-tasks)*

> **AC-2 — Escrita sempre no repositório central dedicado**
> **Given** o harvester estendido configurado com `--output` (ou variável de ambiente equivalente) apontando para o repositório GHE central dedicado (ex.: `nimbus-code-harness-corporativo`),
> **When** a captura é executada,
> **Then** a saída é sempre gravada nesse repositório central — nunca no `docs/reuse-catalog.yaml` (ou equivalente) do repositório de trabalho do dev.
> **Test ref:** `test_AC2_escrita_sempre_repo_central`

> **AC-3 — Anonimização/redação prévia obrigatória antes do LLM externo**
> **Given** texto livre capturado do Harness Agêntico IDE destinado a normalização/resumo via `HARVEST_API_URL`,
> **When** o harvester envia esse conteúdo ao LLM externo,
> **Then** o conteúdo passa antes por um passo automático de anonimização/redação — nunca é enviado cru, e esse passo nunca é contornado ou suprimido.
> **Test ref:** `test_AC3_anonimizacao_previa_llm_externo`

> **AC-4 — Promoção somente via triagem manual humana do Comitê**
> **Given** um item de Harness Agêntico IDE bruto no repositório central,
> **When** o Comitê Nimbus Code avalia esse item,
> **Then** a promoção a Harness Corporativo só ocorre mediante decisão explícita de um dos 4 membros do Comitê — não existe caminho de promoção automática, sem exceção.
> **Test ref:** `test_AC4_promocao_somente_triagem_manual`

> **AC-5 — Expurgo automático de harness bruto não promovido em 3 meses**
> **Given** um item de Harness Agêntico IDE bruto no repositório central que não foi promovido,
> **When** 3 meses se passam desde a captura sem decisão de promoção,
> **Then** o item é automaticamente expurgado do repositório central.
> **Test ref:** `test_AC5_expurgo_automatico_3_meses`

> **AC-6 — Redistribuição pós-promoção opcional e idempotente (Etapa 2)**
> **Given** um item de Harness Corporativo já promovido e classificado pelo Comitê como específico de um bounded context/projeto,
> **When** a redistribuição para o(s) repositório(s) satélite daquele bounded context é executada,
> **Then** o mecanismo idempotente já existente do `bootstrap.sh` é reaproveitado, nunca sobrescrevendo customização local já feita no repositório de destino.
> **Test ref:** `test_AC6_redistribuicao_idempotente_bootstrap`

> **AC-7 — Sucesso do piloto restrito (qualitativo + auxiliar quantitativo)**
> **Given** o piloto v1 restrito ao esquadrão/mantenedores do Nimbus Code em produção até o fim do trimestre atual,
> **When** o processo de captura → agregação → triagem → promoção é observado ao longo do piloto,
> **Then** há evidência qualitativa registrada de melhoria de processo por ter o Harness Corporativo em uso, com 5 promoções/mês registrado apenas como sinal auxiliar de acompanhamento — não como critério único de sucesso.
> **Test ref:** `test_AC7_sucesso_piloto_qualitativo`

> **AC de governança para rollout/toggle (se aplicável)**
> - Não aplicável nesta v1: não há rollout progressivo de produto nem feature flag técnico — a "progressão" do conteúdo (bruto → promovido → eventualmente redistribuído) é inteiramente governada pela triagem humana do Comitê Nimbus Code (Etapas 1–4 do `concept.md`), não por OpenFeature/toggle. Caso uma v2 futura introduza ativação progressiva por squad/repositório, este ponto deve ser revisitado e um provider OpenFeature avaliado então.

## Nimbus-Code — Backlog Hierarchy (EPIC/FEATURE/US)

| Nível | Valor | Observação |
|---|---|---|
| **EPIC** | Aprendizado Organizacional e Reuso de Padrões Técnicos | Mesmo guarda-chuva do Harvest Engineering (SPEC-014) e do Nimbus Harvest Gateway (SPEC-022) |
| **FEATURE** | Harness Corporativo — Consolidação de Harness Agêntico IDE Pessoal | Escopo desta spec |
| **US1** | Capturar Harness Agêntico IDE pessoal on-demand | Extensão de `scripts/harvest-patterns.sh` |
| **US2** | Escrever sempre no repositório central dedicado | Nunca no repositório de trabalho do dev |
| **US3** | Anonimizar/redigir antes de enviar a LLM externo | Gate de segurança obrigatório sobre `HARVEST_API_URL` |
| **US4** | Realizar triagem manual do Comitê Nimbus Code | Portão único de promoção a Harness Corporativo |
| **US5** | Expurgar automaticamente o bruto não promovido em 3 meses | Governança de retenção LGPD |
| **US6** | Redistribuir pontualmente pós-promoção (Etapa 2, opcional) | Reaproveita o mecanismo idempotente do `bootstrap.sh` |

# Feature Specification: Harness Corporativo — Consolidação de Harness Agêntico IDE Pessoal

**Feature Branch**: `029-harness-corporativo-ide`

**Created**: 2026-09-22

**Status**: Draft

**Input**: Consolidação do assessment `harness-consolidacao-corporativa` (GO condicional,
Opção A) e da entrevista de descoberta (`interview.md`): estender
`scripts/harvest-patterns.sh` para também capturar, sempre on-demand, o Harness
Agêntico IDE pessoal (`~/.claude/CLAUDE.md`, `.cursor/rules`) dos colaboradores,
escrevendo sempre em um novo repositório GHE central dedicado, com triagem manual
obrigatória do Comitê Nimbus Code antes de qualquer promoção a Harness Corporativo,
redistribuição opcional pós-promoção via `bootstrap.sh`, anonimização obrigatória
antes de envio a LLM externo, e expurgo automático em 3 meses do bruto não promovido.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Colaborador captura seu próprio Harness Agêntico IDE (Priority: P1)

Como Colaborador (dev que usa Claude Code e/ou Cursor.AI), quero rodar o harvester
estendido apontando para meus arquivos pessoais (`~/.claude/CLAUDE.md`,
`.cursor/rules`) e ter essa captura enviada ao repositório central dedicado, para
que meu conhecimento tácito não se perca e possa eventualmente virar Harness
Corporativo.

**Why this priority**: sem esta etapa, nenhuma outra etapa do fluxo (agregação,
triagem, promoção, redistribuição) tem o que processar — é o ponto de entrada de
todo o valor da feature.

**Independent Test**: um colaborador do piloto roda o harvester estendido apontando
para seus arquivos locais e confirma que o conteúdo aparece no repositório central
dedicado, identificado por autor/data, e nunca no seu próprio repositório de
trabalho.

**Acceptance Scenarios**:

1. **Given** um colaborador com `~/.claude/CLAUDE.md` preenchido, **When** ele executa o harvester estendido manualmente, **Then** o conteúdo é enviado ao repositório central dedicado, identificado por autor, ferramenta de origem e data.
2. **Given** um colaborador que também usa Cursor.AI, **When** ele aponta o harvester para `.cursor/rules`, **Then** esse conteúdo também é capturado e agregado no mesmo repositório central.
3. **Given** que nenhuma invocação manual foi feita, **When** se verifica os workflows de CI/agendadores do repositório, **Then** nenhuma captura ocorre automaticamente.

---

### User Story 2 - Comitê Nimbus Code realiza a triagem manual e promove (Priority: P1)

Como membro do Comitê Nimbus Code, quero revisar o material bruto agregado no
repositório central e decidir item a item o que promover, descartar ou devolver
para anonimização adicional, para garantir que só conhecimento validado vira
Harness Corporativo institucional.

**Why this priority**: é o único portão de promoção do fluxo — sem ele, não existe
distinção confiável entre harness pessoal bruto e Harness Corporativo institucional.

**Independent Test**: um membro do Comitê acessa o repositório central, revisa um
item pendente e registra a decisão de promoção/descarte; confirma-se que o item
promovido passa a existir como Harness Corporativo, rastreável ao membro que
aprovou, e que nenhuma outra via de promoção (automática) existe.

**Acceptance Scenarios**:

1. **Given** um item bruto pendente de triagem no repositório central, **When** um membro do Comitê aprova a promoção, **Then** o item passa a existir como Harness Corporativo, rastreável ao membro que aprovou.
2. **Given** um item considerado inadequado, **When** o Comitê decide descartar, **Then** o item não é promovido e segue sujeito ao expurgo automático em 3 meses caso não seja revisitado.
3. **Given** que nenhuma revisão do Comitê ainda ocorreu sobre um item, **When** qualquer automação tentar promovê-lo, **Then** a promoção é impedida — não existe caminho automático de promoção.

---

### User Story 3 - Redistribuição opcional de Harness Corporativo específico de bounded context (Priority: P2)

Como mantenedor do Nimbus Code, quero que um item de Harness Corporativo
classificado pelo Comitê como específico de um bounded context seja redistribuído
de volta ao(s) repositório(s) satélite daquele contexto, reaproveitando o mecanismo
idempotente do `bootstrap.sh`, para que o próximo dev daquele projeto já encontre o
harness ajustado, sem depender de busca manual no repositório central.

**Why this priority**: é valor incremental de continuidade — não bloqueia o fluxo
central de captura → triagem → promoção (P1), mas aumenta a adoção prática do
Harness Corporativo já promovido.

**Independent Test**: um item promovido e classificado como "específico do bounded
context X" é processado pela rotina de redistribuição; confirma-se que o
repositório satélite de X recebe o item sem sobrescrever nenhuma customização local
já existente.

**Acceptance Scenarios**:

1. **Given** um item de Harness Corporativo classificado pelo Comitê como específico do bounded context X, **When** a redistribuição é executada, **Then** o repositório satélite de X recebe o item via o mecanismo idempotente já existente do `bootstrap.sh`.
2. **Given** que o repositório satélite já possui customização local equivalente, **When** a redistribuição tenta atualizar esse arquivo, **Then** a customização local não é sobrescrita — o sistema apenas registra um aviso de divergência.
3. **Given** um item classificado como genérico (não específico de bounded context), **When** a triagem é concluída, **Then** ele permanece apenas no repositório central, sem redistribuição.

---

### User Story 4 - Expurgo automático do harness bruto não promovido (Priority: P2)

Como Comitê Nimbus Code / responsável por governança de dados, quero que todo
Harness Agêntico IDE bruto que não for promovido em até 3 meses seja
automaticamente expurgado do repositório central, para cumprir a política de
retenção mínima necessária e reduzir a superfície de exposição de dado
potencialmente sensível.

**Why this priority**: é o controle de LGPD/retenção mais concreto já fechado
nesta entrevista — mitigá-lo cedo reduz risco regulatório acumulado ao longo do
piloto, mesmo não sendo bloqueante para a primeira captura.

**Independent Test**: um item de harness bruto capturado há mais de 3 meses e nunca
promovido é verificado ausente do repositório central após a rotina de expurgo
rodar.

**Acceptance Scenarios**:

1. **Given** um item bruto capturado há mais de 3 meses sem promoção, **When** a rotina de expurgo roda, **Then** o item é removido do repositório central.
2. **Given** um item bruto promovido antes de completar 3 meses, **When** a rotina de expurgo roda, **Then** o item promovido (agora Harness Corporativo) não é afetado — apenas material bruto não promovido é elegível ao expurgo.

---

### Edge Cases

- O que acontece quando o colaborador aponta o harvester para um arquivo de Harness Agêntico IDE que contém um segredo colado acidentalmente (ex.: token de API)? O passo de anonimização/redação deve identificar e remover esse padrão antes de qualquer envio a LLM externo — se não conseguir garantir isso, o envio deve ser bloqueado (fail-closed), nunca seguir com o dado cru.
- Como o sistema lida com uma falha ou insuficiência do passo automático de anonimização/redação antes do envio ao LLM externo? Deve bloquear o envio (gate de segurança) — nunca degradar silenciosamente para envio cru como fallback.
- O que acontece se o colaborador não tiver nem `~/.claude/CLAUDE.md` nem `.cursor/rules` preenchidos (harness pessoal vazio)? O harvester deve reportar explicitamente "nada capturado", sem gerar entrada vazia/ruído no repositório central.
- Como o Comitê decide quando dois colaboradores diferentes enviam conteúdo textualmente conflitante para o mesmo tópico (ex.: convenções opostas)? Tratado como critério de triagem qualitativa do Comitê — não há regra automática de desempate nesta v1.
- O que acontece quando um colaborador sai da empresa antes de completar o prazo de 3 meses de retenção do material bruto que ele enviou? O material segue as mesmas regras de expurgo automático em 3 meses; não há tratamento diferenciado nesta v1 (ponto que reforça a motivação original de "não perder o conhecimento antes da saída", mas não altera o prazo de retenção do bruto).
- Como o sistema lida com a redistribuição da Etapa 2 quando o repositório satélite de destino não existe mais, foi arquivado ou renomeado? Deve falhar explicitamente e registrar a exceção para revisão do Comitê/mantenedores — nunca criar um repositório novo silenciosamente nem descartar o item promovido.
- O que acontece quando o Comitê está com quórum incompleto (menos de 4 membros disponíveis) no momento da triagem? Comportamento de quórum mínimo para promoção não foi definido nesta entrevista — ver `[NEEDS CLARIFICATION: comite-composicao]` abaixo.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O harvester (extensão de `scripts/harvest-patterns.sh`) MUST aceitar como fonte de captura os arquivos de Harness Agêntico IDE pessoal do colaborador (`~/.claude/CLAUDE.md`, `.cursor/rules`), além do escopo já existente de metadados estruturais de código versionado.
- **FR-002**: A captura do Harness Agêntico IDE MUST ser executada exclusivamente sob invocação manual e explícita de um humano — nunca por CI, agendador ou processo residente em endpoint.
- **FR-003**: O destino de escrita do harvester estendido MUST ser sempre o repositório GHE central dedicado (via `--output` ou variável de ambiente equivalente) — nunca o `docs/reuse-catalog.yaml` (ou equivalente) do repositório de trabalho do dev.
- **FR-004**: Todo texto livre do Harness Agêntico IDE destinado a normalização/resumo via LLM externo (`HARVEST_API_URL`) MUST passar por um passo automático de anonimização/redação antes do envio.
- **FR-005**: O sistema MUST bloquear (fail-closed) o envio ao LLM externo caso o passo de anonimização/redação falhe ou seja insuficiente — nunca enviar texto cru como fallback.
- **FR-006**: A promoção de qualquer item de Harness Agêntico IDE bruto a Harness Corporativo MUST exigir decisão explícita de um membro do Comitê Nimbus Code — não deve existir caminho de promoção automática, sem exceção.
- **FR-007**: O acesso administrativo ao repositório central dedicado (concessão/revogação de acesso) MUST ser restrito ao Comitê Nimbus Code.
- **FR-008**: O sistema MUST expurgar automaticamente todo item de Harness Agêntico IDE bruto que permanecer no repositório central por mais de 3 meses sem decisão de promoção.
- **FR-009**: A redistribuição de um item de Harness Corporativo já promovido e classificado pelo Comitê como específico de bounded context para repositório(s) satélite MUST reaproveitar o mecanismo idempotente já existente do `bootstrap.sh` (ex.: `refresh_managed_project_root_files` ou equivalente), nunca sobrescrevendo customização local já existente no destino.
- **FR-010**: O sistema MUST registrar a origem (autor, ferramenta — Claude Code e/ou Cursor.AI —, data de captura) de cada item de Harness Agêntico IDE capturado, preservando rastreabilidade até a decisão do Comitê, em linha com o padrão de auditoria já exigido para specs S4.
- **FR-011**: O piloto v1 MUST restringir o acesso de captura/uso ao esquadrão/mantenedores do Nimbus Code — rollout aos ~60 colaboradores fica fora de escopo desta entrega.
- **FR-012**: O sistema MUST NEVER escrever Harness Agêntico IDE bruto (não triado) diretamente em qualquer repositório de projeto/bounded context — a Etapa 1 (repositório central) é sempre obrigatória e sempre anterior a qualquer Etapa 2 opcional de redistribuição.
- **FR-013**: O formato exato de autenticação/RBAC fino do repositório central e a trilha de auditoria detalhada (quem fez o quê, quando) MUST ser detalhados em `plan.md`, herdando o padrão já exigido para specs S4 (ex.: `specs/022-nimbuscode-harvest-gateway/`).
- **FR-014**: A composição individual (nomes e papéis) do Comitê Nimbus Code MUST ser formalizada antes do início da execução em `plan.md` — **[NEEDS CLARIFICATION: comite-composicao]** nomes e papéis individuais dos 4 membros não foram informados nesta entrevista; apenas que são 4 pessoas com papéis já claros internamente. Inclui também o comportamento de quórum mínimo de triagem quando nem todos os 4 membros estão disponíveis (ver Edge Cases).
- **FR-015**: A base legal do tratamento de dado pessoal (NDA ampliado, cláusula específica) MUST ter parecer formal de Jurídico/DPO validado antes de qualquer execução contra dados reais — **[NEEDS CLARIFICATION: parecer-juridico-dpo]** parecer hoje apenas encaminhado, não obtido; é gate de **execução** (bloqueia `/nimbus-code-plan` iniciar construção contra dados reais), não bloqueia esta spec.
- **FR-016**: O tratamento do Harness Agêntico IDE capturado MUST resolver, antes da implementação em `plan.md`, a tensão registrada entre o controle técnico de anonimização aplicado desde a captura (incondicional, para a chamada ao LLM externo) e a classificação administrativa como "dado sensível de cliente" que só passa a valer oficialmente após a triagem do Comitê — **[NEEDS CLARIFICATION: lgpd-tensao-classificacao]** tensão explicitamente registrada como não resolvida nesta entrevista, a validar formalmente com Jurídico/DPO.

### Key Entities *(include if feature involves data)*

- **Harness Agêntico IDE (bruto)**: conteúdo de texto livre pessoal de um colaborador (`~/.claude/CLAUDE.md`, `.cursor/rules`); atributos: autor, ferramenta de origem (Claude Code e/ou Cursor.AI), data de captura, status (pendente / promovido / descartado / expurgado).
- **Harness Corporativo (promovido)**: item validado pelo Comitê Nimbus Code; atributos: classificação (genérico vs. específico de bounded context), data de promoção, membro do Comitê responsável, item bruto de origem (rastreabilidade).
- **Comitê Nimbus Code**: grupo de 4 pessoas (composição individual pendente — `[NEEDS CLARIFICATION: comite-composicao]`) com permissão de administrar acesso ao repositório central e realizar a triagem manual de promoção.
- **Repositório Central Dedicado**: novo repositório GHE (ex.: `nimbus-code-harness-corporativo`) que hospeda tanto o material bruto quanto o promovido, com política de expurgo automático de 3 meses aplicável apenas ao material bruto não promovido.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% das capturas realizadas durante o piloto ocorrem por invocação manual explícita — nenhuma captura registrada com origem em CI/agendador/processo residente.
- **SC-002**: 100% dos itens capturados são gravados apenas no repositório central dedicado — nenhuma ocorrência de escrita no repositório de trabalho do dev.
- **SC-003**: 100% dos envios de texto livre ao LLM externo (`HARVEST_API_URL`) passam pelo passo de anonimização/redação antes do envio — nenhum envio cru registrado.
- **SC-004**: 100% das promoções a Harness Corporativo durante o piloto têm decisão explícita registrada de um membro do Comitê Nimbus Code — nenhuma promoção automática.
- **SC-005**: Até o fim do trimestre atual, o piloto restrito ao esquadrão/mantenedores do Nimbus Code está em produção, com evidência qualitativa registrada de melhoria de processo (critério primário) e, como sinal auxiliar, promoções observadas em direção ao target de 5/mês.
- **SC-006**: 100% dos itens de Harness Agêntico IDE bruto não promovidos em 3 meses são expurgados automaticamente do repositório central, de forma auditável.

## Assumptions

- O termo "Harness Agêntico IDE" (pessoal) e "Harness Corporativo" (institucional pós-triagem) já está fixado pela entrevista/decisão anteriores e não é reaberto nesta spec.
- O nome exato do novo repositório central (ex.: `nimbus-code-harness-corporativo`) é ilustrativo; o nome definitivo e sua estrutura interna ficam para `plan.md`/decisão de arquitetura.
- O piloto v1 é restrito ao esquadrão/mantenedores do Nimbus Code; rollout aos ~60 colaboradores (60 usam Claude Code, ~10 também Cursor.AI) é etapa futura, fora deste ciclo.
- Turnover exato dos ~60 colaboradores não foi informado nesta entrevista; tratado como hipótese razoável ("baixo") apenas para fins de priorização — não é uma pendência bloqueante desta spec, pois as demais dores de negócio (reinvenção, inconsistência de qualidade, ausência de *feedback loop* institucional) permanecem válidas independentemente desse dado.
- A validação formal de Jurídico/DPO (parecer sobre a cláusula do NDA ampliado e sobre a política de retenção do Harness Corporativo já promovido) é uma pendência de **execução**, não de especificação — não bloqueia esta spec, mas bloqueia `/nimbus-code-plan` iniciar construção contra dados reais.
- Apenas 3 marcadores `[NEEDS CLARIFICATION]` são mantidos nesta spec, priorizados por criticidade (segurança/LGPD antes de infraestrutura de detalhe), conforme limite institucional definido no template de entrevista Nimbus Code: `comite-composicao`, `parecer-juridico-dpo`, `lgpd-tensao-classificacao`. O ponto de turnover exato, de menor criticidade e já tratado como hipótese não bloqueante, foi registrado acima como Assumption em vez de marcador formal.
