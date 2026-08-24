# AgentRC Brownfield Evaluation — Recommendation

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

## Final Decision

**Decision**: Adotar com restrições.

**Rationale**:
1. AgentRC contributes useful readiness diagnostics.
2. Current Nimbus flow already has stronger and customized governance controls.
3. A constrained pilot allows evidence-based validation with low disruption.

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
- **Status (Go/No-Go)**: Go para piloto restrito
- **Escopo**: execução de 1 ciclo de avaliação brownfield com AgentRC em modo advisory

## Release/Toggle Note

- Release strategy for this feature remains **direct**.
- Feature flags and OpenFeature are **N/A** because this feature is documentation/evaluation only.
