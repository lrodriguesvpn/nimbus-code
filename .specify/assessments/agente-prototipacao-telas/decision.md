# Decision — Agente de Prototipação de Telas

## Identificação

| Campo | Valor |
|---|---|
| **Assessment** | `agente-prototipacao-telas` |
| **Fase** | Decision Gate |
| **Data** | 2026-09-21 |
| **Insumos** | [`intake.md`](./intake.md), [`research.md`](./research.md), [`problem.md`](./problem.md), [`concept.md`](./concept.md) |

## Avaliação holística

| Critério | Avaliação |
|---|---|
| **Validade do problema** | Real e verificável: hoje não existe, nos dois fluxos do Nimbus Code, uma etapa explícita de exploração visual antes do código. A skill `nc-designer` já cobre julgamento de UX/acessibilidade, mas atua depois que já existe superfície a revisar, não na fase de gerar/comparar alternativas. |
| **Força das evidências** | Moderada. Há evidência institucional forte (arquitetura dos dois fluxos, existência e escopo do `nc-designer`) e evidência externa sólida sobre acessibilidade (W3C WCAG) e prática de pesquisa centrada no usuário (GOV.UK). Não há evidência quantitativa interna (retrabalho, tempo de alinhamento) — está marcada como `[NEEDS CLARIFICATION]` em `problem.md` e `research.md`. |
| **Clareza do conceito** | Alta para o escopo mínimo (Opção 1). As opções 2 e 3 têm trade-offs bem descritos, mas dependem de evidência que ainda não existe. |
| **Alinhamento estratégico** | Alto. Reaproveita capacidade já institucionalizada (`nc-designer`), respeita os dois fluxos sem substituí-los, e segue o princípio de menor apetite viável antes de qualquer gate formal de governança. |
| **Risco de escopo desproporcional** | Baixo para Opção 1; alto para Opção 3 (descartada); médio para Opção 2 (adiada). |

## Veredito

### ✅ GO — escopo restrito à Opção 1 (modo de prototipação no `nc-designer`)

A ideia é aprovada para avançar à Spec Formal, **com escopo explicitamente
limitado**:

- **Aprovado:** adicionar um modo de prototipação estruturado (texto/Markdown/
  diagrama) ao `nc-designer`, acionável a partir de contexto de Assessment
  (`intake.md`/`problem.md`) ou de Spec Formal (`interview.md`), com
  convenção de onde salvar o artefato resultante e critério mínimo de
  "pronto para revisão" alinhado ao checklist de acessibilidade já existente
  no `nc-designer`.
- **Não aprovado nesta rodada:** criação de nova skill dedicada (Opção 2) ou
  de gate formal obrigatório no processo (Opção 3). Ambas ficam registradas
  como evolução futura, condicionadas a evidência de adoção/valor coletada
  após o uso do escopo mínimo.

### Condições do Go (a resolver durante `/nc-spec`, não bloqueiam o Go)

As lacunas abaixo não impedem o Go porque o escopo aprovado é de baixo risco
e baixo apetite, mas devem ser resolvidas como parte da especificação formal
(via `/nc-clarify` se necessário), não deixadas em aberto na implementação:

1. Formato exato de saída do modo de prototipação (Markdown estruturado +
   diagrama Mermaid é a proposta-base de `concept.md`, Opção 1).
2. Convenção de nome/local do artefato gerado, para preservar rastreabilidade
   sem exigir schema formal (ex.: `.specify/assessments/<slug>/prototype-sketch.md`
   ou `specs/<feature>/prototype-sketch.md`).
3. Quem aprova o esboço como suficiente para seguir adiante (papel humano,
   não necessariamente um RACI novo — pode reaproveitar quem já aprova
   `spec.md`).
4. Política mínima para não incluir dados sensíveis/reais no contexto enviado
   ao modo de prototipação (orientação simples, não um controle formal de
   compliance nesta fase).

### Por que não Kill

O problema é real e de baixo custo para mitigar no escopo mínimo aprovado.
Descartar a ideia jogaria fora uma capacidade de baixo risco que já tem
caminho de implementação claro (extensão de instruções em skill existente).

### Por que não Needs Clarification (bloqueante)

As incertezas identificadas (aprovação, formato de arquivo, dados sensíveis)
são de **detalhamento de implementação**, não de **viabilidade da ideia**.
Elas são apropriadas para serem resolvidas em `/nc-spec`/`/nc-clarify`, e não
justificam atrasar o handoff, dado o apetite mínimo (`small`) da Opção 1.

## Handoff para Spec Formal

Como esta ideia teve origem no Fluxo A (Ideação/Assessment) e foi aprovada,
segue-se a regra de decisão registrada em `intake.md`: uma ideia aprovada em
Assessment deve fazer handoff para a Spec Formal, não permanecer
indefinidamente como protótipo/assessment.

**Próximos passos recomendados:**

1. Executar `/nc-intake` para conduzir a entrevista de descoberta formal
   (blocos Negócio, Infraestrutura, Segurança e LGPD), referenciando este
   assessment como contexto de origem — criar `specs/<nova-feature>/interview.md`.
2. Executar `/nc-spec` para gerar `spec.md` com requisitos SMART e cenários
   BDD, escopo limitado à Opção 1 (modo de prototipação no `nc-designer`),
   resolvendo as condições do Go listadas acima como parte da especificação.
3. Seguir o processo padrão: `/nc-critic` → arquitetura/graph → `/nc-spec`
   plan → `/nc-qa` tasks → implementação.

**Escopo explicitamente fora deste handoff:** Opções 2 e 3 de `concept.md`
não devem ser incluídas na spec resultante. Se, após uso do escopo mínimo,
houver evidência de valor (métricas de `problem.md`), uma nova ideia/feature
deve ser aberta para avaliar a evolução — não expandir o escopo desta spec
silenciosamente.
