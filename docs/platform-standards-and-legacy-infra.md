# Padrões de Plataforma/Cliente e Infraestrutura Legada

> **TL;DR**: use o preset `nimbus-code-platform-standards` quando o repositório
> representa o **ambiente real de um cliente/tenant** (contas cloud, legado,
> M365/GWS, D365) — não um projeto de código. Ele organiza o trabalho em três
> planos: **Evidence Plane** (somente leitura), **Desired State Plane**
> (zero-diff, baseline e drift) e **Delivery Plane** (apply protegido e humano).

Este documento detalha o preset
[`nimbus-code-platform-standards`](../presets/nimbus-code-platform-standards) — o par
complementar do [`nimbus-code-standards`](../presets/nimbus-code-standards) para
repositórios que representam o **ambiente real de um cliente/tenant**.

## 1. Por que dois presets?

Um repositório de projeto (`nimbus-code-standards`) modela **módulos de código** e
muda um sistema através de deploys revisados em PR. Um repositório de
plataforma modela **o ambiente real de um cliente** — muitas vezes híbrido,
compartilhado por múltiplos workloads e com partes fora de IaC.

Por isso: **um repositório usa um dos dois presets, nunca os dois.**

| | `nimbus-code-standards` | `nimbus-code-platform-standards` |
|---|---|---|
| Representa | Projeto/feature de software | Ambiente real de um cliente/tenant |
| Muda o ambiente? | Sim, via IaC revisado em PR | **Nunca** nos planos de evidência/desired state |
| Grafo | `graph.yaml` (módulos de código) | `platform-graph.yaml` (platform -> surface -> workload) |
| Quando nasce mudança real | No próprio repo | Em repositório/workflow de delivery protegido |

## 2. Regra de Ouro — Nunca Aplicar Mudança Direta

Um repositório de plataforma é **somente-observação por natureza** enquanto está
no Evidence Plane e no Desired State Plane. Ele registra estado real,
inventário, baselines, drift e vínculos com workloads, mas **não** faz mudança
real em cloud/tenant/cluster.

Se uma tarefa pedir mudança real em qualquer ambiente, ela está no caminho
errado: deve nascer no **Delivery Plane protegido**, com aprovação humana,
identidade dedicada e trilha de auditoria.

## 3. Limite entre Evidence Plane, Desired State Plane e Delivery Plane

### Evidence Plane

Objetivo: descobrir, registrar e comprovar o estado atual sem tocar no ambiente.

**Artefatos**
- `.nimbus/platform-profile.yaml`
- `.nimbus/execution-policy.yaml`
- `platform/evidence-registry.yaml`
- `evidence-record.yaml`
- `.github/workflows/evidence-refresh.yml`
- `scripts/validate-no-direct-write-commands.sh`

**Permitido**
- `terraform plan -refresh-only`
- `terraform show -json`
- `az resource list`
- `aws resourcegroupstaggingapi get-resources`
- `gcloud asset search-all-resources`
- `kubectl get ...`

**Proibido**
- apply/destroy
- verbos de escrita em CLI de cloud
- import de solução ou configuração que altere o tenant

### Desired State Plane

Objetivo: comparar estado real com baseline desejada e bloquear avanço sem
zero-diff, freshness e política de drift.

**Artefatos**
- `platform/baseline-registry.yaml`
- `platform/drift-policy.yaml`
- `drift-finding.yaml`
- `customer-profile.yaml`
- `workload-links.yaml`
- `platform-graph.yaml` / `platform-graph.md`
- `.github/workflows/terraform-plan.yml`

**Regra central**: zero-diff é critério de verdade. Se o `plan` indicar changes
ou destroy inesperado, o estágio não avança e a evidência precisa ser anexada
no PR.

### Delivery Plane

Objetivo: reservar um caminho separado para mudança real, fora da autonomia do
agente e sempre com revisão humana.

**Artefato de contrato**
- `.github/workflows/protected-apply.yml`

**Guardrails obrigatórios**
- Environment protegido (`production-apply` ou equivalente)
- Required reviewers / aprovação humana
- identidade dedicada (não `github.token`, não identidade padrão do agente)
- artifact de auditoria por execução
- bloqueio explícito para actor autônomo

## 4. Critério de Verdade — Reconciliação de Zero-Diff

Um recurso só é considerado "capturado corretamente" quando a comparação entre o
artefato versionado e o estado real mostra **zero diferenças** usando o mecanismo
nativo do domínio:

| Domínio | Mecanismo de reconciliação | Resultado exigido |
|---|---|---|
| Terraform (Azure/AWS/GCP) | `terraform plan` | `0 to add, 0 to change, 0 to destroy` |
| Microsoft 365 | `Test-M365DSCConfiguration` | 100% conformidade |
| Google Workspace | export atual vs. desired state | diff vazio |
| Dynamics 365 / Power Platform | solution exportada vs. unpacked | diff vazio |
| Schema de banco | extração read-only vs. schema versionado | diff vazio |

Enquanto o diff não for zero, a superfície não avança para `managed`.

## 5. Lifecycle oficial de plataforma

```text
discovery -> imported -> plan_diff_zero -> landing_zone_generated -> managed
```

| Fase | Produto | Gate de saída |
|---|---|---|
| `discovery` | discovery report + evidência fresh | owner revisou origem e escopo |
| `imported` | estado atual versionado | plan sem erro |
| `plan_diff_zero` | zero-diff confirmado | nenhum change/destroy |
| `landing_zone_generated` | baseline + landing zone + grafo completos | arquitetura revisada |
| `managed` | drift policy ativa | freshness, baseline e findings dentro do SLA |

## 6. Matriz de Ferramentas por Domínio

| Domínio | Terraform? | Ferramenta de referência | Observação |
|---|---|---|---|
| Azure — infraestrutura | ✅ Sim | `azurerm`/`azapi` + AVM | Provider maduro |
| Azure — legado/reverso | ✅ Sim | `aztfexport` | Reverse-export read-only |
| AWS — infraestrutura | ✅ Sim | Provider `aws` + módulos | Cobertura ampla |
| AWS — legado/reverso | ✅ Sim | `terraformer` | Use via CLI |
| GCP — infraestrutura | ✅ Sim | Provider `google`/`google-beta` | Padrão Google |
| GCP — legado/reverso | ✅ Sim | `terraformer` | Multi-provider |
| Microsoft 365 | ❌ Não | `Microsoft365DSC` | Governança de tenant |
| Entra ID | ✅ Parcial | Provider `azuread` | Identidade madura |
| Google Workspace | ⚠️ Parcial | `googleworkspace` + GAM | Provider limitado |
| Dynamics / Power Platform | ✅ Parcial | Provider Power Platform + `pac` | Tenant x solução separados |
| Kubernetes — cluster | ✅ Sim | Terraform | Infra do cluster |
| Kubernetes — workloads | ❌ Não | GitOps / Helm | Fora do escopo deste preset |

## 7. Modelo de IA por tarefa de plataforma/legado

| Nível | Tarefa típica | Modelo de IA | Revisão humana |
|---|---|---|---|
| S0/S1 | inventário/documentação/localização de evidência | Auto | Opcional |
| S2 | múltiplas superfícies sem impacto crítico | Reasoning | Recomendada |
| S3/S4 | reconciliação de ambiente compartilhado, compliance, identidade | Reasoning forte | **Obrigatória** |

**Toda importação/reconciliação de legado é no mínimo S3**.

## 8. Schemas de bancos legados

Todo banco legado deve ter schema (DDL, sem dados) extraído de forma
somente-leitura e versionado no repositório de plataforma, catalogado em
`db-schema-registry.md`.

| Engine | Comando de extração (somente schema) |
|---|---|
| PostgreSQL | `pg_dump --schema-only --no-owner --no-privileges` |
| MySQL/MariaDB | `mysqldump --no-data --routines --triggers` |
| SQL Server | `SqlPackage /Action:Extract` |
| Oracle | `expdp ... content=metadata_only` ou `dbms_metadata.get_ddl` |

## 9. Grafo de 2 níveis (plataforma -> superfície -> workload)

- **Plataforma**: conta, assinatura, tenant ou ambiente compartilhado
- **Superfície**: rede, policy, identidade, base compartilhada, landing zone
- **Workload**: repositório/produto que depende da superfície

Toda dependência declarada aqui deve ter espelho no `impact-map.md` do
repositório de workload correspondente.

## 10. Instalação e relação com outros documentos

```bash
specify preset add --dev ./nimbus-code/presets/nimbus-code-platform-standards --priority 5
```

Ver também:
- [`presets/nimbus-code-platform-standards/README.md`](../presets/nimbus-code-platform-standards/README.md)
- [`docs/label-taxonomy-and-autonomous-dev.md`](label-taxonomy-and-autonomous-dev.md)
- [`docs/ai-code-quality-and-observability.md`](ai-code-quality-and-observability.md)
- [`docs/module-graphs.md`](module-graphs.md)
