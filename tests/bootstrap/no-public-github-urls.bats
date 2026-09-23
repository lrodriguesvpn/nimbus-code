#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
}

@test "only the official Spec Kit source may reference public github.com" {
  run bash -lc 'set -euo pipefail; cd "$1"; matches=$(grep -RIn "github.com" bootstrap.sh README.md docs templates presets | grep -Ev "github.com/github/spec-kit|github.com/Quratulain-bilal/spec-kit-cost|github.com/actions/add-to-project|docs.github.com|github.com/mikefarah/yq|github.com/lrodriguesvpn/nimbus-code" || true); [ -z "$matches" ]' _ "$REPO_ROOT"
  [ "$status" -eq 0 ]
}
