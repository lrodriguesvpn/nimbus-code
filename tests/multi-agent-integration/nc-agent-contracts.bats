#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  HELPER="$REPO_ROOT/scripts/lib/nc-agent-sync.py"
}

@test "claude native projections expose constrained platform metadata" {
  for agent in nc-builder nc-arch nc-qa; do
    [ -f "$REPO_ROOT/.claude/agents/${agent}.md" ]
    grep -q "^name: ${agent}$" "$REPO_ROOT/.claude/agents/${agent}.md"
    grep -q "^tools:" "$REPO_ROOT/.claude/agents/${agent}.md"
  done
}

@test "vscode exposes a single nimbus orchestrator with constrained metadata" {
  [ -f "$REPO_ROOT/.github/agents/nimbus.agent.md" ]
  grep -q "^name: nimbus$" "$REPO_ROOT/.github/agents/nimbus.agent.md"
  grep -q "^tools:" "$REPO_ROOT/.github/agents/nimbus.agent.md"
  for agent in nc-builder nc-arch nc-qa; do
    [ ! -f "$REPO_ROOT/.github/agents/${agent}.agent.md" ]
    grep -q "skill:${agent}" "$REPO_ROOT/.github/agents/nimbus.agent.md"
  done
}

@test "parity fails when the claude native body drifts" {
  fixture="$(mktemp -d)"
  trap 'rm -rf "$fixture"' EXIT
  mkdir -p "$fixture/.nimbus" "$fixture/.github" "$fixture/.claude"
  cp "$REPO_ROOT/.nimbus/agent-manifest.yaml" "$fixture/.nimbus/"
  cp -R "$REPO_ROOT/.github/skills" "$fixture/.github/"
  cp -R "$REPO_ROOT/.claude/agents" "$fixture/.claude/"
  printf '\nDRIFT\n' >> "$fixture/.claude/agents/nc-builder.md"

  run python3 "$HELPER" --repo-root "$fixture" check --target claude
  [ "$status" -ne 0 ]
  [[ "$output" == *"functional drift"* ]]
}

@test "parity fails when the nimbus orchestrator body drifts" {
  fixture="$(mktemp -d)"
  trap 'rm -rf "$fixture"' EXIT
  mkdir -p "$fixture/.nimbus" "$fixture/.github/agents" "$fixture/scripts/lib/templates"
  cp "$REPO_ROOT/.nimbus/agent-manifest.yaml" "$fixture/.nimbus/"
  cp -R "$REPO_ROOT/.github/skills" "$fixture/.github/"
  cp "$REPO_ROOT/scripts/lib/templates/nimbus-agent.template.md" "$fixture/scripts/lib/templates/"
  cp "$REPO_ROOT/.github/agents/nimbus.agent.md" "$fixture/.github/agents/"
  printf '\nDRIFT\n' >> "$fixture/.github/agents/nimbus.agent.md"

  run python3 "$HELPER" --repo-root "$fixture" check --target vscode
  [ "$status" -ne 0 ]
  [[ "$output" == *"functional drift"* ]]
}
