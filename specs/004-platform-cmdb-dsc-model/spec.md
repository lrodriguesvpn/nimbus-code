# Feature Specification: Plataforma CMDB + Baselines de Segurança e Compliance

**Feature Branch**: `004-platform-cmdb-dsc-model`  
**Created**: 2026-08-12  
**Status**: Draft  
**Input**: User description: "Estruturação do repositório e modelo de Plataforma, integrando descoberta de recursos em nuvem, baselines de segurança do Microsoft 365 e Azure/AWS em um CMDB consumível por IA. Estabelece o modelo Desired State Configuration (DSC) para validação contínua de configurações, conformidade de políticas e auditoria de arquivos Terraform."

## Nimbus-Code — Cabeçalho Obrigatório da Spec

| Campo | Valor |
|---|---|
| **Feature slug** | `004-platform-cmdb-dsc-model` |
| **Complexidade estimada** | S4 |
| **Bounded Context** | Platform Governance & Compliance |
| **PR de referência / Issue** | novo |
| **Data alvo de entrega** | sem data |

## Nimbus-Code — SLO Alvo desta Feature

| Componente | Latência p99 (ms) | Taxa de erro máx. (%) | Disponibilidade alvo | RTO | RPO |
|---|---|---|---|---|---|
| Coleta de inventário de plataforma | — | 1,0% | 99,5% | 30 min | 15 min |
| Atualização de baseline e políticas M365 | — | 1,0% | 99,5% | 30 min | 15 min |
| Consulta do CMDB para governança/IA | 2000 | 0,5% | 99,9% | 15 min | 5 min |

## Nimbus-Code — Objetivo e Contexto

**Objetivo:** estabelecer uma capacidade unificada para autenticar o usuário na plataforma, inventariar recursos e configurações, consolidar um CMDB consumível por IA e manter o estado desejado (DSC) de segurança e compliance.

**Motivação:** hoje o inventário e as configurações críticas de plataforma/M365 ficam dispersos, dificultando governança contínua, validação de infraestrutura e automações de compliance.

**Critério de done (alto nível):** existe um fluxo auditável ponta a ponta que identifica a plataforma, autentica o usuário, consolida inventário e baselines em CMDB, mapeia desvios de segurança/compliance e gera modelo DSC aplicável.

## Clarifications

### Session 2026-08-12

- Q: Qual escopo de plataformas deve ser oficialmente coberto no MVP desta feature? → A: Multicloud no MVP.
- Q: Quais domínios de segurança e compliance devem ser obrigatórios no MVP para o mapeamento de baseline e DSC? → A: Todos os domínios disponíveis no tenant.
- Q: Qual modelo de autenticação corporativa deve ser obrigatório para acesso e coleta multicloud no MVP? → A: SSO central corporativo único.
- Q: Como a validação de Terraform com base no CMDB deve atuar no MVP? → A: Modo advisory com relatório e trilha de exceção obrigatória.
- Q: Qual frequência mínima de atualização completa do CMDB e do modelo DSC deve ser exigida no MVP? → A: A cada 24 horas.

## Nimbus-Code — Critérios de Aceitação (formato BDD)

> **AC-1**  
> **Given** um administrador inicia o processo de governança de plataforma  
> **When** ele seleciona a plataforma alvo e autentica com sua identidade corporativa  
> **Then** o sistema inicia coleta autorizada de inventário com registro de escopo e auditoria  
> **Test ref:** `test_AC1_autenticacao_e_escopo`

> **AC-2**  
> **Given** a coleta de inventário da plataforma foi concluída  
> **When** o CMDB de IA é atualizado  
> **Then** recursos, relacionamentos, metadados e evidências ficam disponíveis para consulta e uso em validações de governança  
> **Test ref:** `test_AC2_cmdb_consolidado`

> **AC-3**  
> **Given** existem baselines M365 e políticas corporativas definidas  
> **When** o processo de baseline é executado  
> **Then** o sistema registra políticas aplicadas, customizações detectadas e desvios relevantes de segurança/compliance  
> **Test ref:** `test_AC3_baseline_m365_e_customizacoes`

> **AC-4**  
> **Given** o estado atual da plataforma e do M365 foi consolidado  
> **When** o modelo DSC é gerado/atualizado  
> **Then** configurações alvo de segurança e compliance ficam descritas de forma versionada e rastreável para validação contínua  
> **Test ref:** `test_AC4_modelo_dsc_versionado`

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Onboarding de Plataforma com Autenticação Governada (Priority: P1)

Como **responsável de plataforma**, quero **informar a plataforma alvo e autenticar com minha identidade corporativa** para que **a coleta de dados ocorra com escopo correto, rastreabilidade e permissão adequada**.

**Why this priority**: sem onboarding e autenticação confiáveis, qualquer inventário posterior perde validade de governança e auditoria.

**Independent Test**: iniciar uma nova execução, selecionar plataforma, autenticar, e verificar que o escopo autorizado e os registros de auditoria foram salvos.

**Acceptance Scenarios**:

1. **Given** um usuário autorizado inicia uma execução, **When** escolhe a plataforma e conclui autenticação, **Then** a execução é criada com identidade, escopo e data/hora registrados.
2. **Given** a autenticação falha ou não possui autorização mínima, **When** a execução tenta continuar, **Then** a coleta é bloqueada com motivo explícito e orientações de correção.

---

### User Story 2 — CMDB para IA com Inventário de Recursos e Dados (Priority: P1)

Como **time de governança e IA**, quero **consolidar recursos, dados e relacionamentos em um CMDB corporativo** para que **o inventário seja reutilizável em análises, validações e automações**.

**Why this priority**: o CMDB é o núcleo de valor da feature; sem ele não há base única para validação de infraestrutura e decisões de IA.

**Independent Test**: executar coleta completa e confirmar que o CMDB contém recursos, classificações, relacionamentos e histórico de atualização para consulta.

**Acceptance Scenarios**:

1. **Given** uma plataforma autenticada e com escopo válido, **When** o inventário é processado, **Then** recursos e dados descobertos são persistidos com normalização e vínculo de origem.
2. **Given** uma nova coleta sobre o mesmo ambiente, **When** o CMDB é atualizado, **Then** mudanças de configuração e novos ativos ficam identificados sem perda de histórico.

---

### User Story 3 — Baselines de M365, Políticas Aplicadas e Customizações (Priority: P2)

Como **responsável de segurança e compliance**, quero **comparar o estado atual do M365 com baselines e políticas corporativas** para que **desvios, exceções e customizações sejam transparentes e acionáveis**.

**Why this priority**: garante aderência regulatória e acelera decisões de risco, mas depende do CMDB consolidado.

**Independent Test**: carregar baseline vigente, processar configurações M365 e verificar relatório contendo políticas aplicadas, customizações e desvios priorizados.

**Acceptance Scenarios**:

1. **Given** um baseline M365 vigente, **When** o processo de comparação roda, **Then** o sistema aponta conformidade e não conformidade por domínio de política.
2. **Given** existem customizações fora do padrão, **When** a análise é finalizada, **Then** cada customização é classificada com impacto e justificativa rastreável.

---

### User Story 4 — Modelo DSC para Segurança e Compliance Contínuos (Priority: P2)

Como **equipe de engenharia de plataforma**, quero **manter um modelo DSC unificado de estado desejado** para que **configurações críticas de segurança e compliance possam ser validadas continuamente**.

**Why this priority**: transforma o inventário em controle contínuo, porém depende do mapeamento de baseline e desvios.

**Independent Test**: gerar modelo DSC a partir do estado consolidado e validar que ele representa configurações alvo, versões e regras de conformidade.

**Acceptance Scenarios**:

1. **Given** o estado consolidado de plataforma/M365, **When** o modelo DSC é emitido, **Then** cada configuração crítica possui estado desejado, origem e versão.
2. **Given** uma alteração de baseline de segurança/compliance, **When** o modelo DSC é atualizado, **Then** versões anteriores permanecem auditáveis e o delta é explícito.

### Edge Cases

- O que acontece quando o usuário autentica com identidade válida, mas sem permissão para parte do escopo selecionado?
- Como o sistema trata recursos não inventariáveis temporariamente (limite de API, indisponibilidade, bloqueio de tenant)?
- Como o sistema evita conflito quando duas coletas simultâneas atualizam o mesmo subconjunto do CMDB?
- Como tratar políticas M365 legadas que não possuem mapeamento direto para baseline atual?
- Como o modelo DSC lida com customizações aprovadas que divergem intencionalmente do baseline?
- O que acontece quando uma plataforma do escopo multicloud está temporariamente indisponível para coleta?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema MUST solicitar a plataforma alvo no início da execução e registrar o escopo escolhido.
- **FR-002**: O sistema MUST exigir autenticação via SSO central corporativo único antes de qualquer coleta de inventário.
- **FR-003**: O sistema MUST validar autorização mínima do usuário para o escopo solicitado.
- **FR-004**: O sistema MUST coletar e consolidar inventário de recursos, dados e relacionamentos relevantes da plataforma selecionada.
- **FR-005**: O sistema MUST manter um CMDB corporativo orientado a consumo por IA, com histórico de atualizações.
- **FR-006**: O sistema MUST registrar origem, timestamp e contexto de cada evidência inserida no CMDB.
- **FR-007**: O sistema MUST importar/considerar baseline de M365 vigente para comparação de conformidade.
- **FR-008**: O sistema MUST identificar políticas aplicadas no ambiente e sinalizar customizações detectadas.
- **FR-009**: O sistema MUST mapear desvios de segurança e compliance por criticidade e domínio.
- **FR-010**: O sistema MUST gerar e versionar um modelo DSC com estado desejado de configurações críticas.
- **FR-011**: O sistema MUST permitir uso do CMDB como fonte de validação para fluxos de governança de infraestrutura.
- **FR-012**: O sistema MUST gerar trilha de auditoria para autenticação, coleta, comparação de baseline e geração do modelo DSC.
- **FR-013**: O sistema MUST suportar onboarding e inventário em escopo multicloud no MVP.
- **FR-014**: O sistema MUST mapear baseline e DSC para todos os domínios de segurança e compliance disponíveis no tenant analisado.
- **FR-015**: O sistema MUST executar validação de infraestrutura em modo advisory no MVP, gerando relatório de não conformidade e exigindo registro de exceção para follow-up.
- **FR-016**: O sistema MUST realizar atualização completa do CMDB e do modelo DSC pelo menos uma vez a cada 24 horas.

### Key Entities *(include if feature involves data)*

- **PlatformExecution**: execução de onboarding/coleta com plataforma alvo, identidade autenticada, escopo e status.
- **ResourceAsset**: ativo descoberto (recurso, serviço, dado) com classificação, origem e relacionamento com outros ativos.
- **AICMDBRecord**: registro consolidado no CMDB para consumo por IA, incluindo histórico e evidências.
- **PolicyBaseline**: baseline corporativo de M365 e demais controles de segurança/compliance.
- **AppliedPolicyState**: estado efetivamente aplicado no ambiente em determinado momento.
- **CustomizationException**: desvio/customização detectada com justificativa, criticidade e aprovação.
- **DSCProfile**: modelo versionado de estado desejado para segurança e compliance.
- **ComplianceFinding**: resultado de comparação baseline vs estado aplicado, com severidade e recomendação.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 95% das execuções iniciadas por usuários autorizados concluem autenticação e definição de escopo em até 5 minutos.
- **SC-002**: 100% das coletas concluídas registram inventário no CMDB com rastreabilidade de origem e data/hora.
- **SC-003**: 95% dos recursos classificados como críticos aparecem no CMDB com relacionamento e contexto completos.
- **SC-004**: 100% das políticas do baseline M365 definido para a organização são avaliadas com status de conformidade.
- **SC-005**: 100% das customizações detectadas recebem classificação de impacto (baixo/médio/alto/crítico) e estado de aprovação.
- **SC-006**: O modelo DSC é atualizado em até 30 minutos após uma nova coleta completa em 95% das execuções.
- **SC-007**: O processo reduz em 60% o tempo médio de preparação de evidências para revisões internas de segurança/compliance.
- **SC-008**: 100% dos ambientes no escopo têm execução completa de atualização de CMDB e DSC em janela máxima de 24 horas.

## Assumptions

- A primeira versão cobre escopo multicloud no MVP, respeitando limites de acesso e disponibilidade de cada provedor.
- A organização já possui baseline corporativo mínimo para M365 e critérios de classificação de criticidade.
- Usuários que operam a solução já têm identidade corporativa ativa e passam por governança de acesso.
- A validação de governança de infraestrutura consumirá o CMDB como fonte de verdade, independentemente da ferramenta de provisionamento.
- Ambientes com restrições temporárias de coleta serão marcados com evidência parcial, sem bloquear a execução completa do pipeline.
