## Resumo

Amplia a SPEC 007 para exigir e auditar proteção de branches (Rulesets preferencialmente), checks obrigatórios em Pull Requests (build, testes, cobertura, CodeQL/SAST, Dependency Review/SCA e verificação de secrets) e estende a varredura semanal de conformidade para **18 controles de repositório** — sempre em modo **detectar e reportar**, sem auto-remediação, com o GitHub App de auditoria **somente leitura** e **sem** habilitar o rollout org-wide (gate S4 preservado).

Relacionado: #450

## Motivação

O baseline atual verificava apenas proteção da branch padrão, revisão, permissões de Actions e existência de Actions secrets. Isso não impedia merge de código sem testes, sem SAST/SCA ou com secret exposto, não cobria `release/*`/`hotfix/*`, não diferenciava Rulesets de proteção clássica e tratava `secrets-configured` como se fosse controle de exposição de secrets.

## Controles adicionados

**Checks obrigatórios de PR** (nomes de job estáveis para required status checks):

| Check | Workflow | Bloqueia quando |
|---|---|---|
| `governance-config` | `pr-quality-gates.yml` | config inválida, exceção vencida, Action sem SHA/`@latest`, check N/A listado como obrigatório |
| `build` | `pr-quality-gates.yml` | comando de build declarado falha (neste repo: bash -n, shellcheck, JSON/YAML, actionlint) |
| `unit-tests` | `pr-quality-gates.yml` | teste falha (neste repo: `scripts/run-tests.sh`) |
| `integration-tests` | `pr-quality-gates.yml` | idem, quando existir (neste repo: N/A declarado, **não** obrigatório) |
| `coverage` | `pr-quality-gates.yml` + `scripts/coverage-gate.py` | < 80% global/diff, redução sem exceção, relatório não publicado (neste repo: N/A justificado — nenhuma métrica inventada) |
| `CodeQL` / `codeql-analyze (<lang>)` | `codeql.yml` | alerta novo com security severity ≥ High (threshold do Code Scanning / regra do Ruleset) |
| `dependency-review` | `dependency-review.yml` | vulnerabilidade ≥ high, dependência proibida, licença fora da política **ou recurso indisponível** (não mascara mais como sucesso) |
| `secret-scan` | `secret-scan.yml` | secret introduzido nos commits do PR (gitleaks CLI pinado com SHA-256, relatório redigido) |

**Varredura semanal** (`scripts/security-compliance-scan.sh`): `branch-protection-default`, `branch-protection-required-patterns`, `rulesets-configured`, `required-review`, `required-pr-checks`, `required-test-checks`, `required-coverage-check`, `codeql-enabled`, `codeql-recent`, `codeql-alerts`, `dependabot-alerts-enabled`, `dependabot-security-updates-enabled`, `dependency-review-enabled`, `secret-scanning-enabled`, `secret-scanning-push-protection-enabled`, `secret-alerts`, `actions-permissions`, `secrets-configured` (+ `platform-project-access`).

- Branches/padrões/checks esperados vêm de `.github/security-governance.json` **de cada repositório** (fallback: o deste template) — nada assume branches iguais.
- Avaliação multi-branch: descobre a branch padrão, lista branches e Rulesets (`includes_parents=true`), combina `rules/branches/{b}` + proteção clássica, reporta a fonte (`ruleset` / `classic (compatibilidade)`).
- Evidência padronizada: `repository | branch/padrão | endpoint -> HTTP | resultado`.
- API indisponível no plano/instância → `pendente`; 403 por permissão → erro explícito (`repos_com_erro`); rate limit → retry com backoff. **Nunca `ok`.**
- Preservado: status `ok/pendente/risco`, issues idempotentes, fechamento automático em `ok`, relatório mensal (agora com todos os controles; sem dados = `N/A (não avaliado)`), dry-run.
- Migração do id legado `branch-protection` → `branch-protection-default` (issue antiga é reaproveitada/fechada).
- Valores de secrets nunca lidos: Actions secrets só metadados; alertas de secret scanning com `hide_secret=true` + projeção.

**Outros**: `.github/dependabot.yml` (version updates `github-actions` e `npm`), `.github/dependency-review-config.yml` (high, runtime+development, licenças já vigentes, espaço para `deny-packages`), `.github/security-exceptions.json` (Exception Records com owner/aprovador/expiração ≤ 90 dias), `.gitleaks.toml`.

## Impacto no GitHub App

- Continua **100% read-only**. Permissões adicionais (todas read): **Code scanning alerts**, **Dependabot alerts**, **Secret scanning alerts** e **Organization Projects** (esta última já era usada pelo GraphQL do Project V2, mas não estava documentada). Documentado no adendo do ADR-0008 (status permanece "Em revisão").
- **Mudança de comportamento**: issues de não conformidade e o relatório mensal passam a ser escritos **somente no repositório que hospeda a varredura**, com o `GITHUB_TOKEN` do job (`issues: write`, via `SECURITY_SCAN_ISSUES_TOKEN`). Antes o script criava issues em cada repositório com o token do App, o que exigiria `Issues: write` não documentado. O modo por repositório (`SECURITY_SCAN_ISSUE_TARGET=scanned-repository`) existe, mas depende de credencial writer aprovada em novo ADR.

## Pré-requisitos administrativos (humanos)

1. GitHub App criado/instalado (T004) + secrets reais (T005) + permissões read-only adicionais (T063).
2. Dependency graph, Dependabot alerts/security updates, GitHub Code Security e Secret Protection nos repositórios piloto; *Check runs failure threshold* = High or higher (T064).
3. Rulesets (branch padrão, `release/*`, `hotfix/*`) e required checks conforme `docs/security-baseline-ghe.md` §9–§10; liberar em *Allowed actions*: `actions/checkout`, `actions/upload-artifact`, `actions/dependency-review-action`, `github/codeql-action` (T065).
4. Saída HTTPS dos runners para as releases oficiais do gitleaks e do actionlint (download com checksum).

## Arquivos alterados

<!-- lista completa no commit -->
Novos: `.github/security-governance.json`, `.github/security-exceptions.json`, `.github/dependency-review-config.yml`, `.github/dependabot.yml`, `.github/workflows/pr-quality-gates.yml`, `.github/workflows/codeql.yml`, `.github/workflows/secret-scan.yml`, `.gitleaks.toml`, `scripts/coverage-gate.py`, `scripts/run-quality-gate.sh`, `scripts/validate-repo-static.sh`, `scripts/validate-security-governance.sh`, `tests/docs/security-governance-policies.test.sh`, `tests/scripts/coverage-gate.test.sh`, `tests/scripts/run-quality-gate.test.sh`, `tests/scripts/security-compliance-scan.governance-controls.test.sh`, `tests/scripts/security-compliance-scan.issue-lifecycle.test.sh`, `tests/scripts/validate-security-governance.test.sh`, `tests/scripts/fixtures/security-scan-gh-mock.sh`, `tests/workflows/security-governance-workflows.test.sh`.

Alterados: `.github/workflows/dependency-review.yml`, `.github/workflows/security-compliance-scan.yml` (pin por SHA, `issues: write` só para o `GITHUB_TOKEN`, env de config — **escopo/flag inalterados**), `scripts/security-compliance-scan.sh`, `docs/security-baseline-ghe.md` (§1, §4, §5, §6, §8 + novas §9–§18), `docs/adr/0008-...md` (adendo), `docs/security-operations-manual.md`, `docs/testing-policy.md` (nota), `specs/007-.../{spec,plan,tasks,quickstart,data-model,impact-map,graph}.md`, `specs/007-.../graph.yaml`, `specs/007-.../contracts/*`, testes existentes de `tests/scripts` e `tests/workflows` atualizados para os novos ids/fixtures.

## Testes executados

Ambiente: sandbox Linux (bash 5, jq, python3), **sem acesso à API do GHE e sem secrets** — todos os testes da varredura usam o mock `tests/scripts/fixtures/security-scan-gh-mock.sh`.

```
bash tests/docs/security-baseline-checklist.test.sh                          PASS 16/16
bash tests/docs/security-baseline-tokens.test.sh                             PASS 7/7
bash tests/docs/security-governance-policies.test.sh                         PASS 63/63
bash tests/docs/testing-policy.test.sh                                       PASS 17/17
bash tests/scripts/coverage-gate.test.sh                                     PASS 17/17
bash tests/scripts/run-quality-gate.test.sh                                  PASS 7/7
bash tests/scripts/security-compliance-scan.auth.test.sh                     PASS 4/4
bash tests/scripts/security-compliance-scan.detect.test.sh                   PASS 20/20
bash tests/scripts/security-compliance-scan.governance-controls.test.sh      PASS 77/77
bash tests/scripts/security-compliance-scan.issue-creation.test.sh           PASS 8/8
bash tests/scripts/security-compliance-scan.issue-lifecycle.test.sh          PASS 23/23
bash tests/scripts/security-compliance-scan.platform-access.test.sh          PASS 6/6
bash tests/scripts/validate-security-governance.test.sh                      PASS 17/17
bash tests/workflows/security-compliance-scan.discovery.test.sh              PASS 15/15
bash tests/workflows/security-compliance-scan.report.test.sh                 PASS 14/14
bash tests/workflows/security-governance-workflows.test.sh                   PASS 61/61
bats tests/platform/read-only-guardrails.bats (bats 1.13.0)                  PASS 2/2
bash scripts/validate-security-governance.sh                                 PASS (50 avisos não bloqueantes em workflows legados)
bash scripts/validate-repo-static.sh (shellcheck 0.11.0, PyYAML 6, actionlint 1.7.7) PASS
shellcheck -S warning (scripts e testes novos/alterados)                    0 avisos novos (2 pré-existentes: RED/YELLOW não usados)
actionlint 1.7.7 (com shellcheck) nos 5 workflows novos/alterados            0 erros; todos os workflows sem shellcheck: 0 erros
yamllint -d relaxed nos YAML novos/alterados                                 0 erros (apenas avisos de line-length)
python3 -m pyflakes scripts/coverage-gate.py                                 0 avisos
gitleaks 8.30.1 dir . + git (commit das mudanças) com .gitleaks.toml         no leaks found
```

**Não executados aqui** (dependem de arquivos que não estavam na cópia de trabalho: `presets/`, `templates/`, `bootstrap.sh`): `tests/bootstrap/*.bats`, `tests/workflows/add-to-repo-project.auth-fallback.test.sh`, `tests/workflows/normalize-issue-bodies.host.test.sh`, `tests/workflows/satellite-preset-governance.test.sh` e o `scripts/run-tests.sh` completo. As falhas desses três `.test.sh` na cópia parcial são idênticas no baseline (arquivos ausentes), não relacionadas a este PR — **precisam rodar no CI**.

## Limitações do GitHub Enterprise / plano

- CodeQL, Dependency Review, Secret Scanning e Push Protection em repositórios privados/internos exigem GitHub Code Security / Secret Protection. Sem isso: `codeql.yml` falha no upload, `dependency-review` falha (por design) e a varredura reporta `pendente` — nunca `ok`.
- Organization Rulesets e merge queue exigem GitHub Enterprise Cloud; disponibilidade no GHE.com (data residency) deve ser confirmada no piloto.
- A suficiência de cada permissão read-only do App para cada endpoint será confirmada no piloto (T063).
- O bloqueio high/critical do CodeQL depende de configuração administrativa (threshold / regra do Ruleset), não de YAML.

## Itens dependentes de ação humana

T004, T005 (App + secrets), T037/T038 (ADR aceito + aprovação S4 — **não marcados**), T062 (revisão deste PR), T063 (permissões read-only adicionais), T064 (GHAS/Dependabot/Secret Scanning), T065 (Rulesets + required checks + allowed actions), T066 (execução do piloto), T067 (decisão sobre `test-suite.yml`), T068 (pin/permissions de workflows legados). O flag `security.baseline_scan.org_wide_enabled` **não** foi alterado.

## Evidência de workflow

Nenhum workflow foi executado no GHE a partir desta sessão: a execução real depende de infraestrutura humana (GitHub App, secrets `SECURITY_SCAN_APP_*`, GHAS habilitado, Rulesets). Os checks de PR (`governance-config`, `build`, `unit-tests`, `secret-scan`, `CodeQL`, `dependency-review`) rodarão neste próprio PR — o resultado deles é a primeira evidência real. `dependency-review`/`CodeQL` devem falhar se Dependency graph/GHAS não estiverem habilitados neste repositório (comportamento esperado e documentado).

🤖 Generated with [Claude Code](https://claude.com/claude-code)

https://claude.ai/code/session_01EauiDqCNsQJEcG8xwUP3uP
