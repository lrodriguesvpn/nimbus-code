# Research — Qwen (self-hosted) e IDE Agentic Agnóstica

**Slug**: `qwen-selfhost-ide-agnostica`
**Data**: 2026-09-21
**Agente**: NC-Assess-Research
**Baseado em**: `intake.md`

---

## 1. Usuários & Demanda

- [ASSUMPTION] Não há dado real de volume de uso de IA para codificação por
  dev/mês nesta organização (tokens consumidos, nº de sessões) disponível
  para esta pesquisa. Sem isso, não é possível calcular breakeven de custo
  self-host vs. API — este é o dado crítico que falta antes de qualquer
  decisão de investimento em GPU dedicada.
- [NEEDS CLARIFICATION] Não há evidência de que devs tenham pedido
  explicitamente uma alternativa de menor custo — a demanda até aqui é uma
  hipótese levantada pelo Dev/liderança, não um sinal vindo de baixo para
  cima (times reclamando de custo de licença Copilot, por exemplo).

## 2. Arte Prévia (o que já existe)

### 2.1 VS Code já suporta modelo customizado/self-hosted (BYOK) — achado que revisa a hipótese do intake

Fonte: [VS Code Docs — "AI language models in VS Code"](https://code.visualstudio.com/docs/copilot/customization/language-models)
(consultado nesta pesquisa, 2026-09-21).

> "Bring Your Own Key (BYOK) lets you connect to any compatible model
> provider while still using the VS Code chat experience and tools. You can
> use BYOK to access models from other providers, to run models locally, or
> to use models that are not yet available as built-in options in VS Code...
> including fully offline scenarios with local models such as Ollama."

E, especificamente sobre endpoint próprio:

> "Custom endpoint: You have a self-hosted, enterprise, or other endpoint
> that speaks Chat Completions, Responses, or Messages API."

**Isso contradiz a hipótese não confirmada registrada no intake** ("Copilot
Agent não permite BYOM hoje"). Na verdade:
- O VS Code Copilot **Chat** já suporta apontar para um endpoint
  self-hosted OpenAI-compatible (ex.: um servidor vLLM servindo Qwen-Coder) —
  sem depender da infraestrutura de modelos do GitHub/Microsoft.
- **Ressalva relevante, com fonte na mesma página**: para sessões de **Agent
  Host** (o modo "Agents window"/sessões autônomas, que é justamente onde o
  esquadrão NC-* roda) o suporte a modelos BYOK é **experimental** e precisa
  de uma flag explícita (`chat.agentHost.byokModels.enabled`), podendo mudar
  ou ser removido. Ou seja: **tecnicamente possível hoje, mas em estágio
  experimental para o cenário que interessa (agentes autônomos), não GA**.
- BYOK dispensa até conta GitHub/plano Copilot para o modelo em si — mas
  features como busca semântica, code completion inline e embeddings
  continuam exigindo conta GitHub (não são cobertas por BYOK).

**Implicação prática**: a arquitetura de projeção multi-agente do Nimbus Code
(`nc-agent-sync.py`) já gera artefatos nativos para VS Code — plugar um
endpoint Qwen self-hosted via BYOK não exigiria um "4º alvo" de projeção como
se pensava (Qwen Code CLI como app separado); poderia, em tese, ser só uma
troca de modelo **dentro do próprio Copilot Chat/Agent**, mantendo a mesma
superfície de agente já gerada. Isso muda a natureza da decisão: de "adotar
uma 4ª ferramenta" para "adotar um 4º provedor de modelo dentro da ferramenta
já oficial" — reduz drasticamente o esforço de engenharia, mas ainda esbarra
no estágio experimental do BYOK em Agent Host.

### 2.2 Qwen Code CLI como alternativa fora do VS Code

Fonte: [GitHub — QwenLM/qwen-code](https://github.com/QwenLM/qwen-code)
(consultado nesta pesquisa).

- CLI agentic open-source, com subagentes, memória, MCP, modo headless
  (`qwen -p "..."`), SDKs (TypeScript/Python/Java) e daemon experimental.
- Suporta múltiplos protocolos (OpenAI, Anthropic, Gemini, Qwen) e modelo
  local via Ollama/vLLM — ou seja, **não depende exclusivamente da API da
  Alibaba**, o que atende à condição colocada pelo Dev ("não via API da
  Alibaba, em nuvem nossa").
- Tem plugin para VS Code, além de app desktop, web UI e integrações de chat
  (Telegram/DingTalk/WeChat/Feishu — irrelevantes para este contexto
  corporativo).
- [NEEDS CLARIFICATION] Não foi possível verificar nesta pesquisa se o
  formato de "agente"/"skill"/subagente do Qwen Code é compatível ou
  facilmente adaptável ao gerador `nc-agent-sync.py` (que hoje projeta para
  VS Code `.github/agents`, Claude `.claude/agents`, Antigravity
  `.agents/skills`). Precisaria de spike técnico dedicado antes de qualquer
  compromisso de suporte oficial.

### 2.3 Cursor.ai (mencionado pelo Dev como outra opção candidata)

- [ASSUMPTION] Cursor é uma IDE agentic proprietária (fork do VS Code), com
  seu próprio modelo de billing (assinatura), suporte a múltiplos provedores
  de modelo, mas — ao contrário do Qwen Code — **não é open-source** e não
  foi encontrada, nesta pesquisa, documentação de suporte oficial a endpoint
  self-hosted arbitrário no mesmo nível do BYOK do VS Code. Precisaria de
  pesquisa dedicada se a organização quiser avaliá-lo formalmente; não
  aprofundado aqui por não ser o foco principal desta ideia (o Dev citou como
  "e etc.", não como alvo primário).

## 3. Mercado & Contexto

- [ASSUMPTION] Modelos da família Qwen-Coder (open-weight) têm reputação de
  qualidade competitiva em benchmarks públicos de codificação frente a
  modelos comerciais de porte equivalente — não há benchmark próprio da
  empresa aplicado nesta pesquisa; a validação real precisaria de piloto
  controlado com tarefas reais do Nimbus Code, não apenas benchmark público.
- [ASSUMPTION] Servir um modelo de porte "coder" competitivo (dezenas de
  bilhões de parâmetros) 24/7 em GPU dedicada em nuvem própria tem custo fixo
  mensal significativo (ordem de milhares de dólares/mês, dependendo do
  tamanho do modelo e SKU de GPU) — isso é conhecimento geral de mercado de
  infraestrutura de IA, não uma cotação real desta organização. **Precisa de
  cotação real (Azure/AWS/GCP GPU) antes de qualquer decisão.**
- Custo de não fazer nada: continuar pagando por token/licença nas APIs
  comerciais atuais — custo variável, previsível, sem investimento inicial,
  mas sem tendência de queda garantida a longo prazo.

## 4. Dados & Restrições (o ponto mais crítico desta ideia)

- **Governança documentada hoje**: o [`README.md`](../../../README.md) e
  `docs/ai-governance/README.md` (não citados literalmente aqui, ver
  `intake.md`) declaram Microsoft Copilot e GitHub Enterprise Copilot como
  **ferramentas oficiais nomeadas**, com Claude/ChatGPT tratadas como
  "legadas" sob a mesma constituição. **Adotar Qwen (modelo) ou qualquer IDE
  agentic adicional como oficial exige mudança de política corporativa de
  IA, não apenas decisão técnica** — este é o maior risco/bloqueio real da
  ideia, maior que qualquer questão de custo ou engenharia.
- **Origem do modelo (Alibaba, empresa chinesa)**: mesmo com self-host
  mitigando o vazamento de dado (nenhum código trafega para servidor
  terceiro), a origem do peso do modelo/software pode exigir avaliação
  jurídica/compliance própria (ex.: restrições de uso de tecnologia de
  determinadas origens em contratos com clientes, políticas setoriais) —
  [NEEDS CLARIFICATION] não há posição de Jurídico/Compliance registrada
  sobre isso nesta pesquisa.
- **Relação direta com o SPEC 026 em andamento** (governança de uso do
  template / IP não sair da empresa): self-host de modelo aberto endereça
  bem esse objetivo (dado não sai para terceiro), o que é um ponto a favor
  desta ideia — mas é preciso alinhar as duas iniciativas para não haver
  política de IA divergente sendo construída em paralelo.

## Conclusão da pesquisa (sem julgar viabilidade — isso é do `/nc-assess-decide`)

A ideia tem uma **lacuna crítica de dado** (volume real de uso/custo atual) e
um **risco de governança maior do que o técnico** (mudar "ferramenta oficial
nomeada" para "processo oficial, ferramenta livre" mexe em política
corporativa de IA já publicada, e a origem do modelo Qwen é um ponto sensível
à parte). Tecnicamente, a hipótese de bloqueio original (Copilot não suporta
modelo customizado) **não se confirmou** — o BYOK existe, mas está em estágio
experimental para o cenário de agente autônomo que interessa ao Nimbus Code.

Recomenda-se seguir para `/nc-assess-define`, deixando claro que esta ideia
tem **dois problemas de dono diferente** (custo/técnico vs. governança
corporativa), e que a decisão final provavelmente não pode ser só do time de
engenharia.
