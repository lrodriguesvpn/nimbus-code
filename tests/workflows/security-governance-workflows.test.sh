#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# tests/workflows/security-governance-workflows.test.sh
#
# Issue #450 / T057: valida estaticamente os workflows de checks obrigatórios
# de PR (pr-quality-gates, codeql, dependency-review, secret-scan):
#   - triggers pull_request + push na branch padrão (+ schedule quando aplicável);
#   - nomes de job estáveis e coerentes com required_status_checks de
#     .github/security-governance.json (nenhum check exigido sem publicador);
#   - Actions fixadas por SHA completo, nenhum @latest;
#   - permissions explícitas e mínimas; nenhum uso de secrets/PAT;
#   - bloqueios reais (SCA indisponível falha, gitleaks com checksum e --redact).
# Não executa os workflows (execução real depende do GHE/GHAS).
###############################################################################

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WF_DIR="${ROOT_DIR}/.github/workflows"
CONFIG="${ROOT_DIR}/.github/security-governance.json"
QG="${WF_DIR}/pr-quality-gates.yml"
CODEQL="${WF_DIR}/codeql.yml"
DR="${WF_DIR}/dependency-review.yml"
SS="${WF_DIR}/secret-scan.yml"

for f in "$QG" "$CODEQL" "$DR" "$SS" "$CONFIG"; do
  [[ -f "$f" ]] || { echo "✗ ${f} não encontrado"; exit 1; }
done

pass=0
fail=0
check() {
  local description="$1" condition="$2"
  if [[ "$condition" == "true" ]]; then
    echo "  ✓ ${description}"; pass=$((pass + 1))
  else
    echo "  ✗ ${description}"; fail=$((fail + 1))
  fi
}
has() { grep -Eq -- "$2" "$1" && echo true || echo false; }
hasnt() { grep -Eq -- "$2" "$1" && echo false || echo true; }
code_only() { grep -Ev '^[[:space:]]*#' "$1"; }

echo "== tests/workflows/security-governance-workflows.test.sh =="

echo "-- pinagem, permissões e ausência de secrets --"
for wf in "$QG" "$CODEQL" "$DR" "$SS"; do
  name="$(basename "$wf")"
  unpinned=$(grep -E '^\s*-?\s*uses:' "$wf" | grep -Ev 'uses:\s*[^@]+@[0-9a-f]{40}(\s|$)' || true)
  check "${name}: todas as Actions fixadas por SHA completo" "$([[ -z "$unpinned" ]] && echo true || echo false)"
  check "${name}: nenhum @latest" "$(hasnt "$wf" '@latest')"
  check "${name}: bloco permissions de topo" "$(has "$wf" '^permissions:')"
  check "${name}: permissions de topo somente leitura" "$(awk '/^permissions:/{f=1;next} /^[^ ]/{f=0} f' "$wf" | grep -q 'write' && echo false || echo true)"
  check "${name}: não usa secrets/PAT" "$(code_only "$wf" | grep -Eq 'secrets\.' && echo false || echo true)"
  check "${name}: executa em pull_request" "$(has "$wf" '^  pull_request:')"
done

echo "-- triggers --"
for wf in "$QG" "$CODEQL" "$SS"; do
  check "$(basename "$wf"): executa em push na branch padrão" "$(awk '/^  push:/{f=1;next} /^  [a-z_]+:/{f=0} f' "$wf" | grep -q '"main"' && echo true || echo false)"
done
check "codeql.yml: execução semanal (schedule)" "$(has "$CODEQL" 'cron: "[0-9]+ [0-9]+ \* \* [0-6]"')"
check "secret-scan.yml: execução semanal (schedule)" "$(has "$SS" 'cron: "[0-9]+ [0-9]+ \* \* [0-6]"')"
check "pr-quality-gates.yml e codeql.yml suportam merge queue" "$( [[ $(has "$QG" '^  merge_group:') == true && $(has "$CODEQL" '^  merge_group:') == true ]] && echo true || echo false)"
check "dependency-review.yml roda em todo PR (sem filtro de paths — required check sempre reportado)" "$(hasnt "$DR" '^\s+paths:')"

echo "-- nomes estáveis de check coerentes com a configuração --"
all_job_names=$(grep -hE '^    name: ' "$WF_DIR"/*.yml | sed -E 's/^    name: *//; s/^"//; s/"$//')
while IFS= read -r ctx; do
  [[ -z "$ctx" ]] && continue
  if [[ "$ctx" == "CodeQL" ]]; then
    check "required check 'CodeQL' é publicado pelo Code Scanning a partir de codeql.yml" "$(has "$CODEQL" 'github/codeql-action/analyze@')"
    continue
  fi
  check "required check '${ctx}' tem job publicador com nome estável" "$(grep -Fxq -- "$ctx" <<< "$all_job_names" && echo true || echo false)"
done < <(jq -r '.required_status_checks | to_entries[] | .value[]' "$CONFIG")
for job in governance-config build unit-tests integration-tests coverage; do
  check "pr-quality-gates.yml publica o job '${job}'" "$(has "$QG" "^    name: ${job}$")"
done
check "codeql.yml publica 'codeql-analyze (<linguagem>)'" "$(has "$CODEQL" 'name: codeql-analyze \(\$\{\{ matrix.language \}\}\)')"
check "dependency-review.yml publica o job 'dependency-review'" "$(has "$DR" '^    name: dependency-review$')"
check "secret-scan.yml publica o job 'secret-scan'" "$(has "$SS" '^    name: secret-scan$')"

echo "-- comportamento de bloqueio --"
check "quality gates executam comandos declarados na config (extensível por linguagem)" "$(has "$QG" 'bash scripts/run-quality-gate.sh (build|unit_tests|integration_tests)')"
check "coverage usa scripts/coverage-gate.py" "$(has "$QG" 'python3 scripts/coverage-gate.py')"
check "relatório de cobertura publicado como artefato e falha se ausente" "$(has "$QG" 'if-no-files-found: error')"
check "coverage N/A exige justificativa (sem métrica inventada)" "$(has "$QG" 'not_applicable_reason')"
check "codeql.yml: security-events: write somente no job de análise" "$(awk '/^  analyze:/{f=1} f' "$CODEQL" | grep -q 'security-events: write' && awk '/^permissions:/{f=1;next} /^[^ ]/{f=0} f' "$CODEQL" | grep -vq 'security-events' && echo true || echo false)"
check "codeql.yml: linguagens vêm de .github/security-governance.json" "$(has "$CODEQL" '\.codeql\.languages')"
check "dependency-review.yml: usa config versionada" "$(has "$DR" 'config-file: \./\.github/dependency-review-config\.yml')"
check "dependency-review.yml: indisponibilidade falha por padrão (não mascara)" "$(has "$DR" 'behavior="fail"')"
check "dependency-review.yml: caminho de erro sai com exit 1" "$(awk '/Dependency Review indisponível/{f=1} f && /exit 1/{print; exit}' "$DR" | grep -q 'exit 1' && echo true || echo false)"
check "dependency-review-config.yml: severidade mínima high" "$(has "${ROOT_DIR}/.github/dependency-review-config.yml" '^fail-on-severity: high$')"
check "secret-scan.yml: gitleaks com checksum SHA-256 verificado" "$(has "$SS" 'sha256sum -c -')"
check "secret-scan.yml: relatório sempre redigido (--redact)" "$(has "$SS" -- '--redact')"
check "secret-scan.yml: PR varre somente os commits do PR (base..head)" "$(has "$SS" 'PR_BASE_SHA\}\.\.\$\{PR_HEAD_SHA')"
if python3 -c 'import yaml' >/dev/null 2>&1; then
  check "workflows de governança não interpolam \${{ github.event.* }} dentro de run (evita injeção)" "$(python3 - "$QG" "$CODEQL" "$DR" "$SS" <<'PY'
import sys, yaml
bad = []
for path in sys.argv[1:]:
    doc = yaml.safe_load(open(path, encoding="utf-8"))
    for job in (doc.get("jobs") or {}).values():
        for step in job.get("steps") or []:
            if "${{ github.event" in str(step.get("run", "")):
                bad.append(path)
print("false" if bad else "true")
PY
)"
fi

echo "-- validação estrutural --"
if python3 -c 'import yaml' >/dev/null 2>&1; then
  check "YAML válido nos workflows de governança" "$(python3 -c 'import sys,yaml; [yaml.safe_load(open(p)) for p in sys.argv[1:]]' "$QG" "$CODEQL" "$DR" "$SS" "${ROOT_DIR}/.github/dependabot.yml" "${ROOT_DIR}/.github/dependency-review-config.yml" && echo true || echo false)"
else
  echo "  ⚠ PyYAML indisponível — validação YAML coberta pelo check build (scripts/validate-repo-static.sh)"
fi
if command -v actionlint >/dev/null 2>&1; then
  check "actionlint sem erros nos workflows de governança" "$(cd "$ROOT_DIR" && actionlint -shellcheck= -pyflakes= "$QG" "$CODEQL" "$DR" "$SS" >/dev/null 2>&1 && echo true || echo false)"
else
  echo "  ⚠ actionlint indisponível localmente — executado pelo check build no CI (versão pinada)"
fi

echo ""
echo "Resultado: ${pass} passaram, ${fail} falharam"
(( fail > 0 )) && exit 1
echo "✓ todos os testes passaram"
