#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# validate-security-governance.sh
#
# Valida a configuração versionada de governança de segurança (SPEC 007,
# issue #450) — publicado como o check obrigatório `governance-config` pelo
# workflow .github/workflows/pr-quality-gates.yml.
#
# Verifica, sem chamar a API do GitHub e sem ler secrets:
#   1. .github/security-governance.json — estrutura, mínimos da política
#      (>= 1 aprovador, force push/deleção bloqueados, cobertura >= 80% ou
#      "not-applicable" justificado) e coerência entre comandos declarados e
#      required status checks (nenhum check "N/A" pode ser exigido).
#   2. .github/security-exceptions.json — campos obrigatórios, datas, prazo
#      máximo de 90 dias e exceções vencidas (falha).
#   3. .github/workflows/*.yml — nenhuma Action com @latest/@main/@master ou
#      sem versão; workflows de governança gerenciados precisam de SHA
#      completo (40 hex) e bloco `permissions:` no topo.
#   4. .github/dependency-review-config.yml — severidade mínima high ou mais
#      restritiva.
#   5. .github/dependabot.yml — `version: 2`.
#
# Uso:
#   bash scripts/validate-security-governance.sh [--root DIR] [--today YYYY-MM-DD]
#
# Exit code: 0 quando válido; 1 quando qualquer violação bloqueante existir.
###############################################################################

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TODAY="${VALIDATE_TODAY:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root) ROOT_DIR="$2"; shift 2 ;;
    --today) TODAY="$2"; shift 2 ;;
    -h|--help)
      sed -n '4,27p' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    *) echo "Argumento desconhecido: $1" >&2; exit 1 ;;
  esac
done

python3 - "$ROOT_DIR" "$TODAY" <<'PY'
import datetime as dt
import json
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
today = dt.date.fromisoformat(sys.argv[2]) if sys.argv[2] else dt.datetime.now(dt.timezone.utc).date()

errors = []
warnings = []

# Workflows mantidos por esta governança: exigem SHA completo e permissions.
MANAGED_WORKFLOWS = {
    "pr-quality-gates.yml",
    "codeql.yml",
    "dependency-review.yml",
    "secret-scan.yml",
    "security-compliance-scan.yml",
}
CATEGORIES = {"build", "unit_tests", "integration_tests", "coverage", "sast", "sca", "secret_scanning", "governance"}
SEVERITY_ORDER = ["low", "moderate", "high", "critical"]
MAX_EXCEPTION_DAYS = 90


def err(msg):
    errors.append(msg)


def load_json(path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        err(f"{path.relative_to(root)}: arquivo obrigatório ausente")
    except json.JSONDecodeError as exc:
        err(f"{path.relative_to(root)}: JSON inválido ({exc})")
    return None


def is_str_list(value):
    return isinstance(value, list) and all(isinstance(v, str) and v.strip() for v in value)


# --- 2. Exceções (carregadas antes: outras regras podem depender delas) ------
exceptions_path = root / ".github" / "security-exceptions.json"
active_controls = set()
exc_doc = load_json(exceptions_path)
if exc_doc is not None:
    items = exc_doc.get("exceptions")
    if not isinstance(items, list):
        err("security-exceptions.json: campo 'exceptions' deve ser uma lista")
        items = []
    seen = set()
    required_fields = ["id", "control", "owner", "justification", "approved_by", "created_at", "expires_at"]
    for idx, item in enumerate(items):
        label = f"security-exceptions.json[{idx}]"
        if not isinstance(item, dict):
            err(f"{label}: entrada deve ser objeto")
            continue
        missing = [f for f in required_fields if not str(item.get(f, "")).strip()]
        if missing:
            err(f"{label}: campos obrigatórios ausentes: {', '.join(missing)}")
            continue
        if item["id"] in seen:
            err(f"{label}: id duplicado '{item['id']}'")
        seen.add(item["id"])
        try:
            created = dt.date.fromisoformat(item["created_at"])
            expires = dt.date.fromisoformat(item["expires_at"])
        except ValueError:
            err(f"{label} ({item['id']}): datas devem estar em YYYY-MM-DD")
            continue
        if expires < created:
            err(f"{label} ({item['id']}): expires_at anterior a created_at")
        elif (expires - created).days > MAX_EXCEPTION_DAYS:
            err(f"{label} ({item['id']}): prazo de {(expires - created).days} dias excede o máximo de {MAX_EXCEPTION_DAYS}")
        if expires < today:
            err(f"{label} ({item['id']}): exceção EXPIRADA em {expires.isoformat()} — renovar com nova aprovação ou remover e corrigir o controle '{item['control']}'")
        else:
            active_controls.add(item["control"])
        if item["owner"].strip() == item["approved_by"].strip():
            warnings.append(f"{label} ({item['id']}): owner e approved_by são a mesma pessoa — prefira segregação de funções")

# --- 1. security-governance.json --------------------------------------------
cfg_path = root / ".github" / "security-governance.json"
cfg = load_json(cfg_path)
if cfg is not None:
    if cfg.get("schema_version") != 1:
        err("security-governance.json: schema_version deve ser 1")

    branches = cfg.get("branches") or {}
    if not isinstance(branches.get("default_branch"), str) or not branches.get("default_branch"):
        err("security-governance.json: branches.default_branch obrigatório ('auto' ou nome da branch)")
    for key in ("production_branches", "protected_patterns", "additional_branches"):
        if not isinstance(branches.get(key), list) or not all(isinstance(v, str) for v in branches.get(key, [])):
            err(f"security-governance.json: branches.{key} deve ser lista de strings")
    if not branches.get("production_branches"):
        err("security-governance.json: branches.production_branches não pode ser vazio")

    rules = cfg.get("branch_rules") or {}
    approvals = rules.get("required_approving_review_count")
    if not isinstance(approvals, int) or approvals < 1:
        err("security-governance.json: branch_rules.required_approving_review_count deve ser inteiro >= 1")
    for flag in ("dismiss_stale_reviews", "block_direct_push", "block_force_push", "block_deletion", "require_status_checks"):
        if rules.get(flag) is not True:
            if "branch-rules" in active_controls:
                warnings.append(f"branch_rules.{flag}=false aceito por exceção ativa 'branch-rules'")
            else:
                err(f"security-governance.json: branch_rules.{flag} deve ser true (mínimo da política)")
    if rules.get("merge_queue") not in ("optional", "required", "disabled"):
        err("security-governance.json: branch_rules.merge_queue deve ser optional|required|disabled")

    checks = cfg.get("required_status_checks")
    if not isinstance(checks, dict):
        err("security-governance.json: required_status_checks deve ser objeto categoria -> lista")
        checks = {}
    for cat, contexts in checks.items():
        if cat not in CATEGORIES:
            err(f"security-governance.json: categoria de check desconhecida '{cat}'")
        if not isinstance(contexts, list) or not all(isinstance(c, str) and c.strip() for c in contexts):
            err(f"security-governance.json: required_status_checks.{cat} deve ser lista de strings não vazias")
    for mandatory in ("build", "unit_tests", "sast", "sca", "secret_scanning"):
        if not checks.get(mandatory):
            if f"required-check:{mandatory}" in active_controls:
                warnings.append(f"required_status_checks.{mandatory} vazio aceito por exceção ativa")
            else:
                err(f"security-governance.json: required_status_checks.{mandatory} não pode ser vazio (política mínima de PR)")

    gates = cfg.get("quality_gates") or {}
    for cat in ("build", "unit_tests", "integration_tests"):
        gate = gates.get(cat) or {}
        command = str(gate.get("command", "")).strip()
        if not command:
            if not str(gate.get("not_applicable_reason", "")).strip():
                err(f"security-governance.json: quality_gates.{cat} sem command exige not_applicable_reason")
            if checks.get(cat):
                err(f"security-governance.json: quality_gates.{cat} está N/A mas required_status_checks.{cat} exige {checks.get(cat)} — um check N/A não pode ser obrigatório")

    cov = cfg.get("coverage") or {}
    mode = cov.get("mode")
    if mode not in ("report", "not-applicable"):
        err("security-governance.json: coverage.mode deve ser 'report' ou 'not-applicable'")
    for key in ("global_min_percent", "diff_min_percent"):
        value = cov.get(key)
        if not isinstance(value, (int, float)) or not 0 <= value <= 100:
            err(f"security-governance.json: coverage.{key} deve estar entre 0 e 100")
        elif value < 80 and "coverage" not in active_controls:
            err(f"security-governance.json: coverage.{key}={value} abaixo do mínimo de 80% sem exceção ativa 'coverage'")
    if mode == "not-applicable":
        if not str(cov.get("not_applicable_reason", "")).strip():
            err("security-governance.json: coverage.mode=not-applicable exige not_applicable_reason")
        if checks.get("coverage"):
            err("security-governance.json: coverage N/A não pode constar em required_status_checks.coverage")
        if not checks.get("unit_tests"):
            err("security-governance.json: coverage N/A exige a suíte de testes (unit_tests) como gate obrigatório")
    elif mode == "report":
        if not str(cov.get("report_path", "")).strip():
            err("security-governance.json: coverage.mode=report exige report_path")
        if not checks.get("coverage"):
            err("security-governance.json: coverage.mode=report exige required_status_checks.coverage (ex.: ['coverage'])")
        if cov.get("report_format", "auto") not in ("auto", "lcov", "cobertura"):
            err("security-governance.json: coverage.report_format deve ser auto|lcov|cobertura")
    if cov.get("allow_decrease_without_exception") is not False:
        err("security-governance.json: coverage.allow_decrease_without_exception deve ser false")

    codeql = cfg.get("codeql") or {}
    if not is_str_list(codeql.get("languages", [])) or not codeql.get("languages"):
        err("security-governance.json: codeql.languages deve listar ao menos uma linguagem suportada")
    sev = codeql.get("blocking_security_severities", [])
    if not {"critical", "high"}.issubset(set(sev)):
        if "codeql-alerts" not in active_controls:
            err("security-governance.json: codeql.blocking_security_severities deve incluir critical e high")

    dr = cfg.get("dependency_review") or {}
    if dr.get("unsupported_behavior") not in ("fail", "advisory"):
        err("security-governance.json: dependency_review.unsupported_behavior deve ser fail|advisory")
    elif dr.get("unsupported_behavior") == "advisory" and "dependency-review-enabled" not in active_controls:
        err("security-governance.json: dependency_review.unsupported_behavior=advisory exige exceção ativa 'dependency-review-enabled'")

    ss = cfg.get("secret_scanning") or {}
    for key in ("require_secret_scanning", "require_push_protection"):
        if ss.get(key) is not True:
            err(f"security-governance.json: secret_scanning.{key} deve ser true")

# --- 3. Workflows ----------------------------------------------------------
wf_dir = root / ".github" / "workflows"
uses_re = re.compile(r"^\s*-?\s*uses:\s*['\"]?([^'\"\s#]+)")
for wf in sorted(wf_dir.glob("*.y*ml")):
    text = wf.read_text(encoding="utf-8")
    managed = wf.name in MANAGED_WORKFLOWS
    if not re.search(r"^permissions:", text, re.MULTILINE):
        (err if managed else warnings.append)(f"{wf.name}: bloco 'permissions:' de topo ausente")
    for line_no, line in enumerate(text.splitlines(), start=1):
        match = uses_re.match(line)
        if not match:
            continue
        ref = match.group(1)
        if ref.startswith("./") or ref.startswith("docker://"):
            continue
        if "@" not in ref:
            err(f"{wf.name}:{line_no}: Action sem versão fixada ({ref})")
            continue
        version = ref.rsplit("@", 1)[1]
        if version in ("latest", "main", "master", "HEAD"):
            err(f"{wf.name}:{line_no}: Action com referência móvel proibida ({ref})")
        elif not re.fullmatch(r"[0-9a-f]{40}", version):
            (err if managed else warnings.append)(f"{wf.name}:{line_no}: Action fixada por tag, não por SHA ({ref})")

# --- 4. Dependency Review config --------------------------------------------
dr_path = root / ".github" / "dependency-review-config.yml"
if dr_path.exists():
    match = re.search(r"^fail-on-severity:\s*(\w+)", dr_path.read_text(encoding="utf-8"), re.MULTILINE)
    if not match or match.group(1) not in SEVERITY_ORDER:
        err("dependency-review-config.yml: fail-on-severity ausente ou inválido")
    elif SEVERITY_ORDER.index(match.group(1)) > SEVERITY_ORDER.index("high") and "dependency-review" not in active_controls:
        err(f"dependency-review-config.yml: fail-on-severity={match.group(1)} é mais permissivo que 'high' sem exceção ativa")
else:
    err(".github/dependency-review-config.yml: arquivo obrigatório ausente")

# --- 5. Dependabot -----------------------------------------------------------
dependabot = root / ".github" / "dependabot.yml"
if not dependabot.exists():
    err(".github/dependabot.yml: arquivo obrigatório ausente (Dependabot version updates)")
elif not re.search(r"^version:\s*2\s*$", dependabot.read_text(encoding="utf-8"), re.MULTILINE):
    err(".github/dependabot.yml: 'version: 2' obrigatório")

for w in warnings:
    print(f"::warning::{w}")
for e in errors:
    print(f"::error::{e}")

if errors:
    print(f"✗ Governança de segurança inválida: {len(errors)} erro(s), {len(warnings)} aviso(s).")
    sys.exit(1)
print(f"✓ Governança de segurança válida ({len(warnings)} aviso(s) não bloqueante(s)).")
PY
