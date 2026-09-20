#!/usr/bin/env bash
set -euo pipefail

# Exit contract: in_sync=0, mismatch=1, error=2. No network access.
exec python3 - "$@" <<'PY'
import json
import os
from pathlib import Path
import re
import sys

args = sys.argv[1:]
json_mode = "--json" in args
root = Path(".")
expected = os.environ.get("NIMBUS_PRESET_VERSION", "")
preset = None
supported_presets = ("nimbus-code-standards", "nimbus-code-platform-standards")
version_pattern = r"[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?"

def version(value):
    if not isinstance(value, str) or not re.fullmatch(version_pattern, value):
        raise ValueError("Invalid or missing preset version")
    return value

def manifest_version(path):
    text = path.read_text()
    block = re.search(r"(?m)^preset:\s*\n((?:[ \t]+[^\n]*\n|\n)*)", text)
    matches = re.findall(r"(?m)^  version:\s*['\"]?([^'\"\s#]+)['\"]?\s*(?:#.*)?$",
                         block.group(1) if block else "")
    if len(matches) != 1:
        raise ValueError(f"Missing or ambiguous preset.version in {path}")
    return version(matches[0])

try:
    i = 0
    while i < len(args):
        arg = args[i]
        if arg == "--json":
            i += 1
            continue
        if arg not in ("--repo-root", "--expected-version", "--preset") or i + 1 >= len(args):
            raise ValueError(f"Unknown or incomplete argument: {arg}")
        if arg == "--repo-root":
            root = Path(args[i + 1])
        elif arg == "--preset":
            preset = args[i + 1]
        else:
            expected = args[i + 1]
        i += 2

    if not root.is_dir():
        raise ValueError(f"Repository directory does not exist: {root}")
    if preset is not None and preset not in supported_presets:
        raise ValueError(f"Unsupported Nimbus preset: {preset}")
    registry_path = ".specify/presets/.registry"
    registry = json.loads((root / registry_path).read_text())
    if not isinstance(registry, dict):
        raise ValueError("Registry must be a JSON object")
    if "presets" in registry:
        if not isinstance(registry["presets"], dict):
            raise ValueError("Registry presets must be a JSON object")
        if preset is None:
            candidates = [name for name in supported_presets if name in registry["presets"]]
            if len(candidates) != 1:
                raise ValueError("Registry must contain one Nimbus preset; pass --preset when ambiguous")
            preset = candidates[0]
        actual = version(registry["presets"][preset]["version"])
    else:
        preset = preset or "nimbus-code-standards"
        actual = version(registry.get("version"))
    source = root / "presets" / preset / "preset.yml"
    installed_path = f".specify/presets/{preset}/preset.yml"
    installed = root / installed_path
    if expected:
        expected = version(expected)
        basis = "explicit"
    elif source.is_file():
        expected = manifest_version(source)
        basis = "bundle_manifest"
    else:
        expected = manifest_version(installed)
        basis = "installed_manifest"

    mismatches = []
    if actual != expected:
        mismatches.append({"file": registry_path, "expected": expected, "actual": actual})
    if installed.is_file():
        installed_version = manifest_version(installed)
        if installed_version != expected:
            mismatches.append({"file": installed_path,
                               "expected": expected, "actual": installed_version})
    code = 1 if mismatches else 0
    result = {"status": "mismatch" if mismatches else "in_sync",
              "preset": preset, "version": expected, "basis": basis, "mismatches": mismatches}
except (OSError, ValueError, KeyError, TypeError) as exc:
    code = 2
    result = {"status": "error", "details": str(exc)}

print(json.dumps(result) if json_mode else f"{result['status']}: {result}")
sys.exit(code)
PY
