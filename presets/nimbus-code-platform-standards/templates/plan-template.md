<!--
  Este bloco é inserido pelo preset `nimbus-code-platform-standards` (estratégia
  `append`) ao final do plan-template.md nativo do Nimbus Code — não substitui
  nenhuma seção existente. Formaliza o planejamento de trabalho de
  plataforma/ambiente/legado (inventário, reconciliação, importação de IaC).
-->

## Nimbus-Code (Plataforma) — Ambiente e Ferramenta de Reconciliação

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

## Nimbus-Code (Plataforma) — Matriz de Ativação por Tenant/Surface (quando usar toggle)

*Preencher quando houver convivência temporária de comportamento entre homologações
ou tenants. Este repositório continua sem `apply`; a matriz orienta rollout no
repositório de workload relacionado.*

| Tenant/Plataforma | Surface/Componente | Flag | Ambiente | Segmento | Estado inicial | Critério de avanço | Critério de rollback |
|---|---|---|---|---|---|---|---|
| `<tenant>` | `<surface>` | `<flag-key>` | dev/hml/prod | piloto/canary/interno | OFF | [métrica/validação] | [limiar de erro] |

> Se não houver toggle neste trabalho, preencher com `N/A`.

## Nimbus-Code (Plataforma) — Checklist de Zero-Diff

*Obrigatório antes de marcar qualquer recurso como `iac_status: completo` no
`platform-graph.yaml`.*

- [ ] Reconciliação executada com a ferramenta do domínio (ver tabela acima)
- [ ] Resultado é diff vazio/zero (`0 to add, 0 to change, 0 to destroy` ou
      equivalente) — anexar evidência (output do comando) no PR
- [ ] Caso o diff não seja zero: recurso permanece `parcial`, causa registrada
      no `legacy-inventory.md`, e plano de correção com data-alvo definido
- [ ] Para bancos de dados: schema extraído (somente leitura) e comparado —
      diff vazio confirmado antes de atualizar `db-schema-registry.md`

## Nimbus-Code (Plataforma) — Grafo de 2 Níveis

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

## Nimbus-Code (Plataforma) — Gate de Fase

*Preencher com a fase atual da plataforma no pipeline (`iac_lifecycle_stage`) e
confirmar o critério de saída antes de marcar este plan como pronto para merge.*

| Campo | Valor |
|---|---|
| **Fase atual (`iac_lifecycle_stage`)** | discovery · imported · plan_diff_zero · landing_zone_generated · managed |
| **Fase alvo após este trabalho** | [fase seguinte — ou mesma se não houver avanço de fase] |
| **Critério de saída desta fase** | [descrever o critério específico — ver tabela na constituição] |

### Gate: `discovery → imported`

*Preencher apenas se este trabalho avança a plataforma para `imported`.*

- [ ] `nimbus-discovery-report.md` preenchido e referenciado no `platform-graph.yaml`
- [ ] Revisão por arquiteto ou analista sênior feita (não apenas agente)
- [ ] Lacunas priorizadas no discovery report com responsável e ferramenta definidos

### Gate: `imported → plan_diff_zero`

*Preencher apenas se este trabalho avança a plataforma para `plan_diff_zero`.*

- [ ] IaC gerado e versionado (`aztfexport`, `terraformer`, exportação M365DSC/GAM/pac)
- [ ] `terraform plan` (ou equivalente do domínio) executado sem erro — output colado abaixo
- [ ] Resultado: **`Plan: 0 to add, 0 to change, 0 to destroy`** (ou equivalente de diff-zero)

```
# Colar aqui o output completo do terraform plan / Test-M365DSCConfiguration / diff equivalente
# que comprova diff-zero. Obrigatório antes de merge.
```

### Gate: `plan_diff_zero → landing_zone_generated`

*Preencher apenas se este trabalho avança a plataforma para `landing_zone_generated`.*

- [ ] `landing-zone/<platform-id>/design.md` criado/atualizado com topologia real
- [ ] `landing-zone/<platform-id>/checklist-caf.md` preenchido por nuvem
- [ ] Gaps registrados no `design.md` com responsável e data alvo
- [ ] Landing Zone revisada por arquiteto (S3 mínimo)

### Gate: `landing_zone_generated → managed`

*Preencher apenas se este trabalho estabelece gestão contínua da plataforma.*

- [ ] Drift-check agendado (workflow periódico de `terraform plan` ou equivalente) configurado
- [ ] Alerta de drift configurado (notificação para o time responsável)
- [ ] Responsável técnico pela plataforma definido e registrado na constituição

## Nimbus-Code (Plataforma) — Classificação e Modelo de IA

| Campo | Valor |
|---|---|
| **Nível** | S0 · S1 · S2 · **S3** · S4 *(importação/reconciliação de legado = mínimo S3)* |
| **Modelo de IA** | Auto / Reasoning / Modelo mais forte *(ver constituição)* |
| **Revisão humana obrigatória** | Sim, sempre para S3/S4 — importação/reconciliação de legado nunca é autônoma |
| **Label `type:legacy-import` aplicado?** | Sim/Não |

## Nimbus-Code (Plataforma) — Gate de Não-Negociáveis e Decisões de Arquitetura

*GATE adicional: deve ser preenchido e aprovado antes de qualquer avanço de fase
(`iac_lifecycle_stage`). Cobre riscos específicos de trabalhar com ambiente real
de cliente/legado que os gates de fase acima não detalham por domínio técnico.*

**Regra de decisões de arquitetura — não impor, documentar e pedir aprovação**:
se durante o planejamento o agente identificar uma decisão (do usuário ou
proposta por ele mesmo) que diverge do padrão institucional deste preset, o
agente **não implementa silenciosamente a preferência dele nem a do usuário**.
Ele registra a divergência no Architecture Decision Log abaixo, explica
objetivamente por que considera fora do padrão, e:
- Se o item estiver marcado **Bloqueante**: não há exceção possível — o gate
  falha até o controle existir de fato, mesmo para a produção da própria VPN.
- Se o item estiver marcado **Escapável (ADL)**: o usuário pode manter a
  decisão fora do padrão, mas precisa justificar explicitamente no ADL e essa
  justificativa precisa de aprovação do owner/arquiteto responsável antes do
  gate ser considerado satisfeito.

| Domínio | Controles aplicáveis | Escapável via ADL? | Status | Observações |
|---|---|---|---|---|
| **Backup do estado original** | Antes de qualquer discovery/import de um sistema legado, backup/snapshot do estado original confirmado e acessível | **Não — bloqueante** | | Garante ponto de retorno antes de auditar/exportar; sem isso, a auditoria em si vira risco |
| **Nunca aplicar mudança direta** | Nenhuma automação deste repositório executa `apply`/escrita contra ambiente real, em nenhuma circunstância | **Não — bloqueante** | | Vale integralmente também para a produção da própria VPN — ver "Regra de Ouro" da constituição |
| **Credencial de escrita** | Nenhum secret/credencial com permissão de escrita configurado neste tipo de repositório | **Não — bloqueante** | | Reforça a natureza somente-leitura do repositório |
| **Schema de banco legado** | Extração é sempre somente-leitura (DDL/metadata); nunca extrai dado real | **Não — bloqueante** | | |
| **Remediação automática de drift** | Nenhuma automação corrige drift sozinha — todo drift detectado abre item para revisão humana | **Não — bloqueante** | | Auto-fix em ambiente legado é estruturalmente arriscado |
| Firewall / segmentação de rede da plataforma | Revisado antes de declarar `iac_status: completo` para uma superfície | Sim, com justificativa no ADL | | Fortemente recomendado — aceitar ausência exige justificativa explícita e aprovação do owner/arquiteto |
| IaC não-Terraform (CDK/Bicep/nativo do provedor) | Terraform é o padrão desta matriz de ferramentas (ver `docs/platform-standards-and-legacy-infra.md` seção 4) | Sim, com justificativa no ADL | | |
| Prazo de regularização (modo somente-observação → IaC completo) | Toda superfície `parcial` tem data-alvo de correção definida | Sim, com justificativa no ADL | | Ausência de prazo não é aceitável silenciosamente — se não houver prazo definido, registrar o motivo |

**Riscos identificados e decisão:**
[Lista de riscos relevantes encontrados durante o planejamento e a decisão tomada
— aplicável apenas aos itens marcados "Escapável via ADL"]

## Nimbus-Code (Plataforma) — Architecture Decision Log

*Preencher para decisões técnicas relevantes desta feature, e **obrigatoriamente**
para qualquer item marcado "Escapável via ADL" no gate acima que não seguiu o
padrão institucional.*

| Decisão | Alternativas consideradas | Opção escolhida | Trade-off assumido | Justificativa do desvio (se aplicável) | Aprovado por |
|---|---|---|---|---|---|
| [ex.: ferramenta de reconciliação de um domínio específico] | [ex.: `terraformer` vs. script próprio] | [opção] | [o que se perde/ganha] | N/A — não é desvio de padrão | — |
| [ex.: sem firewall revisado nesta superfície ainda] | [ex.: revisar agora vs. registrar como `parcial` com prazo] | [ex.: `parcial`, revisão agendada] | [ex.: janela de exposição maior até a data X] | [ex.: superfície legada sem dono técnico definido ainda] | [nome/handle do owner/arquiteto] |
