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
esac
EOF
  chmod +x "$bindir/specify"
}

prepare_consumer_repo() {
  local repo_dir="$1"
  mkdir -p "$repo_dir/src"
  git -C "$repo_dir" init >/dev/null
  printf 'console.log("fixture");\n' > "$repo_dir/src/index.ts"
}

run_bootstrap() {
  local repo="$1"
  local fake_bin="$2"
  local repo_type="$3"
  run bash -lc \
    'cd "$1" && PATH="$2:$PATH" bash "$3/bootstrap.sh" --local "$3" --repo-type "$4"' \
    _ "$repo" "$fake_bin" "$REPO_ROOT" "$repo_type"
  [ "$status" -eq 0 ]
}

@test "each profile materializes only its approved inventory" {
  local workspace="$BATS_TEST_TMPDIR/materialization"
  local fake_bin="$workspace/bin"
  local dev_repo="$workspace/dev"
  local platform_repo="$workspace/platform"

  mkdir -p "$workspace"
  make_fake_toolchain "$fake_bin"
  prepare_consumer_repo "$dev_repo"
  prepare_consumer_repo "$platform_repo"

  run_bootstrap "$dev_repo" "$fake_bin" dev_standards
  run_bootstrap "$platform_repo" "$fake_bin" platform

  [ -f "$dev_repo/.github/workflows/ensure-github-project.yml" ]
  [ ! -e "$dev_repo/.github/workflows/devstats-corporate-integration.yml" ]
  [ -f "$dev_repo/docs/cost-profiles-and-rates.md" ]
  [ -f "$dev_repo/docs/agent-session-manual.md" ]

  [ -f "$platform_repo/.github/copilot-instructions.md" ]
  [ -f "$platform_repo/.github/ISSUE_TEMPLATE/nimbus-code-task.md" ]
  [ -f "$platform_repo/.nimbus/bootstrap.json" ]
  [ ! -e "$platform_repo/.github/workflows/ensure-github-project.yml" ]
  [ ! -e "$platform_repo/.github/workflows/devstats-corporate-integration.yml" ]
  [ ! -e "$platform_repo/docs/cost-profiles-and-rates.md" ]
  [ ! -e "$platform_repo/docs/agent-session-manual.md" ]
}
