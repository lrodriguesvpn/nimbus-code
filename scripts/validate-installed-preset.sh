#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DETECTOR="$ROOT/.specify/scripts/bash/detect-preset-version-mismatch.sh"
if [[ ! -f "$DETECTOR" ]]; then
  echo "ERROR: Missing installed-preset detector: $DETECTOR" >&2
  exit 1
fi
exec bash "$DETECTOR" --repo-root "$ROOT" "$@"
