#!/usr/bin/env bash

###############################################################################
# validate-interview-completeness.sh
#
# Checagem determinística (bash puro, não depende de um LLM "lembrar" de
# preencher tudo antes de salvar) para o fluxo de /speckit-interview. Reaproveita
# o mesmo padrão de docs/reuse-catalog.yaml, tag "skill-mid-flow-instruction-
# reliability-gate" (specs/005-epic-feature-us-ghe-hierarchy): uma instrução em
# prosa no meio de um SKILL.md longo pode ser pulada sem que ninguém perceba —
# este script é a rede de segurança final, chamada incondicionalmente como
# último passo do Outline de /speckit-interview.
#
# Verifica se um interview.md preenchido ainda tem placeholders literais do
# template não substituídos (ex.: "[YYYY-MM-DD]", "<resumo curto>") — sinal de
# que um bloco obrigatório foi esquecido em vez de respondido ou marcado como
# N/A/[NEEDS CLARIFICATION] explicitamente.
#
# Uso:
#   validate-interview-completeness.sh --file <path/interview.md> [--json]
#
# Comportamento:
#   - Arquivo ausente: erro, exit 1.
#   - Placeholders literais do template ainda presentes: reporta quais, exit 1.
#   - Bloco YAML "Saída Estruturada" ausente ou sem `interview_output:`: aviso,
#     não bloqueia (o bloco é opcional no template) — reportado, exit 0.
#   - Tudo preenchido: exit 0.
###############################################################################

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

FILE=""
JSON_MODE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --file)
      FILE="$2"
      shift 2
      ;;
    --json)
      JSON_MODE=true
      shift
      ;;
    --help|-h)
      cat <<'EOF'
Usage: validate-interview-completeness.sh --file <path/interview.md> [--json]

Checagem determinística de completude para o fluxo de /speckit-interview:
confirma que não sobraram placeholders literais do template
(presets/nimbus-code-standards/templates/feature-artifacts/interview-template.md)
no interview.md salvo, o que indicaria um bloco obrigatório esquecido em vez
de respondido/marcado como N/A ou [NEEDS CLARIFICATION] explicitamente.

Seguro de rodar sempre, incondicionalmente, como último passo do Outline de
/speckit-interview antes do Completion Report.
EOF
      exit 0
      ;;
    *)
      echo -e "${RED}Erro: opção desconhecida: $1${NC}" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$FILE" ]]; then
  echo -e "${RED}Erro: --file é obrigatório (caminho do interview.md salvo)${NC}" >&2
  exit 1
fi

if [[ ! -f "$FILE" ]]; then
  if $JSON_MODE; then
    printf '{"status":"error","reason":"file_not_found","file":"%s"}\n' "$FILE"
  else
    echo -e "${RED}Erro: $FILE não encontrado${NC}" >&2
  fi
  exit 1
fi

# Placeholders literais do template que NUNCA devem sobreviver ao preenchimento
# real — cada um indica um campo obrigatório do Cabeçalho ou dos 4 Blocos que
# ficou como o template original, não como resposta/N/A/[NEEDS CLARIFICATION].
PLACEHOLDER_PATTERNS=(
  '\[YYYY-MM-DD\]'
  '\[nome/área\]'
  '\[nome humano, ou "Nimbus Agent'
  '\[presencial / Teams'
  '\[kebab-case, ou "a definir"\]'
  '\[P0-blocker / P1-high / P2-medium / P3-low'
  '\[Completo / Fast-Track\]'
  '\[X minutos\]'
  '\[o que foi entendido\]'
  '\[nome\]$'
)

FOUND=()
for pattern in "${PLACEHOLDER_PATTERNS[@]}"; do
  if grep -qE "$pattern" "$FILE"; then
    FOUND+=("$pattern")
  fi
done

# Bloco YAML "Saída Estruturada" é opcional no template — apenas aviso, não
# bloqueia, mas é útil sinalizar quando ausente (reduz a chance de automação
# futura do NIMBUS AGENT via Teams ter que fazer parsing de prosa livre).
YAML_PRESENT=true
if ! grep -q "interview_output:" "$FILE"; then
  YAML_PRESENT=false
fi

if [[ ${#FOUND[@]} -gt 0 ]]; then
  if $JSON_MODE; then
    IFS=,; printf '{"status":"incomplete","file":"%s","unresolved_placeholders":[%s],"yaml_output_present":%s}\n' \
      "$FILE" "$(printf '"%s",' "${FOUND[@]}" | sed 's/,$//')" "$YAML_PRESENT"
  else
    echo -e "${RED}✗ interview.md incompleto — placeholders não preenchidos encontrados:${NC}"
    for p in "${FOUND[@]}"; do
      echo "  - $p"
    done
    echo "Preencha (ou marque explicitamente N/A / [NEEDS CLARIFICATION]) antes de encerrar a entrevista."
  fi
  exit 1
fi

if $JSON_MODE; then
  printf '{"status":"ok","file":"%s","yaml_output_present":%s}\n' "$FILE" "$YAML_PRESENT"
else
  echo -e "${GREEN}✓ interview.md completo — nenhum placeholder do template sobrando.${NC}"
  if [[ "$YAML_PRESENT" == "false" ]]; then
    echo -e "${YELLOW}⚠ Bloco 'Saída Estruturada' (YAML) não preenchido — opcional, mas recomendado.${NC}"
  fi
fi

exit 0
