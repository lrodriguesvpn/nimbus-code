#!/usr/bin/env bash
# Bootstrap: applies the nimbus-code-project-bundle to a new or existing repository.
set -euo pipefail

STANDARDS_REPO="${NIMBUS_STANDARDS_REPO:-https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code}"
LEGACY_STANDARDS_REPO="https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template"
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
BOOTSTRAP_MODE="apply"
OUTPUT_JSON="false"
TARGET_REPO_ROOT=""
SOURCE_REPO_ROOT=""
PRESET_REFRESH_SNAPSHOT_DIR=""
PRESET_REINSTALLED="false"
SKIP_BOOTSTRAP_SIDE_EFFECTS="false"

IGNORED_TOP_LEVEL_ARTIFACTS=(
  .github .specify docs templates presets extensions workflows tests specs bundles reports scripts
  README.md LICENSE .gitignore .editorconfig .npmrc .prettierrc .prettierrc.json .prettierrc.yml
  .eslintrc .eslintrc.json .markdownlint.json .tool-versions
)

print_usage() {
  cat <<'EOF'
Usage:
  ./bootstrap.sh [--local <path>] [--ref <tag|branch>] [--integration <copilot|claude|antigravity|cursor-agent|kiro-cli|...>] [--repo-type <platform|dev_standards>] [--delivery-model <monorepo|multirepo>] [--decision-reason <text>] [--decision-owner <team|role>] [--satellite-domains <CSV>] [--custom-domain-justification <text>] [--custom-domain-ownership <text>] [--refresh-preset]
  ./bootstrap.sh --detect-preset-version-mismatch [--repo-root <path>] [--source-root <path>] [--json]
Refresh updates the preset and unmodified managed files only; no init or GitHub provisioning.
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

load_repository_type_from_metadata() {
  local repo_root="$1"
  local metadata_file="$repo_root/.nimbus/bootstrap.json"

  if [[ -f "$metadata_file" ]]; then
    jq -r '.repository_type // empty' "$metadata_file" 2>/dev/null || true
  fi
}

load_preset_id_from_metadata() {
  local repo_root="$1"
  local metadata_file="$repo_root/.nimbus/bootstrap.json"

  if [[ -f "$metadata_file" ]]; then
    jq -r '.preset // empty' "$metadata_file" 2>/dev/null || true
  fi
}

normalize_repo_root() {
  local candidate="${1:-}"

  if [[ -z "$candidate" ]]; then
    pwd
    return 0
  fi

  python3 -c 'import os, sys; print(os.path.abspath(sys.argv[1]))' "$candidate"
}

registry_file_for_repo() {
  local repo_root="$1"
  echo "$repo_root/.specify/presets/.registry"
}

preset_manifest_for_source() {
  local source_root="$1"
  local preset_id="$2"
  echo "$source_root/presets/$preset_id/preset.yml"
}

project_root_destination_for_template() {
  local rel_path="$1"

  case "$rel_path" in
    "copilot-instructions.md")
      echo ".github/copilot-instructions.md"
      ;;
    "bounded-contexts.yaml")
      echo "docs/bounded-contexts.yaml"
      ;;
    ".specify/cost/cost-config-template.yml")
      echo ".specify/cost/cost-config.yml"
      ;;
    *)
      echo "$rel_path"
      ;;
  esac
}

extract_version_from_preset_manifest() {
  local manifest="$1"
  grep -m1 -E '^[[:space:]]*version:[[:space:]]*' "$manifest" 2>/dev/null |
    sed -E 's/^[[:space:]]*version:[[:space:]]*"?([^"[:space:]]+)"?.*/\1/'
}

extract_installed_preset_id() {
  local repo_root="$1"
  local preset_id=""
  local registry_file
  registry_file="$(registry_file_for_repo "$repo_root")"

  if [[ -n "${REPO_TYPE:-}" ]]; then
    preset_id="$(preset_for_repo_type "$REPO_TYPE")"
  fi

  if [[ -z "$preset_id" ]]; then
    preset_id="$(load_preset_id_from_metadata "$repo_root")"
  fi

  if [[ -z "$preset_id" && -f "$registry_file" ]]; then
    preset_id="$(python3 - "$registry_file" <<'PY'
import json, sys
path = sys.argv[1]
try:
    with open(path, "r", encoding="utf-8") as fh:
        data = json.load(fh)
    presets = data.get("presets", {})
    print(next(iter(presets.keys()), ""))
except Exception:
    print("")
PY
)"
  fi

  printf '%s' "$preset_id"
}

extract_registry_value() {
  local registry_file="$1"
  local preset_id="$2"
  local field="$3"

  python3 - "$registry_file" "$preset_id" "$field" <<'PY'
import json, sys
registry_path, preset_id, field = sys.argv[1:4]
try:
    with open(registry_path, "r", encoding="utf-8") as fh:
        data = json.load(fh)
    presets = data.get("presets", {}) if isinstance(data, dict) else {}
    preset = presets.get(preset_id, {}) if isinstance(presets, dict) else {}
    value = preset.get(field, "") if isinstance(preset, dict) else ""
    if not value and field == "version" and isinstance(data, dict):
        value = data.get("version", "")
    print(value if value is not None else "")
except Exception:
    print("")
PY
}

sanitize_version_segment() {
  local segment="$1"
  segment="${segment//[^0-9]/}"
  if [[ -z "$segment" ]]; then
    echo 0
  else
    echo "$segment"
  fi
}

compare_semver_versions() {
  local left="$1"
  local right="$2"
  local IFS='.'
  local left_parts right_parts idx
  read -r -a left_parts <<< "$left"
  read -r -a right_parts <<< "$right"

  for idx in 0 1 2; do
    local left_segment="${left_parts[$idx]:-0}"
    local right_segment="${right_parts[$idx]:-0}"
    left_segment="$(sanitize_version_segment "$left_segment")"
    right_segment="$(sanitize_version_segment "$right_segment")"

    if (( 10#$left_segment > 10#$right_segment )); then
      echo 1
      return 0
    fi
    if (( 10#$left_segment < 10#$right_segment )); then
      echo -1
      return 0
    fi
  done

  echo 0
}

emit_preset_report() {
  local status="$1"
  local preset_id="$2"
  local registry_file="$3"
  local source_manifest="$4"
  local expected="$5"
  local actual="$6"
  local details="$7"
  local relation="$8"

  if [[ "$OUTPUT_JSON" == "true" ]]; then
    local mismatches_json='[]'
    local warnings_json='[]'

    case "$relation" in
      older)
        mismatches_json="$(jq -cn --arg file ".specify/presets/.registry" --arg expected "$expected" --arg actual "$actual" '[{file:$file, expected:$expected, actual:$actual}]')"
        ;;
      newer)
        warnings_json="$(jq -cn --arg file ".specify/presets/.registry" --arg expected "$expected" --arg actual "$actual" --arg message "$details" '[{file:$file, expected:$expected, actual:$actual, message:$message}]')"
        ;;
    esac

    jq -cn \
      --arg status "$status" \
      --arg preset "$preset_id" \
      --arg registry_file "$registry_file" \
      --arg source_manifest "$source_manifest" \
      --arg expected "$expected" \
      --arg actual "$actual" \
      --arg details "$details" \
      --argjson mismatches "$mismatches_json" \
      --argjson warnings "$warnings_json" \
      '{
        status: $status,
        preset: $preset,
        registry_file: $registry_file,
        source_manifest: $source_manifest,
        expected_version: (if $expected == "" then null else $expected end),
        actual_version: (if $actual == "" then null else $actual end),
        mismatches: $mismatches,
        warnings: $warnings,
        details: $details
      }'
    return 0
  fi

  case "$status" in
    ok)
      echo "OK: preset $preset_id is synchronized at version $expected."
      ;;
    warn)
      echo "WARN: $details" >&2
      ;;
    mismatch|error)
      echo "ERROR: $details" >&2
      ;;
  esac
}

detect_preset_version_mismatch() {
  local repo_root source_root registry_file preset_id source_manifest expected_version actual_version compare_result
  repo_root="$(normalize_repo_root "${1:-$(pwd)}")"
  source_root="$(normalize_repo_root "${2:-$repo_root}")"
  registry_file="$(registry_file_for_repo "$repo_root")"
  preset_id="$(extract_installed_preset_id "$repo_root")"

  if [[ ! -d "$repo_root/.specify" ]]; then
    emit_preset_report "error" "$preset_id" "$registry_file" "" "" "" "Diretório .specify ausente em $repo_root." ""
    return 1
  fi

  if [[ -z "$preset_id" ]]; then
    emit_preset_report "error" "$preset_id" "$registry_file" "" "" "" "Não foi possível determinar qual preset está instalado neste repositório." ""
    return 1
  fi

  source_manifest="$(preset_manifest_for_source "$source_root" "$preset_id")"
  if [[ ! -f "$source_manifest" ]]; then
    emit_preset_report "error" "$preset_id" "$registry_file" "$source_manifest" "" "" "Manifesto de origem não encontrado em $source_manifest." ""
    return 1
  fi

  expected_version="$(extract_version_from_preset_manifest "$source_manifest")"
  if [[ -z "$expected_version" ]]; then
    emit_preset_report "error" "$preset_id" "$registry_file" "$source_manifest" "" "" "Não foi possível extrair a versão declarada em $source_manifest." ""
    return 1
  fi

  if [[ ! -f "$registry_file" ]]; then
    emit_preset_report "error" "$preset_id" "$registry_file" "$source_manifest" "$expected_version" "" "Arquivo .specify/presets/.registry ausente em $repo_root." ""
    return 1
  fi

  actual_version="$(extract_registry_value "$registry_file" "$preset_id" version)"
  if [[ -z "$actual_version" ]]; then
    emit_preset_report "error" "$preset_id" "$registry_file" "$source_manifest" "$expected_version" "" "Não foi possível extrair a versão instalada do preset a partir de .specify/presets/.registry." ""
    return 1
  fi

  compare_result="$(compare_semver_versions "$actual_version" "$expected_version")"
  case "$compare_result" in
    0)
      emit_preset_report "ok" "$preset_id" "$registry_file" "$source_manifest" "$expected_version" "$actual_version" "Preset sincronizado." "equal"
      return 0
      ;;
    -1)
      emit_preset_report "mismatch" "$preset_id" "$registry_file" "$source_manifest" "$expected_version" "$actual_version" "Preset instalado está defasado: esperado $expected_version, atual $actual_version." "older"
      return 1
      ;;
    1)
      emit_preset_report "warn" "$preset_id" "$registry_file" "$source_manifest" "$expected_version" "$actual_version" "Preset instalado está à frente da origem declarada: esperado $expected_version, atual $actual_version." "newer"
      return 0
      ;;
  esac

  emit_preset_report "error" "$preset_id" "$registry_file" "$source_manifest" "$expected_version" "$actual_version" "Não foi possível comparar as versões do preset." ""
  return 1
}

snapshot_installed_project_root_templates() {
  local repo_root="$1"
  local preset_id="$2"
  local installed_root="$repo_root/.specify/presets/$preset_id/templates/project-root"
  local snapshot_root="$repo_root/.nimbus/preset-refresh-cache/$preset_id"

  rm -rf "$snapshot_root"

  if [[ -d "$installed_root" ]]; then
    mkdir -p "$(dirname "$snapshot_root")"
    cp -R "$installed_root" "$snapshot_root"
    printf '%s' "$snapshot_root"
    return 0
  fi

  printf ''
}

refresh_managed_project_root_files() {
  local repo_root="$1"
  local source_root="$2"
  local preset_id="$3"
  local snapshot_root="$4"
  local template_root="$source_root/presets/$preset_id/templates/project-root"

  [[ -d "$template_root" ]] || return 0

  while IFS= read -r -d '' src_file; do
    local rel_path="${src_file#"$template_root"/}"
    local dest_rel
    local dest_file
    local snapshot_file=""

    dest_rel="$(project_root_destination_for_template "$rel_path")"
    dest_file="$repo_root/$dest_rel"

    if [[ -n "$snapshot_root" ]]; then
      snapshot_file="$snapshot_root/$rel_path"
    fi

    if [[ ! -f "$dest_file" ]]; then
      mkdir -p "$(dirname "$dest_file")"
      cp -p "$src_file" "$dest_file"
      echo "  OK: $dest_rel refreshed (file was missing)."
      continue
    fi

    if [[ -n "$snapshot_file" && -f "$snapshot_file" ]] && cmp -s "$dest_file" "$snapshot_file"; then
      cp -p "$src_file" "$dest_file"
      echo "  OK: $dest_rel refreshed from preset source."
      continue
    fi

    if cmp -s "$dest_file" "$src_file"; then
      echo "  INFO: $dest_rel already matches the current preset source."
      continue
    fi

    echo "  WARN: $dest_rel has local customizations and was not overwritten during preset refresh."
  done < <(find "$template_root" -type f -print0)
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
    --refresh-preset)
      BOOTSTRAP_MODE="refresh"
      SKIP_BOOTSTRAP_SIDE_EFFECTS="true"
      shift
      ;;
    --detect-preset-version-mismatch)
      BOOTSTRAP_MODE="detect"
      shift
      ;;
    --repo-root)
      [[ $# -ge 2 && -n "$2" ]] || { echo "ERROR: --repo-root requires a path." >&2; exit 1; }
      TARGET_REPO_ROOT="$2"
      shift 2
      ;;
    --source-root)
      [[ $# -ge 2 && -n "$2" ]] || { echo "ERROR: --source-root requires a path." >&2; exit 1; }
      SOURCE_REPO_ROOT="$2"
      shift 2
      ;;
    --json)
      OUTPUT_JSON="true"
      shift
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

if [[ "$BOOTSTRAP_MODE" == "detect" ]]; then
  detect_preset_version_mismatch "${TARGET_REPO_ROOT:-$(pwd)}" "${SOURCE_REPO_ROOT:-${LOCAL_PATH:-$(pwd)}}"
  exit $?
fi

if ! command -v specify >/dev/null 2>&1; then
  echo "ERROR: 'specify' CLI not found. Install it first: https://github.com/github/spec-kit" >&2
  exit 1
fi

WORKDIR="$(pwd)"

if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: python3 is required for preset registry and managed-file validation." >&2
  exit 1
fi

if [[ -z "$LOCAL_PATH" ]]; then
  TMP_CLONE="$WORKDIR/.nimbus/bootstrap-source-$$"
  trap 'rm -rf "$TMP_CLONE"' EXIT
  mkdir -p "$WORKDIR/.nimbus"
  rm -rf "$TMP_CLONE"
  echo "-> Cloning $STANDARDS_REPO at ref $NIMBUS_REF..."
  git clone --depth 1 --branch "$NIMBUS_REF" "$STANDARDS_REPO" "$TMP_CLONE" >/dev/null
  LOCAL_PATH="$TMP_CLONE"
elif [[ ! -d "$LOCAL_PATH" ]]; then
  echo "ERROR: local template path does not exist: $LOCAL_PATH" >&2
  exit 1
fi

if [[ "$BOOTSTRAP_MODE" == "refresh" && -z "$REPO_TYPE" ]]; then
  REPO_TYPE="$(load_repository_type_from_metadata "$WORKDIR")"
  if [[ -z "$REPO_TYPE" ]]; then
    case "$(extract_installed_preset_id "$WORKDIR")" in
      nimbus-code-platform-standards)
        REPO_TYPE="platform"
        ;;
      nimbus-code-standards)
        REPO_TYPE="dev_standards"
        ;;
    esac
  fi
fi
resolve_repo_type
SELECTED_PRESET="$(preset_for_repo_type "$REPO_TYPE")"

if [[ "$BOOTSTRAP_MODE" != "refresh" ]]; then
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
else
  echo "-> Refreshing preset files for $SELECTED_PRESET in $WORKDIR..."
fi

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
SOURCE_PRESET_MANIFEST="$LOCAL_PATH/presets/$SELECTED_PRESET/preset.yml"
SOURCE_PRESET_VERSION="$(extract_version_from_preset_manifest "$SOURCE_PRESET_MANIFEST")"
INSTALLED_REGISTRY="$(registry_file_for_repo "$WORKDIR")"
INSTALLED_PRESET_VERSION="$(extract_registry_value "$INSTALLED_REGISTRY" "$SELECTED_PRESET" version)"
PRESET_REINSTALLED="false"
PRESET_REFRESH_SNAPSHOT_DIR=""

if [[ "$BOOTSTRAP_MODE" == "refresh" ]]; then
  if [[ ! -f "$WORKDIR/.specify/presets/.registry" ]]; then
    echo "ERROR: Refresh requires an initialized repository and preset registry." >&2
    exit 1
  fi
  python3 "$LOCAL_PATH/scripts/sync-bundle-artifacts.py" \
    --bundle "$LOCAL_PATH" --target "$WORKDIR" --preset "$SELECTED_PRESET" --check
fi

if [[ "$BOOTSTRAP_MODE" == "refresh" ]]; then
  PRESET_REFRESH_SNAPSHOT_DIR="$(snapshot_installed_project_root_templates "$WORKDIR" "$SELECTED_PRESET")"
  if [[ -n "$INSTALLED_PRESET_VERSION" ]] || component_is_installed preset "$SELECTED_PRESET"; then
    echo "  Refresh mode requested - reinstalling preset $SELECTED_PRESET from source."
    specify preset remove "$SELECTED_PRESET"
  fi
  PRESET_REINSTALLED="true"
elif [[ -n "$INSTALLED_PRESET_VERSION" && -n "$SOURCE_PRESET_VERSION" ]]; then
  case "$(compare_semver_versions "$INSTALLED_PRESET_VERSION" "$SOURCE_PRESET_VERSION")" in
    -1)
      echo "  Installed preset version ($INSTALLED_PRESET_VERSION) is older than source ($SOURCE_PRESET_VERSION) - upgrading..."
      PRESET_REFRESH_SNAPSHOT_DIR="$(snapshot_installed_project_root_templates "$WORKDIR" "$SELECTED_PRESET")"
      if ! specify preset remove "$SELECTED_PRESET"; then
        echo "ERROR: could not remove existing preset $SELECTED_PRESET before upgrade." >&2
        exit 1
      fi
      PRESET_REINSTALLED="true"
      ;;
    1)
      echo "  WARN: installed preset version ($INSTALLED_PRESET_VERSION) is newer than source ($SOURCE_PRESET_VERSION); skipping automatic downgrade."
      ;;
  esac
fi

install_component preset "$SELECTED_PRESET" "preset $SELECTED_PRESET" \
  specify preset add --dev "$LOCAL_PATH/presets/$SELECTED_PRESET" --priority 5

if [[ "$BOOTSTRAP_MODE" != "refresh" && "$REPO_TYPE" == "dev_standards" ]]; then
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

if [[ "$BOOTSTRAP_MODE" != "refresh" && "$REPO_TYPE" == "dev_standards" ]]; then
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

if [[ "$PRESET_REINSTALLED" == "true" ]]; then
  refresh_managed_project_root_files "$WORKDIR" "$LOCAL_PATH" "$SELECTED_PRESET" "$PRESET_REFRESH_SNAPSHOT_DIR"
  if [[ -n "$PRESET_REFRESH_SNAPSHOT_DIR" ]]; then
    rm -rf "$PRESET_REFRESH_SNAPSHOT_DIR"
  fi
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
python3 "$LOCAL_PATH/scripts/sync-bundle-artifacts.py" \
  --bundle "$LOCAL_PATH" --target "$WORKDIR" --preset "$SELECTED_PRESET" --initialize

if [[ -f "$WORKDIR/scripts/sync-nc-agents-to-integrations.sh" ]]; then
  case "$INTEGRATION" in
    claude)
      echo "-> Synchronizing NC agents for Claude Code integration..."
      bash "$WORKDIR/scripts/sync-nc-agents-to-integrations.sh" --target claude || true
      ;;
    antigravity|agy)
      echo "-> Synchronizing NC agents for Antigravity integration..."
      bash "$WORKDIR/scripts/sync-nc-agents-to-integrations.sh" --target antigravity || true
      ;;
    cursor-agent|cursor)
      echo "-> Synchronizing NC agents for Cursor integration..."
      bash "$WORKDIR/scripts/sync-nc-agents-to-integrations.sh" --target cursor || true
      ;;
    kiro-cli|kiro)
      echo "-> Synchronizing NC agents for Kiro integration..."
      bash "$WORKDIR/scripts/sync-nc-agents-to-integrations.sh" --target kiro || true
      ;;
    all)
      echo "-> Synchronizing NC agents for all integrations..."
      bash "$WORKDIR/scripts/sync-nc-agents-to-integrations.sh" --target all || true
      ;;
  esac
fi

echo
echo "OK: bundle $BUNDLE_ID v${BUNDLE_VERSION} applied."
echo "OK: preset installed: $SELECTED_PRESET (repository type: $REPO_TYPE)"
if [[ "$BOOTSTRAP_MODE" != "refresh" ]]; then
  echo "OK: repository classified as $DETECTED_CONTEXT (reason: $CONTEXT_INDICATOR)"
  if [[ "${DETECTED_CONTEXT:-}" == "greenfield" ]]; then
    echo "OK: topology decision recorded: $DELIVERY_MODEL (owner: $DECISION_OWNER)"
    if [[ "$DELIVERY_MODEL" == "multirepo" ]]; then
      echo "OK: suggested satellite domains: ${SATELLITE_DOMAINS:-FRONT,BACK,DESIGN,DATA,JOBS}"
    fi
  fi
fi

auto_assign_hint() {
  echo "  INFO: to enable auto-assign, configure NIMBUS_APP_ID/NIMBUS_APP_PRIVATE_KEY; COPILOT_AGENT_ASSIGN_TOKEN remains a temporary fallback during rollout."
}

if [[ "$SKIP_BOOTSTRAP_SIDE_EFFECTS" != "true" && "$REPO_TYPE" == "dev_standards" ]] && command -v gh >/dev/null 2>&1; then
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
if [[ "$SKIP_BOOTSTRAP_SIDE_EFFECTS" != "true" && "$REPO_TYPE" == "dev_standards" ]]; then
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
if [[ "$BOOTSTRAP_MODE" == "refresh" ]]; then
  echo "OK: preset refresh complete."
  echo ""
  echo "Next steps:"
  echo "  1. Revise os arquivos atualizados e os avisos de customizações preservadas."
  echo "  2. Rode ./scripts/validate-versions.sh se este repositório já expõe esse script."
  echo "  3. Abra um PR com a label sync:preset-version para revisar a sincronização."
else
  echo "✅ Bootstrap complete!"
  echo ""
  echo "Next steps:"
  echo "  1. Review docs/version-synchronization.md for version management"
  echo "  2. Run: ./scripts/validate-versions.sh to verify all versions are synced"
  echo "  3. If this is the Repo Central, create/update specs/<feature>/spec.md there; if this is a satellite repo, keep specs only in the product central repo and route code tasks here."
fi
