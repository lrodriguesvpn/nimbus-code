#!/usr/bin/env bats

setup() {
  ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  DETECTOR="$ROOT/.specify/scripts/bash/detect-preset-version-mismatch.sh"
  FIXTURE="$BATS_TEST_DIRNAME/.preset-version-${BATS_TEST_NUMBER}-$$"
  mkdir -p "$FIXTURE/.specify/presets/nimbus-code-standards"
  printf 'preset:\n  version: "1.18.0"\n' > "$FIXTURE/.specify/presets/nimbus-code-standards/preset.yml"
  printf '{"presets":{"other":{"version":"9.0.0"},"nimbus-code-standards":{"version":"1.18.0"}}}\n' > "$FIXTURE/.specify/presets/.registry"
  unset NIMBUS_PRESET_VERSION
}

teardown() {
  rm -rf "$FIXTURE"
}

@test "consumer without source tree compares named preset against installed manifest" {
  run bash "$DETECTOR" --repo-root "$FIXTURE" --json
  [ "$status" -eq 0 ]
  [[ "$output" == *'"status": "in_sync"'* ]]
  [[ "$output" == *'"basis": "installed_manifest"'* ]]
}

@test "explicit expected version detects drift independently of local manifests" {
  run bash "$DETECTOR" --repo-root "$FIXTURE" --expected-version 1.19.0 --json
  [ "$status" -eq 1 ]
  [[ "$output" == *'"status": "mismatch"'* ]]
}

@test "central source manifest takes priority and flat registry remains compatible" {
  mkdir -p "$FIXTURE/presets/nimbus-code-standards"
  printf 'schema_version: "1.0"\npreset:\n  version: "1.19.0"\n' > "$FIXTURE/presets/nimbus-code-standards/preset.yml"
  printf '{"version":"1.18.0"}' > "$FIXTURE/.specify/presets/.registry"
  run bash "$DETECTOR" --repo-root "$FIXTURE" --json
  [ "$status" -eq 1 ]
  [[ "$output" == *'"basis": "bundle_manifest"'* ]]
}

@test "missing registry is operational error not mismatch" {
  rm "$FIXTURE/.specify/presets/.registry"
  run bash "$DETECTOR" --repo-root "$FIXTURE" --json
  [ "$status" -eq 2 ]
  [[ "$output" == *'"status": "error"'* ]]
}

@test "malformed registry and missing named preset fail explicitly" {
  printf '{bad json' > "$FIXTURE/.specify/presets/.registry"
  run bash "$DETECTOR" --repo-root "$FIXTURE" --json
  [ "$status" -eq 2 ]
  printf '{"presets":{"other":{"version":"1.18.0"}}}' > "$FIXTURE/.specify/presets/.registry"
  run bash "$DETECTOR" --repo-root "$FIXTURE" --json
  [ "$status" -eq 2 ]
}

@test "unknown or incomplete arguments and invalid expected version fail" {
  for argument in --unknown --repo-root --expected-version --preset; do
    run bash "$DETECTOR" --json "$argument"
    [ "$status" -eq 2 ]
  done
  run bash "$DETECTOR" --json --expected-version '1.18.0;echo bad'
  [ "$status" -eq 2 ]
}

@test "newer registry is mismatch rather than a warning-only success" {
  printf '{"version":"2.0.0"}' > "$FIXTURE/.specify/presets/.registry"
  run bash "$DETECTOR" --repo-root "$FIXTURE" --json
  [ "$status" -eq 1 ]
}

@test "manifest drift is detected even when registry matches explicit target" {
  printf 'preset:\n  version: "1.17.0"\n' > "$FIXTURE/.specify/presets/nimbus-code-standards/preset.yml"
  run bash "$DETECTOR" --repo-root "$FIXTURE" --expected-version 1.18.0 --json
  [ "$status" -eq 1 ]
}

@test "missing manifest without explicit target and nonexistent root are errors" {
  rm "$FIXTURE/.specify/presets/nimbus-code-standards/preset.yml"
  run bash "$DETECTOR" --repo-root "$FIXTURE" --json
  [ "$status" -eq 2 ]
  run bash "$DETECTOR" --repo-root "$FIXTURE/missing" --json
  [ "$status" -eq 2 ]
}

@test "platform-only consumer infers installed preset and detects stale registry" {
  rm -rf "$FIXTURE/.specify/presets/nimbus-code-standards"
  mkdir -p "$FIXTURE/.specify/presets/nimbus-code-platform-standards"
  printf 'preset:\n  version: "2.3.4"\n' > "$FIXTURE/.specify/presets/nimbus-code-platform-standards/preset.yml"
  printf '{"presets":{"other":{"version":"9.9.9"},"nimbus-code-platform-standards":{"version":"2.3.4"}}}' \
    > "$FIXTURE/.specify/presets/.registry"
  run bash "$DETECTOR" --repo-root "$FIXTURE" --json
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.status == "in_sync" and .preset == "nimbus-code-platform-standards" and .basis == "installed_manifest"'
  printf '{"presets":{"nimbus-code-platform-standards":{"version":"0.0.0"}}}' > "$FIXTURE/.specify/presets/.registry"
  run bash "$DETECTOR" --repo-root "$FIXTURE" --json
  [ "$status" -eq 1 ]
  echo "$output" | jq -e '.status == "mismatch" and .mismatches[0].expected == "2.3.4"'
}

@test "multiple Nimbus presets require explicit selection even with expected version" {
  printf '{"presets":{"nimbus-code-standards":{"version":"1.18.0"},"nimbus-code-platform-standards":{"version":"2.3.4"}}}' \
    > "$FIXTURE/.specify/presets/.registry"
  run bash "$DETECTOR" --repo-root "$FIXTURE" --expected-version 1.18.0 --json
  [ "$status" -eq 2 ]
  echo "$output" | jq -e '.status == "error" and (.details | contains("--preset"))'
  run bash "$DETECTOR" --repo-root "$FIXTURE" --preset nimbus-code-standards --json
  [ "$status" -eq 0 ]
  run bash "$DETECTOR" --repo-root "$FIXTURE" --preset nimbus-code-platform-standards --expected-version 2.3.4 --json
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.preset == "nimbus-code-platform-standards"'
}

@test "invalid or uninstalled explicit preset cannot fall back to another entry" {
  for preset in '../nimbus-code-standards' nimbus-code-platform-standards; do
    run bash "$DETECTOR" --repo-root "$FIXTURE" --preset "$preset" --json
    [ "$status" -eq 2 ]
    echo "$output" | jq -e '.status == "error"'
  done
}

@test "platform flat legacy registry supports explicit preset selection" {
  mkdir -p "$FIXTURE/.specify/presets/nimbus-code-platform-standards"
  printf 'preset:\n  version: "2.3.4"\n' > "$FIXTURE/.specify/presets/nimbus-code-platform-standards/preset.yml"
  printf '{"version":"2.3.4"}' > "$FIXTURE/.specify/presets/.registry"
  run bash "$DETECTOR" --repo-root "$FIXTURE" --preset nimbus-code-platform-standards --json
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.preset == "nimbus-code-platform-standards" and .version == "2.3.4"'
}
