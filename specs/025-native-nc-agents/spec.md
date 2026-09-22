<!--
  Esta especificacao descreve a evolucao dos NC-* de skills/comandos para
  agentes nativos, preservando compatibilidade durante a transicao.
-->

> **Reaberta em 2026-09-22.** A spec foi dada como entregue (27/27 tasks),
> mas a validação foi só estrutural: arquivos existiam e o hash do corpo batia
> com a fonte. Nenhuma task iniciou de fato um agente em cada IDE agêntica.
> Defeitos encontrados na reabertura:
>
> 1. **Claude Code**: os 18 `.claude/agents/nc-*.md` declaravam ferramentas com
>    nomes do Copilot (`view`, `rg`, `apply_patch`, `skill:*`). O Claude recusa
>    iniciar o subagente ("would be spawned with zero tools"). Corrigido na
>    reabertura (ADL-025-05).
> 2. **Kiro**: mesmos nomes do Copilot em `.kiro/agents/nc-*.md`. Pela
>    documentação e pela issue kirodotdev/Kiro#11411, a IDE descarta o agente
>    inteiro sem aviso. Pendente (T032).
> 3. **Orquestrador `nimbus`**: existia só para VS Code. Claude passa a ter a
>    skill `/nimbus`; Antigravity, Cursor e Kiro seguem sem orquestrador.
> 4. **Skill de terceiros `typesafe-ai`** (ADR 0010): presente só em Claude e
>    Antigravity, porque foi instalada com `npx skills add` (grava em
>    `.agents/skills/` e cria symlink em `.claude/skills/`) e não passa pela
>    fonte `.github/skills/` que alimenta o sync. Copilot, a ferramenta oficial,
>    não a recebe. Pendente de decisão (T037).
>
> Critérios de aceitação adicionais da reabertura: **AC-7** a **AC-9** abaixo.
> Tarefas: `tasks.md`, Phase 7.

## Nimbus-Code — Cabecalho Obrigatorio da Spec

| Campo | Valor |
|---|---|
| **Feature slug** | `native-nc-agents` |
| **Complexidade estimada** | S3 |
| **Bounded Context** | `spec-kit-workflow` |
| **PR de referencia / Issue** | novo |
| **Data alvo de entrega** | sem data |

## Nimbus-Code — SLO Alvo desta Feature

| Componente | Latencia p99 (ms) | Taxa de erro max. (%) | Disponibilidade alvo | RTO | RPO |
|---|---:|---:|---|---|---|
| Geracao dos artefatos de agentes | — | 0% | — | — | — |
| Gate de paridade entre integracoes | — | 0% | — | — | — |

Os componentes sao tooling local/CI e nao expoem SLA de runtime. Falhas devem
bloquear a promocao dos artefatos, sem fallback silencioso.

## Nimbus-Code — Objetivo e Contexto

**Objetivo:** disponibilizar cada agente institucional `NC-*` como agente nativo
nas integracoes VS Code/Copilot Agent e Claude Code, e como a superficie nativa
equivalente suportada pelo Antigravity, mantendo os comandos `/nc-*` existentes
como bridge durante a transicao.

**Motivacao:** hoje o conteudo NC-* e consumido como `SKILL.md` e aparece como
comando/skill. Isso permite reutilizacao, mas nao oferece a experiencia de
agente nativo (picker, delegacao e identidade de agente) em cada plataforma.
A conversao manual criaria drift entre prompts, permissoes, gates e escopo de
arquivos.

**Critério de done:** um desenvolvedor consegue selecionar/delegar cada agente
NC-* pela superficie nativa de cada plataforma; uma unica definicao institucional
mantem identidade, escopo, ferramentas e gates equivalentes; os bridges
`/nc-*` continuam funcionais ate a validacao de paridade e uma decisao posterior
de descontinuacao.

## Nimbus-Code — Hybrid Collaboration Model

| Papel | Responsabilidades | Criterio de handoff | Escalacao |
|---|---|---|---|
| Agente | Gerar adaptadores, validar frontmatter, comparar paridade e executar testes | Parar se o contrato de uma plataforma nao suportar o formato esperado | Dev responsavel pelo template |
| Humano | Aprovar os contratos nativos, validar UX de delegacao e decidir a retirada futura dos bridges | Revisar antes de qualquer remocao de `/nc-*` | Tech lead / architecture board |

## Nimbus-Code — Criterios de Aceitacao (BDD)

> **AC-1**
> **Given** os agentes NC-* existem na fonte institucional
> **When** o gerador de integracoes e executado
> **Then** ele produz um agente nativo correspondente para VS Code/Copilot e
> Claude, e a superficie equivalente suportada pelo Antigravity, sem edicao
> manual dos destinos.
> **Test ref:** `test_AC1_native_agent_artifacts_generated`

> **AC-2**
> **Given** o manifesto institucional define identidade, escopo, ferramentas e gates
> **When** um agente e gerado para qualquer integracao
> **Then** esses controles permanecem presentes e equivalentes no adaptador gerado.
> **Test ref:** `test_AC2_manifest_controls_preserved`

> **AC-3**
> **Given** um desenvolvedor atualiza a fonte de um agente NC-*
> **When** tenta validar ou promover a mudanca sem regenerar os destinos
> **Then** o gate de paridade falha identificando o agente e a integracao divergente.
> **Test ref:** `test_AC3_parity_gate_detects_drift`

> **AC-4**
> **Given** os comandos `/nc-*` ainda sao usados por desenvolvedores
> **When** a transicao nativa e instalada
> **Then** os comandos permanecem disponiveis e apontam para o mesmo comportamento
> institucional ate que uma decisao aprovada autorize sua remocao.
> **Test ref:** `test_AC4_command_bridge_remains_available`

> **AC-5**
> **Given** uma plataforma nao possui contrato nativo de agente confirmado
> **When** o gerador for executado
> **Then** ele nao inventa um formato silenciosamente; gera apenas a superficie
> suportada/documentada e falha explicitamente se a paridade minima nao puder ser garantida.
> **Test ref:** `test_AC5_unsupported_agent_surface_fails_explicitly`

> **AC-6**
> **Given** a feature e S3 e altera superficies de execucao de agentes
> **When** o plano for revisado
> **Then** graph, impact-map, ADL, gates de seguranca e estrategia de rollback
> estao preenchidos antes da implementacao.
> **Test ref:** `test_AC6_governance_artifacts_complete`

> **AC-7** *(reabertura)*
> **Given** um agente NC-* gerado para uma plataforma
> **When** o gate de paridade roda
> **Then** ele falha se algum nome de ferramenta não for reconhecido pela
> plataforma de destino, e não apenas quando diverge do manifesto.
> **Test ref:** `claude native agents only declare tool names Claude Code recognizes`

> **AC-8** *(reabertura)*
> **Given** cada IDE agêntica suportada (VS Code/Copilot, Claude Code,
> Antigravity, Cursor, Kiro)
> **When** a entrega for declarada concluída
> **Then** existe evidência registrada de um teste real em cada uma: o
> orquestrador ou um agente NC-* foi iniciado, listou suas ferramentas e leu
> um arquivo do repositório.
> **Test ref:** `specs/025-native-nc-agents/ide-validation-matrix.md` (evidência humana)

> **AC-9** *(reabertura)*
> **Given** uma skill de terceiros aprovada por ADR (ex.: `typesafe-ai`)
> **When** o sync de integrações roda
> **Then** ela está presente em todas as IDEs suportadas, ou a exclusão de
> cada IDE está documentada com o motivo.
> **Test ref:** a definir em T037

## User Scenarios & Testing

### User Story 1 — Usar NC-* como agente nativo (P1)

Um desenvolvedor seleciona ou delega `NC-Arch`, `NC-Builder`, `NC-QA` ou outro
agente NC-* diretamente na integracao escolhida, sem depender de lembrar o
comando `/nc-*`.

**Independent Test:** instalar os artefatos gerados em um clone limpo e verificar
que cada agente aparece na superficie nativa correspondente e conserva seus
controles de governanca.

### User Story 2 — Atualizar uma definicao sem drift (P1)

Um mantenedor corrige um agente na fonte institucional e executa um unico
gerador para atualizar todas as integracoes.

**Independent Test:** alterar uma copia de fonte em fixture, gerar os destinos,
comparar hashes funcionais e confirmar que o CI detecta qualquer destino nao
regenerado.

### User Story 3 — Fazer transicao sem quebrar usuarios atuais (P1)

Um desenvolvedor que ainda usa `/nc-*` continua executando o mesmo fluxo enquanto
os agentes nativos sao validados.

**Independent Test:** executar os bridges antes e depois da geracao e confirmar
que permanecem disponiveis e semanticamente equivalentes.

## Functional Requirements

- **FR-001:** O projeto deve manter uma fonte institucional unica para cada agente NC-*.
- **FR-002:** O projeto deve manter o manifesto `.nimbus/agent-manifest.yaml`,
  estendido quando necessário, para descrever identidade,
  permissao de escrita, escopo de arquivos, ferramentas permitidas e gates de
  aprovacao de cada agente.
- **FR-003:** O gerador deve produzir adaptadores deterministas para VS Code/Copilot,
  Claude Code e a superficie oficialmente suportada pelo Antigravity.
- **FR-004:** O gerador deve preservar o corpo funcional e adaptar somente o
  frontmatter/metadata exigido por cada plataforma.
- **FR-005:** O gerador deve ser idempotente, explicitar erros e nunca aceitar
  destino ausente como sucesso.
- **FR-006:** O gate de paridade deve detectar arquivos ausentes, extras, drift
  funcional e perda de controles do manifesto.
- **FR-007:** Os comandos `/nc-*` devem continuar sendo gerados como bridge até
  existir uma decisao aprovada de descontinuacao.
- **FR-008:** A plataforma Antigravity deve usar somente um formato suportado e
  validado; nenhum diretorio `.agents/agents/` deve ser presumido sem contrato.
- **FR-009:** A documentacao deve explicar como selecionar/delegar o agente nativo
  em cada plataforma e quando usar o bridge `/nc-*`.
- **FR-010:** A mudanca deve incluir rollback por destino, sem alterar a fonte
  institucional durante a geracao.

## Success Criteria

- 100% dos agentes NC-* listados no manifesto possuem uma superficie gerada para
  cada integracao suportada.
- Uma alteracao na fonte atualiza todos os destinos com uma unica execucao do
  gerador.
- 100% dos destinos divergentes sao rejeitados pelo gate de paridade.
- Nenhum comando `/nc-*` existente deixa de funcionar durante a transicao.
- Uma pessoa nova consegue identificar, na documentacao, quando usar agente nativo
  e quando usar o bridge em menos de 5 minutos.

## Assumptions

- O formato nativo de VS Code/Copilot sera confirmado como custom agent
  (`.github/agents/*.agent.md`) durante a fase de pesquisa.
- O formato nativo de Claude Code sera confirmado como subagent
  (`.claude/agents/*.md`) durante a fase de pesquisa.
- O Antigravity pode continuar consumindo `.agents/skills/` enquanto seu contrato
  de agentes nativos nao estiver confirmado; o gerador deve bloquear uma
  conversao especulativa.
- A remocao dos bridges e uma decisao posterior, fora desta entrega.

## Backlog Hierarchy (EPIC/FEATURE/US)

- **EPIC:** Multi-agent Nimbus Code
- **FEATURE:** Native NC agents with synchronized platform adapters
- **US:** Usar NC-* como agente nativo; Atualizar uma definicao sem drift; Fazer
  transicao sem quebrar usuarios atuais

## Security, Privacy and LGPD

- Nao ha dados pessoais de usuario final nem credenciais na feature.
- O risco principal e perda de escopo de permissao ou ferramenta durante a
  conversao; o manifesto e o gate de paridade devem tratar isso como falha.
- Nenhum segredo pode ser incluido nos artefatos gerados.

## Out of Scope

- Remover imediatamente os comandos `/nc-*`.
- Criar um formato nao documentado para agentes do Antigravity.
- Alterar a politica de autonomia, aprovacao humana ou escopo dos agentes sem ADL.
- Portar agentes para plataformas nao listadas nesta feature.
