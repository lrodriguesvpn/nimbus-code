# Quickstart Validation Guide: Camada de Governanca IA Corporativa M365

## Purpose

Validate that the documentation set presents one corporate AI constitution, clear M365 governance, a legacy-tools guide, and a Nimbus alias map without conflicting with the original Spec Kit commands.

## Prerequisites

- Repo checked out with the feature artifacts generated in `specs/002-camada-governanca-ia-corporativa-m365/`
- Access to the spec, plan, research, data-model, graph, and impact-map files
- Ability to review the existing Nimbus-Code constitution and repository docs

## Validation Steps

1. Open [spec.md](spec.md) and confirm the feature scope is limited to governance and documentation.
2. Open [plan.md](plan.md) and confirm the technical context is documentation-first and does not introduce runtime enforcement.
3. Open [research.md](research.md) and verify the decisions align with Microsoft 365 Copilot governance guidance and the official-tool stance.
4. Open [data-model.md](data-model.md) and confirm the four core entities are represented:
   - Corporate AI Constitution
   - M365 AI Governance Guide
   - Legacy AI Usage Guide
   - Nimbus Command Alias Map
5. Open [graph.md](graph.md) and [graph.yaml](graph.yaml) and verify that all documentation artifacts and external AI tool references are connected.
6. Open [impact-map.md](impact-map.md) and confirm the feature risks are limited to documentation coherence and naming clarity.
7. Verify the command and agent mapping matches the official Nimbus Code matrix:
   - `constitution -> /nc-governor (speckit-constitution)`
   - `specify -> /nc-spec (speckit-specify)`
   - `clarify -> /nc-critic (speckit-clarify)`
   - `plan -> /nc-arch (speckit-plan)`
   - `tasks -> /nc-qa (speckit-tasks + speckit-checklist)`
   - `implement -> /nc-builder (speckit-implement + speckit-converge)`
   - `analyze -> /nc-shield (speckit-analyze)`
   - *(Historical note: the legacy `nimbus.<name>` aliases are superseded by the canonical `/nc-*` command layer and `NC-*` agents documented in `docs/ai-governance/nimbus-aliases.md`).*

## Expected Outcome

- The company-wide AI constitution is clearly the single source of truth.
- Microsoft 365 Copilot governance is documented as a policy layer, not a runtime system.
- Claude Enterprise and ChatGPT are documented as legacy/transition tools that still follow the same constitution.
- Nimbus naming is documented as an alias layer, while the original Spec Kit commands remain intact.
- A reviewer can approve the plan and proceed to `/speckit-tasks` without unresolved scope questions.
