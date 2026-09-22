# Bug Fix: happy-path test pins stale role count

- **Slug**: `agent-orchestration-role-count`
- **Fixed**: 2026-09-22
- **Assessment**: ./assessment.md
- **Status**: applied

## Summary

`len(role_ids) == 15` is replaced by an equality check against the explicit
set of 18 manifest roles, including NC-Bug-Assess, NC-Bug-Fix and NC-Bug-Test.
Every assertion in the happy-path test now has a descriptive message.

## Changes

| File | Change | Notes |
|------|--------|-------|
| `tests/agent-orchestration/happy-path.test.sh` | modified | Checks the exact role set. Also guards against duplicate ids. Adds messages to the phase-order, contract-field and fixture assertions. |

## Diff Highlights

```python
assert role_ids == expected_roles, (
    f"papéis do manifesto divergem do esperado; "
    f"ausentes={sorted(expected_roles - role_ids)} inesperados={sorted(role_ids - expected_roles)}"
)
```

## Tests Added or Updated

- `tests/agent-orchestration/happy-path.test.sh`: pins the full NC-* role set
  in `.nimbus/agent-manifest.yaml`. It still checks the orchestration
  first and last phases, the delivery-handoff required fields and the fixture
  result.

## Local Verification

- `bash tests/agent-orchestration/happy-path.test.sh` → passes.
- Negative check: I removed `NC-Bug-Test` from a scratch copy of the manifest.
  The test fails with
  `AssertionError: papéis do manifesto divergem do esperado; ausentes=['NC-Bug-Test'] inesperados=[]`.
- `./scripts/run-tests.sh` → `49/49 arquivos de teste passaram`.

## Deviations from Assessment

- The assessment expected 50/50. This tree contains 49 test files (checked
  with `find` in this worktree and in the main checkout), so 49/49 is the
  complete suite. The "49/50" in the report was probably taken from a
  different tree or run.

## Follow-ups

- None.
