# Análise Comparativa: Impeccable & Claude Design (`frontend-design`) vs. Nimbus Code

Este documento apresenta a análise técnica que fundamentou a criação da skill institucional **`/nc-designer`**, comparando o projeto open-source **Impeccable (`pbakaus/impeccable`)** e a skill nativa da Anthropic **`frontend-design`** ("Claude Design") com a capacidade de design de interface incorporada ao Nimbus Code.

---

## 1. Visão Geral

### Impeccable (`pbakaus/impeccable`)
Um pacote de *design guidance* multi-agente (compatível com Claude Code, Cursor, Codex, GitHub Copilot, Grok Build, Gemini CLI, Hermes Agent, Veto, entre outros). Consiste em:
- **1 skill + 24 comandos** (`/impeccable init`, `craft`, `audit`, `critique`, `polish`, `bolder`, `quieter`, `harden`, `animate`, `live`, etc.).
- **Contexto persistente**: `PRODUCT.md` (verdades duráveis do produto: público, propósito, contexto operacional) e `DESIGN.md` (sistema de design incumbente ou recém-criado).
- **61 regras determinísticas** de detecção de "AI slop" (fontes genéricas, gradiente roxo-azul, cards aninhados etc.) executadas via CLI/binário próprio, sem custo de LLM.
- Instalador dedicado (`npx impeccable install`) que detecta o(s) agente(s) instalado(s) e aplica hooks nativos por provedor.

### Claude Design (skill nativa `frontend-design` da Anthropic)
Um único arquivo de instruções (`SKILL.md`, licença Apache 2.0) publicado por `anthropics` no repositório `skills` (pasta `skills/frontend-design`). Não é um comando, não tem CLI própria, não introduz arquivos de contexto — é puro **julgamento estético via prompt engineering**: instrui o modelo a agir como "diretor de design de um estúdio que nunca entrega o mesmo visual duas vezes", com um processo de *Plan (sistema de tokens) → Revisar contra o brief → Construir → Auto-crítica*, e uma lista calibrada dos "tells" mais comuns de UI gerada por IA (inclusive os tiques que o próprio Claude comete, como o par cor creme `#F4F1EA` + terracota `#D97757`).

### Nimbus Code (antes desta análise)
O Nimbus Code cobria arquitetura (`/nc-arch`), testes (`/nc-qa`) e segurança (`/nc-shield`) na Camada 2, mas **não possuía nenhuma skill institucional dedicada a julgamento estético/UX de interface** — a qualidade visual dependia inteiramente do "gosto" default do modelo por trás do agente executor.

---

## 2. Matriz Comparativa

| Dimensão | Impeccable | Claude Design (`frontend-design`) | Nimbus Code (`/nc-designer`) |
|---|---|---|---|
| **Formato** | Skill + CLI/binário próprio + 24 comandos | 1 arquivo de instruções (prompt puro) | 1 arquivo de instruções (`SKILL.md`), fonte única sincronizada nos 3 agentes |
| **Dependência de Runtime Externo** | Sim (binário próprio, `npx`/Node para instalar) | Não | Não (nenhuma dependência de terceiros — alinhado ao princípio de soberania de skill do preset) |
| **Portabilidade Multi-Agente** | Alta nativamente (Claude Code, Cursor, Codex, Copilot, Grok Build, Gemini CLI...) | Nula fora do ecossistema Claude/Anthropic (arquivo solto, sem mecanismo de instalação) | Alta — sincronizado para Copilot, Claude Code e Antigravity via `scripts/sync-nc-agents-to-integrations.sh`, igual às demais skills `/nc-*` |
| **Checklist Determinística Anti-"AI Slop"** | 61 regras, execução sem custo de LLM | Lista de "tells" descrita em prosa, sem execução automatizada | Checklist institucional incorporada ao `SKILL.md` (baseada nos "tells" documentados por ambos), aplicada via julgamento do próprio agente — sem binário externo |
| **Contexto Persistente de Produto** | `PRODUCT.md` + `DESIGN.md` dedicados | Nenhum (depende de memória/contexto da sessão) | Reaproveita `DESIGN.md` (se existir) e o `spec.md`/`plan.md` já produzidos pelo ciclo Nimbus Code — sem duplicar artefatos |
| **Modos de Operação** | 24 comandos especializados | Nenhum — um único fluxo de design | 5 modos institucionais (design completo, `audit`, `critique`, `polish`, `harden`) inspirados no vocabulário do Impeccable, mas sem CLI externa |
| **Qualidade Estética Observada** | Boa consistência entre PRs, mas resultado limitado pela qualidade do modelo por trás | Mais avançada na prática — calibrada especificamente para os vieses do próprio Claude | Herda o processo/checklist de ambos; a qualidade final ainda depende do modelo escolhido para a tarefa (S0–S4), mas ganha o mesmo rigor de processo |
| **Licenciamento / Origem** | Open-source, MIT-like (projeto de terceiros, `pbakaus/impeccable`) | Apache License 2.0 (Anthropic) | Obra derivada institucional (Apache 2.0 com atribuição), mantida como fonte única do preset `nimbus-code-standards` |

---

## 3. Conclusão e Decisão Institucional

- **Onde convergem**: Os dois projetos partem do mesmo diagnóstico — modelos de linguagem, sem direção estética explícita, convergem para os mesmos clichês visuais ("SaaS genérico"). Ambos combatem isso com uma lista de anti-padrões e um processo estruturado de plano → crítica.
- **Por que o Claude "pareceu" mais avançado**: parte da vantagem é de **modelo** (Claude Sonnet tem viés estético mais refinado, e a skill nativa foi calibrada especificamente contra os tiques do próprio Claude), e parte é de **foco** — um único arquivo de instruções direto ao ponto, sem a sobrecarga processual dos 24 comandos do Impeccable.
- **Decisão do Nimbus Code**: em vez de adotar uma dependência de terceiros (Impeccable, com seu binário/CLI própria) ou ficar restrito à skill nativa do Claude (não portável para Copilot/Antigravity), o Nimbus Code internalizou o melhor dos dois mundos como skill institucional própria — **`/nc-designer`** — mantendo a soberania de "fonte única" (`.github/skills/` sincronizado) e a total portabilidade multi-agente já estabelecida pelas demais skills `/nc-*`.

Ver a skill resultante em [`.github/skills/nc-designer/SKILL.md`](../../.github/skills/nc-designer/SKILL.md).
