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
| **Feature slug** | `suporte-cursor-kiro` |
| **Complexidade estimada** | S3 *(cruza múltiplos artefatos institucionais — gerador de agentes NC-*, integrações `specify` CLI, testes de paridade, documentação; não envolve dado sensível/segurança crítica)* |
| **Bounded Context** | `spec-kit-workflow` |
| **PR de referência / Issue** | novo |
| **Data alvo de entrega** | sem data |

> S0 = doc · S1 = função isolada · S2 = módulo · S3 = múltiplos módulos ·
> S4 = arquitetura, segurança, dados ou integração crítica

## Nimbus-Code — SLO Alvo desta Feature

*Preencher para componentes novos ou alterados. Alimenta o Observability Gate do
plan.md — alertas serão configurados com base nesses valores.*

| Componente | Latência p99 (ms) | Taxa de erro máx. (%) | Disponibilidade alvo | RTO | RPO |
|---|---|---|---|---|---|
| Gerador de sync de agentes NC-* (estendido para Cursor e Kiro) | — | 0% (falha bloqueia CI) | — | — | — |
| Teste de paridade/drift (5 alvos: vscode, claude, antigravity, cursor, kiro) | — | 0% (falha bloqueia CI) | — | — | — |

> Componentes são scripts/CI locais, sem SLA de runtime contratual — latência/disponibilidade não se aplicam; a taxa de erro máxima é enforced via testes bloqueantes.

## Nimbus-Code — Objetivo e Contexto

**Objetivo:** Estender a paridade multi-agente do Nimbus Code — estabelecida na
spec 024 (`multi-agent-integration-claude-antigravity`) para Copilot, Claude
Code e Antigravity — para incluir **Cursor** e **Kiro** como novas integrações
agênticas suportadas. Isso inclui (1) os 12 comandos agnósticos `/speckit-*`
(via `specify integration install cursor-agent` / `specify integration install
kiro-cli`, ambas já integrações **built-in** do `specify` CLI) e (2) os 9
agentes institucionais `/nc-*` (via extensão do gerador
`scripts/lib/nc-agent-sync.py`, que hoje só suporta `vscode`, `claude` e
`antigravity`), sem remover ou degradar nenhuma das três integrações já
suportadas.

**Motivação:** A spec 024 registrou explicitamente, em `Assumptions`, que
"esta spec não cobre a sincronização de outras integrações além de
Copilot/Claude/Antigravity (ex.: Gemini, Cursor) — pode ser avaliado em spec
futura se houver demanda" (`specs/024-multi-agent-integration-claude-antigravity/spec.md`).
Essa demanda surgiu: o time quer suportar Cursor e Kiro como opções adicionais
de IDE agêntica. Investigação técnica confirmou que ambos já existem como
integrações **built-in** no catálogo do `specify` CLI (`cursor-agent` e
`kiro-cli`), com `multi_install_safe: yes` para os dois — um perfil de risco
**menor** do que o Antigravity teve na spec 024 (que não era
`multi_install_safe` e exigia CLI `v1.20.5+`). O gap real está nos agentes
`/nc-*`, que não são gerenciados pelo `specify` CLI e precisam do mesmo
mecanismo de geração/sincronização criado na spec 024, agora estendido para
dois novos alvos.

**Achado do Harness Gate (HRN-0006) — contagem correta de agentes:** a spec 024
descrevia "9 agentes NC-*"; essa contagem está desatualizada. O `EXPECTED_AGENTS`/
`AGENTS` hardcoded em `scripts/sync-nc-agents-to-integrations.sh` e
`scripts/lib/nc-agent-sync.py` hoje lista 15, mas `.github/skills/nc-*`
(fonte real) já tem **18** — `nc-bug-assess`, `nc-bug-fix` e `nc-bug-test`
existem na origem e não estão nesses arrays, reproduzindo exatamente o
antipadrão já documentado em HRN-0006 ("lista hardcoded que fica
desatualizada, em vez de glob sobre o diretório-fonte real"). Esta spec **não
corrige retroativamente** a ausência desses 3 agentes nas integrações já
existentes (Claude/Antigravity) — isso é um gap pré-existente, fora de
escopo, a ser tratado separadamente (ex.: `/speckit-converge` na linhagem da
spec 025). Porém, esta spec **MUST** implementar a extensão para Cursor e
Kiro com **descoberta dinâmica** (glob sobre `.github/skills/nc-*`), não com
mais uma lista hardcoded — para não repetir o mesmo erro em 2 alvos novos.

**Critério de done (alto nível):** Um dev consegue rodar qualquer um dos 12
comandos `/speckit-*` e qualquer um dos agentes `/nc-*` a partir do Cursor ou
do Kiro, com o mesmo comportamento e gates de governança das três integrações
já suportadas; o teste de paridade/drift já existente (criado na spec 024) é
estendido para cobrir os 5 alvos sem regressão nos 3 já cobertos; a instalação
de Cursor/Kiro não modifica nenhum arquivo já gerenciado por Copilot, Claude ou
Antigravity; e o VS Code continua expondo **apenas** o orquestrador único
`@nimbus` (regra estabelecida na spec 025 — `ADL: SPEC-025 pivot` em
`scripts/lib/nc-agent-sync.py`), sem qualquer regressão de poluição de menu
mesmo com dois novos alvos adicionados ao gerador.

## Nimbus-Code — Hybrid Collaboration Model

| Papel | Responsabilidades | Critério de handoff | Escalação |
|---|---|---|---|
| Agente | Rodar `specify integration install cursor-agent` e `specify integration install kiro-cli`; estender `scripts/lib/nc-agent-sync.py` (`TARGETS`, `GENERATED_ROOTS`, lógica de renderização por alvo) para os 2 novos destinos; estender os testes de paridade/drift (`tests/multi-agent-integration/*.bats`); atualizar `docs/developer-guide.md` | Antes de qualquer merge para a branch principal | Dev responsável pelo template |
| Humano | Validar que a instalação de Cursor/Kiro em ambiente isolado não corrompe as integrações já existentes; aprovar a extensão do teste de paridade antes do rollout | Após teste isolado de cada integração nova, decide se segue para a branch principal | Tech lead |

> Para contexto **WEB**: não aplicável — esta feature não introduz superfície
> web nova.

## Clarifications

### Session 2026-09-22 (auditoria `/nc-critic` — investigação técnica direta + confirmação do usuário)

Diferente de uma clarificação puramente de preferência de negócio, os 3 pontos
abaixo foram resolvidos com **evidência técnica direta**: instalação isolada
em `/tmp` de `cursor-agent` e `kiro-cli` via `specify init`, e consulta à
documentação oficial de cada IDE. As decisões de design resultantes foram
então confirmadas com o usuário.

- Q: Qual formato de arquivo/pasta o Cursor espera para comandos customizados? → A: **`.cursor/skills/<nome>/SKILL.md`** — confirmado via instalação isolada (`specify init --integration cursor-agent`); é a mesma convenção já usada pelos 12 comandos `/speckit-*` nesse alvo. Frontmatter usa `name`, `description`, `compatibility`, `metadata` (não usa `tools` como o Claude).
- Q: Os agentes NC-* devem reusar essa convenção de Skills no Cursor, ou criar um orquestrador único (como fizemos para o VS Code na spec 025)? → A: **Reusar `.cursor/skills/nc-<agente>/SKILL.md`**, sem orquestrador único — não há evidência de que o seletor de Skills do Cursor sofra o mesmo problema de poluição de menu do VS Code. Decisão do usuário nesta auditoria.
- Q: Qual formato de arquivo/pasta o Kiro espera para os comandos `/speckit-*`? → A: **`.kiro/prompts/speckit.<nome>.md`** — confirmado via instalação isolada (`specify init --integration kiro-cli --ignore-agent-tools`); arquivo plano, sem subpasta, separador `.` em vez de `-` no nome do comando (`/speckit.plan`, não `/speckit-plan`).
- Q: Os agentes NC-* devem usar essa mesma convenção de prompts genéricos no Kiro? → A: **Não — usar o mecanismo nativo de "Custom agents" do Kiro** (`.kiro/agents/nc-<agente>.md`, documentado em `https://kiro.dev/docs/custom-agents/`), distinto de `.kiro/prompts/`. Espelha exatamente o pivot já feito para o Claude na spec 025 (`.claude/agents/` em vez de `.claude/skills/` para os agentes institucionais). Decisão do usuário nesta auditoria.
- Q: Qual é a versão mínima de CLI exigida pelo Kiro (paralelo ao `v1.20.5+` do Antigravity)? → A: **Nenhuma versão mínima é verificada pelo `specify` CLI hoje** — a instalação só falha se o binário `kiro-cli` não estiver no `PATH` (mensagem: "kiro-cli not found, install from https://kiro.dev/docs/cli/"), sem checagem de versão. FR-009 foi ajustado para refletir isso; se uma exigência de versão for descoberta durante a implementação, deve ser tratada como achado novo, não como suposição desta spec.

Todas as 3 pendências originais foram resolvidas nesta sessão — nenhum
`[NEEDS CLARIFICATION]` remanescente nesta spec.

## Nimbus-Code — Critérios de Aceitação (formato BDD)

> **AC-1**
> **Given** o repositório já tem Copilot, Claude Code e Antigravity instalados e funcionais (spec 024)
> **When** o dev roda `specify integration install cursor-agent`
> **Then** os 12 comandos `/speckit-*` passam a existir na pasta de destino do Cursor, com o mesmo conteúdo funcional das demais integrações, e nenhum arquivo de `.github/skills/`, `.claude/skills/` ou `.agents/skills/` é alterado
> **Test ref:** `test_AC1_cursor_speckit_commands_installed`

> **AC-2**
> **Given** os agentes `/nc-*` hoje só existem para `vscode`, `claude` e `antigravity`
> **When** o gerador de sync de agentes NC-* (`scripts/lib/nc-agent-sync.py`) é executado com destino `cursor`
> **Then** os agentes passam a existir em `.cursor/skills/nc-<agente>/SKILL.md`, com o mesmo conteúdo institucional (incl. blocos de ALIAS e reforços de governança) e o frontmatter no formato esperado pelo Cursor (`name`, `description`, `compatibility`, `metadata`)
> **Test ref:** `test_AC2_nc_agents_synced_to_cursor`

> **AC-3**
> **Given** o Kiro exige CLI próprio (`kiro-cli`, conforme catálogo do `specify`)
> **When** o dev roda `specify integration install kiro-cli`
> **Then** os 12 comandos `/speckit-*` são instalados na pasta de destino do Kiro, com qualquer pré-requisito de CLI comunicado claramente, e nenhum arquivo das integrações já existentes é alterado
> **Test ref:** `test_AC3_kiro_speckit_commands_installed`

> **AC-4**
> **Given** os agentes `/nc-*` também precisam existir no Kiro
> **When** o gerador de sync de agentes NC-* é executado com destino `kiro`
> **Then** os agentes passam a existir em `.kiro/agents/nc-<agente>.md` (mecanismo nativo de Custom agents do Kiro, não `.kiro/prompts/`), com o mesmo conteúdo institucional e os campos esperados pelo Kiro (`name`, `description`, `tools`, `prompt`)
> **Test ref:** `test_AC4_nc_agents_synced_to_kiro`

> **AC-5**
> **Given** as cinco pastas de agentes NC-* (`vscode` via orquestrador único, `claude`, `antigravity`, `cursor`, `kiro`) devem sempre conter os agentes equivalentes entre si
> **When** um dev edita um `SKILL.md` de agente NC-* apenas em `.github/skills/` e tenta abrir PR/rodar CI sem rodar o gerador de sync
> **Then** o teste de paridade (bats), agora cobrindo os 5 alvos, falha de forma bloqueante, apontando exatamente qual agente e qual destino está desatualizado
> **Test ref:** `test_AC5_nc_agents_parity_gate_five_targets`

> **AC-6**
> **Given** a regra da spec 025 de que o VS Code expõe apenas o orquestrador único `@nimbus` (nenhum arquivo solto `nc-*.agent.md` em `.github/agents/`)
> **When** os dois novos alvos (Cursor, Kiro) são adicionados ao gerador
> **Then** o teste de paridade continua validando que `.github/agents/` contém exclusivamente `nimbus.agent.md`, sem qualquer regressão de poluição de menu causada pela extensão
> **Test ref:** `test_AC6_vscode_single_orchestrator_regression`

> **AC-7**
> **Given** `docs/developer-guide.md` hoje documenta apenas as três integrações da spec 024
> **When** a spec é implementada
> **Then** o manual do dev passa a listar os 12 comandos e os agentes NC-* para as cinco integrações suportadas, incluindo o perfil de risco (`multi_install_safe`) de Cursor e Kiro comparado ao das demais
> **Test ref:** `test_AC7_developer_guide_documents_five_integrations`

> *(Mínimo: 1 critério por feature — 7 fornecidos.)*

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Dev usa Cursor com paridade total às integrações existentes (Priority: P1)

Um dev que prefere trabalhar no Cursor quer usar o Nimbus Code sem abrir mão de
nenhum recurso institucional (comandos `/speckit-*` e agentes `/nc-*`), do
mesmo jeito que já é possível hoje com Copilot, Claude Code e Antigravity.

**Why this priority**: Cursor é `multi_install_safe` e não exige CLI dedicado
(integração via IDE) — perfil de risco baixo e provável IDE de maior demanda
entre as duas novas integrações.

**Independent Test**: Rodar `specify integration install cursor-agent` e o
gerador de sync NC-* com destino `cursor` em um repositório de teste; verificar
que os 12 comandos e os agentes existem e funcionam, sem nenhum arquivo das
integrações já existentes (Copilot/Claude/Antigravity) ser alterado.

**Acceptance Scenarios**:

1. **Given** um repositório com as três integrações já instaladas, **When** o dev instala a integração Cursor, **Then** os 12 comandos `/speckit-*` e os agentes `/nc-*` ficam disponíveis no Cursor sem alterar nenhum arquivo das demais integrações.
2. **Given** a integração Cursor instalada, **When** um agente `/nc-*` é editado apenas na origem (`.github/skills/`), **Then** o teste de paridade acusa a desatualização no destino Cursor.

---

### User Story 2 - Dev usa Kiro com paridade total às integrações existentes (Priority: P1)

Um dev que prefere trabalhar com Kiro (CLI) quer o mesmo nível de paridade
institucional já disponível para as demais integrações.

**Why this priority**: Mesma prioridade da User Story 1 — ambas as integrações
novas são `multi_install_safe`, com risco comparável entre si e menor que o
histórico do Antigravity; não há motivo para sequenciar uma antes da outra
dentro do P1.

**Independent Test**: Rodar `specify integration install kiro-cli` e o gerador
de sync NC-* com destino `kiro` em um repositório de teste, incluindo a
verificação de qualquer pré-requisito de CLI específico do Kiro.

**Acceptance Scenarios**:

1. **Given** um repositório com as integrações já existentes instaladas, **When** o dev instala a integração Kiro, **Then** os 12 comandos `/speckit-*` e os agentes `/nc-*` ficam disponíveis no Kiro sem alterar nenhum arquivo das demais integrações.
2. **Given** o Kiro exigir uma versão mínima de CLI não disponível no ambiente, **When** o dev tenta instalar, **Then** o processo comunica claramente o pré-requisito antes de prosseguir (mesmo padrão de aviso já usado para o Antigravity na spec 024).

---

### User Story 3 - VS Code continua expondo só o `@nimbus`, mesmo com 5 integrações no gerador (Priority: P2)

Como **qualquer dev usando VS Code/Copilot**, quero que o menu de agentes
continue mostrando apenas `@nimbus`, mesmo depois de Cursor e Kiro serem
adicionados ao gerador, para que o menu não volte a ficar poluído com 15+ `@nc-*`
individuais.

**Why this priority**: é uma regra de regressão já validada e imposta por CI
antes desta feature (spec 025) — o risco real é que a extensão do gerador para
2 novos alvos introduza, por engano, algum arquivo solto em `.github/agents/`.

**Independent Test**: Rodar `python3 scripts/lib/nc-agent-sync.py check
--target vscode` depois de estender o gerador para Cursor e Kiro e confirmar
que `.github/agents/` continua contendo somente `nimbus.agent.md`.

**Acceptance Scenarios**:

1. **Given** o gerador estendido para 5 alvos, **When** o teste de paridade é executado para o alvo `vscode`, **Then** ele continua passando sem nenhum arquivo `nc-*.agent.md` solto.
2. **Given** um dev tenta adicionar manualmente um arquivo `nc-<algo>.agent.md` em `.github/agents/` por engano, **When** o teste de paridade roda, **Then** ele falha de forma bloqueante, identificando o arquivo como regressão de poluição de menu.

---

### User Story 4 - Documentação reflete as cinco integrações suportadas (Priority: P3)

Como **um dev novo no projeto**, quero que `docs/developer-guide.md` liste
todas as integrações suportadas (Copilot, Claude Code, Antigravity, Cursor,
Kiro) e suas diferenças de risco, para escolher a integração certa sem precisar
ler o código do gerador.

**Why this priority**: reforça a entrega das User Stories 1–3, mas é a de menor
risco/urgência — a capacidade técnica já funciona mesmo sem a atualização
documental, embora a doc desatualizada gere confusão.

**Independent Test**: Revisar `docs/developer-guide.md` e confirmar que a
seção "Agentes disponíveis por integração" lista as 5 integrações com seus
respectivos `multi_install_safe` e exigências de CLI.

**Acceptance Scenarios**:

1. **Given** a seção de integrações do developer guide hoje lista 3 integrações, **When** a feature é concluída, **Then** a seção passa a listar 5, incluindo o perfil de risco de cada uma.

### Edge Cases

- O que acontece se `specify integration install cursor-agent`/`kiro-cli` for executado antes de os agentes `/nc-*` terem sido sincronizados para esses alvos (ordem de instalação)?
- Como o teste de paridade se comporta se uma 6ª integração for adicionada no futuro sem atualizar `TARGETS`/`GENERATED_ROOTS` — o gate detecta a ausência de forma clara?
- O que acontece se o binário `kiro-cli` não estiver no `PATH` durante a instalação (sem checagem de versão mínima, conforme confirmado nesta auditoria)?
- Cursor é `"no CLI (IDE)"` — como a instalação e a validação de paridade são feitas sem um terminal de CLI dedicado para esse alvo?
- Como o gerador lida com o fato de Cursor usar `SKILL.md` (mesma família de Claude/Antigravity) enquanto Kiro usa um formato nativo de "Custom agents" totalmente diferente (`.kiro/agents/*.md`, campos `name`/`description`/`tools`/`prompt`) — a lógica de renderização por alvo precisa de um terceiro "formato" além dos dois já existentes?
- Como o processo evita que a extensão do gerador para 2 novos alvos reintroduza, por acidente, arquivos `nc-*.agent.md` soltos em `.github/agents/` (regressão da spec 025)?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O dev MUST conseguir rodar `specify integration install cursor-agent` para instalar os 12 comandos `/speckit-*` no Cursor, sem alterar nenhum arquivo já gerenciado por Copilot, Claude Code ou Antigravity.
- **FR-002**: O sistema MUST estender `scripts/lib/nc-agent-sync.py` (`TARGETS`, `GENERATED_ROOTS` e lógica de renderização) para incluir `cursor` como novo alvo dos agentes `/nc-*`, gerando cada agente em `.cursor/skills/nc-<agente>/SKILL.md` — mesma convenção já usada pelo Cursor para os 12 comandos `/speckit-*` (confirmado via instalação isolada; decisão da sessão de clarificação 2026-09-22). Frontmatter MUST usar os campos esperados pelo Cursor (`name`, `description`, `compatibility`, `metadata`), não o formato `{name, description, tools}` usado para Claude.
- **FR-003**: O dev MUST conseguir rodar `specify integration install kiro-cli` para instalar os 12 comandos `/speckit-*` no Kiro, respeitando qualquer pré-requisito de CLI, sem alterar arquivos das demais integrações.
- **FR-004**: O sistema MUST estender `scripts/lib/nc-agent-sync.py` para incluir `kiro` como novo alvo dos agentes `/nc-*`, gerando cada agente no mecanismo nativo de **Custom agents** do Kiro (`.kiro/agents/nc-<agente>.md`), **não** na convenção genérica de prompts (`.kiro/prompts/`) usada pelos comandos `/speckit-*` — decisão que espelha o pivot já feito para o Claude na spec 025 (decisão da sessão de clarificação 2026-09-22).
- **FR-005**: O teste de paridade/drift (`tests/multi-agent-integration/*.bats`) MUST cobrir os 5 alvos (`vscode`, `claude`, `antigravity`, `cursor`, `kiro`) e falhar de forma bloqueante se qualquer um ficar desatualizado ou ausente.
- **FR-006**: O `.github/agents/` MUST continuar contendo exclusivamente `nimbus.agent.md` após a extensão do gerador — nenhum arquivo `nc-*.agent.md` solto pode ser reintroduzido (regressão da spec 025), independentemente de quantos novos alvos forem adicionados ao gerador.
- **FR-007**: `docs/developer-guide.md` MUST ser atualizado para documentar as 5 integrações suportadas, incluindo `multi_install_safe` e exigência de CLI de cada uma.
- **FR-008**: A instalação de Cursor ou Kiro MUST NOT modificar nenhum arquivo já gerenciado pelas integrações Copilot, Claude Code ou Antigravity.
- **FR-009**: A instalação do Kiro MUST validar apenas que o binário `kiro-cli` está disponível no `PATH`, sem checagem de versão mínima — investigação confirmou que o `specify` CLI não impõe uma versão mínima para esse alvo (diferente do Antigravity, que exige `v1.20.5+`); se a ausência do binário for detectada, o processo MUST comunicar o link oficial de instalação (`https://kiro.dev/docs/cli/`) antes de prosseguir (decisão da sessão de clarificação 2026-09-22).
- **FR-010**: O gerador MUST descobrir dinamicamente, via glob, tanto os agentes NC-* (`.github/skills/nc-*`) quanto os comandos `/speckit-*` proprietários do Nimbus Code que não vêm do `specify` CLI (hoje um subconjunto incompleto listado em `EXTRA_SPECKIT_SKILLS`) — não via lista hardcoded — mitigação direta do antipadrão documentado em HRN-0006. **Decisão confirmada com o usuário**: esta descoberta dinâmica se aplica aos **5 alvos** (`vscode`, `claude`, `antigravity`, `cursor`, `kiro`), não apenas aos 2 novos — isso corrige, como efeito colateral arquitetural (não como tarefa dedicada de backfill), a ausência pré-existente de `nc-bug-assess`/`nc-bug-fix`/`nc-bug-test` (e `speckit-bug-*` correspondentes) em Claude/Antigravity. Não há tarefa específica de "sincronizar retroativamente" no escopo desta feature — a correção surge naturalmente da mudança de mecanismo, e deve ser destacada no PR para revisão humana explícita.

### Key Entities *(include if feature involves data)*

- **Agente NC-* (SKILL.md ou formato nativo equivalente)**: representa um agente institucional do Nimbus Code (ex.: NC-Builder, NC-Shield); hoje sincronizado para `vscode` (via orquestrador único), `claude` e `antigravity`; passa a ganhar cópias sincronizadas também para `cursor` e `kiro`.
- **Integração (`specify integration`)**: representa um agente/IDE de IA suportado pelo `specify` CLI, com atributos próprios (`multi_install_safe`, pasta raiz de destino, pós-processamento). `cursor-agent` e `kiro-cli` já existem como integrações built-in no catálogo, mas ainda não estão instaladas neste repositório.
- **Gerador de sync (`scripts/sync-nc-agents-to-integrations.sh` + `scripts/lib/nc-agent-sync.py`)**: par de scripts existentes (criados na spec 024, revisados na spec 025) responsáveis por manter as pastas de agentes NC-* e dos comandos `/speckit-*` proprietários equivalentes entre si; nesta feature, seu conjunto de alvos cresce de 3 para 5, e a descoberta de origem passa de lista hardcoded para glob (FR-010).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Um dev consegue instalar a integração Cursor ou Kiro e usar qualquer um dos 12 comandos + agentes institucionais em menos de 10 minutos, sem etapas manuais além dos comandos documentados.
- **SC-002**: 100% dos agentes NC-* estão disponíveis, com paridade de comportamento, nas 5 integrações (Copilot, Claude, Antigravity, Cursor, Kiro) após a implementação.
- **SC-003**: Zero incidentes de arquivos de uma integração sendo sobrescritos/corrompidos pela instalação de Cursor ou Kiro, validado por teste automatizado antes de qualquer merge.
- **SC-004**: 100% das tentativas de editar um agente NC-* em apenas uma das 5 pastas são detectadas pelo gate de paridade antes de chegar à branch principal.
- **SC-005**: Zero regressões no gate de "orquestrador único" do VS Code (`.github/agents/` com apenas `nimbus.agent.md`) após a extensão do gerador para os 2 novos alvos.

## Assumptions

- O CLI do `specify` já suporta oficialmente as integrações `cursor-agent` e `kiro-cli` no catálogo atualmente usado pelo template (confirmado via `specify integration list`/`info` nesta investigação); ambas aparecem como `multi_install_safe: yes`.
- O formato de arquivo/pasta que Cursor (`.cursor/skills/<nome>/SKILL.md`) e Kiro (`.kiro/agents/<nome>.md` para os agentes NC-*, `.kiro/prompts/speckit.<nome>.md` para os comandos genéricos) esperam foi confirmado por instalação isolada e consulta à documentação oficial nesta auditoria — não é mais uma incógnita para `/nc-arch`, que deve detalhar a lógica de renderização exata, não redescobrir o formato.
- Diferente do Antigravity (spec 024), nenhuma das duas novas integrações exige isolamento especial em worktree nem checagem de versão mínima de CLI — confirmado nesta auditoria (Kiro só exige o binário no `PATH`; Cursor não exige CLI, é integração de IDE).
- Esta spec não cobre a sincronização de outras integrações além das 5 já citadas (ex.: Gemini, Codex CLI, Zed) — pode ser avaliado em spec futura se houver demanda, seguindo o mesmo precedente que a própria spec 024 registrou para Cursor.
- **Efeito colateral confirmado com o usuário (achado do Harness Gate)**: `nc-bug-assess`, `nc-bug-fix`, `nc-bug-test` (e os comandos `speckit-bug-*` correspondentes) já existem em `.github/skills/` mas não estão sincronizados hoje para Claude/Antigravity, porque os arrays hardcoded desses scripts nunca foram atualizados após a criação desses 3 agentes. A decisão confirmada (FR-010) é aplicar a descoberta dinâmica aos 5 alvos, o que corrige esse gap **como efeito colateral da mudança arquitetural**, não como tarefa dedicada de backfill — sem tasks específicas de "sincronizar retroativamente" no escopo desta feature, mas com destaque explícito no PR para revisão humana.
- A regra de "orquestrador único no VS Code" (spec 025) é tratada como invariante herdada, não como escopo novo desta feature — esta spec apenas garante que ela não regride com a adição dos 2 novos alvos.
