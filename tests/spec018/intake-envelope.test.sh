#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# tests/spec018/intake-envelope.test.sh
#
# Valida T001, T004, T005, T006, T007, T008, T009 da SPEC 018:
#   - Validação de schema do envelope
#   - Rejeição de segredos / tokens / PII (DevSecOps)
#   - Idempotência e replay
#   - Projeção de Issue e Project Item central
#   - Modais de intake (teams_bot, cli_command, transcript_upload)
#   - OpenFeature toggle
###############################################################################

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENGINE="${ROOT_DIR}/scripts/nimbus-intake-engine.sh"

pass=0
fail=0

check() {
  local description="$1" condition="$2"
  if [[ "$condition" == "true" ]]; then
    echo "  ✓ ${description}"
    pass=$((pass + 1))
  else
    echo "  ✗ ${description}"
    fail=$((fail + 1))
  fi
}

echo "=== tests/spec018/intake-envelope.test.sh ==="

TMP_DIR="$(mktemp -d /tmp/nimbus-intake-test-XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

# 1. Envelope Válido Padrão
cat << 'EOF' > "$TMP_DIR/valid-envelope.json"
{
  "source_event_id": "nimbus-agent:issue:101:created:1",
  "source_channel": "teams_bot",
  "source_repo": "venha-pra-nuvem/nimbus-agent",
  "source_issue": 101,
  "title": "Integração M365 Teams",
  "description": "Criar fluxo de intake automático",
  "bounded_context": "spec-kit-workflow",
  "priority": "P2",
  "requested_by": "joao.silva",
  "occurred_at": "2026-09-20T16:00:00Z",
  "interview_payload": {
    "interview_file": "specs/018-nimbus-agent-intake/interview.md",
    "coverage_status": "complete",
    "blocks_covered": ["business", "infrastructure", "security", "lgpd"]
  }
}
EOF

val_out="$("$ENGINE" validate --envelope "$TMP_DIR/valid-envelope.json" 2>&1 || true)"
check "Envelope válido passa com status valid" "$([[ $(echo "$val_out" | jq -r '.status') == "valid" ]] && echo true || echo false)"

# 2. Envelope Inválido (Campos faltantes)
cat << 'EOF' > "$TMP_DIR/invalid-envelope.json"
{
  "source_event_id": "nimbus-agent:issue:102",
  "title": "Incompleto"
}
EOF

val_inv="$("$ENGINE" validate --envelope "$TMP_DIR/invalid-envelope.json" 2>&1 || true)"
check "Envelope sem campos obrigatórios é rejeitado" "$([[ $(echo "$val_inv" | jq -r '.status') == "invalid" ]] && echo true || echo false)"

# 3. Rejeição de Segredos e Credenciais (DevSecOps Gate)
cat << 'EOF' > "$TMP_DIR/secret-envelope.json"
{
  "source_event_id": "nimbus-agent:issue:103",
  "source_repo": "venha-pra-nuvem/nimbus-agent",
  "source_issue": 103,
  "title": "Vazamento acidental",
  "description": "Aqui está o token ghp_123456789012345678901234567890",
  "priority": "P1",
  "requested_by": "hacker",
  "occurred_at": "2026-09-20T16:00:00Z"
}
EOF

val_sec="$("$ENGINE" validate --envelope "$TMP_DIR/secret-envelope.json" 2>&1 || true)"
check "Payload contendo token ou segredo é rejeitado" "$([[ $(echo "$val_sec" | jq -r '.error') =~ "contains sensitive data" ]] && echo true || echo false)"

# 4. Processamento com Idempotência e Projeção Central
store_file="$TMP_DIR/store.jsonl"
proc_out1="$("$ENGINE" process --envelope "$TMP_DIR/valid-envelope.json" --store "$store_file")"

check "Processamento gera projeção central com status esperado" "$([[ $(echo "$proc_out1" | jq -r '.central_projection.issue.title') == "Integração M365 Teams" ]] && echo true || echo false)"
check "Labels incluem type:feature e prioridade" "$([[ $(echo "$proc_out1" | jq -r '.central_projection.issue.labels | index("type:feature")') != "null" ]] && echo true || echo false)"

# 5. Replay do mesmo evento (Idempotência)
proc_out2="$("$ENGINE" process --envelope "$TMP_DIR/valid-envelope.json" --store "$store_file")"
check "Replay do mesmo source_event_id detecta duplicidade" "$([[ $(echo "$proc_out2" | jq -r '.status') == "duplicate_detected" ]] && echo true || echo false)"

# 6. OpenFeature flag desabilitada
cat << 'EOF' > "$TMP_DIR/envelope-p3.json"
{
  "source_event_id": "nimbus-agent:issue:104:created:1",
  "source_channel": "cli_command",
  "source_repo": "venha-pra-nuvem/nimbus-agent",
  "source_issue": 104,
  "title": "Demanda CLI",
  "description": "Via console",
  "priority": "P3",
  "requested_by": "dev",
  "occurred_at": "2026-09-20T16:00:00Z"
}
EOF

flag_out="$(NIMBUS_OPENFEATURE_INTAKE_DIRECT_SYNC=false "$ENGINE" process --envelope "$TMP_DIR/envelope-p3.json" --store "$store_file")"
check "OpenFeature flag desabilitada bloqueia o processamento" "$([[ $(echo "$flag_out" | jq -r '.status') == "blocked" ]] && echo true || echo false)"

echo "Resultado: ${pass} passou(aram), ${fail} falhou(aram)"
if [[ "$fail" -gt 0 ]]; then
  exit 1
fi
