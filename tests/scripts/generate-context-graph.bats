#!/usr/bin/env bats

###############################################################################
# tests/scripts/generate-context-graph.bats
#
# Testes de integração para scripts/generate-context-graph.sh — feature
# specs/014-brownfield-multirepo-context-awareness/.
#
# Nota de localização: o plan.md desta feature (escrito antes de
# specs/013-governanca-testes-pr/) sugeria scripts/tests/. Colocado aqui em
# tests/scripts/ para ser descoberto por scripts/run-tests.sh (o gate
# obrigatório de PR introduzido pela feature 013) — ver docs/testing-policy.md,
# seção 4 (Convenções de Localização e Nomenclatura).
#
# Cobre: test_AC1_generate_context_graph_output, test_AC5_graceful_fallback_no_repos,
# test_AC6_ci_api_fallback (ver plan.md, Rastreabilidade AC -> Teste -> Módulo)
###############################################################################

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  SCRIPT="$REPO_ROOT/scripts/generate-context-graph.sh"
  WORKDIR="$(mktemp -d)"
  cd "$WORKDIR"

  cat > bounded-contexts-fixture.yaml << 'EOF'
version: 1
contexts:
  - slug: "test-context"
    description: "Fixture de teste"
    repos:
      - "org/svc-a"
      - "org/svc-b"
    stack: "Java"
    team: "test"
    autonomous_ok: true
  - slug: "empty-context"
    description: "Contexto sem repos"
    repos: []
    stack: ""
    team: "test"
    autonomous_ok: true
EOF

  mkdir -p svc-a svc-b
  cat > svc-a/pom.xml << 'EOF'
<project><dependencies><dependency><artifactId>svc-b</artifactId></dependency></dependencies></project>
EOF
  cat > svc-b/pom.xml << 'EOF'
<project><dependencies></dependencies></project>
EOF

  export BOUNDED_CONTEXTS_FILE="$WORKDIR/bounded-contexts-fixture.yaml"
}

teardown() {
  cd "$REPO_ROOT"
  rm -rf "$WORKDIR"
}

@test "test_AC1_generate_context_graph_output: gera graph.yaml com nós e aresta na direção correta" {
  run bash "$SCRIPT" test-context --out-dir "$WORKDIR/out"
  [ "$status" -eq 0 ]
  [ -f "$WORKDIR/out/graph.yaml" ]
  [ -f "$WORKDIR/out/graph.md" ]
  run grep -c '"repo"' "$WORKDIR/out/graph.yaml"
  [ "$output" -eq 2 ]
  run grep -A1 'src: "org-svc-a"' "$WORKDIR/out/graph.yaml"
  [[ "$output" == *"dst: \"org-svc-b\""* ]]
  # Não deve haver aresta na direção invertida (B não depende de A)
  run bash -c "grep -A1 'src: \"org-svc-b\"' '$WORKDIR/out/graph.yaml' || true"
  [[ "$output" != *"dst: \"org-svc-a\""* ]]
}

@test "test_AC1_generate_context_graph_output: graph.md renderiza diagrama Mermaid válido" {
  run bash "$SCRIPT" test-context --out-dir "$WORKDIR/out"
  [ "$status" -eq 0 ]
  run grep -c '```mermaid' "$WORKDIR/out/graph.md"
  [ "$output" -eq 1 ]
  run grep -c 'graph LR' "$WORKDIR/out/graph.md"
  [ "$output" -eq 1 ]
}

@test "test_AC1: repo sem manifesto reconhecido é registrado no grafo com arestas vazias e aviso" {
  rm -rf svc-b/*
  run bash "$SCRIPT" test-context --out-dir "$WORKDIR/out2"
  [ "$status" -eq 0 ]
  run grep -c 'unavailable' "$WORKDIR/out2/graph.yaml"
  [ "$output" -ge 1 ]
  # svc-b continua presente como nó, não é excluído do grafo
  run grep -c 'repository: "org/svc-b"' "$WORKDIR/out2/graph.yaml"
  [ "$output" -eq 1 ]
}

@test "test_AC5_graceful_fallback_no_repos: contexto sem repos avisa e sai com sucesso (não bloqueia)" {
  run bash "$SCRIPT" empty-context --out-dir "$WORKDIR/out3"
  [ "$status" -eq 0 ]
  [[ "$output" == *"não tem nenhum repositório mapeado"* ]]
  [ ! -f "$WORKDIR/out3/graph.yaml" ]
}

@test "contexto inexistente falha com mensagem clara (erro real, não gracioso)" {
  run bash "$SCRIPT" does-not-exist --out-dir "$WORKDIR/out4"
  [ "$status" -eq 1 ]
  [[ "$output" == *"não encontrado"* ]]
}

@test "test_AC6_ci_api_fallback: usa gh api quando repo não está disponível localmente" {
  rm -rf svc-a
  mkdir -p fake-gh-bin
  cat > fake-gh-bin/gh << 'EOF'
#!/usr/bin/env bash
if [[ "$1" == "api" && "$2" == *"svc-a/contents/pom.xml"* ]]; then
  echo '<project><dependencies><dependency><artifactId>svc-b</artifactId></dependency></dependencies></project>' | base64
  exit 0
fi
exit 1
EOF
  chmod +x fake-gh-bin/gh
  PATH="$WORKDIR/fake-gh-bin:$PATH" run bash "$SCRIPT" test-context --out-dir "$WORKDIR/out5"
  [ "$status" -eq 0 ]
  run grep -c 'manifest_source: "gh-api"' "$WORKDIR/out5/graph.yaml"
  [ "$output" -eq 1 ]
}

@test "detecta dependência circular sem loop infinito e sinaliza no graph.md" {
  cat > svc-b/pom.xml << 'EOF'
<project><dependencies><dependency><artifactId>svc-a</artifactId></dependency></dependencies></project>
EOF
  run bash "$SCRIPT" test-context --out-dir "$WORKDIR/out6"
  [ "$status" -eq 0 ]
  run grep -c 'circulares' "$WORKDIR/out6/graph.md"
  [ "$output" -eq 1 ]
}

@test "--help mostra uso sem exigir bounded-contexts.yaml" {
  rm -f "$BOUNDED_CONTEXTS_FILE"
  run bash "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Uso:"* ]]
}
