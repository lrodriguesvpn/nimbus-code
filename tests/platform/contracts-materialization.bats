#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
}

validate_yaml() {
  python3 - "$1" <<'PY'
import sys
import yaml
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    yaml.safe_load(fh)
PY
}

@test "root e template expõem os contratos mínimos de plataforma" {
  local files=(
    "$REPO_ROOT/.nimbus/platform-profile.yaml"
    "$REPO_ROOT/.nimbus/execution-policy.yaml"
    "$REPO_ROOT/platform/evidence-registry.yaml"
    "$REPO_ROOT/platform/baseline-registry.yaml"
    "$REPO_ROOT/platform/drift-policy.yaml"
    "$REPO_ROOT/presets/nimbus-code-platform-standards/templates/project-root/.nimbus/platform-profile.yaml"
    "$REPO_ROOT/presets/nimbus-code-platform-standards/templates/project-root/.nimbus/execution-policy.yaml"
    "$REPO_ROOT/presets/nimbus-code-platform-standards/templates/project-root/platform/evidence-registry.yaml"
    "$REPO_ROOT/presets/nimbus-code-platform-standards/templates/project-root/platform/baseline-registry.yaml"
    "$REPO_ROOT/presets/nimbus-code-platform-standards/templates/project-root/platform/drift-policy.yaml"
  )

  for file in "${files[@]}"; do
    [ -f "$file" ]
    run validate_yaml "$file"
    [ "$status" -eq 0 ]
  done
}

@test "workflows e templates auxiliares existem no preset platform" {
  local files=(
    "$REPO_ROOT/.github/workflows/evidence-refresh.yml"
    "$REPO_ROOT/.github/workflows/terraform-plan.yml"
    "$REPO_ROOT/presets/nimbus-code-platform-standards/templates/project-root/.github/workflows/evidence-refresh.yml"
    "$REPO_ROOT/presets/nimbus-code-platform-standards/templates/project-root/.github/workflows/terraform-plan.yml"
    "$REPO_ROOT/presets/nimbus-code-platform-standards/templates/project-root/.github/workflows/protected-apply.yml"
    "$REPO_ROOT/presets/nimbus-code-platform-standards/templates/project-root/customer-profile.yaml"
    "$REPO_ROOT/presets/nimbus-code-platform-standards/templates/project-root/workload-links.yaml"
    "$REPO_ROOT/presets/nimbus-code-platform-standards/templates/project-root/evidence-record.yaml"
    "$REPO_ROOT/presets/nimbus-code-platform-standards/templates/project-root/drift-finding.yaml"
  )

  for file in "${files[@]}"; do
    [ -f "$file" ]
  done
}
