# Manual do Dev — Começando com GHE + Nimbus Code na Nimbus-Code

> **TL;DR** (S0/S1 — leitura completa reservada para primeira vez em cada
> cenário ou dúvida específica): repo novo → `curl ... bootstrap.sh | bash`
> (seção 1); repo existente sem Nimbus Code/sem Spec Kit → `curl ... bootstrap.sh | bash`
> no próprio repo (ou `specify init --here` + bootstrap, se quiser separar) e
> só depois ler o código/Boards antes de especificar (seção 2, brownfield);
> ponto de partida a partir de um card do ADO/JIRA → prompt de importação pronto
> (seção 3).
> Pré-requisitos (`specify` CLI, `uv`, Copilot) na tabela logo abaixo.

Este é o manual **central** de como todo dev da Nimbus-Code deve usar o
[GitHub Nimbus Code](https://github.com/github/nimbus-code) no dia a dia, com as
ferramentas da empresa (GHE, Azure DevOps/JIRA, GitHub Copilot). Ele cobre três
cenários, na ordem em que você provavelmente vai precisar deles:

1. [Repositório novo](#1-repositório-novo) — bootstrap padrão em 1 comando.
2. [Repositório existente sem Nimbus Code](#2-repositório-existente-sem-nimbus-code-brownfield) —
   como instalar e rodar o Nimbus Code entendendo o contexto pelo **código
   (brownfield)** e pelos **Boards** (cards já existentes).
3. [Importar um card do Azure DevOps/JIRA para começar uma feature](#3-importar-um-card-do-azure-devops-ou-jira-para-começar-uma-feature) —
   o prompt exato para puxar um work item/issue como ponto de partida.

Se algo aqui divergir do que você vê na prática, este arquivo é a fonte da
verdade — abra um PR corrigindo, não crie um manual paralelo em outro lugar.

## Pré-requisitos (uma vez por máquina)

| Ferramenta | Para quê | Como obter |
|---|---|---|
| `specify` CLI | Roda `specify init`, gerencia presets/extensões/workflows | `uv tool install specify-cli --from git+https://github.com/github/nimbus-code.git` — ver [guia de instalação](https://github.com/github/nimbus-code/blob/main/docs/installation.md) |
| [`uv`](https://docs.astral.sh/uv/) | Gerenciador Python usado para instalar o `specify-cli` | [Guia de instalação do uv](https://github.com/github/nimbus-code/blob/main/docs/install/uv.md) |
| Acesso ao GHE da org `venha-pra-nuvem` | Clonar este repo e os repos de projeto | Onboarding padrão de acesso à organização |
| GitHub Copilot habilitado no editor | Agente que executa os comandos `/speckit.*` | Extensão do Copilot no VS Code (ou outro agente suportado — ver [integrações](https://github.github.io/nimbus-code/reference/integrations.html)) |
| MCP do backlog (Atlassian Rovo **ou** `ado`), se o projeto usa JIRA/Azure DevOps | Necessário só para os fluxos de importação/sincronização de board (seções 2 e 3) | Configuração do host do agente (ex.: `.vscode/mcp.json`) — ver [`docs/mcp-and-bundles.md`](mcp-and-bundles.md) |

Rode `specify check` a qualquer momento para validar se o ambiente está OK.

## 1. Repositório novo

Já documentado em detalhe no [README raiz](../README.md#como-um-projeto-novo-já-nasce-com-isso).
Resumo:

```bash
curl -fsSL https://raw.venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/main/bootstrap.sh | bash
```

Isso já deixa o projeto com `specify init` feito e o bundle
`nimbus-code-project-bundle` (preset + extensão + workflow) instalado.

### 1.1. GitHub Project criado automaticamente (e garantido continuamente)

Se você tiver o `gh` CLI instalado e autenticado, o `bootstrap.sh` também cria
**automaticamente um GitHub Project V2** com o nome `{repo-name} — Nimbus Code Roadmap`.

O project já vem com **3 views padrão** (copiadas do IOX-CROWDFUNDINGPAAS) e
**2 campos customizados**:

- **Board por Epic** — organize issues por épicas (personalizável)
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
secrets `VPNDEV_PROJECT_TOKEN` e `VPNDEV_STANDARDS_READ_TOKEN`.

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
curl -fsSL https://raw.venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/main/bootstrap.sh | bash
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
curl -fsSL https://raw.venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/main/bootstrap.sh | bash
```

Use esta variação só se você **quiser separar conscientemente** a criação da
`.specify/` da aplicação do bundle. Nesse caso, o `bootstrap.sh` detecta que o
`specify init` já rodou e só instala preset + extensão + workflow (ver
[`bootstrap.sh`](../bootstrap.sh)). O resultado final é o mesmo da seção 2.1.

### 2.3. Varrer o código existente — gerar a constituição a partir do que já está implementado

Este é o passo que resolve "como o Nimbus Code entende o código". **Não existe um
comando dedicado de "scan"** — a varredura acontece dentro do próprio
`/nimbus-code.constitution`, sendo explícito no prompt para o agente analisar a
fundo antes de escrever qualquer princípio. Use este prompt (adaptado do
[walkthrough oficial de brownfield](https://github.com/mnriem/nimbus-code-aspnet-brownfield-demo)
do próprio time do Nimbus Code):

```
/nimbus-code.constitution Este é um projeto brownfield já existente, sem
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
como contexto adicional no prompt do `/nimbus-code.specify` seguinte — ele não
substitui a leitura do código feita no passo 2.3, complementa com o "porquê"
por trás de decisões que só existem no board, não no código.

### 2.5. Ciclo normal de features a partir daqui

Com constituição + contexto de board levantados, o resto do ciclo é o padrão
do Nimbus Code (ver [`workflows/nimbus-code-full-cycle/README.md`](../workflows/nimbus-code-full-cycle/README.md)
para a variante com gate de DevSecOps da Nimbus-Code):

```
/nimbus-code.specify   → descreve a feature nova (não retro-especifique o app inteiro)
/nimbus-code.clarify    → (opcional) reduz ambiguidade antes de planejar
/nimbus-code.plan       → plano técnico (já usa o que o agente aprendeu do código real)
/nimbus-code.checklist  → (opcional) "testes unitários" da própria spec
/nimbus-code.tasks      → lista de tarefas ordenada por dependência
/nimbus-code.analyze    → (opcional, somente leitura) checa consistência spec/plan/tasks
/nimbus-code.implement  → executa as tarefas (pode levar múltiplos passes em repo grande)
/nimbus-code.converge   → depois do implement: compara código real vs spec/plan/tasks
                      e anexa o que faltar como novas tarefas — repita
                      implement → converge até sair "✅ Converged"
```

`/nimbus-code.converge` é especialmente útil em brownfield porque é comum já
existir implementação parcial/legada na mesma área da feature nova — ele é
**append-only** (nunca edita/apaga código, só pode adicionar tarefas).

### 2.6. DOs e DONTs — padrão brownfield (crítico para sucesso)

### ✅ DOs — boas práticas brownfield

- **DO** começar pelo `bootstrap.sh` quando o repo brownfield ainda não tem
  Spec Kit/Nimbus Code — ele já faz o `specify init --here` e instala o bundle
  padrão da Nimbus-Code no mesmo fluxo.
- **DO** rodar `/nimbus-code.constitution` como o passo **1 da primeira feature**,
  depois da inicialização do ambiente, com o prompt de análise profunda —
  deixar o agente entender o código existente custa iterações iniciais mas
  economiza em toda feature subsequente.
- **DO** manter `constitution.md`, `spec.md` e `plan.md` como **artefatos vivos**
  — eles são sempre reescritos/atualizados conforme a realidade muda, não são
  cópia estática do que foi feito uma vez.
- **DO** usar `/nimbus-code.converge` **sempre** depois do `implement` — é
  append-only, busca gaps, e é essencial em brownfield onde código legado já
  toca a mesma área da feature nova.
- **DO** fazer **múltiplos passes** de `implement` → converge em features
  grandes/complexas — é esperado e normal, não é sinal de erro.
- **DO** documentar **exceções de padrão** no Architecture Decision Log do
  `plan.md` — se você não segue a constituição em algo, deixe registrado e
  rastreável (ex.: framework IaC diferente do padrão Terraform, por compliance
  nativo do Azure Policy).
- **DO** revisar a análise profunda gerada pelo agente (iterações 1-N do
  `/nimbus-code.constitution`) **como insumo, não como verdade absoluta** — o agente
  pode interpretar padrões errado ou superestimar certa convenção. Edite
  `constitution.md` se necessário antes de prosseguir para features.
- **DO** rodar `/nimbus-code.analyze` **antes** de implementar — a carga cognitiva
  de ambiguidades em spec/plan/tasks é exponencial; pague o custo cedo.
- **DO** manter `.specify/` versionado no git — é parte da história do projeto,
  não é lixo de build. `.specify/memory/` (com artefatos) sim, mas pelo menos
  `.specify/features/` (com as estruturas de feature) devem estar no histórico.

### ❌ DONTs — armadilhas comuns em brownfield

- **DON'T** pular o `/nimbus-code.constitution` achando que "vamos especificar
  features normalmente" — sem princípios derivados do código existente, cada
  feature é um caos; o agente toma decisões contraditórias.
- **DON'T** tentar retro-especificar **todo** o código existente num único
  `/nimbus-code.specify` — isso sobrecarrega o agente e gera uma "spec" gigante e
  inútil. Especifique **só a mudança incremental** (o que é novo/alterado, não
  o que já existe).
- **DON'T** editar `spec.md`/`plan.md`/`tasks.md` manualmente depois que foram
  gerados — se precisa ajustar, reegere os artefatos com os comandos correspondentes
  (ex.: `/nimbus-code.specify` de novo com um prompt ajustado, não edite `spec.md`
  diretamente). Exceção: adicionar observações/notas contextuais, OK; mudar
  requisito/design, não.
- **DON'T** ignorar o `/nimbus-code.converge` achando que "implementamos tudo o que
  foi pedido" — converter sempre encontra lacunas que não eram óbvias na spec
  original. É parte do ciclo, não é falha.
- **DON'T** usar `/nimbus-code.implement` uma única vez em repo grande esperando que
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
  `/nimbus-code.clarify` ou `/nimbus-code.specify`), não culpe o Nimbus Code.

### 2.7. Checklist pré-primeiro-ciclo para brownfield

Antes de rodar a primeira feature em um brownfield, valide:

- [ ] `bootstrap.sh` rodou com sucesso no repo brownfield
- [ ] `.specify/` foi criado (via `bootstrap.sh` ou via `specify init --here`, se você optou por separar)
- [ ] Bundle `nimbus-code-project-bundle` instalado (veja `.specify/presets/` e `.specify/extensions/`)
- [ ] `/nimbus-code.constitution` executado com o prompt de **análise profunda** (seção 2.3)
- [ ] `constitution.md` revisado/editado manualmente se necessário
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
/nimbus-code.specify Busque o work item #1234 no Azure DevOps (organização
<org>, projeto <projeto>) via MCP e construa a especificação desta feature a
partir do título, descrição e critérios de aceitação dele. Se algo estiver
ambíguo, incompleto ou contraditório, liste como observação a esclarecer —
não invente detalhes que não estão no work item.
```

### Prompt para JIRA

```
/nimbus-code.specify Busque a issue <PROJ-123> no JIRA via MCP Atlassian Rovo e
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
(`/nimbus-code.clarify` → `/nimbus-code.plan` → ... ) como na seção 2.5.

## Referência rápida de comandos

| Comando | Quando usar | Obrigatório? |
|---|---|---|
| `/nimbus-code.constitution` | Uma vez por projeto (ou ao mudar princípios); em brownfield, com o prompt de análise profunda da seção 2.3 | Sim, uma vez |
| `/nimbus-code.specify` | Toda feature nova — descreve o quê/porquê, não a stack | Sim |
| `/nimbus-code.clarify` | Quando a spec tem áreas ambíguas | Recomendado |
| `/nimbus-code.plan` | Depois da spec aprovada — stack e arquitetura | Sim |
| `/nimbus-code.checklist` | Validar completude da própria spec antes de detalhar tarefas | Opcional |
| `/nimbus-code.tasks` | Gera `tasks.md` a partir do plano | Sim |
| `/nimbus-code.analyze` | Checagem cruzada spec/plan/tasks antes de implementar | Recomendado |
| `/nimbus-code.implement` | Executa as tarefas | Sim |
| `/nimbus-code.converge` | Depois do implement — garante que nada ficou faltando vs. spec/plan/tasks | Recomendado, essencial em brownfield |

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
