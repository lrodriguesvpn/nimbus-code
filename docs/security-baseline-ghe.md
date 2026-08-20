# Baseline de Segurança no GHE — Projetos e Projeto Plataforma

> Documentação gerada pela feature
> [`007-controle-seguranca-ghe-projetos-plataforma`](/specs/007-controle-seguranca-ghe-projetos-plataforma/spec.md).
> Estrutura obrigatória definida em
> [`contracts/documentation-contract.md`](/specs/007-controle-seguranca-ghe-projetos-plataforma/contracts/documentation-contract.md).
>
> **Status desta versão (MVP)**: as seções **1** e **4** abaixo estão completas
> (User Story 1 — baseline de repositório de projeto e padrão de
> tokens/secrets). As seções **2, 3, 5, 6, 7 e 8** são preenchidas em sessões
> futuras (User Story 2 — Projeto Plataforma; User Story 3 — auditoria
> contínua), conforme `tasks.md` (T021, T028, T032). Os títulos já existem
> abaixo para manter a estrutura final estável e permitir que
> `tests/docs/security-baseline-checklist.test.sh` valide incrementalmente
> cada seção conforme ela é implementada.

## 1. Baseline de Repositório de Projeto

Controles mínimos obrigatórios para **todo** repositório de projeto no GHE da
organização `venha-pra-nuvem`. Atende `FR-001` do
[`spec.md`](/specs/007-controle-seguranca-ghe-projetos-plataforma/spec.md).
Estes são exatamente os controles avaliados automaticamente pela varredura
semanal (`scripts/security-compliance-scan.sh`) — ver seção 5 (Checklist
Operacional) para o mapeamento completo controle → automação.

### Acesso (papéis e princípio de menor privilégio)

- Conceda o menor papel suficiente para a função da pessoa (ver seção 3 —
  Modelo de Acesso por Papéis — para a tabela completa de papel → permissão).
- Nunca conceda `Admin` a contribuidores individuais apenas para "facilitar" —
  administração de repositório (branch protection, secrets, webhooks) fica
  restrita a mantenedores/tech leads.
- Contas de serviço/bots (incluindo o GitHub App desta varredura) recebem
  apenas as permissões estritamente necessárias para sua função — nunca
  `Admin` genérico (ver seção 4).

### Branch protection (regras mínimas)

Na branch padrão (geralmente `main`), configurar em **Settings → Branches →
Add branch protection rule**:

- **Require a pull request before merging** — nenhum commit direto na branch
  padrão, mesmo por administradores.
- **Require approvals** — pelo menos **1** aprovador (`required_approving_review_count >= 1`).
- **Require status checks to pass before merging** — pipelines de CI
  obrigatórios (build/lint/test) marcados como obrigatórios.
- **Do not allow force pushes** e **Do not allow deletions** — nenhuma
  branch protegida pode ser reescrita ou apagada.

**Critério objetivo avaliado pela automação** (controle `branch-protection`):
`GET /repos/{owner}/{repo}/branches/{default_branch}/protection` deve retornar
`200` (branch protection existe). Ausência (`404`) é tratada como `risco`
(controle bloqueante).

### Regras de revisão de Pull Request

- Número mínimo de aprovadores: **1** (`required_approving_review_count`),
  avaliado como controle `required-review` (bloqueante — ausência ou `0`
  aprovadores exigidos gera `risco`).
- Repositórios com times/domínios sensíveis (ex.: infraestrutura, dados de
  produção) **devem** usar um arquivo `CODEOWNERS` para exigir revisão do time
  dono do código, além do mínimo de 1 aprovador.
- "Dismiss stale pull request approvals when new commits are pushed" deve
  estar habilitado para evitar aprovações obsoletas em branches que recebem
  novos commits após a revisão.

### Permissões de GitHub Actions (read/write mínimo necessário)

Em **Settings → Actions → General → Workflow permissions**:

- `Allowed actions`: restrinja para **Selected actions** (nunca deixe em
  **All actions**) — permite auditar exatamente quais Actions de terceiros
  o repositório pode executar.
- `Workflow permissions` (token padrão `GITHUB_TOKEN`): mantenha em
  **Read repository contents permission** por padrão; conceda escrita
  (`contents: write`, `issues: write` etc.) apenas nos workflows específicos
  que realmente precisam, via bloco `permissions:` do próprio workflow — nunca
  eleve o padrão do repositório inteiro para "Read and write" só para
  simplificar um workflow.

**Critério objetivo avaliado pela automação** (controle `actions-permissions`):
`GET /repos/{owner}/{repo}/actions/permissions` deve retornar `enabled: true`
e `allowed_actions != "all"`. Caso contrário, `risco` (controle bloqueante).

### Secrets (repositório vs. organização)

- Secrets **específicos de um único repositório** (ex.: credencial de deploy
  de um serviço) ficam em **Settings → Secrets and variables → Actions** do
  próprio repositório.
- Secrets **compartilhados por múltiplos repositórios** (ex.: token de
  integração usado por vários serviços do mesmo bounded context) ficam em
  **Organization secrets**, com a lista de repositórios autorizados
  explicitamente restrita (nunca "All repositories" por padrão, a menos que o
  secret seja genuinamente necessário em toda a organização).
- Nenhuma credencial (token, chave privada, senha) pode ser commitada em texto
  plano no código-fonte, mesmo em branches de teste — usar sempre GitHub
  Secrets.
- A automação de varredura **nunca lê o valor** de um secret — apenas
  verifica sua *existência* via
  `GET /repos/{owner}/{repo}/actions/secrets` (metadados: nome e data de
  atualização, nunca o valor).

**Critério objetivo avaliado pela automação** (controle `secrets-configured`,
não bloqueante): `total_count > 0` nesse endpoint é tratado como `ok`;
`total_count == 0` gera `pendente` (não eleva a `risco`, pois um repositório
sem workflows que dependam de secrets pode legitimamente não ter nenhum).

---

## 2. Governança do Projeto Plataforma

Controles específicos para o **Project V2 consolidado** usado como visão de
plataforma. Atende `FR-002` do
[`spec.md`](/specs/007-controle-seguranca-ghe-projetos-plataforma/spec.md) e
é **separado** do baseline de repositório da seção 1: aqui o foco não é branch
protection ou secrets de um repo individual, e sim **quem pode administrar o
board consolidado, suas views e seus campos críticos**.

### Diferença explícita: repositório vs. Projeto Plataforma

| Escopo | O que proteger | Onde configurar | Quem administra |
|---|---|---|---|
| **Repositório de projeto** | Branch protection, revisão obrigatória, Actions, secrets | `Settings` do próprio repositório | Maintainers / tech leads do repositório |
| **Projeto Plataforma (Project V2)** | Visibilidade cross-repo, views executivas, campos críticos, automações que escrevem no board | UI/API do Project V2 no repositório/owner que hospeda o board | Responsável de Plataforma + time admin aprovado |

### Regras mínimas de governança do Project V2 consolidado

- O board consolidado **deve permanecer privado** (`public=false`) — nenhuma
  visão cross-repo de segurança/governança deve ficar pública.
- Grants diretos de time no Project V2 ficam restritos à lista aprovada pelo
  responsável de plataforma (ex.: allowlist operacional usada pela automação em
  `SECURITY_SCAN_PLATFORM_ALLOWED_TEAM_SLUGS`).
- Views e campos críticos (ex.: `Board por Prioridade`, `Tabela — P0 Blocker`,
  campos `Status`, `Repository`, `Reviewers`) só podem ser administrados por
  perfis `owner`/`admin` do contexto de plataforma.
- Maintainers, contributors e leitores interagem com o board **por itens**,
  links de issues/PRs e workflows aprovados — não por administração direta de
  views/campos.

### Critério objetivo avaliado pela automação

Controle `platform-project-access` (bloqueante):

- o Project V2 consolidado é encontrado automaticamente no repositório/owner
  configurado para a plataforma;
- `public=false`;
- a credencial da varredura retorna `viewerCanUpdate=false` (prova de que
  continua somente leitura, sem privilégio administrativo no board);
- não existem grants diretos de times fora da allowlist aprovada;
- views/campos críticos obrigatórios existem no projeto.

Se qualquer um dos itens acima falhar, o status é `risco` ou `pendente`,
gerando Issue rastreável no repositório que hospeda a automação.

---

## 3. Modelo de Acesso por Papéis

Atende `FR-003` do
[`spec.md`](/specs/007-controle-seguranca-ghe-projetos-plataforma/spec.md).
Use sempre o menor papel suficiente para a função.

| Papel | Repositório de projeto | Projeto Plataforma | Quando usar |
|---|---|---|---|
| `owner` | Administração institucional do repositório/organização | Aprova política do board, grants excepcionais e revisão S4 | Responsável máximo pelo contexto; uso raro |
| `admin` | Configura branch rules, secrets, webhooks, Actions | Administra views/campos críticos e automações do Project V2 | Time de plataforma/governança autorizado |
| `maintainer` | Mantém backlog, revisa PRs, gerencia labels/issues | Pode operar itens do board e validar fluxo, **sem** administrar estrutura do Project V2 | Tech leads e mantenedores do fluxo |
| `contributor` | Implementa trabalho e interage com PRs/issues | Atualiza somente itens atribuídos/necessários ao trabalho | Devs e agentes atuando em tarefas do board |
| `leitor` | Consulta código, backlog e evidências | Visualiza status consolidado sem editar estrutura | Auditoria, gestão, stakeholders |

### Regras práticas

- Nunca promova `contributor` para `admin` apenas para “ajudar no board”.
- A administração da **estrutura** do Project V2 (views, campos, automações)
  fica restrita a `owner`/`admin`.
- `maintainer` é o papel operacional padrão para quem precisa acompanhar e
  validar itens do board sem superprivilégio.
- `leitor` é suficiente para auditoria e acompanhamento executivo.

---

## 4. Padrão de Tokens e Secrets de Automação

Atende `FR-004` e `FR-004a` do
[`spec.md`](/specs/007-controle-seguranca-ghe-projetos-plataforma/spec.md).

### Escopo mínimo por tipo de credencial (PAT vs. GitHub App)

| Tipo de credencial | Quando usar | Escopo mínimo |
|---|---|---|
| **GitHub App dedicado** | Automação que precisa ler/escrever em **múltiplos repositórios** de forma centralizada e auditável (ex.: varredura de segurança org-wide) | Permissões granulares por recurso, **somente as necessárias** (ex.: `metadata:read`, `administration:read`, `secrets:read`, `contents:read` para esta varredura) — nunca conceder permissões de escrita a um App cuja função é só ler e reportar |
| **PAT (Personal Access Token) de conta de serviço** | Automação já existente que interage com um único repositório ou com a API de Projects V2 do repositório local (ex.: `ensure-github-project.yml`) | Escopo mínimo necessário (`repo` + `project` quando a automação precisa escrever no Project V2 do próprio repositório) — **nunca** usar PAT de conta de serviço para varredura *org-wide* (ver regra abaixo) |
| **`GITHUB_TOKEN` padrão do Actions** | Workflows que só precisam interagir com o próprio repositório onde rodam | Já é escopado automaticamente ao repositório; ainda assim, declare o bloco `permissions:` explícito com o mínimo necessário (ex.: `contents: read`) |

### Regra: varredura org-wide usa GitHub App dedicado (nunca PAT de usuário)

A automação de varredura de conformidade de segurança
(`scripts/security-compliance-scan.sh` / `.github/workflows/security-compliance-scan.yml`)
**DEVE** se autenticar exclusivamente via **GitHub App dedicado** ("Nimbus Code
Security Auditor"), nunca via PAT de usuário ou de conta de serviço. Esta
decisão está documentada em
[ADR-0008](/docs/adr/0008-github-app-para-varredura-de-seguranca-org-wide.md),
que compara as opções (GitHub App vs. PAT de serviço vs. `GITHUB_TOKEN`
padrão) e justifica a escolha por least privilege, auditabilidade e
continuidade operacional. A criação e instalação do App é uma ação manual
administrativa (task `T004` do `tasks.md`, fora do escopo de código desta
feature) — pré-requisito para rodar o workflow em produção.

O fluxo de autenticação (implementado em
[`scripts/security-compliance-scan.sh`](/scripts/security-compliance-scan.sh)):

1. Gerar um JWT assinado com a chave privada do App (`RS256`), válido por até
   10 minutos, com `iss` = App ID.
2. Trocar o JWT por um **installation access token** de curta duração via
   `POST /app/installations/{installation_id}/access_tokens`.
3. Usar o installation access token (nunca o JWT diretamente) para as
   chamadas de leitura à API REST/GraphQL do GitHub durante a execução.

### Rotação, armazenamento e revogação

| Credencial | Armazenamento | Rotação | Revogação |
|---|---|---|---|
| Chave privada do GitHub App (`SECURITY_SCAN_APP_PRIVATE_KEY`) | GitHub Secret do repositório (nunca em texto plano no código ou em anotações de issue/PR) | Trimestral (gerar nova chave na página do App, atualizar o secret, revogar a chave antiga) — ver ação derivada no ADR-0008 | Revogar imediatamente a chave antiga na página do App assim que a nova estiver validada em uma execução bem-sucedida do workflow |
| Installation access token | Nunca armazenado — gerado em memória a cada execução do workflow e descartado ao final | N/A (expira automaticamente em ≤ 1 hora) | Expira sozinho; nenhuma ação manual necessária |
| `SECURITY_SCAN_APP_ID` / `SECURITY_SCAN_APP_INSTALLATION_ID` | GitHub Secret (não são segredos sensíveis por si só, mas mantidos como secret por consistência e para simplificar rotação) | Não se aplica (mudam apenas se o App for recriado ou reinstalado) | Não se aplica |

Todos os secrets são configurados em **Settings → Secrets and variables →
Actions** do repositório que hospeda o workflow — nunca versionados no
código-fonte, nunca colados em corpo de issue/PR/comentário.

---

## 5. Checklist Operacional de Auditoria

Atende `FR-005`, `FR-005a` e `FR-005b`.

### Frequência e escopo

- **Scan semanal automatizado**: workflow
  [`.github/workflows/security-compliance-scan.yml`](/.github/workflows/security-compliance-scan.yml)
  roda toda segunda-feira.
- **Relatório mensal consolidado**: Issue `Relatório de Conformidade de
  Segurança — YYYY-MM` agrega as execuções semanais do mês.
- **Descoberta automática**: o escopo `org-wide` usa a API do GHE para
  descobrir todos os repositórios da organização — nunca depende de lista
  manual estática.
- **Rollout progressivo**: enquanto o flag
  `security.baseline_scan.org_wide_enabled` estiver desligado, o escopo fica no
  piloto `spec-kit-workflow`; quando ligado, expande para `org-wide`.

### Checklist objetivo por controle

| Controle | Escopo | Critério `ok` | Ausência gera |
|---|---|---|---|
| `branch-protection` | Repositório | `GET /repos/{owner}/{repo}/branches/{default}/protection -> 200` | `risco` |
| `required-review` | Repositório | `required_approving_review_count >= 1` | `risco` |
| `actions-permissions` | Repositório | `enabled=true` e `allowed_actions != "all"` | `risco` |
| `secrets-configured` | Repositório | `total_count > 0` em `actions/secrets` | `pendente` |
| `platform-project-access` | Projeto Plataforma | Projeto privado, `viewerCanUpdate=false` para a credencial da varredura, sem grants fora da allowlist, views/campos críticos presentes | `risco` / `pendente` |

### Evidências operacionais que devem existir

- Logs da execução com `repos_avaliados` e `repos_com_erro`.
- Warning explícito se `repos_com_erro / repos_avaliados > 5%`.
- Issues abertas/atualizadas para cada finding com `status != ok`.
- Relatório mensal publicado mesmo quando não houver desvios abertos.

---

## 6. Procedimento de Não Conformidade

Toda `Evidência de Auditoria` com `status != ok` vira uma Issue rastreável,
seguindo o schema de
[`finding-schema.md`](/specs/007-controle-seguranca-ghe-projetos-plataforma/contracts/finding-schema.md).

### Campos obrigatórios da Issue

- `priority:P0-blocker` para controles bloqueantes; `priority:P2-medium` para
  os demais.
- `Responsável inicial`: Tech Lead/mantenedor do repositório ou responsável de
  plataforma, conforme o alvo do finding.
- `Prazo sugerido para correção`:
  - `P0-blocker`: **7 dias corridos**
  - `P2-medium`: **30 dias corridos**
- `Critério de validação`: a próxima execução semanal deve retornar
  `status: ok` para o mesmo `finding_id`.
- Marcador de deduplicação:
  `<!-- security-baseline-finding-id: security-baseline:{repo}:{controle} -->`

### Fluxo operacional

1. A automação cria/atualiza a Issue idempotente.
2. O time dono do repositório/projeto confirma a evidência e define o
   responsável humano final.
3. A correção é feita manualmente no GHE; a automação **não** corrige nada.
4. Quando o controle volta a `ok`, a Issue é fechada automaticamente pela
   próxima varredura (ou manualmente, após validação).
5. O relatório mensal lista desvios ainda abertos e os fechados no período.

---

## 7. Referência ao Fluxo Nimbus Code

Esta feature **não cria processo paralelo** de governança.

- Labels e prioridades reaproveitam a taxonomia já documentada em
  [`docs/label-taxonomy-and-autonomous-dev.md`](/docs/label-taxonomy-and-autonomous-dev.md).
- O board/Project V2 segue o fluxo Nimbus Code já existente; a automação desta
  feature apenas produz evidência (Issues + relatório mensal) que entra no
  mesmo pipeline normal de triagem e execução.
- Para features S4 como esta, a revisão humana obrigatória continua valendo —
  nenhum finding ou rollout org-wide pode contornar esse gate.

---

## 8. Dependências de Workflows com Projects

Atende `FR-008`.

### Regra geral

Workflows que **escrevem** no Project V2 consolidado usam credencial dedicada
de escopo mínimo para aquele board; workflows que **apenas leem** a postura de
segurança org-wide usam o GitHub App da varredura.

### Credenciais mínimas por caso

| Caso | Credencial recomendada | Escopo mínimo | Armazenamento |
|---|---|---|---|
| Workflow que escreve no Project V2 do repositório local | PAT de conta de serviço (ex.: `VPNDEV_PROJECT_TOKEN`) | `repo` + `project`, restrito ao repositório/board necessário | GitHub Secret do repositório |
| Workflow central de varredura org-wide | GitHub App `Nimbus Code Security Auditor` | `metadata:read`, `administration:read`, `secrets:read`, `contents:read` | `SECURITY_SCAN_APP_ID`, `SECURITY_SCAN_APP_PRIVATE_KEY`, `SECURITY_SCAN_APP_INSTALLATION_ID` |
| Workflow que só interage com o próprio repositório | `GITHUB_TOKEN` | `contents: read` por padrão + bloco `permissions:` explícito | Nativo do Actions |

### Regras adicionais

- `GITHUB_TOKEN` padrão **não substitui** o GitHub App para leitura cross-repo
  org-wide nem substitui um PAT quando o workflow precisa escrever em Projects
  V2 fora do escopo do próprio job.
- Todo secret de workflow fica em **Settings → Secrets and variables → Actions**;
  nunca em texto plano no repositório.
- Tokens/PATs usados para Projects devem ter rotação definida (mínimo:
  trimestral) e owner explícito.
- Declarar sempre `permissions:` no workflow com o menor conjunto necessário.
