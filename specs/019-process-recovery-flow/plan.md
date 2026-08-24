# Implementation Plan: Fluxo de Correção de Rota para Specs Existentes

**Branch**: `019-process-recovery-flow` | **Data**: 2026-08-24 | **Spec**: [spec.md](./spec.md)

**Entrada**: Especificação da feature em [spec.md](./spec.md)

## Summary

Formalizar o processo operacional do Nimbus Code para correção de rota quando uma
feature já especificada ou parcialmente implementada apresentar erro funcional,
erro arquitetural ou descoberta de novo escopo. A entrega desta fase consolida a
decisão entre `clarify`, atualização da mesma `spec.md`, atualização do mesmo
`plan.md`, uso de `converge` e abertura de nova spec, com documentação visual e
normativa para Dev, BA e agente.

## Technical Context

**Language/Version**: Markdown, YAML e Mermaid (documentação e artefatos de processo)

**Primary Dependencies**:
- [docs/developer-guide.md](../../docs/developer-guide.md)
- [.specify/memory/constitution.md](../../.specify/memory/constitution.md)
- [specs/017-nimbus-digital-engineer-platform/](../017-nimbus-digital-engineer-platform/)

**Storage**: `specs/019-process-recovery-flow/`, [docs/developer-guide.md](../../docs/developer-guide.md), [.specify/memory/constitution.md](../../.specify/memory/constitution.md)

**Testing**: revisão documental guiada por checklist + validação manual dos fluxos Mermaid, FAQ e rastreabilidade AC/FR/SC

**Target Platform**: repositório central do Nimbus Code no GHE

**Project Type**: governança de processo e documentação operacional

**Performance Goals**: N/A — feature sem runtime

**Constraints**:
- `converge` permanece append-only em `tasks.md`
- a feature não altera runtime, CI/CD ou integrações externas
- a política de idioma deve ser normativa e única na constituição
- o fluxo deve ser compreensível por BA, Dev e agente sem depender de contexto oral

**Scale/Scope**: org `venha-pra-nuvem`, todos os projetos que usam o preset Nimbus-Code

## Constitution Check

*GATE: deve passar antes da pesquisa da Fase 0. Revalidar após o design da Fase 1.*

| Gate | Status | Observação |
|---|---|---|
| Backup & DR | ✅ N/A | Nenhum datastore, serviço ou dado operacional novo |
| Segredos no código | ✅ | Alterações apenas em documentação e constituição |
| Branch/merge protegido | ✅ | Fluxo continua orientado a PR e revisão |
| Isolamento de ambiente | ✅ | Sem acesso a credenciais, infra ou produção |
| Observabilidade | ✅ N/A | Sem componente em runtime |
| IaC | ✅ N/A | Nenhuma infraestrutura nova ou alteração manual |

**Gate: APROVADO** — sem exceções bloqueantes.

## Project Structure

### Documentation (this feature)

```text
specs/019-process-recovery-flow/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── graph.yaml
├── graph.md
├── contracts/
│   └── process-correction-decision.contract.md
└── checklists/
    └── requirements.md
```

### Artefatos alterados (fora da pasta da feature)

```text
docs/
└── developer-guide.md                # manual operacional + FAQ + fluxos Mermaid

.specify/memory/
└── constitution.md                   # política de idioma para código e documentação
```

### Arquivos não aplicáveis

```text
impact-map.md     # N/A — feature S2 sem mudança em runtime nem rollout
```

---

## Nimbus-Code — Classificação de Complexidade (S0–S4)

| Campo | Valor |
|---|---|
| **Nível** | **S2** |
| **Justificativa** | Atualiza um módulo documental central (developer guide), a constituição organizacional e os artefatos de design da própria feature, sem runtime novo nem integração entre serviços |
| **Modelo de IA** | Auto |
| **Revisão humana obrigatória** | Não (S0–S3), mas recomendada por alterar política organizacional |
| **Padrão reutilizado encontrado?** | Sim (tag: `hybrid-dev-templates`) |
| **Estimativa de tokens (input+output)** | ~10–16 mil tokens |

---

## Nimbus-Code — Harness Gate

| Harness consultado (ID) | Padrão de erro evitado | Mitigação preventiva aplicada nesta feature |
|---|---|---|
| HRN-0001 | Scope creep do agente ao corrigir além do escopo | A feature restringe a mudança aos artefatos de processo e documentação explicitamente envolvidos |
| HRN-0002 | Decisão arquitetural/política imposta silenciosamente | A regra de correção de rota é documentada explicitamente no guia e na constituição, em vez de depender de interpretação implícita |
| HRN-0003 | Pular consulta ao reuse-catalog e rederivar solução | O plano referencia padrão já catalogado para evitar rederivar a regra de correção de rota do zero |

**Resultado da consulta:**
- [x] Match encontrado — padrões relevantes declarados e mitigados
- [ ] Nenhum padrão de erro relevante encontrado para este domínio
- [ ] Catálogo vazio — nenhum padrão disponível para consulta

---

## Nimbus-Code — Rastreabilidade AC → Teste → Módulo

| ID AC | Critério (resumo) | Tipo de teste planejado | Arquivo/módulo do teste | Justificativa de ausência |
|---|---|---|---|---|
| AC-1 | Erro de implementação aponta para correção + converge | Manual / walkthrough | [docs/developer-guide.md](../../docs/developer-guide.md) | Convenção de processo, não lógica executável |
| AC-2 | Ambiguidade da spec aponta para mesma spec + clarify quando necessário | Manual / walkthrough | [docs/developer-guide.md](../../docs/developer-guide.md) | Convenção de processo, não lógica executável |
| AC-3 | Erro de arquitetura aponta para o mesmo plan | Manual / walkthrough | [docs/developer-guide.md](../../docs/developer-guide.md) | Convenção de processo, não lógica executável |
| AC-4 | Regra padrão favorece manter a mesma feature | Manual / checklist | [contracts/process-correction-decision.contract.md](./contracts/process-correction-decision.contract.md) | — |
| AC-5 | Critérios objetivos para nova spec | Manual / checklist | [contracts/process-correction-decision.contract.md](./contracts/process-correction-decision.contract.md) | — |
| AC-6 | FAQ e fluxos visuais disponíveis no guia | Manual / inspeção documental | [docs/developer-guide.md](../../docs/developer-guide.md) | — |

---

## Nimbus-Code — Module Dependency Graph

**Arquivos:**
- [graph.yaml](./graph.yaml) — fonte de verdade estruturada
- [graph.md](./graph.md) — diagramas Mermaid

**Checklist de manutenção do grafo:**
- [x] `graph.yaml` criado/atualizado com todos os módulos desta feature
- [x] `graph.md` criado/atualizado com diagrama por código e por business
- [x] Nenhum módulo novo ficou fora do grafo
- [x] Dependências externas/referenciais declaradas no grafo
- [x] `impact-map.md` não se aplica (feature S2)

### Grafo do Contexto (Multi-Repo Brownfield)

| Campo | Valor |
|---|---|
| **Bounded context** | `spec-kit-workflow` |
| **Grafo do contexto** | [graph.yaml](./graph.yaml) / [graph.md](./graph.md) |
| **Dependências relevantes para esta feature** | `docs/developer-guide.md`, `.specify/memory/constitution.md`, `specs/017-nimbus-digital-engineer-platform/` |
| **Padrões de harvest aplicáveis** | `brownfield-multirepo-context-graph` |

## Nimbus-Code — Estratégia de Release

| Campo | Valor |
|---|---|
| **Estratégia** | `direct` |
| **Feature flag name** | `N/A` |
| **Flag provider** | `N/A` |
| **Critério de ativação** | `N/A` |
| **Critério de rollback** | Reverter documentação/constituição caso a revisão humana identifique ambiguidade normativa |

**Justificativa para deploy `direct`**: a feature é exclusivamente documental e normativa; não altera comportamento de runtime nem fluxo transacional em produção.

## Nimbus-Code — Cost Reference

| Campo | Valor |
|---|---|
| **Faixa estimada de tokens** | ~10–16 mil tokens |
| **Faixa estimada de esforço humano** | ~1–2 horas |
| **Método de acompanhamento** | revisão documental do plano + registro de horas humanas no GitHub Project da feature |
| **Teto de orçamento (opcional)** | N/A |

## Nimbus-Code — SLO Gate

| Componente | Latência p99 | Taxa de erro máx. | Disponibilidade | RTO | RPO |
|---|---|---|---|---|---|
| Documentação operacional do processo | — | — | — | — | — |

**SLOs não definidos nesta feature e justificativa:**
- Não há serviço ou componente operacional novo; o resultado é governança documental.

## Nimbus-Code — Security & DevSecOps Gate

| Domínio | Controles aplicáveis | Escapável via ADL? | Status | Observações |
|---|---|---|---|---|
| Backup & Disaster Recovery | N/A — sem datastore | Não | ✅ N/A | Sem dado operacional novo |
| Autenticação (SSO) | N/A — sem sistema novo | Sim | ✅ N/A | Sem login ou identidade nova |
| Segredos no código/repositório | Nunca em texto plano | Não | ✅ | Alterações apenas em docs/YAML |
| Branch/merge protegido | PR obrigatório antes de merge | Não | ✅ | Processo padrão permanece |
| Isolamento de ambiente | Sem credenciais de produção | Não | ✅ | Nenhum acesso de ambiente requerido |
| Containers | N/A | Sim | ✅ N/A | Não aplicável |
| CI/CD | N/A | Sim | ✅ N/A | Sem pipeline novo |
| IaC — provider(s) usado(s) | N/A | Sim | ✅ N/A | Sem infra |
| Banco de dados | N/A | Não | ✅ N/A | Sem banco |
| Firewall / Segmentação de rede | N/A | Sim | ✅ N/A | Sem serviço exposto |
| Observabilidade | N/A | Sim | ✅ N/A | Feature documental |

**Riscos identificados e decisão:**
- Risco principal: ambiguidade residual na distinção entre “mesma spec” e “nova spec”. Mitigação: matriz de decisão + FAQ + contrato explícito.

## Phase 0 — Research Output

Pesquisa consolidada em [research.md](./research.md), com decisões sobre:
- uso de `clarify` apenas para ambiguidades reais;
- preservação do `converge` como mecanismo append-only;
- regra padrão de atualizar a mesma feature quando o recorte de valor permanece;
- uso de artefatos e padrões já consolidados do próprio Nimbus Code como referência complementar, sem ampliar o escopo da feature.

## Phase 1 — Design Output

Artefatos gerados nesta fase:
- [data-model.md](./data-model.md)
- [contracts/process-correction-decision.contract.md](./contracts/process-correction-decision.contract.md)
- [quickstart.md](./quickstart.md)
- [graph.yaml](./graph.yaml)
- [graph.md](./graph.md)

## Post-Design Constitution Check

| Princípio | Status | Notas |
|---|---|---|
| Segredos fora do código | ✓ Aprovado | Nenhum segredo introduzido |
| Grafos obrigatórios | ✓ Aprovado | `graph.yaml` e `graph.md` gerados e alinhados |
| Reuso por ponteiro | ✓ Aprovado | Reaproveita `hybrid-dev-templates` e o guia operacional já existente |
| Harness consultado | ✓ Aprovado | HRN-0001/0002/0003 declarados |
| Idioma dos artefatos | ✓ Aprovado | Documentação em português; contratos/processo explicitados em docs versionados |

**Gate final: APROVADO**
