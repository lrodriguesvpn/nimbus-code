# Research — Agente de Prototipação de Telas

## Identificação

| Campo | Valor |
|---|---|
| **Assessment** | `agente-prototipacao-telas` |
| **Fase** | Evidence Research |
| **Data** | 2026-09-21 |
| **Status** | Pesquisa inicial concluída; pronta para definição do problema |

## Resumo executivo

Há evidência suficiente para tratar a prototipação como uma capacidade útil nos
dois fluxos do Nimbus Code, mas não para concluir ainda que um agente autônomo
deva gerar protótipos de alta fidelidade. A recomendação é validar primeiro uma
capacidade assistida e rastreável: transformar contexto da ideia ou da entrevista
em alternativas visuais, estados e fluxos que possam ser revisados por pessoas.

O melhor encaixe é transversal:

- no **Assessment**, como instrumento de exploração e evidência para decidir se a
  ideia deve avançar;
- na **Spec Formal**, como etapa opcional de descoberta visual antes de fechar
  requisitos, cenários e critérios de aceitação;
- em ambos, com o `nc-designer` como guardrail de UX, acessibilidade e direção
  visual, sem substituir pesquisa, decisão humana ou especificação.

## Lente 1 — Usuários e demanda

### Evidências

1. A ideia identifica quatro grupos potenciais: Product Owners/analistas,
   designers, desenvolvedores/tech leads e stakeholders. Isso é uma hipótese
   derivada do intake, ainda sem entrevistas ou métricas de uso.
   **Fonte:** [intake.md](./intake.md).

2. O Government Digital Service recomenda começar entendendo quem usará o
   serviço, o que essas pessoas tentam fazer e quais problemas enfrentam; também
   recomenda continuar pesquisando e testando ideias de design em cada fase.
   **Fonte:** GOV.UK Service Manual,
   [Start by learning about user needs](https://www.gov.uk/service-manual/user-research/start-by-learning-user-needs).

3. A orientação oficial também diferencia opinião de evidência: sugestões que
   não vêm de usuários devem ser tratadas como hipóteses a serem comprovadas.
   **Fonte:** mesma referência do GOV.UK.

### Interpretação

O agente pode reduzir ambiguidade de comunicação entre negócio, design e
engenharia ao tornar uma alternativa discutível antes do código. Porém, gerar
uma tela não prova que a solução atende usuários. O protótipo deve ser um
artefato para pesquisa e revisão, não um substituto para validação com usuários.

**[NEEDS CLARIFICATION]** Ainda não há evidência interna sobre volume de
retrabalho, tempo gasto em alinhamento visual ou número de features que
precisariam da capacidade.

## Lente 2 — Arte prévia e capacidades existentes

### Evidências internas

1. O Nimbus já possui a skill `/nc-designer`, com processo explícito
   **Plan → Revisar contra o brief → Construir → Auto-Crítica**, modos `audit`,
   `critique`, `polish` e `harden`, e orientação para usar `DESIGN.md` quando
   existir.
   **Fonte:** [SKILL.md do nc-designer](../../../.github/skills/nc-designer/SKILL.md).

2. A skill institucional já exige direção visual específica, revisão contra o
   brief, acessibilidade, responsividade e prevenção de padrões genéricos de
   interface.
   **Fonte:** [SKILL.md do nc-designer](../../../.github/skills/nc-designer/SKILL.md).

3. O repositório registra a decisão de tornar essa capacidade portável entre
   Copilot, Claude Code e Antigravity, sem depender de runtime externo.
   **Fonte:** [análise comparativa de design](../../../docs/comparisons/impeccable-and-claude-design-vs-nimbus-code.md).

### Interpretação

O caminho de menor risco não é criar um agente visual isolado com regras
duplicadas. É adicionar uma capacidade de prototipação ao ecossistema existente,
reutilizando `nc-designer` para julgamento de interface e definindo contratos de
entrada/saída para os dois fluxos.

**[ASSUMPTION]** Um primeiro MVP pode produzir artefatos versionáveis em
Markdown/SVG/HTML estático ou outro formato definido posteriormente, sem
integrar uma ferramenta proprietária de design.

## Lente 3 — Mercado e contexto

### Evidências

1. A acessibilidade não é uma preocupação posterior apenas da implementação:
   WCAG se aplica a conteúdo web, aplicações dinâmicas, mobile e interfaces web
   baseadas em IA.
   **Fonte:** W3C,
   [Web Content Accessibility Guidelines](https://www.w3.org/WAI/standards-guidelines/wcag/).

2. WCAG 2.2 organiza requisitos em quatro princípios — perceptível, operável,
   compreensível e robusto — e define critérios de sucesso testáveis nos níveis
   A, AA e AAA.
   **Fonte:** mesma referência do W3C.

3. O custo de não fazer nada é uma hipótese plausível de decisões visuais
   tardias e retrabalho, registrada no intake, mas ainda não medida neste
   repositório.
   **Fonte:** [intake.md](./intake.md); classificação adicional:
   **[ASSUMPTION]**.

### Interpretação

O diferencial do Nimbus não deveria ser apenas “gerar telas com IA”. O valor
potencial está em conectar protótipo, contexto, decisões de design,
acessibilidade e rastreabilidade até a spec. Sem essa conexão, a capacidade
compete apenas como gerador visual e pode criar expectativas erradas de
implementação automática.

## Lente 4 — Dados, restrições e compliance

### Restrições identificadas

- Protótipos podem conter dados de clientes, fluxos internos, informações de
  autenticação ou outras informações sensíveis.
  **[NEEDS CLARIFICATION]** O intake ainda não classifica os dados que poderão
  ser enviados ao agente.
- A saída precisa preservar decisões de acessibilidade desde a exploração.
  WCAG 2.2 é uma referência verificável para esse requisito.
  **Fonte:** W3C, link acima.
- O protótipo deve ser rastreável à ideia/spec e ter controle de versão.
  **[ASSUMPTION]** Isso será necessário para evitar divergência entre a tela
  aprovada e os requisitos implementados.
- A aprovação do protótipo precisa permanecer humana, especialmente quando a
  tela representa fluxos regulados, dados pessoais ou decisões de negócio.
  **[ASSUMPTION]**.

### Restrições de processo

- No **Fluxo A**, não se deve pular pesquisa e definição apenas porque o agente
  conseguiu gerar uma tela.
- No **Fluxo B**, a prototipação pode ser inserida durante `/nc-spec` sem exigir
  um assessment separado quando a feature já estiver aprovada.
- O protótipo não deve ser tratado como código de produção por padrão.
- Critérios de “pronto para spec” devem ser definidos antes de transformar a
  saída visual em requisitos.

## Opções de encaixe avaliadas

| Opção | Descrição | Avaliação |
|---|---|---|
| **A — Etapa transversal reutilizável** | Capacidade acionada no Assessment ou na Spec, usando `nc-designer` | **Recomendada**; reduz duplicação e respeita os dois fluxos |
| **B — Agente exclusivo do Assessment** | Só prototipa antes da Spec Formal | Inadequada; não atende features que entram diretamente pela Spec |
| **C — Agente exclusivo da Spec** | Só prototipa após entrevista | Inadequada; perde valor na exploração de ideias ainda incertas |
| **D — Gerador autônomo de frontend** | Produz código como resultado principal | Alto risco; mistura descoberta com implementação e dificulta validação |

## Recomendação de pesquisa

Avançar para `/nc-assess-define` com uma definição centrada no problema:

> Equipes precisam tornar e validar decisões de experiência antes da
> implementação, mantendo a conexão entre hipótese visual, feedback,
> acessibilidade e requisitos formais.

Na fase seguinte, definir:

1. usuário primário do MVP;
2. formato mínimo de saída;
3. momento de aprovação humana;
4. métricas de sucesso;
5. dados permitidos no contexto;
6. contrato de handoff para `spec.md`.

## Gaps que impedem uma decisão final de Go

- Não há entrevistas ou dados internos comprovando a frequência do problema.
- Não está definido o tipo de protótipo mínimo.
- Não está definido o mecanismo de validação com stakeholders/usuários.
- Não está definida a política para dados sensíveis em prompts e protótipos.
- Não está definido se o artefato será apenas visual ou também estruturado para
  gerar cenários e critérios de aceitação.

## Handoff

**Recomendação:** seguir para `/nc-assess-define`. A pesquisa apoia a ideia como
hipótese promissora, mas recomenda um MVP assistido e agnóstico de ferramenta,
integrado aos dois fluxos e governado pelo `nc-designer`, antes de qualquer
implementação de um agente autônomo completo.
