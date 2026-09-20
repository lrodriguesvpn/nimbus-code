# Specification Quality Checklist: Governança de Testes em PR

**Purpose**: Validate whether the test governance spec completely and unambiguously defines the test taxonomy, decision matrix (Bats-core vs .test.sh), unified PR gate workflow, local parity, and exception governance.
**Created**: 2026-09-20
**Feature**: [spec.md](../spec.md)

## Requirement Completeness

- [x] CHK001 - Does the spec explicitly inventory all pre-existing executable tests across `tests/bootstrap/`, `tests/docs/`, `tests/scripts/`, and `tests/workflows/`? [Completeness, Spec §AC-1, Spec §FR-001]
- [x] CHK002 - Are the taxonomy definitions for Unit, Integration, and End-to-End (E2E) tests clear and testable for this bundle? [Completeness, Spec §AC-5, Spec §FR-005]
- [x] CHK003 - Does the spec define the unified PR gate workflow (`test-suite.yml`) and its execution triggers on pull requests against `main`? [Completeness, Spec §AC-3, Spec §FR-007]
- [x] CHK004 - Is the single local entrypoint command (`scripts/run-tests.sh`) documented with exact parity to the CI gate? [Completeness, Spec §AC-4, Spec §FR-008]
- [x] CHK005 - Is there an explicit Exception Record governance flow for introducing non-standard test formats or bypasses? [Completeness, Spec §AC-6, Spec §FR-009]

## Requirement Clarity & Format Decision

- [x] CHK006 - Is the format decision matrix documented comparing Bats-core, simple `.test.sh`, and third-party tools with concrete pros/cons? [Clarity, Spec §AC-2, Spec §FR-003]
- [x] CHK007 - Are legacy/simple `.test.sh` files explicitly classified as an accepted, permanent format rather than an unmanaged technical debt? [Clarity, Spec §FR-010]
- [x] CHK008 - Is the phased release rollout (report-only mode first -> human-approved promotion to required status check) unambiguously specified? [Clarity, Plan §Estratégia de Release]

## Measurability & Quality Gates

- [x] CHK009 - Is the maximum CI PR gate execution time limit (< 15 min / 900,000 ms) objectively verifiable? [Measurability, Spec §SLO Alvo]
- [x] CHK010 - Does the test failure output requirement mandate immediate segment identification (`bootstrap`, `docs`, `scripts`, `workflows`) on first read? [Measurability, Spec §FR-011]
- [x] CHK011 - Does the spec require zero external credentials, zero public internet dependency, and pure runner environment isolation? [Security, Constitution, Spec §Edge Cases]
- [x] CHK012 - Is the reusable unified gate pattern cataloged in `docs/reuse-catalog.yaml`? [Traceability, Spec §FR-004]
