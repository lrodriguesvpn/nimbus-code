# Tasks: Documentação de Controle de Segurança no GHE para Projetos e Projeto Plataforma

**Input**: Design documents from `/specs/007-controle-seguranca-ghe-projetos-plataforma/`
**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/](./contracts), [quickstart.md](./quickstart.md)

**Tests**: Incluídas — o `plan.md` já compromete cada AC a um teste de integração planejado (tabela "Rastreabilidade AC → Teste → Módulo"), portanto os testes abaixo não são opcionais.

**Organization**: Tasks são agrupadas por user story (P1/P1/P2 do `spec.md`) para permitir implementação e teste independentes.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode rodar em paralelo (arquivos diferentes, sem dependência)
- **[Story]**: US1, US2 ou US3 (mapeado ao `spec.md`)
- Caminhos de arquivo exatos em cada descrição

## GHE Issue Tracking (hierarquia Epic → Feature → User Story → Task)

*Gerado por `/speckit-taskstoissues` — sub-issues nativas do GHE (Issue Types: Epic/Feature/User Story/Task), com labels de prioridade/complexidade/tipo/agente aplicadas em cada issue.*

| Nível | Issue | Título |
|---|---|---|
| Epic | [#65](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code/issues/65) | Governança de Segurança do GHE — Nimbus-Code |
| Feature (007) | [#66](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code/issues/66) | Controle de Segurança no GHE para Projetos e Projeto Plataforma |
| User Story 1 | [#67](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code/issues/67) | Definir baseline de segurança para repositórios de projeto |
| User Story 2 | [#68](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code/issues/68) | Definir governança de segurança para o Projeto Plataforma |
| User Story 3 | [#69](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code/issues/69) | Padronizar auditoria e operação contínua |

**Tasks → Issue (sub-issue do parent indicado):**

| Task | Issue | Sub-issue de |
|---|---|---|
| T001–T010 | [#23](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code/issues/23)–[#32](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code/issues/32) | Feature #66 (Setup/Foundational, sem US específica) |
| T011–T018 | [#33](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code/issues/33)–[#40](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code/issues/40) | User Story 1 #67 |
| T019–T023 | [#41](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code/issues/41)–[#45](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code/issues/45) | User Story 2 #68 |
| T024–T032 | [#46](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code/issues/46)–[#54](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code/issues/54) | User Story 3 #69 |
| T033–T041 | [#55](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code/issues/55)–[#63](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code/issues/63) | Feature #66 (Polish, sem US específica) |

Cada issue de Task recebeu labels de `priority:*`, `complexity:*`, `type:*` e `agent:autonomous-ok`/`agent:needs-human` (T004 e T038 são `agent:needs-human`, refletindo `[Humano]` nesta lista).

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Inicialização da estrutura de arquivos que a automação e os testes vão usar.

- [x] T001 Create directory skeleton `scripts/`, `tests/docs/`, `tests/scripts/`, `tests/workflows/` (adicionar `.gitkeep` onde necessário)
- [x] T002 [P] Scaffold `scripts/security-compliance-scan.sh` com parsing de argumentos (`--dry-run`, `--scope=pilot|org-wide`) e shellcheck limpo
- [x] T003 [P] Scaffold `.github/workflows/security-compliance-scan.yml` com triggers `schedule` (semanal) + `workflow_dispatch` e passo de verificação de secrets obrigatórios, per [contracts/weekly-scan-workflow-contract.md](./contracts/weekly-scan-workflow-contract.md)

**Checkpoint**: esqueleto de arquivos existe antes de qualquer lógica ser implementada.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Credencial e mecanismos centrais que TODAS as user stories dependem (descoberta de repos, autenticação, deduplicação de issue).

**⚠️ CRITICAL**: Nenhuma user story pode ser considerada completa/testável de ponta a ponta sem esta fase.

**Status desta sessão (MVP)**: T004 é manual (criação do GitHub App na organização) e permanece pendente — nenhum agente pode executá-la. Como consequência, T005 (configurar os secrets reais com as credenciais do App) também permanece pendente, pois depende diretamente de T004. T006–T010 foram implementados em código (a lógica de autenticação, descoberta, dedup de issue e resolução de flag funciona assim que os secrets existirem — ela falha explicitamente com `::error::` enquanto não existirem, sem simular autenticação).

- [ ] T004 [Humano] Criar o GitHub App "Nimbus Code Security Auditor" na organização com permissões somente-leitura (`metadata:read`, `administration:read`, `secrets:read`, `contents:read`) e instalá-lo — ver ADR [0008](/docs/adr/0008-github-app-para-varredura-de-seguranca-org-wide.md) _(decisão consolidada em [issue #72](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code/issues/72) junto com specs 003/008 — aguardar decisão de App único antes de criar um App isolado)_

  ```markdown
  ## Contexto
  A varredura semanal de conformidade (feature 007) precisa ler configurações
  administrativas (branch protection, secrets configurados, permissões de
  Actions) em todos os repositórios da organização. Um GitHub App dedicado
  com permissões somente-leitura foi escolhido em vez de um PAT de usuário
  (ver ADR-0008) para atender ao princípio de least privilege.

  ## Objetivo
  Criar e instalar um GitHub App na organização com o escopo mínimo de leitura
  necessário para a varredura.

  ## Resultado Esperado
  GitHub App criado, instalado na organização, com App ID, Installation ID e
  chave privada (.pem) gerados e prontos para serem configurados como secrets.

  ## Critérios de Aceite
  - [ ] App criado com nome "Nimbus Code Security Auditor" (ou equivalente aprovado)
  - [ ] Permissões concedidas: apenas `metadata:read`, `administration:read`, `secrets:read`, `contents:read` — nenhuma permissão de escrita
  - [ ] App instalado na organização (todos os repositórios ou o conjunto piloto, conforme rollout)
  - [ ] App ID, Installation ID e chave privada documentados em local seguro (não em texto plano no repositório)

  ## Passos Operacionais
  1. Organization Settings → Developer settings → GitHub Apps → New GitHub App
  2. Nome: "Nimbus Code Security Auditor"; Homepage URL: URL do repositório
  3. Webhook: desativado (não é necessário para esta feature)
  4. Permissions → Repository permissions: Metadata (Read-only), Administration (Read-only), Secrets (Read-only, se disponível), Contents (Read-only)
  5. Where can this GitHub App be installed?: Only on this account
  6. Gerar e baixar a chave privada (.pem)
  7. Instalar o App na organização (inicialmente restrito ao bounded context piloto `spec-kit-workflow`, conforme estratégia de release do `plan.md`)
  8. Anotar App ID e Installation ID exibidos na página do App

  ## Dependências
  Nenhuma

  ## Responsável
  Agente: não
  Humano: sim

  ## Estimativa de Esforço
  - Tokens (agente): N/A
  - Horas (humano): ~1 hora

  ## Referência
  - AC-ID: AC-8 (FR-004a)
  - Feature: specs/007-controle-seguranca-ghe-projetos-plataforma
  - SPEC KIT COST: https://github.com/venha-pra-nuvem/spec-kit-cost
  ```

- [ ] T005 Configurar `SECURITY_SCAN_APP_ID`, `SECURITY_SCAN_APP_PRIVATE_KEY`, `SECURITY_SCAN_APP_INSTALLATION_ID` como GitHub Secrets do repositório (depende de T004)
- [x] T006 [P] Implementar autenticação via JWT + installation access token do GitHub App em `scripts/security-compliance-scan.sh`, com falha explícita (`::error::`) se algum secret estiver ausente
- [x] T007 [P] Implementar descoberta paginada de repositórios (`gh api --paginate`) com backoff exponencial em rate limit (403/429) em `scripts/security-compliance-scan.sh`
- [x] T008 Criar as estruturas de dados de `Compliance Finding` (`id`, `repo`, `controle_id`, `status`, `timestamp`, `evidencia`) em `scripts/security-compliance-scan.sh`, conforme [data-model.md](./data-model.md) (depende de T002)
- [x] T009 [P] Implementar criação/atualização idempotente de Issue por `id` de finding (marcador `<!-- security-baseline-finding-id -->`) em `scripts/security-compliance-scan.sh`, reaproveitando o padrão `speckit-deduplication-by-id` (`docs/reuse-catalog.yaml`)
- [x] T010 [P] Implementar resolução do flag `security.baseline_scan.org_wide_enabled` via abstração OpenFeature (provider env/arquivo) em `scripts/security-compliance-scan.sh`

**Checkpoint**: credencial, descoberta de repos, deduplicação de issue e resolução de flag prontos — as user stories podem começar.

---

## Phase 3: User Story 1 - Definir baseline de segurança para repositórios de projeto (Priority: P1) 🎯 MVP

**Goal**: Um administrador consegue configurar (ou auditar) os controles obrigatórios de um repositório de projeto usando apenas a documentação, e a automação detecta os mesmos controles.

**Independent Test**: Aplicar o checklist da documentação em um repositório novo e confirmar que todos os controles (branch protection, revisão, secrets, permissões de Actions) são configuráveis apenas com o texto do guia; comparar um repositório existente com o checklist e identificar rapidamente controles ausentes.

### Tests for User Story 1

- [x] T011 [P] [US1] Escrever teste de integração `tests/docs/security-baseline-checklist.test.sh` validando a presença das seções 1 e 4 do [documentation-contract.md](./contracts/documentation-contract.md) (AC-1)
- [x] T012 [P] [US1] Escrever teste de integração `tests/scripts/security-compliance-scan.detect.test.sh` validando a detecção de branch protection, revisão obrigatória, permissões de Actions e existência de secrets contra repositórios fixture (AC-2)

### Implementation for User Story 1

- [x] T013 [US1] Escrever `docs/security-baseline-ghe.md` — seções 1 (Baseline de Repositório de Projeto) e 4 (Padrão de Tokens e Secrets), conforme [documentation-contract.md](./contracts/documentation-contract.md)
- [x] T014 [P] [US1] Implementar avaliador do controle `branch-protection` em `scripts/security-compliance-scan.sh`
- [x] T015 [P] [US1] Implementar avaliador do controle `required-review` em `scripts/security-compliance-scan.sh`
- [x] T016 [P] [US1] Implementar avaliador do controle `actions-permissions` em `scripts/security-compliance-scan.sh`
- [x] T017 [P] [US1] Implementar avaliador do controle `secrets-configured` (apenas existência, nunca valores) em `scripts/security-compliance-scan.sh`
- [x] T018 [US1] Integrar os avaliadores de repositório ao loop principal de varredura, tratando o edge case "repositório sem permissões administrativas" (marcar como `repos_com_erro`, não falhar a execução) em `scripts/security-compliance-scan.sh` (depende de T014-T017)

**Checkpoint**: User Story 1 completa e testável de forma independente (MVP).

---

## Phase 4: User Story 2 - Definir governança de segurança para o Projeto Plataforma (Priority: P1)

**Goal**: O Project V2 consolidado (Projeto Plataforma) opera com matriz de permissões documentada e menor privilégio, e a automação detecta acesso administrativo fora da matriz aprovada.

**Independent Test**: Aplicar a matriz de acesso documentada ao Project V2 já existente e confirmar que apenas papéis autorizados administram views/campos críticos; validar que workflows que escrevem no board usam token com escopo mínimo e rotação definida.

### Tests for User Story 2

- [x] T019 [P] [US2] Escrever teste de integração `tests/scripts/security-compliance-scan.platform-access.test.sh` validando a avaliação da matriz de permissões do Project V2 (AC-3)
- [x] T020 [P] [US2] Escrever teste de integração `tests/docs/security-baseline-tokens.test.sh` validando a orientação de tokens/secrets para workflows que interagem com Projects (AC-4)

### Implementation for User Story 2

- [x] T021 [US2] Escrever `docs/security-baseline-ghe.md` — seções 2 (Governança do Projeto Plataforma) e 3 (Modelo de Acesso por Papéis), conforme [documentation-contract.md](./contracts/documentation-contract.md)
- [x] T022 [P] [US2] Implementar avaliador da matriz de permissões do Project V2 (GraphQL) em `scripts/security-compliance-scan.sh`
- [x] T023 [US2] Integrar o avaliador de plataforma ao loop de varredura, cobrindo o edge case "múltiplos projetos vinculados ao mesmo Project V2 com sensibilidade diferente" em `scripts/security-compliance-scan.sh` (depende de T022)

**Checkpoint**: User Stories 1 e 2 funcionam de forma independente.

---

## Phase 5: User Story 3 - Padronizar auditoria e operação contínua (Priority: P2)

**Goal**: Varredura semanal automatizada + relatório mensal consolidado + todo desvio detectado vira issue rastreável com prioridade e responsável.

**Independent Test**: Executar a varredura semanalmente por um mês e confirmar que o relatório mensal é produzido com status por controle (ok/pendente/risco) e que cada desvio identificado gerou uma issue rastreável.

### Tests for User Story 3

- [x] T024 [P] [US3] Escrever teste de integração `tests/workflows/security-compliance-scan.report.test.sh` validando o formato do relatório mensal, conforme [monthly-report-contract.md](./contracts/monthly-report-contract.md) (AC-5)
- [x] T025 [P] [US3] Escrever teste de integração `tests/scripts/security-compliance-scan.issue-creation.test.sh` validando os campos obrigatórios da issue (prioridade, responsável, prazo, critério de validação), conforme [finding-schema.md](./contracts/finding-schema.md) (AC-6)
- [x] T026 [P] [US3] Escrever teste de integração `tests/workflows/security-compliance-scan.discovery.test.sh` validando o agendamento semanal e a descoberta org-wide sem lista manual (AC-7)
- [x] T027 [P] [US3] Escrever teste de integração `tests/scripts/security-compliance-scan.auth.test.sh` validando que a autenticação usa exclusivamente o GitHub App, falhando explicitamente se os secrets estiverem ausentes (AC-8)

### Implementation for User Story 3

- [x] T028 [US3] Escrever `docs/security-baseline-ghe.md` — seções 5 (Checklist Operacional de Auditoria) e 6 (Procedimento de Não Conformidade), conforme [documentation-contract.md](./contracts/documentation-contract.md)
- [x] T029 [P] [US3] Implementar a agregação do `Compliance Report` mensal (4–5 execuções semanais) em `scripts/security-compliance-scan.sh`, conforme [monthly-report-contract.md](./contracts/monthly-report-contract.md)
- [x] T030 [P] [US3] Implementar o template de Issue de não conformidade (prioridade, responsável, prazo, critério de validação, labels da taxonomia existente) em `scripts/security-compliance-scan.sh`, conforme [finding-schema.md](./contracts/finding-schema.md)
- [x] T031 [US3] Conectar o gatilho semanal + `workflow_dispatch`, o aviso de rate limit (`repos_com_erro / repos_avaliados > 5%`) e a resolução do flag (piloto vs. org-wide) em `.github/workflows/security-compliance-scan.yml` (depende de T007, T010, T029, T030)
- [x] T032 [US3] Escrever `docs/security-baseline-ghe.md` — seções 7 (Referência ao Fluxo Nimbus Code) e 8 (Dependências de Workflows com Projects), conforme [documentation-contract.md](./contracts/documentation-contract.md)

**Checkpoint**: as 3 user stories funcionam de forma independente.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Fechar a feature com validação E2E, atualização de grafo/impact-map, catálogo de reuso e aprovação humana obrigatória (S4).

- [ ] T033 [P] Executar os passos 1–7 do [quickstart.md](./quickstart.md) de ponta a ponta no bounded context piloto (`spec-kit-workflow`)

  > **Nota (2026-08-20)**: bloqueada por `T004`/`T005`. A implementação de código,
  > documentação e testes automatizados foi concluída, mas a validação E2E do
  > quickstart depende do GitHub App real e dos secrets reais, ambos fora do
  > escopo do agente nesta sessão.

- [x] T034 [P] Adicionar entrada reutilizável em `docs/reuse-catalog.yaml` (tag: `org-wide-security-compliance-scan`) referenciando o `plan.md` desta feature
- [x] T035 [P] Confirmar que `specs/007-controle-seguranca-ghe-projetos-plataforma/graph.yaml` e `graph.md` continuam refletindo a implementação final (atualizar se algum módulo/script divergiu do planejado)
- [x] T036 [P] Confirmar que `specs/007-controle-seguranca-ghe-projetos-plataforma/impact-map.md` (riscos, rollback, critérios Go/No-Go) reflete a implementação final
- [ ] T037 [P] Atualizar o status de `docs/adr/0008-github-app-para-varredura-de-seguranca-org-wide.md` de "Em revisão" para "Aceita" após aprovação humana, registrando o aprovador

  > **Nota (2026-08-20)**: permanece pendente porque depende da aprovação humana
  > obrigatória registrada em `T038`. O ADR não foi alterado para “Aceita” sem
  > aprovação explícita de owner/revisor humano.
- [ ] T038 [Humano] Obter a aprovação humana obrigatória (S4) do `plan.md` completo e do ADR-0008 antes de habilitar o rollout org-wide

  ```markdown
  ## Contexto
  Esta feature foi classificada como S4 (Arquitetura, segurança, dados sensíveis
  ou integração crítica) — a régua de complexidade da Nimbus-Code exige revisão
  humana obrigatória antes de qualquer rollout em produção, sem exceção.

  ## Objetivo
  Obter aprovação humana explícita do plano completo (`plan.md`) e da decisão de
  credencial (ADR-0008) antes de expandir a varredura para 100% dos repositórios
  da organização.

  ## Resultado Esperado
  Aprovação registrada (nome/handle do aprovador + data) no ADR-0008 e no
  `plan.md`, liberando o avanço do flag `security.baseline_scan.org_wide_enabled`
  de `pilot-spec-kit-workflow` para `org-wide`.

  ## Critérios de Aceite
  - [ ] Responsável de plataforma/segurança revisou o `plan.md` completo desta feature
  - [ ] ADR-0008 revisado e seu status atualizado para "Aceita"
  - [ ] Critério de ativação do piloto (2 execuções semanais sem falso-positivo/erro de API) confirmado como satisfeito

  ## Passos Operacionais
  1. Revisor abre o PR desta feature e lê `plan.md`, `impact-map.md` e ADR-0008
  2. Revisor confirma que o piloto (T033) rodou sem falso-positivo
  3. Revisor aprova o PR e atualiza o campo "Revisores"/"Status" do ADR-0008
  4. Revisor autoriza a mudança do flag para `org-wide` (T031 já implementado, apenas o valor do flag muda)

  ## Dependências
  T033 (execução do piloto), T037 (ADR atualizado)

  ## Responsável
  Agente: não
  Humano: sim

  ## Estimativa de Esforço
  - Tokens (agente): N/A
  - Horas (humano): ~2 horas (revisão de plano + ADR + evidência do piloto)

  ## Referência
  - AC-ID: N/A (gate de governança, não critério funcional)
  - Feature: specs/007-controle-seguranca-ghe-projetos-plataforma
  - SPEC KIT COST: https://github.com/venha-pra-nuvem/spec-kit-cost
  ```

- [ ] T039 Preencher a tabela "Nimbus-Code — Estimativa vs. Consumo Real de Tokens e Horas Humanas" abaixo no fechamento da feature
- [ ] T040 Preencher a tabela "Nimbus-Code — Métricas de Branches e Saúde do Repositório (PMO)" abaixo semanalmente enquanto a feature estiver em andamento
- [ ] T041 [P] Manter [`docs/security-operations-manual.md`](/docs/security-operations-manual.md) sincronizado com a implementação final (papéis, ciclo semanal/mensal, rotação do GitHub App, rollback) — atualizar se qualquer comportamento do workflow/script divergir do descrito

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sem dependências — pode começar imediatamente
- **Foundational (Phase 2)**: Depende do Setup — BLOQUEIA todas as user stories (especialmente T004, ação manual administrativa)
- **User Stories (Phase 3+)**: Todas dependem da conclusão da Foundational
  - US1 e US2 podem avançar em paralelo (times diferentes)
  - US3 depende de elementos de US1 e US2 estarem funcionais (avaliadores de controle) antes de agregar o relatório mensal — mas pode iniciar documentação/testes em paralelo
- **Polish (Final Phase)**: Depende de todas as user stories desejadas estarem completas

### User Story Dependencies

- **User Story 1 (P1)**: Pode iniciar após Foundational (Phase 2) — sem dependência de outras stories
- **User Story 2 (P1)**: Pode iniciar após Foundational (Phase 2) — independente de US1, mas usa a mesma estrutura de `Compliance Finding` (Phase 2)
- **User Story 3 (P2)**: Pode iniciar documentação/testes após Foundational; a integração final (T031) depende dos avaliadores de US1 (T018) e US2 (T023) estarem prontos para agregar o relatório completo

### Within Each User Story

- Testes escritos e falhando antes da implementação
- Avaliadores de controle (equivalente a "models") antes da integração no loop principal (equivalente a "services")
- Documentação e automação da mesma story podem ser feitas em paralelo (arquivos diferentes)

### Parallel Opportunities

- Todas as tasks de Setup marcadas [P] podem rodar em paralelo
- T006, T007, T009, T010 (Foundational, marcadas [P]) podem rodar em paralelo após T002
- Após a Foundational, US1 e US2 podem ser trabalhadas em paralelo por pessoas/agentes diferentes
- Dentro de US1: T014-T017 (avaliadores) em paralelo; dentro de US3: T024-T027 (testes) em paralelo

---

## Parallel Example: User Story 1

```bash
# Testes de User Story 1 em paralelo:
Task: "Integration test tests/docs/security-baseline-checklist.test.sh"
Task: "Integration test tests/scripts/security-compliance-scan.detect.test.sh"

# Avaliadores de controle de User Story 1 em paralelo:
Task: "Implementar avaliador branch-protection em scripts/security-compliance-scan.sh"
Task: "Implementar avaliador required-review em scripts/security-compliance-scan.sh"
Task: "Implementar avaliador actions-permissions em scripts/security-compliance-scan.sh"
Task: "Implementar avaliador secrets-configured em scripts/security-compliance-scan.sh"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Completar Phase 1: Setup
2. Completar Phase 2: Foundational (CRÍTICO — inclui criação manual do GitHub App, T004)
3. Completar Phase 3: User Story 1
4. **PARE e VALIDE**: testar User Story 1 de forma independente (Passo 1 do `quickstart.md`)
5. Demonstrar ao responsável de plataforma antes de prosseguir

### Incremental Delivery

1. Setup + Foundational → fundação pronta (credencial, descoberta, deduplicação)
2. Adicionar User Story 1 → testar independentemente → demo (MVP!)
3. Adicionar User Story 2 → testar independentemente → demo
4. Adicionar User Story 3 → testar independentemente → demo (varredura semanal + relatório mensal completos)
5. Aprovação humana obrigatória (S4, T038) antes do rollout org-wide

### Parallel Team Strategy

Com múltiplos desenvolvedores/agentes:

1. Time completa Setup + Foundational em conjunto (T004 exige ação humana administrativa)
2. Após Foundational:
   - Agente/Dev A: User Story 1 (baseline de repositório)
   - Agente/Dev B: User Story 2 (governança do Projeto Plataforma)
   - Agente/Dev C: User Story 3 (auditoria contínua, pode começar documentação/testes em paralelo)
3. Stories se integram no workflow único (`security-compliance-scan.yml`) na Phase 5 (T031)

---

## Notes

- [P] tasks = arquivos diferentes, sem dependência
- [Story] label mapeia a task à user story correspondente para rastreabilidade
- T004 e T038 são as duas únicas tasks desta feature com `Responsável.Humano = sim` — todas as demais são executáveis por agente
- Verificar que os testes falham antes de implementar
- Commit após cada task ou grupo lógico
- Esta feature é **S4** — nenhuma expansão para "todos os repositórios da organização" deve ocorrer sem a aprovação humana registrada em T038

---

## Nimbus-Code — Contrato de Task Executável no GHE

*Referência do formato usado nas tasks humanas (T004, T038) acima — ver bloco completo em cada uma.*

- [x] Toda task com `Responsável.Humano = sim` inclui `Passos Operacionais` completos (T004, T038)
- [x] `Dependências` está preenchido com `Nenhuma` quando não existir bloqueador (T004)
- [x] `Referência` inclui AC-ID e link da feature de origem em ambas as tasks humanas
- [x] `SPEC KIT COST` presente em ambas (feature híbrida agente+humano)

## Nimbus-Code — Checklist de Qualidade de Código, Testes e Observabilidade

*Aplicável a toda tarefa desta lista que produz ou altera código. Marcar como concluída somente após validar cada item relevante ao artefato entregue.*

- [ ] `graph.yaml` e `graph.md` atualizados para refletir módulos adicionados/alterados (T035 cobre a verificação final; Graph Guard valida na PR)
- [ ] `impact-map.md` atualizado e revisado antes do merge (T036) — obrigatório, feature é S4
- [ ] Critérios de aceitação do `spec.md` cobertos com teste rastreável (ver AC-1..AC-8 mapeados em T011, T012, T019, T020, T024-T027)
- [ ] Feature flag `security.baseline_scan.org_wide_enabled` configurada e ativa, conforme Estratégia de Release do `plan.md`
- [ ] Testes contemplam os dois caminhos da flag (piloto ON / org-wide OFF e vice-versa)
- [ ] Estratégia de rollout progressivo executada no piloto (`spec-kit-workflow`) com evidência anexada ao PR (T033)
- [ ] Tarefa/issue de remoção da flag criada com prazo e owner definidos (30 dias após rollout 100% estável, ver `plan.md`)
- [ ] SLO medido (duração da execução, % `repos_com_erro`) dentro dos limites definidos no SLO Gate do `plan.md`
- [ ] Revisão de código por IA (GitHub Copilot code review) solicitada no PR e sem findings High/Critical pendentes
- [ ] Teste de integração cobrindo cada critério de aceitação do `spec.md` correspondente a esta feature
- [ ] Observabilidade instrumentada: logs do workflow + métrica de `repos_com_erro`/conformidade por controle no relatório mensal
- [ ] N/A — arquitetura de microsserviços (workflow batch single-run, sem correlation-id entre serviços internos)
- [ ] Bugs encontrados fora do escopo desta feature abertos como Issue no GitHub e atribuídos ao Copilot coding agent
- [ ] Entrada adicionada a `docs/reuse-catalog.yaml` (T034) — padrão reutilizável de varredura de conformidade org-wide
- [ ] `retro-template.md` preenchido em `specs/007-controle-seguranca-ghe-projetos-plataforma/retro.md` se a implementação divergir do plano

## Nimbus-Code — Métricas de Branches e Saúde do Repositório (PMO)

*Preencher semanalmente pelo Dev responsável pelo repositório enquanto a feature estiver em andamento (T040).*

| Métrica | Esta semana | Semana anterior | Tendência |
|---|---|---|---|
| Branches ativas (com PR aberto) | — | — | — |
| **Branches perdidas** (sem PR, inativas ≥ 3 dias) | — | — | — |
| Branches mergeadas e não-deletadas | — | — | — |
| PRs abertos por agente há > 5 dias sem revisão | — | — | — |

**Ação obrigatória quando "Branches perdidas" > 0:**
- [ ] Listar as branches perdidas (ver `docs/agent-session-manual.md`, seção 7)
- [ ] Para cada branch perdida: deletar ou abrir PR justificando a continuidade
- [ ] Registrar a causa raiz como comentário na tabela acima

## Nimbus-Code — Estimativa vs. Consumo Real de Tokens e Horas Humanas

*Preencher no fechamento da feature (após T040), comparando com a estimativa do `plan.md` (T039).*

| Métrica | Estimado (`plan.md`) | Real | Variância | Fonte da medição |
|---|---|---|---|---|
| Tokens (input+output) | ~140–190 mil | — *(preencher no fechamento)* | — | Copilot Usage da organização / uso reportado pelo agente |
| Horas humanas | ~8–14 horas | — *(preencher no fechamento)* | — | GitHub Project — campo "Horas Humanas" |

**Custo real total desta feature** (se a taxa custo/hora do time estiver documentada):
`[tokens reais × preço do modelo] + [horas humanas × custo/hora do time] = [valor]`

- [ ] Consumo real de tokens registrado e comparado com a estimativa do `plan.md`
- [ ] Horas humanas desta feature (T004, T038 e revisões de PR) lançadas no campo "Horas Humanas" do GitHub Project
- [ ] Se a variância de tokens for consistentemente alta (real >2× estimado), revisar o baseline de estimativa do projeto

## Nimbus-Code — Checklist de Qualidade para Tarefas de Infraestrutura/Deploy

*Aplicável às tasks desta lista que envolvem infraestrutura, pipelines ou automação de plataforma (T003, T004, T005, T031).*

- [ ] Sem segredo hardcoded — `SECURITY_SCAN_APP_PRIVATE_KEY` e demais credenciais apenas via GitHub Secrets
- [ ] Nenhum recurso de nuvem (AWS/GCP/Azure) provisionado por esta feature — N/A para regra de IaC/Terraform
- [ ] Versões fixadas (actions do workflow) — sem `@latest`/sem versão
- [ ] Permissões seguem least privilege — GitHub App com escopo somente-leitura mínimo (T004)
- [ ] Health check / critério de sucesso do workflow definido (SLO Gate do `plan.md`: conclusão em até 30 min, ≤5% de erro)
- [ ] N/A — Build multi-stage/Docker (workflow roda em runner padrão do GitHub Actions, sem containers)
- [ ] Testado via `workflow_dispatch` manual (piloto) antes do rollout semanal automático (T033)
- [ ] `docs/security-baseline-ghe.md` atualizada se o contrato da automação mudar
