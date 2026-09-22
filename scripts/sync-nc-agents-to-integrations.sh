#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Script: scripts/sync-nc-agents-to-integrations.sh
# Purpose: Synchronize NC-* skills and native agent projections from the
#          repository's single source of truth.
# Spec: specs/025-native-nc-agents/
# ==============================================================================

# EXPECTED_AGENTS and EXTRA_SPECKIT_SKILLS are discovered dynamically from
# .github/skills/ (the single source of truth) instead of hardcoded lists.
# A hardcoded list silently drifted from the real source directory in the
# past (see harness-catalog.yaml HRN-0006: nc-bug-assess/nc-bug-fix/nc-bug-test
# existed as source skills but were absent from this list, so tests "passed"
# while those agents were never synced to Claude/Antigravity). Spec 028
# fixes this by discovering agents/commands via glob, applied uniformly to
# every target this script supports.
SOURCE_DIR=".github/skills"

discover_expected_agents() {
  find "${SOURCE_DIR}" -maxdepth 1 -type d -name 'nc-*' -exec test -f '{}/SKILL.md' \; -print \
    | xargs -n1 basename \
    | sort
}

# Official /speckit-* commands installed natively by `specify integration
# install <target>` (upstream spec-kit). Any other `speckit-*` directory in
# ${SOURCE_DIR} is a Nimbus Code proprietary extension and must be synced by
# this script explicitly (EXTRA_SPECKIT_SKILLS).
OFFICIAL_SPECKIT_COMMANDS=(
  "speckit-constitution"
  "speckit-specify"
  "speckit-clarify"
  "speckit-plan"
  "speckit-tasks"
  "speckit-implement"
  "speckit-converge"
  "speckit-analyze"
  "speckit-checklist"
  "speckit-taskstoissues"
)

discover_extra_speckit_skills() {
  local all_speckit official is_official skill
  all_speckit="$(find "${SOURCE_DIR}" -maxdepth 1 -type d -name 'speckit-*' -exec test -f '{}/SKILL.md' \; -print | xargs -n1 basename | sort)"
  while IFS= read -r skill; do
    [[ -z "$skill" ]] && continue
    is_official=0
    for official in "${OFFICIAL_SPECKIT_COMMANDS[@]}"; do
      if [[ "$skill" == "$official" ]]; then
        is_official=1
        break
      fi
    done
    if [[ "$is_official" -eq 0 ]]; then
      echo "$skill"
    fi
  done <<< "$all_speckit"
}

mapfile -t EXPECTED_AGENTS < <(discover_expected_agents)
mapfile -t EXTRA_SPECKIT_SKILLS < <(discover_extra_speckit_skills)

if [[ "${#EXPECTED_AGENTS[@]}" -eq 0 ]]; then
  echo "Error: no nc-* agent skills discovered in ${SOURCE_DIR}" >&2
  exit 1
fi

CLAUDE_DIR=".claude/skills"
AGY_DIR=".agents/skills"
CURSOR_SKILLS_DIR=".cursor/skills"
KIRO_PROMPTS_DIR=".kiro/prompts"

print_help() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Synchronizes the ${#EXPECTED_AGENTS[@]} NC-* agents from ${SOURCE_DIR}/ to other integrations.

Options:
  --target <vscode|claude|antigravity|agy|cursor|kiro|all> Target integration (default: all)
  --check                                 Validate generated outputs without writing
  --help                                  Show this help message and exit
EOF
}

TARGET="all"
MODE="generate"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      if [[ $# -lt 2 ]]; then
        echo "Error: --target requires an argument (claude, antigravity, agy, or all)" >&2
        exit 1
      fi
      TARGET="$2"
      shift 2
      ;;
    --help|-h)
      print_help
      exit 0
      ;;
    --check)
      MODE="check"
      shift
      ;;
    *)
      echo "Error: Unknown option '$1'" >&2
      print_help >&2
      exit 1
      ;;
  esac
done

if [[ "$TARGET" == "agy" ]]; then
  TARGET="antigravity"
fi

if [[ "$TARGET" != "vscode" && "$TARGET" != "claude" && "$TARGET" != "antigravity" && "$TARGET" != "cursor" && "$TARGET" != "kiro" && "$TARGET" != "all" ]]; then
  echo "Error: Invalid target '$TARGET'. Must be one of: vscode, claude, antigravity, agy, cursor, kiro, all" >&2
  exit 1
fi

# T004: Validate source of truth (must be strictly read-only and all 9 must exist)
validate_source() {
  for agent in "${EXPECTED_AGENTS[@]}"; do
    local source_file="${SOURCE_DIR}/${agent}/SKILL.md"
    if [[ ! -f "$source_file" ]]; then
      echo "Error: Source agent not found: $source_file" >&2
      exit 1
    fi
  done
}

# T006 / Helper: Calculate functional body hash
compute_functional_hash() {
  local file_path="$1"
  if [[ ! -f "$file_path" ]]; then
    echo "missing"
    return 0
  fi
  # Normalize by extracting content after frontmatter or stripping integration notes/hints
  python3 -c "
import sys, hashlib, re

content = open(sys.argv[1], 'r', encoding='utf-8').read()
# Extract body after frontmatter
parts = content.split('---', 2)
if len(parts) >= 3:
    body = parts[2]
else:
    body = content

# Normalize hook notes and argument hints
body = re.sub(r'When constructing command invocations from hook command names, replace dots.*?\n', '', body)
body = body.strip()

h = hashlib.sha256(body.encode('utf-8')).hexdigest()
print(h)
" "$file_path"
}

# T011: Post-processing for Claude Code
# Injects argument-hint and user-invocable / disable-model-invocation if missing
process_for_claude() {
  local agent_name="$1"
  local src_file="$2"
  local dest_file="$3"

  mkdir -p "$(dirname "$dest_file")"

  python3 -c "
import sys, re

agent = sys.argv[1]
src = sys.argv[2]
dest = sys.argv[3]

content = open(src, 'r', encoding='utf-8').read()

# Default argument hint per NC agent / custom speckit command if not specified
hints = {
    'nc-assess-intake': '[raw idea, text, URL, ticket, or codebase pointer]',
    'nc-assess-research': '[assessment slug or topic to research]',
    'nc-assess-define': '[assessment slug or problem statement]',
    'nc-assess-shape': '[assessment slug or concept description]',
    'nc-assess-decide': '[assessment slug to evaluate]',
    'nc-intake': '[feature description or transcript path]',
    'nc-spec': '[feature description or interview path]',
    'nc-critic': '[spec path or feature slug]',
    'nc-governor': '[spec path or feature slug]',
    'nc-arch': '[spec path or feature slug]',
    'nc-qa': '[plan path or feature slug]',
    'nc-builder': '[tasks path or feature slug]',
    'nc-shield': '[plan path or feature slug]',
    'nc-telemetry': '[phase or feature slug]',
    'nc-designer': '[screen/component description, or audit|critique|polish|harden <target>]',
    'speckit-assess-intake': '[raw idea, text, URL, ticket, or codebase pointer]',
    'speckit-assess-research': '[assessment slug or topic to research]',
    'speckit-assess-define': '[assessment slug or problem statement]',
    'speckit-assess-shape': '[assessment slug or concept description]',
    'speckit-assess-decide': '[assessment slug to evaluate]',
    'speckit-interview': 'Feature description, live interview, or transcript path',
    'speckit-nimbus-code-backlog-sync-sync': 'Optional feature slug or backlog item reference'
}
hint = hints.get(agent, '')

lines = content.splitlines(keepends=True)
out = []
in_fm = False
dash_count = 0
injected_hint = False

in_desc = False

i = 0
n = len(lines)
while i < n:
    line = lines[i]
    stripped = line.rstrip('\r\n')
    if stripped == '---':
        dash_count += 1
        in_fm = (dash_count == 1)
        out.append(line)
        i += 1
        continue

    if in_fm and not injected_hint and stripped.startswith('description:'):
        out.append(line)
        i += 1
        # Consume continuation lines of a folded/block-scalar description
        # (lines indented relative to the top-level key) before injecting.
        while i < n and lines[i].strip() != '' and (lines[i][:1] in (' ', '\t')):
            out.append(lines[i])
            i += 1
        eol = '\n' if line.endswith('\n') else ''
        if hint and 'argument-hint:' not in content:
            out.append(f'argument-hint: \"{hint}\"{eol}')
            injected_hint = True
        continue

    out.append(line)
    i += 1

final_text = ''.join(out)
open(dest, 'w', encoding='utf-8').write(final_text)
" "$agent_name" "$src_file" "$dest_file"
}

# T019: Post-processing for Antigravity
# Injects the hook dot-to-hyphen conversion note if executable hook line is present
process_for_antigravity() {
  local agent_name="$1"
  local src_file="$2"
  local dest_file="$3"

  mkdir -p "$(dirname "$dest_file")"

  python3 -c "
import sys, re

agent = sys.argv[1]
src = sys.argv[2]
dest = sys.argv[3]

content = open(src, 'r', encoding='utf-8').read()

HOOK_NOTE = '- When constructing command invocations from hook command names, replace dots (\`.\`) with hyphens (\`-\`). For example, \`speckit.git.commit\` → \`/speckit-git-commit\`.\n'

if 'replace dots' not in content:
    # If the file mentions executable hooks instruction, inject the note before it
    pattern = r'(?m)^(\s*)(- For each executable hook, output the following[^\r\n]*)(\r\n|\n|$)'
    def repl(m):
        indent = m.group(1)
        instruction = m.group(2)
        eol = m.group(3) or '\n'
        return indent + HOOK_NOTE.rstrip('\n') + eol + indent + instruction + eol

    content = re.sub(pattern, repl, content)

open(dest, 'w', encoding='utf-8').write(content)
" "$agent_name" "$src_file" "$dest_file"
}

# T029/T016 (spec 028): Post-processing for Cursor custom speckit-* commands.
# Cursor Skills already share the same frontmatter convention as the source
# (name/description/compatibility/metadata) — plain copy, no rewrite needed.
process_for_cursor_skill() {
  local skill_name="$1"
  local src_file="$2"
  local dest_file="$3"
  mkdir -p "$(dirname "$dest_file")"
  cp "$src_file" "$dest_file"
}

# T028 (spec 028): Post-processing for Kiro custom speckit-* commands.
# Kiro's generic /speckit-* commands live in .kiro/prompts/ as flat,
# dot-separated files (e.g. speckit.constitution.md), confirmed via isolated
# `specify init --integration kiro-cli` probe (spec 028 clarify session).
# Only the first hyphen (right after "speckit") is converted to a dot,
# mirroring exactly what the `specify` CLI does for its own official
# commands — the rest of the proprietary command name keeps its hyphens.
process_for_kiro_prompt() {
  local skill_name="$1"
  local src_file="$2"
  local dest_dir="$3"
  mkdir -p "$dest_dir"
  local kiro_name="${skill_name/-/.}"
  cp "$src_file" "${dest_dir}/${kiro_name}.md"
}

# Custom /speckit-* commands must also exist in the source of truth.
validate_extra_speckit_source() {
  for skill in "${EXTRA_SPECKIT_SKILLS[@]}"; do
    local source_file="${SOURCE_DIR}/${skill}/SKILL.md"
    if [[ ! -f "$source_file" ]]; then
      echo "Error: Custom speckit skill not found: $source_file" >&2
      exit 1
    fi
  done
}

validate_source
validate_extra_speckit_source

if [[ "$MODE" == "generate" && ( "$TARGET" == "claude" || "$TARGET" == "all" ) ]]; then
  echo "==> Sincronizando agentes para Claude Code (${CLAUDE_DIR}/)..."
  for agent in "${EXPECTED_AGENTS[@]}"; do
    src="${SOURCE_DIR}/${agent}/SKILL.md"
    dest="${CLAUDE_DIR}/${agent}/SKILL.md"
    process_for_claude "$agent" "$src" "$dest"
  done
  echo "✅ ${#EXPECTED_AGENTS[@]} agentes sincronizados para Claude Code."

  echo "==> Sincronizando comandos /speckit-* customizados para Claude Code (${CLAUDE_DIR}/)..."
  for skill in "${EXTRA_SPECKIT_SKILLS[@]}"; do
    src="${SOURCE_DIR}/${skill}/SKILL.md"
    dest="${CLAUDE_DIR}/${skill}/SKILL.md"
    process_for_claude "$skill" "$src" "$dest"
  done
  echo "✅ ${#EXTRA_SPECKIT_SKILLS[@]} comandos speckit customizados sincronizados para Claude Code."
fi

if [[ "$MODE" == "generate" && ( "$TARGET" == "antigravity" || "$TARGET" == "all" ) ]]; then
  echo "==> Sincronizando agentes para Antigravity (${AGY_DIR}/)..."
  for agent in "${EXPECTED_AGENTS[@]}"; do
    src="${SOURCE_DIR}/${agent}/SKILL.md"
    dest="${AGY_DIR}/${agent}/SKILL.md"
    process_for_antigravity "$agent" "$src" "$dest"
  done
  echo "✅ ${#EXPECTED_AGENTS[@]} agentes sincronizados para Antigravity."

  echo "==> Sincronizando comandos /speckit-* customizados para Antigravity (${AGY_DIR}/)..."
  for skill in "${EXTRA_SPECKIT_SKILLS[@]}"; do
    src="${SOURCE_DIR}/${skill}/SKILL.md"
    dest="${AGY_DIR}/${skill}/SKILL.md"
    process_for_antigravity "$skill" "$src" "$dest"
  done
  echo "✅ ${#EXTRA_SPECKIT_SKILLS[@]} comandos speckit customizados sincronizados para Antigravity."
fi

if [[ "$MODE" == "generate" && ( "$TARGET" == "cursor" || "$TARGET" == "all" ) ]]; then
  echo "==> Sincronizando comandos /speckit-* customizados para Cursor (${CURSOR_SKILLS_DIR}/)..."
  for skill in "${EXTRA_SPECKIT_SKILLS[@]}"; do
    src="${SOURCE_DIR}/${skill}/SKILL.md"
    dest="${CURSOR_SKILLS_DIR}/${skill}/SKILL.md"
    process_for_cursor_skill "$skill" "$src" "$dest"
  done
  echo "✅ ${#EXTRA_SPECKIT_SKILLS[@]} comandos speckit customizados sincronizados para Cursor."
fi

if [[ "$MODE" == "generate" && ( "$TARGET" == "kiro" || "$TARGET" == "all" ) ]]; then
  echo "==> Sincronizando comandos /speckit-* customizados para Kiro (${KIRO_PROMPTS_DIR}/)..."
  for skill in "${EXTRA_SPECKIT_SKILLS[@]}"; do
    src="${SOURCE_DIR}/${skill}/SKILL.md"
    process_for_kiro_prompt "$skill" "$src" "$KIRO_PROMPTS_DIR"
  done
  echo "✅ ${#EXTRA_SPECKIT_SKILLS[@]} comandos speckit customizados sincronizados para Kiro."
fi

NATIVE_TARGET_ARGS=()
case "$TARGET" in
  vscode) NATIVE_TARGET_ARGS=(--target vscode) ;;
  claude) NATIVE_TARGET_ARGS=(--target claude) ;;
  antigravity) NATIVE_TARGET_ARGS=(--target antigravity) ;;
  cursor) NATIVE_TARGET_ARGS=(--target cursor) ;;
  kiro) NATIVE_TARGET_ARGS=(--target kiro) ;;
  all) NATIVE_TARGET_ARGS=(--target vscode --target claude --target antigravity --target cursor --target kiro) ;;
esac

if [[ "$MODE" == "generate" ]]; then
  python3 scripts/lib/nc-agent-sync.py --repo-root . generate "${NATIVE_TARGET_ARGS[@]}"
else
  python3 scripts/lib/nc-agent-sync.py --repo-root . check "${NATIVE_TARGET_ARGS[@]}"
fi
