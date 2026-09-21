# 0010 — Adoção Experimental do Skill TypeSafe/Jev para Julgamentos Tipados de Baixo Custo

- **Status:** Proposta
- **Data:** 2026-09-21
- **Autores:** @nimbus-agent (via sessão Copilot SDK/VS Code)
- **Contexto:** organizacional (skill disponível para qualquer feature que precise de julgamentos semânticos)
- **Revisores:** @nimbus-code-arch-board

---

## Contexto e Problema

O [`corporate-constitution.md`](../ai-governance/corporate-constitution.md) deste
repositório define que as ferramentas oficiais de IA são **Microsoft Copilot**
(negócio) e **GitHub Enterprise Copilot** (engenharia), e que "nenhuma ferramenta
de IA cria uma política paralela" sem que a exceção seja explícita e rastreável.

Foi solicitada a instalação do skill de terceiros
[`typesafe-ai/skills`](https://raw.githubusercontent.com/typesafe-ai/skills/main/skills/typesafe-ai/SKILL.md) — que expõe o
produto **TypeSafe** e seu modelo **Jev** ("System One model"): em vez de gerar
texto livre, o Jev retorna **julgamentos tipados e probabilidades** (roteamento,
ranking, extração, verificação, classificação) a partir de linguagem natural e
estado da aplicação. É um modelo especializado e mais barato/rápido que um LLM
de propósito geral para tarefas que não precisam de geração de texto longo —
apenas de uma decisão estruturada.

Esta decisão registra a exceção — o skill foi instalado localmente
(`.agents/skills/typesafe-ai/`, espelhado via symlink em `.claude/skills/typesafe-ai`)
para avaliação e uso pontual em features que se beneficiem de julgamentos
tipados de baixo custo, sem que isso substitua o Copilot/GitHub Enterprise
Copilot como motor de geração/edição de código do Nimbus Code.

## Drivers de Decisão

- **Custo por chamada**: modelos "System One" tendem a ser ordens de magnitude
  mais baratos que um LLM de reasoning completo para decisões pontuais
  (classificar, rotear, extrair, validar), reduzindo o custo real por feature
  (ver `docs/ai-code-quality-and-observability.md`, seção 8/rastreamento de custo).
- **Latência**: julgamentos tipados respondem mais rápido que gerar/parsear texto
  livre de um LLM genérico, o que importa em fluxos interativos (ex.: triagem
  de issues, roteamento de comandos `/nc-*`).
- **Especialização vs. propósito geral**: nem toda decisão dentro do Nimbus Code
  precisa de um modelo de reasoning caro — algumas são "comum senso programável"
  (ex.: esta issue é P0 ou P1? este PR toca segurança? esta resposta do usuário
  responde à pergunta de clarificação?).
- **Não-substituição do stack oficial**: a decisão precisa deixar claro que isso
  é aditivo/experimental, não uma migração da ferramenta de IA principal.

## Opções Consideradas

- **Opção A** — Adotar o skill TypeSafe/Jev como ferramenta **complementar e
  opcional**, para tarefas específicas de julgamento tipado de baixo custo,
  mantendo Copilot/GitHub Enterprise Copilot como motor principal de código.
- **Opção B** — Não adotar, mantendo apenas as ferramentas oficiais already
  definidas na constituição corporativa.
- **Opção C** — Adotar como substituto direto de partes do pipeline de agentes
  NC-* (ex.: usar Jev em vez de um LLM de reasoning nos gates de decisão).

## Análise das Opções

### Opção A — Adoção complementar e opcional (escolhida)

- ✅ Reduz custo em tarefas de classificação/roteamento sem tocar no núcleo
  do pipeline de geração de código.
- ✅ Não conflita com a política anti-Shadow-IT: fica registrado, com owner e
  escopo de uso explícitos.
- ✅ Reversível — é só um skill a mais em `.agents/skills/`, sem dependência
  de runtime obrigatória.
- ❌ Exige que cada uso pontual declare explicitamente por que o Jev foi
  escolhido em vez do modelo padrão (custo extra de disciplina).

### Opção B — Não adotar

- ✅ Zero risco de shadow IT.
- ❌ Perde a oportunidade real de redução de custo em tarefas de baixo valor
  agregado por token (roteamento, triagem, extração).

### Opção C — Substituir partes do pipeline de agentes NC-*

- ✅ Redução de custo potencialmente maior.
- ❌ Complexidade/risco alto: os gates S3/S4 e os agentes `NC-Shield`/`NC-Governor`
  exigem revisão humana explícita e não devem depender de um modelo de terceiros
  ainda não avaliado em produção.
- ❌ Viola o princípio de "nunca usar modelo mais forte ou mais novo do que o
  necessário sem avaliação" — Jev nunca foi testado neste contexto.

## Decisão

**Opção A**: adotar o skill TypeSafe/Jev como ferramenta **complementar,
opcional e experimental**, restrita a: (1) classificação/roteamento de baixo
risco (ex.: triagem inicial de labels/prioridade, roteamento entre `/nc-*`),
(2) extração/normalização de campos estruturados a partir de texto livre
(ex.: normalizar respostas de `/nc-intake` antes de preencher `interview.md`),
e (3) verificação leve (ex.: "esta resposta cobre o bloco de LGPD?"). Nunca em
substituição a `NC-Governor`, `NC-Shield` ou decisões S3/S4, que continuam
exigindo o modelo de reasoning padrão e revisão humana.

## Consequências

### Positivas

- Ganho de custo/latência em tarefas de julgamento tipado sem tocar no core
  do pipeline de qualidade de código.
- Exceção documentada e rastreável, em conformidade com a constituição
  corporativa de IA.

### Negativas / Trade-offs Assumidos

- Mais uma ferramenta de IA para manter/observar (SLA, disponibilidade,
  custo do provider TypeSafe).
- Requer que cada feature que usar Jev documente no seu `plan.md`
  (Architecture Decision Log) o motivo e o escopo do uso, apontando para
  este ADR.
- Nenhum dado sensível (PII, segredos) deve ser enviado ao Jev sem passar
  pelas mesmas regras de classificação de dados já vigentes (ver
  `docs/ai-governance/`).

### Ações derivadas

- [x] Instalar o skill localmente (`.agents/skills/typesafe-ai/`, espelhado em
      `.claude/skills/typesafe-ai/`) via `npx skills add typesafe-ai/skills --skill typesafe-ai`.
- [x] Registrar este ADR e referenciá-lo em `corporate-constitution.md`.
- [ ] Nenhuma feature deve depender do Jev sem citar este ADR no seu `plan.md`.
- [ ] Reavaliar esta decisão após o primeiro uso real em produção (custo real
      medido vs. estimado, qualidade dos julgamentos).

## Links

- [Skill (fonte, conteúdo bruto)](https://raw.githubusercontent.com/typesafe-ai/skills/main/skills/typesafe-ai/SKILL.md)
- [Documentação viva do TypeSafe](https://docs.typesafe.ai/llms.txt)
- [Análise de oportunidades de uso do Jev no Nimbus Code](../comparisons/typesafe-jev-oportunidades-nimbus-code.md)
- Supersede: —
- Relacionado a: [`docs/ai-governance/corporate-constitution.md`](../ai-governance/corporate-constitution.md)
