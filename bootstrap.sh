#!/usr/bin/env bash
# Bootstrap: applies the nimbus-code-project-bundle to a new or existing repository.
set -euo pipefail

STANDARDS_REPO="https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template"
LOCAL_PATH=""
INTEGRATION="${SPECKIT_INTEGRATION_DEFAULT:-copilot}"
REPO_TYPE=""
SELECTED_PRESET=""

print_usage() {
  cat <<'EOF'
Usage:
  ./bootstrap.sh [--local <path>] [--integration <copilot|claude|gemini>] [--repo-type <platform|dev_standards>]
EOF
}

preset_for_repo_type() {
  case "$1" in
    platform)
      echo "nimbus-code-platform-standards"
      ;;
    dev_standards)
      echo "nimbus-code-standards"
      ;;
    *)
      echo ""
      ;;
  esac
}

resolve_repo_type() {
  if [[ -n "$REPO_TYPE" ]]; then
    if [[ -z "$(preset_for_repo_type "$REPO_TYPE")" ]]; then
      echo "ERROR: invalid --repo-type '$REPO_TYPE'. Use 'platform' or 'dev_standards'." >&2
      exit 1
    fi
    return
  fi

  if [[ ! -t 0 ]]; then
    echo "ERROR: --repo-type is required in non-interactive mode. Use --repo-type platform or --repo-type dev_standards." >&2
    exit 1
  fi

  while true; do
    printf '? Is this repository platform/client or dev standards? [platform/dev_standards] '
    read -r REPO_TYPE
    case "$REPO_TYPE" in
      platform|dev_standards)
        return
        ;;
      *)
        echo "ERROR: answer must be 'platform' or 'dev_standards'."
        ;;
    esac
  done
}

select_template_file() {
  local relative_path="$1"
  local preferred="$LOCAL_PATH/presets/$SELECTED_PRESET/templates/$relative_path"
  local fallback="$LOCAL_PATH/presets/nimbus-code-standards/templates/$relative_path"

  if [[ -f "$preferred" ]]; then
    echo "$preferred"
    return 0
  fi

  if [[ -f "$fallback" ]]; then
    echo "$fallback"
    return 0
  fi

  return 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --local)
      LOCAL_PATH="$2"
      shift 2
      ;;
    --integration)
      INTEGRATION="$2"
      shift 2
      ;;
    --repo-type)
      REPO_TYPE="$2"
      shift 2
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      print_usage >&2
      exit 1
      ;;
  esac
done

if ! command -v specify >/dev/null 2>&1; then
  echo "ERROR: 'specify' CLI not found. Install it first: https://github.com/github/spec-kit" >&2
  exit 1
fi

WORKDIR="$(pwd)"

if [[ -z "$LOCAL_PATH" ]]; then
  TMP_CLONE="$(mktemp -d)"
  trap 'rm -rf "$TMP_CLONE"' EXIT
  echo "-> Cloning $STANDARDS_REPO..."
  git clone --depth 1 "$STANDARDS_REPO" "$TMP_CLONE" >/dev/null
  LOCAL_PATH="$TMP_CLONE"
fi

resolve_repo_type
SELECTED_PRESET="$(preset_for_repo_type "$REPO_TYPE")"

echo "-> Initializing Nimbus Code in $WORKDIR (integration: $INTEGRATION)..."
specify init --here --integration "$INTEGRATION" --force

echo "-> Installing preset $SELECTED_PRESET..."
specify preset add --dev "$LOCAL_PATH/presets/$SELECTED_PRESET" --priority 5   || echo "  (preset already installed - skipped; use 'specify preset remove $SELECTED_PRESET' before reinstalling)"

echo "-> Installing extension nimbus-code-backlog-sync..."
specify extension add --dev "$LOCAL_PATH/extensions/nimbus-code-backlog-sync"   || echo "  (extension already installed - skipped; use 'specify extension remove nimbus-code-backlog-sync' before reinstalling)"

echo "-> Installing workflow nimbus-code-full-cycle..."
specify workflow add "$LOCAL_PATH/workflows/nimbus-code-full-cycle"   || echo "  (workflow already installed - skipped; use 'specify workflow remove nimbus-code-full-cycle' before reinstalling)"

echo "-> Installing update check workflow..."
UPDATE_CHECK_SRC="$LOCAL_PATH/templates/workflows/update-speckit-and-bundle.yml"
if [[ -f "$UPDATE_CHECK_SRC" ]]; then
  mkdir -p "$WORKDIR/.github/workflows"
  cp "$UPDATE_CHECK_SRC" "$WORKDIR/.github/workflows/update-speckit-and-bundle.yml"
  echo "  OK: .github/workflows/update-speckit-and-bundle.yml installed."
  echo "  INFO: with VPNDEV_STANDARDS_READ_TOKEN it can compare the latest bundle version."
else
  echo "  WARN: missing template $UPDATE_CHECK_SRC"
fi

echo
echo "-> Installing ensure-github-project workflow..."
ENSURE_PROJECT_SRC="$LOCAL_PATH/templates/workflows/ensure-github-project.yml"
if [[ -f "$ENSURE_PROJECT_SRC" ]]; then
  mkdir -p "$WORKDIR/.github/workflows"
  cp "$ENSURE_PROJECT_SRC" "$WORKDIR/.github/workflows/ensure-github-project.yml"
  echo "  OK: .github/workflows/ensure-github-project.yml installed."
  echo "  INFO: prefers NIMBUS_APP_ID/NIMBUS_APP_PRIVATE_KEY; falls back to VPNDEV_PROJECT_TOKEN during rollout."
else
  echo "  WARN: missing template $ENSURE_PROJECT_SRC"
fi

echo
echo "-> Installing add-to-repo-project workflow..."
ADD_TO_REPO_PROJECT_SRC="$LOCAL_PATH/templates/workflows/add-to-repo-project.yml"
if [[ -f "$ADD_TO_REPO_PROJECT_SRC" ]]; then
  mkdir -p "$WORKDIR/.github/workflows"
  cp "$ADD_TO_REPO_PROJECT_SRC" "$WORKDIR/.github/workflows/add-to-repo-project.yml"
  echo "  OK: .github/workflows/add-to-repo-project.yml installed."
  echo "  INFO: prefers NIMBUS_APP_ID/NIMBUS_APP_PRIVATE_KEY; falls back to VPNDEV_PROJECT_TOKEN during rollout."
else
  echo "  WARN: missing template $ADD_TO_REPO_PROJECT_SRC"
fi

echo
echo "-> Installing DEVSTATS workflow..."
DEVSTATS_WORKFLOW_SRC="$LOCAL_PATH/templates/workflows/devstats-corporate-integration.yml"
if [[ -f "$DEVSTATS_WORKFLOW_SRC" ]]; then
  mkdir -p "$WORKDIR/.github/workflows"
  cp "$DEVSTATS_WORKFLOW_SRC" "$WORKDIR/.github/workflows/devstats-corporate-integration.yml"
  echo "  OK: .github/workflows/devstats-corporate-integration.yml installed."
else
  echo "  WARN: missing template $DEVSTATS_WORKFLOW_SRC"
fi

echo
echo "INFO: opt-in workflows:"
echo "  - templates/workflows/add-to-pmo-project.yml"
echo "  - templates/workflows/sync-priority-field.yml (prefers NIMBUS_APP_ID/NIMBUS_APP_PRIVATE_KEY; fallback ADD_TO_PROJECT_PAT)"
echo "  - templates/workflows/terraform-plan-gate.yml"

echo
echo "-> Installing cost profile documentation..."
COST_PROFILES_SRC="$(select_template_file 'cost-profiles-and-rates.md' || true)"
if [[ -n "$COST_PROFILES_SRC" && -f "$COST_PROFILES_SRC" ]]; then
  mkdir -p "$WORKDIR/docs"
  if [[ -f "$WORKDIR/docs/cost-profiles-and-rates.md" ]]; then
    echo "  INFO: docs/cost-profiles-and-rates.md already exists - skipped."
  else
    cp "$COST_PROFILES_SRC" "$WORKDIR/docs/cost-profiles-and-rates.md"
    echo "  OK: docs/cost-profiles-and-rates.md installed."
  fi
else
  echo "  WARN: missing cost profile template"
fi

echo
echo "-> Installing reuse catalog..."
REUSE_CATALOG_SRC="$(select_template_file 'reuse-catalog.yaml' || true)"
if [[ -n "$REUSE_CATALOG_SRC" && -f "$REUSE_CATALOG_SRC" ]]; then
  mkdir -p "$WORKDIR/docs"
  if [[ -f "$WORKDIR/docs/reuse-catalog.yaml" ]]; then
    echo "  INFO: docs/reuse-catalog.yaml already exists - skipped."
  else
    cp "$REUSE_CATALOG_SRC" "$WORKDIR/docs/reuse-catalog.yaml"
    echo "  OK: docs/reuse-catalog.yaml installed."
  fi
else
  echo "  WARN: missing reuse catalog template"
fi

echo
echo "-> Installing Copilot instructions..."
COPILOT_INSTRUCTIONS_SRC="$(select_template_file 'project-root/copilot-instructions.md' || true)"
if [[ -n "$COPILOT_INSTRUCTIONS_SRC" && -f "$COPILOT_INSTRUCTIONS_SRC" ]]; then
  mkdir -p "$WORKDIR/.github"
  if [[ -f "$WORKDIR/.github/copilot-instructions.md" ]]; then
    echo "  INFO: .github/copilot-instructions.md already exists - skipped."
  else
    cp "$COPILOT_INSTRUCTIONS_SRC" "$WORKDIR/.github/copilot-instructions.md"
    echo "  OK: .github/copilot-instructions.md installed."
  fi
else
  echo "  WARN: missing Copilot instructions template"
fi

BUNDLE_VERSION="$(grep -A4 '^bundle:' "$LOCAL_PATH/bundles/nimbus-code-project-bundle/bundle.yml" | grep -E '^\s*version:' | head -1 | sed -E 's/.*"([0-9.]+)".*//')"
echo
echo "OK: bundle nimbus-code-project-bundle v${BUNDLE_VERSION} applied."
echo "OK: preset installed: $SELECTED_PRESET (repository type: $REPO_TYPE)"

auto_assign_hint() {
  echo "  INFO: to enable auto-assign, configure NIMBUS_APP_ID/NIMBUS_APP_PRIVATE_KEY; COPILOT_AGENT_ASSIGN_TOKEN remains a temporary fallback during rollout."
}

if command -v gh >/dev/null 2>&1; then
  echo
  echo "-> Configuring GitHub Project V2 and labels..."
  if GIT_REMOTE=$(git config --get remote.origin.url 2>/dev/null); then
    REPO_PATH="$GIT_REMOTE"
    if [[ "$REPO_PATH" == git@* ]]; then
      REPO_PATH="${REPO_PATH#*:}"
    else
      REPO_PATH="${REPO_PATH#*://}"
      REPO_PATH="${REPO_PATH#*/}"
    fi
    REPO_PATH="${REPO_PATH%.git}"
    if [[ -n "$REPO_PATH" && "$REPO_PATH" == */* ]]; then
      REPO_OWNER="${REPO_PATH%%/*}"
      REPO_NAME="${REPO_PATH#*/}"
      SETUP_SCRIPT="$LOCAL_PATH/scripts/setup-github-project.sh"
      if [[ -f "$SETUP_SCRIPT" ]]; then
        bash "$SETUP_SCRIPT" --repo-owner "$REPO_OWNER" --repo-name "$REPO_NAME" || {
          echo "  WARN: could not create GitHub Project automatically."
          echo "  Run manually: bash $SETUP_SCRIPT --repo-owner $REPO_OWNER --repo-name $REPO_NAME"
        }
      fi
      LABELS_SCRIPT="$LOCAL_PATH/scripts/setup-github-labels.sh"
      if [[ -f "$LABELS_SCRIPT" ]]; then
        bash "$LABELS_SCRIPT" --repo-owner "$REPO_OWNER" --repo-name "$REPO_NAME" || {
          echo "  WARN: could not create labels automatically."
          echo "  Run manually: bash $LABELS_SCRIPT --repo-owner $REPO_OWNER --repo-name $REPO_NAME"
        }
        auto_assign_hint
      fi
    else
      echo "  WARN: could not derive owner/repo from remote: $GIT_REMOTE"
    fi
  else
    echo "  WARN: remote.origin.url is not configured"
  fi
else
  echo "  WARN: gh CLI not found - skipping GitHub Project and label setup"
fi

# Install version synchronization hooks
echo
echo "-> Installing git hooks for version synchronization..."
HOOKS_SCRIPT="$LOCAL_PATH/scripts/install-hooks.sh"
if [[ -f "$HOOKS_SCRIPT" ]]; then
  bash "$HOOKS_SCRIPT" || {
    echo "  WARN: could not install hooks automatically."
    echo "  Run manually: bash $HOOKS_SCRIPT"
  }
else
  echo "  WARN: install-hooks.sh not found"
fi

echo
echo "✅ Bootstrap complete!"
echo ""
echo "Next steps:"
echo "  1. Review docs/version-synchronization.md for version management"
echo "  2. Run: ./scripts/validate-versions.sh to verify all versions are synced"
echo "  3. Configure your project in specs/<feature>/spec.md"
