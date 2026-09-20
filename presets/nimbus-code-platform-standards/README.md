# nimbus-code-platform-standards (preset)

## Propósito

Aplica os padrões de governança de **plataforma/cliente/ambiente** da Nimbus-Code
sobre os templates nativos do Nimbus Code. É o par complementar do
[`nimbus-code-standards`](../nimbus-code-standards) — mas para um **tipo diferente de
repositório**:

| | `nimbus-code-standards` | `nimbus-code-platform-standards` |
|---|---|---|
| Representa | Um projeto/feature de software | O ambiente real de um cliente/tenant |
| Muda o ambiente? | Sim, via IaC revisado em PR | **Nunca** — somente observação/inventário |
| Unidade de trabalho | Feature de código | Plataforma / superfície / sistema legado |
| Grafo | `graph.yaml` (módulos de código) | `platform-graph.yaml` (platform -> surface -> workload) |

Um repositório usa **um dos dois presets, nunca os dois**.

## Limite entre os 3 planos

### 1. Evidence Plane

Onde vivem discovery, inventário, refresh-only plan e registro de evidências.
Arquivos-chave:

- `.nimbus/platform-profile.yaml`
- `.nimbus/execution-policy.yaml`
- `platform/evidence-registry.yaml`
- `.github/workflows/evidence-refresh.yml`
- `scripts/validate-no-direct-write-commands.sh`

**Regra:** somente leitura. Nunca `apply`, `destroy` ou CLI com verbo de escrita.

### 2. Desired State Plane

Onde vivem baseline, zero-diff, drift, landing zone e vínculos com workloads.
Arquivos-chave:

- `platform/baseline-registry.yaml`
- `platform/drift-policy.yaml`
- `platform-graph.yaml` / `platform-graph.md`
- `customer-profile.yaml`
- `workload-links.yaml`
- `.github/workflows/terraform-plan.yml`

**Regra:** validar, comparar e bloquear divergência; ainda sem mudança real.

### 3. Delivery Plane

Plano separado e protegido para mudança real. Neste preset ele existe **apenas**
como contrato/scaffold:

- `.github/workflows/protected-apply.yml`

**Regra:** approval humana obrigatória, Environment protegido, identidade dedicada,
trilha de auditoria e bloqueio explícito para agente autônomo.

## Pipeline de ciclo de vida de plataforma

Cada plataforma (conta/assinatura/tenant) dentro do repositório percorre estas
fases em ordem, rastreadas pelo campo `lifecycle_stage` em `platform-graph.yaml`:

```text
discovery -> imported -> plan_diff_zero -> landing_zone_generated -> managed
```

| Fase | Produto | Gate de saída |
|---|---|---|
| `discovery` | discovery report + evidência fresh | Owner revisou origem e freshness |
| `imported` | estado atual versionado | plan executa sem erro |
| `plan_diff_zero` | zero-diff comprovado | `terraform plan` sem changes nem destroy |
| `landing_zone_generated` | design + baseline + grafo completos | arquitetura revisada |
| `managed` | drift policy ativa e workloads vinculados | evidence/baseline/drift dentro do SLA |

## Templates incluídos

### Artefatos de feature

- `templates/feature-artifacts/platform-graph.yaml`
- `templates/feature-artifacts/platform-graph.md`
- `templates/feature-artifacts/nimbus-discovery-report.md`
- `templates/feature-artifacts/landing-zone/design.md`
- `templates/feature-artifacts/landing-zone/checklist-caf.md`
- `templates/feature-artifacts/legacy-inventory.md`
- `templates/feature-artifacts/db-schema-registry.md`

### Contratos de projeto (`templates/project-root/`)

- `.nimbus/platform-profile.yaml`
- `.nimbus/execution-policy.yaml`
- `platform/evidence-registry.yaml`
- `platform/baseline-registry.yaml`
- `platform/drift-policy.yaml`
- `customer-profile.yaml`
- `workload-links.yaml`
- `evidence-record.yaml`
- `drift-finding.yaml`
- `scripts/validate-no-direct-write-commands.sh`

### Workflows de scaffolding

- `.github/workflows/evidence-refresh.yml` — discovery/read-only + artifacts
- `.github/workflows/terraform-plan.yml` — zero-diff + bloqueio de destroy + evidência anexada ao PR
- `.github/workflows/protected-apply.yml` — apply protegido do Delivery Plane

## Regra de Ouro

Este tipo de repositório **nunca** executa `terraform apply` ou qualquer
comando de escrita contra um ambiente real a partir do Evidence Plane ou do
Desired State Plane. Mudança real só pode existir no Delivery Plane protegido,
com revisão humana e identidade dedicada.

## Instalação isolada

```bash
specify preset add nimbus-code-platform-standards --from https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/releases/download/vX.Y.Z/nimbus-code-platform-standards-0.5.0.zip --priority 5
```

Ou, em modo desenvolvimento, a partir de um clone local:

```bash
specify preset add --dev ./nimbus-code-spec-kit-template/presets/nimbus-code-platform-standards --priority 5
```

## Detalhamento completo

Ver [`docs/platform-standards-and-legacy-infra.md`](../../docs/platform-standards-and-legacy-infra.md)
para a separação entre Evidence Plane, Desired State Plane e Delivery Plane,
matriz de ferramentas por domínio e regra de zero-diff.

## Status

**v0.5.0** — inclui contracts de plano operacional, registries de evidência e
baseline, workflow read-only de evidência, workflow de zero-diff e contrato de
protected apply com bloqueio para agente autônomo.
