#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_helpers.sh"

echo "== tests/agent-orchestration/scope-conflict.test.sh =="
python3 - <<'PY'
from pathlib import Path
import json, yaml

root = Path('.').resolve()
orchestration = yaml.safe_load((root / '.nimbus/orchestration.yaml').read_text())['orchestration']
a = json.loads((root / 'tests/agent-orchestration/fixtures/execution-scope-conflict-a.json').read_text())
b = json.loads((root / 'tests/agent-orchestration/fixtures/execution-scope-conflict-b.json').read_text())

stop_codes = {item['code'] for item in orchestration['stop_conditions']}
overlap = set(a['scope']['files']) & set(b['scope']['files'])
assert 'conflicting_scope_lock' in stop_codes
assert overlap == {'specs/008-bootstrap-governance-hardening/graph.yaml'}
PY
pass "conflito de lock de escopo interrompe a execução"
