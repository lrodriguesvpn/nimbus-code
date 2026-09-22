#!/usr/bin/env python3
"""Deliver bundle-owned files without overwriting consumer customizations."""

import argparse
import hashlib
import json
from pathlib import Path
import shutil
import sys


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def delivery_files(bundle, preset):
    root = bundle / "presets" / preset / "templates/project-root"
    if not root.is_dir():
        root = bundle / "presets/nimbus-code-standards/templates/project-root"
    if not root.is_dir():
        raise ValueError("Missing project-root template directory: " + str(root))
    aliases = {
        "copilot-instructions.md": ".github/copilot-instructions.md",
        "bounded-contexts.yaml": "docs/bounded-contexts.yaml",
        ".specify/cost/cost-config-template.yml": ".specify/cost/cost-config.yml",
    }
    files = {}
    for source in sorted(root.rglob("*")):
        if source.is_file():
            relative = source.relative_to(root).as_posix()
            files[aliases.get(relative, relative)] = source
    for name in (
        "common.sh", "create-new-feature.sh", "setup-plan.sh", "setup-tasks.sh",
        "detect-preset-version-mismatch.sh",
    ):
        relative = ".specify/scripts/bash/" + name
        files[relative] = bundle / relative
    if preset == "nimbus-code-standards":
        for name in (
            "update-speckit-and-bundle.yml", "ensure-github-project.yml",
            "add-to-repo-project.yml", "agent-auto-assign.yml",
        ):
            source = bundle / "templates/workflows" / name
            if source.is_file():
                files[".github/workflows/" + name] = source
    for relative in (
        ".github/workflows/validate-bootstrap.yml",
        "docs/version-synchronization.md",
    ):
        source = bundle / relative
        if source.is_file():
            files[relative] = source
    files["scripts/validate-versions.sh"] = bundle / "scripts/validate-installed-preset.sh"
    return files


def preserve(relative):
    return (
        relative in (
            ".github/copilot-instructions.md", "docs/bounded-contexts.yaml",
            ".specify/cost/cost-config.yml", ".vscode/settings.json",
        )
        or relative.endswith("-catalog.yaml")
        or "/overrides/" in relative
    )


def synchronize(args):
    bundle, target = args.bundle.resolve(), args.target.resolve()
    state_path = target / ".specify/bundle-files.json"
    if state_path.is_symlink() or target not in state_path.resolve().parents:
        raise ValueError("Managed-file state must not be a symlink")
    temporary = state_path.with_suffix(".json.tmp")
    if temporary.is_symlink() or temporary.is_dir():
        raise ValueError("Invalid managed-file temporary state")
    state = json.loads(state_path.read_text()) if state_path.exists() else {}
    if not isinstance(state, dict) or not all(
        isinstance(key, str) and isinstance(value, str) for key, value in state.items()
    ):
        raise ValueError("Invalid managed-file state")
    files = delivery_files(bundle, args.preset)
    updates, conflicts = [], []
    for relative, source in files.items():
        destination = target / relative
        if not source.is_file():
            raise ValueError("Missing bundle source: " + str(source))
        if target not in destination.resolve().parents or destination.is_symlink():
            raise ValueError("Unsafe delivery destination: " + relative)
        if destination.exists() and not destination.is_file():
            raise ValueError("Delivery destination is not a file: " + relative)
        if destination.exists() and preserve(relative):
            continue
        expected = digest(source)
        current = digest(destination) if destination.is_file() else None
        if current == expected:
            state[relative] = expected
            continue
        core_overlay = relative.startswith(".specify/scripts/bash/")
        if current is not None and not (args.initialize and core_overlay):
            if relative not in state:
                if args.initialize:
                    continue
                conflicts.append(relative + " (no recorded baseline)")
                continue
            if current != state[relative]:
                conflicts.append(relative + " (locally modified)")
                continue
        updates.append((source, destination))
        state[relative] = expected
    if conflicts:
        raise ValueError(
            "Reconcile these files before refresh; no managed files changed:\n  "
            + "\n  ".join(conflicts)
        )
    if args.check:
        print("Managed-file preflight passed")
        return
    for source, destination in updates:
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)
        if destination.suffix == ".sh":
            destination.chmod(destination.stat().st_mode | 0o100)
        print("Delivered: " + destination.relative_to(target).as_posix())
    state_path.parent.mkdir(parents=True, exist_ok=True)
    temporary.write_text(json.dumps(state, indent=2, sort_keys=True) + "\n")
    temporary.replace(state_path)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bundle", type=Path, required=True)
    parser.add_argument("--target", type=Path, required=True)
    parser.add_argument("--preset", choices=(
        "nimbus-code-standards", "nimbus-code-platform-standards",
    ), required=True)
    parser.add_argument("--initialize", action="store_true")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    try:
        synchronize(args)
    except (OSError, ValueError) as error:
        print("ERROR: " + str(error), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
