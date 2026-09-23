#!/usr/bin/env python3
"""coverage-gate.py — gate de cobertura de testes (SPEC 007 / issue #450).

Lê um relatório de cobertura já gerado pela ferramenta da linguagem do
projeto (LCOV ou Cobertura XML), calcula a cobertura global e a cobertura das
linhas alteradas no Pull Request e falha quando a política não é atendida.
Nunca inventa métricas: sem relatório válido o gate falha (exit 2).

Política (docs/security-baseline-ghe.md, seção 11):
  - cobertura global mínima (padrão 80%);
  - cobertura mínima do código alterado (padrão 80%), quando --base-ref é
    informado e o relatório tem granularidade de linha;
  - nenhuma redução em relação a --baseline sem exceção aprovada;
  - exceções só via .github/security-exceptions.json (controle "coverage"),
    com owner, aprovador e data de expiração válidos.

Uso:
  python3 scripts/coverage-gate.py --report coverage/lcov.info \
      [--format auto|lcov|cobertura] [--min 80] [--diff-min 80] \
      [--base-ref origin/main] [--baseline 83.5] \
      [--exceptions .github/security-exceptions.json] [--summary FILE]

Exit codes: 0 = aprovado, 1 = política violada, 2 = relatório ausente/inválido.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import re
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


def parse_lcov(text: str) -> dict[str, dict[int, int]]:
    files: dict[str, dict[int, int]] = {}
    current = None
    for raw in text.splitlines():
        line = raw.strip()
        if line.startswith("SF:"):
            current = line[3:]
            files.setdefault(current, {})
        elif line.startswith("DA:") and current is not None:
            parts = line[3:].split(",")
            if len(parts) >= 2 and parts[0].isdigit():
                hits = int(parts[1]) if parts[1].lstrip("-").isdigit() else 0
                files[current][int(parts[0])] = max(files[current].get(int(parts[0]), 0), hits)
        elif line == "end_of_record":
            current = None
    return files


def parse_cobertura(text: str) -> dict[str, dict[int, int]]:
    root = ET.fromstring(text)
    if root.tag != "coverage":
        raise ValueError("raiz XML não é <coverage>")
    files: dict[str, dict[int, int]] = {}
    for cls in root.iter("class"):
        filename = cls.get("filename") or ""  # matching com o diff é por sufixo
        lines = files.setdefault(filename, {})
        for ln in cls.iter("line"):
            number, hits = ln.get("number"), ln.get("hits", "0")
            if number and number.isdigit():
                lines[int(number)] = max(lines.get(int(number), 0), int(hits) if hits.isdigit() else 0)
    return files


def load_report(path: Path, fmt: str) -> dict[str, dict[int, int]]:
    text = path.read_text(encoding="utf-8", errors="replace")
    if fmt == "auto":
        fmt = "cobertura" if text.lstrip().startswith("<") else "lcov"
    return parse_cobertura(text) if fmt == "cobertura" else parse_lcov(text)


def pct(covered: int, total: int) -> float:
    return round((covered / total) * 100, 2) if total else 0.0


def normalize(path: str) -> str:
    cwd = os.getcwd().rstrip("/") + "/"
    path = path.replace("\\", "/")
    return path[len(cwd):] if path.startswith(cwd) else path.removeprefix("./")


def changed_lines(base_ref: str) -> dict[str, set[int]]:
    out = subprocess.run(
        ["git", "diff", "--unified=0", "--no-color", f"{base_ref}...HEAD"],
        check=True, capture_output=True, text=True,
    ).stdout
    result: dict[str, set[int]] = {}
    current = None
    for line in out.splitlines():
        if line.startswith("+++ "):
            target = line[4:]
            current = None if target == "/dev/null" else re.sub(r"^b/", "", target)
            if current:
                result.setdefault(current, set())
        elif line.startswith("@@") and current:
            match = re.search(r"\+(\d+)(?:,(\d+))?", line)
            if match:
                start, count = int(match.group(1)), int(match.group(2) or "1")
                result[current].update(range(start, start + count))
    return result


def active_exception(path: Path | None, today: dt.date) -> dict | None:
    if not path or not path.exists():
        return None
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return None
    for item in data.get("exceptions", []):
        if item.get("control") not in ("coverage", "coverage-decrease"):
            continue
        try:
            expires = dt.date.fromisoformat(item.get("expires_at", ""))
        except ValueError:
            continue
        if expires >= today and item.get("owner") and item.get("approved_by"):
            return item
    return None


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--report", required=True)
    parser.add_argument("--format", default="auto", choices=["auto", "lcov", "cobertura"])
    parser.add_argument("--min", type=float, default=80.0)
    parser.add_argument("--diff-min", type=float, default=80.0)
    parser.add_argument("--base-ref", default="")
    parser.add_argument("--baseline", type=float, default=None)
    parser.add_argument("--exceptions", default=".github/security-exceptions.json")
    parser.add_argument("--summary", default=os.environ.get("GITHUB_STEP_SUMMARY", ""))
    parser.add_argument("--today", default="")
    args = parser.parse_args()

    today = dt.date.fromisoformat(args.today) if args.today else dt.datetime.now(dt.timezone.utc).date()
    report = Path(args.report)
    lines_out: list[str] = ["### Cobertura de testes", ""]

    def finish(code: int) -> int:
        text = "\n".join(lines_out) + "\n"
        print(text)
        if args.summary:
            with open(args.summary, "a", encoding="utf-8") as fh:
                fh.write(text)
        return code

    if not report.is_file():
        lines_out.append(f"::error::Relatório de cobertura não publicado: '{args.report}' não existe. O gate falha — não há métrica a avaliar.")
        return finish(2)
    try:
        files = load_report(report, args.format)
    except (ET.ParseError, ValueError) as exc:
        lines_out.append(f"::error::Relatório de cobertura inválido ({exc}).")
        return finish(2)

    total = sum(len(v) for v in files.values())
    covered = sum(1 for v in files.values() for hits in v.values() if hits > 0)
    if total == 0:
        lines_out.append("::error::Relatório de cobertura sem linhas instrumentadas — nenhuma métrica calculável.")
        return finish(2)

    global_pct = pct(covered, total)
    violations: list[str] = []
    lines_out.append(f"- Cobertura global: **{global_pct}%** ({covered}/{total} linhas) — mínimo {args.min}%")
    if global_pct < args.min:
        violations.append(f"cobertura global {global_pct}% < mínimo {args.min}%")

    if args.baseline is not None:
        lines_out.append(f"- Baseline versionado: {args.baseline}%")
        if global_pct < args.baseline:
            violations.append(f"cobertura reduziu de {args.baseline}% para {global_pct}%")

    if args.base_ref:
        normalized = {normalize(k): v for k, v in files.items()}
        diff_total = diff_covered = 0
        for fname, changed in changed_lines(args.base_ref).items():
            match = next((v for k, v in normalized.items() if k == fname or k.endswith("/" + fname) or fname.endswith("/" + k)), None)
            if not match:
                continue
            for ln in changed:
                if ln in match:
                    diff_total += 1
                    diff_covered += 1 if match[ln] > 0 else 0
        if diff_total == 0:
            lines_out.append("- Cobertura do código alterado: N/A (nenhuma linha instrumentada alterada)")
        else:
            diff_pct = pct(diff_covered, diff_total)
            lines_out.append(f"- Cobertura do código alterado: **{diff_pct}%** ({diff_covered}/{diff_total}) — mínimo {args.diff_min}%")
            if diff_pct < args.diff_min:
                violations.append(f"cobertura do código alterado {diff_pct}% < mínimo {args.diff_min}%")
    else:
        lines_out.append("- Cobertura do código alterado: não avaliada (sem --base-ref)")

    if not violations:
        lines_out.extend(["", "✓ Política de cobertura atendida."])
        return finish(0)

    exc = active_exception(Path(args.exceptions) if args.exceptions else None, today)
    if exc:
        lines_out.extend(["", f"::warning::Violação aceita pela exceção {exc.get('id')} (owner {exc.get('owner')}, aprovada por {exc.get('approved_by')}, expira {exc.get('expires_at')}): {'; '.join(violations)}"])
        return finish(0)
    for v in violations:
        lines_out.append(f"::error::{v}")
    return finish(1)


if __name__ == "__main__":
    sys.exit(main())
