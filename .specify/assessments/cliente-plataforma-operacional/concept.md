# Concept: Operação separada de cliente e plataforma

- **Slug**: cliente-plataforma-operacional
- **Created**: 2026-09-21T15:41:40-03:00
- **Updated (Round 2)**: 2026-09-22T08:10:06-03:00
- **Inputs used**: problem.md (Round 2, 2026-09-22) | research.md (Round 1 & Round 2) | intake.md (Round 1 & Round 2) | decision.md (verdict anterior: needs-clarification)
- **Recommended option**: Option B — Repo Plataforma como modelo de referência com critério formal de vínculo CMDB↔IaC

## Contexto do conceito (atualizado na Round 2)

A Round 2 do problema trouxe evidência direta e concreta que muda a forma das
opções em relação à Round 1:

- `venha-pra-nuvem-client-platform` **já é a instância real em produção** do
  padrão deste template, operando o serviço comercial **GSN Premium**
  (managed services). Não é um concorrente nem um exemplo hipotético — é
  prova de demanda validada.
- `vpn-nibo-connect` + `vpn-nibo-connect-iac` é **prior art em produção** do
  princípio "Repo First Company": aplicação e IaC/estado já vivem em
  repositórios separados, com plano somente leitura em PR, apply manual
  protegido e WIF sem chaves estáticas.
- **Nuvem 365** (`nuvem365-nimbuscode-spec`) é confirmado como o produto SaaS
  de FinOps multi-tenant voltado a clientes finais — domínio de negócio
  distinto de Managed Services, sem IaC própria versionada em nenhum de seus
  repositórios satélite hoje.
- O `005-cmdb-gcp` do Nuvem 365 e o CMDB de Managed Services (este template /
  `venha-pra-nuvem-client-platform`) são **domínios separados**, sem
  unificação exigida nesta rodada.

Isso reduz a pergunta central de "que topologia adotar, no abstrato" para uma
decisão concreta já enquadrada pelo problema atualizado: **este template
continua sendo o modelo de referência/gerador do qual cada cliente de managed
services (como GSN Premium) deriva sua própria instância, ou evolui para um
motor central único que atende múltiplos clientes sem repositório de instância
próprio?** Em paralelo, falta o critério objetivo para decidir, por ativo,
quando ele ganha um repositório de IaC dedicado (modelo `vpn-nibo-connect-iac`)
versus quando permanece apenas como inventário dentro do Repo Plataforma.

As opções abaixo continuam deliberadamente conceituais — não escolhem stack,
schema de dados ou arquitetura de sistema. Isso pertence ao ciclo de
especificação (SDD), após o gate de decisão.

## Options

### Option A — Formalizar o vínculo CMDB↔IaC no modelo atual (mínimo viável)

- **Sketch**: Sem alterar a topologia (o template continua modelo de
  referência/gerador, como hoje), formalizar apenas o **modelo de vínculo**
  entre o Repo Plataforma de um cliente (ex.: `venha-pra-nuvem-client-platform`
  para GSN Premium) e repositórios de IaC dedicados existentes (ex.:
  `vpn-nibo-connect-iac`): uma entrada de CMDB por ativo que aponta para
  "repo de código + repo de IaC dedicado (se houver)". Junto disso, redigir e
  aplicar um critério objetivo e documentado (porte do ativo, criticidade,
  exigência contratual de isolamento) para decidir "repo de IaC dedicado" vs.
  "apenas inventário/IaC inline no Repo Plataforma", usando `vpn-nibo-connect`
  e ao menos um ativo sem repo dedicado como casos de teste. Nuvem 365 é
  tratado apenas como candidato futuro a esse mesmo critério, sem mudança
  nesta rodada.
- **Appetite**: small (dias)
- **Trade-offs**: Aproveita 100% do que já está em produção
  (`venha-pra-nuvem-client-platform`, `vpn-nibo-connect-iac`) e resolve a
  lacuna mais barata e mais bloqueante para qualquer opção maior — sem o
  critério de vínculo, nem B nem C conseguem operar de forma consistente.
  Baixíssimo risco, nenhuma mudança de arquitetura. Em contrapartida, não
  decide a pergunta arquitetural de fundo (modelo de referência vs. motor
  central) e não avança a integração com FinOps/Nuvem 365 além de deixá-la
  pronta para ser encaixada depois.
- **Rabbit holes**: tentar decidir a topologia definitiva (gerador vs. motor
  central) dentro desta opção; migrar `vpn-nibo-connect-infra` ou investigar
  sua duplicidade com `-iac` antes de resolver o vínculo básico; desenhar
  schema de dados do CMDB em detalhe; iniciar qualquer integração real com
  Nuvem 365.

### Option B — Repo Plataforma como modelo de referência com critério formal de vínculo CMDB↔IaC

- **Sketch**: Inclui o núcleo da Option A e adiciona a decisão explícita de
  **manter o template como modelo de referência/gerador** (papel já
  confirmado por `venha-pra-nuvem-client-platform`), formalizando o processo
  pelo qual uma nova instância de Repo Plataforma é criada por cliente de
  managed services. Padroniza nomenclatura de repositórios de IaC dedicados
  (resolvendo a dúvida `-iac` vs. `-infra`), documenta o padrão "Repo First
  Company" como um ADR/pattern nomeado da organização, e desenha — em nível
  conceitual, não técnico — como um futuro bounded context `infra` do Nuvem
  365 (já previsto em `docs/bounded-contexts.yaml` mas nunca criado) se
  encaixaria no mesmo critério de vínculo, sem criar essa infraestrutura
  ainda. O piloto mede localização, rastreabilidade e tempo de auditoria em
  pelo menos dois clientes reais (GSN Premium via `venha-pra-nuvem-client-platform`
  e um segundo caso).
- **Appetite**: medium (semanas)
- **Trade-offs**: Resolve a pergunta arquitetural central sem assumir o
  risco e o custo de um motor central multi-tenant ainda não demandado.
  Aproveita diretamente a instância real já em produção como prova, em vez de
  tratá-la como hipótese. Formaliza "Repo First Company" como prática nomeada
  da empresa, o que facilita replicar para Nuvem 365 depois. O risco
  principal é manter, por cliente, uma instância própria do Repo Plataforma —
  o que significa que reuso de padrões continua dependendo de disciplina de
  versionamento e propagação manual/assistida entre instâncias, não de um
  motor único.
- **Rabbit holes**: construir tooling de scaffolding/geração automática de
  novas instâncias antes de validar o processo manualmente em 2 clientes;
  integrar de fato o CMDB de Managed Services com o `005-cmdb-gcp` do Nuvem
  365; criar o bounded context `infra` do Nuvem 365 nesta rodada; prometer
  self-service para times de cliente final.

### Option C — Motor central único multi-cliente para Managed Services

- **Sketch**: Evoluir `platform-governance/` (ou seu equivalente) de modelo
  de referência/gerador para um **motor central único**: uma única aplicação
  operacional que atende múltiplos clientes de managed services (GSN Premium
  e futuros clientes) sem exigir uma instância própria de Repo Plataforma por
  cliente — `venha-pra-nuvem-client-platform` seria migrado ou aposentado em
  favor desse motor central, que manteria isolamento por tenant/cliente
  internamente (dados, RBAC, evidências) em vez de por repositório. O mesmo
  motor central poderia, no limite, também absorver o vínculo com repositórios
  de IaC dedicados de clientes e, futuramente, servir de base para uma
  integração mais profunda com o domínio FinOps do Nuvem 365.
- **Appetite**: large (meses)
- **Trade-offs**: Maior potencial de reuso, consistência entre clientes e
  eficiência operacional de longo prazo — elimina a necessidade de propagar
  mudanças manualmente entre instâncias. Em troca, exige migrar ou aposentar
  uma instância que já está em produção (`venha-pra-nuvem-client-platform`),
  redesenhar isolamento multi-tenant (dados, secrets, RBAC, evidência) que
  hoje é garantido "de graça" pela separação física em repositórios/instâncias
  distintas, e assume um risco de blast radius maior por concentrar múltiplos
  clientes num único sistema. Não há hoje evidência de volume de clientes de
  managed services que justifique esse investimento antes de medir o piloto
  da Option B.
- **Rabbit holes**: migrar `venha-pra-nuvem-client-platform` para o motor
  central antes de provar valor incremental; desenhar multi-tenancy genérico
  para qualquer futuro cliente; unificar precocemente com o CMDB do Nuvem 365
  (`005-cmdb-gcp`); tratar esta opção como necessária para resolver a lacuna
  de vínculo CMDB↔IaC, que a Option A já resolve a um custo muito menor.

## Topologia confirmada (Option B) — esclarecimento do usuário

O usuário confirmou explicitamente a granularidade que ficava implícita nas
opções acima. Registrando de forma inequívoca, para não depender de
interpretação em rodadas futuras:

- **Um Repo Plataforma central por CLIENTE** — não por projeto, não um único
  motor para toda a carteira (isso seria a Option C, não aprovada). Exemplo
  real já em produção: o cliente "Venha Pra Nuvem" (serviço GSN Premium) tem
  um único Repo Plataforma central, `venha-pra-nuvem-client-platform`, que
  concentra CMDB, baselines, evidence registry e drift policy desse cliente.
- **Um repositório de IaC dedicado por PROJETO/ativo** dentro de um cliente,
  quando o critério objetivo da Option A indicar necessidade (porte,
  criticidade, exigência contratual de isolamento). Exemplo real: o projeto
  "NIBO", dentro do cliente Venha Pra Nuvem, tem seu próprio repo de IaC
  dedicado, `vpn-nibo-connect-iac`, separado do repo de aplicação
  (`vpn-nibo-connect`) e do Repo Plataforma central do cliente.
- **Vínculo, não duplicação**: o Repo Plataforma central do cliente registra
  uma entrada de CMDB por projeto, apontando para "repo de aplicação + repo
  de IaC dedicado" quando este existir. Não recria nem espelha o conteúdo
  Terraform do projeto.
- **Projetos sem repo de IaC dedicado** (abaixo do limiar do critério
  objetivo) permanecem **apenas como inventário + IaC inline** dentro do
  próprio Repo Plataforma central do cliente — nunca ficam sem nenhum lugar
  formal de registro.

Resumo da hierarquia: **1 cliente → 1 Repo Plataforma central → N projetos**,
cada projeto **ou** com repo de IaC dedicado próprio (linkado pelo central),
**ou** apenas inventariado/IaC inline dentro do central. Essa é a topologia
que a Option B assume e que a especificação formal deve tratar como modelo
de dados obrigatório do CMDB (relação cliente → projeto → [repo de IaC
dedicado | inventário inline]).

## Recommendation

Recomenda-se **Option B — Repo Plataforma como modelo de referência com
critério formal de vínculo CMDB↔IaC**, com a topologia acima (central por
cliente, IaC dedicado por projeto) como parte do escopo, não apenas como
ilustração.

Essa opção é a melhor combinação provisória entre os objetivos do problema
atualizado:

- responde diretamente à pergunta arquitetural que a Round 2 do research
  deixou como bloqueio central ("modelo de referência" vs. "motor central"),
  optando pela alternativa que já tem prova de produção
  (`venha-pra-nuvem-client-platform`) em vez de exigir uma migração/reescrita
  arriscada sem demanda comprovada de múltiplos clientes simultâneos;
- formaliza o vínculo Repo Plataforma ↔ Repo IaC dedicado como registro, não
  substituição — coerente com o achado corrigido da Round 2 (item 2.4 de
  `research.md`);
- estabelece "Repo First Company" como padrão nomeado e documentado, criando
  a base para replicar o mesmo modelo para o Nuvem 365 (bounded context
  `infra`) numa rodada futura, sem se comprometer a isso agora;
- mede localização, rastreabilidade e tempo de auditoria com clientes reais
  antes de qualquer decisão sobre motor central multi-tenant.

A Option C permanece registrada como direção de evolução possível, a ser
revisitada somente se o piloto da Option B mostrar que o custo de manter
instâncias separadas por cliente cresce mais rápido que a carteira de
managed services.

## Validation sequence

Antes de ampliar o conceito, o piloto (Option B, com núcleo de Option A) deve
validar:

1. se o critério objetivo de "repo de IaC dedicado vs. inventário central"
   produz decisões consistentes ao ser aplicado a `vpn-nibo-connect` e a pelo
   menos um ativo sem repo dedicado;
2. se `venha-pra-nuvem-client-platform` consegue registrar/vincular
   `vpn-nibo-connect-iac` sem duplicar conteúdo Terraform;
3. se o processo de criar uma nova instância de Repo Plataforma para um
   segundo cliente de managed services é repetível e documentado, sem
   depender de conhecimento tácito;
4. se o tempo de localização e produção de evidências cai em relação ao
   baseline observado nos clientes piloto;
5. se a nomenclatura padronizada de repositórios de IaC (`-iac` vs. `-infra`)
   resolve a duplicidade observada em `vpn-nibo-connect-infra`;
6. se o padrão "Repo First Company", documentado como ADR/pattern, é
   compreendido e aceito pelos operadores de GSN Premium sem gerar
   ambiguidade de ownership;
7. se o esforço de propagar um padrão atualizado entre instâncias distintas
   (uma por cliente) permanece administrável no piloto ou já sinaliza a
   necessidade da Option C.

## Out of Scope (for the recommended option)

- Migrar ou aposentar `venha-pra-nuvem-client-platform` em favor de um motor
  central (Option C).
- Unificar o CMDB de Managed Services com o `005-cmdb-gcp` do produto SaaS
  Nuvem 365.
- Criar o bounded context `infra` (IaC) dentro do Nuvem 365 nesta rodada —
  apenas desenhar, em nível conceitual, como ele se encaixaria no mesmo
  critério de vínculo.
- Construir tooling de scaffolding/geração automática de novas instâncias de
  Repo Plataforma.
- Executar apply, destroy ou remediação autônoma em produção.
- Substituir CNAPP, SIEM, ITSM, FinOps, secrets manager, CI/CD ou plataforma
  especializada de Terraform.
- Investigar ou resolver a duplicidade `vpn-nibo-connect-infra` vs.
  `vpn-nibo-connect-iac` além de registrar a pergunta para nomenclatura
  futura.
- Definir arquitetura, APIs, modelos de dados, pipelines ou tarefas de
  implementação; esses itens pertencem ao ciclo de especificação posterior.

## Assumptions to Validate

- `venha-pra-nuvem-client-platform` é reconhecido pela liderança como a
  instância de referência a ser mantida e formalizada, não como algo a ser
  substituído no curto prazo.
- Há pelo menos um segundo cliente/ativo de managed services (além do que já
  opera via `venha-pra-nuvem-client-platform`) disponível para o piloto medir
  repetibilidade do processo de instanciação.
- O critério objetivo de "repo de IaC dedicado vs. inventário central" pode
  ser definido com base em porte, criticidade e exigência contratual, sem
  precisar de dados quantitativos adicionais além dos já levantados na Round
  2 do research.
- O time responsável por `vpn-nibo-connect-iac` está disponível para validar
  o modelo de vínculo e esclarecer o papel de `vpn-nibo-connect-infra`.
- O Nuvem 365 permanece fora do escopo de implementação desta rodada, com
  interesse apenas em preparar o desenho para uma integração futura.
- Segregação de secrets, evidências, estados e acessos entre instâncias de
  clientes distintos continuará garantida pela separação física de
  repositórios (premissa da Option B), sem exigir controles adicionais de
  isolamento lógico multi-tenant.

## Handoff

O próximo gate recomendado é:

```text
/nc-assess-decide slug=cliente-plataforma-operacional
```

O gate deve reavaliar o veredito anterior (`needs-clarification`) à luz da
evidência direta da Round 2 — em particular, se a decisão arquitetural
(Option B, modelo de referência) e o critério de vínculo CMDB↔IaC resolvem as
perguntas bloqueadoras suficientes para autorizar avanço à especificação
formal, ou se ainda faltam dados internos (baseline quantitativo, população
do piloto, critérios de aprovação) antes de prosseguir.
