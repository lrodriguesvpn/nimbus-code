# Implementation Plan: Hybrid Agent-Human Delivery Templates

**Readiness auditada em 2026-09-20**: artefatos e implementação local presentes,
revisão #441 aberta; validar fixtures não equivale a validar pilotos reais.
A divergência entre URL externa obrigatória nos contratos e Cost Reference
interno no gerador bloqueia o fechamento de T016/T017 até decisão humana.
As grafias `hybrid-dev-templates-v1` e `hybrid_dev_templates_v1`
abaixo também precisam de reconciliação antes de configurar rollout; nenhuma
chave operacional foi escolhida neste saneamento.

**Branch**: `016-hybrid-agent-human-dev`

**Created**: 2026-08-18

**Status**: Phase 1 Design Complete ✓

## Summary

Feature que redefine os templates de especificação, planejamento e tasks para operação híbrida entre agentes de IA e humanos, elevando o nível de detalhe, clareza operacional e rastreabilidade de custo na execução de features de desenvolvimento, com padronização de design WEB via Impeccable e feature toggle via OpenFeature.

---

## Technical Context

*Background, dependencies, and high-level technical approach.*

### Architecture Overview

A feature envolve atualização de **três camadas de templates e scripts** que alimentam o fluxo Speckit:

1. **Camada de Especificação** (spec-template): cabeçalho híbrido que define desde o início papéis, responsabilidades e observabilidade
2. **Camada de Planejamento** (plan-template): guia de design que reforça divisão de trabalho entre agente e humano, com estimativas de custo
3. **Camada de Tarefas** (tasks-template e gerador): tasks publicadas no GHE com instruções operacionais detalhadas para humanos
4. **Documentação de Referência**: bloco de referência ao SPEC KIT COST para acompanhamento de custo do modelo híbrido
5. **Padrões de Governança Técnica**: diretriz de design WEB via Impeccable e diretriz de toggles via OpenFeature

**Localização dos templates:**
- `.specify/presets/nimbus-code-standards/templates/spec-template.md` (base em `.specify/templates/`)
- `.specify/presets/nimbus-code-standards/templates/plan-template.md` (base em `.specify/templates/`)
- `.github/skills/speckit-tasks/SKILL.md` e scripts auxiliares em `.specify/scripts/`

**Fluxo de geração:**
```
/speckit-specify → spec-template preenchido → /speckit-plan → plan-template preenchido → /speckit-tasks → tasks-template instanciado no GHE
```

### Dependencies

- Projeto [nimbus-code](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code) — repositório base com templates e skills
- GitHub Enterprise (GHE) — plataforma de publicação de tasks e rastreio
- Documentação Nimbus-Code (`docs/ai-code-quality-and-observability.md`, `docs/developer-guide.md`)
- [SPEC KIT COST](https://github.com/venha-pra-nuvem/spec-kit-cost) — projeto GitHub público para rastreio de custo
- Skill custom `impeccable` (e seus agentes especializados) — padrão de design para projetos WEB
- [OpenFeature](https://openfeature.dev) — padrão de abstração para feature toggles

### Technology Choices

- **Markdown** para templates (compatível com GHE, git, versionável)
- **YAML** para configuração de templates (padrão em `.specify/`)
- **Mermaid** para diagramas de dependência (suportado em markdown GHE)
- **Bash/Shell** para scripts de geração (compatível com CI/CD)
- Referência externa via URL pública ao SPEC KIT COST
- Skill Impeccable como padrão de execução de design em contexto WEB
- OpenFeature como padrão arquitetural para feature toggle, com provider pluggable

**Justificativa**: Manter consistência com stack Nimbus-Code existente; evitar dependência de ferramentas proprietárias ou cloud-specific.

---

## Constitution Check

*Avaliar a feature contra princípios do projeto. Documentar desvios e obter aprovação se necessário.*

| Princípio | Status | Notas |
|---|---|---|
| Segurança — nenhum segredo em texto plano | ✓ Pass | Templates não contêm senhas, tokens ou dados sensíveis; apenas estrutura, referências e guidelines |
| Infraestrutura como Código (Terraform padrão) | ✓ Pass | Feature é pura mudança de templates e documentação; não altera infraestrutura |
| Grafos de Módulos (graph.yaml/graph.md obrigatório para S3+) | ✓ Pass | Será criado `graph.yaml` e `graph.md` descrevendo módulos de template e scripts |
| Escala de Complexidade (S0–S4, revisão obrigatória em S4) | ✓ Pass | Classificada como S3; revisão humana não obrigatória neste nível |
| Reutilização (catálogo + referência por ponteiro) | ✓ Pass | Reutiliza estrutura existente; não redefine templates do zero |
| Priorização (labels, desenvolvimento autônomo) | ✓ Pass | Workflow de labels e autonomia preservados |
| SSO obrigatório para novos sistemas | ✓ Pass | Feature não expõe novo sistema; apenas templates e documentação |

---

## Nimbus-Code — Classificação de Complexidade (S0–S4)

*Determina modelo de IA, artefatos obrigatórios e nível de revisão.*

| Campo | Valor |
|---|---|
| **Nível** | **S3** — múltiplos módulos/templates interdependentes (spec, plan, tasks) |
| **Justificativa** | Cruza geração de artefatos em três camadas (spec, plan, tasks); requer coordenação entre skills e templates; impacto no fluxo de desenvolvimento de todas as features futuras |
| **Modelo de IA** | Reasoning (Claude Sonnet 4.6+) — para design de template e análise de impacto |
| **Revisão humana obrigatória** | Não (S0–S3 não exigem revisão humana obrigatória) |
| **Padrão reutilizado encontrado?** | Não — `docs/reuse-catalog.yaml` consultado; nenhuma entrada match. Padrão será adicionado ao catálogo após conclusão (tag: `hybrid-dev-templates`) |
| **Estimativa de tokens (input+output)** | ~45–65 mil tokens — baseado no multiplicador S3 (4–5x base de 10kt) com análise de múltiplos templates, validação de gates e geração de research.md |

---

## Nimbus-Code — Rastreabilidade AC → Teste → Módulo

*Cada AC do spec.md deve ter um teste planejado e módulo identificado.*

| ID AC | Critério (resumo) | Tipo de teste planejado | Arquivo/módulo do teste | Justificativa de ausência (se N/A) |
|---|---|---|---|---|
| AC-1 | Orientação explícita de colaboração híbrida na spec | integração | `.specify/presets/nimbus-code-standards/templates/spec-template.md` (validar geração de cabeçalho híbrido) | — |
| AC-2 | Tasks no GHE com instruções operacionais para humanos | integração | `.github/skills/speckit-tasks/SKILL.md` (validar estrutura de task gerada) | — |
| AC-3 | Referência ao SPEC KIT COST nos templates | integração | `.specify/presets/nimbus-code-standards/templates/plan-template.md` (validar presença de bloco de referência) | — |
| AC-4 | Padrão Impeccable para design em projetos WEB | integração | `.specify/presets/nimbus-code-standards/templates/spec-template.md` (validar bloco de padrão de design WEB) | — |
| AC-5 | Padrão OpenFeature para feature toggles no plan | integração | `.specify/presets/nimbus-code-standards/templates/plan-template.md` (validar seção de toggle com OpenFeature) | — |

---

## Nimbus-Code — Module Dependency Graph

*OBRIGATÓRIO para S3+. Arquivos: `graph.yaml` (estruturado), `graph.md` (Mermaid), `impact-map.md` (análise de risco para S3+).*

**Status**: Será gerado como artefato Phase 1.

**Módulos envolvidos:**
- Template Layer: spec-template, plan-template, tasks-template
- Script Layer: setup-plan.sh, setup-tasks.sh, task-generator scripts
- Skill Layer: speckit-specify, speckit-plan, speckit-tasks
- Documentation Layer: constitution.md, developer-guide.md, reuse-catalog.yaml
- External Dependency: SPEC KIT COST (GitHub public repo)

Checklist:
- [ ] `graph.yaml` criado com todos os nós e arestas
- [ ] `graph.md` criado com diagramas Mermaid (estrutura técnica e fluxo de negócio)
- [ ] `impact-map.md` criado com análise de risco, dependências e plano de rollback
- [ ] Nenhum módulo novo faltando no grafo
- [ ] Dependências externas (SPEC KIT COST) declaradas em `externals`

---

## Nimbus-Code — Estratégia de Release

*Declarar estratégia e critérios de rollback.*

| Campo | Valor |
|---|---|
| **Estratégia** | `flag` — ativar novos templates gradualmente para projetos piloto antes de rollout universal |
| **Feature flag name** | `hybrid-dev-templates-v1` |
| **Flag provider** | OpenFeature (provider configurável por ambiente; bootstrap inicial pode usar env var provider) |
| **Critério de ativação** | Validação manual em 2 projetos piloto (internos) antes de rollout para `develop` branch |
| **Critério de rollback** | Erro de geração > 5% das features, bloqueio de workflow crítico, ou feedback crítico de Tech Lead |

**Justificativa para uso de flag**: Templates afetam todos os projetos futuros; rollback rápido é essencial caso gerem conteúdo inválido ou confuso.

---

## Nimbus-Code — Plano de Toggle e Rollout

| Campo | Valor |
|---|---|
| **Flag key** | `hybrid_dev_templates_v1` |
| **Tipo de flag** | `release` — ativar/desativar templates híbridos usando padrão OpenFeature |
| **Owner da flag** | Nimbus-Code Architecture Board |
| **Ambiente(s)** | dev · hml · prod (todos os 3) |
| **Default por ambiente** | dev=on, hml=off, prod=off (conservador) |
| **Segmentos de ativação** | `internal-pilot` (internos primeiro), `venha-pra-nuvem-clients` (clientes depois) |
| **Estratégia de rollout** | dev (sempre) → hml com piloto interno → prod com piloto cliente → prod 100% após validação |
| **Kill switch definido?** | Sim — desativar flag via provider OpenFeature e, em fallback, revert via PR |
| **Critério de limpeza** | Remover flag 30 dias após 100% rollout estável (criar Issue de tracking) |

---

## Phase 0: Research & Clarifications

*Resolve NEEDS CLARIFICATION markers from spec.md.*

**Status**: Não houve NEEDS CLARIFICATION na spec; todos os pontos foram cobertos com informed guesses baseados em contexto do projeto.

**Research tasks** (se identificadas durante planning):
- [x] Validar estrutura atual de templates Nimbus-Code (já feito na fase de setup)
- [x] Confirmar localização de SPEC KIT COST (projeto público disponível)
- [x] Validar compatibilidade de Mermaid em GHE (confirmado)

---

## Phase 1: Design & Contracts

*Gerar artefatos de design: data-model.md, contracts/, quickstart.md, graph.yaml, graph.md, impact-map.md.*

### Data Model

**Entidades principais da feature:**

1. **HybridCollaborationModel**
   - Role: agente, humano, tech-lead
   - Responsibility: define atividades de cada papel
   - HandoffCriteria: quando passar responsabilidade entre papéis

2. **DetailedTaskBlueprint**
   - Context: informação necessária para compreender a task
   - Objective: o que fazer
   - AcceptanceCriteria: como validar
   - OperationalSteps: instruções passo-a-passo para humanos
   - Dependencies: pré-requisitos e bloqueadores

3. **CostReferenceBlock**
   - SpecKitCostUrl: link ao projeto público
   - TokenEstimate: faixa estimada para agente
   - HumanHourEstimate: faixa estimada para humano
   - TrackingMethod: como acompanhar custo real

4. **WebDesignStandardPolicy**
   - AppliesTo: projetos WEB
   - RequiredSkill: Impeccable
   - QualityBar: padrão visual e acabamento definido por direção Impeccable

5. **FeatureToggleStandardPolicy**
   - Standard: OpenFeature
   - ProviderStrategy: pluggable por ambiente
   - RolloutPattern: gradual + kill switch

### Contracts (Interface Definitions)

**spec.md output contract**:
- Cabeçalho obrigatório com campos: feature slug, complexidade, bounded context, SLO
- Seção de Critérios de Aceitação em formato BDD (Given/When/Then)
- Orientação explícita de colaboração híbrida
- Regra de padrão Impeccable quando a feature estiver em contexto WEB

**plan.md output contract**:
- Seção de rastreabilidade AC → Teste → Módulo
- Classificação de Complexidade com justificativa e estimativa de tokens
- Graph.yaml/graph.md referenciado antes de tasks
- Estratégia de release com flag/rollout
- Seção de toggle padronizada com OpenFeature como abstração

**task (GHE) output contract**:
- Estrutura: objetivo, contexto, resultado esperado, critérios de aceite, passos operacionais
- Dependências explícitas
- Referência a quem executa (agente vs. humano)

### Quickstart Validation Guide

**Arquivo**: `specs/016-hybrid-agent-human-dev/quickstart.md`

**Validação E2E proposta**:
1. Inicializar novo projeto piloto com preset Nimbus-Code
2. Executar `/speckit-specify` com feature description
3. Validar que spec.md gerada inclui cabeçalho híbrido com campos de complexidade, SLO, etc.
4. Executar `/speckit-plan` e validar estrutura de plan.md com Classification, Graph refs, Release strategy
5. Executar `/speckit-tasks` e validar tasks no GHE com estrutura detalhada (objetivo, contexto, passos)
6. Validar presença de referência ao SPEC KIT COST em plan.md ou template
7. Validar que spec WEB inclui padrão Impeccable como guideline obrigatório de design
8. Validar que plan usa OpenFeature como padrão de toggle (provider como detalhe)
9. Verificar que humano consegue executar uma task usando apenas o texto da task (sem buscar contexto adicional)

---

## Security & DevSecOps Gate

*Verificar itens críticos de segurança, conformidade e DevOps.*

### Não-Negociáveis (zero exceção):

- [ ] Backup & Disaster Recovery: Templates e scripts estão no git com versionamento (versioning = backup); rollback via git revert é o plano DR
- [ ] Segredos em cofre: Feature não cria/armazena secrets; referências a SPEC KIT COST são URLs públicas
- [ ] Branch protegida: Alterações a templates requerem PR + revisão antes de merge em `develop`
- [ ] TLS: Todos os links (SPEC KIT COST, GHE) usam HTTPS
- [ ] Isolamento de ambiente: Templates são agnósticos a ambiente; ativação via flag permite testagem graduada

### Escapáveis via Architecture Decision Log (com justificativa):

- Firewall/VPC: Não aplicável (templates e docs, não infraestrutura)
- SSO: Feature não expõe novo sistema
- IaC não-Terraform: Feature não provisionam infraestrutura

**Status**: Todos os itens não-negociáveis atendidos. Nenhum desvio escapável necessário.

---

## Quality Gate — Code, Tests, Observability

*Verificar cobertura de testes e critérios de observabilidade.*

| Critério | Status | Detalhes |
|---|---|---|
| Code coverage planejada | Integração | Testes integram geração de templates com spec/plan/tasks |
| Observability (logs, métricas, alertas) | Planejado | Adicionar logging a setup-plan.sh e task-generator; métricas de tempo de geração |
| Performance SLO | 3000ms p99, 99.5% availability | Geração de artefatos deve completar em < 3s em CI/CD normal |
| Error handling | Definido | Erros de validação de template devem ser claros (ex.: "missing required field X") |

---

## Architecture Decision Log

**ADR-1: Usar templates text/markdown ao invés de programmatic DSL**

- **Decision**: Manter templates em Markdown com placeholders simples (não JSON schema, OpenAPI, etc.)
- **Rationale**: Legibilidade humana + compatibilidade com git diff + já padrão em Nimbus-Code
- **Alternatives considered**: 
  - JSON Schema (mais rigoroso, menos legível)
  - OpenAPI (overkill para modelo declarativo)
  - YAML DSL (competiria com config já em YAML)
- **Implications**: Trade-off entre rigor formal e usabilidade

**ADR-2: Feature flag obrigatória para ativar novos templates**

- **Decision**: Usar `hybrid_dev_templates_v1` flag; default=off em prod até validação piloto
- **Rationale**: Rollback seguro; protege projetos em andamento contra quebra de template
- **Alternatives considered**:
  - Direct merge sem flag (mais rápido, mais risco)
  - Version-based selection (mais complexo)
- **Implications**: Requer estágio piloto antes de 100% rollout

**ADR-3: Referência ao SPEC KIT COST como URL externa pública**

- **Decision**: Apontar para projeto GitHub público via URL; não copiar conteúdo
- **Rationale**: Reutilização por ponteiro (princípio Nimbus-Code); reduz duplicação; SPEC KIT COST será mantido como "single source of truth"
- **Alternatives considered**:
  - Copiar SPEC KIT COST docs para este repo (duplicação)
  - Depender de link quebrado (frágil)
- **Implications**: Exige manutenção de link; quebra de URL afeta discoverability

**ADR-4: Impeccable como padrão de design para projetos WEB**

- **Decision**: Definir uso da skill Impeccable como padrão oficial de design para features WEB.
- **Rationale**: Garante consistência visual, padrão de acabamento e processo reutilizável entre agentes e humanos.
- **Alternatives considered**:
  - Direção de design livre por time (inconsistência)
  - Checklists genéricos sem skill dedicada (baixo enforcement)
- **Implications**: Necessidade de orientar quando o contexto é WEB e quando não é.

**ADR-5: OpenFeature como padrão de abstração de feature toggle**

- **Decision**: Adotar OpenFeature como padrão de feature toggle; provider permanece pluggable por ambiente.
- **Rationale**: Evita acoplamento em provider único e preserva portabilidade de rollout.
- **Alternatives considered**:
  - Provider fixo proprietário (lock-in)
  - Estratégia sem abstração (alto custo de troca)
- **Implications**: Templates devem declarar OpenFeature mesmo quando o bootstrap inicial usar fallback simples por variável de ambiente.

---

## Next Steps (Readiness for `/speckit-tasks`)

- [x] `graph.yaml`, `graph.md`, `impact-map.md` presentes como artefatos Phase 1
- [x] `research.md` presente (findings de Phase 0)
- [x] `data-model.md` presente com entidades detalhadas
- [x] `contracts/*.md` presentes; conformidade do contrato de custo ainda bloqueada
- [x] `quickstart.md` presente como guia de validação E2E, não prova de execução
- [ ] Validar todos os gates (Security, Quality, Constitution)
- [ ] Obter aprovação de Tech Lead via PR review antes de `/speckit-tasks`

---

## Completion Checklist

- [x] Plan.md preenchido com Technical Context, Constitution Check, Gates
- [x] Phase 0 Research consolidado
- [x] Phase 1 Design artifacts gerados:
  - [x] `graph.yaml` — módulos, dependências, externos
  - [x] `graph.md` — diagramas Mermaid (arquitetura técnica, fluxo de dados, gates)
  - [x] `impact-map.md` — análise de risco, plano de rollback
  - [x] `data-model.md` — entidades com validação (já criado em fase anterior)
  - [x] `contracts/*` — spec-contract.md, plan-contract.md, task-contract.md
  - [x] `quickstart.md` — guia de validação E2E (9 steps)
- [ ] Gates aprovados com evidências; revisões e contrato de custo ainda pendentes
- [x] ADL contém 5 decisões arquiteturais (existência, não nova aprovação)
- [x] `tasks.md` gerado; fechamento não implica aceitação das pendências acima
