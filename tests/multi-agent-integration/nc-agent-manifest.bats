#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
}

@test "generated claude native tools remain within manifest allowlists" {
  python3 - "$REPO_ROOT" <<'PY'
import sys
from pathlib import Path
import yaml

root = Path(sys.argv[1])
manifest = yaml.safe_load((root / ".nimbus/agent-manifest.yaml").read_text())
roles = {role["id"].lower(): set(role["tool_allowlist"]) for role in manifest["manifest"]["roles"]}
for path in (root / ".claude/agents").glob("nc-*.md"):
    metadata = yaml.safe_load(path.read_text().split("---", 2)[1])
    assert set(metadata["tools"]) <= roles[path.stem.lower()]
PY
}

@test "nimbus orchestrator tools remain within the union of manifest allowlists" {
  python3 - "$REPO_ROOT" <<'PY'
import sys
from pathlib import Path
import yaml

root = Path(sys.argv[1])
manifest = yaml.safe_load((root / ".nimbus/agent-manifest.yaml").read_text())
union: set[str] = set()
for role in manifest["manifest"]["roles"]:
    union |= set(role["tool_allowlist"])
path = root / ".github/agents/nimbus.agent.md"
metadata = yaml.safe_load(path.read_text().split("---", 2)[1])
assert set(metadata["tools"]) <= union
missing = list((root / ".github/agents").glob("nc-*.agent.md"))
assert not missing, f"stray per-role vscode agent files: {missing}"
PY
}

@test "approval policies remain in source governance manifest" {
  [ "$(grep -c "human_approval_policy:" "$REPO_ROOT/.nimbus/agent-manifest.yaml")" -ge 15 ]
}
