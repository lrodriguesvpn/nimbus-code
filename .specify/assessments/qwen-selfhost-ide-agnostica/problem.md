# Problem — Qwen (self-hosted) e IDE Agentic Agnóstica

**Slug**: `qwen-selfhost-ide-agnostica`
**Data**: 2026-09-21
**Agente**: NC-Assess-Define
**Baseado em**: `intake.md`, `research.md`

---

## Declaração do Problema

A política de IA da empresa hoje nomeia **ferramenta e fornecedor
específicos** (Microsoft Copilot / GitHub Enterprise Copilot) como oficiais,
em vez de nomear o **processo de desenvolvimento assistido por IA** (Nimbus
Code) como o padrão obrigatório. Isso gera dois problemas concretos, ligados
mas distintos:

1. **Rigidez de custo e soberania de modelo**: toda a codificação assistida
   por IA depende hoje de modelos comerciais acessados via API de
   fornecedores externos (Microsoft/GitHub, Anthropic). Não existe, hoje,
   uma opção institucionalmente reconhecida de usar um modelo aberto
   (ex.: Qwen-Coder) rodando em infraestrutura própria — o que deixa a
   empresa sem alternativa de controle de custo em alto volume e sem opção
   de manter 100% do processamento de código dentro do próprio perímetro de
   nuvem, mesmo quando isso seria tecnicamente possível.
2. **Rigidez de política de ferramenta**: ao nomear uma ferramenta específica
   como "oficial", a governança acopla a validade do processo Nimbus Code
   (gates, agentes, fluxo SDD) à sobrevivência/disponibilidade de um único
   fornecedor. Se o Dev/time quiser usar Claude Code, Antigravity, Qwen Code
   ou qualquer outra IDE agentic que já suporte o mesmo processo — como a
   arquitetura técnica já permite via `nc-agent-sync.py` — a política escrita
   hoje não reconhece isso como legítimo, criando desalinhamento entre o que
   a arquitetura já faz e o que a norma escrita permite.

**Por que agora**: a arquitetura de projeção multi-agente já foi construída e
já opera para 3 alvos (VS Code, Claude Code, Antigravity) sem que a política
tenha acompanhado essa evolução. Além disso, a pesquisa mostrou que o VS Code
já suporta endpoint de modelo customizado (BYOK), tornando a barreira técnica
para usar um modelo self-hosted menor do que se supunha — o que torna a
questão de política, e não de engenharia, o gargalo real a resolver agora.

## Usuários e Stakeholders

| Papel | Como é impactado |
|---|---|
| **Devs que usam o Nimbus Code** | Hoje presos à ferramenta nomeada; não podem oficialmente usar outra IDE agentic mesmo que ela suporte o mesmo processo, nem trocar o modelo por um self-hosted mesmo quando tecnicamente viável. |
| **Liderança de Engenharia / Dono do Nimbus Code** | Precisa decidir se o padrão institucional deve travar em ferramenta ou em processo — decisão que afeta toda a estratégia de adoção multi-IDE já iniciada tecnicamente. |
| **Segurança / Compliance / DPO** | Donos reais da decisão sobre origem de modelo (Qwen é de origem chinesa/Alibaba) e sobre onde o código da empresa pode trafegar — sem aval deles, nenhuma mudança de política pode avançar, independente da vontade técnica. |
| **Jurídico** | Precisa avaliar se usar pesos de modelo de determinadas origens impõe restrição contratual/regulatória, mesmo com self-host mitigando vazamento de dado. |
| **FinOps / área responsável por custo de nuvem** | Precisa validar se o investimento em GPU dedicada 24/7 se paga frente ao consumo real de API hoje — dado que ainda não existe (identificado como lacuna na pesquisa). |

## Metas (o que sucesso parece)

- Uma política de IA revisada que declare **o processo Nimbus Code** (não uma
  ferramenta/fornecedor específico) como o padrão obrigatório, com critérios
  objetivos e verificáveis para qualquer IDE agentic ser aceita (ex.: suporta
  o esquadrão de agentes NC-*, os gates de segurança, o fluxo SDD).
- Uma decisão explícita e documentada (aprovada por Segurança/Jurídico/DPO)
  sobre se modelos abertos de origem sensível (como Qwen) podem ser usados
  self-hosted dentro do perímetro da empresa, e sob quais condições.
- Se aprovado, um caminho técnico validado (piloto) para conectar um modelo
  self-hosted via BYOK/endpoint customizado ao fluxo de agentes já existente,
  sem precisar reconstruir a arquitetura de projeção multi-agente do zero.

## Anti-metas (fora do escopo desta ideia)

- Não é objetivo desta ideia migrar todos os devs para Qwen Code ou abandonar
  o Copilot — é sobre **abrir a política**, não substituir a ferramenta atual
  por decreto.
- Não é objetivo desta ideia decidir a arquitetura final de hospedagem de GPU
  (qual nuvem, qual SKU) — isso é detalhe de implementação, tratado depois de
  uma decisão de política favorável.
- Não é objetivo avaliar Cursor.ai a fundo neste ciclo (foi citado como
  exemplo, não como alvo primário) — pode virar uma ideia separada se a
  política de "processo oficial, ferramenta livre" for aprovada.

## Métricas de Sucesso (o que mediríamos, se aprovado)

- [ASSUMPTION] Custo de API de codificação assistida por dev/mês (linha de
  base hoje inexistente — precisa ser levantado antes de qualquer piloto).
- Existência de um critério de aceitação formal e publicado para "IDE agentic
  compatível com o processo Nimbus Code" (sim/não, hoje não existe).
- Parecer formal de Segurança/Jurídico/DPO sobre uso de modelo Qwen
  self-hosted (aprovado / aprovado com condições / reprovado).
- Se houver piloto: comparação de qualidade de código gerado (self-hosted vs.
  modelo comercial atual) em tarefas reais do Nimbus Code, não apenas
  benchmark público.

## Próximo passo recomendado

Avançar para `/nc-assess-shape` para explorar as opções de solução (desde
"não fazer nada agora, revisitar quando houver dado de custo" até "abrir
política + rodar piloto controlado de BYOK com Qwen self-hosted em ambiente
isolado") e seus respectivos apetites de esforço.
