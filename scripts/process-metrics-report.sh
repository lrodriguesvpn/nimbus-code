#!/usr/bin/env bash
# process-metrics-report.sh — Calcula os 4 indicadores DORA a partir das labels dora:*
#
# Uso: ./scripts/process-metrics-report.sh \
#        --repo-owner <org> \
#        --repo-name <repo> \
#        --since <YYYY-MM-DD> \
#        --until <YYYY-MM-DD> \
#        [--check-retro-cadence]
#
# Requer: gh CLI autenticado

set -euo pipefail

REPO_OWNER=""
REPO_NAME=""
SINCE=""
UNTIL=""
CHECK_RETRO_CADENCE=false

# --- Argument parsing ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-owner) REPO_OWNER="$2"; shift 2 ;;
    --repo-name)  REPO_NAME="$2";  shift 2 ;;
    --since)      SINCE="$2";      shift 2 ;;
    --until)      UNTIL="$2";      shift 2 ;;
    --check-retro-cadence) CHECK_RETRO_CADENCE=true; shift ;;
    *) echo "Argumento desconhecido: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$REPO_OWNER" || -z "$REPO_NAME" || -z "$SINCE" || -z "$UNTIL" ]]; then
  echo "Uso: $0 --repo-owner <org> --repo-name <repo> --since <YYYY-MM-DD> --until <YYYY-MM-DD>" >&2
  exit 1
fi

REPO="${REPO_OWNER}/${REPO_NAME}"

# --- Helper: list closed issues with a given label ---
list_issues_with_label() {
  local label="$1"
  gh issue list \
    --repo "$REPO" \
    --label "$label" \
    --state closed \
    --limit 500 \
    --json number,createdAt,closedAt \
    2>/dev/null || echo "[]"
}

# --- Helper: list merged PRs with a given label ---
list_prs_with_label() {
  local label="$1"
  gh pr list \
    --repo "$REPO" \
    --label "$label" \
    --state merged \
    --limit 500 \
    --json number,createdAt,mergedAt \
    2>/dev/null || echo "[]"
}

# --- Helper: count items in date range ---
count_in_range() {
  local json="$1"
  local since="$2"
  local until="$3"
  echo "$json" | python3 -c "
import sys, json
from datetime import datetime, timezone

data = json.load(sys.stdin)
since = datetime.fromisoformat('${since}').replace(tzinfo=timezone.utc)
until_d = datetime.fromisoformat('${until}').replace(hour=23, minute=59, second=59, tzinfo=timezone.utc)

count = 0
for item in data:
    closed = item.get('closedAt') or item.get('mergedAt')
    if not closed:
        continue
    closed_dt = datetime.fromisoformat(closed.replace('Z', '+00:00'))
    if since <= closed_dt <= until_d:
        count += 1

print(count)
"
}

# --- Helper: avg duration (days or hours) for items in date range ---
avg_duration_in_range() {
  local json="$1"
  local since="$2"
  local until="$3"
  local unit="$4"  # "days" or "hours"
  echo "$json" | python3 -c "
import sys, json
from datetime import datetime, timezone

data = json.load(sys.stdin)
since = datetime.fromisoformat('${since}').replace(tzinfo=timezone.utc)
until_d = datetime.fromisoformat('${until}').replace(hour=23, minute=59, second=59, tzinfo=timezone.utc)
unit = '${unit}'

durations = []
for item in data:
    closed = item.get('closedAt') or item.get('mergedAt')
    created = item.get('createdAt')
    if not closed or not created:
        continue
    closed_dt = datetime.fromisoformat(closed.replace('Z', '+00:00'))
    created_dt = datetime.fromisoformat(created.replace('Z', '+00:00'))
    if since <= closed_dt <= until_d:
        delta = (closed_dt - created_dt).total_seconds()
        if unit == 'hours':
            durations.append(delta / 3600)
        else:
            durations.append(delta / 86400)

if not durations:
    print('INSUFFICIENT_DATA')
else:
    avg = sum(durations) / len(durations)
    print(f'{avg:.2f}')
"
}

# --- Collect data ---
echo "Coletando dados de ${REPO} entre ${SINCE} e ${UNTIL}..."

DEPLOY_JSON=$(list_prs_with_label "dora:deployment-frequency")
LEAD_JSON=$(list_prs_with_label "dora:lead-time")
FAILURE_ISSUES_JSON=$(list_issues_with_label "dora:change-failure-rate")
FAILURE_PRS_JSON=$(list_prs_with_label "dora:change-failure-rate")
MTTR_JSON=$(list_issues_with_label "dora:mttr")

# --- Calculate indicators ---

# 1. Deployment Frequency
DEPLOY_COUNT=$(count_in_range "$DEPLOY_JSON" "$SINCE" "$UNTIL")
if [[ "$DEPLOY_COUNT" == "0" ]]; then
  DEPLOY_FREQ="INSUFFICIENT_DATA (nenhum item com dora:deployment-frequency no período)"
else
  DEPLOY_FREQ=$(python3 -c "
from datetime import datetime
since = datetime.fromisoformat('${SINCE}')
until = datetime.fromisoformat('${UNTIL}')
weeks = max(1, (until - since).days / 7)
count = ${DEPLOY_COUNT}
print(f'${DEPLOY_COUNT} deploys no período ({count/weeks:.2f}/semana)')
")
fi

# 2. Lead Time for Changes
LEAD_TIME=$(avg_duration_in_range "$LEAD_JSON" "$SINCE" "$UNTIL" "days")
if [[ "$LEAD_TIME" == "INSUFFICIENT_DATA" ]]; then
  LEAD_TIME_DISPLAY="INSUFFICIENT_DATA (nenhum item com dora:lead-time no período)"
else
  LEAD_TIME_DISPLAY="${LEAD_TIME} dias (média)"
fi

# 3. Change Failure Rate
# Merge issues + PRs for change-failure-rate label into one list
MERGED_FAILURE=$(python3 -c "
import json
issues = json.loads('''${FAILURE_ISSUES_JSON}''')
prs = json.loads('''${FAILURE_PRS_JSON}''')
# Normalize: PRs use mergedAt, issues use closedAt — map to closedAt
for p in prs:
    if 'mergedAt' in p and 'closedAt' not in p:
        p['closedAt'] = p['mergedAt']
print(json.dumps(issues + prs))
" 2>/dev/null || echo "[]")

FAILURE_COUNT=$(count_in_range "$MERGED_FAILURE" "$SINCE" "$UNTIL")

if [[ "$DEPLOY_COUNT" == "0" ]]; then
  CFR_DISPLAY="INSUFFICIENT_DATA (sem deploys no período para calcular proporção)"
else
  CFR_DISPLAY=$(python3 -c "
failures = int('${FAILURE_COUNT}')
deploys = int('${DEPLOY_COUNT}')
rate = (failures / deploys * 100) if deploys > 0 else 0
print(f'{rate:.1f}% ({failures} falhas / {deploys} deploys)')
")
fi

# 4. MTTR
MTTR=$(avg_duration_in_range "$MTTR_JSON" "$SINCE" "$UNTIL" "hours")
if [[ "$MTTR" == "INSUFFICIENT_DATA" ]]; then
  MTTR_DISPLAY="INSUFFICIENT_DATA (nenhum item com dora:mttr no período)"
else
  MTTR_DISPLAY="${MTTR} horas (média)"
fi

# --- Output report ---
echo ""
echo "============================================================"
echo "  DORA Metrics Report — ${REPO}"
echo "  Período: ${SINCE} a ${UNTIL}"
echo "============================================================"
echo ""
printf "  %-32s %s\n" "Deployment Frequency:"     "${DEPLOY_FREQ}"
printf "  %-32s %s\n" "Lead Time for Changes:"    "${LEAD_TIME_DISPLAY}"
printf "  %-32s %s\n" "Change Failure Rate:"      "${CFR_DISPLAY}"
printf "  %-32s %s\n" "MTTR:"                     "${MTTR_DISPLAY}"
echo ""
echo "  Labels utilizadas:"
echo "    dora:deployment-frequency  — PRs mergeados (contagem)"
echo "    dora:lead-time             — PRs mergeados (criação→merge, dias)"
echo "    dora:change-failure-rate   — Issues/PRs de falha/rollback"
echo "    dora:mttr                  — Issues encerradas (criação→close, horas)"
echo ""

# --- Optional: check retro cadence ---
if [[ "$CHECK_RETRO_CADENCE" == "true" ]]; then
  CADENCE_FILE="docs/playbooks/retro-cadence-state.yaml"
  if [[ -f "$CADENCE_FILE" ]]; then
    FEATURES_SINCE=$(grep "features_since_last_retro:" "$CADENCE_FILE" 2>/dev/null | awk '{print $2}' | tr -d '"' || echo "0")
    CADENCE_N=$(grep "retro_cadence_n:" "$CADENCE_FILE" 2>/dev/null | awk '{print $2}' | tr -d '"' || echo "5")
    if [[ "${FEATURES_SINCE:-0}" -ge "${CADENCE_N:-5}" ]]; then
      echo "⚠️  RETROSPECTIVA PROATIVA SUGERIDA"
      echo "   ${FEATURES_SINCE} features concluídas desde a última retro (cadência: a cada ${CADENCE_N})."
      echo "   Considere agendar retrospectiva antes da próxima feature."
      echo ""
    fi
  else
    echo "ℹ️  ${CADENCE_FILE} não encontrado — cadência de retro não verificada."
    echo ""
  fi
fi

echo "============================================================"
