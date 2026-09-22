# Problem Definition — Agente de Prototipação de Telas

## Identificação

| Campo | Valor |
|---|---|
| **Assessment** | `agente-prototipacao-telas` |
| **Fase** | Problem Definition |
| **Data** | 2026-09-21 |
| **Insumos** | [`intake.md`](./intake.md), [`research.md`](./research.md) |
| **Status** | Problema definido — pronto para `/nc-assess-shape` |

## Declaração do problema

> Equipes que usam o Nimbus Code precisam tornar concreta e validável uma
> decisão de experiência de interface **antes** de ela virar código, mas hoje
> não existe uma capacidade governada, reutilizável e rastreável para isso —
> a exploração visual acontece de forma ad hoc (fora do processo), tarde
> demais (só no fluxo de implementação) ou não acontece, o que gera
> retrabalho, ambiguidade de comunicação entre negócio/design/engenharia e
> perda de rastreabilidade entre a intenção de experiência e os requisitos
> formais em `spec.md`.

Isso importa agora porque:

- o Nimbus Code já formalizou dois fluxos de entrada (Ideação/Assessment e
  Spec Formal), mas nenhum dos dois possui hoje uma etapa explícita de
  prototipação visual antes da especificação
  (**Fonte:** [intake.md](./intake.md), seção "Encaixe nos dois fluxos");
- a skill `nc-designer` já resolve parte do julgamento de UX/acessibilidade,
  mas atua **depois** que já existe uma superfície para revisar — não cobre a
  fase de gerar e comparar alternativas ainda incertas
  (**Fonte:** [research.md](./research.md), Lente 2);
- decisões tardias de interface tendem a gerar retrabalho, mas o Nimbus Code
  ainda não mede esse custo internamente
  (**[ASSUMPTION]**, registrado em `research.md`, Lente 3).

## Usuários e stakeholders

### Personas que sofrem o problema hoje

| Persona | Dor específica |
|---|---|
| **Product Owner / Analista de negócio** | Não tem como validar visualmente um requisito antes de ele virar `spec.md`, dependendo de descrição textual sujeita a interpretação. |
| **Designer / responsável por UX-UI** | É acionado tarde, ou não é acionado, quando a interface já está sendo implementada, perdendo espaço para explorar alternativas. |
| **Desenvolvedor / Tech Lead** | Recebe requisitos de interface ambíguos e só descobre inconsistências de fluxo durante a implementação, gerando retrabalho. |
| **Stakeholder / patrocinador** | Precisa aprovar uma direção de experiência sem ter um artefato visual concreto para decidir, aumentando o risco de aprovar algo que não reflete a expectativa real. |

### Tomadores de decisão

- Quem aprova o avanço de uma ideia em `/nc-assess-decide` (hoje, decisão
  humana apoiada pelo esquadrão Nimbus Code);
- Quem aprova o protótipo como pronto para virar requisito formal em
  `spec.md` (ainda **[NEEDS CLARIFICATION]** — não definido se é o PO, o
  designer, o patrocinador ou um comitê).

**[NEEDS CLARIFICATION]** Não há hoje papéis nomeados/RACI para aprovação de
protótipo, distinto do RACI já existente para aprovação de `spec.md`
(Governance Gate).

## Metas e anti-metas

### Metas (o que define sucesso)

1. Permitir que uma ideia (Fluxo A) ou uma feature já aprovada (Fluxo B)
   produza uma representação visual/navegável da experiência **antes** de
   qualquer código de produção ser escrito.
2. Tornar essa representação um artefato rastreável — versionado junto do
   assessment ou da spec, referenciável em `problem.md`/`concept.md`
   (Fluxo A) ou em `spec.md` (Fluxo B).
3. Reutilizar `nc-designer` como guardrail de qualidade visual, acessibilidade
   e prevenção de padrões genéricos, em vez de duplicar essas regras em uma
   nova capacidade.
4. Manter a aprovação do protótipo como decisão humana explícita, nunca
   automática.
5. Reduzir a ambiguidade de comunicação entre negócio, design e engenharia
   antes da fase de implementação.

### Anti-metas (fora de escopo desta ideia)

1. **Não é objetivo** gerar código de produção diretamente do protótipo —
   protótipo não deve ser confundido com implementação (ver Opção D descartada
   em `research.md`).
2. **Não é objetivo** substituir `/nc-assess-*`, `/nc-intake` ou `/nc-spec` —
   a prototipação é uma capacidade acionada dentro desses fluxos, não um fluxo
   paralelo.
3. **Não é objetivo**, nesta fase, integrar uma ferramenta proprietária de
   design (Figma, Sketch, etc.) — o MVP deve ser agnóstico de ferramenta.
4. **Não é objetivo** validar automaticamente com usuários reais — a validação
   com usuários continua sendo pesquisa humana, apoiada pelo protótipo como
   instrumento, não substituída por ele.
5. **Não é objetivo** cobrir, nesta definição, o tratamento de dados sensíveis
   dentro de protótipos — fica registrado como gap para a fase de shape/design
   técnico (ver "Perguntas em aberto" no intake e Lente 4 da pesquisa).

## Métricas de sucesso propostas

Todas as métricas abaixo são candidatas a validar em `/nc-assess-shape` e
`/nc-assess-decide`; nenhuma tem baseline medido ainda
(**[NEEDS CLARIFICATION]** para todas, salvo indicação contrária):

| Métrica | Descrição | Como medir (proposta) |
|---|---|---|
| Redução de retrabalho de interface | Nº de features que precisaram revisar a UI já implementada por divergência de expectativa | Comparar antes/depois da adoção da capacidade, por sprint ou por feature |
| Tempo até validação visual | Tempo entre início da ideia/spec e primeira validação de experiência por um stakeholder | Timestamp do protótipo aprovado vs. timestamp do intake/interview |
| Taxa de adoção nos dois fluxos | % de assessments e specs que usaram a capacidade de prototipação quando aplicável (feature com superfície visual) | Contagem de artefatos de protótipo versionados por assessment/spec |
| Rastreabilidade preservada | % de protótipos aprovados que foram referenciados explicitamente em `spec.md` ou `concept.md` | Auditoria de links entre protótipo e spec/concept |
| Conformidade de acessibilidade | % de protótipos que passam por checklist mínimo de acessibilidade (via `nc-designer`) antes da aprovação | Checklist associado ao modo `audit`/`critique` do `nc-designer` |

## Handoff

**Recomendação:** avançar para `/nc-assess-shape` para comparar as opções de
solução (extensão de `nc-designer`, nova skill dedicada, ou etapa formal
integrada aos dois fluxos), definir escopo do MVP e apetite de esforço, com
base nas metas, anti-metas e métricas acima.
