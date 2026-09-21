# Problem Definition: Operação de cliente e plataforma

- **Slug**: cliente-plataforma-operacional
- **Created**: 2026-09-21T15:37:19-03:00
- **Inputs used**: intake.md | research.md

## Problem Statement

Uma empresa de gestão de Cloud precisa operar, de forma recorrente e
auditável, os artefatos de infraestrutura, segurança, IaC, Terraform e DSC de
seus clientes, mas esses artefatos e responsabilidades ainda não estão
claramente separados do ciclo dos projetos de software. Essa separação
insuficiente pode dificultar ownership, revisão, evidência, controle de drift,
segregação entre clientes e execução segura de mudanças, justamente quando a
operação precisa escalar para múltiplos clientes, ambientes e provedores.

A existência de padrões de landing zones que distinguem plataforma de
workloads apoia a relevância do problema, mas o impacto quantitativo na
operação desta empresa ainda precisa ser medido. (research.md)

## Affected Users & Stakeholders

### Usuários

- **Operadores de Cloud/Plataforma** — precisam localizar, compreender, validar
  e operar artefatos de infraestrutura e IaC de vários clientes sem misturá-los
  com código de aplicação. O volume de tempo e retrabalho ainda é
  `[NEEDS CLARIFICATION]`.
- **Engenharia de Segurança e Compliance** — precisam verificar baselines,
  políticas, configuração e evidências por cliente e ambiente, mantendo
  rastreabilidade e requisitos de residência/privacidade. As frameworks
  prioritárias ainda são `[NEEDS CLARIFICATION]`.
- **Responsáveis por IaC/DSC** — precisam manter estado desejado, mudanças,
  exceções e divergências identificáveis e revisáveis. A distribuição atual de
  ownership é `[NEEDS CLARIFICATION]`.
- **Owners de plataforma do cliente** — precisam revisar ou aprovar mudanças e
  entender o estado operacional de seus ambientes. A frequência e o nível de
  participação são `[NEEDS CLARIFICATION]`.
- **Owners de aplicações do cliente** — podem ser impactados por mudanças de
  plataforma, mas não devem assumir automaticamente a operação dos artefatos
  que estão fora do software da aplicação. A fronteira de responsabilidade é
  `[NEEDS CLARIFICATION]`.
- **Auditores e solicitantes de evidência** — precisam obter evidências
  confiáveis, contextualizadas e atribuídas ao cliente, ambiente e período
  corretos. O tempo atual de atendimento é desconhecido.

### Stakeholders

- **Liderança da empresa de Managed Services** — decide prioridade, modelo de
  serviço, risco aceitável e retorno operacional/comercial.
- **Service Delivery Manager / operação** — responde pela capacidade de entregar
  mudanças, manter SLAs e coordenar incidentes e aprovações.
- **Responsável por Segurança/Risco** — decide controles mínimos, exceções,
  segregação e evidências necessárias.
- **Responsável por Plataforma/Arquitetura** — define padrões reutilizáveis e
  a consistência entre clientes, sem conhecer ainda `[NEEDS CLARIFICATION]`
  quais decisões devem ser globais ou específicas por cliente.
- **Cliente contratante** — pode aprovar mudanças, exigir evidências e definir
  requisitos regulatórios, de residência e de acesso. O papel contratual exato
  precisa ser confirmado.
- **Finanças/gestão de conta** — avalia custo de operação, margem e
  possibilidade de vender evidência, governança e segurança como parte do
  serviço. Os critérios financeiros ainda são `[NEEDS CLARIFICATION]`.

## Goals

Os resultados abaixo definem o valor de resolver o problema, sem prescrever
como resolvê-lo:

- Tornar inequívoca a fronteira entre artefatos de plataforma/cliente e
  projetos de software, incluindo ownership, revisão e responsabilidade por
  mudanças.
- Reduzir o esforço necessário para localizar, validar, revisar e auditar
  Terraform, IaC, DSC, segurança e infraestrutura de um cliente.
- Aumentar a consistência dos padrões aplicados entre clientes sem apagar
  diferenças legítimas, exceções aprovadas ou requisitos contratuais.
- Permitir que a operação identifique o estado declarado, o estado observado,
  o drift e a evidência correspondente por cliente e ambiente.
- Preservar segregação de tenants, ambientes, credenciais, estados, evidências
  e dados sensíveis.
- Tornar mudanças de plataforma rastreáveis, aprováveis e atribuíveis, com
  distinção entre planejamento, observação e execução.
- Reduzir o tempo de resposta a auditorias, incidentes e solicitações de
  evidência.
- Permitir medir o custo, a qualidade e a capacidade do serviço de Managed
  Services à medida que o número de clientes cresce.

## Non-Goals

- Não definir nesta etapa se o resultado será monorepo, repositório por cliente,
  control plane central, modelo híbrido ou produto SaaS.
- Não escolher agora cloud, provedor de CI/CD, ITSM, CNAPP, SIEM, secrets
  manager ou ferramenta de Terraform.
- Não substituir os projetos de software dos clientes nem assumir ownership do
  código ou do ciclo de entrega das aplicações.
- Não presumir que a operação deverá executar mudanças automaticamente em
  produção.
- Não substituir plataformas especializadas de segurança, observabilidade,
  FinOps, ITSM ou gestão de identidades.
- Não estabelecer ainda frameworks regulatórios prioritários, SLAs, preço,
  margem ou escopo contratual sem validação com a liderança e clientes.
- Não tratar as provas atuais do template em fixtures locais como evidência de
  integração real com APIs cloud, isolamento real entre clientes ou operação
  produtiva.

## Success Metrics

As metas numéricas abaixo são propostas para validação no discovery. Os
baselines atuais não foram fornecidos e devem ser medidos antes de confirmar os
targets.

- **Separação de ownership**: 100% dos artefatos incluídos no piloto devem ter
  cliente, ambiente, owner operacional e owner aprovador identificados
  (baseline: desconhecido).
- **Localização operacional**: reduzir em pelo menos 50% o tempo mediano para
  localizar o artefato, evidência e owner corretos de uma mudança ou finding
  (baseline: `[NEEDS CLARIFICATION]`).
- **Rastreabilidade**: 100% das mudanças de plataforma do piloto devem possuir
  origem, revisão, aprovação, identidade, ambiente e resultado registrados
  (baseline: desconhecido).
- **Segregação**: zero ocorrências de acesso cruzado não autorizado entre
  clientes, ambientes, credenciais, estados ou evidências no piloto (baseline:
  desconhecido).
- **Drift**: medir por cliente a quantidade, severidade e idade dos drifts; após
  estabelecer a linha de base, reduzir em pelo menos 30% a idade mediana de
  drift classificado como acionável (baseline: desconhecido).
- **Auditoria**: reduzir em pelo menos 50% o tempo mediano para produzir um
  pacote de evidências solicitado (baseline: `[NEEDS CLARIFICATION]`).
- **Reuso**: medir a proporção de artefatos/padrões compartilhados e o custo de
  atualizá-los, sem aceitar como sucesso apenas aumentar cópia ou duplicação
  (baseline: desconhecido).
- **Qualidade do serviço**: acompanhar incidentes, retrabalho, mudanças
  reprovadas, rollbacks e violações de janela associados a plataforma por
  cliente (baseline: desconhecido).
- **Escala operacional**: confirmar que o custo operacional por cliente não
  cresce linearmente com o número de clientes no piloto; o limiar aceitável é
  `[NEEDS CLARIFICATION]`.
- **Valor para o cliente**: validar em entrevistas e/ou renovação contratual
  que clientes entendem o boundary de plataforma e consideram úteis as
  evidências e controles entregues (métrica qualitativa inicialmente;
  `[NEEDS CLARIFICATION]`).

## Cost of Inaction

Se o problema permanecer sem definição e tratamento, a empresa tende a
continuar misturando responsabilidades de plataforma e software, com possível
duplicação de padrões, ownership ambíguo, maior esforço de auditoria, drift
menos visível e maior risco de mudanças executadas no contexto incorreto.
Também ficará difícil saber se o serviço de Managed Services está escalando
com qualidade ou apenas transferindo esforço manual para cada novo cliente.

Esses impactos são hipóteses operacionais apoiadas pelo research, não medições
da empresa. O custo real da inação deve ser estabelecido por uma linha de base
de tempo, incidentes, drift, mudanças, auditorias e custo por cliente.

## Open Questions

- [NEEDS CLARIFICATION: Qual é a unidade contratual e operacional de isolamento:
  cliente, tenant, subscription/account, ambiente ou combinação?]
- [NEEDS CLARIFICATION: Qual é a população inicial do problema: número de
  clientes, provedores, contas, ambientes, workloads e mudanças mensais?]
- [NEEDS CLARIFICATION: Quais tipos de artefatos pertencem obrigatoriamente ao
  domínio de plataforma e quais permanecem no domínio de software?]
- [NEEDS CLARIFICATION: Quem pode ler, revisar, aprovar, executar e auditar
  cada tipo de artefato ou mudança?]
- [NEEDS CLARIFICATION: A operação inicial será advisory/read-only, ou incluirá
  execução controlada em ambientes reais?]
- [NEEDS CLARIFICATION: Quais requisitos de LGPD, residência, retenção,
  criptografia e segregação de secrets se aplicam por cliente?]
- [NEEDS CLARIFICATION: Quais frameworks de segurança e compliance têm
  prioridade comercial e operacional?]
- [NEEDS CLARIFICATION: Quais padrões precisam ser globais, versionados por
  cliente, opcionais ou sujeitos a exceção?]
- [NEEDS CLARIFICATION: Quais integrações existentes são obrigatórias para
  operação e evidência: GitHub/Azure DevOps, ITSM, CSPM, SIEM, FinOps e
  secrets management?]
- [NEEDS CLARIFICATION: O cliente final precisa de acesso direto, aprovação,
  relatórios ou apenas evidências entregues pela empresa de gestão?]
- [NEEDS CLARIFICATION: Qual SLA de mudança, incidente e evidência deve ser
  suportado?]
- [NEEDS CLARIFICATION: Qual baseline atual será usado para confirmar redução de
  tempo, drift, retrabalho, incidentes e custo por cliente?]
- [NEEDS CLARIFICATION: Qual critério determina que a iniciativa deve avançar,
  ser redimensionada ou ser interrompida após o piloto?]

## Handoff

O problema está suficientemente articulado para seguir à modelagem de
conceito, mas as métricas e a topologia de operação ainda dependem de
validação. Próximo passo recomendado:

```text
/nc-assess-shape slug=cliente-plataforma-operacional
```
