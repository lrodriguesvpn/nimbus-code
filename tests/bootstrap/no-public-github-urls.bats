#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
}

@test "only the official Spec Kit source may reference public github.com" {
  run bash -lc 'set -euo pipefail; cd "$1"; matches=$(grep -RIn "github.com" bootstrap.sh docs presets | grep -v "github.com/github/spec-kit" || true); [ -z "$matches" ]' _ "$REPO_ROOT"
  [ "$status" -eq 0 ]
}
