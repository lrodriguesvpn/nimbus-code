# Feature Specification: Nimbus Harvest Gateway — Conector Multicloud para Harvest de Padrões

**Feature Branch**: `022-nimbuscode-harvest-gateway`
**Created**: 2026-08-24
**Status**: Draft
**Input**: Solicitação formalizada do usuário: "Resolver a lacuna de que `scripts/harvest-patterns.sh` exige um backend HTTP (`HARVEST_API_URL`/`HARVEST_API_TOKEN`) que nunca foi construído, impedindo o uso real do Harvest em qualquer repositório. Criar um serviço compartilhado (Gateway), usado por todos os repositórios satélite via um único endpoint, com conectores plugáveis para múltiplas nuvens — Azure AI (com modelo escolhível dentro do Azure AI Foundry), Google (Vertex AI/Gemini, com modelo escolhível) e AWS Bedrock (com modelo escolhível) — mantendo o contrato de entrada/saída já existente do `harvest-patterns.sh` inalterado."

## Nimbus-Code — Cabeçalho Obrigatório da Spec

| Campo | Valor |
|---|---|
| **Feature slug** | `022-nimbuscode-harvest-gateway` |
| **Complexidade estimada** | S4 |
| **Bounded Context** | `nimbuscode-harvest-gateway` |
| **PR de referência / Issue** | novo |
| **Data alvo de entrega** | sem data |

> S0 = doc · S1 = função isolada · S2 = módulo · S3 = múltiplos módulos · S4 = arquitetura, segurança, dados ou integração crítica

**Justificativa da complexidade S4**: serviço novo que gerencia credenciais de 3 provedores de nuvem distintos, é infraestrutura crítica compartilhada da qual todos os repositórios satélite passam a depender, e processa metadados de código-fonte de múltiplos repositórios enviando-os a provedores de IA externos — decisão de segurança/privacidade com impacto organizacional. Exige revisão humana obrigatória antes de qualquer implementação, conforme a escala S0–S4 da constituição.

## Nimbus-Code — SLO Alvo desta Feature

| Componente | Latência p99 (ms) | Taxa de erro máx. (%) | Disponibilidade alvo | RTO | RPO |
|---|---|---|---|---|---|
| Endpoint de harvest (qualquer conector ativo) | 20000 | 2,0% | 99,5% | 30 min | N/A (stateless, sem persistência de dados de negócio) |
| Registro de observabilidade (custo/uso por chamada) | 2000 | 1,0% | 99,9% | 15 min | 5 min |

## Nimbus-Code — Objetivo e Contexto

**Objetivo:** oferecer um único endpoint HTTP compartilhado (`HARVEST_API_URL`), configurado uma vez em nível de organização, que implementa o contrato já existente de `scripts/harvest-patterns.sh` e roteia a chamada para um dos três conectores de nuvem — Azure AI Foundry, Google (Vertex AI/Gemini) ou AWS Bedrock — com o modelo específico dentro de cada provedor sendo configurável independentemente, sem exigir nenhuma alteração no script consumidor nem em nenhum repositório satélite.

**Motivação:** hoje `scripts/harvest-patterns.sh` já existe e é shipado a todo projeto via o preset `nimbus-code-standards`, mas exige credenciais de um backend (`HARVEST_API_URL`/`HARVEST_API_TOKEN`) que nunca foi construído em lugar nenhum — nenhum repositório da organização consegue usar o Harvest de fato. Sem um serviço compartilhado, cada squad teria que construir isoladamente sua própria integração de IA, duplicando esforço de engenharia, sem padronização de escolha de modelo nem visibilidade centralizada de custo.

**Critério de done (alto nível):** qualquer repositório satélite, apenas com as variáveis de organização já configuradas, consegue rodar `scripts/harvest-patterns.sh` com sucesso contra qualquer um dos 3 provedores suportados, com modelo específico selecionável dentro de cada um, e toda chamada fica observável (repositório de origem, provedor, modelo, custo estimado).

**Fora de escopo:** alterar o contrato de entrada/saída de `scripts/harvest-patterns.sh`; construir UI de administração; suportar mais de 3 provedores nesta v1; treinar ou fazer fine-tuning de modelo próprio; lidar com volume de chamadas contínuo/alta concorrência (o Harvest é on-demand por design, nunca automático).

## Nimbus-Code — Hybrid Collaboration Model

| Papel | Responsabilidades | Critério de handoff | Escalação |
|---|---|---|---|
| Agente | Estruturar spec/plan/tasks, desenhar a interface comum dos conectores, propor esquema de configuração e observabilidade | Repassa quando houver decisão de custo/orçamento de provisionamento de nuvem ou escolha de provedor padrão inicial | Architecture board |
| Dev | Validar viabilidade técnica de cada conector, revisar credenciais/segurança antes do merge (S4 — obrigatório), implementar após aprovação do plano | Repassa ao Digital Engineering quando a escolha de hospedagem/custo recorrente exigir aprovação orçamentária | Tech lead |
| Business Analyst | Validar que o modelo de custo por chamada é compreensível/reportável para squads que vão adotar o Harvest | Repassa à Digital Engineering quando o critério de sucesso de adoção exigir ajuste de política de uso | Product owner |
| Digital Engineering | Provisionar/aprovar recursos de nuvem reais (Azure AI Foundry, Google Cloud project, AWS Bedrock access), definir provedor padrão inicial e política de custo por repositório | Repassa para liderança quando o custo agregado projetado exigir revisão de orçamento organizacional | Engineering manager |

## Nimbus-Code — Critérios de Aceitação (formato BDD)

> **AC-1**
> **Given** um repositório satélite com `HARVEST_API_URL`/`HARVEST_API_TOKEN` de organização configurados apontando para o Gateway,
> **When** `scripts/harvest-patterns.sh` for executado sem nenhuma alteração no script,
> **Then** a chamada retorna HTTP 200 com o array de padrões no formato exato já esperado pelo script.
> **Test ref:** `test_AC1_harvest_contract_unchanged`

> **AC-2**
> **Given** o Gateway configurado com `HARVEST_LLM_PROVIDER=azure` e `HARVEST_AZURE_MODEL=<modelo>`,
> **When** uma requisição de harvest chegar,
> **Then** ela é roteada ao Azure AI Foundry usando exatamente o modelo configurado (qualquer modelo do catálogo Azure AI Foundry, não só a família GPT).
> **Test ref:** `test_AC2_azure_connector_model_selection`

> **AC-3**
> **Given** o Gateway configurado com `HARVEST_LLM_PROVIDER=google` e `HARVEST_GOOGLE_MODEL=<modelo>`,
> **When** uma requisição de harvest chegar,
> **Then** ela é roteada ao Google (Vertex AI/Gemini) usando exatamente o modelo configurado.
> **Test ref:** `test_AC3_google_connector_model_selection`

> **AC-4**
> **Given** o Gateway configurado com `HARVEST_LLM_PROVIDER=aws` e `HARVEST_AWS_MODEL=<modelo>`,
> **When** uma requisição de harvest chegar,
> **Then** ela é roteada ao AWS Bedrock usando exatamente o modelo (`modelId`) configurado.
> **Test ref:** `test_AC4_aws_bedrock_connector_model_selection`

> **AC-5**
> **Given** uma troca de provedor ativo ou de modelo dentro do mesmo provedor, feita só por variável de ambiente do Gateway,
> **When** a próxima requisição de qualquer repositório satélite for feita,
> **Then** nenhum repositório satélite precisa de qualquer alteração de código ou configuração local.
> **Test ref:** `test_AC5_provider_model_switch_zero_satellite_change`

> **AC-6**
> **Given** uma chamada de harvest concluída, com sucesso ou falha,
> **When** o Gateway processar a resposta,
> **Then** registra em observabilidade central o repositório de origem, o provedor, o modelo e os tokens consumidos/custo estimado.
> **Test ref:** `test_AC6_observability_per_call`

> **AC-7**
> **Given** credenciais ausentes ou inválidas para o provedor atualmente selecionado,
> **When** uma requisição chegar ao Gateway,
> **Then** o Gateway falha explicitamente (nunca silenciosamente), identificando qual credencial específica está faltando.
> **Test ref:** `test_AC7_explicit_credential_failure`

## Nimbus-Code — Backlog Hierarchy (EPIC/FEATURE/US)

| Nível | Valor | Observação |
|---|---|---|
| **EPIC** | Aprendizado Organizacional e Reuso de Padrões Técnicos | Guarda-chuva do Harvest Engineering (SPEC-014) e deste Gateway |
| **FEATURE** | Nimbus Harvest Gateway — Conector Multicloud | Escopo desta spec |
| **US1** | Implementar conector Azure AI Foundry com modelo selecionável | Provedor primário sugerido, dado uso corporativo já existente de Azure |
| **US2** | Implementar conector Google (Vertex AI/Gemini) com modelo selecionável | Segunda opção de nuvem |
| **US3** | Implementar conector AWS Bedrock com modelo selecionável | Terceira opção de nuvem, completa o multicloud |
| **US4** | Prover endpoint único compartilhado, com config e credenciais em nível de organização | Elimina configuração por repositório |
| **US5** | Observabilidade de custo e uso por repositório, provedor e modelo | Alimenta o modelo de custo real já existente na constituição (seção 8) |

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Rodar o Harvest pela primeira vez contra o Azure AI Foundry (Priority: P1)

Como Dev de um repositório satélite, quero configurar `HARVEST_API_URL`/`HARVEST_API_TOKEN` de organização e rodar `scripts/harvest-patterns.sh` com sucesso, sem precisar construir nenhum backend próprio.

**Why this priority**: hoje o Harvest existe como ferramenta mas é inutilizável — sem isso, nenhum repositório consegue extrair valor do recurso.

**Independent Test**: num repositório satélite qualquer, com as variáveis de organização já configuradas, rodar `scripts/harvest-patterns.sh . --dry-run` e confirmar retorno HTTP 200 com padrões propostos, sem nenhuma configuração adicional por repositório.

**Acceptance Scenarios**:

1. **Given** um repositório satélite com as variáveis de organização configuradas, **When** `scripts/harvest-patterns.sh` for executado, **Then** o Gateway responde com sucesso usando o provedor/modelo padrão configurado no Gateway.
2. **Given** o mesmo repositório, **When** as credenciais do Azure AI Foundry estiverem ausentes no Gateway, **Then** a chamada falha com mensagem explícita, nunca silenciosamente.

---

### User Story 2 - Trocar de provedor de nuvem sem tocar em nenhum repositório satélite (Priority: P1)

Como Digital Engineer, quero trocar o provedor de IA ativo (Azure → Google → AWS ou qualquer combinação) mudando só a configuração do Gateway, para não depender de coordenar mudanças em dezenas de repositórios satélite.

**Why this priority**: é o valor central do desenho de Gateway compartilhado — sem isso, cada repositório ficaria acoplado a um provedor específico.

**Independent Test**: trocar `HARVEST_LLM_PROVIDER` no Gateway de `azure` para `google`, rodar o mesmo `harvest-patterns.sh` num repositório satélite sem alterar nada nele, e confirmar que a resposta agora vem do Google.

**Acceptance Scenarios**:

1. **Given** o Gateway rodando com `HARVEST_LLM_PROVIDER=azure`, **When** o valor for trocado para `google` e uma nova chamada for feita, **Then** a resposta passa a vir do conector Google, sem nenhuma mudança em qualquer repositório satélite.
2. **Given** a troca de provedor, **When** a chamada anterior já estava em andamento, **Then** ela é concluída normalmente pelo provedor anterior (sem quebra abrupta de requisição em curso).

---

### User Story 3 - Trocar de modelo dentro do mesmo provedor (Priority: P2)

Como Dev responsável pelo Gateway, quero trocar o modelo específico usado dentro de um provedor (ex.: de um modelo mais barato para um mais robusto) via configuração, para poder ajustar custo/qualidade sem reescrever o conector.

**Why this priority**: permite calibrar custo vs. qualidade de detecção de padrões sem esforço de engenharia repetido.

**Independent Test**: trocar `HARVEST_AZURE_MODEL` de um modelo para outro no Gateway e confirmar, via log de observabilidade, que a próxima chamada usou o novo modelo.

**Acceptance Scenarios**:

1. **Given** o Gateway configurado com `HARVEST_AZURE_MODEL=<modelo A>`, **When** o valor for trocado para `<modelo B>`, **Then** a próxima chamada usa o modelo B, registrado corretamente na observabilidade.

---

### User Story 4 - Observar custo e uso consolidado por repositório (Priority: P2)

Como Digital Engineering, quero ver quanto cada repositório está gastando em chamadas de Harvest, por provedor e modelo, para ter visibilidade de custo antes de expandir o uso.

**Why this priority**: sem isso, o custo real do recurso fica invisível até virar um problema orçamentário.

**Independent Test**: fazer 2-3 chamadas de harvest de repositórios diferentes e confirmar que cada uma aparece separadamente no registro de observabilidade, com repositório, provedor, modelo e custo estimado.

**Acceptance Scenarios**:

1. **Given** chamadas de harvest de repositórios diferentes, **When** consultar o registro de observabilidade, **Then** cada chamada aparece individualmente identificada por repositório, provedor, modelo e custo estimado.

### Edge Cases

- O que acontece quando o provedor selecionado está fora do ar ou retorna erro 5xx?
- Como o sistema lida com uma resposta do LLM que não seja um JSON válido no formato esperado (array de `{tag, description, example, source_file, source_line}`)?
- O que acontece quando as credenciais do provedor atualmente selecionado não estão configuradas no Gateway?
- Como o sistema lida com um repositório satélite chamando com volume muito acima do esperado (uso indevido/loop acidental), dado que o Harvest deveria ser sempre on-demand e esporádico?
- O que acontece se `HARVEST_LLM_PROVIDER` apontar para um valor não reconhecido (nenhum dos 3 conectores)?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O Gateway MUST expor um único endpoint HTTP que implementa exatamente o contrato de entrada/saída já usado por `scripts/harvest-patterns.sh`, sem exigir qualquer alteração nesse script.
- **FR-002**: O Gateway MUST suportar ao menos 3 conectores de provedor de nuvem: Azure AI Foundry, Google (Vertex AI/Gemini) e AWS Bedrock.
- **FR-003**: A escolha do provedor ativo MUST ser configurável via variável de ambiente do Gateway (`HARVEST_LLM_PROVIDER`), sem exigir redeploy de código do conector.
- **FR-004**: Dentro de cada provedor, o modelo específico MUST ser configurável via variável de ambiente própria (`HARVEST_AZURE_MODEL`, `HARVEST_GOOGLE_MODEL`, `HARVEST_AWS_MODEL`).
- **FR-005**: O Gateway MUST registrar, para cada requisição, o repositório de origem, o provedor, o modelo e os tokens consumidos/custo estimado, de forma consultável centralmente.
- **FR-006**: O Gateway MUST falhar explicitamente (nunca silenciosamente) quando credenciais do provedor selecionado estiverem ausentes ou inválidas, identificando qual credencial falta.
- **FR-007**: O endpoint MUST ser único e compartilhado — configurado uma vez em nível de organização (`HARVEST_API_URL`/`HARVEST_API_TOKEN`), consumido por todos os repositórios satélite sem configuração adicional por repositório.
- **FR-008**: O Gateway MUST NEVER persistir ou logar corpo de método, string literal ou dado de runtime do código-fonte analisado — apenas os metadados estruturais já enviados por `scripts/harvest-patterns.sh`, preservando o Security Gate definido em SPEC-014 (allowlist estrita de metadados estruturais).
- **FR-009**: O Gateway MUST responder com erro claro e não roteável quando `HARVEST_LLM_PROVIDER` apontar para um valor não reconhecido.

### Key Entities

- **Requisição de Harvest**: `repo`, `stack`, `prompt`, `metadata` — herda integralmente o contrato já existente de `scripts/harvest-patterns.sh`, sem campos novos.
- **Configuração de Provedor**: provedor ativo, modelo ativo dentro do provedor, credenciais associadas (nunca em texto plano/hardcoded).
- **Registro de Observabilidade**: repositório de origem, provedor, modelo, tokens consumidos, custo estimado, timestamp, status (sucesso/falha), motivo da falha quando aplicável.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Um repositório satélite consegue rodar `scripts/harvest-patterns.sh` com sucesso na primeira tentativa, usando só as variáveis de organização já documentadas, sem configuração adicional própria.
- **SC-002**: Trocar o provedor de IA ativo (ex.: Azure → Google) leva menos de 5 minutos de configuração no Gateway e não exige nenhuma mudança em nenhum repositório satélite.
- **SC-003**: 100% das chamadas de harvest (sucesso ou falha) ficam registradas com repositório de origem, provedor, modelo e custo estimado, disponíveis para consulta.
- **SC-004**: 100% das chamadas com credencial ausente ou inválida resultam em erro explícito identificando a credencial faltante — nenhuma falha silenciosa.

## Assumptions

- Cada squad/Digital Engineering decide qual provedor de nuvem usar como padrão inicial; esta spec não define preferência técnica entre Azure/Google/AWS.
- O provisionamento administrativo dos recursos de nuvem reais (recurso Azure AI Foundry, projeto Google Cloud/Vertex AI, acesso AWS Bedrock) é responsabilidade fora do escopo desta feature — assumido como uma dependência de configuração de plataforma, não implementação de código.
- O volume de chamadas é baixo (Harvest é on-demand por design, nunca contínuo/CI), então não há requisito de alta concorrência ou autoscaling agressivo nesta v1.
- O contrato de `scripts/harvest-patterns.sh` (payload de entrada/saída) permanece inalterado nesta feature — o Gateway se adapta a ele, o script não muda.
- Repositório próprio (`venha-pra-nuvem/nimbus-harvest-gateway`) será criado para hospedar a implementação; esta spec vive no repositório-fonte (`nimbus-code-spec-kit-template`) apenas como artefato de planejamento, seguindo o mesmo precedente de `vpn-skills` (SPEC-003).
