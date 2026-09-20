# Specification Quality Checklist: Harness Engineering (Aprendizado Organizacional com Erros)

**Purpose**: Validate whether the harness spec defines a sufficiently precise, complete, and traceable error-learning mechanism for planning, cataloging, and post-incident reuse across projects.
**Created**: 2026-09-20
**Feature**: [spec.md](../spec.md)

## Requirement Completeness

- [x] CHK001 - Are the required fields and schema definitions of `harness-catalog.yaml` explicitly documented with field types, nullability, and allowed values? [Completeness, Spec §FR-001, Spec §Key Entities & Data Model]
- [x] CHK002 - Are the mandatory behaviors and field outputs of the "Harness Gate" defined for all three states: match found, no match found, and catalog empty? [Completeness, Spec §FR-003, Spec §AC-2, Spec §AC-7]
- [x] CHK003 - Are the complete lifecycle and state transitions for labels (`harness:pending` -> `harness:cataloged`, `harness:blocking`) documented with entry and exit criteria? [Completeness, Spec §FR-005, Spec §AC-3, Spec §AC-5]
- [x] CHK004 - Does the spec define how cross-repository harness propagation works between the central template and satellite projects? [Completeness, Spec §Glossário, Spec §Objective]
- [x] CHK005 - Are formal Functional Requirements (FR-001..FR-008) and Success Criteria (SC-001..SC-004) defined with unique IDs? [Completeness, Traceability, Spec §FR, Spec §SC]
- [x] CHK006 - Does the spec include a data model specifying entities (`HarnessEntry`, `HarnessQuery`, `IncidentPostMortem`)? [Completeness, Spec §Key Entities & Data Model]

## Requirement Clarity

- [x] CHK007 - Is the cataloging trigger "retrabalho > 20% do esforço estimado" quantified with an exact calculation formula and data source? [Clarity, Spec §FR-004, Spec §AC-3]
- [x] CHK008 - Is the matching algorithm for `tags` and `bounded_context` unambiguous (e.g. exact match vs substring vs tag intersection)? [Clarity, Spec §FR-007, Spec §AC-1]
- [x] CHK009 - Are data privacy, redaction, and sanitization rules defined for error logs and incident details before cataloging? [Clarity, Spec §FR-006, Spec §Hybrid Collaboration Model]
- [x] CHK010 - Is `harness:blocking` defined with explicit rules on who can apply and remove the blocking state? [Clarity, Spec §FR-005, Spec §AC-5]

## Consistency & Architecture Alignment

- [x] CHK011 - Does the spec maintain strict parity with the constitution rules and Copilot instructions regarding mandatory gate checks? [Consistency, Constitution, Spec §FR-002]
- [x] CHK012 - Are the search tool performance expectations consistent across native CLI tools (`grep`/`awk`) and `yq` without requiring external dependencies? [Consistency, Spec §FR-007, Spec §AC-4]
- [x] CHK013 - Does the relationship between `reuse-catalog.yaml` (successes/patterns) and `harness-catalog.yaml` (failures/anti-patterns) have distinct boundaries without semantic overlap? [Consistency, Spec §Glossário, Plan §Architecture Decision Log]

## Scenario & Edge Case Coverage

- [x] CHK014 - Does the spec define behavior when multiple distinct harness entries match the same feature domain? [Coverage, Spec §EC-001]
- [x] CHK015 - Does the spec define behavior when a feature's bounded context is not yet mapped in `docs/bounded-contexts.yaml`? [Coverage, Spec §EC-002]
- [x] CHK016 - Is the post-mortem flow specified for incidents that occur during agentic autonomous execution vs human development? [Coverage, Spec §FR-008, Spec §Hybrid Collaboration Model]
- [x] CHK017 - Are recovery procedures defined when a catalog YAML syntax error occurs during automated or manual editing? [Coverage, Spec §EC-003]

## Measurability & Quality Gate Verification

- [x] CHK018 - Can the 5-second search latency limit (AC-4) be objectively measured via automated integration tests? [Measurability, Spec §SC-001, Plan §Rastreabilidade]
- [x] CHK019 - Is there a measurable adoption metric (e.g., % of PRs with Harness Gate filled) to evaluate organizational compliance? [Measurability, Spec §SC-002, Spec §SC-003]
- [x] CHK020 - Are the post-mortem structure requirements in `incident-template.md` verifiable against a standard schema? [Measurability, Spec §FR-008, Spec §AC-6]
