#!/usr/bin/env bash
###############################################################################
# tests/scripts/fixtures/security-scan-gh-mock.sh
#
# Mock do `gh` CLI compartilhado pelos testes de scripts/security-compliance-scan.sh.
# NUNCA chama a API real do GitHub nem usa credenciais — todas as respostas
# vêm de fixtures em memória registradas com `gh_fixture`.
#
# Uso (dentro de um *.test.sh):
#   source "${ROOT_DIR}/tests/scripts/fixtures/security-scan-gh-mock.sh"
#   gh_fixture "repos/org/r/branches/main/protection" 200 '{"...":...}'
#   gh_fixture "repos/org/r/actions/secrets" 403 "" "Resource not accessible by integration"
#
# Rotas `gh api` sem fixture respondem 404 ("Not Found"). Toda chamada é
# registrada em $GH_CALL_LOG com o token em uso (token=<GH_TOKEN>), para que
# os testes verifiquem que o token do GitHub App nunca é usado em escrita.
#
# Subcomandos de escrita/leitura de issue simulados:
#   gh issue list   -> imprime $GH_MOCK_ISSUE_LIST (JSON, padrão "[]")
#   gh issue create -> imprime $GH_MOCK_CREATED_URL
#   gh issue edit / close / comment / view, gh label create, gh search issues
###############################################################################

declare -gA GH_FIXTURE_STATUS=()
declare -gA GH_FIXTURE_BODY=()
declare -gA GH_FIXTURE_ERROR=()
GH_CALL_LOG="${GH_CALL_LOG:-$(mktemp)}"
GH_MOCK_ISSUE_LIST="${GH_MOCK_ISSUE_LIST:-[]}"
GH_MOCK_CREATED_URL="${GH_MOCK_CREATED_URL:-https://ghe.example/org/report/issues/999}"
export GH_CALL_LOG

gh_fixture() {
  local path="$1" status="$2" body="${3:-}" error="${4:-}"
  GH_FIXTURE_STATUS["$path"]="$status"
  GH_FIXTURE_BODY["$path"]="$body"
  GH_FIXTURE_ERROR["$path"]="$error"
}

gh_fixtures_reset() {
  GH_FIXTURE_STATUS=()
  GH_FIXTURE_BODY=()
  GH_FIXTURE_ERROR=()
  : > "$GH_CALL_LOG"
}

gh() {
  printf 'token=%s %s\n' "${GH_TOKEN:-}" "$*" >> "$GH_CALL_LOG"
  local sub="${1:-}"
  shift || true
  case "$sub" in
    api)
      local path="" arg
      while [[ $# -gt 0 ]]; do
        arg="$1"
        case "$arg" in
          --paginate|--silent|-i) shift ;;
          -H|-X|--jq|-f|-F|--method|--header) shift 2 ;;
          *) [[ -z "$path" ]] && path="$arg"; shift ;;
        esac
      done
      local status="${GH_FIXTURE_STATUS[$path]:-404}"
      if [[ "$status" == "200" || "$status" == "204" ]]; then
        printf '%s' "${GH_FIXTURE_BODY[$path]:-}"
        return 0
      fi
      echo "gh: ${GH_FIXTURE_ERROR[$path]:-Not Found} (HTTP ${status})" >&2
      return 1
      ;;
    issue)
      case "${1:-}" in
        list) printf '%s\n' "$GH_MOCK_ISSUE_LIST" ;;
        create) printf '%s\n' "$GH_MOCK_CREATED_URL" ;;
        view) printf '%s\n' '{"comments":[]}' ;;
        edit|close|comment) : ;;
      esac
      return 0
      ;;
    label|search)
      [[ "$sub" == "search" ]] && printf '%s\n' '[]'
      return 0
      ;;
    *)
      echo "mock gh: subcomando não suportado: ${sub}" >&2
      return 1
      ;;
  esac
}
export -f gh

gh_calls_matching() {
  grep -cE -- "$1" "$GH_CALL_LOG" || true
}
