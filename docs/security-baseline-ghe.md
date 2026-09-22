# Baseline de Segurança no GHE — Projetos e Projeto Plataforma

> Documentação gerada pela feature
> [`007-controle-seguranca-ghe-projetos-plataforma`](/specs/007-controle-seguranca-ghe-projetos-plataforma/spec.md).
> Estrutura obrigatória definida em
> [`contracts/documentation-contract.md`](/specs/007-controle-seguranca-ghe-projetos-plataforma/contracts/documentation-contract.md).
>
> **Status desta versão**: seções **1 a 8** completas (User Stories 1–3).
> Seções **9 a 18** adicionadas pela
> [issue #450](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/issues/450)
> (User Story 4 — governança de PR e segurança de código): Rulesets e matriz
> de branches protegidas, required checks, cobertura, SAST, SCA, Secret
> Scanning/Push Protection, exceções, SLA, evidências, pré-requisitos de
> plano, permissões do GitHub App e piloto. A configuração versionada que
> parametriza essas políticas é
> [`.github/security-governance.json`](/.github/security-governance.json).
>
> **Nada aqui foi aplicado automaticamente em repositórios**: Rulesets,
> required checks, GHAS, Secret Scanning e o GitHub App são configurações
> administrativas humanas; a automação apenas **detecta e reporta**. O rollout
> org-wide continua bloqueado pelo gate S4 (T038).

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

Na branch padrão (geralmente `main`) — e em todas as branches da matriz da
seção 9 (produção, `release/*`, `hotfix/*`) — configurar **preferencialmente
via Repository/Organization Rulesets** (**Settings → Rules → Rulesets**). A
proteção clássica (**Settings → Branches → Add branch protection rule**) é
aceita apenas por **compatibilidade** e é reportada como tal pela varredura
(controle `rulesets-configured` = `pendente`). Regras mínimas:

- **Require a pull request before merging** — nenhum commit direto na branch
  padrão, mesmo por administradores.
- **Require approvals** — pelo menos **1** aprovador (`required_approving_review_count >= 1`).
- **Require status checks to pass before merging** — pipelines de CI
  obrigatórios (build/lint/test) marcados como obrigatórios.
- **Do not allow force pushes** e **Do not allow deletions** — nenhuma
  branch protegida pode ser reescrita ou apagada.

**Critério objetivo avaliado pela automação** (controle
`branch-protection-default`, que substitui o id legado `branch-protection` —
issues abertas com o id antigo são reaproveitadas/fechadas automaticamente):
a proteção **efetiva** da branch padrão, combinando
`GET /repos/{owner}/{repo}/rules/branches/{default_branch}` (Rulesets) e
`GET /repos/{owner}/{repo}/branches/{default_branch}/protection` (clássica),
deve exigir Pull Request, bloquear force push e deleção e ter ao menos um
status check obrigatório. Qualquer item ausente é `risco` (bloqueante); `403`
em ambas as fontes é erro de permissão explícito (nunca `ok`). As demais
branches protegidas são avaliadas pelo controle
`branch-protection-required-patterns` (seção 9).

### Regras de revisão de Pull Request

- Número mínimo de aprovadores: **1** (`required_approving_review_count`),
  avaliado como controle `required-review` (bloqueante — ausência ou `0`
  aprovadores exigidos gera `risco`). O mesmo controle verifica dismiss de
  aprovações obsoletas, revisão de CODEOWNERS (quando o arquivo existe) e
  resolução de conversas (`pendente` quando ausente).
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
e `allowed_actions != "all"`, e
`GET /repos/{owner}/{repo}/actions/permissions/workflow` deve retornar
`default_workflow_permissions: read` e
`can_approve_pull_request_reviews: false`. Caso contrário, `risco` (controle
bloqueante); se o segundo endpoint não puder ser lido, `pendente`.

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

> **Atenção**: `secrets-configured` significa **apenas** que existem GitHub
> Actions secrets configurados. Ele **não** detecta secrets expostos no
> código e **não** substitui GitHub Secret Scanning/Push Protection — esses
> são os controles `secret-scanning-enabled`,
> `secret-scanning-push-protection-enabled` e `secret-alerts` (seção 14).

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
| **GitHub App dedicado** | Automação que precisa ler/escrever em **múltiplos repositórios** de forma centralizada e auditável (ex.: varredura de segurança org-wide) | Permissões granulares por recurso, **somente as necessárias** e **somente leitura** para esta varredura (lista completa na seção 17 e no ADR-0008) — nunca conceder permissões de escrita a um App cuja função é só ler e reportar |
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
| `branch-protection-default` | Repositório | Proteção efetiva (Ruleset e/ou clássica) da branch padrão com PR obrigatório, force push e deleção bloqueados e ≥ 1 status check | `risco` |
| `branch-protection-required-patterns` | Repositório | Todas as branches de produção e padrões configurados (`release/*`, `hotfix/*`…) cobertos por Ruleset com baseline, e branches existentes protegidas | `risco` (branch existente desprotegida) / `pendente` (padrão sem Ruleset) |
| `rulesets-configured` | Repositório | Ruleset ativo aplicado à branch padrão | `pendente` (só clássica) / `risco` (nenhuma) |
| `required-review` | Repositório | `required_approving_review_count >= 1`, dismiss stale, CODEOWNERS quando existir | `risco` (conversas: `pendente`) |
| `required-pr-checks` | Repositório | Todos os contexts de `required_status_checks` obrigatórios; strict quando exigido | `risco` (strict: `pendente`) |
| `required-test-checks` | Repositório | Checks de `unit_tests`/`integration_tests` obrigatórios | `risco` |
| `required-coverage-check` | Repositório | Check `coverage` obrigatório **ou** `not-applicable` justificado com testes obrigatórios | `risco` |
| `codeql-enabled` | Repositório | Default setup `configured` ou análises CodeQL publicadas | `risco` (plano sem GHAS: `pendente`) |
| `codeql-recent` | Repositório | Última análise na branch padrão ≤ `max_analysis_age_days` (8) | `risco` |
| `codeql-alerts` | Repositório | 0 alertas CodeQL abertos `critical`/`high` | `risco` |
| `dependabot-alerts-enabled` | Repositório | `GET /vulnerability-alerts -> 204` | `risco` |
| `dependabot-security-updates-enabled` | Repositório | `automated-security-fixes`: `enabled=true`, `paused=false` | `risco` (pausado: `pendente`) — não bloqueante |
| `dependency-review-enabled` | Repositório | Workflow com `actions/dependency-review-action` e check `dependency-review` obrigatório | `risco` / `pendente` |
| `secret-scanning-enabled` | Repositório | `security_and_analysis.secret_scanning.status=enabled` | `risco` (campo ausente: `pendente`) |
| `secret-scanning-push-protection-enabled` | Repositório | `security_and_analysis.secret_scanning_push_protection.status=enabled` | `risco` (campo ausente: `pendente`) |
| `secret-alerts` | Repositório | 0 alertas de secret scanning abertos (lidos com `hide_secret=true`) | `risco` |
| `actions-permissions` | Repositório | `enabled=true`, `allowed_actions != "all"`, token padrão `read` | `risco` |
| `secrets-configured` | Repositório | `total_count > 0` em `actions/secrets` (apenas existência) | `pendente` |
| `platform-project-access` | Projeto Plataforma | Projeto privado, `viewerCanUpdate=false` para a credencial da varredura, sem grants fora da allowlist, views/campos críticos presentes | `risco` / `pendente` |

**Regra de API indisponível** (vale para todos os controles): `403` por
permissão insuficiente do GitHub App é registrado como **erro explícito**
(`repos_com_erro`, com a permissão exigida na evidência); endpoint/recurso
indisponível na instância ou no plano (`404`, "Advanced Security must be
enabled" etc.) vira `pendente` com a limitação na evidência. **Nenhum dos dois
casos é tratado como `ok`.**

**Formato de evidência**: `repository=<org/repo> | branch=<branch ou padrão> |
endpoint=<método e caminho da API -> HTTP> | resultado=<o que foi observado>`.

### Evidências operacionais que devem existir

- Logs da execução com `repos_avaliados` e `repos_com_erro`.
- Warning explícito se `repos_com_erro / repos_avaliados > 5%`.
- Issues abertas/atualizadas para cada finding com `status != ok`.
- Relatório mensal publicado mesmo quando não houver desvios abertos.

---

## 6. Procedimento de Não Conformidade

Toda `Evidência de Auditoria` com `status != ok` vira uma Issue rastreável
**no repositório que hospeda a varredura** (`SECURITY_SCAN_ISSUE_TARGET=report-repository`,
padrão), escrita com o `GITHUB_TOKEN` efêmero do workflow (`issues: write`) —
o GitHub App da auditoria permanece **somente leitura**. O repositório
avaliado aparece no título, no campo **Repositorio** e no marcador de
deduplicação. Criar issues diretamente em cada repositório
(`scanned-repository`) exigiria credencial com `Issues: write` em toda a
organização e depende de nova decisão aprovada (ADR-0008). O formato segue o
schema de
[`finding-schema.md`](/specs/007-controle-seguranca-ghe-projetos-plataforma/contracts/finding-schema.md).

### Campos obrigatórios da Issue

- `priority:P0-blocker` para controles bloqueantes; `priority:P2-medium` para
  os demais (prazos por severidade na seção 16).
- `Responsável inicial`: Tech Lead/mantenedor do repositório ou responsável de
  plataforma, conforme o alvo do finding.
- `Prazo sugerido para correção`:
  - `P0-blocker`: **7 dias corridos** (`secret-alerts`: **1 dia** — revogar/rotacionar em até 24h)
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
| Workflow central de varredura org-wide | GitHub App `Nimbus Code Security Auditor` | Somente leitura: `metadata`, `administration`, `contents`, `secrets`, `code_scanning_alerts` (security events), `dependabot_alerts`, `secret_scanning_alerts`; org: `projects` (seção 17) | `SECURITY_SCAN_APP_ID`, `SECURITY_SCAN_APP_PRIVATE_KEY`, `SECURITY_SCAN_APP_INSTALLATION_ID` |
| Escrita das issues de não conformidade/relatório | `GITHUB_TOKEN` do job de varredura | `issues: write` **somente** no repositório que hospeda o workflow | Nativo do Actions (`SECURITY_SCAN_ISSUES_TOKEN`) |
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

---

## 9. Baseline de Rulesets e Branch Protection

Atende `FR-009` (issue #450). A proteção de branches é **parametrizável por
repositório** em [`.github/security-governance.json`](/.github/security-governance.json)
(`branches.*` e `branch_rules.*`) — a varredura lê a cópia de cada repositório
e, na ausência dela, usa a configuração deste template. Nenhum repositório é
obrigado a ter exatamente as mesmas branches.

| Variável (`branches.*`) | Significado | Padrão deste template |
|---|---|---|
| `default_branch` | Branch padrão (`auto` = descoberta via `GET /repos/{owner}/{repo}`) | `auto` |
| `production_branches` | Branches de produção com nome fixo | `["main"]` |
| `protected_patterns` | Padrões fnmatch de branches principais | `["release/*", "hotfix/*"]` |
| `additional_branches` | Outras branches principais configuráveis (ex.: `develop`) | `[]` |

**Preferência**: Repository Rulesets (ou Organization Rulesets herdados) para
todas as branches acima. A **proteção clássica** de branch continua aceita
**somente por compatibilidade** (ex.: instâncias/planos sem Rulesets) e é
sempre identificada na evidência como `fonte=classic (compatibilidade)`.

### Matriz de branches protegidas

| Regra (cada branch/padrão da tabela acima) | Ruleset (regra) | Proteção clássica (compatibilidade) | Parâmetro em `branch_rules` | Avaliado por |
|---|---|---|---|---|
| Pull Request antes do merge (proíbe push direto) | `pull_request` | Require a pull request before merging | `block_direct_push` | `branch-protection-default`, `branch-protection-required-patterns` |
| ≥ 1 aprovador | `pull_request.required_approving_review_count` | Require approvals | `required_approving_review_count` | `required-review`, `branch-protection-required-patterns` |
| Revisão de CODEOWNERS (quando o arquivo existir) | `pull_request.require_code_owner_review` | Require review from Code Owners | `require_code_owner_review` | `required-review` |
| Dismiss de aprovações obsoletas | `pull_request.dismiss_stale_reviews_on_push` | Dismiss stale approvals | `dismiss_stale_reviews` | `required-review`, `branch-protection-required-patterns` |
| Proibir force push | `non_fast_forward` | Do not allow force pushes | `block_force_push` | `branch-protection-*` |
| Proibir exclusão | `deletion` | Do not allow deletions | `block_deletion` | `branch-protection-*` |
| Status checks obrigatórios | `required_status_checks` | Require status checks to pass | `require_status_checks` | `required-pr-checks` |
| Branch atualizada antes do merge (quando suportado) | `required_status_checks.strict_required_status_checks_policy` | Require branches to be up to date | `require_up_to_date_branch` | `required-pr-checks` (`pendente` se ausente) |
| Resolução de comentários (quando suportado) | `pull_request.required_review_thread_resolution` | Require conversation resolution | `require_conversation_resolution` | `required-review` (`pendente` se ausente) |
| Merge queue (quando adotada pela organização) | `merge_queue` | Require merge queue | `merge_queue` = `optional`/`required`/`disabled` | Evidência informativa; workflows publicam checks em `merge_group` |

**Critério objetivo** (`branch-protection-required-patterns`): para cada alvo
declarado, a varredura (1) lista as branches existentes
(`GET /repos/{owner}/{repo}/branches`), (2) lista os Rulesets ativos
aplicáveis (`GET /repos/{owner}/{repo}/rulesets?includes_parents=true` +
`GET /repos/{owner}/{repo}/rulesets/{id}`) e (3) avalia a proteção efetiva de
cada branch existente que casa com o padrão
(`GET /repos/{owner}/{repo}/rules/branches/{branch}` +
`GET /repos/{owner}/{repo}/branches/{branch}/protection`). Branch existente
sem o baseline → `risco`; padrão sem Ruleset e sem branches existentes →
`pendente` (branches futuras nasceriam desprotegidas). A evidência lista
repositório, padrão/branch, endpoints e resultado por alvo.

## 10. Matriz de Required Checks

Todo PR para a branch padrão, produção, `release/*` e `hotfix/*` exige os
checks abaixo, publicados pelo GitHub Actions com **nomes de job estáveis** e
configurados como **required status checks** no Ruleset. A lista esperada por
repositório fica em `required_status_checks` de
`.github/security-governance.json`; o check `governance-config` impede que um
check "não aplicável" seja listado como obrigatório.

| Categoria | Check (context) | Workflow publicador | Bloqueia o merge quando | Neste repositório |
|---|---|---|---|---|
| Build | `build` | `pr-quality-gates.yml` (`quality_gates.build.command`) | comando de build falha | `scripts/validate-repo-static.sh` (bash -n, shellcheck, JSON/YAML, actionlint) |
| Testes unitários | `unit-tests` | `pr-quality-gates.yml` (`quality_gates.unit_tests.command`) | qualquer teste falha ou o check não executa | `scripts/run-tests.sh` |
| Testes de integração | `integration-tests` | `pr-quality-gates.yml` | idem, quando existirem | N/A declarado (suíte única `run-tests.sh`) — **não** listado como obrigatório |
| Cobertura | `coverage` | `pr-quality-gates.yml` + `scripts/coverage-gate.py` | cobertura < mínimo, redução sem exceção ou relatório não publicado | N/A declarado (seção 11) — **não** listado como obrigatório |
| SAST | `CodeQL` (+ `codeql-analyze (<linguagem>)`) | `codeql.yml` + Code Scanning | alerta novo com security severity ≥ High | `actions`, `python` |
| SCA | `dependency-review` | `dependency-review.yml` | dependência vulnerável ≥ high, proibida, licença fora da política ou recurso indisponível | obrigatório |
| Secrets | `secret-scan` | `secret-scan.yml` (gitleaks pinado) | tentativa de introdução de secret nos commits do PR | obrigatório |
| Governança | `governance-config` | `pr-quality-gates.yml` | config inválida, exceção vencida, Action sem pin | obrigatório |

Regras:

- Um check obrigatório que **não executa** mantém o merge bloqueado
  ("Expected — waiting for status to be reported") — por isso os workflows
  de checks obrigatórios **não usam filtro de `paths`**.
- Etapas dependentes de linguagem são **declaradas**, não inventadas: cada
  repositório preenche `quality_gates.*.command` (ex.: `mvn -B verify`,
  `npm test -- --coverage`, `pytest --cov`). Etapa sem comando exige
  `not_applicable_reason` e é reportada como **NÃO APLICÁVEL** no resumo do job.
- `test-suite.yml` (jobs `Bootstrap Crítico (bloqueante)` e
  `Suíte de Testes Mandatória (relatório)`) permanece inalterado; a promoção
  de qualquer job a required check continua sendo decisão administrativa
  humana (ver [`docs/testing-policy.md`](/docs/testing-policy.md), seção 5).

## 11. Política de Cobertura de Testes

| Regra | Valor padrão | Onde |
|---|---|---|
| Cobertura global mínima | **80%** (`coverage.global_min_percent`) | `scripts/coverage-gate.py --min` |
| Cobertura mínima do código alterado | **80%** (`coverage.diff_min_percent`), quando o relatório tem granularidade de linha | `--diff-min` + `--base-ref origin/<base>` |
| Redução de cobertura | **Proibida** sem exceção aprovada (`coverage.baseline_percent` versionado; `allow_decrease_without_exception=false`) | `--baseline` |
| Publicação | Relatório LCOV ou Cobertura XML publicado como artefato `coverage-report` (`if-no-files-found: error`) + resumo no check `coverage` | `pr-quality-gates.yml` |
| Falha | Exit 1 (política violada) ou 2 (relatório ausente/inválido/sem linhas) | `coverage-gate.py` |

**Repositórios predominantemente shell/documentação** (caso deste
template): não há ferramenta de cobertura aplicável e pinada no runner, então
`coverage.mode = "not-applicable"` com `not_applicable_reason` versionado. O
job `coverage` publica explicitamente que **nenhuma métrica foi calculada**,
o check **não** é listado como obrigatório, e o gate obrigatório passa a ser a
suíte de testes (`unit-tests`). A varredura (`required-coverage-check`) só
aceita esse modo com justificativa **e** com o check de testes obrigatório.
Nenhuma métrica de cobertura é inventada.

## 12. Política de SAST (CodeQL)

- Workflow [`codeql.yml`](/.github/workflows/codeql.yml): Actions oficiais
  `github/codeql-action` fixadas por SHA; execução em PR (main, `release/**`,
  `hotfix/**`), push na branch padrão, merge queue e **semanal**; linguagens
  declaradas em `codeql.languages` (neste repositório: `actions`, `python`;
  shell não é suportado); suíte `security-extended`; resultados publicados no
  Code Scanning; `permissions` mínimas (`security-events: write` apenas no job
  de análise).
- **Bloqueio**: findings com security severity **Critical** ou **High**
  bloqueiam o merge via check `CodeQL` do Code Scanning (Settings → Code
  security → Code scanning → *Check runs failure threshold* = **High or
  higher**) e/ou regra *Require code scanning results* do Ruleset
  (`code_scanning`, `security_alerts_threshold = high_or_higher`).
- **Auditoria contínua**: `codeql-enabled`, `codeql-recent` (análise na
  branch padrão com até 8 dias) e `codeql-alerts` (0 alertas abertos
  critical/high).
- **Exceções**: alerta só pode ser dispensado (*dismiss*) com motivo
  (`false positive`/`won't fix`/`used in tests`), comentário citando o
  Exception Record e registro em `.github/security-exceptions.json` (seção 15).

## 13. Política de SCA e Segurança de Dependências

| Controle | Como | Avaliado por |
|---|---|---|
| Dependabot alerts | Settings → Code security → Dependabot alerts (requer Dependency graph) | `dependabot-alerts-enabled` (inclui contagem de alertas critical/high abertos) |
| Dependabot security updates | Settings → Code security → Dependabot security updates | `dependabot-security-updates-enabled` (não bloqueante) |
| Dependabot version updates | [`.github/dependabot.yml`](/.github/dependabot.yml) (`github-actions` e `npm` em `/platform-governance`) | check `governance-config` |
| Dependency Review em PR | [`dependency-review.yml`](/.github/workflows/dependency-review.yml) + [`.github/dependency-review-config.yml`](/.github/dependency-review-config.yml) | `dependency-review-enabled` + required check `dependency-review` |
| Lockfiles e versões fixadas | Commitar lockfiles do ecossistema (`package-lock.json`, `poetry.lock`, `go.sum`…); Actions por SHA; ferramentas baixadas com versão + checksum | revisão de PR / `governance-config` (Actions) |

Política de severidade e dependências proibidas:

- `fail-on-severity: high` — vulnerabilidade **high** ou **critical**
  introduzida bloqueia o merge (`fail-on-scopes: runtime, development`).
- Dependências proibidas: `deny-packages`/`deny-groups` (purl) no arquivo de
  configuração, alteradas somente via PR revisado por CODEOWNERS.
- Licenças: a allowlist já vigente (MIT, Apache-2.0, BSD-2/3-Clause, ISC,
  MPL-2.0, LGPL-2.1/3.0, CC0-1.0, Unlicense) foi preservada.
- Dependency Review indisponível (Dependency graph/GHAS desabilitado) **falha
  o check** por padrão (`dependency_review.unsupported_behavior = "fail"`); o
  modo `advisory` só é aceito com Exception Record ativo.
- Nenhum PAT/secret é usado nesses workflows (apenas `GITHUB_TOKEN`).

## 14. Política de Secret Scanning e Push Protection

### a) Secrets usados por workflows (GitHub Actions secrets)

- Armazenar **somente** em GitHub Secrets (repositório/organização) ou
  **Environment Secrets**; deploy usa **ambientes protegidos** com revisores
  obrigatórios (aprovação manual quando aplicável) e branches permitidas.
- Escopo mínimo (secret de organização restrito a repositórios selecionados),
  **owner** e **rotação** definidos (mínimo trimestral), revogação imediata em
  suspeita de exposição.
- Preferir **OIDC** (`permissions: id-token: write` + federação no provedor de
  nuvem) a credenciais estáticas sempre que suportado.
- Declarar `permissions:` com menor privilégio em todo workflow.
- Nunca colocar secrets em código, logs (`::add-mask::` para valores
  derivados), issues, PRs, comentários ou artefatos.
- Controle `secrets-configured`: verifica **apenas a existência** de Actions
  secrets (metadados) — **não é** Secret Scanning.

### b) Secrets expostos no código

| Controle | Configuração | Avaliado por |
|---|---|---|
| GitHub Secret Scanning | Settings → Code security → Secret Protection → Secret scanning | `secret-scanning-enabled` |
| Push Protection | Settings → Code security → Secret scanning → Push protection (bypass só com justificativa) | `secret-scanning-push-protection-enabled` |
| Tratamento de alertas | Revogar/rotacionar na origem (**≤ 24h**), remover do código, fechar o alerta com o motivo correto | `secret-alerts` (lido com `hide_secret=true`; o valor nunca é lido/logado) |
| Verificação complementar em PR | [`secret-scan.yml`](/.github/workflows/secret-scan.yml) — gitleaks pinado com checksum, varre só os commits do PR, relatório redigido | required check `secret-scan` |

Exceções (falso positivo, segredo de teste inerte) seguem a seção 15 e são
registradas também na allowlist específica de
[`.gitleaks.toml`](/.gitleaks.toml) — nunca allowlist genérica.

## 15. Processo de Exceções

Toda exceção a qualquer controle desta política é um **Exception Record**
versionado em [`.github/security-exceptions.json`](/.github/security-exceptions.json),
alterado **somente via PR** revisado por CODEOWNERS:

| Campo | Obrigatório | Regra |
|---|---|---|
| `id` | Sim | Único (ex.: `EXC-2026-001`) |
| `control` | Sim | Id do controle (ex.: `codeql-alerts`, `coverage`, `dependency-review-enabled`, `secret-scan`) |
| `owner` | Sim | Responsável pela correção definitiva |
| `justification` | Sim | Motivo objetivo e risco residual |
| `approved_by` | Sim | Responsável de Plataforma/Segurança (diferente do owner, recomendado) |
| `created_at` / `expires_at` | Sim | `YYYY-MM-DD`; prazo máximo de **90 dias** |
| `reference` | Recomendado | Issue/alerta/PR relacionado |

- Exceção **vencida quebra o check `governance-config`** (bloqueia PRs) até
  ser renovada com nova aprovação ou removida com o controle corrigido.
- Alertas nativos (CodeQL, Dependabot, Secret Scanning) só são dispensados com
  motivo e comentário referenciando o `id` da exceção.
- Exceções nunca contêm valores de secrets.

## 16. SLA de Tratamento por Severidade

| Severidade | Exemplos | Prioridade da issue | Prazo |
|---|---|---|---|
| **Crítica — secret exposto** | alerta de secret scanning aberto, detecção do `secret-scan` | `priority:P0-blocker` | Revogar/rotacionar em **≤ 24h**; issue em **1 dia** |
| **Crítica** | CodeQL/Dependabot `critical`; branch padrão sem proteção; Secret Scanning desligado | `priority:P0-blocker` | **7 dias corridos** |
| **Alta** | CodeQL/Dependabot `high`; required checks/testes/cobertura ausentes; Push Protection desligado | `priority:P0-blocker` | **7 dias corridos** |
| **Média** | `moderate`; controles não bloqueantes (`rulesets-configured`, `dependabot-security-updates-enabled`, `secrets-configured`) | `priority:P2-medium` | **30 dias corridos** |
| **Baixa** | `low`/informativos | backlog normal | **90 dias** ou próxima revisão trimestral |

Estourar o SLA sem Exception Record ativo é tratado como não conformidade no
relatório mensal.

## 17. Evidências, Pré-requisitos de Plano/Licença e Permissões do GitHub App

### Evidências necessárias para auditoria

- Issue mensal `Relatório de Conformidade de Segurança — YYYY-MM` com % por
  controle (os 18 controles de repositório + Projeto Plataforma), desvios
  abertos e fechados e snapshots por execução.
- Issues `security-baseline` com evidência no formato
  `repository | branch/padrão | endpoint -> HTTP | resultado`.
- Logs das execuções semanais (`repos_avaliados`, `repos_com_erro`).
- Execuções dos checks obrigatórios nos PRs (resumos de `coverage`,
  `dependency-review`, `secret-scan`, CodeQL no Code Scanning).
- Exportação dos Rulesets aplicados (Settings → Rules → Rulesets → Export) e
  histórico de `.github/security-governance.json`/`security-exceptions.json`.

### Pré-requisitos de plano/licença (confirmar na instância `venha-pra-nuvem.ghe.com`)

| Recurso | Requisito |
|---|---|
| Repository Rulesets / Organization Rulesets | GitHub Enterprise Cloud (org rulesets exigem Enterprise) |
| Merge queue | Repositórios de organização no GitHub Enterprise Cloud |
| CodeQL / Code Scanning em repositórios privados/internos | **GitHub Code Security** (antigo GHAS) |
| Secret Scanning e Push Protection em repositórios privados/internos | **GitHub Secret Protection** (antigo GHAS) |
| Dependency Review em repositórios privados/internos | **GitHub Code Security** + Dependency graph |
| Dependabot alerts / security updates / version updates | Incluídos no plano (requer Dependency graph) |
| Actions de terceiros (`github/codeql-action`, `actions/*`) | Liberadas em *Allowed actions → Selected actions* da organização |
| Download de ferramentas pinadas (gitleaks, actionlint) | Runner com saída HTTPS para as releases oficiais das ferramentas |

GHE.com (data residency) pode ter disponibilidade de recursos diferente do
GitHub.com; quando uma API não existir no plano, a varredura reporta
`pendente` com a limitação na evidência — nunca `ok`.

### Permissões do GitHub App "Nimbus Code Security Auditor" (todas somente leitura)

| Permissão (read-only) | Uso | Endpoints |
|---|---|---|
| Repository: Metadata | Descoberta de repositórios, branches, Rulesets aplicáveis | `GET /orgs/{org}/repos`, `/branches`, `/rules/branches/{b}`, `/rulesets` |
| Repository: Administration | Proteção clássica, detalhes de Rulesets, permissões de Actions, Dependabot, `security_and_analysis`, CodeQL default setup | `/branches/{b}/protection`, `/rulesets/{id}`, `/actions/permissions*`, `/vulnerability-alerts`, `/automated-security-fixes`, `GET /repos/{r}`, `/code-scanning/default-setup` |
| Repository: Contents | `.github/security-governance.json`, CODEOWNERS, workflows | `/contents/{path}` |
| Repository: Secrets | Existência de Actions secrets (metadados) | `/actions/secrets` |
| Repository: Code scanning alerts | Análises e alertas CodeQL | `/code-scanning/analyses`, `/code-scanning/alerts` |
| Repository: Dependabot alerts | Contagem de alertas critical/high | `/dependabot/alerts` |
| Repository: Secret scanning alerts | Alertas abertos (`hide_secret=true`) | `/secret-scanning/alerts` |
| Organization: Projects | Governança do Project V2 | GraphQL `projectsV2` |

**Nenhuma permissão de escrita** é concedida ao App. A escrita de issues usa o
`GITHUB_TOKEN` do workflow (`issues: write`) apenas no repositório de
relatório. Detalhes e justificativa: [ADR-0008](/docs/adr/0008-github-app-para-varredura-de-seguranca-org-wide.md).

## 18. Procedimento de Piloto e Validação

1. **Pré-requisitos humanos**: GitHub App criado/instalado com as permissões
   da seção 17 (T004/T063), secrets configurados (T005), GHAS/Code Security e
   Secret Protection habilitados nos repositórios piloto (T064).
2. **Configuração do piloto** (bounded context `spec-kit-workflow`): aplicar
   os Rulesets da seção 9 e marcar como obrigatórios os checks da seção 10
   (T065) — ação administrativa humana.
3. **Validação de PR**: abrir PR de teste e confirmar que os checks
   `governance-config`, `build`, `unit-tests`, `CodeQL`, `dependency-review` e
   `secret-scan` são reportados e que uma falha proposital (teste quebrado,
   dependência vulnerável, secret fictício) bloqueia o merge (T066).
4. **Varredura em dry-run**: `gh workflow run security-compliance-scan.yml -f
   dry_run=true` e revisar evidências dos 18 controles (sem falso positivo).
5. **Varredura real no piloto** (2 execuções semanais) e revisão do relatório
   mensal.
6. **Gate S4 (T038)**: somente após aprovação humana registrada o flag
   `security.baseline_scan.org_wide_enabled` pode ser alterado. Esta
   documentação **não** habilita rollout org-wide.
