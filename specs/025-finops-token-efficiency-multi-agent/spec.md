## Nimbus-Code — Cabeçalho Obrigatório da Spec

*Preencher ANTES dos critérios de aceitação. Alimenta o plan.md, o graph.yaml e
a seleção de modelo do agente.*

| Campo | Valor |
|---|---|
| **Feature slug** | `finops-token-efficiency-multi-agent` |
| **Complexidade estimada** | S3 *(cruza diretrizes e benchmarks para 3 ferramentas agenticas — VS Code Agent/Copilot, Antigravity e Claude Code —, matriz de modelos, telemetria FinOps e artefatos de governança)* |
| **Bounded Context** | `spec-kit-workflow` |
| **PR de referência / Issue** | novo |
| **Data alvo de entrega** | sem data |

> S0 = doc · S1 = função isolada · S2 = módulo · S3 = múltiplos módulos ·
> S4 = arquitetura, segurança, dados ou integração crítica

## Nimbus-Code — SLO Alvo desta Feature

*Preencher para componentes novos ou alterados. Alimenta o Observability Gate do
plan.md — alertas serão configurados com base nesses valores.*

| Componente | Latência p99 (ms) | Taxa de erro máx. (%) | Disponibilidade alvo | RTO | RPO |
|---|---|---|---|---|---|
| Script de auditoria de consumo/estimativa de tokens (`scripts/audit-agent-token-costs.sh`) | < 2000ms | 0% (falha no cálculo bloqueia CI/gate) | — | — | — |
| Matriz de benchmark e catalogação FinOps | — | 0% (inconsistência de métricas bloqueia PR) | — | — | — |

> Componentes são ferramentas de análise local e automação de governança de repositório, sem endpoint de runtime transacional em produção.

## Nimbus-Code — Objetivo e Contexto

**Objetivo:** Estabelecer uma especificação de **FinOps para Tokens de IA em Programação Agentica**, definindo:
1. Uma **matriz de benchmark comparativo** entre os três agentes suportados no Nimbus Code (**VS Code Agent / Copilot**, **Antigravity** e **Claude Code**) para avaliar eficiência de tokens (input, output, reasoning e cache) e tempo de resolução em tarefas padronizadas.
2. A validação formal de uma **estratégia de modelos econômicos e eficientes** (ex.: *Gemini 3.8 Flash*, *Claude 3.5 Haiku*, *GPT-5.6 Luna/mini*) como camada padrão para tarefas S0–S2, reservando modelos de alto raciocínio (Sonnet, Opus, Pro, reasoning pesado) exclusivamente para S3/S4.
3. Um **catálogo normativo de melhores práticas e guardrails operacionais** específicos para cada uma das três ferramentas, erradicando os principais causadores de desperdício de tokens (loops de tool calling, leituras cegas de diretórios/arquivos gigantes, reescritas integrais desnecessárias e perda de prompt caching).

**Motivação:** A adoção de fluxos multi-agente introduzida pela SPEC 024 trouxe liberdade de escolha entre Copilot, Claude Code e Antigravity. No entanto, programadores e agentes autônomos operando sem restrições de FinOps geram explosão de custos:
- Agentes lendo arquivos inteiros de milhares de linhas quando um `grep_search` ou leitura pontual bastaria;
- Loops iterativos de ferramentas sem condição de parada inteligente (tentativas cegas de correção de erros);
- Falta de aproveitamento de *Prompt Caching* / *Prefix Caching*, reenviando o contexto completo a cada iteração;
- Uso injustificado de modelos de última geração de alto custo (Opus/Sonnet/Pro) para tarefas mecânicas ou de documentação (S0/S1).

**Critério de done (alto nível):** 
- Matriz de benchmark publicada com protocolo reproduzível de testes em cenários S0, S1 e S2 para os 3 agentes;
- Tabela oficial de seleção de modelos econômicos vs. capacidade por complexidade S0–S4;
- Guia de boas práticas e anti-padrões de tokens implementado em `docs/finops-agentic-tokens-guide.md` com seções dedicadas para VS Code Agent, Antigravity e Claude Code;
- Script utilitário de auditoria/cálculo de consumo e estimativa de tokens (`scripts/audit-agent-token-costs.sh`) com cobertura de testes automatizados;
- Integração das métricas de tokens no checklist de fechamento de tarefas do Nimbus Code (`tasks.md`).

## Nimbus-Code — Hybrid Collaboration Model

| Papel | Responsabilidades | Critério de handoff | Escalação |
|---|---|---|---|
| Agente | Executar suítes de benchmark padronizadas; medir consumo real de tokens (input/output/cache); documentar regras de mitigação de anti-padrões para cada CLI/IDE; implementar scripts de verificação de limites. | Quando o custo estimado de uma tarefa ultrapassar o teto estipulado para o seu nível (ex.: > 50k tokens em S1) — pausar e requerer aprovação humana. | Tech Lead / FinOps Champion |
| Humano | Definir e revisar orçamentos por squad/projeto; homologar quais modelos são permitidos pelas políticas corporativas; auditar desvios reportados pelo script de telemetria; validar exceções para uso de modelos Tier S4. | Validação dos thresholds de tolerância de tokens e aprovação de novos modelos na tabela oficial. | Engineering Manager / FinOps Lead |

## Nimbus-Code — Critérios de Aceitação (formato BDD)

> **AC-1: Matriz de Benchmark Comparativo Multi-Agente**
> **Given** os três ambientes configurados (VS Code Agent / Copilot, Antigravity e Claude Code)
> **When** o protocolo de benchmark padronizado é executado sobre tarefas representativas das classes S0 (documentação), S1 (função isolada) e S2 (módulo com testes)
> **Then** a matriz registra: total de tokens de input, tokens de output, tokens servidos por cache, número de tool calls e tempo decorrido, permitindo comparação direta de eficiência de tokens entre as três ferramentas
> **Test ref:** `test_AC1_multi_agent_benchmark_matrix_published`

> **AC-2: Validação e Tiering de Modelos Custo-Eficientes (Workhorse Models)**
> **Given** a tabela de seleção de modelos por complexidade S0–S4
> **When** avaliados os modelos eficientes de entrada (ex.: Gemini 3.8 Flash no Antigravity, Claude Haiku no Claude Code, GPT-mini/Luna no Copilot) em tarefas S0–S2
> **Then** a especificação valida que esses modelos atingem 100% de assertividade funcional com redução mínima de 60% no consumo financeiro/tokens ponderados em relação aos modelos de reasoning topo de linha (Sonnet/Pro/Opus)
> **Test ref:** `test_AC2_workhorse_model_cost_efficiency_validated`

> **AC-3: Guardrails Anti-Desperdício para VS Code Agent (Copilot)**
> **Given** o uso do VS Code Agent / GitHub Copilot no ambiente de desenvolvimento
> **When** o desenvolvedor ou automação interage com o agente
> **Then** as diretrizes estabelecem e comprovam: (1) escopo cirúrgico com `@workspace` e `#file` apenas para referências necessárias; (2) proibição de reescrita total de arquivos grandes em prol de edições pontuais; (3) otimização do `.github/copilot-instructions.md` para ser conciso e focado em governança sem inflar o prompt de sistema
> **Test ref:** `test_AC3_vscode_copilot_token_guardrails_documented`

> **AC-4: Guardrails Anti-Desperdício para Google Antigravity**
> **Given** o uso do Google Antigravity como plataforma agentica
> **When** o agente executa tarefas no repositório
> **Then** as diretrizes estabelecem e comprovam: (1) uso mandatório de `grep_search` e `find_by_name` antes de `view_file` para evitar ler arquivos desnecessários; (2) uso de paginação (`StartLine`/`EndLine`) no `view_file` restringindo chunks a no máximo 800 linhas; (3) adoção de `replace_file_content` para diffs cirúrgicos em vez de `write_to_file` com overwrite completo; (4) controle de invocação de subagentes para evitar proliferação de contextos concorrentes; (5) aproveitamento do Planning Mode estruturado para evitar loops exploratórios cegos
> **Test ref:** `test_AC4_antigravity_token_guardrails_documented`

> **AC-5: Guardrails Anti-Desperdício para Claude Code**
> **Given** o uso do Claude Code via CLI
> **When** sessões de codificação interativas ou headless são iniciadas
> **Then** as diretrizes estabelecem e comprovam: (1) aproveitamento de *Prompt Caching* mantendo arquivos estáticos e contexto de sistema no topo da sessão; (2) uso obrigatório do comando `/compact` após blocos de execução extensos; (3) filtragem de comandos bash ruidosos (usando pipes como `head`, `tail`, `grep -c`) para evitar cuspir milhares de tokens na janela de contexto; (4) restrição do loop de auto-iteração para no máximo 5 tentativas antes de requerer input humano
> **Test ref:** `test_AC5_claude_code_token_guardrails_documented`

> **AC-6: Ferramenta e Checklist de Auditoria FinOps de Tokens no Repositório**
> **Given** uma tarefa sendo finalizada no ciclo de desenvolvimento Nimbus Code
> **When** o desenvolvedor ou agente preenche o fechamento em `tasks.md`
> **Then** o script `scripts/audit-agent-token-costs.sh` calcula a estimativa e o consumo real de tokens com base nos logs/transcrições disponíveis, compara contra a tabela de limites aceitáveis por nível S0–S4 e emite alerta caso haja desvio superior a 30% em relação ao planejado
> **Test ref:** `test_AC6_token_audit_tool_and_checklist_functional`

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Desenvolvedor utiliza modelo econômico (Workhorse) sem perda de qualidade (Priority: P1)

Um engenheiro de software precisa gerar funções auxiliares, documentação técnica e testes unitários (tarefas S0 e S1) e deseja usar um modelo de baixo custo sem queimar o orçamento mensal de tokens do projeto.

**Why this priority**: Tarefas S0 e S1 representam entre 50% e 70% de todo o volume de requisições de um time. Garantir o uso de modelos econômicos (ex.: Gemini Flash, Haiku, GPT-mini) gera impacto imediato de redução de custos.

**Independent Test**: Executar uma tarefa de geração de teste unitário e documentação nos três agentes alternando entre o modelo Tier Econômico e o Tier Reasoning. Validar que o resultado funcional é equivalente e que o consumo ponderado de tokens/custo é pelo menos 60% menor no tier econômico.

**Acceptance Scenarios**:
1. **Given** uma tarefa classificada como S1, **When** o dev seleciona o modelo econômico recomendado pelo guia FinOps, **Then** a tarefa é concluída com sucesso e o total de tokens faturados fica dentro do limiar S1 (< 10k tokens).
2. **Given** um agente tentando usar um modelo de classe S4 para uma tarefa S0/S1, **When** as regras de governança são avaliadas, **Then** o sistema alerta o desvio de modelo sugerindo downgrade para o tier econômico.

---

### User Story 2 - Tech Lead / FinOps Officer compara a eficiência entre os 3 agentes (Priority: P2)

O Tech Lead quer entender qual das três ferramentas (VS Code Agent, Antigravity, Claude Code) é mais eficiente para diferentes tipos de tarefa (refatoração, arquitetura, testes, exploração) para recomendar a melhor ferramenta por caso de uso.

**Why this priority**: Com a SPEC 024 implementada, a organização precisa de dados empíricos e mensuráveis para nortear o uso inteligente de licenças e cotas de API.

**Independent Test**: Submeter o mesmo cenário de refatoração modular (S2) aos 3 agentes e extrair o relatório de tokens de entrada, saída, chamadas de ferramenta e cache hits.

**Acceptance Scenarios**:
1. **Given** a execução da mesma suíte de tarefas padrão nos 3 agentes, **When** os logs de execução são processados pelo script de benchmark, **Then** uma tabela consolidada compara os três agentes em: tokens brutos consumidos, aproveitamento de cache de prompt, número de requisições de ferramentas e custo financeiro estimado.
2. **Given** os dados de benchmark consolidados, **When** o Tech Lead consulta o guia, **Then** encontra uma matriz de decisão clara indicando qual ferramenta usar para cada perfil de tarefa.

---

### User Story 3 - Squad detecta e bloqueia vazamento de tokens em sessões longas (Priority: P3)

Um agente ou dev entra em um loop interativo de debugging onde o contexto se estende por mais de 50 turnos de conversa, consumindo centenas de milhares de tokens repetidamente.

**Why this priority**: Sessões longas degradadas são responsáveis pelos maiores picos de desperdício em programação agentica devido ao efeito cumulativo da janela de contexto.

**Independent Test**: Simular uma sessão longa com contexto ruidoso e verificar se as diretrizes e ferramentas indicam o momento exato de truncamento, compactação (`/compact`) ou encerramento da sessão em favor de um novo subagente/conversa limpa.

**Acceptance Scenarios**:
1. **Given** uma sessão que ultrapassa 50k tokens de histórico acumulado, **When** o agente executa a próxima tool call, **Then** o guia orienta a compactação imediata do histórico ou criação de um novo thread limpo com apenas os artefatos de estado consolidados.
2. **Given** uma ferramenta que falha 3 vezes seguidas no mesmo arquivo, **When** o agente atinge o limite do guardrail, **Then** ele para a iteração automática e pede intervenção humana em vez de queimar tokens em tentativas infrutíferas.

---

### Edge Cases

- **Grandes volumes de logs em falhas de compilação/teste**: Quando um comando de teste cospe milhares de linhas de erro no terminal, o agente não deve ler todo o stdout; o comando deve ser encapsulado com filtros ou truncado nas primeiras 50 linhas relevantes.
- **Incompatibilidade de contagem de tokens entre provedores**: Provedores usam tokenizadores distintos (tiktoken da OpenAI vs SentencePiece/Gemini vs Anthropic tokenizer). O framework de benchmark deve normalizar métricas em Tokens Totais e Custo Financeiro Normalizado (USD / R$) conforme taxa padrão de `docs/cost-profiles-and-rates.md`.
- **Cache Invalidation acidental**: Alterações em linhas iniciais de prompts ou comentários de topo que invalidam o prefix cache do Claude ou Gemini devem ser alertadas como anti-padrão no guia.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema MUST fornecer um protocolo reproduzível de benchmark de tokens para avaliar VS Code Agent, Antigravity e Claude Code sob as mesmas tarefas padronizadas (S0, S1, S2).
- **FR-002**: O sistema MUST definir a matriz de modelos recomendados por nível de complexidade, definindo explicitamente o "Modelo Econômico Padrão" (Workhorse) para S0–S2 e "Modelo de Reasoning Estrito" para S3–S4 em cada agente.
- **FR-003**: O sistema MUST documentar em `docs/finops-agentic-tokens-guide.md` o catálogo de anti-padrões de tokens e o conjunto de guardrails técnicos específicos para:
  - GitHub Copilot / VS Code Agent;
  - Google Antigravity;
  - Anthropic Claude Code.
- **FR-004**: O sistema MUST implementar um script executável `scripts/audit-agent-token-costs.sh` capaz de calcular e validar estimativas de tokens e custos de tarefas, comparando-as com os limites da política FinOps corporativa.
- **FR-005**: O sistema MUST incluir testes automatizados em Bats para o script de auditoria FinOps (`tests/finops/audit-agent-token-costs.bats`), garantindo cálculo confiável e tratamento de erros.
- **FR-006**: O sistema MUST integrar o checklist de verificação de tokens ao template padrão de tarefas (`presets/nimbus-code-standards/templates/tasks-template.md`), tornando obrigatório o registro do modelo utilizado e a declaração de desvio caso o consumo exceda o previsto.
- **FR-007**: O sistema MUST fornecer recomendações explícitas sobre técnicas de conservação de contexto, incluindo Prompt Caching, limites de paginação de leitura de arquivos, diffs cirúrgicos e supressão de saídas ruidosas de terminal.

### Key Entities

- **TokenBenchmarkMatrix**: Tabela estruturada contendo as medições comparativas (Input, Output, Cache, Latência, Tool Calls, Custo) dos 3 agentes para cada arquétipo de tarefa.
- **ModelTierPolicy**: Regra normativa que mapeia níveis S0–S4 para os modelos correspondentes em cada ecossistema (OpenAI/Copilot, Google/Gemini, Anthropic/Claude).
- **FinOpsGuardrail**: Regra prescritiva que define o comportamento esperado do agente para impedir desperdício de tokens (ex.: paginação de arquivos, diffs pontuais, compactação de contexto).
- **TaskTokenAuditRecord**: Registro gerado no encerramento de cada tarefa comparando tokens planejados vs. tokens consumidos.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Redução comprovada de pelo menos **60% no custo financeiro** de execução de tarefas S0–S2 ao adotar os modelos Tier Econômico (ex.: Gemini Flash / Claude Haiku / GPT-mini) validados na spec em comparação com os modelos de raciocínio máximo.
- **SC-002**: Eliminação de 100% dos casos de leitura cega de arquivos inteiros superiores a 800 linhas nas instruções do Antigravity e Claude Code, mediante uso mandatório de paginação ou `grep_search`.
- **SC-003**: Aproveitamento comprovado de **Prompt Caching** acima de **70%** em sessões multi-turn no Claude Code e Antigravity através do correto posicionamento de instruções estáticas.
- **SC-004**: 100% dos 3 agentes (VS Code Agent, Antigravity, Claude Code) com guias operacionais dedicados e anti-padrões mapeados em documentação oficial versionada.

## Assumptions

- Os desenvolvedores têm acesso a pelo menos um dos três agentes com telemetria visível de tokens (via console, status bar, token counter ou logs de API).
- A tabela de custos e taxas base de `docs/cost-profiles-and-rates.md` e `docs/ai-code-quality-and-observability.md` serve como referência primária de unit economics do repositório.
- A validação de modelos eficientes não degrada a taxa de aprovação dos testes de conformidade técnica do Nimbus Code.
