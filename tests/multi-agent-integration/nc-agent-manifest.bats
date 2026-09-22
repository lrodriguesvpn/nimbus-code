#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
}

@test "generated claude native tools remain within manifest allowlists (translated to Claude names)" {
  python3 - "$REPO_ROOT" <<'PY'
import importlib.util
import sys
from pathlib import Path
import yaml

root = Path(sys.argv[1])
spec = importlib.util.spec_from_file_location("nc_agent_sync", root / "scripts/lib/nc-agent-sync.py")
helper = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helper)
manifest = yaml.safe_load((root / ".nimbus/agent-manifest.yaml").read_text())
roles = {role["id"].lower(): role["tool_allowlist"] for role in manifest["manifest"]["roles"]}
for path in (root / ".claude/agents").glob("nc-*.md"):
    metadata = yaml.safe_load(path.read_text().split("---", 2)[1])
    assert set(metadata["tools"]) <= set(helper.claude_tools(roles[path.stem.lower()])), path
PY
}

@test "claude native agents only declare tool names Claude Code recognizes" {
  # Regression guard (spec 025 reopen): Claude Code refuses to spawn a
  # subagent whose tools resolve to nothing, so Copilot names such as
  # view/rg/apply_patch/skill:* must never reach .claude/agents/.
  python3 - "$REPO_ROOT" <<'PY'
import sys
from pathlib import Path
import yaml

valid = {"Read", "Grep", "Glob", "Bash", "Edit", "Write", "WebFetch", "WebSearch", "Skill", "NotebookEdit"}
root = Path(sys.argv[1])
agents = sorted((root / ".claude/agents").glob("nc-*.md"))
assert agents, "no claude agents found"
for path in agents:
    metadata = yaml.safe_load(path.read_text().split("---", 2)[1])
    tools = set(metadata["tools"])
    assert tools, f"{path.name}: empty tools list"
    unknown = tools - valid
    assert not unknown, f"{path.name}: unknown Claude tools {sorted(unknown)}"
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
