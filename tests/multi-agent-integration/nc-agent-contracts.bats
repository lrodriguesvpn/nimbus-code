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

@test "cursor native projections expose Skills-compatible metadata (no tools field)" {
  for agent in nc-builder nc-arch nc-qa; do
    local path="$REPO_ROOT/.cursor/skills/${agent}/SKILL.md"
    [ -f "$path" ]
    grep -q "^name: ${agent}$" "$path"
    grep -q "^compatibility:" "$path"
    grep -q "^metadata:" "$path"
    ! grep -q "^tools:" "$path"
  done
}

@test "kiro native projections expose Custom agents metadata (name/description/tools)" {
  for agent in nc-builder nc-arch nc-qa; do
    local path="$REPO_ROOT/.kiro/agents/${agent}.md"
    [ -f "$path" ]
    grep -q "^name: ${agent}$" "$path"
    grep -q "^description:" "$path"
    grep -q "^tools:" "$path"
    # Kiro's native Custom agents mechanism, not the generic prompts folder
    [ ! -f "$REPO_ROOT/.kiro/prompts/${agent}.md" ]
  done
}

@test "parity fails when the cursor native body drifts" {
  fixture="$(mktemp -d)"
  trap 'rm -rf "$fixture"' EXIT
  mkdir -p "$fixture/.nimbus" "$fixture/.github" "$fixture/.cursor"
  cp "$REPO_ROOT/.nimbus/agent-manifest.yaml" "$fixture/.nimbus/"
  cp -R "$REPO_ROOT/.github/skills" "$fixture/.github/"
  cp -R "$REPO_ROOT/.cursor/skills" "$fixture/.cursor/"
  printf '\nDRIFT\n' >> "$fixture/.cursor/skills/nc-builder/SKILL.md"

  run python3 "$HELPER" --repo-root "$fixture" check --target cursor
  [ "$status" -ne 0 ]
  [[ "$output" == *"functional drift"* ]]
}

@test "parity fails when the kiro native body drifts" {
  fixture="$(mktemp -d)"
  trap 'rm -rf "$fixture"' EXIT
  mkdir -p "$fixture/.nimbus" "$fixture/.github" "$fixture/.kiro"
  cp "$REPO_ROOT/.nimbus/agent-manifest.yaml" "$fixture/.nimbus/"
  cp -R "$REPO_ROOT/.github/skills" "$fixture/.github/"
  cp -R "$REPO_ROOT/.kiro/agents" "$fixture/.kiro/"
  printf '\nDRIFT\n' >> "$fixture/.kiro/agents/nc-builder.md"

  run python3 "$HELPER" --repo-root "$fixture" check --target kiro
  [ "$status" -ne 0 ]
  [[ "$output" == *"functional drift"* ]]
}

@test "parity fails when the claude native body drifts" {
  fixture="$(mktemp -d)"
  trap 'rm -rf "$fixture"' EXIT
  mkdir -p "$fixture/.nimbus" "$fixture/.github" "$fixture/.claude/skills" "$fixture/scripts/lib/templates"
  cp "$REPO_ROOT/.nimbus/agent-manifest.yaml" "$fixture/.nimbus/"
  cp -R "$REPO_ROOT/.github/skills" "$fixture/.github/"
  cp -R "$REPO_ROOT/.claude/agents" "$fixture/.claude/"
  cp -R "$REPO_ROOT/.claude/skills/nimbus" "$fixture/.claude/skills/"
  cp "$REPO_ROOT/scripts/lib/templates/nimbus-agent.template.md" "$fixture/scripts/lib/templates/"
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

@test "claude exposes the nimbus orchestrator as a main-thread skill, not a subagent" {
  local path="$REPO_ROOT/.claude/skills/nimbus/SKILL.md"
  [ -f "$path" ]
  grep -q "^name: nimbus$" "$path"
  grep -q "Claude" "$path"
  ! grep -q "^tools:" "$path"
  # Claude subagents cannot spawn subagents, so an orchestrator subagent could not delegate
  [ ! -f "$REPO_ROOT/.claude/agents/nimbus.md" ]
  for agent in nc-builder nc-arch nc-qa; do
    grep -q "/${agent}" "$path"
  done
}

@test "parity fails when the claude nimbus orchestrator drifts" {
  fixture="$(mktemp -d)"
  mkdir -p "$fixture/.nimbus" "$fixture/.github" "$fixture/.claude/skills" "$fixture/scripts/lib/templates"
  cp "$REPO_ROOT/.nimbus/agent-manifest.yaml" "$fixture/.nimbus/"
  cp -R "$REPO_ROOT/.github/skills" "$fixture/.github/"
  cp -R "$REPO_ROOT/.claude/agents" "$fixture/.claude/"
  cp -R "$REPO_ROOT/.claude/skills/nimbus" "$fixture/.claude/skills/"
  cp "$REPO_ROOT/scripts/lib/templates/nimbus-agent.template.md" "$fixture/scripts/lib/templates/"
  printf '\nDRIFT\n' >> "$fixture/.claude/skills/nimbus/SKILL.md"

  run python3 "$HELPER" --repo-root "$fixture" check --target claude
  rm -rf "$fixture"
  [ "$status" -ne 0 ]
  [[ "$output" == *"functional drift for nimbus in claude"* ]]
}
