#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_helpers.sh"

echo "== tests/agent-orchestration/retry-budget-exhausted.test.sh =="
python3 - <<'PY'
from pathlib import Path
import json, yaml

root = Path('.').resolve()
orchestration = yaml.safe_load((root / '.nimbus/orchestration.yaml').read_text())['orchestration']
event = json.loads((root / 'tests/agent-orchestration/fixtures/execution-retry-exhausted.json').read_text())

assert orchestration['retry_policy']['default_max_retries_per_phase'] == 2
assert event['retry_count'] == 2
assert event['failure_reason'] == 'retry_budget_exhausted'
assert event['final_result'] == 'failure'
PY
pass "retry budget esgotado falha a fase conforme política declarada"
