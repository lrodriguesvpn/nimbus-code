# Data Model: Nimbus Agent Intake

## Intake Demand

`source_event_id`, `source_repo`, `source_issue`, `title`, `description`,
`bounded_context`, `priority`, `requested_by`, `received_at`, `status`.

`source_event_id` is globally unique. `status` is `received`, `invalid`,
`reconciliation_pending`, `projected`, `blocked` or `closed`.

## Project Item

`central_issue`, `central_project_item`, `source_event_id`, `feature_ref`,
`priority`, `mode_decision_id`, `created_at`, `updated_at`.

One source event maps to at most one central Issue and Project Item.

## Mode Decision

`id`, `intake_id`, `mode` (`autonomous`, `semi-autonomous`, `manual`),
`reason`, `confidence`, `rules_evaluated`, `decided_by`, `decided_at`.

Confidence below the configured threshold or conflicting rules forces human
review.

## Approval Decision

`id`, `intake_id`, `decision` (`go`, `no-go`), `approver`, `reason`,
`decided_at`, `evidence_ref`.

Required before execution for semi-autonomous and manual modes.

## State transitions

`received → invalid` for schema failure; `received → reconciliation_pending`
for retryable external failure; `received → projected` after central Issue and
Project Item creation; `projected → blocked` when approval is required;
`blocked → closed` only after Go; `blocked → closed` with No-Go records the
decision and prevents execution.

