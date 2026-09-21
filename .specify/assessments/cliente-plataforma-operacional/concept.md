# Concept: Operação separada de cliente e plataforma

- **Slug**: cliente-plataforma-operacional
- **Created**: 2026-09-21T15:41:40-03:00
- **Recommended option**: Option B — Modelo híbrido de plataforma gerenciada

## Contexto do conceito

O problema pede mais do que reorganizar pastas: a empresa precisa distinguir
responsabilidades de plataforma e software, preservar isolamento entre clientes,
reutilizar padrões e operar evidências, drift e mudanças de forma auditável. A
pesquisa apoia a separação conceitual entre fundação de plataforma e workloads,
mas não prova qual topologia organizacional ou ferramenta deve ser adotada.

As opções abaixo são deliberadamente conceituais. A validação deve começar com
um piloto pequeno e dados reais de operação, sem assumir integração produtiva
ou execução automática.

## Options

### Option A — Kit operacional mínimo por cliente

- **Sketch**: Para um pequeno grupo de clientes, estabelecer uma fronteira
  operacional explícita entre plataforma e software, com um catálogo comum de
  responsabilidades, inventário dos artefatos existentes, owners, ambientes,
  exceções e fluxo de aprovação. O cliente e a equipe passam a consultar um
  registro operacional único para saber o que pertence à plataforma, quem
  responde por cada item e qual evidência existe. O escopo inicial permanece
  read-only/advisory; a mudança principal é tornar o estado atual organizado,
  atribuível e auditável.
- **Appetite**: small (dias)
- **Trade-offs**: É a forma mais rápida de testar se a separação reduz tempo de
  localização, ambiguidade e esforço de auditoria. Tem baixo risco e não exige
  decidir a topologia definitiva. Em contrapartida, oferece pouco reuso
  automatizado, não resolve a escala de muitos clientes e pode continuar
  dependendo de trabalho manual.
- **Rabbit holes**: tentar catalogar todos os artefatos históricos; incluir
  todas as clouds e frameworks no primeiro piloto; transformar o catálogo em
  portal completo; executar remediação antes de medir o baseline.

### Option B — Modelo híbrido de plataforma gerenciada

- **Sketch**: Manter uma camada de padrões, constituição, baselines e regras
  reutilizáveis para a operação da empresa, enquanto cada cliente conserva um
  contexto operacional claramente separado para seus artefatos, owners,
  evidências, exceções, estado observado e mudanças. A equipe de Managed
  Services trabalha com uma experiência consistente entre clientes, mas cada
  cliente mantém fronteiras próprias de acesso, decisão e prestação de contas.
  O serviço começa com discovery, validação, drift e evidência; delivery só
  ocorre mediante o processo de aprovação acordado.
- **Appetite**: medium (semanas)
- **Trade-offs**: Equilibra reuso e isolamento, alinha-se às evidências de
  platform/application landing zones e permite medir custo por cliente,
  rastreabilidade e tempo de auditoria. Exige disciplina para versionar
  padrões, tratar exceções e não confundir padrão central com obrigação
  contratual do cliente. O risco principal é a complexidade de governar
  herança, customização e promoção de mudanças.
- **Rabbit holes**: construir um control plane multi-tenant antes de validar o
  processo; suportar toda combinação multicloud/Kubernetes/on-premises;
  integrar simultaneamente ITSM, SIEM, CSPM, FinOps e todos os CI/CD; oferecer
  self-service completo; automatizar apply e remediação em produção.

### Option C — Serviço integrado de control plane e operações

- **Sketch**: Oferecer uma experiência operacional abrangente para a empresa e
  seus clientes, com visão consolidada de postura, inventário, IaC, DSC,
  evidências, drift, solicitações, aprovações e execução controlada. O serviço
  seria tratado como uma capacidade central do portfólio de Managed Services,
  com níveis de acesso e relatórios adequados a operadores, segurança,
  gestores e clientes.
- **Appetite**: large (meses)
- **Trade-offs**: Maior potencial de escala, diferenciação comercial e
  visibilidade do serviço. Pode reduzir a fragmentação de ferramentas e tornar
  métricas de operação comparáveis entre clientes. Em troca, tem maior custo,
  risco de blast radius e exigência de segurança, integração, suporte,
  disponibilidade e governança. Ainda não há evidência de volume, orçamento ou
  demanda suficientes para justificar esse investimento.
- **Rabbit holes**: virar substituto de CNAPP, SIEM, ITSM, FinOps, secrets
  management ou Terraform platform; prometer remediação autônoma; criar
  multi-tenancy genérico para todos os cenários; definir preço e SLA antes de
  medir o custo atual; tratar fixtures do template como prova de prontidão
  produtiva.

## Recommendation

Recomenda-se **Option B — Modelo híbrido de plataforma gerenciada**, iniciado
por um piloto controlado com o núcleo de Option A.

Essa opção é a melhor combinação provisória entre os objetivos do problema:

- mantém a fronteira entre plataforma e software;
- permite reuso sem exigir cópia integral por cliente;
- preserva segregação, ownership e evidência por cliente;
- cria condições para medir localização, rastreabilidade, drift, auditoria e
  custo por cliente;
- aproveita as capacidades já comprovadas do template sem afirmar que elas já
  constituem uma operação produtiva;
- mantém a execução real de mudanças como atividade protegida e explícita,
  não como consequência automática do repositório.

A recomendação não é uma decisão final de arquitetura. Ela deve ser revogada ou
redimensionada se o piloto mostrar que o isolamento contratual exige separação
mais forte, que o reuso gera risco excessivo ou que a demanda não compensa o
esforço operacional.

## Validation sequence

Antes de ampliar o conceito, o piloto deve validar:

1. se operadores conseguem distinguir plataforma de software sem criar novos
   conflitos de ownership;
2. se cada artefato e mudança pode ser associado a cliente, ambiente, owner e
   aprovador;
3. se o tempo de localização e produção de evidências cai em relação ao
   baseline;
4. se não ocorre acesso cruzado entre clientes e ambientes;
5. se padrões reutilizáveis reduzem retrabalho sem apagar exceções legítimas;
6. se drift e mudanças passam a ter idade, severidade, decisão e resultado
   observáveis;
7. se clientes reconhecem valor na prestação de contas e nas evidências;
8. se o custo operacional por cliente começa a desacoplar-se do crescimento da
   carteira.

## Out of Scope (for the recommended option)

- Escolher definitivamente monorepo, repositório por cliente, produto SaaS ou
  outra topologia de implementação.
- Construir um portal ou control plane completo antes do piloto.
- Executar apply, destroy ou remediação autônoma em produção.
- Substituir CNAPP, SIEM, ITSM, FinOps, secrets manager, CI/CD ou plataforma
  especializada de Terraform.
- Suportar todas as clouds, ambientes, frameworks e modelos de cliente no
  primeiro ciclo.
- Incorporar os repositórios e o ciclo de desenvolvimento dos softwares dos
  clientes.
- Fixar preço, SLA, margem, framework regulatório ou contrato padrão sem
  validação com liderança e clientes.
- Definir arquitetura, APIs, modelos de dados, pipelines ou tarefas de
  implementação; esses itens pertencem ao ciclo de especificação posterior.

## Assumptions to Validate

- O principal comprador inicial é a própria empresa de Managed Services, com
  participação de pelo menos um cliente contratante no piloto.
- Há pelo menos dois clientes ou ambientes com padrões suficientemente
  semelhantes para que o reuso seja relevante, sem tornar o isolamento
  impraticável.
- O template atual pode ser usado como ponto de partida para um piloto
  advisory/read-only, mas as integrações reais precisarão ser comprovadas.
- A empresa consegue medir uma linha de base de tempo, drift, retrabalho,
  incidentes e atendimento de evidências.
- Clientes aceitarão uma fronteira formal de plataforma versus software e
  participarão de decisões de ownership e aprovação.
- Segregação de secrets, evidências, estados e acessos poderá ser validada com
  Segurança, LGPD e requisitos contratuais antes de qualquer operação
  produtiva.
- O valor comercial inclui redução de esforço, menor risco e melhor auditoria,
  mas disposição de pagar e margem ainda precisam ser confirmadas.
- A política inicial de delivery continuará exigindo revisão, aprovação,
  identidade apropriada e trilha de auditoria.

## Handoff

O próximo gate recomendado é:

```text
/nc-assess-decide slug=cliente-plataforma-operacional
```

O gate deve avaliar se a Option B merece avançar para especificação formal,
quais perguntas bloqueiam o avanço e quais critérios devem encerrar ou
redimensionar o piloto.
