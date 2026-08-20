#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/validate-issue-template-parity.sh [--template-a PATH --template-b PATH [--label-a NAME --label-b NAME]]

Without arguments, validates:
  1. presets/nimbus-code-standards <-> presets/nimbus-code-platform-standards
  2. presets <-> .specify/presets active copies for both presets
EOF
}

template_a=""
template_b=""
label_a="template-a"
label_b="template-b"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --template-a)
      template_a="${2:-}"
      shift 2
      ;;
    --template-b)
      template_b="${2:-}"
      shift 2
      ;;
    --label-a)
      label_a="${2:-}"
      shift 2
      ;;
    --label-b)
      label_b="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

extract_headings() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "ERROR: missing file: $path" >&2
    return 1
  fi

  grep -E '^## ' "$path" | sed -E 's/^##[[:space:]]+//'
}

compare_templates() {
  local reference_path="$1"
  local candidate_path="$2"
  local reference_label="$3"
  local candidate_label="$4"
  local reference_headings candidate_headings

  reference_headings="$(extract_headings "$reference_path")"
  candidate_headings="$(extract_headings "$candidate_path")"

  if [[ "$reference_headings" != "$candidate_headings" ]]; then
    echo "ERROR: divergence between $reference_label and $candidate_label:" >&2
    diff -u       <(printf '%s
' "$reference_headings")       <(printf '%s
' "$candidate_headings") >&2 || true
    return 1
  fi
}

if [[ -n "$template_a" || -n "$template_b" ]]; then
  if [[ -z "$template_a" || -z "$template_b" ]]; then
    echo "ERROR: use --template-a and --template-b together." >&2
    exit 1
  fi

  compare_templates "$template_a" "$template_b" "$label_a" "$label_b"
  echo "OK: issue templates are identical between $label_a and $label_b"
  exit 0
fi

standard_source="presets/nimbus-code-standards/templates/project-root/.github/ISSUE_TEMPLATE/nimbus-code-task.md"
platform_source="presets/nimbus-code-platform-standards/templates/project-root/.github/ISSUE_TEMPLATE/nimbus-code-task.md"
standard_active=".specify/presets/nimbus-code-standards/templates/project-root/.github/ISSUE_TEMPLATE/nimbus-code-task.md"
platform_active=".specify/presets/nimbus-code-platform-standards/templates/project-root/.github/ISSUE_TEMPLATE/nimbus-code-task.md"

compare_templates "$standard_source" "$platform_source"   "nimbus-code-standards" "nimbus-code-platform-standards"
compare_templates "$standard_source" "$standard_active"   "presets/nimbus-code-standards" ".specify/presets/nimbus-code-standards"
compare_templates "$platform_source" "$platform_active"   "presets/nimbus-code-platform-standards" ".specify/presets/nimbus-code-platform-standards"

echo "OK: issue templates are identical between nimbus-code-standards and nimbus-code-platform-standards"
