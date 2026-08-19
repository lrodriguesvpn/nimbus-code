#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/normalize-github-issues.sh [--repo owner/repo] [--issue NUMBER] [--all] [--dry-run]

Normalizes GitHub issue bodies to the Nimbus-Code hybrid task contract.
If --issue is omitted, open issues are normalized.
EOF
}

repo=""
issue_number=""
all=false
dry_run=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      repo="${2:-}"
      shift 2
      ;;
    --issue)
      issue_number="${2:-}"
      shift 2
      ;;
    --all)
      all=true
      shift
      ;;
    --dry-run)
      dry_run=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

command -v gh >/dev/null 2>&1 || { echo "gh CLI is required" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "python3 is required" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq is required" >&2; exit 1; }

if [[ -z "$repo" ]]; then
  repo="$(git config --get remote.origin.url | sed -E 's#.*github.com[/:]([^/]+/[^/.]+)(\.git)?#\1#')"
fi

if [[ -z "$repo" ]]; then
  echo "Unable to resolve repository. Pass --repo owner/name." >&2
  exit 1
fi

normalize_one() {
  local issue_json="$1"
  python3 - "$issue_json" <<'PY'
import json
import re
import sys

issue = json.loads(sys.argv[1])
body = issue.get("body") or ""
body = body.replace("\\r\\n", "\n").replace("\\n", "\n")
title = issue.get("title") or f"Issue #{issue.get('number')}"
labels = [label.get("name", "") for label in issue.get("labels", [])]

required_sections = [
    "Contexto",
    "Objetivo",
    "Resultado Esperado",
    "Critérios de Aceite",
    "Passos Operacionais",
    "Dependências",
    "Responsável",
    "Estimativa de Esforço",
    "Referência",
]

def parse_sections(markdown: str):
    """Parse markdown sections (## Heading), handling escaped newlines correctly."""
    # First, decode any literal escaped newlines that may exist
    markdown = markdown.replace("\\n", "\n")
    sections = {}
    current = None
    buffer = []
    for line in markdown.splitlines():
        match = re.match(r"^##\s+(.+?)\s*$", line)
        if match:
            if current is not None:
                sections[current] = "\n".join(buffer).strip()
            current = match.group(1).strip()
            buffer = []
            continue
        if current is not None:
            buffer.append(line)
    if current is not None:
        sections[current] = "\n".join(buffer).strip()
    return sections

def has_format_issues(sections: dict, body: str) -> bool:
    """Check if the formatted sections have common issues (duplicated headings, etc)."""
    # Check for double ## Contexto
    if body.count("## Contexto") > 1:
        return True
    # Check for literal escaped newlines in section content
    for section_name, content in sections.items():
        if "\\n" in content:
            return True
    return False

sections = parse_sections(body)
if all(sections.get(name) for name in required_sections) and not has_format_issues(sections, body):
    print("UNCHANGED")
    sys.exit(0)

def strip_text(text: str):
    """Strip and clean text: decode escapes, remove heading markers, trim whitespace."""
    text = text.replace("\\r\\n", "\n").replace("\\n", "\n")
    # Remove markdown headings and "Contexto" marker if present
    text = re.sub(r"^#+\s*(Contexto|Context)?\s*\n?", "", text, flags=re.IGNORECASE | re.MULTILINE)
    # Remove leading/trailing whitespace from each line and overall
    return "\n".join(line.rstrip() for line in text.splitlines()).strip()

context = sections.get("Contexto") or strip_text(body.strip()) or "Descreva aqui o contexto."
objective = sections.get("Objetivo")
if not objective:
    cleaned_title = re.sub(r"^\[[^\]]+\]\s*", "", title).strip()
    objective = cleaned_title

result = sections.get("Resultado Esperado")
if not result:
    # Try to synthesize from context and objective if not explicitly provided
    has_m365 = any(keyword.lower() in body.lower() for keyword in ["m365", "sharepoint", "copilot"])
    has_workflow = any(keyword.lower() in body.lower() for keyword in ["workflow", "automação", "pipeline"])
    has_manual = any(keyword.lower() in body.lower() for keyword in ["danilo", "manual", "configuração"])
    
    if has_m365 and has_manual:
        result = f"Configurações M365 aplicadas conforme documentação técnica com evidência de implementação registrada."
    elif has_workflow or has_m365:
        result = f"Solução implementada, versionada, testada em ambiente real e documentada."
    else:
        result = "Entregável atualizado para o novo contrato híbrido, com instruções claras para execução humana e acompanhamento por agente."

steps = sections.get("Passos Operacionais") or sections.get("Ações") or sections.get("Escopo sugerido")
if not steps:
    # Try to synthesize from detected patterns
    if any(keyword.lower() in body.lower() for keyword in ["sharepoint", "m365", "danilo"]):
        steps = "1. Revisar documentação técnica e requisitos.\n2. Aplicar configurações conforme guia.\n3. Validar implementação e registrar evidências.\n4. Informar resultado neste issue."
    elif any(keyword.lower() in body.lower() for keyword in ["workflow", "automação", "pipeline"]):
        steps = "1. Definir gatilho e escopo de automação.\n2. Implementar e versionar código/configuração.\n3. Testar em ambiente real/sandbox.\n4. Registrar resultado e logs de execução."
    else:
        steps = "1. Revisar o contexto e o objetivo.\n2. Executar a mudança descrita.\n3. Validar o resultado e registrar evidências."

criteria = sections.get("Critérios de Aceite") or sections.get("Critérios de aceite")
if not criteria:
    criteria = "- [ ] A issue deve estar no novo formato híbrido.\n- [ ] O contexto deve permitir execução sem leitura adicional."

deps = sections.get("Dependências") or sections.get("Dependência") or "Nenhuma"

responsavel = sections.get("Responsável")
if not responsavel:
    human_only = any(keyword.lower() in body.lower() for keyword in ["danilo", "sharepoint", "copilot"]) or "type:incident" in " ".join(labels)
    if human_only:
        responsavel = "Agente: não\nHumano: sim"
    else:
        responsavel = "Agente: sim\nHumano: sim"

estimate = sections.get("Estimativa de Esforço")
if not estimate:
    if any("complexity:s2" == label.lower() for label in labels) or "workflow" in title.lower() or "automação" in title.lower():
        estimate = "- Tokens (agente): ~2–4 mil\n- Horas (humano): ~2–4 horas"
    elif any(keyword.lower() in title.lower() for keyword in ["danilo", "sharepoint", "copilot", "m365"]):
        estimate = "- Tokens (agente): ~1–2 mil\n- Horas (humano): ~1–2 horas"
    else:
        estimate = "- Tokens (agente): ~1–3 mil\n- Horas (humano): ~1–2 horas"

reference = sections.get("Referência")
if not reference:
    if "specs/005-hybrid-agent-human-dev" in body:
        reference = "- AC-ID: N/A\n- Feature: specs/005-hybrid-agent-human-dev\n- SPEC KIT COST: https://github.com/venha-pra-nuvem/spec-kit-cost"
    elif any(keyword.lower() in body.lower() for keyword in ["docs/ai-governance", "m365"]):
        reference = "- AC-ID: N/A\n- Feature: docs/ai-governance\n- SPEC KIT COST: https://github.com/venha-pra-nuvem/spec-kit-cost"
    else:
        reference = "- AC-ID: N/A\n- Feature: N/A\n- SPEC KIT COST: https://github.com/venha-pra-nuvem/spec-kit-cost"

normalized = "\n".join([
    "## Contexto",
    strip_text(context),
    "",
    "## Objetivo",
    strip_text(objective),
    "",
    "## Resultado Esperado",
    strip_text(result),
    "",
    "## Critérios de Aceite",
    strip_text(criteria),
    "",
    "## Passos Operacionais",
    strip_text(steps),
    "",
    "## Dependências",
    strip_text(deps),
    "",
    "## Responsável",
    strip_text(responsavel),
    "",
    "## Estimativa de Esforço",
    strip_text(estimate),
    "",
    "## Referência",
    strip_text(reference),
])

print(normalized)
PY
}

issue_jsons=()
if [[ -n "$issue_number" ]]; then
  issue_jsons+=("$(gh issue view "$issue_number" --repo "$repo" --json number,title,body,labels)")
elif [[ "$all" == true ]]; then
  while IFS= read -r issue; do
    issue_jsons+=("$issue")
  done < <(gh issue list --repo "$repo" --state all --limit 100 --json number,title,body,labels | jq -c '.[]')
else
  while IFS= read -r issue; do
    issue_jsons+=("$issue")
  done < <(gh issue list --repo "$repo" --state open --limit 100 --json number,title,body,labels | jq -c '.[]')
fi

if [[ ${#issue_jsons[@]} -eq 0 ]]; then
  echo "No issues found."
  exit 0
fi

for issue_json in "${issue_jsons[@]}"; do
  issue_number_current="$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["number"])' "$issue_json")"
  title_current="$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["title"])' "$issue_json")"
  normalized_body="$(normalize_one "$issue_json")"

  if [[ "$normalized_body" == "UNCHANGED" ]]; then
    echo "Issue #$issue_number_current already uses the new format, skipping."
    continue
  fi

  if [[ "$dry_run" == true ]]; then
    echo "Would update issue #$issue_number_current: $title_current"
    continue
  fi

  tmp_file="$(mktemp)"
  printf '%s\n' "$normalized_body" > "$tmp_file"
  gh issue edit "$issue_number_current" --repo "$repo" --body-file "$tmp_file" >/dev/null
  rm -f "$tmp_file"
  echo "Updated issue #$issue_number_current: $title_current"
done
