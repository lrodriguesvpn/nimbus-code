#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# nimbus-intake-engine.sh
#
# Engine de Intake Direto e Governança do Nimbus Agent (SPEC 018 / SPEC 017).
# Responsabilidades:
#   1. Validação de Envelope (JSON) contra schema do contrato multicanal
#      (teams_bot, cli_command, transcript_upload) e checagem dos 4 blocos.
#   2. Rejeição estrita de segredos, tokens e dados sensíveis (DevSecOps).
#   3. Armazenamento e verificação de idempotência por source_event_id.
#   4. Projeção de demanda para Issue e Project Item central.
#   5. Classificação de modo de execução (Autônomo, Semiautônomo, Manual).
#   6. Checkpoint de aprovação humana Go/No-Go e auditoria estruturada.
#   7. Controle de feature toggle compatível com OpenFeature.
#
# Uso:
#   ./scripts/nimbus-intake-engine.sh validate --envelope <arquivo.json>
#   ./scripts/nimbus-intake-engine.sh process --envelope <arquivo.json> [--store <arquivo.jsonl>]
#   ./scripts/nimbus-intake-engine.sh decide-mode --intake <arquivo.json>
#   ./scripts/nimbus-intake-engine.sh record-approval --id <id> --decision <go|no-go> --approver <user>
###############################################################################

STORE_FILE_DEFAULT=".specify/intake-idempotency.jsonl"
AUDIT_LOG_DEFAULT=".specify/intake-audit.log"

check_secrets_and_pii() {
  local content="$1"
  # Padrões comuns de credenciais, tokens e chaves privadas
  if echo "$content" | grep -Ei -q '(ghp_[a-zA-Z0-9]{20,}|github_pat_[a-zA-Z0-9_]{20,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|password["'\'']?\s*[:=]\s*["'\''][^"'\'']{4,}|client_secret["'\'']?\s*[:=]\s*["'\''][^"'\'']{4,})'; then
    return 1
  fi
  return 0
}

validate_envelope_json() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo "ERROR: Envelope file not found: $file" >&2
    return 2
  fi

  local json
  json="$(cat "$file")"

  # Validação de formato JSON básico
  if ! command -v jq >/dev/null 2>&1; then
    echo "ERROR: jq is required for envelope processing" >&2
    return 2
  fi

  if ! echo "$json" | jq . >/dev/null 2>&1; then
    echo '{"status":"invalid","error":"Invalid JSON syntax"}'
    return 1
  fi

  # Verificação de segurança (Sem segredos/credenciais)
  if ! check_secrets_and_pii "$json"; then
    echo '{"status":"invalid","error":"Payload rejected: contains sensitive data, credentials or tokens"}'
    return 1
  fi

  local source_event_id source_channel source_repo source_issue title description requested_by occurred_at
  source_event_id="$(echo "$json" | jq -r '.source_event_id // empty')"
  source_channel="$(echo "$json" | jq -r '.source_channel // empty')"
  source_repo="$(echo "$json" | jq -r '.source_repo // empty')"
  source_issue="$(echo "$json" | jq -r '.source_issue // empty')"
  title="$(echo "$json" | jq -r '.title // empty')"
  description="$(echo "$json" | jq -r '.description // empty')"
  requested_by="$(echo "$json" | jq -r '.requested_by // empty')"
  occurred_at="$(echo "$json" | jq -r '.occurred_at // empty')"

  if [[ -z "$source_event_id" || -z "$source_repo" || -z "$source_issue" || -z "$title" || -z "$description" || -z "$requested_by" || -z "$occurred_at" ]]; then
    echo '{"status":"invalid","error":"Missing mandatory envelope fields"}'
    return 1
  fi

  # Validação do canal (se fornecido)
  if [[ -n "$source_channel" ]]; then
    if [[ "$source_channel" != "teams_bot" && "$source_channel" != "cli_command" && "$source_channel" != "transcript_upload" ]]; then
      echo '{"status":"invalid","error":"Invalid source_channel. Allowed: teams_bot, cli_command, transcript_upload"}'
      return 1
    fi
  fi

  # Validação do interview_payload (se presente)
  local has_interview
  has_interview="$(echo "$json" | jq 'has("interview_payload")')"
  if [[ "$has_interview" == "true" ]]; then
    local cov_status
    cov_status="$(echo "$json" | jq -r '.interview_payload.coverage_status // "missing_blocks"')"
    local blocks_count
    blocks_count="$(echo "$json" | jq '.interview_payload.blocks_covered // [] | length')"
    if [[ "$cov_status" == "complete" && "$blocks_count" -lt 4 ]]; then
      echo '{"status":"invalid","error":"Inconsistent interview payload: complete status requires all 4 blocks (business, infrastructure, security, lgpd)"}'
      return 1
    fi
  fi

  echo '{"status":"valid"}'
  return 0
}

is_duplicate() {
  local event_id="$1"
  local store_file="$2"
  if [[ -f "$store_file" ]]; then
    if grep -q "\"source_event_id\":\"$event_id\"" "$store_file" 2>/dev/null; then
      return 0
    fi
  fi
  return 1
}

save_intake_event() {
  local event_id="$1"
  local json_payload="$2"
  local store_file="$3"
  mkdir -p "$(dirname "$store_file")"
  echo "$json_payload" | jq -c --arg id "$event_id" '. + {stored_at: (now | todate), source_event_id: $id}' >> "$store_file"
}

classify_mode() {
  local json="$1"
  local priority
  priority="$(echo "$json" | jq -r '.priority // "P2"')"
  local description
  description="$(echo "$json" | jq -r '.description // ""')"
  local title
  title="$(echo "$json" | jq -r '.title // ""')"

  local mode="autonomous"
  local reason="Demanda padrão de baixa/média complexidade sem risco crítico de segurança"
  local confidence="0.95"
  local rules_evaluated='["RULE-AUTO-P2-P3", "RULE-LOW-RISK"]'

  # Regra de criticidade e risco
  if [[ "$priority" == "P0" || "$priority" == "P0-blocker" ]] || echo "$title $description" | grep -Ei -q '(auth|segurança|security|lgpd|pii|banco de dados|schema|destrutivo|migration)'; then
    mode="manual"
    reason="Demanda crítica com impacto em segurança, dados ou arquitetura S4 — requer aprovação humana mandatória"
    confidence="0.98"
    rules_evaluated='["RULE-MANUAL-CRITICAL-S4", "RULE-SECURITY-SENSITIVE"]'
  elif [[ "$priority" == "P1" || "$priority" == "P1-high" ]] || echo "$title $description" | grep -Ei -q '(multi-repo|infraestrutura|integração)'; then
    mode="semi-autonomous"
    reason="Demanda de média/alta prioridade com impacto entre múltiplos serviços — requer checkpoint de validação"
    confidence="0.90"
    rules_evaluated='["RULE-SEMI-AUTO-MULTI-MODULE", "RULE-P1-HIGH"]'
  fi

  jq -n \
    --arg mode "$mode" \
    --arg reason "$reason" \
    --arg confidence "$confidence" \
    --argjson rules "$rules_evaluated" \
    '{
      mode: $mode,
      reason: $reason,
      confidence: ($confidence | tonumber),
      rules_evaluated: $rules,
      decided_at: (now | todate)
    }'
}

record_audit() {
  local audit_file="$1"
  local entry="$2"
  mkdir -p "$(dirname "$audit_file")"
  echo "$entry" | jq -c '. + {audit_timestamp: (now | todate)}' >> "$audit_file"
}

# ─────────────────────────────────────────────────────────────────────────────
# CLI Subcommand Dispatch
# ─────────────────────────────────────────────────────────────────────────────

cmd="${1:-help}"
shift || true

case "$cmd" in
  validate)
    envelope_file=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --envelope) envelope_file="$2"; shift 2 ;;
        *) echo "Unknown option: $1" >&2; exit 2 ;;
      esac
    done
    if [[ -z "$envelope_file" ]]; then
      echo "Usage: $0 validate --envelope <file.json>" >&2
      exit 2
    fi
    validate_envelope_json "$envelope_file"
    ;;

  process)
    envelope_file=""
    store_file="$STORE_FILE_DEFAULT"
    audit_file="$AUDIT_LOG_DEFAULT"
    flag_enabled="${NIMBUS_OPENFEATURE_INTAKE_DIRECT_SYNC:-true}"

    while [[ $# -gt 0 ]]; do
      case "$1" in
        --envelope) envelope_file="$2"; shift 2 ;;
        --store) store_file="$2"; shift 2 ;;
        --audit) audit_file="$2"; shift 2 ;;
        *) echo "Unknown option: $1" >&2; exit 2 ;;
      esac
    done

    if [[ "$flag_enabled" != "true" ]]; then
      echo '{"status":"blocked","reason":"OpenFeature toggle nimbus.intake.direct_sync is disabled"}'
      exit 0
    fi

    val_res="$(validate_envelope_json "$envelope_file")"
    val_status="$(echo "$val_res" | jq -r '.status')"
    if [[ "$val_status" != "valid" ]]; then
      echo "$val_res"
      exit 1
    fi

    payload="$(cat "$envelope_file")"
    event_id="$(echo "$payload" | jq -r '.source_event_id')"

    if is_duplicate "$event_id" "$store_file"; then
      echo '{"status":"duplicate_detected","message":"Event already processed; idempotency preserved","source_event_id":"'"$event_id"'"}'
      exit 0
    fi

    # Classificação de modo
    mode_decision="$(classify_mode "$payload")"
    mode="$(echo "$mode_decision" | jq -r '.mode')"

    # Projeção de Issue e Project Item
    projected_issue_title="$(echo "$payload" | jq -r '.title')"
    projected_issue_body="$(echo "$payload" | jq -r '"### Intake Demand\n\n**Source**: " + .source_repo + "#" + (.source_issue|tostring) + "\n**Channel**: " + (.source_channel // "standard") + "\n**Requested by**: @" + .requested_by + "\n\n" + .description')"
    
    project_status="projected"
    if [[ "$mode" == "manual" || "$mode" == "semi-autonomous" ]]; then
      project_status="blocked_waiting_approval"
    fi

    result_json="$(jq -n \
      --arg event_id "$event_id" \
      --arg status "$project_status" \
      --arg title "$projected_issue_title" \
      --arg body "$projected_issue_body" \
      --argjson mode_dec "$mode_decision" \
      --argjson original "$payload" \
      '{
        status: $status,
        source_event_id: $event_id,
        mode_decision: $mode_dec,
        central_projection: {
          issue: {
            title: $title,
            labels: ["type:feature", ("priority:" + ($original.priority // "P2")), ("mode:" + $mode_dec.mode)],
            body: $body
          },
          project_item: {
            status: $status,
            priority: ($original.priority // "P2"),
            mode: $mode_dec.mode
          }
        }
      }')"

    save_intake_event "$event_id" "$result_json" "$store_file"
    record_audit "$audit_file" "$result_json"

    echo "$result_json"
    ;;

  decide-mode)
    envelope_file=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --envelope) envelope_file="$2"; shift 2 ;;
        *) echo "Unknown option: $1" >&2; exit 2 ;;
      esac
    done
    payload="$(cat "$envelope_file")"
    classify_mode "$payload"
    ;;

  record-approval)
    intake_id=""
    decision=""
    approver=""
    reason=""
    audit_file="$AUDIT_LOG_DEFAULT"

    while [[ $# -gt 0 ]]; do
      case "$1" in
        --id) intake_id="$2"; shift 2 ;;
        --decision) decision="$2"; shift 2 ;;
        --approver) approver="$2"; shift 2 ;;
        --reason) reason="$2"; shift 2 ;;
        --audit) audit_file="$2"; shift 2 ;;
        *) echo "Unknown option: $1" >&2; exit 2 ;;
      esac
    done

    if [[ -z "$intake_id" || -z "$decision" || -z "$approver" ]]; then
      echo "Usage: $0 record-approval --id <id> --decision <go|no-go> --approver <user> [--reason <text>]" >&2
      exit 2
    fi

    if [[ "$decision" != "go" && "$decision" != "no-go" ]]; then
      echo "ERROR: Decision must be 'go' or 'no-go'" >&2
      exit 1
    fi

    approval_record="$(jq -n \
      --arg id "$intake_id" \
      --arg decision "$decision" \
      --arg approver "$approver" \
      --arg reason "${reason:-Aprovação humana registrada formalmente via RACI}" \
      '{
        intake_id: $id,
        approval_decision: $decision,
        approver: $approver,
        reason: $reason,
        status: (if $decision == "go" then "approved_ready_for_execution" else "rejected_execution_blocked" end),
        decided_at: (now | todate)
      }')"

    record_audit "$audit_file" "$approval_record"
    echo "$approval_record"
    ;;

  *)
    echo "Usage: $0 {validate|process|decide-mode|record-approval} [options]"
    exit 1
    ;;
esac
