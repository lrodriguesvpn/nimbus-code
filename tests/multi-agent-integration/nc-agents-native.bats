#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
}

@test "native outputs exist for every manifest NC role" {
  count="$(find "$REPO_ROOT/.github/agents" -maxdepth 1 -name 'nc-*.agent.md' | wc -l | tr -d ' ')"
  [ "$count" -eq 15 ]
  count="$(find "$REPO_ROOT/.claude/agents" -maxdepth 1 -name 'nc-*.md' | wc -l | tr -d ' ')"
  [ "$count" -eq 15 ]
}

@test "native outputs retain source instructions" {
  for agent in nc-assess-intake nc-builder nc-designer; do
    source_body="$(python3 -c 'from pathlib import Path; import sys; t=Path(sys.argv[1]).read_text(); print(t.split("---", 2)[2].strip() if t.startswith("---") else t.strip())' "$REPO_ROOT/.github/skills/$agent/SKILL.md")"
    generated_body="$(python3 -c 'from pathlib import Path; import sys; t=Path(sys.argv[1]).read_text(); print(t.split("---", 2)[2].strip())' "$REPO_ROOT/.github/agents/$agent.agent.md")"
    [ "$source_body" = "$generated_body" ]
  done
}
