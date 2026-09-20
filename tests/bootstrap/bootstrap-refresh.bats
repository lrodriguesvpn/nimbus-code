#!/usr/bin/env bats

setup() {
  ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  WORK="$(mktemp -d)"
  CONSUMER="$WORK/consumer"
  mkdir -p "$CONSUMER/.specify/presets" "$WORK/bin"
  export CALL_LOG="$WORK/calls"
  export PATH="$WORK/bin:$PATH"
  printf '{"presets":{"nimbus-code-standards":{"version":"1.0.0"}}}\n' > "$CONSUMER/.specify/presets/.registry"
  cat > "$WORK/bin/specify" <<'SH'
#!/usr/bin/env bash
set -eu
printf '%s\n' "$*" >> "$CALL_LOG"
[[ "${FAIL_SPECIFY:-false}" != true ]] || exit 9
[[ "$1" == preset ]] || { echo "Unexpected provisioning call" >&2; exit 8; }
if [[ "$2" == add ]]; then
  source="$4"
  version="$(awk '/^[[:space:]]*version:/ {print $2; exit}' "$source/preset.yml" | tr -d '"')"
  printf '{"presets":{"nimbus-code-standards":{"version":"%s"}}}\n' "$version" > .specify/presets/.registry
fi
SH
  chmod +x "$WORK/bin/specify"
  python3 "$ROOT/scripts/sync-bundle-artifacts.py" --bundle "$ROOT" \
    --target "$CONSUMER" --preset nimbus-code-standards --initialize
}

teardown() {
  rm -rf "$WORK"
}

refresh() {
  run bash -c 'cd "$1"; bash "$2/bootstrap.sh" --local "$2" --refresh-preset --repo-type dev_standards' _ "$CONSUMER" "$ROOT"
}

@test "new consumer receives patched scripts and version hook companion" {
  for script in common create-new-feature setup-plan setup-tasks detect-preset-version-mismatch; do
    cmp "$ROOT/.specify/scripts/bash/$script.sh" "$CONSUMER/.specify/scripts/bash/$script.sh"
  done
  cmp "$ROOT/scripts/validate-installed-preset.sh" "$CONSUMER/scripts/validate-versions.sh"
  [ -f "$CONSUMER/.specify/bundle-files.json" ]
}

@test "both spec prepend templates omit wrap-only placeholders" {
  for preset in nimbus-code-standards nimbus-code-platform-standards; do
    ! grep -Fq '{CORE_TEMPLATE}' "$ROOT/presets/$preset/templates/spec-template.md"
  done
}

@test "consumer version hook validates installed manifests without central catalogs" {
  mkdir -p "$CONSUMER/.specify/presets/nimbus-code-standards"
  cp "$ROOT/presets/nimbus-code-standards/preset.yml" \
    "$CONSUMER/.specify/presets/nimbus-code-standards/preset.yml"
  refresh
  [ "$status" -eq 0 ]
  [ ! -d "$CONSUMER/bundles" ]
  [ ! -d "$CONSUMER/presets" ]
  run bash "$CONSUMER/scripts/validate-versions.sh" --json
  [ "$status" -eq 0 ]
  printf '{"presets":{"nimbus-code-standards":{"version":"0.0.0"}}}\n' \
    > "$CONSUMER/.specify/presets/.registry"
  run bash "$CONSUMER/scripts/validate-versions.sh" --json
  [ "$status" -eq 1 ]
}

@test "refresh reads nested source version and reinstalls without provisioning" {
  refresh
  [ "$status" -eq 0 ]
  grep -q '^preset remove nimbus-code-standards$' "$CALL_LOG"
  grep -q '^preset add --dev ' "$CALL_LOG"
  [ "$(wc -l < "$CALL_LOG" | tr -d ' ')" = 2 ]
  [[ "$output" == *"preset refresh complete"* ]]
}

@test "delivery rejects a state directory pointing outside the consumer" {
  mkdir -p "$WORK/linked" "$WORK/external"
  ln -s "$WORK/external" "$WORK/linked/.specify"
  run python3 "$ROOT/scripts/sync-bundle-artifacts.py" \
    --bundle "$ROOT" --target "$WORK/linked" --preset nimbus-code-standards --initialize
  [ "$status" -ne 0 ]
  [[ "$output" == *"state must not"* ]]
  [ ! -e "$WORK/external/bundle-files.json" ]
  [ ! -e "$WORK/linked/scripts" ]
}

@test "refresh rejects customized managed scripts before removing preset" {
  printf '\n# consumer customization\n' >> "$CONSUMER/.specify/scripts/bash/common.sh"
  refresh
  [ "$status" -ne 0 ]
  [[ "$output" == *"locally modified"* ]]
  [ ! -e "$CALL_LOG" ]
  grep -q 'consumer customization' "$CONSUMER/.specify/scripts/bash/common.sh"
}

@test "refresh preserves local catalogs, instructions and overrides" {
  printf 'custom catalog\n' > "$CONSUMER/docs/harness/harness-catalog.yaml"
  printf 'custom instructions\n' > "$CONSUMER/.github/copilot-instructions.md"
  mkdir -p "$CONSUMER/.specify/templates/overrides"
  printf 'custom template\n' > "$CONSUMER/.specify/templates/overrides/plan-template.md"
  refresh
  [ "$status" -eq 0 ]
  grep -q '^custom catalog$' "$CONSUMER/docs/harness/harness-catalog.yaml"
  grep -q '^custom instructions$' "$CONSUMER/.github/copilot-instructions.md"
  grep -q '^custom template$' "$CONSUMER/.specify/templates/overrides/plan-template.md"
}

@test "refresh reports failed preset install instead of success" {
  export FAIL_SPECIFY=true
  refresh
  [ "$status" -ne 0 ]
  [[ "$output" != *"preset refresh complete"* ]]
}

@test "legacy files without baseline require reconciliation, not silent overwrite" {
  rm "$CONSUMER/.specify/bundle-files.json"
  printf 'legacy resolver\n' > "$CONSUMER/.specify/scripts/bash/common.sh"
  refresh
  [ "$status" -ne 0 ]
  [[ "$output" == *"no recorded baseline"* ]]
  [ ! -e "$CALL_LOG" ]
}

@test "refresh rehydrates a deleted managed artifact" {
  rm "$CONSUMER/.specify/scripts/bash/setup-tasks.sh"
  refresh
  [ "$status" -eq 0 ]
  cmp "$ROOT/.specify/scripts/bash/setup-tasks.sh" "$CONSUMER/.specify/scripts/bash/setup-tasks.sh"
}
