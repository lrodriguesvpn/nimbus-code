# Research: Nimbus Agent Intake

## Decisions

1. The satellite sends an intake envelope with a stable `source_event_id`;
   retries are idempotent.
2. The central record is an Issue plus Project Item; creating a spec is a human
   decision and is never implicit.
3. Q&A answers use the central repository artifacts as normative sources with
   precedence: constitution, active spec/plan/tasks, then playbooks/catalogs.
4. Missing or conflicting evidence produces clarification or human review, never
   an invented rule.
5. Mode classification follows SPEC 017 and is explainable through a decision
   record. Semi-autonomous and manual modes require explicit Go/No-Go.
6. Authentication uses a least-privilege GitHub App; no PAT is accepted in the
   normal path. Intake data excludes secrets, credentials and unnecessary PII.
7. US5 Teams interview ingestion is roadmap-only and excluded from the MVP.

