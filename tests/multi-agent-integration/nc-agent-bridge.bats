#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
}

@test "native generation keeps legacy NC and custom speckit bridges" {
  for agent in nc-assess-intake nc-builder nc-telemetry nc-designer; do
    [ -f "$REPO_ROOT/.github/skills/${agent}/SKILL.md" ]
    [ -f "$REPO_ROOT/.claude/skills/${agent}/SKILL.md" ]
    [ -f "$REPO_ROOT/.agents/skills/${agent}/SKILL.md" ]
  done

  for command in speckit-interview speckit-nimbus-code-backlog-sync-sync; do
    [ -f "$REPO_ROOT/.github/skills/${command}/SKILL.md" ]
    [ -f "$REPO_ROOT/.claude/skills/${command}/SKILL.md" ]
    [ -f "$REPO_ROOT/.agents/skills/${command}/SKILL.md" ]
  done
}
