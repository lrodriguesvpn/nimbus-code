#!/usr/bin/env bats
# ==============================================================================
# Suite: tests/multi-agent-integration/bootstrap-nc-agent-sync-coverage.bats
# Purpose: Regression guard — every per-satellite target the NC agent
#          generator (scripts/lib/nc-agent-sync.py TARGETS) supports MUST be
#          wired into bootstrap.sh's `case "$INTEGRATION"` sync dispatch.
#
# Context: spec 028 added "cursor" and "kiro" as new generator targets but
# did not extend bootstrap.sh's dispatch case, so satellite repos bootstrapped
# with --integration cursor-agent/kiro-cli silently never received NC agent
# sync (nc-*, and the proprietary speckit-* commands) on apply or refresh.
# This test fails loudly if that class of gap recurs for a future 6th target.
# ==============================================================================

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
}

@test "bootstrap.sh dispatches sync-nc-agents-to-integrations.sh for every non-vscode generator target" {
  local targets
  targets=$(python3 -c "
import re
content = open('$REPO_ROOT/scripts/lib/nc-agent-sync.py').read()
m = re.search(r'TARGETS = \(([^)]*)\)', content)
targets = [t.strip().strip('\"') for t in m.group(1).split(',') if t.strip()]
print('\n'.join(t for t in targets if t != 'vscode'))
")
  local missing=""
  while IFS= read -r target; do
    [ -z "$target" ] && continue
    if ! grep -q -- "--target ${target}\\b" "$REPO_ROOT/bootstrap.sh"; then
      missing="${missing}\n  - ${target}"
    fi
  done <<< "$targets"
  if [ -n "$missing" ]; then
    echo -e "bootstrap.sh does not dispatch sync-nc-agents-to-integrations.sh for these generator targets (satellite repos using them would silently skip NC agent sync):${missing}"
    return 1
  fi
}

@test "bootstrap.sh accepts the real specify CLI integration keys for cursor and kiro" {
  # specify integration list reports the installable keys as cursor-agent/kiro-cli,
  # not the short "cursor"/"kiro" aliases used internally by the sync scripts.
  grep -q "cursor-agent|cursor)" "$REPO_ROOT/bootstrap.sh"
  grep -q "kiro-cli|kiro)" "$REPO_ROOT/bootstrap.sh"
}
