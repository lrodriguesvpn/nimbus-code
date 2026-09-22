#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
}

@test "VS Code hides Claude native agents from its agent picker" {
  python3 - "$REPO_ROOT/.vscode/settings.json" <<'PY'
import json
import sys
from pathlib import Path

settings = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
locations = settings["chat.agentFilesLocations"]
assert locations[".github/agents"] is True
assert locations[".claude/agents"] is False
PY
}

@test "native outputs exist for every manifest NC role (claude) and a single orchestrator (vscode)" {
  count="$(find "$REPO_ROOT/.github/agents" -maxdepth 1 -name '*.agent.md' | wc -l | tr -d ' ')"
  [ "$count" -eq 1 ]
  [ -f "$REPO_ROOT/.github/agents/nimbus.agent.md" ]
  count="$(find "$REPO_ROOT/.github/agents" -maxdepth 1 -name 'nc-*.agent.md' | wc -l | tr -d ' ')"
  [ "$count" -eq 0 ]
  count="$(find "$REPO_ROOT/.claude/agents" -maxdepth 1 -name 'nc-*.md' | wc -l | tr -d ' ')"
  expected_count="$(find "$REPO_ROOT/.github/skills" -maxdepth 1 -type d -name 'nc-*' | wc -l | tr -d ' ')"
  # Assert against the real source-of-truth count (glob), not a hardcoded
  # number — a hardcoded expectation here previously drifted silently from
  # the actual .github/skills/nc-* inventory (see HRN-0006).
  [ "$count" -eq "$expected_count" ]
  [ "$expected_count" -ge 15 ]
}

@test "claude native outputs retain source instructions" {
  for agent in nc-assess-intake nc-builder nc-designer; do
    source_body="$(python3 -c 'from pathlib import Path; import sys; t=Path(sys.argv[1]).read_text(); print(t.split("---", 2)[2].strip() if t.startswith("---") else t.strip())' "$REPO_ROOT/.github/skills/$agent/SKILL.md")"
    generated_body="$(python3 -c 'from pathlib import Path; import sys; t=Path(sys.argv[1]).read_text(); print(t.split("---", 2)[2].strip())' "$REPO_ROOT/.claude/agents/$agent.md")"
    [ "$source_body" = "$generated_body" ]
  done
}

@test "nimbus orchestrator covers every manifest NC role by reference" {
  for agent in nc-assess-intake nc-builder nc-designer nc-arch nc-critic nc-governor nc-intake nc-qa nc-shield nc-spec nc-telemetry nc-assess-decide nc-assess-define nc-assess-research nc-assess-shape; do
    grep -q "/${agent}" "$REPO_ROOT/.github/agents/nimbus.agent.md"
  done
}
