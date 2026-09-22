# Intake de Assessment — Consolidação Corporativa de Harness Individuais (Claude/Cursor)

## Identificação

| Campo | Valor |
|---|---|
| **Slug** | `harness-consolidacao-corporativa` |
| **Data** | 2026-09-22 |
| **Origem** | Ideia informada diretamente pelo solicitante via `/nc-assess-intake` |
| **Tipo de entrada** | Texto livre |
| **Status** | Intake capturado — aguardando pesquisa |

## Ideia bruta

> "Existe algum modelo de copiar o HARNESS do CLAUDE para numa empresa não se
> perder o modelo de relacionamento do dev com os LLM, numa forma de fazer
> consolidação dos HARNESS, pra evoluirmos no NIMBUS CODE como o PROCESSO DE
> ENGENHARIA CORPORATIVA e os harness individuais serem consolidados de uma
> forma que possamos aprender com todos os 60 colaboradores. Isso poderia ser
> feito mesmo antes de todos os projetos usarem o NIMBUS CODE, poderíamos
> unificar todo os harness de todos os devs que usam CLAUDE e CURSOR."

## Problema ou oportunidade percebida

Cada desenvolvedor, ao usar assistentes de IA (Claude Code, Cursor, entre
outros), constrói ao longo do tempo um **relacionamento individual e tácito**
com o LLM: instruções personalizadas (`CLAUDE.md`, `.cursor/rules`,
custom instructions, memórias, prompts recorrentes, atalhos, convenções de
projeto informais). Esse conhecimento — aqui chamado de "harness individual" —
tende a:

- ficar preso à máquina/perfil de cada dev (não é versionado nem compartilhado);
- se perder quando o dev sai da empresa, troca de time ou de ferramenta;
- não alimentar aprendizado organizacional, mesmo quando resolve problemas
  recorrentes que outros colegas ainda enfrentam do zero;
- divergir do processo formal Nimbus Code, criando dois "cérebros" paralelos:
  o individual (informal, no editor de cada um) e o institucional (formal, em
  `docs/harness/`, `docs/playbooks/`, `docs/reuse-catalog.yaml`).

A oportunidade percebida é **consolidar os harness individuais dos ~60
colaboradores que já usam Claude e Cursor** — mesmo antes de todos os projetos
adotarem formalmente o Nimbus Code — como uma forma de acelerar e enriquecer o
próprio Nimbus Code enquanto **processo de engenharia corporativa**, e não
apenas como um template de projeto isolado.

Esta é uma hipótese inicial, não uma conclusão de valor ou viabilidade.

## Relação com artefatos já existentes no repositório (não redigir do zero)

O repositório já possui três mecanismos de memória organizacional que são
vizinhos diretos desta ideia e precisam ser considerados na pesquisa/definição
para evitar duplicidade:

| Artefato existente | O que já cobre | O que a ideia parece pedir a mais |
|---|---|---|
| `docs/harness/harness-catalog.yaml` + `docs/harness/harness-guide.md` | Catálogo institucional de **erros/incidentes por feature** (schema `HRN-NNNN`), consultado obrigatoriamente antes de `/nimbus-code-plan` | Não captura o **harness individual** (configs, prompts, regras pessoais) que cada dev usa no dia a dia com Claude/Cursor, independente de uma feature específica |
| `docs/playbooks/success-catalog.yaml` | Padrões e decisões que **funcionaram bem** (schema análogo, `SUC-NNNN`) | Também é por feature/decisão, não por relacionamento dev↔LLM |
| `docs/reuse-catalog.yaml` | Catálogo de **soluções técnicas reutilizáveis** (padrões de arquitetura/código) | Não trata de configuração de agente/harness em si |
| `specs/011-harness-engineering/` | Spec formal que originou os catálogos acima | Já define o conceito de "harness" no vocabulário Nimbus Code — a ideia nova propõe **estender esse conceito** para harness *individual/pessoal*, e não só organizacional-por-incidente |

Ou seja: a empresa já sabe consolidar "o que deu errado" e "o que funcionou bem"
por feature. O que ainda não existe é um mecanismo para consolidar **como cada
dev configurou seu próprio agente** (Claude Code / Cursor) — um nível abaixo,
mais pessoal e tácito, que hoje só existe na máquina/histórico de cada um.

## Público potencial

- os ~60 colaboradores que já usam Claude Code e/ou Cursor no dia a dia;
- squads/times que ainda não adotaram o Nimbus Code formalmente, mas já têm
  hábitos de uso de LLM que poderiam ser aproveitados;
- mantenedores do Nimbus Code (esquadrão Nimbus), como consumidores do
  conhecimento consolidado para evoluir presets, skills e catálogos;
- lideranças técnicas/engenharia, interessadas em reduzir perda de
  conhecimento tácito na saída/rotação de colaboradores.

## Resultado desejado inicialmente

Ter um mecanismo (processo + possivelmente ferramenta) que:

1. capture os harness individuais hoje dispersos (arquivos de configuração,
   regras, prompts recorrentes, convenções pessoais) de devs que usam Claude e
   Cursor;
2. normalize e consolide esse conteúdo em um formato institucional,
   reaproveitando ou estendendo os catálogos já existentes
   (`harness-catalog.yaml`, `success-catalog.yaml`, `reuse-catalog.yaml`) em
   vez de criar um quarto catálogo desconectado;
3. permita que esse aprendizado alimente a evolução do próprio Nimbus Code como
   processo de engenharia corporativa — funcionando mesmo em projetos que ainda
   não adotaram o Nimbus Code formalmente.

## Limites conhecidos

- Não está definido se a consolidação será manual (entrevistas, submissão
  voluntária) ou automatizada (varredura de arquivos de configuração locais,
  ex.: `CLAUDE.md`, `.cursor/rules`, histórico de prompts).
- Não está definido o nível de granularidade: harness por indivíduo, por time,
  ou por ferramenta (Claude vs. Cursor)?
- Há uma tensão explícita a resolver: capturar conhecimento tácito de devs sem
  violar privacidade, propriedade intelectual de terceiros ou políticas de uso
  de dados corporativos — especialmente se histórico de prompts contiver dados
  sensíveis, código proprietário de clientes ou credenciais.
- Não está definido se a consolidação é um evento único (fotografia atual dos
  60 harness) ou um processo contínuo (novo dev entra, harness é incorporado).
- Não está claro se o resultado consolidado deve virar: (a) atualização direta
  dos catálogos/presets do Nimbus Code, (b) um novo catálogo específico de
  "harness individual", ou (c) apenas insumo de pesquisa para futuras revisões
  do processo.
- A ideia assume que Claude e Cursor são as únicas ferramentas relevantes hoje;
  pode haver outras (VS Code Copilot, Antigravity, outras) já usadas pelos 60
  colaboradores que também guardam harness relevante.

## Perguntas em aberto

- Quantos dos ~60 colaboradores usam Claude Code, quantos usam Cursor, e há
  sobreposição/uso simultâneo das duas ferramentas?
- Onde fisicamente residem os harness individuais hoje (repositórios pessoais,
  dotfiles, `~/.claude/`, `.cursor/`, gists, notas soltas)? Existe algum
  levantamento prévio?
- Qual é o apetite da empresa para tornar esse levantamento **obrigatório**
  (parte do onboarding/offboarding) versus **voluntário** (opt-in)?
- Como equilibrar consolidação de conhecimento útil com risco de vazamento de
  dados sensíveis ou de clientes presentes em prompts/configurações pessoais?
- O resultado consolidado deve gerar mudanças diretas em
  `docs/harness/harness-catalog.yaml`, `docs/playbooks/success-catalog.yaml`,
  `docs/reuse-catalog.yaml`, nos presets (`presets/nimbus-code-standards/`),
  ou em um artefato novo e independente desses três?
- Existe um processo de retenção/expurgo já definido para dados de harness
  pessoal (ex.: quando alguém sai da empresa)?
- Como medir se a consolidação efetivamente acelerou onboarding, reduziu
  retrabalho ou melhorou a adoção do Nimbus Code nos projetos que ainda não o
  usam formalmente?
- Este esforço deveria ser conduzido como iniciativa pontual (assessment →
  spec → implementação de uma ferramenta/processo) ou como um novo item de
  processo recorrente dentro do próprio ciclo Nimbus Code (ex.: gate adicional
  em onboarding/offboarding)?

## Próximo handoff

Recomenda-se avaliar com o solicitante se o próximo passo é:

- `/nc-assess-research` — para investigar: (a) o que já existe de fato como
  harness individual entre os 60 colaboradores (levantamento leve), (b)
  práticas de mercado de consolidação de "prompt engineering" ou "agent
  configuration" corporativo, (c) riscos de privacidade/segurança envolvidos; ou
- `/nc-assess-define`, caso o solicitante já considere o problema e as
  restrições suficientemente claros para pular a etapa de pesquisa exploratória
  e ir direto para a formalização do problema, público e métricas.

Ambos os caminhos devem preservar e referenciar os artefatos institucionais já
existentes (`docs/harness/`, `docs/playbooks/success-catalog.yaml`,
`docs/reuse-catalog.yaml`, `specs/011-harness-engineering/`) para evitar
redesenhar do zero algo que a organização já resolveu parcialmente.
