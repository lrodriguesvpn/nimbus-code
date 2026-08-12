# Princípios Não-Negociáveis da Nimbus-Code

<!--
  © Venha Pra Nuvem — Propriedade Intelectual Exclusiva.
  Uso restrito a colaboradores autorizados da organização venha-pra-nuvem.
  Cópia, redistribuição ou uso externo são proibidos — ver LICENSE no repositório
  nimbus-code-spec-kit-template. Alterações exigem aprovação do @nimbus-code-arch-board.
-->

<!--
  Este bloco é inserido pelo preset `nimbus-code-standards` (estratégia `wrap`) antes da
  constituição específica de cada projeto. Ele representa o conjunto MÍNIMO de regras
  que valem para TODO projeto da organização — o restante da constituição (abaixo)
  continua sendo preenchido normalmente via `/nimbus-code-constitution` para o que for
  específico deste projeto.

  Alterar este arquivo é uma mudança de política organizacional, não de projeto:
  requer aprovação do time responsável pelos padrões da Nimbus-Code e deve seguir o
  mesmo controle de versão do preset (ver presets/nimbus-code-standards/preset.yml).
-->

## Segurança e Dados

- Nenhum segredo (senha, token, chave de API, certificado) pode ser commitado em
  texto plano em qualquer artefato versionado (código, IaC, pipelines, configs).
  Usar cofre de segredos (Secret Manager, Key Vault, GitHub/Azure DevOps secrets).
- **SSO é obrigatório para todo sistema novo** (greenfield): nenhum sistema novo
  pode expor autenticação própria (usuário/senha local, auth ad-hoc) sem que o
  caso de não uso de SSO esteja formalmente declarado e registrado no Architecture
  Decision Log do `plan.md` da feature, com justificativa técnica explícita. Ausência
  de SSO sem registro bloqueia o Security & DevSecOps Gate.
- Toda conexão com banco de dados gerenciado exige TLS/mTLS obrigatório.
- Toda instância de banco de dados relacional deve habilitar, no mínimo, logs de
  conexão/desconexão, auditoria de statements DDL e duração de query.
- Buckets/containers de armazenamento usados para dados de auditoria ou logs
  arquivados devem ter logging de acesso habilitado e política de retenção.

## Infraestrutura como Código

- **Toda infraestrutura é código, sem exceção**: nenhum recurso em nuvem
  (AWS, GCP ou Azure) é criado ou alterado manualmente via console/CLI em
  ambiente compartilhado — sempre via IaC versionado e revisado em Pull
  Request.
- **Terraform é o framework padrão para os três provedores** (AWS, GCP e
  Azure). Usar a ferramenta nativa do provedor (ex.: AWS CDK, Bicep/ARM,
  Google Cloud Deployment Manager) só é permitido como **exceção
  justificada**, registrada no Architecture Decision Log do `plan.md` da
  feature que a introduziu — nunca como escolha silenciosa ou "porque o time
  prefere".
- Least privilege por padrão: nenhuma role/permissão de IAM ampla (ex.: `Owner`,
  `roles/editor`, papéis "básicos") sem justificativa explícita registrada no plano.
- Versões de imagens base, actions de CI e providers Terraform devem ser fixadas
  (pin), nunca `latest`/sem versão.
- Toda alteração de infraestrutura passa por `terraform plan`/equivalente revisado
  em Pull Request antes de aplicar em qualquer ambiente compartilhado.

## Grafos de Módulos

- Todo `plan.md` de feature **deve** conter ou referenciar um `graph.yaml` e um
  `graph.md` estruturados (localização: `specs/<feature-slug>/`), preenchidos
  antes de `/nimbus-code-tasks`. Grafo ausente ou desatualizado bloqueia merge sob a
  mesma régua do gate de segurança.
- O `graph.yaml` é a fonte de verdade estrutural: lista todos os módulos/serviços
  envolvidos, suas dependências (tipo e protocolo) e os sistemas externos com sua
  criticidade. O `graph.md` é o equivalente legível por humanos, com diagramas
  Mermaid (grafo por código e grafo por business).
- Toda PR que altera código em `src/`, `services/`, `infrastructure/` ou
  `modules/` deve atualizar `graph.yaml` e `graph.md` na mesma PR — o GitHub
  Action Graph Guard valida isso automaticamente.
- Features de complexidade **S3 ou S4** (múltiplos módulos, arquitetura, segurança
  ou integração crítica) exigem também um `impact-map.md` com análise de risco,
  dependências indiretas, plano de rollback e critérios de Go/No-Go.

## Escala de Complexidade e Seleção de Modelo (S0–S4)

- Toda tarefa deve ser classificada na escala de complexidade abaixo antes de
  iniciar a implementação. Essa classificação determina o modelo de IA usado e os
  artefatos obrigatórios.

  | Nível | Descrição | Modelo obrigatório |
  |---|---|---|
  | **S0** | Documentação, comentários, textos | Auto / modo rápido |
  | **S1** | Função isolada, sem dependência externa | Auto / modo rápido |
  | **S2** | Módulo completo, testes, refatoração | Auto |
  | **S3** | Múltiplos módulos, integração entre serviços | Modelo de reasoning |
  | **S4** | Arquitetura, segurança, dados sensíveis ou integração crítica | Modelo mais forte + **revisão humana obrigatória** |

- Usar modelo mais forte que o nível exige é desperdício e deve ser evitado.
  Usar modelo mais fraco que o nível exige é risco técnico e também deve ser
  evitado.
- Features S4 exigem label `complexity:S4` no PR e revisão humana — nunca
  apenas revisão automática.
- O mapeamento nível→modelo acima é a recomendação padrão do bundle e **pode
  ser ajustado por projeto** (política de modelos habilitados, compliance,
  disponibilidade) — a régua S0–S4 em si e a exigência de revisão humana em S4
  **não são ajustáveis**. Documente qualquer ajuste no Architecture Decision
  Log do `plan.md`.
- Toda feature deve ter uma **estimativa de tokens** registrada no `plan.md`
  antes de `/nimbus-code-tasks`, e o consumo real comparado com ela no fechamento
  do `tasks.md` — ver metodologia em
  [`docs/ai-code-quality-and-observability.md`](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/blob/main/docs/ai-code-quality-and-observability.md), seção 6.

## Reutilização de Conteúdo e Referência por Ponteiro

- **Referenciar por ponteiro, nunca duplicar por valor**: ao citar um ADR, uma
  decisão de plano anterior ou um padrão já documentado, use um link para o
  artefato original (`docs/adr/NNNN-slug.md`, `specs/<feature>/plan.md#seção`)
  — nunca copie/reescreva o conteúdo inteiro dentro de um novo `spec.md`/
  `plan.md`. Isso vale tanto para o texto gerado quanto para o contexto lido
  por um agente ao planejar uma feature nova.
- Todo projeto mantém um **catálogo de reuso** (`docs/reuse-catalog.yaml`,
  instalado pelo `bootstrap.sh`) indexando padrões/decisões reaproveitáveis por
  tag e bounded context. Ao iniciar uma feature nova, consultar esse catálogo
  **antes** de desenhar uma solução do zero é parte do processo, não opcional.
- Toda feature que introduzir um padrão reaproveitável (não específico só dela)
  deve registrar uma entrada no catálogo como parte do checklist de fechamento
  do `tasks.md`.
- Detalhamento completo (estrutura do catálogo, TL;DR em docs longos e
  integração com a estimativa de tokens) em
  [`docs/ai-code-quality-and-observability.md`](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/blob/main/docs/ai-code-quality-and-observability.md), seção 9.

## Priorização e Desenvolvimento Autônomo (Labels)

- Todo projeto deve manter a taxonomia de labels do bundle Nimbus-Code criada por
  `scripts/setup-github-labels.sh`: `priority:P0-blocker` a `P3-low`,
  `complexity:S0`–`S4`, `type:bug/feature/chore/docs/incident`,
  `agent:autonomous-ok`/`agent:needs-human`,
  `status:needs-triage`/`status:blocked` e
  `dora:deployment-frequency`/`dora:lead-time`/`dora:change-failure-rate`/`dora:mttr`.
- **Ordenamento do backlog** é sempre por `priority:*`
  (`P0-blocker` > `P1-high` > `P2-medium` > `P3-low`), excluindo itens
  `status:blocked` ou `status:needs-triage` da fila até serem triados.
- **Desenvolvimento autônomo** (atribuição automática ao Copilot coding agent
  sem supervisão humana constante) só é permitido quando a issue tem o label
  `agent:autonomous-ok` **e não tem** nenhum dos seguintes: `agent:needs-human`,
  `complexity:S4`, `type:incident` ou `status:blocked`. `complexity:S4` e
  `type:incident` bloqueiam autonomia **sempre**, cada um reforçando sua
  própria regra de revisão humana obrigatória (S4 por arquitetura/segurança;
  `type:incident` por ser originada de ocorrência em produção/ambiente de
  cliente — independente da complexidade S0–S4 daquela issue específica).
- **Labels DORA** (`dora:*`) marcam qual dos 4 indicadores DORA (Deployment
  Frequency, Lead Time for Changes, Change Failure Rate, MTTR) uma issue
  impacta — usados para correlação/relatório, não disparam automação.
  `type:incident` tipicamente carrega também `dora:mttr` (o tempo entre
  abertura e fechamento da issue é a métrica de restauração de serviço).
- Ver detalhamento completo (taxonomia, guardrails do workflow de auto-assign
  e como evitar gatilhos duplicados) em
  [`docs/label-taxonomy-and-autonomous-dev.md`](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/blob/main/docs/label-taxonomy-and-autonomous-dev.md).

## Ocorrências (CRM) e Issues de Infraestrutura

- Ocorrências tratadas em N1 no CRM que exigirem uma mudança real no ambiente
  (não resolvidas por procedimento padrão) devem virar uma **issue** no
  repositório de infraestrutura correspondente, com o label `type:incident` e
  o campo **"Ocorrência CRM (N1)"** do GitHub Project preenchido com a
  URL/ID do atendimento original (rastreabilidade + cálculo de MTTR).
- `type:incident` **sempre exige revisão humana**, independente da
  complexidade S0–S4 — nunca é atribuída automaticamente ao Copilot coding
  agent (ver guardrail acima).
- Ausência de Terraform (ou outra IaC formal) **não é bloqueio** para usar o
  Nimbus Code em infraestrutura: a classificação S0–S4, o Module Dependency
  Graph e o `impact-map.md` (S3/S4) se aplicam independente da ferramenta —
  o `impact-map.md` fica ainda **mais crítico** sem `terraform plan` como
  rede de segurança, pois é o único artefato documentando blast radius e
  rollback antes de uma mudança manual. Documente a ferramenta real usada
  (scripts, runbook, ClickOps documentado etc.) no `plan.md` da feature.

## Modelo Híbrido (Agente + Humano) e Custo Real

- Tarefas de modelo híbrido (agente gera a maior parte, humano revisa/ajusta)
  devem ter as horas humanas lançadas no campo **"Horas Humanas"** do GitHub
  Project (criado por `scripts/setup-github-project.sh`), mesmo que seja
  apenas o tempo de revisão do PR.
- Custo real da tarefa = tokens do agente (estimado vs. real, ver acima) +
  horas humanas × custo/hora do time. A taxa custo/hora é documentada pelo
  próprio projeto (README ou ADR) — este bundle não define uma taxa padrão.
- Detalhamento completo em
  [`docs/ai-code-quality-and-observability.md`](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/blob/main/docs/ai-code-quality-and-observability.md), seção 8.

## Release e Feature Flags

- **Deploy desacoplado de release é o padrão**: features S3/S4 devem chegar a
  produção atrás de feature flag (`flag`), deploy canário (`canary`) ou
  blue-green — nunca `direct` sem justificativa explícita registrada no
  `plan.md`. Isso permite rollback imediato sem reverter código.
- **Toda flag deve ter metadados mínimos obrigatórios** no `plan.md`: nome,
  owner, ambiente(s), tipo (`release` · `ops` · `experiment`), valor default,
  critério de ativação, critério de rollback e critério/data de remoção.
- **Feature flags têm ciclo de vida**: toda flag criada deve ter data de expiração
  ou critério de remoção definidos no `plan.md`. Flags não removidas após a
  feature ser considerada estável são dívida técnica e devem ser registradas
  como Issue.
- **Cenários com múltiplas homologações concorrentes** (3+ frentes tocando arquivos
  sobrepostos) devem usar flag com default seguro (**OFF**) e ativação progressiva
  por ambiente/cliente para evitar acoplamento de release.
- **Provider de flags configurável por projeto**: usar OpenFeature SDK como
  abstração — permite trocar o provider (LaunchDarkly, AWS AppConfig, etc.) sem
  alterar o código de aplicação.

## Decisões de Arquitetura (ADRs)

- Decisões técnicas com impacto duradouro (>3 meses) ou que escolham entre
  alternativas reais devem ser registradas como ADR:
  - **Escopo organizacional** (afeta múltiplos projetos): `docs/adr/` neste
    repositório (`nimbus-code-spec-kit-template`).
  - **Escopo de projeto**: `docs/adr/` no repositório do projeto.
- O Architecture Decision Log do `plan.md` captura decisões locais de feature;
  quando a decisão tiver impacto organizacional, adicionar link para o ADR
  correspondente.
- Template e guia em [`docs/adr-guide.md`](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/blob/main/docs/adr-guide.md).

## Bounded Contexts

- Todo projeto mantém um arquivo `docs/bounded-contexts.yaml` (instalado pelo
  `bootstrap.sh` via template) com a lista oficial dos bounded contexts —
  slugs em kebab-case, cada um com descrição, owner e repositórios associados.
- Ao preencher o campo "Bounded Context" em qualquer `spec.md`, o Dev ou agente
  **deve usar um slug desta lista**. Usar um nome não listado exige adicionar
  a entrada ao arquivo primeiro (via PR), não improvsar um nome ad-hoc.
- Bounded contexts novos têm impacto organizacional: a adição de um novo slug
  deve ser registrada no Architecture Decision Log do `plan.md` ou em um ADR
  dedicado em `docs/adr/`.
- O agente verifica o arquivo antes de propor o preenchimento do campo
  "Bounded Context" — se não encontrar match, informa o Dev e propõe a adição
  em vez de usar um nome inventado.

## Modo de Operação do Agente por Complexidade (S0–S4)

*Regras de comportamento do agente Copilot de acordo com o nível de complexidade
da tarefa — complementam a escala S0–S4 da Constituição com expectativas
operacionais concretas.*

| Nível | Modo do agente | O agente deve… | O agente **não deve**… |
|---|---|---|---|
| **S0** | Autônomo direto | Executar e abrir PR sem pedir confirmação intermediária | Solicitar aprovação de estrutura antes de agir |
| **S1** | Autônomo direto | Executar e abrir PR sem pedir confirmação intermediária | Solicitar aprovação de estrutura antes de agir |
| **S2** | Autônomo com proposta | Apresentar a estrutura de módulos proposta antes de implementar; aguardar "ok" do Dev antes de escrever código | Implementar sem exibir o design de alto nível primeiro |
| **S3** | Proposta + reasoning | Apresentar design detalhado (módulos, dependências, estratégia de release) e aguardar aprovação explícita; usar modelo de reasoning | Começar a implementação sem aprovação do design |
| **S4** | Plano apenas | Entregar **somente o plano** (`plan.md` completo + `impact-map.md`) para revisão humana; **não escrever código** sem aprovação explícita do Dev | Escrever qualquer linha de código antes de aprovação; nunca merge direto |

> **Regra de escalonamento**: se durante a execução de um nível menor o agente
> descobrir que a tarefa é na verdade S3 ou S4 (ex.: módulo novo tem dependência
> não prevista com serviço de autenticação), ele **para imediatamente**, reclassifica
> a tarefa e informa o Dev — nunca continua silenciosamente num nível errado.

## Sessões de Agente, Branches e Isolamento de Código

- **1 agente = 1 branch = 1 fase = conjunto fechado de arquivos**: nunca dois
  agentes editam o mesmo arquivo ao mesmo tempo. Se duas fases planejadas tocam
  no mesmo arquivo, elas são sequenciais — a segunda fase só começa após o PR da
  primeira ser aprovado e mergeado.
- **Planejamento em fases é obrigatório antes de qualquer sessão de agente**: a
  feature deve ser dividida em fases no `plan.md`, cada fase com lista explícita
  de arquivos de escopo (máximo 5 arquivos, 1 responsabilidade, máximo S2 por
  fase), antes de iniciar a primeira sessão.
- **Toda sessão de agente recebe um escopo fechado explicitamente**: o prompt de
  início da sessão deve declarar os arquivos que o agente pode criar ou editar.
  O agente **não deve editar** nenhum arquivo fora dessa lista — se o fizer, o
  PR é rejeitado e uma nova sessão é iniciada com instrução mais precisa.
- **Nada muda sem aprovação via PR**: agentes nunca fazem merge diretamente.
  Todo trabalho produzido por agente chega a `develop` ou `main` exclusivamente
  via Pull Request revisado e aprovado pelo Dev.
- **Branches perdidas são dívida técnica**: qualquer branch sem PR aberto
  associado ou sem commit há mais de 3 dias deve ser deletada. Branch mergeada
  é deletada imediatamente após o merge. A contagem de branches perdidas é uma
  métrica de PMO auditada semanalmente (ver `tasks-template.md`).
- Ver manual operacional completo em
  [`docs/agent-session-manual.md`](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/blob/main/docs/agent-session-manual.md).

## Qualidade e Processo

- Nenhuma implementação de feature relevante começa sem uma especificação formal
  (`/nimbus-code-specify` → `/nimbus-code-plan` → `/nimbus-code-tasks` → `/nimbus-code-implement`). Branch criado **apenas** na fase implement — as fases discovery/specify/plan/tasks são artefatos de planejamento sem branch..
- Todo Pull Request que altera infraestrutura ou lógica de autorização/segurança
  exige pelo menos uma revisão humana antes do merge.
- Achados de ferramentas de SAST/IaC scanning (ex.: CodeQL, Checkov, tflint)
  classificados como High/Critical bloqueiam o merge, salvo supressão documentada
  com justificativa técnica explícita no próprio código (comentário de skip).
- Todo Pull Request passa por revisão de qualidade de código assistida por IA
  (GitHub Copilot code review) antes do merge, **em complemento** à revisão
  humana já exigida acima — nunca em substituição a ela. Findings High/Critical
  do Copilot bloqueiam o merge sob a mesma régua do SAST/IaC scanning.
- Cada critério de aceitação declarado em `spec.md` deve ter, sempre que
  tecnicamente viável, um teste de integração automatizado correspondente — não
  apenas cobertura por testes unitários isolados. Exceções (ex.: dependência
  externa indisponível em CI) exigem justificativa explícita registrada no
  `plan.md`.
- Observabilidade (logs estruturados, métricas e alertas) é obrigatória para
  todo componente/serviço novo ou alterado de forma relevante — não é opcional.
- Em arquiteturas de microsserviços/distribuídas: propagação de correlation-id
  (ou trace-id via W3C Trace Context) ponta a ponta entre serviços, e
  visibilidade documentada da orquestração/coreografia entre eles, são
  obrigatórias.
- Todo bug identificado (em CI, produção ou revisão de código) que não for
  corrigido dentro da própria tarefa em andamento deve ser aberto
  automaticamente como Issue no GitHub e atribuído ao Copilot coding agent —
  nunca deixado apenas registrado em log/alerta sem rastreamento formal.

Ver o detalhamento técnico de como aplicar estas regras em:
- [`docs/ai-code-quality-and-observability.md`](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/blob/main/docs/ai-code-quality-and-observability.md) — revisão por IA, seleção de modelos S0–S4, estimativa de tokens, modelo híbrido humano+agente, tracing, gestão de bugs
- [`docs/module-graphs.md`](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/blob/main/docs/module-graphs.md) — grafos de módulos, Graph Guard, templates
- [`docs/adr-guide.md`](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/blob/main/docs/adr-guide.md) — como criar e manter ADRs organizacionais

# [PROJECT_NAME] Constitution
<!-- Example: Spec Constitution, TaskFlow Constitution, etc. -->

## Core Principles

### [PRINCIPLE_1_NAME]
<!-- Example: I. Library-First -->
[PRINCIPLE_1_DESCRIPTION]
<!-- Example: Every feature starts as a standalone library; Libraries must be self-contained, independently testable, documented; Clear purpose required - no organizational-only libraries -->

### [PRINCIPLE_2_NAME]
<!-- Example: II. CLI Interface -->
[PRINCIPLE_2_DESCRIPTION]
<!-- Example: Every library exposes functionality via CLI; Text in/out protocol: stdin/args → stdout, errors → stderr; Support JSON + human-readable formats -->

### [PRINCIPLE_3_NAME]
<!-- Example: III. Test-First (NON-NEGOTIABLE) -->
[PRINCIPLE_3_DESCRIPTION]
<!-- Example: TDD mandatory: Tests written → User approved → Tests fail → Then implement; Red-Green-Refactor cycle strictly enforced -->

### [PRINCIPLE_4_NAME]
<!-- Example: IV. Integration Testing -->
[PRINCIPLE_4_DESCRIPTION]
<!-- Example: Focus areas requiring integration tests: New library contract tests, Contract changes, Inter-service communication, Shared schemas -->

### [PRINCIPLE_5_NAME]
<!-- Example: V. Observability, VI. Versioning & Breaking Changes, VII. Simplicity -->
[PRINCIPLE_5_DESCRIPTION]
<!-- Example: Text I/O ensures debuggability; Structured logging required; Or: MAJOR.MINOR.BUILD format; Or: Start simple, YAGNI principles -->

## [SECTION_2_NAME]
<!-- Example: Additional Constraints, Security Requirements, Performance Standards, etc. -->

[SECTION_2_CONTENT]
<!-- Example: Technology stack requirements, compliance standards, deployment policies, etc. -->

## [SECTION_3_NAME]
<!-- Example: Development Workflow, Review Process, Quality Gates, etc. -->

[SECTION_3_CONTENT]
<!-- Example: Code review requirements, testing gates, deployment approval process, etc. -->

## Governance
<!-- Example: Constitution supersedes all other practices; Amendments require documentation, approval, migration plan -->

[GOVERNANCE_RULES]
<!-- Example: All PRs/reviews must verify compliance; Complexity must be justified; Use [GUIDANCE_FILE] for runtime development guidance -->

**Version**: [CONSTITUTION_VERSION] | **Ratified**: [RATIFICATION_DATE] | **Last Amended**: [LAST_AMENDED_DATE]
<!-- Example: Version: 2.1.1 | Ratified: 2025-06-13 | Last Amended: 2025-07-16 -->

