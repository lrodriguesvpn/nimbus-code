# Definição do Problema — Consolidação Corporativa de Harness Individuais (Claude/Cursor)

## Identificação

| Campo | Valor |
|---|---|
| **Slug** | `harness-consolidacao-corporativa` |
| **Data** | 2026-09-22 |
| **Origem** | `/nc-assess-define` (alias de `/speckit-assess-define`), a partir de `intake.md` e `research.md` |
| **Status** | Problema definido — aguardando gate de decisão (`/nc-assess-decide`) |
| **Legenda de evidência** | 🔍 *Evidência real* (fonte citada, herdada de `research.md`) · `[ASSUMPTION]` *suposição não verificada* · `[NEEDS CLARIFICATION]` *pergunta em aberto que precisa de resposta humana/levantamento interno* · `[PLACEHOLDER]` *meta candidata sem baseline, a validar com o negócio* |

> **Nota de escopo**: este documento fica estritamente no **espaço do
> problema**. Não propõe arquitetura, ferramenta, schema de catálogo ou
> pipeline — isso é responsabilidade de etapas posteriores (`/nc-assess-shape`,
> `/nc-assess-plan`, `/nimbus-code-plan`), condicionadas ao gate de decisão.

---

## 1. Declaração do Problema

Cada um dos ~60 colaboradores que usam assistentes de IA (Claude Code,
Cursor, entre outros) constrói, ao longo do tempo, um **relacionamento
individual e tácito** com o LLM — instruções personalizadas, prompts
recorrentes, convenções de uso, atalhos e regras próprias (`~/.claude/CLAUDE.md`,
`.cursor/rules`, custom instructions, memórias de sessão). Este conhecimento,
aqui chamado de **harness individual**, hoje:

- **fica preso à máquina/conta pessoal** de cada colaborador — não é
  versionado, não é visível a terceiros, não é auditável pela empresa;
- **se perde integralmente** quando o colaborador sai da empresa, troca de
  time ou de ferramenta — não há mecanismo de captura antes da saída;
- **não alimenta nenhum aprendizado organizacional**, mesmo quando resolve
  problemas recorrentes que outros colegas ainda enfrentam do zero, gerando
  reinvenção silenciosa e distribuída da mesma solução;
- **diverge do único mecanismo de memória institucional que já existe** no
  Nimbus Code — `docs/harness/harness-catalog.yaml` e
  `docs/playbooks/success-catalog.yaml` — porque esses catálogos capturam
  **erros/acertos por feature** (schema `HRN-NNNN`/`SUC-NNNN`, gatilho:
  incidente, retrabalho, decisão revertida), não o **relacionamento pessoal
  dev↔agente**, que é um nível diferente e mais tácito de conhecimento
  🔍 (confirmado em `research.md`, seção 2.4: "nenhum artefato institucional
  atual captura o relacionamento tácito dev↔agente — não há schema, gatilho
  de entrada, nem processo de consolidação para isso hoje").

**Por que importa agora**: o Nimbus Code está evoluindo de "template de
projeto" para "processo de engenharia corporativa" (conforme a própria ideia
bruta do `intake.md`). Enquanto isso, os ~60 colaboradores já produzem, dia
após dia, harness pessoal valioso — inclusive em squads que **ainda não
adotaram o Nimbus Code formalmente** — e esse conhecimento de campo real está
sendo gerado e perdido simultaneamente, sem que a organização tenha hoje
qualquer mecanismo de captura, mesmo que rudimentar. 🔍 A pesquisa de mercado
(`research.md`, seção 1) confirma que os três principais fornecedores
(Anthropic, Cursor, GitHub) já resolveram a distribuição **top-down**
(organização → indivíduo) de instruções, mas nenhum resolve nativamente a
mineração **bottom-up** (indivíduo → organização) que é o núcleo desta ideia —
ou seja, este é um problema real, não coberto pelo próprio mercado de
ferramentas, e não apenas uma lacuna interna do Nimbus Code.

---

## 2. Usuários e Stakeholders

| Grupo | Como é afetado hoje | Papel na definição/validação |
|---|---|---|
| **Novos colaboradores em onboarding** | Começam do zero seu próprio relacionamento com Claude/Cursor, sem acesso ao harness já validado por colegas mais experientes — reinventam prompts e convenções já resolvidos por outros | Beneficiários diretos de um eventual mecanismo de consolidação |
| **Squads/times sem Nimbus Code formal** | Já usam Claude/Cursor no dia a dia, mas não têm nenhum processo — nem o institucional do Nimbus Code, nem um alternativo — para capturar o que aprendem | Fonte de harness pessoal "selvagem", potencialmente rico, hoje totalmente invisível à organização |
| **A empresa (como organização), no momento de saída/rotação de um colaborador** | Perde de forma irrecuperável todo o harness pessoal acumulado por aquele colaborador — não há processo de offboarding que capture esse conhecimento | Stakeholder de risco organizacional (perda de capital intelectual tácito) |
| **Mantenedores do Nimbus Code (esquadrão Nimbus)** | Evoluem presets, skills e catálogos hoje majoritariamente com base em teoria/design intencional, sem um canal estruturado de insumo vindo do uso real de campo pelos 60 colaboradores | Consumidores primários do conhecimento consolidado — decisores sobre o que vira `harness-catalog.yaml`/`success-catalog.yaml`/preset institucional |
| **Lideranças técnicas/engenharia** | Têm interesse em reduzir perda de conhecimento tácito e em acelerar onboarding, mas hoje não têm visibilidade nem métrica sobre o estado de harness pessoal na empresa | Patrocinadores/decisores do gate de viabilidade (`/nc-assess-decide`) |
| **Os próprios ~60 colaboradores usuários de Claude/Cursor** | São, simultaneamente, a fonte do conhecimento e os potenciais beneficiários de acessar o harness de colegas — mas também os que carregam o risco de exposição de dados pessoais/sensíveis se o mecanismo for mal desenhado | Fonte primária de dados e parte interessada direta em qualquer decisão de privacidade/opt-in vs. obrigatoriedade |

`[NEEDS CLARIFICATION]` (herdado de `research.md`, seção 4): não há hoje
levantamento de quantos dos 60 usam Claude, quantos usam Cursor, sobreposição
entre os dois, nem taxa de turnover — todos dados necessários para dimensionar
o real tamanho do público impactado antes de qualquer decisão de investimento.

---

## 3. Dores Específicas

Lista objetiva das dores confirmadas (por evidência direta do `intake.md`/
`research.md`) ou logicamente decorrentes da declaração do problema — não
dores vagas ou genéricas:

1. **Perda de conhecimento na saída do colaborador**: quando um dos 60
   colaboradores sai da empresa, troca de time ou de ferramenta, todo o
   harness pessoal acumulado (prompts, regras, convenções) é perdido de forma
   irrecuperável — não existe hoje nenhum gatilho de offboarding que capture
   esse conteúdo antes da saída.
2. **Reinvenção de prompts/regras já resolvidos por outro dev**: sem um
   canal de compartilhamento, múltiplos colaboradores tendem a resolver
   independentemente o mesmo problema recorrente de configuração de agente,
   gastando esforço redundante que já foi pago por um colega.
3. **Inconsistência de qualidade entre devs que usam Claude vs. Cursor vs.
   nenhum harness pessoal**: colaboradores com harness pessoal maduro tendem a
   obter resultados de maior qualidade e consistência dos agentes de IA do
   que colaboradores sem nenhuma customização — criando uma variação de
   produtividade/qualidade não gerenciada e invisível à liderança.
4. **Dificuldade de evoluir o Nimbus Code com base em uso real de campo**: os
   mantenedores do Nimbus Code hoje evoluem presets, skills e catálogos
   principalmente por design intencional/teórico, sem um canal estruturado
   que traga de volta o que realmente funciona (ou não) na prática cotidiana
   dos 60 colaboradores — um problema estrutural de falta de *feedback loop*
   entre uso real e evolução do processo institucional.
5. **Dois "cérebros" paralelos e divergentes** (herdado do `intake.md`): o
   conhecimento institucional formal (`docs/harness/`, `docs/playbooks/`,
   `docs/reuse-catalog.yaml`) e o conhecimento individual informal (harness
   pessoal em cada máquina) evoluem de forma desconectada, sem nenhum
   mecanismo de sincronização entre os dois.
6. **Squads fora do Nimbus Code formal ficam completamente sem rede de
   segurança**: mesmo os mecanismos institucionais parciais que já existem
   (`harness-catalog.yaml`, `success-catalog.yaml`) só se aplicam a quem já
   adota o processo formal — squads que ainda não adotaram não têm acesso a
   nenhum aprendizado consolidado, nem institucional nem pessoal.

---

## 4. Metas e Anti-metas

### 4.1 Metas mensuráveis candidatas (SMART)

**Nenhuma das metas abaixo tem baseline real medido hoje** 🔍 (confirmado em
`research.md`, seção 4: "Nenhum número quantitativo real foi levantado ou deve
ser assumido nesta pesquisa"). Todas são candidatas a validar com o negócio em
`/nc-assess-decide` e/ou levantamento interno complementar antes de virarem
compromisso formal.

| # | Meta candidata | Baseline | Status |
|---|---|---|---|
| M1 | Reduzir o tempo de onboarding técnico de novos colaboradores de **X dias para Y dias**, reaproveitando harness consolidado de colegas experientes | Nenhum (tempo médio de onboarding atual não medido) | `[PLACEHOLDER]` — X e Y a definir com liderança de engenharia/RH |
| M2 | Capturar harness pessoal de **N% dos ~60 colaboradores em M meses** (ex.: 50% em 3 meses, como valor ilustrativo) | Nenhum (0% capturado hoje, por definição do problema) | `[PLACEHOLDER]` — N e M a validar; depende da decisão voluntário vs. obrigatório (seção 5.3 do `research.md`) |
| M3 | Promover **N padrões de harness pessoal a entradas institucionais** (`harness-catalog.yaml`/`success-catalog.yaml`/preset) **por trimestre** | Nenhum (0 promovidos hoje, mecanismo inexistente) | `[PLACEHOLDER]` — N a definir; é a métrica mais diretamente ligada à dor #4 |
| M4 | Reduzir a taxa de reinvenção de prompts/regras já resolvidos (medida por ex. via survey de "você já resolveu um problema que descobriu depois já ter sido resolvido por um colega?") em **Z pontos percentuais** | Nenhum (não medido, nem instrumento de medição existe hoje) | `[PLACEHOLDER]` — requer desenho de instrumento de medição antes de virar meta formal |
| M5 | Garantir que **100% dos colaboradores que saem da empresa** tenham, no processo de offboarding, uma oportunidade formal de contribuir seu harness pessoal antes do desligamento | Nenhum (offboarding hoje não contempla isso) | `[PLACEHOLDER]` — meta de processo, não de ferramenta; mais fácil de validar sem dependência de tooling |

`[NEEDS CLARIFICATION]`: nenhuma dessas metas deve ser tratada como
compromisso até que o negócio (liderança patrocinadora) valide os valores de
X, Y, N, M, Z — o papel deste `problem.md` é registrar a **forma** da meta
(o que seria mensurável), não fixar valores arbitrários como se fossem reais.

### 4.2 Anti-metas / Fora de Escopo nesta definição

- **Não é uma reescrita do Nimbus Code**: o objetivo não é substituir ou
  redesenhar os catálogos institucionais existentes
  (`harness-catalog.yaml`, `success-catalog.yaml`, `reuse-catalog.yaml`), e
  sim endereçar uma lacuna que eles explicitamente não cobrem (harness
  pessoal), reaproveitando-os como destino possível de conteúdo promovido.
- **Não é uma ferramenta de vigilância de produtividade individual**: o
  mecanismo não deve ser usado para avaliar, comparar ou ranquear
  colaboradores por volume/qualidade de harness pessoal — isso geraria
  incentivo perverso e resistência à participação voluntária (risco já
  antecipado em `research.md`, seção 5.3).
- **Não substitui `harness-catalog.yaml`/`success-catalog.yaml` existentes**:
  o novo conceito (harness pessoal) deve coexistir e, quando aplicável,
  alimentar esses catálogos — não os duplicar nem competir com eles.
- **Não é, nesta definição, uma decisão de arquitetura, schema ou ferramenta
  específica** (ex.: automação de varredura de arquivos locais, LLM de
  normalização, dashboard de captura) — essas decisões pertencem a etapas
  posteriores (`/nc-assess-shape`, `/nc-assess-plan`), condicionadas à
  resolução dos riscos e ambiguidades registrados na seção 6 abaixo.
- **Não assume, nesta definição, se a consolidação é evento único ou processo
  contínuo** (`[NEEDS CLARIFICATION]` herdado de `intake.md`/`research.md`,
  seção 5.5) — essa é uma decisão de desenho, não de definição de problema.
- **Não assume, nesta definição, se Claude e Cursor são as únicas ferramentas
  relevantes** — outras ferramentas (GitHub Copilot, VS Code, Antigravity)
  podem estar em uso pelos 60 colaboradores e ficam fora do escopo até
  confirmação (`[NEEDS CLARIFICATION]` herdado do `intake.md`).

---

## 5. Métricas de Sucesso (indicadores de validação)

Estes são os **indicadores**, não as metas com valor fixado (essas estão na
seção 4.1). Servem para orientar o desenho de instrumentação, caso a ideia
avance:

- **Taxa de participação voluntária** (% dos 60 colaboradores que contribuem
  harness pessoal, se o modelo for opt-in).
- **Taxa de promoção institucional** (quantidade de entradas de harness
  pessoal que efetivamente viram entrada em catálogo institucional ou preset,
  dividido pelo total de harness capturado).
- **Tempo de onboarding técnico** (do primeiro dia até "produtivo de forma
  independente", medido antes e depois, para squads que adotarem harness
  consolidado vs. squads controle que não adotarem).
- **Incidência de retrabalho por reinvenção** (via survey qualitativo
  periódico, dado que não há hoje instrumento quantitativo automatizado para
  isso).
- **Cobertura de offboarding** (% de colaboradores que saem da empresa e que
  passaram por um passo formal de contribuição de harness antes da saída).

Todas as métricas acima **dependem de instrumentação a ser desenhada** — nenhuma
delas é coletada automaticamente hoje por nenhum sistema existente no
repositório ou fora dele, até onde a pesquisa (`research.md`) conseguiu
confirmar.

---

## 6. Riscos que já condicionam a viabilidade (a levar ao gate de decisão)

Estes dois riscos foram sinalizados em `research.md` e devem ser tratados
como **pré-condições de viabilidade a resolver em `/nc-assess-decide`**, não
como detalhes a adiar para uma fase de implementação:

### 6.1 Risco de dados sensíveis / privacidade (classificação provável S4)

🔍 Por analogia direta com `specs/022-nimbuscode-harvest-gateway/`
(classificado **S4** — "arquitetura, segurança, dados sensíveis ou integração
crítica", com exigência de revisão humana obrigatória antes de qualquer
implementação), é razoável antecipar `[ASSUMPTION]` que uma iniciativa de
consolidação de harness **pessoal** — que por natureza pode conter dados de
clientes, código proprietário, ou credenciais coladas acidentalmente em
prompts — também seria classificada **S4**, com exigências equivalentes:
`impact-map.md` obrigatório, revisão humana sem opção de burlar via ADR/ADL,
e avaliação formal do agente `nc-shield` (DevSecOps Guardian) antes de
qualquer construção. Isso é estruturalmente mais sensível que o precedente
mais próximo já existente no repositório (`scripts/harvest-patterns.sh`), que
mitiga risco varrendo **apenas metadados estruturais de código versionado**
(nunca corpo de método, string literal, ou texto livre) — o harness pessoal,
por definição, é justamente texto livre escrito por humanos, o "corpo" que o
precedente institucional evita capturar. Isso é um **trade-off central**: não
é possível copiar 1:1 o precedente de design sem perder o valor central da
ideia (o conteúdo do prompt/instrução em si). Este risco, e a decisão sobre
como endereçá-lo (opt-in vs. obrigatório, anonimização, retenção/expurgo,
eventual necessidade de DPA se houver processamento por LLM de terceiro),
precisa ser resolvido — ou pelo menos formalmente reconhecido e aceito como
condição de avanço — antes de `/nc-assess-shape`.

### 6.2 Colisão terminológica com "harness" já institucional

🔍 O termo "harness" já tem significado institucional consolidado e
amplamente referenciado no Nimbus Code (`docs/harness/harness-catalog.yaml`,
`harness-guide.md`, `specs/011-harness-engineering/`), com protocolo de
consulta obrigatória por agentes antes de `/nimbus-code-plan`. Reaproveitar o
mesmo termo para "configuração pessoal de agente" — um conceito diferente
(relacionamento tácito dev↔LLM, não catálogo de erros/acertos por feature) —
cria risco real e imediato de confusão terminológica entre agentes e humanos
que já seguem o protocolo existente. Este risco precisa ser resolvido
explicitamente — recomenda-se que o gate de decisão avalie um nome distinto
para este novo conceito (ex.: "perfil de agente pessoal", "configuração
individual consolidada", "agent profile catalog") antes de qualquer avanço
para `/nc-assess-shape`, para evitar que a própria iniciativa nasça colidindo
com o vocabulário que o Nimbus Code já usa e depende operacionalmente.

---

## 7. Síntese para o Gate de Decisão

| Dimensão | Estado após esta definição |
|---|---|
| Problema | Claramente definido, distinto e não-duplicado em relação aos artefatos institucionais existentes |
| Público | Mapeado (5 grupos de stakeholders), mas sem dimensionamento quantitativo real |
| Metas | Formuladas em formato SMART, mas **todas** sem baseline — são placeholders a validar com o negócio |
| Anti-metas | Explicitadas para conter escopo e evitar interpretação como vigilância ou reescrita do Nimbus Code |
| Riscos bloqueantes | Dois riscos identificados que **condicionam viabilidade**: (1) provável classificação S4 por dados sensíveis/privacidade/LGPD; (2) colisão terminológica com "harness" institucional já existente |

Este `problem.md` **não conclui** se a ideia deve avançar, ser reformulada ou
descartada — essa é a função do gate `/nc-assess-decide`, que deve considerar
explicitamente os dois riscos da seção 6 como condição de qualquer avanço
para `/nc-assess-shape`.

---

## Fontes

Este documento herda integralmente as fontes já citadas em `research.md`
(documentação oficial de Anthropic/Claude Code, Cursor, GitHub Copilot;
artefatos internos `docs/harness/`, `docs/playbooks/success-catalog.yaml`,
`docs/reuse-catalog.yaml`, `scripts/harvest-patterns.sh`,
`specs/011-harness-engineering/`, `specs/014-brownfield-multirepo-context-awareness/`,
`specs/022-nimbuscode-harvest-gateway/`, `.agents/skills/nc-shield/SKILL.md`,
`docs/ai-code-quality-and-observability.md`, `docs/mkt/nimbus-code-product-and-methodology.md`,
`docs/developer-guide.md`) e o `intake.md` original deste assessment.

---

## Próximo handoff

Este documento **não avança sozinho** para a etapa seguinte. Recomenda-se que
o solicitante avalie e decida explicitamente se o próximo passo é:

- `/nc-assess-decide` (ou `/speckit-assess-decide`) — gate de decisão
  obrigatório antes de qualquer shaping de solução, dado que dois riscos
  bloqueantes/condicionantes foram registrados na seção 6 (privacidade/S4 e
  colisão terminológica) e precisam de decisão humana explícita;
- somente após o gate de decisão aprovar o avanço, seguir para
  `/nc-assess-shape` (ou `/speckit-assess-shape`), para desenhar a forma da
  solução (voluntário vs. obrigatório, evento único vs. contínuo, nome final
  do conceito, integração ou não com os catálogos existentes).
