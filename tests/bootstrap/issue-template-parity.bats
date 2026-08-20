#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  FAILURE_FIXTURE="$REPO_ROOT/specs/008-bootstrap-governance-hardening/fixtures/invalid-nimbus-code-task.md"
}

@test "parity validator passes for committed templates" {
  run bash -lc 'set -euo pipefail; cd "$1"; bash scripts/validate-issue-template-parity.sh' _ "$REPO_ROOT"
  [ "$status" -eq 0 ]
}

@test "parity validator reports a divergent fixture" {
  run bash -lc 'set -euo pipefail; cd "$1"; bash scripts/validate-issue-template-parity.sh --template-a presets/nimbus-code-standards/templates/project-root/.github/ISSUE_TEMPLATE/nimbus-code-task.md --template-b "$2" --label-a nimbus-code-standards --label-b fixture-divergente' _ "$REPO_ROOT" "$FAILURE_FIXTURE"
  [ "$status" -ne 0 ]
}
