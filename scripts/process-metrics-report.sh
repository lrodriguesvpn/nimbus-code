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
# Modos adicionais (specs/021-dora-metrics-governance — governança de coleta
# híbrida, trilha de auditoria de ajustes manuais e gate de fechamento de
# revisão periódica):
#
#   --record-manual-adjustment --indicator <indicador> \
#     --justification "<texto>" --author <handle> --evidence-link <url> \
#     --exception-category <categoria> [--approved-by <handle>] \
#     [--review-cycle-period <periodo>]
#     Registra um ajuste manual em docs/playbooks/dora-manual-adjustments-log.yaml.
#     Rejeita a entrada se qualquer um dos 5 campos obrigatórios
#     (indicator, justification, author, evidence_link, exception_category)
#     estiver vazio (FR-004/FR-005).
#
#   --check-review-cycle-closure --review-cycle-period <periodo>
#     Verifica se algum ajuste manual vinculado a esse período está com
#     campo obrigatório incompleto. Reporta CLOSURE_BLOCKED (exit 1) ou
#     CLOSURE_OK (exit 0) — nunca fecha uma revisão silenciosamente com
#     ajuste pendente (FR-006).
#
# Requer: gh CLI autenticado (apenas nos modos de coleta automática)

set -euo pipefail

REPO_OWNER=""
REPO_NAME=""
SINCE=""
UNTIL=""
CHECK_RETRO_CADENCE=false

RECORD_MANUAL_ADJUSTMENT=false
CHECK_REVIEW_CYCLE_CLOSURE=false
INDICATOR=""
JUSTIFICATION=""
AUTHOR=""
EVIDENCE_LINK=""
EXCEPTION_CATEGORY=""
APPROVED_BY=""
REVIEW_CYCLE_PERIOD=""

ADJUSTMENTS_LOG_FILE="docs/playbooks/dora-manual-adjustments-log.yaml"

# --- Argument parsing ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-owner) REPO_OWNER="$2"; shift 2 ;;
    --repo-name)  REPO_NAME="$2";  shift 2 ;;
    --since)      SINCE="$2";      shift 2 ;;
    --until)      UNTIL="$2";      shift 2 ;;
    --check-retro-cadence) CHECK_RETRO_CADENCE=true; shift ;;
    --record-manual-adjustment) RECORD_MANUAL_ADJUSTMENT=true; shift ;;
    --check-review-cycle-closure) CHECK_REVIEW_CYCLE_CLOSURE=true; shift ;;
    --indicator)            INDICATOR="$2";            shift 2 ;;
    --justification)        JUSTIFICATION="$2";         shift 2 ;;
    --author)                AUTHOR="$2";                shift 2 ;;
    --evidence-link)         EVIDENCE_LINK="$2";          shift 2 ;;
    --exception-category)    EXCEPTION_CATEGORY="$2";     shift 2 ;;
    --approved-by)            APPROVED_BY="$2";            shift 2 ;;
    --review-cycle-period)   REVIEW_CYCLE_PERIOD="$2";    shift 2 ;;
    *) echo "Argumento desconhecido: $1" >&2; exit 1 ;;
  esac
done

# --- Modo: registrar ajuste manual (T010, FR-004, FR-005) ---
if [[ "$RECORD_MANUAL_ADJUSTMENT" == "true" ]]; then
  MISSING_FIELDS=()
  [[ -z "$INDICATOR" ]] && MISSING_FIELDS+=("--indicator")
  [[ -z "$JUSTIFICATION" ]] && MISSING_FIELDS+=("--justification")
  [[ -z "$AUTHOR" ]] && MISSING_FIELDS+=("--author")
  [[ -z "$EVIDENCE_LINK" ]] && MISSING_FIELDS+=("--evidence-link")
  [[ -z "$EXCEPTION_CATEGORY" ]] && MISSING_FIELDS+=("--exception-category")

  if [[ ${#MISSING_FIELDS[@]} -gt 0 ]]; then
    echo "✗ Ajuste manual REJEITADO — campo(s) obrigatório(s) ausente(s): ${MISSING_FIELDS[*]}" >&2
    echo "  Um ajuste manual sempre exige justificativa, autor, evidência e categoria de exceção (FR-004)." >&2
    exit 1
  fi

  if [[ ! -f "$ADJUSTMENTS_LOG_FILE" ]]; then
    echo "✗ $ADJUSTMENTS_LOG_FILE não encontrado — crie o arquivo de estado antes de registrar ajustes" >&2
    exit 1
  fi

  EXISTING_COUNT="$(grep -c '^  - id: ADJ-' "$ADJUSTMENTS_LOG_FILE" 2>/dev/null)" || EXISTING_COUNT=0
  NEXT_SEQ=$(( EXISTING_COUNT + 1 ))
  ADJUSTMENT_ID=$(printf "ADJ-%04d" "$NEXT_SEQ")
  TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  # json.dumps produz uma string entre aspas duplas com escapes válidos tanto
  # em JSON quanto em YAML flow scalar — evita depender de PyYAML/yq para uma
  # escrita simples e append-only.
  ESCAPED=$(python3 -c "
import json
fields = ['''${JUSTIFICATION}''', '''${AUTHOR}''', '''${EVIDENCE_LINK}''', '''${EXCEPTION_CATEGORY}''', '''${APPROVED_BY:-$AUTHOR}''', '''${REVIEW_CYCLE_PERIOD}''']
print('\n'.join(json.dumps(f) for f in fields))
")
  ESCAPED_JUSTIFICATION=$(sed -n '1p' <<< "$ESCAPED")
  ESCAPED_AUTHOR=$(sed -n '2p' <<< "$ESCAPED")
  ESCAPED_EVIDENCE=$(sed -n '3p' <<< "$ESCAPED")
  ESCAPED_CATEGORY=$(sed -n '4p' <<< "$ESCAPED")
  ESCAPED_APPROVED_BY=$(sed -n '5p' <<< "$ESCAPED")
  ESCAPED_PERIOD=$(sed -n '6p' <<< "$ESCAPED")

  cat >> "$ADJUSTMENTS_LOG_FILE" <<EOF
  - id: ${ADJUSTMENT_ID}
    indicator: ${INDICATOR}
    justification: ${ESCAPED_JUSTIFICATION}
    author: ${ESCAPED_AUTHOR}
    timestamp: "${TIMESTAMP}"
    evidence_link: ${ESCAPED_EVIDENCE}
    exception_category: ${ESCAPED_CATEGORY}
    approved_by: ${ESCAPED_APPROVED_BY}
    review_cycle_period: ${ESCAPED_PERIOD}
EOF

  echo "✓ Ajuste manual ${ADJUSTMENT_ID} registrado em ${ADJUSTMENTS_LOG_FILE}"
  exit 0
fi

# --- Modo: gate de fechamento de revisão periódica (T011, FR-006) ---
if [[ "$CHECK_REVIEW_CYCLE_CLOSURE" == "true" ]]; then
  if [[ -z "$REVIEW_CYCLE_PERIOD" ]]; then
    echo "Uso: $0 --check-review-cycle-closure --review-cycle-period <periodo>" >&2
    exit 1
  fi

  if [[ ! -f "$ADJUSTMENTS_LOG_FILE" ]]; then
    echo "CLOSURE_OK — ${ADJUSTMENTS_LOG_FILE} não encontrado, nenhum ajuste a verificar"
    exit 0
  fi

  RESULT=$(python3 -c "
import re

REQUIRED = ['justification', 'author', 'timestamp', 'evidence_link', 'exception_category']
period = '''${REVIEW_CYCLE_PERIOD}'''
text = open('${ADJUSTMENTS_LOG_FILE}').read()

# Cada entrada começa em uma linha '  - id: ADJ-XXXX' e vai até a próxima
# entrada do mesmo nível ou o fim do arquivo — parsing linha-a-linha simples,
# suficiente para o schema fixo e controlado deste arquivo (não é um parser
# YAML genérico).
blocks = re.split(r'(?=^  - id: )', text, flags=re.M)
pending = []
for block in blocks:
    m = re.search(r'^  - id: (\S+)', block, flags=re.M)
    if not m:
        continue
    entry_id = m.group(1)
    period_match = re.search(r'^\s*review_cycle_period:\s*\"?([^\"\n]*)\"?', block, flags=re.M)
    entry_period = period_match.group(1).strip() if period_match else ''
    if entry_period != period:
        continue
    for field in REQUIRED:
        field_match = re.search(rf'^\s*{field}:\s*\"?([^\"\n]*)\"?', block, flags=re.M)
        value = field_match.group(1).strip() if field_match else ''
        if not value:
            pending.append(entry_id)
            break

if pending:
    print('CLOSURE_BLOCKED: ' + ', '.join(sorted(set(pending))))
else:
    print('CLOSURE_OK')
")

  echo "$RESULT"
  if [[ "$RESULT" == CLOSURE_BLOCKED* ]]; then
    echo "  Revisão do período '${REVIEW_CYCLE_PERIOD}' NÃO pode ser fechada — complete a justificativa dos ajustes acima (FR-006)." >&2
    exit 1
  fi
  exit 0
fi

# --- Modo padrão: relatório de métricas DORA (requer repo-owner/repo-name) ---
if [[ -z "$REPO_OWNER" || -z "$REPO_NAME" ]]; then
  echo "Uso: $0 --repo-owner <org> --repo-name <repo> [--since <YYYY-MM-DD>] [--until <YYYY-MM-DD>] [--check-retro-cadence]" >&2
  echo "  ou: $0 --record-manual-adjustment --indicator <ind> --justification <texto> --author <handle> --evidence-link <url> --exception-category <cat>" >&2
  echo "  ou: $0 --check-review-cycle-closure --review-cycle-period <periodo>" >&2
  exit 1
fi

REPO="${REPO_OWNER}/${REPO_NAME}"

if [[ -z "$UNTIL" ]]; then
  UNTIL="$(date -u +%Y-%m-%d)"
fi

if [[ -z "$SINCE" ]]; then
  SINCE="$(date -u -v-30d +%Y-%m-%d 2>/dev/null || date -u -d '30 days ago' +%Y-%m-%d)"
fi

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

# --- Helper: checagem de qualidade de dados (T006, FR-011) ---
# Verifica, para um dataset já coletado: (a) ausência de duplicidade (mesmo
# `number` aparecendo mais de uma vez) e (b) consistência temporal
# (createdAt <= closedAt/mergedAt — um item nunca pode ser fechado antes de
# ser criado). Não recalcula completude aqui: indicadores sem dado suficiente
# já são marcados explicitamente como INSUFFICIENT_DATA pelas funções
# existentes (count_in_range/avg_duration_in_range).
data_quality_check() {
  local json="$1"
  local label="$2"
  echo "$json" | python3 -c "
import sys, json
from datetime import datetime

data = json.load(sys.stdin)
label = '${label}'

seen_numbers = set()
duplicates = set()
temporal_issues = []

for item in data:
    number = item.get('number')
    if number in seen_numbers:
        duplicates.add(number)
    seen_numbers.add(number)

    created = item.get('createdAt')
    closed = item.get('closedAt') or item.get('mergedAt')
    if created and closed:
        created_dt = datetime.fromisoformat(created.replace('Z', '+00:00'))
        closed_dt = datetime.fromisoformat(closed.replace('Z', '+00:00'))
        if closed_dt < created_dt:
            temporal_issues.append(number)

if duplicates:
    print(f'  ⚠ {label}: duplicidade detectada — item(ns) #' + ', #'.join(str(d) for d in sorted(duplicates)))
if temporal_issues:
    print(f'  ⚠ {label}: inconsistência temporal (fechado antes de criado) — item(ns) #' + ', #'.join(str(t) for t in sorted(temporal_issues)))
"
}

DATA_QUALITY_WARNINGS=""
DATA_QUALITY_WARNINGS+="$(data_quality_check "$DEPLOY_JSON" "dora:deployment-frequency")"
DATA_QUALITY_WARNINGS+="$(data_quality_check "$LEAD_JSON" "dora:lead-time")"
DATA_QUALITY_WARNINGS+="$(data_quality_check "$FAILURE_ISSUES_JSON" "dora:change-failure-rate (issues)")"
DATA_QUALITY_WARNINGS+="$(data_quality_check "$FAILURE_PRS_JSON" "dora:change-failure-rate (PRs)")"
DATA_QUALITY_WARNINGS+="$(data_quality_check "$MTTR_JSON" "dora:mttr")"

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

# --- Gatilhos objetivos de degradação (T016, FR-008/FR-009) ---
# Reaproveita as Metas Iniciais Sugeridas já documentadas em
# docs/playbooks/README.md (feature 012): apenas sinaliza — não abre Issue
# automaticamente. A abertura da Improvement Action com owner/prioridade/
# prazo continua sendo uma ação humana orientada por este sinal (mesmo
# racional já usado pela sinalização proativa de retrospectiva).
DEGRADATION_SIGNALS=""

if [[ "$DEPLOY_COUNT" != "0" ]]; then
  DEPLOY_PER_WEEK=$(python3 -c "
from datetime import datetime
since = datetime.fromisoformat('${SINCE}')
until = datetime.fromisoformat('${UNTIL}')
weeks = max(1, (until - since).days / 7)
print(f'{${DEPLOY_COUNT} / weeks:.2f}')
")
  if python3 -c "exit(0 if float('${DEPLOY_PER_WEEK}') < 1.0 else 1)"; then
    DEGRADATION_SIGNALS+="  ⚠ deployment_frequency abaixo da meta inicial (< 1/semana, atual: ${DEPLOY_PER_WEEK}/semana)\n"
  fi
fi

if [[ "$LEAD_TIME" != "INSUFFICIENT_DATA" ]]; then
  if python3 -c "exit(0 if float('${LEAD_TIME}') > 7.0 else 1)"; then
    DEGRADATION_SIGNALS+="  ⚠ lead_time_for_changes acima da meta inicial (> 7 dias, atual: ${LEAD_TIME} dias)\n"
  fi
fi

if [[ "$DEPLOY_COUNT" != "0" ]]; then
  CFR_VALUE=$(python3 -c "
failures = int('${FAILURE_COUNT}')
deploys = int('${DEPLOY_COUNT}')
print(f'{(failures / deploys * 100) if deploys > 0 else 0:.1f}')
")
  if python3 -c "exit(0 if float('${CFR_VALUE}') > 15.0 else 1)"; then
    DEGRADATION_SIGNALS+="  ⚠ change_failure_rate acima da meta inicial (> 15%, atual: ${CFR_VALUE}%)\n"
  fi
fi

if [[ "$MTTR" != "INSUFFICIENT_DATA" ]]; then
  if python3 -c "exit(0 if float('${MTTR}') > 24.0 else 1)"; then
    DEGRADATION_SIGNALS+="  ⚠ mttr acima da meta inicial (> 24h, atual: ${MTTR}h)\n"
  fi
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
echo "  Origem dos dados: 100% automática nesta execução (labels dora:* via gh API)."
echo "  Ajustes manuais (se houver) ficam em ${ADJUSTMENTS_LOG_FILE}, nunca neste relatório."
echo ""

if [[ -n "$DATA_QUALITY_WARNINGS" ]]; then
  echo "  Qualidade de dados — alertas (FR-011):"
  echo "$DATA_QUALITY_WARNINGS"
  echo ""
else
  echo "  Qualidade de dados: nenhuma duplicidade ou inconsistência temporal detectada."
  echo ""
fi

if [[ -n "$DEGRADATION_SIGNALS" ]]; then
  echo "  Sinais de degradação (FR-008) — ação de backlog recomendada (FR-009):"
  echo -e "$DEGRADATION_SIGNALS"
  echo "  Abra/atualize uma Issue de melhoria com owner, priority:* e prazo de reavaliação."
  echo "  Ver docs/playbooks/README.md, seção \"Cadência de Revisão de Métricas de Processo (DORA)\"."
  echo ""
else
  echo "  Nenhum indicador abaixo/acima da meta inicial nesta execução — sem sinal de degradação."
  echo ""
fi

# --- Optional: check retro cadence ---
if [[ "$CHECK_RETRO_CADENCE" == "true" ]]; then
  CADENCE_FILE="docs/playbooks/retro-cadence-state.yaml"
  if [[ -f "$CADENCE_FILE" ]]; then
    FEATURES_SINCE=$(grep "features_since_last_retro:" "$CADENCE_FILE" 2>/dev/null | awk '{print $2}' | tr -d '"' || echo "0")
    CADENCE_N=$(grep "retro_cadence_n:" "$CADENCE_FILE" 2>/dev/null | awk '{print $2}' | tr -d '"' || echo "5")
    LAST_RETRO_DATE=$(grep "last_retro_date:" "$CADENCE_FILE" 2>/dev/null | awk '{print $2}' | tr -d '"' || echo "null")

    FEATURES_SINCE="${FEATURES_SINCE:-0}"
    CADENCE_N="${CADENCE_N:-5}"
    LAST_RETRO_DATE="${LAST_RETRO_DATE:-null}"

    if ! [[ "$FEATURES_SINCE" =~ ^[0-9]+$ ]]; then FEATURES_SINCE=0; fi
    if ! [[ "$CADENCE_N" =~ ^[0-9]+$ ]]; then CADENCE_N=5; fi

    FEATURES_SINCE=$((FEATURES_SINCE + 1))

    python3 - <<PY
from pathlib import Path
import re
p = Path("$CADENCE_FILE")
txt = p.read_text()
txt = re.sub(r'^features_since_last_retro:\\s*.*$', f'features_since_last_retro: $FEATURES_SINCE', txt, flags=re.M)
if not re.search(r'^features_since_last_retro:\\s*', txt, flags=re.M):
    txt += f'\\nfeatures_since_last_retro: $FEATURES_SINCE\\n'
p.write_text(txt)
PY

    if [[ "$FEATURES_SINCE" -ge "$CADENCE_N" ]]; then
      echo "⚠️  Retrospectiva devida — ${FEATURES_SINCE} features concluídas desde ${LAST_RETRO_DATE}."
      echo "   Use presets/nimbus-code-standards/templates/feature-artifacts/retro-template.md"
      echo "   para registrar a retro e, após realizá-la, resetar features_since_last_retro para 0."
      echo ""
    else
      echo "ℹ️  Cadência de retrospectiva: ${FEATURES_SINCE}/${CADENCE_N} features desde ${LAST_RETRO_DATE}."
      echo ""
    fi
  else
    echo "ℹ️  ${CADENCE_FILE} não encontrado — cadência de retro não verificada."
    echo ""
  fi
fi

echo "============================================================"
