# Decision — Consolidação Corporativa de Harness Individuais (Claude/Cursor)

**Slug**: `harness-consolidacao-corporativa`
**Data**: 2026-09-22
**Agente**: NC-Assess-Decide
**Baseado em**: `intake.md`, `research.md`, `problem.md` (não há `concept.md` neste ciclo — ver seção "Por que não avançar direto para shape/spec")

---

## Veredito: **Needs Clarification**

O problema é real, não-duplicado e bem definido (`problem.md` demonstra, com
evidência direta, que nenhum artefato institucional atual — `harness-catalog.yaml`,
`success-catalog.yaml`, `reuse-catalog.yaml` — cobre o relacionamento tácito
dev↔agente). Mas há **quatro incertezas críticas**, três delas de natureza
decisória (não apenas de dado factual), que impedem tanto um Go direto para
`/nc-spec`/`/speckit-specify` quanto um Kill definitivo. Cada uma é avaliada
explicitamente abaixo, na ordem em que foi sinalizada.

---

## 1. Risco S4 de privacidade/LGPD — bloqueante de **design**, não de existência da ideia

**Avaliação**: nem Kill nem Go incondicional. É uma condição de avanço.

`research.md` (seção 3) e `problem.md` (seção 6.1) já estabelecem, por
analogia direta e razoável com `specs/022-nimbuscode-harvest-gateway/`
(também S4, "revisão humana obrigatória antes de qualquer implementação"),
que esta iniciativa muito provavelmente também seria classificada **S4**. A
diferença importante — e que os dois documentos já registram com honestidade
— é que o precedente do harvest-gateway mitiga risco varrendo **apenas
metadados estruturais de código versionado** (nunca corpo de método, string
literal ou texto livre), enquanto o harness pessoal é, por definição,
**exatamente o texto livre que esse precedente evita capturar**. Isso não
invalida a ideia, mas significa que **copiar 1:1 o desenho de
`harvest-patterns.sh` destrói o valor central da proposta**.

Precedente S4 no Nimbus Code não significa "matar a ideia" — significa
"nenhuma implementação começa sem `impact-map.md`, revisão humana obrigatória
e avaliação formal do `nc-shield` antes de qualquer construção". Isso é
compatível com um Go condicional, **desde que** as seguintes decisões sejam
tomadas por quem tem mandato para isso (não pelo esquadrão de agentes
sozinho):

- Modelo de captura **opt-in explícito**, nunca obrigatório/automatizado por
  varredura silenciosa de `~/.claude/CLAUDE.md` ou `.cursor/rules` sem
  consentimento do colaborador;
- Necessidade (ou não) de **redação/anonimização** de dados de cliente,
  segredos e PII antes de qualquer consolidação — e por quem/como isso é
  auditado;
- Se há envio de conteúdo a LLM de terceiros para normalizar/resumir (como
  `harvest-patterns.sh` faz para metadados) — se sim, é uma **segunda camada
  de risco** que exige avaliação de DPA com o fornecedor, hoje não coberta;
- Política de retenção/expurgo quando um colaborador sai da empresa.

**Conclusão do ponto 1**: não é motivo de Kill (o risco é do mesmo tipo já
aceito e operado no repositório via `022-nimbuscode-harvest-gateway`), mas
**bloqueia qualquer Go incondicional**. É uma pré-condição de design a
resolver com Segurança/Jurídico/DPO antes de `/nc-spec`.

---

## 2. Colisão terminológica com "harness" institucional — bloqueante de **nomenclatura**, resolvível rapidamente

**Avaliação**: não bloqueia a existência da ideia, mas bloqueia a criação de
qualquer artefato formal (spec, catálogo, preset) sob o nome atual.

O termo "harness" já é vocabulário institucional fixo e operacional no Nimbus
Code — `docs/harness/harness-catalog.yaml` é consultado obrigatoriamente por
agentes antes de `/nimbus-code-plan` (protocolo descrito em
`harness-guide.md`). Reaproveitar o mesmo termo para "configuração pessoal de
agente" (um conceito de natureza diferente: relacionamento tácito dev↔LLM,
não catálogo de erros/acertos por feature) criaria ambiguidade real e
imediata para agentes e humanos que já seguem esse protocolo.

Diferente do ponto 1, este é um risco **barato e rápido de mitigar** — não
exige pesquisa nem aprovação externa, apenas uma decisão de nomenclatura (ex.:
"perfil de agente pessoal", "agent profile", "configuração individual
consolidada"). Não deveria, por si só, gerar um ciclo inteiro de reavaliação,
mas **deve ser resolvido antes de abrir qualquer spec formal**, para que o
próprio artefato de especificação já nasça com o nome correto e não precise
ser renomeado depois de já referenciado em código/catálogos.

**Conclusão do ponto 2**: bloqueante de baixo custo. Deve ser resolvido como
primeiro passo do próximo ciclo (mesmo que informalmente, por decisão do
solicitante/esquadrão), não como pesquisa adicional.

---

## 3. Ausência de baseline quantitativo real — **não bloqueante de Go**, mas bloqueante de **dimensionamento de investimento**

**Avaliação**: não é motivo de Needs Clarification isolado. Concordo com a
leitura que o próprio `problem.md` já antecipa (seção 4.1): os placeholders
(quantos usam Claude/Cursor, turnover real, distribuição de maturidade de
harness) são, em geral, o tipo de dado que se resolve **dentro** do ciclo
formal de spec-driven development — por exemplo, na entrevista de descoberta
obrigatória (`Negócio, Infraestrutura, Segurança, LGPD`) que já faz parte do
processo Nimbus Code, ou como uma tarefa de pesquisa paralela e leve (survey
interno curto), sem travar o assessment.

A exceção é a pergunta sobre **turnover real**: ela sustenta diretamente a
motivação central declarada na ideia bruta ("não perder esse conhecimento
quando um dev sai"). Sem nenhuma evidência de que a rotatividade é
materialmente relevante, o dimensionamento do esforço (evento único barato vs.
processo contínuo caro, conforme `research.md` seção 5.5) fica sem uma âncora
objetiva de urgência. Isto não invalida o problema (as outras dores —
reinvenção, inconsistência de qualidade, falta de feedback loop para o
próprio Nimbus Code — seguem válidas independentemente do turnover), mas deve
condicionar **qual variante** de solução se persegue primeiro.

**Conclusão do ponto 3**: não bloqueante para decidir avançar o assessment,
mas deve entrar explicitamente como pergunta de descoberta no próximo ciclo
formal (interview de `/nc-spec` ou etapa equivalente), não como pré-requisito
para reabrir este gate.

---

## 4. Sobreposição com `scripts/harvest-patterns.sh` — bloqueante de **arquitetura/escopo**, precisa de decisão de shape antes de spec

**Avaliação**: é o ponto que mais pesa contra um Go direto para `/nc-spec`.

`research.md` (seção 2.3) já identifica `scripts/harvest-patterns.sh` como "o
principal precedente de design a considerar" — não apenas um artefato
relacionado, mas o mecanismo tecnicamente mais próximo já existente e
operacional (allowlist estrita de metadados, nunca roda em CI, escreve
direto no catálogo com o diff do Git como gate de revisão). Isso levanta uma
pergunta de arquitetura que **ainda não foi respondida em nenhum dos três
documentos**: a nova iniciativa deveria ser (a) uma extensão/variante do
`harvest-patterns.sh` já existente, adaptando seu modelo de allowlist e
governança para um novo tipo de fonte (harness pessoal em vez de código
versionado), ou (b) um pipeline paralelo e independente?

Essa não é uma pergunta que se responde durante a redação de uma spec — ela
**muda o desenho da solução antes mesmo de a spec ser escrita** (reuso de
componente institucional existente vs. construção de algo novo do zero, com
implicações diretas de custo, conforme `research.md` seção 5.4: um pipeline
contínuo herdaria custo operacional real e recorrente, análogo ao já
documentado para o gateway multicloud). É, por natureza, uma decisão de
**shape** (`/nc-assess-shape`), não de spec.

**Conclusão do ponto 4**: bloqueante para pular direto a `/nc-spec`. Não é
bloqueante para a existência da ideia — é evidência de que existe um caminho
de menor custo (estender infraestrutura já madura) que precisa ser avaliado
antes de comprometer orçamento de engenharia em um pipeline novo.

---

## Por que não é Kill

Nenhum dos quatro pontos invalida o problema em si:

- O problema (perda de conhecimento tácito dev↔agente, sem mecanismo de
  captura) é real, confirmado por evidência de mercado (`research.md`,
  seção 1: nem Anthropic, nem Cursor, nem GitHub resolvem nativamente a
  mineração bottom-up) e por evidência interna (nenhum catálogo institucional
  cobre esse nível de conhecimento).
- O risco de privacidade (ponto 1) é do mesmo tipo já aceito e operado pelo
  Nimbus Code em `022-nimbuscode-harvest-gateway` — S4 é gerenciável, não é
  motivo de descarte.
- A colisão terminológica (ponto 2) é trivialmente corrigível.
- A ausência de baseline (ponto 3) é normal nesta fase e resolvível dentro do
  próprio ciclo formal.
- A sobreposição com `harvest-patterns.sh` (ponto 4) é uma oportunidade de
  **reduzir custo e risco reaproveitando infraestrutura madura**, não um
  motivo para descartar a ideia.

## Por que não é Go direto para `/nc-spec`

Forçar um Go agora empurraria para dentro da spec formal três decisões que
não são de engenharia de especificação, e sim de **política/arquitetura
prévia**:
1. aprovação de Segurança/Jurídico/DPO sobre o modelo de captura de dados
   pessoais (opt-in, anonimização, retenção) — decisão que o esquadrão de
   agentes não pode tomar sozinho, pelo mesmo padrão já aplicado no ciclo
   `qwen-selfhost-ide-agnostica`;
2. decisão de nomenclatura para evitar que a spec nasça colidindo com
   "harness" institucional já em uso operacional;
3. decisão de arquitetura (estender `harvest-patterns.sh` vs. pipeline novo)
   que muda o escopo e custo da spec antes mesmo de ela ser escrita.

---

## Condições/pré-requisitos antes de reavaliar (Needs Clarification)

Estas perguntas precisam de resposta humana/decisão de negócio — não são
tarefas que o esquadrão de agentes resolve sozinho:

1. **Nomenclatura**: qual nome substitui "harness pessoal/individual" para
   não colidir com `harness-catalog.yaml`? (decisão rápida, pode ser
   resolvida em horas por quem patrocina a ideia).
2. **Modelo de captura de dados sensíveis**: Segurança/Jurídico/DPO aprovam
   (ou aprovam com condições, ou reprovam) um modelo de captura opt-in de
   conteúdo de harness pessoal, incluindo eventual necessidade de
   anonimização/redação e política de retenção/expurgo? Há necessidade de DPA
   se houver envio a LLM de terceiros para normalização?
3. **Decisão de arquitetura de reuso**: a iniciativa deve ser conduzida como
   extensão de `scripts/harvest-patterns.sh` (adaptando allowlist e
   governança para uma nova fonte) ou como pipeline paralelo? Esta decisão
   deveria ser tomada em um `/nc-assess-shape` leve, com as opções desenhadas
   lado a lado (custo/risco/valor), antes de qualquer `/nc-spec`.
4. **Turnover real**: existe dado (mesmo aproximado) de rotatividade dos ~60
   colaboradores que sustente a urgência de "não perder conhecimento na
   saída"? Sem isso, recomenda-se tratar a motivação de perda por rotatividade
   como hipótese razoável, não como fato, ao dimensionar prioridade.

As perguntas quantitativas remanescentes (quantos usam Claude/Cursor,
distribuição de maturidade de harness) **não bloqueiam** a reavaliação — podem
ser resolvidas em paralelo, durante a etapa de shape/spec, como já apontado no
ponto 3 acima.

---

## Handoff recomendado

- **Não** executar `/nc-spec` ou `/speckit-specify` neste momento.
- Próximo passo recomendado: `/nc-assess-shape` (ou `/speckit-assess-shape`)
  — mas **condicionado** a que, em paralelo, o solicitante já encaminhe as
  perguntas 1 e 2 acima (nomenclatura e aprovação de Segurança/Jurídico/DPO)
  aos respectivos responsáveis, pelo mesmo padrão de ação imediata já usado
  no ciclo `qwen-selfhost-ide-agnostica` (abrir uma comunicação formal com
  o(s) stakeholder(s) responsável(is), sem esperar o parecer para começar o
  shaping técnico das opções de arquitetura, que não depende dessa
  aprovação).
- O `/nc-assess-shape` deveria produzir explicitamente ao menos duas opções
  comparáveis: (A) extensão de `scripts/harvest-patterns.sh` com allowlist
  adaptada para harness pessoal e opt-in explícito; (B) pipeline paralelo
  dedicado — com custo, risco e valor lado a lado, para que o patrocinador
  decida com dados objetivos.
- Quando (1) o nome estiver decidido, (2) houver parecer de
  Segurança/Jurídico/DPO (aprovado, aprovado com condições, ou reprovado) e
  (3) o `concept.md` do shape estiver pronto com as opções comparadas, este
  ciclo de assessment deve ser **reaberto e reavaliado** em um novo
  `/nc-assess-decide` — nesse momento, se aprovado, a opção escolhida pode
  virar um `/nc-spec` (ou `/speckit-specify`) formal.

---

## Atualização — Respostas do solicitante (2026-09-22)

O solicitante respondeu diretamente às 4 perguntas abertas da seção anterior.
Três delas ficam **encaminhadas/resolvidas**; a quarta **escala o escopo
técnico da iniciativa** e precisa ser tratada como opção adicional (não
prevista originalmente) no `/nc-assess-shape`.

1. **Base legal (pergunta 2 original)** — ✅ Encaminhado. Todos os
   colaboradores e clientes da VPN já possuem NDA vigente; o solicitante vai
   incluir uma cláusula específica autorizando o armazenamento de
   prompts/harness agêntico como parte desse NDA. **Ainda pendente**: validação
   formal de Jurídico/DPO sobre a redação da cláusula e sobre política de
   retenção/expurgo (o NDA cobre a permissão de guardar o dado; não define,
   por si só, anonimização, prazo de retenção nem escopo de acesso interno —
   isso continua como item de shape/spec, não como bloqueio de viabilidade).
2. **Nomenclatura (pergunta 1 original)** — ✅ Proposta recebida: **"Harness
   Agêntico IDE"** para o conceito individual/pessoal (por dev/IDE), reservando
   o nome **"Harness Corporativo"** para o ativo institucional pós-triagem —
   dois nomes distintos, o que já resolve a colisão terminológica apontada
   nesta decisão. O solicitante pediu também sugestões de nomes de mercado
   alternativos; isso será tratado como parte do `concept.md` do shape (seção
   de nomenclatura), não decidido unilateralmente aqui.
3. **Dado quantitativo de ferramentas (pergunta 4 original, parcial)** — ✅
   Resolvido. Dos ~60 colaboradores: **60 usam Claude** (Claude Code) e um
   subconjunto de **~10 também usa Cursor.AI** (uso combinado, não exclusivo).
   Isso simplifica a superfície de ferramentas do shape — não é necessário
   desenhar para "N ferramentas heterogêneas", e sim para **Claude Code como
   fonte primária universal + Cursor.AI como fonte secundária parcial**.
   Turnover real segue **não respondido** — mantém-se como hipótese razoável,
   não fato, ao dimensionar prioridade.
4. **Escopo de captura (pergunta 3 original) — ⚠️ ESCALA O RISCO, não apenas
   responde.** O solicitante esclareceu que a intenção **não** é estender
   `scripts/harvest-patterns.sh` no seu modelo atual (que varre apenas a
   *fonte de um repositório já clonado*, sob invocação manual e on-demand).
   A intenção real é uma **terceira opção**, não modelada nas opções A/B
   originais deste decision: um mecanismo que **varre automaticamente os
   computadores de todos os colaboradores da empresa** (não apenas repos),
   localizando e coletando os arquivos de configuração/harness agêntico local
   (ex.: `CLAUDE.md`, memórias, regras do Cursor, histórico de prompts) —
   agregando-os para uma **triagem humana do "Comitê Nimbus Code"**, que
   decide o que é promovido de "Harness Agêntico IDE" (pessoal) para
   **"Harness Corporativo"** (institucional, distribuído junto ao próprio
   template do Nimbus Code). Este último conceito — "Harness Corporativo" como
   artefato de primeira classe distribuído pelo template — **não existe hoje
   no Nimbus Code** e precisa ser desenhado do zero.

   **Por que isso escala o risco em vez de apenas resolver a pergunta 3**:
   variar de "ler o histórico de commits de um repo já clonado" para "escanear
   automaticamente todo computador de todo colaborador" muda a natureza do
   controle de S4 — não é mais um script on-demand com allowlist de metadados
   de repositório, é um **agente com presença permanente no endpoint** lendo
   arquivos de configuração pessoal (que podem conter prompts com dados de
   cliente, segredos, credenciais coladas acidentalmente). Isso deve ser
   tratado no `/nc-assess-shape` como uma opção explícita **(C)** ao lado de
   (A) e (B), com uma variante adicional de captura **não automática/opt-in
   ativo** (o colaborador aciona a exportação, em vez de um agente residente
   monitorando o endpoint) como alternativa de menor risco a ser comparada
   lado a lado. `/nc-shield` deve ser consultado no shape antes de qualquer
   comprometimento de arquitetura para a opção (C).

**Efeito sobre o veredito**: mantém-se **Needs Clarification** — os pontos 1-3
avançaram o suficiente para liberar o `/nc-assess-shape`, mas o ponto 4 deve
ser modelado (não pressuposto) como uma de várias opções de captura, com
`/nc-shield` envolvido desde o desenho inicial das opções, não apenas na
revisão final.

---

## Atualização — Reavaliação do Gate de Decisão (2026-09-22, ciclo 2)

**Baseado em**: as duas seções anteriores deste `decision.md`, mais
`concept.md` completo (opções A/B/C comparadas, seção 0 "o que já está
resolvido", e seção 6 "Mecânica Detalhada da Opção A e Posicionamento") e a
confirmação direta do solicitante sobre base legal, nomenclatura, dado
quantitativo de ferramentas e arquitetura de captura escolhida.

### Veredito atualizado: ✅ **GO CONDICIONAL** — escopo restrito à Opção A

A ideia é aprovada para avançar ao ciclo formal (`/nc-intake` → `/nc-spec`),
com escopo explicitamente limitado à **Opção A** de `concept.md` (extensão de
`scripts/harvest-patterns.sh`, com escrita sempre redirecionada a um
repositório central dedicado, nunca ao repo do projeto de trabalho, e modelo
de duas etapas para eventual redistribuição pós-promoção). As Opções B e C
permanecem fora deste handoff, exatamente como já registrado na seção 5 de
`concept.md`.

### Por que os quatro pontos que geravam "Needs Clarification" estão agora resolvidos ou reclassificados

| # | Ponto original (ciclo 1) | Status agora | Reclassificação |
|---|---|---|---|
| 1 | Risco S4 de privacidade/LGPD — bloqueante de *design* | **Modelo de captura decidido** (opt-in via cláusula de NDA ampliada, nunca varredura silenciosa/automática — ver ponto 4 abaixo). Falta apenas o parecer formal de redação/retenção. | De "bloqueante de design" para **"pré-requisito de execução"** (ver seção "Gate de execução" abaixo) — o *modelo* já foi decidido por quem tem mandato para isso; o que falta é validação jurídica da redação, não uma decisão de arquitetura pendente. |
| 2 | Colisão terminológica com "harness" institucional | ✅ **Resolvido.** "Harness Agêntico IDE" (pessoal) vs. "Harness Corporativo" (institucional pós-triagem) — dois nomes distintos, sem sobreposição com `harness-catalog.yaml`. | Encerrado. Não requer mais acompanhamento neste gate. |
| 3 | Ausência de baseline quantitativo real | Parcialmente resolvido: **60/60 usam Claude Code, ~10 também Cursor.AI** — suficiente para dimensionar a superfície de ferramentas do v1 (não é preciso desenhar para "N ferramentas heterogêneas"). Turnover real **segue não respondido**. | Mantém-se como **hipótese, não fato** — exatamente como o próprio ciclo 1 já concluía, isto **não bloqueia** o Go; entra como pergunta de descoberta no `/nc-intake` (bloco Negócio), não como pré-requisito de reabertura do gate. |
| 4 | Sobreposição com `harvest-patterns.sh` — decisão de arquitetura pendente | ✅ **Resolvido.** `concept.md` comparou A/B/C lado a lado, o solicitante confirmou Opção A, e a mecânica de execução foi detalhada e validada por investigação direta do código (execução on-demand pelo dev, destino sempre o repo central, nunca o repo de trabalho, triagem manual do Comitê Nimbus Code, modelo de 2 etapas reaproveitando o mecanismo idempotente de distribuição do `bootstrap.sh`). | Encerrado como decisão de arquitetura. O que resta (schema do "Harness Corporativo" como artefato de primeira classe, composição exata do Comitê, formato exato de redistribuição) é **trabalho de especificação**, não de assessment — ver seção "O que fica explicitamente para `/nc-spec`/`/nc-arch`" abaixo. |

### Ponto novo identificado nesta reavaliação (não estava explícito em nenhum dos ciclos anteriores)

Ao reconferir `scripts/harvest-patterns.sh` diretamente (não apenas os
resumos de `concept.md`), confirmo que o script **hoje envia os metadados
capturados a um endpoint LLM configurável** (`HARVEST_API_URL`) para
identificar padrões — não faz apenas cópia/gravação direta. Nenhum dos
documentos deste assessment (`decision.md` ciclo 1, `concept.md` seção 6)
resolve explicitamente se a Opção A estendida **mantém** essa chamada a um
LLM externo para normalizar/resumir o conteúdo de texto livre do Harness
Agêntico IDE, ou se a extensão deve **desviar** desse comportamento (ex.:
gravação bruta sem chamada a LLM de terceiro, pelo menos na v1). Isso importa
porque, se a chamada a `HARVEST_API_URL` for mantida para conteúdo de texto
livre (prompts pessoais, potencialmente com dados de cliente), isso é
exatamente a "segunda camada de risco" já antecipada no ciclo 1 deste
`decision.md` (ponto 1: "se há envio de conteúdo a LLM de terceiros para
normalizar/resumir... isso exige avaliação de DPA com o fornecedor, hoje não
coberta").

**Isto não é motivo para manter "Needs Clarification"** — é uma pergunta de
especificação de comportamento (uma flag/config a decidir, não uma mudança de
arquitetura), mas **deve ser registrada explicitamente como requisito a
resolver em `/nc-spec`**, e tratada como bloqueante de *execução* junto com o
parecer de Jurídico/DPO (mesma seção abaixo), porque se a resposta for "sim,
mantém a chamada ao LLM externo", o escopo do parecer jurídico/DPO precisa
necessariamente cobrir também esse fornecedor, não apenas o armazenamento
interno.

### Por que não é Kill

Nenhum dado novo invalida o problema. Pelo contrário: a arquitetura de menor
custo e menor risco (Opção A) foi confirmada como viável e tecnicamente
compatível com a infraestrutura já madura do repositório (`bootstrap.sh` para
redistribuição idempotente, `harvest-patterns.sh` para captura), o que reduz
— não aumenta — o risco de execução em relação ao que se sabia no ciclo 1.

### Por que não é mais "Needs Clarification" bloqueante

No ciclo 1, três das quatro condições listadas exigiam decisão humana
*antes* de qualquer avanço de shape/spec (nomenclatura, aprovação de
modelo de captura, decisão de arquitetura). Hoje:

- as decisões de **nomenclatura** e de **arquitetura** foram tomadas por
  quem tem mandato para isso (o solicitante) e já estão documentadas e
  validadas tecnicamente (`concept.md`);
- a decisão sobre o **modelo de captura de dados sensíveis** também já foi
  tomada (opt-in via cláusula de NDA ampliada — não varredura automática
  silenciosa) — o que falta agora é *validação formal de redação jurídica*,
  não uma decisão de modelo em aberto. Isso é qualitativamente diferente:
  não é mais uma pergunta "o que fazemos?", é uma pergunta "a redação X está
  juridicamente correta?", que corre em paralelo à especificação técnica sem
  bloquear sua escrita — pelo mesmo racional que este próprio `decision.md`
  já registrou no ciclo 1 ("precedente S4 não significa matar a ideia,
  significa nenhuma implementação começa sem revisão humana obrigatória
  antes de qualquer construção" — a *especificação* não é "construção").

Continuar a exigir "Needs Clarification" agora seria tratar uma
pendência de **validação/assinatura formal** (Jurídico/DPO) e uma
pergunta de **hipótese de priorização** (turnover) como se fossem
bloqueios de *existência da ideia* — o que elas não são mais, dado que o
modelo e a arquitetura já foram decididos.

---

### Gate de execução (não de spec) — o que precisa estar pronto antes de `/nimbus-code-plan` construir algo

Estes itens **não bloqueiam** iniciar `/nc-intake`/`/nc-spec`, mas **bloqueiam
qualquer implementação real** (rodar o harvester estendido contra harness de
colaboradores reais). Devem ser tratados no processo formal como o mesmo tipo
de gate S4 já aplicado a `specs/022-nimbuscode-harvest-gateway/` (Security
Gate do `nimbus-code-plan`, `impact-map.md` obrigatório, revisão humana antes
de qualquer construção):

1. **Parecer formal de Jurídico/DPO** sobre a redação da cláusula do NDA e
   sobre a política de retenção/expurgo — hoje apenas encaminhado, não
   obtido. Sem este parecer, a spec pode ser escrita e planejada, mas o
   `nimbus-code-plan`/implementação não deve iniciar a construção do
   mecanismo de captura contra dados reais.
2. **Decisão explícita sobre a chamada a `HARVEST_API_URL`** para o conteúdo
   de texto livre do Harness Agêntico IDE (ponto novo identificado acima) —
   se mantida, o escopo do parecer de Jurídico/DPO deve cobrir também o
   fornecedor de LLM (DPA), não apenas o armazenamento interno.
3. **Turnover real dos 60 colaboradores** — tratar como hipótese na
   priorização/dimensionamento do esforço (não como fato), até que haja dado
   real. Não bloqueia início do ciclo formal, mas deve ser levantado como
   pergunta de descoberta explícita no `/nc-intake` (bloco Negócio).

### O que fica explicitamente para `/nc-spec`/`/nc-arch` (não é trabalho deste assessment)

- Desenho formal do **"Harness Corporativo"** como artefato de primeira
  classe distribuído junto ao template Nimbus Code (schema, formato de
  arquivo/catálogo, se é entrada nova ou extensão de
  `harness-catalog.yaml`/`success-catalog.yaml`/preset — pergunta já aberta
  desde `intake.md` e ainda não decidida).
- Composição exata, cadência e critérios objetivos de promoção/rejeição do
  **Comitê Nimbus Code** (`[NEEDS CLARIFICATION]` já sinalizado em
  `concept.md`, seção 2).
- Mecanismo exato de redistribuição da Etapa 2 (reaproveitar literalmente
  `bootstrap.sh`/`refresh_managed_project_root_files` vs. script novo e mais
  leve) e o critério objetivo do Comitê para classificar uma entrada como
  "específica de bounded context" vs. "genérica" (`concept.md`, seção 6.3).
- Definição exata dos valores de retenção/expurgo, uma vez obtido o parecer
  de Jurídico/DPO (item 1 do gate de execução acima).

---

### Handoff recomendado

1. **Executar `/nc-intake`** para conduzir a entrevista de descoberta formal
   (blocos Negócio, Infraestrutura, Segurança e LGPD), referenciando este
   assessment (`intake.md`, `research.md`, `problem.md`, `concept.md`,
   `decision.md`) como contexto de origem. O bloco Negócio deve
   explicitamente registrar o turnover real como pergunta aberta (hipótese,
   não fato) e o bloco Segurança/LGPD deve registrar o status "parecer de
   Jurídico/DPO encaminhado, não obtido" como pendência rastreada, não como
   bloqueio de abertura da spec.
2. **Executar `/nc-spec`** para gerar `spec.md`, com escopo limitado à
   **Opção A** de `concept.md`: extensão de `scripts/harvest-patterns.sh`,
   escrita sempre redirecionada ao repositório central dedicado (nunca ao
   repo do projeto de trabalho), triagem manual do Comitê Nimbus Code, e
   modelo de 2 etapas para redistribuição opcional pós-promoção. A spec deve
   registrar explicitamente como requisito em aberto (`[NEEDS
   CLARIFICATION]`, resolvível via `/nc-clarify`) a decisão sobre manter ou
   não a chamada a `HARVEST_API_URL`/LLM externo para o conteúdo de texto
   livre.
3. **Antes de `/nimbus-code-plan` iniciar qualquer construção real**: os três
   itens do "Gate de execução" acima (parecer de Jurídico/DPO, decisão sobre
   LLM externo, turnover como hipótese explícita) devem estar, no mínimo,
   formalmente rastreados no `impact-map.md`/Security Gate do plano — com o
   parecer de Jurídico/DPO **obtido** (aprovado, aprovado com condições, ou
   reprovado) antes de qualquer execução contra dados reais de
   colaboradores, seguindo o mesmo padrão S4 já aplicado a
   `specs/022-nimbuscode-harvest-gateway/`.

**Escopo explicitamente fora deste handoff**: Opções B e C de `concept.md`
não devem ser incluídas na spec resultante. A Opção C, em particular,
permanece condicionada a evidência de que a Opção A é insuficiente **e** a
parecer específico de Segurança de Endpoint/TI e avaliação formal de
`/nc-shield` — nenhuma dessas condições foi avaliada neste ciclo, e não deve
ser assumida como aprovada por extensão do Go concedido à Opção A.
