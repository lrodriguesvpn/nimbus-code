#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
}

@test "lifecycle e campos de evidência aparecem nos contratos principais" {
  run python3 - "$REPO_ROOT" <<'PY'
from pathlib import Path
import yaml
import sys
root = Path(sys.argv[1])
profile = yaml.safe_load((root / '.nimbus/platform-profile.yaml').read_text())
drift = yaml.safe_load((root / 'platform/drift-policy.yaml').read_text())
graph = (root / 'presets/nimbus-code-platform-standards/templates/feature-artifacts/platform-graph.yaml').read_text()
assert profile['execution_policy']['allow_direct_cloud_write'] is False
assert drift['lifecycle']['ordered_stages'] == ['discovery', 'imported', 'plan_diff_zero', 'landing_zone_generated', 'managed']
for token in ['workloads:', 'evidence:', 'owner:', 'depends_on:']:
    assert token in graph, token
print('ok')
PY
  [ "$status" -eq 0 ]
}

@test "workflow de terraform plan exige artifact e bloqueio de destroy" {
  run python3 - "$REPO_ROOT/.github/workflows/terraform-plan.yml" <<'PY'
from pathlib import Path
import sys
text = Path(sys.argv[1]).read_text()
required = [
    'actions/upload-artifact@v4',
    'gh pr comment',
    'destroy_count',
    'Zero-diff é obrigatório',
]
for token in required:
    assert token in text, token
print('ok')
PY
  [ "$status" -eq 0 ]
}
