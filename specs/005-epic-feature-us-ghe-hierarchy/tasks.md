# Tasks: Epic/Feature/US Hierarchy no GHE com Spec Kit

**Input**: Design documents from `/specs/005-epic-feature-us-ghe-hierarchy/`

**Prerequisites**: `plan.md` ✅, `spec.md` ✅, `graph.yaml` ✅, `graph.md` ✅, `impact-map.md` ✅

**Organization**: Tasks agrupadas por User Story para entrega incremental e teste independente.

---

## Phase 1: Setup (Pré-requisitos compartilhados)

**Purpose**: Artefatos de grafo e plan.md exigidos pelo preset antes de qualquer implementação

- [x] T001 Criar `specs/005-epic-feature-us-ghe-hierarchy/plan.md` com todos os gates preenchidos
- [x] T002 [P] Criar `specs/005-epic-feature-us-ghe-hierarchy/graph.yaml` com nós, arestas e externals
- [x] T003 [P] Criar `specs/005-epic-feature-us-ghe-hierarchy/graph.md` com diagramas Mermaid (por código e por business)
- [x] T004 [P] Criar `specs/005-epic-feature-us-ghe-hierarchy/impact-map.md` com análise de risco e plano de rollback (S3 — obrigatório)

**Checkpoint**: Artefatos de planejamento completos — implementação pode começar.

---

## Phase 2: User Story 1 — Configurar Issue Types na org GHE (P1) 🎯

**Goal**: `setup-github-project.sh` cria os 5 Issue Types (Epic, Feature, User Story, Task, Bug) de forma idempotente

**Independent Test**: Rodar `setup-github-project.sh` 2x consecutivamente no mesmo repo/org de sandbox; verificar que Issue Types existem e não foram duplicados.

- [x] T005 [US1] Adicionar função `setup_issue_types` em `scripts/setup-github-project.sh` que:
  - Consulta `organization.issueTypes` via GraphQL antes de criar
  - Cria apenas os tipos ausentes (idempotente)
  - Detecta ausência de suporte (GHE Server legado) e ativa modo degradado com mensagem clara
  - Tipos a criar: Epic (cor roxo), Feature (cor azul), User Story (cor verde), Task (cor cinza), Bug (cor vermelho)
  - **Nota**: já implementado (passo `[4/9]` de `scripts/setup-github-project.sh`) — a lógica está inline no script em vez de extraída para uma função nomeada `setup_issue_types`, mas cobre 100% do requisito (query prévia, criação idempotente por tipo ausente, detecção de modo degradado). Validado em 2026-08-20 rodando `check-issue-types` do novo helper (`.specify/scripts/bash/create-github-issue-hierarchy.sh`) contra `venha-pra-nuvem/nimbus-code-spec-kit-template` — retornou `native` (Issue Types já configurados na org).
- [x] T006 [US1] Atualizar numeração de passos e resumo final em `scripts/setup-github-project.sh` para incluir o novo passo de Issue Types
  - **Nota**: já implementado — passo `[4/9]` e resumo final (`[10/10]`) já listam os 5 Issue Types e a orientação de fallback via labels.

**Checkpoint**: Issue Types disponíveis na org — fluxo de filtragem por tipo funciona no board.

---

## Phase 3: User Story 2 — Hierarquia via sub-issues no fluxo do Spec Kit (P1) 🎯

**Goal**: `/speckit-specify` + `/speckit-taskstoissues` criam Feature/US/Task como sub-issues hierarquizadas no GHE

**Independent Test**: Executar o fluxo completo para uma feature de exemplo com `epic_issue` definido; verificar no GHE que as issues existem com as relações pai→filho corretas e sem duplicatas em re-execução.

- [x] T007 [US2] Estender `.specify/feature.json` (schema): documentar campo `epic_issue` (número inteiro, opcional) no arquivo `docs/developer-guide.md` e no arquivo de exemplo `feature.json` se existir
  - **Nota**: documentação já existente em `docs/developer-guide.md` seção 4.3 (Passo 2, com exemplo JSON). Não existe um arquivo de exemplo `feature.json` versionado no repo (é artefato de runtime por feature, não commitado) — nada a atualizar nesse ponto.
- [x] T008 [US2] Atualizar o script de criação de feature (`.specify/scripts/bash/create-new-feature.sh`) para:
  - Solicitar `EPIC_ISSUE` como parâmetro opcional na inicialização
  - Persistir `"epic_issue": <N>` em `.specify/feature.json` quando fornecido
  - Documentar no output que o campo pode ser preenchido manualmente depois
  - **Implementado nesta sessão**: nova flag `--epic-issue <N>` (validada como inteiro positivo), merge em `feature.json` como número (não string), refletido em `--json`/texto de saída (`EPIC_ISSUE: N`) e no help. `.github/skills/speckit-specify/SKILL.md` também passou a reconhecer o token `EPIC_ISSUE=<N>` no texto livre do `/speckit-specify` e persistir o mesmo campo. Testado com `--dry-run` e execução real em repo Git isolado (não afeta `main`).
  - **Reforço de confiabilidade (mesma sessão, follow-up)**: identificado que a extração de `EPIC_ISSUE=<N>` dependia de o agente LLM seguir uma instrução em prosa no meio de um fluxo longo do `/speckit-specify` (o comando não invoca `create-new-feature.sh` no caminho principal — ele mesmo cria o diretório/spec/feature.json via prosa). Corrigido com defesa em profundidade:
    1. `create-new-feature.sh` agora também extrai `EPIC_ISSUE=<N>` de dentro do próprio texto livre da descrição (não só via `--epic-issue`), removendo o token antes de gerar o slug/short-name — ajuda quem chama o script direto.
    2. Novo script determinístico `.specify/scripts/bash/check-epic-issue-consistency.sh`: recebe a descrição bruta original, extrai `EPIC_ISSUE=<N>` via regex bash, compara com `feature.json` e se autocorrige (via `jq`, com fallback sem `jq`) se estiver ausente/divergente. Testado com 5+ cenários em repo isolado (sem token, consistente, inconsistente, re-execução idempotente, sem `jq`).
    3. `.github/skills/speckit-specify/SKILL.md` ganhou uma seção "Mandatory Post-Execution Validation" **incondicional** (não depende de hooks/`extensions.yml`) que instrui o agente a sempre rodar o script acima como último passo, substituindo a dependência de "lembrar no meio do fluxo" por uma checagem final obrigatória e auditável.
- [x] T009 [US2] Implementar lógica de criação de sub-issues em `/speckit-taskstoissues` (`.specify/workflows/speckit/workflow.yml` ou script associado):
  - Ler `epic_issue` de `feature.json`
  - Criar issue de Feature com `type:Feature`; vinculá-la como sub-issue do Epic (se `epic_issue` definido)
  - Para cada seção `[USN]` em `tasks.md`: criar issue de User Story com `type:User Story`; vinculá-la como sub-issue da Feature
  - Para cada linha `T00N` em cada seção: criar issue de Task com `type:Task`; vinculá-la como sub-issue da US correspondente
  - **Implementado nesta sessão**: novo helper `.specify/scripts/bash/create-github-issue-hierarchy.sh` (bash + `gh` CLI, mesmo idioma de `scripts/setup-github-project.sh`) com subcomandos `ensure-feature`, `ensure-user-story`, `link-task` e `set-type`, usando as mutations GraphQL reais `addSubIssue` e `updateIssueIssueType` (confirmadas via introspecção contra `venha-pra-nuvem.ghe.com`) e o campo `subIssuesSummary`/`parent` do schema `Issue`. `.github/skills/speckit-taskstoissues/SKILL.md` foi atualizado para invocar o script no bootstrap da hierarquia e ao vincular cada Task issue.
- [x] T010 [US2] Implementar deduplicação por ID `T00N` no `/speckit-taskstoissues`:
  - Antes de criar cada issue, verificar se já existe issue com título contendo `T00N`
  - Antes de vincular sub-issue, verificar se o vínculo já existe
  - Registrar no output: "✓ T001 já existe (#N) — verificando vínculo"
  - **Implementado nesta sessão**: dedup de Task por `T00N` no título já existia (via MCP `list_issues`); passou a ser complementado pela verificação de vínculo (`link-task` checa o `parent` atual da issue antes de chamar `addSubIssue`). Feature/User Story usam um novo padrão de marcador oculto no corpo (`<!-- speckit-feature-id: ... -->` / `<!-- speckit-us-id: ... -->`), no mesmo estilo já usado por outra automação deste repositório (`security-baseline-finding-id`, ver `specs/007-.../quickstart.md`), com pré-filtro via `gh issue list --search` e confirmação exata via `jq`.
- [x] T011 [US2] Implementar fallback gracioso para orgs sem Issue Types nativos:
  - Detectar no início se a org suporta Issue Types (query `organization.issueTypes`)
  - Se não: usar labels `type:epic`, `type:feature`, `type:user-story`, `type:task` como substituto
  - Imprimir mensagem clara: `[MODO DEGRADADO] Issue Types não disponíveis — usando labels como fallback`
  - **Nota**: detecção/fallback em `scripts/setup-github-project.sh` já existia (passo `[4/9]`). Nesta sessão, a mesma detecção (`check-issue-types`) e o mesmo fallback por label foram implementados de forma independente em `create-github-issue-hierarchy.sh`, para que a criação de Feature/User Story/Task issues em `/speckit-taskstoissues` funcione corretamente também em modo degradado, sem depender de o setup do Project já ter rodado antes.
- [x] T012 [US2] Implementar alerta de limite de sub-issues:
  - Verificar count de sub-issues existentes antes de adicionar
  - Se `count >= 90`: imprimir aviso de aproximação do limite
  - Se `count >= 100`: abortar com erro claro sugerindo dividir a feature
  - **Implementado nesta sessão**: `link_sub_issue()` em `create-github-issue-hierarchy.sh` consulta `subIssuesSummary.total` do parent antes de cada vínculo; valores confirmados contra dado real do repo (`venha-pra-nuvem/nimbus-code-spec-kit-template#66` retornou `total: 22`).

**Checkpoint**: Hierarquia Epic → Feature → US → Task funciona ponta a ponta no GHE com deduplicação e fallback.

---

## Phase 4: User Story 3 — Views de Project V2 por nível hierárquico (P2)

**Goal**: `setup-github-project.sh` cria as views hierárquicas de forma idempotente

**Independent Test**: Rodar `setup-github-project.sh` em repo limpo; verificar as 6 views no Project V2. Rodar novamente; verificar que nenhuma view foi duplicada.

- [x] T013 [US3] Adicionar as 6 novas views ao array `VIEWS` em `scripts/setup-github-project.sh`:
  - "Board de Epics" (BOARD_LAYOUT, filter `type:"Epic"`)
  - "Board de Features" (BOARD_LAYOUT, filter `type:"Feature"`)
  - "Board de User Stories" (BOARD_LAYOUT, filter `type:"User Story"`)
  - "Sprint Ativo" (BOARD_LAYOUT, sem filtro inicial — orientar customização manual)
  - "Backlog Completo" (TABLE_LAYOUT, sem filtro)
  - "P0 Blocker" (TABLE_LAYOUT, filter `label:"priority:P0-blocker"`) — já existe; não duplicar
  - **Nota**: já implementado — array `VIEWS` (passo `[3/9]`) já contém as 6 views listadas acima.
- [x] T014 [US3] Atualizar o resumo final do `setup-github-project.sh` para listar as novas views e instruções de "group by" manual (a API não suporta `group by` via GraphQL)
  - **Nota**: já implementado — resumo final (`[10/10]`) lista as 8 views (6 novas + 2 legadas) e a nota de que "group by" precisa de ajuste manual na UI.

**Checkpoint**: Views hierárquicas disponíveis no Project V2 sem duplicatas.

---

## Phase 5: User Story 4 — Documentação no developer-guide e labels (P2)

**Goal**: Developer Guide tem seção clara de hierarquia Agile; labels fallback criados

**Independent Test**: Pedir a um colaborador que siga apenas o `developer-guide.md` para criar um Epic com uma Feature vinculada — sem ajuda externa.

- [x] T015 [US4] Adicionar labels de fallback em `scripts/setup-github-labels.sh`:
  - `type:epic` (cor: `6f42c1` — roxo)
  - `type:feature` (cor: `0075ca` — azul)
  - `type:user-story` (cor: `0e8a16` — verde)
  - `type:task` (cor: `cfd3d7` — cinza)
  - **Nota**: já implementado — os 4 labels (+ `type:bug`) já existem em `scripts/setup-github-labels.sh`.
- [x] T016 [US4] Adicionar seção "Hierarquia Agile (Epic → Feature → US → Task)" no `docs/developer-guide.md` com:
  - Visão geral do modelo hierárquico e mapeamento spec↔issue
  - Passos exatos: criar Epic no GHE → rodar `/speckit-specify EPIC_ISSUE=N` → rodar `/speckit-taskstoissues` → ver resultado no board
  - Tabela de mapeamento: `spec.md` = Feature issue, seção `US1` = User Story issue, linha `T001` = Task issue
  - Edge case: o que fazer quando o Epic ainda não existe
  - Edge case: modo degradado (org sem Issue Types)
  - Edge case: Features com múltiplos Epics (instruir divisão)
  - **Nota**: já implementado — seção 4 completa (4.1–4.6) já cobre todos os itens acima. Ajustada nesta sessão apenas a referência ao script auxiliar recém-criado (`create-github-issue-hierarchy.sh`) que agora executa de fato o que a seção descreve.

**Checkpoint**: Documentação completa — novo colaborador consegue executar o fluxo sem ajuda.

---

## Phase 6: Fechamento e Catálogo de Reuso

**Purpose**: Registrar padrões reutilizáveis introduzidos por esta feature

- [x] T017 Adicionar entradas ao `docs/reuse-catalog.yaml`:
  - `ghe-sub-issues-hierarchy` — padrão de criação de hierarquia Epic/Feature/US/Task via sub-issues GHE com deduplicação
  - `speckit-deduplication-by-id` — padrão de deduplicação de issues por ID `T00N` em vez de título
  - **Nota**: as duas entradas já existiam (adicionadas numa sessão anterior, antes de a automação real existir). Atualizadas nesta sessão para referenciar o script concreto `create-github-issue-hierarchy.sh` que agora implementa o padrão descrito.
  - **Follow-up nesta sessão**: adicionada uma terceira entrada, `skill-mid-flow-instruction-reliability-gate`, documentando o padrão de defesa em profundidade (hardening do script + checagem determinística autocorretiva + gate incondicional no SKILL.md) criado para resolver a fragilidade da extração de `epic_issue`, reaproveitável para qualquer outro campo de `feature.json` extraído de texto livre por um SKILL.md.

---

## Dependencies & Execution Order

- **Phase 1 (Setup)**: Sem dependências — pode começar imediatamente. ✅ Concluída
- **Phase 2 (US1 — Issue Types)**: Depende de Phase 1 ✅ — pode ser executada em paralelo com Phase 3
- **Phase 3 (US2 — Sub-issues)**: Depende de Phase 1 ✅ — pode ser executada em paralelo com Phase 2
- **Phase 4 (US3 — Views)**: Depende de Phase 2 (Issue Types necessários para filtros por tipo)
- **Phase 5 (US4 — Docs/Labels)**: Pode ser executada em paralelo com Phases 2, 3 e 4
- **Phase 6 (Fechamento)**: Depende de todas as fases anteriores

### Parallel Opportunities

- T002, T003, T004 (Phase 1): paralelos entre si ✅ já concluídos
- T005-T006 (US1) e T007-T012 (US2): paralelos entre si após Phase 1
- T015-T016 (US4): paralelos com US1, US2, US3

---

## Notes

- [P] = tasks sem dependência entre si (podem rodar em paralelo)
- [USN] = rastreabilidade da tarefa à User Story do spec.md
- Cada US pode ser testada independentemente antes de seguir para a próxima
- Commits granulares: um por tarefa ou por fase concluída
- Antes do merge: rodar `secret scanning` nos arquivos modificados

---

## Phase 7: Convergence

- [ ] T018 Adicionar um gate de validação pós-execução incondicional e determinístico em `.github/skills/speckit-taskstoissues/SKILL.md` (com um script auxiliar correspondente, no mesmo padrão de `.specify/scripts/bash/check-epic-issue-consistency.sh`) que confirme, antes de reportar conclusão, que toda issue de User Story e Task processada na execução atual está de fato vinculada ao parent correto no GHE (consultando `parent`/`subIssuesSummary` via GraphQL) — em vez de depender apenas da prosa do Outline sendo seguida corretamente pelo agente per FR-009, reuse-catalog tag `skill-mid-flow-instruction-reliability-gate` (partial)
