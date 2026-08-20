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

> **Pendente** — implementado na User Story 2 (`tasks.md` T021), fora do
> escopo desta sessão (MVP). Ver
> [`spec.md` — User Story 2](/specs/007-controle-seguranca-ghe-projetos-plataforma/spec.md)
> e
> [`data-model.md` — Projeto Plataforma](/specs/007-controle-seguranca-ghe-projetos-plataforma/data-model.md).

---

## 3. Modelo de Acesso por Papéis

> **Pendente** — implementado na User Story 2 (`tasks.md` T021), fora do
> escopo desta sessão (MVP). A enumeração de papéis já está definida em
> [`data-model.md` — Perfil de Acesso](/specs/007-controle-seguranca-ghe-projetos-plataforma/data-model.md)
> (`owner`, `admin`, `maintainer`, `contributor`, `leitor`); a tabela completa
> papel → permissão → quando usar será adicionada nesta seção junto com a
> governança do Projeto Plataforma.

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

> **Pendente** — implementado na User Story 3 (`tasks.md` T028), fora do
> escopo desta sessão (MVP). A varredura automatizada dos 4 controles de
> repositório já roda semanalmente via
> [`.github/workflows/security-compliance-scan.yml`](/.github/workflows/security-compliance-scan.yml)
> (ver seção 1 acima para os critérios objetivos de cada controle); o
> checklist operacional consolidado e o relatório mensal (`Compliance
> Report`) serão documentados nesta seção junto com a padronização de
> auditoria contínua (User Story 3).

---

## 6. Procedimento de Não Conformidade

> **Pendente (detalhamento completo)** — parte do fluxo já está em produção
> nesta versão MVP: toda `Evidência de Auditoria` com `status != ok` gerada
> pelos 4 avaliadores da seção 1 é automaticamente registrada como uma Issue
> rastreável no próprio repositório avaliado, seguindo o formato definido em
> [`contracts/finding-schema.md`](/specs/007-controle-seguranca-ghe-projetos-plataforma/contracts/finding-schema.md):
> título, corpo com controle/status/evidência/instrução de correção, labels
> `security-baseline` + prioridade (`priority:P0-blocker` para controles
> bloqueantes, `priority:P2-medium` para os demais), e um marcador HTML
> `<!-- security-baseline-finding-id: ... -->` usado para deduplicação
> (reaproveita o padrão `speckit-deduplication-by-id` — ver
> `docs/reuse-catalog.yaml`). O detalhamento completo do procedimento
> (responsável, prazo por prioridade) é adicionado na User Story 3
> (`tasks.md` T028).

---

## 7. Referência ao Fluxo Nimbus Code

> **Pendente** — implementado na User Story 3 (`tasks.md` T032), fora do
> escopo desta sessão (MVP). Ver desde já
> [`docs/label-taxonomy-and-autonomous-dev.md`](/docs/label-taxonomy-and-autonomous-dev.md)
> para a taxonomia de labels (`priority:*`, `status:*`, `agent:*`) usada pelas
> issues de não conformidade geradas por esta automação — nenhum processo de
> governança paralelo é criado por esta feature.

---

## 8. Dependências de Workflows com Projects

> **Pendente** — implementado na User Story 3 (`tasks.md` T032), fora do
> escopo desta sessão (MVP). Esta seção documentará as permissões e secrets
> mínimos exigidos por workflows que leem/escrevem no Project V2 consolidado
> (Projeto Plataforma), complementando a seção 2 (Governança do Projeto
> Plataforma).
