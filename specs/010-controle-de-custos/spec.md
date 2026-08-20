# Feature Specification: Controle de Custos

**Feature Branch**: `010-controle-de-custos`

**Created**: 2026-08-18

**Status**: Draft

**Input**: User description: "Controle de Custos"

## Nimbus-Code — Cabeçalho Obrigatório da Spec

*Preencher ANTES dos critérios de aceitação. Alimenta o plan.md, o graph.yaml e
a seleção de modelo do agente.*

| Campo | Valor |
|---|---|
| **Feature slug** | `controle-de-custos` |
| **Complexidade estimada** | S3 |
| **Bounded Context** | FinOps & Developer Experience |
| **PR de referência / Issue** | novo |
| **Data alvo de entrega** | sem data |

> S0 = doc · S1 = função isolada · S2 = módulo · S3 = múltiplos módulos ·
> S4 = arquitetura, segurança, dados ou integração crítica

## Nimbus-Code — SLO Alvo desta Feature

*Preencher para componentes novos ou alterados. Alimenta o Observability Gate do
plan.md — alertas serão configurados com base nesses valores.*

| Componente | Latência p99 (ms) | Taxa de erro máx. (%) | Disponibilidade alvo | RTO | RPO |
|---|---|---|---|---|---|
| Dashboard de custos (leitura) | 800 | 0,5% | 99,5% | 1 h | 24 h |
| Coleta e agregação de métricas de custo | 3000 | 1,0% | 99,0% | 4 h | 1 h |
| Alertas de orçamento | — | 1,0% | 99,5% | 30 min | — |

> Deixar vazio (`—`) apenas se o componente não expõe SLO mensurável (ex.: job
> batch interno sem SLA contratual). Omissão sem justificativa é tratada como
> "não definido" — o Observability Gate bloqueará o plan.md.

## Nimbus-Code — Objetivo e Contexto

**Objetivo:** implementar um sistema de controle de custos que consolide, rastreie
e exiba o custo combinado do modelo híbrido (tokens de IA + horas humanas +
recursos de nuvem), permitindo governança financeira ao longo do ciclo de vida
de features e projetos.

**Motivação:** o modelo de desenvolvimento híbrido (agentes + humanos) gera custos
em múltiplas dimensões — consumo de tokens, horas de trabalho humano e recursos
de infraestrutura provisionados. Hoje esses dados ficam em silos separados
(GitHub Project, logs do modelo, planilhas manuais), dificultando decisões de
priorização, estimativas futuras e prestação de contas. Um sistema centralizado
de controle de custos é pré-requisito para operar o modelo híbrido em escala.

**Critério de done (alto nível):** engenheiros e gestores conseguem visualizar,
em um único lugar, o custo real por feature/sprint/projeto e comparar com a
estimativa registrada no `plan.md`, com alertas automáticos quando um orçamento
pré-definido é atingido.

## Nimbus-Code — Critérios de Aceitação (formato BDD)

*Todo critério de aceitação deve estar no formato Given/When/Then para permitir
rastreabilidade direta com testes de integração. Cada item recebe um ID único
(AC-N) que será referenciado no `tasks.md` e nos testes.*

> **AC-1**
> **Given** uma feature com estimativa de tokens e horas humanas registrada no `plan.md`
> **When** a feature for concluída e os dados de consumo real forem coletados
> **Then** o sistema exibe o custo real vs. estimado com variação percentual por feature
> **Test ref:** `test_AC1_custo_real_vs_estimado`

> **AC-2**
> **Given** um orçamento de sprint ou projeto configurado no sistema
> **When** o consumo acumulado atingir 80% do limite definido
> **Then** um alerta é disparado para o responsável antes de estourar o budget
> **Test ref:** `test_AC2_alerta_orcamento_80pct`

> **AC-3**
> **Given** dados de custo coletados de múltiplas fontes (tokens, horas humanas, nuvem)
> **When** o gestor acessar o dashboard de controle de custos
> **Then** o custo total combinado é apresentado de forma consolidada, com drill-down por dimensão
> **Test ref:** `test_AC3_dashboard_consolidado`

> **AC-4**
> **Given** um novo projeto inicializado com os templates do Spec Kit
> **When** os artefatos forem criados
> **Then** o template de `plan.md` inclui campos obrigatórios de estimativa de custo (tokens + horas humanas) que alimentam o sistema de controle
> **Test ref:** `test_AC4_campos_estimativa_no_template`

> **AC-5**
> **Given** histórico de custo de features anteriores disponível no sistema
> **When** um agente ou humano iniciar o planejamento de uma nova feature
> **Then** o sistema exibe benchmarks de custo de features similares para calibrar estimativas
> **Test ref:** `test_AC5_benchmarks_historicos`

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Visualizar custo real vs. estimado por feature (Priority: P1)

Como gestor de engenharia, quero comparar o custo real (tokens consumidos + horas
humanas lançadas) com a estimativa registrada no `plan.md` de cada feature para
identificar desvios e calibrar estimativas futuras.

**Why this priority**: É a funcionalidade central do controle de custos; sem ela,
todo o rastreio financeiro fica sem valor de gestão.

**Independent Test**: Selecionar uma feature finalizada, registrar manualmente a
estimativa e o consumo real, e confirmar que o sistema exibe a variação
corretamente.

**Acceptance Scenarios**:

1. **Given** uma feature com estimativa de tokens `~20k` e horas humanas `4h`, **When** o consumo real for coletado ao fechar a feature, **Then** o dashboard exibe custo estimado, custo real e variação percentual lado a lado.
2. **Given** uma feature sem estimativa registrada, **When** o custo real for coletado, **Then** o sistema sinaliza a ausência de estimativa como não-conformidade rastreável.

---

### User Story 2 - Receber alertas antes de estourar o orçamento (Priority: P1)

Como Tech Lead responsável por um projeto, quero ser notificado automaticamente
quando o consumo de custos atingir 80% do orçamento definido para o sprint ou
projeto, para agir antes do estouro.

**Why this priority**: Alertas preventivos evitam surpresas financeiras e permitem
repriorização a tempo.

**Independent Test**: Definir um orçamento de teste baixo, gerar consumo simulado
e confirmar que o alerta é disparado no momento correto.

**Acceptance Scenarios**:

1. **Given** orçamento de sprint configurado em R$ 1.000, **When** o consumo acumulado atingir R$ 800, **Then** o responsável recebe notificação com breakdown do consumo até o momento.
2. **Given** orçamento estourado sem alerta prévio, **When** o sistema detectar o estouro retroativamente, **Then** um alerta de estouro é enviado imediatamente com severidade elevada.

---

### User Story 3 - Consultar dashboard consolidado de custos (Priority: P1)

Como gestor ou diretor de engenharia, quero um painel único que consolide custos
de tokens, horas humanas e recursos de nuvem por projeto, squad ou período, para
ter visibilidade completa do gasto de IA + humanos.

**Why this priority**: Decisões de escala do modelo híbrido dependem de visibilidade
consolidada — sem isso, os dados ficam em silos e não geram insight acionável.

**Independent Test**: Acessar o dashboard e verificar que custos de pelo menos
duas dimensões (ex.: tokens + horas humanas) aparecem consolidados num único
painel com filtros funcionais.

**Acceptance Scenarios**:

1. **Given** dados de custo de múltiplas fontes disponíveis, **When** o gestor acessar o dashboard, **Then** ele vê custo total por feature, por sprint e por squad com drill-down por dimensão.
2. **Given** filtro de período aplicado, **When** o usuário selecionar "último mês", **Then** apenas dados do período aparecem, com total recalculado corretamente.

---

### User Story 4 - Estimar custo de novas features com base em histórico (Priority: P2)

Como agente ou humano planejando uma nova feature, quero visualizar benchmarks de
custo de features anteriores similares para calibrar a estimativa de tokens e
horas humanas no `plan.md`.

**Why this priority**: Estimativas baseadas em dados históricos reduzem a variância
real vs. estimado e melhoram a previsibilidade do modelo híbrido ao longo do tempo.

**Independent Test**: Acessar a consulta de benchmarks, selecionar uma feature
de complexidade similar a uma nova feature e confirmar que os dados históricos
são exibidos de forma utilizável.

**Acceptance Scenarios**:

1. **Given** histórico de pelo menos 3 features com complexidade S2 concluídas, **When** iniciar o planejamento de uma nova feature S2, **Then** o sistema sugere faixas de estimativa de tokens e horas humanas baseadas nas médias históricas.
2. **Given** features de diferentes complexidades (S1 a S3) no histórico, **When** filtrar por complexidade, **Then** os benchmarks exibidos correspondem somente ao nível selecionado.

---

### User Story 5 - Registrar horas humanas diretamente no GitHub Project (Priority: P2)

Como desenvolvedor humano, quero lançar minhas horas de trabalho diretamente no
campo de "Horas Humanas" do GitHub Project vinculado à feature, para que o
sistema de controle de custos capture esse dado sem precisar de uma ferramenta
separada.

**Why this priority**: Eliminar fricção no lançamento de horas garante dados de
qualidade sem sobrecarga operacional para o time.

**Independent Test**: Lançar horas num GitHub Project de teste e confirmar que o
sistema de controle de custos reflete o valor sem intervenção manual adicional.

**Acceptance Scenarios**:

1. **Given** uma issue no GitHub Project com o campo "Horas Humanas" preenchido, **When** o sistema de controle de custos processar os dados, **Then** as horas aparecem associadas à feature correta no dashboard.
2. **Given** um campo "Horas Humanas" vazio em uma issue concluída, **When** o sistema consolidar os dados, **Then** a feature é marcada como "custo humano não registrado" para acompanhamento.

---

### Edge Cases

- O que acontece quando tokens e horas são registrados em fusos horários diferentes e a reconciliação de período é imprecisa?
- Como o sistema se comporta quando uma feature ultrapassa o escopo original e o orçamento precisa ser reajustado retroativamente?
- Como tratar features canceladas parcialmente executadas — o custo incorrido deve ser exibido, arquivado ou descartado?
- Como o sistema lida com ausência do campo "Horas Humanas" em projetos que ainda não configuraram o GitHub Project padronizado?
- O que acontece quando dois agentes executam trabalho paralelo na mesma feature e os tokens são duplicados no relatório?
- Como garantir que variações cambiais (custo de tokens em USD vs. report em BRL) não distorçam comparações históricas?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema MUST coletar e armazenar o consumo real de tokens por feature, associando ao modelo utilizado e à sessão de agente correspondente.
- **FR-002**: O sistema MUST integrar com o campo "Horas Humanas" do GitHub Project para capturar o custo de trabalho humano por feature.
- **FR-003**: O sistema MUST permitir definir orçamentos por sprint, projeto ou squad, com limites configuráveis por responsável.
- **FR-004**: O sistema MUST disparar alertas automáticos quando o consumo atingir 80% e 100% do orçamento definido, com notificação para o responsável cadastrado.
- **FR-005**: O sistema MUST exibir um dashboard consolidado com custo real vs. estimado por feature, com drill-down por dimensão (tokens, horas humanas, nuvem).
- **FR-006**: O sistema MUST armazenar histórico de custo por complexidade (S0–S4) para uso como benchmarks em estimativas futuras.
- **FR-007**: O template de `plan.md` MUST incluir campos obrigatórios de estimativa de custo (tokens + horas humanas) que se integrem ao sistema de coleta.
- **FR-008**: O sistema MUST suportar filtros por período, projeto, squad e complexidade no dashboard e nos relatórios exportáveis.
- **FR-009**: O sistema MUST registrar, por feature, a variação entre estimativa e consumo real, tornando o dado disponível para auditoria e melhoria de processo.
- **FR-010**: O sistema MUST [NEEDS CLARIFICATION: definir se o custo de recursos de nuvem (compute, storage) entra no escopo desta fase ou é uma fase futura].

### Key Entities *(include if feature involves data)*

- **CostRecord**: representa o custo real de uma feature em uma dimensão específica (tokens, horas humanas ou nuvem); atributos: `feature_id`, `dimension`, `amount`, `currency`, `period`, `source`.
- **CostEstimate**: representa a estimativa registrada no `plan.md` antes da execução; atributos: `feature_id`, `dimension`, `estimated_amount`, `complexity_level`, `recorded_at`.
- **Budget**: orçamento configurado para um sprint, projeto ou squad; atributos: `scope_type`, `scope_id`, `limit_amount`, `currency`, `period`, `alert_threshold_pct`, `owner`.
- **CostAlert**: alerta disparado quando um limite de orçamento é atingido; atributos: `budget_id`, `triggered_at`, `consumption_at_trigger`, `threshold_pct`, `notified_to`.
- **CostBenchmark**: agregado histórico de custo por nível de complexidade usado para sugestão de estimativas; atributos: `complexity_level`, `avg_tokens`, `avg_human_hours`, `sample_size`, `period`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% das features com `plan.md` preenchido têm estimativa de custo registrada nos campos obrigatórios ao final de cada sprint.
- **SC-002**: A variância média entre estimativa e consumo real de tokens cai em pelo menos 25% após 3 meses de uso do sistema (comparado ao baseline de estimativas livres).
- **SC-003**: 100% dos alertas de orçamento são disparados dentro de 30 minutos após o limiar ser atingido.
- **SC-004**: Gestores conseguem gerar um relatório de custo por sprint em menos de 2 minutos, sem precisar consolidar dados manualmente.
- **SC-005**: 90% dos desenvolvedores que participam do piloto avaliam o sistema de lançamento de horas como "sem fricção adicional relevante" em survey pós-adoção.
- **SC-006**: Histórico de benchmarks cobre ao menos 10 features concluídas por nível de complexidade antes de o recurso de sugestão de estimativas ser ativado em produção.

## Assumptions

- O GitHub Project já está configurado com o campo "Horas Humanas" conforme descrito em `docs/ai-code-quality-and-observability.md` (seção 8) — este sistema o lê, não o recria.
- O custo de recursos de nuvem (compute, storage) está fora do escopo do MVP; a integração com provedores de nuvem pode ser endereçada numa fase futura.
- Todos os projetos consumidores do bundle usam o mesmo padrão de `plan.md` com os campos de estimativa de custo — features sem esse campo são consideradas não-conformes e sinalizadas.
- A moeda base de consolidação é BRL; custos em USD (tokens) são convertidos pela taxa de câmbio do dia da coleta, armazenada junto com o registro.
- O modelo híbrido continuará sendo o padrão de operação da organização pelo menos pelos próximos 12 meses, justificando o investimento em rastreio de custo estruturado.
- O acesso ao dashboard é restrito a Tech Leads, gestores e diretores — desenvolvedores veem apenas custos de suas próprias features.
