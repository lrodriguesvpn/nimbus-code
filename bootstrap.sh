#!/usr/bin/env bash
# Bootstrap: applies the nimbus-code-project-bundle to a new or existing repository.
set -euo pipefail

STANDARDS_REPO="https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template"
LOCAL_PATH=""
INTEGRATION="${SPECKIT_INTEGRATION_DEFAULT:-copilot}"
REPO_TYPE=""
SELECTED_PRESET=""
DELIVERY_MODEL=""
DECISION_REASON=""
DECISION_OWNER=""
SATELLITE_DOMAINS=""
CUSTOM_DOMAIN_JUSTIFICATION=""
CUSTOM_DOMAIN_OWNERSHIP=""

print_usage() {
  cat <<'EOF'
Usage:
  ./bootstrap.sh [--local <path>] [--integration <copilot|claude|gemini>] [--repo-type <platform|dev_standards>] [--delivery-model <monorepo|multirepo>] [--decision-reason <text>] [--decision-owner <team|role>] [--satellite-domains <CSV>] [--custom-domain-justification <text>] [--custom-domain-ownership <text>]
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
  local classification="greenfield"
  local indicator_list=""

  if detect_has_relevant_application_code; then
    classification="brownfield"
    indicator_list="Relevant application code detected in source directories, build manifests, or application tests"
  else
    indicator_list="No relevant application code found; only README, LICENSE, workflows, setup scripts, or minimal templates"
  fi

  echo "$classification"
  echo "$indicator_list"
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
  echo "-> Cloning $STANDARDS_REPO..."
  git clone --depth 1 "$STANDARDS_REPO" "$TMP_CLONE" >/dev/null
  LOCAL_PATH="$TMP_CLONE"
fi

resolve_repo_type
SELECTED_PRESET="$(preset_for_repo_type "$REPO_TYPE")"

echo "-> Classifying repository context (greenfield vs brownfield)..."
read -r DETECTED_CONTEXT CONTEXT_INDICATOR <<< "$(classify_repository_context)"
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

echo "-> Installing preset $SELECTED_PRESET..."
specify preset add --dev "$LOCAL_PATH/presets/$SELECTED_PRESET" --priority 5   || echo "  (preset already installed - skipped; use 'specify preset remove $SELECTED_PRESET' before reinstalling)"

echo "-> Installing extension nimbus-code-backlog-sync..."
specify extension add --dev "$LOCAL_PATH/extensions/nimbus-code-backlog-sync"   || echo "  (extension already installed - skipped; use 'specify extension remove nimbus-code-backlog-sync' before reinstalling)"

echo "-> Installing extension cost (spec-kit-cost)..."
if command -v specify >/dev/null 2>&1; then
  specify extension install cost --version ">=1.0.0" >/dev/null 2>&1 || echo "  INFO: cost extension requires 'specify extension install cost' (network install from GitHub)"
else
  echo "  WARN: specify CLI not available for cost extension installation"
fi

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
echo "  3. If this is the Repo Central, create/update specs/<feature>/spec.md there; if this is a satellite repo, keep specs only in the product central repo and route code tasks here."
