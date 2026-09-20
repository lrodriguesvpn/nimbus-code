# Quickstart: Nimbus Agent Intake

## Prerequisites

- Test `nimbus-agent` issue and central GHE Project.
- Least-privilege GitHub App configured in a non-production environment.
- OpenFeature rollout flag disabled by default.

## Scenarios

1. Submit a valid envelope; verify one central Issue and Project Item within
   two minutes, with source link and idempotency key.
2. Replay the same envelope; verify no duplicate Issue or Project Item.
3. Submit an invalid envelope; verify explicit correction status and no
   execution.
4. Force a temporary central API failure; verify bounded retry and
   `reconciliation_pending`.
5. Classify autonomous, semi-autonomous and manual examples; verify the
   decision record and SPEC 017 rule references.
6. Attempt execution for semi-autonomous/manual mode without approval; verify
   the human gate blocks it. Record Go and No-Go paths.
7. Ask a process question with a source conflict; verify cited sources and a
   clarification request rather than an invented answer.
8. Enable the OpenFeature flag only in the pilot and verify rollback.

US5/Teams transcript validation is deferred until a separate roadmap phase.

