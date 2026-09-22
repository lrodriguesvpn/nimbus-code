# Bug Assessment: happy-path test pins stale role count

- **Slug**: `agent-orchestration-role-count`
- **Created**: 2026-09-22
- **Source**: pasted text (manual report in a Claude Code session; no GHE Issue)
- **Verdict**: valid
- **Severity**: medium

## Report (summarized)

`tests/agent-orchestration/happy-path.test.sh` fails with a bare
`AssertionError` at line 17 of the embedded Python
(`assert len(role_ids) == 15 and ...`). `.nimbus/agent-manifest.yaml` now
declares 18 roles, because NC-Bug-Assess, NC-Bug-Fix and NC-Bug-Test were
added. `./scripts/run-tests.sh` reports 49/50. The failure also reproduces on
`origin/develop` at `95e68db`.

## Symptom

The happy-path orchestration test fails on a clean tree. The
`AssertionError` has no message, so it does not say which condition failed.
Expected: the test passes against the current manifest, and any failure names
the condition that broke.

## Reproduction

1. Check out `95e68db` (`origin/develop`).
2. Run `bash tests/agent-orchestration/happy-path.test.sh`.
3. Observe `Traceback ... File "<stdin>", line 11 ... AssertionError`. That is
   line 11 of the heredoc, which is line 17 of the file.

## Suspected Code Paths

- `tests/agent-orchestration/happy-path.test.sh:17`: hardcodes
  `len(role_ids) == 15`. The last update was in `17b21a1` (14 → 15, adding
  NC-Designer).
- `.nimbus/agent-manifest.yaml:234-270`: `54507a5` added the `NC-Bug-Assess`,
  `NC-Bug-Fix` and `NC-Bug-Test` roles (15 → 18) and did not update the test.

## Root Cause Hypothesis

This is test drift, not a product defect. The test uses a magic-number count
that has to be updated by hand each time a role is added to the manifest.
`54507a5` legitimately added three bug-flow roles and left the count at 15.
Confidence: high. The manifest has exactly 18 unique ids, and it is the only
assertion that fails. The orchestration phase order (NC-Intake … NC-Telemetry)
and the delivery-handoff `payload.required` fields still match the other
assertions.

## Proposed Remediation

**Preferred**: replace the count check with an equality check against the
explicit expected set of 18 role ids, including the three bug roles. On
failure, report the missing and unexpected ids. Add descriptive messages to
every assertion in the heredoc (phase order, contract fields, fixture result)
so future failures explain themselves.

**Alternatives**:
- Only bump `15` → `18`. This is the smallest diff, but it keeps the magic
  number and the uninformative failure.
- Derive the expected set from another source, such as `.claude/agents/`.
  Rejected: that would couple this test to projection parity, which the
  spec-025 parity tests already cover.

**Files likely to change**:
- `tests/agent-orchestration/happy-path.test.sh`

**Tests to add or update**:
- The updated happy-path test itself. Verify it with
  `bash tests/agent-orchestration/happy-path.test.sh` and
  `./scripts/run-tests.sh` (expect 50/50).

## Risks & Considerations

- An explicit set still has to be updated when a role is added. That is
  intentional: adding a role should be a deliberate, reviewed test change,
  and the failure message will name the new id.

## Open Questions

- None.
