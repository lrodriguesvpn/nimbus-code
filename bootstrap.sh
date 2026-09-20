#!/usr/bin/env bash
# Bootstrap: applies the nimbus-code-project-bundle to a new or existing repository.
set -euo pipefail

STANDARDS_REPO="https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template"
LOCAL_PATH=""
NIMBUS_REF="${NIMBUS_REF:-main}"
INTEGRATION="${SPECKIT_INTEGRATION_DEFAULT:-copilot}"
REPO_TYPE=""
SELECTED_PRESET=""
DELIVERY_MODEL=""
DECISION_REASON=""
DECISION_OWNER=""
SATELLITE_DOMAINS=""
CUSTOM_DOMAIN_JUSTIFICATION=""
CUSTOM_DOMAIN_OWNERSHIP=""

IGNORED_TOP_LEVEL_ARTIFACTS=(
  .github .specify docs templates presets extensions workflows tests specs bundles reports scripts
  README.md LICENSE .gitignore .editorconfig .npmrc .prettierrc .prettierrc.json .prettierrc.yml
  .eslintrc .eslintrc.json .markdownlint.json .tool-versions
)

print_usage() {
  cat <<'EOF'
Usage:
  ./bootstrap.sh [--local <path>] [--ref <tag|branch>] [--integration <copilot|claude|gemini>] [--repo-type <platform|dev_standards>] [--delivery-model <monorepo|multirepo>] [--decision-reason <text>] [--decision-owner <team|role>] [--satellite-domains <CSV>] [--custom-domain-justification <text>] [--custom-domain-ownership <text>]
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
  local prompt='? Is this repository platform/client or dev standards? [platform/dev_standards] '

  if [[ -n "$REPO_TYPE" ]]; then
    if [[ -z "$(preset_for_repo_type "$REPO_TYPE")" ]]; then
      echo "ERROR: invalid --repo-type '$REPO_TYPE'. Use 'platform' or 'dev_standards'." >&2
      exit 1
    fi
    return
  fi

  while true; do
    if [[ -t 0 ]]; then
      printf '%s' "$prompt"
      read -r REPO_TYPE
    elif [[ -r /dev/tty ]]; then
      printf '%s' "$prompt" > /dev/tty
      read -r REPO_TYPE < /dev/tty
    else
      echo "ERROR: --repo-type is required in fully non-interactive mode. Use --repo-type platform or --repo-type dev_standards." >&2
      exit 1
    fi

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

read_interactive_value() {
  local prompt="$1"
  local result_var="$2"
  local value=""

  if [[ -t 0 ]]; then
    printf '%s' "$prompt"
    IFS= read -r value
  elif [[ -r /dev/tty ]]; then
    printf '%s' "$prompt" > /dev/tty
    IFS= read -r value < /dev/tty
  fi

  printf -v "$result_var" '%s' "$value"
}

require_non_empty_value() {
  local var_name="$1"
  local prompt="$2"
  local non_interactive_error="$3"
  local current=""

  eval "current=\"\${$var_name:-}\""

  while [[ -z "$current" ]]; do
    if [[ -t 0 || -r /dev/tty ]]; then
      read_interactive_value "$prompt" current
    else
      echo "ERROR: $non_interactive_error" >&2
      exit 1
    fi
  done

  printf -v "$var_name" '%s' "$current"
}

resolve_delivery_model() {
  local prompt='? For greenfield, choose delivery model [monorepo/multirepo] '

  while true; do
    if [[ -n "$DELIVERY_MODEL" ]]; then
      case "$DELIVERY_MODEL" in
        monorepo|multirepo)
          return
          ;;
        *)
          echo "ERROR: invalid --delivery-model '$DELIVERY_MODEL'. Use 'monorepo' or 'multirepo'." >&2
          exit 1
          ;;
      esac
    fi

    if [[ -t 0 || -r /dev/tty ]]; then
      read_interactive_value "$prompt" DELIVERY_MODEL
    else
      echo "ERROR: --delivery-model is required in fully non-interactive greenfield mode. Use --delivery-model monorepo or --delivery-model multirepo." >&2
      exit 1
    fi
  done
}

normalize_satellite_domains() {
  local domains="$1"
  echo "$domains" | tr '[:lower:]' '[:upper:]' | tr -d ' ' | sed -E 's/,+/,/g; s/^,+//; s/,+$//'
}

resolve_greenfield_topology_decision() {
  local baseline_domains="FRONT,BACK,DESIGN,DATA,JOBS"
  local domains_prompt='? Suggested satellite baseline is FRONT/BACK/DESIGN/DATA/JOBS. Press ENTER to accept or provide CSV to adapt it: '
  local domains_input=""

  [[ "${DETECTED_CONTEXT:-}" == "greenfield" ]] || return 0

  echo "-> Capturing topology decision for greenfield intake..."
  resolve_delivery_model

  require_non_empty_value \
    "DECISION_REASON" \
    "? Why did you choose ${DELIVERY_MODEL}? (main reason + expected trade-off) " \
    "--decision-reason is required in fully non-interactive greenfield mode."

  require_non_empty_value \
    "DECISION_OWNER" \
    "? Who is confirming this structural decision? (team/role) " \
    "--decision-owner is required in fully non-interactive greenfield mode."

  if [[ "$DELIVERY_MODEL" == "multirepo" ]]; then
    if [[ -n "$SATELLITE_DOMAINS" ]]; then
      domains_input="$SATELLITE_DOMAINS"
    elif [[ -t 0 || -r /dev/tty ]]; then
      read_interactive_value "$domains_prompt" domains_input
    else
      domains_input="$baseline_domains"
    fi

    if [[ -z "$domains_input" ]]; then
      SATELLITE_DOMAINS="$baseline_domains"
    else
      SATELLITE_DOMAINS="$(normalize_satellite_domains "$domains_input")"
    fi

    if [[ "$SATELLITE_DOMAINS" != "$baseline_domains" ]]; then
      require_non_empty_value \
        "CUSTOM_DOMAIN_JUSTIFICATION" \
        "? Why are you adapting the baseline domains? " \
        "--custom-domain-justification is required when --satellite-domains differs from FRONT,BACK,DESIGN,DATA,JOBS."

      require_non_empty_value \
        "CUSTOM_DOMAIN_OWNERSHIP" \
        "? Who owns the custom domain topology? (team/role/repo) " \
        "--custom-domain-ownership is required when --satellite-domains differs from FRONT,BACK,DESIGN,DATA,JOBS."
    fi

    echo "  Handoff: define/confirm satellite domains after the first structural spec in the Repo Central."
    echo "  Baseline recommendation: FRONT/BACK/DESIGN/DATA/JOBS (adaptable with explicit ownership)."
  else
    SATELLITE_DOMAINS=""
  fi
}

persist_topology_decision() {
  local feature_file="$WORKDIR/.specify/feature.json"
  local timestamp
  local domains_json="[]"

  [[ "${DETECTED_CONTEXT:-}" == "greenfield" ]] || return 0

  if [[ ! -f "$feature_file" ]]; then
    echo "  WARN: .specify/feature.json not found; skipping topology decision persistence."
    return 0
  fi

  if [[ -n "$SATELLITE_DOMAINS" ]]; then
    domains_json="$(printf '%s' "$SATELLITE_DOMAINS" | tr ',' '\n' | sed '/^$/d' | jq -R . | jq -s .)"
  fi

  timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

  jq \
    --arg dm "$DELIVERY_MODEL" \
    --arg dr "$DECISION_REASON" \
    --arg do "$DECISION_OWNER" \
    --arg cj "$CUSTOM_DOMAIN_JUSTIFICATION" \
    --arg co "$CUSTOM_DOMAIN_OWNERSHIP" \
    --arg ci "$CONTEXT_INDICATOR" \
    --arg ts "$timestamp" \
    --argjson domains "$domains_json" \
    '
    .topology_decision = {
      delivery_model: $dm,
      decision_reason: $dr,
      decision_owner: $do,
      satellite_domains: $domains,
      custom_domain_justification: (if $cj == "" then null else $cj end),
      custom_domain_ownership: (if $co == "" then null else $co end),
      context_indicator: $ci,
      recorded_at: $ts
    }
    ' "$feature_file" > "$feature_file.tmp"

  mv "$feature_file.tmp" "$feature_file"
  echo "  OK: topology decision persisted to .specify/feature.json."
}

select_template_file() {
  local relative_path="$1"
  local preferred="$LOCAL_PATH/presets/$SELECTED_PRESET/templates/$relative_path"

  if [[ -f "$preferred" ]]; then
    echo "$preferred"
    return 0
  fi

  return 1
}

detect_has_relevant_application_source() {
  local application_dirs=(
    "src" "app" "packages" "services" "frontend" "backend"
    "lib" "config" "routes" "controllers" "models" "components"
  )
  local dir

  for dir in "${application_dirs[@]}"; do
    [[ -d "$WORKDIR/$dir" ]] || continue
    if find "$WORKDIR/$dir" -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.py' -o -name '*.go' -o -name '*.java' -o -name '*.cs' -o -name '*.rb' \) 2>/dev/null | grep -q .; then
      return 0
    fi
  done

  return 1
}

detect_has_relevant_application_manifest() {
  local manifest_files=(
    "package.json" "pom.xml" "build.gradle" "Makefile" "Dockerfile"
    "pyproject.toml" "setup.py" "go.mod" "Cargo.toml"
  )
  local manifest

  for manifest in "${manifest_files[@]}"; do
    if [[ -f "$WORKDIR/$manifest" ]] && grep -Eq 'src|app|packages|services|frontend|backend' "$WORKDIR/$manifest" 2>/dev/null; then
      return 0
    fi
  done

  if find "$WORKDIR" -type f \( -name '*.csproj' -o -name '*.fsproj' \) 2>/dev/null | grep -q .; then
    return 0
  fi

  return 1
}

detect_has_relevant_application_tests() {
  local test_dirs=("__tests__" "test" "tests" "spec" "specs")
  local test_dir test_file

  for test_dir in "${test_dirs[@]}"; do
    [[ -d "$WORKDIR/$test_dir" ]] || continue
    while IFS= read -r test_file; do
      [[ -n "$test_file" ]] || continue
      case "$test_file" in
        *bootstrap*|*infra*|*setup*)
          continue
          ;;
        *)
          return 0
          ;;
      esac
    done < <(find "$WORKDIR/$test_dir" -type f \( -name '*.test.*' -o -name '*.spec.*' -o -name '*_test.*' -o -name '*_spec.*' \) 2>/dev/null)
  done

  return 1
}

detect_has_relevant_application_code() {
  detect_has_relevant_application_source || \
    detect_has_relevant_application_manifest || \
    detect_has_relevant_application_tests
}

classify_repository_context() {
  if detect_has_relevant_application_code; then
    DETECTED_CONTEXT="brownfield"
    CONTEXT_INDICATOR="Relevant application code detected in source directories, build manifests, or application tests"
  else
    DETECTED_CONTEXT="greenfield"
    CONTEXT_INDICATOR="No relevant application code found; only README, LICENSE, workflows, setup scripts, or minimal templates"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --local)
      [[ $# -ge 2 && -n "$2" ]] || { echo "ERROR: --local requires a path." >&2; exit 1; }
      LOCAL_PATH="$2"
      shift 2
      ;;
    --ref|--version)
      [[ $# -ge 2 && -n "$2" ]] || { echo "ERROR: $1 requires a tag or branch." >&2; exit 1; }
      NIMBUS_REF="$2"
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
    --delivery-model)
      DELIVERY_MODEL="$2"
      shift 2
      ;;
    --decision-reason)
      DECISION_REASON="$2"
      shift 2
      ;;
    --decision-owner)
      DECISION_OWNER="$2"
      shift 2
      ;;
    --satellite-domains)
      SATELLITE_DOMAINS="$2"
      shift 2
      ;;
    --custom-domain-justification)
      CUSTOM_DOMAIN_JUSTIFICATION="$2"
      shift 2
      ;;
    --custom-domain-ownership)
      CUSTOM_DOMAIN_OWNERSHIP="$2"
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
  echo "-> Cloning $STANDARDS_REPO at ref $NIMBUS_REF..."
  git clone --depth 1 --branch "$NIMBUS_REF" "$STANDARDS_REPO" "$TMP_CLONE" >/dev/null
  LOCAL_PATH="$TMP_CLONE"
elif [[ ! -d "$LOCAL_PATH" ]]; then
  echo "ERROR: local template path does not exist: $LOCAL_PATH" >&2
  exit 1
fi

resolve_repo_type
SELECTED_PRESET="$(preset_for_repo_type "$REPO_TYPE")"

echo "-> Classifying repository context (greenfield vs brownfield)..."
classify_repository_context
echo "  Detected context: $DETECTED_CONTEXT"
if [[ "$DETECTED_CONTEXT" == "brownfield" ]]; then
  echo "  Interpretation: relevant application code is present, so the repo follows the brownfield path."
else
  echo "  Interpretation: no relevant application code was found, so the repo follows the greenfield path."
fi
echo "  Evidence: $CONTEXT_INDICATOR"
resolve_greenfield_topology_decision

echo "-> Initializing Nimbus Code in $WORKDIR (integration: $INTEGRATION)..."
specify init --here --integration "$INTEGRATION" --force
persist_topology_decision

persist_bootstrap_metadata() {
  local metadata_file="$WORKDIR/.nimbus/bootstrap.json"
  local bundle_id="$1"
  local bundle_version="$2"
  local source_ref="$3"

  mkdir -p "$(dirname "$metadata_file")"
  jq -n \
    --arg bundle "$bundle_id" \
    --arg version "$bundle_version" \
    --arg ref "$source_ref" \
    --arg preset "$SELECTED_PRESET" \
    --arg repo_type "$REPO_TYPE" \
    '{
      schema_version: "1.0",
      bundle: $bundle,
      bundle_version: $version,
      source_ref: $ref,
      preset: $preset,
      repository_type: $repo_type,
      recorded_at: (now | strftime("%Y-%m-%dT%H:%M:%SZ"))
    }' > "$metadata_file"
  echo "  OK: bootstrap metadata recorded at .nimbus/bootstrap.json."
}

component_is_installed() {
  local kind="$1"
  local component_id="$2"

  case "$kind" in
    preset) [[ -d "$WORKDIR/.specify/presets/$component_id" ]] ;;
    extension) [[ -d "$WORKDIR/.specify/extensions/$component_id" ]] ;;
    workflow) [[ -d "$WORKDIR/.specify/workflows/$component_id" ]] ;;
    *) return 1 ;;
  esac
}

install_component() {
  local kind="$1"
  local component_id="$2"
  local description="$3"
  shift 3

  if "$@"; then
    return 0
  fi

  if component_is_installed "$kind" "$component_id"; then
    echo "  INFO: $description already installed; leaving existing installation unchanged."
    return 0
  fi

  echo "ERROR: failed to install $description." >&2
  echo "       Command: $*" >&2
  exit 1
}

echo "-> Installing preset $SELECTED_PRESET..."
# Detect a stale already-installed preset and upgrade it automatically.
# `specify preset add` has no "update" verb: re-running it on a repo that
# already has the same preset ID installed just fails/no-ops, so simply
# re-running bootstrap.sh after a preset version bump silently kept every
# repo on its old (possibly broken) preset forever. Compare the version
# recorded in .specify/presets/.registry against the version declared in
# the source preset.yml, and remove+reinstall when they differ.
SOURCE_PRESET_MANIFEST="$LOCAL_PATH/presets/$SELECTED_PRESET/preset.yml"
SOURCE_PRESET_VERSION="$({ grep -E '^version:' "$SOURCE_PRESET_MANIFEST" 2>/dev/null || true; } | head -1 | sed -E 's/^version:[[:space:]]*"?([^"[:space:]]+)"?.*/\1/')"
INSTALLED_REGISTRY="$WORKDIR/.specify/presets/.registry"
INSTALLED_PRESET_VERSION=""
if [[ -f "$INSTALLED_REGISTRY" ]] && command -v python3 >/dev/null 2>&1; then
  INSTALLED_PRESET_VERSION="$(SPECKIT_REGISTRY="$INSTALLED_REGISTRY" SPECKIT_PRESET="$SELECTED_PRESET" python3 -c "
import json, os
try:
    with open(os.environ['SPECKIT_REGISTRY']) as f:
        data = json.load(f)
    print(data.get('presets', {}).get(os.environ['SPECKIT_PRESET'], {}).get('version', ''))
except Exception:
    print('')
" 2>/dev/null)"
fi
if [[ -n "$INSTALLED_PRESET_VERSION" && -n "$SOURCE_PRESET_VERSION" && "$INSTALLED_PRESET_VERSION" != "$SOURCE_PRESET_VERSION" ]]; then
  echo "  Installed preset version ($INSTALLED_PRESET_VERSION) differs from source ($SOURCE_PRESET_VERSION) - upgrading..."
  if ! specify preset remove "$SELECTED_PRESET"; then
    echo "ERROR: could not remove existing preset $SELECTED_PRESET before upgrade." >&2
    exit 1
  fi
fi
install_component preset "$SELECTED_PRESET" "preset $SELECTED_PRESET" \
  specify preset add --dev "$LOCAL_PATH/presets/$SELECTED_PRESET" --priority 5

if [[ "$REPO_TYPE" == "dev_standards" ]]; then
  echo "-> Installing extension nimbus-code-backlog-sync..."
  install_component extension nimbus-code-backlog-sync "extension nimbus-code-backlog-sync" \
    specify extension add --dev "$LOCAL_PATH/extensions/nimbus-code-backlog-sync"

  echo "-> Installing extension cost (spec-kit-cost)..."
  install_component extension cost "extension cost (spec-kit-cost)" \
    specify extension install cost --version ">=1.0.0"

  echo "-> Installing extension bug (Bug Triage Workflow)..."
  install_component extension bug "extension bug" \
    specify extension add bug

  echo "-> Installing extension assess (Idea Assessment Pipeline)..."
  install_component extension assess "extension assess" \
    specify extension add assess
fi

if [[ "$REPO_TYPE" == "dev_standards" ]]; then
  echo "-> Installing workflow nimbus-code-full-cycle..."
  install_component workflow nimbus-code-full-cycle "workflow nimbus-code-full-cycle" \
    specify workflow add "$LOCAL_PATH/workflows/nimbus-code-full-cycle"
fi

if [[ "$REPO_TYPE" == "dev_standards" ]]; then
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

if [[ "$REPO_TYPE" == "dev_standards" ]]; then
echo
echo "-> Installing agent session manual..."
AGENT_SESSION_MANUAL_SRC="$(select_template_file 'agent-session-manual.md' || true)"
if [[ -n "$AGENT_SESSION_MANUAL_SRC" && -f "$AGENT_SESSION_MANUAL_SRC" ]]; then
  mkdir -p "$WORKDIR/docs"
  if [[ -f "$WORKDIR/docs/agent-session-manual.md" ]]; then
    echo "  INFO: docs/agent-session-manual.md already exists - skipped."
  else
    cp "$AGENT_SESSION_MANUAL_SRC" "$WORKDIR/docs/agent-session-manual.md"
    echo "  OK: docs/agent-session-manual.md installed."
  fi
else
  echo "  WARN: missing agent session manual template"
fi
fi

# Generic delivery for every remaining file the preset declares under
# templates/project-root/ (workflows, ISSUE_TEMPLATE, Harness Engineering,
# Playbook de Sucesso, automation scripts, cost-config, bounded-contexts.yaml).
# Without this loop, adding a new "provides.templates" entry to preset.yml
# never actually reaches a consumer project - only the handful of files
# explicitly cp'd above (and the 4 hardcoded workflows earlier in this script)
# were ever delivered. Existing files are never overwritten (idempotent reruns
# won't clobber org data accumulated in harness-catalog.yaml, for example).
echo
echo "-> Installing remaining preset project-root files..."
PRESET_ROOT_DIR="$LOCAL_PATH/presets/$SELECTED_PRESET/templates/project-root"
if [[ ! -d "$PRESET_ROOT_DIR" ]]; then
  echo "ERROR: project-root templates directory not found for preset $SELECTED_PRESET." >&2
  exit 1
fi

if [[ -d "$PRESET_ROOT_DIR" ]]; then
  while IFS= read -r -d '' src_file; do
    rel_path="${src_file#"$PRESET_ROOT_DIR"/}"
    case "$rel_path" in
      "copilot-instructions.md")
        # Already installed explicitly above (different target: .github/copilot-instructions.md).
        continue
        ;;
      "bounded-contexts.yaml")
        dest_rel="docs/bounded-contexts.yaml"
        ;;
      ".specify/cost/cost-config-template.yml")
        dest_rel=".specify/cost/cost-config.yml"
        ;;
      *)
        dest_rel="$rel_path"
        ;;
    esac

    dest_file="$WORKDIR/$dest_rel"
    if [[ -f "$dest_file" ]]; then
      echo "  INFO: $dest_rel already exists - skipped."
      continue
    fi
    mkdir -p "$(dirname "$dest_file")"
    cp -p "$src_file" "$dest_file"
    echo "  OK: $dest_rel installed."
  done < <(find "$PRESET_ROOT_DIR" -type f -print0)
else
  echo "ERROR: preset project-root templates directory not found - skipped." >&2
  exit 1
fi

BUNDLE_ID="nimbus-code-project-bundle"
if [[ "$REPO_TYPE" == "platform" ]]; then
  BUNDLE_ID="nimbus-code-platform-bundle"
fi
BUNDLE_MANIFEST="$LOCAL_PATH/bundles/$BUNDLE_ID/bundle.yml"
if [[ ! -f "$BUNDLE_MANIFEST" ]]; then
  echo "ERROR: bundle manifest not found for $REPO_TYPE: $BUNDLE_MANIFEST" >&2
  exit 1
fi
BUNDLE_VERSION="$(grep -A4 '^bundle:' "$BUNDLE_MANIFEST" | grep -E '^[[:space:]]*version:' | head -1 | sed -E 's/.*"([0-9.]+)".*/\1/')"
if [[ -z "$BUNDLE_VERSION" ]]; then
  echo "ERROR: could not determine version for bundle $BUNDLE_ID." >&2
  exit 1
fi
persist_bootstrap_metadata "$BUNDLE_ID" "$BUNDLE_VERSION" "$NIMBUS_REF"
echo
echo "OK: bundle $BUNDLE_ID v${BUNDLE_VERSION} applied."
echo "OK: preset installed: $SELECTED_PRESET (repository type: $REPO_TYPE)"
echo "OK: repository classified as $DETECTED_CONTEXT (reason: $CONTEXT_INDICATOR)"
if [[ "${DETECTED_CONTEXT:-}" == "greenfield" ]]; then
  echo "OK: topology decision recorded: $DELIVERY_MODEL (owner: $DECISION_OWNER)"
  if [[ "$DELIVERY_MODEL" == "multirepo" ]]; then
    echo "OK: suggested satellite domains: ${SATELLITE_DOMAINS:-FRONT,BACK,DESIGN,DATA,JOBS}"
  fi
fi

auto_assign_hint() {
  echo "  INFO: to enable auto-assign, configure NIMBUS_APP_ID/NIMBUS_APP_PRIVATE_KEY; COPILOT_AGENT_ASSIGN_TOKEN remains a temporary fallback during rollout."
}

if [[ "$REPO_TYPE" == "dev_standards" ]] && command -v gh >/dev/null 2>&1; then
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
elif [[ "$REPO_TYPE" == "dev_standards" ]]; then
  echo "  WARN: gh CLI not found - skipping GitHub Project and label setup"
fi

# Install version synchronization hooks
if [[ "$REPO_TYPE" == "dev_standards" ]]; then
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
fi

echo
echo "✅ Bootstrap complete!"
echo ""
echo "Next steps:"
echo "  1. Review docs/version-synchronization.md for version management"
echo "  2. Run: ./scripts/validate-versions.sh to verify all versions are synced"
echo "  3. If this is the Repo Central, create/update specs/<feature>/spec.md there; if this is a satellite repo, keep specs only in the product central repo and route code tasks here."
