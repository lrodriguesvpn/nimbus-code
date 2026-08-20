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

## Nimbus-Code — Harness Gate

*Preencher ANTES de qualquer gate. Consultar `docs/harness/harness-catalog.yaml`
por `tags` e `bounded_context` relacionados ao domínio desta feature.
Se o arquivo estiver vazio, declarar "Catálogo vazio". Nunca deixar em branco.*

> **Como consultar:** `./scripts/harness-search.sh <tag>` — ou `grep` direto no YAML.
> Consultar também `docs/reuse-catalog.yaml` (padrões de soluções, não de erros).

| Harness consultado (ID) | Padrão de erro evitado | Mitigação preventiva aplicada nesta feature |
|---|---|---|
| [HRN-NNNN ou "Nenhum"] | [descrição do padrão] | [como foi endereçado] |

**Resultado da consulta:**
- [ ] Match encontrado — padrão(ões) de erro relevante(s) declarado(s) acima e mitigado(s)
- [ ] Nenhum padrão de erro relevante encontrado para este domínio
- [ ] Catálogo vazio — nenhum padrão disponível para consulta

> Se esta feature gerar retrabalho > 20% ou incidente, o checklist de fechamento do
> `tasks.md` exige abrir Issue com `harness:pending` e adicionar entrada ao catálogo.
> Ver `docs/harness/harness-guide.md` para o protocolo completo.

## Nimbus-Code — Rastreabilidade AC → Teste → Módulo

*Preencher antes de `/nimbus-code-tasks`. Cada critério de aceitação do `spec.md`
deve ter ao menos um teste de integração planejado e o módulo que o implementa
identificado — assim o Dev entra no `/nimbus-code-implement` sem surpresas.*

| ID AC | Critério (resumo) | Tipo de teste planejado | Arquivo/módulo do teste | Justificativa de ausência (se N/A) |
|---|---|---|---|---|
| AC-1 | [resumo do critério] | integração / unitário / e2e | `tests/<caminho>` | — |
| AC-2 | [resumo do critério] | integração / unitário / e2e | `tests/<caminho>` | — |

> Linha com **Tipo: N/A** exige justificativa explícita (ex.: dependência externa
> indisponível em CI). Critérios sem entrada nesta tabela são tratados como sem
> cobertura — o Qualidade Gate bloqueará o `plan.md`.

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
| **Flag provider** | **OpenFeature** (obrigatório como camada de abstração) + provider pluggable por ambiente — ou `N/A` |
| **Critério de ativação** | [ex.: 10% tráfego por 24h sem aumento de erro rate] |
| **Critério de rollback** | [ex.: taxa de erro > 0,5% ou p99 > 500ms por 5 min] |

> **Regra**: features S3/S4 **obrigam** estratégia `flag`, `canary` ou `blue-green`
> — `direct` não é permitido sem justificativa explícita registrada aqui e no ADL.
>
> **Regra adicional**: quando houver toggle, o plano **deve** declarar OpenFeature como padrão.
> O provider específico (LaunchDarkly, AppConfig etc.) fica atrás da API OpenFeature.

**Justificativa para deploy `direct` (se aplicável):**
[Razão técnica para não usar flag/canary — ex.: migration de schema incompatível
com flag, ou feature de infraestrutura sem plano de ativação incremental]

## Nimbus-Code — Plano de Toggle e Rollout (obrigatório com `flag`)

*Preencher para toda feature que usar toggle. Obrigatório para S3/S4 quando
houver homologações concorrentes.*

| Campo | Valor |
|---|---|
| **Flag key** | `<dominio>.<feature>.<acao>` |
| **Tipo de flag** | `release` · `ops` · `experiment` |
| **Owner da flag** | [squad/pessoa responsável] |
| **Ambiente(s)** | dev · hml · prod |
| **Default por ambiente** | [ex.: dev=off, hml=off, prod=off] |
| **Segmentos de ativação** | [ex.: cliente-piloto, canary-10, interno] |
| **Estratégia de rollout** | [ex.: hml interno → hml cliente piloto → prod canary 10% → prod 100%] |
| **Kill switch definido?** | Sim/Não — [chave/caminho de operação] |
| **Critério de limpeza** | [ex.: remover até D+14 após 100% rollout estável] |
| **Issue/tarefa de remoção criada?** | Sim/Não — [ID] |

**Conflitos funcionais entre homologações (quando aplicável):**
- Decisor de negócio/arquitetura: [nome/time]
- Regra de precedência entre frentes: [qual comportamento vence em conflito]
- Evidência registrada no ADL: [link/âncora da decisão]

## Nimbus-Code — Cost Reference

*Obrigatório para features com participação híbrida agente+humano. O objetivo é
deixar explícito como estimativa e consumo real serão rastreados ao longo do ciclo.*

| Campo | Valor |
|---|---|
| **Token estimate range** | ~[X]–[Y] mil tokens (coerente com Classificação de Complexidade) |
| **Human effort estimate range** | ~[X]–[Y] horas (quando houver execução/revisão humana) |
| **Tracking method** | [ex.: tabela "Estimativa vs. Consumo Real" no tasks.md + campo "Horas Humanas" no GitHub Project] |
| **Budget ceiling (optional)** | [ex.: ~US$150] |

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

**Regra de decisões de arquitetura — não impor, documentar e pedir aprovação**:
se durante o planejamento o agente identificar uma decisão de arquitetura (do
usuário ou proposta por ele mesmo) que diverge do padrão institucional, o
agente **não implementa silenciosamente a preferência dele nem a do usuário**.
Ele registra a divergência no Architecture Decision Log abaixo, explica
objetivamente por que considera fora do padrão, e:
- Se o item estiver marcado **Bloqueante** na tabela abaixo: não há exceção
  possível — o gate falha até o controle existir de fato (ex.: não existe
  "justificativa" que substitua ter um backup).
- Se o item estiver marcado **Escapável (ADL)**: o usuário pode manter a
  decisão fora do padrão, mas precisa justificar explicitamente no ADL e essa
  justificativa precisa de aprovação (do owner do repo ou de quem a
  constituição designar) antes do gate ser considerado satisfeito.

| Domínio | Controles aplicáveis | Escapável via ADL? | Status | Observações |
|---|---|---|---|---|
| **Backup & Disaster Recovery** | Todo datastore com dado real (produção) tem backup automatizado, retenção definida e restore testado/documentado ao menos uma vez | **Não — bloqueante** | | Perda de dado não se justifica, se previne. Sem exceção mesmo com aprovação do owner |
| Autenticação (SSO) | Sistemas novos (greenfield) devem usar SSO | Sim, com justificativa no ADL | | Se não usar SSO, registrar justificativa no ADL — caso contrário este gate é bloqueante |
| Segredos no código/repositório | Nunca em texto plano; secret scanning bloqueia merge se detectar | **Não — bloqueante** | | Vazamento de credencial é irreversível, sem escape hatch |
| Branch/merge protegido | PR obrigatório + revisão antes de merge em branch protegida; nenhum merge com CI vermelho ou check obrigatório pulado | **Não — bloqueante** | | Convenção já vigente neste bundle; formalizado aqui como gate explícito |
| Isolamento de ambiente | Credencial de produção nunca usada em ambiente de dev/test | **Não — bloqueante** | | |
| Containers | Imagem base pinada, scan de vulnerabilidade, usuário não-root | Sim, com justificativa no ADL | | |
| CI/CD | Segredos via cofre/CI secrets, least privilege no service account do pipeline | Sim, com justificativa no ADL | | |
| IaC — provider(s) usado(s) | 100% da infra desta feature via IaC (nenhuma alteração manual); **Terraform** como framework padrão para AWS/GCP/Azure; `plan` revisado em PR, sem credenciais hardcoded, state remoto protegido; qualquer `destroy` no `terraform plan` requer aprovação do owner via GitHub Environment protegido (ver `templates/workflows/terraform-plan-gate.yml`) | Sim, com justificativa no ADL | | Se usar ferramenta nativa do provedor (CDK/Bicep/Deployment Manager) em vez de Terraform, justificar no Architecture Decision Log abaixo. O gate de `destroy` em si **não** é escapável — todo destroy detectado exige aprovação, independente do provider de IaC |
| Banco de dados | TLS/mTLS obrigatório para dado sensível em trânsito | **Não — bloqueante** | | |
| **Firewall / Segmentação de rede** | Regras de firewall/least exposure, sem exposição pública desnecessária | Sim, com justificativa no ADL | | Fortemente recomendado — aceitar ausência exige justificativa explícita e aprovação do owner, não é silencioso |
| Observabilidade | Logs, métricas e alertas mínimos definidos para os componentes críticos | Sim, com justificativa no ADL | | Pode ser adiado para fase seguinte com data definida, mas precisa estar registrado |

**Riscos identificados e decisão:**
[Lista de riscos relevantes encontrados durante o planejamento e a decisão tomada:
endurecer agora / mitigar em fase seguinte (com data) / aceitar risco documentado
— aplicável apenas aos itens marcados "Escapável via ADL"]

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

*Preencher para decisões técnicas relevantes desta feature, e **obrigatoriamente**
para qualquer item marcado "Escapável via ADL" nos gates acima que não seguiu o
padrão institucional. Decisões triviais/óbvias não precisam de entrada aqui.*

| Decisão | Alternativas consideradas | Opção escolhida | Trade-off assumido | Justificativa do desvio (se aplicável) | Aprovado por |
|---|---|---|---|---|---|
| [ex.: estratégia de mensageria] | [ex.: Pub/Sub vs Kafka vs polling] | [opção] | [o que se perde/ganha com a escolha] | N/A — não é desvio de padrão | — |
| [ex.: framework de IaC, apenas se diferente do padrão Terraform] | [ex.: Terraform vs Bicep] | [ex.: Bicep, por exigência de compliance nativo do Azure Policy neste workload] | [ex.: perde padronização multi-cloud com os demais projetos, ganha integração nativa com Azure Policy/Defender] | [justificativa explícita do owner] | [nome/handle do owner] |
| [ex.: sem Firewall/segmentação de rede nesta fase] | [ex.: WAF completo vs. lançar sem, por prazo] | [ex.: lançar sem, com endurecimento no sprint seguinte] | [ex.: janela de exposição maior até a data X] | [ex.: prazo comercial inegociável, ver Issue #NNN] | [nome/handle do owner] |
