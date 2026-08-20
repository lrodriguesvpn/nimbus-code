# Data Model: Bootstrap Governance & Repo Provisioning Hardening

## Entity: RepoProvisioningProfile

Representa as respostas coletadas durante a execução do `bootstrap.sh` num
repositório novo.

| Campo | Tipo | Descrição | Validação |
|---|---|---|---|
| `repo_type` | enum | `platform` \| `dev_standards` | Obrigatório — pergunta feita antes de instalar qualquer preset |
| `preset_installed` | string | `nimbus-code-platform-standards` \| `nimbus-code-standards` | Derivado de `repo_type`, nunca assumido por padrão |
| `product_role` | enum (opcional) | `produto` \| `frontend` \| `backend` \| `n/a` | Delegado a `specs/006-multirepo-support/` — apenas referenciado aqui, não implementado nesta feature |

## Entity: GitHubAppCredentialPolicy

Regra que determina, por automação, qual mecanismo de autenticação usar.

| Campo | Tipo | Descrição |
|---|---|---|
| `automation_name` | string | Nome do workflow (ex.: `ensure-github-project`) |
| `scope` | enum | `same-repo` \| `cross-repo-org` |
| `auth_mechanism` | enum | `github_token_native` (se `same-repo`) \| `github_app_installation_token` (se `cross-repo-org`) |
| `fallback_mechanism` | enum (nullable) | `pat_classic` — apenas durante o período de rollout (ver ADL-2 em `plan.md`); `null` após conclusão da migração |
| `required_permissions` | list[string] | Permissões mínimas do GitHub App necessárias para esta automação específica |

**Regra de validação**: nenhuma automação com `scope = same-repo` pode ter
`auth_mechanism = github_app_installation_token` nem `pat_classic` — deve sempre
usar `github_token_native` (FR-005).

## Entity: SourceOfTruthRegistry

Lista das fontes canônicas de URL permitidas por tipo de conteúdo.

| Campo | Tipo | Descrição |
|---|---|---|
| `content_type` | enum | `spec_kit_cli` \| `vpn_internal` |
| `allowed_domain` | string | `github.com/github/spec-kit` (única exceção pública) \| `venha-pra-nuvem.ghe.com` (todo o resto) |

**Regra de validação**: qualquer URL de `content_type = vpn_internal` que não
comece com `https://venha-pra-nuvem.ghe.com/` falha a validação (FR-007, AC-7).

## Entity: SkillDistributionManual

Entrada por skill no manual de distribuição local vs. remota.

| Campo | Tipo | Descrição |
|---|---|---|
| `skill_name` | string | Nome da skill (ex.: `speckit-specify`) |
| `distribution_mode` | enum | `local` (`.github/skills/`) \| `remote` (VPN-SKILLS) |
| `current_status` | enum | `available` \| `planned` (VPN-SKILLS ainda não implementado — ver `specs/003-vpn-skills-repo-governance/`) |
| `invocation_path_or_command` | string | Caminho local ou comando de invocação remota |

## Relacionamentos

- `RepoProvisioningProfile` → determina qual `GitHubAppCredentialPolicy` template
  é instalado no novo repositório (via `bootstrap.sh`).
- `GitHubAppCredentialPolicy` → referencia `SourceOfTruthRegistry` para garantir
  que a URL de emissão de token/instalação do App usa o domínio correto.
- `SkillDistributionManual` → não depende de `RepoProvisioningProfile`; é um
  documento estático consultado independentemente do tipo de repositório.
