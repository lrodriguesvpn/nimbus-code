#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
}

@test "interview bundle assets exist in source and active preset mirrors" {
  run bash -lc 'set -euo pipefail; cd "$1"; \
    test -f .github/skills/speckit-interview/SKILL.md; \
    test -f presets/nimbus-code-standards/templates/feature-artifacts/interview-template.md; \
    test -f presets/nimbus-code-standards/templates/project-root/.github/skills/speckit-interview/SKILL.md; \
    test -f presets/nimbus-code-standards/templates/project-root/.specify/scripts/bash/validate-interview-completeness.sh; \
    test -f .specify/presets/nimbus-code-standards/templates/feature-artifacts/interview-template.md; \
    test -f .specify/presets/nimbus-code-standards/templates/project-root/.github/skills/speckit-interview/SKILL.md; \
    test -f .specify/presets/nimbus-code-standards/templates/project-root/.specify/scripts/bash/validate-interview-completeness.sh' _ "$REPO_ROOT"
  [ "$status" -eq 0 ]
}

@test "interview bundle registry advertises the new assets" {
  run bash -lc 'set -euo pipefail; cd "$1"; \
    grep -q "speckit-interview-skill" presets/nimbus-code-standards/preset.yml; \
    grep -q "interview-template" presets/nimbus-code-standards/preset.yml; \
    grep -q "validate-interview-completeness-script" presets/nimbus-code-standards/preset.yml; \
    grep -q "speckit-interview-skill" .specify/presets/nimbus-code-standards/preset.yml; \
    grep -q "interview-template" .specify/presets/nimbus-code-standards/preset.yml; \
    grep -q "validate-interview-completeness-script" .specify/presets/nimbus-code-standards/preset.yml' _ "$REPO_ROOT"
  [ "$status" -eq 0 ]
}

@test "docs mention the interview flow entrypoint" {
  run bash -lc 'set -euo pipefail; cd "$1"; \
    grep -q "/speckit-interview" README.md; \
    grep -q "/speckit-interview" docs/developer-guide.md; \
    grep -q "/speckit-interview" templates/README-bundle-section.md' _ "$REPO_ROOT"
  [ "$status" -eq 0 ]
}
