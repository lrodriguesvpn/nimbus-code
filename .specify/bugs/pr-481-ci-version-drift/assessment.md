# Bug Assessment: PR #481 CI version drift

- **Slug**: `pr-481-ci-version-drift`
- **Created**: 2026-09-21T17:54:09-03:00
- **Source**: GHE PR [#481](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/pull/481) and failed workflow run [219390096](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/actions/runs/219390096)
- **Verdict**: valid, likely pre-existing
- **Severity**: high

## Report

PR #481 was merged, but the required CI checks reported failures:

1. **Bootstrap Crítico (bloqueante)** failed in `tests/bootstrap/*.bats`.
2. **Detect Preset Version Mismatches** failed because the active preset mirror
   did not match the release catalog.
3. **Suíte de Testes Mandatória (relatório)** failed with 47/48 test files
   passing.

The failure logs are the authoritative source for this assessment. No code
change from PR #481 directly modifies the release catalogs or README version
references.

## Symptom

The repository contains inconsistent version metadata across the source preset,
release catalogs, and README bundle documentation. As a result, the preset
validation gate and bootstrap test suite fail even though the agent visibility
tests and agent parity checks pass.

Expected behavior: all canonical version metadata and published documentation
should resolve to the same approved release versions, allowing bootstrap and
the mandatory suite to pass.

## Reproduction

1. Check out the PR #481 branch or the corresponding merged tree.
2. Run:
   ```bash
   bash .specify/scripts/bash/detect-preset-version-mismatch.sh --json
   ```
3. Run:
   ```bash
   bats tests/bootstrap/interview-flow-parity.bats
   ```
4. Observe:
   - `.specify/presets/nimbus-code-standards/preset.yml` reports `1.20.0`;
   - `presets/catalog.json` and `bundles/catalog.json` expect `1.21.0`;
   - `README.md` and `templates/README-bundle-section.md` still advertise
     `1.19.0`.

## Evidence

### Failure A: preset mirror mismatch

The workflow reported:

```json
{
  "status": "mismatch",
  "preset": "nimbus-code-standards",
  "version": "1.21.0",
  "basis": "bundle_manifest",
  "mismatches": [
    {
      "file": ".specify/presets/nimbus-code-standards/preset.yml",
      "expected": "1.21.0",
      "actual": "1.20.0"
    }
  ]
}
```

Local reproduction returns the same mismatch and exit code 1.

### Failure B: README/catalog mismatch

`tests/bootstrap/interview-flow-parity.bats` test 4 fails because:

- `bundles/catalog.json` advertises project bundle `1.21.0`;
- `presets/catalog.json` advertises `nimbus-code-standards` `1.21.0`;
- `README.md` advertises the project bundle and preset as `1.19.0`;
- `templates/README-bundle-section.md` advertises the bundle as `1.19.0`.

The mandatory suite identifies this as the only failed test file:
`tests/bootstrap/interview-flow-parity.bats`, resulting in 47/48 files passing.
The Bootstrap Crítico check repeats the same failure as test 26.

## Suspected root cause

The repository has multiple version authorities that were updated
asynchronously:

1. The release catalogs and source preset were advanced to different versions.
2. The `.specify/presets` active mirror was not refreshed to the catalog version.
3. README version references were not updated during the release bump.

The commit in PR #481 adds VS Code settings, tests, and Feature 026 discovery
artifacts; it does not change these version-bearing files. Therefore the
failure is **likely pre-existing** and was exposed by the mandatory CI gates,
not introduced by the agent visibility change.

## Severity rationale

**High**: the failed checks are release/bootstrap gates. A consumer can receive
an inconsistent preset version, and the repository cannot establish a clean
green release state. The evidence does not indicate data loss or a security
vulnerability in the PR change itself, so this is not classified as critical.

## Proposed remediation

### Preferred fix

1. Select the single approved release version from the release manifest.
2. Refresh `.specify/presets/nimbus-code-standards/preset.yml` from the approved
   source preset rather than editing only its version string.
3. Update `README.md` and `templates/README-bundle-section.md` from the same
   release metadata.
4. Run the repository's parity, preset detector, bootstrap, and mandatory test
   suites.
5. Add or strengthen a release validation gate that rejects catalog/source/
   documentation drift before merge.

### Alternative

Generate all release catalogs and README version fragments from one canonical
manifest during release preparation. This reduces future drift but is a larger
release-process change and should be planned separately if not already
supported by existing tooling.

## Files likely to change during fix

- `.specify/presets/nimbus-code-standards/preset.yml`
- `README.md`
- `templates/README-bundle-section.md`
- Potentially the release catalog or version-generation validation scripts,
  only if the canonical source is found to be incorrect.

## Tests required

- `bats tests/bootstrap/bootstrap-preset-detection.bats`
- `bats tests/bootstrap/interview-flow-parity.bats`
- `bats tests/bootstrap/*.bats`
- `./scripts/run-tests.sh`
- `scripts/sync-nc-agents-to-integrations.sh --check --target all`

## Risks and open questions

- Do not blindly replace `1.20.0` with `1.21.0` until the approved release
  source and all component versions are confirmed.
- The active branch is based on the pre-merge commit; the fix must be based on
  the current default branch after PR #481 was merged.
- The catalog currently contains both project/platform bundles with different
  version values. The release policy must clarify whether this is intentional or
  another mismatch.
- `[NEEDS CLARIFICATION]` Confirm the authoritative release manifest and the
  intended version for the platform bundle before implementation.

## Handoff

This assessment is ready for `/nc-bug-fix` after confirming the authoritative
release version. The proposed fix should be implemented as a separate branch and
PR; PR #481 is already merged and should not be amended.
