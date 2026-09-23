# Implementation Plan: Nimbus Digital Engineer Platform

**Readiness auditada em 2026-09-20**: entrega documental, não plataforma runtime.
Revisão S4 #442 aberta. Os seis arquivos `tests/spec017/*.integration.spec.md`
são desenhos de teste em Markdown, não testes executáveis ou evidências de
execução. Rollout, SLO e instrumentação abaixo descrevem requisitos futuros.
O checklist de qualidade citado em #442 não existe neste checkout;
`checklists/requirements.md` é outro artefato e não prova aprovação S4.

**Feature**: `017-nimbus-digital-engineer-platform`  
**Spec**: [spec.md](./spec.md)  
**Branch**: `017-nimbus-digital-engineer-platform`  
**Date**: 2026-08-24

## Nimbus-Code — Classificação de Complexidade (S0–S4)

| Campo | Valor |
|---|---|
| **Nível** | **S4** |
| **Justificativa** | Mudança arquitetural e organizacional multi-repo, com governança de aprovação humana e integração corporativa M365/GitHub |
| **Modelo de IA** | Modelo forte |
| **Revisão humana obrigatória** | **Sim (S4)** |
| **Padrão reutilizado encontrado?** | Sim (tag: `hybrid-governance-raci`) |
| **Estimativa de tokens (input+output)** | ~120–220 mil tokens |

## Nimbus-Code — Harness Gate

| Harness consultado (ID) | Padrão de erro evitado | Mitigação preventiva aplicada nesta feature |
|---|---|---|
| Nenhum | Ausência de padrão catalogado específico para este domínio no momento | Manter checklist de governança e gates obrigatórios como fallback |

**Resultado da consulta:**
- [x] Nenhum padrão de erro relevante encontrado para este domínio
- [ ] Match encontrado — padrão(ões) de erro relevante(s) declarado(s) acima e mitigado(s)
- [ ] Catálogo vazio — nenhum padrão disponível para consulta

## Nimbus-Code — Rastreabilidade AC → Teste → Módulo

| ID AC | Critério (resumo) | Tipo de teste planejado | Arquivo/módulo do teste | Justificativa de ausência (se N/A) |
|---|---|---|---|---|
| AC-1 | Intake M365/GitHub com contexto mínimo | desenho de integração (Markdown) | `tests/spec017/intake-registration.integration.spec.md` | Execução runtime futura |
| AC-2 | Classificação por modo com justificativa | desenho de integração (Markdown) | `tests/spec017/mode-classification.integration.spec.md` | Execução runtime futura |
| AC-3 | Gate humano bloqueia avanço sem aprovação | desenho de integração (Markdown) | `tests/spec017/approval-gate.integration.spec.md` | Execução runtime futura |
| AC-4 | Handoff com evidências de custo/qualidade | desenho de integração (Markdown) | `tests/spec017/handoff-package.integration.spec.md` | Execução runtime futura |
| AC-5 | OpenFeature definido como abstração de toggle | desenho de integração (Markdown) | `tests/spec017/openfeature-toggle.integration.spec.md` | Execução runtime futura |
| AC-6 | Badges por domínio com critérios auditáveis | desenho de integração (Markdown) | `tests/spec017/domain-badges.integration.spec.md` | Execução runtime futura |

## Nimbus-Code — Module Dependency Graph

**Arquivos:**
- [graph.yaml](./graph.yaml)
- [graph.md](./graph.md)
- [impact-map.md](./impact-map.md)

**Checklist de manutenção do grafo:**
- [x] `graph.yaml` criado/atualizado com todos os nós e arestas desta feature
- [x] `graph.md` criado/atualizado com diagrama por código e diagrama por business
- [x] Para S3/S4: `impact-map.md` criado/atualizado com análise de risco e plano de rollback
- [x] Nenhum módulo/serviço novo criado nesta feature está faltando no grafo
- [x] Dependências externas declaradas em `externals` no `graph.yaml`
- [x] Grafo será atualizado novamente após `/nimbus-code-implement` se a implementação divergir do plano

### Grafo do Contexto (Multi-Repo Brownfield)

| Campo | Valor |
|---|---|
| **Bounded context** | `spec-kit-workflow` |
| **Grafo do contexto** | [graph.yaml](./graph.yaml) e [graph.md](./graph.md) |
| **Dependências relevantes para esta feature** | `nimbus-agent`, `nimbus-code`, repositórios satélites de execução |
| **Padrões de harvest aplicáveis** | Nenhuma entrada adicional de harvest aplicada |

## Nimbus-Code — Estratégia de Release

| Campo | Valor |
|---|---|
| **Estratégia** | `flag` |
| **Feature flag name** | `nimbus.modes.autonomy-orchestration` |
| **Flag provider** | **OpenFeature** + provider por ambiente |
| **Critério de ativação** | Habilitar em piloto interno com 10% das demandas e elevar para 100% após 7 dias sem regressão |
| **Critério de rollback** | Erro > 0,5% por 5 minutos ou bloqueio indevido de aprovação em qualquer demanda crítica |

## Nimbus-Code — Plano de Toggle e Rollout (obrigatório com `flag`)

| Campo | Valor |
|---|---|
| **Flag key** | `nimbus.modes.autonomy-orchestration` |
| **Tipo de flag** | `release` |
| **Owner da flag** | Squad ADE Platform |
| **Ambiente(s)** | dev · hml · prod |
| **Default por ambiente** | dev=off, hml=off, prod=off |
| **Segmentos de ativação** | interno, piloto, geral |
| **Estratégia de rollout** | dev interno → hml piloto → prod canary 10% → prod 100% |
| **Kill switch definido?** | Sim — desativação imediata da flag |
| **Critério de limpeza** | Remover flag até D+21 após estabilidade em 100% |
| **Issue/tarefa de remoção criada?** | Sim — registrar em tasks de polish |

## Nimbus-Code — Cost Reference

| Campo | Valor |
|---|---|
| **Token estimate range** | ~120–220 mil tokens |
| **Human effort estimate range** | ~28–44 horas |
| **Tracking method** | Tabela de estimativa vs consumo real no `tasks.md` + campo "Horas Humanas" no GitHub Project |
| **Budget ceiling (optional)** | ~US$ 800 equivalente de esforço combinado |

**Fórmula de custo híbrido (US4)**:
`Custo total da demanda = (tokens_input + tokens_output) * custo_unitário_modelo + (horas_humanas * custo_hora_time)`

**Regras operacionais**:
- custo híbrido deve ser calculado em toda demanda concluída;
- o handoff deve exibir custo IA e custo humano separadamente, além do total;
- pendências devem indicar owner para responsabilização de custo residual.

## Nimbus-Code — SLO Gate

| Componente | Latência p99 | Taxa de erro máx. | Disponibilidade | RTO | RPO |
|---|---|---|---|---|---|
| Intake M365 → Nimbus Agent | 3000ms | 1,0% | 99,9% | 30 min | 5 min |
| Classificação de modo | 2000ms | 0,5% | 99,9% | 15 min | 1 min |
| Handoff para cliente | 1500ms | 0,5% | 99,9% | 15 min | 1 min |

**SLOs não definidos nesta feature e justificativa:** Nenhum.

## Nimbus-Code — Security & DevSecOps Gate

| Domínio | Controles aplicáveis | Escapável via ADL? | Status | Observações |
|---|---|---|---|---|
| **Backup & Disaster Recovery** | Backup/restore de stores de auditoria e handoff | **Não — bloqueante** | Conforme (planejado) | Política definida para stores críticos |
| Autenticação (SSO) | SSO obrigatório para fluxos de aprovação | Sim, com justificativa no ADL | Conforme | Sem credenciais locais |
| Segredos no código/repositório | Cofre de segredos e scan ativo | **Não — bloqueante** | Conforme | Sem segredo em artefato versionado |
| Branch/merge protegido | PR obrigatório + checks | **Não — bloqueante** | Conforme | Processo institucional |
| Isolamento de ambiente | Separação de credenciais por ambiente | **Não — bloqueante** | Conforme | Escopo de integração respeita segregação |
| Containers | Base pinada e scan | Sim, com justificativa no ADL | N/A nesta fase | Planejamento sem entrega de container novo |
| CI/CD | Secrets via cofre e least privilege | Sim, com justificativa no ADL | Conforme | Sem bypass de pipeline |
| IaC — provider(s) usado(s) | Terraform padrão para infraestrutura compartilhada | Sim, com justificativa no ADL | Conforme | Sem desvio proposto nesta feature |
| Banco de dados | TLS/mTLS para dado sensível | **Não — bloqueante** | Conforme (planejado) | Requisito explícito de integração |
| **Firewall / Segmentação de rede** | Exposição mínima e regras de rede | Sim, com justificativa no ADL | Conforme (planejado) | Endpoints de intake sob segmentação corporativa |
| Observabilidade | Logs, métricas e alertas mínimos | Sim, com justificativa no ADL | Conforme | Definido nos artefatos de quickstart/teste |

**Riscos identificados e decisão:**
- Risco de classificação incorreta de modo em casos limítrofes: mitigar com regras explícitas e trilha de justificativa (US2).
- Risco de bloqueio operacional por ausência de aprovador: mitigar com escalonamento RACI e SLA de aprovação (US3).
- Risco de custo opaco no modelo híbrido: mitigar com handoff obrigatório contendo custo IA + humano (US4).

## Nimbus-Code — Qualidade de Código, Testes e Observabilidade Gate

| Domínio | Controles aplicáveis | Status | Observações |
|---|---|---|---|
| Revisão de código por IA | Copilot review com bloqueio para findings críticos | Conforme | Exigência aplicada à fase de implementação |
| Testes integrados | Cobertura AC-1..AC-6 com cenários de integração planejados | Conforme | Matriz AC→teste preenchida |
| Observabilidade | Logs estruturados e métricas de fluxo | Conforme | Evidências exigidas no handoff |
| Arquitetura distribuída / Microsserviços | Correlation-id ponta a ponta | Conforme | Aplicável ao fluxo multi-repo |
| Gestão de bugs | Bugs fora de escopo viram issue dedicada | Conforme | Processo operacional definido |

**Critérios de aceitação sem teste de integração automatizado (se houver) — justificativa:** Nenhum.

## Nimbus-Code — Architecture Decision Log

| Decisão | Alternativas consideradas | Opção escolhida | Trade-off assumido | Justificativa do desvio (se aplicável) | Aprovado por |
|---|---|---|---|---|---|
| Toggle de rollout dos modos | Provider direto por ambiente vs abstração única | OpenFeature como camada de abstração | Exige camada adicional de integração, mas reduz lock-in | N/A — segue padrão institucional | Architecture board |
| Governaça de aprovação em fluxo híbrido | Aprovação opcional por equipe vs gate formal | Gate formal com RACI e trilha auditável | Mais etapas formais, porém maior segurança decisória | N/A — segue padrão institucional | Product/Engineering |
| Integração de intake multi-fonte | Fluxos separados por canal vs normalização única | Pipeline unificado de IntakeEntry | Mais complexidade inicial de normalização, menor retrabalho operacional | N/A — segue padrão institucional | ADE lead |

## Nimbus-Code — Badge Governance Workflow (US5)

1. **Draft**: domínio propõe badge com critérios/evidências mínimas.
2. **Review**: BA + Digital Engineering validam clareza, mensurabilidade e auditabilidade.
3. **Publish**: owner do domínio publica badge com versão e data.
4. **Deprecate**: quando critério perder validade, migrar para `deprecated` com justificativa e plano de substituição.

**Controles**:
- nenhuma publicação sem critérios objetivos e evidências exigidas;
- toda mudança de status deve ser registrada com owner, timestamp e racional.
