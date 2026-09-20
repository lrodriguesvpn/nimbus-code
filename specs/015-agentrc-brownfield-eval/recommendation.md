# AgentRC Brownfield Evaluation — Recommendation

> **Status:** BACKLOG — esta recomendação não autoriza piloto, integração ou
> adoção. A SPEC só poderá ser retomada após a pesquisa de mercado e novo
> Go/No-Go humano.

## Executive Summary

Recommendation: **Adotar com restrições**.

AgentRC can add value as a brownfield readiness accelerator, but it should not replace the current Nimbus governance flow. The recommended path is a constrained pilot that preserves existing mandatory gates and keeps final architecture/governance decisions in the current process.

## Contexto

This feature evaluates whether AgentRC introduces net gain for brownfield analysis without conflicting with what Nimbus Code already does.

## Objective

Close the evaluation with one decision and a clear next step that preserves the current `spec -> plan -> tasks` workflow.

## Traceability (AC / FR / SC)

| Reference | Coverage |
|---|---|
| AC-1 | Comparison matrix completed with capabilities from both sides |
| AC-2 | Capability classifications explicit (complementar/duplicada/conflitante/não aplicável) |
| AC-3 | Single final recommendation selected |
| AC-4 | Pilot scope and exit criteria defined for adoption path |
| FR-001..FR-006 | Covered by matrix + conflict list + decision and pilot boundaries |
| SC-001..SC-004 | Covered through measurable documentary outputs and decision package |

## Recommendation Options Considered

### Option A — Adotar integralmente
- **Pros**: Potential acceleration in initial assessment.
- **Cons**: High overlap risk with current templates/skills; governance drift risk.

### Option B — Adotar com restrições (**Chosen**)
- **Pros**: Captures readiness value while preserving mandatory governance controls.
- **Cons**: Requires clear boundary and review checkpoint discipline.

### Option C — Rejeitar
- **Pros**: Zero operational change.
- **Cons**: Missed opportunity to accelerate readiness diagnostics.

## Current Backlog Decision

**Decision**: Não executar agora; manter em backlog.

**Rationale**:
1. A pesquisa de mercado e a maturidade pública do AgentRC ainda precisam ser
   confirmadas antes de investir em um piloto.
2. O fluxo Nimbus atual já possui controles de governança customizados.
3. A hipótese de uso continua válida, mas deve permanecer advisory e fora do
   fluxo normativo até nova aprovação.

## Sugestão de uso futuro

Se a pesquisa confirmar maturidade suficiente, usar AgentRC somente como uma
camada advisory de triagem brownfield:

- executar contra um repositório de avaliação não produtivo;
- gerar diagnóstico inicial de estrutura, dependências e riscos;
- registrar os resultados em `evidence-register.md`;
- comparar o diagnóstico com `graph.yaml`, `reuse-catalog.yaml` e Harness;
- nunca permitir que o AgentRC altere `spec.md`, `plan.md`, `tasks.md`,
  constituição, IaC ou políticas;
- usar o resultado apenas para informar o ciclo
  `specify → plan → tasks`, sujeito aos gates existentes.

## Conflict & Mitigation

| Conflict | Impact | Mitigation | Requires Human Approval |
|---|---|---|---|
| Governance bypass risk | Could bypass mandatory plan/constitution gates | AgentRC outputs are advisory only; final decisions remain in Nimbus flow | Yes |
| Instruction overlap risk | Duplicate or conflicting instruction layers | Normalize generated guidance against existing presets before adoption | Yes |
| Workflow ambiguity risk | Decision ownership confusion | Keep architecture board as final approver for adoption decisions | Yes |

## Impacted Current-Flow Artifacts

- `.specify/memory/constitution.md`
- `.specify/presets/` templates
- `.github/skills/` workflow prompts
- `specs/*` governance artifacts (graph/reuse/harness references)

## Minimal Pilot Scope (for chosen recommendation)

### Scope
- One controlled brownfield evaluation cycle.
- Advisory use only; no runtime integration changes.
- No replacement of current template workflow.

### Out of Scope
- Organization-wide replacement of existing workflow.
- Automatic policy enforcement by AgentRC.
- Runtime architecture decisions delegated to external tooling.

### Exit Criteria
1. Pilot produces actionable diagnostics without conflicting with mandatory governance gates.
2. No unresolved critical conflicts with constitution MUST controls.
3. Architecture board confirms the pilot output is net-positive and reproducible.

## Next Step Package (SC-004 format)

- **Responsável**: Architecture board + Tech Lead
- **Prazo**: até 5 dias úteis após aprovação desta recomendação
- **Status (Go/No-Go)**: No-Go por backlog; reavaliar após pesquisa de mercado
- **Escopo futuro**: 1 ciclo controlado de avaliação brownfield em modo advisory,
  somente após retomada formal e aprovação humana

## Release/Toggle Note

- Release strategy for this feature remains **direct**.
- Feature flags and OpenFeature are **N/A** because this feature is documentation/evaluation only.
