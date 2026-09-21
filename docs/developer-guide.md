# Manual do Dev — Começando com GHE + Nimbus Code na Nimbus-Code

> **TL;DR** (S0/S1 — leitura completa reservada para primeira vez em cada
> cenário ou dúvida específica): repo novo → `curl ... bootstrap.sh | bash`
> (seção 1); repo existente sem Nimbus Code/sem Spec Kit → `curl ... bootstrap.sh | bash`
> no próprio repo (ou `specify init --here` + bootstrap, se quiser separar) e
> só depois ler o código/Boards antes de especificar (seção 2, brownfield);
> ponto de partida a partir de um card do ADO/JIRA → prompt de importação pronto
> (seção 3); ponto de partida a partir de uma entrevista de descoberta com o
> cliente (ainda sem card/issue) → `/speckit.interview` (seção 3.5).
> Pré-requisitos (`specify` CLI, `uv`, Copilot) na tabela logo abaixo.

Este é o manual **central** de como todo dev da Nimbus-Code deve usar o
[GitHub Spec Kit](https://github.com/github/spec-kit) no dia a dia, com as
ferramentas da empresa (GHE, Azure DevOps/JIRA, GitHub Copilot). Ele cobre três
cenários, na ordem em que você provavelmente vai precisar deles:

1. [Repositório novo](#1-repositório-novo) — bootstrap padrão em 1 comando.
2. [Repositório existente sem Nimbus Code](#2-repositório-existente-sem-nimbus-code-brownfield) —
   como instalar e rodar o Nimbus Code entendendo o contexto pelo **código
   (brownfield)** e pelos **Boards** (cards já existentes).
3. [Importar um card do Azure DevOps/JIRA para começar uma feature](#3-importar-um-card-do-azure-devops-ou-jira-para-começar-uma-feature) —
   o prompt exato para puxar um work item/issue como ponto de partida.
   - [3.5. Conduzindo uma entrevista de descoberta antes do `/speckit.specify`](#35-conduzindo-uma-entrevista-de-descoberta-antes-do-speckitspecify-speckitinterview) —
     ponto de partida a partir de uma conversa com o cliente, ao vivo ou por transcript, quando ainda não existe card/issue.

Se algo aqui divergir do que você vê na prática, este arquivo é a fonte da
verdade — abra um PR corrigindo, não crie um manual paralelo em outro lugar.

## Pré-requisitos (uma vez por máquina)

| Ferramenta | Para quê | Como obter |
|---|---|---|
| `specify` CLI | Roda `specify init`, gerencia presets/extensões/workflows | `uv tool install specify-cli --from git+https://github.com/github/spec-kit.git` — ver [guia de instalação](https://github.com/github/spec-kit) |
| [`uv`](https://docs.astral.sh/uv/) | Gerenciador Python usado para instalar o `specify-cli` | [Guia de instalação do uv](https://docs.astral.sh/uv/getting-started/installation/) |
| Acesso ao GHE da org `venha-pra-nuvem` | Clonar este repo e os repos de projeto | Onboarding padrão de acesso à organização |
| GitHub Copilot habilitado no editor | Agente que executa os comandos `/speckit.*` | Extensão do Copilot no VS Code (ou outro agente suportado — ver [integrações](https://github.github.io/nimbus-code/reference/integrations.html)) |
| MCP do backlog (Atlassian Rovo **ou** `ado`), se o projeto usa JIRA/Azure DevOps | Necessário só para os fluxos de importação/sincronização de board (seções 2 e 3) | Configuração do host do agente (ex.: `.vscode/mcp.json`) — ver [`docs/mcp-and-bundles.md`](mcp-and-bundles.md) |

Rode `specify check` a qualquer momento para validar se o ambiente está OK.

## 0. Governança corporativa de IA (leitura obrigatória)

Antes de criar ou revisar qualquer feature relacionada a IA, leia:

- [`docs/ai-governance/README.md`](ai-governance/README.md) — índice central da
  constituição corporativa e dos guias por ferramenta
- [`docs/ai-governance/corporate-constitution.md`](ai-governance/corporate-constitution.md)
- [`docs/ai-governance/m365-governance.md`](ai-governance/m365-governance.md)
- [`docs/ai-governance/legacy-tool-guidance.md`](ai-governance/legacy-tool-guidance.md)
- [`docs/ai-governance/nimbus-aliases.md`](ai-governance/nimbus-aliases.md)

**Regra oficial**: Microsoft Copilot é a ferramenta oficial de IA para
produtividade/negócio e GitHub Enterprise Copilot é a ferramenta oficial para
engenharia. Claude Enterprise e ChatGPT só devem ser usados sob a mesma
constituição corporativa, sem política paralela.

## 1. Repositório novo

Já documentado em detalhe no [README raiz](../README.md#como-um-projeto-novo-já-nasce-com-isso).
Resumo:

```bash
curl -fsSL https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/raw/main/bootstrap.sh | bash
```

Isso já deixa o projeto com `specify init` feito e o bundle
`nimbus-code-project-bundle` (preset + extensão + workflow) instalado.

Se a ideia ainda estiver nebulosa, execute primeiro `/speckit-interview` para
produzir `specs/<feature>/interview.md` e só depois siga com `/speckit-specify`.
O skill de entrevista e o validador determinístico são instalados junto com o
preset para manter o mesmo fluxo em qualquer repositório inicializado.

**Alternativa recomendada quando o time precisa depurar, rodar atrás de VPN/proxy
ou evitar qualquer fragilidade de `curl | bash`:**

```bash
curl -fsSL https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/raw/main/bootstrap.sh \
  -o /tmp/nimbus-bootstrap.sh
bash /tmp/nimbus-bootstrap.sh
```

### 1.1. GitHub Project criado automaticamente (e garantido continuamente)

Se você tiver o `gh` CLI instalado e autenticado, o `bootstrap.sh` também cria
**automaticamente um GitHub Project V2** com o nome `{repo-name} — Nimbus Code Roadmap`.

O project já vem com **5 views padrão** (copiadas do IOX-CROWDFUNDINGPAAS) e
**2 campos customizados**:

- **Board por Epic** — visão da camada EPIC (`type:epic`)
- **Board por Feature** — visão da camada FEATURE (`type:feature`)
- **Board por User Story** — visão da camada US (`type:user-story`)
- **Board por Prioridade** — organize por prioridade (personalizável)
- **Tabela — P0 Blocker** — filtro pré-pronto para bloqueadores críticos (P0-blocker)
- **Campo "Horas Humanas"** (número) — custo real do modelo híbrido (ver
  seção 8 de [`ai-code-quality-and-observability.md`](ai-code-quality-and-observability.md)
  e [`cost-profiles-and-rates.md`](../presets/nimbus-code-standards/templates/cost-profiles-and-rates.md))
- **Campo "Oportunidade D365"** (texto) — URL da Oportunidade no Dynamics 365 vinculada

O `bootstrap.sh` também instala `.github/workflows/ensure-github-project.yml`,
que roda semanalmente e **recria o Project automaticamente se ele não existir
mais** — garante que todo repositório com este bundle sempre tenha o Project,
mesmo que o passo automático do bootstrap tenha sido pulado originalmente
(ex.: `gh` CLI indisponível na máquina de quem rodou o bootstrap). Requer os
secrets `NIMBUS_APP_ID` e `NIMBUS_APP_PRIVATE_KEY`, com `VPNDEV_PROJECT_TOKEN` mantido apenas como fallback tempor?rio durante o rollout.

Depois do bootstrap, você pode:

1. Abrir o project (link será exibido no output do script)
2. Customizar filtros, grupos e colunas conforme sua necessidade
3. Ligar o project ao repositório (Settings do repo → Project → habilitar)

**Se o `gh` CLI não estiver disponível** ou você preferir criar manualmente, rode:

```bash
bash ./scripts/setup-github-project.sh --repo-owner venha-pra-nuvem --repo-name seu-repo
```

**Visão de portfólio (PMO, todos os repositórios)**: ver [`README.md` — Bônus:
Portfólio PMO](../README.md#bônus-portfólio-pmo-visão-consolidada-de-todos-os-repositórios)
para agregar backlog/prioridade e custo real de múltiplos repositórios num
único board.

Depois disso, pule direto para a seção 3 para começar sua primeira feature.

## 2. Repositório existente sem Nimbus Code (brownfield)

Este é o cenário mais comum na prática: um repo que já existe há anos, com
código real, talvez com um board no Azure DevOps/JIRA cheio de cards, mas
**sem nenhum artefato do Nimbus Code ainda**. O objetivo aqui é fazer o Nimbus Code
entender o contexto por **duas fontes**: o código já escrito e o histórico do
board — antes de escrever a primeira spec.

> **Ordem recomendada para brownfield sem Spec Kit:** 1) rode o `bootstrap.sh`
> no próprio repositório para inicializar o Nimbus Code; 2) confirme que a
> pasta `.specify/` e o bundle foram instalados; 3) só então derive a
> constituição e leia o backlog/boards.

### 2.1. Inicializar o brownfield com o bootstrap da Nimbus-Code (recomendado)

```bash
cd meu-repo-existente
curl -fsSL https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/raw/main/bootstrap.sh | bash
```

Para **repo brownfield que ainda não tem Spec Kit/Nimbus Code**, este é o ponto
de partida mais simples e correto: o `bootstrap.sh` já executa
`specify init --here --integration copilot --force` e, na sequência, instala o
bundle `nimbus-code-project-bundle` (preset + extensão + workflow). Ou seja: se
o projeto ainda não foi inicializado, **o bootstrap já faz a inicialização e o
bootstrap complementar da Nimbus-Code no mesmo fluxo**.

### 2.2. Separar `specify init` do bootstrap (opcional)

```bash
cd meu-repo-existente
specify init --here --integration copilot --force
curl -fsSL https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/raw/main/bootstrap.sh | bash
```

Use esta variação só se você **quiser separar conscientemente** a criação da
`.specify/` da aplicação do bundle. Nesse caso, o `bootstrap.sh` detecta que o
`specify init` já rodou e só instala preset + extensão + workflow (ver
[`bootstrap.sh`](../bootstrap.sh)). O resultado final é o mesmo da seção 2.1.

### 2.3. Varrer o código existente — gerar a constituição a partir do que já está implementado

Este é o passo que resolve "como o Nimbus Code entende o código". **Não existe um
comando dedicado de "scan"** — a varredura acontece dentro do próprio
`/speckit.constitution`, sendo explícito no prompt para o agente analisar a
fundo antes de escrever qualquer princípio. Use este prompt (adaptado do
walkthrough oficial de brownfield do time do Spec Kit (demo ASP.NET brownfield)
do próprio time do Nimbus Code):

```
/speckit.constitution Este é um projeto brownfield já existente, sem
constituição prévia. Analise o código-fonte de forma exaustiva e em
profundidade — não superficialmente, use quantas iterações forem necessárias
para explorar a estrutura de pastas, stack, padrões de arquitetura, convenções
de nomenclatura e testes já existentes. Derive os princípios de qualidade de
código, padrões de teste, consistência e performance diretamente do que já
está implementado no repositório, não de um ideal genérico. Inclua governança
para essas decisões guiarem as próximas features.
```

O agente escreve `.specify/memory/constitution.md` refletindo a **realidade do
repo**. Como o preset `nimbus-code-standards` usa estratégia `wrap`, os princípios
não-negociáveis da Nimbus-Code (segurança, IaC, qualidade — ver
[`presets/nimbus-code-standards/templates/constitution-template.md`](../presets/nimbus-code-standards/templates/constitution-template.md))
entram **antes** dessa constituição derivada do código — os dois convivem sem
conflito, nenhum sobrescreve o outro.

**Nota importante**: Este é um processo que pode levar múltiplas iterações. Para
entender bem padrões, armadilhas, troubleshooting e a importância da constituição
em brownfield, consulte a referência completa em
[`docs/brownfield-best-practices.md`](brownfield-best-practices.md).

**Passo opcional pós-constituição — Harvest de padrões reutilizáveis**: depois
de rodar `/speckit.constitution`, considere também rodar `scripts/harvest-patterns.sh`
para varrer o código já existente por padrões técnicos estruturais (interfaces,
factories, decorators recorrentes) e propor entradas para `docs/reuse-catalog.yaml`.
Diferente do `/speckit.constitution` (que deriva princípios de qualidade/arquitetura),
o Harvest alimenta especificamente o catálogo de reuso. É **sempre on-demand,
nunca automático nem em CI** — se este projeto ainda não rodou:

```bash
export HARVEST_API_URL="<endpoint LLM configurado pelo seu time>"
export HARVEST_API_TOKEN="<token>"

scripts/harvest-patterns.sh . --dry-run   # revisa antes de escrever
scripts/harvest-patterns.sh .              # escreve em docs/reuse-catalog.yaml
```

Se `scripts/harvest-patterns.sh` ainda não existir neste projeto (bundle
instalado antes desta versão), siga primeiro o prompt de auto-atualização da
seção 6.7 para trazer os artefatos novos do preset.

### 2.4. Entender o contexto pelos Boards (cards já existentes)

O Nimbus Code não tem um comando de "importar todos os cards", mas antes de
especificar a primeira feature nova num repo com histórico de board, vale
pedir ao agente uma leitura prévia dos cards recentes relacionados à área que
você vai mexer — para não contradizer nem reimplementar algo já decidido ou
em andamento:

```
Antes de especificarmos a próxima feature, busque no Azure DevOps (projeto
<nome>) os work items fechados ou em andamento nas últimas 4 semanas
relacionados a <área/módulo>. Resuma o que já foi feito ou decidido, para
usarmos como contexto na spec.
```

(Troque "Azure DevOps" por "JIRA" e "work items" por "issues" conforme a
ferramenta do time — ver seção 3 para o MCP necessário.) Esse resumo entra
como contexto adicional no prompt do `/speckit.specify` seguinte — ele não
substitui a leitura do código feita no passo 2.3, complementa com o "porquê"
por trás de decisões que só existem no board, não no código.

### 2.5. Ciclo normal de features a partir daqui

Com constituição + contexto de board levantados, o resto do ciclo é o padrão
do Nimbus Code (ver [`workflows/nimbus-code-full-cycle/README.md`](../workflows/nimbus-code-full-cycle/README.md)
para a variante com gate de DevSecOps da Nimbus-Code):

```
/speckit.specify   → descreve a feature nova (não retro-especifique o app inteiro)
/speckit.clarify    → (opcional) reduz ambiguidade antes de planejar
/speckit.plan       → plano técnico (já usa o que o agente aprendeu do código real)
/speckit.checklist  → (opcional) "testes unitários" da própria spec
/speckit.tasks      → lista de tarefas ordenada por dependência
/speckit.analyze    → (opcional, somente leitura) checa consistência spec/plan/tasks
/speckit.implement  → executa as tarefas (pode levar múltiplos passes em repo grande)
/speckit.converge   → depois do implement: compara código real vs spec/plan/tasks
                      e anexa o que faltar como novas tarefas — repita
                      implement → converge até sair "✅ Converged"
```

**Camada de aliases Nimbus**: os nomes abaixo são equivalentes operacionais dos
comandos do Spec Kit. O comando original continua válido.

- `constitution` → `nimbus.constitution`
- `specify` → `nimbus.discovery`
- `clarify` → `nimbus.refinement`
- `plan` → `nimbus.plan`
- `tasks` → `nimbus.backlog`
- `implement` → `nimbus.build`
- `analyze` → `nimbus.validate`
- `converge` → `nimbus.release`

`/speckit.converge` é especialmente útil em brownfield porque é comum já
existir implementação parcial/legada na mesma área da feature nova — ele é
**append-only** (nunca edita/apaga código, só pode adicionar tarefas).

### 2.6. DOs e DONTs — padrão brownfield (crítico para sucesso)

### ✅ DOs — boas práticas brownfield

- **DO** começar pelo `bootstrap.sh` quando o repo brownfield ainda não tem
  Spec Kit/Nimbus Code — ele já faz o `specify init --here` e instala o bundle
  padrão da Nimbus-Code no mesmo fluxo.
- **DO** rodar `/speckit.constitution` como o passo **1 da primeira feature**,
  depois da inicialização do ambiente, com o prompt de análise profunda —
  deixar o agente entender o código existente custa iterações iniciais mas
  economiza em toda feature subsequente.
- **DO** manter `constitution.md`, `spec.md` e `plan.md` como **artefatos vivos**
  — eles são sempre reescritos/atualizados conforme a realidade muda, não são
  cópia estática do que foi feito uma vez.
- **DO** usar `/speckit.converge` **sempre** depois do `implement` — é
  append-only, busca gaps, e é essencial em brownfield onde código legado já
  toca a mesma área da feature nova.
- **DO** fazer **múltiplos passes** de `implement` → converge em features
  grandes/complexas — é esperado e normal, não é sinal de erro.
- **DO** documentar **exceções de padrão** no Architecture Decision Log do
  `plan.md` — se você não segue a constituição em algo, deixe registrado e
  rastreável (ex.: framework IaC diferente do padrão Terraform, por compliance
  nativo do Azure Policy).
- **DO** revisar a análise profunda gerada pelo agente (iterações 1-N do
  `/speckit.constitution`) **como insumo, não como verdade absoluta** — o agente
  pode interpretar padrões errado ou superestimar certa convenção. Edite
  `constitution.md` se necessário antes de prosseguir para features.
- **DO** rodar `/speckit.analyze` **antes** de implementar — a carga cognitiva
  de ambiguidades em spec/plan/tasks é exponencial; pague o custo cedo.
- **DO** manter `.specify/` versionado no git — é parte da história do projeto,
  não é lixo de build. `.specify/memory/` (com artefatos) sim, mas pelo menos
  `.specify/features/` (com as estruturas de feature) devem estar no histórico.

### ❌ DONTs — armadilhas comuns em brownfield

- **DON'T** pular o `/speckit.constitution` achando que "vamos especificar
  features normalmente" — sem princípios derivados do código existente, cada
  feature é um caos; o agente toma decisões contraditórias.
- **DON'T** tentar retro-especificar **todo** o código existente num único
  `/speckit.specify` — isso sobrecarrega o agente e gera uma "spec" gigante e
  inútil. Especifique **só a mudança incremental** (o que é novo/alterado, não
  o que já existe).
- **DON'T** editar `spec.md`/`plan.md`/`tasks.md` manualmente depois que foram
  gerados — se precisa ajustar, reegere os artefatos com os comandos correspondentes
  (ex.: `/speckit.specify` de novo com um prompt ajustado, não edite `spec.md`
  diretamente). Exceção: adicionar observações/notas contextuais, OK; mudar
  requisito/design, não.
- **DON'T** ignorar o `/speckit.converge` achando que "implementamos tudo o que
  foi pedido" — converter sempre encontra lacunas que não eram óbvias na spec
  original. É parte do ciclo, não é falha.
- **DON'T** usar `/speckit.implement` uma única vez em repo grande esperando que
  saia perfeito — quebre em stages (Setup, Foundational, depois user story por
  story), valide cada uma, continue. Vários passes pequenos > um pass gigante.
- **DON'T** deixar `constitution.md` desatualizado quando princípios mudam — se
  o stack mudou (ex.: migração de ORM, novo framework de testes), atualize a
  constituição, não só deixe comentários no código.
- **DON'T** criar specs em silos sem ler o que o agente já aprendeu do código
  — sempre reutilize o contexto de constituição e planos anteriores no mesmo
  projeto (o agente já tem esse contexto em `.specify/memory/`).
- **DON'T** confundir "Nimbus Code" com "gerador de código" — o Nimbus Code é um
  **framework de documentação estruturada** que *alimenta* um gerador (o agente).
  Se o agente gera código ruim, a spec estava ambígua; volte e clarifique (via
  `/speckit.clarify` ou `/speckit.specify`), não culpe o Nimbus Code.

### 2.7. Checklist pré-primeiro-ciclo para brownfield

Antes de rodar a primeira feature em um brownfield, valide:

- [ ] `bootstrap.sh` rodou com sucesso no repo brownfield
- [ ] `.specify/` foi criado (via `bootstrap.sh` ou via `specify init --here`, se você optou por separar)
- [ ] Bundle `nimbus-code-project-bundle` instalado (veja `.specify/presets/` e `.specify/extensions/`)
- [ ] `/speckit.constitution` executado com o prompt de **análise profunda** (seção 2.3)
- [ ] `constitution.md` revisado/editado manualmente se necessário
- [ ] `scripts/harvest-patterns.sh` executado ao menos uma vez (opcional, mas recomendado — seção 2.3) para semear `docs/reuse-catalog.yaml` com padrões já existentes no código
- [ ] `.specify/` adicionado ao git e versionado
- [ ] README do projeto atualizado com a seção de Nimbus Code (ver [`templates/README-bundle-section.md`](../templates/README-bundle-section.md))
- [ ] Se usa backlog externo (Azure DevOps/JIRA): MCP correspondente configurado no agente
- [ ] Se vai criar feature incremental: ler contexto de cards recentes no board (seção 2.4)

Se tudo passou, seu brownfield está pronto. Próximo passo: seção 3.

## 3. Importar um card do Azure DevOps ou JIRA para começar uma feature

Isso vale tanto para o repo novo quanto para o brownfield, sempre que você
quiser começar uma feature a partir de um work item/issue que já existe no
backlog em vez de escrever a descrição do zero.

**Pré-condição**: o MCP do backlog precisa estar configurado no seu agente —
`ado` para Azure DevOps ou Atlassian Rovo para JIRA (ver
[`docs/mcp-and-bundles.md`](mcp-and-bundles.md); é sempre configuração do host
do agente, o Nimbus Code não instala nem verifica isso).

### Prompt para Azure DevOps

```
/speckit.specify Busque o work item #1234 no Azure DevOps (organização
<org>, projeto <projeto>) via MCP e construa a especificação desta feature a
partir do título, descrição e critérios de aceitação dele. Se algo estiver
ambíguo, incompleto ou contraditório, liste como observação a esclarecer —
não invente detalhes que não estão no work item.
```

### Prompt para JIRA

```
/speckit.specify Busque a issue <PROJ-123> no JIRA via MCP Atlassian Rovo e
construa a especificação desta feature a partir do resumo, descrição e
critérios de aceitação dela. Se algo estiver ambíguo, incompleto ou
contraditório, liste como observação a esclarecer — não invente detalhes que
não estão na issue.
```

Isso é o caminho **oposto** ao que a extensão `nimbus-code-backlog-sync` deste
bundle faz nativamente: ela sincroniza `spec.md`/`tasks.md` **para** o board
(hooks `after_specify`/`after_tasks`, opcionais); a importação **do** board
para dentro da spec é sempre feita via prompt manual como acima — o Nimbus Code
não tem um comando dedicado de importação nesse sentido.

Depois de gerar a spec a partir do card, continue o ciclo normal
(`/speckit.clarify` → `/speckit.plan` → ... ) como na seção 2.5.

### 3.5. Conduzindo uma entrevista de descoberta antes do `/speckit.specify` (`/speckit.interview`)

Use isso quando **ainda não existe** um card/issue pronto (seção 3) nem uma
descrição já madura da feature — você vai conversar com o cliente/solicitante
primeiro (ao vivo ou a partir de um transcript de reunião) e quer que essa
conversa já saia estruturada, cobrindo negócio, infraestrutura, segurança e
LGPD, antes de gerar a spec.

Isso é **hoje um passo manual** — você (ou o Nimbus, conduzindo a conversa por
você) preenche o modelo de entrevista
(`presets/nimbus-code-standards/templates/feature-artifacts/interview-template.md`)
e salva como `specs/<feature-slug>/interview.md`. Não existe ainda nenhuma
integração automática com Microsoft Teams — o roadmap dessa automação está
registrado em `specs/018-nimbus-agent-intake/spec.md` (User Story 5), mas por
enquanto **quem conduz a entrevista é você**, com o Nimbus como assistente.

**Pré-condição de transcript**: se a reunião já aconteceu e você tem as
anotações/gravação transcrita, hoje isso normalmente está numa pasta pessoal do
OneDrive (ex.: `OneDrive - Nimbus-Code/Notas/reuniao-cliente-x.txt`) ou em
qualquer outro lugar que você tenha acesso local — não existe ainda um
conector automático que busque isso pra você. Baixe/exporte o transcript para
um caminho que o agente consiga ler (local ou dentro do próprio repo, ex.:
`specs/_transcripts/reuniao-cliente-x.txt`) e referencie esse caminho no prompt.

#### Prompt — sem transcript (entrevista ao vivo, do zero)

```
/speckit.interview Cliente do time Financeiro pediu um jeito de consolidar
relatórios mensais que hoje são feitos manualmente em planilha. Conduza a
entrevista de descoberta comigo agora, bloco por bloco (negócio, infra,
segurança, LGPD) — eu vou respondendo.
```

#### Prompt — com transcript em arquivo (ex.: exportado do OneDrive)

```
/speckit.interview Consolidação de relatórios financeiros mensais. Já tenho o
transcript da reunião com o cliente em
specs/_transcripts/reuniao-financeiro-2026-08-26.txt (copiei da minha pasta
pessoal do OneDrive). Avalie o que já está coberto nesse transcript e só me
pergunte o que estiver faltando ou ambíguo.
```

#### Prompt — colando o transcript direto na mensagem

```
/speckit.interview Consolidação de relatórios financeiros mensais.
Segue o transcript da reunião:
---
[Maria - Financeiro]: hoje a gente fecha o relatório mensal manualmente...
[João - TI]: entendi, e quem mais usa esse relatório hoje?
[Maria]: só o time financeiro mesmo, uso interno...
---
Avalie a cobertura contra os 4 blocos e pergunte só o que faltar.
```

**O que acontece depois**: o Nimbus cria `specs/<feature-slug>/interview.md`
(a mesma pasta que a próxima spec vai usar — não duplica), pergunta só o que
não veio no transcript (nunca inventa resposta de segurança/infra/LGPD), e ao
final avisa: *"rode `/speckit.specify` agora"*. O `/speckit.specify` detecta
essa pasta automaticamente e usa a entrevista como base do `spec.md` — você
não precisa referenciar `interview.md` manualmente.

Se a demanda for claramente pequena (documentação, ajuste isolado), o Nimbus
vai propor o modo **Fast-Track** (~9 perguntas essenciais, ~10 min) em vez do
modo Completo (~20-30 min) — ele sempre confirma com você antes de aplicar.

## 4. Hierarquia Agile (Epic → Feature → US → Task) no GHE

O Spec Kit suporta criação automática de uma hierarquia de issues no GHE
seguindo o modelo **Epic → Feature → User Story → Task**, usando o recurso
nativo de sub-issues do GitHub.

### 4.1. Mapeamento: artefatos Spec Kit ↔ issues GHE

| Artefato Spec Kit | Issue GHE | Tipo (`type:`) | Relação |
|---|---|---|---|
| — (criada manualmente no GHE) | **Epic** | Epic | Pai de Features |
| `specs/NNN-slug/` (pasta da feature) | **Feature** | Feature | Sub-issue do Epic |
| Seção `### User Story N` no `spec.md` | **User Story** | User Story | Sub-issue da Feature |
| Linha `T00N` no `tasks.md` | **Task** | Task | Sub-issue da User Story |

> **Regra 1:1** — cada pasta `specs/NNN-slug/` corresponde a exatamente uma
> Feature issue. Features que cobrem múltiplos Epics devem ser divididas em
> specs separadas antes de iniciar o `/speckit-specify`.

### 4.2. Pré-requisitos

1. **Issue Types configurados na org**: execute `setup-github-project.sh` para
   criar os 5 tipos (Epic, Feature, User Story, Task, Bug). Em orgs sem suporte
   a Issue Types nativos (GHE Server < 3.10), o fluxo usa labels como fallback
   (ver seção 4.6).

2. **Epic criado no GHE**: antes de iniciar o `/speckit-specify`, crie a issue
   Epic manualmente em `https://venha-pra-nuvem.ghe.com/<org>/<repo>/issues/new` com type "Epic"
   (ou label `type:epic` em modo degradado). Anote o número da issue (`#N`).

### 4.3. Passo a passo: criando a hierarquia

#### Passo 1 — Criar o Epic no GHE

```bash
# Via gh CLI:
gh issue create \
  --repo <org>/<repo> \
  --title "Nome da iniciativa" \
  --body "Descrição do Epic" \
  --label "type:epic"   # fallback; ou use o seletor de Issue Type na UI

# Anote o número retornado, ex.: #42
```

Ou crie diretamente na UI do GHE selecionando `type: Epic` no campo de tipo.

#### Passo 2 — Rodar `/speckit-specify` com referência ao Epic

```
/speckit-specify Descrição da feature. EPIC_ISSUE=42
```

O Spec Kit registra `"epic_issue": 42` em `.specify/feature.json`. Esse campo
é opcional — sem ele, o fluxo funciona normalmente mas sem vinculação ao Epic.

> Se você esqueceu de passar `EPIC_ISSUE`, edite `.specify/feature.json`
> manualmente e adicione o campo:
> ```json
> { "epic_issue": 42 }
> ```

#### Passo 3 — Refinar com `/speckit-plan` e `/speckit-tasks`

Execute o fluxo normal:

```
/speckit-plan
/speckit-tasks
```

#### Passo 4 — Criar a hierarquia no GHE com `/speckit-taskstoissues`

```
/speckit-taskstoissues
```

O comando:
1. Cria a **Feature issue** (`type:Feature`) e a vincula como sub-issue do Epic `#42`
2. Para cada seção `[USN]` do `tasks.md`: cria a **User Story issue** (`type:User Story`) como sub-issue da Feature
3. Para cada linha `T00N` de cada seção: cria a **Task issue** (`type:Task`) como sub-issue da User Story

> Internamente, a parte estrutural (criação de Feature/User Story, vínculos de
> sub-issue e aplicação de Issue Type) é feita por
> `.specify/scripts/bash/create-github-issue-hierarchy.sh` — um helper bash +
> `gh` CLI no mesmo padrão de `scripts/setup-github-project.sh`, que pode
> também ser chamado isoladamente (com `--dry-run`) para depurar o fluxo.

> **Deduplicação**: se o comando for executado novamente, ele identifica issues
> já existentes pelo ID `T00N` (não pelo título) e não cria duplicatas.
> Vínculos ausentes são criados sem duplicar a issue.

#### Quando usar (e quando pular) o `/speckit-taskstoissues`

- **Use quando** o trabalho vai ser **orquestrado entre várias pessoas e/ou
  agentes** — handoff de tarefas, execução paralela por devs/agentes
  diferentes, acompanhamento de portfólio/PMO, correlação com métricas DORA,
  ou quando você quer aproveitar o auto-assign autônomo do Copilot coding
  agent (que depende do label `agent:autonomous-ok` estar presente na issue —
  ver seção 5). É esse comando que efetivamente **aplica** os labels de
  governança (`priority:*`, `complexity:*`, `agent:*`, `type:*`) nas issues —
  ver "De onde vêm os labels nas issues" logo abaixo.
- **Pode pular quando** a execução é **solo e imediata**: uma única pessoa vai
  rodar `/speckit.implement` direto em cima do `tasks.md` na mesma sessão, sem
  necessidade de rastrear cada task como issue separada no GHE. Nesse caso o
  próprio `tasks.md` já é o tracker de execução — criar a hierarquia de issues
  é um custo extra sem benefício.
- **Não é um loop autônomo**: é um comando/skill invocado manualmente
  (`/speckit-taskstoissues`), idempotente por design (dedup por `T00N`), sem
  gatilho de schedule/webhook. Ele só executa quando alguém (humano ou agente)
  o chama explicitamente — nunca dispara sozinho em background.

##### De onde vêm os labels nas issues (evitando o engano "os labels não estão sendo criados")

Vale distinguir **criar a taxonomia de labels no repositório** de **aplicar um
label numa issue** — são coisas diferentes e só um desses mecanismos aplica
labels automaticamente:

| Mecanismo | O que faz | Aplica label em issue? |
|---|---|---|
| `scripts/setup-github-labels.sh` | Cria/atualiza as *definições* de label (nome/cor/descrição) no repositório via `gh label create --force` | ❌ Não — só garante que o label existe como opção, nunca toca em issues |
| `.github/workflows/agent-auto-assign.yml` | Dispara em `issues: labeled` — **reage** a um label (`agent:autonomous-ok`) que já foi aplicado, para atribuir o Copilot coding agent | ❌ Não — consome o label, não o cria |
| `.github/workflows/sync-priority-field.yml` | Lê o label `priority:*` já existente na issue e espelha no campo nativo do Project | ❌ Não — só leitura/espelhamento |
| `/speckit-taskstoissues` (via `.specify/scripts/bash/create-github-issue-hierarchy.sh`) | Cria as issues de Feature/User Story/Task **e aplica** `priority:*`, `complexity:*`, `agent:autonomous-ok`/`agent:needs-human`, `type:*` no momento da criação (e reaplica os que faltarem em reexecuções) | ✅ Sim, mas só nas issues que ele mesmo cria/rastreia (`T00N`) |
| `scripts/apply-governance-labels.sh` | Varre issues **já existentes** (criadas por qualquer via, inclusive manual) e aplica defaults nos labels de governança ausentes, sem prompt por issue | ✅ **É o mecanismo para corrigir issues manuais que ficaram sem labels** |

Se a equipe cria issues manualmente (pela UI do GHE, `gh issue create` avulso,
ou qualquer fluxo que não passe por `/speckit-taskstoissues`), é esperado que
elas fiquem sem `priority:*`/`complexity:*`/`agent:*` — nenhum outro workflow
deste bundle aplica esses labels de forma automática. Para uma issue de
Task/User Story/Feature já rastreada por `T00N`, rode `/speckit-taskstoissues`
(ele detecta a issue existente e aplica os labels de governança ausentes sem
duplicar nada). Para qualquer outra issue manual (bug reportado direto no
GHE, chore, incidente, etc.) que não passa por esse fluxo, use o script
`scripts/apply-governance-labels.sh`:

```bash
# Ver o que seria alterado, sem aplicar nada ainda
./scripts/apply-governance-labels.sh \
  --repo-owner venha-pra-nuvem --repo-name <repo> --dry-run

# Aplicar de fato — varre todas as issues abertas, preenche só os labels
# ausentes com defaults sensatos (priority:P2-medium, complexity:S2,
# agent:autonomous-ok/needs-human, type:task) e nunca sobrescreve um label
# já presente
./scripts/apply-governance-labels.sh \
  --repo-owner venha-pra-nuvem --repo-name <repo>
```

Ele é o "modo bulk": varre todas as issues abertas de uma vez e aplica
defaults automáticos sem perguntar valor por issue — depois de rodar, revise
as issues que ganharam `type:task` "no chute" (o default mais neutro) e
corrija manualmente se a issue for na verdade um Epic/Feature/Bug/Chore/Docs/
Incident. Rode `--help` para ver todas as opções (`--only`, `--include-closed`,
`--default-*`, `--json`).

#### Passo 5 — Verificar no board

Abra o GitHub Project V2. Na view **"Board de Epics"**, cada Epic mostra o
campo **"Sub-issue progress"** com o percentual de conclusão das Features (e
transitivamente das User Stories e Tasks).

### 4.4. Configurar as views do GitHub Project

Execute `setup-github-project.sh` para criar automaticamente as views:

| View | Layout | Filtro | Group by (manual na UI) |
|---|---|---|---|
| Board de Epics | Board | `type:"Epic"` | Status |
| Board de Features | Board | `type:"Feature"` | Parent issue (Epic) |
| Board de User Stories | Board | `type:"User Story"` | Parent issue (Feature) |
| Sprint Ativo | Board | — | Iteration atual |
| Backlog Completo | Tabela | — | — |
| Tabela — P0 Blocker | Tabela | `label:"priority:P0-blocker"` | — |

> **NOTA**: `Group by` não é configurável via API GraphQL — configure manualmente
> na UI de cada view após a criação pelo script.

### 4.5. Edge cases

**Epic ainda não existe ao rodar `/speckit-specify`**

Crie o Epic manualmente antes (Passo 1 acima). Alternativa: rode `/speckit-specify`
sem `EPIC_ISSUE`, finalize o Epic manualmente e depois edite `.specify/feature.json`
para adicionar `"epic_issue": <N>` antes de rodar `/speckit-taskstoissues`.

**Feature com múltiplos Epics**

Não suportado — cada Feature pertence a exatamente um Epic. Se a feature cobre
mais de um Epic, divida-a em specs separadas (`NNN-slug-a/` e `NNN-slug-b/`),
cada uma com seu próprio `EPIC_ISSUE`.

**Re-execução do `/speckit-taskstoissues`**

Seguro — o comando usa o ID `T00N` como chave de deduplicação. Issues existentes
são identificadas e não recriadas; vínculos ausentes são adicionados.

**Limite de 100 sub-issues por parent**

O comando alerta ao se aproximar do limite (≥ 90) e aborta com mensagem clara
ao atingi-lo (≥ 100). Nesse caso, divida a Feature ou a User Story em partes
menores antes de prosseguir.

### 4.6. Modo degradado (org sem Issue Types nativos)

Em orgs com GHE Server < 3.10 que não suportam Issue Types nativos:

1. O `setup-github-project.sh` detecta automaticamente a ausência de suporte
   e imprime `[MODO DEGRADADO] Issue Types não disponíveis`.
2. Execute `setup-github-labels.sh` para criar os labels de fallback:
   - `type:epic` (roxo)
   - `type:feature` (azul)
   - `type:user-story` (verde)
   - `type:task` (cinza)
3. O `/speckit-taskstoissues` aplica esses labels nas issues em vez de Issue Types.
   Em qualquer modo, cada Task issue também deve sair com o conjunto mínimo
   `priority:*`, `complexity:S0`–`S4`, `type:task` e
   `agent:autonomous-ok`/`agent:needs-human` coerente com a task.
4. As views do Project V2 criadas por `setup-github-project.sh` terão filtros
   por label em vez de `type:`.

A hierarquia de sub-issues funciona da mesma forma — apenas a classificação
visual por tipo fica menos rica.



| Comando | Quando usar | Obrigatório? |
|---|---|---|
| `/speckit.constitution` | Uma vez por projeto (ou ao mudar princípios); em brownfield, com o prompt de análise profunda da seção 2.3 | Sim, uma vez |
| `/speckit.specify` | Toda feature nova — descreve o quê/porquê, não a stack | Sim |
| `/speckit.clarify` | Quando a spec tem áreas ambíguas | Recomendado |
| `/speckit.plan` | Depois da spec aprovada — stack e arquitetura | Sim |
| `/speckit.checklist` | Validar completude da própria spec antes de detalhar tarefas | Opcional |
| `/speckit.tasks` | Gera `tasks.md` a partir do plano | Sim |
| `/speckit-taskstoissues` | Espelha o `tasks.md` como hierarquia Epic→Feature→US→Task no GHE — só necessário quando o trabalho será orquestrado entre várias pessoas/agentes (handoff, execução paralela, PMO, auto-assign do Copilot). Dispensável em execução solo (ver seção 4.3) | Opcional |
| `/speckit.analyze` | Checagem cruzada spec/plan/tasks antes de implementar | Recomendado |
| `/speckit.implement` | Executa as tarefas | Sim |
| `/speckit.converge` | Depois do implement — garante que nada ficou faltando vs. spec/plan/tasks | Recomendado, essencial em brownfield |

---

### 4.7. Manual operacional — quando a feature já existe, mas surgem erros funcionais ou de arquitetura

Este é o cenário clássico de **correção de rota**, não de criação de feature do zero.
O ponto central do processo Nimbus Code é separar **erro de implementação** de
**mudança na fonte de verdade**.

#### Regra-mãe

- Se o problema está no **código** e a intenção original continua válida, a fonte
  de verdade **não muda**: use `implement` e `converge`.
- Se o problema está na **intenção, escopo, regra de negócio ou critério de aceite**,
  a fonte de verdade **mudou**: atualize a **mesma spec** (com `clarify` quando
  precisar estruturar a ambiguidade) e depois reflita isso em `plan.md` e `tasks.md`.
- **Nova spec** só existe quando o trabalho virou **outra feature**: novo recorte
  de valor, novo rollout, novo owner, novo Epic/Feature, ou mudança grande o
  bastante para perder identidade com a spec atual.

#### Matriz de decisão

| Sintoma encontrado | A fonte de verdade mudou? | Ação principal | A spec atualiza? | Cria nova spec? | O converge entra? |
|---|---|---|---|---|---|
| Bug funcional no código, mas `spec.md`/`plan.md` continuam corretos | Não | Corrigir implementação e/ou rodar `converge` para anexar tarefas faltantes | Não | Não | Sim |
| Critério de aceite estava ambíguo ou incompleto | Sim | Atualizar a **mesma** `spec.md`; usar `clarify` se precisar resolver ambiguidades | Sim | Não | Só depois de novo `implement` |
| Arquitetura planejada ficou inválida, mas o objetivo de negócio continua o mesmo | Parcialmente | Atualizar a **mesma** `plan.md` e regenerar/refinar `tasks.md` | Só se o impacto alterar comportamento esperado | Não | Só depois de novo `implement` |
| Descobriu-se um escopo adicional independente do problema original | Sim, mas em outro recorte | Abrir **nova spec** | Não na spec antiga, salvo referência cruzada | Sim | Não como primeira ação |
| A entrega foi feita, mas sobrou gap entre artefato e código | Não | Rodar `converge` | Não | Não | Sim, é o comando certo |

#### Fluxo 1 — erro de implementação, sem mudar a intenção

```mermaid
flowchart TD
    A[Spec, Plan e Tasks continuam válidos] --> B[Implementação apresentou erro]
    B --> C{O erro altera objetivo, regra ou aceite?}
    C -- Não --> D[Corrigir código]
    D --> E[/speckit.converge]
    E --> F{Converge encontrou gaps?}
    F -- Sim --> G[Append de novas tasks na mesma feature]
    G --> H[/speckit.implement]
    H --> I[Rodar converge de novo]
    F -- Não --> J[Feature pronta para PR/revisão]
```

#### Fluxo 2 — erro de especificação, regra ou escopo

```mermaid
flowchart TD
    A[Problema descoberto] --> B{A ambiguidade está na intenção da feature?}
    B -- Sim --> C[/speckit.clarify ou edição da mesma spec]
    C --> D[Atualizar a mesma spec.md]
    D --> E[Revisar plan.md]
    E --> F[Regenerar ou atualizar tasks.md]
    F --> G[/speckit.implement]
    G --> H[/speckit.converge]
    H --> I[PR/revisão]
```

#### Fluxo 3 — erro de arquitetura, mas mesma feature

```mermaid
flowchart TD
    A[Objetivo de negócio continua o mesmo] --> B[Arquitetura atual não atende]
    B --> C[Atualizar o mesmo plan.md]
    C --> D{Mudou comportamento esperado do usuário?}
    D -- Sim --> E[Atualizar também a mesma spec.md]
    D -- Não --> F[Manter spec e seguir]
    E --> G[Atualizar tasks.md]
    F --> G
    G --> H[/speckit.implement]
    H --> I[/speckit.converge]
```

#### Ordem operacional recomendada

1. **Diagnostique onde está o erro**
   - Código? → siga pelo fluxo de `implement` + `converge`
   - Intenção/aceite? → atualize a **mesma spec**
   - Arquitetura/plano? → atualize o **mesmo plan**
2. **Não use `converge` para reescrever intenção**
   - `converge` é **append-only em `tasks.md`**
   - ele **não altera** `spec.md`
   - ele **não altera** `plan.md`
3. **Não abra nova spec por reflexo**
   - nova spec é exceção de particionamento, não mecanismo padrão de correção
4. **Se a spec mudou, trate `plan.md` e `tasks.md` como derivadas**
   - spec primeiro
   - plan depois
   - tasks depois
   - implement/converge no final

#### Critério oficial para abrir nova spec

Abra uma nova spec **somente** quando pelo menos um dos pontos abaixo for verdadeiro:

- o trabalho virou uma **nova entrega de valor** independente;
- a mudança pede **rollout próprio**, owner próprio ou janela própria;
- o problema identificado gera uma **segunda feature** e não apenas correção da atual;
- a relação com a spec original vira apenas referência histórica.

Caso contrário, o padrão é: **atualizar a mesma spec e continuar o ciclo nela**.

**Exemplos de borda que continuam na mesma feature:**

- o critério de aceite estava incompleto e precisa ser corrigido na mesma `spec.md`;
- a arquitetura falhou, mas o objetivo de negócio e o rollout continuam os mesmos;
- o bug apareceu depois do merge, mas continua sendo correção da entrega original.

**Exemplos de borda que viram nova spec:**

- surgiu uma nova entrega de valor com owner, rollout ou janela própria;
- o trabalho deixa de ser correção e passa a ser um novo desdobramento funcional;
- a spec original passa a servir só como antecedente histórico.

### 4.8. FAQ — correção de rota de spec/plan/tasks

**A implementação ficou errada. Eu rodo `clarify` de novo?**  
Só se o erro revelar que a **spec estava ambígua ou incompleta**. Se o problema é
apenas o código ter ficado incorreto frente à spec atual, `clarify` não é o
próximo passo; corrija a implementação e rode `converge`.

**`converge` atualiza a `spec.md`?**  
Não. `converge` é append-only em `tasks.md`. Ele só anexa novas tarefas de
fechamento de gap entre a implementação e os artefatos já existentes.

**`converge` atualiza o `plan.md`?**  
Não. Se o plano arquitetural ficou errado, atualize o **mesmo `plan.md`** antes
de voltar para `tasks`/`implement`.

**Quando eu atualizo a mesma spec?**  
Quando a mudança continua sendo a mesma feature, mas a intenção, os critérios de
aceite, edge cases ou hipóteses de negócio precisam ser corrigidos.

**Quando eu crio uma nova spec?**  
Quando o que surgiu deixou de ser correção da feature atual e passou a ser uma
nova entrega de valor, um desdobramento independente ou um novo recorte de rollout.

**Se eu atualizar a spec, preciso mexer em `tasks.md` também?**  
Sim. No processo Nimbus Code, `tasks.md` deriva de `spec.md` + `plan.md`. Se a
fonte de verdade mudou, as tasks precisam ser regeneradas ou refinadas.

**Posso pular `converge` depois de corrigir a rota?**  
Não é recomendado. `converge` é a verificação final de que não ficou nenhum gap
entre artefato e implementação após a correção.

**O que eu faço se existe dúvida entre “corrigir a spec” e “abrir uma nova spec”?**  
Use esta pergunta de corte: *se eu remover o histórico antigo, o novo trabalho ainda
faz sentido como continuação da mesma feature?*  
Se sim, atualize a mesma spec. Se não, abra uma nova.

**E se o erro foi descoberto antes mesmo de existir `plan.md`?**  
Atualize primeiro a mesma `spec.md`, normalize a intenção da feature e só então
gere ou regenere o `plan.md`.

**E se o erro foi descoberto depois do merge em produção?**  
O fluxo de correção de rota continua válido para artefatos (`spec.md`, `plan.md`,
`tasks.md`), mas a decisão de hotfix, rollback ou janela de release segue o
processo operacional de release do projeto.

### 4.9. Recuperação de "issues perdidas" (implementadas, mas ainda abertas)

Quando PRs são mergeadas sem `Closes #<n>` / `Fixes #<n>`, as issues podem ficar
abertas mesmo com implementação concluída.

#### Causa raiz recorrente

- O corpo da PR lista issue apenas como texto/tabela (ex.: `#288`, `#289`), sem
  keyword de fechamento.
- Resultado: o GitHub não registra vínculo de auto-close.

#### Correção permanente aplicada

- Workflow de fallback: [close-referenced-issues-fallback.yml](/Users/lrodrigues/projects/nimbus-code-spec-kit-template/.github/workflows/close-referenced-issues-fallback.yml)
  fecha issues abertas referenciadas na PR mergeada (incluindo seção
  "Issues Resolvidas"), quando o auto-close padrão não ocorreu.
- Instrução obrigatória no Copilot: sempre usar `Closes #<n>` no corpo da PR.

#### Prompt padrão (time) — triagem e correção de issues perdidas

```text
Faça triagem de issues abertas e identifique "issues perdidas" (implementadas, mas ainda abertas).

Objetivo:
1) Listar issues `type:task` abertas cujo T-ID esteja marcado como [x] no `tasks.md` da mesma feature.
2) Para cada issue perdida, validar evidência em PR mergeada (arquivos alterados + descrição da PR).
3) Fechar somente casos de alta confiança com comentário padrão:
   "Fechada por triagem: implementação já mergeada em PR #<n>, porém sem auto-close keyword."
4) Para os casos não conclusivos, comentar com pendência e manter aberta.
5) No final, gerar relatório: fechadas, pendentes, risco/ambiguidade e ações recomendadas.

Regras obrigatórias:
- Em toda PR futura, incluir `Closes #<n>` ou `Fixes #<n>` para cada issue resolvida.
- Não usar apenas menções soltas `#<n>` em tabela/texto.
```

---

## 5. MultiRepo — Registrando Microsserviços

Esta seção descreve a estratégia **1 Repo Central de Specs + N Repos por
stack/microsserviço** suportada pelo Nimbus Code. O Repo Central hospeda
`specs/`, `docs/` e o GitHub Project V2 (board cross-repo). Cada microsserviço
tem seu próprio repo onde o Copilot Agent abre PRs e onde as Tasks são criadas.

### 5.1. Convenção de nomes de repos

| Tipo | Prefixo | Exemplo |
|---|---|---|
| Microsserviço backend | `svc-` | `org/svc-auth`, `org/svc-orders` |
| Frontend web | `frontend-` | `org/frontend-web`, `org/frontend-admin` |
| Mobile | `mobile-` | `org/mobile-ios`, `org/mobile-android` |
| Biblioteca compartilhada | `lib-` | `org/lib-commons`, `org/lib-ui` |
| Infraestrutura (IaC) | `infra` ou `infra-` | `org/infra`, `org/infra-aws` |
| Repo Central (governança) | nome do produto | `org/nimbus-code-spec-kit-template` |

### 5.2. Registrando um novo microsserviço

**Passo 1 — Adicionar entrada em `docs/bounded-contexts.yaml`:**

```yaml
contexts:
  - slug: "order-management"
    description: "Ciclo de vida de pedidos: criação, atualização, cancelamento e histórico."
    repository: "minha-org/svc-orders"
    stack: "Node.js"
    team: "core-squad"
    autonomous_ok: true   # true = Copilot Agent pode trabalhar sem supervisão
                          # false = label agent:needs-human aplicado automaticamente nas Tasks
```

Convenção de slugs: `kebab-case`, substantivo no singular.
Não invente slugs sem adicionar aqui primeiro — o agente valida esta lista ao
criar uma nova spec.

**Passo 2 — Abrir PR com a nova entrada** (revisão obrigatória antes de merge).

**Passo 3 — Vincular o repo ao Project V2:**

```bash
./scripts/setup-github-project.sh --repo-owner minha-org --repo-name repo-central
```

O script lê `docs/bounded-contexts.yaml` e chama `linkProjectV2ToRepository`
para cada repo listado. Requer escopo `write:org` no token. Se o vínculo já
existir, o script é idempotente (imprime `↻ Já vinculado`).

**Passo 4 — Configurar labels no novo repo:**

```bash
./scripts/setup-github-labels.sh --repo-owner minha-org --repo-name svc-orders
```

### 5.3. Criando uma feature que cruza múltiplos repos

```bash
# /speckit-specify com bounded contexts
.specify/scripts/bash/create-new-feature.sh \
    "Checkout flow — integração pedidos e pagamentos" \
    --bounded-contexts "order-management,billing"
```

O que acontece:
1. Os slugs são validados contra `docs/bounded-contexts.yaml`
2. Se qualquer slug for inválido, o script aborta e lista os slugs válidos
3. Os repos resolvidos são persistidos em `.specify/feature.json`:

```json
{
  "feature_directory": "specs/007-checkout-flow",
  "bounded_contexts": ["order-management", "billing"],
  "repos": ["minha-org/svc-orders", "minha-org/svc-payments"]
}
```

### 5.4. Como o `/speckit-taskstoissues` roteia Tasks para repos

O roteamento usa a **anotação inline** no header de cada seção `[USN]` do
`tasks.md`. Adicione o slug do contexto após um traço:

```markdown
## Phase 2: User Story 1 — Criar pedido [US1 — order-management]

- [ ] T001 [US1] Implementar endpoint POST /orders
- [ ] T002 [US1] Validar estoque antes de confirmar pedido

## Phase 3: User Story 2 — Processar pagamento [US2 — billing]

- [ ] T003 [US2] Integrar com gateway de pagamento
- [ ] T004 [US2] Emitir evento payment.processed
```

**Resultado:** Tasks de `[US1 — order-management]` são criadas em
`minha-org/svc-orders`; Tasks de `[US2 — billing]` em `minha-org/svc-payments`.
Issues sem anotação de slug são criadas no Repo Central (comportamento atual,
retrocompatível).

**Deduplicação:** o comando usa o ID `T00N` como chave — safe para re-execução.

**`autonomous_ok: false`:** se o bounded context tiver `autonomous_ok: false`
em `bounded-contexts.yaml`, o label `agent:needs-human` é aplicado
automaticamente nas Tasks criadas naquele repo. Tasks humanas de segurança,
GitHub App ou permissão organizacional também devem receber `agent:needs-human`
mesmo fora desse caso.

### 5.5. Verificando o board cross-repo

Após rodar `setup-github-project.sh`:

1. Acesse o GitHub Project V2 do Repo Central
2. `Settings → Linked Repositories` → todos os repos listados em
   `bounded-contexts.yaml` devem aparecer
3. As views criadas pelo script (Board de Epics, Board de Features, etc.)
   exibem issues de **todos** os repos vinculados no mesmo board

> **NOTA**: `Group by` e `Iteration` não são configuráveis via API GraphQL —
> configure manualmente na UI de cada view após a criação.

### 5.6. Processo operacional para repos satélite

Quando um bounded context aponta para um **repo satélite** (repo de código,
microsserviço, frontend, mobile, lib ou infra), siga sempre este fluxo:

1. Rode o `bootstrap.sh` **dentro do repo satélite** para instalar labels,
   workflows e o bundle padronizado do Nimbus Code.
2. Mantenha o workflow
   [update-speckit-and-bundle.yml](../.github/workflows/update-speckit-and-bundle.yml)
   ativo no satélite. Ele é a verificação contínua para manter o satélite
   alinhado com o Repo Central.
3. Quando o Repo Central publicar mudança de preset/extensão/workflow/bundle,
   deixe a issue semanal do `update-speckit-and-bundle.yml` abrir o diagnóstico
   automaticamente **ou** dispare o workflow manualmente no satélite.
4. Aplique a atualização do bundle no satélite via PR normal, com diff revisado;
   se algum artefato local copiado pelo bootstrap tiver sido removido, rerode o
   mesmo `bootstrap.sh`/sync antes do PR para reidratar os arquivos faltantes.
   A atualização **nunca** deve ser aplicada diretamente na branch principal do
   satélite.
5. No intake greenfield do `bootstrap.sh`, registre explicitamente:
   - `delivery_model`: `monorepo` ou `multirepo`
   - `decision_reason`: motivo principal + trade-off esperado
   - `decision_owner`: quem aprovou a decisão estrutural
6. Se o `delivery_model` for `multirepo`, use FRONT/BACK/DESIGN/DATA/JOBS como
   baseline recomendada e adapte apenas com justificativa e ownership explícitos.
   Esse ajuste ocorre **após a primeira spec estrutural** no Repo Central.

**Resumo operacional:** o Repo Central dita o padrão; o repo satélite consome o
mesmo bundle, reidrata artefatos locais pelo mesmo bootstrap/sync quando
necessário e atualiza por PR a partir do diagnóstico do workflow semanal.

### 5.7. Política: `specs/` só existe no Repo Central

Em topologia multi-repo, **todo artefato de spec fica exclusivamente no Repo
Central do produto**:

- `spec.md`, `plan.md`, `tasks.md`, `research.md`, `graph.yaml`, `graph.md` e
  checklists ficam no Repo Central.
- Repos satélite recebem **código, testes, IaC, PRs e issues roteadas** a partir
  do Repo Central.
- Se uma mudança nascer num repo satélite, o fluxo correto é **abrir ou atualizar
  a spec no Repo Central primeiro** e só depois roteá-la para o satélite.

Isso evita drift de processo, duplicação de artefatos e conflito entre múltiplas
fontes de verdade.

**Regra prática para o time:** se uma demanda nascer no satélite, a decisão de
escopo e artefatos de spec continua no Repo Central; o satélite recebe apenas o
roteamento de implementação.

### 5.8. Edge cases

**Org sem suporte ao `linkProjectV2ToRepository` (GHE Server < 3.8)**

O script detecta o erro e imprime instrução de vínculo manual:
`Project → Settings → Linked Repositories → Add repository`.

**Token sem escopo `write:org`**

O script imprime erro claro identificando o repo problemático e continua
vinculando os demais. Apenas o repo com falha precisa ser adicionado manualmente.

**`bounded-contexts.yaml` ausente ao rodar `setup-github-project.sh`**

O passo de vínculo de repos é pulado com aviso. O restante do setup funciona
normalmente.

**Feature single-repo (sem `--bounded-contexts`)**

Comportamento idêntico ao atual — `bounded_contexts` e `repos` são `[]` em
`feature.json`. O `/speckit-taskstoissues` cria todas as issues no Repo Central.
Zero breaking change.

**Feature com múltiplos Epics**

Não suportado — cada feature pertence a exatamente um Epic. Se a feature cobre
mais de um Epic, divida-a em specs separadas, cada uma com seu próprio
`EPIC_ISSUE`.

**`setup-github-project.sh` chamado por caminho absoluto de outro clone**

Corrigido (issue #21): o script resolve `docs/bounded-contexts.yaml` a partir
da raiz git do **diretório de chamada** (`$PWD`, via `git rev-parse
--show-toplevel` sem `-C`), não do diretório onde o script físico está. Isso
evita vincular o Project V2 de um projeto consumidor ao repo errado quando o
script é invocado por caminho absoluto de outro clone (ex.: `/tmp/nimbus-code-
spec-kit-template/scripts/setup-github-project.sh` chamado de dentro de
`~/meu-projeto`). O fallback para o `docs/bounded-contexts.yaml` relativo ao
próprio script só é usado quando o diretório de chamada não está dentro de um
repo git com esse arquivo.

### 5.7. Testes e Validação

- **Testes unitários (bats)**: `.specify/scripts/bash/tests/create-new-feature.bats`
  cobre a resolução de `--bounded-contexts` (slug válido, flag omitida, slug
  inválido, arquivo ausente) contra um projeto fixture isolado — não requer
  API do GHE. Rode com [bats-core](https://bats-core.readthedocs.io/):
  ```bash
  bats .specify/scripts/bash/tests/create-new-feature.bats
  ```
- **Checklist de validação E2E**: [`specs/006-multirepo-support/quickstart.md`](../specs/006-multirepo-support/quickstart.md)
  mapeia cada um dos 15 ACs desta feature a um passo de validação (automatizado
  onde possível; manual onde depende de uma API GHE real ou do comportamento
  do agente).

## 6. Release semi-automático (Preset/Bundle/Workflow)

### 6.1. Objetivo

Padronizar quando criar nova versão e impedir publicação fora do fluxo
`develop` -> `main`.

### 6.2. Labels de impacto de release

Classifique cada PR que toca superfície de bundle/preset com um label:

- `release:major` — breaking change
- `release:minor` — nova capacidade compatível
- `release:patch` — correção compatível
- `release:skip` — sem impacto de versão

> O script [setup-github-labels.sh](/Users/lrodrigues/projects/nimbus-code-spec-kit-template/scripts/setup-github-labels.sh)
> cria/atualiza esses labels.

### 6.2.1. Gate automático para não depender de memória humana

O workflow
[release-readiness-gate.yml](/Users/lrodrigues/projects/nimbus-code-spec-kit-template/.github/workflows/release-readiness-gate.yml)
roda em toda PR para `develop` e bloqueia merge quando:

- a PR toca superfície de release (`presets/`, `extensions/`, `workflows/`,
  `bundles/`, docs de release e scripts de versionamento) sem label `release:*`;
- há mais de um label `release:*`;
- a PR foi classificada como `release:major|minor|patch` mas não atualizou
  arquivo de versão e `catalog.json`.

### 6.3. Recomendação automática de bump em `develop`

Ao merge de PR em `develop`, o workflow
[release-impact-advisor.yml](/Users/lrodrigues/projects/nimbus-code-spec-kit-template/.github/workflows/release-impact-advisor.yml)
registra recomendação na issue `Release Candidate: develop` (`release:pending`).

### 6.4. PR automático de promoção `develop` -> `main`

O workflow
[promote-develop-to-main.yml](/Users/lrodrigues/projects/nimbus-code-spec-kit-template/.github/workflows/promote-develop-to-main.yml)
abre/atualiza o PR de promoção e solicita revisão para aprovadores configurados
nas variáveis do repositório:

- `NIMBUS_MAIN_PR_REVIEWERS` (lista CSV de usuários)
- `NIMBUS_MAIN_PR_REVIEW_TEAMS` (lista CSV de times)

### 6.5. Gate humano obrigatório antes da tag

Mesmo com automação, o merge para `main` exige:

- aprovação dos revisores/owner designados;
- aprovação do Comitê Nimbus registrada no PR.

### 6.6. Publicação da versão

Após merge em `main`, o workflow
[tag-release-on-main.yml](/Users/lrodrigues/projects/nimbus-code-spec-kit-template/.github/workflows/tag-release-on-main.yml)
cria/pusha a tag `vX.Y.Z` automaticamente com base na versão do bundle. Em
seguida, o workflow
[release.yml](/Users/lrodrigues/projects/nimbus-code-spec-kit-template/.github/workflows/release.yml)
publica os assets, validando que a tag aponta para commit da `main`.

### 6.7. Atualizando um projeto consumidor para a versão mais recente do bundle

Isto **não** é sobre publicar uma nova versão aqui — é sobre um projeto que já
foi bootstrapado com uma versão antiga do `nimbus-code-project-bundle` e
precisa se atualizar para a versão atual publicada neste repositório, sem
perder customização local (Contexto do Projeto, Bounded Contexts próprios,
entradas de catálogo já registradas, seções preenchidas de "Padrões de Código
deste Projeto") e sem quebrar o fluxo de PR normal.

O workflow `update-speckit-and-bundle.yml` (instalado pelo `bootstrap.sh` em
todo projeto consumidor) **detecta** que há uma versão nova e abre/atualiza
uma issue de aviso — ele nunca aplica a atualização sozinho. Quando essa issue
aparecer (ou quando você quiser verificar manualmente), use o prompt abaixo
com o agente de Copilot **dentro do repositório do projeto consumidor**:

```text
Você está atualizando este projeto para a versão mais recente do bundle
`nimbus-code-project-bundle` da Nimbus-Code (fonte: nimbus-code-spec-kit-template).
Siga este roteiro sem pular etapas:

1. Diagnóstico
   - Leia .specify/integration.json e a tabela de versão no README (seção
     "Nimbus Code — Padrões Nimbus-Code") para descobrir as versões
     instaladas hoje (Nimbus Code CLI, bundle, preset, extensão, workflow).
   - Compare com a versão mais recente publicada nos catalog.json de
     nimbus-code-spec-kit-template (registre os catálogos primeiro se ainda
     não estiverem registrados, com os comandos da seção "Publicação e
     Catálogo" do README de nimbus-code-spec-kit-template).
   - Se a versão instalada já for a mais recente, pare aqui e informe — não
     há nada para atualizar.

2. Branch e escopo
   - Crie uma branch dedicada (ex.: `chore/update-nimbus-code-bundle-vX.Y.Z`).
   - Nunca faça commit direto em `main`/`develop` — esta atualização segue a
     mesma regra de qualquer outra mudança de dependência.

3. Aplicar a atualização sem destruir customização local
   - Rode `specify bundle install nimbus-code-project-bundle` (ou
     `specify preset add`/`extension add`/`workflow add` individualmente, se
     o projeto não usa o bundle consolidado).
   - **Nunca sobrescreva cegamente** `copilot-instructions.md`,
     `.specify/memory/constitution.md`, `docs/bounded-contexts.yaml`,
     `docs/reuse-catalog.yaml`, `docs/cost-profiles-and-rates.md`, nem
     qualquer arquivo em `docs/harness/` ou `docs/playbooks/` que já exista
     neste projeto com conteúdo próprio — faça diff seção por seção contra o
     template novo e mescle apenas o que é aditivo (novas seções, novas
     regras), preservando 100% do conteúdo específico deste projeto.
   - Se um arquivo novo do template (ex.: `docs/harness/`, `docs/playbooks/`,
     `scripts/generate-context-graph.sh`, `scripts/harvest-patterns.sh`,
     `scripts/process-metrics-report.sh`, `.github/workflows/graph-guard.yml`,
     `.github/workflows/agent-auto-assign.yml`) ainda não existir neste
     projeto, copie-o integralmente — são artefatos aditivos, seguros de criar.
   - Se este projeto tiver `.github/workflows/tag-release-on-main.yml`,
     `release-impact-advisor.yml` ou `release-readiness-gate.yml` copiados de
     uma versão antiga do template, **remova-os** — eram bugs de empacotamento
     (referenciavam `bundles/*/bundle.yml`/`catalog.json` que só existem no
     repositório-fonte) e nunca deveriam ter sido shipados a projetos
     consumidores; foram retirados do preset a partir desta versão.
   - Se este projeto ainda não tiver a seção "Idioma dos Artefatos" na
     constituição, ou não tiver "Harness Engineering"/"Playbook de Sucesso"
     no `copilot-instructions.md`, adicione-as (são regras aditivas desta
     versão) sem remover nada que já existia.

4. Atualizar a documentação de versão
   - Atualize a tabela de versões no README (modelo em
     `templates/README-bundle-section.md` do repositório-fonte).
   - `.specify/integration.json` normalmente é reescrito por
     `specify init --here --force`, não editado à mão — confirme antes de
     alterá-lo manualmente.

5. Validar antes de abrir o PR
   - Rode qualquer suíte de testes/lint já existente neste projeto (ex.:
     `./scripts/run-tests.sh`, se existir).
   - Valide sintaticamente todo arquivo novo/alterado (YAML: parseia sem
     erro; shell: `bash -n`).
   - Confirme que nenhuma seção pré-existente de `copilot-instructions.md`/
     `constitution.md` foi removida — apenas adicionada.

6. Abrir o PR
   - Título: "chore: atualizar bundle nimbus-code-project-bundle para vX.Y.Z".
   - Corpo do PR deve listar: versão anterior → nova, o que é novo nesta
     versão (seções/artefatos adicionados) e confirmação de que nenhuma
     customização local foi perdida.
   - Classifique a complexidade como S1 ou S2 (atualização de dependência
     aditiva); se alterar comportamento de autenticação, segurança ou
     branch/merge, reclassifique para S3/S4 e peça revisão humana antes de
     prosseguir.
   - Peça revisão humana normal antes do merge — nunca faça merge sozinho.

Se em qualquer etapa encontrar conflito real entre o conteúdo específico
deste projeto e o novo conteúdo do template (não um caso puramente aditivo),
pare, documente o conflito no PR e peça decisão explícita do Dev — nunca
resolva um conflito de conteúdo escolhendo um lado silenciosamente.
```

Ver também: [FAQ — Como atualizo um projeto criado com uma versão antiga do bundle/preset com segurança?](FAQ.md#como-atualizo-um-projeto-criado-com-uma-versão-antiga-do-bundlepreset-com-segurança).

## Documentos relacionados neste repositório

- [`docs/bundle-architecture.md`](bundle-architecture.md) — diagramas Mermaid
  de como preset + extensão + workflow se compõem no bundle.
- [`docs/mcp-and-bundles.md`](mcp-and-bundles.md) — o que o Nimbus Code realmente
  faz (e não faz) com `requires.mcp`, e tabela de servidores MCP por
  plataforma (GitHub, Microsoft 365, Azure, Google Workspace, GCP).
- [`docs/ai-code-quality-and-observability.md`](ai-code-quality-and-observability.md) —
  como aplicar na prática as regras de revisão por IA, testes integrados,
  observabilidade, correlation-id/microsserviços e abertura automática de bugs.
- [`docs/extension-candidates.md`](extension-candidates.md) — quais extensões
  (oficiais e da Nimbus-Code) considerar instalar além do bundle padrão.

## Integrações Multi-Agente e Agentes Disponíveis (SPEC 024)

O Nimbus Code suporta três plataformas de execução de agentes com paridade completa nos 17 comandos `/speckit-*` e nos 14 agentes institucionais `/nc-*`:

| Plataforma / Agente | Diretório de Instalação | `multi_install_safe` | 17 Comandos `/speckit-*` | 14 Agentes `/nc-*` |
|---|---|:---:|:---:|:---:|
| **GitHub Copilot** | `.github/skills/` | `true` | ✅ Nativo | ✅ Fonte única |
| **Claude Code** | `.claude/skills/` | `true` | ✅ `specify integration install claude` | ✅ Sincronizado (`scripts/sync-nc-agents-to-integrations.sh --target claude`) |
| **Antigravity** | `.agents/skills/` | `false` | ✅ `specify integration install agy` (Worktree isolado) | ✅ Sincronizado (`scripts/sync-nc-agents-to-integrations.sh --target antigravity`) |

### Tabela de Agentes e Comandos Disponíveis por Integração

| Identificador | Tipo | Camada / Descrição | Copilot | Claude Code | Antigravity |
|---|---|---|:---:|:---:|:---:|
| `/speckit-assess-intake` | Workflow | Discovery (Intake de Ideia Bruta) | ✅ | ✅ | ✅ |
| `/speckit-assess-research` | Workflow | Discovery (Pesquisa & Evidências) | ✅ | ✅ | ✅ |
| `/speckit-assess-define` | Workflow | Discovery (Definição de Problema) | ✅ | ✅ | ✅ |
| `/speckit-assess-shape` | Workflow | Discovery (Modelagem de Conceito) | ✅ | ✅ | ✅ |
| `/speckit-assess-decide` | Workflow | Discovery (Decisão Go/Clarify/Kill) | ✅ | ✅ | ✅ |
| `/speckit-constitution` | Workflow | Governança & Princípios | ✅ | ✅ | ✅ |
| `/speckit-specify` | Workflow | Especificação SDD | ✅ | ✅ | ✅ |
| `/speckit-clarify` | Workflow | Clarificação de Requisitos | ✅ | ✅ | ✅ |
| `/speckit-checklist` | Workflow | Geração de Checklists | ✅ | ✅ | ✅ |
| `/speckit-plan` | Workflow | Planejamento de Arquitetura | ✅ | ✅ | ✅ |
| `/speckit-tasks` | Workflow | Geração de Tarefas | ✅ | ✅ | ✅ |
| `/speckit-analyze` | Workflow | Análise de Consistência | ✅ | ✅ | ✅ |
| `/speckit-implement` | Workflow | Implementação de Código | ✅ | ✅ | ✅ |
| `/speckit-converge` | Workflow | Fechamento de Lacunas | ✅ | ✅ | ✅ |
| `/speckit-taskstoissues` | Workflow | Sincronização de Issues GHE | ✅ | ✅ | ✅ |
| `/speckit-interview` | Workflow | Entrevista de Descoberta 4 Blocos | ✅ | ✅ | ✅ |
| `/speckit-nimbus-code-backlog-sync-sync` | Workflow | Backlog Externo (Jira/ADO) | ✅ | ✅ | ✅ |
| `/nc-assess-intake` | Agente | Camada 0: Idea Intake Specialist | ✅ | ✅ | ✅ |
| `/nc-assess-research` | Agente | Camada 0: Evidence Researcher | ✅ | ✅ | ✅ |
| `/nc-assess-define` | Agente | Camada 0: Problem Definer | ✅ | ✅ | ✅ |
| `/nc-assess-shape` | Agente | Camada 0: Concept Shaper | ✅ | ✅ | ✅ |
| `/nc-assess-decide` | Agente | Camada 0: Assessment Decider | ✅ | ✅ | ✅ |
| `/nc-intake` | Agente | Camada 1: Discovery Intake (Alias `/speckit-interview`) | ✅ | ✅ | ✅ |
| `/nc-spec` | Agente | Camada 1: Spec Architect (Alias `/speckit-specify`) | ✅ | ✅ | ✅ |
| `/nc-critic` | Agente | Camada 1: Spec Auditor | ✅ | ✅ | ✅ |
| `/nc-governor` | Agente | Camada 1: Gates & Integridade SHA-256 | ✅ | ✅ | ✅ |
| `/nc-arch` | Agente | Camada 2: Solution Architect | ✅ | ✅ | ✅ |
| `/nc-qa` | Agente | Camada 2: Test Strategist | ✅ | ✅ | ✅ |
| `/nc-builder` | Agente | Camada 3: Autonomous Builder (Alias `/speckit-implement` + `/speckit-converge`) | ✅ | ✅ | ✅ |
| `/nc-shield` | Agente | Camada 2: DevSecOps Guardian | ✅ | ✅ | ✅ |
| `/nc-telemetry` | Agente | Camada 3: Observability & SRE | ✅ | ✅ | ✅ |

### Regra de Segurança para Antigravity (`multi_install_safe: false`)

Como o `specify_cli` define `multi_install_safe = false` para Antigravity, a instalação e validação inicial de novas versões deve ocorrer sempre em worktree isolado (`git worktree add ../nimbus-agy-validation`), promovendo para a branch de trabalho somente após validação completa, evitando qualquer sobreposição acidental em ambientes compartilhados.

### Sincronização e Prevenção de Drift

A fonte da verdade de todos os agentes `/nc-*` reside exclusivamente em `.github/skills/nc-*/`. Quando qualquer agente institucional for atualizado, execute:

```bash
./scripts/sync-nc-agents-to-integrations.sh --target all
```

O workflow de CI `.github/workflows/nc-agents-parity-check.yml` executa a suíte Bats `tests/multi-agent-integration/nc-agents-parity.bats` em todo Pull Request que altera skills ou scripts de sincronização, garantindo que nenhum drift passe despercebido.


## Phase 2: Automated Preset Synchronization (SPEC 020)

Esta fase fornece auditoria de versões e um caminho controlado de atualização.
**Não significa rollout aprovado**: o auto-sync permanece desabilitado por padrão,
dependente de opt-in, credencial com acesso aos satélites e piloto humano
(#433/#445). O token padrão do workflow não concede acesso cross-repo.

### Weekly Satellite Preset Audit

**Schedule**: Every Monday at 09:00 UTC

The central repository runs `.github/workflows/satellite-preset-audit.yml`, which:

1. Consulta os satélites acessíveis à credencial configurada.
2. Lê `.specify/presets/.registry` e compara com os manifests do checkout
   central, sem versão fixa no script.
3. Produz relatório CSV e distingue drift, ausência de bootstrap e erros de
   consulta; ausência de acesso não é prova de ausência de preset.
4. Publica evidência/issue quando aplicável. Um relatório sem drift é válido
   e não deve falhar por um filtro sem correspondências.

**View audit results**:
```bash
# Download latest audit report
gh run list --workflow=satellite-preset-audit.yml --limit 1 \
  --json databaseId,createdAt --jq '.[0].databaseId' | xargs -I {} \
  gh run download {} -n preset-audit-report
```

### Auto-PR Generation for Drifted Repos

O workflow `.github/workflows/auto-sync-preset.yml` é um mecanismo opt-in,
não autorização para alterar todos os satélites. O fluxo só pode usar uma
versão existente no checkout de origem, executar refresh sem provisioning e
abrir PR para revisão. Não deve mascarar falhas nem sobrescrever branches
remotas por force-push.

`NIMBUS_SATELLITE_SYNC_ENABLED=true` habilita apenas o dispatch manual;
ausente/false mantém o sync desabilitado. Nesta entrega, o auto-sync suporta
somente `dev_standards`. O preset `platform` pode usar o refresh manual
documentado abaixo, mas não está incluído no rollout automatizado.

Consulte os inputs, variáveis e autenticação vigentes no workflow e no
[quickstart da SPEC 020](../specs/020-satellite-repo-governance/quickstart.md)
antes de habilitar um piloto. Não existe a operação “adicionar label a um PR
antes de ele ser criado”; mantenha o opt-in desabilitado enquanto a revisão
humana estiver pendente.

### Preset Version Validation in CI/CD

O bootstrap entrega `.github/workflows/validate-bootstrap.yml` e seu detector.
O check deve preservar o exit code de mismatch/erro, não somente publicar uma
mensagem. No consumidor, a referência local é o manifest instalado em
`.specify/presets/`, não um diretório `presets/` central que ele não possui.
Comparação local verifica consistência da instalação; não substitui a auditoria
central de versão mais recente. Tornar o check obrigatório depende da proteção
de branch aprovada pelo responsável.

O hook `scripts/validate-versions.sh` entregue ao consumidor usa esse detector.
O script homônimo do repositório central valida também bundles/catalogs e
**não deve ser copiado diretamente para um satélite**.

### Manual Preset Refresh

Use um checkout confiável da versão desejada do bundle e execute a partir
do repositório consumidor. O bootstrap não precisa existir no satélite:

```bash
# Dentro do repositorio consumidor; ajuste para o checkout do bundle desejado
bash /caminho/do/bundle/bootstrap.sh \
  --local /caminho/do/bundle --refresh-preset --repo-type dev_standards
git diff --stat
```

Use `platform` para o preset de plataforma. O tipo pode ser omitido somente
quando o registro identifica exatamente um preset Nimbus suportado.

Pré-requisitos: Bash 4+, `specify`, `python3` com PyYAML. O refresh não executa
`specify init`, extensões, topology, GitHub Projects, labels ou instalação de
hooks. Reinstala o preset e sincroniza arquivos gerenciados sem sobrescrever
instruções locais, catálogos, configuração de custos ou overrides.

`.specify/bundle-files.json` registra hashes dos arquivos entregues. Alteração
local ou arquivo legado divergente sem baseline interrompe o preflight antes
de remover o preset. Reconcilie conscientemente os arquivos indicados: não
apague o estado nem use o bootstrap normal como um “force refresh”.
O bootstrap normal continua sendo o caminho de criação/inicialização.
Uma falha de instalação é reportada; não equivale a atualização concluída.

Revise **todas** as alterações (incluindo scripts e workflows, não apenas
`.specify/`), valide e envie um PR pela branch de trabalho aprovada, sem merge
automático. A distribuição geral de skills enriquecidas continua sujeita à
decisão #367/#405; copiar scripts corrigidos não resolve esse gate.

### Phase 2 Compliance Checklist

- [ ] Credencial cross-repo e piloto humano aprovados antes de habilitar opt-in
- [ ] Relatório distingue drift, instalação ausente e falha de acesso
- [ ] Refresh executado em fixture antes de um satélite real
- [ ] Registry, manifest instalado, arquivos gerenciados e overrides revisados
- [ ] Check de CI realmente falha em drift/erro e proteção de branch revisada

---

## 7. Análises Comparativas de Frameworks

Para entender como o Nimbus Code se posiciona em relação a outros frameworks e projetos open-source da comunidade de IA e engenharia de software, consulte os relatórios técnicos detalhados:

- [GSD Core vs. Nimbus Code](comparisons/gsd-core-vs-nimbus-code.md): Comparação aprofundada de foco operacional (Context Engineering e ciclos de terminal vs. Governança Corporativa Full-Cycle, RACI, DORA, DevSecOps e FinOps).
- [Understand-Anything vs. Nimbus Harvest & Catálogo de Reuso](comparisons/understand-anything-vs-nimbus-harvest.md): Comparação de propósitos (Visualização/navegação interativa de AST para onboarding humano vs. Mineração on-demand de componentes e assinaturas sem segredos para governança de IA e economia de tokens).

