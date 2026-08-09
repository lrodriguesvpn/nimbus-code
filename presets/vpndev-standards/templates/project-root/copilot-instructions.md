# Copilot Instructions — <project-name>

<!--
  Este arquivo é o ponto central de configuração do GitHub Copilot para este projeto.
  Gerado pelo preset vpndev-standards. Manter atualizado a cada mudança de arquitetura.
  Referenciado pelo preset via extensão agent-context.
-->

## Contexto do Projeto

- **Repositório:** `<org>/<repo>`
- **Stack principal:** `<linguagem/framework>`
- **Spec Kit workflow:** `vpndev-full-cycle` (specify → plan → tasks → implement)
- **Plano ativo:** `specs/<feature-slug>/plan.md` (atualizar este link na feature em andamento)

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

No início de cada tarefa (ou ao receber um `/speckit-implement`), declare:

```
Complexidade desta tarefa: S<N> — <justificativa breve>
Modelo selecionado: <modelo>
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

- **S0 e S1**: use sempre o modelo mais rápido disponível (Auto ou modo inline). Não solicite reasoning.
- **S2**: use Auto. Se encontrar ambiguidade arquitetural, escale para S3 e documente no ADL.
- **S3**: ative reasoning. Documente a decisão no Architecture Decision Log do `plan.md`.
  Atualize `graph.yaml` e `graph.md` antes de implementar.
- **S4**: use o modelo mais forte disponível. **Requerer revisão humana no PR é obrigatório**
  (não opcional). Criar `impact-map.md`. Sinalizar no PR com label `complexity:S4`.

---

## Gates Obrigatórios (Spec Kit VPN Dev)

Antes de `/speckit-tasks`, todos os seguintes gates devem estar aprovados no `plan.md`:

- [ ] **Security & DevSecOps Gate** preenchido
- [ ] **Qualidade de Código, Testes e Observabilidade Gate** preenchido
- [ ] **Module Dependency Graph** (graph.yaml + graph.md) presente e atualizado
- [ ] **Impact Map** presente para S3/S4
- [ ] **Architecture Decision Log** com entradas para decisões relevantes

---

## Priorização e Labels (Desenvolvimento Autônomo)

Este projeto usa uma taxonomia de labels padrão do bundle VPN Dev para ordenar
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
  `presets/vpndev-standards/templates/adr/NNNN-template.md`.
- Referenciar o ADR no Architecture Decision Log do `plan.md`.
- Ver guia completo em `docs/adr-guide.md`.

## Padrões de Código deste Projeto

<!-- Adicionar aqui os padrões específicos do projeto -->
- Convenções de nomenclatura: `<definir>`
- Framework de testes: `<definir>`
- Padrão de logs: JSON estruturado com `trace_id`, `span_id`, `service`, `level`
- Correlation-id: header `X-Correlation-Id` propagado em todas as chamadas entre serviços

---

## Referências

- [Guia do Dev VPN Dev](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/speckit-vpndev-standards/blob/main/docs/developer-guide.md)
- [Seleção de Modelos por Complexidade](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/speckit-vpndev-standards/blob/main/docs/ai-code-quality-and-observability.md#6-seleção-de-modelo-por-complexidade-s0s4)
- [Grafos de Módulos — Guia](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/speckit-vpndev-standards/blob/main/docs/module-graphs.md)
- [Labels — Priorização e Desenvolvimento Autônomo](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/speckit-vpndev-standards/blob/main/docs/label-taxonomy-and-autonomous-dev.md)
- [Modelo Híbrido e Estimativa de Tokens](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/speckit-vpndev-standards/blob/main/docs/ai-code-quality-and-observability.md#8-modelo-híbrido-agentes-de-ia--humanos-codando-juntos)
