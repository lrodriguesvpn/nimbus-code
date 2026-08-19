# 0008 — GitHub App dedicado para varredura de segurança org-wide

- **Status:** Em revisão
- **Data:** 2026-08-19
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
organização com permissões granulares (`metadata:read`, `administration:read`,
`secrets:read`, `contents:read`). O workflow gera um installation access token
de curta duração a cada execução.

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

### Ações derivadas

- [ ] Criar o GitHub App "Nimbus Code Security Auditor" na organização (owner: administrador da organização)
- [ ] Configurar `SECURITY_SCAN_APP_ID`, `SECURITY_SCAN_APP_PRIVATE_KEY`, `SECURITY_SCAN_APP_INSTALLATION_ID` como GitHub Secrets
- [ ] Definir e documentar a rotação trimestral da chave privada (owner: responsável de plataforma)
- [ ] Atualizar o ADL do `plan.md` da feature 007 apontando para este ADR (já feito)

## Links

- [plan.md — feature 007](/specs/007-controle-seguranca-ghe-projetos-plataforma/plan.md)
- [spec.md — feature 007](/specs/007-controle-seguranca-ghe-projetos-plataforma/spec.md)
- [research.md — feature 007](/specs/007-controle-seguranca-ghe-projetos-plataforma/research.md)
- Supersede: —
- Relacionado a: `.github/workflows/ensure-github-project.yml` (padrão de PAT existente, mantido para seu caso de uso original)
