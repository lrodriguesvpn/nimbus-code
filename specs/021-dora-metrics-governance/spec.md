# Feature Specification: Governança de Métricas DORA com Coleta Híbrida

**Feature Branch**: `021-dora-metrics-governance`  
**Created**: 2026-08-24  
**Status**: Draft  
**Input**: Solicitação formalizada do usuário: "Formalizar um padrão organizacional de métricas DORA para a Nimbus-Code, cobrindo coleta automática e manual assistida, interpretação executiva e técnica, e governança de uso em backlog e melhoria contínua. A feature deve definir claramente como medir Deployment Frequency, Lead Time for Changes, Change Failure Rate e MTTR; quando a coleta automática é obrigatória; quando ajustes manuais são permitidos com trilha de auditoria; quais papéis são responsáveis por registrar, validar e revisar as métricas; e como transformar sinais de degradação em ações priorizadas. A solução deve incluir regras de qualidade dos dados, prevenção de manipulação de métricas, leitura combinada dos 4 indicadores (evitando interpretação isolada), e cadência operacional semanal/mensal para squads e PMO. Também deve padronizar critérios de sucesso mensuráveis para adoção do modelo DORA em repositórios e portfólios, com foco em decisões orientadas por evidência e melhoria contínua."

## Nimbus-Code — Cabeçalho Obrigatório da Spec

| Campo | Valor |
|---|---|
| **Feature slug** | `021-dora-metrics-governance` |
| **Complexidade estimada** | S3 |
| **Bounded Context** | `spec-kit-workflow` |
| **PR de referência / Issue** | novo |
| **Data alvo de entrega** | sem data |

> S0 = doc · S1 = função isolada · S2 = módulo · S3 = múltiplos módulos · S4 = arquitetura, segurança, dados ou integração crítica

## Nimbus-Code — SLO Alvo desta Feature

| Componente | Latência p99 (ms) | Taxa de erro máx. (%) | Disponibilidade alvo | RTO | RPO |
|---|---|---|---|---|---|
| Ingestão automática de eventos DORA | 5000 | 1,0% | 99,9% | 30 min | 5 min |
| Registro manual assistido com auditoria | 4000 | 1,0% | 99,9% | 30 min | 5 min |
| Consolidação semanal/mensal de indicadores | 8000 | 1,0% | 99,5% | 60 min | 15 min |

## Nimbus-Code — Objetivo e Contexto

**Objetivo:** definir um padrão único de medição e uso de DORA na Nimbus-Code, combinando coleta automática e ajustes manuais auditáveis para garantir decisão baseada em evidência.

**Motivação:** hoje existem sinais dispersos (issues, labels, workflows e dados de entrega), mas sem um modelo operacional completo e consistente para leitura executiva/técnica e melhoria contínua.

**Critério de done (alto nível):** squads e PMO operam os 4 indicadores DORA com definições padronizadas, qualidade de dados rastreável, interpretação conjunta e geração disciplinada de ações de melhoria.

**Fora de escopo:** construção de painéis visuais finais, mudanças em infraestrutura de telemetria externa e alteração de metas de performance específicas de cada time.

## Nimbus-Code — Hybrid Collaboration Model

| Papel | Responsabilidades | Critério de handoff | Escalação |
|---|---|---|---|
| Agente | Estruturar spec/plan/tasks, mapear fontes de dados, propor regras de qualidade e trilha de auditoria, consolidar evidências de medição | Repassa quando houver conflito de interpretação de negócio ou decisão de governança cross-squad | Architecture board |
| Dev | Validar viabilidade técnica da coleta, confiabilidade da origem dos dados e rastreabilidade de ajustes manuais | Repassa ao BA quando definição de indicador impactar priorização do backlog | Tech lead |
| Business Analyst | Validar semântica dos indicadores para leitura de negócio e coerência das regras de exceção manual | Repassa ao PMO quando houver divergência entre times sobre interpretação | Product owner |
| Digital Engineering | Definir cadência operacional, governança de adoção e critério de ação corretiva em nível de portfólio | Repassa para liderança quando metas globais exigirem ajuste de política | Engineering manager |

## Nimbus-Code — Critérios de Aceitação (formato BDD)

> **AC-1**  
> **Given** um repositório com fluxo de entrega ativo,  
> **When** a governança DORA for aplicada,  
> **Then** os quatro indicadores (Deployment Frequency, Lead Time for Changes, Change Failure Rate, MTTR) ficam definidos com fórmula, evento de origem e janela de medição padronizada.  
> **Test ref:** `test_AC1_dora_metric_definition`

> **AC-2**  
> **Given** um evento de entrega elegível para automação,  
> **When** ele ocorrer no fluxo operacional,  
> **Then** o registro deve ser capturado automaticamente sem intervenção manual como caminho padrão.  
> **Test ref:** `test_AC2_auto_collection_default`

> **AC-3**  
> **Given** um caso fora do fluxo automático esperado,  
> **When** um ajuste manual for necessário,  
> **Then** o processo exige justificativa, responsável, timestamp e vínculo com evidência para auditoria.  
> **Test ref:** `test_AC3_manual_adjustment_audit_trail`

> **AC-4**  
> **Given** um conjunto de dados DORA consolidado,  
> **When** a análise semanal ou mensal for executada,  
> **Then** o processo avalia os quatro indicadores de forma combinada, sem tomada de decisão baseada em um único indicador isolado.  
> **Test ref:** `test_AC4_combined_metric_interpretation`

> **AC-5**  
> **Given** degradação relevante em qualquer combinação de indicadores,  
> **When** o limite operacional definido for atingido,  
> **Then** uma ação priorizável é registrada no backlog com ownership e prazo de revisão.  
> **Test ref:** `test_AC5_degradation_to_action_flow`

> **AC-6**  
> **Given** múltiplas squads com níveis diferentes de maturidade,  
> **When** o modelo de governança DORA for adotado,  
> **Then** o framework permite comparar evolução relativa sem distorcer contexto por diferenças de tamanho/escopo entre equipes.  
> **Test ref:** `test_AC6_context_aware_comparison`

## Nimbus-Code — Backlog Hierarchy (EPIC/FEATURE/US)

| Nível | Valor | Observação |
|---|---|---|
| **EPIC** | Excelência de Entrega Orientada por Métricas | Padronizar governança de performance de engenharia |
| **FEATURE** | Governança DORA com coleta híbrida | Escopo desta spec |
| **US1** | Padronizar definições e fronteiras dos 4 indicadores DORA | Evita leitura inconsistente entre times |
| **US2** | Garantir coleta automática como padrão | Reduz erro humano e esforço operacional |
| **US3** | Controlar exceções manuais com auditoria | Preserva confiança dos dados |
| **US4** | Instituir interpretação executiva e técnica combinada | Melhora decisão de priorização |
| **US4** | Interpretar os indicadores e converter degradação em ações de backlog rastreáveis | Fecha loop de melhoria contínua; não existe uma US5 separada |

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Padronizar a base de medição DORA (Priority: P1)

Como Digital Engineer, quero definições únicas para os quatro indicadores DORA para que todas as squads usem a mesma régua de leitura.

**Why this priority**: sem definição comum, qualquer comparação ou decisão de melhoria fica inconsistente.

**Independent Test**: revisar um conjunto de repositórios e confirmar que todos aplicam a mesma definição de evento, janela e regra de cálculo para cada indicador.

**Acceptance Scenarios**:

1. **Given** uma squad iniciando o ciclo de medição, **When** consultar o padrão DORA, **Then** encontra definições fechadas e não ambíguas para os quatro indicadores.
2. **Given** duas squads diferentes, **When** reportarem os indicadores do mesmo período, **Then** os números são comparáveis sob a mesma regra.

---

### User Story 2 - Coletar automaticamente o máximo possível (Priority: P1)

Como Dev, quero que a maior parte da medição seja automática para reduzir retrabalho manual e aumentar confiabilidade dos dados.

**Why this priority**: automação é o principal mecanismo para reduzir erro de captura e viés operacional.

**Independent Test**: acompanhar eventos de entrega durante um período e verificar que entradas elegíveis são capturadas sem edição humana.

**Acceptance Scenarios**:

1. **Given** um evento de deploy elegível, **When** ele é concluído, **Then** o indicador correspondente é registrado automaticamente.
2. **Given** o registro automático concluído, **When** o responsável consultar o histórico, **Then** ele encontra rastreabilidade de origem do evento.

---

### User Story 3 - Tratar exceções sem perder auditabilidade (Priority: P1)

Como Business Analyst, quero um fluxo manual controlado para corrigir lacunas de captura sem comprometer a governança dos indicadores.

**Why this priority**: exceções sempre existirão; sem trilha de auditoria, a credibilidade da métrica se perde.

**Independent Test**: executar um ajuste manual e validar que justificativa, autor, data e evidência ficam vinculados.

**Acceptance Scenarios**:

1. **Given** uma inconsistência de coleta, **When** um ajuste manual for solicitado, **Then** o sistema exige justificativa objetiva e responsável identificado.
2. **Given** um ajuste manual registrado, **When** ocorrer auditoria periódica, **Then** o histórico permite reconstruir o motivo e o impacto da alteração.

---

### User Story 4 - Interpretar os indicadores para ação prática (Priority: P1)

Como PMO, quero uma cadência semanal/mensal de leitura combinada de DORA para orientar priorização e investimento de melhoria.

**Why this priority**: sem rotina operacional de leitura e ação, os indicadores viram apenas relatório sem efeito real.

**Independent Test**: executar uma rodada de revisão com dados reais e comprovar geração de ações priorizadas com dono e prazo.

**Acceptance Scenarios**:

1. **Given** uma revisão semanal ou mensal, **When** os quatro indicadores são analisados em conjunto, **Then** são identificadas causas prováveis e propostas de ação.
2. **Given** uma degradação confirmada, **When** a revisão é concluída, **Then** uma ação entra no backlog com prioridade, responsável e data de revisão.

---

### Edge Cases

- Como agir quando houver dados automáticos faltantes por indisponibilidade temporária da fonte de eventos?
- Como tratar conflito entre registro automático e ajuste manual sobre o mesmo evento?
- Como impedir ganho aparente de um indicador que cause piora relevante em outro no mesmo período?
- Como lidar com squads recém-criadas sem histórico suficiente para comparação mensal?

**Regras para esses casos:** indisponibilidade da fonte coloca o ciclo em
`data_insufficient` e exige reconciliação no próximo ciclo; o registro
automático prevalece até que um ajuste manual aprovado seja vinculado ao mesmo
evento; eventos corrigidos preservam o registro original e criam nova
evidência; e squads sem um ciclo completo ficam fora de comparações relativas
até formar um baseline.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O padrão DORA MUST definir explicitamente os quatro indicadores com fórmula textual, evento de origem, início/fim da janela e regra de inclusão/exclusão.
- **FR-002**: O processo MUST adotar coleta automática como caminho padrão para todos os eventos elegíveis.
- **FR-003**: O processo MUST registrar a origem de cada métrica coletada para permitir rastreabilidade.
- **FR-004**: Ajustes manuais MUST ser permitidos apenas como exceção controlada com justificativa, autor, horário, evidência vinculada e `approved_by`.
- **FR-005**: O modelo MUST classificar ajustes manuais por uma categoria pertencente ao vocabulário controlado `fonte_indisponivel`, `evento_duplicado`, `correcao_retroativa` ou `outro_justificado`.
- **FR-006**: O fluxo MUST impedir fechamento de revisão periódica quando houver ajustes manuais sem justificativa completa, aprovação, ou reconciliação de fonte indisponível.
- **FR-007**: O processo de análise MUST exigir leitura combinada dos quatro indicadores e registrar conclusão de causa e impacto.
- **FR-008**: O modelo MUST considerar degradação relevante quando (a) um indicador ultrapassar sua meta inicial por um ciclo completo, ou (b) dois indicadores apresentarem piora relativa de pelo menos 20% contra o baseline da própria squad no mesmo ciclo; dados insuficientes não podem gerar ação automática.
- **FR-009**: Cada ação corretiva gerada a partir de DORA MUST conter owner, prioridade inicial e prazo de reavaliação.
- **FR-010**: O padrão MUST definir cadência mínima semanal para squads e mensal para visão de portfólio/PMO.
- **FR-011**: O processo MUST incluir regras de qualidade de dados: completude de 100% dos campos obrigatórios, consistência temporal sem eventos fora da janela, e ausência de duplicidade por `indicator` + `evidence_reference` + janela.
- **FR-012**: O processo MUST disponibilizar trilha de auditoria para evidenciar quem mediu, quem ajustou, quem aprovou e quando, preservando registros substituídos e a referência ao ciclo afetado.

> **Regra de composição da US4:** a conversão de degradação em `Improvement Action` faz parte da US4 e deve seguir uma única cadeia normativa: conclusão combinada dos quatro indicadores → gatilho objetivo → Issue criada/atualizada → `owner`, `priority` e `review_deadline` → reavaliação. Não há uma User Story 5 independente.

### Key Entities *(include if feature involves data)*

- **Metric Definition**: especifica o significado oficial de cada indicador DORA, incluindo evento de origem, janela de medição e regras de cálculo.
- **Collection Record**: representa cada captura de dado de métrica, com origem (automática/manual), timestamp e vínculo de evidência.
- **Manual Adjustment**: representa alteração excepcional em registro de métrica, com justificativa, autor, categoria de exceção e aprovação.
- **Review Cycle**: representa rodada semanal ou mensal de análise, com conclusões combinadas dos indicadores e decisões tomadas.
- **Improvement Action**: representa item de backlog aberto por degradação de métrica, com owner, prioridade e data de revisão.

`Review Cycle` MUST usar os estados `open`, `data_insufficient`,
`reconciliation_pending`, `approved` e `closed`. Apenas `approved` pode
transicionar para `closed`; estados de dados insuficientes exigem recuperação
antes do fechamento.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% das squads participantes passam a reportar os quatro indicadores com a mesma definição oficial em até 2 ciclos mensais após adoção.
- **SC-002**: Pelo menos 85% dos registros de eventos elegíveis são capturados automaticamente já no primeiro ciclo mensal completo.
- **SC-003**: 100% dos ajustes manuais realizados no período possuem justificativa, responsável, evidência e aprovação auditáveis.
- **SC-004**: 100% das revisões mensais de DORA resultam em conclusão documentada sobre tendência e impacto cruzado entre os indicadores.
- **SC-005**: Toda degradação classificada como relevante gera ação formal no backlog em até 5 dias úteis após a revisão.

## Assumptions

- O repositório e os times já possuem um fluxo básico de entrega com eventos mínimos observáveis.
- O objetivo desta feature é padronização de processo e governança, não substituição completa das ferramentas já existentes.
- As squads aceitarão uma cadência comum de revisão para permitir comparabilidade e aprendizagem organizacional.
- A priorização final das ações de melhoria continuará respeitando o contexto de negócio de cada produto.
