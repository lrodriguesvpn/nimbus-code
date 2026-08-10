# Padrões de Plataforma/Cliente e Infraestrutura Legada

Este documento detalha o preset
[`nimbus-code-platform-standards`](../presets/nimbus-code-platform-standards) — o par
complementar do [`nimbus-code-standards`](../presets/nimbus-code-standards) para
repositórios que representam o **ambiente real de um cliente/tenant**
(contas cloud, tenants M365/GWS, ambiente D365, sistemas legados), em vez de
um projeto/feature de software isolado.

## 1. Por que dois presets?

Um repositório de projeto (`nimbus-code-standards`) modela **módulos de código** e
muda um sistema através de deploys revisados em PR. Um repositório de
plataforma modela **o ambiente real de um cliente** — que muitas vezes tem
partes não-Terraformadas (legado), é compartilhado por múltiplos projetos, e
onde uma mudança feita "pelo projeto errado" pode quebrar outro projeto que
depende do mesmo ambiente sem que ninguém tenha percebido a dependência.

Misturar os dois modelos no mesmo repositório/preset gera dois problemas
recorrentes:
1. O grafo de módulos de código (`graph.yaml`) não tem vocabulário para
   representar "esta VNet é compartilhada por 3 projetos diferentes".
2. A régua de complexidade S0–S4, pensada para código, não força
   automaticamente revisão humana e classificação alta para "eu acabei de
   rodar `aztfexport` num ambiente que nunca foi Terraformado" — que é
   estruturalmente mais arriscado que uma feature de código nova.

Por isso: **um repositório usa um dos dois presets, nunca os dois.**

| | `nimbus-code-standards` | `nimbus-code-platform-standards` |
|---|---|---|
| Representa | Projeto/feature de software | Ambiente real de um cliente/tenant |
| Muda o ambiente? | Sim, via IaC revisado em PR | **Nunca** — somente observação/inventário |
| Grafo | `graph.yaml` (módulos de código) | `platform-graph.yaml` (superfícies de plataforma) |
| Quando uma mudança real é necessária num sistema legado | N/A | Nasce um **novo repositório de projeto** para essa mudança |

## 2. Regra de Ouro — Nunca Aplicar Mudança Direta

Um repositório de plataforma é **somente-observação por natureza**: ele
registra o estado real (inventário, IaC gerado a partir do estado real,
schemas de bancos legados, grafo de superfícies compartilhadas). Nenhuma
automação dele executa `terraform apply`, altera um recurso via CLI de
provedor, importa uma `pac solution`, ou qualquer comando de escrita contra
um ambiente real — nem mesmo credenciais de escrita são configuradas nele.

**Isso vale objetivamente também para a produção da própria VPN (Venha Pra
Nuvem)**, quando este preset for aplicado ao repositório piloto interno — não
existe exceção "porque é a gente". Se uma tarefa neste tipo de repositório
pedir uma mudança real em qualquer ambiente, ela está no repositório errado:
a mudança nasce em um repositório de projeto (`nimbus-code-standards`) e,
quando o sistema/ambiente afetado ainda não tem um projeto responsável,
**um novo projeto nasce especificamente para essa mudança**.

## 3. Critério de Verdade — Reconciliação de Zero-Diff

Um recurso só é considerado "capturado corretamente" quando a comparação
entre o artefato versionado e o estado real do ambiente mostra **zero
diferenças** — usando o mecanismo de reconciliação nativo do domínio:

| Domínio | Mecanismo de reconciliação | Resultado exigido |
|---|---|---|
| Terraform (Azure/AWS/GCP) | `terraform plan` | `0 to add, 0 to change, 0 to destroy` |
| Microsoft 365 | `Test-M365DSCConfiguration` / comparação MOF | 100% conformidade |
| Google Workspace | Export atual (GAM/Admin SDK) vs. desired state versionado | diff vazio |
| Dynamics 365 / Power Platform | `pac solution` exportado vs. solution unpacked no repo | diff vazio |
| Schema de banco (legado) | Extração read-only vs. schema versionado | diff vazio |

Enquanto o diff não for zero, o recurso permanece `iac_status: parcial` no
`platform-graph.yaml` — nunca `completo`. Diff-zero não é permanente: é
reavaliado a cada drift-check agendado, e qualquer drift detectado reabre o
status para `parcial` até nova reconciliação.

> **Por que isso importa mais aqui do que num projeto normal:** num projeto
> normal, `terraform plan` já é rotina a cada PR. Num ambiente legado sendo
> importado pela primeira vez, o risco é declarar "prontinho, virou IaC" com
> base numa exportação que na verdade omitiu atributos, segredos ou
> dependências — e só descobrir isso quando alguém rodar `apply` e o plano
> mostrar mudanças destrutivas inesperadas. Zero-diff confirmado é o único
> jeito honesto de dizer "isto é verdade".

## 4. Matriz de Ferramentas por Domínio

Regra geral (alinhada ao Well-Architected Framework): **Terraform governa a
camada de infraestrutura** (o recurso existe, topologia, rede, IAM);
**ferramentas nativas de cada plataforma governam a camada de
configuração/tenant/aplicação**. Misturar as duas na mesma ferramenta é a
causa mais comum de state bloat e drift silencioso.

| Domínio | Terraform? | Ferramenta de referência | Por quê |
|---|---|---|---|
| **Azure — infraestrutura** (rede, compute, storage, IAM, PaaS) | ✅ Sim | `azurerm`/`azapi` + módulos **AVM** (Azure Verified Modules, já alinhados ao WAF) | Provider mais maduro dos três; AVM é mantido pela própria Microsoft |
| **Azure — legado/reverso** | ✅ Sim | `aztfexport` (oficial Microsoft) | Ferramenta oficial de reverse-export, por recurso/resource group/query do Resource Graph |
| **AWS — infraestrutura** | ✅ Sim | Provider `aws` + módulos `terraform-aws-modules` (registry público, referência de facto) | Cobertura ampla e madura |
| **AWS — legado/reverso** | ✅ Sim | `terraformer` (externo, via CLI) | Sem tooling MCP dedicado nesta stack — usar via linha de comando |
| **GCP — infraestrutura** | ✅ Sim | Provider `google`/`google-beta` + módulos oficiais do Google | Padrão da comunidade e do próprio Google |
| **GCP — legado/reverso** | ✅ Sim | `terraformer` (originado no Google Cloud Platform, também suporta AWS/Azure) | Mesma ferramenta cobre múltiplos provedores |
| **Kubernetes (AKS/EKS/GKE) — o cluster** | ✅ Sim | Terraform cria cluster/node pools/rede | Camada de infraestrutura |
| **Kubernetes — o que roda dentro do cluster** | ❌ Não | GitOps (Flux/ArgoCD) ou Helm | Padrão WAF/CNCF: "Terraform para no limite do cluster" |
| **Microsoft 365 — baseline de tenant** (Exchange, SharePoint, Teams, Intune, Conditional Access, DLP) | ❌ Não (provider comunitário imaturo para isso) | **Microsoft365DSC** (PowerShell DSC) | Padrão de facto usado pela própria Microsoft em consultoria/FastTrack |
| **Entra ID** (apps, service principals, roles) | ✅ Sim, fatia madura | Provider `azuread` | Cobertura sólida e amplamente usada |
| **Google Workspace** (usuários, grupos, OUs, políticas) | ⚠️ Parcial | Provider `googleworkspace` onde cobre; **GAM** (script Python, referência da comunidade GWS) como principal | Provider Terraform tem manutenção limitada; GAM é o padrão de facto de administradores GWS |
| **Dynamics 365 / Power Platform — ambiente/DLP** | ✅ Sim (provider oficial em maturação) | Provider `microsoft/power-platform` | Cobre criação de ambiente, políticas DLP, conectores |
| **Dynamics 365 / Power Platform — customização** (entidades, forms, plugins, flows) | ❌ Não | **Power Platform CLI (`pac`)** + Solutions | ALM oficial da Microsoft para Power Platform — não é modelado como recurso de infraestrutura |
| **Segredos** (o recurso, não o valor) | ✅ Sim para o recurso | Key Vault/Secrets Manager via Terraform | O **valor** do segredo nunca deveria viver em `.tf`/state — injeção externa |
| **Schema/dados de banco** | ❌ Não | Extração read-only por engine (ver seção 6) | Fora do escopo de infraestrutura — é dado da aplicação |

### Ferramentas de apoio disponíveis neste ambiente de trabalho

- `azure-azureterraform` — AVM catalog, `aztfexport`, schema AzAPI/azurerm
- `azure-azureterraformbestpractices` — guardrails de versão/estilo a seguir
  **antes** de gerar qualquer Terraform de Azure
- `azure-wellarchitectedframework` — guidance por serviço, nas 5 pilares
- `azure-azuremigrate` — geração de Landing Zone **nova** (greenfield) e
  guidance para modificar uma já existente — não é reverse-export
- Skills AWS (`aws-well-architected-review`, `aws-resource-query`,
  `aws-cost-optimize`) — guidance de pilares e consulta, sem reverse-export
  dedicado (usar `terraformer` via CLI)

## 5. Modelo de IA por Tarefa de Plataforma/Legado

Reaproveita a régua S0–S4 já usada em `nimbus-code-standards`
(ver [`ai-code-quality-and-observability.md`](ai-code-quality-and-observability.md#6-seleção-de-modelo-por-complexidade-s0s4)),
com o seguinte mapeamento específico:

| Nível | Tarefa típica | Modelo de IA | Revisão humana |
|---|---|---|---|
| S0/S1 | 1 recurso novo, módulo AVM/pattern documentado, atualização de inventário | Auto / modo rápido | Opcional |
| S2 | Múltiplos recursos num ambiente, refatorar saída de `aztfexport`/`terraformer` em módulos | Modelo de reasoning | Recomendada |
| S3/S4 | Ambiente compartilhado entre projetos, reconciliação de legado tocando produção, impacto financeiro/compliance | Modelo de reasoning mais forte | **Obrigatória, sempre** |

**Toda importação/reconciliação de ambiente legado é classificada no mínimo
S3** e **nunca é atribuída ao Copilot coding agent de forma autônoma** —
independente de qualquer outro label presente na issue.

## 6. Schemas de Bancos de Dados do Legado

Todo banco de dados de sistema legado deve ter seu schema (DDL, sem dados)
extraído de forma somente-leitura e versionado no repositório de plataforma,
catalogado em `db-schema-registry.md`:

| Engine | Comando de extração (somente schema) |
|---|---|
| PostgreSQL | `pg_dump --schema-only --no-owner --no-privileges` |
| MySQL/MariaDB | `mysqldump --no-data --routines --triggers` |
| SQL Server | `SqlPackage /Action:Extract` (gera `.dacpac`) |
| Oracle | `expdp ... content=metadata_only` ou `dbms_metadata.get_ddl` |

Mudança de schema **nunca acontece no repositório de plataforma** — apenas
documentação do estado atual. Quando uma mudança de schema for necessária,
ela nasce como tarefa dentro do repositório de projeto responsável por
aquele sistema, e o schema atualizado é re-extraído e sincronizado de volta
ao catálogo como parte do fechamento daquele projeto.

## 7. Grafo de 2 Níveis (Plataforma ↔ Workload)

- **Nível de plataforma** (`platform-graph.yaml`/`.md`, neste tipo de
  repositório): superfícies compartilhadas — contas cloud, tenants, redes
  hub, políticas M365, ambientes D365 — com `iac_status`
  (`nao_iniciado`/`parcial`/`completo`) e lista de workloads dependentes.
- **Nível de workload** (`graph.yaml`/`impact-map.md`, em cada repositório de
  projeto): toda feature S2+ que consome uma superfície de plataforma declara
  isso no campo "Impacto em superfície de plataforma compartilhada" do seu
  `impact-map.md`.
- É assim que se rastreia, por exemplo: "este projeto mandou criar algo em
  CI/CD que toca a VNet hub — quais outros projetos/ambientes legados que
  também dependem dessa VNet podem ser afetados?"

## 8. Piloto Interno — Venha Pra Nuvem como "Cliente Frontier"

A própria Venha Pra Nuvem (que usa Azure, GCP, AWS e M365) será o primeiro
caso real de uso deste preset — todo o ambiente atual tratado como legado a
ser auditado e, no que fizer sentido, scriptado ao máximo até virar IaC
completa.

**Sequenciamento confirmado:** o repositório piloto de plataforma da própria
Venha Pra Nuvem **só é criado depois que os dois presets
(`nimbus-code-standards` e `nimbus-code-platform-standards`) estiverem prontos e
publicados** — não antes, e não como um repositório de teste isolado. Isso
garante que o piloto já nasce usando a versão estável da governança, em vez
de virar um caso especial que diverge do padrão.

Quando esse repositório piloto for criado, a regra da seção 2 (nunca aplicar
mudança direta) vale integralmente para a produção da própria VPN — sem
exceção.

## 9. Instalação e Relação com Outros Documentos

```bash
specify preset add --dev ./nimbus-code-spec-kit-template/presets/nimbus-code-platform-standards --priority 5
```

Ver também:
- [`presets/nimbus-code-platform-standards/README.md`](../presets/nimbus-code-platform-standards/README.md) — detalhes de instalação do preset
- [`docs/label-taxonomy-and-autonomous-dev.md`](label-taxonomy-and-autonomous-dev.md) — taxonomia de labels (inclui `type:legacy-import`)
- [`docs/ai-code-quality-and-observability.md`](ai-code-quality-and-observability.md) — régua S0–S4, estimativa de tokens, modelo híbrido
- [`docs/module-graphs.md`](module-graphs.md) — grafo de módulos de código (nível de workload)
