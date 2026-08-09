# Princípios Não-Negociáveis da VPN Dev — Plataforma/Cliente

<!--
  © Venha Pra Nuvem — Propriedade Intelectual Exclusiva.
  Uso restrito a colaboradores autorizados da organização venha-pra-nuvem.
  Cópia, redistribuição ou uso externo são proibidos — ver LICENSE no repositório
  speckit-vpndev-standards. Alterações exigem aprovação do @vpndev-arch-board.
-->

<!--
  Este bloco é inserido pelo preset `vpndev-platform-standards` (estratégia `wrap`).

  ESCOPO: este preset é para repositórios de PLATAFORMA/CLIENTE/TENANT — o
  repositório que representa o ambiente real de um cliente (contas cloud,
  tenants M365/GWS, ambiente D365, sistemas legados) — NÃO para repositórios
  de projeto/feature comuns. Repositórios de projeto continuam usando o preset
  `vpndev-standards`. Os dois presets são mutuamente exclusivos por
  repositório: um repositório de plataforma não aplica também o `wrap` de
  `vpndev-standards`.

  Alterar este arquivo é uma mudança de política organizacional: requer
  aprovação do time responsável pelos padrões da VPN Dev e segue o controle de
  versão do preset (ver presets/vpndev-platform-standards/preset.yml).
-->

## Identidade do Repositório (preencher antes de qualquer outra seção)

| Campo | Valor |
|---|---|
| **Cliente/Tenant** | [ex.: Venha Pra Nuvem (piloto interno), Cliente X] |
| **Tipo de repositório** | `platform` — representa o ambiente real, nunca um projeto isolado |
| **Nuvens/plataformas envolvidas** | Azure · AWS · GCP · Google Workspace (GWS) · Microsoft 365 (M365) · Dynamics 365 (D365) *(marcar as aplicáveis)* |
| **Repositório(s) de projeto/workload relacionados** | [lista ou "nenhum ainda"] |

> Este repositório só deve ser criado depois que os dois presets (`vpndev-standards`
> e `vpndev-platform-standards`) estiverem estáveis e publicados no catálogo —
> não é um repositório "de teste" isolado, é o registro de verdade de um
> ambiente real.

## Regra de Ouro — Este Repositório Nunca Aplica Mudança Direta

- **Este repositório é somente-observação (read-only por natureza)**: seu conteúdo
  é o **registro** do estado real de um ambiente (inventário, IaC gerado a partir
  do estado real, schemas de bancos legados, grafo de superfícies compartilhadas).
  Nenhuma automação deste repositório executa `terraform apply`,
  `az resource update/delete`, importação de `pac solution`, alteração via
  Microsoft365DSC/GAM ou qualquer comando de escrita contra um ambiente real.
- **Nenhuma credencial de escrita (`apply`) contra ambiente de PRODUÇÃO** é
  configurada neste repositório — apenas credenciais de leitura (Resource
  Graph, `aztfexport`, exportações read-only). Isso vale objetivamente também
  para os ambientes/tenants de **produção da própria VPN**, quando este preset
  for aplicado ao repositório piloto interno — não é uma exceção "porque é a
  gente".
- **Toda mudança REAL em qualquer ambiente nasce em um repositório de PROJETO**
  (workload), usando o preset `vpndev-standards`, nunca aqui. Quando não existe
  ainda um projeto responsável por um sistema/ambiente legado que precisa de
  mudança, **um novo repositório de projeto nasce especificamente para essa
  mudança** — referenciando este repositório de plataforma como fonte de
  verdade do estado atual (via `platform-graph.yaml`) e, quando aplicável,
  atualizando o inventário aqui depois que a mudança for aplicada e
  reconciliada (zero-diff).
- Violação desta regra (qualquer PR/workflow que introduza um passo de
  `apply`/escrita neste repositório) é tratada como incidente de governança —
  bloqueia merge e exige revisão do @vpndev-arch-board.

## Critério de Verdade — Reconciliação de Zero-Diff

- Um recurso só é considerado **corretamente capturado** neste repositório
  quando a comparação entre o artefato versionado e o estado real do ambiente
  mostra **zero diferenças**, usando o mecanismo de reconciliação nativo do
  domínio:

  | Domínio | Comando/mecanismo de reconciliação | Resultado exigido |
  |---|---|---|
  | Terraform (Azure/AWS/GCP) | `terraform plan` | `0 to add, 0 to change, 0 to destroy` |
  | Microsoft 365 (M365) | `Test-M365DSCConfiguration` / comparação MOF | 100% conformidade, 0 desvios |
  | Google Workspace (GWS) | Export atual (GAM/Admin SDK) vs. desired state versionado | diff vazio |
  | Dynamics 365 / Power Platform | `pac solution` exportado vs. solution unpacked no repo | diff vazio |
  | Schemas de banco (legado) | Extração read-only (`pg_dump --schema-only`, `SqlPackage /Action:Extract`, etc.) vs. schema versionado | diff vazio |

- Enquanto o diff não for zero, o recurso permanece classificado como
  `iac_status: parcial` no `platform-graph.yaml` — **nunca** `completo`.
  Declarar "completo" com diff pendente é dado inválido e bloqueia o Drift
  Gate deste repositório.
- Diff-zero **não é um estado permanente**: é reavaliado em cada execução do
  drift-check agendado. Drift detectado reabre o status para `parcial` até
  nova reconciliação — nunca silenciar/ignorar drift sem registrar no
  `legacy-inventory.md` a causa e o plano de correção.

## Cobertura Multi-Plataforma — Ferramenta por Domínio

- A VPN Dev opera hoje sobre **Azure, AWS, GCP, Google Workspace (GWS),
  Microsoft 365 (M365) e Dynamics 365 (D365)**. Cada domínio tem uma ferramenta
  de referência — usar Terraform em tudo que for camada de infraestrutura
  (Well-Architected: recurso, rede, IAM) e a ferramenta nativa da plataforma
  para o que for camada de configuração/tenant/aplicação:

  | Domínio | Terraform? | Ferramenta de referência |
  |---|---|---|
  | Azure (infra) | Sim | `azurerm`/`azapi` + módulos AVM; reverso via `aztfexport` |
  | AWS (infra) | Sim | Provider `aws` + `terraform-aws-modules`; reverso via `terraformer` |
  | GCP (infra) | Sim | Provider `google`/`google-beta` + módulos oficiais Google; reverso via `terraformer` |
  | Kubernetes — cluster (AKS/EKS/GKE) | Sim | Terraform cria o cluster/node pools/rede |
  | Kubernetes — workloads no cluster | Não | GitOps (Flux/ArgoCD) ou Helm — Terraform para no limite do cluster |
  | Microsoft 365 (tenant/policies) | Não (provider imaturo p/ isso) | **Microsoft365DSC** (PowerShell DSC) |
  | Entra ID (apps, service principals, roles) | Sim (fatia madura) | Provider `azuread` |
  | Google Workspace (usuários, grupos, OUs) | Parcial | Provider `googleworkspace` onde cobre; **GAM** (script) como referência principal |
  | Dynamics 365 / Power Platform — ambiente/DLP | Sim (provider oficial em maturação) | Provider `microsoft/power-platform` |
  | Dynamics 365 / Power Platform — customização (entidades, forms, plugins) | Não | **Power Platform CLI (`pac`)** + Solutions (ALM oficial) |
  | Segredos (valor, não o recurso) | Cuidado | Recurso do cofre via Terraform sim; valor nunca em `.tf`/state |
  | Schema/dados de banco | Não | Extração read-only (ver tabela de reconciliação acima) |

- Detalhamento completo, com exemplos e justificativa de cada linha, em
  [`docs/platform-standards-and-legacy-infra.md`](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/speckit-vpndev-standards/blob/main/docs/platform-standards-and-legacy-infra.md).
- Qualquer resultado de `terraform plan`/reconciliação equivalente relevante a
  Well-Architected (segurança, custo, confiabilidade) deve ser validado contra
  as 5 pilares antes de ser aceito como padrão — não apenas "aplica e funciona".

## Schemas de Bancos de Dados do Legado

- Todo banco de dados de sistema legado identificado no `legacy-inventory.md`
  **deve** ter seu schema (DDL, sem dados) extraído e versionado neste
  repositório, em `schemas/<sistema>/<banco>/schema.sql` (ou formato nativo do
  engine, ex.: `.dacpac`), catalogado no `db-schema-registry.md`.
- A extração é **sempre somente-leitura** (`pg_dump --schema-only`,
  `mysqldump --no-data`, `SqlPackage /Action:Extract`, etc.) — nunca uma
  ferramenta de migração aplicando mudança a partir daqui.
- **Mudança de schema nunca acontece neste repositório** — apenas
  documentação do estado atual. Quando uma mudança de schema for necessária,
  ela nasce como tarefa dentro do repositório de projeto responsável por
  aquele sistema, seguindo `vpndev-standards`.
- Schema desatualizado (sem re-extração após uma mudança conhecida no sistema)
  é tratado como drift e aparece no relatório do Drift Gate deste repositório.

## Grafo de Plataforma (2 Níveis)

- Este repositório mantém o **nível de plataforma** do grafo: `platform-graph.yaml`
  e `platform-graph.md`, listando cada recurso/superfície compartilhada
  (conta cloud, tenant, VNet hub, política M365, ambiente D365 etc.), seu
  `iac_status` (`nao_iniciado` · `parcial` · `completo`), a ferramenta usada e
  quais repositórios de workload dependem dele.
- Todo repositório de **workload** (`vpndev-standards`) que consome uma
  superfície listada aqui deve declarar essa dependência no seu próprio
  `impact-map.md` (campo "Impacto em superfície de plataforma compartilhada")
  — é assim que uma mudança em um projeto sinaliza risco para outros projetos
  que compartilham o mesmo ambiente/cliente.
- Adicionar/remover uma superfície de plataforma é, por si, uma mudança de
  arquitetura organizacional — classificar como **S3 ou S4** (ver abaixo) e
  exigir `impact-map.md` mesmo dentro deste repositório de plataforma.

## Classificação de Complexidade e Modelo de IA para Trabalho de Plataforma/Legado

- Reutiliza a mesma régua S0–S4 do `vpndev-standards`, com o seguinte mapeamento
  específico para tarefas de infraestrutura/legado:

  | Nível | Tarefa típica de plataforma/legado | Modelo de IA | Revisão humana |
  |---|---|---|---|
  | S0/S1 | 1 recurso novo, módulo AVM/pattern documentado, atualização de inventário | Auto / modo rápido | Opcional |
  | S2 | Múltiplos recursos em um ambiente, refatorar saída de `aztfexport`/`terraformer` em módulos | Modelo de reasoning | Recomendada |
  | S3/S4 | Ambiente compartilhado entre projetos, reconciliação de legado tocando produção, qualquer coisa com impacto financeiro/compliance | Modelo de reasoning mais forte | **Obrigatória, sempre** |
- **Toda importação/reconciliação de ambiente legado (aztfexport, terraformer,
  exportação M365DSC/GAM/pac solution) é classificada no mínimo S3** e
  **nunca é atribuída ao Copilot coding agent de forma autônoma** —
  `agent:autonomous-ok` nunca se aplica a issues deste repositório
  independente de qualquer outro label presente.
- Antes de qualquer geração/sugestão de Terraform para Azure, consultar a
  ferramenta de boas práticas correspondente (`azure-azureterraformbestpractices`)
  e o guia por serviço do Well-Architected Framework — não gerar Terraform "de
  memória" sem essa checagem.

## Priorização e Labels

- Reutiliza a taxonomia base do `vpndev-standards`
  (`priority:*`, `complexity:S0`–`S4`, `agent:*`, `status:*`, `dora:*`) e
  acrescenta o rótulo **`type:legacy-import`** para qualquer issue de
  importação/reconciliação de ambiente legado — sempre combinado com
  `complexity:S3` ou `S4`, nunca com `agent:autonomous-ok`.
- `type:incident` (Ocorrência CRM N1 → issue de infraestrutura) segue a mesma
  regra do `vpndev-standards`: sempre bloqueia autonomia, independente de
  complexidade.

## Decisões de Arquitetura (ADRs)

- Decisões que afetem a topologia de plataforma (nova superfície
  compartilhada, mudança de ferramenta de reconciliação por domínio, adoção
  de novo provider Terraform) são registradas como ADR neste repositório
  (`docs/adr/`), nunca apenas como comentário de PR.

Ver o detalhamento técnico completo em
[`docs/platform-standards-and-legacy-infra.md`](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/speckit-vpndev-standards/blob/main/docs/platform-standards-and-legacy-infra.md) —
matriz de ferramentas por domínio, fluxo de reconciliação zero-diff, e o
piloto interno (Venha Pra Nuvem como "Cliente Frontier").

{CORE_TEMPLATE}
