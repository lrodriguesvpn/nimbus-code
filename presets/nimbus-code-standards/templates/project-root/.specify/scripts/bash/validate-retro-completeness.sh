#!/usr/bin/env bash

###############################################################################
# validate-retro-completeness.sh
#
# Checagem determinística de completude para specs/<feature>/retro.md,
# análoga a validate-interview-completeness.sh. Detecta se o texto de EXEMPLO
# do retro-template.md ainda está presente sem substituição — sinal de que o
# arquivo foi criado (copiado do template) mas nunca de fato preenchido com o
# conteúdo real da divergência.
#
# Usado por /speckit-implement (Mandatory Post-Execution Validation) em
# conjunto com detect-retro-signal.sh: quando um sinal de retrabalho é
# detectado, este script garante que o retro.md resultante não fica apenas
# com os textos de exemplo do template, sem exigir um formato rígido de
# quantas linhas/causas devem existir (podem ser 1, 2 ou mais).
#
# Uso:
#   validate-retro-completeness.sh --file <path/retro.md> [--json]
#
# Comportamento:
#   - Arquivo ausente: erro, exit 1.
#   - Texto de exemplo literal do template ainda presente: reporta quais
#     trechos, exit 1 (NÃO valida como completo).
#   - Nenhum texto de exemplo restante: exit 0.
###############################################################################

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
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
Usage: validate-retro-completeness.sh --file <path/retro.md> [--json]

Checagem determinística de completude para specs/<feature>/retro.md: confirma
que os textos de EXEMPLO do retro-template.md
(presets/nimbus-code-standards/templates/feature-artifacts/retro-template.md)
foram substituídos por conteúdo real, não deixados como estavam no template.

Seguro de rodar sempre, incondicionalmente, como parte da Mandatory
Post-Execution Validation de /speckit-implement, junto com
detect-retro-signal.sh.
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
  echo -e "${RED}Erro: --file é obrigatório (caminho do retro.md)${NC}" >&2
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

# Textos de EXEMPLO literais do retro-template.md — se qualquer um deles
# ainda estiver presente verbatim, o arquivo não foi customizado com o
# conteúdo real da divergência.
EXAMPLE_PATTERNS=(
  '\[ex\.: graph\.yaml\]'
  '\[módulos X e Y\]'
  '\[foi necessário incluir módulo Z não previsto\]'
  '\[ex\.: SLO Gate\]'
  '\[p99 < 200ms\]'
  '\[p99 real em staging: 340ms'
  '\[ex\.: testes de integração\]'
  '\[AC-2 coberto por teste\]'
  '\[dependência externa indisponível em CI'
  '\[causa raiz 1\]'
  '\[causa raiz 2\]'
  '\[ex\.: adicionar módulo X ao bounded-contexts\.yaml\]'
  '\[YYYY-MM-DD\]'
  '\[link\]$'
  '\[tag\]` — `\[descrição em 1'
)

FOUND=()
for pattern in "${EXAMPLE_PATTERNS[@]}"; do
  if grep -qE "$pattern" "$FILE"; then
    FOUND+=("$pattern")
  fi
done

if [[ ${#FOUND[@]} -gt 0 ]]; then
  if $JSON_MODE; then
    IFS=,; printf '{"status":"incomplete","file":"%s","unresolved_examples":[%s]}\n' \
      "$FILE" "$(printf '"%s",' "${FOUND[@]}" | sed 's/,$//')"
  else
    echo -e "${RED}✗ retro.md incompleto — texto de exemplo do template ainda presente:${NC}"
    for p in "${FOUND[@]}"; do
      echo "  - $p"
    done
    echo "Substitua os exemplos pelo conteúdo real da divergência (ou remova a linha/seção se não aplicável)."
  fi
  exit 1
fi

if $JSON_MODE; then
  printf '{"status":"ok","file":"%s"}\n' "$FILE"
else
  echo -e "${GREEN}✓ retro.md completo — nenhum texto de exemplo do template restante.${NC}"
fi

exit 0
