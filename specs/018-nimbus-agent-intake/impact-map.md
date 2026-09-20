# Impact Map: Nimbus Agent Intake

## Material risks

| Risk | Impact | Mitigation | Rollback |
|---|---|---|---|
| Duplicate projection | Duplicate backlog and governance drift | Idempotency key and reconciliation | Disable OpenFeature flag |
| Wrong autonomy mode | Unauthorized execution | Explainable decision + human gate | Block all non-manual execution |
| Source conflict in Q&A | Incorrect process guidance | Precedence and cited clarification | Disable Q&A action path |
| GHE outage | Lost/late intake | Retry and reconciliation state | Replay from source event |
| Sensitive payload | Data exposure | Reject secrets/PII and audit failures | Rotate App credentials and purge rejected payload |

## Required approvals

Architecture/security review before pilot; product/BA review of Q&A source
precedence; explicit Go/No-Go for semi-autonomous/manual execution.
