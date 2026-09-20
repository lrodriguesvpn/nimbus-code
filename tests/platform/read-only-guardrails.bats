#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
}

@test "guardrail passa nos workflows e scripts versionados" {
  run bash -lc 'cd "$1" && bash scripts/validate-no-direct-write-commands.sh' _ "$REPO_ROOT"
  [ "$status" -eq 0 ]
}

@test "guardrail falha quando encontra escrita direta" {
  local fixture="$BATS_TEST_TMPDIR/forbidden.sh"
  cat > "$fixture" <<'EOF'
#!/usr/bin/env bash
terraform apply -auto-approve
EOF
  run bash -lc 'cd "$1" && bash scripts/validate-no-direct-write-commands.sh "$2"' _ "$REPO_ROOT" "$fixture"
  [ "$status" -ne 0 ]
}
