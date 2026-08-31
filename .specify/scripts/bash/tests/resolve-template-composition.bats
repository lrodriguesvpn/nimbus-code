#!/usr/bin/env bats

COMMON_SH="/tmp/nimbus-023-remote/.specify/scripts/bash/common.sh"

setup() {
    FIXTURE_DIR="$(mktemp -d)"
    mkdir -p "$FIXTURE_DIR/.specify/templates" "$FIXTURE_DIR/.specify/presets" "$FIXTURE_DIR/lib"
    cat > "$FIXTURE_DIR/lib/yaml.py" <<'PY'
import json

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
{"schema_version":"1.0","presets":{"preset-a":{"enabled":true,"priority":1},"preset-b":{"enabled":true,"priority":5}}}
JSON
}

write_core_template() {
    local template_name="$1"
    local content="$2"
    printf '%s' "$content" > "$FIXTURE_DIR/.specify/templates/$template_name.md"
}

write_preset_template() {
    local preset_name="$1"
    local template_name="$2"
    local strategy="$3"
    local content="$4"
    mkdir -p "$FIXTURE_DIR/.specify/presets/$preset_name/templates"
    cat > "$FIXTURE_DIR/.specify/presets/$preset_name/preset.yml" <<JSON
{"schema_version":"1.0","provides":{"templates":[{"type":"template","name":"$template_name","file":"templates/$template_name.md","strategy":"$strategy"}]}}
JSON
    printf '%s' "$content" > "$FIXTURE_DIR/.specify/presets/$preset_name/templates/$template_name.md"
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

@test "wrap strategy composes the core template placeholder (AC-1)" {
    write_core_template "plan-template" "CORE"
    write_preset_template "preset-a" "plan-template" "wrap" "WRAP:{CORE_TEMPLATE}:END"
    write_registry

    resolve_content "plan-template"
    [ "$status" -eq 0 ]
    [ "$output" = "WRAP:CORE:END" ]
}

@test "append strategy concatenates after the base template (AC-2)" {
    write_core_template "plan-template" "CORE"
    write_preset_template "preset-a" "plan-template" "append" "APPEND"
    write_registry

    resolve_content "plan-template"
    [ "$status" -eq 0 ]
    [ "$output" = "CORE

APPEND" ]
}

@test "prepend strategy concatenates before the base template (AC-3)" {
    write_core_template "plan-template" "CORE"
    write_preset_template "preset-a" "plan-template" "prepend" "PREPEND"
    write_registry

    resolve_content "plan-template"
    [ "$status" -eq 0 ]
    [ "$output" = "PREPEND

CORE" ]
}

@test "replace strategy wins entirely over lower layers (AC-4)" {
    write_core_template "plan-template" "CORE"
    write_preset_template "preset-a" "plan-template" "replace" "REPLACED"
    write_registry

    resolve_content "plan-template"
    [ "$status" -eq 0 ]
    [ "$output" = "REPLACED" ]
}

@test "multi-layer composition applies strategies recursively (AC-5)" {
    write_core_template "plan-template" "CORE"
    write_preset_template "preset-a" "plan-template" "append" "LOW"
    write_preset_template "preset-b" "plan-template" "prepend" "HIGH"
    write_registry

    resolve_content "plan-template"
    [ "$status" -eq 0 ]
    [ "$output" = "HIGH

CORE

LOW" ]
}

@test "materialize_template_content writes the composed body to disk verbatim" {
    write_core_template "tasks-template" "CORE-TASKS"
    write_preset_template "preset-a" "tasks-template" "append" "APPENDED-TASKS"
    write_registry
    OUT_FILE="$FIXTURE_DIR/materialized-tasks.md"

    materialize_content "tasks-template" "$OUT_FILE"
    [ "$status" -eq 0 ]
    [ -f "$OUT_FILE" ]
    [ "$(cat "$OUT_FILE")" = "CORE-TASKS

APPENDED-TASKS" ]
}

@test "no preset installed keeps the native template unchanged (AC-7)" {
    write_core_template "plan-template" "CORE"
    rm -rf "$FIXTURE_DIR/.specify/presets"

    resolve_content "plan-template"
    [ "$status" -eq 0 ]
    [ "$output" = "CORE" ]
}
