# Data Model: Documentação de Controle de Segurança no GHE para Projetos e Projeto Plataforma

**Feature**: `007-controle-seguranca-ghe-projetos-plataforma`
**Fase**: Phase 1 (Design & Contracts)

> Esta feature não introduz um banco de dados próprio. As "entidades" abaixo são
> registros lógicos manipulados pela automação de varredura (lidos da API do
> GitHub e materializados como Issues/relatórios), não tabelas de um schema SQL.

## Entidades do `spec.md` (Key Entities)

### 1. Controle de Segurança

Política ou configuração obrigatória no GHE avaliada pela varredura.

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | string | Identificador estável do controle (ex.: `branch-protection-default`, `required-review`, `required-pr-checks`, `codeql-alerts`, `secret-alerts`, `actions-permissions`, `secrets-configured` — lista completa em `contracts/finding-schema.md`; o id legado `branch-protection` foi migrado para `branch-protection-default`) |
| `nome` | string | Nome legível (ex.: "Proteção de branch") |
| `escopo` | enum | `repositorio` \| `projeto-plataforma` |
| `criterio_conformidade` | string | Regra objetiva usada para avaliar `ok`/`pendente`/`risco` |
| `bloqueante` | boolean | Se `true`, ausência é tratada como `risco`; se `false`, como `pendente` |

### 2. Projeto de Repositório

Repositório individual do time, alvo da varredura.

| Campo | Tipo | Descrição |
|---|---|---|
| `full_name` | string | `org/repo` |
| `visibilidade` | enum | `public` \| `private` \| `internal` |
| `bounded_context` | string \| null | Referência a `docs/bounded-contexts.yaml`, se registrado |
| `tem_admin_disponivel` | boolean | Se a varredura conseguiu ler configurações administrativas (branch protection etc.) — `false` cobre o edge case "sem permissões administrativas" do `spec.md` |

### 3. Projeto Plataforma

Project V2 consolidado que agrega visibilidade de vários repositórios.

| Campo | Tipo | Descrição |
|---|---|---|
| `project_id` | string | ID do Project V2 (GraphQL node id) |
| `titulo` | string | Título do Project (convenção: sufixo "— Nimbus Code Roadmap") |
| `matriz_permissoes` | list\<PerfilDeAcesso\> | Papéis autorizados a administrar views/campos críticos |

### 4. Perfil de Acesso

Papel de usuário/grupo com permissões delimitadas para repositório e projeto.

| Campo | Tipo | Descrição |
|---|---|---|
| `papel` | enum | `owner` \| `admin` \| `maintainer` \| `contributor` \| `leitor` |
| `escopo` | enum | `repositorio` \| `projeto-plataforma` |
| `principio_menor_privilegio` | boolean | Se o papel concedido é o mínimo necessário para a função |

### 5. Evidência de Auditoria

Registro verificável do estado de conformidade de um controle.

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | string | `security-baseline:{repo}:{controle}` (chave idempotente) |
| `repo` | string | `org/repo` avaliado (ou `platform` para o Projeto Plataforma) |
| `controle_id` | string | Referência a `Controle de Segurança.id` |
| `status` | enum | `ok` \| `pendente` \| `risco` |
| `timestamp` | datetime | Momento da avaliação (execução semanal) |
| `evidencia` | string | Detalhe/link (ex.: campo da API que evidenciou o estado) |
| `issue_url` | string \| null | Link da issue rastreável, se `status != ok` |

## Entidades adicionais da camada de automação (Phase 1)

### 6. Scan Run

Execução única do workflow semanal.

| Campo | Tipo | Descrição |
|---|---|---|
| `run_id` | string | ID da execução do GitHub Actions |
| `iniciado_em` | datetime | Início da execução |
| `repos_avaliados` | int | Total de repositórios varridos nesta execução |
| `repos_com_erro` | int | Repositórios não avaliados por erro de API/permissão (usado no SLO de "taxa de erro máx.") |
| `findings` | list\<Evidência de Auditoria\> | Resultado desta execução |

**Validação/regra**: se `repos_com_erro / repos_avaliados > 5%`, a execução deve sinalizar `::warning::` (ver SLO Gate no `plan.md`) sem falhar o workflow inteiro (falha parcial não deve bloquear a varredura dos demais repositórios).

### 7. Compliance Finding

Alias operacional de "Evidência de Auditoria" no momento em que é gerado (antes de virar Issue), usado como payload interno do script antes da materialização.

*(Ver schema completo em [`contracts/finding-schema.md`](./contracts/finding-schema.md).)*

### 8. Compliance Report (mensal)

Agregação de até 5 `Scan Run` do mesmo mês calendário.

| Campo | Tipo | Descrição |
|---|---|---|
| `mes_referencia` | string | `YYYY-MM` |
| `total_repos` | int | Total de repositórios únicos avaliados no mês |
| `percentual_conformidade_por_controle` | map\<controle_id, float\> | % de repositórios `ok` por controle |
| `desvios_abertos` | list\<Evidência de Auditoria\> | Ainda não corrigidos ao final do mês |
| `desvios_fechados_no_mes` | list\<Evidência de Auditoria\> | Corrigidos durante o mês (para medir SC-004) |

### 9. Governance Config *(issue #450)*

Configuração versionada por repositório (`.github/security-governance.json`).

| Campo | Tipo | Descrição |
|---|---|---|
| `branches` | objeto | `default_branch` (`auto`), `production_branches`, `protected_patterns`, `additional_branches` |
| `branch_rules` | objeto | Aprovadores, CODEOWNERS, dismiss stale, bloqueios de push/force push/deleção, strict, conversas, merge queue |
| `required_status_checks` | map\<categoria, list\<context\>\> | Checks esperados como obrigatórios (build, unit_tests, integration_tests, coverage, sast, sca, secret_scanning, governance) |
| `quality_gates` | objeto | `setup_command`/`command`/`not_applicable_reason` por etapa |
| `coverage` | objeto | `mode` (`report`/`not-applicable`), mínimos global/diff, baseline, relatório |
| `codeql` | objeto | Linguagens, idade máxima da análise, severidades bloqueantes |

### 10. Exception Record *(issue #450)*

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | string | Identificador único |
| `control` | string | Controle excetuado |
| `owner` / `approved_by` | string | Responsável e aprovador |
| `justification` | string | Motivo e risco residual |
| `created_at` / `expires_at` | date | Prazo máximo de 90 dias; vencida quebra `governance-config` |

## Relacionamentos

```
Projeto de Repositório (1) ──< avaliado-por >── (N) Evidência de Auditoria
Projeto Plataforma (1)       ──< avaliado-por >── (N) Evidência de Auditoria
Controle de Segurança (1)   ──< referenciado-por >── (N) Evidência de Auditoria
Governance Config (1)        ──< parametriza >── (N) Controle de Segurança (por repositório)
Exception Record (N)         ──< excetua >── (1) Controle de Segurança
Perfil de Acesso (N)         ──< aplica-se-a >── Projeto de Repositório | Projeto Plataforma
Scan Run (1)                 ──< produz >── (N) Evidência de Auditoria
Compliance Report (1)        ──< agrega >── (4..5) Scan Run
```

## Regras de validação

- Toda `Evidência de Auditoria` com `status != ok` **deve** ter `issue_url` preenchido antes do fim da execução (garante rastreabilidade — FR-006).
- `id` de `Evidência de Auditoria` é a chave de deduplicação — nunca gerar duas issues para o mesmo `{repo}+{controle}` em aberto simultaneamente (reaproveita padrão `speckit-deduplication-by-id`).
- `Controle de Segurança.bloqueante = true` (ex.: secret scanning, branch protection) eleva o `status` a `risco`; controles não bloqueantes (ex.: rotação de token dentro do prazo) geram `pendente`.
