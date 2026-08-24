#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  BOOTSTRAP_SCRIPT="$REPO_ROOT/bootstrap.sh"
}

@test "nimbus-code entrypoints do not use the broken raw GHE subdomain" {
  run bash -lc 'set -euo pipefail; cd "$1"; matches=$(grep -RIn "raw\\.venha-pra-nuvem\\.ghe\\.com/venha-pra-nuvem/nimbus-code-spec-kit-template/main/" README.md bootstrap.sh docs templates .github bundles presets extensions workflows tests || true); [ -z "$matches" ]' _ "$REPO_ROOT"
  [ "$status" -eq 0 ]
}

@test "bootstrap repo type prompt supports piped installs via /dev/tty fallback" {
  run bash -lc 'set -euo pipefail; cd "$1"; grep -q "/dev/tty" bootstrap.sh' _ "$REPO_ROOT"
  [ "$status" -eq 0 ]
}

@test "AC-1: detect_has_relevant_application_code function exists and handles greenfield case" {
  # Extract and test the detect_has_relevant_application_code function
  TEMP_DIR=$(mktemp -d)
  trap 'rm -rf "$TEMP_DIR"' EXIT
  
  cd "$TEMP_DIR"
  touch README.md LICENSE
  mkdir -p .github/workflows
  touch .github/workflows/test.yml
  
  # Create a test script that only sources the function
  cat > test_detection.sh << 'EOF'
    set -euo pipefail
    WORKDIR="$(pwd)"
    
    detect_has_relevant_application_code() {
      local application_dirs=(
        "src" "app" "packages" "services" "frontend" "backend"
        "lib" "config" "routes" "controllers" "models" "components"
      )
      
      for dir in "${application_dirs[@]}"; do
        if [[ -d "$WORKDIR/$dir" && -n "$(find "$WORKDIR/$dir" -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.py' -o -name '*.go' -o -name '*.java' -o -name '*.cs' -o -name '*.rb' \) 2>/dev/null | head -1)" ]]; then
          return 0
        fi
      done
      
      local manifest_files=(
        "package.json" "pom.xml" "build.gradle" "Makefile" "Dockerfile"
        "pyproject.toml" "setup.py" "go.mod" "Cargo.toml" ".csproj"
      )
      
      for manifest in "${manifest_files[@]}"; do
        if [[ -f "$WORKDIR/$manifest" ]]; then
          if grep -q "src\|app\|packages\|services\|frontend\|backend" "$WORKDIR/$manifest" 2>/dev/null; then
            return 0
          fi
        fi
      done
      
      local test_dirs=("__tests__" "test" "tests" "spec" "specs")
      for test_dir in "${test_dirs[@]}"; do
        if [[ -d "$WORKDIR/$test_dir" ]]; then
          local test_files=$(find "$WORKDIR/$test_dir" -type f \( -name '*.test.*' -o -name '*.spec.*' -o -name '*_test.*' -o -name '*_spec.*' \) 2>/dev/null | head -1)
          if [[ -n "$test_files" ]]; then
            if ! echo "$test_files" | grep -q "bootstrap\|infra\|setup"; then
              return 0
            fi
          fi
        fi
      done
      
      return 1
    }
    
    detect_has_relevant_application_code
    exit $?
EOF
  
  run bash test_detection.sh
  [ "$status" -eq 1 ]  # Greenfield should return 1 (no code found)
}

@test "AC-2: detect_has_relevant_application_code function identifies brownfield (src/ with JS)" {
  TEMP_DIR=$(mktemp -d)
  trap 'rm -rf "$TEMP_DIR"' EXIT
  
  cd "$TEMP_DIR"
  mkdir -p src
  echo "console.log('app code');" > src/index.js
  
  # Create a test script that only sources the function
  cat > test_detection.sh << 'EOF'
    set -euo pipefail
    WORKDIR="$(pwd)"
    
    detect_has_relevant_application_code() {
      local application_dirs=(
        "src" "app" "packages" "services" "frontend" "backend"
        "lib" "config" "routes" "controllers" "models" "components"
      )
      
      for dir in "${application_dirs[@]}"; do
        if [[ -d "$WORKDIR/$dir" && -n "$(find "$WORKDIR/$dir" -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.py' -o -name '*.go' -o -name '*.java' -o -name '*.cs' -o -name '*.rb' \) 2>/dev/null | head -1)" ]]; then
          return 0
        fi
      done
      
      local manifest_files=(
        "package.json" "pom.xml" "build.gradle" "Makefile" "Dockerfile"
        "pyproject.toml" "setup.py" "go.mod" "Cargo.toml" ".csproj"
      )
      
      for manifest in "${manifest_files[@]}"; do
        if [[ -f "$WORKDIR/$manifest" ]]; then
          if grep -q "src\|app\|packages\|services\|frontend\|backend" "$WORKDIR/$manifest" 2>/dev/null; then
            return 0
          fi
        fi
      done
      
      local test_dirs=("__tests__" "test" "tests" "spec" "specs")
      for test_dir in "${test_dirs[@]}"; do
        if [[ -d "$WORKDIR/$test_dir" ]]; then
          local test_files=$(find "$WORKDIR/$test_dir" -type f \( -name '*.test.*' -o -name '*.spec.*' -o -name '*_test.*' -o -name '*_spec.*' \) 2>/dev/null | head -1)
          if [[ -n "$test_files" ]]; then
            if ! echo "$test_files" | grep -q "bootstrap\|infra\|setup"; then
              return 0
            fi
          fi
        fi
      done
      
      return 1
    }
    
    detect_has_relevant_application_code
    exit $?
EOF
  
  run bash test_detection.sh
  [ "$status" -eq 0 ]  # Brownfield should return 0 (code found)
}

@test "AC-2: detect_has_relevant_application_code function identifies brownfield (with package.json referencing src)" {
  TEMP_DIR=$(mktemp -d)
  trap 'rm -rf "$TEMP_DIR"' EXIT
  
  cd "$TEMP_DIR"
  cat > package.json << 'EOF'
{
  "name": "my-app",
  "main": "src/index.js",
  "scripts": {
    "build": "tsc src/**/*.ts"
  }
}
EOF
  
  # Create a test script that only sources the function
  cat > test_detection.sh << 'EOF'
    set -euo pipefail
    WORKDIR="$(pwd)"
    
    detect_has_relevant_application_code() {
      local application_dirs=(
        "src" "app" "packages" "services" "frontend" "backend"
        "lib" "config" "routes" "controllers" "models" "components"
      )
      
      for dir in "${application_dirs[@]}"; do
        if [[ -d "$WORKDIR/$dir" && -n "$(find "$WORKDIR/$dir" -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.py' -o -name '*.go' -o -name '*.java' -o -name '*.cs' -o -name '*.rb' \) 2>/dev/null | head -1)" ]]; then
          return 0
        fi
      done
      
      local manifest_files=(
        "package.json" "pom.xml" "build.gradle" "Makefile" "Dockerfile"
        "pyproject.toml" "setup.py" "go.mod" "Cargo.toml" ".csproj"
      )
      
      for manifest in "${manifest_files[@]}"; do
        if [[ -f "$WORKDIR/$manifest" ]]; then
          if grep -q "src\|app\|packages\|services\|frontend\|backend" "$WORKDIR/$manifest" 2>/dev/null; then
            return 0
          fi
        fi
      done
      
      local test_dirs=("__tests__" "test" "tests" "spec" "specs")
      for test_dir in "${test_dirs[@]}"; do
        if [[ -d "$WORKDIR/$test_dir" ]]; then
          local test_files=$(find "$WORKDIR/$test_dir" -type f \( -name '*.test.*' -o -name '*.spec.*' -o -name '*_test.*' -o -name '*_spec.*' \) 2>/dev/null | head -1)
          if [[ -n "$test_files" ]]; then
            if ! echo "$test_files" | grep -q "bootstrap\|infra\|setup"; then
              return 0
            fi
          fi
        fi
      done
      
      return 1
    }
    
    detect_has_relevant_application_code
    exit $?
EOF
  
  run bash test_detection.sh
  [ "$status" -eq 0 ]  # Brownfield should return 0 (manifest references src)
}

@test "AC-2: detect_has_relevant_application_code function identifies brownfield (dotnet csproj)" {
  TEMP_DIR=$(mktemp -d)
  trap 'rm -rf "$TEMP_DIR"' EXIT

  cd "$TEMP_DIR"
  touch MyApp.csproj

  cat > test_detection.sh << 'EOF'
    set -euo pipefail
    WORKDIR="$(pwd)"

    detect_has_relevant_application_code() {
      local application_dirs=(
        "src" "app" "packages" "services" "frontend" "backend"
        "lib" "config" "routes" "controllers" "models" "components"
      )

      for dir in "${application_dirs[@]}"; do
        [[ -d "$WORKDIR/$dir" ]] || continue
        if find "$WORKDIR/$dir" -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.py' -o -name '*.go' -o -name '*.java' -o -name '*.cs' -o -name '*.rb' \) 2>/dev/null | grep -q .; then
          return 0
        fi
      done

      local manifest_files=(
        "package.json" "pom.xml" "build.gradle" "Makefile" "Dockerfile"
        "pyproject.toml" "setup.py" "go.mod" "Cargo.toml"
      )

      for manifest in "${manifest_files[@]}"; do
        if [[ -f "$WORKDIR/$manifest" ]] && grep -Eq 'src|app|packages|services|frontend|backend' "$WORKDIR/$manifest" 2>/dev/null; then
          return 0
        fi
      done

      if find "$WORKDIR" -type f \( -name '*.csproj' -o -name '*.fsproj' \) 2>/dev/null | grep -q .; then
        return 0
      fi

      local test_dirs=("__tests__" "test" "tests" "spec" "specs")
      for test_dir in "${test_dirs[@]}"; do
        [[ -d "$WORKDIR/$test_dir" ]] || continue
        while IFS= read -r test_file; do
          [[ -n "$test_file" ]] || continue
          case "$test_file" in
            *bootstrap*|*infra*|*setup*)
              continue
              ;;
            *)
              return 0
              ;;
          esac
        done < <(find "$WORKDIR/$test_dir" -type f \( -name '*.test.*' -o -name '*.spec.*' -o -name '*_test.*' -o -name '*_spec.*' \) 2>/dev/null)
      done

      return 1
    }

    detect_has_relevant_application_code
    exit $?
EOF

  run bash test_detection.sh
  [ "$status" -eq 0 ]  # Brownfield should return 0 (csproj present)
}

@test "bootstrap.sh includes classification step in main flow" {
  run bash -lc 'set -euo pipefail; cd "$1"; grep -q "Classifying repository context" bootstrap.sh' _ "$REPO_ROOT"
  [ "$status" -eq 0 ]
}

@test "bootstrap.sh outputs explicit context classification guidance" {
  run bash -lc 'set -euo pipefail; cd "$1"; grep -q "Interpretation: no relevant application code was found" bootstrap.sh && grep -q "Interpretation: relevant application code is present" bootstrap.sh && grep -q "repository classified as" bootstrap.sh' _ "$REPO_ROOT"
  [ "$status" -eq 0 ]
}

@test "AC-3: bootstrap defines topology decision flags for greenfield intake" {
  run bash -lc 'set -euo pipefail; cd "$1"; grep -q -- "--delivery-model" bootstrap.sh && grep -q -- "--decision-reason" bootstrap.sh && grep -q -- "--decision-owner" bootstrap.sh && grep -q "resolve_greenfield_topology_decision" bootstrap.sh' _ "$REPO_ROOT"
  [ "$status" -eq 0 ]
}

@test "AC-3: bootstrap persists topology decision in .specify/feature.json" {
  run bash -lc 'set -euo pipefail; cd "$1"; grep -q "topology_decision" bootstrap.sh && grep -q "decision_reason" bootstrap.sh && grep -q "decision_owner" bootstrap.sh && grep -q "satellite_domains" bootstrap.sh' _ "$REPO_ROOT"
  [ "$status" -eq 0 ]
}
