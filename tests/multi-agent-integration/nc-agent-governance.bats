#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
}

@test "governance: spec 025 graph.yaml exists and is valid YAML" {
  [ -f "$REPO_ROOT/specs/025-native-nc-agents/graph.yaml" ]
  python3 -c "import yaml; yaml.safe_load(open('$REPO_ROOT/specs/025-native-nc-agents/graph.yaml'))"
}

@test "governance: spec 025 impact-map.md exists and covers platforms and rollback" {
  [ -f "$REPO_ROOT/specs/025-native-nc-agents/impact-map.md" ]
  run grep -E "(vscode|claude|antigravity)" "$REPO_ROOT/specs/025-native-nc-agents/impact-map.md"
  [ "$status" -eq 0 ]
  run grep -i "rollback" "$REPO_ROOT/specs/025-native-nc-agents/impact-map.md"
  [ "$status" -eq 0 ]
}

@test "governance: spec 025 contracts are defined for vscode and claude" {
  [ -f "$REPO_ROOT/specs/025-native-nc-agents/contracts/vscode-custom-agent.contract.md" ]
  [ -f "$REPO_ROOT/specs/025-native-nc-agents/contracts/claude-subagent.contract.md" ]
}

@test "governance: spec 025 plan.md has approved ADLs and passing constitution checks" {
  [ -f "$REPO_ROOT/specs/025-native-nc-agents/plan.md" ]
  run grep -i "Aprovado por" "$REPO_ROOT/specs/025-native-nc-agents/plan.md"
  [ "$status" -eq 0 ]
  run grep -i "PASS" "$REPO_ROOT/specs/025-native-nc-agents/plan.md"
  [ "$status" -eq 0 ]
}
