# Research: Documentação de Controle de Segurança no GHE para Projetos e Projeto Plataforma

**Feature**: `007-controle-seguranca-ghe-projetos-plataforma`
**Fase**: Phase 0 (Outline & Research)
**Input**: [spec.md](./spec.md) (com `## Clarifications`), [plan.md](./plan.md)

Todos os `NEEDS CLARIFICATION` do Technical Context do `plan.md` foram resolvidos durante a sessão `/speckit-clarify` de 2026-08-19. Este documento consolida as decisões técnicas de suporte necessárias para a fase de design (Phase 1), no formato Decision / Rationale / Alternatives considered.

---

## 1. Credencial de autenticação da varredura org-wide

- **Decision**: Usar um **GitHub App dedicado** ("Nimbus Code Security Auditor"), instalado na organização, com permissões de repositório somente-leitura: `metadata:read`, `administration:read` (branch protection), `secrets:read` (apenas para checar *existência* de segredos configurados, nunca seus valores), `contents:read` (necessário para ler arquivos de configuração como `CODEOWNERS`). Autenticação via JWT + installation access token, seguindo o padrão oficial do GitHub para Apps.
- **Rationale**: Least privilege — um GitHub App permite escopo de permissões granular por recurso, diferente de um PAT (Personal Access Token) que herda todos os escopos amplos concedidos pelo usuário titular. Além disso, um GitHub App:
  - Não expira atrelado à conta de uma pessoa (reduz risco de "token órfão" quando alguém sai da organização).
  - Gera logs de auditoria próprios no GHE, atribuídos ao App, e não a um usuário humano.
  - Suporta rotação de chave privada sem precisar recriar PATs manualmente.
- **Alternatives considered**:
  - **PAT de conta de serviço** (padrão já usado em `ensure-github-project.yml` via `VPNDEV_PROJECT_TOKEN`): mais simples de configurar, mas exige escopo `repo` amplo (leitura E escrita) mesmo quando só leitura é necessária, e está atrelado à conta que o gerou.
  - **`GITHUB_TOKEN` padrão do Actions, workflow por repositório**: não tem escopo cross-repo — não conseguiria listar/ler configuração de outros repositórios da organização a partir de um único workflow central.
- **Registrado em**: [ADR-0008](/docs/adr/0008-github-app-para-varredura-de-seguranca-org-wide.md).

## 2. Descoberta de repositórios (paginação e rate limit)

- **Decision**: Usar `gh api --paginate /orgs/{org}/repos` (ou GraphQL equivalente com cursor) para listar todos os repositórios, respeitando os cabeçalhos `X-RateLimit-Remaining`/`Retry-After` da API do GitHub, com backoff exponencial em caso de `403`/`429`.
- **Rationale**: `gh api --paginate` já lida com paginação nativa; adicionar checagem de rate limit evita falha abrupta do workflow em organizações com muitos repositórios.
- **Alternatives considered**: Script customizado de paginação manual via `curl` — mais código para manter sem ganho real sobre o suporte nativo do `gh` CLI.

## 3. Formato do "finding" de não conformidade e da issue gerada

- **Decision**: Cada controle avaliado gera um registro estruturado (repo, controle, status: `ok`/`pendente`/`risco`, timestamp, evidência) — ver `data-model.md` e `contracts/`. Quando o status é `pendente` ou `risco`, o script cria (ou atualiza, se já existir) uma Issue no repositório-alvo (ou em um repositório central de auditoria, a decidir em `/speckit-tasks`) usando uma chave idempotente `security-baseline:{repo}:{controle}` no corpo da issue como marcador de deduplicação.
- **Rationale**: Reaproveita o padrão já catalogado (`docs/reuse-catalog.yaml`, tag `speckit-deduplication-by-id`) de deduplicação por chave estruturada, evitando spam de issues duplicadas a cada execução semanal.
- **Alternatives considered**: Criar sempre uma nova issue a cada execução — gera ruído e dificulta rastrear o histórico de um único desvio.

## 4. Formato do relatório mensal consolidado

- **Decision**: O relatório mensal é gerado a partir da agregação das 4 (ou 5) execuções semanais do mês, publicado como um comentário/issue de resumo (ou artifact do workflow) listando: total de repositórios avaliados, % em conformidade por controle, lista de desvios abertos e fechados no período, e link para as issues individuais.
- **Rationale**: Atende ao SC-003 (relatório consolidado mensal com evidência) sem exigir uma nova infraestrutura de armazenamento — usa apenas primitivas já existentes do GHE (issues, comentários, workflow artifacts).
- **Alternatives considered**: Dashboard externo (ex.: Grafana) — mais poder de visualização, mas introduz uma nova dependência de infraestrutura fora do escopo desta feature (documentação + automação leve).

## 5. Rollout progressivo (flag) para o escopo de repositórios

- **Decision**: Um flag simples (`security.baseline_scan.org_wide_enabled`) controla se o workflow varre apenas o bounded context piloto (`spec-kit-workflow`, já registrado em `docs/bounded-contexts.yaml`) ou todos os repositórios da organização. Implementado via OpenFeature com um provider mínimo baseado em variável de ambiente/arquivo de configuração no repositório (sem exigir um serviço de flags dedicado).
- **Rationale**: A constituição do projeto exige OpenFeature como camada de abstração sempre que houver toggle, mas não exige um provider comercial completo — um provider simples (env/file-based) já satisfaz a abstração e permite trocar de provider depois sem reescrever o código de decisão do flag.
- **Alternatives considered**: Rollout direto para 100% dos repositórios sem piloto — rejeitado pela regra de que S3/S4 não podem usar deploy `direct`.

## 6. Linguagem/stack

- **Decision**: Bash + `gh` CLI para o script (`scripts/security-compliance-scan.sh`), YAML para o workflow — mesma stack já usada em `scripts/setup-github-project.sh`, `scripts/setup-github-labels.sh` e `.github/workflows/ensure-github-project.yml`.
- **Rationale**: Nenhuma dependência nova (runtime Node/Python) é necessária; reduz superfície de manutenção e mantém consistência com o padrão observável no restante do repositório.
- **Alternatives considered**: Node.js + Octokit (mais type-safety e testabilidade unitária), Python + PyGithub — ambos viáveis, mas introduziriam uma stack nova só para esta feature.
