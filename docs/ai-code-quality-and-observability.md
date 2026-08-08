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
- **Automatizado (ex.: falha de teste em CI, alerta de produção)**: um step de
  workflow do GitHub Actions cria a Issue via `gh issue create` (com título,
  stack trace/logs relevantes e labels, ex.: `bug`, `auto-filed`); a atribuição
  ao Copilot pode ser feita na sequência por uma automação que tenha acesso à
  mesma capacidade exposta pela ferramenta MCP `assign_copilot_to_issue` do
  GitHub MCP Server (é a via recomendada neste ambiente, já configurada) — evite
  tentar atribuir via `assignees` da REST API pura, pois o Copilot não é um
  colaborador comum e a atribuição usa o mecanismo dedicado do recurso "Assign
  to Copilot".
- Rastreado no `plan.md` pela linha "Gestão de bugs" do novo gate, e por tarefa
  no checklist do `tasks.md`.

## 6. Modelos do Copilot Agent prioritários — dá para declarar isso no preset?

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
