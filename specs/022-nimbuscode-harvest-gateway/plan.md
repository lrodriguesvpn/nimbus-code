# Implementation Plan: Nimbus Harvest Gateway — Conector Multicloud para Harvest de Padrões

**Branch**: `022-nimbuscode-harvest-gateway` | **Date**: 2026-08-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/022-nimbuscode-harvest-gateway/spec.md`

## Summary

Um serviço HTTP compartilhado ("Gateway") que implementa, sem nenhuma alteração,
o contrato de entrada/saída já existente de `scripts/harvest-patterns.sh`
(`{repo, stack, prompt, metadata}` → `[{tag, description, example, source_file,
source_line}]`) e o roteia para um de três conectores de inferência LLM
plugáveis — Azure AI Foundry, Google (Vertex AI/Gemini) e AWS Bedrock —, cada
um com o modelo específico selecionável independentemente via variável de
ambiente. Abordagem técnica: função HTTP serverless (Azure Functions,
Consumption plan) com um Connector Router interno que seleciona o conector
ativo por configuração, sem acoplamento entre o contrato externo (harvest) e
o SDK/formato de cada provedor de nuvem.

## Technical Context

**Language/Version**: Python 3.11 (compatível com Azure Functions Python Worker v2, `openai`, `google-cloud-aiplatform`/`google-genai` e `boto3`)

**Primary Dependencies**: `azure-functions`, `openai` (cliente Azure OpenAI/Azure AI Foundry), `google-genai` ou `google-cloud-aiplatform` (Vertex AI/Gemini), `boto3` (AWS Bedrock Runtime), `opencensus-ext-azure` ou SDK equivalente do Application Insights

**Storage**: N/A para dados de negócio (serviço stateless). Application Insights (Azure Monitor) para logs estruturados/observabilidade — sem banco de dados próprio nesta v1

**Testing**: `pytest` — testes de contrato (payload de entrada/saída idêntico ao esperado por `harvest-patterns.sh`), testes unitários por conector com SDKs mockados (nenhuma chamada real de LLM em CI)

**Target Platform**: Azure Functions, plano Consumption, Linux

**Project Type**: web-service (API HTTP interna, sem UI)

**Performance Goals**: p99 < 20s por chamada (SLO já definido no spec.md) — compatível com latência típica de inferência LLM síncrona

**Constraints**: nunca persistir ou logar corpo de método/string literal/dado de runtime do código-fonte analisado (herda o Security Gate de SPEC-014, ADL-004); credenciais somente via Azure Key Vault/App Settings, nunca hardcoded; volume de chamadas é baixo por design (Harvest é on-demand, nunca contínuo/CI) — sem requisito de alta concorrência nesta v1

**Scale/Scope**: um único endpoint compartilhado por todos os repositórios satélite da organização; volume esperado é baixo (dezenas de chamadas/mês, não milhares) — dimensionamento não é um risco nesta v1

## Constitution Check

**Result**: ✅ PASSA, com pendências explícitas de execução humana documentadas no Security & DevSecOps Gate abaixo (provisionamento real de credenciais de 3 nuvens é responsabilidade administrativa, fora do escopo de código desta feature)

### Padrões Nimbus-Code aplicáveis

1. **Segurança e Dados**: sem segredo em texto plano (credenciais via Key Vault/App Settings); nenhum dado de runtime/código-fonte persistido — só metadados estruturais que o próprio `harvest-patterns.sh` já envia (ADL-004 de SPEC-014).
2. **Infraestrutura como Código**: recursos Azure (Function App, Storage Account de suporte, Application Insights) via Terraform — ver ADR a criar no repositório novo `nimbus-harvest-gateway`.
3. **Grafos de Módulos**: `graph.yaml`/`graph.md` obrigatórios — gerados na Fase 1 abaixo. `impact-map.md` obrigatório (S4).
4. **Escala de Complexidade S4**: modelo mais forte + revisão humana obrigatória — este plano entrega só o desenho, nenhum código será escrito sem aprovação explícita do Dev.
5. **Reutilização e Referência por Ponteiro**: reaproveita integralmente o contrato já existente de `scripts/harvest-patterns.sh` (SPEC-014) sem redefinir nada; reaproveita o precedente de repositório extraído do template (SPEC-003, `vpn-skills`) como modelo de governança.

## Project Structure

### Documentation (this feature)

```text
specs/022-nimbuscode-harvest-gateway/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
├── graph.yaml / graph.md
├── impact-map.md        # obrigatório — S4
└── tasks.md             # Phase 2 output (/speckit-tasks — ainda não gerado)
```

### Source Code (repositório novo: `venha-pra-nuvem/nimbus-harvest-gateway`)

```text
src/
├── router.py             # Connector Router — seleciona conector por HARVEST_LLM_PROVIDER
├── connectors/
│   ├── base.py            # Protocol/interface comum LLMConnector
│   ├── azure_ai.py         # AzureAIConnector (Azure AI Foundry — modelo via HARVEST_AZURE_MODEL)
│   ├── google.py           # GoogleConnector (Vertex AI/Gemini — modelo via HARVEST_GOOGLE_MODEL)
│   └── aws_bedrock.py      # AWSBedrockConnector (Bedrock Runtime — modelo via HARVEST_AWS_MODEL)
├── observability.py       # Log estruturado: repo, provider, model, tokens_used, custo estimado
└── function_app.py        # Azure Functions HTTP trigger — endpoint único (HARVEST_API_URL)

tests/
├── contract/               # Valida payload de entrada/saída idêntico ao esperado por harvest-patterns.sh
├── unit/                   # Um arquivo por conector, com SDK mockado
└── integration/            # Router + conector mockado, ponta a ponta sem chamada real de LLM

infra/
└── main.tf                 # Function App, Application Insights, Key Vault references (Terraform)
```

**Structure Decision**: serviço único (não monólito complexo) com um módulo por conector atrás de uma interface comum (`connectors/base.py`), seguindo o desenho já validado com o Dev nesta sessão. Repositório próprio (não vive dentro de `nimbus-code-spec-kit-template`), mesmo precedente de extração usado por `vpn-skills` (SPEC-003).

## Complexity Tracking

> Nenhuma violação do Constitution Check exige justificativa nesta tabela — a
> arquitetura segue os padrões da constituição (IaC via Terraform, sem SSO
> tradicional pois é um serviço machine-to-machine autenticado por token,
> observabilidade obrigatória desde a v1).

## Nimbus-Code — Classificação de Complexidade (S0–S4)

| Campo | Valor |
|---|---|
| **Nível** | **S4** |
| **Justificativa** | Serviço novo que gerencia credenciais de 3 provedores de nuvem distintos, é infraestrutura crítica compartilhada da qual todos os repositórios satélite passam a depender, e processa metadados de código-fonte de múltiplos repositórios enviando-os a provedores de IA externos — decisão de segurança/privacidade com impacto organizacional (ver justificativa completa no cabeçalho do `spec.md`) |
| **Modelo de IA** | Modelo mais forte (reasoning) |
| **Revisão humana obrigatória** | Sim (S4) |
| **Padrão reutilizado encontrado?** | Sim (tag: `github-app-auth-pattern` — ver `docs/reuse-catalog.yaml`, precedente de autenticação via GitHub App/token com fallback já usado em `sync-priority-field.yml`/`ensure-github-project.yml`; e o próprio precedente de extração de repositório de `vpn-skills`, SPEC-003) |
| **Estimativa de tokens (input+output)** | ~60–90 mil tokens (S4: research + data-model + contracts + 3 conectores + testes de contrato) |

## Nimbus-Code — Harness Gate

| Harness consultado (ID) | Padrão de erro evitado | Mitigação preventiva aplicada nesta feature |
|---|---|---|
| HRN-0002 | Decisão arquitetural imposta silenciosamente sem registrar no ADL | Cada escolha desta feature (linguagem, hosting, SDKs) foi discutida e confirmada explicitamente com o Dev antes de escrever este plano — nada foi decidido silenciosamente |
| HRN-0004 | Drift código↔produção (fechar tarefa sem validação real) | Este plano define testes de contrato específicos (payload idêntico ao esperado por `harvest-patterns.sh`) — nenhuma task de implementação será considerada concluída sem essa validação real |

**Resultado da consulta:**
- [x] Match encontrado — padrão(ões) de erro relevante(s) declarado(s) acima e mitigado(s)

## Nimbus-Code — Playbook de Sucesso Gate

| Padrão consultado (ID) | O que funcionou | Como foi reaplicado nesta feature |
|---|---|---|
| SUC-0002 | Rollout faseado manual (modo relatório → required) como padrão de baixo risco para gates de CI novos | Aplicado ao desenho de conectores: cada conector pode ser habilitado/testado isoladamente via `HARVEST_LLM_PROVIDER`, sem precisar dos 3 prontos simultaneamente para entregar valor incremental (US1 já entrega valor com só o conector Azure) |
| SUC-0003 | Uso de `docs/reuse-catalog.yaml` por ponteiro em vez de reexplicar solução do zero | O padrão de autenticação GitHub App + fallback (já usado em `sync-priority-field.yml`/`ensure-github-project.yml`) é referenciado, não redesenhado, para a autenticação do próprio endpoint do Gateway |

**Resultado da consulta:**
- [x] Match encontrado — padrão(ões) de sucesso relevante(s) declarado(s) acima e reaplicado(s)

## Nimbus-Code — Rastreabilidade AC → Teste → Módulo

| ID AC | Critério (resumo) | Tipo de teste planejado | Arquivo/módulo do teste | Justificativa de ausência (se N/A) |
|---|---|---|---|---|
| AC-1 | Contrato de harvest-patterns.sh inalterado, resposta 200 no formato esperado | contrato | `tests/contract/test_harvest_contract.py` | — |
| AC-2 | Roteamento Azure AI Foundry com modelo configurável | unitário | `tests/unit/test_azure_ai_connector.py` | — |
| AC-3 | Roteamento Google (Vertex AI/Gemini) com modelo configurável | unitário | `tests/unit/test_google_connector.py` | — |
| AC-4 | Roteamento AWS Bedrock com modelo configurável | unitário | `tests/unit/test_aws_bedrock_connector.py` | — |
| AC-5 | Troca de provedor/modelo sem mudança em repositório satélite | integração | `tests/integration/test_provider_switch.py` | — |
| AC-6 | Observabilidade por chamada (repo, provider, model, custo) | integração | `tests/integration/test_observability_logging.py` | — |
| AC-7 | Falha explícita com credencial ausente/inválida | unitário | `tests/unit/test_credential_failure_explicit.py` | — |

## Nimbus-Code — Module Dependency Graph

**Arquivos:**
- `specs/022-nimbuscode-harvest-gateway/graph.yaml` — atualizado nesta fase com os módulos internos planejados (Router + 3 conectores)
- `specs/022-nimbuscode-harvest-gateway/graph.md` — diagramas Mermaid correspondentes
- `specs/022-nimbuscode-harvest-gateway/impact-map.md` — obrigatório (S4), criado nesta fase

**Checklist de manutenção do grafo:**
- [x] `graph.yaml` criado/atualizado com todos os nós e arestas desta feature
- [x] `graph.md` criado/atualizado com diagrama por código e diagrama por business
- [x] Para S3/S4: `impact-map.md` criado/atualizado com análise de risco e plano de rollback
- [x] Nenhum módulo/serviço novo criado nesta feature está faltando no grafo
- [x] Dependências externas (third-party, cloud) declaradas em `externals` no `graph.yaml`
- [ ] Grafo será atualizado novamente após `/nimbus-code-implement` se a implementação divergir do plano

### Grafo do Contexto (Multi-Repo Brownfield)

| Campo | Valor |
|---|---|
| **Bounded context** | `nimbuscode-harvest-gateway` |
| **Grafo do contexto** | [specs/022-nimbuscode-harvest-gateway/graph.yaml](./graph.yaml) / [graph.md](./graph.md) — repositório `venha-pra-nuvem/nimbus-harvest-gateway` ainda não existe (`unanalyzed_repos`), grafo será reprocessado após a criação do repo |
| **Dependências relevantes para esta feature** | Todos os repositórios satélite da organização (consumidores futuros do endpoint) — nenhum ainda mapeado como dependente formal em `docs/bounded-contexts.yaml` |
| **Padrões de harvest aplicáveis** | Nenhuma (catálogo de reuso ainda não tem entradas originadas de harvest para este contexto — é, ironicamente, a própria feature que viabiliza o harvest funcionar) |

## Nimbus-Code — Estratégia de Release

| Campo | Valor |
|---|---|
| **Estratégia** | `direct` |
| **Feature flag name** | `N/A` |
| **Flag provider** | `N/A` |
| **Critério de ativação** | N/A — ver justificativa abaixo |
| **Critério de rollback** | Reverter `HARVEST_API_URL`/`HARVEST_API_TOKEN` de organização para vazio — `harvest-patterns.sh` volta a falhar explicitamente como hoje, sem afetar nenhum outro fluxo (Harvest é on-demand, nunca crítico de caminho principal) |

> **Regra**: features S3/S4 **obrigam** estratégia `flag`, `canary` ou `blue-green`
> — `direct` não é permitido sem justificativa explícita registrada aqui e no ADL.

**Justificativa para deploy `direct`:**
Esta feature não tem "tráfego de produção" a proteger no sentido tradicional — é uma ferramenta on-demand, invocada manualmente por um humano (nunca em CI, nunca automática), sem usuários finais nem SLA de disponibilidade contínua. Um rollback é literalmente esvaziar a variável de organização, revertendo ao estado atual (Harvest inutilizável, que é o status quo hoje). Ativação incremental faz mais sentido **por conector** (US1 antes de US2/US3) do que por flag de release — já coberto pela ordem de prioridade das User Stories no `spec.md`.

## Nimbus-Code — Cost Reference

| Campo | Valor |
|---|---|
| **Token estimate range** | ~60–90 mil tokens (agente, fases spec+plan+tasks+implementação dos 3 conectores) |
| **Human effort estimate range** | ~6–10 horas (revisão de segurança S4 obrigatória, provisionamento de credenciais reais nas 3 nuvens, revisão de PR) |
| **Tracking method** | Tabela "Estimativa vs. Consumo Real de Tokens e Horas Humanas" no `tasks.md` + campo "Horas Humanas" no GitHub Project do repositório `nimbus-harvest-gateway` |
| **Budget ceiling (optional)** | Custo de inferência LLM estimado em centavos a poucos dólares por rodada completa de harvest (ver estimativa detalhada discutida com o Dev) — não é o driver de custo desta feature; o custo real está no esforço de engenharia, coberto pela estimativa de horas humanas acima |

## Nimbus-Code — SLO Gate

| Componente | Latência p99 | Taxa de erro máx. | Disponibilidade | RTO | RPO |
|---|---|---|---|---|---|
| Endpoint de harvest (qualquer conector ativo) | 20000 ms | 2,0% | 99,5% | 30 min | N/A |
| Registro de observabilidade (custo/uso por chamada) | 2000 ms | 1,0% | 99,9% | 15 min | 5 min |

**SLOs não definidos nesta feature e justificativa:**
Nenhum componente ficou sem SLO — os dois SLOs acima cobrem os dois componentes reais desta feature (o próprio endpoint e o registro de observabilidade).

## Nimbus-Code — Security & DevSecOps Gate

| Domínio | Controles aplicáveis | Escapável via ADL? | Status | Observações |
|---|---|---|---|---|
| **Backup & Disaster Recovery** | Todo datastore com dado real (produção) tem backup automatizado, retenção definida e restore testado | **Não — bloqueante** | N/A | Serviço stateless, sem datastore de dado de negócio nesta v1 — nada a fazer backup |
| Autenticação (SSO) | Sistemas novos (greenfield) devem usar SSO | Sim, com justificativa no ADL | Escapado, justificado | Serviço machine-to-machine (chamado só por `harvest-patterns.sh` via token), sem usuário humano fazendo login — SSO tradicional não se aplica; ver ADL abaixo |
| Segredos no código/repositório | Nunca em texto plano; secret scanning bloqueia merge | **Não — bloqueante** | Pendente (implementação) | Credenciais das 3 nuvens via Azure Key Vault/App Settings — nenhuma linha de código com segredo hardcoded |
| Branch/merge protegido | PR obrigatório + revisão antes de merge | **Não — bloqueante** | Pendente (repo novo) | Repositório `nimbus-harvest-gateway` deve nascer já com branch protection configurada (ver issue #325 desta organização, mesmo padrão pedido org-wide) |
| Isolamento de ambiente | Credencial de produção nunca usada em dev/test | **Não — bloqueante** | Pendente (implementação) | Testes usam SDKs mockados (ver Technical Context) — nenhuma credencial real em CI |
| Containers | N/A | Sim, com justificativa no ADL | N/A | Azure Functions Consumption plan não usa container customizado nesta v1 |
| CI/CD | Segredos via cofre/CI secrets, least privilege | Sim, com justificativa no ADL | Pendente (implementação) | GitHub Actions do repo novo usa OIDC/Federated Credentials do Azure, sem secret de longa duração no repositório |
| IaC — provider(s) usado(s) | 100% via IaC, Terraform como padrão | Sim, com justificativa no ADL | Pendente (implementação) | Terraform para Function App + Application Insights + referências a Key Vault |
| Banco de dados | TLS/mTLS obrigatório | **Não — bloqueante** | N/A | Sem banco de dados de negócio nesta v1 |
| **Firewall / Segmentação de rede** | Regras de firewall/least exposure | Sim, com justificativa no ADL | Pendente (implementação) | Endpoint HTTP autenticado por token; avaliar IP allowlist por organização na fase de implementação |
| Observabilidade | Logs, métricas e alertas mínimos | Sim, com justificativa no ADL | Planejado (FR-005/FR-006, AC-6) | Application Insights desde a v1 — não é opcional para esta feature, é requisito funcional (FR-005) |

**Riscos identificados e decisão:**
- **Credenciais de 3 nuvens simultâneas**: risco de superfície de ataque ampliada (3 conjuntos de credenciais em vez de 1). Decisão: cada conector só é habilitado (credenciais provisionadas) quando sua User Story correspondente for implementada — não provisionar as 3 nuvens de uma vez sem necessidade real (mitigar agora, não em fase seguinte).
- **Endpoint compartilhado por toda a organização = single point of failure para o recurso Harvest**: aceitável, pois Harvest já é opcional/on-demand hoje (falha do Gateway não afeta nenhum fluxo crítico de nenhum repositório) — decisão: aceitar o risco, documentado aqui, sem endurecimento adicional na v1.

## Nimbus-Code — Qualidade de Código, Testes e Observabilidade Gate

| Domínio | Controles aplicáveis | Status | Observações |
|---|---|---|---|
| Revisão de código por IA | GitHub Copilot code review solicitado em todo PR desta feature | Planejado | A ser solicitado no repositório novo, em cada PR de implementação |
| Testes integrados | Cada AC do `spec.md` tem teste de integração/unitário/contrato correspondente | Planejado | Ver tabela de Rastreabilidade AC → Teste → Módulo acima — 100% das 7 ACs cobertas |
| Observabilidade | Logs estruturados, métricas e alertas mínimos instrumentados | Planejado | Application Insights desde a v1 (FR-005) |
| Arquitetura distribuída / Microsserviços | Correlation-id/trace-id propagado ponta a ponta | N/A | Serviço de request/response único (sem coreografia entre múltiplos serviços internos) — cada chamada de harvest é uma transação isolada, sem propagação de trace entre serviços distintos |
| Gestão de bugs | Bugs fora do escopo abertos como Issue e atribuídos ao Copilot coding agent | Planejado | Política padrão do bundle, sem desvio nesta feature |

**Critérios de aceitação sem teste de integração automatizado (se houver) — justificativa:**
Nenhum. Todas as 7 ACs têm teste planejado (contrato, unitário ou integração) — ver tabela de Rastreabilidade acima.

## Nimbus-Code — Architecture Decision Log

| Decisão | Alternativas consideradas | Opção escolhida | Trade-off assumido | Justificativa do desvio (se aplicável) | Aprovado por |
|---|---|---|---|---|---|
| Hospedagem do Gateway | Azure Functions (Consumption) vs. Azure Container Apps vs. AWS Lambda vs. Google Cloud Functions | Azure Functions (Consumption) | Menor esforço operacional e custo (escala a zero, sem servidor ocioso) vs. menor controle fino de runtime que um container daria | N/A — não é desvio de padrão, é escolha de implementação dentro do escopo desta feature | — |
| Padrão de conectores multicloud | Um serviço por nuvem (3 deploys separados) vs. um único serviço com Router interno | Router interno único | Menor duplicação operacional (1 endpoint, 1 deploy) vs. acoplamento de todos os SDKs de nuvem no mesmo processo (mitigado por interface comum `LLMConnector`) | N/A — decisão de arquitetura desta feature, sem violar padrão institucional | — |
| Ausência de SSO tradicional | SSO obrigatório para todo sistema greenfield (regra padrão da constituição) vs. autenticação machine-to-machine por token | Autenticação por token (`HARVEST_API_TOKEN`), sem SSO | Modelo mais simples de operar para um serviço sem usuário humano interativo, mas exige rotação de token cuidadosa como controle compensatório | Serviço é chamado exclusivamente por `harvest-patterns.sh` (script, não humano) — SSO não tem sentido operacional aqui; escapável via ADL conforme a própria constituição prevê | Dev (sessão de planejamento 2026-08-24) |
