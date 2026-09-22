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
    "nc-assess-intake"
    "nc-assess-research"
    "nc-assess-define"
    "nc-assess-shape"
    "nc-assess-decide"
    "nc-intake"
    "nc-spec"
    "nc-critic"
    "nc-governor"
    "nc-arch"
    "nc-qa"
    "nc-builder"
    "nc-shield"
    "nc-telemetry"
    "nc-designer"
  )

  SPECKIT_COMMANDS=(
    "speckit-analyze"
    "speckit-assess-decide"
    "speckit-assess-define"
    "speckit-assess-intake"
    "speckit-assess-research"
    "speckit-assess-shape"
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

  # Custom Nimbus-Code speckit-* commands NOT managed by the upstream `specify`
  # CLI (unlike SPECKIT_COMMANDS above). They must be explicitly synced by
  # scripts/sync-nc-agents-to-integrations.sh (see EXTRA_SPECKIT_SKILLS, HRN-0006).
  CUSTOM_SPECKIT_COMMANDS=(
    "speckit-assess-intake"
    "speckit-assess-research"
    "speckit-assess-define"
    "speckit-assess-shape"
    "speckit-assess-decide"
    "speckit-interview"
    "speckit-nimbus-code-backlog-sync-sync"
  )
}

# Helper function to compute functional body hash
compute_hash() {
  local file="$1"
  python3 -c "
import sys, hashlib, re

content = open(sys.argv[1], 'r', encoding='utf-8').read()
parts = content.split('---', 2) if content.startswith('---') else [content]
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

# ------------------------------------------------------------------------------
# AC7 (HRN-0006 regression): comandos /speckit-* customizados (não geridos pelo
# `specify` CLI) sincronizados com paridade funcional para Claude e Antigravity.
# ------------------------------------------------------------------------------
@test "test_AC7_custom_speckit_commands_synced_to_claude_and_agy" {
  for cmd in "${CUSTOM_SPECKIT_COMMANDS[@]}"; do
    local github_file=".github/skills/${cmd}/SKILL.md"
    local claude_file=".claude/skills/${cmd}/SKILL.md"
    local agy_file=".agents/skills/${cmd}/SKILL.md"

    [ -f "$github_file" ]
    [ -f "$claude_file" ]
    [ -f "$agy_file" ]

    # Claude copy must carry an argument-hint (same contract as nc-* agents)
    grep -q "argument-hint:" "$claude_file"

    local h_gh h_cl h_ag
    h_gh=$(compute_hash "$github_file")
    h_cl=$(compute_hash "$claude_file")
    h_ag=$(compute_hash "$agy_file")

    [ "$h_gh" = "$h_cl" ]
    [ "$h_gh" = "$h_ag" ]
  done
}

# ==============================================================================
# Spec 028: Suporte a Cursor e Kiro como Integrações Agênticas
# Acceptance Criteria: AC1, AC2, AC3, AC4, AC5, AC6
# ==============================================================================

# ------------------------------------------------------------------------------
# 028 AC1: Comandos /speckit-* instalados para Cursor sem afetar outras integrações
# ------------------------------------------------------------------------------
@test "test_AC1_cursor_speckit_commands_installed" {
  for cmd in "${SPECKIT_COMMANDS[@]}"; do
    [ -f ".cursor/skills/${cmd}/SKILL.md" ]
  done
}

# ------------------------------------------------------------------------------
# 028 AC2: agentes NC-* sincronizados para Cursor (.cursor/skills/nc-<agente>/SKILL.md)
# com o frontmatter esperado (name/description/compatibility/metadata, sem "tools")
# ------------------------------------------------------------------------------
@test "test_AC2_nc_agents_synced_to_cursor" {
  local discovered_agents
  discovered_agents=$(find ".github/skills" -maxdepth 1 -type d -name 'nc-*' -exec test -f '{}/SKILL.md' \; -print | xargs -n1 basename | sort)
  while IFS= read -r agent; do
    [ -z "$agent" ] && continue
    local src=".github/skills/${agent}/SKILL.md"
    local dest=".cursor/skills/${agent}/SKILL.md"

    [ -f "$dest" ]
    grep -q "^compatibility:" "$dest"
    grep -q "^metadata:" "$dest"
    ! grep -q "^tools:" "$dest"

    local src_hash dest_hash
    src_hash=$(compute_hash "$src")
    dest_hash=$(compute_hash "$dest")
    [ "$src_hash" = "$dest_hash" ]
  done <<< "$discovered_agents"
}

# ------------------------------------------------------------------------------
# 028 AC3: Comandos /speckit-* instalados para Kiro (.kiro/prompts/, dot-separado)
# ------------------------------------------------------------------------------
@test "test_AC3_kiro_speckit_commands_installed" {
  for cmd in "${SPECKIT_COMMANDS[@]}"; do
    local kiro_name="${cmd/-/.}"
    [ -f ".kiro/prompts/${kiro_name}.md" ]
  done
}

# ------------------------------------------------------------------------------
# 028 AC4: agentes NC-* sincronizados para Kiro via mecanismo nativo Custom
# agents (.kiro/agents/nc-<agente>.md), NÃO em .kiro/prompts/
# ------------------------------------------------------------------------------
@test "test_AC4_nc_agents_synced_to_kiro" {
  local discovered_agents
  discovered_agents=$(find ".github/skills" -maxdepth 1 -type d -name 'nc-*' -exec test -f '{}/SKILL.md' \; -print | xargs -n1 basename | sort)
  while IFS= read -r agent; do
    [ -z "$agent" ] && continue
    local src=".github/skills/${agent}/SKILL.md"
    local dest=".kiro/agents/${agent}.md"

    [ -f "$dest" ]
    [ ! -f ".kiro/prompts/${agent}.md" ]
    grep -q "^tools:" "$dest"

    local src_hash dest_hash
    src_hash=$(compute_hash "$src")
    dest_hash=$(compute_hash "$dest")
    [ "$src_hash" = "$dest_hash" ]
  done <<< "$discovered_agents"
}

# ------------------------------------------------------------------------------
# 028 AC5: Gate de paridade cobre os 5 alvos (vscode, claude, antigravity,
# cursor, kiro) usando a descoberta real de agentes (glob), não uma contagem fixa
# ------------------------------------------------------------------------------
@test "test_AC5_nc_agents_parity_gate_five_targets" {
  run python3 scripts/lib/nc-agent-sync.py check --target all
  [ "$status" -eq 0 ]
  [[ "$output" == *"vscode"* ]]
  [[ "$output" == *"claude"* ]]
  [[ "$output" == *"antigravity"* ]]
  [[ "$output" == *"cursor"* ]]
  [[ "$output" == *"kiro"* ]]
}

# ------------------------------------------------------------------------------
# 028 AC6: VS Code continua expondo só o @nimbus após a extensão para 5 alvos
# (regressão da spec 025) — .github/agents/ nunca ganha arquivos nc-*.agent.md
# ------------------------------------------------------------------------------
@test "test_AC6_vscode_single_orchestrator_regression" {
  run python3 scripts/lib/nc-agent-sync.py check --target vscode
  [ "$status" -eq 0 ]
  count="$(find ".github/agents" -maxdepth 1 -name 'nc-*.agent.md' | wc -l | tr -d ' ')"
  [ "$count" -eq 0 ]
  [ -f ".github/agents/nimbus.agent.md" ]
}

