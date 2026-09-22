# Problem Definition: Operação de cliente e plataforma

- **Slug**: cliente-plataforma-operacional
- **Created**: 2026-09-21T15:37:19-03:00
- **Updated (Round 2)**: 2026-09-22T08:15:00-03:00
- **Inputs used**: intake.md (Round 1 & Round 2) | research.md (Round 1 & Round 2)

## Problem Statement

A Venha Pra Nuvem opera duas linhas de negócio distintas que hoje demandam
estruturação formal de governança de infraestrutura e dados:
1. **Managed Services (GSN Premium)**: serviço gerenciado de infraestrutura,
   segurança, CMDB, baselines, schemas de bancos e DSC para clientes
   gerenciados. A operação necessita que todos os artefatos de infraestrutura,
   Terraform e estado residam em repositórios dedicados de plataforma/IaC
   (**princípio "Repo First Company"**), nunca misturados ao código-fonte das
   aplicações. Além disso, a operação precisa gerenciar de forma unificada tanto
   ativos que justificam um repositório de IaC dedicado (ex.:
   `vpn-nibo-connect-iac`) quanto ativos legados ou de menor porte que devem
   permanecer inventariados diretamente no "Repo Plataforma" central.
2. **SaaS FinOps (Nuvem 365)**: produto multi-tenant voltado a clientes finais
   (`nuvem365-nimbuscode-spec`), focado em visibilidade de custos, faturamento
   multi-cloud (AWS/Azure/OCI), rentabilidade e alertas orçamentários. O Nuvem
   365 hoje é o contexto formal de FinOps, mas não possui IaC própria
   versionada em seus repositórios satélite, e seu CMDB interno
   (`005-cmdb-gcp`) atende ao escopo do produto SaaS, sem integração direta
   imediata com o CMDB operacional da linha de Managed Services.

O problema central consiste em:
- Como estruturar o **Repo Cliente/Plataforma** para servir à operação de
  Managed Services (GSN Premium), decidindo se este template permanece como um
  **modelo de referência/gerador de instâncias por cliente** (como a instância
  real `venha-pra-nuvem-client-platform`) ou evolui para um **motor central
  único** multicliente;
- Como estabelecer um mecanismo claro de **registro e vinculação** de
  repositórios de IaC dedicados no CMDB, permitindo convivência fluida com
  ativos mantidos apenas em inventário central;
- Como conectar o contexto de FinOps (`nuvem365-nimbuscode-spec`/`billing`)
  como fonte de dados de custo e relatórios de clientes, mantendo os domínios
  de negócio e as responsabilidades de segurança claramente segregados.

## Affected Users & Stakeholders

### Usuários

- **Operadores de Cloud/Plataforma (Time GSN Premium / Managed Services)** —
  precisam localizar, inventariar, auditar e operar artefatos de infraestrutura,
  Terraform, baselines e DSC sem misturá-los com código de aplicação, operando
  sob o modelo "Repo First Company".
- **Engenharia de Segurança e Compliance da Venha Pra Nuvem** — precisam
  auditar configurações, baselines (ex.: M365, CIS, Landing Zones), políticas de
  drift e registros de evidência por cliente e ambiente, com rastreabilidade
  total e sem credenciais estáticas (usando WIF / identidades federadas).
- **Responsáveis por IaC e Terraform** — mantêm estados desejados, planos
  advisory, branches protegidas e pipelines de homologação/produção, vinculando
  repositórios de IaC dedicados ao CMDB central.
- **Desenvolvedores e Owners de Aplicações dos Clientes** — desenvolvem nos
  repositórios de software (ex.: `vpn-nibo-connect`) com a certeza de que a IaC,
  segredos e estado de nuvem são geridos isoladamente em repositório apropriado
  (ex.: `vpn-nibo-connect-iac`).
- **Usuários do Portal FinOps (Clientes Nuvem 365)** — consomem dashboards de
  custos, rentabilidade e faturamento multi-cloud gerados pelo produto Nuvem 365.
- **Auditores externos e internos** — necessitam de pacotes de evidência
  contextualizados por cliente, ambiente, período e controle (sem esforço
  manual de consolidação).

### Stakeholders

- **Liderança da Venha Pra Nuvem** — define estratégia comercial para a oferta
  GSN Premium e para o produto SaaS Nuvem 365, avaliando escalabilidade da
  operação e margem por cliente.
- **Service Delivery Managers (SDMs)** — respondem por SLAs, cumprimento de
  janelas, relatórios operacionais e governança de mudanças de clientes.
- **Product Owner do Nuvem 365** — lidera o roadmap de FinOps, rentabilidade e
  features do produto SaaS, incluindo o CMDB GCP para clientes do produto.
- **Clientes Contratantes de Managed Services** — demandam isolamento estrito de
  seus ambientes, previsibilidade de mudanças e conformidade regulatória (LGPD).

## Goals

Os resultados abaixo definem o valor de resolver o problema, sem prescrever
a implementação detalhada:

- **Isolamento "Repo First Company"**: Garantir que toda IaC e estado de
  clientes residam em repositórios segregados do código de aplicação, com
  esteiras de CI/CD protegidas (plans de leitura em PR, apply manual com
  aprovação em ambientes controlados).
- **Vínculo Unificado no CMDB**: Permitir que o "Repo Plataforma" registre e
  aponte para repositórios de IaC dedicados existentes (ex.:
  `vpn-nibo-connect-iac`), ao mesmo tempo em que fornece inventário central
  direto para ativos que não possuem repo de IaC dedicado.
- **Decisão Arquitetural do Modelo de Plataforma**: Definir com clareza o papel
  deste template — se atua como gerador/modelo de referência para instâncias por
  cliente (como `venha-pra-nuvem-client-platform`) ou como motor central
  multicliente.
- **Integração com Contexto FinOps**: Estabelecer a interface de contexto com o
  Nuvem 365 (`nuvem365-nimbuscode-spec`/`billing`) para enriquecer o inventário
  e a operação com métricas de custo e rentabilidade.
- **Padronização de Baselines e DSC**: Disponibilizar registros de baseline,
  políticas de drift advisory e coleta de evidências aplicáveis de forma
  consistente entre clientes gerenciados.
- **Auditoria e Rastreabilidade**: Reduzir significativamente o tempo de resposta
  a solicitações de auditoria e diagnóstico de drift entre estado declarado e
  estado real.

## Non-Goals

- **Não unificar nesta rodada o CMDB do produto SaaS Nuvem 365 (`005-cmdb-gcp`)
  com o CMDB de Managed Services**: são produtos e domínios de negócio com
  propósitos e bases de clientes distintos; qualquer convergência futura é
  tratada como evolução desacoplada.
- **Não exigir obrigatoriamente um repositório de IaC dedicado para 100% dos
  ativos**: ativos legados, menores ou puramente inventariados podem residir
  diretamente no inventário do Repo Plataforma sem forçar criação de repo
  exclusivo.
- **Não alterar o código de aplicação dos clientes**: o escopo se restringe à
  camada de infraestrutura, plataforma, governança e FinOps.
- **Não executar mudanças automáticas destrutivas em produção**: a operação
  mantém o princípio advisory-first e aprovação humana explícita antes de applies
  de infraestrutura crítica.
- **Não substituir ferramentas nativas de nuvem ou ITSM de mercado**: o modelo
  atua como orquestrador de governança e repositório de verdade, integrando-se
  às ferramentas existentes.

## Success Metrics

- **Separação de IaC ("Repo First")**: 100% dos novos projetos e clientes
  gerenciados com infraestrutura provisionada têm a IaC e o estado versionados
  fora do repositório de software (baseline atual no piloto NIBO: 100%; baseline
  geral: em mapeamento).
- **Cobertura de Inventário no CMDB**: 100% dos ativos gerenciados mapeados no
  Repo Plataforma, com identificação clara se possuem repo de IaC dedicado
  vinculado ou se são inventário central.
- **Rastreabilidade de Mudanças**: 100% das alterações de infraestrutura e
  baseline com evidência registrada (PR, approver, commit, WIF identity).
- **Tempo de Resposta a Auditorias**: Redução de pelo menos 50% no tempo
  necessário para extrair relatórios de conformidade e drift de um cliente
  gerenciado.
- **Segregação de Acessos e Estado**: Zero vazamento de credenciais ou estados
  de Terraform entre clientes ou entre ambientes de homologação/produção.

## Cost of Inaction

Manter o cenário atual acarreta:
1. Risco de proliferação de IaC desorganizada ou embutida em repositórios de
   código, quebrando o princípio "Repo First Company".
2. Ineficiência operacional no time GSN Premium, que precisará navegar em
   múltiplas convenções ad-hoc para operar clientes distintos.
3. Desconexão entre os dados de custo gerados no FinOps (Nuvem 365) e a
   governança operacional dos recursos geridos pela Venha Pra Nuvem.
4. Dificuldade em escalar a carteira de clientes de Managed Services sem
   aumentar linearmente o custo de headcount operacional.

## Open Questions

- [NEEDS CLARIFICATION: Qual deve ser o modelo operacional definitivo do Repo
  Plataforma: gerador/template de instâncias por cliente (como
  `venha-pra-nuvem-client-platform`) ou motor central único multicliente?]
- [NEEDS CLARIFICATION: Quais são os critérios objetivos para decidir quando um
  ativo/cliente exige um repositório de IaC dedicado (ex.: tamanho, criticidade,
  ambiente, exigência contratual) vs. quando permanece como inventário central?]
- [NEEDS CLARIFICATION: Qual é o padrão oficial de nomenclatura de repositórios
  de IaC para novos clientes (ex.: `vpn-<cliente>-iac` vs. `vpn-<cliente>-infra`)?]
- [NEEDS CLARIFICATION: Qual é o formato e protocolo de interface desejado entre
  o Repo Plataforma e o contexto de FinOps Nuvem 365 (export de relatórios,
  consumo de API/MCP, ou enriquecimento via schemas comuns)?]

## Handoff

A definição do problema está atualizada e alinhada com as evidências do Round 2
e os direcionamentos de negócio da Venha Pra Nuvem. Próximo passo recomendado:

```text
/nc-assess-shape slug=cliente-plataforma-operacional
```

