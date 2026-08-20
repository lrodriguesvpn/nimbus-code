# Data Model: Codespaces para DEV e CI/CD

## Entity: StandardDevcontainerProfile

| Campo | Tipo | Descrição |
|---|---|---|
| `base_image` | string | `mcr.microsoft.com/devcontainers/base:ubuntu` |
| `features` | list[string] | Bash, Python 3, Node.js, GitHub CLI |
| `extensions` | list[string] | Extensões VS Code mínimas (ex.: GitHub Copilot, GitLens) |
| `env_vars` | list[string] | Variáveis de ambiente padrão (não-secretas) |

## Entity: CiCdAccelerationMap

| Campo | Tipo | Descrição |
|---|---|---|
| `pipeline_step` | string | Nome da etapa (ex.: `lint`, `unit-tests`) |
| `codespace_executable` | boolean | Se pode ser validada antecipadamente dentro do Codespace |
| `estimated_time_saved` | string | Estimativa qualitativa de tempo economizado |

## Entity: CodespaceIdleGovernancePolicy

| Campo | Tipo | Descrição |
|---|---|---|
| `idle_timeout_minutes` | int | Limite de inatividade antes de parar automaticamente |
| `retention_period_days` | int | Retenção do Codespace parado antes de exclusão |
| `cost_alert_threshold` | string | Limite que dispara alerta de custo |

## Entity: RemoteAgentSessionModel

| Campo | Tipo | Descrição |
|---|---|---|
| `allowed_secrets_scope` | string | Escopo de segredos permitido — igual à política de CI do repositório |
| `isolation_model` | string | Cada sessão de agente roda em ambiente próprio, sem estado compartilhado |

## Relacionamentos

- `StandardDevcontainerProfile` é a base tanto para desenvolvedores humanos
  quanto para `RemoteAgentSessionModel` — mesmo ambiente, política de segredos
  diferenciada por quem/o que está executando.
- `CiCdAccelerationMap` referencia etapas de pipeline que rodam dentro de um
  Codespace criado a partir de `StandardDevcontainerProfile`.
