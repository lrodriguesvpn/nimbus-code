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
  printf '# Demo\n' > "$repo/README.md"
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

@test "bootstrap persists context evidence and pinned source metadata" {
  local workspace repo fake_bin
  workspace="$(mktemp -d)"
  repo="$workspace/consumer-metadata"
  fake_bin="$workspace/bin"

  prepare_consumer_repo "$repo"
  make_fake_toolchain "$fake_bin"

  run bash -lc 'set -euo pipefail; cd "$1"; PATH="$2:$PATH" bash "$3/bootstrap.sh" --local "$3" --ref v1.18.0 --repo-type dev_standards --delivery-model monorepo --decision-reason "baseline repo" --decision-owner "platform"' _ "$repo" "$fake_bin" "$REPO_ROOT"
  [ "$status" -eq 0 ]
  [ "$(jq -r '.topology_decision.context_indicator' "$repo/.specify/feature.json")" = "No relevant application code found; only README, LICENSE, workflows, setup scripts, or minimal templates" ]
  [ "$(jq -r '.source_ref' "$repo/.nimbus/bootstrap.json")" = "v1.18.0" ]
  [ "$(jq -r '.bundle' "$repo/.nimbus/bootstrap.json")" = "nimbus-code-project-bundle" ]

  rm -rf "$workspace"
}

@test "bootstrap fails when a critical component installation fails" {
  local workspace repo fake_bin
  workspace="$(mktemp -d)"
  repo="$workspace/consumer-failure"
  fake_bin="$workspace/bin"

  prepare_consumer_repo "$repo"
  mkdir -p "$fake_bin"
  cat > "$fake_bin/specify" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "init" ]]; then
  mkdir -p .specify
  printf '{"feature_directory":"."}\n' > .specify/feature.json
  exit 0
fi
if [[ "${1:-}" == "preset" ]]; then
  exit 42
fi
exit 0
EOF
  chmod +x "$fake_bin/specify"

  run bash -lc 'set -euo pipefail; cd "$1"; PATH="$2:$PATH" bash "$3/bootstrap.sh" --local "$3" --repo-type dev_standards --delivery-model monorepo --decision-reason "baseline repo" --decision-owner "platform"' _ "$repo" "$fake_bin" "$REPO_ROOT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"failed to install preset nimbus-code-standards"* ]]

  rm -rf "$workspace"
}

@test "platform bootstrap does not install workload automation or project governance" {
  local workspace repo fake_bin
  workspace="$(mktemp -d)"
  repo="$workspace/consumer-platform"
  fake_bin="$workspace/bin"

  prepare_consumer_repo "$repo"
  make_fake_toolchain "$fake_bin"

  run bash -lc 'set -euo pipefail; cd "$1"; PATH="$2:$PATH" bash "$3/bootstrap.sh" --local "$3" --repo-type platform --delivery-model monorepo --decision-reason "platform baseline" --decision-owner "platform"' _ "$repo" "$fake_bin" "$REPO_ROOT"
  [ "$status" -eq 0 ]
  [ -f "$repo/.github/copilot-instructions.md" ]
  [ -f "$repo/.github/ISSUE_TEMPLATE/nimbus-code-task.md" ]
  [ ! -e "$repo/.github/workflows/update-speckit-and-bundle.yml" ]
  [ ! -e "$repo/.github/workflows/ensure-github-project.yml" ]
  [ ! -e "$repo/.github/workflows/add-to-repo-project.yml" ]
  [ ! -e "$repo/.github/workflows/devstats-corporate-integration.yml" ]
  [ ! -e "$repo/docs/cost-profiles-and-rates.md" ]
  [ ! -e "$repo/docs/reuse-catalog.yaml" ]
  [ ! -e "$repo/docs/agent-session-manual.md" ]
  [ ! -e "$repo/.git/hooks/pre-commit" ]
  [ "$(jq -r '.bundle' "$repo/.nimbus/bootstrap.json")" = "nimbus-code-platform-bundle" ]

  rm -rf "$workspace"
}
