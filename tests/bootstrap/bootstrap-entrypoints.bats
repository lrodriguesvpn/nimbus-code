#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  BOOTSTRAP_SCRIPT="$REPO_ROOT/bootstrap.sh"
}

make_fake_toolchain() {
  local bindir="$1"
  mkdir -p "$bindir"

  cat > "$bindir/specify" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
  init)
    mkdir -p .specify
    printf '{"feature_directory":"."}\n' > .specify/feature.json
    ;;
  preset|extension|workflow)
    :
    ;;
esac

exit 0
EOF
  chmod +x "$bindir/specify"

  cat > "$bindir/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
exit 1
EOF
  chmod +x "$bindir/gh"
}

prepare_consumer_repo() {
  local repo_dir="$1"
  mkdir -p "$repo_dir"
  git -C "$repo_dir" init >/dev/null
  git -C "$repo_dir" remote add origin https://example.com/acme/consumer.git
}

@test "nimbus-code entrypoints do not use the broken raw GHE subdomain" {
  run bash -lc 'set -euo pipefail; cd "$1"; matches=$(grep -RIn "raw\\.venha-pra-nuvem\\.ghe\\.com/venha-pra-nuvem/nimbus-code-spec-kit-template/main/" README.md bootstrap.sh docs templates .github bundles presets extensions workflows tests || true); [ -z "$matches" ]' _ "$REPO_ROOT"
  [ "$status" -eq 0 ]
}

@test "bootstrap repo type prompt supports piped installs via /dev/tty fallback" {
  run bash -lc 'set -euo pipefail; cd "$1"; grep -q "/dev/tty" bootstrap.sh' _ "$REPO_ROOT"
  [ "$status" -eq 0 ]
}

@test "bootstrap classifies a greenfield repo without application code" {
  local workspace repo fake_bin
  workspace="$(mktemp -d)"
  repo="$workspace/consumer-greenfield"
  fake_bin="$workspace/bin"

  prepare_consumer_repo "$repo"
  make_fake_toolchain "$fake_bin"

  mkdir -p "$repo/docs"
  mkdir -p "$repo/src"
  printf '# Demo\n' > "$repo/README.md"
  printf 'console.log("hello");\n' > "$repo/src/index.ts"
  printf 'MIT\n' > "$repo/LICENSE"
  printf '*.log\n' > "$repo/.gitignore"
  printf 'notes\n' > "$repo/docs/notes.md"

  run bash -lc 'set -euo pipefail; cd "$1"; PATH="$2:$PATH" bash "$3/bootstrap.sh" --local "$3" --repo-type dev_standards --delivery-model monorepo --decision-reason "baseline repo" --decision-owner "platform"' _ "$repo" "$fake_bin" "$REPO_ROOT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Detected context: greenfield"* ]]
  [[ "$output" == *"Interpretation: no relevant application code was found"* ]]
  rm -rf "$workspace"
}

@test "bootstrap classifies a brownfield repo with application code" {
  local workspace repo fake_bin
  workspace="$(mktemp -d)"
  repo="$workspace/consumer-brownfield"
  fake_bin="$workspace/bin"

  prepare_consumer_repo "$repo"
  make_fake_toolchain "$fake_bin"

  mkdir -p "$repo/src"
  printf '# Demo\n' > "$repo/README.md"
  printf 'console.log("hello");\n' > "$repo/src/index.ts"

  run bash -lc 'set -euo pipefail; cd "$1"; PATH="$2:$PATH" bash "$3/bootstrap.sh" --local "$3" --repo-type dev_standards' _ "$repo" "$fake_bin" "$REPO_ROOT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Detected context: brownfield"* ]]
  [[ "$output" == *"Interpretation: relevant application code is present"* ]]
  rm -rf "$workspace"
}

@test "bootstrap reruns rehydrate missing copied artifacts" {
  local workspace repo fake_bin source_file restored_file
  workspace="$(mktemp -d)"
  repo="$workspace/consumer-rehydrate"
  fake_bin="$workspace/bin"

  prepare_consumer_repo "$repo"
  make_fake_toolchain "$fake_bin"

  mkdir -p "$repo/docs" "$repo/src"
  printf '# Demo\n' > "$repo/README.md"
  printf 'console.log("hello");\n' > "$repo/src/index.ts"

  run bash -lc 'set -euo pipefail; cd "$1"; PATH="$2:$PATH" bash "$3/bootstrap.sh" --local "$3" --repo-type dev_standards' _ "$repo" "$fake_bin" "$REPO_ROOT"
  [ "$status" -eq 0 ]

  source_file="$REPO_ROOT/presets/nimbus-code-standards/templates/project-root/bounded-contexts.yaml"
  restored_file="$repo/docs/bounded-contexts.yaml"
  [ -f "$restored_file" ]
  rm -f "$restored_file"

  run bash -lc 'set -euo pipefail; cd "$1"; PATH="$2:$PATH" bash "$3/bootstrap.sh" --local "$3" --repo-type dev_standards' _ "$repo" "$fake_bin" "$REPO_ROOT"
  [ "$status" -eq 0 ]
  [ -f "$restored_file" ]
  cmp -s "$restored_file" "$source_file"

  rm -rf "$workspace"
}
