# Implementation Plan: Codespaces para DEV e CI/CD

**Branch**: `009-codespaces-dev-planning` | **Date**: 2026-08-20 | **Spec**: [spec.md](/Users/lrodrigues/projects/nimbus-code-spec-kit-template.worktrees/vpn-skills-repo-governance-specs/specs/009-codespaces-dev-planning/spec.md)

**Input**: Feature specification from `specs/009-codespaces-dev-planning/spec.md`

## Summary

Esta é uma feature de **planejamento** (não de implementação/rollout): produzir
uma decisão documentada sobre uso de GitHub Codespaces como ambiente padronizado
de desenvolvimento para os times Nimbus-Code, cobrindo devcontainer padrão,
aceleração de CI/CD via prebuilds, governança de custo/ociosidade, e modelo de
uso para sessões remotas de agentes de IA com paridade de segurança do CI.

Abordagem: pesquisa e avaliação (Phase 0), seguida de artefatos de design que
são, em si, o produto desta feature — um `devcontainer.json` de referência, um
mapeamento de quais etapas de pipeline se beneficiam de execução antecipada em
Codespace, e uma política de governança de custo. Não há "implementação de
produto" tradicional — os artefatos de Phase 1 **são** o entregável.

## Technical Context

**Language/Version**: JSON (`devcontainer.json`), YAML (workflows de exemplo),
Markdown (documentação de decisão)

**Primary Dependencies**: GitHub Codespaces (plataforma), `devcontainer` CLI
(para validação local do devcontainer de referência), GitHub Actions (para
qualquer workflow de exemplo de prebuild)

**Storage**: N/A

**Testing**: Validação manual do devcontainer de referência (abrir Codespace de
teste e confirmar toolchain funcional); sem testes automatizados tradicionais,
já que o produto é um plano/decisão, não código de produção

**Target Platform**: GitHub Codespaces (GHE da organização, se suportado —
validado em Phase 0)

**Project Type**: Documentação de decisão + artefato de configuração de
referência (devcontainer)

**Performance Goals**: Ver SLOs no `spec.md` (provisionamento de Codespace <120s
p99; prebuild <600s p99) — metas para quando o rollout for executado, não para
esta fase de planejamento

**Constraints**: Nenhum rollout real de Codespaces em repositórios de produção
nesta feature — apenas o plano e o devcontainer de referência validado em
ambiente de teste

**Scale/Scope**: Aplicável a todos os repositórios Nimbus-Code que optarem por
adotar Codespaces após este plano ser aprovado

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Notas |
|---|---|---|
| Segurança — nenhum segredo em texto plano | ✓ Pass | Devcontainer de referência não contém segredos; política de segredos para sessões de agente é parte do próprio entregável (FR-005) |
| SSO obrigatório para sistema novo | N/A | Codespaces usa a autenticação já existente do GitHub Enterprise — não introduz sistema de login próprio |
| Infraestrutura como Código | N/A | Codespaces é um serviço gerenciado pelo GitHub, não um recurso cloud provisionado por Terraform |
| Grafos de Módulos (S3+) | N/A | Feature classificada como **S3**, mas por cruzar múltiplos artefatos de configuração (devcontainer, CI/CD, política de custo, modelo de agente) — não por complexidade de módulos de código. `graph.yaml`/`graph.md` ainda serão gerados por consistência com o processo; `impact-map.md` também |
| Escala de Complexidade S0–S4 | ✓ Pass | S3 conforme `spec.md` |
| Reutilização (catálogo + ponteiro) | ✓ Pass | `docs/reuse-catalog.yaml` consultado — nenhuma entrada para "ambiente de desenvolvimento padronizado"; será adicionada ao final (tag: `standard-devcontainer`) |
| Qualidade e Processo | ✓ Pass | PR de revisão humana obrigatório para o devcontainer de referência e a política de governança de custo |

## Project Structure

### Documentation (this feature)

```text
specs/009-codespaces-dev-planning/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
├── graph.yaml           # Phase 1 output (S3)
├── graph.md             # Phase 1 output (S3)
├── impact-map.md        # Phase 1 output (S3)
└── tasks.md             # Phase 2 output (/speckit-tasks)
```

### Source Code (repository root)

```text
.devcontainer/
├── devcontainer.json                  # Novo: devcontainer de referência Nimbus-Code
└── Dockerfile                         # Novo (se necessário além da imagem base padrão)

docs/
├── codespaces-adoption-guide.md       # Novo: guia de adoção + governança de custo
└── ci-cd-acceleration-map.md          # Novo: mapeamento de etapas de pipeline aceleráveis via Codespace

.github/workflows/
└── codespaces-idle-governance.yml     # Exemplo/referência (não necessariamente ativo nesta feature — depende de aprovação de rollout)
```

**Structure Decision**: Todos os artefatos são novos (não há código de produto
pré-existente a modificar) — a feature entrega configuração de referência e
documentação de decisão, não altera nenhum sistema em produção.

## Complexity Tracking

*Nenhuma violação do Constitution Check identificada — tabela não aplicável.*

---

## Nimbus-Code — Classificação de Complexidade (S0–S4)

| Campo | Valor |
|---|---|
| **Nível** | **S3** |
| **Justificativa** | Cruza múltiplos artefatos (devcontainer, mapeamento de CI/CD, política de governança de custo, modelo de segurança para sessões de agente) que juntos formam uma decisão de plataforma com impacto em todos os repositórios que adotarem o padrão |
| **Modelo de IA** | Reasoning — decisão de arquitetura de ambiente de desenvolvimento |
| **Revisão humana obrigatória** | Não (S3 não exige por padrão); recomendada dado o impacto em todos os times, mas não bloqueante como em 008 |
| **Padrão reutilizado encontrado?** | Não — `docs/reuse-catalog.yaml` consultado; nenhuma entrada para devcontainer/Codespaces padrão |
| **Estimativa de tokens (input+output)** | ~20–30 mil tokens — pesquisa de Codespaces/devcontainer, design do mapeamento de CI/CD e da política de governança |

## Nimbus-Code — Rastreabilidade AC → Teste → Módulo

| ID AC | Critério (resumo) | Tipo de teste planejado | Arquivo/módulo do teste | Justificativa de ausência (se N/A) |
|---|---|---|---|---|
| AC-1 | Devcontainer zero-setup | manual (validação humana) | `.devcontainer/devcontainer.json` | Validação de UX de onboarding não é automatizável de forma significativa |
| AC-2 | Validação de pipeline pré-PR | manual + documentação | `docs/ci-cd-acceleration-map.md` | Depende de comparação de tempo entre ambientes, melhor validado manualmente na Phase 1 |
| AC-3 | Governança de Codespace ocioso | integração (workflow de exemplo) | `.github/workflows/codespaces-idle-governance.yml` | — |
| AC-4 | Paridade de segurança para sessão de agente | manual (revisão de política) | `docs/codespaces-adoption-guide.md` | Política de segurança é validada por revisão humana, não teste automatizado |

## Nimbus-Code — Module Dependency Graph

**Status**: Será gerado como artefato Phase 1.

**Módulos previstos:**
- Configuration Layer: `.devcontainer/devcontainer.json`
- Documentation Layer: `docs/codespaces-adoption-guide.md`, `docs/ci-cd-acceleration-map.md`
- Governance Layer: `.github/workflows/codespaces-idle-governance.yml` (referência)
- External Dependency: GitHub Codespaces (plataforma gerenciada)

## Nimbus-Code — Estratégia de Release

| Campo | Valor |
|---|---|
| **Estratégia** | `direct` |
| **Feature flag name** | N/A |
| **Flag provider** | N/A |
| **Critério de ativação** | N/A |
| **Critério de rollback** | N/A |

**Justificativa para deploy `direct`**: esta feature entrega apenas documentação
e um devcontainer de referência — não há rollout de sistema em produção para
gatear. A decisão de qual repositório efetivamente adota Codespaces é posterior
a este planejamento e tratada individualmente por cada repositório.

## Nimbus-Code — Cost Reference

| Campo | Valor |
|---|---|
| **Estimativa de tokens (agente)** | ~20–30 mil (ver Classificação de Complexidade acima) |
| **Estimativa de horas (humano)** | ~2–4 horas — revisão do devcontainer de referência e da política de governança de custo |
| **Metodologia de rastreio** | `docs/ai-code-quality-and-observability.md`, seção 6 |

## Phase 0: Research & Clarifications

**Status**: Nenhuma `[NEEDS CLARIFICATION]` pendente no `spec.md`.

**Research tasks**:
- [ ] Confirmar se GitHub Codespaces está disponível/licenciado no GitHub
      Enterprise da organização (`venha-pra-nuvem.ghe.com`) — pré-requisito
      comercial/contratual citado como Assumption no `spec.md`
- [ ] Avaliar imagem base de devcontainer adequada (`mcr.microsoft.com/devcontainers/*`)
      compatível com a stack já usada nos repositórios Nimbus-Code (Bash, Python,
      Node — usado por `normalize-github-issues.sh` e scripts correlatos)
- [ ] Pesquisar política de retenção/timeout de Codespaces ociosos disponível
      nativamente no GitHub (configuração de organização) antes de desenhar
      automação própria

**Expected Output**: `research.md`

## Phase 1: Design & Contracts

*Gerar artefatos de design: `data-model.md`, `contracts/`, `quickstart.md`, `graph.yaml`, `graph.md`, `impact-map.md`.*

### Data Model (prévia)

1. **StandardDevcontainerProfile** — imagem base, features, extensões, variáveis de ambiente padrão
2. **CiCdAccelerationMap** — etapa de pipeline → aplicável em Codespace (sim/não) → tempo estimado economizado
3. **CodespaceIdleGovernancePolicy** — limite de inatividade, ação (parar), alerta de custo
4. **RemoteAgentSessionModel** — escopo de segredos permitido, paridade com política de CI

### Contracts (prévia)

- **devcontainer-reference-contract.md**: schema esperado do `devcontainer.json` de referência
- **idle-governance-contract.md**: contrato do workflow de parada automática

### Quickstart Validation Guide

`quickstart.md` documentará: (1) abrir um Codespace usando o devcontainer de
referência e validar toolchain; (2) rodar uma etapa de pipeline localmente no
Codespace e comparar com o resultado do CI; (3) simular um Codespace ocioso e
validar a parada automática; (4) revisar a política de segredos para sessão de
agente.

---

## Next Steps (Readiness for `/speckit-tasks`)

- [ ] Gerar `research.md`, `data-model.md`, `contracts/*.md`, `quickstart.md`, `graph.yaml`, `graph.md`, `impact-map.md` (Phase 1)
- [ ] Validar gates (Constitution Check já ✓ Pass)
- [ ] Pronta para `/speckit-tasks` sem necessidade de aprovação humana bloqueante prévia (diferente da 008)
