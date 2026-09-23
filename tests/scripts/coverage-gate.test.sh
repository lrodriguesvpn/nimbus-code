#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# tests/scripts/coverage-gate.test.sh
#
# Issue #450 / T055: valida scripts/coverage-gate.py (política de cobertura):
#   - cobertura global abaixo de 80% falha; acima passa;
#   - relatório ausente ("não publicado") ou vazio falha com exit 2;
#   - LCOV e Cobertura XML;
#   - cobertura do código alterado (diff) abaixo do mínimo falha;
#   - redução em relação ao baseline falha sem exceção;
#   - exceção ativa e aprovada aceita a violação; exceção vencida não.
# Usa apenas arquivos temporários e um repositório git local descartável.
###############################################################################

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GATE="${ROOT_DIR}/scripts/coverage-gate.py"
[[ -f "$GATE" ]] || { echo "✗ ${GATE} não encontrado"; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
pass=0
fail=0

expect_exit() {
  local description="$1" expected="$2"; shift 2
  local status=0
  (cd "$WORK" && python3 "$GATE" --summary "" "$@") >"$WORK/out.txt" 2>&1 || status=$?
  if [[ "$status" -eq "$expected" ]]; then
    echo "  ✓ ${description} (exit=${status})"; pass=$((pass + 1))
  else
    echo "  ✗ ${description} (esperado exit=${expected}, obtido=${status})"; sed 's/^/      /' "$WORK/out.txt"; fail=$((fail + 1))
  fi
}
expect_output() {
  local description="$1" pattern="$2"
  if grep -Fq -- "$pattern" "$WORK/out.txt"; then
    echo "  ✓ ${description}"; pass=$((pass + 1))
  else
    echo "  ✗ ${description} (padrão ausente: ${pattern})"; fail=$((fail + 1))
  fi
}

lcov() {
  # lcov <arquivo> <linhas-cobertas> <linhas-não-cobertas> (lista separada por espaço)
  local file="$1" covered="$2" uncovered="$3" ln
  echo "SF:${file}"
  for ln in $covered; do echo "DA:${ln},1"; done
  for ln in $uncovered; do echo "DA:${ln},0"; done
  echo "end_of_record"
}

echo "== tests/scripts/coverage-gate.test.sh =="

lcov "src/app.py" "1 2 3 4 5 6 7 8 9" "10" > "$WORK/high.info"          # 90%
lcov "src/app.py" "1 2 3 4 5 6 7" "8 9 10" > "$WORK/low.info"           # 70%
: > "$WORK/empty.info"

echo "-- cobertura global --"
expect_exit "90% >= 80% passa" 0 --report high.info --min 80
expect_output "resumo publica a cobertura global" "Cobertura global: **90.0%**"
expect_exit "70% < 80% falha" 1 --report low.info --min 80
expect_output "falha explica a violação" "cobertura global 70.0% < mínimo 80.0%"
expect_exit "relatório não publicado falha (exit 2)" 2 --report inexistente.info
expect_output "mensagem de relatório ausente" "Relatório de cobertura não publicado"
expect_exit "relatório sem linhas instrumentadas falha (exit 2)" 2 --report empty.info

cat > "$WORK/cobertura.xml" <<'XML'
<?xml version="1.0" ?>
<coverage line-rate="0.5"><packages><package name="p"><classes>
<class filename="src/mod.py"><lines><line number="1" hits="1"/><line number="2" hits="0"/></lines></class>
</classes></package></packages></coverage>
XML
expect_exit "Cobertura XML 50% falha" 1 --report cobertura.xml --format cobertura --min 80

echo "-- baseline (sem redução sem exceção) --"
expect_exit "90% abaixo do baseline 95% falha" 1 --report high.info --baseline 95
expect_output "falha cita redução" "cobertura reduziu de 95.0% para 90.0%"
expect_exit "90% acima do baseline 85% passa" 0 --report high.info --baseline 85

echo "-- exceções --"
cat > "$WORK/exc-active.json" <<'JSON'
{"schema_version":1,"exceptions":[{"id":"EXC-9","control":"coverage","owner":"@dono","justification":"migração","approved_by":"@aprovador","created_at":"2026-09-01","expires_at":"2026-10-15"}]}
JSON
cat > "$WORK/exc-expired.json" <<'JSON'
{"schema_version":1,"exceptions":[{"id":"EXC-8","control":"coverage","owner":"@dono","justification":"migração","approved_by":"@aprovador","created_at":"2026-06-01","expires_at":"2026-07-01"}]}
JSON
expect_exit "violação aceita por exceção ativa e aprovada" 0 --report low.info --exceptions exc-active.json --today 2026-09-22
expect_output "resumo registra a exceção usada" "Violação aceita pela exceção EXC-9"
expect_exit "exceção vencida não libera o gate" 1 --report low.info --exceptions exc-expired.json --today 2026-09-22

echo "-- cobertura do código alterado (diff) --"
(
  cd "$WORK"
  git init -q -b main repo
  cd repo
  git config user.email t@example.invalid; git config user.name t; git config commit.gpgsign false
  mkdir -p src
  printf 'a\nb\n' > src/app.py
  git add . && git commit -qm base
  git checkout -qb feature
  printf 'a\nb\nc\nd\ne\n' > src/app.py
  git commit -qam change
) >/dev/null
# linhas 1-2 antigas cobertas; linhas novas 3-5: só a 3 coberta => diff 33%
lcov "src/app.py" "1 2 3" "4 5" > "$WORK/repo/diff.info"
WORK_SAVE="$WORK"; WORK="$WORK/repo"
expect_exit "diff coverage 33% < 80% falha" 1 --report diff.info --min 50 --diff-min 80 --base-ref main
expect_output "resumo publica cobertura do código alterado" "Cobertura do código alterado: **33.33%** (1/3)"
lcov "src/app.py" "1 2 3 4 5" "" > "$WORK/diff-ok.info"
expect_exit "diff coverage 100% passa" 0 --report diff-ok.info --min 50 --diff-min 80 --base-ref main
WORK="$WORK_SAVE"

echo ""
echo "Resultado: ${pass} passaram, ${fail} falharam"
(( fail > 0 )) && exit 1
echo "✓ todos os testes passaram"
