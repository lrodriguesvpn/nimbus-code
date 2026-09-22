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


TARGETS = ("vscode", "claude", "antigravity", "cursor", "kiro")
GENERATED_ROOTS = {
    "vscode": Path(".github/agents"),
    "claude": Path(".claude/agents"),
    "antigravity": Path(".agents/skills"),
    "cursor": Path(".cursor/skills"),
    "kiro": Path(".kiro/agents"),
}

# ---------------------------------------------------------------------------
# VS Code single-orchestrator projection (ADL: SPEC-025 pivot).
#
# Unlike Claude Code and Antigravity — which keep one native file per NC role
# so specialist subagents/skills remain individually invocable — the VS Code
# Copilot Chat agent menu is polluted by 15 separate `@nc-*` entries. VS Code
# instead gets exactly ONE generated agent, `@nimbus`, that actively triages
# the developer (Bug/Fix, Nova Spec, Ideação) and delegates internally to the
# same `/nc-*` skills. The orchestrator body is a static, versioned template
# plus a deterministically generated "Esquadrão Disponível" coverage table,
# so drift is still verifiable exactly like the per-agent projections.
# ---------------------------------------------------------------------------
ORCHESTRATOR_NAME = "nimbus"
ORCHESTRATOR_TEMPLATE_PATH = Path("scripts/lib/templates/nimbus-agent.template.md")
ORCHESTRATOR_DEST_PATH = Path(".github/agents/nimbus.agent.md")
ORCHESTRATOR_DESCRIPTION = (
    "Nimbus Code Squad Orchestrator — triagem entre Bug/Fix, Nova Spec e Ideação, "
    "conduzindo o ciclo SDD completo e delegando para os especialistas nc-*."
)
ROLES_TABLE_PLACEHOLDER = "{{ROLES_TABLE}}"


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


def load_roles(root: Path, agents: tuple[str, ...]) -> dict[str, dict[str, Any]]:
    manifest_path = root / ".nimbus/agent-manifest.yaml"
    try:
        manifest = yaml.safe_load(manifest_path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        fail(f"manifest not found: {manifest_path}")
    except yaml.YAMLError as exc:
        fail(f"invalid manifest {manifest_path}: {exc}")
    roles = manifest.get("manifest", {}).get("roles", [])
    result = {str(role.get("id", "")).lower(): role for role in roles}
    missing = [name for name in agents if f"nc-{name.removeprefix('nc-')}" not in result]
    if missing:
        fail(f"manifest roles missing: {', '.join(missing)}")
    return result


def discover_agents(root: Path) -> tuple[str, ...]:
    """Discover NC-* agent skill directories from the source of truth
    (.github/skills/) via glob, instead of a hardcoded list.

    Mitigation for HRN-0006 (docs/harness/harness-catalog.yaml): a hardcoded
    agent list silently drifted from the real source directory, letting
    tests "pass" while agents were missing from generated integrations. This
    discovery is applied uniformly across all targets (spec 028, ADL)."""
    skills_dir = root / ".github/skills"
    if not skills_dir.is_dir():
        fail(f"skills source directory missing: {skills_dir}")
    discovered = sorted(
        p.name
        for p in skills_dir.glob("nc-*")
        if p.is_dir() and (p / "SKILL.md").is_file()
    )
    if not discovered:
        fail(f"no nc-* agent skills discovered in {skills_dir}")
    return tuple(discovered)


def source_paths(root: Path, agents: tuple[str, ...]) -> dict[str, Path]:
    sources = {name: root / ".github/skills" / name / "SKILL.md" for name in agents}
    missing = [name for name, path in sources.items() if not path.is_file()]
    if missing:
        fail(f"source skills missing: {', '.join(missing)}")
    return sources


def role_for(roles: dict[str, dict[str, Any]], agent: str) -> dict[str, Any]:
    return roles[f"nc-{agent.removeprefix('nc-')}"]


def yaml_frontmatter(values: dict[str, Any]) -> str:
    return "---\n" + yaml.safe_dump(values, sort_keys=False, allow_unicode=True).rstrip() + "\n---\n\n"


def orchestrator_tools(roles: dict[str, dict[str, Any]], sources: dict[str, Path]) -> list[str]:
    tools: set[str] = set()
    for agent in sources:
        tools.update(str(tool) for tool in role_for(roles, agent).get("tool_allowlist", []))
    return sorted(tools)


def roles_table(roles: dict[str, dict[str, Any]], sources: dict[str, Path]) -> str:
    header = "| Camada | Comando | Papel |\n| --- | --- | --- |\n"
    rows = []
    for agent in sorted(sources.keys()):
        role = role_for(roles, agent)
        source_meta, _ = split_frontmatter(sources[agent].read_text(encoding="utf-8"))
        role_name = str(source_meta.get("description") or role.get("name") or agent)
        rows.append(f"| {role.get('layer', '')} | `/{agent}` | {role_name} |")
    return header + "\n".join(rows) + "\n"


def render_orchestrator(root: Path, roles: dict[str, dict[str, Any]], sources: dict[str, Path]) -> str:
    template_path = root / ORCHESTRATOR_TEMPLATE_PATH
    if not template_path.is_file():
        fail(f"orchestrator template missing: {template_path}")
    template_text = template_path.read_text(encoding="utf-8")
    body = template_text.replace(ROLES_TABLE_PLACEHOLDER, roles_table(roles, sources))
    metadata = {
        "name": ORCHESTRATOR_NAME,
        "description": ORCHESTRATOR_DESCRIPTION,
        "tools": orchestrator_tools(roles, sources),
    }
    return yaml_frontmatter(metadata) + body


def render(root: Path, agent: str, target: str, role: dict[str, Any], source: Path) -> str:
    source_text = source.read_text(encoding="utf-8")
    source_meta, body = split_frontmatter(source_text)
    description = str(source_meta.get("description") or role.get("name") or agent)
    tools = [str(tool) for tool in role.get("tool_allowlist", [])]
    if target == "antigravity":
        return source_text
    if target == "claude":
        metadata = {"name": agent, "description": description, "tools": tools}
    elif target == "cursor":
        # Cursor Skills expect {name, description, compatibility, metadata}
        # (no "tools" field) — confirmed by isolated `specify init
        # --integration cursor-agent` probe (spec 028 clarify session).
        metadata = {
            "name": agent,
            "description": description,
            "compatibility": str(
                source_meta.get("compatibility")
                or "Requires spec-kit project structure with .specify/ directory"
            ),
            "metadata": source_meta.get("metadata")
            or {"author": "nimbus-code", "role": role.get("name", agent)},
        }
    elif target == "kiro":
        # Kiro's native Custom agents mechanism (.kiro/agents/*.md, distinct
        # from the generic .kiro/prompts/ used for /speckit-* commands).
        # JSON/Markdown formats share the same fields per
        # https://kiro.dev/docs/custom-agents/; the markdown body carries the
        # long-form prompt instead of an inline `prompt` frontmatter string.
        metadata = {"name": agent, "description": description, "tools": tools}
    else:
        fail(f"unsupported per-agent target: {target}")
    return yaml_frontmatter(metadata) + body


def destination(root: Path, agent: str, target: str) -> Path:
    if target == "antigravity":
        return root / GENERATED_ROOTS[target] / agent / "SKILL.md"
    if target == "claude":
        return root / GENERATED_ROOTS[target] / f"{agent}.md"
    if target == "cursor":
        return root / GENERATED_ROOTS[target] / agent / "SKILL.md"
    if target == "kiro":
        return root / GENERATED_ROOTS[target] / f"{agent}.md"
    fail(f"unsupported per-agent target: {target}")


def validate_inventory(root: Path) -> tuple[dict[str, dict[str, Any]], dict[str, Path]]:
    agents = discover_agents(root)
    roles = load_roles(root, agents)
    sources = source_paths(root, agents)
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
    if target == "cursor":
        required = ("name", "description", "compatibility", "metadata")
    else:
        required = ("name", "description", "tools")
    missing = [field for field in required if not metadata.get(field)]
    if missing:
        fail(f"{target} contract missing {', '.join(missing)} for {agent}")
    if target == "cursor":
        return
    expected = {str(tool) for tool in role.get("tool_allowlist", [])}
    actual = {str(tool) for tool in metadata.get("tools", [])}
    if not actual.issubset(expected):
        fail(f"{target} tools broadened for {agent}: {sorted(actual - expected)}")


def stray_vscode_agent_files(root: Path) -> list[Path]:
    """Any `.github/agents/nc-*.agent.md` file is a menu-pollution regression:
    VS Code must only ever expose the single `@nimbus` orchestrator."""
    agents_dir = root / GENERATED_ROOTS["vscode"]
    if not agents_dir.is_dir():
        return []
    return sorted(agents_dir.glob("nc-*.agent.md"))


def generate_vscode_orchestrator(root: Path, roles: dict[str, dict[str, Any]], sources: dict[str, Path]) -> None:
    for stray in stray_vscode_agent_files(root):
        stray.unlink()
    path = root / ORCHESTRATOR_DEST_PATH
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(render_orchestrator(root, roles, sources), encoding="utf-8")
    validate_contract(root, ORCHESTRATOR_NAME, "vscode", {"tool_allowlist": orchestrator_tools(roles, sources)}, path)


def check_vscode_orchestrator(root: Path, roles: dict[str, dict[str, Any]], sources: dict[str, Path]) -> None:
    stray = stray_vscode_agent_files(root)
    if stray:
        fail(
            "VS Code agent menu polluted by legacy per-role files: "
            + ", ".join(str(p.relative_to(root)) for p in stray)
        )
    path = root / ORCHESTRATOR_DEST_PATH
    if not path.is_file():
        fail(f"missing vscode orchestrator artifact: {path}")
    validate_contract(root, ORCHESTRATOR_NAME, "vscode", {"tool_allowlist": orchestrator_tools(roles, sources)}, path)
    expected = render_orchestrator(root, roles, sources)
    actual = path.read_text(encoding="utf-8")
    if expected != actual:
        fail(f"functional drift for {ORCHESTRATOR_NAME} in vscode: {path}")


def generate(root: Path, targets: list[str]) -> None:
    roles, sources = validate_inventory(root)
    for target in targets:
        if target not in TARGETS:
            fail(f"unsupported target: {target}")
        if target == "vscode":
            generate_vscode_orchestrator(root, roles, sources)
            continue
        for agent, source in sources.items():
            path = destination(root, agent, target)
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(render(root, agent, target, role_for(roles, agent), source), encoding="utf-8")
            validate_contract(root, agent, target, role_for(roles, agent), path)
    print(f"Generated agents for: {', '.join(targets)}")


def check(root: Path, targets: list[str]) -> None:
    roles, sources = validate_inventory(root)
    for target in targets:
        if target not in TARGETS:
            fail(f"unsupported target: {target}")
        if target == "vscode":
            check_vscode_orchestrator(root, roles, sources)
            continue
        for agent, source in sources.items():
            path = destination(root, agent, target)
            if not path.is_file():
                fail(f"missing {target} artifact for {agent}: {path}")
            validate_contract(root, agent, target, role_for(roles, agent), path)
            expected = normalize_body(source.read_text(encoding="utf-8"))
            actual = normalize_body(path.read_text(encoding="utf-8"))
            if expected != actual:
                fail(f"functional drift for {agent} in {target}: {path}")
    print(f"Parity OK across: {', '.join(targets)}")


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
