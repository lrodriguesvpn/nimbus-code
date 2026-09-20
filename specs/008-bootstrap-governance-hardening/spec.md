# Feature Specification: Bootstrap Governance & Repo Provisioning Hardening

**Feature Branch**: `[008-bootstrap-governance-hardening]`

> **Nota de renumeração (2026-08-20)**: esta spec foi originalmente criada como
> `006-bootstrap-governance-hardening`, mas colidiu com `006-multirepo-support`
> e `007-controle-seguranca-ghe-projetos-plataforma`, já publicadas na `main`
> por outra sessão em paralelo. Renumerada para `008` e com o escopo revisado
> abaixo para não duplicar essas duas specs — ver seção "Sobreposição com
> Specs Existentes" após os Assumptions.

**Created**: 2026-08-20

**Status**: Draft

**Input**: User description: "Melhorar processo de BOOTSTRAP do template em novos REPOSITORIOS, fazendo perguntas sobre se é PLATAFORMA ou DEV STANDARDS, Validando que as ISSUES dos 2 PRESETS sejam as mesmas, questionar se o REPO é do PRODUTO ou de um FRONTEND ou BACKEND (pra produtos que tenha um REPO pra SPECs e outros pra CODIGO, sendo que o BOARD/ISSUES de todos os repos correlatos devem estar no PROJECT V2 do REPO do PRODUTO), Modificar tudo que usar PAT nos preset ou scripts pra usar o conceito do GITHUB APP para melhorar a Seguranca, Garantir que o SPECKIT seja baixado sempre do GITHUB OFICIAL e que tudo da Venha pra Nuvem usa o GIT HUB ENTERPRISE e nunca o GIT HUB publico, Validar o REPO de SKILLs da VPN e criar um manual para uso das SKILLS de forma remota e local."

## Nimbus-Code — Cabeçalho Obrigatório da Spec

| Campo | Valor |
|---|---|
| **Feature slug** | `bootstrap-governance-hardening` (specs/008-bootstrap-governance-hardening) |
| **Complexidade estimada** | S4 |
| **Bounded Context** | Repository Provisioning & Security Governance |
| **PR de referência / Issue** | novo |
| **Data alvo de entrega** | sem data |

> S0 = doc · S1 = função isolada · S2 = módulo · S3 = múltiplos módulos ·
> S4 = arquitetura, segurança, dados ou integração crítica

> **Nota de classificação**: marcada como **S4** porque a feature substitui o
> mecanismo de autenticação (PAT → GitHub App) usado por automações de
> escopo organizacional — mudança de segurança com impacto em todos os
> repositórios provisionados pelo bootstrap. Exige revisão humana obrigatória
> antes do merge, conforme constituição.

## Nimbus-Code — SLO Alvo desta Feature

| Componente | Latência p99 (ms) | Taxa de erro máx. (%) | Disponibilidade alvo | RTO | RPO |
|---|---|---|---|---|---|
| Execução do `bootstrap.sh` (perguntas + instalação de preset/labels/board) | 15000 | 1,0% | 99,0% | 30 min | 24 h |
| Emissão de token de instalação de GitHub App (workflows cross-repo/org) | 2000 | 0,5% | 99,9% | 15 min | N/A |

## Nimbus-Code — Objetivo e Contexto

**Objetivo:** endurecer o processo de bootstrap de repositórios Nimbus-Code para que ele (1) pergunte explicitamente o tipo de repositório e instale o preset correto, (2) garanta paridade estrutural entre as issues geradas pelos dois presets de governança, (3) elimine o uso de PAT clássico em automações de escopo organizacional/cross-repo em favor de um GitHub App instalado na organização, (4) garanta que o Spec Kit CLI seja sempre obtido da fonte oficial pública do GitHub e que todo conteúdo próprio da Venha Pra Nuvem referencie exclusivamente o GitHub Enterprise da organização, e (5) documente com clareza a diferença entre skills locais e remotas (VPN-SKILLS), incluindo o estado atual de transição.

**Motivação:** hoje o bootstrap sempre instala o preset `nimbus-code-standards` sem perguntar, os dois presets de governança têm templates de issue divergentes (um preset não tem `ISSUE_TEMPLATE` nenhum), não existe consolidação de board para produtos com múltiplos repositórios (spec/código separados), quatro segredos do tipo PAT clássico estão em uso hoje para automações que agem fora do escopo do próprio repositório, e o repositório VPN-SKILLS (governança já especificada em `specs/003-vpn-skills-repo-governance/`) ainda não foi implementado — as skills continuam 100% locais em `.github/skills/`, sem nenhum manual explicando a diferença entre uso local e remoto.

**Critério de done (alto nível):** todo novo bootstrap pergunta e aplica o tipo de repositório e o preset correspondente; os dois presets de governança produzem issues estruturalmente idênticas; nenhuma automação cross-repo/organização depende de PAT clássico; toda instalação do Spec Kit CLI usa a fonte oficial pública; todo link/URL de conteúdo próprio da Venha Pra Nuvem usa o domínio GitHub Enterprise; e existe um manual publicado explicando uso local vs. remoto de skills. O roteamento de Tasks entre repositórios é responsabilidade da SPEC 006.

## Nimbus-Code — Critérios de Aceitação (formato BDD)

> **AC-1**
> **Given** um novo repositório sendo inicializado via `bootstrap.sh`
> **When** o operador responder à pergunta de tipo de repositório (Plataforma/Cliente vs. Dev Standards)
> **Then** o preset correspondente (`nimbus-code-platform-standards` ou `nimbus-code-standards`) é instalado, e nenhum preset é assumido por padrão sem confirmação explícita
> **Test ref:** `test_AC1_bootstrap_preset_selection`

> **AC-2**
> **Given** os dois presets de governança da Nimbus-Code (`nimbus-code-standards` e `nimbus-code-platform-standards`)
> **When** uma issue for gerada a partir de qualquer um dos dois presets
> **Then** a estrutura de campos da issue (Contexto, Objetivo, Resultado Esperado, Critérios de Aceite, Passos Operacionais, Dependências, Responsável, Estimativa de Esforço, Referência) é idêntica entre os dois presets, e uma validação automatizada bloqueia divergência
> **Test ref:** `test_AC2_issue_template_parity`

> **AC-3** — **REMOVIDO** (2026-08-20): consolidação de board Produto/Frontend/Backend
> é tratada integralmente por `specs/006-multirepo-support/` (repo central de specs +
> N repos de serviço, `bounded-contexts.yaml`, roteamento de Tasks via
> `/speckit-taskstoissues`, vínculo ao Project V2 via `setup-github-project.sh`).
> Ver "Sobreposição com Specs Existentes" ao final deste documento — não
> reimplementar aqui.

> **AC-4**
> **Given** uma automação que precisa agir em escopo de organização ou cross-repo (ex.: Portfólio PMO, `ensure-github-project`, `add-to-repo-project`, `sync-priority-field`, `agent-auto-assign`)
> **When** o workflow correspondente for executado
> **Then** a autenticação usa um token de instalação de GitHub App de curta duração emitido dinamicamente, e nenhum secret do tipo PAT clássico é necessário
> **Test ref:** `test_AC4_github_app_cross_repo_auth`

> **AC-5**
> **Given** uma automação que só precisa agir no próprio repositório onde o workflow roda
> **When** o workflow for executado
> **Then** a autenticação usa o `GITHUB_TOKEN` nativo do workflow, sem exigir nenhum secret adicional de longa duração
> **Test ref:** `test_AC5_native_token_same_repo_scope`

> **AC-6**
> **Given** a instalação ou atualização do Spec Kit CLI durante o bootstrap
> **When** o comando de instalação for executado
> **Then** a fonte usada é o repositório oficial público do Spec Kit no GitHub, e nenhuma URL de mirror não oficial ou desatualizada é referenciada
> **Test ref:** `test_AC6_speckit_official_source`

> **AC-7**
> **Given** qualquer artefato (documentação, workflow, mensagem de bootstrap, link) gerado ou instalado pelo bootstrap ou pelos presets que referencie um repositório da Venha Pra Nuvem
> **When** o artefato for revisado
> **Then** a URL usada aponta exclusivamente para o domínio GitHub Enterprise da organização, nunca para `github.com` público — exceto a fonte oficial do Spec Kit CLI (AC-6), que é a única exceção documentada
> **Test ref:** `test_AC7_ghe_only_for_vpn_content`

> **AC-8**
> **Given** um desenvolvedor ou agente que precisa executar uma skill Nimbus-Code
> **When** ele consultar o manual de uso de skills
> **Then** ele consegue identificar, em poucos minutos, se aquela skill deve ser usada localmente (`.github/skills/`) ou remotamente (VPN-SKILLS), e qual é o estado atual de disponibilidade de cada modalidade
> **Test ref:** `test_AC8_skill_usage_manual_clarity`

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Selecionar o preset correto no bootstrap (Priority: P1)

Como Tech Lead iniciando um repositório novo, quero que o bootstrap me pergunte explicitamente se o repositório é de Plataforma/Cliente ou de Dev Standards, para que o preset de governança correto seja instalado desde o primeiro commit, sem depender de eu saber de cor qual preset usar.

**Why this priority**: Sem essa pergunta, todo repositório novo recebe o preset errado por padrão (hoje sempre `nimbus-code-standards`), o que já aconteceu silenciosamente até agora.

**Independent Test**: Rodar o bootstrap em um repositório novo e confirmar que ele pergunta o tipo antes de instalar qualquer preset, e que a resposta determina o preset instalado.

**Acceptance Scenarios**:

1. **Given** um repositório novo sem preset instalado, **When** o bootstrap for executado, **Then** ele pergunta explicitamente o tipo do repositório antes de instalar qualquer preset.
2. **Given** a resposta "Plataforma/Cliente", **When** o bootstrap continuar, **Then** o preset `nimbus-code-platform-standards` é instalado em vez do `nimbus-code-standards`.

---

### User Story 2 - Garantir paridade entre os presets de governança (Priority: P1)

Como membro do time de padrões Nimbus-Code, quero que os templates de issue dos dois presets de governança sejam estruturalmente idênticos, para que um humano ou agente executando uma task não perceba diferença de contrato dependendo do tipo de repositório em que está.

**Why this priority**: Divergência de contrato de issue quebra a promessa do modelo híbrido humano+agente (feature 005) — hoje um dos dois presets nem tem `ISSUE_TEMPLATE`.

**Independent Test**: Gerar uma issue a partir de cada preset e comparar a lista de seções obrigatórias; qualquer diferença estrutural deve falhar a validação.

**Acceptance Scenarios**:

1. **Given** os dois presets de governança, **When** suas issues forem comparadas, **Then** as mesmas seções obrigatórias aparecem, na mesma ordem, em ambos.
2. **Given** uma futura alteração em um dos dois templates de issue, **When** o outro não for atualizado em conjunto, **Then** uma validação automatizada sinaliza a divergência antes do merge.

---

### User Story 3 — **REMOVIDO** (2026-08-20): consolidação de board multi-repositório

Esta user story colidia com `specs/006-multirepo-support/` (já publicada na `main`
por outra sessão em paralelo), que trata exatamente do modelo "1 Repo Central de
Specs + N Repos por stack/microsserviço", incluindo `bounded-contexts.yaml`,
roteamento de Tasks por `/speckit-taskstoissues` e vínculo cross-repo ao Project V2
via `setup-github-project.sh` (15 ACs já detalhados naquela spec). Ver
"Sobreposição com Specs Existentes" ao final deste documento — não reimplementar
aqui; referenciar aquela spec por ponteiro quando esta feature precisar do
conceito de repo central vs. repo de serviço.

---

### User Story 4 - Migrar automações cross-repo/org de PAT para GitHub App (Priority: P1)

Como responsável por segurança da plataforma, quero que toda automação que precisa agir em escopo de organização ou cross-repo (Portfólio PMO, criação/população de boards, auto-assign do Copilot) use um GitHub App instalado na organização em vez de PAT clássico vinculado a uma pessoa, para reduzir risco de token de longa duração vazado ou órfão quando alguém sai da organização.

**Why this priority**: PAT clássico hoje está vinculado a indivíduos, não expira, e não tem escopo fino — é o maior risco de segurança identificado no ciclo de vida do bootstrap.

> **Nota de convergência (2026-08-20)**: `specs/007-controle-seguranca-ghe-projetos-plataforma/`
> já decidiu (ADR [0008](/docs/adr/0008-github-app-para-varredura-de-seguranca-org-wide.md))
> usar um GitHub App dedicado, **somente-leitura**, especificamente para a automação de
> varredura de segurança daquela feature. Esta user story tem escopo **mais amplo**:
> estende o mesmo padrão arquitetural (GitHub App em vez de PAT) para as demais
> automações cross-repo/org já existentes no bootstrap hoje (Portfólio PMO,
> `ensure-github-project`, `add-to-repo-project`, `sync-priority-field`,
> `agent-auto-assign`), que ADR-0008 não cobre. Não há contradição — é a mesma
> direção arquitetural aplicada a um conjunto diferente (e maior) de automações;
> referenciar ADR-0008 como precedente ao formalizar o ADR desta feature no `plan.md`.

**Independent Test**: Executar um workflow de escopo organizacional (ex.: `ensure-github-project.yml`) e confirmar que ele autentica via token de instalação de GitHub App de curta duração, sem exigir nenhum PAT configurado como secret.

**Acceptance Scenarios**:

1. **Given** um workflow que precisa gerenciar um GitHub Project V2 a nível de organização, **When** ele executar, **Then** a autenticação usa um token de instalação de GitHub App emitido dinamicamente na própria execução.
2. **Given** um workflow que só age no repositório onde roda (ex.: labels, comentário em issue), **When** ele executar, **Then** ele usa o `GITHUB_TOKEN` nativo do workflow, sem precisar de GitHub App nem de PAT.

---

### User Story 5 - Garantir fonte oficial do Spec Kit e domínio GHE para conteúdo próprio (Priority: P2)

Como Dev iniciando um bootstrap, quero ter certeza de que o Spec Kit CLI vem sempre da fonte oficial pública do GitHub e que qualquer link para conteúdo da Venha Pra Nuvem (templates, docs, VPN-SKILLS) aponta sempre para o GitHub Enterprise da organização, para evitar depender de mirrors não confiáveis ou vazar referências a um domínio público por engano.

**Why this priority**: Já existe hoje uma referência quebrada/incorreta no bootstrap apontando para um caminho público inexistente do Spec Kit — um risco de confusão operacional, mesmo que não seja uma vulnerabilidade de segurança direta.

**Independent Test**: Revisar todas as URLs geradas ou usadas pelo bootstrap e presets, e classificar cada uma como "Spec Kit oficial" (única exceção pública permitida) ou "conteúdo VPN" (deve ser GHE).

**Acceptance Scenarios**:

1. **Given** a etapa de instalação do Spec Kit CLI no bootstrap, **When** o link de instalação for exibido, **Then** ele aponta para o repositório oficial público do Spec Kit no GitHub.
2. **Given** qualquer outro link gerado pelo bootstrap (templates, docs, VPN-SKILLS), **When** ele for revisado, **Then** ele aponta exclusivamente para o domínio GitHub Enterprise da organização.

---

### User Story 6 - Entender e usar skills locais vs. remotas com um manual claro (Priority: P2)

Como desenvolvedor ou agente executando uma skill Nimbus-Code, quero um manual que explique claramente a diferença entre skills locais (instaladas em `.github/skills/` do próprio repositório) e skills remotas (centralizadas no futuro repositório VPN-SKILLS), incluindo o estado atual de cada skill, para não ficar confuso sobre onde uma skill vive e como invocá-la corretamente.

**Why this priority**: A governança do VPN-SKILLS já foi especificada (`specs/003-vpn-skills-repo-governance/`) mas ainda não foi implementada — hoje todas as skills são locais, e não existe nenhuma documentação explicando essa transição ou a diferença de uso.

**Independent Test**: Consultar o manual e verificar, para uma skill arbitrária, se é possível determinar corretamente se ela é local ou remota e como invocá-la em cada caso.

**Acceptance Scenarios**:

1. **Given** o manual de uso de skills, **When** um desenvolvedor consultar uma skill específica, **Then** ele identifica se ela é local ou remota e o caminho/comando correto de invocação.
2. **Given** o estado atual de transição (skills ainda locais, VPN-SKILLS não implementado), **When** o manual for lido, **Then** essa limitação atual é declarada explicitamente, sem sugerir uma capacidade remota que ainda não existe.

---

### Edge Cases

- Como o bootstrap se comporta quando o GitHub App organizacional ainda não foi instalado/configurado no momento da execução?
- Como um workflow que combina operações no próprio repositório e operações
  organizacionais/cross-repo separa os tokens e falha quando apenas a etapa de
  escopo ampliado não pode prosseguir?
- O que acontece se os dois presets divergirem no futuro e ninguém perceber antes de um novo release ser publicado?

> Edge cases sobre categorização Produto/Frontend/Backend e migração de board
> própria foram movidos para `specs/006-multirepo-support/` (2026-08-20).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O bootstrap MUST perguntar explicitamente se o repositório é de "Plataforma/Cliente" ou "Dev Standards" antes de instalar qualquer preset, e instalar o preset correspondente (`nimbus-code-platform-standards` ou `nimbus-code-standards`) sem assumir um padrão silencioso.
- **FR-002**: O sistema MUST manter estrutura de campos idêntica entre os templates de issue dos dois presets de governança, bloqueando publicação de um preset cujo template de issue divirja estruturalmente do outro.
- **FR-003**: **REMOVIDO** (2026-08-20) — consolidação de board Produto/Frontend/Backend é escopo de `specs/006-multirepo-support/` (ver AC-1 a AC-15 daquela spec); não reimplementar aqui.
- **FR-004**: Toda automação de escopo organizacional ou cross-repo (Portfólio PMO, `ensure-github-project`, `add-to-repo-project`, `sync-priority-field`, `agent-auto-assign`) MUST autenticar via token de instalação de um GitHub App da organização, emitido dinamicamente por execução, em vez de um secret do tipo PAT clássico.
- **FR-005**: Toda automação cujo escopo seja restrito ao próprio repositório onde o workflow roda MUST usar o `GITHUB_TOKEN` nativo do workflow em vez de qualquer PAT ou GitHub App. Workflows com escopo misto MUST separar as operações em etapas explícitas e usar o token correspondente em cada etapa; um token cross-repo/org não pode ser reutilizado em uma etapa local.
- **FR-006**: O bootstrap MUST obter o Spec Kit CLI exclusivamente da fonte oficial pública do GitHub, nunca de um mirror não oficial ou de uma URL desatualizada.
- **FR-007**: Todo link/URL gerado ou instalado pelo bootstrap ou pelos presets que referencie conteúdo próprio da Venha Pra Nuvem (templates, docs, VPN-SKILLS, repositórios internos) MUST apontar exclusivamente para o domínio GitHub Enterprise da organização, nunca para `github.com` público.
- **FR-008**: O sistema MUST disponibilizar um manual documentando a diferença entre skills locais (`.github/skills/`) e skills remotas (VPN-SKILLS), incluindo o estado atual de disponibilidade de cada modalidade por skill.
- **FR-009**: O bootstrap MAY materializar artefatos locais quando o GitHub App ainda não estiver configurado, mas MUST registrar a capacidade cross-repo/org como `blocked` e apresentar instrução clara de remediação. Qualquer workflow que dependa dessa capacidade MUST falhar fechado antes da primeira operação ampliada. Fallback para PAT clássico não pode ser ativado apenas pela ausência dos secrets; só pode existir em modo de migração opt-in, com owner, prazo, ambiente permitido e auditoria.

### Key Entities *(include if feature involves data)*

- **Repo Provisioning Profile**: conjunto de respostas coletadas no bootstrap (tipo de preset, ref da fonte, classificação greenfield/brownfield e modo de execução).
- **GitHub App Credential Policy**: regra que determina, por automação, se ela usa token de instalação de GitHub App (escopo org/cross-repo) ou `GITHUB_TOKEN` nativo (escopo do próprio repositório).
- **Source-of-Truth Registry**: lista das fontes canônicas de URL permitidas (Spec Kit oficial público; todo o restante do conteúdo VPN via GitHub Enterprise).
- **Skill Distribution Manual**: documento que descreve, por skill, se ela é local ou remota, e como invocá-la em cada modalidade.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% dos novos bootstraps resultam na instalação do preset correto já na primeira execução, validado contra o tipo de repositório declarado.
- **SC-002**: Zero diferenças estruturais entre os templates de issue dos dois presets de governança em qualquer momento, verificado por validação automatizada.
- **SC-003**: **REMOVIDO** (2026-08-20) — critério de consolidação de board é escopo de `specs/006-multirepo-support/`.
- **SC-004**: No commit candidato de release, 100% dos workflows cross-repo/org dos bundles, scripts referenciados pelo bootstrap e workflows dos repositórios piloto operam sem PAT clássico, exceto fixtures explicitamente marcadas como migração e não executáveis.
- **SC-005**: No commit candidato de release, a auditoria de `docs/`, `presets/`, `bundles/`, `.github/workflows/`, scripts referenciados pelo bootstrap e artefatos materializados nos repositórios piloto encontra zero URLs `github.com` para conteúdo próprio da Venha Pra Nuvem; a única exceção é `https://github.com/github/spec-kit`, registrada no Source-of-Truth Registry.
- **SC-006**: Em uma avaliação com cinco desenvolvedores ou agentes, cada participante consegue, em até 2 minutos e consultando somente `docs/skills-distribution-guide.md`, identificar para uma skill sorteada sua modalidade (local/remota), localização, comando de invocação e disponibilidade atual; o critério passa com pelo menos quatro respostas completas.

## Assumptions

- O repositório VPN-SKILLS (governança especificada em `specs/003-vpn-skills-repo-governance/`) ainda não foi implementado; esta feature documenta o estado de transição, mas não reimplementa aquela especificação — refere-se a ela por ponteiro.
- A organização Venha Pra Nuvem já possui (ou criará como parte do rollout, fora do escopo desta spec de planejamento) permissão administrativa para instalar um GitHub App a nível de organização.
- O Spec Kit CLI é uma ferramenta open source mantida publicamente pelo GitHub; manter sua fonte pública é uma exceção deliberada e documentada à regra geral de "tudo VPN usa GHE", não uma contradição dela.

## Sobreposição com Specs Existentes (revisão de convergência, 2026-08-20)

*Esta spec foi originalmente numerada `006` e concebida antes de `git fetch` revelar
que `006-multirepo-support` e `007-controle-seguranca-ghe-projetos-plataforma` já
haviam sido publicadas na `main` por outra sessão em paralelo, cobrindo parte do
mesmo espaço de problema. Renumerada para `008`; esta seção documenta o que foi
removido/ajustado e por quê, para que o histórico de decisão não se perca.*

| Item original desta spec | Spec que já cobre o tema | Ação tomada |
|---|---|---|
| User Story 3 / AC-3 / FR-003 / SC-003 (consolidação de board Produto/Frontend/Backend) | `specs/006-multirepo-support/` (modelo "1 Repo Central + N Repos de Serviço", `bounded-contexts.yaml`, 15 ACs já detalhados) | Removido desta spec; referenciar `006-multirepo-support` por ponteiro quando esta feature precisar do conceito |
| User Story 4 / FR-004 (GitHub App para automações cross-repo/org) | `specs/007-controle-seguranca-ghe-projetos-plataforma/` — ADR [0008](/docs/adr/0008-github-app-para-varredura-de-seguranca-org-wide.md) (GitHub App **somente-leitura**, escopo restrito à varredura de segurança daquela feature) | **Mantido** — escopo desta spec é mais amplo (Portfólio PMO, `ensure-github-project`, `add-to-repo-project`, `sync-priority-field`, `agent-auto-assign`, nenhum coberto por ADR-0008); referenciar ADR-0008 como precedente arquitetural ao formalizar o ADR desta feature no `plan.md`, não como decisão redundante |
| Demais User Stories (1, 2, 5, 6 — seleção de preset, paridade de issue templates, fonte oficial do Spec Kit + domínio GHE, manual de skills) | Nenhuma spec existente | **Mantidas integralmente** — conteúdo único desta feature |

- Repositórios que hoje já têm board própria (Frontend/Backend de um Produto) serão migrados para o board consolidado por um processo de rollout controlado, não instantâneo — tratado em `specs/006-multirepo-support/`, fora do escopo desta spec.
- O bootstrap não pergunta nem persiste papéis Produto/Frontend/Backend. Quando
  o fluxo de uma feature precisar rotear Tasks, os bounded contexts e
  repositórios são resolvidos por `specs/006-multirepo-support/`.
