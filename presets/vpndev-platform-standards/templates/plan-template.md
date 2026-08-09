<!--
  Este bloco é inserido pelo preset `vpndev-platform-standards` (estratégia
  `append`) ao final do plan-template.md nativo do Spec Kit — não substitui
  nenhuma seção existente. Formaliza o planejamento de trabalho de
  plataforma/ambiente/legado (inventário, reconciliação, importação de IaC).
-->

## VPN Dev (Plataforma) — Ambiente e Ferramenta de Reconciliação

*Preencher antes de qualquer gate. Determina qual mecanismo de zero-diff será
usado para validar esta feature.*

| Campo | Valor |
|---|---|
| **Cliente/Tenant** | [herdado da constituição — confirmar] |
| **Ambiente(s) afetado(s)** | prod · hml · dev *(marcar; para prod, reforçar que este repo não aplica nada diretamente)* |
| **Nuvem(ns)/plataforma(s)** | Azure · AWS · GCP · GWS · M365 · D365 *(marcar as aplicáveis)* |
| **Domínio principal** | infra (Terraform) · tenant/config (M365DSC/GAM) · aplicação (pac/Solutions) · schema de banco |
| **Ferramenta de reconciliação** | `terraform plan` · `Test-M365DSCConfiguration` · export GAM · `pac solution` diff · extração de schema |
| **Este trabalho aplica mudança direta em algum ambiente?** | **Não** *(deve ser sempre "Não" neste repositório — se "Sim", está no repositório errado; mover para um repositório de projeto)* |

## VPN Dev (Plataforma) — Checklist de Zero-Diff

*Obrigatório antes de marcar qualquer recurso como `iac_status: completo` no
`platform-graph.yaml`.*

- [ ] Reconciliação executada com a ferramenta do domínio (ver tabela acima)
- [ ] Resultado é diff vazio/zero (`0 to add, 0 to change, 0 to destroy` ou
      equivalente) — anexar evidência (output do comando) no PR
- [ ] Caso o diff não seja zero: recurso permanece `parcial`, causa registrada
      no `legacy-inventory.md`, e plano de correção com data-alvo definido
- [ ] Para bancos de dados: schema extraído (somente leitura) e comparado —
      diff vazio confirmado antes de atualizar `db-schema-registry.md`

## VPN Dev (Plataforma) — Grafo de 2 Níveis

**Arquivos:**
- `platform-graph.yaml` — fonte de verdade estrutural das superfícies de plataforma
- `platform-graph.md` — diagramas Mermaid para leitura humana
- `legacy-inventory.md` — auditoria as-is por nuvem/domínio
- `db-schema-registry.md` — catálogo de schemas de bancos legados

**Checklist:**
- [ ] `platform-graph.yaml`/`.md` atualizados com toda superfície nova/alterada
- [ ] Cada superfície nova/alterada tem `iac_status` correto (`nao_iniciado` ·
      `parcial` · `completo`) e lista de workloads dependentes
- [ ] Se esta superfície é consumida por algum repositório de workload, o
      `impact-map.md` correspondente naquele repositório foi sinalizado para
      atualização (abrir issue lá se você não tem permissão de editar direto)
- [ ] Para S3/S4: `impact-map.md` **neste** repositório de plataforma também
      criado/atualizado

## VPN Dev (Plataforma) — Classificação e Modelo de IA

| Campo | Valor |
|---|---|
| **Nível** | S0 · S1 · S2 · **S3** · S4 *(importação/reconciliação de legado = mínimo S3)* |
| **Modelo de IA** | Auto / Reasoning / Modelo mais forte *(ver constituição)* |
| **Revisão humana obrigatória** | Sim, sempre para S3/S4 — importação/reconciliação de legado nunca é autônoma |
| **Label `type:legacy-import` aplicado?** | Sim/Não |
