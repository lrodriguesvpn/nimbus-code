#!/usr/bin/env bats

setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../../../.." && pwd)"
    COMMON_SH="$REPO_ROOT/.specify/scripts/bash/common.sh"
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
    write_core_template "plan-template" "CORE-PLAN"
    write_manual_merge_template "plan-template" "$(awk '/^## Nimbus-Code — Classificação de Complexidade/{flag=1} flag' "$REPO_ROOT/specs/021-dora-metrics-governance/plan.md")"
    write_registry

    resolve_content "plan-template"
    [ "$status" -eq 0 ]
    [[ "$output" == CORE-PLAN* ]]
    [[ "$output" == *"## Nimbus-Code — Classificação de Complexidade (S0–S4)"* ]]
    [[ "$output" == *"## Nimbus-Code — Security & DevSecOps Gate"* ]]
}

@test "tasks-template regression keeps the returned file path and composed body" {
    write_core_template "tasks-template" "CORE-TASKS"
    write_manual_merge_template "tasks-template" "$(awk '/^## Nimbus-Code — Contrato de Task Executável no GHE/{flag=1} flag' "$REPO_ROOT/specs/022-nimbuscode-harvest-gateway/tasks.md")"
    write_registry
    OUT_FILE="$FIXTURE_DIR/materialized-tasks-template.md"

    materialize_content "tasks-template" "$OUT_FILE"
    [ "$status" -eq 0 ]
    [ -f "$OUT_FILE" ]
    [[ "$(cat "$OUT_FILE")" == CORE-TASKS* ]]
    [[ "$(cat "$OUT_FILE")" == *"## Nimbus-Code — Contrato de Task Executável no GHE"* ]]
}
