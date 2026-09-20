#!/usr/bin/env python3
"""Parse audit inputs and summarize CSV without treating zero matches as failure."""
import argparse
import base64
import csv
import json
from pathlib import Path
import re
import sys

VERSION = r"[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?"
FIELDS = ["repo", "current_version", "drift_status", "last_updated"]


def version(value):
    if not isinstance(value, str) or not re.fullmatch(VERSION, value):
        raise ValueError("Invalid or missing preset version")
    return value


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    manifest = sub.add_parser("version")
    manifest.add_argument("manifest", type=Path)
    sub.add_parser("registry")
    summary = sub.add_parser("summary")
    summary.add_argument("csv", type=Path)
    summary.add_argument("--manifest", required=True, type=Path)
    summary.add_argument("--summary", required=True, type=Path)
    summary.add_argument("--outputs", required=True, type=Path)
    args = parser.parse_args()

    if args.command == "registry":
        response = json.load(sys.stdin)
        content = base64.b64decode("".join(response["content"].split()), validate=True)
        registry = json.loads(content)
        data = registry["presets"]["nimbus-code-standards"] if "presets" in registry else registry
        print(version(data["version"]))
        return

    text = args.manifest.read_text()
    block = re.search(r"(?m)^preset:\s*\n((?:[ \t]+[^\n]*\n|\n)*)", text)
    matches = re.findall(r"(?m)^  version:\s*['\"]?([^'\"\s#]+)['\"]?\s*(?:#.*)?$",
                         block.group(1) if block else "")
    if len(matches) != 1:
        raise ValueError("Missing or ambiguous preset.version")
    central = version(matches[0])
    if args.command == "version":
        print(central)
        return

    counts = dict(in_sync=0, drift=0, not_bootstrapped=0, error=0)
    with args.csv.open(newline="") as source:
        reader = csv.DictReader(source)
        if reader.fieldnames != FIELDS:
            raise ValueError("Unexpected audit CSV header")
        rows = list(reader)
    for row in rows:
        if None in row or any(value is None for value in row.values()):
            raise ValueError("Malformed audit CSV row")
        if row["drift_status"] not in counts:
            raise ValueError("Unknown audit status")
        counts[row["drift_status"]] += 1
    with args.outputs.open("a") as output:
        for key, value in counts.items():
            output.write(f"{'drifted' if key == 'drift' else key}={value}\n")
        output.write(f"central_version={central}\n")
    lines = [f"## Satellite preset audit — {central}", ""]
    lines.extend(f"- {key}: {value}" for key, value in counts.items())
    lines.extend(["", "Read errors are not evidence of missing bootstrap.",
                  "Sync remains disabled by default; manual pilot approval (#433/#445) is required."])
    lines.extend(f"- {row['repo']}: {row['drift_status']}" for row in rows
                 if row["drift_status"] != "in_sync")
    args.summary.write_text("\n".join(lines) + "\n")
    if counts["error"]:
        raise ValueError("Audit incomplete: one or more repositories could not be read")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, KeyError, TypeError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        sys.exit(2)
