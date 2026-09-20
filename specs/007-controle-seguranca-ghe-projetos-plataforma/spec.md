# Feature Specification: Documentação de Controle de Segurança no GHE para Projetos e Projeto Plataforma
﻿# Feature Specification: Documentação de Controle de Segurança no GHE para Projetos e Projeto Plataforma

**Feature Branch**: `007-controle-seguranca-ghe-projetos-plataforma`

**Created**: 2026-08-19

**Status**: Draft

**Input**: User description: "/scpekit-specify Criar documentacao para Controle de Seguranca no GHE para controle dos projetos e projeto plataforma."

---

## Clarifications

### Session 2026-08-19

- Q: O objetivo desta feature é produzir apenas a documentação (guia manual de configuração), ou ela também deve incluir/gerar automação (scripts, GitHub Actions, rulesets) que aplique os controles descritos? → A: Documentação + automação (scripts/workflows que aplicam ou validam os controles automaticamente)
- Q: Quando um controle automatizado detectar um repositório fora de conformidade, a automação deve corrigir automaticamente ou apenas reportar o desvio para correção manual? → A: Apenas detectar e reportar (gera issue/relatório; correção é manual, seguindo o fluxo já existente)
- Q: Com que frequência/gatilho a automação de detecção deve rodar nos repositórios de projeto e no Projeto Plataforma? → A: Agendamento automático semanal, com relatório consolidado mensal
- Q: Qual deve ser o escopo de repositórios cobertos pela automação: todos os repositórios da organização, apenas os que seguem o fluxo Nimbus Code, ou uma lista explícita configurável? → A: Todos os repositórios da organização automaticamente (descoberta via API, sem lista manual)
- Q: Que tipo de credencial a automação de varredura org-wide deve usar para acessar todos os repositórios da organização? → A: GitHub App dedicado, instalado na organização, com permissões somente-leitura mínimas necessárias

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Definir baseline de segurança para repositórios de projeto (Priority: P1)

Como **administrador da organização no GHE**, quero uma documentação única com os controles mínimos obrigatórios para os repositórios de projeto, para que todos os times adotem o mesmo padrão de segurança.

**Why this priority**: Sem baseline única, cada projeto aplica controles diferentes e cria risco de compliance e acesso indevido.

**Independent Test**: Revisar apenas a seção de baseline e validar que um admin consegue aplicar os controles em um repositório novo sem depender de outros documentos.

**Acceptance Scenarios**:

1. **Given** um repositório novo no GHE, **When** sigo a documentação, **Then** consigo configurar branch protection, regras de revisão, secrets e permissões mínimas de Actions.
2. **Given** um repositório já existente, **When** comparo com o checklist da documentação, **Then** identifico rapidamente quais controles estão ausentes.

---

### User Story 2 — Definir governança de segurança para o Projeto Plataforma (Priority: P1)

Como **responsável pela plataforma**, quero documentação específica para o Project V2 de plataforma (visão consolidada), para que o acesso, automações e tokens do board sejam controlados com menor privilégio.

**Why this priority**: O projeto de plataforma concentra informação de múltiplos repositórios e requer governança reforçada.

**Independent Test**: Revisar a seção do Projeto Plataforma e validar que um mantenedor consegue configurar os acessos e segredos necessários sem superprivilégios.

**Acceptance Scenarios**:

1. **Given** o Project V2 de plataforma já criado, **When** aplico os controles documentados, **Then** apenas papéis autorizados conseguem administrar views/campos críticos.
2. **Given** workflows que escrevem no board, **When** sigo a documentação de tokens, **Then** consigo usar PAT com escopo mínimo e rotação definida.

---

### User Story 3 — Padronizar auditoria e operação contínua (Priority: P2)

Como **time de engenharia e governança**, quero uma rotina de auditoria periódica documentada, para que desvios de segurança sejam detectados e corrigidos continuamente.

**Why this priority**: A configuração inicial não é suficiente; sem auditoria recorrente os controles degradam ao longo do tempo.

**Independent Test**: Executar o checklist de auditoria mensal documentado e validar que ele gera evidências objetivas de conformidade.

**Acceptance Scenarios**:

1. **Given** a documentação publicada, **When** um time executa a auditoria mensal, **Then** ele produz um relatório com status de cada controle (ok, pendente, risco).
2. **Given** um desvio identificado, **When** sigo o fluxo de tratamento descrito, **Then** o desvio vira issue rastreável com prioridade e responsável.

---

### Edge Cases

- Repositório sem permissões administrativas para aplicar branch protection no momento da auditoria.
- Projeto sem suporte completo a recursos de segurança por limitação de plano/instância GHE.
- Workflow de automação dependente de token expirado ou secret ausente.
- Time com múltiplos projetos vinculados ao mesmo Project V2 de plataforma com níveis de sensibilidade diferentes.

## Requirements *(mandatory)*

### Functional Requirements

> **Saneamento documental (2026-09-20):** removidas as repetições textuais de
> FR-002/003/004/005, preservando seus IDs e vínculos. As duas formulações
> anteriormente identificadas como SC-003 foram consolidadas no mesmo ID,
> mantendo tanto a auditoria mensal quanto a varredura semanal/relatório mensal.
> Isso não aprova requisitos, checklist ou rollout. As revisões
> [#450](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/issues/450)
> e [#60/T038](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/issues/60)
> estavam abertas na consulta desta data; aprovação S4, ADR-0008 aceito e
> evidência do piloto continuam dependências humanas.

- **FR-001**: A documentação DEVE listar os controles obrigatórios de segurança para repositórios de projeto no GHE (acesso, branch protection, revisão, Actions, secrets).
- **FR-002**: A documentação DEVE separar claramente controles para nível de repositório e controles para o Projeto Plataforma (Project V2 consolidado).
- **FR-003**: A documentação DEVE definir modelo de acesso por papéis (owner/admin/maintainer/contributor/leitor) com princípio de menor privilégio.
- **FR-004**: A documentação DEVE definir padrão para uso de tokens e secrets de automação (escopo mínimo, rotação, armazenamento e revogação).
- **FR-005**: A documentação DEVE incluir checklist operacional de auditoria periódica com critérios objetivos de conformidade.
- **FR-001a**: A feature DEVE entregar automação (scripts e/ou GitHub Actions) que detecta e reporta (não corrige automaticamente) os controles documentados nos repositórios de projeto e no Projeto Plataforma, gerando issue/relatório rastreável para correção manual seguindo o fluxo existente.
- **FR-004a**: A automação de varredura organizacional DEVE autenticar-se via GitHub App dedicado instalado na organização, com permissões somente-leitura mínimas necessárias (least privilege), em vez de PAT de usuário ou credenciais de escopo amplo.
- **FR-005a**: A automação DEVE executar a varredura de conformidade em agendamento semanal (cron) para repositórios de projeto e Projeto Plataforma, e DEVE consolidar os resultados em um relatório mensal.
- **FR-005b**: A automação DEVE descobrir automaticamente todos os repositórios da organização via API do GHE (sem depender de lista manual configurada) para determinar o escopo de varredura.
- **FR-006**: A documentação DEVE incluir procedimento de resposta para não conformidades (registro, prioridade, responsável, prazo e validação de correção).
- **FR-007**: A documentação DEVE referenciar o fluxo Nimbus Code já existente para governança (labels, board e gates) sem criar processo paralelo.
- **FR-008**: A documentação DEVE explicitar dependências mínimas para workflows que interagem com Projects (permissões e secrets obrigatórios).

### Key Entities *(include if feature involves data)*

- **Controle de Segurança**: Política ou configuração obrigatória no GHE (ex.: proteção de branch, revisão obrigatória, secret management).
- **Projeto de Repositório**: Repositório individual do time, com backlog e automações próprias.
- **Projeto Plataforma**: Project V2 consolidado que agrega visibilidade de vários repositórios.
- **Perfil de Acesso**: Papel de usuário/grupo com permissões delimitadas para repositório e projeto.
- **Evidência de Auditoria**: Registro verificável do estado de conformidade de um controle.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% dos novos repositórios conseguem aplicar o baseline de segurança usando apenas esta documentação.
- **SC-002**: O Projeto Plataforma passa a operar com matriz de permissões documentada e sem concessão de acesso administrativo fora da matriz aprovada.
- **SC-003**: Pelo menos 1 auditoria mensal é executada com checklist completo e evidência registrada para cada projeto ativo; a automação executa a varredura semanalmente sem falha e gera um relatório consolidado mensal com evidência registrada para cada projeto ativo.
- **SC-004**: Reduzir em pelo menos 80% a ocorrência de falhas operacionais por secret/token ausente em workflows de governança de Projects.

## Assumptions

- A organização possui permissões de administração necessárias no GHE para configurar os controles descritos.
- Os repositórios usam o fluxo Nimbus Code e seus workflows padrão de governança.
- O Projeto Plataforma já existe ou será criado com scripts oficiais do template.
- O processo de auditoria será executado por responsável de plataforma com apoio dos times de projeto.
