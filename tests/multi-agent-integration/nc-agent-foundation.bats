#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  HELPER="$REPO_ROOT/scripts/lib/nc-agent-sync.py"
}

# Fixture cleanup lives in teardown, never in `trap ... EXIT`: overriding the
# EXIT trap inside a test hijacks Bats' own reporting, so a failing test
# vanished from the report ("Executed N instead of expected N+1").
teardown() {
  if [ -n "${fixture:-}" ]; then
    rm -rf "$fixture"
  fi
}

@test "foundation helper validates the manifest and source inventory" {
  run python3 "$HELPER" --repo-root "$REPO_ROOT" check --target vscode
  [ "$status" -eq 0 ]
  [[ "$output" == *"Parity OK"* ]]
}

@test "foundation helper fails when a generated source is missing" {
  fixture="$(mktemp -d)"
  mkdir -p "$fixture/.nimbus" "$fixture/.github"
  cp "$REPO_ROOT/.nimbus/agent-manifest.yaml" "$fixture/.nimbus/"
  cp -R "$REPO_ROOT/.github/skills" "$fixture/.github/"
  rm "$fixture/.github/skills/nc-builder/SKILL.md"

  run python3 "$HELPER" --repo-root "$fixture" check --target vscode
  [ "$status" -ne 0 ]
  [[ "$output" == *"source skills missing"* ]]
}

@test "unsupported Antigravity native agents are not generated" {
  [ ! -d "$REPO_ROOT/.agents/agents" ]
}
