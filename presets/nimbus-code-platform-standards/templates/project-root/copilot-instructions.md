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

## Antes de Fechar Qualquer Tarefa

1. Confirme que nenhum comando de escrita foi executado contra o ambiente real.
2. Confirme reconciliação zero-diff (ou registre `parcial` com causa e plano).
3. Atualize `platform-graph.yaml`/`.md`, `legacy-inventory.md` e/ou
   `db-schema-registry.md` conforme aplicável.
4. Se a tarefa é importação/reconciliação de legado: classifique **S3 ou S4**,
   aplique `type:legacy-import`, e **peça revisão humana explicitamente** —
   nunca deixe seguir apenas com aprovação automática.
