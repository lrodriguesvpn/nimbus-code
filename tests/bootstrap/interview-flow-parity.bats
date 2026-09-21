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

@test "readme bundle versions stay aligned with release catalogs" {
  run bash -lc 'set -euo pipefail; cd "$1"; \
    bundle_version=$(jq -r ".bundles[\"nimbus-code-project-bundle\"].version" bundles/catalog.json); \
    preset_version=$(jq -r ".presets[\"nimbus-code-standards\"].version" presets/catalog.json); \
    extension_version=$(jq -r ".extensions[\"nimbus-code-backlog-sync\"].version" extensions/catalog.json); \
    workflow_version=$(jq -r ".workflows[\"nimbus-code-full-cycle\"].version" workflows/catalog.json); \
    grep -Fq "bundle: nimbus-code-project-bundle (v${bundle_version})" README.md; \
    grep -Fq "preset: nimbus-code-standards (v${preset_version})" README.md; \
    grep -Fq "| **Bundle \`nimbus-code-project-bundle\`**" templates/README-bundle-section.md; \
    grep -Fq "| \`$bundle_version\` |" templates/README-bundle-section.md; \
    grep -Fq "| — preset \`nimbus-code-standards\` | \`$preset_version\` |" templates/README-bundle-section.md; \
    grep -Fq "| — extensão \`nimbus-code-backlog-sync\` | \`$extension_version\` |" templates/README-bundle-section.md; \
    grep -Fq "| — workflow \`nimbus-code-full-cycle\` | \`$workflow_version\` |" templates/README-bundle-section.md' _ "$REPO_ROOT"
  [ "$status" -eq 0 ]
}
