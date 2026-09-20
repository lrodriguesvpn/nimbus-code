# Contract: Direct Intake Envelope

```json
{
  "source_event_id": "nimbus-agent:issue:123:updated:7",
  "source_repo": "venha-pra-nuvem/nimbus-agent",
  "source_issue": 123,
  "title": "Solicitar nova capacidade",
  "description": "Demanda operacional",
  "bounded_context": "spec-kit-workflow",
  "priority": "P2",
  "requested_by": "user-login",
  "occurred_at": "2026-09-20T15:00:00Z"
}
```

All fields are required except `bounded_context` when triage is needed.
`source_event_id` provides idempotency. Payloads containing secrets, tokens,
credentials or unnecessary PII are rejected with an explicit validation error.

