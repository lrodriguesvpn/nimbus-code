#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# run-quality-gate.sh
#
# Executa uma etapa de quality gate declarada em .github/security-governance.json
# (SPEC 007 / issue #450). Chamado pelos jobs de
# .github/workflows/pr-quality-gates.yml — o workflow não conhece a linguagem
# do projeto; cada repositório declara seus próprios comandos.
#
# Uso: bash scripts/run-quality-gate.sh <build|unit_tests|integration_tests|coverage>
#
# Contrato por etapa (quality_gates.<etapa>, ou coverage.* para "coverage"):
#   setup_command          opcional — instalação de ferramentas pinadas
#   command                comando da etapa; exit != 0 falha o check
#   not_applicable_reason  obrigatório quando command estiver vazio
#
# Etapa sem command: o check termina com sucesso, MAS publica no resumo e em
# ::notice:: que a etapa NÃO foi executada e o motivo versionado. O check
# governance-config garante que uma etapa N/A nunca esteja listada em
# required_status_checks (não há check obrigatório "fictício").
###############################################################################

STAGE="${1:-}"
CONFIG="${GOVERNANCE_CONFIG:-.github/security-governance.json}"
SUMMARY="${GITHUB_STEP_SUMMARY:-/dev/null}"

case "$STAGE" in
  build|unit_tests|integration_tests) prefix=".quality_gates.${STAGE}" ;;
  coverage) prefix=".coverage" ;;
  *) echo "::error::Etapa inválida '${STAGE}' (use build|unit_tests|integration_tests|coverage)." >&2; exit 1 ;;
esac

if [[ ! -f "$CONFIG" ]]; then
  echo "::error::${CONFIG} não encontrado — declare os comandos de quality gate do repositório (ver docs/security-baseline-ghe.md, seção 10)." >&2
  exit 1
fi

setup_cmd="$(jq -r "${prefix}.setup_command // \"\"" "$CONFIG")"
cmd="$(jq -r "${prefix}.command // \"\"" "$CONFIG")"
reason="$(jq -r "${prefix}.not_applicable_reason // \"\"" "$CONFIG")"

if [[ -z "$cmd" ]]; then
  if [[ -z "$reason" ]]; then
    echo "::error::Etapa '${STAGE}' sem command e sem not_applicable_reason em ${CONFIG}." >&2
    exit 1
  fi
  {
    echo "### ${STAGE} — NÃO APLICÁVEL (declarado)"
    echo
    echo "> ${reason}"
    echo
    echo "Esta etapa não executou nenhum teste/build. Ela não pode constar como required status check (validado por governance-config)."
  } >> "$SUMMARY"
  echo "::notice::Etapa '${STAGE}' não aplicável: ${reason}"
  exit 0
fi

if [[ -n "$setup_cmd" ]]; then
  echo "==> [${STAGE}] setup: ${setup_cmd}"
  bash -c "$setup_cmd"
fi

echo "==> [${STAGE}] ${cmd}"
set +e
bash -c "$cmd"
status=$?
set -e

if (( status == 0 )); then
  echo "### ${STAGE} — ✓ aprovado" >> "$SUMMARY"
  echo "Comando: \`${cmd}\`" >> "$SUMMARY"
else
  echo "### ${STAGE} — ✗ reprovado (exit ${status})" >> "$SUMMARY"
  echo "Comando: \`${cmd}\`" >> "$SUMMARY"
  echo "::error::Etapa '${STAGE}' falhou (exit ${status}) — o merge deve ser bloqueado pelo required status check."
fi
exit "$status"
