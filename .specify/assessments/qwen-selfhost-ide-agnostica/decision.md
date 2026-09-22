# Decision — Qwen (self-hosted) e IDE Agentic Agnóstica

**Slug**: `qwen-selfhost-ide-agnostica`
**Data**: 2026-09-21
**Agente**: NC-Assess-Decide
**Baseado em**: `intake.md`, `research.md`, `problem.md`, `concept.md`

---

## Veredito: **Needs Clarification**

A ideia é legítima, o problema é real e o conceito (Opções A/B/C) está claro
e bem sequenciado. Mas há uma **incerteza crítica de decisão externa** que
bloqueia qualquer avanço, inclusive da opção mínima (A): a mudança de
política de "ferramenta oficial nomeada" para "processo oficial, ferramenta
livre" — e, mais sensível ainda, a eventual adoção de um modelo self-hosted
de origem Qwen/Alibaba — **não são decisões que o time de engenharia pode
tomar sozinho**. Elas dependem de aprovação de Segurança, Jurídico e DPO,
conforme identificado tanto em `problem.md` quanto em `concept.md`.

### Por que não é Go direto para `/nc-spec`

O fluxo de especificação formal (SDD: spec → plan → tasks → implement) serve
para **construir algo** — código, automação, IaC. Mas o item que está
efetivamente pronto para avançar agora (Opção A do `concept.md`) não é uma
peça de engenharia: é uma **mudança de redação de governança** que precisa de
aprovação formal de stakeholders fora do esquadrão de agentes. Forçar um Go
para `/nc-spec` neste momento pularia essa aprovação e trataria uma decisão
de política corporativa como se fosse uma tarefa técnica — o que o próprio
processo Nimbus Code recomenda evitar (ver regra de "nunca impor uma decisão
de arquitetura silenciosamente" nas instruções do projeto).

### Por que não é Kill

Não há nada na pesquisa que invalide a ideia — pelo contrário, o achado sobre
BYOK do VS Code **reduziu** a barreira técnica percebida inicialmente. O
problema é real (rigidez de política + rigidez de custo/soberania), o
apetite da Opção A é pequeno, e a lógica de sequenciamento (A → B → C) é
sólida. Matar a ideia agora descartaria algo com valor estratégico real só
por falta de uma aprovação que ainda nem foi solicitada.

## O que precisa ser esclarecido antes de reavaliar

1. **Parecer de Segurança/Jurídico/DPO** sobre:
   - Alterar a política de "ferramenta oficial nomeada" para "processo
     Nimbus Code oficial, IDE agentic livre mediante critérios objetivos".
   - Uso de modelo aberto de origem Qwen/Alibaba, mesmo self-hosted dentro
     do perímetro da empresa (pode ser aprovado, aprovado com condições, ou
     reprovado — qualquer resultado é uma resposta válida para destravar
     esta ideia).
2. **Dado real de custo/volume** de uso de IA para codificação hoje (linha de
   base), para permitir avaliar o breakeven de GPU dedicada antes de aprovar
   qualquer piloto (Opção B).
3. **Alinhamento com o SPEC 026** (governança de uso do template/IP) para
   garantir que as duas iniciativas de política de IA não caminhem em
   paralelo com posições conflitantes.

## Ação imediata recomendada (não é `/nc-spec` ainda)

Como passo concreto e de baixo custo, recomenda-se **redigir um rascunho de
ADR** com a proposta da Opção A (mudança de redação da política, critérios
objetivos de compatibilidade de IDE agentic) e **encaminhar formalmente a
Segurança/Jurídico/DPO** para aprovação — o mesmo padrão de handoff já usado
no assessment anterior (ex.: abrir uma Issue avisando o responsável, como foi
feito para o Eduardo Pereira no ciclo de prototipação de telas).

Quando o parecer desses stakeholders existir (aprovado / aprovado com
condições / reprovado), este ciclo de assessment deve ser **reaberto e
reavaliado** com esse dado novo — nesse momento sim, se aprovado, a Opção A
pode virar um `/nc-spec` leve (documentação/ADR) e as Opções B/C podem ser
tratadas como ideias subsequentes no funil.

## Handoff

- **Não** executar `/nc-spec` ou `/speckit-specify` neste momento.
- Registrar esta decisão e notificar o(s) stakeholder(s) responsável(is) por
  Segurança/Jurídico/DPO, para que o parecer solicitado no item 1 acima possa
  ser produzido.
