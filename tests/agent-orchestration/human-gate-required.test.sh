#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_helpers.sh"

echo "== tests/agent-orchestration/human-gate-required.test.sh =="
python3 - <<'PY'
from pathlib import Path
import json, yaml

root = Path('.').resolve()
manifest = yaml.safe_load((root / '.nimbus/agent-manifest.yaml').read_text())['manifest']
event = json.loads((root / 'tests/agent-orchestration/fixtures/execution-human-gate-missing.json').read_text())

assert manifest['approval_matrix_by_complexity']['S4']['human_approval_before_action'] is True
assert event['approval']['required'] is True
assert event['approval']['status'] == 'missing'
assert event['failure_reason'] == 'missing_human_approval'
PY
pass "gate humano obrigatório para S4 bloqueia escrita sem aprovação"
