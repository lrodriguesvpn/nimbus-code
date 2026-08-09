<!--
  Este repositório (speckit-vpndev-standards) gera presets para outros projetos, mas
  também é, ele mesmo, um "projeto vivo" da VPN Dev — este é o primeiro artefato SDD
  dogfooded aqui, seguindo o próprio spec-template.md do preset vpndev-standards.
-->

# STATUS: APROVADO E IMPLEMENTADO (v1.5.0 do preset vpndev-standards)

> Aprovação humana recebida em conversa ("Pode seguir vamos usar suas
> sugestões") — o escopo descrito abaixo (seção "Escopo") foi implementado
> diretamente (sem passar por `/speckit-plan`/`/speckit-tasks` formais, dado
> que o próprio pedido de aprovação já autorizou a execução direta do escopo
> já detalhado aqui). Entregue como parte da v1.5.0 (MINOR) do preset
> `vpndev-standards`: novo princípio "referenciar por ponteiro" na
> constituição, artefato `templates/reuse-catalog.yaml` (instalado em
> `docs/reuse-catalog.yaml` pelo `bootstrap.sh`), campo "Padrão reutilizado
> encontrado?" no `plan-template.md`/`copilot-instructions.md`, e TL;DR no
> topo de `ai-code-quality-and-observability.md` (nova seção 9),
> `label-taxonomy-and-autonomous-dev.md`, `module-graphs.md` e
> `developer-guide.md`. Este arquivo permanece como registro histórico da
> spec original.

---

## VPN Dev — Cabeçalho Obrigatório da Spec

| Campo | Valor |
|---|---|
| **Feature slug** | `001-catalogo-conteudo-reutilizavel` |
| **Complexidade estimada** | S2 *(módulo/convenção completa: novo arquivo `docs/reuse-catalog.yaml`, ajuste em templates de preset e na constituição; sem integração entre serviços externos — pode revisar para S3 no `plan.md` se a automação de indexação exigir workflow próprio)* |
| **Bounded Context** | Governança do próprio bundle Spec Kit (meta — afeta como agentes consomem o bundle, não um sistema de produção da VPN Dev) |
| **PR de referência / Issue** | novo — nenhuma issue de rastreamento criada ainda (ver "Próximos passos" abaixo) |
| **Data alvo de entrega** | sem data — backlog, aguardando priorização manual |

> S0 = doc · S1 = função isolada · S2 = módulo · S3 = múltiplos módulos ·
> S4 = arquitetura, segurança, dados ou integração crítica

## VPN Dev — SLO Alvo desta Feature

Não aplicável — este é um artefato de convenção/documentação e templates, não um
serviço em produção com latência/disponibilidade mensuráveis.

## User Story

Como **agente de IA executando SDD com Spec Kit num projeto que usa o preset
`vpndev-standards`**, eu quero **encontrar rapidamente padrões, ADRs e features
anteriores reutilizáveis via um índice curto e machine-readable**, para que eu
**gaste menos tokens re-derivando soluções já resolvidas e re-lendo documentos
inteiros quando só uma seção é relevante para a complexidade da tarefa atual**.

## Contexto / Motivação

Discutido em conversa com o mantenedor: hoje cada feature nova em um projeto que
consome este bundle reconstrói contexto do zero (relendo `constitution.md`, ADRs
inteiros, docs de referência completos) mesmo quando uma feature anterior já
resolveu um problema equivalente (ex.: padrão de correlation-id, CRUD padrão,
outbox pattern). Isso aumenta o custo de tokens por tarefa sem necessidade,
especialmente em tarefas S0/S1 (30–40% do volume, conforme
[`ai-code-quality-and-observability.md`](/Users/lrodrigues/projects/speckit-vpndev-standards.worktrees/branch-perdido-verificacao/docs/ai-code-quality-and-observability.md#6-seleção-de-modelo-por-complexidade-s0s4),
seção 6) que não precisariam do contexto completo.

## Escopo (proposta a refinar no `/speckit-plan`, se aprovado)

1. **Princípio "referenciar por ponteiro, não por valor"** — adicionar como regra
   explícita no `constitution-template.md` do preset `vpndev-standards`: agentes
   devem citar ADRs/docs por link + seção, nunca reexplicar/duplicar o conteúdo
   dentro de `plan.md`/`spec.md`.
2. **Catálogo de reuso** — novo arquivo `docs/reuse-catalog.yaml` (ou dentro do
   preset, como template) indexando features/ADRs por tag/bounded-context/padrão
   técnico, com link para o artefato original. Alimentado manualmente no início;
   automação de preenchimento fica para uma iteração futura.
3. **TL;DR / resumo no topo de docs longos** — adicionar um resumo de 2–3 linhas
   no topo de `ai-code-quality-and-observability.md`, `platform-standards-and-legacy-infra.md`
   e docs equivalentes, para leitura rápida em tarefas S0/S1.
4. **Campo de reuso na estimativa de tokens** — estender a seção 6 de
   `ai-code-quality-and-observability.md` e a tabela de Classificação de
   Complexidade do `plan-template.md` com um campo "Padrão reutilizado
   encontrado? (S/N, qual)".

## Fora de Escopo (nesta fase)

- RAG/índice semântico via embeddings — considerado prematuro até o corpus de
  specs/ADRs crescer o suficiente para justificar a infraestrutura adicional.
- Automação de preenchimento do catálogo (ex.: workflow que atualiza
  `reuse-catalog.yaml` automaticamente ao fechar `/speckit-tasks`) — pode ser uma
  segunda fase, não faz parte do MVP.
- Qualquer mudança em código/scripts/workflows já existentes neste repositório —
  este spec não altera nada do que já está implementado (Priority field sync,
  labels, PMO project, etc.).

## Perguntas em Aberto (para o `/speckit-plan`, quando aprovado)

- O catálogo de reuso deve viver no bundle `vpndev-standards` (aplicado a todo
  projeto consumidor) ou ser uma extensão opcional separada, como
  `vpndev-backlog-sync`?
- O preenchimento do catálogo deve ser manual (curadoria humana periódica) ou
  parte do checklist de fechamento do `tasks.md` desde o início?
- Vale a pena já reservar um campo `reuse_tags` em `graph.yaml` agora, mesmo
  antes do catálogo existir, para não exigir migração retroativa depois?

## Métricas de Sucesso (a validar no `plan.md`)

- Redução mensurável na variância "estimativa vs. consumo real de tokens"
  (seção já existente em `ai-code-quality-and-observability.md`) para tarefas
  que citam um item do catálogo de reuso.
- % de specs novas que referenciam ao menos 1 entrada do catálogo, medido ao
  longo do tempo.

## Próximos Passos (requer aprovação humana)

~~1. Humano decide se esta ideia deve avançar — se sim, criar issue de
   rastreamento neste repositório com `priority:*` + `type:feature` e linkar
   aqui.
2. Só então rodar `/speckit-plan` a partir deste `spec.md` para detalhar
   arquitetura, gates e `graph.yaml`/`graph.md` (S2 exige ambos).
3. `/speckit-tasks` e implementação seguem o fluxo normal do bundle depois do
   plano aprovado.~~

**Atualização**: aprovado e implementado diretamente (ver banner de status no
topo). Escolhas feitas nas perguntas em aberto acima:
- Catálogo de reuso vive no bundle `vpndev-standards` (não como extensão
  separada) — é aplicável a todo projeto consumidor, não um caso especial.
- Preenchimento é **manual/curatorial** desde o início (não há automação de
  indexação nesta versão — ver "Fora de Escopo").
- Campo `reuse_tags` em `graph.yaml` **não** foi adicionado agora — o
  catálogo (`reuse-catalog.yaml`) já cobre o caso de uso sem exigir mudança no
  schema do grafo; pode ser revisitado se, na prática, a granularidade por
  feature (graph.yaml) se mostrar necessária além da granularidade por
  padrão/tag (reuse-catalog.yaml).
