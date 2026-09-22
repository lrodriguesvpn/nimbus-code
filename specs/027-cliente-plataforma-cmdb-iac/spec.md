# Feature Specification: CMDB↔IaC — Vínculo e Critério de Repositório Dedicado por Projeto

**Feature Branch**: `027-cliente-plataforma-cmdb-iac`

**Created**: 2026-09-22

**Status**: Draft

**Input**: User description: "Formalizar vínculo CMDB↔IaC e critério de repo dedicado por projeto, com topologia 1 cliente → 1 Repo Plataforma central → N projetos, a partir do assessment cliente-plataforma-operacional (Option B, decisão Go)"

**Origem**: `.specify/assessments/cliente-plataforma-operacional/` (intake.md, research.md, problem.md, concept.md, decision.md — verdict `go`, Option B completa, apetite `medium`)

## Nimbus-Code — Cabeçalho Obrigatório da Spec

| Campo | Valor |
|---|---|
| **Feature slug** | `027-cliente-plataforma-cmdb-iac` |
| **Complexidade estimada** | S3 |
| **Bounded Context** | Platform Governance & Compliance |
| **PR de referência / Issue** | novo |
| **Data alvo de entrega** | sem data |

## Nimbus-Code — SLO Alvo desta Feature

| Componente | Latência p99 (ms) | Taxa de erro máx. (%) | Disponibilidade alvo | RTO | RPO |
|---|---|---|---|---|---|
| Registro/consulta de vínculo CMDB↔IaC no Repo Plataforma central | 2000 | 0,5% | 99,9% | 15 min | 5 min |
| Processo de instanciação de novo Repo Plataforma central (por cliente) | — | — | — | — | — |

> A segunda linha não expõe SLO mensurável: é um processo operacional/documental executado sob demanda por onboarding de cliente, não um serviço com tráfego contínuo.

## Nimbus-Code — Objetivo e Contexto

**Objetivo:** Formalizar, dentro do Repo Plataforma central de cada cliente de managed services (instância de referência: `venha-pra-nuvem-client-platform`, cliente Venha Pra Nuvem / serviço GSN Premium), o modelo de dados e o processo de vínculo entre um projeto/ativo do cliente e (a) seu repositório de IaC dedicado, quando existir, ou (b) seu registro de inventário com IaC inline dentro do próprio Repo Plataforma central — segundo a topologia **1 cliente → 1 Repo Plataforma central → N projetos**. Inclui aplicar um critério objetivo e documentado para decidir entre as duas formas de vínculo, documentar o padrão "Repo First Company" como ADR nomeado da organização, e repetir o processo de instanciação do Repo Plataforma central em um segundo cliente de managed services, medindo baseline de localização, rastreabilidade e tempo de auditoria.

**Motivação:** O Repo Plataforma central de um cliente de managed services hoje não tem um modelo formal para registrar quando um projeto tem repositório de IaC dedicado (como `vpn-nibo-connect-iac`, vinculado ao projeto NIBO) versus quando ele existe apenas como inventário dentro do próprio Repo Plataforma. Essa lacuna foi identificada como bloqueio central em duas rodadas do assessment `cliente-plataforma-operacional`: sem o critério e o modelo de vínculo, não há forma consistente de evitar duplicação de conteúdo Terraform, garantir rastreabilidade por projeto, ou replicar o padrão para um segundo cliente.

**Critério de done (alto nível):** O Repo Plataforma central de pelo menos dois clientes de managed services registra, para cada projeto, um vínculo explícito e auditável — a um repositório de IaC dedicado (quando aplicável) ou a um registro de inventário/IaC inline — aplicando um critério objetivo e documentado; o padrão "Repo First Company" está publicado como ADR nomeado, referenciando um caso real; e o baseline de localização/rastreabilidade/auditoria foi medido antes e depois do rollout nos dois clientes piloto.

## Clarifications

### Session 2026-09-22 (herdada do assessment `cliente-plataforma-operacional`)

- Q: Este template deve continuar como modelo de referência/gerador por cliente, ou evoluir para um motor central único multi-cliente? → A: Modelo de referência/gerador — decisão registrada em `decision.md` (Option B; Option C explicitamente fora de escopo).
- Q: O Repo Plataforma central deve duplicar o conteúdo Terraform de um repositório de IaC dedicado já existente? → A: Não. Ele registra/linka uma referência (repo de aplicação + repo de IaC dedicado), nunca duplica o conteúdo (`research.md` §2.4, achado corrigido da Round 2).
- Q: Qual é a granularidade correta do vínculo — por cliente, por projeto ou por ambiente? → A: Um Repo Plataforma central por CLIENTE; um repositório de IaC dedicado por PROJETO/ativo dentro desse cliente, quando o critério objetivo indicar necessidade (esclarecido pelo usuário na Round 2b — ver `concept.md`, seção "Topologia confirmada").
- Q: Projetos sem repositório de IaC dedicado ficam sem nenhum registro formal? → A: Não. Permanecem como inventário + IaC inline dentro do próprio Repo Plataforma central do cliente — todo projeto tem um vínculo formal, de um dos dois tipos.
- Q: A integração real com o domínio FinOps do Nuvem 365 faz parte desta feature? → A: Não. Fora de escopo nesta rodada (`decision.md`); tratado apenas como direção futura.

### Session 2026-09-22b (auditoria `/nc-critic` — resolução das 5 perguntas abertas)

- Q: Qual deve ser a regra inicial (v1) para decidir se um projeto ganha repositório de IaC dedicado ou fica como inventário inline? → A: Repo dedicado **apenas se o contrato do cliente exigir isolamento formal** (SLA/compliance) — critério binário e restritivo na v1; porte e criticidade técnica deixam de ser gatilhos automáticos nesta versão (podem voltar a ser considerados em versão futura, se necessário).
- Q: Como deve ser medido o baseline de tempo de localização/rastreabilidade/auditoria antes e depois do rollout? → A: **Cronometragem manual** em tarefas reais de auditoria (ex.: tempo para localizar a IaC de um projeto), registrada em planilha/issue — sem instrumentação automática nesta feature.
- Q: Quem deve aprovar/revisar novas entradas de vínculo CMDB↔IaC antes de produção? → A: **Reaproveitar os mesmos aprovadores/revisores já configurados no ambiente `homologacao` de `vpn-nibo-connect-iac`** — sem criar papel novo dedicado ao CMDB nesta feature.
- Q: Qual é o status de `vpn-nibo-connect-infra` frente a `vpn-nibo-connect-iac`? → A: **Ainda não sabemos** — permanece como pendência explícita, a ser esclarecida pelo time responsável por `vpn-nibo-connect-iac` durante a execução da feature; não bloqueia o início da implementação, mas bloqueia a fixação final da convenção de nomenclatura no ADR "Repo First Company" (ver FR-013 e FR-010).
- Q: O que deve constar no checklist mínimo de LGPD/segurança para o próprio registro de vínculo? → A: **Checklist básico v1** — nenhum PII de cliente final no registro, apenas identificadores técnicos (nome de repo, cliente, projeto, timestamp), validado por amostragem manual (sem revisão formal do time de Segurança/Risco nesta versão).

Todas as 5 perguntas originalmente abertas foram resolvidas nesta sessão, exceto a
pendência de `vpn-nibo-connect-infra` (item 3), que permanece como
`[NEEDS CLARIFICATION]` de execução — não de viabilidade — e está refletida em
FR-013 abaixo.

## Nimbus-Code — Hybrid Collaboration Model

| Papel | Responsabilidades | Critério de handoff | Escalação |
|---|---|---|---|
| Agente | Levantar o inventário atual de projetos dos clientes piloto; propor entradas de CMDB (dedicado vs. inline) aplicando o critério documentado; gerar o rascunho do ADR "Repo First Company"; automatizar a medição de baseline onde for possível (ex.: tempo de busca via scripts/queries) | Antes de aplicar qualquer entrada em produção no Repo Plataforma central de um cliente real, ou sempre que o critério objetivo resultar em decisão ambígua | Tech lead de Managed Services / Arquitetura de Plataforma |
| Humano | Aprovar os limiares finais do critério objetivo; aprovar cada entrada de vínculo antes do commit em produção; validar o checklist de LGPD/segurança do registro; decidir o papel de `vpn-nibo-connect-infra`; escolher o segundo cliente piloto | Quando o agente sinalizar ambiguidade no critério, ou para qualquer entrada envolvendo dado real de cliente | Tech lead / Product Owner de Managed Services |

> Contexto **WEB**: não aplicável nesta feature — não introduz nova superfície web. Uma eventual UI futura de consulta ao CMDB deve seguir *"Impeccable é o padrão oficial de design"*, conforme já vigente no template.

## Nimbus-Code — Critérios de Aceitação (formato BDD)

> **AC-1**
> **Given** um projeto de cliente (ex.: NIBO) já possui repositório de IaC dedicado (ex.: `vpn-nibo-connect-iac`)
> **When** o operador registra esse projeto no Repo Plataforma central do cliente
> **Then** o CMDB cria uma entrada vinculando repo de aplicação + repo de IaC dedicado, sem duplicar conteúdo Terraform, com origem/autor/timestamp registrados
> **Test ref:** `test_AC1_vinculo_iac_dedicado`

> **AC-2**
> **Given** um projeto de cliente não atinge o critério objetivo para repositório de IaC dedicado
> **When** o operador registra esse projeto no Repo Plataforma central
> **Then** o CMDB cria uma entrada de inventário com IaC inline dentro do próprio Repo Plataforma central, sem exigir criação de repositório externo
> **Test ref:** `test_AC2_inventario_inline`

> **AC-3**
> **Given** o critério objetivo documentado (exigência contratual de isolamento formal — SLA/compliance)
> **When** o mesmo projeto é avaliado por operadores diferentes
> **Then** a decisão (dedicado vs. inline) é a mesma para ambos, e a justificativa aplicada fica registrada na entrada do CMDB
> **Test ref:** `test_AC3_criterio_consistente`

> **AC-4**
> **Given** o processo de instanciação do Repo Plataforma central está documentado
> **When** um segundo cliente de managed services é onboardado
> **Then** uma nova instância central é criada seguindo o mesmo padrão, sem exigir conhecimento tácito de quem operou a primeira instância, e o tempo de localização/auditoria é medido contra o baseline
> **Test ref:** `test_AC4_segunda_instancia_replicada`

> **AC-5**
> **Given** o padrão "IaC e estado sempre em repositório dedicado, nunca junto do código de aplicação" ainda não está documentado como prática nomeada da organização
> **When** esta feature é concluída
> **Then** existe um ADR nomeado "Repo First Company", referenciando pelo menos um caso real já em produção (`vpn-nibo-connect` / `vpn-nibo-connect-iac`) como evidência
> **Test ref:** `test_AC5_adr_repo_first_company`

> **AC de governança para rollout/toggle (se aplicável)**
> - Não aplicável: esta feature não introduz rollout progressivo de funcionalidade de produto nem feature flag — é registro de CMDB e documentação de padrão.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Vincular projeto com repositório de IaC dedicado (Priority: P1)

Como **operador de Managed Services**, quero **registrar, no Repo Plataforma central do cliente, o vínculo entre um projeto e seu repositório de IaC dedicado** para que **eu não precise adivinhar ou procurar manualmente onde a infraestrutura de cada projeto está versionada**.

**Why this priority**: é o caso mais comum e de maior risco de duplicação/perda de rastreabilidade caso não seja resolvido primeiro — resolve diretamente a lacuna que bloqueou o assessment.

**Independent Test**: registrar o projeto NIBO (com `vpn-nibo-connect-iac` já existente) no Repo Plataforma central e verificar que a entrada do CMDB aponta para os dois repositórios corretos, sem copiar arquivos Terraform.

**Acceptance Scenarios**:

1. **Given** um projeto com repositório de IaC dedicado já existente, **When** o operador cria a entrada de vínculo, **Then** o CMDB registra referência ao repo de aplicação e ao repo de IaC, sem duplicar conteúdo.
2. **Given** uma entrada de vínculo já existente, **When** um operador tenta criar uma segunda entrada duplicada para o mesmo projeto, **Then** o sistema recusa ou sinaliza a duplicidade, mantendo uma única entrada por projeto.

---

### User Story 2 — Registrar projeto sem repositório de IaC dedicado (Priority: P1)

Como **operador de Managed Services**, quero **registrar um projeto de menor porte como inventário com IaC inline dentro do Repo Plataforma central** para que **nenhum ativo do cliente fique sem registro formal só porque não justifica um repositório próprio**.

**Why this priority**: sem este caminho, o modelo de vínculo fica incompleto — projetos legados/pequenos continuariam invisíveis ao CMDB, replicando a lacuna que motivou o assessment.

**Independent Test**: registrar um ativo legado sem repositório de IaC próprio e verificar que ele aparece no CMDB do Repo Plataforma central com IaC inline, sem exigir criação de repositório externo.

**Acceptance Scenarios**:

1. **Given** um projeto abaixo do limiar do critério objetivo, **When** o operador o registra, **Then** o CMDB cria uma entrada de inventário com IaC inline, marcada como tal.
2. **Given** um projeto registrado como inventário inline, **When** o contrato do cliente passa a exigir isolamento formal para esse projeto, **Then** é possível migrar a entrada para "repo de IaC dedicado" preservando o histórico da decisão anterior.

---

### User Story 3 — Aplicar critério objetivo de decisão de forma consistente (Priority: P2)

Como **tech lead de Managed Services**, quero **um critério documentado e objetivo (exigência contratual de isolamento formal — SLA/compliance)** para que **diferentes operadores cheguem à mesma decisão sobre repo dedicado vs. inventário inline, sem depender de julgamento individual**.

**Why this priority**: sem um critério objetivo, as User Stories 1 e 2 funcionam individualmente mas produzem inconsistência entre clientes e operadores — o valor de auditabilidade do CMDB cai.

**Independent Test**: aplicar o critério documentado ao mesmo conjunto de projetos-teste com dois operadores diferentes e confirmar que o resultado (dedicado vs. inline) é idêntico.

**Acceptance Scenarios**:

1. **Given** o critério objetivo documentado, **When** um projeto é avaliado, **Then** a decisão e a justificativa (quais dimensões pesaram) ficam registradas na entrada do CMDB.
2. **Given** um projeto em zona de ambiguidade do critério, **When** o operador não consegue decidir automaticamente, **Then** o sistema sinaliza a ambiguidade para revisão humana em vez de assumir um padrão silencioso.

---

### User Story 4 — Replicar a instanciação do Repo Plataforma central em um segundo cliente (Priority: P2)

Como **time de Arquitetura de Plataforma**, quero **repetir o processo de criação do Repo Plataforma central para um segundo cliente de managed services**, medindo baseline de localização/auditoria, para que **eu tenha evidência de que o modelo de referência é replicável, não um caso único (`venha-pra-nuvem-client-platform`)**.

**Why this priority**: sem uma segunda instância real, a decisão arquitetural (Option B, modelo de referência) permanece validada por um único caso — depende das User Stories 1–3 já estarem funcionando no primeiro cliente.

**Independent Test**: aplicar o processo documentado de instanciação a um segundo cliente piloto e comparar o tempo de localização/auditoria antes e depois do rollout.

**Acceptance Scenarios**:

1. **Given** o processo de instanciação documentado, **When** ele é aplicado a um segundo cliente, **Then** uma nova instância central é criada sem suporte ad-hoc do time que operou a primeira instância.
2. **Given** baseline medido antes do rollout no segundo cliente, **When** o rollout é concluído, **Then** o tempo de localização e de produção de evidências é comparado ao baseline e registrado.

---

### User Story 5 — Documentar "Repo First Company" como ADR nomeado (Priority: P3)

Como **engenharia de plataforma**, quero **publicar o padrão "IaC e estado sempre em repositório dedicado, nunca junto do código de aplicação" como ADR nomeado**, para que **a organização tenha uma referência formal e citável em vez de uma prática apenas implícita**.

**Why this priority**: reforça e nomeia uma prática que já existe informalmente (`vpn-nibo-connect`/`-iac`) — de menor risco e menor urgência que os fluxos operacionais das User Stories 1–4, mas necessário para o handoff de `decision.md`.

**Independent Test**: revisar o ADR publicado e confirmar que ele referencia o caso real `vpn-nibo-connect`/`vpn-nibo-connect-iac` como evidência de prática já validada.

**Acceptance Scenarios**:

1. **Given** o padrão ainda não documentado, **When** o ADR é publicado, **Then** ele descreve a regra, o motivo e ao menos um caso real de aplicação.
2. **Given** o ADR publicado, **When** um novo projeto/cliente precisa decidir sua topologia de repositórios, **Then** o ADR é a referência citada, evitando redecidir o padrão a cada caso.

---

### Edge Cases

- O que acontece quando um projeto já tem um repositório cujo nome não segue a convenção padrão esperada (ex.: `vpn-nibo-connect-infra` vs. `vpn-nibo-connect-iac`)?
- Como o sistema evita que um operador copie/cole arquivos Terraform de um repo de IaC dedicado para dentro do Repo Plataforma central por engano, criando duplicação?
- O que acontece quando um projeto está no limite do critério objetivo — não claramente "dedicado" nem "inventário inline"?
- Como uma entrada de vínculo é atualizada quando um projeto migra de "inventário inline" para "repo de IaC dedicado" à medida que o contrato do cliente passa a exigir isolamento formal?
- O que acontece se o segundo cliente piloto só tiver ativos pequenos/legados, sem nenhum projeto comparável a `vpn-nibo-connect` para validar o caminho "repo dedicado"?
- Como o sistema trata um projeto que é descontinuado — a entrada de CMDB é removida, arquivada ou marcada como inativa?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema MUST manter, no Repo Plataforma central de cada cliente, uma entrada de CMDB por projeto/ativo do cliente.
- **FR-002**: Cada entrada MUST indicar exatamente um tipo de vínculo — repositório de IaC dedicado (com referência ao repositório) ou inventário com IaC inline — nunca ambos nem nenhum dos dois.
- **FR-003**: O sistema MUST NOT duplicar o conteúdo Terraform de um repositório de IaC dedicado dentro do Repo Plataforma central — apenas referenciar/linkar.
- **FR-004**: O sistema MUST registrar origem, autor, timestamp e justificativa (critério aplicado) para cada entrada de vínculo criada ou alterada.
- **FR-005**: O sistema MUST aplicar um critério objetivo e documentado para decidir entre repositório de IaC dedicado e inventário inline: **repositório dedicado somente quando o contrato do cliente exigir isolamento formal (SLA/compliance) para aquele projeto**; na ausência dessa exigência contratual, o projeto MUST ser registrado como inventário inline, independentemente de porte ou criticidade técnica isolados (decisão da sessão de clarificação 2026-09-22b; porte/criticidade poderão voltar a ser considerados em versão futura do critério, se necessário).
- **FR-006**: O sistema MUST permitir consultar todos os projetos de um cliente e o tipo de vínculo de cada um a partir do Repo Plataforma central.
- **FR-007**: O processo de criação de uma nova instância de Repo Plataforma central para um cliente MUST estar documentado de forma repetível, sem depender de conhecimento tácito de quem operou `venha-pra-nuvem-client-platform`.
- **FR-008**: O sistema MUST ser aplicado, dentro do escopo desta feature, a pelo menos um segundo cliente de managed services além da instância de referência existente.
- **FR-009**: O sistema MUST medir e registrar baseline de tempo de localização, rastreabilidade e tempo de auditoria antes e depois do rollout em cada cliente piloto, **via cronometragem manual em tarefas reais de auditoria (ex.: tempo para localizar a IaC de um projeto), registrada em planilha/issue** — sem instrumentação automática nesta feature (decisão da sessão de clarificação 2026-09-22b).
- **FR-010**: A organização MUST documentar o padrão "Repo First Company" como ADR nomeado, referenciando pelo menos um caso real já em produção (`vpn-nibo-connect` / `vpn-nibo-connect-iac`) como evidência.
- **FR-011**: A alteração de uma entrada de vínculo (ex.: migração de inventário inline para repo dedicado) MUST preservar o histórico da decisão anterior, não sobrescrever silenciosamente.
- **FR-012**: O sistema MUST ter um papel humano responsável por aprovar/revisar novas entradas de vínculo CMDB↔IaC antes de aplicação em produção — **reaproveitando os mesmos aprovadores/revisores já configurados no ambiente `homologacao` de `vpn-nibo-connect-iac`**, sem criar papel novo dedicado ao CMDB nesta feature (decisão da sessão de clarificação 2026-09-22b).
- **FR-013**: A organização MUST esclarecer e documentar o papel de `vpn-nibo-connect-infra` frente a `vpn-nibo-connect-iac` antes de fixar a nomenclatura padrão de repositórios de IaC no ADR "Repo First Company". [NEEDS CLARIFICATION: propósitos distintos ou duplicidade de nomenclatura? — pendência mantida deliberadamente na sessão de clarificação 2026-09-22b; a esclarecer com o time responsável por `vpn-nibo-connect-iac` durante a execução da feature, sem bloquear o início da implementação das demais FRs]
- **FR-014**: O registro de vínculo no CMDB MUST conter apenas metadados de localização/ownership (nunca credenciais, segredos ou dados de cliente final) — **checklist básico v1: nenhum PII de cliente final, apenas identificadores técnicos (nome de repo, cliente, projeto, timestamp), validado por amostragem manual**, sem revisão formal do time de Segurança/Risco nesta versão (decisão da sessão de clarificação 2026-09-22b).

### Key Entities *(include if feature involves data)*

- **ClientPlatformInstance**: instância central do Repo Plataforma de um cliente de managed services (ex.: `venha-pra-nuvem-client-platform`); relação 1:1 com o cliente.
- **ProjectAsset**: projeto/ativo do cliente (ex.: NIBO); pertence a exatamente uma `ClientPlatformInstance`.
- **IaCLinkEntry**: entrada de CMDB que vincula um `ProjectAsset` a um repositório de IaC dedicado externo (referência, sem duplicar conteúdo).
- **InlineInventoryEntry**: entrada de CMDB que registra um `ProjectAsset` sem repo de IaC dedicado, com IaC/configuração inline dentro do Repo Plataforma central.
- **LinkDecisionCriteria**: critério objetivo documentado (v1: dimensão única — exigência contratual de isolamento formal, SLA/compliance) usado para decidir entre `IaCLinkEntry` e `InlineInventoryEntry`.
- **RepoFirstCompanyADR**: documento de arquitetura nomeado que formaliza o padrão "IaC e estado sempre em repositório dedicado, nunca junto do código de aplicação".

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% dos projetos ativos dos dois clientes piloto têm uma entrada de CMDB (dedicada ou inline) — nenhum projeto sem registro formal.
- **SC-002**: 0% de duplicação de conteúdo Terraform entre o Repo Plataforma central e os repositórios de IaC dedicados vinculados.
- **SC-003**: O tempo de localização de um projeto e sua IaC (dedicada ou inline) cai em relação ao baseline medido antes do rollout, em ambos os clientes piloto.
- **SC-004**: 100% das entradas de vínculo criadas ou alteradas têm origem, autor, timestamp e justificativa registrados.
- **SC-005**: O processo de instanciação do Repo Plataforma central é executado com sucesso no segundo cliente piloto sem suporte ad-hoc do time que criou a primeira instância.
- **SC-006**: O ADR "Repo First Company" está publicado e referenciado por pelo menos um caso real de produção.

## Assumptions

- `venha-pra-nuvem-client-platform` continua sendo a instância de referência e não será migrada nem aposentada nesta feature (Option C explicitamente fora de escopo em `decision.md`).
- Há pelo menos um segundo cliente de managed services disponível para servir de piloto de instanciação dentro do prazo desta feature.
- O critério objetivo v1 é binário e baseado exclusivamente em exigência contratual de isolamento (FR-005) — porte e criticidade técnica não são gatilhos automáticos nesta versão; se a experiência do piloto mostrar que isso é insuficiente, o critério pode ser expandido em versão futura.
- A integração real com o domínio FinOps do Nuvem 365 (`nuvem365-nimbuscode-spec`) permanece fora de escopo desta feature.
- A segregação de secrets, evidências e acessos entre clientes continua garantida pela separação física de instâncias/repositórios — esta feature não introduz nem exige isolamento lógico multi-tenant adicional.
- O time responsável por `vpn-nibo-connect-iac` está disponível para esclarecer o papel de `vpn-nibo-connect-infra` durante a execução desta feature.
