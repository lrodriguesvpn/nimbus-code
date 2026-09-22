# Idea Intake: Repositório operacional de cliente e plataforma

- **Slug**: cliente-plataforma-operacional
- **Created**: 2026-09-21T15:32:19-03:00
- **Source**: pasted text + existing repository context
- **Type**: new-capability

## Idea (as captured)

> Somos uma empresa de gestão de CLOUD, e temos um desafio de operar os IaC dos clientes (Terraform), os DSC e demais, que já são suportados por esse REPO TEMPLATE Client/Plataforma. Hoje gostaríamos de ter um local onde tudo que não seja um projeto de SOFTWARE do cliente esteja ali: SEGURANÇA, INFRA, IAC, etc., com constituição própria e padrões reaproveitados. O objetivo é olhar o research feito acima e refazê-lo considerando este intake.

O contexto do repositório existente inclui um preset de plataforma/cliente, contratos de Evidence Plane, Desired State Plane e Delivery Plane, lifecycle de governança, CMDB, baselines, evidências, drift policy e workflows Terraform read-only/protegidos.

## Restated

A empresa quer consolidar, em um espaço operacional próprio por cliente/plataforma, todos os artefatos e processos que não pertencem aos projetos de software do cliente, incluindo segurança, infraestrutura, IaC, Terraform e Desired State Configuration. Esse espaço deverá ter uma constituição própria e permitir o reaproveitamento consistente de padrões já suportados pelo template.

O problema a ser investigado é como transformar o template atual em uma base operacional confiável para gerir esses artefatos e responsabilidades de Cloud e Segurança sem misturá-los ao ciclo de desenvolvimento dos softwares dos clientes.

## Origin & Context

- **Raised by**: empresa de gestão de Cloud / [NEEDS CLARIFICATION: área ou papel responsável pela decisão]
- **Trigger**: necessidade operacional de organizar e operar IaC, Terraform, DSC, Segurança e Infraestrutura dos clientes fora dos repositórios de projetos de software.
- **Existing context**: o repositório já suporta um preset Client/Plataforma com governança, inventário multicloud, evidências, baselines, lifecycle e guardrails read-only.
- **Prior research context**: a pesquisa anterior apontou como hipóteses de oportunidade um control plane de evidências e drift, compliance evidence-as-code, automação protegida, integração entre FinOps e SecOps e operação gerenciada orientada por serviço de negócio. Essas hipóteses ainda precisam ser reavaliadas especificamente para o contexto de operação de artefatos de plataforma por cliente.

## Idea Boundaries Captured

- **Incluído na ideia**: IaC, Terraform, DSC, Segurança, Infraestrutura, governança, constituição própria, padrões reutilizáveis e artefatos operacionais de Cloud.
- **Fora do foco inicial**: projetos de software dos clientes.
- **Ainda não definido**: se o espaço será um repositório único multi-cliente, um repositório por cliente, uma composição de repositórios ou uma combinação desses modelos.

## First-Glance Unknowns

- [NEEDS CLARIFICATION: Qual é a unidade de organização e isolamento: um repositório por cliente, um repositório central multi-tenant, uma organização/projeto por cliente ou outra composição?]
- [NEEDS CLARIFICATION: Quais artefatos devem obrigatoriamente residir nesse espaço: Terraform, Terragrunt, Bicep, Kubernetes, DSC, políticas, scripts, runbooks, evidências, contratos, relatórios, tickets e documentação?]
- [NEEDS CLARIFICATION: O espaço apenas versionará e governará os artefatos ou também executará discovery, plan, validação, apply, drift remediation e operações recorrentes?]
- [NEEDS CLARIFICATION: Qual é o limite entre esse espaço de plataforma e os repositórios de software dos clientes?]
- [NEEDS CLARIFICATION: Quais clouds, tenants, subscriptions, accounts, projetos e ambientes precisam ser suportados na primeira versão?]
- [NEEDS CLARIFICATION: O modelo deve atender apenas a operação interna da empresa ou também oferecer visibilidade, aprovação e evidências ao cliente final?]
- [NEEDS CLARIFICATION: Quais papéis precisam aprovar mudanças: operação, segurança, cliente, owner da aplicação, CAB ou combinação?]
- [NEEDS CLARIFICATION: O modo inicial será somente advisory/read-only ou haverá execução controlada de mudanças em ambientes reais?]
- [NEEDS CLARIFICATION: Quais frameworks e obrigações são prioritários: LGPD, CIS, NIST, ISO 27001, PCI DSS, SOC 2, requisitos setoriais ou controles próprios?]
- [NEEDS CLARIFICATION: Como serão segregados segredos, credenciais, evidências sensíveis e dados pessoais entre clientes?]
- [NEEDS CLARIFICATION: Quais padrões existentes devem ser reaproveitados e quais precisam de versionamento independente por cliente?]
- [NEEDS CLARIFICATION: Como serão tratados forks, overlays, exceções, customizações e divergências legítimas entre clientes?]
- [NEEDS CLARIFICATION: Quais integrações operacionais são obrigatórias: GitHub Enterprise, Azure DevOps, Jira, ServiceNow, SIEM, CSPM, FinOps, Terraform Cloud ou outras?]
- [NEEDS CLARIFICATION: Qual é o modelo de serviço esperado: projeto de implantação, operação recorrente, SOC/NOC gerenciado, plataforma self-service ou combinação?]
- [NEEDS CLARIFICATION: Quais métricas definem sucesso: redução de tempo operacional, menor drift, menos incidentes, evidência mais rápida, menor custo ou aumento de margem do serviço?]
- [NEEDS CLARIFICATION: Qual é o ICP prioritário e o tamanho operacional esperado: número de clientes, contas, subscriptions, workloads e mudanças por período?]

## Additional Intake Round — 2026-09-22

- **Slug**: cliente-plataforma-operacional (mesmo assessment, nova rodada de intake)
- **Created**: 2026-09-22T07:48:50-03:00
- **Source**: texto colado + contexto de repositório existente
- **Type**: refinement (responde parcialmente às blocking questions do `decision.md` de 2026-09-21)
- **Trigger imediato**: `decision.md` marcou verdict `needs-clarification` e recomendou revisitar `research`/`define` com dados internos. Este intake traz um dado novo relevante antes dessa revisita.

### Idea (as captured)

> No modelo Plataforma vamos iniciar um ASSESS INTAKE (verificar se já existia
> algum estudo) pra incorporar melhorias nesse ambiente para realizar o CMDB
> (Terraform), BASE LINES, SCHEMAS de bancos, DSC, e etc, já temos muita coisa
> no TEMPLATE, mas preciso revisar, ver o que faz sentido e o que não faz mais
> sentido, incluir como Contexto o nosso REPO Nuvem365-nimbuscode-spec como o
> nosso FINOPS (o FINOPS é o site pra clientes, precisamos ter o REPO na
> estrutura de REPO FIRST Company pra ter tudo de IaC e estado no REPO
> Cliente/Plataforma).

### Restated

Antes de decidir qualquer coisa nova, a empresa quer auditar o que já existe
no template (spec [004-platform-cmdb-dsc-model](/Users/lrodrigues/projects/nimbus-code-spec-kit-template.worktrees/plataforma-assess-intake-improvements/specs/004-platform-cmdb-dsc-model/spec.md) e o módulo implementado
[platform-governance/](/Users/lrodrigues/projects/nimbus-code-spec-kit-template.worktrees/plataforma-assess-intake-improvements/platform-governance) — CMDB via Terraform, baselines, schemas de banco em
`platform-governance/db/migrations/`, DSC) e decidir, item a item, o que ainda
faz sentido manter e o que não faz mais sentido, à luz de um novo dado
operacional: existe um repositório real chamado "Nuvem365-nimbuscode-spec"
que hoje cumpre o papel de FinOps — descrito como "o site pra clientes". A
empresa quer que esse repositório (ou o padrão que ele representa) siga uma
estrutura "Repo First Company", de forma que todo o IaC e o estado
(Terraform state, configuração desejada) fique hospedado dentro do Repo
Cliente/Plataforma de cada cliente, e não disperso ou fora desse modelo.

### Origin & Context

- **Raised by**: mesma origem do intake original (empresa de gestão de Cloud) — [NEEDS CLARIFICATION: área/papel responsável confirmado].
- **Trigger**: necessidade de revisar o inventário de artefatos já suportados pelo template (CMDB, Terraform, baselines, schemas, DSC) antes de expandir o escopo, e de incorporar um repositório real de FinOps ("Nuvem365-nimbuscode-spec") ao modelo operacional.
- **Existing context adicional identificado nesta rodada**:
  - [004-platform-cmdb-dsc-model](/Users/lrodrigues/projects/nimbus-code-spec-kit-template.worktrees/plataforma-assess-intake-improvements/specs/004-platform-cmdb-dsc-model/spec.md) — spec formal já `Ready`, complexidade S4, cobre autenticação SSO, coleta multicloud, CMDB para IA, baselines M365, e modelo DSC versionado.
  - [platform-governance/](/Users/lrodrigues/projects/nimbus-code-spec-kit-template.worktrees/plataforma-assess-intake-improvements/platform-governance) — implementação já existente com discovery (Azure/AWS/GCP), baseline engine, DSC profile composer/renderer, CMDB consolidation service, validação advisory de Terraform, migrations de banco (`001_initial.sql` a `004_dsc_profiles.sql`).
  - [platform/baseline-registry.yaml](/Users/lrodrigues/projects/nimbus-code-spec-kit-template.worktrees/plataforma-assess-intake-improvements/platform/baseline-registry.yaml), [platform/drift-policy.yaml](/Users/lrodrigues/projects/nimbus-code-spec-kit-template.worktrees/plataforma-assess-intake-improvements/platform/drift-policy.yaml) e [platform/evidence-registry.yaml](/Users/lrodrigues/projects/nimbus-code-spec-kit-template.worktrees/plataforma-assess-intake-improvements/platform/evidence-registry.yaml) — registros de plataforma já presentes na raiz do template.
  - Repositório **Nuvem365-nimbuscode-spec** (externo a este template) — apontado pelo usuário como o site de FinOps voltado a clientes; ainda não inspecionado nesta sessão. [NEEDS CLARIFICATION: localização/organização GHE, acesso e conteúdo atual desse repositório.]

### Idea Boundaries Captured (atualização desta rodada)

- **Incluído nesta rodada**: auditoria de reuso (o que do template ainda serve) para CMDB, Terraform, baselines, schemas de banco e DSC; inclusão do domínio FinOps (via repo Nuvem365-nimbuscode-spec) como parte do contexto operacional de plataforma; exigência de que IaC e estado residam no Repo Cliente/Plataforma segundo um padrão "Repo First Company".
- **Ainda fora do foco desta rodada**: desenho de solução técnica definitiva; migração ou refatoração do repo Nuvem365-nimbuscode-spec em si.
- **Ainda não definido**: o que exatamente significa "Repo First Company" neste contexto (é um padrão institucional já nomeado em outro lugar, ou uma diretriz nova sendo proposta agora?); se o FinOps (Nuvem365-nimbuscode-spec) passa a ser um cliente do modelo Client/Plataforma, um caso especial, ou o próprio padrão de referência a ser replicado para os demais clientes.

### First-Glance Unknowns (novas, específicas desta rodada)

- [NEEDS CLARIFICATION: "Repo First Company" é uma convenção/nome já estabelecido na empresa (ex.: um padrão de nomenclatura ou arquitetura de repositórios documentado em outro lugar) ou é uma proposta nova surgindo aqui pela primeira vez?]
- [NEEDS CLARIFICATION: O repositório Nuvem365-nimbuscode-spec já existe hoje com IaC/Terraform próprio, ou hoje ele só contém o código do site FinOps sem infraestrutura versionada?]
- [NEEDS CLARIFICATION: "Ter o REPO na estrutura de REPO FIRST Company" significa migrar/mover o Nuvem365-nimbuscode-spec para dentro do padrão Client/Plataforma deste template, ou apenas aplicar o mesmo padrão de organização a ele mantendo-o como repositório separado?]
- [NEEDS CLARIFICATION: Quais partes específicas do que já existe em `specs/004-platform-cmdb-dsc-model` e `platform-governance/` a empresa já considera que "não fazem mais sentido"? (ainda não apontado explicitamente pelo usuário — precisa ser levantado no research/define.)]
- [NEEDS CLARIFICATION: O FinOps (custos, billing) é um domínio de dado a mais dentro do CMDB/baseline existente, ou exige um plano de dados e schema próprios (ex.: dados de billing multicloud, tags de custo, alocação por cliente)?]
- [NEEDS CLARIFICATION: Quem no time de FinOps/Nuvem365-nimbuscode-spec precisa ser consultado para validar a integração com o modelo Client/Plataforma?]

## Handoff

Esta rodada de intake **não substitui** a necessidade de research/define
apontada no `decision.md` de 2026-09-21 — ela adiciona um dado concreto (o
repositório Nuvem365-nimbuscode-spec como FinOps e a exigência de padrão
"Repo First Company") que deve ser incorporado à próxima pesquisa. Próximo
passo recomendado:

```text
/nc-assess-research slug=cliente-plataforma-operacional
```

O research deve, especificamente: (1) auditar `specs/004-platform-cmdb-dsc-model`
e `platform-governance/` item a item para separar o que continua válido do que
está obsoleto; (2) investigar o repositório Nuvem365-nimbuscode-spec e seu papel
de FinOps; (3) revisar as blocking questions já registradas em `decision.md`
que ainda seguem em aberto, incluindo as novas listadas acima. Depois do
research, seguir para `/nc-assess-define` e, se necessário, `/nc-assess-shape`
e `/nc-assess-decide` para gerar um novo veredito.
