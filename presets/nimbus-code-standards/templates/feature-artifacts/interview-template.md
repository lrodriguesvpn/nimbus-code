# Modelo de Entrevista de Descoberta — `<feature-slug>`

<!--
  Guia de entrevista para a fase de DESCOBERTA (antes de escrever o spec.md).
  Usado hoje por um humano (BA/ADE) conduzindo a conversa com o cliente/solicitante;
  desenhado para no futuro ser conduzido pelo NIMBUS AGENT via Microsoft Teams,
  gravando o transcript e preenchendo este mesmo formato.

  Referenciado por: .github/skills/speckit-specify/SKILL.md (checagem de cobertura
  mínima antes de finalizar o spec.md — ver seção "Cobertura da Entrevista de
  Descoberta" nesse SKILL). Roadmap de condução automatizada: ver
  specs/018-nimbus-agent-intake/spec.md (User Story "Conduzir entrevista de
  descoberta via Teams").

  Localização quando preenchido: specs/<feature-slug>/interview.md

  Versão deste template: v1.3 (mescla com o padrão de entrevista de PO —
  ver "Como este Modelo Evolui" no final deste arquivo — que acrescentou a
  seção de Critérios de Aceite e a Análise de Tamanho/Quebra ao Bloco 1, e
  reforçou a checagem de duplicidade brownfield no Bloco 2. Continua em ciclo
  de teste ativo: modo Completo vs. Fast-Track, saída estruturada e checklist
  de 3 estados seguem sendo medidos na prática antes de reduzir/expandir).
-->

## Como usar este modelo

**Regra de ouro: esta entrevista existe para descobrir O QUE o cliente precisa
e POR QUE — nunca o COMO técnico será construído.** Se a conversa começar a
discutir tecnologia, framework, banco de dados ou arquitetura, anote como nota
lateral (não bloqueia a entrevista) e redirecione para o próximo bloco — o
"como" é decidido depois, no `/speckit-plan`, não aqui.

Não é um formulário de compliance para ser lido item a item sem contexto. Os
4 blocos abaixo podem ser conduzidos em qualquer ordem, de forma conversacional
— o objetivo é sair da reunião com todas as perguntas **obrigatórias**
respondidas (ou explicitamente marcadas `N/A — motivo`), não seguir um roteiro
rígido. Leva ~20–30 minutos numa conversa fluida no modo Completo (~10 minutos
no modo Fast-Track — ver abaixo).

**Não aceite resposta vaga.** Em qualquer pergunta do roteiro — não só nos
Critérios de Aceite — se a resposta for genérica ("vai melhorar a experiência",
"deve funcionar corretamente"), reforce até virar algo concreto e verificável:
"melhorar de qual forma, o que o usuário passa a conseguir fazer que não
conseguia antes?". Isso é herdado do padrão de entrevista de Product Owner e
vale para toda a conversa, não é um bloco isolado.

**Nunca deixar uma pergunta obrigatória em branco silenciosamente.** Se o
respondente não souber, registre `[NEEDS CLARIFICATION: <o que falta>]` — isso
alimenta diretamente o `spec.md` gerado a partir desta entrevista.

**Se a reunião for gravada (ex.: condução futura via Teams)**: avise os
participantes no início e registre o consentimento — a gravação em si contém
dado pessoal dos participantes da própria entrevista, não só do sistema sendo
especificado. Trate isso à parte do Bloco 4 (que é sobre dado pessoal *do
sistema pedido*, não da reunião).

---

## Modo Fast-Track (S0/S1)

*Se a complexidade estimada da demanda já é baixa (S0 — documentação/texto,
S1 — função isolada sem dependência externa), use apenas as perguntas
marcadas com ⚡ abaixo — geralmente 9 perguntas no total, ~10 minutos. As
demais podem ser puladas nesta rodada; se a complexidade real revelar-se maior
durante a conversa, mude para o modo Completo sem constrangimento.*

Se não tiver certeza da complexidade antes de começar, comece pelo modo
Completo — é mais barato perguntar a mais do que reabrir a entrevista depois.

---

## Cabeçalho

| Campo | Valor |
|---|---|
| **Data** | [YYYY-MM-DD] |
| **Solicitante/Cliente** | [nome/área] |
| **Facilitador** | [nome humano, ou "Nimbus Agent (Teams)"] |
| **Canal** | [presencial / Teams / assíncrono (formulário)] |
| **Feature slug (se já souber)** | [kebab-case, ou "a definir"] |
| **Prioridade inferida (uso interno — não ler ao cliente)** | [P0-blocker / P1-high / P2-medium / P3-low — inferida a partir do Bloco 1, pergunta 7] |
| **Versão deste modelo** | v1.3 |
| **Modo desta entrevista** | [Completo / Fast-Track] |
| **Duração real** *(preencher no Encerramento)* | [X minutos] |

---

## Bloco 1 — Negócio (o quê e por quê) — **obrigatório**

*O coração da entrevista. Sem isso, não há spec possível. Perguntas com ⚡ compõem o modo Fast-Track.*

1. ⚡ Qual problema ou necessidade você está tentando resolver? Para quem?
2. Como isso é feito hoje — manualmente, ou já existe um sistema/ferramenta que faz isso (mesmo que mal ou parcialmente)? *(descreva o processo/sistema atual, não como o novo deve ser construído)*
3. ⚡ O que "pronto" significa para você — como saberemos que funcionou (no dia da entrega **e** algum tempo depois — que sinal mostraria que isso resolveu o problema de verdade, não só que foi entregue)?
4. Quem usa isso no dia a dia (perfis/papéis, não nomes de sistema)?
5. ⚡ O que **definitivamente não** faz parte deste pedido agora (fora de escopo)?
6. Existe prazo ou evento que torna isso urgente?
7. Se só pudesse resolver **1 coisa** nesta entrega, qual seria? *(usar a resposta para inferir a prioridade no campo interno do cabeçalho — não citar P0–P3 na conversa)*
8. ⚡ Quem dá o aceite final (aprovação de que está correto)? E quem, se discordar, consegue travar isso mesmo depois de aprovado?
9. Já foi tentado algo parecido antes que não funcionou? O que aconteceu?
10. O que essa demora está custando hoje — o que continua acontecendo de ruim enquanto isso não sai?
11. Algum outro time ou projeto já está trabalhando em algo parecido? *(facilitador: se sim, sinalizar para o agente checar `docs/reuse-catalog.yaml` antes do `/speckit-plan` — evita esforço duplicado)*
12. Já existe orçamento/patrocínio aprovado para isso, ou ainda estamos validando viabilidade?

### Critérios de Aceite — **obrigatório, mínimo 4 critérios mensuráveis**

*Herdado do padrão de entrevista de Product Owner: em vez de perguntar "quais
são os critérios de aceite?" em aberto (resposta quase sempre vaga), o
facilitador **sugere primeiro, valida depois** — usando o que já foi coletado
nas perguntas 1–3 acima como matéria-prima.*

Apresentar ao respondente algo como:

> "Com base no que você me descreveu, aqui estão sugestões de critérios de
> aceite — você valida, remove o que não faz sentido e adiciona o que estiver
> faltando:"
>
> - **C1** — [critério gerado a partir da pergunta 1 (problema) e 3 (pronto)]
> - **C2** — [critério gerado a partir da pergunta 4 (usuário) ou 2 (estado atual)]
> - **C3** — [critério gerado a partir da pergunta 5 (fora de escopo) ou 8 (aprovação)]
> - **C4** — [critério adicional, se aplicável]

Aguardar a validação do respondente: se confirmar todos, aceitar; se pedir
ajuste, corrigir e reapresentar apenas os alterados; se pedir mais, incluir e
reapresentar a lista completa. Garantir ao final **pelo menos 4 critérios**
claros e verificáveis — cada um deve descrever um comportamento observável
("o sistema faz X quando Y"), nunca um adjetivo vago ("funciona bem",
"está correto"). Se um critério sugerido ou informado for vago, desafiar:

> "'Funcionar corretamente' não é um critério de aceite — o que exatamente
> deve acontecer? Qual o comportamento esperado, mensagem, estado do sistema?"

Os critérios validados aqui alimentam diretamente a seção "Success Criteria"/
"Acceptance Scenarios" do `spec.md` gerado pelo `/speckit-specify` — evita
`[NEEDS CLARIFICATION]` tardio sobre "como saberemos que está pronto".

---

## Bloco 1.5 — Análise de Tamanho / Proposta de Quebra (opcional — só quando há sinal claro)

*Não é um bloco obrigatório nem conta para a Checklist de Cobertura Mínima —
é uma checagem de qualidade que o facilitador faz mentalmente antes de
encerrar o Bloco 1. Herdado do padrão de entrevista de Product Owner.*

Avaliar se **pelo menos dois** destes sinais estão presentes nas respostas já
coletadas (um sinal isolado não é suficiente para propor quebra):

- A Descrição da Demanda (pergunta 1) cobre **múltiplos fluxos independentes**.
- Os Critérios de Aceite somam **mais de 8 itens** cobrindo comportamentos desconexos.
- A descrição contém várias ocorrências de "e também", "além disso", "e ainda".
- Há **mais de um perfil de usuário** (pergunta 4) com necessidades distintas.
- Claramente envolve **mais de um domínio de negócio ou bounded context** (ver Bloco 2).
- O respondente descreveu uma entrega que **"levaria mais de uma sprint"**.

Se nenhum ou apenas um sinal estiver presente: **não propor quebra**, seguir
direto para o Bloco 2.

Se dois ou mais sinais estiverem presentes, apresentar a proposta usando
cortes **verticais** (fluxo completo do usuário) — nunca cortes técnicos
("back-end" vs "front-end" não são fatias válidas):

> "Com base no que você me descreveu, essa demanda parece grande para uma
> única feature. Identifiquei uma forma de quebrar em fatias menores, mas
> ainda coesas e entregáveis de ponta a ponta:"
>
> **Fatia A — [Título conciso]** — Foco: [o que essa fatia entrega de ponta a
> ponta para o usuário] — Critérios: [subconjunto de C1..Cn]
>
> **Fatia B — [Título conciso]** — Foco: [idem] — Critérios: [subconjunto]

Registrar a decisão do respondente (aceitar a quebra, ou manter como uma única
feature) na Saída Estruturada (`quebra_proposta`) e no resumo do Encerramento.
Se aceita, cada fatia normalmente vira uma feature/`interview.md` própria via
`/speckit-interview` — este documento registra apenas a fatia que está sendo
entrevistada agora.

---

## Bloco 2 — Infraestrutura — **obrigatório, mas curto**

*Não é sobre desenhar a arquitetura — é sobre restrições e contexto que o Dev/agente precisa saber antes de propor o "como". Perguntas com ⚡ compõem o modo Fast-Track.*

1. ⚡ Onde isso vai rodar/ser hospedado? *(nuvem já usada pela empresa, on-premise, SaaS de terceiro — se não souber, tudo bem, registrar "a definir em plan.md")*
2. ⚡ Isso é uma mudança dentro de um sistema que já existe (brownfield), ou é construído do zero (greenfield)? *(se brownfield, o agente consulta `docs/bounded-contexts.yaml` e pode rodar `scripts/generate-context-graph.sh` automaticamente no `/speckit-specify`)*
3. Já existe um padrão, bounded context ou repositório de referência que essa solução deve seguir? Quais repositórios/serviços concretos são afetados ou precisam ser tocados? *(ver `docs/bounded-contexts.yaml` se este projeto usa MultiRepo; facilitador: cruzar a resposta com `docs/reuse-catalog.yaml` — se já existir um padrão catalogado para o mesmo domínio/bounded context, sinalizar isso ao agente antes do `/speckit-plan` em vez de deixar para descobrir depois)*
4. ⚡ Quem ou o quê vai acessar isso? *(usuários internos, parceiros externos, público, outro sistema/integração)*
5. Existe expectativa de volume (poucos usuários internos vs. escala alta/pública)?
6. Depende de integração com algum sistema já existente? Qual?
7. *(opcional, não bloqueia a entrevista)* Isso pode ficar fora do ar de vez em quando (manutenção agendada), ou precisa estar sempre disponível? Se parar por algumas horas, o que acontece de ruim? *(alimenta a tabela de SLO Alvo do `plan.md`, que já aceita "—" com justificativa quando não souberem responder)*

---

## Bloco 3 — Segurança — **obrigatório, mas curto**

*Perguntas com ⚡ compõem o modo Fast-Track.*

1. ⚡ Este sistema expõe alguma informação sensível ou crítica para o negócio? *(ex.: dado de pagamento/cartão, segredo industrial, propriedade intelectual, contrato confidencial — dado **pessoal** é tratado no Bloco 4/LGPD, não aqui)*
2. Quem pode e quem não pode acessar (perfis de autorização, mesmo que a granularidade fina venha depois)?
3. Existe exigência de autenticação corporativa (SSO/AD) ou pode usar um padrão mais simples?
4. Há necessidade de auditoria/trilha de "quem fez o quê"?

---

## Bloco 4 — LGPD / Proteção de Dados — **obrigatório, mas curto**

*Perguntas com ⚡ compõem o modo Fast-Track.*

1. ⚡ Este pedido envolve dado pessoal (nome, e-mail, CPF, dado de saúde, localização, etc.)?
2. Se sim: de quem são esses dados — funcionário, cliente final, terceiro?
3. Qual a base legal para tratar esse dado? *(execução de contrato, consentimento, obrigação legal, legítimo interesse — se não souber, registrar como pendência para jurídico/DPO, não adivinhar)*
4. Esses dados têm prazo de retenção definido, ou existe pedido de exclusão a considerar?
5. Esse dado sai da organização (parceiro, fornecedor terceiro, nuvem fora do país)?

> Se a resposta ao item 1 for claramente "não" (nenhum dado pessoal envolvido),
> marque os itens 2–5 como `N/A — sem dado pessoal identificado` e siga em
> frente. Não force perguntas de LGPD quando não há dado pessoal em jogo — isso
> é burocracia sem valor.

---

## Encerramento

*Leia de volta um resumo do que foi entendido para o solicitante confirmar
antes de encerrar a reunião.*

- **Resumo em 3–5 linhas**: [o que foi entendido]
- **Pendências / [NEEDS CLARIFICATION]**: [lista — cada uma vira um marcador no spec.md]
- **Responsável por validar o spec.md gerado**: [nome]
- **Duração real desta entrevista**: [X minutos] *(preencher também no Cabeçalho — dado usado para medir se o modo Fast-Track/Completo está calibrado corretamente, ver "Como este Modelo Evolui")*

---

## Checklist de Cobertura Mínima

*Usado por quem conduz a entrevista (humano ou Nimbus Agent) para autoavaliar
se a entrevista está completa antes de encerrar. Também é o contrato que o
`/speckit-specify` valida contra o input/transcript recebido — ver
`.github/skills/speckit-specify/SKILL.md`. No modo Fast-Track, os itens
correspondentes a perguntas não marcadas com ⚡ podem ficar como "Ausente —
fast-track" sem virar `[NEEDS CLARIFICATION]`.*

**Estado de cada item**: `Coberto` (resposta clara e acionável) · `Ambíguo`
(o tema foi tocado, mas a resposta não é acionável — ex.: "acho que não tem
dado pessoal, mas não tenho certeza") · `Ausente` (não foi respondido).
Apenas `Ambíguo` e `Ausente` (fora do Fast-Track) viram candidatos a
`[NEEDS CLARIFICATION]`.

| Item | Estado (Coberto / Ambíguo / Ausente) | Nota |
|---|---|---|
| Objetivo de negócio (o quê e por quê) | | |
| Critério de sucesso/pronto (entrega + sustentado) | | |
| Perfis de usuário identificados | | |
| Escopo fora (o que não é) | | |
| Critérios de aceite (mínimo 4, mensuráveis e verificáveis) | | |
| Infraestrutura: hospedagem ou padrão de referência (ou "a definir") | | |
| Infraestrutura: brownfield/greenfield indicado | | |
| Infraestrutura: repositórios/bounded contexts afetados | | |
| Infraestrutura: quem acessa | | |
| Segurança: sensibilidade/exposição | | |
| Segurança: perfis de autorização | | |
| LGPD: presença ou ausência de dado pessoal | | |
| LGPD: base legal (ou pendência para jurídico/DPO) | | |

> Se qualquer item acima estiver `Ambíguo` ou `Ausente` (fora do Fast-Track)
> no input recebido pelo `/speckit-specify`, trate como candidato a
> `[NEEDS CLARIFICATION]`, respeitando o limite de 3 marcadores e a
> prioridade: escopo de negócio > segurança/LGPD > infraestrutura > detalhe
> técnico. Nunca inventar resposta de segurança, infraestrutura ou LGPD
> silenciosamente — mesmo quando `Ambíguo`, tratar como pendência, não como
> resposta suficiente.
> Toda pendência sem resposta está listada explicitamente como `[NEEDS CLARIFICATION]` no Encerramento acima.

---

## Saída Estruturada (para automação)

*Bloco opcional hoje, mas recomendado sempre que possível — reduz a
dependência de parsing de prosa livre pelo NIMBUS AGENT no roadmap da
`specs/018-nimbus-agent-intake/spec.md`. Preencher ao final, resumindo (não
substituindo) as respostas de prosa acima.*

```yaml
interview_output:
  feature_slug: "<kebab-case ou a-definir>"
  modo: "completo"          # completo | fast-track
  prioridade_inferida: "P2-medium"
  negocio:
    problema: "<resumo curto>"
    criterio_sucesso: "<resumo curto>"
    fora_de_escopo: "<resumo curto>"
    orcamento_aprovado: true   # true | false | "em validação"
    duplicidade_outro_time: false
    criterios_aceite:
      - "<C1 — comportamento observável, não adjetivo vago>"
      - "<C2>"
      - "<C3>"
      - "<C4>"
    quebra_proposta:
      avaliada: false          # true somente se 2+ sinais do Bloco 1.5 estavam presentes
      aceita: false            # true | false | "n/a — não avaliada"
      fatias: []               # ex.: ["<slug-fatia-a>", "<slug-fatia-b>"], se aceita
  infraestrutura:
    hospedagem: "<ex.: Azure, on-premise, a definir>"
    brownfield_ou_greenfield: "brownfield"   # brownfield | greenfield
    repositorios_ou_bounded_contexts:
      - "<repo/contexto afetado, ou 'a definir'>"
    duplicidade_reuse_catalog: false   # true se já existe padrão catalogado em docs/reuse-catalog.yaml para o mesmo domínio
    quem_acessa: "<ex.: usuários internos>"
  seguranca:
    dado_sensivel_negocio: false
    perfis_autorizacao: "<resumo curto ou a definir>"
  lgpd:
    dado_pessoal: false
    base_legal: "N/A — sem dado pessoal identificado"
  pendencias:
    - "<NEEDS CLARIFICATION 1, se houver>"
  duracao_real_minutos: 0
```

---

## Como este Modelo Evolui

*Este template está em ciclo de teste ativo (v1.3): a v1.2 introduziu todas
as perguntas e o modo Fast-Track de uma vez; a v1.3 mesclou o padrão de
entrevista de Product Owner (sugestão de critérios de aceite antes de validar,
e a proposta de quebra de demanda grande) preservando os 4 blocos obrigatórios
e as regras de não-adivinhação de infraestrutura/segurança/LGPD. Ambas as
mudanças continuam sendo medidas na prática antes de reduzir/expandir — não
em opinião.*

- Ao fechar uma feature cuja entrevista rodou neste modelo, registre no
  checklist de fechamento do `tasks.md` se a entrevista precisou de retrabalho
  (`spec.md` teve que ser reaberto por informação que a entrevista deveria ter
  capturado) — isso é candidato a entrada em `docs/harness/harness-catalog.yaml`.
- Se uma pergunta específica (ex.: uma das novas do Bloco 1) se mostrar
  consistentemente útil para acelerar o `/speckit-plan` ou evitar
  `[NEEDS CLARIFICATION]` tardio, isso é candidato a entrada em
  `docs/playbooks/success-catalog.yaml` — cite o número da pergunta.
- Se a seção de Critérios de Aceite (v1.3) reduzir retrabalho de `spec.md` de
  forma mensurável, ou se a Análise de Tamanho/Quebra (Bloco 1.5) se mostrar
  redundante com o que `/speckit-plan` já faz sozinho, documente no `retro.md`
  da feature — isso decide se o bloco é mantido, simplificado ou removido na
  próxima revisão.
- Se o modo Fast-Track (9 perguntas ⚡) se mostrar insuficiente para S0/S1 em
  algum caso real, ou se o modo Completo se mostrar redundante mesmo para
  S2+, documente no `retro.md` da feature (ver
  `presets/nimbus-code-standards/templates/feature-artifacts/retro-template.md`)
  — isso alimenta a próxima revisão deste template.
- Comparar `Duração real` (Cabeçalho) contra a meta (~10min Fast-Track,
  ~20–30min Completo) ao longo de várias entrevistas é o sinal mais direto de
  que o modelo está calibrado — desvio sistemático em qualquer direção é
  sinal de ajuste necessário, não de execução malfeita.
