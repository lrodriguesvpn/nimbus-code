#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_helpers.sh"

echo "== tests/agent-orchestration/happy-path.test.sh =="
python3 - <<'PY'
from pathlib import Path
import json, yaml

root = Path('.').resolve()
manifest = yaml.safe_load((root / '.nimbus/agent-manifest.yaml').read_text())['manifest']
orchestration = yaml.safe_load((root / '.nimbus/orchestration.yaml').read_text())['orchestration']
contract = yaml.safe_load((root / '.nimbus/contracts/delivery-handoff.contract.yaml').read_text())
event = json.loads((root / 'tests/agent-orchestration/fixtures/execution-happy-path.json').read_text())

role_ids = {role['id'] for role in manifest['roles']}
assert len(role_ids) == 14 and 'NC-Builder' in role_ids and 'NC-Telemetry' in role_ids and 'NC-Assess-Intake' in role_ids
assert orchestration['phase_dependencies'][0]['phase'] == 'NC-Intake'
assert orchestration['phase_dependencies'][-1]['phase'] == 'NC-Telemetry'
required = set(contract['payload']['required'])
for field in ('cost_ai_tokens', 'execution_time_minutes', 'cost_human_hours', 'quality_status', 'rework_summary', 'rework_percentage'):
    assert field in required
assert event['final_result'] == 'success'
PY
pass "happy path validado com manifesto, orquestração, contrato e fixture coerentes"
