#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-specs/005-hybrid-agent-human-dev/fixtures}"

require_file() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo "ERROR: required file not found: $file" >&2
    exit 1
  fi
}

require_contains() {
  local file="$1"
  local pattern="$2"
  if ! grep -Fq "$pattern" "$file"; then
    echo "ERROR: '$pattern' not found in $file" >&2
    exit 1
  fi
}

spec_file="$TARGET_DIR/spec-sample.md"
plan_file="$TARGET_DIR/plan-sample.md"
task_file="$TARGET_DIR/task-sample.md"

require_file "$spec_file"
require_file "$plan_file"
require_file "$task_file"

# spec contract
require_contains "$spec_file" "Nimbus-Code — Cabeçalho Obrigatório da Spec"
require_contains "$spec_file" "Nimbus-Code — SLO Alvo desta Feature"
require_contains "$spec_file" "Nimbus-Code — Critérios de Aceitação (formato BDD)"
require_contains "$spec_file" "Given"
require_contains "$spec_file" "When"
require_contains "$spec_file" "Then"
require_contains "$spec_file" "Impeccable"
require_contains "$spec_file" "## Assumptions"

# plan contract
require_contains "$plan_file" "Nimbus-Code — Classificação de Complexidade (S0–S4)"
require_contains "$plan_file" "Nimbus-Code — Rastreabilidade AC → Teste → Módulo"
require_contains "$plan_file" "Nimbus-Code — Module Dependency Graph"
require_contains "$plan_file" "Nimbus-Code — Estratégia de Release"
require_contains "$plan_file" "OpenFeature"
require_contains "$plan_file" "SPEC KIT COST"

# task contract
require_contains "$task_file" "## Contexto"
require_contains "$task_file" "## Objetivo"
require_contains "$task_file" "## Resultado Esperado"
require_contains "$task_file" "## Critérios de Aceite"
require_contains "$task_file" "## Passos Operacionais"
require_contains "$task_file" "## Dependências"
require_contains "$task_file" "## Responsável"
require_contains "$task_file" "## Estimativa de Esforço"
require_contains "$task_file" "## Referência"
require_contains "$task_file" "SPEC KIT COST"

echo "OK: hybrid contracts validated in $TARGET_DIR"
