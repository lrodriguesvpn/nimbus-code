#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

collect_default_targets() {
  local targets=(
    ".github/workflows/evidence-refresh.yml"
    ".github/workflows/terraform-plan.yml"
    "scripts/validate-no-direct-write-commands.sh"
    "presets/nimbus-code-platform-standards/templates/project-root/.github/workflows/evidence-refresh.yml"
    "presets/nimbus-code-platform-standards/templates/project-root/.github/workflows/terraform-plan.yml"
    "presets/nimbus-code-platform-standards/templates/project-root/.github/workflows/protected-apply.yml"
    "presets/nimbus-code-platform-standards/templates/project-root/scripts/validate-no-direct-write-commands.sh"
  )

  local existing=()
  local target
  for target in "${targets[@]}"; do
    [[ -f "$target" ]] && existing+=("$target")
  done

  printf '%s\n' "${existing[@]}"
}

if [[ "$#" -gt 0 ]]; then
  TARGETS=("$@")
else
  TARGETS=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && TARGETS+=("$line")
  done < <(collect_default_targets)
fi

if [[ "${#TARGETS[@]}" -eq 0 ]]; then
  echo "Nenhum arquivo alvo encontrado para validar." >&2
  exit 1
fi

python3 - "$ROOT_DIR" "${TARGETS[@]}" <<'PY'
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
targets = [Path(p) for p in sys.argv[2:]]
patterns = [
    (re.compile(r'\bterraform\s+(apply|destroy)\b'), 'Terraform com escrita direta'),
    (re.compile(r'\baz\b.*\b(create|delete|update|patch|set|start|stop|restart|purge|recover)\b'), 'Azure CLI com verbo de escrita'),
    (re.compile(r'\baws\b.*\b(create|put|delete|update|modify|attach|detach|associate|disassociate|terminate|run|start|stop|reboot)\b'), 'AWS CLI com verbo de escrita'),
    (re.compile(r'\bgcloud\b.*\b(create|delete|update|deploy|apply|add-iam-policy-binding|remove-iam-policy-binding)\b'), 'gcloud com verbo de escrita'),
    (re.compile(r'\bkubectl\s+(apply|create|delete|edit|patch|replace|scale|set|rollout)\b'), 'kubectl com mutação'),
    (re.compile(r'\bpac\b.*\b(create|update|delete|import|publish|assign)\b'), 'Power Platform CLI com mutação'),
]
violations = []
for target in targets:
    path = target if target.is_absolute() else root / target
    if not path.exists():
        continue
    for line_no, raw_line in enumerate(path.read_text().splitlines(), start=1):
        if re.match(r'^\s*#', raw_line):
            continue
        line = raw_line.strip()
        if not line:
            continue
        for regex, label in patterns:
            if regex.search(line):
                violations.append((str(path.relative_to(root)), line_no, label, line))
                break
if violations:
    print('Foram detectados comandos de escrita direta proibidos:')
    for path, line_no, label, line in violations:
        print(f'- {path}:{line_no}: {label} -> {line}')
    sys.exit(1)
print('Nenhum comando de escrita direta proibido foi detectado nos arquivos informados.')
PY
