# Decision: Operação de cliente e plataforma

- **Slug**: cliente-plataforma-operacional
- **Decided**: 2026-09-21T15:43:24-03:00
- **Verdict**: needs-clarification
- **Artifacts reviewed**: intake.md | research.md | problem.md | concept.md

## Scorecard

| Criterion | Rating | Justification |
|-----------|--------|---------------|
| Problem validity | adequate | A empresa relata uma dor operacional concreta na gestão de Terraform, IaC, DSC, Segurança e Infraestrutura fora dos projetos de software; porém a frequência, o custo e a extensão do problema ainda não foram medidos. |
| Evidence strength | weak | As fontes externas sustentam a separação entre plataforma e workloads, e o template possui provas locais; não há ainda dados de clientes, entrevistas, tickets, incidentes, métricas de drift, ROI ou integração real com APIs cloud. |
| Value vs. inaction | adequate | Ownership ambíguo, evidências dispersas, drift e risco de mudanças incorretas são custos plausíveis da inação, mas o impacto financeiro e operacional específico da empresa permanece desconhecido. |
| Feasibility / appetite | adequate | O conceito híbrido tem um piloto de apetite medium e pode começar com um núcleo read-only/advisory; a viabilidade produtiva, multi-tenant e de isolamento ainda precisa ser comprovada. |
| Strategic fit | adequate | A iniciativa se alinha ao preset Client/Plataforma, aos contratos de governança existentes e ao posicionamento de Managed Services; a constituição estratégica e o modelo comercial da empresa não foram formalmente confirmados. |
| Risk posture | weak | Os riscos principais foram identificados, mas segregação de clientes, secrets, evidências, contratos, aprovações, residência de dados e execução em ambientes reais ainda não têm critérios validados. |

## Verdict & Rationale

**Needs Clarification.** A ideia é plausível e o problema merece investigação,
mas não atende ainda ao requisito de evidência mínima para um veredito
**Go**. O research é majoritariamente estrutural e externo, enquanto as
decisões dependem de fatos internos da operação: população de clientes,
topologia de isolamento, baseline de esforço, demanda contratual, papéis de
aprovação e critérios de valor. O conceito recomendado — Option B, modelo
híbrido de plataforma gerenciada — é coerente e tem apetite razoável, mas não
deve avançar para especificação formal enquanto essas incertezas bloqueadoras
não forem reduzidas.

## If needs-clarification

### Blocking questions

- [NEEDS CLARIFICATION: Qual é a população do piloto e qual problema observado
  será medido em cada cliente: quantidade de repositórios, contas,
  subscriptions, ambientes, artefatos, mudanças e operadores?]
- [NEEDS CLARIFICATION: Qual é a linha de base atual para tempo de localização,
  revisão, auditoria, tratamento de drift, retrabalho, incidentes e custo por
  cliente?]
- [NEEDS CLARIFICATION: Qual unidade precisa de isolamento contratual e
  técnico: cliente, tenant, subscription/account, ambiente ou combinação?]
- [NEEDS CLARIFICATION: Quem pode ler, revisar, aprovar, executar e auditar
  artefatos e mudanças, incluindo a participação do cliente final?]
- [NEEDS CLARIFICATION: Quais artefatos pertencem ao domínio Client/Plataforma
  e quais permanecem nos repositórios de software?]
- [NEEDS CLARIFICATION: Quais requisitos de LGPD, residência, retenção,
  criptografia e segregação de secrets são obrigatórios por cliente?]
- [NEEDS CLARIFICATION: O primeiro ciclo será estritamente advisory/read-only
  ou existe necessidade contratual de delivery controlado em ambientes reais?]
- [NEEDS CLARIFICATION: Quais frameworks de segurança/compliance e integrações
  são prioritários para o serviço comercial inicial?]
- [NEEDS CLARIFICATION: Qual critério quantitativo determina que o piloto
  justifica avançar, ser redimensionado ou ser encerrado?]

### Revisit stage

- **Primary**: `research` — coletar dados internos, entrevistas com operadores,
  liderança, segurança e clientes, além de medir o baseline do piloto.
- **Secondary**: `define` — atualizar metas, anti-metas e métricas com os dados
  observados.
- **Shape**: revisar somente se os dados alterarem a hipótese do modelo
  híbrido, o apetite ou a necessidade de isolamento.

## Handoff status

Não há handoff para `/speckit-specify` neste momento. Depois que as questões
bloqueadoras forem respondidas e o baseline for medido, reexecutar:

```text
/nc-assess-research slug=cliente-plataforma-operacional
/nc-assess-define slug=cliente-plataforma-operacional
/nc-assess-shape slug=cliente-plataforma-operacional
/nc-assess-decide slug=cliente-plataforma-operacional
```

O objetivo do próximo gate é verificar se a força de evidência subiu para
`adequate` ou mais e se a recomendação continua sendo o modelo híbrido.
