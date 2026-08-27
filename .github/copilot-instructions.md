# Copilot Instructions — <project-name>

<!--
  Este arquivo é o ponto central de configuração do GitHub Copilot para este projeto.
  Gerado pelo preset nimbus-code-standards. Manter atualizado a cada mudança de arquitetura.
  Referenciado pelo preset via extensão agent-context.
-->

## Contexto do Projeto

- **Repositório:** `<org>/<repo>`
- **Stack principal:** `<linguagem/framework>`
- **Nimbus Code workflow:** `nimbus-code-full-cycle` (specify → plan → tasks → implement)
- **Plano ativo:** `specs/<feature-slug>/plan.md` (atualizar este link na feature em andamento)

---

## Modelo de Entrevista de Descoberta (antes do Specify)

> Antes de redigir qualquer `spec.md`, consulte
> `presets/nimbus-code-standards/templates/feature-artifacts/interview-template.md`
> (ou sua cópia em `.specify/presets/`) — o modelo padrão de entrevista de
> descoberta, com 4 blocos obrigatórios: **Negócio** (o quê e por quê, nunca o
> como técnico), **Infraestrutura**, **Segurança** e **LGPD**.

- O `/speckit-specify` verifica se o input recebido (descrição da feature ou
  transcript de entrevista já preenchido) cobre os 4 blocos. Bloco ausente vira
  candidato a `[NEEDS CLARIFICATION]` — nunca é preenchido com suposição
  silenciosa, especialmente Segurança e LGPD.
- Se o input já vier como uma entrevista preenchida (ex.: resumo de reunião),
  ele é salvo como `specs/<feature-slug>/interview.md` usando a estrutura do
  template, preservando as respostas dadas.
- Este modelo é usado hoje por humanos (BA/ADE) conduzindo a conversa
  manualmente. O roadmap de condução automatizada via Microsoft Teams pelo
  NIMBUS AGENT está registrado em
  `specs/018-nimbus-agent-intake/spec.md`.

---

## Isolamento de Sessão e Regras de Branch

Você está executando como agente numa **sessão de escopo fechado**. As seguintes
regras são não-negociáveis:

1. **Edite apenas os arquivos listados no prompt de início da sessão.** Se
   precisar alterar um arquivo fora dessa lista para concluir a tarefa, **pare**
   e informe o Dev — nunca edite silenciosamente fora do escopo.
2. **Não faça merge.** Ao finalizar, abra um PR para `develop` com o checklist
   da fase preenchido. O merge é decisão exclusiva do Dev após revisão.
   **Obrigatório no corpo do PR:** para cada issue implementada, inclua
   `Closes #<n>` (ou `Fixes #<n>`). Só mencionar `#<n>` em texto/tabela não
   fecha a issue automaticamente.
3. **1 branch por sessão.** Não crie branches adicionais além do declarado no
   início da sessão. Se a tarefa exigir mais do que o escopo permite, **pare e
   informe** — não subdivida por conta própria em novos branches.
4. **Não altere configurações de CI/CD, workflows ou arquivos de infraestrutura**
   a menos que estejam explicitamente listados no escopo da fase.
5. **Não apague testes existentes** que não sejam relacionados diretamente aos
   arquivos do escopo desta fase.
6. Se encontrar um bug fora do escopo durante a implementação, **abra uma Issue**
   em vez de corrigir inline — corrigir fora do escopo invalida o isolamento.

### Formato obrigatório de declaração no início de cada tarefa

```
Fase: {N} — {descrição}
Branch: feature/fase-{N}-{slug}
Arquivos em escopo: {lista}
Complexidade desta tarefa: S{N} — {justificativa breve}
Modelo selecionado: {modelo}
Bounded Context: {slug de docs/bounded-contexts.yaml — verificar antes de preencher}
Padrão reutilizado encontrado (docs/reuse-catalog.yaml)? Sim (tag: {tag}) / Não
Estimativa de tokens (input+output): ~{X}–{Y} mil tokens
```

---

## Regras Obrigatórias de Grafo

Todo trabalho neste repositório que cria ou altera módulos **deve**:

1. Criar ou atualizar `specs/<feature>/graph.yaml` refletindo todos os módulos envolvidos.
2. Criar ou atualizar `specs/<feature>/graph.md` com os diagramas Mermaid (por código e por business).
3. Para complexidade **S3 ou S4**: criar ou atualizar `specs/<feature>/impact-map.md`.
4. Nenhum PR que altere arquivos em `src/`, `services/`, `infrastructure/` ou `modules/`
   pode ser mergeado sem atualizar o grafo correspondente.

Se você (agente) detectar que o grafo está ausente ou desatualizado ao iniciar uma tarefa,
**pare e atualize o grafo antes de continuar** — não implemente código sem grafo válido.

---

## Escala de Complexidade e Seleção de Modelo (S0–S4)

Antes de iniciar qualquer tarefa, classifique a complexidade e use o modelo correspondente.
**Nunca use modelo mais forte do que o necessário** — isso reduz custo sem perder qualidade.

| Nível | Descrição | Exemplos | Modelo |
|---|---|---|---|
| **S0** | Documentação, comentários, textos | README, ADL, docstring | Auto / modo rápido |
| **S1** | Função isolada, sem dependência externa | Util, helper, validação simples | Auto / modo rápido |
| **S2** | Módulo completo, testes, refatoração | CRUD de um serviço, módulo novo | Auto |
| **S3** | Múltiplos módulos, integração entre serviços | Feature que cruza 2+ serviços | Modelo de reasoning (ex.: GPT-5.4 / Claude Sonnet) |
| **S4** | Arquitetura, segurança, dados sensíveis, integração crítica | Auth, schema de banco, API pública, pipeline de dados PII | Modelo mais forte (ex.: GPT-5.5 / Claude Opus) + **revisão humana obrigatória** |

### Como declarar a complexidade

No início de cada tarefa (ou ao receber um `/nimbus-code-implement`), declare:

```
Complexidade desta tarefa: S<N> — <justificativa breve>
Modelo selecionado: <modelo>
Padrão reutilizado encontrado no catálogo de reuso (docs/reuse-catalog.yaml)? <Sim (tag: <tag>) / Não>
Estimativa de tokens (input+output): ~<X>–<Y> mil tokens
```

A estimativa de tokens vai para a tabela de Classificação de Complexidade do
`plan.md` e é comparada com o consumo real no fechamento do `tasks.md` (ver
`docs/ai-code-quality-and-observability.md`, seção 6, para a metodologia de
estimativa e as limitações de medição real). O mapeamento nível→modelo acima é
a recomendação padrão do bundle — pode ser ajustado por projeto (nunca a
régua S0–S4 em si nem a exigência de revisão humana em S4); documente o ajuste
no `constitution.md` do projeto ou no ADL.

### Regras de escalonamento

- **S0 e S1**: use sempre o modelo mais rápido disponível (Auto ou modo inline). Não solicite reasoning. **Execute e abra PR diretamente.**
- **S2**: use Auto. Apresente a estrutura de módulos proposta antes de implementar — aguarde confirmação do Dev. Se encontrar ambiguidade arquitetural, escale para S3 e documente no ADL.
- **S3**: ative reasoning. Apresente design detalhado (módulos, dependências, estratégia de release) e aguarde aprovação explícita antes de escrever código. Documente no Architecture Decision Log do `plan.md`. Atualize `graph.yaml` e `graph.md` antes de implementar.
- **S4**: use o modelo mais forte disponível. **Entregue somente o plano** (`plan.md` completo + `impact-map.md`) — não escreva código sem aprovação humana explícita. **Requerer revisão humana no PR é obrigatório** (não opcional). Sinalizar no PR com label `complexity:S4`.
- **Escalonamento ativo**: se durante a execução de um nível menor você descobrir que a tarefa é na verdade S3 ou S4, **pare imediatamente**, reclassifique e informe o Dev — nunca continue silenciosamente num nível errado.

---

## Gates Obrigatórios (Nimbus Code Nimbus-Code)

Antes de `/nimbus-code-tasks`, todos os seguintes gates devem estar aprovados no `plan.md`:

- [ ] **Security & DevSecOps Gate** preenchido — inclui itens **Não-Negociáveis**
      (backup & DR, segredos, branch protegida, TLS, isolamento de ambiente,
      destroy de Terraform aprovado — sem exceção, ver seção 10/11 de
      `docs/ai-code-quality-and-observability.md`) e itens **Escapáveis via ADL**
      (firewall, SSO, IaC não-Terraform, observabilidade — aceitáveis fora do
      padrão só com justificativa explícita registrada no ADL)
- [ ] **Qualidade de Código, Testes e Observabilidade Gate** preenchido
- [ ] **Module Dependency Graph** (graph.yaml + graph.md) presente e atualizado
- [ ] **Impact Map** presente para S3/S4
- [ ] **Architecture Decision Log** com entradas para decisões relevantes e para
      todo item Escapável via ADL que não seguiu o padrão (com justificativa e
      aprovação registradas)

---

## Priorização e Labels (Desenvolvimento Autônomo)

Este projeto usa uma taxonomia de labels padrão do bundle Nimbus-Code para ordenar
o backlog e decidir o que pode ser trabalhado por agente sem supervisão
humana constante. Instalada via `scripts/setup-github-labels.sh`.

- **Ordem de prioridade**: `priority:P0-blocker` > `priority:P1-high` >
  `priority:P2-medium` > `priority:P3-low`. Ao escolher a próxima issue para
  trabalhar, sempre puxe a de maior prioridade disponível (que não esteja
  `status:blocked` ou `status:needs-triage`).
- **Antes de iniciar trabalho autônomo numa issue**, verifique:
  - Ela tem o label `agent:autonomous-ok`? Se não, trate como trabalho que
    precisa de acompanhamento humano mais próximo.
  - Ela **não** tem `agent:needs-human`? Esse label sempre bloqueia,
    independente de qualquer outro.
  - Ela **não** tem `complexity:S4`? S4 nunca é autônomo — exige revisão
    humana (ver escala acima).
  - Ela **não** tem `status:blocked`?
- Em repositórios com o workflow `agent-auto-assign.yml` instalado, essas
  checagens já acontecem automaticamente quando `agent:autonomous-ok` é
  aplicado — mas ao decidir manualmente qual issue puxar (ex.: ao planejar
  seu próprio trabalho), aplique a mesma lógica.
- Guia completo, incluindo como evitar gatilhos duplicados de auto-assign:
  `docs/label-taxonomy-and-autonomous-dev.md`.
- **Labels DORA** (`dora:deployment-frequency`/`dora:lead-time`/
  `dora:change-failure-rate`/`dora:mttr`): aplique na issue quando ela impacta
  diretamente um dos 4 indicadores DORA (deploy, lead time, taxa de falha de
  mudança, tempo de recuperação) — usado para correlacionar trabalho entregue
  com esses indicadores, não dispara automação nenhuma.

---

## Catálogo de Reuso (Reduzindo Custo de Tokens)

> **Passo obrigatório antes de qualquer `/nimbus-code-plan`**: consulte
> `docs/reuse-catalog.yaml` buscando por tags relacionadas ao domínio da
> feature. **Se encontrar match, declare-o na tabela de Classificação de
> Complexidade do `plan.md`** (campo "Padrão reutilizado encontrado?") e
> referencie por ponteiro — nunca re-derive ou re-explique a solução do zero.

- Antes de desenhar a solução de uma feature nova, **consulte
  `docs/reuse-catalog.yaml`** por tags relacionadas ao problema — se houver
  match, referencie a entrada por link no `plan.md` em vez de re-derivar a
  solução do zero.
- Nunca reexplique/copie o conteúdo de um ADR ou plano anterior dentro de um
  novo `spec.md`/`plan.md` — sempre **referencie por ponteiro** (link direto).
- Ao fechar uma feature que introduziu um padrão reaproveitável, adicione uma
  entrada ao catálogo (`tag`, `bounded_context`, `description`, `source`).
- Detalhamento completo:
  `docs/ai-code-quality-and-observability.md`, seção 9.

---

## Grafo de Contexto Multi-Repo (Brownfield)

> **Passo obrigatório antes de qualquer `/nimbus-code-plan` em projeto
> brownfield multirepo**: consulte `specs/<feature>/graph.yaml` do bounded
> context ativo (gerado automaticamente por `/speckit-specify` via
> `scripts/generate-context-graph.sh` quando o contexto está registrado em
> `docs/bounded-contexts.yaml` — ver
> specs/014-brownfield-multirepo-context-awareness/) **antes** de propor
> qualquer decisão arquitetural que afete mais de um repositório do contexto.
> Referencie o grafo no Architecture Decision Log do `plan.md` (seção "Grafo
> do Contexto").

- Se `docs/bounded-contexts.yaml` tiver o contexto mapeado mas o
  `graph.yaml` da feature ainda não existir, rode manualmente
  `scripts/generate-context-graph.sh <context-slug> --feature <feature-slug>`
  antes de continuar — não proponha arquitetura multi-repo sem o grafo.
- Se o contexto não estiver mapeado em `docs/bounded-contexts.yaml`, isso não
  bloqueia o fluxo — sinalize o aviso e prossiga sem o grafo (ver edge case
  de specs/014-brownfield-multirepo-context-awareness/spec.md).
- `scripts/harvest-patterns.sh` (varredura de padrões técnicos existentes via
  LLM, alimenta `docs/reuse-catalog.yaml`) é **exclusivamente on-demand,
  nunca automático nem em CI** — só é executado quando um humano o invoca
  explicitamente. Se o catálogo de reuso já tiver entradas originadas de
  harvest para o bounded context ativo, declare quais se aplicam na seção
  "Padrão reutilizado encontrado?" do `plan.md`, junto às entradas manuais.

## Harness Engineering (Aprendizado com Erros)

> **Passo obrigatório antes de qualquer `/nimbus-code-plan`**: consulte também
> `docs/harness/harness-catalog.yaml` buscando por `tags` e `bounded_context`
> relacionados ao domínio da feature — ANTES de redigir o `plan.md`.
>
> Use `./scripts/harness-search.sh <tag>` ou `grep` direto no arquivo.

- Se encontrar match: declare na seção **"Harness Gate"** do `plan.md`:
  - ID(s) do harness consultado(s)
  - Padrão de erro evitado
  - Como foi mitigado preventivamente nesta feature
- Se não encontrar match: declare explicitamente `"Nenhum padrão de erro relevante
  encontrado"` na seção "Harness Gate" — **nunca deixar em branco**.
- Se o catálogo estiver vazio: declare `"Catálogo vazio — nenhum padrão disponível"`.
- Se durante a implementação você (agente) perceber que está prestes a cometer um
  padrão catalogado no harness: **pare imediatamente** e informe o Dev antes de continuar.
- Ao fechar uma feature com retrabalho > 20% ou incidente: abrir Issue com label
  `harness:pending` e preencher entrada no `harness-catalog.yaml`.
- Detalhamento completo: `docs/harness/harness-guide.md`.

---

## Playbook de Sucesso (Aprendizado com Acertos)

> **Passo obrigatório antes de qualquer `/nimbus-code-plan`**: consulte também
> `docs/playbooks/success-catalog.yaml` buscando por `tags` e `bounded_context`
> relacionados ao domínio da feature — ANTES de redigir o `plan.md`.
>
> Use `grep -i "<tag>" docs/playbooks/success-catalog.yaml` para busca rápida.

- Se encontrar match: declare na seção **"Playbook de Sucesso Gate"** do `plan.md`:
  - ID(s) do playbook consultado(s)
  - O que funcionou
  - Como foi reaplicado nesta feature
- Se não encontrar match: declare explicitamente `"Nenhum padrão relevante encontrado"`
  na seção "Playbook de Sucesso Gate" — **nunca deixar em branco**.
- Se o catálogo estiver vazio: declare `"Catálogo vazio — nenhum padrão disponível"`.
- Ao fechar uma feature com padrão digno de repetição: o checklist de fechamento do
  `tasks.md` pergunta "o que deu certo?". Registrar em `docs/playbooks/success-catalog.yaml`
  (requer validação humana antes de catalogar).
- Detalhamento completo: `docs/playbooks/README.md`.

---

## Modelo Híbrido (Agente + Humano) e Controle de Custo

Toda tarefa em modo híbrido (agente gera a maior parte, humano revisa/ajusta)
deve ter as horas humanas lançadas no campo **"Horas Humanas"** do GitHub
Project (criado por `scripts/setup-github-project.sh`), mesmo que seja apenas
o tempo de revisão do PR — isso é o que permite calcular o custo real da
tarefa (`tokens do agente + horas humanas × custo/hora do time`), não apenas o
custo de tokens isolado. Ver `docs/ai-code-quality-and-observability.md`,
seção 8.

---

## Estratégia de Release e Feature Flags

- Toda feature S3/S4 deve chegar a produção atrás de feature flag, canary ou
  blue-green — nunca deploy `direct` sem justificativa no `plan.md`.
- Use OpenFeature SDK como abstração do provider de flags.
- Toda flag criada deve ter critério de remoção ou data de expiração no `plan.md`.
- Se encontrar uma flag sem critério de remoção ao revisar código, abrir Issue.

## Decisões de Arquitetura (ADRs)

- Quando uma tarefa exigir uma decisão com impacto duradouro, criar um ADR em
  `docs/adr/NNNN-slug.md` usando o template em
  `presets/nimbus-code-standards/templates/adr/NNNN-template.md`.
- Referenciar o ADR no Architecture Decision Log do `plan.md`.
- Ver guia completo em `docs/adr-guide.md`.

### Regra: nunca impor uma decisão de arquitetura silenciosamente

Ao planejar (`/nimbus-code-plan`), se você (agente) identificar que uma decisão de
arquitetura — sua ou do usuário — diverge do padrão institucional deste
preset, **não implemente a preferência silenciosamente em nenhuma direção**:

1. Documente a divergência no Architecture Decision Log do `plan.md`.
2. Explique objetivamente por que considera a decisão fora do padrão.
3. Verifique a tabela do Security & DevSecOps Gate: se o item está marcado
   **"Não-Negociável"**, não há exceção possível — pare e informe que o
   controle precisa existir de fato (ex.: backup, segredo em cofre, TLS).
   Se está marcado **"Escapável via ADL"**, o usuário pode manter a decisão
   fora do padrão, mas você deve pedir explicitamente a justificativa e
   registrar quem aprovou antes de considerar o gate satisfeito.
- Lista completa de itens Não-Negociáveis vs. Escapáveis para este preset:
  `docs/ai-code-quality-and-observability.md`, seção 11.

## Padrões de Código deste Projeto

<!-- Adicionar aqui os padrões específicos do projeto -->
- Convenções de nomenclatura: `<definir>`
- Framework de testes: `<definir>`
- Padrão de logs: JSON estruturado com `trace_id`, `span_id`, `service`, `level`
- Correlation-id: header `X-Correlation-Id` propagado em todas as chamadas entre serviços

---

## Rastreamento de Custo Real por Fase (spec-kit-cost)

**Extensão integrada**: [spec-kit-cost](https://github.com/Quratulain-bilal/spec-kit-cost) (instalada automaticamente via `bootstrap.sh`)

Todo feature no Nimbus Code tem um custo financeiro real (tokens × preço). Use os
comandos abaixo para rastrear, comparar e reportar custos:

### Workflow Padrão

Após cada fase (specify, plan, tasks, implement), registre o custo:

```bash
/speckit.cost.track phase=specify input_tokens=12345 output_tokens=3210
/speckit.cost.track phase=plan input_tokens=28400 output_tokens=9150
/speckit.cost.track phase=tasks input_tokens=15000 output_tokens=4800
/speckit.cost.track phase=implement input_tokens=180000 output_tokens=52000
```

### Comandos Disponíveis

| Comando | Propósito |
|---|---|
| `/speckit.cost.track phase=<fase> input_tokens=X output_tokens=Y` | Registrar custo da fase |
| `/speckit.cost.report` | Breakdown de custo por fase e total |
| `/speckit.cost.budget set scope=feature amount=20` | Definir orçamento por feature |
| `/speckit.cost.compare` | Comparar custo projetado entre LLMs (Claude, Copilot, Gemini, etc.) |
| `/speckit.cost.export format=csv source=summary out=./report.csv` | Exportar para BI/finance |

### Onde Encontrar Token Counts

- **Copilot Agent**: Resumo de fim de sessão mostra "Tokens: IN=X, OUT=Y"
- **Claude/ChatGPT**: Interface nativa mostra contador de tokens
- **Logs/Transcript**: Verifique a saída do agente ou transcrição

### Configuração de Preços

Se sua organização negocia taxas diferentes com Claude/OpenAI/Google, edite:

```
.specify/cost/cost-config.yml  →  pricing.rates
```

Mudanças se aplicam a todos os `/speckit.cost.track` futuros.

### Armazenamento

Dados de custo são locais e diff-friendly:

```
.specify/cost/
├── ledger.jsonl     # Append-only: um registro por /speckit.cost.track
└── summary.json     # Totalizados por feature/phase/integração
```

**Privacidade**: Armazena apenas contagens de tokens e metadados — sem prompts,
respostas ou segredos.

---

## Referências

- [Manual de Sessões Remotas e Branches](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/blob/main/docs/agent-session-manual.md)
- [Guia do Dev Nimbus-Code](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/blob/main/docs/developer-guide.md)
- [Seleção de Modelos por Complexidade](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/blob/main/docs/ai-code-quality-and-observability.md#6-seleção-de-modelo-por-complexidade-s0s4)
- [Grafos de Módulos — Guia](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/blob/main/docs/module-graphs.md)
- [Labels — Priorização e Desenvolvimento Autônomo](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/blob/main/docs/label-taxonomy-and-autonomous-dev.md)
- [Modelo Híbrido e Estimativa de Tokens](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/blob/main/docs/ai-code-quality-and-observability.md#8-modelo-híbrido-agentes-de-ia--humanos-codando-juntos)
- [Catálogo de Reuso](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/blob/main/docs/ai-code-quality-and-observability.md#9-catálogo-de-reuso--reduzindo-custo-de-tokens-com-conteúdo-já-existente)
- [Rastreamento de Custo — Cost Tracking Workflow](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/blob/main/docs/cost-tracking-workflow.md)
