<!--
  Este bloco é inserido pelo preset `nimbus-code-standards` (estratégia `append`) ao final
  do plan-template.md nativo do Nimbus Code — não substitui nenhuma seção existente
  (Summary, Technical Context, Constitution Check, Project Structure, Complexity
  Tracking). Ele formaliza práticas que hoje viviam soltas nas skills internas
  de refinamento técnico e planejamento DevOps da Nimbus-Code.
-->

## Nimbus-Code — Classificação de Complexidade (S0–S4)

*Preencher antes de qualquer gate. Determina modelo de IA, artefatos obrigatórios e
nível de revisão exigido.*

| Campo | Valor |
|---|---|
| **Nível** | S0 · S1 · S2 · **S3** · S4 *(marcar um)* |
| **Justificativa** | [ex.: cruza order-service e billing-service via evento] |
| **Modelo de IA** | Auto / Reasoning / Modelo forte *(conforme tabela abaixo)* |
| **Revisão humana obrigatória** | Sim (S4) · Não (S0–S3) |
| **Padrão reutilizado encontrado?** | Sim (tag: `[tag do catálogo]`) · Não *(ver `docs/reuse-catalog.yaml` antes de preencher)* |
| **Estimativa de tokens (input+output)** | ~[X]–[Y] mil tokens — baseado no multiplicador de custo relativo do nível (ver `docs/ai-code-quality-and-observability.md` seção 6), com desconto se um padrão reutilizado foi encontrado (seção 9) |

> S0 = documentação · S1 = função isolada · S2 = módulo · S3 = múltiplos módulos ·
> S4 = arquitetura, segurança, dados ou integração crítica

> A estimativa de tokens é preenchida **antes** de `/nimbus-code-tasks` e comparada
> com o consumo real no fechamento do `tasks.md` (ver checklist "Estimativa vs.
> Consumo Real de Tokens"). Não é um compromisso exato — é uma faixa para
> permitir comparar depois.

## Nimbus-Code — Module Dependency Graph

*OBRIGATÓRIO — deve estar presente e atualizado antes de `/nimbus-code-tasks`.
Para S3/S4, criar também `impact-map.md` na mesma pasta.*

**Arquivos:**
- `specs/<feature-slug>/graph.yaml` — fonte de verdade estruturada (lida pelo Graph Guard)
- `specs/<feature-slug>/graph.md` — diagramas Mermaid para leitura humana
- `specs/<feature-slug>/impact-map.md` — **obrigatório para S3 e S4**

**Checklist de manutenção do grafo:**
- [ ] `graph.yaml` criado/atualizado com todos os nós e arestas desta feature
- [ ] `graph.md` criado/atualizado com diagrama por código e diagrama por business
- [ ] Para S3/S4: `impact-map.md` criado/atualizado com análise de risco e plano de rollback
- [ ] Nenhum módulo/serviço novo criado nesta feature está faltando no grafo
- [ ] Dependências externas (third-party, cloud) declaradas em `externals` no `graph.yaml`
- [ ] Grafo será atualizado novamente após `/nimbus-code-implement` se a implementação divergir do plano

## Nimbus-Code — Estratégia de Release

*Declarar antes de `/nimbus-code-tasks`. Para S3/S4, esta escolha alimenta o
`impact-map.md` (simplifica ou complica o plano de rollback).*

| Campo | Valor |
|---|---|
| **Estratégia** | `flag` · `direct` · `canary` · `blue-green` *(marcar uma)* |
| **Feature flag name** | `<nome-da-flag>` — ou `N/A` se não usar flag |
| **Flag provider** | [ex.: LaunchDarkly, AWS AppConfig, OpenFeature] — ou `N/A` |
| **Critério de ativação** | [ex.: 10% tráfego por 24h sem aumento de erro rate] |
| **Critério de rollback** | [ex.: taxa de erro > 0,5% ou p99 > 500ms por 5 min] |

> **Regra**: features S3/S4 **obrigam** estratégia `flag`, `canary` ou `blue-green`
> — `direct` não é permitido sem justificativa explícita registrada aqui e no ADL.

**Justificativa para deploy `direct` (se aplicável):**
[Razão técnica para não usar flag/canary — ex.: migration de schema incompatível
com flag, ou feature de infraestrutura sem plano de ativação incremental]

## Nimbus-Code — SLO Gate

*Preencher para todo componente novo ou alterado de forma relevante. Os valores
aqui definidos são a referência para configuração de alertas (Observability Gate)
e critérios de Go/No-Go do `impact-map.md` (S3/S4).*

| Componente | Latência p99 | Taxa de erro máx. | Disponibilidade | RTO | RPO |
|---|---|---|---|---|---|
| `<serviço>` | [ex.: 200ms] | [ex.: 0,1%] | [ex.: 99,9%] | [ex.: 5 min] | [ex.: 1 min] |

> Deixar `—` apenas quando o componente não expõe SLO mensurável (ex.: job batch
> interno). Omissão sem justificativa bloqueia o Observability Gate.

**SLOs não definidos nesta feature e justificativa:**
[Listar componentes sem SLO e o motivo — ex.: "consumer Kafka assíncrono: sem
SLO de latência, monitorado por lag de fila"]

## Nimbus-Code — Security & DevSecOps Gate

*GATE adicional: deve ser preenchido e aprovado antes de `/nimbus-code-tasks`, junto com
o Constitution Check nativo. Cobre lacunas que a constituição sozinha não detalha
por domínio técnico.*

| Domínio | Controles aplicáveis | Status | Observações |
|---|---|---|---|
| Autenticação (SSO) | Sistemas novos (greenfield) devem usar SSO; ausência de SSO deve estar formalmente declarada e registrada no Architecture Decision Log abaixo | | Se não usar SSO, registrar justificativa no ADL — caso contrário este gate é bloqueante |
| Containers | Imagem base pinada, scan de vulnerabilidade, usuário não-root | | |
| CI/CD | Segredos via cofre/CI secrets, least privilege no service account do pipeline | | |
| IaC — provider(s) usado(s) | 100% da infra desta feature via IaC (nenhuma alteração manual); **Terraform** como framework padrão para AWS/GCP/Azure; `plan` revisado em PR, sem credenciais hardcoded, state remoto protegido | | Se usar ferramenta nativa do provedor (CDK/Bicep/Deployment Manager) em vez de Terraform, justificar no Architecture Decision Log abaixo |
| Banco de dados | TLS/mTLS obrigatório, flags de auditoria mínimas, backup/retenção definidos | | |
| Rede | Regras de firewall/least exposure, sem exposição pública desnecessária | | |
| Observabilidade | Logs, métricas e alertas mínimos definidos para os componentes críticos | | |

**Riscos identificados e decisão:**
[Lista de riscos relevantes encontrados durante o planejamento e a decisão tomada:
endurecer agora / mitigar em fase seguinte (com data) / aceitar risco documentado]

## Nimbus-Code — Qualidade de Código, Testes e Observabilidade Gate

*GATE adicional: deve ser preenchido e aprovado antes de `/nimbus-code-tasks`, junto
com o Constitution Check nativo e o Security & DevSecOps Gate acima. Traduz em
verificações concretas as regras de "Qualidade e Processo" da constituição da
Nimbus-Code (revisão por IA, testes integrados, observabilidade, arquitetura
distribuída e gestão de bugs).*

| Domínio | Controles aplicáveis | Status | Observações |
|---|---|---|---|
| Revisão de código por IA | GitHub Copilot code review solicitado em todo PR desta feature; findings High/Critical bloqueiam merge (mesma régua do SAST/IaC) | | |
| Testes integrados | Cada critério de aceitação do `spec.md` tem teste de integração automatizado correspondente, sempre que tecnicamente viável | | |
| Observabilidade | Logs estruturados, métricas e alertas mínimos instrumentados para os componentes entregues (obrigatório, não condicional) | | |
| Arquitetura distribuída / Microsserviços | Correlation-id/trace-id (W3C Trace Context) propagado ponta a ponta entre serviços; orquestração/coreografia documentada no Architecture Decision Log abaixo | Marcar "N/A" se monólito/sem chamadas entre serviços | |
| Gestão de bugs | Bugs encontrados fora do escopo desta tarefa/feature abertos como Issue no GitHub e atribuídos ao Copilot coding agent | | |

**Critérios de aceitação sem teste de integração automatizado (se houver) — justificativa:**
[Lista de critérios de aceitação do `spec.md` que não terão teste de integração
e o motivo técnico — ex.: dependência externa indisponível em CI]

## Nimbus-Code — Architecture Decision Log

*Preencher apenas para decisões técnicas relevantes desta feature (não é
necessário registrar decisões triviais/óbvias).*

| Decisão | Alternativas consideradas | Opção escolhida | Trade-off assumido |
|---|---|---|---|
| [ex.: estratégia de mensageria] | [ex.: Pub/Sub vs Kafka vs polling] | [opção] | [o que se perde/ganha com a escolha] |
| [ex.: framework de IaC, apenas se diferente do padrão Terraform] | [ex.: Terraform vs Bicep] | [ex.: Bicep, por exigência de compliance nativo do Azure Policy neste workload] | [ex.: perde padronização multi-cloud com os demais projetos, ganha integração nativa com Azure Policy/Defender] |
