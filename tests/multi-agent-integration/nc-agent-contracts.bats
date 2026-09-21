#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  HELPER="$REPO_ROOT/scripts/lib/nc-agent-sync.py"
}

@test "native projections expose constrained platform metadata" {
  for agent in nc-builder nc-arch nc-qa; do
    [ -f "$REPO_ROOT/.github/agents/${agent}.agent.md" ]
    [ -f "$REPO_ROOT/.claude/agents/${agent}.md" ]
    grep -q "^name: ${agent}$" "$REPO_ROOT/.github/agents/${agent}.agent.md"
    grep -q "^name: ${agent}$" "$REPO_ROOT/.claude/agents/${agent}.md"
    grep -q "^tools:" "$REPO_ROOT/.github/agents/${agent}.agent.md"
    grep -q "^tools:" "$REPO_ROOT/.claude/agents/${agent}.md"
  done
}

@test "parity fails when a native body drifts" {
  fixture="$(mktemp -d)"
  trap 'rm -rf "$fixture"' EXIT
  mkdir -p "$fixture/.nimbus" "$fixture/.github" "$fixture/.claude"
  cp "$REPO_ROOT/.nimbus/agent-manifest.yaml" "$fixture/.nimbus/"
  cp -R "$REPO_ROOT/.github/skills" "$fixture/.github/"
  cp -R "$REPO_ROOT/.github/agents" "$fixture/.github/"
  printf '\nDRIFT\n' >> "$fixture/.github/agents/nc-builder.agent.md"

  run python3 "$HELPER" --repo-root "$fixture" check --target vscode
  [ "$status" -ne 0 ]
  [[ "$output" == *"functional drift"* ]]
}
