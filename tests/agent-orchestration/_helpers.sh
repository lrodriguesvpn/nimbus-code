#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

pass() { echo "✓ $1"; }
fail() { echo "✗ $1"; exit 1; }
