# 0008 — GitHub App dedicado para varredura de segurança org-wide

- **Status:** Em revisão _(inalterado pela issue #450 — a aceitação continua dependendo da aprovação humana S4, T037/T038)_
- **Data:** 2026-08-19 (adendo de permissões: 2026-09-22, issue #450)
- **Autores:** @copilot (sessão `/speckit-plan`, feature 007)
- **Contexto:** `007-controle-seguranca-ghe-projetos-plataforma`
- **Revisores:** _a definir (owner de plataforma / administrador da organização)_

---

## Contexto e Problema

A feature 007 introduz uma automação que varre semanalmente **todos os
repositórios da organização** no GHE para detectar não conformidades de
segurança (branch protection, revisão obrigatória, permissões de Actions,
secrets configurados) e a matriz de acesso do Projeto Plataforma (Project V2
consolidado). Essa varredura precisa de uma credencial capaz de ler
configurações administrativas em repositórios que, na maioria dos casos, não
pertencem ao time que mantém a automação.

O repositório já usa, para necessidades semelhantes (`ensure-github-project.yml`),
um PAT (`VPNDEV_PROJECT_TOKEN`) de uma conta de serviço com escopos amplos
(`repo` + `project`). Repetir esse padrão para a varredura de segurança
concentraria em um único PAT de usuário um nível de acesso de leitura sobre
**toda a organização**, o que diverge do princípio de least privilege da
constituição do projeto (`docs/ai-code-quality-and-observability.md` seção 11;
`.specify/memory/constitution.md`, "Infraestrutura como Código" / least
privilege).

Esta decisão define qual mecanismo de autenticação a automação de varredura
deve usar.

## Drivers de Decisão

- Least privilege — a credencial deve ter apenas os escopos de leitura estritamente necessários.
- Auditabilidade — a organização precisa distinguir ações da automação de ações de humanos nos audit logs.
- Continuidade operacional — a credencial não pode depender do ciclo de vida de uma conta de usuário individual.
- Consistência com o padrão já existente no repositório (`gh` CLI, GitHub Actions), evitando introduzir uma stack nova.

## Opções Consideradas

- **Opção A** — GitHub App dedicado, instalado na organização, permissões somente-leitura
- **Opção B** — PAT de conta de serviço com escopo `read:org` + `repo` (leitura)
- **Opção C** — `GITHUB_TOKEN` padrão do Actions, executando um workflow por repositório

## Análise das Opções

### Opção A — GitHub App dedicado

Um GitHub App ("Nimbus Code Security Auditor") é criado e instalado na
organização com permissões granulares **somente leitura** (`metadata:read`,
`administration:read`, `secrets:read`, `contents:read` e, após o adendo da
issue #450, `code_scanning_alerts:read`, `dependabot_alerts:read`,
`secret_scanning_alerts:read` e `organization_projects:read` — ver seção
"Adendo" abaixo). O workflow gera um installation access token de curta
duração a cada execução.

- ✅ Permissões granulares por recurso (não herda escopos amplos de um usuário)
- ✅ Não fica atrelado ao ciclo de vida de uma conta de pessoa (sem "token órfão")
- ✅ Ações aparecem no audit log atribuídas ao App, distintas de ações humanas
- ✅ Token de instalação é de curta duração (reduz janela de exposição em caso de log leak)
- ❌ Requer setup administrativo inicial (criar o App, gerar chave privada, instalar na org) — não é self-service via código

### Opção B — PAT de conta de serviço

Reaproveita o padrão já usado em `ensure-github-project.yml`.

- ✅ Setup mais rápido (já existe o padrão no repositório)
- ❌ PAT clássico não permite granularidade de "somente metadata/branch-protection" — herda escopo `repo` inteiro (leitura E escrita, mesmo que a automação só precise ler)
- ❌ Atrelado à conta que o gerou; expira ou quebra se a conta for desativada
- ❌ Concentra em um único secret de longa duração o acesso de leitura a toda a organização

### Opção C — `GITHUB_TOKEN` padrão por repositório

- ✅ Zero configuração de credencial adicional
- ❌ `GITHUB_TOKEN` é escopado ao repositório onde o workflow roda — não permite ler configuração de outros repositórios da organização a partir de um workflow central, inviabilizando a varredura org-wide

## Decisão

**Opção escolhida: Opção A — GitHub App dedicado**, porque é a única opção que
atende simultaneamente least privilege (permissões granulares, somente
leitura), auditabilidade (ações atribuídas ao App) e continuidade operacional
(não depende de uma conta de usuário), sem exigir uma nova stack de automação.

## Consequências

### Positivas

- Least privilege comprovável — permissões do App podem ser revisadas isoladamente do restante da organização.
- Rotação de chave privada é um processo padrão do GitHub, sem precisar recriar tokens manualmente em múltiplos lugares.
- Audit log da organização distingue claramente ações da varredura de ações humanas.

### Negativas / Trade-offs Assumidos

- Setup inicial exige um administrador da organização (ação manual, fora do escopo de código desta feature — documentada no `quickstart.md`).
- Introduz um segundo padrão de credencial no repositório (GitHub App, além do PAT já usado por `ensure-github-project.yml`) — aceito porque cada padrão é apropriado ao seu contexto de risco (governança de board vs. leitura de segurança org-wide).

## Adendo (2026-09-22) — Permissões adicionais para a issue #450

A issue [#450](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/issues/450)
amplia a varredura para Rulesets/branch protection em múltiplas branches,
required checks, CodeQL, Dependabot, Dependency Review e Secret Scanning. A
decisão (GitHub App dedicado) **não muda**; muda apenas o conjunto mínimo de
permissões, **todas somente leitura**:

| Permissão do App (read-only) | Status | Necessária para | Endpoints |
|---|---|---|---|
| Repository → Metadata | Existente | Descoberta de repositórios/branches; Rulesets aplicáveis | `GET /orgs/{org}/repos`, `GET /repos/{r}/branches`, `GET /repos/{r}/rules/branches/{b}`, `GET /repos/{r}/rulesets` |
| Repository → Administration | Existente | Proteção clássica, detalhes de Rulesets, permissões de Actions, Dependabot alerts/security updates, `security_and_analysis`, CodeQL default setup | `.../branches/{b}/protection`, `.../rulesets/{id}`, `.../actions/permissions`, `.../actions/permissions/workflow`, `.../vulnerability-alerts`, `.../automated-security-fixes`, `GET /repos/{r}`, `.../code-scanning/default-setup` |
| Repository → Contents | Existente | `.github/security-governance.json`, CODEOWNERS, arquivos de workflow | `.../contents/{path}` |
| Repository → Secrets | Existente | Existência de Actions secrets (metadados, nunca valores) | `.../actions/secrets` |
| Repository → **Code scanning alerts** | **Nova** | `codeql-enabled`, `codeql-recent`, `codeql-alerts` | `.../code-scanning/analyses`, `.../code-scanning/alerts` |
| Repository → **Dependabot alerts** | **Nova** | Contagem de alertas critical/high em `dependabot-alerts-enabled` | `.../dependabot/alerts` |
| Repository → **Secret scanning alerts** | **Nova** | `secret-alerts` (sempre com `hide_secret=true`) | `.../secret-scanning/alerts` |
| Organization → **Projects** | **Nova (explicitada)** | `platform-project-access` (GraphQL Project V2 — já usado, não estava documentado) | GraphQL `projectsV2` |

Regras mantidas/reforçadas:

- **Nenhuma permissão de escrita** ao App — nem `Issues: write`. As issues de
  não conformidade e o relatório mensal passam a ser escritos exclusivamente
  no repositório que hospeda a varredura com o `GITHUB_TOKEN` efêmero do
  workflow (`permissions: issues: write`), via `SECURITY_SCAN_ISSUES_TOKEN`
  (`SECURITY_SCAN_ISSUE_TARGET=report-repository`, padrão). Isso também
  corrige a lacuna anterior, em que o script criava issues com o token do App
  sem que `Issues: write` constasse na lista de permissões.
- Criar issues diretamente em cada repositório avaliado
  (`SECURITY_SCAN_ISSUE_TARGET=scanned-repository`) exigiria uma credencial
  com `Issues: write` em toda a organização — **não adotado**; depende de novo
  ADR/aprovação.
- Endpoint indisponível no plano/instância → `pendente` com evidência; `403`
  por permissão ausente → erro explícito em `repos_com_erro`. Nunca `ok`.
- O App nunca lê valores de secrets (Actions secrets: só metadados; alertas de
  secret scanning: `hide_secret=true` + projeção sem o campo `secret`).
- A lista de endpoints acima reflete a documentação atual da API REST; a
  confirmação de que cada permissão é suficiente no GHE.com é feita no piloto
  (task T063) antes do gate S4.

### Ações derivadas

- [ ] Criar o GitHub App "Nimbus Code Security Auditor" na organização (owner: administrador da organização)
- [ ] Conceder ao App as permissões **read-only** adicionais do adendo (Code scanning alerts, Dependabot alerts, Secret scanning alerts, Organization Projects) — task T063, humana
- [ ] Configurar `SECURITY_SCAN_APP_ID`, `SECURITY_SCAN_APP_PRIVATE_KEY`, `SECURITY_SCAN_APP_INSTALLATION_ID` como GitHub Secrets
- [ ] Definir e documentar a rotação trimestral da chave privada (owner: responsável de plataforma)
- [ ] Atualizar o ADL do `plan.md` da feature 007 apontando para este ADR (já feito)

## Links

- [plan.md — feature 007](/specs/007-controle-seguranca-ghe-projetos-plataforma/plan.md)
- [spec.md — feature 007](/specs/007-controle-seguranca-ghe-projetos-plataforma/spec.md)
- [research.md — feature 007](/specs/007-controle-seguranca-ghe-projetos-plataforma/research.md)
- Supersede: —
- Relacionado a: `.github/workflows/ensure-github-project.yml` (padrão de PAT existente, mantido para seu caso de uso original)
