#!/usr/bin/env bats
#
# Unit tests for the `--bounded-contexts` flag of create-new-feature.sh
# (MultiRepo support, specs/006-multirepo-support). Covers:
#   - AC-4: valid slugs resolve to repos and persist in feature.json/--json output
#   - AC-5 / AC-10: flag omitted => bounded_contexts/repos are empty arrays, no error
#   - AC-6: invalid slug aborts with a clear list of the valid slugs
#
# Requires bats-core (https://github.com/bats-core/bats-core). Run with:
#   bats .specify/scripts/bash/tests/create-new-feature.bats
#
# Each test runs against an isolated fixture project (its own `.specify/`
# marker and `docs/bounded-contexts.yaml`) so it never touches this
# repository's real `specs/` directory or `docs/bounded-contexts.yaml`.

SCRIPT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/create-new-feature.sh"

setup() {
    FIXTURE_DIR="$(mktemp -d)"
    mkdir -p "$FIXTURE_DIR/.specify" "$FIXTURE_DIR/docs" "$FIXTURE_DIR/specs"
    cat > "$FIXTURE_DIR/docs/bounded-contexts.yaml" <<'YAML'
version: 1
contexts:
  - slug: "auth"
    description: "Authentication service"
    repository: "acme/svc-auth"
    stack: "Go"
    team: "identity"
    autonomous_ok: true
  - slug: "billing"
    description: "Billing service"
    repository: "acme/svc-billing"
    stack: "Python"
    team: "payments"
    autonomous_ok: false
YAML
}

teardown() {
    rm -rf "$FIXTURE_DIR"
}

@test "valid --bounded-contexts resolves slugs to repos and persists arrays (AC-4)" {
    cd "$FIXTURE_DIR"
    run "$SCRIPT" --json --dry-run --bounded-contexts 'auth,billing' 'Test feature'
    [ "$status" -eq 0 ]
    [[ "$output" == *'"bounded_contexts":["auth","billing"]'* ]]
    [[ "$output" == *'"repos":["acme/svc-auth","acme/svc-billing"]'* ]]
}

@test "omitting --bounded-contexts yields empty arrays without error (AC-5, AC-10)" {
    cd "$FIXTURE_DIR"
    run "$SCRIPT" --json --dry-run 'Test feature without contexts'
    [ "$status" -eq 0 ]
    [[ "$output" == *'"bounded_contexts":[]'* ]]
    [[ "$output" == *'"repos":[]'* ]]
}

@test "invalid slug aborts with a clear list of valid slugs (AC-6)" {
    cd "$FIXTURE_DIR"
    run "$SCRIPT" --json --dry-run --bounded-contexts 'auth,nope' 'Test feature'
    [ "$status" -ne 0 ]
    [[ "$output" == *"bounded context slug 'nope' not found"* ]]
    [[ "$output" == *"auth"* ]]
    [[ "$output" == *"billing"* ]]
}

@test "missing docs/bounded-contexts.yaml aborts with a clear error when the flag is used" {
    cd "$FIXTURE_DIR"
    rm -f "$FIXTURE_DIR/docs/bounded-contexts.yaml"
    run "$SCRIPT" --json --dry-run --bounded-contexts 'auth' 'Test feature'
    [ "$status" -ne 0 ]
    [[ "$output" == *"requires docs/bounded-contexts.yaml to exist"* ]]
}
