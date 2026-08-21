#!/usr/bin/env bats

###############################################################################
# tests/scripts/harvest-patterns.bats
#
# Testes de integração para scripts/harvest-patterns.sh — feature
# specs/014-brownfield-multirepo-context-awareness/.
#
# Localização em tests/scripts/ (não scripts/tests/, como o plan.md desta
# feature sugeria antes de specs/013-governanca-testes-pr/ existir) para ser
# descoberto por scripts/run-tests.sh — ver docs/testing-policy.md, seção 4.
#
# Mocka o endpoint LLM via HARVEST_CURL_BIN (nunca chama uma API real).
#
# Cobre: test_AC3_harvest_patterns_java_interfaces, test_AC10_idempotency
# (ver plan.md, Rastreabilidade AC -> Teste -> Módulo)
###############################################################################

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  SCRIPT="$REPO_ROOT/scripts/harvest-patterns.sh"
  WORKDIR="$(mktemp -d)"
  cd "$WORKDIR"

  mkdir -p repo/domain/port fake-bin
  cat > repo/pom.xml << 'EOF'
<project></project>
EOF
  cat > repo/domain/port/UserRepository.java << 'EOF'
package com.example.domain.port;

public interface UserRepository {
    User findById(String id);
}
EOF

  cat > fake-bin/curl << 'MOCKEOF'
#!/usr/bin/env bash
args=("$@")
output_file=""
for i in "${!args[@]}"; do
  if [[ "${args[$i]}" == "-o" ]]; then
    output_file="${args[$((i+1))]}"
  fi
done
cat > "$output_file" << 'EOF'
{
  "tokens_used": 500,
  "estimated_cost": 0.001,
  "entries": [
    {
      "tag": "java-port-interface",
      "description": "Interfaces Java em domain/port como ponto de extensao",
      "example": "public interface UserRepository { User findById(String id); }",
      "source_file": "domain/port/UserRepository.java",
      "source_line": "3"
    }
  ]
}
EOF
echo -n "200"
MOCKEOF
  chmod +x fake-bin/curl

  cat > fake-bin/curl-empty << 'MOCKEOF'
#!/usr/bin/env bash
args=("$@")
output_file=""
for i in "${!args[@]}"; do
  if [[ "${args[$i]}" == "-o" ]]; then
    output_file="${args[$((i+1))]}"
  fi
done
echo '{"entries": []}' > "$output_file"
echo -n "200"
MOCKEOF
  chmod +x fake-bin/curl-empty

  export HARVEST_API_URL="https://fake-llm.example.com/analyze"
  export HARVEST_API_TOKEN="fake-token-123"
  export HARVEST_CURL_BIN="$WORKDIR/fake-bin/curl"
  export CATALOG_FILE="$WORKDIR/reuse-catalog-test.yaml"
  echo 'version: 1' > "$CATALOG_FILE"
  echo 'entries: []' >> "$CATALOG_FILE"
}

teardown() {
  cd "$REPO_ROOT"
  rm -rf "$WORKDIR"
}

@test "erro claro quando HARVEST_API_URL/HARVEST_API_TOKEN ausentes" {
  unset HARVEST_API_URL
  unset HARVEST_API_TOKEN
  run bash "$SCRIPT" "$WORKDIR/repo"
  [ "$status" -eq 1 ]
  [[ "$output" == *"HARVEST_API_URL"* ]]
  [[ "$output" == *"HARVEST_API_TOKEN"* ]]
}

@test "test_AC3_harvest_patterns_java_interfaces: detecta interface Java e propõe entrada" {
  run bash "$SCRIPT" "$WORKDIR/repo" --output "$CATALOG_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Stack detectada: java"* ]]
  run grep -c 'tag: java-port-interface' "$CATALOG_FILE"
  [ "$output" -eq 1 ]
  run grep -c 'source_file\|domain/port/UserRepository.java' "$CATALOG_FILE"
  [ "$output" -ge 1 ]
}

@test "test_AC10_idempotency: segunda execução não duplica a entrada" {
  run bash "$SCRIPT" "$WORKDIR/repo" --output "$CATALOG_FILE"
  [ "$status" -eq 0 ]
  run bash "$SCRIPT" "$WORKDIR/repo" --output "$CATALOG_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"já existe no catálogo"* ]]
  run grep -c 'tag: java-port-interface' "$CATALOG_FILE"
  [ "$output" -eq 1 ]
}

@test "repo sem padrões detectáveis não gera entrada vazia/genérica" {
  mkdir -p "$WORKDIR/empty-repo"
  HARVEST_CURL_BIN="$WORKDIR/fake-bin/curl-empty" run bash "$SCRIPT" "$WORKDIR/empty-repo" --output "$CATALOG_FILE"
  [ "$status" -eq 0 ]
  run grep -c 'tag:' "$CATALOG_FILE"
  [ "$output" -eq 0 ]
}

@test "--subpath limita o harvest a um subdiretório" {
  mkdir -p "$WORKDIR/repo/vendor/other/domain/port"
  cat > "$WORKDIR/repo/vendor/other/domain/port/ShouldNotBeScanned.java" << 'EOF'
public interface ShouldNotBeScanned { void x(); }
EOF
  run bash "$SCRIPT" "$WORKDIR/repo" --subpath domain/port --output "$CATALOG_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" != *"ShouldNotBeScanned"* ]]
}

@test "--dry-run não escreve no catálogo" {
  run bash "$SCRIPT" "$WORKDIR/repo" --output "$CATALOG_FILE" --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"[--dry-run]"* ]]
  run grep -c 'tag:' "$CATALOG_FILE"
  [ "$output" -eq 0 ]
}

@test "--help mostra uso sem exigir HARVEST_API_URL/HARVEST_API_TOKEN" {
  unset HARVEST_API_URL
  unset HARVEST_API_TOKEN
  run bash "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Uso:"* ]]
}
