#!/usr/bin/env bats

setup_file() {
  export REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  export TEST_ROOT="$REPO_ROOT/.bats-tmp/bootstrap-preset-detection"
  rm -rf "$TEST_ROOT"
  mkdir -p "$TEST_ROOT"
}

teardown_file() {
  rm -rf "$TEST_ROOT"
}

setup() {
  export TEST_DIR="$TEST_ROOT/${BATS_TEST_NAME// /_}"
  rm -rf "$TEST_DIR"
  mkdir -p "$TEST_DIR/repo" "$TEST_DIR/source/presets/nimbus-code-standards"
}

write_registry() {
  local version="$1"
  mkdir -p "$TEST_DIR/repo/.specify/presets"
  cat > "$TEST_DIR/repo/.specify/presets/.registry" <<JSON
{
  "schema_version": "1.0",
  "presets": {
    "nimbus-code-standards": {
      "version": "$version",
      "installed_at": "2026-09-20T12:00:00Z"
    }
  }
}
JSON
}

write_source_manifest() {
  local version="$1"
  cat > "$TEST_DIR/source/presets/nimbus-code-standards/preset.yml" <<YAML
schema_version: "1.0"

preset:
  id: "nimbus-code-standards"
  version: "$version"
YAML
}

@test "T038 AC1: versão exata passa sem drift" {
  write_registry "1.19.0"
  write_source_manifest "1.19.0"

  run bash "$REPO_ROOT/.specify/scripts/bash/detect-preset-version-mismatch.sh" \
    --repo-root "$TEST_DIR/repo" \
    --source-root "$TEST_DIR/source" \
    --json

  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.status == "ok"'
  echo "$output" | jq -e '.expected_version == "1.19.0"'
  echo "$output" | jq -e '.actual_version == "1.19.0"'
}

@test "T038 AC2: diretório .specify ausente retorna erro" {
  write_source_manifest "1.19.0"

  run bash "$REPO_ROOT/.specify/scripts/bash/detect-preset-version-mismatch.sh" \
    --repo-root "$TEST_DIR/repo" \
    --source-root "$TEST_DIR/source" \
    --json

  [ "$status" -eq 1 ]
  echo "$output" | jq -e '.status == "error"'
  echo "$output" | jq -e '.details | contains("Diretório .specify ausente")'
}

@test "T038 AC3: registry desatualizado é detectado como mismatch" {
  write_registry "1.18.0"
  write_source_manifest "1.19.0"

  run bash "$REPO_ROOT/.specify/scripts/bash/detect-preset-version-mismatch.sh" \
    --repo-root "$TEST_DIR/repo" \
    --source-root "$TEST_DIR/source" \
    --json

  [ "$status" -eq 1 ]
  echo "$output" | jq -e '.status == "mismatch"'
  echo "$output" | jq -e '.mismatches[0].expected == "1.19.0"'
  echo "$output" | jq -e '.mismatches[0].actual == "1.18.0"'
}

@test "T038 AC4: registry mais novo gera aviso e não falha" {
  write_registry "1.20.0"
  write_source_manifest "1.19.0"

  run bash "$REPO_ROOT/.specify/scripts/bash/detect-preset-version-mismatch.sh" \
    --repo-root "$TEST_DIR/repo" \
    --source-root "$TEST_DIR/source" \
    --json

  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.status == "warn"'
  echo "$output" | jq -e '.warnings[0].expected == "1.19.0"'
  echo "$output" | jq -e '.warnings[0].actual == "1.20.0"'
}
