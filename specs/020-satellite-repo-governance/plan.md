# Implementation Plan: Governança de Repos Satélite e Intake Greenfield MultiRepo

**Branch**: `020-satellite-repo-governance` | **Data**: 2026-08-24 | **Spec**: [spec.md](./spec.md)

**Entrada**: Especificação da feature em [spec.md](./spec.md)

## Summary

Formalizar a camada de governança que diferencia projetos greenfield e brownfield
no bootstrap do Nimbus Code, registra a decisão entre monorepo e multirepo com
justificativa explícita, orienta o momento correto para sugerir uma topologia
inicial de repositórios satélite por domínio após a primeira spec estrutural do
produto e reforça o repo central do produto como fonte única de verdade para
`spec.md`, `plan.md`, `tasks.md` e demais artefatos de processo.

## Technical Context

**Language/Version**: Bash 3.2+, Markdown, YAML e Mermaid

**Primary Dependencies**:
- [bootstrap.sh](../../bootstrap.sh)
- [docs/developer-guide.md](../../docs/developer-guide.md)
- [docs/bounded-contexts.yaml](../../docs/bounded-contexts.yaml)
- [README.md](../../README.md)
- [templates/BROWNFIELD-SETUP-CHECKLIST.md](../../templates/BROWNFIELD-SETUP-CHECKLIST.md)
- [templates/workflows/update-speckit-and-bundle.yml](../../templates/workflows/update-speckit-and-bundle.yml)

**Storage**:
- `specs/020-satellite-repo-governance/`
- `.specify/feature.json`
- `docs/bounded-contexts.yaml`

**Testing**:
- validação manual do fluxo de bootstrap greenfield vs brownfield
- revisão documental guiada por checklist
- testes shell/bats para as heurísticas de entrada e mensagens críticas do bootstrap

**Target Platform**: repositório central Nimbus Code no GHE + repositórios satélite bootstrapados pelo bundle oficial

**Project Type**: governança de processo + tooling de bootstrap multi-repo

**Performance Goals**:
- classificação greenfield/brownfield sem exigir intervenção adicional além dos prompts já previstos
- captura da decisão mono vs multirepo no mesmo fluxo inicial do bootstrap

**Operational Definitions**:
- `relevant application code` = diretórios ou arquivos que representam implementação real do produto, como `src/`, `app/`, `packages/`, `services/`, `frontend/`, `backend/`, manifests de build/runtime já ligados a código (`package.json` com scripts de app, `pom.xml`, `build.gradle`, `pyproject.toml`, `go.mod`, `.csproj`) e testes de aplicação vinculados a esse código.
- artefatos isolados como `README`, `LICENSE`, `.gitignore`, workflows, templates, `.editorconfig`, pastas vazias, scripts de setup ou esqueleto sem código executável **não** contam, sozinhos, como `relevant application code`.
- `decision_reason` = texto curto em linguagem natural contendo: motivo principal da escolha, trade-off esperado e papel/responsável que confirmou a decisão.
- `domain ownership` = time, papel ou repositório responsável por cada domínio satélite proposto ou customizado.

**Constraints**:
- esta feature não cobre bugfixes já tratados separadamente no bootstrap
- a decisão greenfield vs brownfield precisa ser compreensível por humano, não só por heurística implícita
- `specs/` continua proibido em repositórios satélite como prática padrão
- a topologia sugerida de domínios deve acelerar, sem virar taxonomia rígida
- o mecanismo oficial de atualização do bundle entre central e satélites deve permanecer auditável via PR

## Escopo Consolidado: Governança Permanente vs. Bugfix Operacional (FR-011)

**Governança Permanente — Regras de Processo (EM ESCOPO desta feature 020)**:
- Classificação greenfield vs brownfield baseada em presença de código de aplicação relevante
- Decisão entre monorepo e multirepo com registro obrigatório de justificativa, trade-off esperado e ownership
- Sugestão de topologia inicial de domínios satélite (FRONT/BACK/DESIGN/DATA/JOBS) como baseline recomendada, não rígida
- Regra permanente: repo central como fonte única de verdade para specs, planos, tasks, grafos e checklists
- Regra permanente: repositórios satélite recebem código, testes, IaC, PRs e tasks roteadas, mas não mantêm artefatos locais de spec
- Mecanismo oficial e auditável de alinhamento central → satélite por PR revisado, sem bypass direto em branch principal
- Definições operacionais explícitas: `relevant application code`, `decision_reason`, `domain ownership`
- Documentação de processo em `docs/developer-guide.md`, `docs/bounded-contexts.yaml`, `README.md` e templates

**Bugfix Operacional — Correções Técnicas Pontuais (FORA DO ESCOPO desta feature 020)**:
- Erros de URL quebrada no bootstrap
- Regressões de leitura interativa (pipe, heredocs)
- Regressões de execução de comandos shell
- Erros de escape de caracteres em prompts
- Correções de compatibilidade de versão do Bash
- Outros defects no bootstrap já identificados como backlog de manutenção

> **Justificativa**: Separar governança (permanente, tranversal, que altera fluxo de entrada de todos os projetos greenfield futuros) de bugfix operacional (correcional, puntual, que melhora a qualidade atual da ferramenta) reduz risco de confundir regras arquiteturais com ajustes técnicos isolados. Isso garante rastreabilidade clara de quais decisões são estruturantes e quais são manutenção.

> **Política de PR**: PRs desta feature devem detalhar se a mudança pertence a "Governança Permanente" ou, se houver acidental overlap com bugfix, declarar isso explicitamente e separar em PR distinta.

**Scale/Scope**: todos os produtos da organização que adotarem o bootstrap Nimbus Code daqui em diante; efeito transversal sobre repo central, satélites e fluxo de onboarding greenfield

## Constitution Check

*GATE: deve passar antes da pesquisa da Fase 0. Revalidar após o design da Fase 1.*

| Gate | Status | Observação |
|---|---|---|
| Backup & DR | ✅ N/A | Sem datastore novo de produção |
| Segredos no código | ✅ | Mudanças previstas são em prompts, scripts, documentação e templates; nenhum secret novo |
| Branch/merge protegido | ✅ | Entrega continua por PR revisado |
| Isolamento de ambiente | ✅ | O fluxo distingue contexto de repo sem usar credenciais de produção |
| Observabilidade | ✅ N/A | Sem runtime de produção novo; feature altera fluxo de bootstrap e documentação |
| IaC | ✅ N/A | Não provisiona infraestrutura |

**Gate: APROVADO** — sem violações bloqueantes identificadas nesta fase de planejamento.

## Project Structure

### Artefatos da feature

```text
specs/020-satellite-repo-governance/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── graph.yaml
├── graph.md
├── impact-map.md
├── contracts/
│   └── topology-intake.contract.md
└── checklists/
    └── requirements.md
```

### Arquivos candidatos a alteração fora da pasta da feature

```text
bootstrap.sh                                      # classificador greenfield/brownfield + intake de topologia
.specify/feature.json                             # persistência da decisão estrutural e rastreabilidade do intake
docs/developer-guide.md                           # processo operacional de repo central/satélites
docs/bounded-contexts.yaml                        # reforço normativo do papel de repo central e registro de domínios
README.md                                         # onboarding greenfield e decisão mono/multirepo
templates/BROWNFIELD-SETUP-CHECKLIST.md           # alinhamento do fluxo de setup quando brownfield
templates/workflows/update-speckit-and-bundle.yml # referência oficial de alinhamento contínuo central -> satélite
```

### Decisão estrutural

```text
Governança centralizada em um repo central + consumo controlado pelos satélites.
A feature altera o fluxo de entrada do bootstrap e a documentação de operação,
sem criar um segundo mecanismo paralelo fora do bundle oficial.
```

---

## Nimbus-Code — Classificação de Complexidade (S0–S4)

| Campo | Valor |
|---|---|
| **Nível** | **S3** |
| **Justificativa** | Cruza múltiplos módulos do processo: `bootstrap.sh`, documentação operacional, registro de bounded contexts, templates de onboarding e governança multi-repo central → satélite |
| **Modelo de IA** | Reasoning |
| **Revisão humana obrigatória** | Não (S0–S3), mas altamente recomendada por alterar regra estrutural de onboarding |
| **Padrão reutilizado encontrado?** | Sim (tag: `multirepo-bounded-context-routing`); Sim (tag: `bootstrap-github-app-auth`) |
| **Estimativa de tokens (input+output)** | ~24–36 mil tokens |

---

## Nimbus-Code — Harness Gate

| Harness consultado (ID) | Padrão de erro evitado | Mitigação preventiva aplicada nesta feature |
|---|---|---|
| HRN-0001 | Scope creep do agente fora do escopo explícito | O plano limita a feature à governança central/satélite e intake de topologia, sem absorver bugfixes paralelos do bootstrap |
| HRN-0002 | Decisão arquitetural imposta silenciosamente | O plano obriga a registrar justificativa da escolha monorepo vs multirepo e qualquer desvio da topologia sugerida |
| HRN-0003 | Re-derivação de padrão já existente sem consultar reuso | O plano reaproveita o padrão multi-repo da feature 006 e o padrão de alinhamento operacional do bootstrap da feature 008 |

**Resultado da consulta:**
- [x] Match encontrado — padrões relevantes declarados e mitigados
- [ ] Nenhum padrão de erro relevante encontrado para este domínio
- [ ] Catálogo vazio — nenhum padrão disponível para consulta

---

## Nimbus-Code — Rastreabilidade AC → Teste → Módulo

| ID AC | Critério (resumo) | Tipo de teste planejado | Arquivo/módulo do teste | Justificativa de ausência |
|---|---|---|---|---|
| AC-1 | Repo sem código relevante entra como greenfield | Integração shell / manual | `tests/bootstrap/*` + `bootstrap.sh` | Heurística de filesystem precisa de fixture controlada |
| AC-2 | Repo com código relevante entra como brownfield | Integração shell / manual | `tests/bootstrap/*` + `bootstrap.sh` | Idem AC-1 |
| AC-3 | Motivo da decisão mono vs multirepo é obrigatório | Integração shell / manual | `bootstrap.sh` + documentação do fluxo | Validação textual do prompt/saída |
| AC-4 | Baseline FRONT/BACK/DESIGN/DATA/JOBS é sugerido após a primeira spec | Manual / walkthrough | `bootstrap.sh` + `docs/developer-guide.md` + `README.md` | Bootstrap só faz o handoff; a sugestão detalhada vive na documentação operacional |
| AC-5 | Domínios alternativos são aceitos com justificativa | Manual / checklist | `docs/developer-guide.md` | Regra operacional/documental |
| AC-6 | Specs vivem apenas no repo central | Manual / inspeção documental | `docs/developer-guide.md` + `docs/bounded-contexts.yaml` | Regra de governança |
| AC-7 | Satélite segue mecanismo oficial de update por PR | Manual / inspeção documental | `templates/workflows/update-speckit-and-bundle.yml` + `docs/developer-guide.md` | Processo validado por documentação + workflow existente |

---

## Nimbus-Code — Module Dependency Graph

**Arquivos:**
- [graph.yaml](./graph.yaml) — fonte de verdade estruturada
- [graph.md](./graph.md) — diagramas Mermaid
- [impact-map.md](./impact-map.md) — obrigatório (S3)

**Checklist de manutenção do grafo:**
- [x] `graph.yaml` criado/atualizado com todos os módulos desta feature
- [x] `graph.md` criado/atualizado com diagrama por código e por business
- [x] Para S3: `impact-map.md` criado com análise de risco e plano de rollback
- [x] Nenhum módulo novo ficou fora do grafo
- [x] Dependências externas declaradas no `graph.yaml`
- [x] Grafo será atualizado novamente após `/nimbus-code-implement` se a implementação divergir do plano

### Grafo do Contexto (Multi-Repo Brownfield)

| Campo | Valor |
|---|---|
| **Bounded context** | `spec-kit-workflow` |
| **Grafo do contexto** | [graph.yaml](./graph.yaml) / [graph.md](./graph.md) |
| **Dependências relevantes para esta feature** | `bootstrap.sh`, `docs/developer-guide.md`, `docs/bounded-contexts.yaml`, `templates/workflows/update-speckit-and-bundle.yml` |
| **Padrões de harvest aplicáveis** | `brownfield-multirepo-context-graph` |

## Nimbus-Code — Estratégia de Release

| Campo | Valor |
|---|---|
| **Estratégia** | `direct` |
| **Feature flag name** | `N/A` |
| **Flag provider** | `N/A` |
| **Critério de ativação** | merge do bundle oficial após revisão humana |
| **Critério de rollback** | reverter o commit/PR se o bootstrap orientar incorretamente a topologia ou quebrar a governança central → satélite |

**Justificativa para deploy `direct`**: a feature altera scripts e documentação do bundle organizacional, sem runtime progressivo por usuário final. O controle de risco vem de revisão humana, quickstart e rollback por revert de PR.

## Nimbus-Code — Cost Reference

| Campo | Valor |
|---|---|
| **Token estimate range** | ~24–36 mil tokens |
| **Human effort estimate range** | ~2–4 horas |
| **Tracking method** | tabela "Estimativa vs. Consumo Real" no `tasks.md` + campo "Horas Humanas" no GitHub Project |
| **Budget ceiling (optional)** | N/A |

## Nimbus-Code — SLO Gate

| Componente | Latência p99 | Taxa de erro máx. | Disponibilidade | RTO | RPO |
|---|---|---|---|---|---|
| Classificação greenfield/brownfield no bootstrap | 3000 ms | 1,0% | 99,9% | 30 min | 5 min |
| Intake de decisão mono vs multirepo | 4000 ms | 1,0% | 99,9% | 30 min | 5 min |
| Governança de sincronização central → satélite | — | — | — | 60 min | 15 min |

**SLOs não definidos nesta feature e justificativa:**
- Governança de sincronização central → satélite é processo operacional/documental apoiado por workflow já existente, sem endpoint de runtime para medir latência contínua.

## Nimbus-Code — Security & DevSecOps Gate

| Domínio | Controles aplicáveis | Escapável via ADL? | Status | Observações |
|---|---|---|---|---|
| **Backup & Disaster Recovery** | Sem datastore novo de produção | N/A | ✅ N/A | Feature só altera fluxo e documentação |
| Autenticação (SSO) | Greenfield continua sujeito à regra de SSO obrigatório quando um sistema novo for criado | Sim, com justificativa no ADL | ✅ | O plano apenas captura a decisão; não cria sistema com autenticação própria |
| Segredos no código/repositório | Nenhum secret novo; prompts e templates não podem introduzir credenciais | **Não — bloqueante** | ✅ | |
| Branch/merge protegido | PR obrigatório + revisão humana antes de merge do bundle | **Não — bloqueante** | ✅ | |
| Isolamento de ambiente | Heurística de classificação não deve depender de credenciais ou ambiente produtivo | **Não — bloqueante** | ✅ | |
| Containers | N/A | Sim | ✅ N/A | Não há container novo |
| CI/CD | Atualização satélite continua via workflow oficial e PR revisado | Sim, com justificativa no ADL | ✅ | Sem bypass manual silencioso |
| IaC — provider(s) usado(s) | N/A | Sim | ✅ N/A | Não há provisionamento cloud |
| Banco de dados | N/A | **Não — bloqueante** | ✅ N/A | |
| **Firewall / Segmentação de rede** | N/A | Sim | ✅ N/A | Sem superfície de rede nova |
| Observabilidade | Quickstart e rastreabilidade documental definem validação mínima do fluxo | Sim, com justificativa no ADL | ✅ | Sem runtime novo |

**Riscos identificados e decisão:**
- **Heurística excessivamente simplista para brownfield**: mitigar exigindo definição explícita de “código de aplicação relevante” no próprio plano, na pesquisa e no contrato.
- **Times tratarem baseline de domínios como regra fixa**: mitigar documentando que a lista é recomendada e adaptável com justificativa.
- **Satélite virar fonte paralela de specs**: mitigar reforçando a proibição operacional no guia e nos artefatos do plano.

## Nimbus-Code — Qualidade de Código, Testes e Observabilidade Gate

| Domínio | Controles aplicáveis | Status | Observações |
|---|---|---|---|
| Revisão de código por IA | Copilot Code Review solicitado em todo PR desta feature | ✅ | |
| Testes integrados | Cenários do bootstrap e da governança documental mapeados na rastreabilidade AC → Teste | ✅ | Parte shell, parte walkthrough documental |
| Observabilidade | Fluxo validado por quickstart e mensagens explícitas; sem runtime novo | ✅ N/A | |
| Arquitetura distribuída / Microsserviços | N/A — feature governa topologia, mas não implementa comunicação entre serviços | N/A | |
| Gestão de bugs | Bugfixes fora do escopo desta feature continuam indo para issues/PRs próprios | ✅ | separação explícita entre governança e bugfix |

**Critérios de aceitação sem teste de integração automatizado (se houver) — justificativa:**
- AC-4, AC-5 e AC-6 dependem de validação documental e governança de processo, não de uma API ou comando único totalmente automatizável.

## Nimbus-Code — Architecture Decision Log

| Decisão | Alternativas consideradas | Opção escolhida | Trade-off assumido | Justificativa do desvio (se aplicável) | Aprovado por |
|---|---|---|---|---|---|
| Momento de sugerir domínios satélite | Sugerir antes de qualquer spec · sugerir após a primeira spec estrutural · não sugerir baseline | **Sugerir após a primeira spec estrutural, com handoff explícito vindo do bootstrap** | Exige um passo de entendimento prévio, mas evita criar repos cedo demais e mantém o bootstrap focado no intake inicial | N/A — segue objetivo da feature | — |
| Classificação greenfield vs brownfield | Perguntar sempre manualmente · classificar só por heurística invisível · heurística com explicação e confirmação contextual | **Heurística com explicação contextual e critérios operacionais explícitos** | Um pequeno custo de explicação no bootstrap em troca de menos erro silencioso e mais previsibilidade | N/A | — |
| Topologia inicial multirepo | Lista fixa obrigatória · lista aberta sem baseline · baseline recomendada com liberdade de adaptação | **Baseline recomendada (FRONT/BACK/DESIGN/DATA/JOBS) com adaptação permitida** | Menos liberdade inicial absoluta, mas mais aceleração e consistência de onboarding | N/A | — |
| Formato da justificativa e ownership | Texto livre sem padrão · schema rígido demais · formato mínimo legível | **Formato mínimo legível** | Exige um pouco mais de disciplina, mas evita decisões e domínios sem contexto reutilizável | N/A | — |
| Fonte de verdade de specs | Permitir specs locais em satélites · centralizar no repo central | **Centralizar no repo central** | Exige disciplina operacional, mas elimina drift entre artefatos | N/A | — |
