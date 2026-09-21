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

## Handoff

O próximo passo recomendado é executar `/nc-assess-research slug=cliente-plataforma-operacional`, refazendo a pesquisa com foco no modelo operacional de uma empresa de gestão de Cloud e na separação entre repositórios de software e plataforma/cliente. Depois da pesquisa, seguir para `/nc-assess-define`.
