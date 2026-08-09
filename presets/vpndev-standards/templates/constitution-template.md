# Princípios Não-Negociáveis da VPN Dev

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
    repositório (`speckit-vpndev-standards`).
  - **Escopo de projeto**: `docs/adr/` no repositório do projeto.
- O Architecture Decision Log do `plan.md` captura decisões locais de feature;
  quando a decisão tiver impacto organizacional, adicionar link para o ADR
  correspondente.
- Template e guia em [`docs/adr-guide.md`](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/speckit-vpndev-standards/blob/main/docs/adr-guide.md).

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
- [`docs/ai-code-quality-and-observability.md`](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/speckit-vpndev-standards/blob/main/docs/ai-code-quality-and-observability.md) — revisão por IA, seleção de modelos S0–S4, tracing, gestão de bugs
- [`docs/module-graphs.md`](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/speckit-vpndev-standards/blob/main/docs/module-graphs.md) — grafos de módulos, Graph Guard, templates
- [`docs/adr-guide.md`](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/speckit-vpndev-standards/blob/main/docs/adr-guide.md) — como criar e manter ADRs organizacionais

{CORE_TEMPLATE}
