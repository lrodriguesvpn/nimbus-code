# Intake — Qwen (self-hosted) e IDE Agentic Agnóstica

**Slug**: `qwen-selfhost-ide-agnostica`
**Data**: 2026-09-21
**Origem da ideia**: Conversa direta com o Dev (chat, sem link/ticket externo).
**Agente**: NC-Assess-Intake

---

## O que é a ideia (como o Dev descreveu)

A ideia tem dois componentes que o próprio Dev trouxe como uma coisa só, mas
que são duas hipóteses distintas — registradas aqui juntas, a separação em
eixos independentes fica para `/nc-assess-research` e `/nc-assess-define`:

1. **Modelo Qwen self-hosted (custo)**: usar os modelos abertos da família
   Qwen (ex.: Qwen-Coder) rodando em infraestrutura de nuvem própria da
   empresa — **não** via API pública da Alibaba — como alternativa de menor
   custo variável às APIs comerciais atualmente usadas (Copilot/Claude/etc.)
   para tarefas de codificação assistida por IA.

2. **Mudança de política de "ferramenta oficial" (governança)**: hoje o
   `README.md` e `docs/ai-governance/README.md` declaram Microsoft Copilot e
   GitHub Enterprise Copilot como as ferramentas oficiais de IA da empresa. O
   Dev propõe inverter esse eixo: **o oficial passa a ser o processo Nimbus
   Code** (o esquadrão de agentes, os gates de qualidade/segurança, o fluxo
   SDD) — e a IDE agentic usada no dia a dia (VS Code/Copilot, Claude Code,
   Antigravity, Qwen Code, Cursor.ai, ou outra) deixaria de ser prescrita por
   nome/fornecedor, desde que suporte esse processo.

## Contexto adicional levantado na conversa (não confirmado, precisa validar)

- O Nimbus Code já tem um mecanismo técnico de projeção multi-agente
  ([`scripts/lib/nc-agent-sync.py`](../../../scripts/lib/nc-agent-sync.py))
  que gera o mesmo esquadrão de 15 agentes NC-* a partir de uma única fonte
  para VS Code, Claude Code e Antigravity — ou seja, parte da arquitetura já
  é agnóstica de ferramenta hoje, mesmo a política documentada não sendo.
- Hipótese levantada (não verificada): o **GitHub Copilot Agent no VS Code
  hoje não permite apontar para um endpoint de modelo self-hosted arbitrário**
  (BYOM) — ele usa os modelos disponibilizados pela própria plataforma
  GitHub/Microsoft. Se confirmado, "rodar Qwen dentro do Copilot Agent"
  seria tecnicamente inviável hoje; a alternativa equivalente seria usar o
  **Qwen Code CLI** (ou outra IDE agentic com suporte a endpoint customizado)
  em paralelo/substituição ao Copilot dentro do mesmo VS Code.
- Modelos Qwen-Coder abertos têm reputação de qualidade competitiva em
  tarefas de código; ordem de grandeza de custo de GPU para servir isso 24/7
  em nuvem própria não foi validada com números reais da empresa — só
  estimativa qualitativa em conversa.
- Já existe menção anterior (SPEC 026, ainda em andamento) sobre
  preocupação institucional com **IP não sair da empresa** — o self-host de
  modelo aberto endereça diretamente esse ponto (nenhum dado de código
  trafega para terceiro, nem Alibaba nem outro fornecedor de API).

## Dúvidas / lacunas já observadas nesta captura

- Não há dado real de volume de uso (tokens/mês, número de devs ativos) para
  estimar breakeven de custo entre API paga por token vs. GPU dedicada
  self-hosted.
- Não está confirmado se GitHub Copilot Agent aceita BYOM hoje ou em roadmap
  anunciado — precisa de pesquisa técnica dedicada.
- Não está confirmado se Qwen Code (CLI) tem paridade de recursos
  (subagentes, MCP, formato de agente/skill) suficiente para reaproveitar o
  mecanismo de projeção já existente no Nimbus Code sem retrabalho grande.
- A mudança de política de "ferramenta oficial nomeada" para "processo
  oficial, ferramenta livre" é uma decisão de governança corporativa de IA
  (mexe em `docs/ai-governance/README.md`), não uma decisão de engenharia —
  precisa de dono/aprovação fora do escopo técnico (provável: liderança de
  Segurança/Compliance, já envolvida na discussão do SPEC 026).
- Origem do modelo (Alibaba, empresa chinesa) é um ponto sensível à parte,
  mesmo com self-host mitigando o vazamento de dado — pode exigir avaliação
  jurídica/compliance independente da arquitetura técnica escolhida.

## Próximo passo recomendado

Avançar para `/nc-assess-research` (ou `/speckit-assess-research`) tratando
os dois eixos citados acima como **linhas de pesquisa separadas**:
1. Viabilidade técnica e de custo do self-host de Qwen-Coder (ou modelo
   aberto equivalente) em nuvem própria.
2. Viabilidade de governança da mudança de política "ferramenta oficial
   nomeada" → "processo Nimbus Code oficial, IDE agentic livre".
