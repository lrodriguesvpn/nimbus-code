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

expected_roles = {
    'NC-Assess-Intake', 'NC-Assess-Research', 'NC-Assess-Define', 'NC-Assess-Shape', 'NC-Assess-Decide',
    'NC-Intake', 'NC-Spec', 'NC-Critic', 'NC-Governor', 'NC-Arch', 'NC-Shield', 'NC-Designer', 'NC-QA',
    'NC-Builder', 'NC-Telemetry',
    'NC-Bug-Assess', 'NC-Bug-Fix', 'NC-Bug-Test',
}
role_list = [role['id'] for role in manifest['roles']]
role_ids = set(role_list)
assert len(role_list) == len(role_ids), f"ids duplicados no manifesto: {sorted({r for r in role_list if role_list.count(r) > 1})}"
assert role_ids == expected_roles, (
    f"papéis do manifesto divergem do esperado; "
    f"ausentes={sorted(expected_roles - role_ids)} inesperados={sorted(role_ids - expected_roles)}"
)
phases = [dep['phase'] for dep in orchestration['phase_dependencies']]
assert phases[0] == 'NC-Intake', f"primeira fase deveria ser NC-Intake, obtido {phases[0]!r}"
assert phases[-1] == 'NC-Telemetry', f"última fase deveria ser NC-Telemetry, obtido {phases[-1]!r}"
required = set(contract['payload']['required'])
for field in ('cost_ai_tokens', 'execution_time_minutes', 'cost_human_hours', 'quality_status', 'rework_summary', 'rework_percentage'):
    assert field in required, f"campo {field!r} ausente em payload.required do contrato delivery-handoff"
assert event['final_result'] == 'success', f"fixture happy-path deveria ter final_result=success, obtido {event['final_result']!r}"
PY
pass "happy path validado com manifesto, orquestração, contrato e fixture coerentes"
