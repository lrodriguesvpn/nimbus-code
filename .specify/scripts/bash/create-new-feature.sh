#!/usr/bin/env bash

set -e

JSON_MODE=false
DRY_RUN=false
ALLOW_EXISTING=false
SHORT_NAME=""
BRANCH_NUMBER=""
USE_TIMESTAMP=false
NUMBER_EXPLICIT=false
BOUNDED_CONTEXTS_INPUT=""
EPIC_ISSUE_INPUT=""
ARGS=()
i=1
while [ $i -le $# ]; do
    arg="${!i}"
    case "$arg" in
        --json)
            JSON_MODE=true
            ;;
        --dry-run)
            DRY_RUN=true
            ;;
        --allow-existing-branch)
            ALLOW_EXISTING=true
            ;;
        --short-name)
            if [ $((i + 1)) -gt $# ]; then
                echo 'Error: --short-name requires a value' >&2
                exit 1
            fi
            i=$((i + 1))
            next_arg="${!i}"
            # Check if the next argument is another option (starts with --)
            if [[ "$next_arg" == --* ]]; then
                echo 'Error: --short-name requires a value' >&2
                exit 1
            fi
            SHORT_NAME="$next_arg"
            ;;
        --number)
            if [ $((i + 1)) -gt $# ]; then
                echo 'Error: --number requires a value' >&2
                exit 1
            fi
            i=$((i + 1))
            next_arg="${!i}"
            if [[ "$next_arg" == --* ]]; then
                echo 'Error: --number requires a value' >&2
                exit 1
            fi
            BRANCH_NUMBER="$next_arg"
            if [ -n "$BRANCH_NUMBER" ]; then
                NUMBER_EXPLICIT=true
            fi
            ;;
        --timestamp)
            USE_TIMESTAMP=true
            ;;
        --bounded-contexts)
            if [ $((i + 1)) -gt $# ]; then
                echo 'Error: --bounded-contexts requires a value (comma-separated slugs)' >&2
                exit 1
            fi
            i=$((i + 1))
            next_arg="${!i}"
            if [[ "$next_arg" == --* ]]; then
                echo 'Error: --bounded-contexts requires a value (comma-separated slugs)' >&2
                exit 1
            fi
            BOUNDED_CONTEXTS_INPUT="$next_arg"
            ;;
        --epic-issue)
            if [ $((i + 1)) -gt $# ]; then
                echo 'Error: --epic-issue requires a value (GHE Epic issue number)' >&2
                exit 1
            fi
            i=$((i + 1))
            next_arg="${!i}"
            if [[ "$next_arg" == --* ]]; then
                echo 'Error: --epic-issue requires a value (GHE Epic issue number)' >&2
                exit 1
            fi
            EPIC_ISSUE_INPUT="$next_arg"
            ;;
        --help|-h)
            echo "Usage: $0 [--json] [--dry-run] [--allow-existing-branch] [--short-name <name>] [--number N] [--timestamp] [--bounded-contexts <slug1,slug2>] [--epic-issue N] <feature_description>"
            echo ""
            echo "Options:"
            echo "  --json                      Output in JSON format"
            echo "  --dry-run                   Compute feature name and paths without creating directories or files"
            echo "  --allow-existing-branch     Reuse an existing feature directory if it already exists"
            echo "  --short-name <name>         Provide a custom short name (2-4 words) for the feature"
            echo "  --number N                  Prefer a feature number (auto-corrected if its specs prefix exists)"
            echo "  --timestamp                 Use timestamp prefix (YYYYMMDD-HHMMSS) instead of sequential numbering"
            echo "  --bounded-contexts <slugs>  Comma-separated bounded context slugs for multi-repo features."
            echo "                              Slugs are resolved to repositories via docs/bounded-contexts.yaml."
            echo "                              Persisted in .specify/feature.json as bounded_contexts and repos."
            echo "  --epic-issue N              Optional GHE Epic issue number this feature belongs to."
            echo "                              Persisted in .specify/feature.json as epic_issue for use by"
            echo "                              /speckit-taskstoissues (see docs/developer-guide.md, seção 4)."
            echo "  --help, -h                  Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 'Add user authentication system' --short-name 'user-auth'"
            echo "  $0 'Implement OAuth2 integration for API' --number 5"
            echo "  $0 --timestamp --short-name 'user-auth' 'Add user authentication'"
            echo "  $0 'Order checkout flow' --bounded-contexts 'order-management,billing'"
            echo "  $0 'Checkout flow' --epic-issue 42"
            exit 0
            ;;
        *)
            ARGS+=("$arg")
            ;;
    esac
    i=$((i + 1))
done

FEATURE_DESCRIPTION="${ARGS[*]}"
if [ -z "$FEATURE_DESCRIPTION" ]; then
    echo "Usage: $0 [--json] [--dry-run] [--allow-existing-branch] [--short-name <name>] [--number N] [--timestamp] <feature_description>" >&2
    exit 1
fi

# Trim whitespace and validate description is not empty (e.g., user passed only whitespace)
FEATURE_DESCRIPTION=$(echo "$FEATURE_DESCRIPTION" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')
if [ -z "$FEATURE_DESCRIPTION" ]; then
    echo "Error: Feature description cannot be empty or contain only whitespace" >&2
    exit 1
fi

# Auto-detect an inline EPIC_ISSUE=<N> token inside the free-text description
# (specs/005-epic-feature-us-ghe-hierarchy — Camada 1 of the reliability fix).
# This is a deterministic fallback so epic_issue gets persisted even when the
# caller (e.g. an LLM-driven skill) forwards the raw description untouched
# instead of extracting --epic-issue itself. The explicit --epic-issue flag
# always wins if both are present and disagree (with a warning).
INLINE_EPIC_ISSUE=$(printf '%s' "$FEATURE_DESCRIPTION" | grep -ioE 'EPIC_ISSUE[[:space:]]*=[[:space:]]*[0-9]+' | head -1 | grep -oE '[0-9]+$' || true)
if [ -n "$INLINE_EPIC_ISSUE" ]; then
    # Strip the token from the description so it never leaks into the slug,
    # short name, or spec content.
    FEATURE_DESCRIPTION=$(printf '%s' "$FEATURE_DESCRIPTION" | sed -E 's/EPIC_ISSUE[[:space:]]*=[[:space:]]*[0-9]+//gi' | sed -E 's/^[[:space:]]+|[[:space:]]+$//g' | sed -E 's/[[:space:]]+/ /g')
    if [ -z "$EPIC_ISSUE_INPUT" ]; then
        EPIC_ISSUE_INPUT="$INLINE_EPIC_ISSUE"
    elif [ "$EPIC_ISSUE_INPUT" != "$INLINE_EPIC_ISSUE" ]; then
        echo "[specify] Warning: --epic-issue $EPIC_ISSUE_INPUT conflicts with inline EPIC_ISSUE=$INLINE_EPIC_ISSUE found in the description; using --epic-issue $EPIC_ISSUE_INPUT" >&2
    fi
fi

if [ -z "$FEATURE_DESCRIPTION" ]; then
    echo "Error: Feature description cannot be empty or contain only whitespace after removing EPIC_ISSUE=<N>" >&2
    exit 1
fi

MAX_FEATURE_NUMBER=9223372036854775807
MAX_BRANCH_LENGTH=244

is_feature_number_in_range() {
    local value="$1"
    local normalized="${value#"${value%%[!0]*}"}"
    [ -n "$normalized" ] || normalized=0
    [ ${#normalized} -lt ${#MAX_FEATURE_NUMBER} ] && return 0
    [ ${#normalized} -gt ${#MAX_FEATURE_NUMBER} ] && return 1
    # Equal-length digit strings must be compared without arithmetic overflow.
    # shellcheck disable=SC2071
    [[ "$normalized" < "$MAX_FEATURE_NUMBER" || "$normalized" == "$MAX_FEATURE_NUMBER" ]]
}

# Function to get highest number from specs directory
get_highest_from_specs() {
    local specs_dir="$1"
    local highest=0

    if [ -d "$specs_dir" ]; then
        for dir in "$specs_dir"/*; do
            [ -d "$dir" ] || continue
            dirname=$(basename "$dir")
            # Match sequential prefixes (>=3 digits), but skip timestamp dirs.
            if echo "$dirname" | grep -Eq '^[0-9]{3,}-' && ! echo "$dirname" | grep -Eq '^[0-9]{8}-[0-9]{6}-'; then
                number=$(echo "$dirname" | grep -Eo '^[0-9]+')
                if is_feature_number_in_range "$number"; then
                    number=$((10#$number))
                    if [ "$number" -gt "$highest" ]; then
                        highest=$number
                    fi
                fi
            fi
        done
    fi

    echo "$highest"
}

# Return success when a spec directory owns the given numeric prefix.
spec_prefix_exists() {
    local specs_dir="$1"
    local feature_num="$2"

    for spec_path in "$specs_dir/${feature_num}-"*; do
        [ -d "$spec_path" ] && return 0
    done
    return 1
}

# Function to clean and format a branch name
clean_branch_name() {
    local name="$1"
    echo "$name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^-//' | sed 's/-$//'
}

# Fit a feature prefix and suffix within GitHub's branch-name limit.
fit_branch_name() {
    local feature_num="$1"
    local branch_suffix="$2"
    local branch_name="${feature_num}-${branch_suffix}"

    if [ ${#branch_name} -gt $MAX_BRANCH_LENGTH ]; then
        local prefix_length=$(( ${#feature_num} + 1 ))
        local max_suffix_length=$((MAX_BRANCH_LENGTH - prefix_length))
        local truncated_suffix
        truncated_suffix=$(printf '%s' "$branch_suffix" | cut -c "1-$max_suffix_length" | sed 's/-$//')
        branch_name="${feature_num}-${truncated_suffix}"
    fi

    printf '%s' "$branch_name"
}

# Quote a value for POSIX shell reuse, byte-identical to Python's shlex.quote
# so the persistence hints match the Python variant exactly (printf %q output
# differs between bash versions and from shlex.quote for spaces/metachars).
shell_quote() {
    local value="$1" LC_ALL=C
    if [[ "$value" =~ ^[A-Za-z0-9_@%+=:,./-]+$ ]]; then
        printf '%s' "$value"
    else
        local q="'\"'\"'"
        printf "'%s'" "${value//\'/$q}"
    fi
}

# Resolve repository root using common.sh functions which prioritize .specify
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

REPO_ROOT=$(get_repo_root) || exit 1

cd "$REPO_ROOT"

# ---------------------------------------------------------------------------
# MultiRepo: parse bounded-contexts.yaml and resolve slugs → repos
# ---------------------------------------------------------------------------
# Path to the project's bounded-contexts registry
BOUNDED_CONTEXTS_FILE="$REPO_ROOT/docs/bounded-contexts.yaml"

# Parse YAML using yq (preferred), python3 -c (fallback), or grep/awk (minimal)
_yaml_parse_tool() {
    if command -v yq >/dev/null 2>&1; then
        echo "yq"
    elif python3 -c "import yaml" 2>/dev/null; then
        echo "python3"
    else
        echo "grep"
    fi
}

# Resolve a single bounded context slug to its repository (org/repo).
# Returns empty string if not found; prints warning to stderr.
_resolve_bc_slug_to_repo() {
    local slug="$1"
    local bc_file="$2"
    local tool
    tool=$(_yaml_parse_tool)

    case "$tool" in
        yq)
            yq e ".contexts[] | select(.slug == \"$slug\") | .repository" "$bc_file" 2>/dev/null | grep -v '^null$' | head -1
            ;;
        python3)
            python3 - "$bc_file" "$slug" <<'PYEOF'
import sys, yaml
bc_file, slug = sys.argv[1], sys.argv[2]
with open(bc_file) as f:
    data = yaml.safe_load(f) or {}
contexts = data.get("contexts") or []
for ctx in contexts:
    if isinstance(ctx, dict) and ctx.get("slug") == slug:
        print(ctx.get("repository", ""))
        break
PYEOF
            ;;
        grep)
            # Minimal fallback: assumes slug and repository appear in consecutive lines
            awk -v slug="$slug" '
                /slug:/ && $0 ~ "\"?" slug "\"?" { found=1; next }
                found && /repository:/ { gsub(/.*repository:[[:space:]]*"?/, ""); gsub(/".*/, ""); print; exit }
                found && /slug:/ { exit }
            ' "$bc_file"
            ;;
    esac
}

# Check whether autonomous_ok is true for a slug.
_bc_autonomous_ok() {
    local slug="$1"
    local bc_file="$2"
    local tool
    tool=$(_yaml_parse_tool)

    case "$tool" in
        yq)
            yq e ".contexts[] | select(.slug == \"$slug\") | .autonomous_ok" "$bc_file" 2>/dev/null | grep -v '^null$' | head -1
            ;;
        python3)
            python3 - "$bc_file" "$slug" <<'PYEOF'
import sys, yaml
bc_file, slug = sys.argv[1], sys.argv[2]
with open(bc_file) as f:
    data = yaml.safe_load(f) or {}
contexts = data.get("contexts") or []
for ctx in contexts:
    if isinstance(ctx, dict) and ctx.get("slug") == slug:
        print(str(ctx.get("autonomous_ok", True)).lower())
        break
PYEOF
            ;;
        grep)
            # Best-effort; assumes autonomous_ok follows slug within a few lines
            awk -v slug="$slug" '
                /slug:/ && $0 ~ "\"?" slug "\"?" { found=1; next }
                found && /autonomous_ok:/ { gsub(/.*autonomous_ok:[[:space:]]*/, ""); gsub(/"/, ""); print; exit }
                found && /slug:/ { exit }
            ' "$bc_file"
            ;;
    esac
}

# List all valid slugs from bounded-contexts.yaml
_list_bc_slugs() {
    local bc_file="$1"
    local tool
    tool=$(_yaml_parse_tool)

    case "$tool" in
        yq)
            yq e ".contexts[].slug" "$bc_file" 2>/dev/null | grep -v '^null$'
            ;;
        python3)
            python3 - "$bc_file" <<'PYEOF'
import sys, yaml
with open(sys.argv[1]) as f:
    data = yaml.safe_load(f) or {}
contexts = data.get("contexts") or []
for ctx in contexts:
    if isinstance(ctx, dict) and ctx.get("slug"):
        print(ctx["slug"])
PYEOF
            ;;
        grep)
            grep -E '^\s+slug:' "$bc_file" | sed 's/.*slug:[[:space:]]*"*//; s/"*[[:space:]]*$//'
            ;;
    esac
}

# Resolve the --bounded-contexts input to parallel arrays of slugs and repos.
# Sets RESOLVED_SLUGS_JSON and RESOLVED_REPOS_JSON (JSON arrays as strings).
RESOLVED_SLUGS_JSON="[]"
RESOLVED_REPOS_JSON="[]"

if [ -n "$BOUNDED_CONTEXTS_INPUT" ]; then
    if [ ! -f "$BOUNDED_CONTEXTS_FILE" ]; then
        echo "Error: --bounded-contexts requires docs/bounded-contexts.yaml to exist." >&2
        echo "       Create it first (see .specify/presets/.../templates/project-root/bounded-contexts.yaml)." >&2
        exit 1
    fi

    if command -v yq >/dev/null 2>&1; then
        true  # preferred tool available
    elif python3 -c "import yaml" 2>/dev/null; then
        echo "[specify] Info: yq not found — using python3 to parse bounded-contexts.yaml" >&2
    else
        echo "[specify] Warning: neither yq nor python3+yaml available. Using grep/awk fallback (limited)." >&2
        echo "          Install yq (brew install yq / snap install yq) for reliable YAML parsing." >&2
    fi

    VALID_SLUGS=$(_list_bc_slugs "$BOUNDED_CONTEXTS_FILE")

    resolved_slugs=()
    resolved_repos=()

    IFS=',' read -ra INPUT_SLUGS <<< "$BOUNDED_CONTEXTS_INPUT"
    for raw_slug in "${INPUT_SLUGS[@]}"; do
        slug=$(echo "$raw_slug" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')
        [ -z "$slug" ] && continue

        repo=$(_resolve_bc_slug_to_repo "$slug" "$BOUNDED_CONTEXTS_FILE")

        if [ -z "$repo" ]; then
            echo "Error: bounded context slug '$slug' not found in docs/bounded-contexts.yaml." >&2
            echo "       Valid slugs:" >&2
            while IFS= read -r valid_slug; do
                echo "         - $valid_slug" >&2
            done <<< "$VALID_SLUGS"
            exit 1
        fi

        resolved_slugs+=("$slug")
        resolved_repos+=("$repo")
    done

    # Build JSON arrays
    if command -v jq >/dev/null 2>&1; then
        slugs_json=$(printf '%s\n' "${resolved_slugs[@]}" | jq -R . | jq -s .)
        repos_json=$(printf '%s\n' "${resolved_repos[@]}" | jq -R . | jq -s .)
    else
        # Manual JSON array construction (no jq)
        slugs_json="["
        repos_json="["
        first=true
        for idx in "${!resolved_slugs[@]}"; do
            $first || { slugs_json+=","; repos_json+=","; }
            first=false
            slugs_json+="\"${resolved_slugs[$idx]}\""
            repos_json+="\"${resolved_repos[$idx]}\""
        done
        slugs_json+="]"
        repos_json+="]"
    fi

    RESOLVED_SLUGS_JSON="$slugs_json"
    RESOLVED_REPOS_JSON="$repos_json"
fi
# ---------------------------------------------------------------------------

# Validate --epic-issue: must be a positive integer (a GHE issue number).
# Persisted as epic_issue in feature.json for /speckit-taskstoissues to read
# when creating the Feature issue as a sub-issue of this Epic
# (specs/005-epic-feature-us-ghe-hierarchy).
if [ -n "$EPIC_ISSUE_INPUT" ]; then
    if ! [[ "$EPIC_ISSUE_INPUT" =~ ^[0-9]+$ ]] || [ "$EPIC_ISSUE_INPUT" -eq 0 ]; then
        echo "Error: --epic-issue must be a positive integer (GHE issue number), got '$EPIC_ISSUE_INPUT'" >&2
        exit 1
    fi
fi
# ---------------------------------------------------------------------------

SPECS_DIR="$REPO_ROOT/specs"
if [ "$DRY_RUN" != true ]; then
    mkdir -p "$SPECS_DIR"
fi

# Function to generate branch name with stop word filtering and length filtering
generate_branch_name() {
    local description="$1"

    # Common stop words to filter out
    local stop_words="^(i|a|an|the|to|for|of|in|on|at|by|with|from|is|are|was|were|be|been|being|have|has|had|do|does|did|will|would|should|could|can|may|might|must|shall|this|that|these|those|my|your|our|their|want|need|add|get|set)$"

    # Convert to lowercase and split into words
    local clean_name=$(printf '%s' "$description" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/ /g')

    # Filter words: remove stop words and words shorter than 3 chars (unless they're uppercase acronyms in original)
    local meaningful_words=()
    for word in $clean_name; do
        # Skip empty words
        [ -z "$word" ] && continue

        # Keep words that are NOT stop words AND (length >= 3 OR are potential acronyms)
        if ! echo "$word" | grep -qiE "$stop_words"; then
            if [ ${#word} -ge 3 ]; then
                meaningful_words+=("$word")
            # Keep short words that appear as an uppercase acronym in the original.
            # Uppercase via tr and match with grep -w (both portable) rather than
            # bash's 4+ "^^" case expansion (breaks on macOS bash 3.2) and \b (non-POSIX).
            elif printf '%s' "$description" | grep -qw -- "$(printf '%s' "$word" | tr '[:lower:]' '[:upper:]')"; then
                meaningful_words+=("$word")
            fi
        fi
    done

    # If we have meaningful words, use first 3-4 of them
    if [ ${#meaningful_words[@]} -gt 0 ]; then
        local max_words=3
        if [ ${#meaningful_words[@]} -eq 4 ]; then max_words=4; fi

        local result=""
        local count=0
        for word in "${meaningful_words[@]}"; do
            if [ $count -ge $max_words ]; then break; fi
            if [ -n "$result" ]; then result="$result-"; fi
            result="$result$word"
            count=$((count + 1))
        done
        echo "$result"
    else
        # Fallback to original logic if no meaningful words found
        local cleaned=$(clean_branch_name "$description")
        echo "$cleaned" | tr '-' '\n' | grep -v '^$' | head -3 | tr '\n' '-' | sed 's/-$//'
    fi
}

# Generate branch name
if [ -n "$SHORT_NAME" ]; then
    # Use provided short name, just clean it up
    BRANCH_SUFFIX=$(clean_branch_name "$SHORT_NAME")
else
    # Generate from description with smart filtering
    BRANCH_SUFFIX=$(generate_branch_name "$FEATURE_DESCRIPTION")
fi

# Warn if --number and --timestamp are both specified
if [ "$USE_TIMESTAMP" = true ] && [ -n "$BRANCH_NUMBER" ]; then
    >&2 echo "[specify] Warning: --number is ignored when --timestamp is used"
    BRANCH_NUMBER=""
fi

# Determine branch prefix
if [ "$USE_TIMESTAMP" = true ]; then
    FEATURE_NUM=$(date +%Y%m%d-%H%M%S)
    BRANCH_NAME="${FEATURE_NUM}-${BRANCH_SUFFIX}"
else
    if [ -n "$BRANCH_NUMBER" ] && [[ ! "$BRANCH_NUMBER" =~ ^[0-9]+$ ]]; then
        echo "Error: --number must be an unsigned integer, got '$BRANCH_NUMBER'" >&2
        exit 1
    fi

    # Bash arithmetic is signed 64-bit; reject digit strings that would wrap.
    if [ -n "$BRANCH_NUMBER" ] && ! is_feature_number_in_range "$BRANCH_NUMBER"; then
        echo "Error: --number must be between 0 and $MAX_FEATURE_NUMBER, got '$BRANCH_NUMBER'" >&2
        exit 1
    fi

    # Determine branch number from existing feature directories
    if [ -z "$BRANCH_NUMBER" ]; then
        HIGHEST=$(get_highest_from_specs "$SPECS_DIR")
        if [ "$HIGHEST" -eq "$MAX_FEATURE_NUMBER" ]; then
            echo "Error: feature number must be between 0 and $MAX_FEATURE_NUMBER, got '9223372036854775808'" >&2
            exit 1
        fi
        BRANCH_NUMBER=$((HIGHEST + 1))
    fi

    # Force base-10 interpretation to prevent octal conversion (e.g., 010 → 8 in octal, but should be 10 in decimal)
    FEATURE_NUM=$(printf "%03d" "$((10#$BRANCH_NUMBER))")

    # Treat an explicit number as a preference when its prefix is already used
    # by a feature directory. Auto-detected numbers are already conflict-free.
    if [ "$NUMBER_EXPLICIT" = true ]; then
        SPEC_CONFLICT=false
        REQUESTED_BRANCH_NAME=$(fit_branch_name "$FEATURE_NUM" "$BRANCH_SUFFIX")
        REQUESTED_DIR="$SPECS_DIR/$REQUESTED_BRANCH_NAME"
        if [ "$ALLOW_EXISTING" != true ] || [ ! -d "$REQUESTED_DIR" ]; then
            spec_prefix_exists "$SPECS_DIR" "$FEATURE_NUM" && SPEC_CONFLICT=true
        fi

        if [ "$SPEC_CONFLICT" = true ]; then
            REQUESTED_NUM="$FEATURE_NUM"
            HIGHEST=$(get_highest_from_specs "$SPECS_DIR")
            BRANCH_NUMBER=$HIGHEST
            while true; do
                if [ "$BRANCH_NUMBER" -eq "$MAX_FEATURE_NUMBER" ]; then
                    echo "Error: feature number must be between 0 and $MAX_FEATURE_NUMBER, got '9223372036854775808'" >&2
                    exit 1
                fi
                BRANCH_NUMBER=$((BRANCH_NUMBER + 1))
                FEATURE_NUM=$(printf "%03d" "$((10#$BRANCH_NUMBER))")
                spec_prefix_exists "$SPECS_DIR" "$FEATURE_NUM" || break
            done
            >&2 echo "[specify] Warning: --number $REQUESTED_NUM conflicts with an existing spec directory; using $FEATURE_NUM instead"
        fi
    fi

fi

# GitHub enforces a 244-byte limit on branch names
# Validate and truncate if necessary
ORIGINAL_BRANCH_NAME="${FEATURE_NUM}-${BRANCH_SUFFIX}"
BRANCH_NAME=$(fit_branch_name "$FEATURE_NUM" "$BRANCH_SUFFIX")
if [ "$BRANCH_NAME" != "$ORIGINAL_BRANCH_NAME" ]; then
    >&2 echo "[specify] Warning: Branch name exceeded GitHub's 244-byte limit"
    >&2 echo "[specify] Original: $ORIGINAL_BRANCH_NAME (${#ORIGINAL_BRANCH_NAME} bytes)"
    >&2 echo "[specify] Truncated to: $BRANCH_NAME (${#BRANCH_NAME} bytes)"
fi

FEATURE_DIR="$SPECS_DIR/$BRANCH_NAME"
SPEC_FILE="$FEATURE_DIR/spec.md"

if [ "$DRY_RUN" != true ]; then
    if [ -d "$FEATURE_DIR" ] && [ "$ALLOW_EXISTING" != true ]; then
        if [ "$USE_TIMESTAMP" = true ]; then
            >&2 echo "Error: Feature directory '$FEATURE_DIR' already exists. Rerun to get a new timestamp or use a different --short-name."
        else
            >&2 echo "Error: Feature directory '$FEATURE_DIR' already exists. Please use a different feature name or specify a different number with --number."
        fi
        exit 1
    fi

    mkdir -p "$FEATURE_DIR"

    # Materialize the composed spec template once for this feature.
    if [ ! -f "$SPEC_FILE" ]; then
        if materialize_template_content "spec-template" "$REPO_ROOT" "$SPEC_FILE"; then
            if $JSON_MODE; then
                echo "Materialized composed spec template to $SPEC_FILE" >&2
            else
                echo "Materialized composed spec template to $SPEC_FILE"
            fi
        else
            if $JSON_MODE; then
                echo "Warning: Spec template not found; created empty spec file" >&2
            else
                echo "Warning: Spec template not found; created empty spec file"
            fi
            touch "$SPEC_FILE"
        fi
    fi

    # Persist to .specify/feature.json so downstream commands can find the feature
    _persist_feature_json "$REPO_ROOT" "$FEATURE_DIR"

    # Merge bounded_contexts and repos into feature.json (MultiRepo support)
    # + epic_issue when --epic-issue was provided (specs/005-epic-feature-us-ghe-hierarchy)
    _fj="$REPO_ROOT/.specify/feature.json"
    if command -v jq >/dev/null 2>&1; then
        _fj_tmp=$(jq \
            --argjson bc "$RESOLVED_SLUGS_JSON" \
            --argjson repos "$RESOLVED_REPOS_JSON" \
            --arg epic "$EPIC_ISSUE_INPUT" \
            '. + {bounded_contexts: $bc, repos: $repos} + (if $epic == "" then {} else {epic_issue: ($epic | tonumber)} end)' \
            "$_fj")
        printf '%s\n' "$_fj_tmp" > "$_fj"
    else
        # Minimal fallback: insert fields before the closing brace
        _existing=$(cat "$_fj")
        _existing="${_existing%\}}"
        if [ -n "$EPIC_ISSUE_INPUT" ]; then
            printf '%s,"bounded_contexts":%s,"repos":%s,"epic_issue":%s}\n' \
                "$_existing" "$RESOLVED_SLUGS_JSON" "$RESOLVED_REPOS_JSON" "$EPIC_ISSUE_INPUT" > "$_fj"
        else
            printf '%s,"bounded_contexts":%s,"repos":%s}\n' \
                "$_existing" "$RESOLVED_SLUGS_JSON" "$RESOLVED_REPOS_JSON" > "$_fj"
        fi
    fi

    # Inform the user how to set feature state in their own shell
    printf '# To persist: export SPECIFY_FEATURE=%s\n' "$(shell_quote "$BRANCH_NAME")" >&2
    printf '#              export SPECIFY_FEATURE_DIRECTORY=%s\n' "$(shell_quote "$FEATURE_DIR")" >&2
fi

if $JSON_MODE; then
    if command -v jq >/dev/null 2>&1; then
        if [ "$DRY_RUN" = true ]; then
            jq -cn \
                --arg branch_name "$BRANCH_NAME" \
                --arg spec_file "$SPEC_FILE" \
                --arg feature_num "$FEATURE_NUM" \
                --argjson bc "$RESOLVED_SLUGS_JSON" \
                --argjson repos "$RESOLVED_REPOS_JSON" \
                --arg epic "$EPIC_ISSUE_INPUT" \
                '{BRANCH_NAME:$branch_name,SPEC_FILE:$spec_file,FEATURE_NUM:$feature_num,bounded_contexts:$bc,repos:$repos,DRY_RUN:true} + (if $epic == "" then {} else {epic_issue: ($epic|tonumber)} end)'
        else
            jq -cn \
                --arg branch_name "$BRANCH_NAME" \
                --arg spec_file "$SPEC_FILE" \
                --arg feature_num "$FEATURE_NUM" \
                --argjson bc "$RESOLVED_SLUGS_JSON" \
                --argjson repos "$RESOLVED_REPOS_JSON" \
                --arg epic "$EPIC_ISSUE_INPUT" \
                '{BRANCH_NAME:$branch_name,SPEC_FILE:$spec_file,FEATURE_NUM:$feature_num,bounded_contexts:$bc,repos:$repos} + (if $epic == "" then {} else {epic_issue: ($epic|tonumber)} end)'
        fi
    else
        _epic_json_field=""
        [ -n "$EPIC_ISSUE_INPUT" ] && _epic_json_field=",\"epic_issue\":$EPIC_ISSUE_INPUT"
        if [ "$DRY_RUN" = true ]; then
            printf '{"BRANCH_NAME":"%s","SPEC_FILE":"%s","FEATURE_NUM":"%s","bounded_contexts":%s,"repos":%s,"DRY_RUN":true%s}\n' "$(json_escape "$BRANCH_NAME")" "$(json_escape "$SPEC_FILE")" "$(json_escape "$FEATURE_NUM")" "$RESOLVED_SLUGS_JSON" "$RESOLVED_REPOS_JSON" "$_epic_json_field"
        else
            printf '{"BRANCH_NAME":"%s","SPEC_FILE":"%s","FEATURE_NUM":"%s","bounded_contexts":%s,"repos":%s%s}\n' "$(json_escape "$BRANCH_NAME")" "$(json_escape "$SPEC_FILE")" "$(json_escape "$FEATURE_NUM")" "$RESOLVED_SLUGS_JSON" "$RESOLVED_REPOS_JSON" "$_epic_json_field"
        fi
    fi
else
    echo "BRANCH_NAME: $BRANCH_NAME"
    echo "SPEC_FILE: $SPEC_FILE"
    echo "FEATURE_NUM: $FEATURE_NUM"
    if [ "$RESOLVED_SLUGS_JSON" != "[]" ]; then
        echo "BOUNDED_CONTEXTS: $RESOLVED_SLUGS_JSON"
        echo "REPOS: $RESOLVED_REPOS_JSON"
    fi
    if [ -n "$EPIC_ISSUE_INPUT" ]; then
        echo "EPIC_ISSUE: $EPIC_ISSUE_INPUT"
    fi
    if [ "$DRY_RUN" != true ]; then
        printf '# To persist in your shell: export SPECIFY_FEATURE=%s\n' "$(shell_quote "$BRANCH_NAME")"
        printf '#                           export SPECIFY_FEATURE_DIRECTORY=%s\n' "$(shell_quote "$FEATURE_DIR")"
    fi
fi
