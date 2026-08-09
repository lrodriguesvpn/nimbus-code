# Qualidade de Código com IA, Testes Integrados, Observabilidade e Gestão de Bugs

Este documento detalha **como aplicar na prática** as regras adicionadas pelo
preset `vpndev-standards` à seção "Qualidade e Processo" da constituição (ver
[`templates/constitution-template.md`](../presets/vpndev-standards/templates/constitution-template.md)),
ao **Qualidade de Código, Testes e Observabilidade Gate** do `plan.md` (ver
[`templates/plan-template.md`](../presets/vpndev-standards/templates/plan-template.md))
e ao checklist correspondente do `tasks.md` (ver
[`templates/tasks-template.md`](../presets/vpndev-standards/templates/tasks-template.md)).

## 1. Revisão de código por IA (GitHub Copilot) obrigatória

**Regra**: todo Pull Request passa por revisão do Copilot **além** da revisão
humana já exigida pela constituição — uma nunca substitui a outra.

Como aplicar:

- **Preferencial (automático)**: habilitar em Settings → Copilot do
  repositório/organização a solicitação automática do Copilot como revisor em
  todo PR aberto (feature "Copilot code review" / auto-request). Assim nenhum
  dev precisa lembrar de pedir manualmente.
- **Manual, quando não habilitado automaticamente**: solicitar Copilot como
  revisor no próprio PR (botão "Reviewers" → Copilot), ou, em automações/CI,
  usar a ferramenta MCP `request_copilot_review` (disponível no GitHub MCP
  Server já configurado neste ambiente) para acionar a revisão
  programaticamente.
- **Gate de bloqueio**: findings **High/Critical** relatados pelo Copilot
  bloqueiam o merge sob a mesma régua já aplicada a SAST/IaC scanning
  (CodeQL/Checkov/tflint) — supressão exige justificativa técnica explícita.
- Isso é rastreado no `plan.md` pela linha "Revisão de código por IA" do novo
  gate, e por tarefa no `tasks.md` pelo item "Revisão de código por IA (GitHub
  Copilot code review) solicitada no PR e sem findings High/Critical
  pendentes".

## 2. Testes de integração cobrindo os critérios de aceitação

**Regra**: cada critério de aceitação do `spec.md` deve ter, sempre que
tecnicamente viável, um **teste de integração automatizado** correspondente —
não basta cobertura só por testes unitários isolados.

Como aplicar:

- Ao escrever `tasks.md`, nomeie/relacione o teste ao ID do critério de
  aceitação (ex.: `test_AC3_checkout_falha_com_cartao_invalido`), para que a
  rastreabilidade spec → teste seja auditável.
- Quando não for tecnicamente viável (ex.: depende de um serviço externo
  indisponível em CI, hardware específico, etc.), documente a exceção na seção
  "Critérios de aceitação sem teste de integração automatizado — justificativa"
  do novo gate no `plan.md`. Omissão silenciosa não é uma opção válida.
- Testes unitários continuam sendo bem-vindos e não são substituídos — a regra
  exige que exista **também** cobertura de integração ligada ao comportamento
  observável descrito na spec, não apenas ao código internamente.

## 3. Observabilidade obrigatória

**Regra**: logs estruturados, métricas e alertas mínimos são obrigatórios para
todo componente/serviço novo ou alterado de forma relevante — não é opcional
nem condicionado ao tipo de projeto.

Bar mínimo esperado (os "golden signals"):

- **Logs**: estruturados (JSON ou formato parseável), com nível de severidade e
  contexto suficiente para debugging sem acesso ao código-fonte.
- **Métricas**: latência, taxa de erro e throughput (ou o equivalente ao
  domínio) expostas para o stack de monitoramento do projeto.
- **Alertas**: definidos para os componentes críticos, com destinatário e
  limiar claros — não apenas "logamos, alguém vai olhar".

Isso já existia como linha da tabela do Security/DevSecOps Gate; agora também é
verificado por tarefa via checklist no `tasks.md`.

## 4. Microsserviços: correlation-id, tracing e orquestração

**Regra**: em arquiteturas de microsserviços/distribuídas, propagação de
correlation-id ponta a ponta entre serviços e visibilidade da
orquestração/coreografia são obrigatórias.

Padrão recomendado (para detalhar no Architecture Decision Log do `plan.md`
quando a feature envolver mais de um serviço):

- **Trace-id/span-id**: adotar o padrão [W3C Trace Context](https://www.w3.org/TR/trace-context/)
  (`traceparent`/`tracestate`) propagado via headers HTTP/mensageria entre
  serviços, instrumentado com [OpenTelemetry](https://opentelemetry.io/) (SDK
  disponível para a maioria das linguagens/plataformas usadas na VPN Dev).
- **Correlation-id de negócio**: além do trace técnico, manter um
  `X-Correlation-Id` (ou equivalente) estável por transação/requisição de
  negócio, propagado nos logs de todos os serviços envolvidos — permite
  reconstruir o fluxo completo de uma operação mesmo fora de uma ferramenta de
  APM.
- **Orquestração vs. coreografia**: documentar explicitamente no Architecture
  Decision Log qual modelo foi escolhido (orquestrador central vs. eventos
  coreografados) e o trade-off assumido — isso já é coberto pela tabela nativa
  do Architecture Decision Log do preset, só reforçando que é obrigatório
  preencher quando há mais de um serviço envolvido.
- Se a feature/tarefa **não** envolve chamadas entre serviços (monólito), marque
  este item como "N/A" no gate/checklist — não é necessário inventar
  correlation-id onde não há necessidade real.

## 5. Bugs abertos e atribuídos automaticamente ao Copilot

**Regra**: todo bug identificado (CI, produção, revisão de código) que não seja
corrigido dentro da própria tarefa em andamento deve virar uma Issue no GitHub,
atribuída ao Copilot coding agent — nunca ficar só em log/alerta sem
rastreamento formal.

Duas formas de aplicar, conforme o ponto de origem do bug:

- **Interativo (durante o dia a dia de desenvolvimento/triagem)**: abrir a
  Issue normalmente e usar o botão **"Assign to Copilot"** em Assignees — é a
  forma suportada nativamente pelo GitHub para delegar o bug ao Copilot cloud
  agent, que then pesquisa o repositório, cria um plano e abre um PR.
- **Automatizado por label (recomendado para este bundle)**: aplicar o label
  `agent:autonomous-ok` dispara o workflow
  [`.github/workflows/agent-auto-assign.yml`](../.github/workflows/agent-auto-assign.yml),
  que atribui o Copilot coding agent via REST API (`POST
  /repos/{owner}/{repo}/issues/{issue_number}/assignees` com
  `assignees: ["copilot-swe-agent[bot]"]`) — endpoint oficialmente suportado
  para esse fim, desde que autenticado com um token **user-to-server** (PAT),
  nunca o `GITHUB_TOKEN` padrão do workflow (server-to-server, rejeitado por
  essa API). Ver taxonomia completa de labels, guardrails e ordenamento por
  prioridade em
  [`docs/label-taxonomy-and-autonomous-dev.md`](label-taxonomy-and-autonomous-dev.md).
- **Automatizado ad-hoc (ex.: falha de teste em CI, alerta de produção)**: um
  step de workflow do GitHub Actions cria a Issue via `gh issue create` (com
  título, stack trace/logs relevantes e labels, ex.: `type:bug`,
  `agent:autonomous-ok`) — a issue já nasce marcada para acionar o auto-assign
  acima, ou pode ser atribuída na hora via a mesma ferramenta MCP
  `assign_copilot_to_issue` do GitHub MCP Server, se disponível no ambiente.
- Rastreado no `plan.md` pela linha "Gestão de bugs" do novo gate, e por tarefa
  no checklist do `tasks.md`.

## 6. Seleção de Modelo por Complexidade (S0–S4)

**Regra**: toda tarefa deve ser classificada na escala de complexidade abaixo
antes de iniciar a implementação. O modelo de IA é escolhido com base nessa
classificação — nunca usar modelo mais forte que o necessário (custo) nem mais
fraco que o necessário (risco técnico).

### Escala de Complexidade

| Nível | Descrição | Exemplos típicos |
|---|---|---|
| **S0** | Documentação, comentários, textos | README, ADL, docstrings, mensagens de commit |
| **S1** | Função isolada, sem dependência externa | Util, helper, validação simples, mapper |
| **S2** | Módulo completo, testes, refatoração | CRUD de um serviço, módulo novo, suite de testes |
| **S3** | Múltiplos módulos, integração entre serviços | Feature que cruza 2+ serviços, contrato de evento, refatoração cross-module |
| **S4** | Arquitetura, segurança, dados sensíveis ou integração crítica | Auth/authz, schema de banco de dados, API pública, pipeline de dados PII, mudança de infraestrutura core |

### Modelo por Nível

| Nível | Modelo no Copilot | Modo | Artefatos obrigatórios |
|---|---|---|---|
| **S0** | Auto (GPT-5.6 Luna ou Claude Haiku) | Rápido / inline | — |
| **S1** | Auto (GPT-5.6 Luna ou Claude Haiku) | Rápido / inline | — |
| **S2** | Auto (GPT-5.6 Terra ou equivalente) | Padrão | `graph.yaml` + `graph.md` |
| **S3** | GPT-5.4 / Claude Sonnet (reasoning) | Reasoning ativo | `graph.yaml` + `graph.md` + ADL entry |
| **S4** | GPT-5.5 / Claude Opus (máximo) | Reasoning máximo | `graph.yaml` + `graph.md` + `impact-map.md` + revisão humana |

### Ajuste por Projeto

A **régua de complexidade S0–S4 em si é não-negociável** (todo projeto do
bundle usa a mesma escala e a mesma exigência de revisão humana obrigatória em
S4 — isso é o que permite comparar custo/qualidade entre projetos da VPN Dev).

O que **pode** ser ajustado por projeto é a coluna **"Modelo no Copilot"**: a
tabela acima é a recomendação padrão do bundle, mas cada projeto pode adaptar
qual modelo específico usar em cada nível conforme:

- política de modelos habilitados pela organização (Settings → Copilot →
  Policies) — se um modelo recomendado aqui não estiver disponível, o projeto
  documenta o substituto equivalente;
- restrições de compliance/dados sensíveis do projeto (ex.: exigir um modelo
  específico certificado para residência de dados);
- disponibilidade de modelos novos que substituam os listados aqui com o
  tempo (esta tabela não é atualizada automaticamente).

Para ajustar, documente a substituição no `constitution.md` do próprio projeto
(logo após a seção `{CORE_TEMPLATE}` do `constitution-template.md`, que é onde
conteúdo específico do projeto entra sem conflitar com o que o preset já
define) ou como entrada no Architecture Decision Log do `plan.md`. **Nunca**
remova a exigência de revisão humana em S4 como parte desse ajuste — isso não
é "modelo", é a régua de governança em si.

### Como declarar no início de cada tarefa

O agente (Copilot ou equivalente) deve declarar explicitamente ao receber um
`/speckit-implement` ou iniciar trabalho em qualquer task:

```
Complexidade desta tarefa: S<N> — <justificativa em uma linha>
Modelo selecionado: <modelo>
Estimativa de tokens (input+output): ~<N> mil tokens — <racional: nº de
  arquivos/linhas de diff esperado, iterações previstas, baseado na tabela de
  custo relativo abaixo>
Artefatos de grafo necessários: graph.yaml [+ graph.md] [+ impact-map.md]
```

Se a complexidade real for maior que a declarada no `plan.md`, o agente deve:
1. Parar a implementação.
2. Atualizar a classificação no `plan.md`.
3. Escalar o modelo conforme a nova classificação.
4. Atualizar `graph.yaml`/`graph.md`/`impact-map.md` se necessário.
5. Revisar a estimativa de tokens para o novo nível.

### Medição de Custo por Tipo de Tarefa

O objetivo da escala S0–S4 é reduzir o custo total do código automático sem
sacrificar qualidade. A referência de custo relativo por nível:

| Nível | Custo relativo por tarefa | Meta de distribuição |
|---|---|---|
| S0 | ~1× (base) | 20–30% das tarefas |
| S1 | ~1–2× | 30–40% das tarefas |
| S2 | ~3–5× | 20–30% das tarefas |
| S3 | ~10–20× | 5–10% das tarefas |
| S4 | ~30–50× | <5% das tarefas |

Se a distribuição real de tarefas da equipe mostrar mais de 15% em S3/S4, rever
se a classificação está sendo usada corretamente — muitas tarefas podem estar
sendo superclassificadas.

A política de modelos habilitados para a organização deve ser configurada em
**Organization/Enterprise Settings → Copilot → Policies** para restringir
modelos de alta capacidade (S3/S4) conforme o plano contratado, reforçando a
escala acima no nível organizacional.

### Estimativa de tokens ANTES de codar vs. consumo REAL depois

**Regra**: toda feature deve ter uma estimativa de tokens registrada no
`plan.md` **antes** de `/speckit-tasks` (na mesma tabela de Classificação de
Complexidade — ver
[`plan-template.md`](../presets/vpndev-standards/templates/plan-template.md)),
e o consumo real deve ser confrontado com ela ao final, no fechamento das
tarefas em `tasks.md`.

**Como estimar antes de codar** (heurística, não medição exata):

1. Parta do nível de complexidade já declarado (S0–S4) e do multiplicador de
   custo relativo da tabela acima.
2. Calibre o "1×" (baseline de S0) com o histórico real do seu projeto — não
   existe um número universal correto; um baseline inicial razoável para
   calibrar (até haver histórico próprio) é **~30–60 mil tokens** para uma
   tarefa S0 simples (ex.: atualizar um README curto).
3. Ajuste o multiplicador para cima se a tarefa envolve muitos arquivos, muitas
   iterações esperadas de correção, ou múltiplas chamadas de ferramenta
   (leitura de código extensa, buscas repetidas).
4. Registre o resultado como uma faixa (`~X–Y mil tokens`), não um número
   único — estimativa não é compromisso exato.

**Como medir o consumo real depois** (limitação importante a documentar com o
time): a maioria dos agentes/IDEs **não expõe contagem exata de tokens por
tarefa individual** em tempo real para o próprio agente ler. A fonte prática
de "real" é:

- **GitHub Copilot Premium Requests / uso da organização** (Settings →
  Copilot → Usage, ou API de métricas do Copilot para Enterprise) — dá
  consumo agregado por usuário/dia, não por tarefa isolada. Para aproximar por
  tarefa, correlacione pelo período de tempo em que a tarefa foi trabalhada.
- Se a ferramenta/agente usado expõe uso de tokens da sessão (alguns agentes
  de terceiros mostram isso ao final da execução), registre esse valor
  diretamente — é mais preciso que a aproximação por usage agregado.
- Na ausência de qualquer medição, registre `"não disponível — sem telemetria
  de tokens desta ferramenta"` em vez de inventar um número — a honestidade
  sobre a lacuna é mais útil do que um dado real que os dados não sustentam.

**Onde registrar a comparação**: no checklist de fechamento do `tasks.md`
(seção "VPN Dev — Estimativa vs. Consumo Real de Tokens", adicionada pelo
preset) — ver
[`tasks-template.md`](../presets/vpndev-standards/templates/tasks-template.md).
Variâncias grandes e recorrentes (ex.: real consistentemente >2× a estimativa)
são sinal para recalibrar o baseline do projeto, não para ignorar a prática.

## 7. Modelos do Copilot Agent prioritários — dá para declarar isso no preset?

**Não diretamente no schema do Spec Kit.** `preset.yml`/`extension.yml`/
`bundle.yml` não têm nenhum campo para "modelo de IA preferido" — isso não é
uma configuração de projeto, é uma **política de organização/enterprise do
GitHub Copilot**, configurada fora do Spec Kit em:

- **Organization/Enterprise Settings → Copilot → Policies** — permite habilitar
  ou desabilitar modelos específicos para todos os membros (ex.: bloquear
  certos modelos por política de compliance/custo). Isso é o mecanismo real de
  "obrigatoriedade" — o Spec Kit não tem visibilidade nem controle sobre isso.
- **Model picker do Copilot Chat** — cada dev escolhe o modelo por sessão,
  dentro do conjunto habilitado pela política acima. "Auto" deixa o próprio
  Copilot escolher o modelo mais adequado à tarefa (com desconto de custo).

O que **é possível e recomendado** fazer, mesmo sem enforcement técnico:
documentar uma **lista de prioridade recomendada por tipo de tarefa** como
orientação para devs e para quem administra a política de modelos da
organização. Baseado na [documentação oficial de comparação de modelos do
GitHub Copilot](https://docs.github.com/en/copilot/reference/ai-models/model-comparison):

| Tipo de tarefa | Modelo recomendado (prioridade) |
| --- | --- |
| Uso geral / tarefas agenticas do dia a dia | GPT-5.6 Terra ou GPT-5 mini |
| Trabalho agentico de longa duração (ex.: `/speckit-implement` de features grandes) | GPT-5.3-Codex ou Claude Fable 5 |
| Raciocínio profundo, debugging complexo, análise arquitetural | GPT-5.4 / GPT-5.5 / GPT-5.6 Sol ou Claude Opus 4.7 |
| Exploração de codebase (grep-style, navegação) | GPT-5.4 mini |
| Tarefas simples/repetitivas, respostas rápidas e baratas | GPT-5.6 Luna ou Claude Haiku 4.5 |

Esta tabela é apenas **orientação documentada** — para tornar algo disso
"obrigatório" de fato, é a organização (via Enterprise/Org Settings → Copilot →
Policies) que precisa restringir os modelos habilitados de acordo com esta
priorização, não o bundle do Spec Kit.

## 8. Modelo híbrido: agentes de IA + humanos codando juntos

**Conceito**: na prática, quase nenhuma feature é 100% agente ou 100% humano.
O padrão mais comum é **híbrido**: o agente (Copilot coding agent, ou um dev
usando Copilot Chat/inline) gera a maior parte da implementação, e um humano
entra em pontos específicos — revisão de PR, ajuste manual de um trecho que o
agente não acertou, decisão de arquitetura (S4), ou simplesmente pareamento
ativo durante a tarefa. Para ter **controle de custo real**, os dois lados do
custo total precisam ser somados:

```
Custo real da tarefa = custo de tokens (agente) + (horas humanas × custo/hora do time)
```

Sem capturar o segundo termo, qualquer comparação "economizamos X% com IA" é
enganosa — ela ignora o tempo humano que ainda foi gasto revisando, corrigindo
ou pareando com o agente.

### Onde lançar as horas humanas

Não existe um campo nativo no Spec Kit para isso (specs/plans/tasks são
markdown, não têm schema de apontamento de horas). O bundle resolve isso via
**GitHub Project V2**, criado automaticamente pelo `bootstrap.sh`
(`scripts/setup-github-project.sh`):

1. O script cria um campo numérico customizado **"Horas Humanas"** no Project
   V2 do repositório (ver [README — Bônus: GitHub Project criado
   automaticamente](../README.md#bônus-github-project-criado-automaticamente)).
2. Ao trabalhar em uma issue/PR em modo híbrido, quem faz a parte humana
   (revisão, ajuste manual, pareamento) atualiza esse campo no card do Project
   com o total de horas gastas — pode ser incremental (some ao valor existente
   conforme mais trabalho humano entra na mesma issue).
3. Para tarefas totalmente autônomas (`agent:autonomous-ok`, sem intervenção
   humana além da aprovação do PR), o campo fica em `0` ou só com o tempo de
   revisão do PR (registre também esse tempo — revisão de PR **é** custo
   humano, mesmo que pequeno).
4. Ao fechar a feature, o checklist de fechamento do `tasks.md` (seção "VPN
   Dev — Estimativa vs. Consumo Real de Tokens", ver seção anterior) referencia
   esse campo para compor o custo real total: tokens estimados/reais **+**
   horas humanas do Project.

### Por que não usar comentário de issue ou PR description em vez de um campo

Comentário/descrição funciona para registrar contexto, mas não é **agregável
nem filtrável** — o campo numérico do Project permite somar horas por
`priority:*`, por `type:*`, por sprint/iteração, ou por pessoa, o que é o que
de fato viabiliza um relatório de FinOps confiável. Use o campo do Project
como fonte de verdade; comentários continuam úteis para justificar *por que*
aquela quantidade de horas foi necessária, não *quanto* foi.

### Taxa de conversão horas → custo

Este bundle não define uma taxa de custo/hora padrão (varia por projeto,
região e nível do time) — cada projeto deve documentar a sua própria taxa
(ex.: custo médio carregado por hora do time) no próprio `README.md` ou em um
ADR, para que o cálculo de custo real (`tokens + horas × taxa`) seja
reproduzível por qualquer pessoa que audite depois.
