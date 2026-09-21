# Concept — Qwen (self-hosted) e IDE Agentic Agnóstica

**Slug**: `qwen-selfhost-ide-agnostica`
**Data**: 2026-09-21
**Agente**: NC-Assess-Shape
**Baseado em**: `intake.md`, `research.md`, `problem.md`

---

## Opção A (mínima) — "Abrir a política, sem mexer em modelo ainda"

**Esboço conceitual**: Revisar apenas a governança escrita
(`docs/ai-governance/README.md` e trecho correspondente do `README.md`), sem
tocar em nenhum modelo/ferramenta nova ainda. Trocar a redação de "ferramenta
oficial: Microsoft Copilot / GitHub Enterprise Copilot" para "**processo
oficial: Nimbus Code**; qualquer IDE agentic que atenda aos critérios de
compatibilidade abaixo é aceita". Definir formalmente esses critérios (ex.:
suporta o esquadrão de agentes NC-* via arquivo de agente/skill, respeita os
gates de segurança do processo, permite auditoria/rastreabilidade
equivalente). Nenhum piloto de Qwen ainda — só a mudança de política.

- **Apetite**: `small` (dias). É essencialmente um ADR + atualização de 2
  documentos + aprovação formal de Segurança/Jurídico sobre a redação.
- **Trade-offs**:
  - ✅ Resolve o desalinhamento entre arquitetura (já multi-ferramenta) e
    política (ainda mono-ferramenta) rapidamente e sem risco técnico.
  - ✅ Não exige nenhuma decisão sobre origem de modelo Qwen ainda — separa
    claramente as duas preocupações identificadas no `problem.md`.
  - ⚠️ Não entrega, por si só, o benefício de custo/soberania que motivou a
    ideia original — é um pré-requisito, não a solução completa.
  - ⚠️ Ainda depende de aprovação de Segurança/Jurídico, que pode não ser
    imediata mesmo para só a mudança de redação.

## Opção B (intermediária) — "Abrir a política + piloto controlado de BYOK com modelo aberto"

**Esboço conceitual**: Tudo da Opção A, mais um piloto técnico limitado: um
pequeno grupo de devs voluntários testa, em ambiente isolado (não produção),
conectar o VS Code Copilot Chat a um endpoint self-hosted (BYOK/custom
endpoint, conforme documentado pela Microsoft) servindo um modelo aberto —
podendo ser Qwen-Coder ou outro modelo aberto equivalente, decisão que ficaria
para o piloto avaliar, não travada a priori só no Qwen. O piloto mede: (1)
qualidade de código em tarefas reais do Nimbus Code comparado ao modelo atual,
(2) custo real de infraestrutura de GPU no período, (3) fricção de uso
(o BYOK em Agent Host é experimental, conforme achado da pesquisa).

- **Apetite**: `medium` (semanas). Inclui provisionar GPU temporária,
  configurar o servidor de inferência (ex.: vLLM), configurar BYOK, definir
  tarefas de avaliação e coletar métricas.
- **Trade-offs**:
  - ✅ Gera o dado que falta hoje (custo real, qualidade real) antes de
    qualquer compromisso maior — reduz o risco da Opção C.
  - ✅ Testa a mitigação de soberania de dado na prática (modelo dentro do
    perímetro da empresa).
  - ⚠️ Ainda esbarra no estágio experimental do BYOK em Agent Host — pode ser
    necessário testar via Copilot Chat comum (não sessão de agente autônomo)
    como primeira etapa, o que limita o escopo do piloto.
  - ⚠️ Exige orçamento de infraestrutura (GPU), mesmo que temporário, e ainda
    depende do parecer de Jurídico/Compliance sobre a origem do modelo antes
    de sequer iniciar (não pode ser feito "por baixo" para depois legitimar).

## Opção C (ampla) — "Suporte institucional oficial a Qwen Code / modelo self-hosted como 4º alvo"

**Esboço conceitual**: Estender `nc-agent-sync.py` para projetar o esquadrão
NC-* também para o formato do Qwen Code CLI (4º alvo, ao lado de VS Code,
Claude Code, Antigravity), com suporte institucional formal, documentação e
onboarding — tratando Qwen Code como IDE agentic de primeira classe dentro do
Nimbus Code, incluindo o cenário de modelo self-hosted como opção
recomendada de baixo custo para alto volume.

- **Apetite**: `large` (meses). Envolve spike técnico de paridade de recursos
  (subagentes, MCP, formato de skill do Qwen Code), manutenção contínua de
  um 4º alvo de projeção, suporte a devs usando essa ferramenta, e resolução
  prévia obrigatória de tudo que a Opção A e B endereçam primeiro.
- **Trade-offs**:
  - ✅ Maior potencial de ganho de custo em escala e de soberania de dado.
  - ✅ Coerente com a visão de longo prazo do Dev ("processo é o oficial,
    ferramenta é livre").
  - ⚠️ Maior esforço de manutenção contínua (mais um alvo para manter em
    paridade a cada evolução do esquadrão NC-*).
  - ⚠️ Não deveria ser feito sem ter passado antes pelas Opções A e B — fazer
    isso primeiro seria investir esforço grande em algo cuja política e
    cujos dados de custo/qualidade ainda não foram validados.
  - ⚠️ Reforça a necessidade de decisão de Jurídico/Compliance sobre origem
    do modelo/software antes de qualquer compromisso institucional formal.

## Recomendação de sequenciamento (não é a decisão final — isso é do `/nc-assess-decide`)

As três opções não são mutuamente exclusivas — são **fases naturais**: A
(política) → B (piloto e dado real) → C (suporte institucional, só se A e B
confirmarem valor e viabilidade). Não há como pular direto para C sem passar
por A, dado que a barreira real identificada no `problem.md` é de governança,
não de engenharia.

## Próximo passo recomendado

Avançar para `/nc-assess-decide` para o veredito formal, considerando que
esta ideia tem **dependências externas ao time de engenharia** (aprovação de
Segurança/Jurídico/DPO) como pré-condição de qualquer opção, mesmo a mínima.
