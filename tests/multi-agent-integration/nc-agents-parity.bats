#!/usr/bin/env bats
# ==============================================================================
# Suite: tests/multi-agent-integration/nc-agents-parity.bats
# Spec: specs/024-multi-agent-integration-claude-antigravity/
# Acceptance Criteria: AC1, AC2, AC3, AC4, AC5, AC6
# ==============================================================================

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  cd "$REPO_ROOT"

  EXPECTED_AGENTS=(
    "nc-intake"
    "nc-spec"
    "nc-critic"
    "nc-governor"
    "nc-arch"
    "nc-qa"
    "nc-builder"
    "nc-shield"
    "nc-telemetry"
  )

  SPECKIT_COMMANDS=(
    "speckit-analyze"
    "speckit-checklist"
    "speckit-clarify"
    "speckit-constitution"
    "speckit-converge"
    "speckit-implement"
    "speckit-plan"
    "speckit-specify"
    "speckit-tasks"
    "speckit-taskstoissues"
  )
}

# Helper function to compute functional body hash
compute_hash() {
  local file="$1"
  python3 -c "
import sys, hashlib, re

content = open(sys.argv[1], 'r', encoding='utf-8').read()
parts = content.split('---', 2)
body = parts[2] if len(parts) >= 3 else content
# Remove integration notes and hints
body = re.sub(r'When constructing command invocations from hook command names, replace dots.*?\n', '', body)
body = body.strip()
print(hashlib.sha256(body.encode('utf-8')).hexdigest())
" "$file"
}

# ------------------------------------------------------------------------------
# AC1: Comandos /speckit-* instalados para Claude Code sem afetar Copilot
# ------------------------------------------------------------------------------
@test "test_AC1_claude_speckit_commands_installed" {
  for cmd in "${SPECKIT_COMMANDS[@]}"; do
    [ -f ".claude/skills/${cmd}/SKILL.md" ]
  done
}

# ------------------------------------------------------------------------------
# AC2: 9 agentes NC-* sincronizados para Claude Code com argument-hint e paridade
# ------------------------------------------------------------------------------
@test "test_AC2_nc_agents_synced_to_claude" {
  for agent in "${EXPECTED_AGENTS[@]}"; do
    local src=".github/skills/${agent}/SKILL.md"
    local dest=".claude/skills/${agent}/SKILL.md"

    [ -f "$dest" ]

    # Verify frontmatter has argument-hint
    grep -q "argument-hint:" "$dest"

    # Verify functional parity hash
    local src_hash
    local dest_hash
    src_hash=$(compute_hash "$src")
    dest_hash=$(compute_hash "$dest")

    [ "$src_hash" = "$dest_hash" ]
  done
}

# ------------------------------------------------------------------------------
# AC3: Comandos /speckit-* instalados para Antigravity
# ------------------------------------------------------------------------------
@test "test_AC3_agy_isolated_install_validated" {
  for cmd in "${SPECKIT_COMMANDS[@]}"; do
    [ -f ".agents/skills/${cmd}/SKILL.md" ]
  done
}

# ------------------------------------------------------------------------------
# AC4: 9 agentes NC-* sincronizados para Antigravity
# ------------------------------------------------------------------------------
@test "test_AC4_nc_agents_synced_to_agy" {
  for agent in "${EXPECTED_AGENTS[@]}"; do
    local src=".github/skills/${agent}/SKILL.md"
    local dest=".agents/skills/${agent}/SKILL.md"

    [ -f "$dest" ]

    # Verify functional parity hash
    local src_hash
    local dest_hash
    src_hash=$(compute_hash "$src")
    dest_hash=$(compute_hash "$dest")

    [ "$src_hash" = "$dest_hash" ]
  done
}

# ------------------------------------------------------------------------------
# AC5: Gate de paridade detecta e relata qualquer divergência (drift)
# ------------------------------------------------------------------------------
@test "test_AC5_nc_agents_parity_gate" {
  local drift_detected=0
  local drift_report=""

  for agent in "${EXPECTED_AGENTS[@]}"; do
    local github_file=".github/skills/${agent}/SKILL.md"
    local claude_file=".claude/skills/${agent}/SKILL.md"
    local agy_file=".agents/skills/${agent}/SKILL.md"

    [ -f "$github_file" ]
    [ -f "$claude_file" ]
    [ -f "$agy_file" ]

    local h_gh h_cl h_ag
    h_gh=$(compute_hash "$github_file")
    h_cl=$(compute_hash "$claude_file")
    h_ag=$(compute_hash "$agy_file")

    if [ "$h_gh" != "$h_cl" ]; then
      drift_detected=1
      drift_report="${drift_report}\nDrift detected in Claude integration for ${agent}: github=${h_gh} vs claude=${h_cl}"
    fi

    if [ "$h_gh" != "$h_ag" ]; then
      drift_detected=1
      drift_report="${drift_report}\nDrift detected in Antigravity integration for ${agent}: github=${h_gh} vs agy=${h_ag}"
    fi
  done

  if [ "$drift_detected" -ne 0 ]; then
    echo -e "$drift_report"
    return 1
  fi
}

# ------------------------------------------------------------------------------
# AC6: Developer Guide documenta os agentes e comandos para as 3 integrações
# ------------------------------------------------------------------------------
@test "test_AC6_developer_guide_documents_integrations" {
  [ -f "docs/developer-guide.md" ]
  grep -qi "Claude Code" "docs/developer-guide.md"
  grep -qi "Antigravity" "docs/developer-guide.md"
  grep -qi "multi_install_safe" "docs/developer-guide.md"
}
