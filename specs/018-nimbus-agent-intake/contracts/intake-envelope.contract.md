# Contract: Direct Intake Envelope

```json
{
  "source_event_id": "nimbus-agent:issue:123:updated:7",
  "source_channel": "teams_bot | cli_command | transcript_upload",
  "source_repo": "venha-pra-nuvem/nimbus-agent",
  "source_issue": 123,
  "title": "Solicitar nova capacidade",
  "description": "Demanda operacional",
  "bounded_context": "spec-kit-workflow",
  "priority": "P2",
  "requested_by": "user-login",
  "interview_payload": {
    "interview_file": "specs/<feature-slug>/interview.md",
    "coverage_status": "complete | missing_blocks",
    "blocks_covered": ["business", "infrastructure", "security", "lgpd"]
  },
  "occurred_at": "2026-09-20T15:00:00Z"
}
```

All fields are required except `bounded_context` when triage is needed.
`source_channel` identifies the intake channel:
- `teams_bot`: Intake conversacional coletado via Microsoft Teams bot.
- `cli_command`: Intake disparado via console/Copilot Chat (`/nc-intake`, `/speckit-interview`).
- `transcript_upload`: Ingestão direta de arquivo `.txt`/`.vtt`/`.md` ou texto de reunião colado.

`source_event_id` provides idempotency. Payloads containing secrets, tokens,
credentials or unnecessary PII are rejected with an explicit validation error.

