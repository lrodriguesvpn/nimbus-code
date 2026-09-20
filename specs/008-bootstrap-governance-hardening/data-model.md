# Data Model: Bootstrap Governance & Repo Provisioning Hardening

## Entity: RepoProvisioningProfile

Representa as respostas coletadas durante a execução do `bootstrap.sh` num
repositório novo.

| Campo | Tipo | Descrição | Validação |
|---|---|---|---|
| `repo_type` | enum | `platform` \| `dev_standards` | Obrigatório — pergunta feita antes de instalar qualquer preset |
| `preset_installed` | string | `nimbus-code-platform-standards` \| `nimbus-code-standards` | Derivado de `repo_type`, nunca assumido por padrão |
| `source_ref` | string | Tag ou versão usada como fonte do bootstrap | Obrigatório em modo não interativo; não pode ser branch móvel |
| `context_classification` | enum | `greenfield` \| `brownfield` | Derivado da classificação inicial do repositório |
| `bootstrap_mode` | enum | `interactive` \| `non_interactive` | Deve refletir a forma de execução utilizada |

O roteamento de Produto, Frontend, Backend e demais bounded contexts não faz
parte deste perfil. Esse relacionamento é responsabilidade da
`specs/006-multirepo-support/`, por meio de `docs/bounded-contexts.yaml` e dos
campos `bounded_contexts`/`repos` em `.specify/feature.json`.

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

## Entity: ValidationRelease

Representa a versão imutável usada no projeto piloto e o vínculo entre os
componentes publicados.

| Campo | Tipo | Descrição | Validação |
|---|---|---|---|
| `ref` | string | Tag Git usada pelo piloto, inicialmente `v1.19.0-rc.1` | Deve resolver para commit em `main`; nunca branch móvel |
| `project_bundle_version` | semver | Versão do bundle de projeto | `1.19.0` |
| `platform_bundle_version` | semver | Versão do bundle de plataforma | `0.5.0` |
| `pilot_status` | enum | `planned` \| `running` \| `passed` \| `failed` | Só promove para release final após gates |
| `evidence` | list[string] | Logs, links e resultados do piloto | Sem secrets ou chaves privadas |

## Entity: PlatformCapabilityProfile

Contrato de capacidades entregues pelo preset de plataforma, sem executar
coleta cloud ou `terraform apply` durante o bootstrap.

| Campo | Tipo | Descrição |
|---|---|---|
| `evidence_source` | enum | `cloud_inventory` \| `cmdb` \| `terraform_plan` \| `policy_baseline` |
| `lifecycle_stage` | enum | `discovery` \| `imported` \| `plan_diff_zero` \| `landing_zone_generated` \| `managed` |
| `drift_policy` | enum | `advisory` \| `blocked` \| `exception` |
| `production_apply_allowed` | boolean | Deve ser `false` no preset Platform |
| `workload_dependencies` | list[string] | Workloads ligados à superfície de plataforma |

## Entity: DevStandardsAgentGuardrail

Contrato de governança para agentes instalado somente no perfil Dev Standards.

| Campo | Tipo | Descrição |
|---|---|---|
| `complexity` | enum | `S0` \| `S1` \| `S2` \| `S3` \| `S4` |
| `required_artifacts` | list[string] | spec, plan, tasks, graph, impact map, retro conforme o nível |
| `human_gate` | boolean | Obrigatório para S4 e mudanças de segurança |
| `cost_tracking` | boolean | Registra tokens e horas humanas |
