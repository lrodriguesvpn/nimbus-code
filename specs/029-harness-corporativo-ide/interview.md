# Modelo de Entrevista de Descoberta — `029-harness-corporativo-ide`

<!--
  Guia de entrevista para a fase de DESCOBERTA (antes de escrever o spec.md).
  Feature: 029-harness-corporativo-ide

  Origem: esta entrevista consolida o assessment com GO condicional em
  `.specify/assessments/harness-consolidacao-corporativa/` (intake.md,
  research.md, problem.md, concept.md, decision.md — incluindo as 2 seções
  de "Atualização" do decision.md com respostas do solicitante) mais as
  respostas adicionais do solicitante aos 4 blocos formais da entrevista
  (Negócio, Infraestrutura, Segurança, LGPD), coletadas de forma assíncrona
  via `/nc-intake` (alias de `/speckit-interview`).

  Escopo v1 já fechado no gate de decisão (não reaberto aqui): Opção A do
  `concept.md` — extensão de `scripts/harvest-patterns.sh`, sempre on-demand,
  nunca CI/residente. Opção C (agente residente com varredura automática de
  endpoint) está fora de escopo deste ciclo.
-->

## Como usar este modelo

Conduzido de forma assíncrona: as perguntas já haviam sido levantadas nos
ciclos anteriores do assessment (`intake.md` → `research.md` → `problem.md`
→ `concept.md` → `decision.md`) e as lacunas remanescentes foram fechadas
diretamente pelo solicitante nos 4 blocos formais desta entrevista. Nenhuma
pergunta já respondida e fechada no `decision.md` (ciclo 2 — GO condicional)
foi reaberta aqui.

## Cabeçalho

| Campo | Valor |
|---|---|
| **Data** | 2026-09-22 |
| **Solicitante/Cliente** | Leonardo Rodrigues (patrocinador/dono orçamentário) |
| **Facilitador** | NC-Intake (Nimbus Agent) — alias institucional de `/speckit-interview` |
| **Canal** | assíncrono (consolidação de assessment + respostas escritas complementares) |
| **Feature slug** | `029-harness-corporativo-ide` |
| **Prioridade inferida (uso interno — não ler ao cliente)** | P1-high — patrocínio explícito do solicitante, prazo definido (fim do trimestre), mas escopo v1 deliberadamente restrito (piloto fechado) e com gate de execução (parecer Jurídico/DPO) ainda pendente antes de qualquer construção contra dados reais |
| **Versão deste modelo** | v1.3 |
| **Modo desta entrevista** | Completo |
| **Duração real** | N/A — consolidação assíncrona a partir de 5 artefatos de assessment prévios + respostas escritas complementares do solicitante (não houve sessão única cronometrada) |

---

## Bloco 1 — Negócio (o quê e por quê) — **obrigatório**

1. **Qual problema ou necessidade você está tentando resolver? Para quem?**
   - Cada um dos ~60 colaboradores que usam Claude Code e/ou Cursor.AI constrói,
     ao longo do tempo, um relacionamento pessoal e tácito com o LLM
     ("Harness Agêntico IDE": `~/.claude/CLAUDE.md`, `.cursor/rules`, prompts
     recorrentes, convenções próprias). Esse conhecimento fica preso à
     máquina/conta de cada um, se perde na saída/troca de time/ferramenta do
     colaborador, gera reinvenção redundante de soluções já resolvidas por
     colegas, e não alimenta a evolução do próprio Nimbus Code como processo
     de engenharia corporativa (herdado de `problem.md`, seções 1 e 3).
   - Público: os ~60 colaboradores (fonte do conhecimento), o Comitê Nimbus
     Code (triagem), os mantenedores do Nimbus Code (consumidores
     institucionais do conhecimento promovido).

2. **Como isso é feito hoje — manualmente, ou já existe um sistema/ferramenta que faz isso?**
   - Não existe hoje nenhum mecanismo de captura, nem institucional nem
     informal. `docs/harness/harness-catalog.yaml`, `docs/playbooks/success-catalog.yaml`
     e `docs/reuse-catalog.yaml` cobrem domínios vizinhos (erros/acertos por
     feature, padrões técnicos reutilizáveis), mas nenhum captura o
     relacionamento pessoal dev↔agente. `scripts/harvest-patterns.sh` já
     existe e é o precedente técnico mais próximo, mas hoje varre apenas
     metadados estruturais de código versionado de um repo já clonado —
     nunca texto livre pessoal (confirmado em `research.md`, seção 2.3, e
     `concept.md`, seção 3, Opção A).

3. **O que "pronto" significa para você — como saberemos que funcionou?**
   - Critério de sucesso da v1 piloto é **principalmente qualitativo**:
     "melhoria do processo por ter o Harness novo colocado em produção" —
     não é uma meta de quantidade. Mantém-se, como target numérico auxiliar
     (não como critério único), **5 promoções/mês** a Harness Corporativo
     pelo Comitê Nimbus Code.
   - Piloto restrito (não os 60 colaboradores de imediato) deve estar em
     produção até o fim deste trimestre.

4. **Quem usa isso no dia a dia (perfis/papéis)?**
   - Colaborador individual (executa o harvester estendido on-demand contra
     seu próprio Harness Agêntico IDE).
   - Comitê Nimbus Code — 4 pessoas, papéis já claros e definidos
     internamente — administra o acesso ao repositório central e realiza a
     triagem manual humana de promoção. `[NEEDS CLARIFICATION: comite-composicao]`
     nomes e papéis individuais dos 4 membros não foram informados nesta
     entrevista — registrar como pendência de detalhe, não como bloqueio.
   - Mantenedores do Nimbus Code — consomem o Harness Corporativo promovido
     para evoluir presets/skills/catálogos.

5. **O que definitivamente não faz parte deste pedido agora (fora de escopo)?**
   - Opção C do `concept.md` (agente residente com varredura automática de
     todos os endpoints da empresa) — **fora de escopo**, condicionada a
     evidência futura de que a Opção A é insuficiente e a parecer específico
     de Segurança de Endpoint/TI e avaliação formal de `/nc-shield`, nenhuma
     das quais foi avaliada neste ciclo.
   - Opção B do `concept.md` (pipeline paralelo dedicado) — também fora de
     escopo deste ciclo (o GO condicional restringiu explicitamente à Opção A).
   - Qualquer execução automática/residente ou em CI — o mecanismo é sempre
     on-demand, iniciado por um humano.
   - Envio de texto livre cru (sem anonimização) ao LLM externo
     (`HARVEST_API_URL`).
   - Rollout aos 60 colaboradores nesta entrega — a v1 é restrita ao piloto
     (ver pergunta 6).

6. **Existe prazo ou evento que torna isso urgente?**
   - Sim: piloto v1 até o fim deste trimestre.

7. **Se só pudesse resolver 1 coisa nesta entrega, qual seria?**
   - Validar, com o esquadrão/mantenedores do Nimbus Code como piloto
     restrito, que a extensão de `scripts/harvest-patterns.sh` (Opção A) é
     capaz de capturar Harness Agêntico IDE real, passar pela triagem manual
     do Comitê, e gerar pelo menos algumas promoções reais a Harness
     Corporativo — comprovando o processo de ponta a ponta antes de
     qualquer expansão aos 60.

8. **Quem dá o aceite final? E quem, se discordar, consegue travar isso mesmo depois de aprovado?**
   - Aceite final: Leonardo Rodrigues (patrocinador/dono orçamentário).
   - Pode travar mesmo após aprovação: Jurídico/DPO (parecer formal sobre a
     redação da cláusula do NDA ampliado e sobre a política de
     retenção/expurgo — hoje apenas encaminhado, não obtido; é um gate de
     **execução**, não de especificação — herdado de `decision.md`, ciclo 2);
     o Comitê Nimbus Code (nenhuma promoção acontece sem a triagem dos 4
     membros).

9. **Já foi tentado algo parecido antes que não funcionou?**
   - Não houve tentativa anterior de consolidação de harness pessoal. As
     Opções B (pipeline paralelo) e C (agente residente) foram desenhadas e
     comparadas lado a lado em `concept.md`, mas descartadas para o v1 por
     risco/custo desproporcionais ao valor ainda não comprovado — não é um
     "já tentamos e falhou", é uma decisão consciente de sequenciamento
     (começar pela opção de menor custo e risco, medir, só então escalar).
   - Confirmado por pesquisa de mercado (`research.md`, seção 1): nenhum dos
     três fornecedores (Anthropic, Cursor, GitHub) resolve nativamente a
     mineração bottom-up (individual → institucional) que esta ideia propõe.

10. **O que essa demora está custando hoje?**
    - Perda irrecuperável de harness pessoal na saída/troca de colaborador;
      reinvenção redundante de prompts/regras já resolvidos por colegas;
      inconsistência de qualidade entre devs com harness pessoal maduro vs.
      sem customização; ausência de *feedback loop* de uso real de campo
      para evoluir o próprio Nimbus Code (herdado de `problem.md`, seção 3,
      dores 1 a 4).

11. **Algum outro time ou projeto já está trabalhando em algo parecido?**
    - Não. Os artefatos institucionais vizinhos já existentes
      (`docs/harness/harness-catalog.yaml`, `docs/playbooks/success-catalog.yaml`,
      `docs/reuse-catalog.yaml`, `scripts/harvest-patterns.sh`,
      `specs/011-harness-engineering/`, `specs/022-nimbuscode-harvest-gateway/`)
      foram checados e confirmados como não-duplicados (`problem.md`, seção
      1; `research.md`, seção 2) — nenhum cobre o relacionamento tácito
      dev↔agente no nível individual.

12. **Já existe orçamento/patrocínio aprovado para isso, ou ainda estamos validando viabilidade?**
    - Aprovado. Patrocinador: Leonardo Rodrigues. O assessment
      (`harness-consolidacao-corporativa`) já recebeu **GO condicional**,
      restrito à Opção A, no ciclo 2 do `decision.md`.

### Critérios de Aceite — **mínimo 4 critérios mensuráveis**

- **C1 — Captura sempre on-demand, nunca CI/residente:** a extensão de
  `scripts/harvest-patterns.sh` para ler `~/.claude/CLAUDE.md` / `.cursor/rules`
  só é executada mediante invocação manual e explícita de um humano (dev ou
  membro do esquadrão Nimbus). Nenhuma automação contínua, agendada ou
  residente em endpoint é aceitável na v1.
- **C2 — Escrita sempre no repositório central dedicado:** toda saída do
  harvester estendido é redirecionada (via `--output` ou variável de
  ambiente equivalente) para o repositório GHE central dedicado (ex.:
  `nimbus-code-harness-corporativo`) — nunca para o `docs/reuse-catalog.yaml`
  (ou equivalente) do repositório de trabalho do dev.
- **C3 — Anonimização/redação prévia obrigatória antes de LLM externo:**
  qualquer texto livre do Harness Agêntico IDE só é enviado a
  `HARVEST_API_URL` (LLM externo) após passar por um passo automático de
  anonimização/redação — nunca em texto cru, e nunca com o envio
  completamente desviado/suprimido.
- **C4 — Promoção somente via triagem manual humana do Comitê Nimbus Code:**
  nenhum item de Harness Agêntico IDE bruto vira Harness Corporativo sem
  revisão explícita de um dos 4 membros do Comitê — sem exceção, e sem
  caminho de promoção automática.
- **C5 — Expurgo automático de harness bruto não promovido em 3 meses:** todo
  material de Harness Agêntico IDE que chega ao repositório central e não é
  promovido dentro de 3 meses é automaticamente expurgado.
- **C6 — Redistribuição pós-promoção opcional e idempotente (Etapa 2):**
  quando o Comitê classifica um item de Harness Corporativo como específico
  de um bounded context/projeto, a redistribuição de volta ao(s) repo(s)
  satélite reaproveita o mecanismo idempotente já existente no `bootstrap.sh`
  (nunca sobrescreve customização local já feita no repo de destino).
- **C7 — Sucesso do piloto restrito (qualitativo + auxiliar quantitativo):**
  até o fim deste trimestre, o piloto restrito ao esquadrão/mantenedores do
  Nimbus Code demonstra, de forma qualitativa, melhoria de processo por ter
  o Harness Corporativo em produção; o valor de 5 promoções/mês é mantido
  como sinal auxiliar de acompanhamento, não como critério único de sucesso.

---

## Bloco 1.5 — Análise de Tamanho / Proposta de Quebra

Sinais avaliados: múltiplos perfis de usuário (colaborador, Comitê,
mantenedores), múltiplas etapas de fluxo (captura → agregação → triagem →
promoção → redistribuição opcional) e classificação de risco provável S3–S4
(herdada do precedente `specs/022-nimbuscode-harvest-gateway/`). Embora dois
ou mais sinais estejam tecnicamente presentes, **não se propõe quebra em
múltiplas features aqui** — o gate de decisão do assessment
(`decision.md`, ciclo 2) já fechou o escopo como uma única iniciativa restrita
à Opção A, com um modelo de 2 etapas (captura+triagem sempre obrigatória;
redistribuição opcional condicional) tratado como sequência interna da mesma
feature, não como fatias separadas. Reabrir essa decisão de fatiamento não é
escopo desta entrevista.

**Decisão registrada**: manter como feature única (`029-harness-corporativo-ide`),
sem quebra adicional.

---

## Bloco 2 — Infraestrutura — **obrigatório**

1. **Onde isso vai rodar/ser hospedado?**
   - O script estendido roda localmente na máquina do dev (on-demand). O
     destino de escrita é sempre o **repositório central dedicado**: um novo
     repositório GHE (ex.: `nimbus-code-harness-corporativo`). Nunca
     roda como serviço hospedado contínuo, nunca em CI.

2. **Isso é uma mudança dentro de um sistema que já existe (brownfield), ou é construído do zero (greenfield)?**
   - Brownfield: extensão direta de `scripts/harvest-patterns.sh`, já
     existente e maduro no template Nimbus Code (originado em
     `specs/014-brownfield-multirepo-context-awareness/`). Reaproveita também
     o mecanismo idempotente de distribuição do `bootstrap.sh`
     (`refresh_managed_project_root_files`) para a Etapa 2 opcional.

3. **Já existe um padrão, bounded context ou repositório de referência que essa solução deve seguir? Quais repositórios concretos são afetados?**
   - Padrões de referência: `scripts/harvest-patterns.sh` (mecanismo de
     captura e allowlist), `docs/harness/harness-catalog.yaml` +
     `harness-guide.md` (fluxo de triagem via Issue `harness:pending` →
     `harness:cataloged`, usado como analogia de processo, não como destino
     de escrita), `bootstrap.sh` (distribuição idempotente).
   - Repositórios concretos afetados: o repositório-template do Nimbus Code
     (onde `scripts/harvest-patterns.sh` é estendido), o **novo repositório
     GHE central dedicado** (`nimbus-code-harness-corporativo` ou nome
     equivalente a definir em `/nc-spec`), e — apenas na Etapa 2 opcional —
     repositórios satélite de bounded context específico.
   - `docs/reuse-catalog.yaml` já é consultado como precedente, mas **não
     duplicado** — o Harness Corporativo é tratado como um artefato
     conceitualmente distinto (destino final exato — novo artefato vs.
     extensão de catálogo existente — fica para `/nc-spec`/`/nc-arch`,
     conforme já registrado em `decision.md`, ciclo 2).

4. **Quem ou o quê vai acessar isso?**
   - Piloto v1: apenas o esquadrão/mantenedores do Nimbus Code (critério de
     seleção do piloto, conforme resposta do solicitante). Rollout completo
     aos 60 colaboradores é etapa posterior, não coberta por este ciclo.
   - Administração de acesso ao repositório central: o próprio
     time/Comitê Nimbus Code.

5. **Existe expectativa de volume?**
   - Piloto restrito: baixo volume inicial (apenas o esquadrão/mantenedores).
     Potencial total (pós-rollout, fora deste ciclo): até 60 colaboradores,
     dos quais 60 usam Claude Code e ~10 também usam Cursor.AI (uso
     combinado, não exclusivo — dado confirmado em `decision.md`, ciclo 2).
     Target auxiliar de throughput de triagem: 5 promoções/mês.

6. **Depende de integração com algum sistema já existente?**
   - GHE (novo repositório central dedicado), `HARVEST_API_URL` (endpoint LLM
     externo configurável, já existente no `harvest-patterns.sh`, agora com
     anonimização/redação prévia obrigatória para conteúdo de Harness
     Agêntico IDE), `bootstrap.sh` (mecanismo idempotente de redistribuição
     na Etapa 2 opcional).

7. **Isso pode ficar fora do ar de vez em quando, ou precisa estar sempre disponível?**
   - Não se aplica no sentido tradicional de uptime/SLO — não é um serviço
     residente. O repositório central precisa estar acessível quando um dev
     ou membro do Comitê interage com ele, mas não há exigência de
     disponibilidade contínua 24/7 nem SLA formal nesta v1.

---

## Bloco 3 — Segurança — **obrigatório**

1. **Este sistema expõe alguma informação sensível ou crítica para o negócio?**
   - Sim. O Harness Agêntico IDE é, por definição, texto livre escrito por
     humanos e pode conter convenções internas, propriedade intelectual,
     nomes/dados de projetos e clientes, e potencialmente segredos colados
     acidentalmente em prompts (herdado de `research.md`, seção 3, e
     `concept.md`, seção 3, Opção A — trade-off central já reconhecido: a
     allowlist estrita do `harvest-patterns.sh` original reduz esse risco,
     mas também reduz o valor central da consolidação se aplicada sem
     ajuste).

2. **Quem pode e quem não pode acessar (perfis de autorização)?**
   - Comitê Nimbus Code (4 pessoas) administra o acesso ao repositório
     central e é o único grupo autorizado a promover conteúdo a Harness
     Corporativo. Colaborador individual só interage com seu próprio Harness
     Agêntico IDE bruto (captura/envio). Mantenedores do Nimbus Code acessam
     o Harness Corporativo já promovido. Composição individual (nomes/papéis
     específicos dos 4 membros do Comitê) não foi detalhada nesta entrevista
     — ver `[NEEDS CLARIFICATION: comite-composicao]`.

3. **Existe exigência de autenticação corporativa (SSO/AD) ou pode usar um padrão mais simples?**
   - Autenticação via GHE corporativo (mesmo padrão institucional já usado
     nos demais repositórios do Nimbus Code) — formato exato de autenticação
     e RBAC fino no repositório central fica para detalhamento em
     `/nc-spec`/`/nimbus-code-plan`.

4. **Há necessidade de auditoria/trilha de "quem fez o quê"?**
   - Sim — herdado do padrão S4 já aplicado ao precedente mais próximo
     (`specs/022-nimbuscode-harvest-gateway/`). Formato exato da trilha
     (o quê, quem, quando) é detalhamento técnico de plan, não desta
     entrevista.

**Decisão explícita sobre `HARVEST_API_URL` (LLM externo)** — resposta direta
do solicitante à pergunta em aberto deixada por `decision.md` (ciclo 2, "ponto
novo identificado"): o texto livre do Harness Agêntico IDE é enviado ao LLM
externo **apenas após anonimização/redação automática prévia** — nem envio
cru, nem desvio total do envio. Se esta anonimização automática falhar ou for
insuficiente, isso deve ser tratado como bloqueio de execução (gate de
segurança), não como detalhe a resolver depois.

---

## Bloco 4 — LGPD / Proteção de Dados — **obrigatório**

1. **Este pedido envolve dado pessoal?**
   - Sim. Harness Agêntico IDE pode conter, por natureza, dado pessoal do
     próprio colaborador (identidade, estilo de trabalho, preferências) e,
     potencialmente, dado pessoal de terceiros citados em prompts (nomes de
     clientes, colegas, projetos).

2. **De quem são esses dados?**
   - Colaboradores internos (fonte primária) e, potencialmente, terceiros/
     clientes mencionados no conteúdo de prompts/instruções.

3. **Qual a base legal para tratar esse dado?**
   - NDA ampliado: todos os colaboradores e clientes da VPN já possuem NDA
     vigente; o solicitante incluirá uma cláusula específica autorizando o
     armazenamento de prompts/harness agêntico como parte desse NDA.
     **Pendente**: validação formal de Jurídico/DPO sobre a redação exata
     dessa cláusula — hoje apenas encaminhado, não obtido (gate de
     **execução**, não bloqueia a abertura da spec, mas bloqueia
     `/nimbus-code-plan` iniciar construção contra dados reais, conforme
     `decision.md`, ciclo 2).

4. **Esses dados têm prazo de retenção definido, ou existe pedido de exclusão a considerar?**
   - Sim: harness bruto **não promovido** pelo Comitê é expurgado
     automaticamente em **3 meses**. Prazo de retenção do Harness Corporativo
     já **promovido** não foi definido nesta entrevista — fica para
     `/nc-spec`/`/nimbus-code-plan`, condicionado também ao parecer de
     Jurídico/DPO.

5. **Esse dado sai da organização (parceiro, fornecedor terceiro, nuvem fora do país)?**
   - Potencialmente sim, para o LLM externo via `HARVEST_API_URL` — mas
     **somente conteúdo já anonimizado/redigido previamente**, nunca texto
     livre cru (ver decisão do Bloco 3). Se a chamada a este LLM externo for
     mantida na implementação final, o escopo do parecer de Jurídico/DPO
     precisa cobrir também esse fornecedor (DPA), não apenas o armazenamento
     interno no repositório central — conforme já registrado em
     `decision.md`, ciclo 2, "Gate de execução", item 2.

### ⚠️ Tensão de tratamento LGPD registrada explicitamente (não resolvida aqui)

O solicitante confirmou que o tratamento com o rigor de "dado sensível de
cliente" **não** se aplica desde a captura — só passa a valer **depois** que
o Comitê classificar o conteúdo como sensível. Ao mesmo tempo, existe um
**controle técnico obrigatório de redação/anonimização desde a captura**
(Bloco 3, decisão sobre `HARVEST_API_URL`), aplicável à chamada ao LLM
externo independentemente da classificação do Comitê.

Isso gera uma tensão real entre dois níveis de tratamento que coexistem no
mesmo fluxo:

- **Nível técnico** (chamada ao LLM externo): controle de anonimização
  aplicado **desde a captura**, incondicionalmente.
- **Nível administrativo/de acesso** (tratamento como "dado sensível de
  cliente" para fins de restrição de acesso interno, retenção diferenciada,
  etc.): só passa a valer **oficialmente** após a triagem/classificação do
  Comitê Nimbus Code.

Esta entrevista **não resolve** essa tensão — apenas a registra
explicitamente, conforme instrução do solicitante, como ponto a validar
formalmente com Jurídico/DPO antes que a especificação assuma qualquer uma
das duas leituras como definitiva. `[NEEDS CLARIFICATION: lgpd-tensao-classificacao]`.

---

## Encerramento

- **Resumo em 3–5 linhas**: A feature `029-harness-corporativo-ide` implementa
  a Opção A do assessment `harness-consolidacao-corporativa` (GO condicional):
  extensão on-demand de `scripts/harvest-patterns.sh` para capturar Harness
  Agêntico IDE (`~/.claude/CLAUDE.md`, `.cursor/rules`) dos ~60 colaboradores
  (60 usam Claude Code, ~10 também Cursor.AI), sempre escrevendo em um
  repositório central dedicado (nunca no repo de trabalho do dev), com
  triagem manual humana obrigatória do Comitê Nimbus Code (4 pessoas) antes
  de qualquer promoção a Harness Corporativo, redistribuição opcional
  pós-promoção via mecanismo idempotente do `bootstrap.sh`, anonimização
  obrigatória antes de qualquer envio a LLM externo, e expurgo automático em
  3 meses do harness bruto não promovido. Piloto v1 restrito ao
  esquadrão/mantenedores do Nimbus Code, com meta até o fim deste trimestre,
  critério de sucesso principalmente qualitativo (auxiliado por 5
  promoções/mês). Base legal: NDA ampliado, com redação ainda pendente de
  validação formal de Jurídico/DPO.
- **Pendências / `[NEEDS CLARIFICATION]`**:
  - `[NEEDS CLARIFICATION: comite-composicao]` Nomes e papéis individuais
    dos 4 membros do Comitê Nimbus Code não foram informados — apenas que
    são 4 pessoas com papéis já claros e definidos internamente.
  - `[NEEDS CLARIFICATION: turnover-real]` Valor exato de turnover dos ~60
    colaboradores não foi informado — registrado como hipótese razoável
    ("baixo"), não como fato, para fins de priorização.
  - `[NEEDS CLARIFICATION: lgpd-tensao-classificacao]` Tensão entre o
    controle técnico de anonimização obrigatório desde a captura (para a
    chamada ao LLM externo) e o tratamento administrativo/de acesso como
    "dado sensível de cliente" que só passa a valer oficialmente após
    classificação do Comitê — ponto explicitamente não resolvido aqui,
    a validar formalmente com Jurídico/DPO.
  - `[NEEDS CLARIFICATION: parecer-juridico-dpo]` Parecer formal de
    Jurídico/DPO sobre a redação da cláusula do NDA ampliado e sobre a
    política de retenção/expurgo — hoje apenas encaminhado, não obtido.
    Gate de **execução** (não bloqueia `/nc-spec`, bloqueia
    `/nimbus-code-plan` iniciar construção contra dados reais).
- **Responsável por validar o spec.md gerado**: Leonardo Rodrigues
  (patrocinador) + Comitê Nimbus Code; validação formal de Jurídico/DPO
  obrigatória antes de qualquer execução contra dados reais.
- **Duração real desta entrevista**: N/A (consolidação assíncrona).

---

## Checklist de Cobertura Mínima

| Item | Estado (Coberto / Ambíguo / Ausente) | Nota |
|---|---|---|
| Objetivo de negócio (o quê e por quê) | Coberto | Perda de harness pessoal, reinvenção, falta de feedback loop institucional |
| Critério de sucesso/pronto (entrega + sustentado) | Coberto | Qualitativo (processo melhorado) + 5 promoções/mês auxiliar; piloto até fim do trimestre |
| Perfis de usuário identificados | Coberto | Colaborador, Comitê Nimbus Code (4 pessoas), mantenedores Nimbus Code |
| Escopo fora (o que não é) | Coberto | Opções B e C fora de escopo; nunca CI/residente; nunca envio cru a LLM |
| Critérios de aceite (mínimo 4, mensuráveis) | Coberto | 7 critérios (C1–C7) |
| Infraestrutura: hospedagem ou padrão de referência | Coberto | Repo GHE central dedicado; extensão de `harvest-patterns.sh` |
| Infraestrutura: brownfield/greenfield indicado | Coberto | Brownfield |
| Infraestrutura: repositórios/bounded contexts afetados | Coberto | Repo-template, novo repo central, repos satélite (Etapa 2 opcional) |
| Infraestrutura: quem acessa | Coberto | Piloto: esquadrão/mantenedores; administração: Comitê Nimbus Code |
| Segurança: sensibilidade/exposição | Coberto | Texto livre pode conter PI, dados de cliente, segredos acidentais |
| Segurança: perfis de autorização | Ambíguo | Comitê administra acesso, mas composição individual não detalhada — ver `[NEEDS CLARIFICATION: comite-composicao]` |
| LGPD: presença ou ausência de dado pessoal | Coberto | Sim — dado do colaborador e potencialmente de terceiros citados em prompts |
| LGPD: base legal (ou pendência para jurídico/DPO) | Ambíguo | NDA ampliado decidido, mas parecer formal de redação/retenção ainda pendente — ver `[NEEDS CLARIFICATION: parecer-juridico-dpo]` |

---

## Saída Estruturada (para automação)

```yaml
interview_output:
  feature_slug: "029-harness-corporativo-ide"
  modo: "completo"
  prioridade_inferida: "P1-high"
  negocio:
    problema: "Harness Agêntico IDE pessoal dos ~60 colaboradores (Claude Code/Cursor.AI) fica preso à máquina de cada um, se perde na saída/troca, gera reinvenção e não alimenta o Nimbus Code institucional."
    criterio_sucesso: "Qualitativo — melhoria do processo por ter Harness Corporativo em produção no piloto restrito; 5 promoções/mês como target auxiliar."
    fora_de_escopo: "Opções B e C do concept.md; execução automática/CI/residente; envio cru a LLM externo; rollout aos 60 nesta entrega."
    orcamento_aprovado: true
    duplicidade_outro_time: false
    criterios_aceite:
      - "C1: Captura sempre on-demand, nunca CI/residente."
      - "C2: Escrita sempre no repositório central dedicado, nunca no repo de trabalho do dev."
      - "C3: Anonimização/redação prévia obrigatória antes de envio a HARVEST_API_URL (LLM externo)."
      - "C4: Promoção somente via triagem manual humana do Comitê Nimbus Code (4 pessoas)."
      - "C5: Expurgo automático de harness bruto não promovido em 3 meses."
      - "C6: Redistribuição pós-promoção opcional via mecanismo idempotente do bootstrap.sh."
      - "C7: Sucesso do piloto restrito qualitativo, com 5 promoções/mês como sinal auxiliar."
    quebra_proposta:
      avaliada: true
      aceita: false
      fatias: []
  infraestrutura:
    hospedagem: "Execução local on-demand na máquina do dev; escrita sempre no novo repositório GHE central dedicado (ex.: nimbus-code-harness-corporativo)"
    brownfield_ou_greenfield: "brownfield"
    repositorios_ou_bounded_contexts:
      - "repositório-template Nimbus Code (extensão de scripts/harvest-patterns.sh)"
      - "novo repositório GHE central dedicado (Harness Corporativo)"
      - "repos satélite de bounded context específico (Etapa 2, opcional)"
    duplicidade_reuse_catalog: false
    quem_acessa: "Piloto: esquadrão/mantenedores do Nimbus Code; administração de acesso: Comitê Nimbus Code"
  seguranca:
    dado_sensivel_negocio: true
    perfis_autorizacao: "Comitê Nimbus Code (4 pessoas, administra acesso e triagem) — composição individual não detalhada [NEEDS CLARIFICATION: comite-composicao]"
  lgpd:
    dado_pessoal: true
    base_legal: "NDA ampliado (cláusula específica em redação) — parecer formal de Jurídico/DPO encaminhado, não obtido [NEEDS CLARIFICATION: parecer-juridico-dpo]"
  pendencias:
    - "[NEEDS CLARIFICATION: comite-composicao] Nomes/papéis individuais dos 4 membros do Comitê Nimbus Code."
    - "[NEEDS CLARIFICATION: turnover-real] Valor exato de turnover dos ~60 colaboradores (hoje apenas hipótese 'baixo')."
    - "[NEEDS CLARIFICATION: lgpd-tensao-classificacao] Tensão entre controle técnico de anonimização desde a captura e tratamento administrativo de 'dado sensível' só após classificação do Comitê — validar com Jurídico/DPO."
    - "[NEEDS CLARIFICATION: parecer-juridico-dpo] Parecer formal de Jurídico/DPO sobre redação da cláusula do NDA e política de retenção/expurgo — hoje apenas encaminhado."
  duracao_real_minutos: 0
```
