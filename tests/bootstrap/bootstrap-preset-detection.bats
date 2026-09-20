#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  FIXTURE="$BATS_TEST_DIRNAME/.preset-detection-${BATS_TEST_NUMBER}-$$"
  mkdir -p "$FIXTURE/.specify/presets" "$FIXTURE/presets/nimbus-code-standards"
  printf 'schema_version: "1.0"\npreset:\n  version: "1.17.0"\n' \
    > "$FIXTURE/presets/nimbus-code-standards/preset.yml"
  unset NIMBUS_PRESET_VERSION
}

teardown() {
  rm -rf "$FIXTURE"
}

@test "T-045-AC-1: detect_preset_version_mismatch detects exact version match" {
  cat > "$FIXTURE/.specify/presets/.registry" <<'JSON'
{
  "presets": {
    "nimbus-code-standards": {"version": "1.17.0"}
  }
}
JSON
  run "$REPO_ROOT/.specify/scripts/bash/detect-preset-version-mismatch.sh" \
    --repo-root "$FIXTURE" --json
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.status == "in_sync" and .version == "1.17.0"'
}

@test "T-045-AC-2: detect_preset_version_mismatch detects stale registry version" {
  cat > "$FIXTURE/.specify/presets/.registry" <<'JSON'
{
  "presets": {
    "nimbus-code-standards": {"version": "1.15.0"}
  }
}
JSON
  run "$REPO_ROOT/.specify/scripts/bash/detect-preset-version-mismatch.sh" \
    --repo-root "$FIXTURE" --json
  [ "$status" -eq 1 ]
  echo "$output" | jq -e '.status == "mismatch" and
    .mismatches[0].expected == "1.17.0" and .mismatches[0].actual == "1.15.0"'
}

@test "T-045-AC-3: detect_preset_version_mismatch errors when registry missing" {
  run "$REPO_ROOT/.specify/scripts/bash/detect-preset-version-mismatch.sh" \
    --repo-root "$FIXTURE" --json
  [ "$status" -eq 2 ]
  echo "$output" | jq -e '.status == "error"'
}

@test "T-045-AC-4: detect_preset_version_mismatch handles JSON mode correctly" {
  echo '{"version":"1.17.0"}' > "$FIXTURE/.specify/presets/.registry"
  run "$REPO_ROOT/.specify/scripts/bash/detect-preset-version-mismatch.sh" \
    --repo-root "$FIXTURE" --json
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.status == "in_sync" and .version == "1.17.0"'
}
