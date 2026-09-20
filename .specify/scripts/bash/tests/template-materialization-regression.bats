#!/usr/bin/env bats

SCRIPTS_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
REPO_ROOT="$(cd "$SCRIPTS_DIR/../../.." && pwd)"
COMMON_SH="$SCRIPTS_DIR/common.sh"

setup() {
    FIXTURE_DIR="$(mktemp -d)"
    mkdir -p "$FIXTURE_DIR/.specify/templates" "$FIXTURE_DIR/.specify/presets" "$FIXTURE_DIR/lib"
    cat > "$FIXTURE_DIR/lib/yaml.py" <<'PY'
import json
YAMLError = ValueError

def safe_load(stream):
    if hasattr(stream, "read"):
        return json.loads(stream.read())
    return json.loads(stream)
PY
    export PYTHONPATH="$FIXTURE_DIR/lib${PYTHONPATH:+:$PYTHONPATH}"
}

teardown() {
    rm -rf "$FIXTURE_DIR"
}

write_registry() {
    cat > "$FIXTURE_DIR/.specify/presets/.registry" <<'JSON'
{"schema_version":"1.0","presets":{"manual-merge":{"enabled":true,"priority":5}}}
JSON
}

write_core_template() {
    local template_name="$1"
    local content="$2"
    printf '%s' "$content" > "$FIXTURE_DIR/.specify/templates/$template_name.md"
}

write_manual_merge_template() {
    local template_name="$1"
    local content="$2"
    mkdir -p "$FIXTURE_DIR/.specify/presets/manual-merge/templates"
    cat > "$FIXTURE_DIR/.specify/presets/manual-merge/preset.yml" <<JSON
{"schema_version":"1.0","provides":{"templates":[{"type":"template","name":"$template_name","file":"templates/$template_name.md","strategy":"append"}]}}
JSON
    printf '%s' "$content" > "$FIXTURE_DIR/.specify/presets/manual-merge/templates/$template_name.md"
}

resolve_content() {
    local template_name="$1"
    run bash -c "source '$COMMON_SH'; resolve_template_content '$template_name' '$FIXTURE_DIR'"
}

materialize_content() {
    local template_name="$1"
    local out_file="$2"
    run bash -c "source '$COMMON_SH'; materialize_template_content '$template_name' '$FIXTURE_DIR' '$out_file'"
}

@test "plan-template regression matches the merged block preserved in specs/021" {
    write_manual_merge_template "plan-template" ""
    python3 - "$REPO_ROOT/specs/021-dora-metrics-governance/plan.md" "$FIXTURE_DIR" <<'PY'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_bytes()
marker = "## Nimbus-Code — Classificação de Complexidade".encode()
core, marker, preset = source.partition(marker)
assert marker and core.endswith(b"\n\n")
root = Path(sys.argv[2])
(root / ".specify/templates/plan-template.md").write_bytes(core[:-2])
(root / ".specify/presets/manual-merge/templates/plan-template.md").write_bytes(marker + preset)
PY
    write_registry

    materialize_content "plan-template" "$FIXTURE_DIR/output.md"
    [ "$status" -eq 0 ]
    cmp "$REPO_ROOT/specs/021-dora-metrics-governance/plan.md" "$FIXTURE_DIR/output.md"
}

@test "tasks-template regression keeps the returned file path and composed body" {
    write_core_template "tasks-template" "CORE-TASKS"
    write_manual_merge_template "tasks-template" "$(awk '/^## Nimbus-Code — Contrato de Task Executável no GHE/{flag=1} flag' "$REPO_ROOT/specs/022-nimbuscode-harvest-gateway/tasks.md")"
    write_registry
    mkdir -p "$FIXTURE_DIR/specs/001-regression"
    touch "$FIXTURE_DIR/specs/001-regression/spec.md" "$FIXTURE_DIR/specs/001-regression/plan.md"

    run env SPECIFY_INIT_DIR="$FIXTURE_DIR" SPECIFY_FEATURE_DIRECTORY="specs/001-regression" \
        TMPDIR="$FIXTURE_DIR" bash "$SCRIPTS_DIR/setup-tasks.sh" --json
    [ "$status" -eq 0 ]
    OUT_FILE="$(printf '%s' "$output" | python3 -c 'import json,sys; print(json.load(sys.stdin)["TASKS_TEMPLATE"])')"
    [[ "$OUT_FILE" == /* ]]
    [ -f "$OUT_FILE" ]
    { printf 'CORE-TASKS\n\n'; cat "$FIXTURE_DIR/.specify/presets/manual-merge/templates/tasks-template.md"; } > "$FIXTURE_DIR/expected.md"
    cmp "$FIXTURE_DIR/expected.md" "$OUT_FILE"
}

@test "setup-plan propagates composition failure instead of creating an empty plan" {
    write_core_template "plan-template" "CORE"
    write_manual_merge_template "plan-template" "PRESET"
    sed -i.bak 's/"append"/"invalid"/' "$FIXTURE_DIR/.specify/presets/manual-merge/preset.yml"
    write_registry
    mkdir -p "$FIXTURE_DIR/specs/001-regression"
    touch "$FIXTURE_DIR/specs/001-regression/spec.md"
    run env SPECIFY_INIT_DIR="$FIXTURE_DIR" SPECIFY_FEATURE_DIRECTORY="specs/001-regression" \
        bash "$SCRIPTS_DIR/setup-plan.sh" --json
    [ "$status" -ne 0 ]
    [ ! -e "$FIXTURE_DIR/specs/001-regression/plan.md" ]
}
