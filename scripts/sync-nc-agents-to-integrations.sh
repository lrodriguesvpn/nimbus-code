#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Script: scripts/sync-nc-agents-to-integrations.sh
# Purpose: Synchronize NC-* agent skills from .github/skills/ (single source of
#          truth) to .claude/skills/ and .agents/skills/ with integration-specific
#          post-processing (Claude argument-hint/flags; Antigravity hook note).
# Spec: specs/024-multi-agent-integration-claude-antigravity/
# Contract: specs/024-multi-agent-integration-claude-antigravity/contracts/nc-agent-sync.contract.md
# ==============================================================================

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

# Custom Nimbus Code /speckit-* commands that are NOT part of the upstream
# spec-kit template and therefore are NOT installed by `specify integration
# install claude|agy`. These must be synced by this script too, or they will
# silently be missing from .claude/skills/ and .agents/skills/ (see
# harness-catalog.yaml HRN-0006).
EXTRA_SPECKIT_SKILLS=(
  "speckit-interview"
  "speckit-nimbus-code-backlog-sync-sync"
)

SOURCE_DIR=".github/skills"
CLAUDE_DIR=".claude/skills"
AGY_DIR=".agents/skills"

print_help() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Synchronizes the 9 NC-* agents from ${SOURCE_DIR}/ to other integrations.

Options:
  --target <claude|antigravity|agy|all>   Target integration (default: all)
  --help                                  Show this help message and exit
EOF
}

TARGET="all"

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

if [[ "$TARGET" != "claude" && "$TARGET" != "antigravity" && "$TARGET" != "all" ]]; then
  echo "Error: Invalid target '$TARGET'. Must be one of: claude, antigravity, agy, all" >&2
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
    'nc-intake': '[feature description or transcript path]',
    'nc-spec': '[feature description or interview path]',
    'nc-critic': '[spec path or feature slug]',
    'nc-governor': '[spec path or feature slug]',
    'nc-arch': '[spec path or feature slug]',
    'nc-qa': '[plan path or feature slug]',
    'nc-builder': '[tasks path or feature slug]',
    'nc-shield': '[plan path or feature slug]',
    'nc-telemetry': '[phase or feature slug]',
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

if [[ "$TARGET" == "claude" || "$TARGET" == "all" ]]; then
  echo "==> Sincronizando agentes para Claude Code (${CLAUDE_DIR}/)..."
  for agent in "${EXPECTED_AGENTS[@]}"; do
    src="${SOURCE_DIR}/${agent}/SKILL.md"
    dest="${CLAUDE_DIR}/${agent}/SKILL.md"
    process_for_claude "$agent" "$src" "$dest"
  done
  echo "✅ 9 agentes sincronizados para Claude Code."

  echo "==> Sincronizando comandos /speckit-* customizados para Claude Code (${CLAUDE_DIR}/)..."
  for skill in "${EXTRA_SPECKIT_SKILLS[@]}"; do
    src="${SOURCE_DIR}/${skill}/SKILL.md"
    dest="${CLAUDE_DIR}/${skill}/SKILL.md"
    process_for_claude "$skill" "$src" "$dest"
  done
  echo "✅ ${#EXTRA_SPECKIT_SKILLS[@]} comandos speckit customizados sincronizados para Claude Code."
fi

if [[ "$TARGET" == "antigravity" || "$TARGET" == "all" ]]; then
  echo "==> Sincronizando agentes para Antigravity (${AGY_DIR}/)..."
  for agent in "${EXPECTED_AGENTS[@]}"; do
    src="${SOURCE_DIR}/${agent}/SKILL.md"
    dest="${AGY_DIR}/${agent}/SKILL.md"
    process_for_antigravity "$agent" "$src" "$dest"
  done
  echo "✅ 9 agentes sincronizados para Antigravity."

  echo "==> Sincronizando comandos /speckit-* customizados para Antigravity (${AGY_DIR}/)..."
  for skill in "${EXTRA_SPECKIT_SKILLS[@]}"; do
    src="${SOURCE_DIR}/${skill}/SKILL.md"
    dest="${AGY_DIR}/${skill}/SKILL.md"
    process_for_antigravity "$skill" "$src" "$dest"
  done
  echo "✅ ${#EXTRA_SPECKIT_SKILLS[@]} comandos speckit customizados sincronizados para Antigravity."
fi
