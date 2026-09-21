#!/usr/bin/env python3
"""Deterministic generation and parity checks for native NC agent projections."""

from __future__ import annotations

import argparse
import hashlib
import re
import sys
from pathlib import Path
from typing import Any

import yaml


AGENTS = tuple(
    name
    for name in (
        "nc-assess-intake",
        "nc-assess-research",
        "nc-assess-define",
        "nc-assess-shape",
        "nc-assess-decide",
        "nc-intake",
        "nc-spec",
        "nc-critic",
        "nc-governor",
        "nc-arch",
        "nc-qa",
        "nc-builder",
        "nc-shield",
        "nc-telemetry",
        "nc-designer",
    )
)
TARGETS = ("vscode", "claude", "antigravity")
GENERATED_ROOTS = {
    "vscode": Path(".github/agents"),
    "claude": Path(".claude/agents"),
    "antigravity": Path(".agents/skills"),
}


def fail(message: str) -> None:
    print(f"Error: {message}", file=sys.stderr)
    raise SystemExit(1)


def split_frontmatter(text: str) -> tuple[dict[str, Any], str]:
    if not text.startswith("---"):
        return {}, text
    parts = text.split("---", 2)
    if len(parts) != 3:
        fail("source skill has unterminated frontmatter")
    metadata = yaml.safe_load(parts[1]) or {}
    if not isinstance(metadata, dict):
        fail("source skill frontmatter must be a mapping")
    return metadata, parts[2].lstrip("\r\n")


def normalize_body(text: str) -> str:
    _, body = split_frontmatter(text)
    body = re.sub(
        r"(?m)^\s*- When constructing command invocations from hook command names, "
        r"replace dots.*(?:\r?\n|$)",
        "",
        body,
    )
    return body.strip()


def functional_hash(path: Path) -> str:
    return hashlib.sha256(normalize_body(path.read_text(encoding="utf-8")).encode()).hexdigest()


def load_roles(root: Path) -> dict[str, dict[str, Any]]:
    manifest_path = root / ".nimbus/agent-manifest.yaml"
    try:
        manifest = yaml.safe_load(manifest_path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        fail(f"manifest not found: {manifest_path}")
    except yaml.YAMLError as exc:
        fail(f"invalid manifest {manifest_path}: {exc}")
    roles = manifest.get("manifest", {}).get("roles", [])
    result = {str(role.get("id", "")).lower(): role for role in roles}
    missing = [name for name in AGENTS if f"nc-{name.removeprefix('nc-')}" not in result]
    if missing:
        fail(f"manifest roles missing: {', '.join(missing)}")
    return result


def source_paths(root: Path) -> dict[str, Path]:
    sources = {name: root / ".github/skills" / name / "SKILL.md" for name in AGENTS}
    missing = [name for name, path in sources.items() if not path.is_file()]
    if missing:
        fail(f"source skills missing: {', '.join(missing)}")
    return sources


def role_for(roles: dict[str, dict[str, Any]], agent: str) -> dict[str, Any]:
    return roles[f"nc-{agent.removeprefix('nc-')}"]


def yaml_frontmatter(values: dict[str, Any]) -> str:
    return "---\n" + yaml.safe_dump(values, sort_keys=False, allow_unicode=False).rstrip() + "\n---\n\n"


def render(root: Path, agent: str, target: str, role: dict[str, Any], source: Path) -> str:
    source_text = source.read_text(encoding="utf-8")
    source_meta, body = split_frontmatter(source_text)
    description = str(source_meta.get("description") or role.get("name") or agent)
    tools = [str(tool) for tool in role.get("tool_allowlist", [])]
    if target == "antigravity":
        return source_text
    if target == "vscode":
        metadata = {"name": agent, "description": description, "tools": tools}
    elif target == "claude":
        metadata = {"name": agent, "description": description, "tools": tools}
    else:
        fail(f"unsupported target: {target}")
    return yaml_frontmatter(metadata) + body


def destination(root: Path, agent: str, target: str) -> Path:
    if target == "antigravity":
        return root / GENERATED_ROOTS[target] / agent / "SKILL.md"
    suffix = ".agent.md" if target == "vscode" else ".md"
    return root / GENERATED_ROOTS[target] / f"{agent}{suffix}"


def validate_inventory(root: Path) -> tuple[dict[str, dict[str, Any]], dict[str, Path]]:
    roles = load_roles(root)
    sources = source_paths(root)
    for agent, path in sources.items():
        role = role_for(roles, agent)
        if not role.get("allowed_file_scope") or not role.get("tool_allowlist"):
            fail(f"manifest controls incomplete for {agent}")
        if not role.get("human_approval_policy"):
            fail(f"human approval policy missing for {agent}")
        if not path.is_file():
            fail(f"source skill missing for {agent}: {path}")
    return roles, sources


def validate_contract(root: Path, agent: str, target: str, role: dict[str, Any], path: Path) -> None:
    if target == "antigravity":
        if path != destination(root, agent, target):
            fail(f"invalid Antigravity destination for {agent}")
        return
    metadata, _ = split_frontmatter(path.read_text(encoding="utf-8"))
    required = ("name", "description", "tools")
    missing = [field for field in required if not metadata.get(field)]
    if missing:
        fail(f"{target} contract missing {', '.join(missing)} for {agent}")
    expected = {str(tool) for tool in role.get("tool_allowlist", [])}
    actual = {str(tool) for tool in metadata.get("tools", [])}
    if not actual.issubset(expected):
        fail(f"{target} tools broadened for {agent}: {sorted(actual - expected)}")


def generate(root: Path, targets: list[str]) -> None:
    roles, sources = validate_inventory(root)
    for target in targets:
        if target not in TARGETS:
            fail(f"unsupported target: {target}")
        for agent, source in sources.items():
            path = destination(root, agent, target)
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(render(root, agent, target, role_for(roles, agent), source), encoding="utf-8")
            validate_contract(root, agent, target, role_for(roles, agent), path)
    print(f"Generated {len(sources)} agents for: {', '.join(targets)}")


def check(root: Path, targets: list[str]) -> None:
    roles, sources = validate_inventory(root)
    for target in targets:
        if target not in TARGETS:
            fail(f"unsupported target: {target}")
        for agent, source in sources.items():
            path = destination(root, agent, target)
            if not path.is_file():
                fail(f"missing {target} artifact for {agent}: {path}")
            validate_contract(root, agent, target, role_for(roles, agent), path)
            expected = normalize_body(source.read_text(encoding="utf-8"))
            actual = normalize_body(path.read_text(encoding="utf-8"))
            if expected != actual:
                fail(f"functional drift for {agent} in {target}: {path}")
    print(f"Parity OK for {len(sources)} agents across: {', '.join(targets)}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path, default=Path("."))
    parser.add_argument("command", choices=("generate", "check", "hash"))
    parser.add_argument("--target", action="append", choices=(*TARGETS, "all"))
    parser.add_argument("--agent")
    args = parser.parse_args()
    root = args.repo_root.resolve()
    targets = args.target or list(TARGETS)
    if "all" in targets:
        targets = list(TARGETS)
    if args.command == "generate":
        generate(root, targets)
    elif args.command == "check":
        check(root, targets)
    else:
        if not args.agent:
            fail("--agent is required for hash")
        source = source_paths(root).get(args.agent)
        if source is None:
            fail(f"unknown agent: {args.agent}")
        print(functional_hash(source))


if __name__ == "__main__":
    main()
