# Manual do Dev — Começando com GHE + Spec Kit na VPN Dev

Este é o manual **central** de como todo dev da VPN Dev deve usar o
[GitHub Spec Kit](https://github.com/github/spec-kit) no dia a dia, com as
ferramentas da empresa (GHE, Azure DevOps/JIRA, GitHub Copilot). Ele cobre três
cenários, na ordem em que você provavelmente vai precisar deles:

1. [Repositório novo](#1-repositório-novo) — bootstrap padrão em 1 comando.
2. [Repositório existente sem Spec Kit](#2-repositório-existente-sem-spec-kit-brownfield) —
   como instalar e rodar o Spec Kit entendendo o contexto pelo **código
   (brownfield)** e pelos **Boards** (cards já existentes).
3. [Importar um card do Azure DevOps/JIRA para começar uma feature](#3-importar-um-card-do-azure-devops-ou-jira-para-começar-uma-feature) —
   o prompt exato para puxar um work item/issue como ponto de partida.

Se algo aqui divergir do que você vê na prática, este arquivo é a fonte da
verdade — abra um PR corrigindo, não crie um manual paralelo em outro lugar.

## Pré-requisitos (uma vez por máquina)

| Ferramenta | Para quê | Como obter |
|---|---|---|
| `specify` CLI | Roda `specify init`, gerencia presets/extensões/workflows | `uv tool install specify-cli --from git+https://github.com/github/spec-kit.git` — ver [guia de instalação](https://github.com/github/spec-kit/blob/main/docs/installation.md) |
| [`uv`](https://docs.astral.sh/uv/) | Gerenciador Python usado para instalar o `specify-cli` | [Guia de instalação do uv](https://github.com/github/spec-kit/blob/main/docs/install/uv.md) |
| Acesso ao GHE da org `venha-pra-nuvem` | Clonar este repo e os repos de projeto | Onboarding padrão de acesso à organização |
| GitHub Copilot habilitado no editor | Agente que executa os comandos `/speckit.*` | Extensão do Copilot no VS Code (ou outro agente suportado — ver [integrações](https://github.github.io/spec-kit/reference/integrations.html)) |
| MCP do backlog (Atlassian Rovo **ou** `ado`), se o projeto usa JIRA/Azure DevOps | Necessário só para os fluxos de importação/sincronização de board (seções 2 e 3) | Configuração do host do agente (ex.: `.vscode/mcp.json`) — ver [`docs/mcp-and-bundles.md`](mcp-and-bundles.md) |

Rode `specify check` a qualquer momento para validar se o ambiente está OK.

## 1. Repositório novo

Já documentado em detalhe no [README raiz](../README.md#como-um-projeto-novo-já-nasce-com-isso).
Resumo:

```bash
curl -fsSL https://raw.venha-pra-nuvem.ghe.com/venha-pra-nuvem/speckit-vpndev-standards/main/bootstrap.sh | bash
```

Isso já deixa o projeto com `specify init` feito e o bundle
`vpndev-project-bundle` (preset + extensão + workflow) instalado.

### 1.1. GitHub Project criado automaticamente

Se você tiver o `gh` CLI instalado e autenticado, o `bootstrap.sh` também cria
**automaticamente um GitHub Project V2** com o nome `{repo-name} — Spec Kit Roadmap`.

O project já vem com **3 views padrão** (copiadas do IOX-CROWDFUNDINGPAAS):

- **Board por Epic** — organize issues por épicas (personalizável)
- **Board por Prioridade** — organize por prioridade (personalizável)
- **Tabela — P0 Blocker** — filtro pré-pronto para bloqueadores críticos (P0-blocker)

Depois do bootstrap, você pode:

1. Abrir o project (link será exibido no output do script)
2. Customizar filtros, grupos e colunas conforme sua necessidade
3. Ligar o project ao repositório (Settings do repo → Project → habilitar)

**Se o `gh` CLI não estiver disponível** ou você preferir criar manualmente, rode:

```bash
bash ./scripts/setup-github-project.sh --repo-owner venha-pra-nuvem --repo-name seu-repo
```

Depois disso, pule direto para a seção 3 para começar sua primeira feature.

## 2. Repositório existente sem Spec Kit (brownfield)

Este é o cenário mais comum na prática: um repo que já existe há anos, com
código real, talvez com um board no Azure DevOps/JIRA cheio de cards, mas
**sem nenhum artefato do Spec Kit ainda**. O objetivo aqui é fazer o Spec Kit
entender o contexto por **duas fontes**: o código já escrito e o histórico do
board — antes de escrever a primeira spec.

### 2.1. Instalar o Spec Kit no repo (sem tocar no código existente)

```bash
cd meu-repo-existente
specify init --here --integration copilot --force
```

`--here` inicializa dentro do diretório atual em vez de criar um novo — isso só
adiciona a pasta `.specify/` e os arquivos de comando do agente (ex.:
prompts/skills do Copilot). **Nada do código-fonte existente é tocado.**

### 2.2. Aplicar o bundle da VPN Dev por cima

```bash
curl -fsSL https://raw.venha-pra-nuvem.ghe.com/venha-pra-nuvem/speckit-vpndev-standards/main/bootstrap.sh | bash
```

O `bootstrap.sh` detecta que o `specify init` já rodou e só instala
preset + extensão + workflow (ver [`bootstrap.sh`](../bootstrap.sh)). Isso
garante que, desde o primeiro dia, o repo já tem o Security/DevSecOps Gate, o
checklist de qualidade e a extensão de backlog — mesmo sendo um projeto
"antigo".

### 2.3. Varrer o código existente — gerar a constituição a partir do que já está implementado

Este é o passo que resolve "como o Spec Kit entende o código". **Não existe um
comando dedicado de "scan"** — a varredura acontece dentro do próprio
`/speckit.constitution`, sendo explícito no prompt para o agente analisar a
fundo antes de escrever qualquer princípio. Use este prompt (adaptado do
[walkthrough oficial de brownfield](https://github.com/mnriem/spec-kit-aspnet-brownfield-demo)
do próprio time do Spec Kit):

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
repo**. Como o preset `vpndev-standards` usa estratégia `wrap`, os princípios
não-negociáveis da VPN Dev (segurança, IaC, qualidade — ver
[`presets/vpndev-standards/templates/constitution-template.md`](../presets/vpndev-standards/templates/constitution-template.md))
entram **antes** dessa constituição derivada do código — os dois convivem sem
conflito, nenhum sobrescreve o outro.

**Nota importante**: Este é um processo que pode levar múltiplas iterações. Para
entender bem padrões, armadilhas, troubleshooting e a importância da constituição
em brownfield, consulte a referência completa em
[`docs/brownfield-best-practices.md`](brownfield-best-practices.md).

### 2.4. Entender o contexto pelos Boards (cards já existentes)

O Spec Kit não tem um comando de "importar todos os cards", mas antes de
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
do Spec Kit (ver [`workflows/vpndev-full-cycle/README.md`](../workflows/vpndev-full-cycle/README.md)
para a variante com gate de DevSecOps da VPN Dev):

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

`/speckit.converge` é especialmente útil em brownfield porque é comum já
existir implementação parcial/legada na mesma área da feature nova — ele é
**append-only** (nunca edita/apaga código, só pode adicionar tarefas).

## 2.6. DOs e DONTs — padrão brownfield (crítico para sucesso)

### ✅ DOs — boas práticas brownfield

- **DO** rodar `/speckit.constitution` como o passo **1**, antes de qualquer
  feature nova, com o prompt de análise profunda — deixar o agente entender o
  código existente custa iterações iniciais mas economiza em toda feature
  subsequente.
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
- **DON'T** confundir "Spec Kit" com "gerador de código" — o Spec Kit é um
  **framework de documentação estruturada** que *alimenta* um gerador (o agente).
  Se o agente gera código ruim, a spec estava ambígua; volte e clarifique (via
  `/speckit.clarify` ou `/speckit.specify`), não culpe o Spec Kit.

### Checklist pré-primeiro-ciclo para brownfield

Antes de rodar a primeira feature em um brownfield, valide:

- [ ] `specify init --here` rodou com sucesso
- [ ] Bundle `vpndev-project-bundle` instalado (veja `.specify/presets/` e `.specify/extensions/`)
- [ ] `/speckit.constitution` executado com o prompt de **análise profunda** (seção 2.3)
- [ ] `constitution.md` revisado/editado manualmente se necessário
- [ ] `.specify/` adicionado ao git e versionado
- [ ] README do projeto atualizado com a seção de Spec Kit (ver [`templates/README-bundle-section.md`](../templates/README-bundle-section.md))
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
do agente, o Spec Kit não instala nem verifica isso).

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

Isso é o caminho **oposto** ao que a extensão `vpndev-backlog-sync` deste
bundle faz nativamente: ela sincroniza `spec.md`/`tasks.md` **para** o board
(hooks `after_specify`/`after_tasks`, opcionais); a importação **do** board
para dentro da spec é sempre feita via prompt manual como acima — o Spec Kit
não tem um comando dedicado de importação nesse sentido.

Depois de gerar a spec a partir do card, continue o ciclo normal
(`/speckit.clarify` → `/speckit.plan` → ... ) como na seção 2.5.

## Referência rápida de comandos

| Comando | Quando usar | Obrigatório? |
|---|---|---|
| `/speckit.constitution` | Uma vez por projeto (ou ao mudar princípios); em brownfield, com o prompt de análise profunda da seção 2.3 | Sim, uma vez |
| `/speckit.specify` | Toda feature nova — descreve o quê/porquê, não a stack | Sim |
| `/speckit.clarify` | Quando a spec tem áreas ambíguas | Recomendado |
| `/speckit.plan` | Depois da spec aprovada — stack e arquitetura | Sim |
| `/speckit.checklist` | Validar completude da própria spec antes de detalhar tarefas | Opcional |
| `/speckit.tasks` | Gera `tasks.md` a partir do plano | Sim |
| `/speckit.analyze` | Checagem cruzada spec/plan/tasks antes de implementar | Recomendado |
| `/speckit.implement` | Executa as tarefas | Sim |
| `/speckit.converge` | Depois do implement — garante que nada ficou faltando vs. spec/plan/tasks | Recomendado, essencial em brownfield |

## Documentos relacionados neste repositório

- [`docs/bundle-architecture.md`](bundle-architecture.md) — diagramas Mermaid
  de como preset + extensão + workflow se compõem no bundle.
- [`docs/mcp-and-bundles.md`](mcp-and-bundles.md) — o que o Spec Kit realmente
  faz (e não faz) com `requires.mcp`, e tabela de servidores MCP por
  plataforma (GitHub, Microsoft 365, Azure, Google Workspace, GCP).
- [`docs/ai-code-quality-and-observability.md`](ai-code-quality-and-observability.md) —
  como aplicar na prática as regras de revisão por IA, testes integrados,
  observabilidade, correlation-id/microsserviços e abertura automática de bugs.
- [`docs/extension-candidates.md`](extension-candidates.md) — quais extensões
  (oficiais e da VPN Dev) considerar instalar além do bundle padrão.
