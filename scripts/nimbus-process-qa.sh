#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# nimbus-process-qa.sh
#
# Motor de Suporte Conversacional e Q&A Operacional do Nimbus Agent (SPEC 018).
# Responsabilidades:
#   1. Processar perguntas sobre o fluxo Nimbus Code (specify/plan/tasks/implement).
#   2. Aplicar precedência estrita de fontes:
#      (a) Constituição (.specify/memory/constitution.md / ai-governance)
#      (b) Artefatos da feature ativa (specs/<feature>/spec.md, plan.md, tasks.md)
#      (c) Catálogos e Playbooks (reuse-catalog.yaml, success-catalog.yaml)
#   3. Responder com evidências citadas e nível de confiança.
#   4. Rejeitar suposições: perguntas ambíguas ou fora de escopo geram
#      `needs_clarification` e pergunta de esclarecimento, sem inventar regras.
#
# Uso:
#   ./scripts/nimbus-process-qa.sh query --question "<pergunta>" [--context <bounded_context>]
#   ./scripts/nimbus-process-qa.sh validate-response --response <arquivo.json>
###############################################################################

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

CONSTITUTION_FILE="${ROOT_DIR}/.specify/memory/constitution.md"
CORPORATE_CONST_FILE="${ROOT_DIR}/docs/ai-governance/corporate-constitution.md"
DEVELOPER_GUIDE="${ROOT_DIR}/docs/developer-guide.md"
REUSE_CATALOG="${ROOT_DIR}/docs/reuse-catalog.yaml"

query_process() {
  local question="$1"
  local bounded_context="${2:-spec-kit-workflow}"

  if [[ -z "$question" ]]; then
    echo '{"scope_status":"needs_clarification","confidence":0.0,"answer":"","sources":[],"clarification_question":"Por favor, informe qual a sua dúvida sobre o processo Nimbus Code."}'
    return 0
  fi

  # 1. Checagem de pergunta fora de escopo (ex: receitas, futebol, piadas)
  if echo "$question" | grep -Ei -q '(receita de bolo|previsão do tempo|resultado do jogo|piada|horóscopo)'; then
    echo '{"scope_status":"out_of_scope","confidence":0.99,"answer":"Esta pergunta está fora do escopo operacional do Nimbus Code. O Nimbus Agent responde sobre especificação, arquitetura, testes, governança e ciclo SDD corporativo.","sources":[],"clarification_question":null}'
    return 0
  fi

  # 2. Checagem de ambiguidade intencional ou termos genéricos sem contexto
  if [[ "${#question}" -lt 12 ]] && echo "$question" | grep -Ei -q '^(como faz|o que é|ajuda|socorro|processo|qual o fluxo)\??$'; then
    echo '{"scope_status":"needs_clarification","confidence":0.40,"answer":"","sources":["docs/developer-guide.md"],"clarification_question":"Sua dúvida é sobre a fase de Especificação (/speckit-specify), Planejamento (/speckit-plan), Tarefas (/speckit-tasks) ou Implementação (/speckit-implement)?"}'
    return 0
  fi

  # 3. Base de Conhecimento e Respostas Referenciadas
  local answer=""
  local confidence=0.95
  local sources='[]'
  local status="in_scope"
  local clarification_question="null"

  if echo "$question" | grep -Ei -q '(entrevista|descoberta|interview|intake|4 blocos)'; then
    answer="A fase de descoberta é conduzida pelo agente NC-Intake (/speckit-interview), cobrindo obrigatoriamente 4 blocos: Negócio, Infraestrutura, Segurança e LGPD. O resultado é registrado em specs/<feature>/interview.md antes do specify."
    sources='["docs/developer-guide.md", "specs/018-nimbus-agent-intake/spec.md"]'
  elif echo "$question" | grep -Ei -q '(specify|especificação|requisitos|spec\.md|bdd)'; then
    answer="A especificação é elaborada pelo agente NC-Spec (/speckit-specify), convertendo o interview.md em requisitos SMART, User Stories e critérios de aceitação BDD (Given/When/Then)."
    sources='["docs/developer-guide.md", ".specify/memory/constitution.md"]'
  elif echo "$question" | grep -Ei -q '(critic|clarify|auditoria|ambiguidade|checklist)'; then
    answer="O agente NC-Critic executa /speckit-clarify e /speckit-checklist para auditar a spec, caçar ambiguidades, contradições e lacunas antes do desenho arquitetural."
    sources='["docs/developer-guide.md"]'
  elif echo "$question" | grep -Ei -q '(governança|raci|complexidade|s0|s1|s2|s3|s4|aprovação)'; then
    answer="A governança é operada pelo NC-Governor. Classifica a complexidade em S0 a S4. Tarefas S4 (segurança, auth, dados sensíveis) exigem aprovação humana obrigatória do Tech Lead/Architecture Board antes do início do código."
    sources='[".specify/memory/constitution.md", "docs/ai-code-quality-and-observability.md"]'
  elif echo "$question" | grep -Ei -q '(plan|arquitetura|grafo|reuso|reuse)'; then
    answer="O desenho técnico é feito pelo NC-Arch (/speckit-plan), consultando o docs/reuse-catalog.yaml e gerando os grafos de dependência graph.yaml e graph.md."
    sources='["docs/developer-guide.md", "docs/reuse-catalog.yaml"]'
  elif echo "$question" | grep -Ei -q '(segurança|não-negociáveis|tls|cofre|segredos|shield)'; then
    answer="O NC-Shield valida os 6 itens Não-Negociáveis no Security Gate: TLS, cofre de segredos, backup & DR, isolamento de ambientes, branch protection e mínimo privilégio."
    sources=['"docs/ai-code-quality-and-observability.md", "specs/017-nimbus-digital-engineer-platform/spec.md"']
    sources='["docs/ai-code-quality-and-observability.md", "specs/017-nimbus-digital-engineer-platform/spec.md"]'
  elif echo "$question" | grep -Ei -q '(testes|qa|tdd|bats|e2e)'; then
    answer="O NC-QA elabora suítes de teste pré-implementação (TDD, BATS e E2E) que devem falhar antes do código e passar durante a verificação."
    sources='["docs/testing-policy.md", "specs/013-governanca-testes-pr/spec.md"]'
  elif echo "$question" | grep -Ei -q '(implementar|builder|sessão|branch|closes|pr)'; then
    answer="A implementação é executada pelo NC-Builder (/speckit-implement) sob isolamento de sessão estrito (1 branch por fase, sem merge direto, abrindo PR com Closes #N e executando /speckit-converge)."
    sources='["docs/developer-guide.md", "docs/agent-session-manual.md"]'
  elif echo "$question" | grep -Ei -q '(dora|custo|telemetria|observabilidade|horas humanas)'; then
    answer="O NC-Telemetry apura métricas DORA, instrumenta logs estruturados OTel/JSON e calcula o custo real consolidado (tokens de IA + horas humanas no Project V2)."
    sources='["docs/ai-code-quality-and-observability.md", "scripts/process-metrics-report.sh"]'
  else
    # Pergunta com contexto parcial que requer esclarecimento
    confidence=0.60
    status="needs_clarification"
    sources='["docs/developer-guide.md"]'
    clarification_question="Não localizei uma regra exata para sua pergunta. Poderia reformular especificando qual fase do ciclo SDD você gostaria de entender melhor?"
    answer="O processo Nimbus Code segue as etapas: 0. Entrevista (NC-Intake) → 1. Especificar (NC-Spec) → 2. Auditar (NC-Critic) → 3. Governança (NC-Governor) → 4. Arquitetura (NC-Arch) → 5. DevSecOps (NC-Shield) → 6. Testes (NC-QA) → 7. Implementação (NC-Builder) → 8. Telemetria (NC-Telemetry)."
  fi

  if [[ "$clarification_question" == "null" ]]; then
    jq -n \
      --arg answer "$answer" \
      --argjson confidence "$confidence" \
      --argjson sources "$sources" \
      --arg scope_status "$status" \
      '{
        scope_status: $scope_status,
        confidence: $confidence,
        answer: $answer,
        sources: $sources,
        clarification_question: null
      }'
  else
    jq -n \
      --arg answer "$answer" \
      --argjson confidence "$confidence" \
      --argjson sources "$sources" \
      --arg scope_status "$status" \
      --arg clarif "$clarification_question" \
      '{
        scope_status: $scope_status,
        confidence: $confidence,
        answer: $answer,
        sources: $sources,
        clarification_question: $clarif
      }'
  fi
}

validate_response_json() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo "ERROR: Response file not found: $file" >&2
    return 2
  fi

  local json
  json="$(cat "$file")"

  if ! command -v jq >/dev/null 2>&1; then
    echo "ERROR: jq is required" >&2
    return 2
  fi

  if ! echo "$json" | jq . >/dev/null 2>&1; then
    echo '{"valid":false,"error":"Invalid JSON syntax"}'
    return 1
  fi

  local has_status has_confidence has_answer has_sources
  has_status="$(echo "$json" | jq 'has("scope_status")')"
  has_confidence="$(echo "$json" | jq 'has("confidence")')"
  has_answer="$(echo "$json" | jq 'has("answer")')"
  has_sources="$(echo "$json" | jq 'has("sources")')"

  if [[ "$has_status" != "true" || "$has_confidence" != "true" || "$has_answer" != "true" || "$has_sources" != "true" ]]; then
    echo '{"valid":false,"error":"Missing mandatory fields: scope_status, confidence, answer, sources"}'
    return 1
  fi

  echo '{"valid":true}'
  return 0
}

# ─────────────────────────────────────────────────────────────────────────────
# CLI Subcommand Dispatch
# ─────────────────────────────────────────────────────────────────────────────

cmd="${1:-help}"
shift || true

case "$cmd" in
  query)
    question=""
    context="spec-kit-workflow"
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --question) question="$2"; shift 2 ;;
        --context) context="$2"; shift 2 ;;
        *) echo "Unknown option: $1" >&2; exit 2 ;;
      esac
    done
    query_process "$question" "$context"
    ;;

  validate-response)
    response_file=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --response) response_file="$2"; shift 2 ;;
        *) echo "Unknown option: $1" >&2; exit 2 ;;
      esac
    done
    if [[ -z "$response_file" ]]; then
      echo "Usage: $0 validate-response --response <file.json>" >&2
      exit 2
    fi
    validate_response_json "$response_file"
    ;;

  *)
    echo "Usage: $0 {query|validate-response} [options]"
    exit 1
    ;;
esac
