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

## Próximo handoff (Round 1)

Recomenda-se `/nc-assess-define slug=cliente-plataforma-operacional`, levando
para a definição do problema as evidências, hipóteses e lacunas acima. A
definição deve incluir entrevistas/dados internos como condição para converter
as hipóteses de demanda e ROI em metas mensuráveis.

---

## Round 2 — Research adicional (2026-09-22)

- **Research date**: 2026-09-22
- **Input**: [intake.md § Additional Intake Round — 2026-09-22](./intake.md)
- **Gatilho**: `decision.md` (verdict `needs-clarification`) pediu para
  revisitar `research` com dados internos antes de qualquer novo `define`. O
  usuário pediu, nesta rodada: (1) auditoria item-a-item dos artefatos de
  template (CMDB/Terraform/baselines/schemas/DSC) já existentes, (2) inclusão
  do repositório `Nuvem365-nimbuscode-spec` como contexto de FinOps, e (3) um
  requisito de "Repo First Company" (IaC e estado sempre no Repo
  Cliente/Plataforma, nunca junto do código de produto).

Esta rodada teve acesso real ao GitHub Enterprise da organização
`venha-pra-nuvem` (via `gh` CLI/API), o que muda o research de "apenas
hipóteses de fora" para **evidência direta do próprio ambiente** em vários
pontos abaixo.

### 2.1 Auditoria item-a-item dos artefatos de template (CMDB/Terraform/Baselines/Schemas/DSC)

Escopo auditado: [specs/004-platform-cmdb-dsc-model/spec.md](/Users/lrodrigues/projects/nimbus-code.worktrees/plataforma-assess-intake-improvements/specs/004-platform-cmdb-dsc-model/spec.md),
[platform-governance/](/Users/lrodrigues/projects/nimbus-code.worktrees/plataforma-assess-intake-improvements/platform-governance),
[platform/baseline-registry.yaml](/Users/lrodrigues/projects/nimbus-code.worktrees/plataforma-assess-intake-improvements/platform/baseline-registry.yaml),
[platform/drift-policy.yaml](/Users/lrodrigues/projects/nimbus-code.worktrees/plataforma-assess-intake-improvements/platform/drift-policy.yaml),
[platform/evidence-registry.yaml](/Users/lrodrigues/projects/nimbus-code.worktrees/plataforma-assess-intake-improvements/platform/evidence-registry.yaml).

| Item | Estado observado | Ainda faz sentido? | Evidência |
|---|---|---|---|
| Modelo conceitual (SSO, discovery multicloud, CMDB, baseline M365, DSC versionado, Terraform em modo advisory) | Especificado em detalhe, S4, status "Ready" | **Sim, como referência de modelo** — o desenho (advisory-first, trilha de exceção obrigatória, cadência de refresh) é coerente com o que a Round 1 já recomendou (drift ≠ apply, delivery protegido) | `spec.md` |
| Implementação em `platform-governance/` (discovery Azure/AWS/GCP, baseline engine, DSC composer, migrations 001–004, validador Terraform advisory) | Código real, testado (contract/integration/e2e/perf), mas **isolado neste repo-template**, sem cliente real consumindo | `[NEEDS CLARIFICATION]` — é um protótipo de referência ou pretende virar o motor de produção? Hoje não há evidência de uso por nenhum cliente Nuvem365 | diretório `platform-governance/` |
| Registries YAML (`baseline-registry.yaml`, `drift-policy.yaml`, `evidence-registry.yaml`) | Presentes na raiz do template, formato genérico (não têm cliente/tenant associado) | **Sim, como esqueleto reutilizável**, mas precisam ganhar um "dono" real (repo Cliente/Plataforma) para deixar de ser apenas exemplo | arquivos citados acima |
| CMDB do template vs. CMDB real do produto | Existe uma **instância real em produção** deste mesmo padrão fora do repo-template (`venha-pra-nuvem-client-platform`, ver 2.2 e 2.3) | **Não é conflito** — é a confirmação de que o modelo funciona; falta decidir se o template continua modelo de referência/gerador ou vira motor central único | ver achado 2.2 |

**Conclusão da auditoria:** o modelo conceitual do template (advisory-first,
trilha de evidência, DSC versionado) continua válido e é reaproveitável, e a
**implementação concreta em `platform-governance/` está desconectada da
realidade operacional** — não há cliente rodando diretamente a partir deste
repositório — mas já existe uma **instância real em produção** do mesmo
padrão (`venha-pra-nuvem-client-platform`, achado corrigido da Round 2, ver
2.2). `[NEEDS CLARIFICATION]`: decidir se `platform-governance/` deve ser (a)
o **modelo de referência/gerador** a partir do qual instâncias por cliente
(como `venha-pra-nuvem-client-platform`) continuam sendo criadas, ou (b)
evoluído para um **motor central único** que várias instâncias de managed
services passam a consumir diretamente, sem repositório próprio por cliente.

### 2.2 Achado corrigido: `venha-pra-nuvem-client-platform` é a instância real deste template, não um concorrente

**Correção pós-Round 2 (validada diretamente pelo usuário)**: a leitura inicial
deste research tratou `venha-pra-nuvem/venha-pra-nuvem-client-platform` como um
segundo esforço de CMDB divergente/concorrente. O usuário esclareceu o modelo
correto: **`venha-pra-nuvem-client-platform` é a aplicação real deste próprio
template, implantada para o cliente "Venha Pra Nuvem"** dentro do modelo de
**Managed Services**. **GSN Premium não é um cliente separado usado como
exemplo — é um serviço/produto da própria Venha Pra Nuvem**, ou seja, é a
oferta comercial de managed services (gestão gerenciada de CMDB/baseline/IaC)
que a Venha Pra Nuvem vende, e é justamente esse serviço que consome o "Repo
Plataforma" deste template. Não é uma arquitetura concorrente — é um
**consumidor/instância** do padrão deste template, com stack própria (FastAPI
+ React), que é esperado e correto diferir tecnicamente de repositório para
repositório de cliente.

Estrutura observada permanece útil como evidência de como o padrão se
materializa na prática:

```
cmdb/  cmdb_engine/  platform-api/  platform_api/  portal-web/
reconciliation-engine/  reports/  schemas/  scripts/  specs/  tests/
```

com `specs/001-platform-governance-cmdb` e `specs/002-cmdb-portal-auditoria`,
e um "Portal CMDB Web" com backend FastAPI (Python) + frontend React/TS,
autenticação JWT/Entra ID, dashboard, busca de recursos, view de baseline e
exportação de auditoria — **este é o tipo de artefato que o "Repo Plataforma"
deste template deve produzir por cliente de managed services**, não um
concorrente a ele.

Duas linhas de negócio distintas ficam confirmadas nesta correção:

| Linha de negócio | Modelo | Exemplo de cliente | Repositório(s) |
|---|---|---|---|
| **SaaS (produto)** | Nuvem 365 — multi-tenant, potencialmente com mais clientes que a linha de managed services | Clientes finais do Nuvem 365 (não nomeados aqui) | `nuvem365-nimbuscode-spec` + satélites |
| **Managed Services (gestão gerenciada)** | Este template ("Repo Plataforma") — CMDB/baseline/IaC/DSC por cliente gerenciado | GSN Premium — serviço/produto de managed services da própria Venha Pra Nuvem; `venha-pra-nuvem-client-platform` é a instância real desse serviço | `venha-pra-nuvem-client-platform` (instância real) + este template (modelo de referência) |

`[NEEDS CLARIFICATION]` remanescente (não bloqueante, mas relevante para
`/nc-assess-define`): este template deve (a) continuar como **modelo de
referência/gerador** a partir do qual instâncias como
`venha-pra-nuvem-client-platform` são criadas por cliente, ou (b) evoluir para
um **motor central único** que atende múltiplos clientes de managed services
sem precisar de um repositório dedicado por cliente? A resposta molda
diretamente o desenho do "Repo Cliente/Plataforma" na definição do problema.

### 2.3 Nuvem365-nimbuscode-spec como contexto de FinOps — confirmado com evidência direta

Localizado como `venha-pra-nuvem/nuvem365-nimbuscode-spec` (GHE, privado,
"Projeto com a especificação do sistema Nuvem 365"). O `README.md` do
repositório confirma que ele é o **repositório central de specs** de um
produto multi-repo chamado **Nuvem 365**, com um bounded context por
repositório satélite (`docs/bounded-contexts.yaml`):

| Bounded context | Repositório | Stack |
|---|---|---|
| portal-frontend | `nuvem365-portal-frontend` | React/TS/Vite |
| portal-backend | `nuvem365-portal-back` | Java/Spring Boot |
| billing | `nuvem365-portal-back` (mesmo repo do backend) | Java/Spring Boot + React |
| partner-microsoft-api | `nuvem365-portal-back-partner-microsoft-api` | .NET/C# |
| itsm / itsm-ia / itsm-alert / itsm-alerta-integracrm | 4 repos distintos | .NET/C#, Python |
| ia-generativa | `nuvem365-portal-back-iagenerativa` | Python |
| portal-jobs | `nuvem365-portal-jobs` | Python/PowerShell/SQL |
| portal-mcp | `nuvem365-mcp` | Python/PowerShell/SQL |
| portal-powerbi | `nuvem365-portal-powerbi` | — |
| firewall-feed | `nuvem365-portal-back-firewall-feed` | .NET/C# |

O conteúdo de `specs/` confirma que Nuvem 365 **é de fato o produto FinOps
voltado a clientes** citado pelo usuário: as specs incluem `001-relatorio-rentabilidade`
(profitability), `023-oracle-billing-config` e `002-importa-processamento-interface`
(importação/processamento de billing multi-cloud AWS/Azure/OCI),
`023-fix-budget-alert-incident-link` (budget alerts), `029-fix-price-licenciamento`
(pricing/licenciamento) e `030-mcp-tool-privada-profitability`. O bounded context
`billing` no `bounded-contexts.yaml` descreve explicitamente: *"Gestão de
faturamento multi-cloud: importação, processamento e visualização de custos de
AWS, Azure e Oracle Cloud"* (`autonomous_ok: false` — dados financeiros exigem
revisão humana).

Achado adicional relevante, mas de **domínio separado**: `specs/005-cmdb-gcp` é
uma implementação de CMDB **dentro do próprio produto SaaS Nuvem 365**
(GCP Organization → Folders → Projects → Resources, S4, escalado por exigir
acesso de leitura em nível de Organization no ambiente do cliente final do
Nuvem 365). **Correção pós-Round 2**: este CMDB não concorre com o CMDB de
managed services deste template — são **públicos diferentes e propósitos
diferentes**. O CMDB do template (e sua instância real,
`venha-pra-nuvem-client-platform`) serve à operação interna de managed
services (governança de infraestrutura de clientes gerenciados, ex.: GSN
Premium). O `005-cmdb-gcp` do Nuvem 365 é uma **feature do produto SaaS**,
para inventariar recursos dos clientes finais que assinam o Nuvem 365 —
potencialmente uma base de clientes maior e com objetivo comercial distinto
(billing/FinOps do próprio produto, não gestão operacional de infraestrutura
pela MSP). Uma eventual unificação de modelos de dados de CMDB entre os dois
mundos é mencionada pelo usuário como possibilidade futura, não como
requisito desta rodada. `[ASSUMPTION]`: por ora, tratar como dois domínios
independentes, sem dependência mútua.

**Confirmação**: "Nuvem365-nimbuscode-spec" já segue o padrão multi-repo
"Repo Central de Specs + N repositórios satélite de código" que este próprio
template recomenda para bounded contexts (`docs/bounded-contexts.yaml` deste
template usa a mesma convenção). Isso é prior art direta de que o padrão
proposto pelo usuário é viável operacionalmente — a organização já opera dessa
forma para pelo menos um produto.

### 2.4 "Repo First Company" — não é um termo institucional prévio, mas há prior art direto na organização

Busca em `docs/*.md` deste template e nos artefatos de assessment não encontrou
o termo "Repo First Company" como padrão nomeado preexistente — trata-se de uma
formulação nova do usuário nesta sessão. `[NEEDS CLARIFICATION]` permanece
aberto quanto ao nome, mas a **prática que o termo descreve já existe e está em
produção** na organização:

- `venha-pra-nuvem/vpn-nibo-connect` (aplicação) e
  `venha-pra-nuvem/vpn-nibo-connect-iac` (Terraform + workflows de deploy) são
  dois repositórios separados para o mesmo cliente/produto — a IaC nunca fica
  junto do código de aplicação. Existe ainda `vpn-nibo-connect-infra`, um
  terceiro repositório correlato (nome distinto de `-iac`, não investigado em
  detalhe nesta rodada — `[NEEDS CLARIFICATION]`: são papéis diferentes ou
  duplicidade de nomenclatura?).
- O `README.md` de `vpn-nibo-connect-iac` documenta o modelo operacional já
  validado: Terraform plan somente leitura em PR, apply manual protegido por
  ambiente `homologacao` com revisores obrigatórios, autenticação via Workload
  Identity Federation (nenhuma service-account key armazenada), conta de
  serviço de infraestrutura separada da conta de build/deploy de aplicação, e
  estado do Terraform em bucket dedicado (`GCP_TF_STATE_BUCKET`).
- Esse modelo é evidência forte e concreta — não hipotética — de que "IaC e
  estado sempre em um Repo Cliente/Plataforma dedicado, nunca junto do
  produto" já é uma prática validada na organização para pelo menos um
  cliente/produto (`vpn-nibo-connect`).

**Modelo de relação corrigido (Round 2): Repo Plataforma registra/linka Repo(s)
IaC dedicados — não os substitui.** Conforme esclarecido pelo usuário, o
`venha-pra-nuvem-client-platform` (a instância real do Repo Plataforma para o
cliente Venha Pra Nuvem/GSN Premium) não compete com `vpn-nibo-connect-iac`;
ele deve **inventariar e apontar para** repositórios de IaC dedicados como
esse, quando eles existirem. Ou seja, o CMDB do Repo Plataforma registra uma
entrada do tipo "App NIBO → repo de código `vpn-nibo-connect` + repo de IaC
`vpn-nibo-connect-iac`", sem duplicar o conteúdo Terraform em si. Um ponto
igualmente importante levantado pelo usuário: **nem todo ativo de cliente
ganha um repositório de IaC dedicado** — ativos legados, de menor porte ou
sem justificativa de isolamento próprio continuarão existindo **apenas como
entrada de inventário dentro do próprio Repo Plataforma** (sem Terraform
próprio versionado à parte, e possivelmente com config/estado gerenciado
diretamente dentro do Repo Plataforma). Isso implica que o modelo de dados do
CMDB precisa suportar dois modos de vínculo por ativo: (a) referência a um
repo de IaC externo dedicado, ou (b) inventário + IaC inline dentro do
próprio Repo Plataforma — e o critério de quando usar cada um ainda não está
definido (`[NEEDS CLARIFICATION]`, ver 2.6).
  O que falta é (a) generalizar esse
  padrão de repo-dedicado para Nuvem365 e para os demais clientes cobertos
  pelo assessment `cliente-plataforma-operacional`, e (b) definir o critério
  de decisão "repo de IaC dedicado" vs. "apenas inventário no Repo
  Plataforma" por ativo/cliente.
- Busca por `terraform` via GitHub code search na organização
  (`search/code?q=terraform+org:venha-pra-nuvem`) retornou apenas 8
  repositórios com referência ao termo, incluindo este template,
  `vpn-nibo-connect-iac`/`-infra`, `venha-pra-nuvem-client-platform` e
  repositórios de outros clientes (`nibo-data-hub`, `IOX-CROWDFUNDINGPAAS`,
  `vulcabras-aidesignstudio`). **Nenhum repositório satélite do Nuvem 365**
  (`nuvem365-portal-back`, `nuvem365-portal-frontend`, `nuvem365-portal-jobs`,
  `nuvem365-mcp`) apareceu nessa busca nem tem pasta `terraform/`, `infra/`,
  `iac/` ou `bicep/` no root — **confirma diretamente a lacuna relatada pelo
  usuário**: o produto FinOps para clientes (Nuvem 365) hoje não tem nenhuma
  infraestrutura própria versionada como código, em nenhum dos seus
  repositórios satélite.
- O próprio `docs/bounded-contexts.yaml` do repositório `nuvem365-nimbuscode-spec`
  já documenta a convenção de nome `infra` para "infraestrutura
  (Terraform/IaC)" na seção de convenções — mas **não existe nenhuma entrada
  de bounded context desse tipo na lista atual**. Ou seja, a própria estrutura
  de bounded contexts do Nuvem 365 já previa esse repositório e ele nunca foi
  criado.

### 2.5 Atualização da síntese de hipóteses (Round 2)

| Hipótese | Status da evidência (Round 2) |
|---|---|
| O modelo conceitual advisory-first do template continua válido | **Confirmado como direção correta**, e agora sabemos que já existe uma instância real em produção (`venha-pra-nuvem-client-platform`) validando o modelo — falta apenas religar as duas pontas (template = modelo de referência, instância = operação real) |
| Existe demanda real por CMDB/baseline de plataforma | **Confirmado além da dúvida** — já existe uma instância real em produção do modelo deste template (`venha-pra-nuvem-client-platform`, para o serviço GSN Premium/managed services), o que é evidência direta de demanda genuína e validada, não apenas teórica |
| "Repo First Company" (IaC/estado separado do código em repo dedicado por cliente/plataforma) é operacionalmente viável | **Confirmado com prior art em produção** (`vpn-nibo-connect` + `vpn-nibo-connect-iac`) — e o Repo Plataforma deve registrar/linkar esses repos dedicados, não substituí-los |
| Nuvem 365 é o produto FinOps para clientes citado no intake | **Confirmado** (specs de billing multi-cloud, rentabilidade, budget alerts, licenciamento) — é um produto SaaS de negócio distinto do managed services, com seu próprio CMDB de escopo separado (`005-cmdb-gcp`) |
| Nuvem 365 já tem alguma IaC/infraestrutura própria versionada | **Refutado** — busca de código e inspeção de root de todos os repositórios satélite não encontrou nenhuma pasta/arquivo de IaC |
| "Repo First Company" é um termo institucional já definido | **Refutado** — não encontrado em nenhuma documentação; é uma formulação nova do usuário que precisa virar ADR/pattern nomeado se for adotada |

### 2.6 Lacunas que seguem abertas após a Round 2

1. **Modelo de referência vs. motor central**: este template deve continuar
   sendo o *modelo de referência* a partir do qual cada cliente managed
   services (ex.: GSN Premium) gera sua própria instância (como
   `venha-pra-nuvem-client-platform`), ou deve evoluir para um **motor
   central único** que atenda múltiplos clientes de managed services sem
   exigir um repo de instância por cliente? Essa decisão de arquitetura ainda
   não está tomada e é pré-requisito para desenhar a solução (impacta
   diretamente onde e como o CMDB, baselines e schemas serão versionados).
2. **Critério de "repo de IaC dedicado" vs. "apenas inventário no Repo
   Plataforma"**: falta definir regras objetivas (porte do cliente, criticidade
   do ativo, requisito de isolamento de acesso, etc.) para decidir quando um
   ativo/cliente ganha um repositório de IaC próprio (modelo
   `vpn-nibo-connect-iac`) versus quando ele só existe como entrada de
   inventário + IaC inline dentro do Repo Plataforma central.
3. Qual é a relação formal entre `nuvem365-nimbuscode-spec` (repo central de
   specs do produto) e o futuro "Repo Cliente/Plataforma" de IaC — é um novo
   bounded context (`infra`) dentro do mesmo produto Nuvem 365, ou um
   repositório à parte, por cliente final do Nuvem 365 (multi-tenant)? Esta
   pergunta é de **baixa prioridade/não urgente** por ora — o usuário
   confirmou que a unificação com o CMDB do produto SaaS Nuvem 365 pode ficar
   para um momento futuro, fora do escopo desta rodada.
4. `vpn-nibo-connect-infra` vs. `vpn-nibo-connect-iac`: propósitos distintos
   ou nomenclatura duplicada por engano? Relevante para não repetir o erro ao
   nomear o novo repositório de Nuvem 365.
5. Nenhuma entrevista ou dado quantitativo novo foi obtido nesta rodada (a
   Round 2 usou apenas evidência documental/estrutural do GitHub, não dados de
   clientes/uso) — os gaps de volume, ROI e critério de go/no-go da Round 1
   continuam abertos.

## Próximo handoff (Round 2)

Recomenda-se `/nc-assess-define slug=cliente-plataforma-operacional`, com duas
condições adicionais em relação à Round 1 (corrigidas nesta rodada):

1. A definição do problema **precisa decidir explicitamente** se este template
   permanece como modelo de referência (gerando instâncias por cliente, como
   `venha-pra-nuvem-client-platform`) ou evolui para um motor central único
   (2.6.1) — essa decisão molda todo o desenho de solução subsequente.
2. Deve especificar o **modelo de vínculo Repo Plataforma ↔ Repo IaC
   dedicado** (registro/link, não substituição — ver 2.4) e o critério de
   quando um ativo ganha repo próprio vs. fica só inventariado centralmente
   (2.6.2).

Também deve registrar `nuvem365-nimbuscode-spec`/`billing` como o contexto de
FinOps formal (produto SaaS, domínio de negócio separado do managed
services) e usar `vpn-nibo-connect` + `vpn-nibo-connect-iac` como o
precedente de referência (não hipotético) para o padrão "Repo First Company".
A unificação do CMDB do Nuvem 365 (`005-cmdb-gcp`) com o modelo de managed
services **fica explicitamente fora de escopo** desta rodada, por decisão do
usuário. Um novo `/nc-assess-decide` (ou `/speckit-assess-decide`) será
necessário depois do `define` atualizado para emitir um novo veredito.
