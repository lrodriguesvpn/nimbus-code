# Research de Assessment — Consolidação Corporativa de Harness Individuais (Claude/Cursor)

## Identificação

| Campo | Valor |
|---|---|
| **Slug** | `harness-consolidacao-corporativa` |
| **Data** | 2026-09-22 |
| **Origem** | `/nc-assess-research` (alias de `/speckit-assess-research`), a partir de `intake.md` |
| **Status** | Pesquisa concluída — aguardando decisão de avanço para `/nc-assess-define` |
| **Legenda de evidência** | 🔍 *Evidência real* (fonte citada) · `[ASSUMPTION]` *suposição não verificada* · `[NEEDS CLARIFICATION]` *pergunta em aberto que precisa de resposta humana/levantamento interno* |

---

## 1. Evidências de mercado — "harness consolidation" / prompt library corporativa / configuration management de agentes de IA

Não existe hoje um termo de mercado único e consolidado equivalente a "harness
consolidation" tal como formulado na ideia bruta (consolidar o *relacionamento
pessoal* de cada dev com seu agente de IA). O que existe, e é 🔍 verificável em
documentação oficial dos próprios fornecedores, é um **padrão de três camadas
de configuração hierárquica** (pessoal → repositório/projeto → organização),
que é a aproximação de mercado mais próxima do problema:

### 1.1 Claude Code — memória em camadas (CLAUDE.md)

🔍 A documentação oficial do Claude Code (`https://code.claude.com/docs/en/memory`,
redirecionado a partir de `docs.anthropic.com/en/docs/claude-code/memory`,
consultado em 2026-09-22) define explicitamente três escopos de `CLAUDE.md`,
em ordem de amplitude:

| Escopo | Localização | Quem escreve | Compartilhado com |
|---|---|---|---|
| **Managed policy** (organização) | `/Library/Application Support/ClaudeCode/CLAUDE.md` (macOS), `/etc/claude-code/CLAUDE.md` (Linux/WSL), `C:\Program Files\ClaudeCode\CLAUDE.md` (Windows) | IT/DevOps da empresa | Todos os usuários da organização |
| **User instructions** (pessoal) | `~/.claude/CLAUDE.md` | O próprio dev | Só o dev, em todos os projetos dele |
| **Project instructions** | `CLAUDE.md` no repositório | Time do projeto | Todos que clonam o repo |

Além disso, o Claude Code possui **"auto memory"**: um mecanismo em que o
próprio agente registra automaticamente aprendizados e correções dadas pelo
dev ao longo das sessões (por repositório, compartilhado entre worktrees).

**Leitura crítica para esta ideia**: o mecanismo oficial da Anthropic já
resolve a *distribuição top-down* de instruções organizacionais (IT empurra
padrões para todos os devs). Ele **não resolve** o problema inverso que a
ideia propõe — **capturar bottom-up** o que já está em `~/.claude/CLAUDE.md`
de cada um dos ~60 colaboradores e consolidar isso de volta em conhecimento
institucional. Não há, na documentação oficial, nenhum fluxo de exportação/
agregação de "user instructions" de múltiplos devs para um repositório
central. Isso é evidência de que **a ideia está pedindo algo que o próprio
fornecedor da ferramenta ainda não oferece nativamente** — o que a torna mais
original, mas também mais arriscada de construir sem tooling de terceiros.

### 1.2 Cursor — Project Rules, User Rules, Team Rules

🔍 A documentação oficial do Cursor (`https://cursor.com/docs/rules`,
consultado em 2026-09-22) define **quatro tipos de regras**:

| Tipo | Escopo | Observação |
|---|---|---|
| **Project Rules** | `.cursor/rules/*.mdc`, versionado no repo | Já é institucional por natureza (git) |
| **User Rules** | Global ao ambiente Cursor do dev | Exatamente o "harness pessoal" descrito na ideia — não versionado, não visível a terceiros por padrão |
| **Team Rules** | Gerenciadas centralmente via dashboard | **Somente disponível em planos Team e Enterprise** |
| **AGENTS.md** | Alternativa simples em markdown | Convergindo para o padrão cross-tool `AGENTS.md` |

**Leitura crítica**: o Cursor já **antecipou comercialmente** exatamente o
problema desta ideia — só que como um recurso pago de dashboard corporativo
("Team Rules"), não como um processo de mineração de harness já existentes.
Isso é evidência de mercado forte de que o problema é real e reconhecido pelos
próprios fornecedores, mas a solução deles é "criar regras novas de cima para
baixo", não "descobrir e recuperar o que os 60 devs já construíram
individualmente". `[NEEDS CLARIFICATION]`: a empresa já possui (ou pretende
adquirir) o plano Team/Enterprise do Cursor? Se sim, parte do problema pode
ser resolvida por **compra de feature existente**, não por construção interna
via Nimbus Code — isso muda drasticamente o escopo da ideia.

### 1.3 GitHub Copilot — Personal → Repository → Organization custom instructions

🔍 A documentação oficial (`https://docs.github.com/en/copilot/concepts/prompting/response-customization`,
consultado em 2026-09-22) descreve um modelo de precedência de três camadas
muito similar ao do Claude Code:

- **Personal instructions** (preferências individuais, via GitHub.com);
- **Repository custom instructions** (`.github/copilot-instructions.md`,
  path-specific `*.instructions.md`, ou `AGENTS.md`/`CLAUDE.md`/`GEMINI.md`);
- **Organization custom instructions** (definidas por owners da organização,
  exigem plano Copilot Business/Enterprise, aplicadas a *todos* os membros
  independente de qual repositório estejam usando).

A ordem de precedência documentada é: Personal > Repository > Organization —
ou seja, mesmo a instrução organizacional é a de **menor prioridade
efetiva**, servindo como piso comum, não como substituição do que o
indivíduo/repositório definiu. Isso confirma, em três fornecedores distintos
(Anthropic, Cursor, GitHub), o mesmo padrão arquitetural: **camadas de
herança de configuração, não agregação de conhecimento tácito individual**.

### 1.4 Conclusão da pesquisa de mercado

🔍 O padrão de mercado hoje é "layered configuration inheritance" (pessoal →
projeto → organização), resolvido nativamente pelos três principais
fornecedores (Anthropic, Cursor, GitHub) como **distribuição descendente** de
regras. Nenhum dos três oferece, na documentação pública consultada, um
mecanismo nativo de **mineração ascendente** (personal → organizacional) que
é o núcleo da ideia original. Isso sugere duas leituras possíveis, que devem
ser resolvidas em `/nc-assess-define`:

- (a) a ideia tem valor de diferenciação real porque ataca uma lacuna que os
  próprios fornecedores ainda não cobrem nativamente; ou
- (b) a ideia pode ser parcialmente substituída por **adoção/expansão do uso
  de features comerciais já existentes** (ex.: Cursor Team Rules, GitHub
  Copilot Organization custom instructions) combinada com um processo leve de
  *curadoria* (não de mineração automatizada), o que reduziria drasticamente o
  escopo de construção necessária.

`[ASSUMPTION]` Não foi encontrada, na pesquisa realizada, nenhuma ferramenta
de mercado (open-source ou comercial) especializada especificamente em
"exportar e consolidar automaticamente o CLAUDE.md/.cursor/rules pessoal de N
colaboradores em um catálogo institucional". Isso pode ser um gap real de
mercado, ou pode ser um sinal de que a prática de mercado dominante é resolver
isso por **processo/cultura** (ex.: revisão periódica manual, sessões de
compartilhamento de prompts) em vez de **automação** — recomenda-se pesquisa
adicional dedicada (não coberta neste research, ver `[NEEDS CLARIFICATION]`
abaixo) antes de assumir que "construir uma ferramenta" é a resposta certa.

`[NEEDS CLARIFICATION]` Existem comunidades/artigos de práticas ("AI dotfiles",
"prompt engineering guilds", "AI Center of Excellence playbooks") que tratam
do tema de forma mais informal (blogs de engenharia, talks de conferência)?
A pesquisa via busca textual (DuckDuckGo/Bing) não retornou resultados
utilizáveis nesta sessão (bloqueio anti-bot/CAPTCHA nas duas tentativas) — a
ausência de achado aqui é **limitação da pesquisa**, não uma confirmação de
que essas práticas não existem.

---

## 2. Estado interno já existente no repositório

O repositório já resolve, com maturidade, dois problemas vizinhos — mas
**nenhum dos dois cobre o harness pessoal/individual** que a ideia propõe
consolidar. Mapeamento detalhado:

### 2.1 `docs/harness/harness-catalog.yaml` + `docs/harness/harness-guide.md` + `docs/harness/README.md`

🔍 Cobre exclusivamente **erros, incidentes e retrabalhos catalogados por
feature/bounded_context** (schema `HRN-NNNN`), com gatilhos objetivos de
entrada: incidente em produção, retrabalho > 20% do esforço, decisão
arquitetural revertida, erro de agente documentado. É consultado
obrigatoriamente antes de `/nimbus-code-plan` (protocolo descrito em
`harness-guide.md`, seção "Para Agentes"). **Não captura**: configuração
pessoal de agente, prompts recorrentes, convenções de uso individual — o
"harness" aqui é uma metáfora institucional emprestada de engenharia de teste
(cabo de teste/fixture), não uma referência ao conceito de "harness pessoal"
descrito na ideia bruta (relação dev↔LLM).

Origem: `specs/011-harness-engineering/spec.md` — feature que formalizou o
conceito de "Harness Engineering" no vocabulário Nimbus Code como "instrumentar
o processo de desenvolvimento para capturar, catalogar e propagar aprendizados
de falhas". A ideia nova propõe **reaproveitar o nome, mas estender o
conceito** para um domínio diferente (configuração pessoal de agente, não
lição de incidente) — isso é um risco de **ambiguidade terminológica** que
`/nc-assess-define` deve resolver explicitamente (ex.: renomear a nova
iniciativa para evitar colisão semântica com "Harness Catalog" já existente).

### 2.2 `docs/playbooks/success-catalog.yaml`

🔍 Catálogo estruturalmente análogo ao harness-catalog (schema `SUC-NNNN`),
mas para **o que funcionou bem** por feature/decisão — não por indivíduo.
Mesmo padrão de consulta obrigatória antes de `/nimbus-code-plan`. Novamente:
granularidade de *feature*, não de *relacionamento pessoal dev↔agente*.

### 2.3 `docs/reuse-catalog.yaml` + `scripts/harvest-patterns.sh`

🔍 Este é o achado interno **mais relevante e mais próximo tecnicamente** da
ideia, e deveria ser o principal precedente de design a considerar em
`/nc-assess-define`:

- `docs/reuse-catalog.yaml` cataloga **padrões técnicos reutilizáveis**
  (arquitetura, interfaces, decisões), não harness de agente.
- `scripts/harvest-patterns.sh` (originado em
  `specs/014-brownfield-multirepo-context-awareness/`) já é uma **automação
  de mineração** que varre um repositório e propõe entradas de catálogo via
  chamada a um endpoint LLM configurável. Pontos de design que já resolvem,
  por precedente, exatamente as perguntas em aberto que a ideia de harness
  pessoal ainda não respondeu:
  - **Allowlist estrita de metadados estruturais**: o script varre apenas
    nomes de arquivo, assinaturas de método/classe/interface, anotações —
    **nunca corpo de método, string literal ou dado de runtime** (comentário
    no próprio script, `ADL-004`). Este é o precedente de design mais direto
    para mitigar o risco de PII/segredos citado na seção 3.
  - **Nunca roda em CI, apenas on-demand por humano** (`FR-011`, comentado no
    cabeçalho do script) — outro precedente de governança direta para uma
    futura consolidação de harness pessoal.
  - **Escreve direto no catálogo, usando o diff do Git como gate de
    revisão** (`ADL-003`) — em vez de um pipeline de aprovação separado.
  - `docs/comparisons/understand-anything-vs-nimbus-harvest.md` já documenta,
    em comparação com uma ferramenta de mercado (Understand-Anything), que a
    escolha de design do Nimbus Harvest é precisamente **"Extração Restrita
    de Assinaturas (Sem PII/Segredos)"** como diferencial de proteção de
    dados.
  - `specs/022-nimbuscode-harvest-gateway/` estendeu esse mecanismo para um
    gateway multicloud (Azure AI, Vertex AI, AWS Bedrock) — e foi classificado
    como **complexidade S4** ("arquitetura, segurança, dados sensíveis ou
    integração crítica"), com justificativa explícita de que é "infraestrutura
    crítica compartilhada... decisão de segurança/privacidade com impacto
    organizacional", exigindo revisão humana obrigatória antes de qualquer
    implementação.

**Leitura crítica**: se a consolidação de harness pessoal seguir um desenho
semelhante ao `harvest-patterns.sh` (extrair apenas metadados estruturais,
nunca o conteúdo literal de prompts/instruções pessoais), o risco de
vazamento de dados sensíveis diminui bastante — mas isso também **reduz o
valor da consolidação**, porque o conteúdo mais valioso de um harness pessoal
(o texto da instrução, do prompt, da convenção) é exatamente o "corpo" que o
padrão de harvest institucional hoje evita capturar. Este é um **trade-off
central** que `/nc-assess-define` precisa endereçar explicitamente: não dá
para copiar o precedente 1:1 sem perder o valor central da ideia.

### 2.4 Gap confirmado (harness pessoal vs. harness por feature)

🔍 Confirma-se, com evidência direta dos três catálogos e da spec de origem, o
gap identificado no `intake.md`: **nenhum artefato institucional atual
captura o relacionamento tácito dev↔agente** — não há schema, gatilho de
entrada, nem processo de consolidação para isso hoje. A ideia é, de fato, algo
novo em relação ao que o Nimbus Code já resolve — não uma duplicação.

---

## 3. Riscos de privacidade, segurança e propriedade intelectual

Esta é a dimensão de maior risco da ideia, e deve ser tratada como
**pré-requisito de design**, não como detalhe de implementação posterior.

🔍 O projeto já define, em `docs/ai-code-quality-and-observability.md` (seção
"Não-Negociáveis vs. Decisões Justificáveis") e em `.agents/skills/nc-shield/SKILL.md`,
um **Security & DevSecOps Gate** com 6 itens Não-Negociáveis, entre eles:
segredos fora do código (cofre/Key Vault), mínimo privilégio/RBAC, e
TLS/criptografia em trânsito e repouso. Qualquer mecanismo de consolidação de
harness pessoal que envolva **leitura de arquivos de configuração locais**
(`~/.claude/CLAUDE.md`, `.cursor/rules`, histórico de prompts) precisa ser
auditado por este gate antes de qualquer implementação, porque:

- Prompts e instruções pessoais podem conter, por natureza, **dados de
  clientes, nomes de projetos confidenciais, trechos de código proprietário,
  ou até credenciais coladas acidentalmente em um prompt** — um padrão de
  risco categoricamente diferente do que `harvest-patterns.sh` mitiga hoje
  (que varre apenas *assinaturas estruturais* de código versionado em um
  repositório, não *texto livre pessoal* escrito por um humano em uma sessão
  de chat).
- 🔍 O documento `docs/mkt/nimbus-code-product-and-methodology.md` e o
  `docs/developer-guide.md` confirmam que **LGPD** é o marco de compliance de
  referência do processo Nimbus Code (bloco obrigatório da entrevista de
  descoberta: Negócio, Infraestrutura, Segurança, LGPD). Qualquer coleta de
  harness pessoal que envolva dados pessoais de terceiros (nomes de clientes
  em prompts, por exemplo) é, por definição, tratamento de dado pessoal sob
  LGPD e precisa de base legal, finalidade declarada e possivelmente
  anonimização antes de qualquer consolidação.
- Por analogia direta com `specs/022-nimbuscode-harvest-gateway/` (classificado
  S4, com "revisão humana obrigatória antes de qualquer implementação" por
  processar metadados de código-fonte enviados a provedores de IA externos),
  é razoável antecipar — `[ASSUMPTION]`, a confirmar formalmente em
  `/nc-assess-define` e no `plan.md` da eventual feature — que uma iniciativa
  de consolidação de harness *pessoal* (potencialmente mais sensível que
  metadados estruturais de código) também seria classificada **S4** na régua
  de complexidade do Nimbus Code, com os artefatos obrigatórios
  correspondentes (`impact-map.md` + revisão humana) e sem opção de burlar a
  exigência de revisão humana via ADR/ADL.
- Esta iniciativa **precisará de avaliação formal do `nc-shield`** (agente
  DevSecOps Guardian) em fase de `/nc-assess-plan` ou `/nimbus-code-plan`,
  especificamente quanto a: (a) onde os dados de harness consolidados ficam
  armazenados e por quanto tempo; (b) se há necessidade de anonimização/
  redação automática antes da consolidação; (c) processo de retenção/expurgo
  quando um colaborador sai da empresa (pergunta já registrada como
  `[NEEDS CLARIFICATION]` no `intake.md` e reafirmada aqui).

`[NEEDS CLARIFICATION]` Existe uma política de retenção de dados de sessão de
IA já definida na empresa (fora do escopo do Nimbus Code) que já rege como
prompts de Claude Code/Cursor são retidos ou descartados hoje? Se sim, ela
deveria ser o piso mínimo de qualquer consolidação institucional.

`[NEEDS CLARIFICATION]` A consolidação prevista envolveria enviar conteúdo de
harness pessoal a um LLM de terceiros (como o `harvest-patterns.sh` faz para
metadados de código) para normalizar/resumir o conteúdo? Se sim, isso
adiciona uma segunda camada de risco (dado pessoal sendo processado por um
provedor externo de IA), que precisa de avaliação de DPA (Data Processing
Agreement) com o fornecedor, não coberta por esta pesquisa.

---

## 4. Dados quantitativos sobre os ~60 colaboradores

Nenhum número quantitativo real foi levantado ou deve ser assumido nesta
pesquisa. Os números abaixo são **perguntas em aberto** — `[NEEDS
CLARIFICATION]` — a responder por levantamento interno (survey curto ou
entrevistas amostrais), não fatos:

- `[NEEDS CLARIFICATION]` Quantos dos ~60 colaboradores usam Claude Code,
  quantos usam Cursor, e quantos usam ambos simultaneamente? (já registrado no
  `intake.md`, reforçado aqui como pré-requisito de dimensionamento antes de
  `/nc-assess-plan`).
- `[NEEDS CLARIFICATION]` Qual a distribuição de maturidade de uso — devs com
  harness pessoal extenso e maduro vs. devs que mal customizam o agente?
  (afeta diretamente o ROI esperado da consolidação: se a maioria não tem
  harness relevante, o esforço de construir um pipeline de consolidação pode
  não se justificar).
- `[NEEDS CLARIFICATION]` Qual a taxa de rotatividade (turnover) atual da
  empresa nesse grupo de 60 colaboradores? É o principal dado que sustentaria
  ou refutaria a urgência declarada na ideia ("não perder esse conhecimento
  quando um dev sai") — sem esse número, a motivação de perda de conhecimento
  por rotatividade é uma **hipótese razoável, mas não uma evidência**.
- `[NEEDS CLARIFICATION]` Quantos projetos/squads hoje já adotam o Nimbus Code
  formalmente vs. quantos ainda não adotam? A ideia menciona explicitamente
  que a consolidação deveria funcionar "mesmo antes de todos os projetos
  usarem o Nimbus Code" — isso pressupõe um número de squads fora do processo
  formal que não foi quantificado.

`[ASSUMPTION]` Esta pesquisa **não** assume nenhum valor específico para os
números acima. Qualquer estimativa numérica sobre adoção, maturidade de
harness ou turnover que venha a aparecer em documentos futuros do assessment
deve citar a fonte do levantamento interno realizado, não esta pesquisa.

---

## 5. Riscos e desafios de adoção

### 5.1 Heterogeneidade de ferramentas e formatos

🔍 Confirmado pela pesquisa de mercado (seção 1): Claude Code, Cursor e GitHub
Copilot usam **formatos de arquivo, escopos e semânticas de precedência
diferentes** entre si (`CLAUDE.md` vs. `.cursor/rules/*.mdc` com frontmatter
`alwaysApply`/`globs`/`description` vs. `.github/copilot-instructions.md` +
`*.instructions.md` + `AGENTS.md`). Um mecanismo de consolidação precisaria de
uma camada de normalização (schema comum) capaz de representar regras
"sempre aplicar", "aplicar por padrão de arquivo" e "aplicar sob demanda" de
forma equivalente entre ferramentas — não é uma simples concatenação de
arquivos. `[ASSUMPTION]` A convergência recente do mercado para `AGENTS.md`
como formato comum entre ferramentas (citado tanto na doc do GitHub Copilot
quanto na do Cursor) pode reduzir esse atrito ao longo do tempo, mas não deve
ser assumida como solução pronta hoje.

### 5.2 Ambiguidade terminológica interna

🔍 Como descrito na seção 2.1, o termo "harness" já tem um significado
institucional consolidado no Nimbus Code (`harness-catalog.yaml` = catálogo de
erros/incidentes por feature). Reaproveitar o mesmo termo para "configuração
pessoal de agente" cria risco real de confusão entre agentes e humanos que já
seguem o protocolo de consulta obrigatória descrito em `harness-guide.md`.
Recomenda-se que `/nc-assess-define` avalie um nome distinto para este novo
conceito (ex.: "perfil de agente", "configuração pessoal consolidada",
"agent profile catalog") para evitar colisão semântica.

### 5.3 Resistência de devs a expor prompts/configurações pessoais

`[ASSUMPTION]` Não há dado interno coletado sobre o apetite real dos ~60
colaboradores para compartilhar seus harness pessoais (ver pergunta em aberto
na seção 4). É razoável antecipar, por analogia com a literatura geral de
gestão do conhecimento tácito (a dificuldade de "codificar tácito em
explícito" é um tema clássico, não específico de IA), que parte da resistência
viria de:
- receio de que o conteúdo revele atalhos "não oficiais" ou desvios do
  processo formal;
- receio de exposição de dados de clientes/projetos sensíveis presentes no
  histórico (ver seção 3);
- percepção de perda de vantagem pessoal ("meu jeito de usar o Claude é o meu
  diferencial") se o conteúdo virar propriedade institucional.

Uma consolidação **obrigatória** (top-down) tende a gerar mais resistência e
risco de conteúdo de baixa qualidade (preenchimento superficial só para
cumprir) do que uma consolidação **voluntária com incentivo claro** (ex.:
reconhecimento, redução de esforço de onboarding do próprio contribuidor).
Esta é uma decisão de desenho de processo a ser tomada em `/nc-assess-define`,
não uma conclusão desta pesquisa.

### 5.4 Custo de manter um pipeline de consolidação

🔍 Por analogia direta com o precedente interno mais próximo
(`scripts/harvest-patterns.sh` + `specs/022-nimbuscode-harvest-gateway/`), um
mecanismo de consolidação de harness pessoal que envolva chamadas a LLM para
normalizar/resumir conteúdo herdaria custos operacionais reais e já
documentados no repositório: dependência de gateway multicloud, custo de
tokens por chamada, necessidade de observabilidade de custo/uso por chamada
(ver tabela de SLO do gateway, que já define latência p99, taxa de erro e
disponibilidade-alvo para esse tipo de serviço). Isso não é um custo trivial
de "rodar um script uma vez" — se o processo for contínuo (novo dev entra,
harness incorporado, conforme uma das opções listadas no `intake.md`), o
custo se torna recorrente e deve ser modelado com rigor equivalente ao de
qualquer outra integração S3/S4 do Nimbus Code.

### 5.5 Evento único vs. processo contínuo

`[NEEDS CLARIFICATION]` (reafirma pergunta já presente no `intake.md`): a
decisão entre "fotografia única dos 60 harness hoje" e "processo contínuo de
onboarding/offboarding" muda completamente o desenho técnico e o custo
recorrente. Uma fotografia única é um esforço finito e mais barato de
justificar mesmo sem adoção formal do Nimbus Code em todos os projetos; um
processo contínuo exige integração ao ciclo de vida de RH (onboarding/
offboarding) e, portanto, teria interseção com sistemas e processos fora do
escopo técnico atual do Nimbus Code.

---

## 6. Síntese e recomendação de leitura para `/nc-assess-define`

| Dimensão | O que a pesquisa confirma | O que fica em aberto |
|---|---|---|
| Mercado | Padrão de 3 camadas (pessoal→projeto→org) já existe nos 3 fornecedores principais; nenhum resolve mineração bottom-up nativamente; Cursor "Team Rules" é o mais próximo, mas pago e top-down | Se a empresa já tem/pode ter Cursor Team/Enterprise, parte do escopo pode ser resolvida por compra, não construção |
| Interno | `harness-catalog.yaml`, `success-catalog.yaml`, `reuse-catalog.yaml` e `harvest-patterns.sh` cobrem domínios vizinhos, mas nenhum cobre harness pessoal; `harvest-patterns.sh` é o precedente de design técnico mais próximo (allowlist estrita, on-demand, nunca em CI) | Nome da iniciativa (evitar colisão com "harness" institucional já existente) |
| Segurança/Privacidade | Security & DevSecOps Gate e LGPD já são marcos obrigatórios do processo; precedente `022-nimbuscode-harvest-gateway` (S4) sugere que esta iniciativa também tende a ser S4 | Confirmação formal da classificação de complexidade; política de retenção/expurgo; necessidade de DPA se envolver LLM de terceiros |
| Dados quantitativos | Nenhum número deve ser assumido | Uso real de Claude/Cursor entre os 60, turnover, % de squads sem Nimbus Code formal |
| Adoção | Heterogeneidade de formato entre ferramentas é real e documentada; custo de pipeline contínuo é análogo a uma integração S3/S4 já existente no repo | Apetite real dos devs (voluntário vs. obrigatório); evento único vs. processo contínuo |

**Recomendação**: avançar para `/nc-assess-define` (ou seu alias
`/nc-assess-define`) tratando como pré-requisitos de definição, não de
pesquisa adicional:
1. decidir explicitamente o nome/termo para não colidir com "Harness Catalog"
   institucional já existente;
2. tratar a dimensão de privacidade/LGPD como requisito de design desde a
   primeira definição de escopo, não como revisão posterior;
3. registrar as perguntas quantitativas da seção 4 como ação de descoberta
   paralela (survey interno curto), não como bloqueio do assessment.

---

## Fontes consultadas

- 🔍 `https://code.claude.com/docs/en/memory` (Anthropic/Claude Code — memória
  em camadas, CLAUDE.md, auto memory), consultado em 2026-09-22.
- 🔍 `https://cursor.com/docs/rules` (Cursor — Project/User/Team Rules,
  AGENTS.md), consultado em 2026-09-22.
- 🔍 `https://docs.github.com/en/copilot/concepts/prompting/response-customization`
  (GitHub Copilot — Personal/Repository/Organization custom instructions e
  ordem de precedência), consultado em 2026-09-22.
- 🔍 `.specify/assessments/harness-consolidacao-corporativa/intake.md`
  (documento de origem deste assessment).
- 🔍 `docs/harness/harness-catalog.yaml`, `docs/harness/harness-guide.md`,
  `docs/harness/README.md`, `specs/011-harness-engineering/spec.md`.
- 🔍 `docs/playbooks/success-catalog.yaml`.
- 🔍 `docs/reuse-catalog.yaml`, `scripts/harvest-patterns.sh`,
  `specs/014-brownfield-multirepo-context-awareness/spec.md`.
- 🔍 `specs/022-nimbuscode-harvest-gateway/spec.md`.
- 🔍 `docs/comparisons/understand-anything-vs-nimbus-harvest.md`.
- 🔍 `.agents/skills/nc-shield/SKILL.md`, `docs/ai-code-quality-and-observability.md`
  (Security & DevSecOps Gate, escala de complexidade S0–S4, Não-Negociáveis).
- 🔍 `docs/mkt/nimbus-code-product-and-methodology.md`, `docs/developer-guide.md`
  (referências a LGPD como marco de compliance do processo Nimbus Code).
- Tentativas sem sucesso (limitação da pesquisa, não conclusão de ausência de
  achado): busca textual via DuckDuckGo e Bing sobre "prompt library
  corporativa" / práticas informais de mercado — bloqueadas por
  anti-bot/CAPTCHA na sessão desta pesquisa.

---

## Próximo handoff

Esta pesquisa **não avança sozinha** para a etapa seguinte. Recomenda-se que o
solicitante avalie e decida explicitamente se o próximo passo é:

- `/nc-assess-define` (ou `/speckit-assess-define`) — para formalizar
  problema, público, métricas de sucesso e escopo, usando esta pesquisa e o
  `intake.md` como insumos, resolvendo em particular a questão de nomenclatura
  (seção 5.2) e o desenho de privacidade (seção 3) antes de detalhar solução.
