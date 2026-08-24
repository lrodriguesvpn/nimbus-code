#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/normalize-github-issues.sh [--repo owner/repo] [--issue NUMBER] [--all] [--dry-run] [--force-reclassify]

Normalizes GitHub issue bodies to the Nimbus-Code hybrid task contract and
reconciles mandatory Task labels (`priority:*`, `complexity:*`, `type:task`,
`agent:*`) when the issue title matches `T00N`.
If --issue is omitted, open issues are normalized.
EOF
}

repo=""
issue_number=""
all=false
dry_run=false
force_reclassify=false

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
    --force-reclassify)
      force_reclassify=true
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
  repo="$(git config --get remote.origin.url | sed -E 's#^(https?://[^/]+/|git@[^:]+:)?([^/]+/[^/.]+)(\.git)?$#\2#')"
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

GENERIC_RESULT = (
    "Entregável atualizado para o novo contrato híbrido, com instruções claras para execução humana e acompanhamento por agente."
)
GENERIC_CRITERIA = (
    "- [ ] A issue deve estar no novo formato híbrido.\n- [ ] O contexto deve permitir execução sem leitura adicional."
)
GENERIC_STEPS = (
    "1. Revisar o contexto e o objetivo.\n2. Executar a mudança descrita.\n3. Validar o resultado e registrar evidências."
)

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

def canonical(text: str) -> str:
    return re.sub(r"\s+", " ", (text or "").strip()).lower()

def get_section(sections: dict, *names: str):
    """Look up a section by any of its known spelling variants (accents, aliases)."""
    for name in names:
        value = sections.get(name)
        if value:
            return value
    return None

def extract_inline_field(text: str, field: str):
    """Extract an inline bold field like '**Responsável**: Agente' embedded inside a section body."""
    if not text:
        return None
    match = re.search(rf"\*\*{re.escape(field)}\*\*:\s*(.+)", text)
    return match.group(1).strip() if match else None

def strip_inline_field(text: str, field: str) -> str:
    """Remove an inline bold field line from a section body, leaving the rest intact."""
    if not text:
        return text
    return re.sub(rf"\n?\*\*{re.escape(field)}\*\*:\s*.+\n?", "\n", text).strip()

def strip_spec_kit_cost_line(text: str) -> str:
    """Remove only the SPEC KIT COST reference line, preserving any other reference lines."""
    if not text:
        return text
    lines = [line for line in text.splitlines() if "spec-kit-cost" not in line.lower()]
    return "\n".join(lines).strip()

def has_generic_content(sections: dict) -> bool:
    if canonical(sections.get("Resultado Esperado", "")) == canonical(GENERIC_RESULT):
        return True
    if canonical(sections.get("Critérios de Aceite", "")) == canonical(GENERIC_CRITERIA):
        return True
    if canonical(sections.get("Passos Operacionais", "")) == canonical(GENERIC_STEPS):
        return True
    if "spec-kit-cost" in (get_section(sections, "Referência", "Referencia") or "").lower():
        return True
    # Section headers present under a non-accented/alias spelling (e.g. "Referencia",
    # "Descrição" without the task's own "Objetivo") mean the contract isn't actually
    # satisfied yet, even though `all(sections.get(name) ...)` would miss this.
    if sections.get("Escopo") and "Escopo" not in required_sections:
        return True
    if (sections.get("Descrição") or sections.get("Descricao")) and not sections.get("Objetivo"):
        return True
    if sections.get("Referencia") and not sections.get("Referência"):
        return True
    return False

sections = parse_sections(body)
if (
    all(sections.get(name) for name in required_sections)
    and not has_format_issues(sections, body)
    and not has_generic_content(sections)
):
    print("UNCHANGED")
    sys.exit(0)

def strip_text(text: str):
    """Strip and clean text: decode escapes, remove heading markers, trim whitespace."""
    text = text.replace("\\r\\n", "\n").replace("\\n", "\n")
    # Remove markdown headings and "Contexto" marker if present
    text = re.sub(r"^#+\s*(Contexto|Context)?\s*\n?", "", text, flags=re.IGNORECASE | re.MULTILINE)
    # Remove leading/trailing whitespace from each line and overall
    return "\n".join(line.rstrip() for line in text.splitlines()).strip()

context = sections.get("Contexto")
if not context:
    # When there's no explicit "## Contexto", prefer a short, non-duplicated context
    # over dumping the raw body (which would repeat "Descrição"/"Referência" verbatim
    # and duplicate content already placed into Objetivo/Referência below).
    descricao_preview = sections.get("Descrição") or sections.get("Descricao")
    feature_match = re.search(r"Feature:\s*(\S+)", body)
    if descricao_preview and feature_match:
        context = f"Task técnica derivada de {feature_match.group(1)} (ver Referência)."
    else:
        context = strip_text(body.strip()) or "Descreva aqui o contexto."
context = strip_inline_field(context, "Responsável")
context = strip_inline_field(context, "Priority")
context = strip_inline_field(context, "User Story")

# Preserve "## Escopo" (Epic-level issues) instead of discarding it — fold it into Contexto.
escopo = sections.get("Escopo")
if escopo and canonical(escopo) not in canonical(context):
    context = f"{context}\n\n**Escopo**:\n{escopo}"

descricao = sections.get("Descrição") or sections.get("Descricao")
if descricao:
    descricao = strip_inline_field(descricao, "Responsável")
    descricao = strip_inline_field(descricao, "User Story")

objective = sections.get("Objetivo")
if not objective:
    # T-level task issues carry the actual action under "## Descrição" — reuse it
    # verbatim instead of falling back to a generic title-derived objective.
    objective = descricao or re.sub(r"^\[[^\]]+\]\s*", "", title).strip()

result = sections.get("Resultado Esperado")
if not result or canonical(result) == canonical(GENERIC_RESULT):
    # Try to synthesize from context and objective if not explicitly provided.
    # NOTE: "has_workflow" must require actual M365/SharePoint co-occurrence — a bare
    # "workflow" match also fires on unrelated strings like ".github/workflows/*.yml",
    # which would otherwise mislabel any CI/CD task as M365 SharePoint sync.
    has_m365 = any(keyword.lower() in body.lower() for keyword in ["m365", "sharepoint", "copilot"])
    has_workflow = has_m365 and any(keyword.lower() in body.lower() for keyword in ["workflow", "automação", "pipeline"])
    has_manual = any(keyword.lower() in body.lower() for keyword in ["danilo", "manual", "configuração"])

    if has_m365 and has_manual:
        result = "Configurações M365 Copilot aplicadas conforme documentação, com evidências e URL final de publicação no SharePoint registrada."
    elif has_workflow:
        result = "Workflow de sincronização da constituição M365 para SharePoint implementado, parametrizado e com rastreabilidade de execução."
    elif has_m365:
        result = "Operação de governança M365/SharePoint concluída conforme escopo definido e validada com evidências."
    elif objective and objective != title:
        result = f"\"{objective.splitlines()[0].strip()}\" implementado, testado e validado conforme os critérios de aceite da feature de origem."
    else:
        result = "Entregável atualizado para o novo contrato híbrido, com instruções claras para execução humana e acompanhamento por agente."

steps = sections.get("Passos Operacionais") or sections.get("Ações") or sections.get("Escopo sugerido")
if not steps or canonical(steps) == canonical(GENERIC_STEPS):
    # Try to synthesize from detected patterns
    if any(keyword.lower() in body.lower() for keyword in ["workflow", "automação", "pipeline"]):
        steps = "1. Definir gatilho e escopo de automação.\n2. Implementar e versionar código/configuração.\n3. Testar em ambiente real/sandbox.\n4. Registrar resultado e logs de execução."
    elif any(keyword.lower() in body.lower() for keyword in ["sharepoint", "m365", "danilo"]):
        steps = "1. Revisar documentação técnica e requisitos.\n2. Aplicar configurações conforme guia.\n3. Validar implementação e registrar evidências.\n4. Informar resultado neste issue."
    else:
        steps = "1. Revisar o contexto e o objetivo.\n2. Executar a mudança descrita.\n3. Validar o resultado e registrar evidências."

criteria = sections.get("Critérios de Aceite") or sections.get("Critérios de aceite")
if not criteria or canonical(criteria) == canonical(GENERIC_CRITERIA):
    if any(keyword.lower() in body.lower() for keyword in ["workflow", "automação", "pipeline"]):
        criteria = "- [ ] Workflow versionado no repositório e com gatilho definido.\n- [ ] Parâmetros/segredos documentados e validados.\n- [ ] Execução de teste registrada com status de sucesso/falha."
    elif any(keyword.lower() in body.lower() for keyword in ["sharepoint", "m365", "danilo"]):
        criteria = "- [ ] Configurações e/ou automações M365 aplicadas conforme documentação.\n- [ ] Evidências registradas no issue (logs, prints ou checklist técnico).\n- [ ] URL final do SharePoint informada quando aplicável."
    else:
        criteria = "- [ ] Contexto e objetivo estão claros para execução humana.\n- [ ] Entregável definido e verificável."

deps = sections.get("Dependências") or sections.get("Dependência") or "Nenhuma"

responsavel = sections.get("Responsável")
if not responsavel:
    # T-level task issues carry this as an inline bold field, not its own heading.
    inline_responsavel = extract_inline_field(descricao or body, "Responsável")
    if inline_responsavel:
        is_agente = "agente" in inline_responsavel.lower()
        is_humano = "humano" in inline_responsavel.lower()
        responsavel = f"Agente: {'sim' if is_agente else 'não'}\nHumano: {'sim' if is_humano or not is_agente else 'não'}"
    else:
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

reference = get_section(sections, "Referência", "Referencia")
if reference:
    reference = strip_spec_kit_cost_line(reference)
    inline_user_story = extract_inline_field(descricao or body, "User Story")
    if inline_user_story and inline_user_story.lower() not in reference.lower():
        reference = f"{reference}\n- User Story: {inline_user_story}"
if not reference:
    if "specs/016-hybrid-agent-human-dev" in body:
        reference = "- AC-ID: N/A\n- Feature: specs/016-hybrid-agent-human-dev"
    elif any(keyword.lower() in body.lower() for keyword in ["docs/ai-governance", "m365"]):
        reference = "- AC-ID: N/A\n- Feature: docs/ai-governance"
    else:
        reference = "- AC-ID: N/A\n- Feature: N/A"

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

reconcile_task_labels() {
  local issue_json="$1"
  local force_mode="$2"
  python3 - "$issue_json" "$force_mode" <<'PY'
import json
import re
import sys

issue = json.loads(sys.argv[1])
force_reclassify = sys.argv[2].lower() == "true"
title = issue.get("title") or ""
body = (issue.get("body") or "").replace("\\r\\n", "\n").replace("\\n", "\n")
labels = []
for label in issue.get("labels", []):
    if isinstance(label, dict):
        labels.append(label.get("name", ""))
    else:
        labels.append(str(label))

if not re.search(r"\bT\d{3}\b", title):
    print(json.dumps({"add": [], "remove": []}))
    sys.exit(0)

text = f"{title}\n{body}".lower()

def find_family(prefix):
    return next((label for label in labels if label.startswith(prefix)), None)

def infer_priority():
    if "p0-blocker" in text or re.search(r"\bpriority:\s*p0\b", text):
        return "priority:P0-blocker"
    match = re.search(r"\bpriority:\s*p([123])\b", text)
    if match:
        return {
            "1": "priority:P1-high",
            "2": "priority:P2-medium",
            "3": "priority:P3-low",
        }[match.group(1)]
    return "priority:P2-medium"

def infer_complexity():
    if any(keyword in text for keyword in [
        "github app", "security", "org-wide", "organization", "organização",
        "permission", "permiss", "oauth", "credential", "secret",
        "branch protection", "administra", "governança"
    ]):
        return "complexity:S4"
    if any(keyword in text for keyword in [
        "cross-repo", "multi-repo", "graphql", "project v2", "sub-issue",
        "workflow orchestration", "integração", "integration", "board"
    ]):
        return "complexity:S3"
    if any(keyword in text for keyword in [
        "database", "migration", "endpoint", "schema", "api ", " api",
        "workflow", ".yml", ".yaml", ".json", ".ts", ".go", ".py", ".sh"
    ]):
        return "complexity:S2"
    if any(keyword in text for keyword in [
        "document", "documentar", "guia", "guide", "quickstart", "readme",
        "checklist", ".md", "cenário", "cenario", "validar"
    ]):
        return "complexity:S0"
    return "complexity:S1"

def infer_agent():
    if any(keyword in text for keyword in [
        "[humano]", "humano", "manual", "github app", "security", "org-wide",
        "organization settings", "permiss", "oauth", "credential", "secret"
    ]):
        return "agent:needs-human"
    return "agent:autonomous-ok"

desired = {
    "priority:": infer_priority(),
    "complexity:": infer_complexity(),
    "type:": "type:task",
    "agent:": infer_agent(),
}

to_add = []
to_remove = []
for family, wanted in desired.items():
    current = find_family(family)
    if current:
        if force_reclassify and current != wanted:
            to_remove.append(current)
            to_add.append(wanted)
        continue
    to_add.append(wanted)

print(json.dumps({"add": to_add, "remove": to_remove}))
PY
}

list_issues_paginated() {
  local state="$1"
  gh api --paginate "repos/${repo}/issues?state=${state}&per_page=100" \
    --jq '.[] | select(.pull_request | not) | {number, title, body, labels}' | jq -c .
}

issue_jsons=()
if [[ -n "$issue_number" ]]; then
  issue_jsons+=("$(gh issue view "$issue_number" --repo "$repo" --json number,title,body,labels)")
elif [[ "$all" == true ]]; then
  while IFS= read -r issue; do
    issue_jsons+=("$issue")
  done < <(list_issues_paginated all)
else
  while IFS= read -r issue; do
    issue_jsons+=("$issue")
  done < <(list_issues_paginated open)
fi

if [[ ${#issue_jsons[@]} -eq 0 ]]; then
  echo "No issues found."
  exit 0
fi

for issue_json in "${issue_jsons[@]}"; do
  issue_number_current="$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["number"])' "$issue_json")"
  title_current="$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["title"])' "$issue_json")"
  normalized_body="$(normalize_one "$issue_json")"
  label_plan="$(reconcile_task_labels "$issue_json" "$force_reclassify")"
  labels_to_add="$(python3 -c 'import json,sys; print(",".join(json.loads(sys.argv[1])["add"]))' "$label_plan")"
  labels_to_remove="$(python3 -c 'import json,sys; print(",".join(json.loads(sys.argv[1])["remove"]))' "$label_plan")"

  if [[ "$normalized_body" == "UNCHANGED" && -z "$labels_to_add" && -z "$labels_to_remove" ]]; then
    echo "Issue #$issue_number_current already uses the new format, skipping."
    continue
  fi

  if [[ "$dry_run" == true ]]; then
    echo "Would update issue #$issue_number_current: $title_current"
    [[ -n "$labels_to_add" ]] && echo "  add labels: $labels_to_add"
    [[ -n "$labels_to_remove" ]] && echo "  remove labels: $labels_to_remove"
    continue
  fi

  edit_args=(gh issue edit "$issue_number_current" --repo "$repo")
  tmp_file=""
  if [[ "$normalized_body" != "UNCHANGED" ]]; then
    tmp_file="$(mktemp)"
    printf '%s\n' "$normalized_body" > "$tmp_file"
    edit_args+=(--body-file "$tmp_file")
  fi
  [[ -n "$labels_to_add" ]] && edit_args+=(--add-label "$labels_to_add")
  [[ -n "$labels_to_remove" ]] && edit_args+=(--remove-label "$labels_to_remove")
  "${edit_args[@]}" >/dev/null
  [[ -n "$tmp_file" ]] && rm -f "$tmp_file"
  echo "Updated issue #$issue_number_current: $title_current"
done
