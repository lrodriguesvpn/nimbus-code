# Assessment Research: Repositório operacional de cliente e plataforma

- **Slug**: cliente-plataforma-operacional
- **Research date**: 2026-09-21
- **Input**: [intake.md](./intake.md)
- **Status**: evidência inicial; ainda não é decisão de produto

## Resumo executivo

Há evidência forte de que operações Cloud maduras separam uma fundação de
plataforma — identidade, segurança, rede, governança, gestão e automação — dos
ambientes de workload/aplicação. O Azure Cloud Adoption Framework chama essas
duas camadas de *platform landing zone* e *application landing zones*; o AWS
Control Tower usa landing zone, controls, Account Factory e dashboard para
governar ambientes multi-account; e o Google Cloud descreve landing zones como
configurações modulares e escaláveis que abrangem identidade, gestão de
recursos, segurança e rede.

Isso apoia a direção do intake: manter os artefatos de plataforma, segurança,
IaC, Terraform e DSC fora do ciclo dos projetos de software. Porém, essas
fontes não determinam se uma MSP deve usar um repositório por cliente, um
control plane central ou um modelo híbrido. Essa escolha depende de requisitos
internos de isolamento, delegação, volume, contratos e ferramentas.

**Conclusão preliminar:** há uma oportunidade plausível de produto/operação,
mas a hipótese mais segura para a próxima etapa é “repositório operacional de
plataforma por cliente, baseado em padrões versionados e governança central”,
mantida como hipótese até obter dados de clientes, volume e processo de
mudança. `[ASSUMPTION]`

## 1. Usuários & Demanda

### Evidências disponíveis

- O usuário relata um problema operacional concreto: a empresa de gestão de
  Cloud precisa operar Terraform, IaC, DSC, Segurança e Infraestrutura de
  clientes sem misturar esses artefatos com projetos de software. Isso é uma
  evidência qualitativa de dor interna, mas não mede frequência, custo ou
  número de clientes. A fonte é o [intake](./intake.md).
- O intake identifica papéis distintos de plataforma, segurança, executivo e
  operação, mas ainda não confirma quem aprova mudanças nem quem consome as
  evidências. `[NEEDS CLARIFICATION]`
- A documentação do Azure CAF distribui responsabilidades entre funções como
  identidade, segurança, gestão, governança e platform automation/DevOps. Isso
  é consistente com múltiplos usuários e controles no espaço de plataforma,
  embora não seja evidência de demanda específica da empresa. [CAF design
  areas](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/design-areas)

### Lacunas de demanda

Não há ainda tickets agregados, entrevistas de operadores, dados de incidentes,
tempo gasto por mudança, quantidade de repositórios, taxa de drift, tempo para
produzir evidências ou disposição de clientes a usar um portal/fluxo de
aprovação. Esses dados são necessários antes de afirmar ROI.

### Perguntas de pesquisa recomendadas

1. Quantas horas por cliente/mês são gastas localizando, validando e executando
   mudanças de plataforma?
2. Quais incidentes ou retrabalhos ocorreram por mistura entre software e
   plataforma?
3. Quantos operadores e clientes precisam de leitura, aprovação, execução e
   auditoria?
4. Qual é o menor conjunto de clientes representativo para um piloto?

## 2. Arte prévia, alternativas e concorrência

### Padrões comprovados no ecossistema

- O Azure CAF define uma separação explícita entre **platform landing zone**,
  que centraliza governança, segurança e recursos compartilhados, e
  **application landing zones**, onde os times implantam workloads sob
  guardrails da plataforma. Também recomenda accelerators ou custom build com
  IaC. [What is an Azure landing zone?](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/)
- O AWS Control Tower oferece uma camada de orquestração para ambientes
  multi-account, com landing zone, controles preventivos/detectivos/proativos,
  Account Factory e dashboard. A documentação afirma que controles ajudam a
  detectar/prevenir drift e que uma camada de orquestração é útil quando há
  mais que algumas contas. [What Is AWS Control Tower?](https://docs.aws.amazon.com/controltower/latest/userguide/what-is-control-tower.html)
- O Google Cloud descreve landing zones como uma base modular e escalável para
  adoção segura, com identidade, resource management, security e networking.
  Também admite mais de uma landing zone quando workloads têm requisitos
  diferentes, compartilhando alguns elementos e variando outros. [Google
  Cloud landing zones](https://docs.cloud.google.com/architecture/landing-zones)
- O HCP Terraform oferece o conceito de **workspaces** como unidade operacional
  documentada para organizar configurações/estado e execução Terraform. Isso
  prova que isolamento lógico por workspace é uma alternativa estabelecida,
  mas não prova que workspace equivale a isolamento contratual entre clientes.
  [HCP Terraform workspaces](https://developer.hashicorp.com/terraform/cloud-docs/workspaces)
- O Microsoft Defender for Cloud reúne CSPM, DevSecOps e CWPP para recursos
  Azure, AWS, GCP e ambientes on-premises. Isso confirma que postura,
  proteção de workload e segurança de código podem ser correlacionadas
  transversalmente, mas também mostra que o repositório operacional não deve
  presumir que será o substituto de um CNAPP/SIEM. [Defender for Cloud
  overview](https://learn.microsoft.com/en-us/azure/defender-for-cloud/defender-for-cloud-introduction)
- A AWS Managed Services descreve mecanismos de segurança, guardrails e
  verificações alinhados a NIST e a requisitos como PCI-DSS, HIPAA, GDPR, ISO
  e SOC. Isso é evidência de que serviços gerenciados vendem operação,
  compliance e auditoria como parte do serviço, não somente código IaC. [AWS
  Managed Services](https://aws.amazon.com/managed-services/)

### Alternativas que precisam ser comparadas

| Alternativa | Benefício | Risco principal | Evidência atual |
|---|---|---|---|
| Repositório por cliente | Isolamento e ownership claros; facilita auditoria contratual | Duplicação de padrões e custo de atualização | `[ASSUMPTION]`; compatível com perfis/tenants já existentes |
| Control plane central multi-cliente | Reuso máximo, visão operacional consolidada | Blast radius, vazamento de contexto e complexidade de autorização | `[ASSUMPTION]`; análogo conceitual a camadas centrais de governança |
| Modelo híbrido: padrões centrais + estado/execução por cliente | Equilibra reuso e isolamento | Exige contratos de versão, promoção e exceção | `[HYPOTHESIS]`; melhor candidato para validar |
| Ferramenta SaaS/ITSM/CNAPP como centro | Menor construção própria e integrações prontas | Lock-in, limites de customização e separação entre evidência e IaC | Alternativas existentes acima; comparação de custo não realizada |
| Monorepo operacional | Busca e governança uniformes | Escala de permissões, histórico e pipelines | `[ASSUMPTION]`; sem evidência interna |

### O que o template já provou

No próprio repositório, a pesquisa anterior verificou:

- runtime de governança com SSO simulado, discovery multicloud, CMDB,
  baselines, DSC versionado, Terraform advisory e freshness;
- contratos de Evidence Plane, Desired State Plane e Delivery Plane;
- política padrão advisory/read-only que bloqueia escrita direta;
- lifecycle `discovery → imported → plan_diff_zero →
  landing_zone_generated → managed`;
- workflows de refresh de evidências e Terraform plan com artifact, zero-diff e
  bloqueio de destroy inesperado;
- 16 testes Node passando, 6 testes Bats de contratos/guardrails passando e
  validação do bloqueio de comandos de escrita passando.

Essas são provas de comportamento do template em fixtures locais. Os
adaptadores Azure, AWS e GCP ainda não provam integração real com APIs cloud,
isolamento real entre clientes, execução de apply em produção ou operação
comercial MSP.

## 3. Mercado & Contexto

### Sinais estruturais

- As três grandes clouds publicam arquiteturas de landing zone que tratam
  segurança, governança, identidade e operações como uma fundação distinta dos
  workloads. Isso reduz o risco de a ideia ser apenas uma preferência
  organizacional local.
- O AWS Control Tower e o Azure CAF tratam drift, controls/guardrails,
  organização multi-account/subscription e automação como preocupações
  contínuas, não como atividade única de implantação.
- A CIS posiciona seus Controls como um conjunto priorizado e simplificado de
  boas práticas, incluindo configuração e higiene operacional, com mapeamentos
  para GDPR, PCI DSS e outras regulamentações. [CIS Controls at a
  glance](https://www.cisecurity.org/controls)
- O NIST Cybersecurity Framework é uma referência pública de gestão de risco;
  sua página oficial mantém materiais de adoção e aprendizagem para organizar
  atividades de segurança. [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)

### Custo provável de não fazer nada

Os riscos abaixo são inferências operacionais, não métricas observadas:

- mudanças de plataforma misturadas a software dificultam ownership, revisão e
  rollback; `[ASSUMPTION]`
- padrões divergentes por cliente aumentam manutenção e dificultam auditoria;
  `[ASSUMPTION]`
- evidências dispersas aumentam o tempo de resposta a auditorias e incidentes;
  `[ASSUMPTION]`
- execução sem separação formal de identidade, aprovação e tenant pode ampliar
  blast radius; `[ASSUMPTION]`
- drift não detectado pode tornar o estado declarado de Terraform diferente do
  ambiente real; o fato de clouds tratarem drift como preocupação explícita é
  suportado pelas fontes de CAF e Control Tower, mas a magnitude local ainda é
  desconhecida.

## 4. Dados, restrições e compliance

### Restrições observadas

- O template já impõe separação entre Evidence, Desired State e Delivery Plane,
  proíbe cloud-write direto por padrão, requer aprovação humana para delivery e
  exige identidade dedicada. [execution-policy.yaml](../../../.nimbus/execution-policy.yaml)
- O perfil de plataforma inclui tenant, owners, provedores, ambientes,
  criticidade, residência de dados, classificação LGPD e política de execução.
  [platform-profile.yaml](../../../.nimbus/platform-profile.yaml)
- A pesquisa interna não contém ainda volumes de tenants, contas,
  subscriptions, estados Terraform, evidências ou mudanças. Portanto, não é
  possível dimensionar monorepo, pipelines, CMDB ou retenção.
- Dados de segurança, logs, inventário e evidências podem conter informação
  sensível ou pessoal. A necessidade de residência, retenção, acesso por
  cliente e segregação criptográfica deve ser definida; o intake menciona
  LGPD, mas não fornece classificação detalhada por artefato.

### Requisitos que a solução provavelmente terá de satisfazer

Estes são requisitos derivados de fontes e do contexto, ainda sujeitos a
validação:

1. **Isolamento por cliente e ambiente**: permissões, secrets, estados,
   evidências e logs não devem atravessar tenants sem autorização explícita.
2. **Reuso versionado**: módulos, constituição, baselines e políticas devem ser
   promovidos com versionamento e exceções rastreáveis.
3. **Proveniência e auditoria**: cada finding/evidência/mudança deve registrar
   origem, horário, identidade, escopo e aprovação.
4. **Drift e zero-diff**: o estado observado e o desejado precisam ser
   comparáveis sem transformar refresh em apply.
5. **Delivery protegido**: qualquer mudança real deve manter revisão, aprovação,
   identidade dedicada, janela e trilha de auditoria.
6. **Interoperabilidade**: o espaço deve integrar repositórios, CI/CD, ITSM,
   secrets management, CSPM/SIEM e clouds sem se declarar substituto de todos
   esses sistemas.
7. **Retenção e residência**: evidências e logs precisam de política por
   cliente, jurisdição e classificação LGPD.

## Síntese de hipóteses

| Hipótese | Status da evidência | Como testar |
|---|---|---|
| Separar plataforma de software reduz ambiguidade operacional | Apoiada por CAF e landing zones; benefício local não medido | Comparar tempo de triagem, incidentes e ownership antes/depois em 2–3 clientes |
| Modelo híbrido é melhor que monorepo ou cópia integral | `[HYPOTHESIS]` | Pilotar padrões centrais versionados + estado/execução isolados por cliente |
| Evidência e drift são parte vendável do serviço MSP | Apoiada por AWS Managed Services/Control Tower e Defender CSPM; demanda local não medida | Entrevistas com clientes, análise de auditorias e disposição de pagar |
| O template pode ser a base operacional | Provado em fixtures e contratos locais | Teste com APIs reais read-only, dois tenants e dados anonimizados |
| Apply protegido deve permanecer separado do repositório | Apoiado pela execution policy do próprio template e práticas de guardrail | Simular mudança aprovada, rejeitada, destroy inesperado e rollback |

## Decisão de pesquisa

A oportunidade merece avançar para **definição formal do problema**, desde que a
próxima etapa trate o repositório como um produto operacional de Managed
Services, e não apenas como reorganização de pastas. O research apoia estes
eixos:

- separação explícita Client/Plataforma versus Software;
- padrões centrais reutilizáveis com estado e evidência isolados por cliente;
- governança de IaC/DSC, drift e compliance evidence-as-code;
- delivery protegido e integração com ferramentas existentes;
- métricas de operação e valor comercial.

Não há evidência suficiente para escolher ainda:

- topologia final de repositórios;
- clouds e frameworks prioritários;
- escopo de execução automática;
- produto self-service versus operação interna;
- preço, margem ou tamanho do mercado.

## Próximo handoff

Recomenda-se `/nc-assess-define slug=cliente-plataforma-operacional`, levando
para a definição do problema as evidências, hipóteses e lacunas acima. A
definição deve incluir entrevistas/dados internos como condição para converter
as hipóteses de demanda e ROI em metas mensuráveis.
