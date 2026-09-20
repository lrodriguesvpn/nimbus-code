# Tasks: Nimbus Harvest Gateway — Conector Multicloud para Harvest de Padrões

**Input**: Design documents from `/specs/022-nimbuscode-harvest-gateway/`

**Prerequisites**: `plan.md` ✅, `spec.md` ✅, `research.md` ✅, `data-model.md` ✅, `contracts/` ✅, `quickstart.md` ✅, `graph.yaml` ✅, `graph.md` ✅, `impact-map.md` ✅ (S4 — obrigatório)

**Organization**: Tasks agrupadas por User Story (US1 P1, US2 P1, US3 P2, US4 P2) para entrega incremental e teste independente, conforme `spec.md`. Repositório de destino já criado: `venha-pra-nuvem/nimbus-harvest-gateway`.

## Reconciliação de evidências — 2026-09-20

Fonte consultada: [satélite, commit 4de7532](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-harvest-gateway/tree/4de753209caf0c0c19c3e67856d86dcb794f6292).
O satélite registra 21/31 tarefas marcadas. Aqui foram reconciliadas 19/31:
estrutura, dependências, endpoint/router/observabilidade, três conectores,
testes de contrato/unitários e consulta KQL existem no código publicado.
Isso comprova entrega de arquivos, não execução real contra provedores.
Os testes remotos não foram executados nesta auditoria; README relata 28
testes e tasks relata 31, divergência que requer atualização com um log real.

T029 permanece aberta: o catálogo central ainda não registra o padrão. T030
permanece aberta até validar a correspondência do grafo com a implementação e
reconciliar as cópias históricas de specs no satélite. Conforme SPEC 020, a
fonte canônica de governança é este repositório; não apagar cópias remotas
automaticamente.

- Azure/T012 e validação T013: `venha-pra-nuvem/nimbus-harvest-gateway#7`.
- Google/T017 e validação T018: `venha-pra-nuvem/nimbus-harvest-gateway#8`.
- AWS/T022 e validação T023: `venha-pra-nuvem/nimbus-harvest-gateway#9`.
- Aprovação S4/T028: `venha-pra-nuvem/nimbus-harvest-gateway#10`, #397 e #447.
- Cenários operacionais T026/T027, métricas T031 e reconciliação T029/T030
  permanecem pendentes para acompanhamento em #447; não há aprovação implícita.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode rodar em paralelo (arquivos diferentes, sem dependência)
- **[Story]**: US1, US2, US3 ou US4 (mapeado ao `spec.md`)
- Caminhos de arquivo exatos em cada descrição, relativos ao repositório novo `nimbus-harvest-gateway`
- Os cabeçalhos das Fases 3–6 trazem a anotação `[USN — nimbuscode-harvest-gateway]`, consumida pelo
  `/speckit-taskstoissues` para rotear as Tasks dessas fases ao repositório de serviço declarado em
  `docs/bounded-contexts.yaml` (`venha-pra-nuvem/nimbus-harvest-gateway`) em vez do Repo Central — ver
  `docs/developer-guide.md`, seção 5.7. As Fases 1, 2 e 7 permanecem sem anotação de propósito: ainda
  não há repositório de serviço quando o Setup roda (T001 o cria), e Foundational/Polish são
  transversais ao Repo Central.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Criar o repositório novo e a estrutura de projeto antes de qualquer lógica de conector.

- [x] T001 [Humano] Criar o repositório `venha-pra-nuvem/nimbus-harvest-gateway` no GitHub Enterprise e rodar `bootstrap.sh` (Nimbus Code) nele, instalando o preset `nimbus-code-standards`

  ```markdown
  ## Contexto
  Esta feature (spec 022) planeja um serviço novo que ainda não tem
  repositório próprio — todo o desenho técnico foi feito em
  `nimbus-code-spec-kit-template` como artefato de planejamento (mesmo
  precedente de `vpn-skills`, SPEC-003).

  ## Objetivo
  Criar o repositório de destino e aplicar a governança Nimbus-Code padrão
  antes de qualquer código ser escrito.

  ## Resultado Esperado
  Repositório `venha-pra-nuvem/nimbus-harvest-gateway` criado, com
  `bootstrap.sh` executado (preset `nimbus-code-standards` instalado,
  `.specify/` versionado, labels/GitHub Project configurados).

  ## Critérios de Aceite
  - [ ] Repositório criado na organização `venha-pra-nuvem`
  - [ ] `bootstrap.sh` executado com sucesso (preset instalado)
  - [ ] Branch padrão configurado como `develop` (ver issue #325 desta organização — mesmo padrão pedido org-wide)
  - [ ] Branch protection configurada em `main` e `develop` (idem #325)

  ## Passos Operacionais
  1. Criar o repositório vazio na organização `venha-pra-nuvem`.
  2. Rodar `curl -fsSL <url-raw-do-bootstrap.sh> | bash` dentro do repositório clonado.
  3. Confirmar branch padrão e branch protection conforme a issue #325.
  4. Referenciar esta feature canônica no README do satélite, sem criar uma
     segunda fonte de verdade. Cópias históricas já existentes exigem
     reconciliação revisada, conforme SPEC 020 e T030.

  ## Dependências
  Nenhuma

  ## Responsável
  Agente: não
  Humano: sim

  ## Estimativa de Esforço
  - Tokens (agente): N/A
  - Horas (humano): ~1 hora

  ## Referência
  - AC-ID: N/A (pré-requisito de infraestrutura)
  - Feature: specs/022-nimbuscode-harvest-gateway
  ```

- [x] T002 [P] Criar estrutura de diretórios `src/`, `src/connectors/`, `tests/contract/`, `tests/unit/`, `tests/integration/`, `infra/` no repositório novo, conforme Project Structure do `plan.md`
- [x] T003 [P] Configurar projeto Python (`pyproject.toml` ou `requirements.txt`) com `azure-functions`, `openai`, `google-genai` (ou `google-cloud-aiplatform`), `boto3`, `pytest`, conforme Technical Context do `plan.md`

**Checkpoint**: repositório existe, governança Nimbus-Code aplicada, estrutura de pastas pronta.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Endpoint, Router e observabilidade — base sem a qual nenhuma User Story funciona.

**⚠️ CRITICAL**: Nenhuma User Story pode ser considerada completa/testável sem esta fase.

- [x] T004 Implementar `src/connectors/base.py` com a interface `LLMConnector` (Protocol) e a exceção `HarvestConnectorError`, conforme `contracts/llm-connector-interface.md`
- [x] T005 Implementar `src/function_app.py` — endpoint HTTP único, valida o payload de entrada (`repo`, `stack`, `prompt`, `metadata`) contra `contracts/harvest-external-contract.md`, sem introduzir nenhum campo novo (FR-001)
- [x] T006 Implementar `src/router.py` — Connector Router, lê `HARVEST_LLM_PROVIDER`, valida contra os 3 valores reconhecidos (`azure`, `google`, `aws`), levanta `HarvestConnectorError` explícito se não reconhecido (FR-009)
- [x] T007 Implementar `src/observability.py` — grava `ObservabilityRecord` (repo, provider, model, tokens_used, custo estimado, status, timestamp) no Application Insights a cada requisição, sucesso ou falha (FR-005)
- [x] T008 [P] Criar teste de contrato `tests/contract/test_harvest_contract.py` — valida que a resposta do Gateway é bit-a-bit compatível com o formato já esperado por `scripts/harvest-patterns.sh` (AC-1, test ref `test_AC1_harvest_contract_unchanged`)

**Checkpoint**: endpoint responde, roteia (mesmo sem nenhum conector real ainda) e grava observabilidade — pronto para a primeira User Story.

---

## Phase 3: User Story 1 — Conector Azure AI Foundry (Priority: P1) 🎯 MVP [US1 — nimbuscode-harvest-gateway]

**Goal**: Rodar `scripts/harvest-patterns.sh` com sucesso contra o Azure AI Foundry, com modelo selecionável.

**Independent Test**: Configurar `HARVEST_LLM_PROVIDER=azure` e `HARVEST_AZURE_MODEL=<modelo>` no Gateway, rodar `scripts/harvest-patterns.sh . --dry-run` num repositório satélite de teste e confirmar HTTP 200 com padrões propostos — Independent Test do `spec.md`, US1.

- [x] T009 [P] [US1] Implementar `src/connectors/azure_ai.py` (`AzureAIConnector`), modelo selecionável via `HARVEST_AZURE_MODEL`, conforme `contracts/llm-connector-interface.md`
- [x] T010 [US1] Registrar `AzureAIConnector` no dicionário `CONNECTORS` do Router (depende de T006, T009)
- [x] T011 [P] [US1] Criar teste unitário `tests/unit/test_azure_ai_connector.py` com SDK Azure mockado — nenhuma chamada real de LLM (AC-2, test ref `test_AC2_azure_connector_model_selection`)
- [ ] T012 [Humano] [US1] Provisionar recurso real do Azure AI Foundry + Key Vault (Terraform, `infra/main.tf`) e configurar `AZURE_AI_ENDPOINT`/`AZURE_AI_KEY` no Gateway

  ```markdown
  ## Contexto
  O conector Azure precisa de um recurso real do Azure AI Foundry para
  funcionar de ponta a ponta — os testes unitários (T011) usam SDK mockado,
  mas a validação real (T013) exige credenciais de verdade.

  ## Objetivo
  Provisionar o recurso Azure AI Foundry via Terraform e configurar as
  credenciais no Gateway (Azure Key Vault ou App Settings).

  ## Resultado Esperado
  `infra/main.tf` aplicado com sucesso; `AZURE_AI_ENDPOINT`/`AZURE_AI_KEY`
  disponíveis para o Function App via referência de Key Vault (nunca em
  texto plano).

  ## Critérios de Aceite
  - [ ] Recurso Azure AI Foundry criado via `terraform apply`, sem alteração manual
  - [ ] Ao menos um modelo deployado no catálogo (ex.: `gpt-4o-mini`)
  - [ ] Credenciais acessíveis pelo Function App via Key Vault reference

  ## Passos Operacionais
  1. Revisar/aplicar `infra/main.tf` com o recurso Azure AI Foundry.
  2. Deployar o modelo inicial escolhido no catálogo do Azure AI Foundry.
  3. Configurar `AZURE_AI_ENDPOINT`/`AZURE_AI_KEY` como referência de Key Vault
     no Function App (nunca hardcoded).

  ## Dependências
  T002 (estrutura `infra/`)

  ## Responsável
  Agente: não (provisionamento de recurso de nuvem real e custo associado)
  Humano: sim

  ## Estimativa de Esforço
  - Tokens (agente): N/A
  - Horas (humano): ~1–2 horas

  ## Referência
  - AC-ID: AC-2
  - Feature: specs/022-nimbuscode-harvest-gateway
  ```

- [ ] T013 [US1] Validar o Cenário 1 do [quickstart.md](./quickstart.md) de ponta a ponta contra o recurso Azure real (depende de T012)

**Checkpoint**: MVP entregável — Harvest funciona de ponta a ponta contra ao menos 1 provedor real.

---

## Phase 4: User Story 2 — Conector Google (Vertex AI/Gemini) (Priority: P1) [US2 — nimbuscode-harvest-gateway]

**Goal**: Trocar o provedor ativo de Azure para Google sem nenhuma mudança em repositório satélite.

**Independent Test**: Trocar `HARVEST_LLM_PROVIDER` de `azure` para `google` só no Gateway, rodar o mesmo `harvest-patterns.sh` num repositório satélite sem alterar nada nele, e confirmar que a resposta agora vem do Google — Independent Test do `spec.md`, US2.

- [x] T014 [P] [US2] Implementar `src/connectors/google.py` (`GoogleConnector`), modelo selecionável via `HARVEST_GOOGLE_MODEL`
- [x] T015 [US2] Registrar `GoogleConnector` no dicionário `CONNECTORS` do Router (depende de T006, T014)
- [x] T016 [P] [US2] Criar teste unitário `tests/unit/test_google_connector.py` com SDK Google mockado (AC-3, test ref `test_AC3_google_connector_model_selection`)
- [ ] T017 [Humano] [US2] Provisionar projeto Google Cloud/Vertex AI e configurar `GOOGLE_PROJECT_ID`/`GOOGLE_CREDENTIALS` no Gateway (mesmo padrão de T012, adaptado ao Google)
- [ ] T018 [US2] Validar o Cenário 2 do [quickstart.md](./quickstart.md) — trocar `HARVEST_LLM_PROVIDER` de `azure` para `google` e confirmar zero mudança necessária em repositório satélite (AC-5, test ref `test_AC5_provider_model_switch_zero_satellite_change`)

**Checkpoint**: 2 provedores reais funcionando — troca de nuvem comprovadamente transparente para os repositórios satélite.

---

## Phase 5: User Story 3 — Conector AWS Bedrock (Priority: P2) [US3 — nimbuscode-harvest-gateway]

**Goal**: Completar o multicloud com o terceiro provedor (AWS Bedrock) e comprovar troca de modelo dentro do mesmo provedor.

**Independent Test**: Trocar `HARVEST_AWS_MODEL` para um modelo diferente dentro do mesmo provedor e confirmar, via `ObservabilityRecord`, que a próxima chamada usou o novo modelo — Independent Test do `spec.md`, US3.

- [x] T019 [P] [US3] Implementar `src/connectors/aws_bedrock.py` (`AWSBedrockConnector`), modelo (`modelId`) selecionável via `HARVEST_AWS_MODEL`, autenticação via IAM role/instance profile (nunca access key hardcoded)
- [x] T020 [US3] Registrar `AWSBedrockConnector` no dicionário `CONNECTORS` do Router (depende de T006, T019)
- [x] T021 [P] [US3] Criar teste unitário `tests/unit/test_aws_bedrock_connector.py` com SDK `boto3` mockado (AC-4, test ref `test_AC4_aws_bedrock_connector_model_selection`)
- [ ] T022 [Humano] [US3] Provisionar acesso IAM ao AWS Bedrock Runtime (role, não access key) e configurar `AWS_REGION` no Gateway (mesmo padrão de T012, adaptado à AWS)
- [ ] T023 [US3] Validar o Cenário 3 do [quickstart.md](./quickstart.md) — trocar `HARVEST_AZURE_MODEL` (ou `HARVEST_AWS_MODEL`) para outro modelo dentro do mesmo provedor e confirmar no `ObservabilityRecord`

**Checkpoint**: os 3 provedores planejados estão implementados e validados — Gateway verdadeiramente multicloud.

---

## Phase 6: User Story 4 — Observabilidade de Custo e Uso Consolidado (Priority: P2) [US4 — nimbuscode-harvest-gateway]

**Goal**: Visibilidade centralizada de custo/uso por repositório, provedor e modelo; falhas sempre explícitas.

**Independent Test**: Fazer chamadas de harvest de 2+ repositórios diferentes e confirmar que cada uma aparece individualmente no registro de observabilidade — Independent Test do `spec.md`, US4.

- [x] T024 [P] [US4] Criar consulta KQL de referência (documentada em `README.md` do novo repo) para consolidar `ObservabilityRecord` por repositório/provedor/modelo no Application Insights (AC-6, test ref `test_AC6_observability_per_call`)
- [x] T025 [P] [US4] Criar teste unitário `tests/unit/test_credential_failure_explicit.py` — confirma que credencial ausente/inválida produz erro explícito, nunca resposta 200 silenciosa (AC-7, test ref `test_AC7_explicit_credential_failure`)
- [ ] T026 [US4] Validar o Cenário 4 do [quickstart.md](./quickstart.md) — observabilidade de custo por repositório (depende de T007, T024)
- [ ] T027 [US4] Validar os Cenários 5 e 6 do [quickstart.md](./quickstart.md) — falha explícita com credencial ausente e provedor não reconhecido (depende de T006, T025)

**Checkpoint**: todas as 4 User Stories entregues — Gateway multicloud completo, observável e com falhas sempre explícitas.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Fechamento da feature — segurança, documentação, catalogação de reuso, métricas.

- [ ] T028 [Humano] Obter a aprovação humana obrigatória (S4) do `plan.md` completo e do `impact-map.md` antes do merge final em `main` do repositório novo

  ```markdown
  ## Contexto
  Esta feature é classificada como S4 (credenciais de 3 nuvens + infraestrutura
  crítica compartilhada) — a constituição Nimbus-Code exige revisão humana
  obrigatória antes de qualquer merge para produção.

  ## Objetivo
  Revisar e aprovar formalmente o desenho de segurança (Security &
  DevSecOps Gate do `plan.md`) e os riscos identificados no `impact-map.md`.

  ## Resultado Esperado
  Aprovação registrada (comentário de PR ou ata) confirmando que os
  controles de segurança (credenciais via Key Vault, sem SSO justificado,
  observabilidade obrigatória) foram revisados e aceitos.

  ## Critérios de Aceite
  - [ ] Security & DevSecOps Gate do `plan.md` revisado item a item
  - [ ] Riscos do `impact-map.md` revisados e aceitos ou mitigados
  - [ ] Aprovação registrada com nome/handle do aprovador

  ## Passos Operacionais
  1. Revisar a seção Security & DevSecOps Gate do `plan.md`.
  2. Revisar a tabela de riscos do `impact-map.md`.
  3. Registrar aprovação explícita (comentário no PR de implementação).

  ## Dependências
  T009–T027 (implementação dos 3 conectores completa)

  ## Responsável
  Agente: não
  Humano: sim

  ## Estimativa de Esforço
  - Tokens (agente): N/A
  - Horas (humano): ~1 hora

  ## Referência
  - AC-ID: N/A (gate de governança S4)
  - Feature: specs/022-nimbuscode-harvest-gateway
  ```

- [ ] T029 [P] Adicionar entrada a `docs/reuse-catalog.yaml` (deste repositório-fonte) documentando o padrão "Gateway multicloud com Connector Router" como reaproveitável para futuras integrações de IA multi-provedor
- [ ] T030 Atualizar `graph.yaml`/`graph.md` do repositório novo se a implementação divergir do planejado nesta sessão
- [ ] T031 Preencher a tabela "Nimbus-Code — Estimativa vs. Consumo Real de Tokens e Horas Humanas" abaixo, no fechamento da feature

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sem dependências — primeiro passo
- **Foundational (Phase 2)**: Depende de Phase 1 (estrutura de projeto existir)
- **User Story 1 (Phase 3)**: Depende de Phase 2 (Router e endpoint existirem)
- **User Story 2 (Phase 4)**: Depende de Phase 2; independente de US1 (pode rodar em paralelo depois de Phase 2)
- **User Story 3 (Phase 5)**: Depende de Phase 2; independente de US1/US2
- **User Story 4 (Phase 6)**: Depende de Phase 2 (observability.py) e beneficia-se de US1/US2/US3 já implementadas para ter dados reais a observar
- **Polish (Phase 7)**: Depende de todas as User Stories completas

### User Story Dependencies

- **US1 (P1)**: Depende só da Fase Foundational — primeira a ser implementada (MVP)
- **US2 (P1)**: Independente de US1 tecnicamente, mas priorizada logo em seguida (mesmo nível de prioridade no `spec.md`)
- **US3 (P2)**: Independente de US1/US2
- **US4 (P2)**: Tecnicamente independente, mas mais valiosa depois de ao menos 1 conector real existir

### Parallel Opportunities

- T002, T003 (Phase 1) em paralelo
- T009, T014, T019 (conectores de US1/US2/US3) podem ser implementados em paralelo por squads diferentes, já que cada um é um arquivo isolado sob a mesma interface `LLMConnector`
- T011, T016, T021, T025 (testes unitários) em paralelo com a implementação dos conectores correspondentes

---

## Parallel Example: User Story 1

```bash
# Lançar em paralelo (arquivos diferentes, sem dependência entre si):
Task: "T009 [P] [US1] Implementar src/connectors/azure_ai.py"
Task: "T011 [P] [US1] Criar tests/unit/test_azure_ai_connector.py"
```

---

## Implementation Strategy

### MVP First (User Story 1 apenas)

1. Completar Phase 1: Setup (repositório criado, governança aplicada)
2. Completar Phase 2: Foundational (endpoint, Router, observabilidade)
3. Completar Phase 3: User Story 1 — conector Azure AI Foundry
4. Já é um incremento de valor entregável: Harvest funciona de ponta a ponta contra 1 provedor real, mesmo sem Google/AWS ainda

### Incremental Delivery

1. Setup + Foundational → base pronta
2. US1 (Azure) → MVP, Harvest funciona pela primeira vez em qualquer repositório da organização
3. US2 (Google) → comprova a promessa central do desenho: trocar de nuvem sem tocar em repositório satélite
4. US3 (AWS) → completa o multicloud
5. US4 (Observabilidade) → fecha o ciclo de visibilidade de custo
6. Polish → segurança S4 aprovada, reuso catalogado, métricas fechadas

---

## Notes

- [P] = tasks sem dependência entre si (podem rodar em paralelo)
- [USN] = rastreabilidade da tarefa à User Story do `spec.md`
- Nenhum arquivo/repositório existente é alterado por esta feature — é 100% aditivo em repositório novo (Estratégia de Release do `plan.md`: `direct`, sem toggle)
- Commits granulares recomendados: um por User Story completa
- Cada conector (`AzureAIConnector`, `GoogleConnector`, `AWSBedrockConnector`) só deve ter suas credenciais reais provisionadas quando sua User Story correspondente for implementada — nunca provisionar as 3 nuvens de uma vez (mitigação de risco já registrada no `impact-map.md`)

---

## Nimbus-Code — Contrato de Task Executável no GHE

*Toda task orientada a execução humana deve permitir execução sem depender de
leitura adicional de spec/plan. Ver T001, T012, T017, T022 e T028 acima como
exemplos já preenchidos neste formato.*

- [x] Toda task com `Responsável.Humano = sim` inclui `Passos Operacionais` completos (T001, T012, T017, T022, T028)
- [x] `Dependências` está preenchido com `Nenhuma` quando não existir bloqueador
- [x] `Referência` inclui AC-ID e link da feature de origem

## Nimbus-Code — Checklist de Qualidade de Código, Testes e Observabilidade

*Aplicável a toda tarefa desta lista que produz ou altera código.*

- [ ] `graph.yaml` e `graph.md` atualizados para refletir módulos adicionados ou alterados por esta tarefa (Graph Guard valida automaticamente na PR)
- [x] Para complexidade S4: `impact-map.md` atualizado e revisado antes do merge (T028)
- [ ] Critérios de aceitação da `spec.md` cobertos com ID de teste rastreável — ver tabela de Rastreabilidade AC → Teste → Módulo do `plan.md` (100% das 7 ACs mapeadas)
- [x] Estratégia de release: `direct` — justificada no `plan.md` (sem toggle, sem flag aplicável)
- [ ] SLO medido em staging dentro dos limites definidos no SLO Gate do `plan.md` (p99 < 20s)
- [ ] Revisão de código por IA (GitHub Copilot code review) solicitada no PR e sem findings High/Critical pendentes
- [ ] Teste de integração/unitário/contrato cobrindo cada AC do `spec.md` — ver tabela de Rastreabilidade do `plan.md`
- [x] Observabilidade instrumentada: `src/observability.py` grava logs estruturados a cada chamada (FR-005)
- [ ] N/A — sem arquitetura de microsserviços distribuída nesta feature (serviço único de request/response)
- [ ] Bugs encontrados durante o desenvolvimento que não foram corrigidos na própria tarefa foram abertos como Issue e atribuídos ao Copilot coding agent
- [ ] Entrada adicionada a `docs/reuse-catalog.yaml` (T029)
- [ ] "O que deu certo aqui que vale a pena repetir?" — resposta registrada em `docs/playbooks/success-catalog.yaml` ou "Nada relevante a registrar"
- [ ] `retro-template.md` preenchido em `specs/022-nimbuscode-harvest-gateway/retro.md` apenas se a implementação divergir deste plano

## Nimbus-Code — Checklist de Qualidade para Tarefas de Infraestrutura/Deploy

*Aplicável às tarefas T001, T012, T017, T022 (provisionamento de recursos de nuvem).*

- [ ] Sem segredo hardcoded (usa Key Vault/App Settings/secret do CI)
- [ ] Recurso provisionado 100% via IaC (Terraform, `infra/main.tf`) — nenhuma criação manual via console/CLI
- [ ] Versões fixadas (runtime Python, actions, providers Terraform) — sem `latest` implícito
- [ ] Permissões seguem least privilege (IAM role do Bedrock, Managed Identity do Azure, service account do Google escopados ao mínimo necessário)
- [ ] Testado localmente ou via `terraform plan`/dry-run antes do merge
- [ ] Documentação/README do módulo atualizada, se o contrato mudou

## Nimbus-Code — Métricas de Branches e Saúde do Repositório (PMO)

| Métrica | Esta semana | Semana anterior | Tendência |
|---|---|---|---|
| Branches ativas (com PR aberto) | | | |
| **Branches perdidas** (sem PR, inativas ≥ 3 dias) | | | ↑ / ↓ / = |
| Branches mergeadas e não-deletadas | | | |
| PRs abertos por agente há > 5 dias sem revisão | | | |

## Nimbus-Code — Estimativa vs. Consumo Real de Tokens e Horas Humanas

| Métrica | Estimado (`plan.md`) | Real | Variância | Fonte da medição |
|---|---|---|---|---|
| Tokens (input+output) | ~60–90 mil | [preencher ao fechar] | — | Copilot Usage da organização |
| Horas humanas | ~6–10 horas | [total lançado no GitHub Project do repo novo] | — | GitHub Project — campo "Horas Humanas" |
