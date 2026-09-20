#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  SCRIPT="$REPO_ROOT/scripts/harness-search.sh"
  PRESET="$REPO_ROOT/presets/nimbus-code-standards/templates/project-root/scripts/harness-search.sh"
  WORKDIR="$REPO_ROOT/.harness-search-fixtures-${BATS_TEST_NUMBER}-$$"
  mkdir -p "$WORKDIR/bin"
  for tool in awk dirname basename; do
    ln -s "$(command -v "$tool")" "$WORKDIR/bin/$tool"
  done
  CATALOG="$WORKDIR/catalog.yaml"
  cat > "$CATALOG" <<'YAML'
version: 1
entries:
  - id: HRN-0001
    date: 2026-09-20
    complexity: S3
    bounded_context: Spec-Kit-Workflow
    error_pattern: >
      Primeira linha do erro
      segunda linha do erro.
    prevention: |-
      Primeira ação
      segunda ação.
    tags:
      - shared
      - 'a[0].*'
      - 'path\name'
      - '-option'
    root_cause: text-only-needle
  - id: "HRN-0002"
    date: "2026-09-21"
    complexity: "S2"
    bounded_context: "spec-kit-workflow"
    error_pattern: "Erro com \"aspas\" e # literal"
    prevention: 'Don''t omit review'
    tags: [shared, "comma,tag", 'quote''tag', "hash#tag", "double\\slash"]
  - id: 'HRN-0003'
    bounded_context: another-context
    error_pattern: text-only-needle
    prevention: Other prevention
    tags: ['SHARED', alpha, beta] # comment-only-needle
ignored:
  - id: HRN-NOT-AN-ENTRY
    tags: [shared]
YAML
}

teardown() {
  rm -rf "$WORKDIR"
}

@test "hash-prefixed content inside block scalars is not a YAML comment" {
  cat > "$CATALOG" <<'YAML'
entries:
  - id: HRN-BLOCK
    bounded_context: |
      # literal-context
    error_pattern: >
      First line
      # literal evidence
    prevention: |-
      # keep prevention
    # outside-comment
    tags: [block]
YAML
  search '# literal-context'
  [ "$status" -eq 0 ]
  [[ "$output" == *"1 entrada(s)"* ]]
  [[ "$output" == *"First line # literal evidence"* ]]
  [[ "$output" == *"# keep prevention"* ]]
  [[ "$output" != *"outside-comment"* ]]
}

search() {
  run env PATH="$WORKDIR/bin" "$BASH" "$SCRIPT" "$@" --file "$CATALOG"
}

@test "local and distributed harness scripts remain identical and executable" {
  cmp "$SCRIPT" "$PRESET"
  [ -x "$SCRIPT" ]
  [ -x "$PRESET" ]
}

@test "both scripts find the real catalog entry without yq" {
  for script in "$SCRIPT" "$PRESET"; do
    run env PATH="$WORKDIR/bin" "$BASH" "$script" agent-scope-creep \
      --file "$REPO_ROOT/docs/harness/harness-catalog.yaml"
    [ "$status" -eq 0 ]
    [[ "$output" == *"HRN-0001"* ]]
    [[ "$output" == *"Prevenção:"* ]]
  done
}

@test "quoted and unquoted IDs return all tag matches exactly once" {
  search shared
  [ "$status" -eq 0 ]
  [[ "$output" == *"HRN-0001"* ]]
  [[ "$output" == *"HRN-0002"* ]]
  [[ "$output" == *"HRN-0003"* ]]
  [[ "$output" == *"3 entrada(s)"* ]]
  [[ "$output" != *"HRN-NOT-AN-ENTRY"* ]]
}

@test "context uses case-insensitive literal substring matching" {
  search KIT-WORK
  [ "$status" -eq 0 ]
  [[ "$output" == *"2 entrada(s)"* ]]
  [[ "$output" != *"HRN-0003"* ]]
}

@test "multiline summaries stay with their entry" {
  search '-option'
  [ "$status" -eq 0 ]
  [[ "$output" == *"Primeira linha do erro segunda linha do erro."* ]]
  [[ "$output" == *"Primeira ação segunda ação."* ]]
  [[ "$output" != *"Other prevention"* ]]
}

@test "only tags and context participate in search" {
  for term in text-only-needle comment-only-needle HRN-0001 'alpha beta'; do
    search "$term"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Nenhum resultado encontrado"* ]]
  done
}

@test "regex metacharacters and backslashes remain literal" {
  for term in 'a[0].*' 'path\name' '[' '-option'; do
    search "$term"
    [ "$status" -eq 0 ]
    [[ "$output" == *"HRN-0001"* ]]
    [[ "$output" == *"1 entrada(s)"* ]]
  done
  search 'a0'
  [ "$status" -eq 0 ]
  [[ "$output" == *"Nenhum resultado encontrado"* ]]
}

@test "flow lists preserve quoted commas hashes apostrophes and escaped backslashes" {
  for term in 'comma,tag' "quote'tag" 'hash#tag' 'double\slash'; do
    search "$term"
    [ "$status" -eq 0 ]
    [[ "$output" == *"HRN-0002"* ]]
    [[ "$output" == *'Erro com "aspas" e # literal'* ]]
    [[ "$output" == *"Don't omit review"* ]]
    [[ "$output" == *"1 entrada(s)"* ]]
  done
}

@test "missing match and empty catalog succeed without phantom entries" {
  search absent
  [ "$status" -eq 0 ]
  [[ "$output" == *"Nenhum resultado encontrado"* ]]
  printf 'version: 1\nentries: []\n' > "$CATALOG"
  search shared
  [ "$status" -eq 0 ]
  [[ "$output" == *"Nenhum resultado encontrado"* ]]
}

@test "indentationless sequences and CRLF catalogs work" {
  printf 'entries:\r\n- id: HRN-CRLF\r\n  tags:\r\n  - crlf-tag\r\n  bounded_context: crlf-context\r\n' > "$CATALOG"
  search crlf-tag
  [ "$status" -eq 0 ]
  [[ "$output" == *"HRN-CRLF"* ]]
  [[ "$output" == *"1 entrada(s)"* ]]
}

@test "CLI reports missing arguments files and unknown options" {
  run "$BASH" "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Uso:"* ]]
  run "$BASH" "$SCRIPT" ""
  [ "$status" -ne 0 ]
  run "$BASH" "$SCRIPT" shared --file
  [ "$status" -ne 0 ]
  [[ "$output" == *"--file exige um caminho"* ]]
  run "$BASH" "$SCRIPT" shared --file "$WORKDIR/missing.yaml"
  [ "$status" -ne 0 ]
  [[ "$output" == *"catálogo não encontrado"* ]]
  run "$BASH" "$SCRIPT" shared --unknown
  [ "$status" -ne 0 ]
  [[ "$output" == *"Argumento desconhecido"* ]]
}
