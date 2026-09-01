#!/usr/bin/env bats

setup_file() {
  cd "$BATS_TEST_DIRNAME/../.."
  export REPO_ROOT="$PWD"
  export TEST_TEMP_DIR="$(mktemp -d)"
}

teardown_file() {
  rm -rf "$TEST_TEMP_DIR"
}

setup() {
  export BATS_TEST_TEMP_DIR="$TEST_TEMP_DIR/test-$$"
  mkdir -p "$BATS_TEST_TEMP_DIR"
  cd "$BATS_TEST_TEMP_DIR"
}

@test "T-045-AC-1: detect_preset_version_mismatch detects exact version match" {
  # Arrange: Create mock .specify structure with matching versions
  mkdir -p .specify/presets
  cat > .specify/presets/.registry <<'JSON'
{
  "version": "1.16.0",
  "presets": {}
}
JSON
  
  mkdir -p presets/nimbus-code-standards
  cat > presets/nimbus-code-standards/preset.yml <<'YAML'
version: "1.16.0"
YAML

  # Act
  cd "$REPO_ROOT"
  result=$(.specify/scripts/bash/detect-preset-version-mismatch.sh \
    --repo-root "$BATS_TEST_TEMP_DIR" --json 2>&1)
  exit_code=$?

  # Assert
  [ $exit_code -eq 0 ]
  echo "$result" | jq -e '.status == "ok"'
  echo "$result" | jq -e '.version == "1.16.0"'
}

@test "T-045-AC-2: detect_preset_version_mismatch detects stale registry version" {
  # Arrange: Create .registry with older version than source
  mkdir -p .specify/presets
  cat > .specify/presets/.registry <<'JSON'
{
  "version": "1.15.0",
  "presets": {}
}
JSON
  
  mkdir -p presets/nimbus-code-standards
  cat > presets/nimbus-code-standards/preset.yml <<'YAML'
version: "1.16.0"
YAML

  # Act
  cd "$REPO_ROOT"
  result=$(.specify/scripts/bash/detect-preset-version-mismatch.sh \
    --repo-root "$BATS_TEST_TEMP_DIR" --json 2>&1)
  exit_code=$?

  # Assert
  [ $exit_code -eq 1 ]
  echo "$result" | jq -e '.status == "mismatch"'
  echo "$result" | jq -e '.mismatches[0].expected == "1.16.0"'
  echo "$result" | jq -e '.mismatches[0].actual == "1.15.0"'
}

@test "T-045-AC-3: detect_preset_version_mismatch errors when registry missing" {
  # Arrange: Create preset.yml but no .registry
  mkdir -p presets/nimbus-code-standards
  cat > presets/nimbus-code-standards/preset.yml <<'YAML'
version: "1.16.0"
YAML

  # Act
  cd "$REPO_ROOT"
  result=$(.specify/scripts/bash/detect-preset-version-mismatch.sh \
    --repo-root "$BATS_TEST_TEMP_DIR" --json 2>&1)
  exit_code=$?

  # Assert
  [ $exit_code -eq 1 ]
  echo "$result" | jq -e '.status == "error"'
}

@test "T-045-AC-4: detect_preset_version_mismatch handles JSON mode correctly" {
  # Arrange
  mkdir -p .specify/presets presets/nimbus-code-standards
  echo '{"version":"1.16.0"}' > .specify/presets/.registry
  echo 'version: "1.16.0"' > presets/nimbus-code-standards/preset.yml

  # Act
  cd "$REPO_ROOT"
  result=$(.specify/scripts/bash/detect-preset-version-mismatch.sh \
    --repo-root "$BATS_TEST_TEMP_DIR" --json 2>&1)

  # Assert
  echo "$result" | jq empty  # Validates JSON syntax
  [ $? -eq 0 ]
}
