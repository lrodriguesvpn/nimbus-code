# CI/CD Acceleration Map — Codespaces

> Artefato de planejamento da feature [009-codespaces-dev-planning](/specs/009-codespaces-dev-planning/spec.md)
> (FR-002, FR-003 / AC-2). Mapeia quais etapas do pipeline de CI/CD atual deste
> repositório podem ser validadas antecipadamente dentro de um Codespace criado
> a partir do [.devcontainer/devcontainer.json](/.devcontainer/devcontainer.json),
> antes da abertura do Pull Request — reduzindo o lead time de feedback (métrica
> DORA já rastreada pela organização, ver
> [docs/label-taxonomy-and-autonomous-dev.md](/docs/label-taxonomy-and-autonomous-dev.md)).

Entidade correspondente: `CiCdAccelerationMap` em
[data-model.md](/specs/009-codespaces-dev-planning/data-model.md).

## Mapeamento

| Etapa de pipeline (workflow) | Executável antecipadamente no Codespace? | Comando equivalente local | Tempo estimado economizado |
|---|---|---|---|
| [validate-manifests.yml](/.github/workflows/validate-manifests.yml) — schema de `preset.yml`/`bundle.yml`/`extension.yml`/`workflow.yml`/`catalog.json` | Sim | `pip install pyyaml` + o bloco Python embutido no step "Validar manifests..." (mesma lógica, roda localmente sem depender do runner) | Alto — evita todo um ciclo de push/CI (minutos) só para descobrir um campo `speckit_version` ausente/renomeado |
| [validate-manifests.yml](/.github/workflows/validate-manifests.yml) — step "Validar contratos híbridos de spec/plan/tasks" | Sim | `.specify/scripts/bash/validate-hybrid-contracts.sh` (mesmo script chamado pelo workflow) | Alto — mesmo resultado do CI, sem esperar fila de runner |
| [graph-guard.yml](/.github/workflows/graph-guard.yml) — grafo de módulos obrigatório | Parcial | A lógica compara `git diff` entre `base` e `head` de uma PR real; localmente dá para simular com `git diff --name-only <branch-base> HEAD` e conferir manualmente se `specs/<feature>/graph.yaml`/`graph.md` foram tocados quando `src/`, `services/`, `infrastructure/` ou `modules/` mudam | Médio — detecta a omissão antes do PR, mas a checagem de complexidade S3/S4 × `impact-map.md` exige leitura manual do `graph.yaml` (não há script standalone extraído do workflow) |
| [dependency-review.yml](/.github/workflows/dependency-review.yml) — CVE High/Critical em dependências | Não | Depende da API de Dependency Graph/SBOM do GitHub (`/repos/{owner}/{repo}/dependency-graph/sbom`) e da `dependency-review-action`, que não têm equivalente local sem acesso à API do repositório remoto | N/A — este gate só é significativo contra o estado real do repositório no GitHub |

## Etapas fora do escopo deste mapeamento

Os demais workflows deste repositório (`sync-priority-field.yml`,
`ensure-github-project.yml`, `add-to-repo-project.yml`, `add-to-pmo-project.yml`,
`agent-auto-assign.yml`, `normalize-issue-bodies.yml`, `update-speckit-and-bundle.yml`,
`release.yml`) reagem a eventos do GitHub (issues, projects, releases) ou
dependem de permissões/tokens de organização — não são "etapas de
build/test/lint" no sentido de FR-002 e não fazem sentido serem replicadas
dentro de um Codespace de desenvolvimento individual.

## Avaliação de Codespaces Prebuilds (FR-003)

**Linha de base atual**: sem prebuild, o provisionamento de um Codespace a
partir do [.devcontainer/devcontainer.json](/.devcontainer/devcontainer.json)
paga o custo de baixar a imagem base (`mcr.microsoft.com/devcontainers/base:ubuntu`)
e instalar as features (`python`, `node`, `github-cli`) e o
`postCreateCommand` (`scripts/setup-dev-environment.sh`) a cada criação —
estimado em 2–5 minutos para este devcontainer (imagem oficial leve, poucas
features, sem build de aplicação).

**Com prebuild habilitado** (GitHub Codespaces Prebuilds, nível de
repositório/branch): o tempo de criação de um novo Codespace cai para a ordem
de segundos a ~1 minuto, pois a imagem já vem construída com as features e o
resultado do `postCreateCommand` cacheado — atende ao SLO de 120s p99 definido
no `spec.md` com folga.

**Impacto de custo esperado**: prebuilds consomem armazenamento e minutos de
build adicionais (cobrados por uso, fora do tempo de execução do Codespace do
desenvolvedor) toda vez que a branch de referência (`main`) muda em um caminho
coberto pelo devcontainer. Dado que este template tem baixo volume de mudanças
estruturais diárias, o custo adicional esperado é **baixo** frente ao ganho de
tempo de onboarding — mas a ativação de prebuilds em repositórios de projeto
(não este template) deve ser avaliada individualmente por cada time, pesando
frequência de mudança vs. economia de tempo por Codespace criado.

**Recomendação**: habilitar prebuild apenas se o volume de criação de novos
Codespaces por semana justificar o custo adicional de build — decisão
operacional posterior a este plano, não uma ativação automática desta feature.

## Validação (AC-2 / T009)

Cenário 2 do [quickstart.md](/specs/009-codespaces-dev-planning/quickstart.md)
pede para rodar uma etapa mapeada localmente no Codespace e comparar com o
resultado do CI. Nesta sessão de planejamento (sem acesso a um Codespace real
provisionado), os dois comandos locais mapeados acima como "Sim" foram
**executados de fato** em um ambiente equivalente (mesmo toolchain
Bash/Python do devcontainer de referência):

- `.specify/scripts/bash/validate-hybrid-contracts.sh` → `OK: hybrid contracts
  validated in specs/016-hybrid-agent-human-dev/fixtures` (mesmo script
  invocado pelo step "Validar contratos híbridos..." do
  [validate-manifests.yml](/.github/workflows/validate-manifests.yml))
- Bloco Python de validação de schema (mesma lógica embutida no step "Validar
  manifests de preset, bundle, extension e workflow") → `OK: all manifests
  valid`, confirmando que todos os manifests do repositório passam no mesmo
  critério aplicado pelo CI

Como os comandos executados **são os mesmos scripts/lógica** que os workflows
correspondentes invocam, o resultado é equivalente por construção ao que o CI
produziria para o estado atual do repositório.

A comparação de **tempo** de feedback (Codespace vs. CI remoto) exige um
Codespace real provisionado (medição de wall-clock em ambiente hospedado) e
permanece **pendente de validação humana** — ver seção "Pendências" no PR
desta feature.
