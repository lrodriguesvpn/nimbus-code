# Instruções do Copilot — Repositório de Plataforma/Cliente

<!--
  Copiado pelo preset `nimbus-code-platform-standards` para a raiz do repositório
  de plataforma. Diferente do copilot-instructions.md de um repositório de
  projeto (`nimbus-code-standards`), este arquivo governa um repositório que
  representa o ESTADO REAL de um ambiente/cliente, não uma feature de código.
-->

## Regra Mais Importante

**Este repositório nunca aplica mudança em nenhum ambiente.** Se uma tarefa
pedir para você rodar `terraform apply`, alterar um recurso via `az`/`aws`/
`gcloud` CLI, importar uma `pac solution`, ou qualquer outro comando de
escrita — **pare e sinalize**: essa mudança pertence a um repositório de
projeto (workload), não a este. Isso vale mesmo quando o ambiente é da
própria VPN (Venha Pra Nuvem) — não existe exceção "porque é a gente".

## O Que Este Repositório Faz

- Mantém o **inventário as-is** (`legacy-inventory.md`) de tudo que existe
  hoje em Azure, AWS, GCP, Google Workspace, Microsoft 365 e Dynamics 365.
- Mantém o **grafo de plataforma** (`platform-graph.yaml`/`.md`) — as
  superfícies compartilhadas e quais repositórios de workload dependem delas.
- Mantém os **schemas de bancos de dados legados** (`db-schema-registry.md`),
  extraídos de forma somente-leitura.
- Só considera um recurso "capturado corretamente" quando a reconciliação
  (ver tabela na constituição) mostra **zero diferenças** — nunca antes disso.

## Ferramenta por Domínio (referência rápida)

| Você recebeu uma tarefa sobre... | Use |
|---|---|
| Recurso de infraestrutura Azure | `aztfexport` (exportar) + `azurerm`/AVM (documentar) — sempre consultar `azureterraformbestpractices` antes |
| Recurso de infraestrutura AWS/GCP | `terraformer` (exportar) + módulos oficiais do provider |
| Workload dentro de um cluster Kubernetes | Não é Terraform — é GitOps (Flux/ArgoCD)/Helm |
| Tenant/política M365 | Microsoft365DSC — não Terraform |
| Usuário/grupo/OU do Google Workspace | GAM (script) — Terraform `googleworkspace` só onde cobre |
| Ambiente/DLP do Power Platform (D365) | Provider `microsoft/power-platform` |
| Customização de D365 (entidade, form, plugin) | Power Platform CLI (`pac`) + Solutions |
| Schema de banco legado | Extração read-only (`pg_dump --schema-only`, `SqlPackage /Action:Extract`, etc.) |

## Ciclo de Vida de Plataforma (fases obrigatórias)

O pipeline de uma plataforma percorre estas fases em ordem. **Nunca pular uma fase.**

```
discovery → imported → plan_diff_zero → landing_zone_generated → managed
```

| Fase | O que produz | Critério de saída |
|---|---|---|
| `discovery` | `nimbus-discovery-report.md` (por plataforma) | Relatório revisado por arquiteto; lacunas priorizadas |
| `imported` | IaC gerado e versionado (aztfexport / terraformer / M365DSC export) | `terraform plan` roda sem erro (pode ter diff ainda) |
| `plan_diff_zero` | Output do `terraform plan` zerado | `0 to add, 0 to change, 0 to destroy` — evidência no PR |
| `landing_zone_generated` | `landing-zone/<platform-id>/design.md` + `checklist-caf.md` | Landing Zone revisada por arquiteto; gaps registrados |
| `managed` | Drift-check ativo | Alerta de drift configurado; responsável técnico definido |

**Quando regenerar a Landing Zone:**
- Toda vez que `iac_lifecycle_stage` avança para `landing_zone_generated` ou superior.
- Toda vez que uma nova plataforma é adicionada ao `platform-graph.yaml`.
- Toda vez que a topologia muda estruturalmente: nova superfície crítica, mudança de
  modelo de identidade, mudança de ferramenta de reconciliação.
- A Landing Zone não é "gerada uma vez e esquecida" — é um espelho do estado real.

**Checklist CAF por nuvem** — usar `landing-zone/<platform-id>/checklist-caf.md`:
- Azure → Azure CAF (Management Groups, Hub-Spoke, Defender, Policies)
- AWS → Well-Architected + Control Tower (Organizations, SCPs, Security Hub)
- GCP → Cloud Foundation Toolkit (Org, Folders, Shared VPC, Security Command Center)
- M365 → CIS M365 Benchmark via Microsoft365DSC
- D365 → Power Platform ALM guidance + CoE Starter Kit

**A Landing Zone não é uma configuração aplicável** — é documentação derivada do
estado real confirmado com diff-zero. Nenhum artefato em `landing-zone/` executa
`terraform apply` ou equivalente.

## Isolamento de Credenciais

- Cada cliente/tenant tem credenciais de leitura **exclusivas** (nunca compartilhar
  entre clientes ou tenants diferentes).
- Nomear com padrão rastreável: `spn-<cliente>-<nuvem>-<ambiente>-ro`.
- Somente leitura neste repositório — nunca permissão de escrita/apply.
- Se receber uma tarefa pedindo configurar credenciais de escrita neste repositório:
  **pare e sinalize** — isso viola a Regra de Ouro.

## Regra: nunca impor uma decisão de arquitetura silenciosamente

Ao planejar (`/nimbus-code-plan`), se você (agente) identificar que uma decisão —
sua ou do usuário — diverge do padrão institucional deste preset, **não
implemente a preferência silenciosamente em nenhuma direção**:

1. Documente a divergência no Architecture Decision Log do `plan.md`.
2. Explique objetivamente por que considera a decisão fora do padrão.
3. Verifique a tabela do Gate de Não-Negociáveis: se o item está marcado
   **"Não-Negociável"** (ex.: backup do estado original, nunca aplicar
   mudança direta, credencial de escrita, schema sem dado real, remediação
   automática de drift), não há exceção possível — pare e informe que o
   controle precisa existir de fato. Se está marcado **"Escapável via ADL"**
   (ex.: firewall/segmentação, IaC não-Terraform, prazo de regularização), o
   usuário pode manter a decisão fora do padrão, mas você deve pedir
   explicitamente a justificativa e registrar quem aprovou.
- Lista completa: `docs/ai-code-quality-and-observability.md`, seção 11.

## Antes de Fechar Qualquer Tarefa

1. Confirme que nenhum comando de escrita foi executado contra o ambiente real.
2. Confirme reconciliação zero-diff (ou registre `parcial` com causa e plano).
3. Atualize `platform-graph.yaml`/`.md`, `legacy-inventory.md` e/ou
   `db-schema-registry.md` conforme aplicável.
4. Se a tarefa é importação/reconciliação de legado: classifique **S3 ou S4**,
   aplique `type:legacy-import`, e **peça revisão humana explicitamente** —
   nunca deixe seguir apenas com aprovação automática.
