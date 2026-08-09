# Princípios Não-Negociáveis da VPN Dev

<!--
  © Venha Pra Nuvem — Propriedade Intelectual Exclusiva.
  Uso restrito a colaboradores autorizados da organização venha-pra-nuvem.
  Cópia, redistribuição ou uso externo são proibidos — ver LICENSE no repositório
  nimbus-code-spec-kit-template. Alterações exigem aprovação do @vpndev-arch-board.
-->

<!--
  Este bloco é inserido pelo preset `vpndev-standards` (estratégia `wrap`) antes da
  constituição específica de cada projeto. Ele representa o conjunto MÍNIMO de regras
  que valem para TODO projeto da organização — o restante da constituição (abaixo)
  continua sendo preenchido normalmente via `/speckit-constitution` para o que for
  específico deste projeto.

  Alterar este arquivo é uma mudança de política organizacional, não de projeto:
  requer aprovação do time responsável pelos padrões da VPN Dev e deve seguir o
  mesmo controle de versão do preset (ver presets/vpndev-standards/preset.yml).
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
  antes de `/speckit-tasks`. Grafo ausente ou desatualizado bloqueia merge sob a
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
  antes de `/speckit-tasks`, e o consumo real comparado com ela no fechamento
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

- Todo projeto deve manter a taxonomia de labels do bundle VPN Dev criada por
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
  Spec Kit em infraestrutura: a classificação S0–S4, o Module Dependency
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
- **Feature flags têm ciclo de vida**: toda flag criada deve ter data de expiração
  ou critério de remoção definidos no `plan.md`. Flags não removidas após a
  feature ser considerada estável são dívida técnica e devem ser registradas
  como Issue.
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

## Qualidade e Processo

- Nenhuma implementação de feature relevante começa sem uma especificação formal
  (`/speckit-specify` → `/speckit-plan` → `/speckit-tasks` → `/speckit-implement`).
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

{CORE_TEMPLATE}
