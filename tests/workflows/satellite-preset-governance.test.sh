#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FIXTURE="$ROOT/tests/workflows/.satellite-governance-$$"
mkdir "$FIXTURE"
trap 'rm -rf "$FIXTURE"' EXIT
mkdir -p "$FIXTURE/bin" "$FIXTURE/bundle/scripts" "$FIXTURE/bundle/presets/nimbus-code-standards" \
  "$FIXTURE/bundle/.specify/scripts/bash"
export MOCK_LOG="$FIXTURE/commands.log"
export GH_TOKEN=mock GITHUB_REPOSITORY_OWNER=example GITHUB_REPOSITORY=example/central
export GH_HOST=example.invalid
export MOCK_CENTRAL
MOCK_CENTRAL="$(python3 "$ROOT/scripts/preset-audit-report.py" version "$ROOT/presets/nimbus-code-standards/preset.yml")"
cp "$ROOT/scripts/preset-audit-report.py" "$FIXTURE/bundle/scripts/"
cp "$ROOT/.specify/scripts/bash/detect-preset-version-mismatch.sh" "$FIXTURE/bundle/.specify/scripts/bash/"
printf 'preset:\n  version: "%s"\n' "$MOCK_CENTRAL" > "$FIXTURE/bundle/presets/nimbus-code-standards/preset.yml"

cat > "$FIXTURE/bin/gh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf 'gh %s\n' "$*" >> "$MOCK_LOG"
case "$*" in
  *orgs/*)
    [[ "${MOCK_MODE:-}" != list_error ]] || exit 9
    [[ "${MOCK_MODE:-}" != empty ]] || exit 0
    echo example/satellite ;;
  *contents/.specify/presets/.registry*)
    [[ "${MOCK_MODE:-}" != api_error ]] || exit 9
    if [[ "${MOCK_MODE:-}" == malformed ]]; then echo '{"content":"!"}'; exit 0; fi
    python3 - <<'PY'
import base64, json, os
v = "0.0.1" if os.environ.get("MOCK_MODE") == "drift" else os.environ["MOCK_CENTRAL"]
print(json.dumps({"content": base64.b64encode(json.dumps({"presets": {
    "nimbus-code-standards": {"version": v}}}).encode()).decode()}))
PY
    ;;
  *commits*)
    [[ "${MOCK_MODE:-}" != date_error ]] || exit 9
    echo '2026-09-20T00:00:00Z' ;;
  'api repos/example/satellite --jq .permissions.push')
    if [[ "${MOCK_MODE:-}" == denied ]]; then echo false; else echo true; fi ;;
  'pr list '*)
    if [[ "${MOCK_MODE:-}" == active ]]; then echo 1; else echo 0; fi ;;
  'repo clone '*)
    mkdir -p "$4/.specify/presets"
    printf '{"version":"%s"}' "$MOCK_CENTRAL" > "$4/.specify/presets/.registry" ;;
  'pr create '*)
    [[ "${MOCK_MODE:-}" != pr_error ]] || exit 9
    echo 'https://example.invalid/example/satellite/pull/1' ;;
  *) echo "Unexpected gh invocation: $*" >&2; exit 99 ;;
esac
SH
cat > "$FIXTURE/bin/git" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf 'git %s\n' "$*" >> "$MOCK_LOG"
case "$*" in
  'status --porcelain') if [[ -f refreshed ]]; then echo ' M .specify/presets/.registry'; fi ;;
  'branch --show-current') echo develop ;;
  'ls-remote --heads '*)
    if [[ "${MOCK_MODE:-}" == existing ]]; then echo 'abc refs/heads/existing'; fi ;;
  'push '*)
    [[ "${MOCK_MODE:-}" != push_error ]] || exit 9
    [[ "$*" != *--force* && "$*" != *' -f '* ]] || exit 99 ;;
  'checkout -b '*|'config '*|'add -A'|'commit -m '*) ;;
  *) echo "Unexpected git invocation: $*" >&2; exit 99 ;;
esac
SH
cat > "$FIXTURE/bundle/bootstrap.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf 'refresh %s\n' "$*" >> "$MOCK_LOG"
[[ "$1" == --refresh-preset && "$2" == --local && "$4" == --repo-type && "$5" == dev_standards ]] || exit 99
[[ "${MOCK_MODE:-}" != refresh_error ]] || exit 9
[[ "${MOCK_MODE:-}" != unchanged ]] || exit 0
touch refreshed
if [[ "${MOCK_MODE:-}" == version_error ]]; then
  printf '{"version":"0.0.1"}' > .specify/presets/.registry
fi
SH
chmod +x "$FIXTURE/bin/gh" "$FIXTURE/bin/git"
export PATH="$FIXTURE/bin:$PATH"

expect_status() {
  local expected="$1" actual=0
  shift
  "$@" > "$FIXTURE/output" 2>&1 || actual=$?
  if [[ "$actual" != "$expected" ]]; then
    cat "$FIXTURE/output" >&2
    echo "Expected exit $expected, got $actual: $*" >&2
    exit 1
  fi
}
no_writes() {
  if grep -Eq '^git (commit|push)|^gh pr create' "$MOCK_LOG"; then
    cat "$MOCK_LOG" >&2
    echo "Unexpected remote-write sequence" >&2
    exit 1
  fi
}
export MOCK_MODE=normal
: > "$MOCK_LOG"
expect_status 0 bash "$ROOT/scripts/sync-satellite-preset.sh"
grep -q disabled "$FIXTURE/output"
[[ ! -s "$MOCK_LOG" ]]
export NIMBUS_SATELLITE_SYNC_ENABLED=true
for input in 'example/evil;echo' 'other/satellite' 'example/central'; do
  expect_status 2 bash "$ROOT/scripts/sync-satellite-preset.sh" "$input" "$MOCK_CENTRAL" "$FIXTURE/bundle" "$FIXTURE/checkout"
done
for version in '1.2;echo' '9.9.9'; do
  expect_status 2 bash "$ROOT/scripts/sync-satellite-preset.sh" example/satellite "$version" "$FIXTURE/bundle" "$FIXTURE/checkout"
done
[[ ! -s "$MOCK_LOG" ]]
expect_status 2 env GH_TOKEN= bash "$ROOT/scripts/sync-satellite-preset.sh" example/satellite "$MOCK_CENTRAL" "$FIXTURE/bundle" "$FIXTURE/checkout"

for mode in denied active existing refresh_error version_error normal unchanged push_error pr_error; do
  export MOCK_MODE="$mode"
  : > "$MOCK_LOG"
  expected=2
  case "$mode" in
    refresh_error|push_error|pr_error) expected=9 ;;
    version_error) expected=1 ;;
    normal|unchanged) expected=0 ;;
  esac
  expect_status "$expected" bash "$ROOT/scripts/sync-satellite-preset.sh" example/satellite "$MOCK_CENTRAL" "$FIXTURE/bundle" "$FIXTURE/checkout-$mode"
  case "$mode" in
    normal)
      grep -q '^git push --set-upstream origin fix/preset-sync-to-v' "$MOCK_LOG"
      grep -q '^gh pr create --repo example/satellite --base develop --head fix/preset-sync-to-v' "$MOCK_LOG" ;;
    push_error) ! grep -q '^gh pr create' "$MOCK_LOG" ;;
    pr_error) ! grep -q '^proposed:' "$FIXTURE/output" ;;
    *) no_writes ;;
  esac
done
echo "PASS: disabled/input/auth/active-PR/branch/refresh/version/no-change/failure/PR strategy"

for mode in normal empty drift api_error malformed date_error list_error; do
  export MOCK_MODE="$mode"
  expected=0
  case "$mode" in api_error|malformed|date_error) expected=2 ;; list_error) expected=9 ;; esac
  expect_status "$expected" bash "$ROOT/scripts/scan-org-rename-references.sh" \
    --mode satellite-preset-audit --org example --output "$FIXTURE/audit.csv"
  if [[ "$mode" == list_error ]]; then continue; fi
  expect_status "$expected" python3 "$ROOT/scripts/preset-audit-report.py" summary "$FIXTURE/audit.csv" \
    --manifest "$FIXTURE/bundle/presets/nimbus-code-standards/preset.yml" \
    --summary "$FIXTURE/summary.md" --outputs "$FIXTURE/outputs-$mode"
  case "$mode" in
    normal) grep -q '^in_sync=1$' "$FIXTURE/outputs-$mode"; grep -q '^drifted=0$' "$FIXTURE/outputs-$mode" ;;
    empty) grep -q '^in_sync=0$' "$FIXTURE/outputs-$mode"; grep -q '^drifted=0$' "$FIXTURE/outputs-$mode" ;;
    drift) grep -q '^drifted=1$' "$FIXTURE/outputs-$mode" ;;
    *) grep -q '^error=1$' "$FIXTURE/outputs-$mode" ;;
  esac
done
echo "PASS: audit zero drift, empty CSV, drift, API/registry/date/list failures"

python3 - "$ROOT" "$FIXTURE" <<'PY'
import os
from pathlib import Path
import shutil
import subprocess
import sys
import textwrap
root, fixture = map(Path, sys.argv[1:])
workflow = (root / ".github/workflows/validate-bootstrap.yml").read_text()
script = textwrap.dedent(workflow.split("        run: |\n", 1)[1])
work = fixture / "validation"
detector = work / ".specify/scripts/bash/detect-preset-version-mismatch.sh"
detector.parent.mkdir(parents=True)
env = dict(os.environ, GITHUB_STEP_SUMMARY=str(fixture / "step-summary"))
for state, code in [("in_sync", 0), ("mismatch", 1), ("error", 2),
                    ("bad_json", 0), ("in_sync", 1), ("missing", 2)]:
    if state == "missing":
        detector.unlink()
    else:
        payload = '{"status":"' + state + '"}' if state != "bad_json" else "invalid"
        detector.write_text(f"printf '%s\\n' '{payload}'\nexit {code}\n")
    result = subprocess.run(["bash", "-c", script], cwd=work, env=env,
                            capture_output=True, text=True)
    expected = code if state in ("in_sync", "mismatch", "error") else 2
    if state == "in_sync" and code != 0:
        expected = 2
    assert result.returncode == expected, (state, result.stdout, result.stderr)
sync = (root / ".github/workflows/auto-sync-preset.yml").read_text()
assert "  issues:" not in sync and "pending-from-issue" not in sync
assert "vars.NIMBUS_SATELLITE_SYNC_ENABLED == 'true'" in sync
assert "secrets.GITHUB_TOKEN" not in sync
assert "VPNDEV_PROJECT_TOKEN" in sync and "actions/create-github-app-token@v1" in sync
assert "permission-workflows: write" in sync
assert "${{ inputs.repo }}" in sync and 'TARGET_REPO: ${{ inputs.repo }}' in sync
helper = (root / "scripts/sync-satellite-preset.sh").read_text()
assert "--force" not in helper and "gh pr merge" not in helper
audit = (root / ".github/workflows/satellite-preset-audit.yml").read_text()
assert "workflow run" not in audit and "createWorkflowDispatch" not in audit
parse = audit.split("      - name: Parse audit results\n", 1)[1]
parse_script = textwrap.dedent(parse.split("        run: |\n", 1)[1].split("\n      - name:", 1)[0])
shutil.copyfile(fixture / "audit.csv", fixture / "bundle/preset-audit-report.csv")
env.update(AUDIT_OUTCOME="failure", GITHUB_OUTPUT=str(fixture / "partial-outputs"))
result = subprocess.run(["bash", "-c", parse_script], cwd=fixture / "bundle", env=env,
                        capture_output=True, text=True)
assert result.returncode == 2, result.stderr
assert "counts may be partial" in (fixture / "bundle/audit-summary.md").read_text()
inputs = sync.split("      - name: Validate manual inputs before authentication\n", 1)[1]
input_script = textwrap.dedent(inputs.split("        run: |\n", 1)[1].split("\n      - uses:", 1)[0])
env.update(GITHUB_ENV=str(fixture / "job-env"), TARGET_VERSION=os.environ["MOCK_CENTRAL"])
for repo, expected in [("example/satellite", 0), ("example/evil;touch unexpected", 2),
                       ("other/satellite", 2), ("example/central", 2)]:
    env["TARGET_REPO"] = repo
    result = subprocess.run(["bash", "-c", input_script], cwd=fixture / "bundle", env=env,
                            capture_output=True, text=True)
    assert result.returncode == expected, (repo, result.stderr)
assert not (fixture / "bundle/unexpected").exists()
print("PASS: actual validation workflow shell: in_sync/mismatch/error/missing/invalid contract")
print("PASS: actual input-validation and partial-audit workflow shell")
print("PASS: workflows require structured manual input, opt-in and cross-repo auth")
PY
