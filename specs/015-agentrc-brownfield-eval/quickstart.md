# Quickstart: AgentRC Brownfield Evaluation

## Purpose

Validate that the evaluation is complete and that the recommendation is
traceable to the evidence gathered.

## Prerequisites

- `spec.md` completed
- `plan.md` completed
- `research.md` completed
- Access to the public AgentRC README/docs
- Access to the current Nimbus Code docs in this repository

## Validation Steps

1. Open [spec.md](./spec.md) and confirm AC-1 to AC-4 are present in BDD form.
2. Open [research.md](./research.md) and confirm the decisions cite public docs
   and current repo artifacts.
3. Open [data-model.md](./data-model.md) and confirm the matrix captures
   Capability, EvidenceSource, Conflict and Recommendation.
4. Open [comparison-matrix.md](./comparison-matrix.md) and confirm every compared
   capability has a classification (complementar/duplicada/conflitante/não aplicável)
   and evidence IDs.
5. Open [evidence-register.md](./evidence-register.md) and confirm all key claims
   in the comparison matrix are traceable to evidence records.
6. Open [recommendation.md](./recommendation.md) and confirm there is exactly one
   final recommendation and, if adoption-oriented, a minimal pilot scope with exit criteria.
7. Open [graph.yaml](./graph.yaml) and [graph.md](./graph.md) and confirm the
   context graph exists for `spec-kit-workflow`.
8. Verify the plan does **not** introduce `impact-map.md`, because this feature
   is S2 and does not change runtime behavior.
9. Confirm the final recommendation is one of:
   - adopt
   - adopt with restrictions
   - reject
10. Confirm release strategy is `direct` and rollout/toggle remains N/A for this feature.

## Expected Outcome

- A comparison matrix that shows where AgentRC adds value
- A conflict list that highlights overlaps with existing Nimbus Code flow
- One clear recommendation with rationale

## Evidence Checklist

- [ ] AgentRC public README reviewed
- [ ] Current Nimbus Code governance artifacts reviewed
- [ ] Conflicts identified and classified
- [ ] Recommendation is unique and actionable
- [ ] Next step package contains responsável, prazo, status and escopo
