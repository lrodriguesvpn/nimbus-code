# Implementation Plan: Nimbus Agent Process Q&A and Direct Intake

> **Backlog:** este plano está preservado para referência, mas a implementação
> da SPEC 018 está adiada e não deve ser iniciada neste ciclo.

**Branch**: `018-nimbus-agent-intake` | **Date**: 2026-09-20 | **Spec**: [spec.md](./spec.md)

## Summary

Add a governed intake envelope from `nimbus-agent` to the central repository,
create an idempotent Issue/Project Item, classify execution mode under SPEC 017,
and provide evidence-backed process Q&A. Teams interview ingestion remains
roadmap-only.

## Technical Context

**Language/Version**: Consumer-defined; contract-first integration  
**Primary Dependencies**: GitHub App, Issues/Projects API, central spec artifacts  
**Storage**: GitHub Issue/Project metadata plus append-only audit record  
**Testing**: contract, integration, replay/idempotency and human-gate tests  
**Target Platform**: GHE-hosted workflow/service  
**Project Type**: multi-repository intake integration and process Q&A  
**Performance Goals**: valid intake visible within 2 minutes; Q&A p99 <2.5s  
**Constraints**: least privilege, no secrets/PII in payload, explicit failures,
OpenFeature rollout, human approval for semi-autonomous/manual modes  
**Scale/Scope**: satellite `nimbus-agent` to central project; MVP excludes Teams

## Architecture and decisions

- Intake envelope → validation → idempotency lookup → central Issue → Project
  Item → mode decision → human gate when required.
- Q&A retrieval precedence is constitution, active spec/plan/tasks, then
  playbooks/catalogs. Conflicts are reported with source references.
- Retryable failures use bounded retry and `reconciliation_pending`; permanent
  validation failures are visible for correction and do not advance.
- OpenFeature is the rollout abstraction; provider is environment-specific.
- Audit records include source event, actor, mode, decision, timestamps and
  central references. Transcript ingestion is not part of MVP.

## Constitution Check

- Secrets/PII: pass — payload validation rejects them.
- SSO/least privilege/TLS: pass — GitHub App and HTTPS required.
- Human gates: pass — semi-autonomous/manual cannot execute without Go/No-Go.
- OpenFeature: pass — required for direct-intake rollout.
- S3 graph/impact map/cost reference: included.

## Traceability

| Requirement | Tasks |
|---|---|
| FR-001–FR-003 | T004–T010 |
| FR-004–FR-006 | T011–T016 |
| FR-007–FR-010 | T017–T022 |
| FR-011–FR-012 | T023–T024 roadmap only |
| SC-001–SC-005 | T025–T028 |

## Cost Reference

Estimated delivery: 35–55k agent tokens and 6–12 human hours. Record actual
tokens in the session ledger and human time in GitHub Project `Horas Humanas`.
