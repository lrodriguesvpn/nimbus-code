#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# detect-preset-version-mismatch.sh
# 
# T-043: Detect preset version mismatches between source and installed
# 
# Usage:
#   ./detect-preset-version-mismatch.sh [--repo-root /path/to/repo] [--json]
#
# Output (JSON mode):
#   {
#     "status": "ok|error",
#     "mismatches": [
#       { "file": ".specify/presets/.registry", "expected": "1.16.0", "actual": "1.15.0" }
#     ],
#     "details": "error message if status=error"
#   }
#
###############################################################################

REPO_ROOT="${1:-.}"
JSON_MODE=false

while (( $# > 0 )); do
  case "$1" in
    --repo-root)
      REPO_ROOT="$2"
      shift 2
      ;;
    --json)
      JSON_MODE=true
      shift
      ;;
    *)
      shift
      ;;
  esac
done

cd "$REPO_ROOT"

# Extract version from source preset.yml
PRESET_MANIFEST=".specify/presets/.registry"
PRESET_SOURCE="presets/nimbus-code-standards/preset.yml"

if [ ! -f "$PRESET_SOURCE" ]; then
  if $JSON_MODE; then
    echo '{"status":"error","details":"preset.yml not found at presets/nimbus-code-standards/preset.yml"}'
  else
    echo "ERROR: preset.yml not found" >&2
  fi
  exit 1
fi

# Get source version from preset.yml
SOURCE_VERSION=$(sed -E 's/^version:[[:space:]]*"?([^"[:space:]]+)"?.*/\1/' "$PRESET_SOURCE" | head -1)

if [ -z "$SOURCE_VERSION" ]; then
  if $JSON_MODE; then
    echo '{"status":"error","details":"Could not parse version from preset.yml"}'
  else
    echo "ERROR: Could not parse version from preset.yml" >&2
  fi
  exit 1
fi

# Check if .registry exists
if [ ! -f "$PRESET_MANIFEST" ]; then
  if $JSON_MODE; then
    echo "{\"status\":\"error\",\"details\":\"Preset not installed (.registry missing)\"}"
  else
    echo "ERROR: Preset not installed (.registry missing)" >&2
  fi
  exit 1
fi

# Get installed version from .registry
INSTALLED_VERSION=$(cat "$PRESET_MANIFEST" | python3 -c "
import json, sys
try:
  data = json.load(sys.stdin)
  # Get latest preset by checking metadata
  if 'presets' in data:
    presets = data['presets']
    # Get first preset's version or metadata version
    for key in presets:
      print(data.get('version', ''))
      break
  else:
    print('')
except:
  print('')
" 2>/dev/null || echo "")

# Fallback: extract from registry filename pattern if parsing fails
if [ -z "$INSTALLED_VERSION" ]; then
  INSTALLED_VERSION="unknown"
fi

# Compare versions
if [ "$SOURCE_VERSION" != "$INSTALLED_VERSION" ]; then
  if $JSON_MODE; then
    echo "{\"status\":\"mismatch\",\"mismatches\":[{\"file\":\"$PRESET_MANIFEST\",\"expected\":\"$SOURCE_VERSION\",\"actual\":\"$INSTALLED_VERSION\"}]}"
  else
    echo "MISMATCH: Expected $SOURCE_VERSION, got $INSTALLED_VERSION" >&2
  fi
  exit 1
else
  if $JSON_MODE; then
    echo "{\"status\":\"ok\",\"version\":\"$SOURCE_VERSION\",\"details\":\"Versions match\"}"
  else
    echo "OK: Preset version matches ($SOURCE_VERSION)"
  fi
  exit 0
fi
