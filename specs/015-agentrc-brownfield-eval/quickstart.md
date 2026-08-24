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
4. Open [graph.yaml](./graph.yaml) and [graph.md](./graph.md) and confirm the
   context graph exists for `spec-kit-workflow`.
5. Verify the plan does **not** introduce `impact-map.md`, because this feature
   is S2 and does not change runtime behavior.
6. Confirm the final recommendation is one of:
   - adopt
   - adopt with restrictions
   - reject

## Expected Outcome

- A comparison matrix that shows where AgentRC adds value
- A conflict list that highlights overlaps with existing Nimbus Code flow
- One clear recommendation with rationale

## Evidence Checklist

- [ ] AgentRC public README reviewed
- [ ] Current Nimbus Code governance artifacts reviewed
- [ ] Conflicts identified and classified
- [ ] Recommendation is unique and actionable

