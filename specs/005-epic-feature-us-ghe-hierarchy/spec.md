# Feature Specification: Epic/Feature/User Story Hierarchy no GHE com Spec Kit

**Feature Branch**: `005-epic-feature-us-ghe-hierarchy`

**Created**: 2026-08-18

**Status**: Ready

**Input**: User description: "Implementar a hierarquia Agile completa (Epic → Feature → User Story → Task) no GitHub Enterprise e GitHub Projects V2, automatizando a criação e os vínculos de sub-issues a partir dos artefatos SDD via `/speckit-taskstoissues`."

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Criar e configurar os Issue Types da org GHE (Priority: P1)

Como **administrador da organização GHE**, quero configurar os Issue Types (Epic, Feature, User Story, Task, Bug) na organização para que todos os repositórios do Spec Kit possam classificar issues com a hierarquia Agile correta.

**Why this priority**: É o pré-requisito fundamental — sem os Issue Types configurados, nenhum dos fluxos de filtragem, agrupamento ou vinculação por hierarquia funcionam no GitHub Projects v2. Bloqueia todos os demais itens.

**Independent Test**: Pode ser testado de forma independente criando uma issue num repositório de teste e verificando que os tipos "Epic", "Feature", "User Story" aparecem no seletor de type. Entrega valor imediato de classificação mesmo sem os demais fluxos.

**Acceptance Scenarios**:

1. **Given** que sou admin da org `venha-pra-nuvem`, **When** acesso *Org Settings → Planning → Issue types*, **Then** vejo os tipos Epic, Feature, User Story, Task e Bug disponíveis com cores distintas.
2. **Given** que os tipos foram criados, **When** crio uma nova issue num repositório da org, **Then** consigo selecionar o tipo "Epic", "Feature" ou "User Story" no campo de tipo da issue.
3. **Given** que Issue Types estão configurados, **When** abro um GitHub Project v2 e adiciono a coluna "Type", **Then** cada issue exibe seu tipo e consigo filtrar por `type:"Epic"` na view.

---

### User Story 2 — Criar hierarquia Epic → Feature → US → Task via Sub-issues no fluxo do Spec Kit (Priority: P1)

Como **desenvolvedor/PO usando o Spec Kit**, quero que o processo `/speckit-specify` → `/speckit-plan` → `/speckit-tasks` → `/speckit-taskstoissues` crie automaticamente a hierarquia correta de issues no GHE (Epic como pai de Features, Feature como pai de User Stories, User Story como pai das Tasks), para que o board do projeto reflita a estrutura de negócio sem trabalho manual adicional.

**Why this priority**: É o coração da feature — a razão de ser desta spec. Transforma o processo textual do Spec Kit em uma hierarquia visual rastreável no GHE.

**Independent Test**: Pode ser testado executando o fluxo completo para uma feature de exemplo e verificando no GHE que as issues existem com as relações pai→filho corretas. Entrega rastreabilidade imediata de Epic até Task.

**Acceptance Scenarios**:

1. **Given** que um Epic Issue existe no GHE com número `#N`, **When** o `/speckit-specify` é executado para uma feature vinculada a esse Epic, **Then** a issue de Feature criada aparece como sub-issue do Epic `#N`.
2. **Given** que uma Feature Issue existe (sub-issue do Epic), **When** o `/speckit-taskstoissues` é executado, **Then** cada User Story (`[US1]`, `[US2]`…) do `tasks.md` gera uma issue de tipo "User Story" vinculada como sub-issue da Feature.
3. **Given** que as User Story issues existem, **When** o `/speckit-taskstoissues` cria as Tasks (`T001`, `T002`…), **Then** cada Task issue é criada como sub-issue da User Story correspondente (`[US1]` → parent da US1 issue).
4. **Given** que a hierarquia foi criada, **When** acesso o GitHub Project v2 e habilito o campo "Sub-issue progress", **Then** cada Feature mostra o percentual de conclusão das suas User Stories e cada Epic mostra o progresso das Features.
5. **Given** que já existem issues criadas anteriormente, **When** executo `/speckit-taskstoissues` novamente, **Then** o comando detecta as issues já existentes (deduplicação) e não cria duplicatas, apenas atualiza vínculos ausentes.

---

### User Story 3 — Configurar GitHub Project v2 com Views por nível hierárquico (Priority: P2)

Como **PO ou Tech Lead**, quero que o script `setup-github-project.sh` crie automaticamente as views do GitHub Project v2 organizadas por nível de hierarquia (Board de Epics, Board de Features, Board de User Stories, Sprint Board), para que o time tenha visibilidade do progresso em cada nível sem configurar manualmente as views.

**Why this priority**: Complementa a rastreabilidade — sem as views certas, a hierarquia existe mas não é visível de forma útil. Pode ser configurado manualmente enquanto P1 é implantado.

**Independent Test**: Pode ser testado rodando `setup-github-project.sh` num repositório limpo e verificando que as views aparecem no Project com os filtros corretos.

**Acceptance Scenarios**:

1. **Given** que o `setup-github-project.sh` foi executado, **When** abro o GitHub Project v2, **Then** vejo as views: "Board de Epics", "Board de Features", "Board de User Stories", "Sprint Ativo", "Backlog Completo" e "P0 Blocker".
2. **Given** que issues de diferentes tipos existem no projeto, **When** seleciono a view "Board de Features", **Then** vejo apenas issues de tipo "Feature" organizadas por Status, com o campo "Parent issue" (Epic) visível.
3. **Given** que a view "Sprint Ativo" existe, **When** acesso essa view, **Then** vejo apenas issues de tipo "User Story" e "Task" do iteration atual, agrupadas por issue pai (Feature).
4. **Given** que o script é executado num projeto que já tem views, **Then** o script é idempotente: não duplica views existentes.

---

### User Story 4 — Documentar o processo de hierarquia no developer-guide e templates (Priority: P2)

Como **novo membro do time** chegando ao Spec Kit, quero encontrar documentação clara sobre como criar EPICs, Features e User Stories no GHE com o processo Nimbus Code, incluindo os comandos exatos e o mapeamento entre artefatos do Spec Kit e issues do GHE, para poder começar a trabalhar sem precisar perguntar a ninguém.

**Why this priority**: Sem documentação, o processo fica na cabeça de quem o criou. A doc é o multiplicador de adoção.

**Independent Test**: Pode ser testado pedindo a um novo colaborador que siga apenas o `developer-guide.md` para criar um Epic com duas Features e verificar se consegue sem ajuda externa.

**Acceptance Scenarios**:

1. **Given** que sou novo no time, **When** leio a seção "Hierarquia Agile (Epic → Feature → US)" do `developer-guide.md`, **Then** encontro os passos exatos: criar o Epic no GHE, rodar `/speckit-specify` com referência ao Epic, e ver o resultado no board.
2. **Given** que o `setup-github-labels.sh` é executado, **Then** os labels `type:epic`, `type:feature`, `type:user-story` são criados no repositório (complementando os Issue Types da org).
3. **Given** que a documentação existe, **When** consulto o mapeamento de artefatos, **Then** tenho clareza de que: spec.md = Feature, seções US = User Stories, tasks T001 = Tasks GHE.

---

### Edge Cases

- O que acontece quando o Epic Issue ainda não existe no GHE ao rodar `/speckit-specify`? O fluxo deve guiar o usuário a criar o Epic primeiro (ou criá-lo automaticamente como draft).
- O que acontece quando a org não tem Issue Types configurados (ex.: GHE Server versão antiga)? O fluxo deve degradar graciosamente usando labels como fallback (`type:epic`, `type:feature`, `type:user-story`) sem quebrar.
- O que acontece quando uma Feature cobre múltiplos Epics? A spec deve documentar que Features pertencem a um único Epic (1:1), e features multi-Epic devem ser divididas.
- O que acontece com a deduplicação em `taskstoissues` quando a mesma task é re-executada após um `tasks.md` regenerado? O ID da task (`T001`) é a chave de deduplicação — não o título.
- O que acontece quando sub-issues atingem o limite de 100 por parent? O fluxo deve alertar o usuário com mensagem clara.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O processo DEVE suportar a criação de uma issue de tipo "Epic" no GHE como ponto de partida para uma iniciativa, antes de qualquer `/speckit-specify`.
- **FR-002**: O comando `/speckit-specify` DEVE aceitar um parâmetro opcional `EPIC_ISSUE` (número da issue Epic) e registrá-lo em `.specify/feature.json` para uso downstream.
- **FR-003**: O comando `/speckit-taskstoissues` DEVE criar a issue de Feature com `type:Feature` e vinculá-la como sub-issue do Epic informado (se `EPIC_ISSUE` estiver em `feature.json`).
- **FR-004**: O comando `/speckit-taskstoissues` DEVE criar issues de User Story (uma por seção `[USN]` em `tasks.md`) com `type:"User Story"` e vinculá-las como sub-issues da Feature issue.
- **FR-005**: O comando `/speckit-taskstoissues` DEVE criar issues de Task (uma por linha `T00N`) com `type:Task` e vinculá-las como sub-issues da User Story issue correspondente.
- **FR-006**: O script `setup-github-project.sh` DEVE criar as views de Project v2 para cada nível hierárquico (Epic, Feature, User Story, Sprint) com filtros e campos pré-configurados.
- **FR-007**: O script `setup-github-labels.sh` DEVE incluir labels de fallback `type:epic`, `type:feature`, `type:user-story` para orgs sem suporte a Issue Types nativos.
- **FR-008**: O `developer-guide.md` DEVE incluir uma seção dedicada ao fluxo de hierarquia Agile com mapeamento explícito entre artefatos Spec Kit e issues GHE.
- **FR-009**: O processo de deduplicação do `/speckit-taskstoissues` DEVE verificar, além do título, se a issue já está vinculada como sub-issue do parent correto.
- **FR-010**: O fluxo DEVE funcionar com degradação graciosa quando Issue Types nativos não estiverem disponíveis na org, usando labels como substituto.

### Key Entities

- **Epic**: Issue de tipo "Epic" no GHE; representa uma iniciativa ou programa de negócio; pode ter múltiplas Features como sub-issues; corresponde a um Milestone no contexto de rastreamento de prazo.
- **Feature**: Issue de tipo "Feature" no GHE; sub-issue de um Epic; tem correspondência 1:1 com um diretório `specs/NNN-slug/` do Spec Kit; contém User Stories como sub-issues.
- **User Story**: Issue de tipo "User Story" no GHE; sub-issue de uma Feature; corresponde a uma seção `US1..USN` do `spec.md`; contém Tasks como sub-issues.
- **Task**: Issue de tipo "Task" no GHE; sub-issue de uma User Story; gerada pelo `/speckit-taskstoissues` a partir de cada linha `T00N` do `tasks.md`.
- **feature.json**: Arquivo `.specify/feature.json`; estendido com campo `epic_issue` para rastrear o Epic pai de uma feature.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Um desenvolvedor novo consegue criar um Epic com 2 Features e 4 User Stories cada, completamente vinculadas no GHE, seguindo apenas o `developer-guide.md`, em menos de 30 minutos na primeira vez.
- **SC-002**: 100% das issues de Task geradas pelo `/speckit-taskstoissues` aparecem como sub-issues da User Story correta no GHE (sem vínculos soltos).
- **SC-003**: O campo "Sub-issue progress" nos Epics do GitHub Project v2 reflete em tempo real o percentual de Tasks concluídas, sem intervenção manual.
- **SC-004**: O script `setup-github-project.sh` cria as views de hierarquia em menos de 60 segundos e é idempotente (rodar 2x não duplica views).
- **SC-005**: O fluxo funciona sem erros em orgs sem Issue Types nativos (GHE Server), usando labels como fallback — com mensagem clara indicando o modo degradado.
- **SC-006**: A deduplicação do `/speckit-taskstoissues` evita 100% de criação de issues duplicadas quando o comando é re-executado sobre a mesma `tasks.md`.

---

## Assumptions

- A organização `venha-pra-nuvem` usa GitHub Enterprise Cloud (GHEC), que suporta Issue Types nativos. Se algum repositório estiver em GHE Server, o fallback via labels será usado.
- O GitHub Projects v2 está habilitado para a organização e os repositórios.
- O campo "group by" nas views do Project v2 será configurado manualmente na UI após a criação via script (a API do GitHub não suporta definir `group by` via GraphQL mutation).
- O sub-issue progress roll-up automático cobre apenas um nível direto de hierarquia; para roll-up profundo (Epic → Task), é necessário consulta via API ou GitHub Actions.
- Cada Feature pertence a exatamente um Epic (relação 1:1). Features que cobrem múltiplos Epics devem ser divididas antes de iniciar o `/speckit-specify`.
- O número do Epic Issue no GHE é informado pelo Dev ao rodar `/speckit-specify` (parâmetro opcional); não é gerado automaticamente.
- A integração com JIRA/Azure DevOps via `nimbus-code-backlog-sync` continua usando a hierarquia Epic/Story/Task nativa de cada ferramenta (não é alterada por esta feature).
