# Bug Verification: happy-path test pins stale role count

- **Slug**: `agent-orchestration-role-count`
- **Tested**: 2026-09-22
- **Assessment**: ./assessment.md
- **Fix**: ./fix.md
- **Result**: verified

## Summary

Before the fix, the test failed on `95e68db` with a bare `AssertionError`.
After the fix it passes, and a manifest mutation makes it fail with a message
naming the missing role. No regressions: the rest of the agent-orchestration
group and the full mandatory suite pass.

## Checks Performed

| Check | Command / Action | Result | Notes |
|-------|------------------|--------|-------|
| Reproduction (pre-fix) | ran the `HEAD` (`95e68db`) version of the test | fail (expected) | bare `AssertionError` |
| Reproduction (post-fix) | `bash tests/agent-orchestration/happy-path.test.sh` | pass | |
| Negative / regression guard | removed `NC-Bug-Test` from a scratch copy of the manifest and reran | fail (expected) | message: `ausentes=['NC-Bug-Test']` |
| Agent-orchestration group | `bash tests/agent-orchestration/*.test.sh` | pass | 5/5 |
| Regression suite | `./scripts/run-tests.sh` | pass | 49/49 files; the tree contains 49 test files |
| Lint | `bash -n`, `shellcheck` | pass | only SC1091 (info) on the `source _helpers.sh` line, which this change didn't introduce |

## Output Excerpts

```
✓ happy path validado com manifesto, orquestração, contrato e fixture coerentes
Resultado consolidado: 49/49 arquivos de teste passaram.
```

## Residual Risks

- The expected role set has to be updated by hand when a new NC-* role is
  added. That is intentional, and the failure message names the new id.

## Recommendation

Close the bug. The fix is verified end-to-end, and the PR is ready for human
review.
