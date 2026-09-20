#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_helpers.sh"

echo "== tests/agent-orchestration/handoff-incomplete.test.sh =="
python3 - <<'PY'
from pathlib import Path
import yaml

root = Path('.').resolve()
contract = yaml.safe_load((root / '.nimbus/contracts/delivery-handoff.contract.yaml').read_text())
handoff = yaml.safe_load((root / 'tests/agent-orchestration/fixtures/handoff-incomplete.yaml').read_text())

required = set(contract['payload']['required'])
present = set((handoff.get('payload') or {}).keys())
missing = required - present
assert {'quality_evidence', 'cost_ai_tokens', 'execution_time_minutes', 'cost_human_hours', 'quality_status', 'rework_summary', 'rework_percentage'} <= missing
PY
pass "handoff incompleto é rejeitado por campos obrigatórios ausentes"
