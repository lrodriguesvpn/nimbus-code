# Concept — Consolidação Corporativa de Harness Individuais (Claude/Cursor)

**Slug**: `harness-consolidacao-corporativa`
**Data**: 2026-09-22
**Agente**: NC-Assess-Shape
**Baseado em**: `intake.md`, `research.md`, `problem.md`, `decision.md` (incluindo a seção "Atualização — Respostas do solicitante (2026-09-22)")

**Atualização (2026-09-22, continuação do mesmo dia)**: solicitante confirmou
avanço com a **Opção A** e levantou uma pergunta de mecânica de execução
(onde o harness pessoal é escrito, e se há ganho em também deixá-lo dentro
do repositório de um projeto brownfield específico). Respondida na nova
seção 6, com investigação direta do código (`scripts/harvest-patterns.sh`,
`docs/harness/`, `docs/reuse-catalog.yaml`, `docs/bounded-contexts.yaml`,
`scripts/generate-context-graph.sh`, `bootstrap.sh`,
`specs/014-brownfield-multirepo-context-awareness/`) — não redecide as
seções 0-5, que permanecem válidas.

> **Nota de escopo**: este documento fica no espaço de **conceito de solução**
> — opções de captura, apetite e trade-offs. Não é um blueprint técnico
> (schema de dados, endpoints, formato de arquivo de configuração) — isso
> pertence a `/nc-assess-plan`/`/nimbus-code-plan`, condicionado ao gate de
> decisão e aos pareceres externos ainda pendentes (Jurídico/DPO; Segurança de
> Endpoint/`nc-shield` para a opção C).

---

## 0. O que já está resolvido (não redecidir aqui)

Herdado diretamente da atualização do solicitante em `decision.md`:

1. **Base legal**: NDA já existente com os ~60 colaboradores/clientes da VPN
   será ampliado com cláusula específica autorizando o armazenamento de
   prompts/harness agêntico. **Pré-requisito de execução** (não redesenhado
   aqui): validação formal de Jurídico/DPO sobre a redação da cláusula e
   sobre a política de retenção/expurgo. O NDA resolve a permissão de guardar
   o dado; não resolve, por si só, anonimização, prazo de retenção ou escopo
   de acesso interno — esses pontos seguem como item de shape/plan.
2. **Superfície de ferramentas**: dos ~60 colaboradores, **60 usam Claude
   Code** (fonte primária universal) e **~10 também usam Cursor.AI** (fonte
   secundária parcial, uso combinado, não exclusivo). As três opções abaixo
   são desenhadas para essa realidade concreta — não para "N ferramentas
   heterogêneas".
3. **Comitê Nimbus Code**: existe um consenso do solicitante de que um
   comitê humano de triagem deve revisar o que é agregado dos Harness
   Agênticos IDE individuais antes de qualquer promoção a Harness
   Corporativo. Isso é modelado como parte comum às três opções (seção 2),
   não como uma variável em disputa.

O que **este documento modela de fato** é a forma de **captura** dos Harness
Agênticos IDE individuais — o ponto que a atualização do solicitante escalou
de "extensão de `harvest-patterns.sh`" para uma decisão de arquitetura mais
ampla, com uma terceira opção (varredura automática de endpoint) que não
existia no ciclo anterior de decisão.

---

## 1. Nomenclatura

O solicitante já validou os dois nomes-âncora, que resolvem a colisão
terminológica identificada em `decision.md` (ponto 2):

| Nome (validado pelo solicitante) | Conceito |
|---|---|
| **Harness Agêntico IDE** | Configuração pessoal/individual — por dev, por IDE (Claude Code ou Cursor.AI). Nível tácito, não versionado, não institucional. |
| **Harness Corporativo** | Ativo institucional pós-triagem pelo Comitê Nimbus Code — o que foi promovido do nível individual para o nível organizacional, distribuído junto ao próprio template do Nimbus Code. |

Esses dois nomes são mantidos como as opções âncora desta modelagem — não
estão em disputa. A pedido do solicitante, seguem **2-3 alternativas de nome
de mercado** para "Harness Agêntico IDE", apenas como referência de
vocabulário já usado por fornecedores para conceitos análogos (ver
`research.md`, seção 1), a escolher ou descartar livremente:

| Alternativa de mercado | Fornecedor/uso análogo | Observação |
|---|---|---|
| **Agent Profile** | Termo genérico usado em discussões de configuração de agente por usuário (análogo ao "User Rules" do Cursor) | Mais neutro, sem colisão com "harness" institucional |
| **Personal Ruleset** | Análogo direto ao "User Rules" do Cursor (`research.md`, seção 1.2) | Comunica bem que é um conjunto de regras pessoal, não um catálogo |
| **User Memory / Personal Instructions** | Terminologia oficial do Claude Code ("user instructions", `~/.claude/CLAUDE.md`) e do GitHub Copilot ("personal instructions") | Mais alinhado ao vocabulário nativo das próprias ferramentas-fonte, o que pode facilitar comunicação com os 60 colaboradores |

**Recomendação**: manter **"Harness Agêntico IDE"** e **"Harness
Corporativo"** como os nomes de trabalho deste ciclo (já validados), usando a
tabela acima apenas se o solicitante quiser revisar antes de a nomenclatura
ser fixada em spec formal.

---

## 2. Fluxo de governança do Comitê Nimbus Code (comum às três opções)

Este fluxo é idêntico nas opções A, B e C — o que muda entre elas é **apenas
o mecanismo de captura** (etapa 1 abaixo). A partir da etapa 2, o processo é
o mesmo:

```
[1] CAPTURA                 [2] AGREGAÇÃO           [3] TRIAGEM HUMANA           [4] PROMOÇÃO
Harness Agêntico IDE   -->  Consolidação bruta  --> Comitê Nimbus Code       --> Harness Corporativo
(por dev, por IDE)          (sem juízo de valor)     revisa, filtra, decide       (distribuído com o
                                                       o que é promovido           template Nimbus Code)
                                                       e o que é descartado/
                                                       anonimizado
```

- **Etapa 1 — Captura**: é a variável modelada nas opções A/B/C abaixo.
- **Etapa 2 — Agregação**: consolidação bruta do que foi capturado, sem
  decisão de promoção — apenas organização/normalização mínima (ex.: por
  dev, por ferramenta, por data), preservando a rastreabilidade da origem.
- **Etapa 3 — Triagem humana (Comitê Nimbus Code)**: grupo humano designado
  revisa o material agregado e decide, item a item, o que é: (a) promovido a
  Harness Corporativo, (b) descartado, ou (c) devolvido para
  anonimização/redação antes de nova avaliação. Esta é a camada que
  formalmente decide o que sai do nível pessoal para o nível institucional —
  nenhuma promoção acontece sem essa revisão humana, independentemente da
  opção de captura escolhida.
- **Etapa 4 — Promoção**: o que o comitê aprova vira **Harness Corporativo**,
  distribuído junto ao próprio template Nimbus Code (destino final ainda a
  decidir em `/nc-assess-plan`: novo artefato de primeira classe vs. entrada
  em `harness-catalog.yaml`/`success-catalog.yaml`/preset já existentes —
  ver `problem.md`, pergunta em aberto do `intake.md`).

`[NEEDS CLARIFICATION]` (fora do escopo deste `concept.md`, a resolver em
`/nc-assess-plan`): composição exata do Comitê Nimbus Code (quantas pessoas,
quais papéis — ex. Segurança, Jurídico, liderança técnica, mantenedores do
Nimbus Code), cadência de reunião, e critérios objetivos de promoção/rejeição.

---

## 3. As três opções de captura

### Opção A — Extensão de `scripts/harvest-patterns.sh`

**Esboço conceitual**: adaptar o mecanismo já existente e maduro (hoje varre
a fonte de um repositório já clonado, on-demand, allowlist estrita de
metadados estruturais — nunca corpo de método, string literal ou texto
livre) para também aceitar como fonte os arquivos de Harness Agêntico IDE
(`~/.claude/CLAUDE.md`, `.cursor/rules/*.mdc`). Continua sendo **on-demand/
manual** — um colaborador ou o próprio esquadrão Nimbus roda o script
apontando para esses arquivos, reaproveitando o pipeline, a governança e as
ferramentas já maduras (diff do Git como gate de revisão, nunca roda em CI).

- **Apetite**: `small`–`medium` (dias a poucas semanas). É extensão de algo
  que já existe e já está operacional; o esforço principal é adaptar a
  allowlist para o novo tipo de fonte, não construir um pipeline novo.
- **Custo de implementação/manutenção**: **baixo**. Reaproveita 100% da
  infraestrutura, do modelo de governança (diff do Git como gate) e do
  conhecimento operacional já existentes. Não introduz um segundo pipeline
  para manter em paralelo.
- **Risco de segurança/privacidade**: **moderado, mas o mais contido das
  três opções** — herda o precedente de allowlist estrita de metadados
  estruturais. **Trade-off central já identificado em `decision.md`
  (ponto 1) e `research.md` (seção 2.3)**: se a allowlist for mantida tão
  estrita quanto no modelo atual (nunca capturar texto livre), o risco de
  vazamento de PII/segredo cai bastante, mas **o valor central da ideia
  também cai** — o conteúdo mais valioso de um Harness Agêntico IDE é
  justamente o texto livre da instrução/prompt, que é exatamente o "corpo"
  que este precedente institucional foi desenhado para nunca capturar. Não é
  possível copiar o desenho 1:1 sem perder o valor central da proposta.
- **Valor/velocidade de consolidação**: **moderado**. Depende de ação manual
  (alguém rodar o script apontando para o arquivo certo), o que naturalmente
  limita a taxa de captura — mas o atrito de execução em si é baixo, porque
  reaproveita uma ferramenta já familiar à engenharia.
- **Dependência de aprovação**: Jurídico/DPO (redação da cláusula do NDA,
  política de retenção — já em andamento conforme seção 0). Não exige,
  a priori, envolvimento de Segurança de Endpoint/TI, porque não há agente
  residente nem varredura automática de máquina — o mecanismo continua
  operando sobre arquivos explicitamente apontados, sob invocação humana.

### Opção B — Pipeline paralelo dedicado, com exportação manual/opt-in ativo

**Esboço conceitual**: um pipeline novo, construído especificamente para
Harness Agêntico IDE (não uma extensão do `harvest-patterns.sh`), mas ainda
**sem agente residente**. Cada colaborador aciona voluntariamente (ex.: um
comando de export tipo `nimbus-code harness export`) o envio do seu Harness
Agêntico IDE para a etapa de agregação — nada monitora continuamente o
endpoint entre um export e outro.

- **Apetite**: `medium` (semanas). Não reaproveita o `harvest-patterns.sh`
  como base técnica, mas ainda é um mecanismo relativamente simples
  (comando client-side + destino de agregação), sem a complexidade de
  varredura automática/residente da opção C.
- **Custo de implementação/manutenção**: **médio**. Um segundo pipeline para
  manter, com seu próprio ciclo de vida, versionamento e suporte — não herda
  a maturidade operacional do `harvest-patterns.sh`, mas também não carrega o
  custo recorrente de um agente residente monitorando endpoints.
- **Risco de segurança/privacidade**: **moderado, comparável ou levemente
  maior que a Opção A** — como é construído do zero, permite desenhar a
  captura para trazer mais conteúdo de texto livre (maior valor), mas isso
  significa reintroduzir deliberadamente o risco de PII/segredo que o
  precedente institucional evita. O ponto positivo de governança: por ser
  **opt-in ativo** (o colaborador decide o que e quando exportar), o
  colaborador tem oportunidade de revisar o conteúdo antes do envio — uma
  camada adicional de controle humano que as opções A e C não têm da mesma
  forma (A é on-demand mas tipicamente operado por quem roda o script, não
  necessariamente o dono do harness; C é automática, sem revisão prévia).
- **Valor/velocidade de consolidação**: **moderado a alto**, mas
  **dependente de adesão voluntária** — a taxa de captura real depende do
  quanto os 60 colaboradores efetivamente rodam o comando de export,
  replicando o risco de baixa adesão já antecipado em `research.md`
  (seção 5.3: resistência de devs a expor prompts pessoais).
- **Dependência de aprovação**: Jurídico/DPO (mesmo escopo da Opção A).
  Ainda não exige, a priori, Segurança de Endpoint/TI de forma equivalente à
  Opção C, porque não há presença permanente no endpoint — mas pode exigir
  uma revisão leve de Segurança sobre o destino/transporte dos dados
  exportados (para onde o comando envia o conteúdo, como é armazenado em
  trânsito).

### Opção C — Agente residente com varredura automática de todos os endpoints

**Esboço conceitual**: conforme descrito pelo solicitante na atualização de
`decision.md` — um mecanismo automatizado que varre periodicamente **todos os
computadores de todos os colaboradores da empresa** (não apenas repositórios
já clonados), localizando e coletando arquivos de configuração/harness
agêntico local (`CLAUDE.md`, memórias, regras do Cursor, possivelmente
histórico de prompts), sem exigir ação manual do colaborador a cada ciclo.

- **Apetite**: `large` (meses). Envolve construir e operar um agente
  residente multiplataforma, com ciclo de vida próprio (deploy, atualização,
  monitoramento de saúde em ~60 endpoints), além de toda a camada de
  agregação/triagem comum às três opções.
- **Custo de implementação/manutenção**: **alto**. É, por natureza, uma nova
  peça de infraestrutura residente e contínua — análogo em complexidade
  operacional ao gateway multicloud já classificado S4 no repositório
  (`specs/022-nimbuscode-harvest-gateway/`), mas com uma superfície de risco
  adicional: presença permanente em endpoint de usuário final, não apenas em
  infraestrutura de servidor.
- **Risco de segurança/privacidade**: **substancialmente mais invasivo que A
  e B**. Um agente residente com varredura periódica automática implica
  **presença permanente no endpoint**, lendo arquivos que podem conter
  segredos, credenciais coladas acidentalmente em prompts, e dados de
  clientes colados em sessões de chat — sem a camada de revisão humana
  prévia que a Opção B oferece via opt-in ativo, e sem a natureza pontual/
  sob demanda da Opção A. É a opção que mais eleva a classificação de risco
  (provável S4, conforme já antecipado em `problem.md`/`decision.md`) e que
  introduz uma categoria de risco distinta: não é mais "um script que lê o
  que foi apontado", é "um agente que decide o que ler, continuamente, em
  toda máquina da empresa".
- **Valor/velocidade de consolidação**: **potencialmente o mais alto das
  três** — captura harness de forma consistente e completa, sem depender de
  disciplina/adesão voluntária do colaborador (elimina o problema de baixa
  adesão da Opção B), possivelmente capturando mais harness com menos
  atrito para o colaborador no dia a dia. Esse ganho de cobertura, porém, **é
  obtido ao custo direto de maior exposição de dados sensíveis** — não é um
  ganho "gratuito", é uma troca explícita de completude por invasividade.
- **Dependência de aprovação**: **a mais ampla das três**. Além de
  Jurídico/DPO (mesmo escopo das opções A/B, mas com exigências
  provavelmente mais rígidas de anonimização e retenção dado o volume/
  automatismo da coleta), esta opção **exigiria envolvimento do time de
  Segurança de Endpoint/TI** — não é uma decisão que Jurídico/DPO resolve
  sozinho, porque envolve instalar e operar um agente com acesso de leitura
  a arquivos locais em toda a frota de máquinas da empresa, uma superfície
  de ataque e de auditoria completamente diferente das opções A e B.

> ⚠️ **Obrigatório antes de qualquer comprometimento de arquitetura para a
> opção C**: consultar `/nc-shield` (Nimbus DevSecOps Guardian) já nesta fase
> de shape. Este `concept.md` **não** avalia a viabilidade final de
> segurança da opção C — apenas sinaliza os trade-offs acima para permitir
> uma decisão informada em `/nc-assess-decide` ou etapa equivalente. A
> avaliação formal de `nc-shield` deve preceder qualquer construção,
> alinhado ao mesmo padrão já aplicado a `specs/022-nimbuscode-harvest-gateway/`
> (S4, revisão humana obrigatória antes de qualquer implementação).

---

## 4. Comparação lado a lado

| Dimensão | A — Extensão de `harvest-patterns.sh` | B — Pipeline paralelo, exportação manual/opt-in | C — Agente residente, varredura automática |
|---|---|---|---|
| **Apetite** | `small`–`medium` (dias a poucas semanas) | `medium` (semanas) | `large` (meses) |
| **Custo de implementação/manutenção** | Baixo — reaproveita pipeline maduro | Médio — segundo pipeline novo, mas sem agente residente | Alto — infraestrutura residente e contínua, análoga a integração S4 |
| **Risco de segurança/privacidade** | Moderado (contido pela allowlist estrita, mas isso limita o valor capturado) | Moderado (opt-in dá camada extra de revisão humana antes do envio) | **Substancialmente mais invasivo** — presença permanente no endpoint, sem revisão prévia do colaborador |
| **Valor/velocidade de consolidação** | Moderado — depende de execução manual pontual | Moderado a alto — depende de adesão voluntária (risco de baixa adesão) | Potencialmente o mais alto — cobertura consistente, mas às custas de maior exposição |
| **Dependência de aprovação** | Jurídico/DPO (redação NDA, retenção) | Jurídico/DPO (mesmo escopo de A) + revisão leve de transporte/armazenamento | Jurídico/DPO **+ Segurança de Endpoint/TI** + `/nc-shield` obrigatório antes de arquitetura |
| **Classificação de complexidade provável** | S3–S4 (herda o precedente já S4 do `harvest-gateway`, mas com allowlist mais estrita) | S4 (mesmo racional de `decision.md`/`problem.md`, dados de texto livre) | S4, com controles adicionais de endpoint — o caso mais rígido das três |
| **Reaproveita infraestrutura existente?** | Sim, quase integralmente | Parcialmente (reaproveita apenas a etapa de agregação/triagem comum) | Não — é infraestrutura nova de ponta a ponta |
| **Depende de disciplina/adesão do colaborador?** | Sim (quem roda o script precisa apontar para o arquivo certo) | Sim, e é o ponto mais crítico (adesão voluntária pode ser baixa) | Não — é o principal argumento de valor da opção |

---

## 5. Recomendação para uma primeira versão (v1)

**A Opção A (extensão de `scripts/harvest-patterns.sh`) parece a mais
equilibrada para uma v1**, pelos seguintes motivos objetivos:

1. **Menor custo e menor risco simultâneos**: é a única opção que reaproveita
   quase integralmente uma infraestrutura já madura, testada e já operando
   sob o mesmo tipo de gate de governança (diff do Git, nunca em CI) que este
   domínio precisa.
2. **Compatível com o apetite de `small`–`medium`**, permitindo validar o
   valor real da consolidação (quantos itens o Comitê Nimbus Code
   efetivamente promove a Harness Corporativo) antes de investir em algo
   maior — o mesmo racional de sequenciamento em fases já usado em outro
   ciclo deste repositório (`qwen-selfhost-ide-agnostica/concept.md`:
   começar pela opção mínima, medir, só então escalar).
3. **Não introduz a categoria de risco mais severa (agente residente em
   endpoint)** antes de haver evidência de que o valor da consolidação
   justifica esse nível de exposição.
4. A **Opção B** é uma alternativa intermediária razoável **se** a Opção A
   se mostrar limitada demais (ex.: allowlist estrita capturando pouco valor
   real) — mas não deveria ser o ponto de partida, porque implica construir
   um segundo pipeline sem ainda ter medido se a Opção A já basta.
5. A **Opção C** só deveria ser considerada **depois** que A (ou B) tiver
   demonstrado, com dados reais, que: (a) a cobertura/adesão manual é
   insuficiente, e (b) o Comitê Nimbus Code e a organização têm apetite para
   absorver o nível de invasividade que ela exige — e **nunca antes** de uma
   avaliação formal de `/nc-shield` e de Segurança de Endpoint/TI.

**Esta recomendação não é a decisão final.** A escolha entre A, B e C
depende, para **todas as três opções**, do parecer de Jurídico/DPO sobre o
modelo de captura, redação da cláusula do NDA e política de retenção/expurgo
(seção 0) — e, **especificamente para a opção C**, depende adicionalmente do
parecer de Segurança de Endpoint/TI e da avaliação formal de `/nc-shield`
antes de qualquer comprometimento de arquitetura.

---

## 6. Mecânica Detalhada da Opção A e Posicionamento (Central vs. Brownfield)

> Esta seção responde diretamente a uma pergunta de mecânica levantada pelo
> solicitante após confirmar a Opção A, com base em investigação direta do
> código hoje existente (`scripts/harvest-patterns.sh`, `docs/harness/`,
> `docs/reuse-catalog.yaml`, `docs/bounded-contexts.yaml`,
> `scripts/generate-context-graph.sh`, `bootstrap.sh` e
> `specs/014-brownfield-multirepo-context-awareness/`) — não é especulação.

### 6.1 Confirmação da mecânica de execução

**A mecânica descrita pelo solicitante está correta em essência, com um
ajuste de precisão técnica importante.** Confirmando ponto a ponto:

- ✅ **Execução por demanda, nunca automática/contínua.** É exatamente a
  filosofia já codificada em `scripts/harvest-patterns.sh` hoje: o cabeçalho
  do script declara explicitamente "**NUNCA rodar em CI** (FR-011) —
  exclusivamente on-demand, iniciado por um humano" e "este script não é
  referenciado por nenhum workflow em `.github/workflows/`". A Opção A herda
  esse comportamento sem alteração — o desenho já resolve a preocupação do
  solicitante de "não pode ficar rodando sozinho".
- ✅ **Cada desenvolvedor roda a partir de um checkout local.** O script é
  invocado como `scripts/harvest-patterns.sh <repo-path> [--subpath <dir>]
  [--output <arquivo>]`, ou seja, já é desenhado para apontar para um
  caminho de repositório local qualquer — hoje esse `<repo-path>` é
  tipicamente um repositório de código já clonado, mas nada na mecânica
  impede apontá-lo para os arquivos de Harness Agêntico IDE do próprio
  usuário (`~/.claude/CLAUDE.md`, `.cursor/rules/*.mdc`) na etapa de
  extensão da Opção A.
- ⚠️ **Ajuste de precisão sobre "para onde escreve" — este é o ponto que
  precisa de decisão explícita, não é automático hoje.** O script, no seu
  comportamento atual, escreve o resultado em `$OUTPUT_FILE`, cujo *default*
  é `docs/reuse-catalog.yaml` **relativo ao diretório onde o comando é
  executado (`cwd`)** — não necessariamente dentro de `<repo-path>`. Ou
  seja: hoje, se um dev roda o script de dentro do checkout do projeto em
  que está trabalhando, o catálogo atualizado é o `docs/reuse-catalog.yaml`
  **daquele projeto** (o que faz sentido para o propósito atual: catalogar
  padrões de código *daquele* repo, no próprio repo). Para a Opção A
  estendida a Harness Agêntico IDE, isso significa que **é necessário um
  ajuste explícito de destino** (via a flag já existente `--output`, ou uma
  nova variável de ambiente análoga a `REUSE_CATALOG_FILE`) para que a
  escrita seja **sempre redirecionada para o repositório central dedicado**
  (ex.: `nimbus-code-harness-corporativo`, ou uma área dedicada dentro do
  próprio repo-template) — **nunca para o `docs/reuse-catalog.yaml` do
  repositório de trabalho do dev**. Isso não é uma mudança arquitetural
  grande (a flag `--output` já existe), mas precisa ser tratada como decisão
  de configuração explícita no `/nc-assess-plan`, não como comportamento
  padrão herdado sem revisão.
- ✅ **Triagem manual do Comitê antes de qualquer promoção.** Confirma
  exatamente o fluxo já modelado na seção 2 deste documento (Captura →
  Agregação → Triagem humana → Promoção) — o repositório central recebe o
  material bruto, e nenhuma promoção a Harness Corporativo acontece sem essa
  revisão humana.

**Mecânica confirmada e ajustada**: cada dev, a partir de um checkout local
do repositório-template do Nimbus Code (ou de um comando/script distribuído
por ele), roda `scripts/harvest-patterns.sh` (estendido) apontando
`<repo-path>` para os arquivos de Harness Agêntico IDE pessoais na sua
máquina, com `--output` explicitamente configurado para escrever no
**repositório central dedicado** — nunca no repositório do projeto em que o
dev está trabalhando. O Comitê Nimbus Code então revisa manualmente o que
chega nesse repositório central antes de qualquer promoção a Harness
Corporativo.

### 6.2 Resposta direta à pergunta de brownfield

**Pergunta**: existe ganho real em também deixar (ou referenciar) o Harness
Agêntico IDE de um dev específico dentro do repositório do projeto
brownfield que ele mantém, além de mandá-lo para o repo central?

**Resposta objetiva: não, não para o Harness Agêntico IDE bruto/não
triado — o ganho de continuidade é real, mas o custo de pular a triagem do
Comitê é maior e evitável com um modelo em duas etapas (seção 6.3).**

Avaliando os dois lados, com evidência do próprio repositório:

- **A favor (continuidade de manutenção)**: é um argumento legítimo — um
  novo dev que herda um projeto brownfield específico se beneficiaria
  diretamente de um harness já ajustado às particularidades daquele código,
  sem precisar procurar no repo central nem depender de uma promoção
  institucional já concluída. Esse ganho é real e não deve ser descartado.
- **Contra (o motivo que pesa mais)**: harness pessoal bruto, por
  definição, ainda não passou pela triagem do Comitê — pode conter
  instruções erradas, hiperespecíficas ao estilo de comunicação de um único
  dev (não necessariamente um bom padrão a herdar), ou dados sensíveis que
  coincidem com aquele projeto/cliente específico (justamente o cenário de
  maior risco, já que projeto brownfield real tende a ter mais dados de
  produção/cliente reais do que um ambiente de teste). Colocar esse material
  bruto dentro do repositório do projeto — que pode ser acessado por outros
  devs do time, auditado, ou em alguns casos entregue/exposto ao cliente —
  **pula exatamente a etapa de triagem que é a razão de existir do Comitê
  Nimbus Code** (seção 2 deste documento). Isso contraria diretamente o
  ponto 3 da seção 0 ("nenhuma promoção acontece sem revisão humana,
  independentemente da opção de captura escolhida").
- **Comparação com o padrão já existente no repositório — ambos confirmam
  que não há precedente direto para "harness pessoal cru no repo do
  projeto"**:
  - `docs/harness/harness-catalog.yaml` já vive dentro do repositório (do
    template, e por extensão de cada projeto que o adota via
    `bootstrap.sh`), mas cataloga **padrões de erro institucionais já
    triados** (`error_pattern`, `root_cause`, `prevention`, ver
    `docs/harness/harness-guide.md`), com um fluxo de triagem explícito
    embutido no próprio processo: uma Issue é aberta com o label
    `harness:pending`, revisada, e só então fechada com
    `harness:cataloged`. Ou seja, mesmo esse catálogo — que já vive dentro
    do repo do projeto — não aceita entrada bruta sem revisão; é
    estruturalmente diferente de "meu jeito pessoal de conversar com o
    Claude", que é tácito, não estruturado e não revisado por definição.
  - O grafo de contexto multi-repo brownfield
    (`specs/014-brownfield-multirepo-context-awareness/`,
    `scripts/generate-context-graph.sh`, `docs/bounded-contexts.yaml`) existe
    para um propósito completamente diferente: mapear **dependências
    estruturais de código entre repositórios** do mesmo bounded context
    (ex.: quais repos satélite dependem de quais interfaces/manifestos),
    para alimentar `graph.yaml`/`graph.md` antes de `plan.md`. Não há,
    hoje, nenhum mecanismo ali (nem em `bounded-contexts.yaml`) desenhado
    para propagar conteúdo tácito/pessoal de um dev entre repositórios —
    seria reaproveitar uma peça de infraestrutura para um propósito para o
    qual ela nunca foi desenhada nem tem os controles de triagem
    necessários.

### 6.3 Recomendação: modelo em duas etapas

Para resolver a tensão entre "ganho de continuidade local" e "risco de
pular a triagem", a recomendação é um modelo de **duas etapas obrigatórias
em sequência** — nunca em paralelo, nunca com a segunda pulando a primeira:

```
ETAPA 1 (sempre, sem exceção)          ETAPA 2 (opcional, condicional)
Harness Agêntico IDE (bruto)     -->   Harness Corporativo (já promovido)
      |                                       |
      v                                       v
Repo central dedicado                 SE for claramente específico de um
(triagem do Comitê Nimbus Code)        bounded context/projeto (não
                                        genérico) --> redistribuído/
                                        sincronizado de volta ao(s) repo(s)
                                        de projeto daquele bounded context
```

- **(a) Etapa 1 — sempre para o repo central primeiro.** Harness pessoal
  bruto **nunca** vai direto para o repositório do projeto, em nenhuma
  circunstância — resolve diretamente o risco levantado em 6.2 (instrução
  errada, viés pessoal, dado sensível de cliente) e mantém o Comitê Nimbus
  Code como o único portão de promoção, coerente com o que já está
  resolvido na seção 0/2 deste documento.
- **(b) Etapa 2 — redistribuição opcional pós-promoção, só quando aplicável
  a um bounded context específico.** Uma vez que um trecho do harness é
  validado e promovido a Harness Corporativo **e** o Comitê identifica que
  ele é claramente específico de um bounded context/projeto (não um padrão
  genérico de uso da ferramenta), ele pode ser opcionalmente
  redistribuído/sincronizado de volta para o(s) repo(s) de projeto daquele
  bounded context. Esta etapa **reaproveita infraestrutura de distribuição
  que já existe no Nimbus Code**, em vez de inventar um mecanismo novo: o
  `bootstrap.sh` já implementa exatamente esse tipo de entrega
  unidirecional template→projeto para `docs/harness/harness-catalog.yaml`,
  `docs/reuse-catalog.yaml` e `docs/bounded-contexts.yaml` (instalação
  inicial idempotente que nunca sobrescreve arquivo já existente, mais uma
  rotina de *refresh* — `refresh_managed_project_root_files` — que
  atualiza arquivos ainda não customizados localmente e avisa, sem
  sobrescrever, quando encontra customização local). O mesmo padrão
  (entrega idempotente, nunca-overwrite de customização local, log
  explícito do que foi/não foi atualizado) é reaproveitável para
  redistribuir entradas de Harness Corporativo específicas de bounded
  context de volta ao(s) repo(s) satélite daquele contexto — **sempre a
  partir do conteúdo já promovido no repo central, nunca pulando a etapa 1**.

Este modelo entrega o ganho de continuidade que motivou a pergunta
("o próximo dev daquele projeto brownfield específico já encontra o
harness ajustado ali") **sem** abrir uma via alternativa que contorne a
triagem do Comitê — o repositório do projeto brownfield só recebe harness
que já passou pela revisão humana da Etapa 1, nunca material cru.

`[NEEDS CLARIFICATION]` (fora do escopo deste `concept.md`, a resolver em
`/nc-assess-plan`): mecanismo exato de "sincronização de volta" da Etapa 2
(reaproveitar literalmente `bootstrap.sh`/`refresh_managed_project_root_files`
vs. um script novo e mais leve dedicado a isso); e critério objetivo do
Comitê para classificar uma entrada de Harness Corporativo como "específica
de bounded context" (elegível à Etapa 2) vs. "genérica" (permanece apenas
no repo central).

---

## 7. Handoff

Ao concluir este `concept.md`, o próximo passo recomendado é o gate de
decisão formal:

- `/nc-assess-decide` (ou `/speckit-assess-decide`) — para registrar o
  veredito considerando as três opções comparadas aqui, os pareceres externos
  ainda pendentes (Jurídico/DPO para todas; Segurança de Endpoint/`nc-shield`
  para C), e a recomendação de sequenciamento acima.

Este ciclo **não** avança automaticamente para `/nc-assess-decide` — a
execução desse próximo passo fica a critério do solicitante.
