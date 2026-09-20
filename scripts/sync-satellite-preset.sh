#!/usr/bin/env bash
set -euo pipefail

# Usage: sync-satellite-preset.sh owner/repo X.Y.Z /bundle /new-checkout
fail() { echo "ERROR: $*" >&2; exit 2; }

if [[ "${NIMBUS_SATELLITE_SYNC_ENABLED:-false}" != true ]]; then
  echo "disabled: explicit NIMBUS_SATELLITE_SYNC_ENABLED=true and human pilot approval required"
  exit 0
fi
[[ $# == 4 ]] || fail "Expected repository, version, bundle path and new checkout path"
repo="$1"
target="$2"
bundle="$3"
checkout="$4"
[[ "$repo" =~ ^[A-Za-z0-9][A-Za-z0-9-]*/[A-Za-z0-9][A-Za-z0-9_.-]*$ ]] || fail "Invalid repository"
[[ "$target" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "Invalid target version (expected X.Y.Z)"
[[ -n "${GITHUB_REPOSITORY_OWNER:-}" && "${repo%%/*}" == "$GITHUB_REPOSITORY_OWNER" ]] || fail "Target must be in the configured organization"
[[ "$repo" != "${GITHUB_REPOSITORY:-}" ]] || fail "Target must be a satellite, not the central repository"
[[ -n "${GH_TOKEN:-}" ]] || fail "Cross-repository App/PAT token required; GITHUB_TOKEN is not a substitute"
[[ ! -e "$checkout" ]] || fail "Checkout path already exists; refusing to reuse a dirty workspace"
bundle="$(cd "$bundle" && pwd)"
[[ -f "$bundle/bootstrap.sh" ]] || fail "Bundle bootstrap is missing"
detector="$bundle/.specify/scripts/bash/detect-preset-version-mismatch.sh"
[[ -f "$detector" ]] || fail "Bundle version detector is missing"
central="$(python3 "$bundle/scripts/preset-audit-report.py" version "$bundle/presets/nimbus-code-standards/preset.yml")"
[[ "$target" == "$central" ]] || fail "Requested version does not match this approved bundle checkout ($central)"
[[ "$(gh api "repos/$repo" --jq '.permissions.push')" == true ]] || fail "Token lacks satellite content-write permission; human App/PAT configuration required (#433/#445)"
open_prs="$(gh pr list --repo "$repo" --state open --json number --jq length)"
[[ "$open_prs" =~ ^[0-9]+$ ]] || fail "Invalid open-PR response"
[[ "$open_prs" == 0 ]] || fail "Satellite has active PRs; coordinate with owners before retrying"

gh repo clone "$repo" "$checkout" -- --single-branch
cd "$checkout"
[[ -z "$(git status --porcelain)" ]] || fail "Fresh checkout is not clean"
base="$(git branch --show-current)"
[[ -n "$base" ]] || fail "Cannot identify satellite default branch"
branch="fix/preset-sync-to-v${target}"
existing_branch="$(git ls-remote --heads origin "$branch")"
if [[ -n "$existing_branch" ]]; then
  fail "Sync branch already exists; review it manually"
fi
git checkout -b "$branch"

bash "$bundle/bootstrap.sh" --refresh-preset --local "$bundle" --repo-type dev_standards
bash "$detector" --repo-root "$PWD" --expected-version "$target" --json

if [[ -z "$(git status --porcelain)" ]]; then
  echo "in_sync: verified $target; no changes to propose"
  exit 0
fi
git config user.name "Nimbus Preset Sync"
git config user.email "actions@github.com"
git config credential.helper '!gh auth git-credential'
git add -A
git commit -m "chore(preset): refresh to v${target}"
git push --set-upstream origin "$branch"
gh pr create --repo "$repo" --base "$base" --head "$branch" \
  --title "fix(preset): sync to v${target}" \
  --body "Managed preset refresh from the approved central bundle. Human review and passing CI are required. No automatic merge. Pilot gates: #433/#445 in the central governance repository."
echo "proposed: review the PR before merging"
