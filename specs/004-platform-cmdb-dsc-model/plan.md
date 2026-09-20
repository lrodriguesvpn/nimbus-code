# Implementation Plan: Platform Preset CMDB + Security/Compliance Baselines

**Feature**: Plataforma CMDB + Baselines de Seguranca e Compliance  
**Feature Branch**: `004-platform-cmdb-dsc-model`  
**Complexity**: S4 (arquitetura multi-cloud, seguranca e compliance criticos)  
**Created**: 2026-08-12

---

## Summary

Esta feature define a evolucao do Preset de Plataforma para:

1. autenticar operadores via SSO corporativo central;
2. coletar inventario multi-cloud com rastreabilidade;
3. consolidar CMDB orientado a IA para governanca e validacao de infraestrutura;
4. mapear baseline/politicas/customizacoes de seguranca e compliance;
5. gerar modelo DSC versionado para validacao continua.

Escopo confirmado nas clarificacoes da spec:
- MVP multi-cloud;
- todos os dominios de seguranca/compliance disponiveis no tenant;
- validacao de infraestrutura em modo advisory no MVP;
- atualizacao completa de CMDB/DSC a cada 24h.

---

## Nimbus-Code — Classificacao de Complexidade (S0–S4)

| Campo | Valor |
|---|---|
| **Nivel** | **S4** |
| **Justificativa** | Cruza autenticacao corporativa, inventario multi-cloud, baseline de seguranca/compliance e governanca de infraestrutura |
| **Modelo de IA** | Modelo forte (reasoning avancado) |
| **Revisao humana obrigatoria** | Sim (S4) |
| **Padrao reutilizado encontrado?** | Nao (catalogo atual sem entradas) |
| **Estimativa de tokens (input+output)** | ~28–40 mil tokens |

---

## Technical Context

### Architecture Overview

A solucao e organizada em 6 blocos:

1. **Identity & Access Gateway**
   - entrada autenticada por SSO corporativo;
   - emissao de contexto de execucao auditavel.

2. **Multi-Cloud Discovery Orchestrator**
   - orquestra coletas por provedor (Azure, AWS, GCP);
   - trata retries, timeout e evidencias parciais.

3. **CMDB for AI Core**
   - consolida recursos, relacionamentos, evidencias e historico;
   - exposto para consultas e validacoes de governanca.

4. **Policy Baseline Engine**
   - compara estado aplicado com baseline corporativo;
   - identifica customizacoes e achados de conformidade.

5. **DSC Model Composer**
   - produz modelo de estado desejado versionado;
   - preserva historico e delta entre versoes.

6. **Governance Validation Interface**
   - integra validacoes em pipelines de infraestrutura (modo advisory no MVP);
   - exige trilha de excecao para nao conformidades.

### Key Technical Decisions (resolved in Phase 0)

1. Escopo de plataforma no MVP: **multi-cloud**.
2. Cobertura de dominios de seguranca/compliance: **todos os dominios disponiveis no tenant**.
3. Autenticacao: **SSO corporativo central unico**.
4. Validacao de infraestrutura: **advisory com relatorio e trilha de excecao**.
5. Frequencia de atualizacao CMDB/DSC: **maximo 24h**.

### External Dependencies

- Provedores cloud: Azure, AWS e GCP;
- M365 tenant para baseline/politicas;
- IdP corporativo para SSO;
- Repositorios/pipelines de infraestrutura para consumo das validacoes.

### Technology Choices (plan-level)

- Contratos de interoperabilidade documentados em OpenAPI + schemas YAML/JSON;
- Pipelines de validacao via CI corporativo;
- Persistencia versionada para evidencias e perfis DSC;
- IaC padrao Terraform (conforme constituicao).

---

## Constitution Check

**Result**: ✅ PASS (com controles e gates planejados para S4)

### 1) Seguranca e Dados

- SSO obrigatorio: ✅ Atendido (decisao explicita no escopo).
- Segredos: ✅ Sem armazenamento em texto plano; uso de cofre corporativo.
- Auditoria: ✅ Trilha de autenticacao, coleta, comparacao e geracao DSC prevista.

### 2) Infraestrutura como Codigo

- Terraform como padrao: ✅ Mantido.
- Version pinning e least privilege: ✅ exigidos nos gates.

### 3) Grafos e Impacto (S4)

- `graph.yaml` + `graph.md`: ✅ gerados neste plano.
- `impact-map.md`: ✅ gerado neste plano (obrigatorio S4).

### 4) Modelo e Processo (S4)

- Planejamento antes de implementacao: ✅.
- Revisao humana obrigatoria para PR final: ✅.

---

## Quality Gates — Status Before Planning

> **Estado verificável (2026-09-20):** os `PASS` abaixo registram decisões e
> artefatos de planejamento, não controles operacionais ou aprovação humana S4.
> A execução local passou 16/16 testes com fixtures. SSO/descoberta reais,
> persistência durável e atualização operacional em 24h não foram comprovados.
> Ver [estado verificável em tasks.md](tasks.md#estado-verificável--2026-09-20)
> para limites e entregas não localizadas. Nenhum gate foi aprovado nesta revisão.

| Gate | Status | Notes |
|---|---|---|
| Specification Quality | ✅ PASS | Spec validada e clarificada |
| Requirement Traceability | ✅ PASS | ACs mapeados para testes no plano |
| Module Dependency Graph | ✅ PASS | `graph.yaml` + `graph.md` gerados |
| Impact Map (S4) | ✅ PASS | `impact-map.md` gerado |
| Security & DevSecOps | ✅ PASS | SSO + advisory governance + auditoria definidos |
| SLO Gate | ✅ PASS | SLOs da spec refletidos no plano |
| Release Strategy | ✅ PASS | rollout controlado com review humano |

---

## Nimbus-Code — Rastreabilidade AC → Teste → Modulo

| ID AC | Criterio (resumo) | Tipo de teste planejado | Arquivo/modulo do teste | Justificativa de ausencia (se N/A) |
|---|---|---|---|---|
| AC-1 | Selecao de plataforma + autenticacao SSO | contrato/integração/e2e com fixtures | `platform-governance/tests/contract/auth-session.contract.test.js`, `platform-governance/tests/integration/execution-scope.test.js`, `platform-governance/tests/e2e/auth-rejection.test.js` | Cobertura local; não valida um IdP corporativo real |
| AC-2 | Atualizacao CMDB com evidencias | integração com fixtures | `platform-governance/tests/integration/cmdb-ingestion.test.js`, `platform-governance/tests/e2e/cmdb-history.test.js` | Não comprova descoberta cloud real ou persistência durável |
| AC-3 | Baseline/politicas/customizacoes | integração/e2e com fixtures | `platform-governance/tests/integration/m365-baseline.test.js`, `platform-governance/tests/e2e/customization-report.test.js` | Não comprova coleta de políticas no tenant |
| AC-4 | Geracao DSC versionada | integração com fixtures | `platform-governance/tests/integration/dsc-profile-generation.test.js` | Não comprova versionamento persistente em operação |

Mapa corrigido em 2026-09-20 para arquivos existentes; substituir os caminhos
planejados não amplia a cobertura demonstrada pelos testes.

---

## Nimbus-Code — Estrategia de Release

| Campo | Valor |
|---|---|
| **Estrategia** | `canary` |
| **Feature flag name** | `platform-preset-cmdb-governance` |
| **Flag provider** | `OpenFeature` |
| **Criterio de ativacao** | 7 dias sem regressao em SLO e sem findings criticos de compliance |
| **Criterio de rollback** | erro >1% na coleta ou falha de consistencia de CMDB/DSC em ambiente piloto |

Justificativa: por ser S4 e multi-cloud, rollout progressivo reduz risco operacional.

---

## Nimbus-Code — SLO Gate

| Componente | Latencia p99 | Taxa de erro max. | Disponibilidade | RTO | RPO |
|---|---|---|---|---|---|
| Coleta de inventario multi-cloud | — | 1,0% | 99,5% | 30 min | 15 min |
| Atualizacao baseline/politicas | — | 1,0% | 99,5% | 30 min | 15 min |
| Consulta CMDB para IA/governanca | 2000ms | 0,5% | 99,9% | 15 min | 5 min |
| Geracao de DSC versionado | — | 1,0% | 99,5% | 30 min | 15 min |

---

## Nimbus-Code — Security & DevSecOps Gate

| Dominio | Controles aplicaveis | Escapavel via ADL? | Status | Observacoes |
|---|---|---|---|---|
| Backup & DR | backup automatizado + restore testado para dados de CMDB/DSC | Nao | ✅ | obrigatorio antes de go-live |
| Autenticacao (SSO) | SSO corporativo central unico | Nao | ✅ | requisito funcional ja definido |
| Segredos | cofre de segredos + rotacao + sem hardcode | Nao | ✅ | validacao em CI |
| IaC | Terraform com `plan` revisado em PR | Sim (ADL) | ✅ | excecoes so com ADL aprovado |
| Observabilidade | logs, metricas e trilhas de auditoria fim a fim | Sim (ADL) | ✅ | sem observabilidade, sem rollout |

---

## Phase 0 — Research (completed)

Arquivo: `research.md`

Topicos resolvidos:
1. recorte do MVP multi-cloud;
2. estrategia de autenticacao corporativa;
3. estrategia de comparacao baseline/compliance em todos os dominios;
4. modo de validacao para pipelines de infraestrutura (advisory);
5. cadencia operacional minima de atualizacao CMDB/DSC.

---

## Phase 1 — Design & Contracts (completed)

Artefatos gerados:

- `data-model.md`
- `contracts/api-openapi.yaml`
- `contracts/dsc-profile-schema.yaml`
- `contracts/governance-validation-contract.md`
- `quickstart.md`
- `graph.yaml`
- `graph.md`
- `impact-map.md`

---

## Architecture Decision Log (ADL)

### ADL-001: Escopo multicloud no MVP
**Decision**: suportar Azure, AWS e GCP no MVP.  
**Rationale**: requisito de plataforma confirmado na clarificacao; evita desenho restrito que precisaria retrabalho estrutural imediato.  
**Tradeoff**: aumento de complexidade de descoberta e normalizacao inicial.

### ADL-002: SSO corporativo unico
**Decision**: acesso somente com SSO corporativo central.  
**Rationale**: aderencia a constituicao e trilha de auditoria consistente entre provedores.  
**Tradeoff**: dependencia direta do IdP corporativo.

### ADL-003: Validacao de Terraform em modo advisory no MVP
**Decision**: nao bloquear pipeline no MVP; exigir relatorio + trilha de excecao.  
**Rationale**: melhora adocao inicial sem ruptura operacional abrupta.  
**Tradeoff**: governanca depende de follow-up disciplinado das excecoes.

### ADL-004: Atualizacao completa a cada 24h
**Decision**: cadencia minima de 24h para CMDB e DSC.  
**Rationale**: equilibrio entre frescor e custo operacional multi-cloud.  
**Tradeoff**: mudancas intra-dia podem ser refletidas com atraso controlado.

---

## Implementation Readiness

Status: ✅ READY FOR `/speckit-tasks`  

Condicoes para avancar:
- [x] Nenhum `NEEDS CLARIFICATION` pendente
- [x] Gates S4 preenchidos
- [x] Contratos e modelo de dados definidos
- [x] Grafo e impacto publicados
- [x] Estrategia de release/rollback definida
