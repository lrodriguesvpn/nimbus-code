#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
}

@test "generated native tools remain within manifest allowlists" {
  python3 - "$REPO_ROOT" <<'PY'
import sys
from pathlib import Path
import yaml

root = Path(sys.argv[1])
manifest = yaml.safe_load((root / ".nimbus/agent-manifest.yaml").read_text())
roles = {role["id"].lower(): set(role["tool_allowlist"]) for role in manifest["manifest"]["roles"]}
for path in (root / ".github/agents").glob("nc-*.agent.md"):
    metadata = yaml.safe_load(path.read_text().split("---", 2)[1])
    assert set(metadata["tools"]) <= roles[path.stem.removesuffix(".agent").lower()]
PY
}

@test "approval policies remain in source governance manifest" {
  [ "$(grep -c "human_approval_policy:" "$REPO_ROOT/.nimbus/agent-manifest.yaml")" -ge 15 ]
}
