#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
}

@test "nimbus-code entrypoints do not use the broken raw GHE subdomain" {
  run bash -lc 'set -euo pipefail; cd "$1"; matches=$(grep -RIn "raw\\.venha-pra-nuvem\\.ghe\\.com/venha-pra-nuvem/nimbus-code-spec-kit-template/main/" README.md bootstrap.sh docs templates .github bundles presets extensions workflows tests || true); [ -z "$matches" ]' _ "$REPO_ROOT"
  [ "$status" -eq 0 ]
}

@test "bootstrap repo type prompt supports piped installs via /dev/tty fallback" {
  run bash -lc 'set -euo pipefail; cd "$1"; grep -q "/dev/tty" bootstrap.sh' _ "$REPO_ROOT"
  [ "$status" -eq 0 ]
}
