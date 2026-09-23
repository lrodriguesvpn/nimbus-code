# open-pr.ps1 — commit, push e abertura do PR da issue #450.
# Rodar no PowerShell a partir de QUALQUER diretório:
#   powershell -ExecutionPolicy Bypass -File "C:\Users\fabio.noth\nimbus-code-spec-kit-template\_claude-issue-450\open-pr.ps1"
#
# Por que existe a pasta _claude-issue-450: as ferramentas remotas do Claude não
# podem gravar em .github/ nem em .git/. Os arquivos de .github/ desta entrega
# foram entregues em _claude-issue-450/github/; este script os copia para
# .github/, move os metadados (mensagem de commit/corpo do PR) para uma pasta
# temporária e REMOVE _claude-issue-450 antes do commit (nada dela é versionado).
# Pré-requisitos: git e gh CLI autenticados em venha-pra-nuvem.ghe.com
#   (gh auth login --hostname venha-pra-nuvem.ghe.com).
# O script NÃO faz merge e NÃO altera o flag de rollout org-wide.

$ErrorActionPreference = "Stop"
function Assert-Ok($what) { if ($LASTEXITCODE -ne 0) { throw "$what falhou (exit $LASTEXITCODE)" } }
$repo = "C:\Users\fabio.noth\nimbus-code-spec-kit-template"
$staging = Join-Path $repo "_claude-issue-450"
$meta = Join-Path $env:TEMP "claude-issue-450"
Set-Location $repo
if (-not (Test-Path $staging)) { throw "Pasta $staging não encontrada." }

$branch = git rev-parse --abbrev-ref HEAD
if ($branch -ne "feat/security-governance-hardening") {
  git switch feat/security-governance-hardening; Assert-Ok "git switch"
}

# 1) Instala os arquivos de .github/ entregues na pasta de staging.
New-Item -ItemType Directory -Force -Path $meta | Out-Null
Copy-Item -Force (Join-Path $staging "pr-body.md"), (Join-Path $staging "commit-message.txt") $meta
Copy-Item -Recurse -Force (Join-Path $staging "github\*") (Join-Path $repo ".github")
# 2) Remove a pasta de staging (não deve ser commitada).
Remove-Item -Recurse -Force $staging

git status --short

# Adiciona somente os caminhos alterados por esta entrega.
git add -- .github scripts tests docs specs .gitleaks.toml; Assert-Ok "git add"

# Scripts novos executáveis (core.filemode=false no Windows não registra o bit).
git update-index --chmod=+x scripts/coverage-gate.py scripts/run-quality-gate.sh `
  scripts/validate-repo-static.sh scripts/validate-security-governance.sh `
  tests/scripts/coverage-gate.test.sh tests/scripts/run-quality-gate.test.sh `
  tests/scripts/security-compliance-scan.governance-controls.test.sh `
  tests/scripts/security-compliance-scan.issue-lifecycle.test.sh `
  tests/scripts/validate-security-governance.test.sh `
  tests/docs/security-governance-policies.test.sh `
  tests/workflows/security-governance-workflows.test.sh
Assert-Ok "git update-index"

git diff --cached --stat
git commit -F (Join-Path $meta "commit-message.txt"); Assert-Ok "git commit"
$sha = git rev-parse HEAD
Write-Host "Commit: $sha"

git push -u origin feat/security-governance-hardening; Assert-Ok "git push"

$env:GH_HOST = "venha-pra-nuvem.ghe.com"
$reviewers = @()
$ErrorActionPreference = "Continue"
foreach ($r in @("moises", "eduardo-pereira")) {
  gh api "users/$r" --silent *> $null
  if ($LASTEXITCODE -eq 0) { $reviewers += $r } else { Write-Warning "Usuário $r não encontrado — revisão não solicitada." }
}
$ErrorActionPreference = "Stop"
$ghArgs = @("pr", "create", "--repo", "venha-pra-nuvem/nimbus-code-spec-kit-template",
  "--base", "main", "--head", "feat/security-governance-hardening",
  "--title", "feat: harden GitHub security governance and PR controls",
  "--body-file", (Join-Path $meta "pr-body.md"))
if ($reviewers.Count -gt 0) { $ghArgs += @("--reviewer", ($reviewers -join ",")) }
& gh @ghArgs; Assert-Ok "gh pr create"
Write-Host "Commit SHA: $sha"
