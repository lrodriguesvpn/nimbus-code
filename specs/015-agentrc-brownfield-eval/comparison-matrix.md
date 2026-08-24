# Comparison Matrix: AgentRC vs Nimbus Code (Brownfield)

## Scope

Evaluation-only comparison based on:
- Public AgentRC documentation
- Existing Nimbus Code governance/workflow artifacts in this repository

No runtime integration is performed in this feature.

## Classification Rubric

- **Complementar**: capability adds clear value not currently covered.
- **Duplicada**: capability already covered by current Nimbus flow with equivalent intent.
- **Conflitante**: capability introduces operational ambiguity or bypasses existing governance controls.
- **Não aplicável**: capability does not apply to this repository scope.

## Capability Comparison

| Capability | AgentRC | Nimbus Code (atual) | Classificação | Impacto | Evidência |
|---|---|---|---|---|---|
| Readiness assessment for AI tooling | Readiness score and dashboard output | Governance gates, checklists, constitution controls | Complementar | Adds fast diagnostic baseline for brownfield readiness | ER-001, ER-003 |
| Instruction generation for copilots/agents | Generates tailored instruction files | Existing instruction system, preset templates, skills | Duplicada | Potential value exists, but overlaps with mature internal template stack | ER-001, ER-004 |
| Policy-driven evaluation criteria | Supports policy customization in assessments | Existing mandatory gates and constitution MUST controls | Complementar | Can improve consistency in initial triage if mapped to current gates | ER-001, ER-002 |
| Autonomous decision routing for implementation | Not a replacement for full internal flow governance | Internal flow already defines gates, role split, and handoff | Conflitante | Risk of bypassing current governance checkpoints if used as authoritative | ER-002, ER-004 |
| Cost/benefit recommendation for adoption | Provides indicators and recommendations | Internal process requires explicit architecture decision log | Complementar | Useful as input, not as final decision source | ER-001, ER-005 |

## Conflict List

1. **Governance bypass risk**  
   If AgentRC output is treated as final architecture decision, it can conflict with mandatory plan gates and constitution-driven controls.

2. **Instruction overlap risk**  
   Auto-generated instructions may duplicate existing `.specify` presets and create drift if not normalized.

3. **Workflow ambiguity risk**  
   Mixed ownership of “who decides adoption” (tool vs architecture board) can create inconsistent decisions.

## Gap Notes

- AgentRC can accelerate initial assessment posture.
- Nimbus Code remains stronger in deeply customized governance and artifact traceability.
