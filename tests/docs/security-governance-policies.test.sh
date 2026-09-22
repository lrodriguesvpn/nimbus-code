#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# tests/docs/security-governance-policies.test.sh
#
# Issue #450 / T042 (AC-9): valida que docs/security-baseline-ghe.md contém as
# seções 9–18 (Rulesets e matriz de branches, required checks, cobertura, SAST,
# SCA, Secret Scanning/Push Protection, exceções, SLA, evidências/pré-requisitos/
# permissões do App e piloto), que o ADR-0008 documenta as permissões
# adicionais SOMENTE LEITURA e que spec/tasks/quickstart rastreiam a issue.
# Apenas leitura de arquivos — sem API e sem credenciais.
###############################################################################

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC_FILE="${ROOT_DIR}/docs/security-baseline-ghe.md"
ADR_FILE="${ROOT_DIR}/docs/adr/0008-github-app-para-varredura-de-seguranca-org-wide.md"
SPEC_DIR="${ROOT_DIR}/specs/007-controle-seguranca-ghe-projetos-plataforma"
for f in "$DOC_FILE" "$ADR_FILE" "$SPEC_DIR/spec.md" "$SPEC_DIR/tasks.md" "$SPEC_DIR/quickstart.md"; do
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
contains() { grep -qiF -- "$2" <<< "$1" && echo true || echo false; }
all_of() {
  local text="$1"; shift
  local p
  for p in "$@"; do grep -qiF -- "$p" <<< "$text" || { echo false; return; }; done
  echo true
}
extract_section() {
  awk -v h="$1" '
    $0 ~ "^## " h { capture=1; next }
    /^## / { if (capture) exit }
    capture { print }
  ' "$DOC_FILE"
}

echo "== tests/docs/security-governance-policies.test.sh =="

s9=$(extract_section "9[.] Baseline de Rulesets e Branch Protection")
s10=$(extract_section "10[.] Matriz de Required Checks")
s11=$(extract_section "11[.] Política de Cobertura de Testes")
s12=$(extract_section "12[.] Política de SAST")
s13=$(extract_section "13[.] Política de SCA")
s14=$(extract_section "14[.] Política de Secret Scanning e Push Protection")
s15=$(extract_section "15[.] Processo de Exceções")
s16=$(extract_section "16[.] SLA de Tratamento por Severidade")
s17=$(extract_section "17[.] Evidências, Pré-requisitos de Plano/Licença e Permissões do GitHub App")
s18=$(extract_section "18[.] Procedimento de Piloto e Validação")

for n in 9 10 11 12 13 14 15 16 17 18; do
  var="s${n}"
  check "Seção ${n} existe e não está vazia" "$([[ -n "${!var}" ]] && echo true || echo false)"
done

echo "-- 9. Rulesets e matriz de branches --"
check "prefere Rulesets e marca proteção clássica como compatibilidade" "$(all_of "$s9" "Rulesets" "compatibilidade")"
check "branches parametrizáveis (default, produção, padrões, adicionais)" "$(all_of "$s9" "default_branch" "production_branches" "protected_patterns" "additional_branches")"
check "padrões release/* e hotfix/*" "$(all_of "$s9" 'release/*' 'hotfix/*')"
check "matriz cobre PR, aprovador, CODEOWNERS, dismiss stale, force push, deleção, status checks, branch atualizada, conversas e merge queue" "$(all_of "$s9" "Pull Request" "aprovador" "CODEOWNERS" "obsoletas" "force push" "exclusão" "Status checks" "atualizada" "comentários" "Merge queue")"

echo "-- 10. Required checks --"
check "matriz lista build, testes, integração, cobertura, CodeQL, dependency-review e secret-scan" "$(all_of "$s10" '`build`' '`unit-tests`' '`integration-tests`' '`coverage`' '`CodeQL`' '`dependency-review`' '`secret-scan`')"
check "explica bloqueio quando check obrigatório não executa" "$(contains "$s10" "não executa")"
check "proíbe check fictício / declara N/A explicitamente" "$(all_of "$s10" "não aplicável" "not_applicable_reason")"

echo "-- 11. Cobertura --"
check "80% global e 80% no código alterado" "$(all_of "$s11" "80%" "código alterado")"
check "proíbe redução sem exceção e publica relatório" "$(all_of "$s11" "Redução" "exceção" "artefato")"
check "comportamento explícito para repositório shell/documentação sem métrica inventada" "$(all_of "$s11" "not-applicable" "Nenhuma métrica de cobertura é inventada")"

echo "-- 12. SAST --"
check "CodeQL em PR, branch padrão e semanal, versões fixadas e permissões mínimas" "$(all_of "$s12" "codeql.yml" "semanal" "SHA" "security-events: write")"
check "bloqueio high/critical documentado" "$(all_of "$s12" "Critical" "High")"

echo "-- 13. SCA --"
check "Dependabot alerts, security updates, version updates e Dependency Review" "$(all_of "$s13" "Dependabot alerts" "Dependabot security updates" "Dependabot version updates" "Dependency Review")"
check "severidade mínima, dependências proibidas, licenças e lockfiles" "$(all_of "$s13" "fail-on-severity" "deny-packages" "Licenças" "lockfiles")"
check "sem PAT/secrets nos workflows de SCA" "$(contains "$s13" "Nenhum PAT/secret")"

echo "-- 14. Secrets --"
check "diferencia secrets de workflows de secrets expostos no código" "$(all_of "$s14" "Secrets usados por workflows" "Secrets expostos no código")"
check "workflows: Environment Secrets, ambientes protegidos, owner, rotação, OIDC, permissions" "$(all_of "$s14" "Environment Secrets" "ambientes protegidos" "owner" "rotação" "OIDC" "permissions:")"
check "código: Secret Scanning, Push Protection, revogação/rotação" "$(all_of "$s14" "Secret Scanning" "Push Protection" "Revogar/rotacionar")"
check "secrets-configured não substitui Secret Scanning" "$(all_of "$s14" "secrets-configured" "não é")"

echo "-- 15/16. Exceções e SLA --"
check "exceção exige responsável, justificativa, aprovador, prazo e expiração" "$(all_of "$s15" "owner" "justification" "approved_by" "expires_at" "90 dias")"
check "exceção vencida bloqueia (governance-config)" "$(all_of "$s15" "vencida" "governance-config")"
check "SLA por severidade com secret exposto em 24h" "$(all_of "$s16" "Crítica" "Alta" "Média" "Baixa" "24h")"

echo "-- 17/18. Evidências, plano, permissões e piloto --"
check "evidências de auditoria listadas" "$(all_of "$s17" "Evidências necessárias para auditoria" "relatório" "Rulesets")"
check "pré-requisitos de plano/licença (Code Security, Secret Protection, Rulesets)" "$(all_of "$s17" "Code Security" "Secret Protection" "Rulesets")"
check "permissões do App todas somente leitura e sem escrita" "$(all_of "$s17" "somente leitura" "Nenhuma permissão de escrita" "Code scanning alerts" "Dependabot alerts" "Secret scanning alerts")"
check "piloto preserva gate S4 e não habilita org-wide" "$(all_of "$s18" "S4" "T038" "org-wide")"
check "piloto valida bloqueio de PR e dry-run" "$(all_of "$s18" "falha proposital" "dry_run=true")"

echo "-- seções legadas atualizadas --"
section5=$(awk '/^## 5[.] /{c=1;next} /^## /{if(c)exit} c' "$DOC_FILE")
for control in branch-protection-default branch-protection-required-patterns rulesets-configured required-review required-pr-checks required-test-checks required-coverage-check codeql-enabled codeql-recent codeql-alerts dependabot-alerts-enabled dependabot-security-updates-enabled dependency-review-enabled secret-scanning-enabled secret-scanning-push-protection-enabled secret-alerts actions-permissions secrets-configured; do
  check "checklist (seção 5) inclui \`${control}\`" "$(contains "$section5" "\`${control}\`")"
done
check "seção 5 documenta que API indisponível/403 nunca é ok" "$(all_of "$section5" "403" "pendente" "Nenhum dos dois")"

echo "-- ADR-0008, spec, tasks e quickstart --"
adr=$(cat "$ADR_FILE")
check "ADR-0008 documenta permissões adicionais read-only" "$(all_of "$adr" "Adendo" "Code scanning alerts" "Dependabot alerts" "Secret scanning alerts" "Nenhuma permissão de escrita")"
check "ADR-0008 continua 'Em revisão' (aprovação S4 pendente)" "$(grep -q '^- \*\*Status:\*\* Em revisão' "$ADR_FILE" && echo true || echo false)"
spec=$(cat "$SPEC_DIR/spec.md")
check "spec.md tem FR-009..FR-018 e User Story 4" "$(all_of "$spec" "FR-009" "FR-015" "FR-018" "User Story 4")"
tasks=$(cat "$SPEC_DIR/tasks.md")
check "tasks.md rastreia a issue #450 (T042–T068)" "$(all_of "$tasks" "T042" "T061" "T068" "#450")"
check "tarefas humanas continuam pendentes (T004, T005, T038, T062–T066)" "$(for t in T004 T005 T038 T062 T063 T064 T065 T066; do grep -qE "^- \[ \] ${t} " "$SPEC_DIR/tasks.md" || { echo false; exit; }; done; echo true)"
check "quickstart.md tem passos de validação da issue #450" "$(all_of "$(cat "$SPEC_DIR/quickstart.md")" "Passo 8" "Passo 11" "dry_run=true")"
check "documentação não referencia github.com público (regra do bundle)" "$(grep -n 'github\.com' "$DOC_FILE" | grep -v 'ghe\.com' | grep -qv 'docs\.github\.com' && echo false || echo true)"

echo ""
echo "Resultado: ${pass} passaram, ${fail} falharam"
(( fail > 0 )) && exit 1
echo "✓ todos os testes passaram"
