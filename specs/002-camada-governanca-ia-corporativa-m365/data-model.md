# Data Model: Camada de Governanca IA Corporativa M365

## Corporate AI Constitution

- **Purpose**: single corporate policy source for all AI usage.
- **Key fields**: title, version, owner, scope, official tools, allowed tools, prohibited behaviors, approval rules, review cadence, effective date.
- **Relationships**: referenced by the M365 governance guide, the legacy tools guide, and the Nimbus alias map context.
- **Validation rules**: exactly one active company-wide constitution; any change requires explicit review and version bump.

## M365 AI Governance Guide

- **Purpose**: apply the corporate constitution to Microsoft 365 Copilot and M365 Copilot CoWork.
- **Key fields**: target audience, supported experiences, permitted data sources, publication rules, sharing scope, owner, review notes.
- **Relationships**: derived from the Corporate AI Constitution; may reference official Microsoft 365 admin guidance.
- **Validation rules**: must remain consistent with the constitution and must not introduce conflicting tool-specific policies.

## Legacy AI Usage Guide

- **Purpose**: explain how Claude Enterprise and ChatGPT users follow the same corporate constitution.
- **Key fields**: tool name, permitted use, restrictions, migration status, exception notes, owner.
- **Relationships**: references the Corporate AI Constitution and the official-tool positioning.
- **Validation rules**: cannot redefine policy; it can only translate the corporate constitution for users of legacy tools.

## Nimbus Command Alias Map

- **Purpose**: document the compatibility mapping between Nimbus command names and the original Spec Kit commands.
- **Key fields**: Nimbus alias, original command, description, compatibility note, status.
- **Relationships**: maps one-to-one to the original command names and is referenced from the plan and quickstart docs.
- **Validation rules**: every alias must have one original command and the mapping must preserve the original command unchanged.

## Supporting Governance Artifact

- **Purpose**: keep the feature self-contained with enough documentation to validate coherence.
- **Key fields**: feature branch, feature directory, document list, checklist status.
- **Relationships**: links the spec, plan, research, quickstart, graph, and impact-map artifacts together.
- **Validation rules**: all feature artifacts must reference the same feature slug and remain internally consistent.
