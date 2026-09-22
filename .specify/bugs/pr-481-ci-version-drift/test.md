# Bug Verification: PR #481 CI version drift

- **Slug**: `pr-481-ci-version-drift`
- **Tested**: 2026-09-22
- **Assessment**: ./assessment.md
- **Fix**: ./fix.md (commit `ec33298`)
- **Result**: verified

## Summary

O sintoma original reproduz no código anterior à correção (`origin/develop` `95e68db`)
e não reproduz com a correção `ec33298`. Detector de preset,
`validate-versions.sh`, suíte de bootstrap e paridade de agentes passam. A suíte
mandatória tem uma única falha, `happy-path.test.sh`. Ela também falha no código anterior, não tem relação com esta correção e está registrada como T038b da spec 025.

Uma segunda sessão produziu, em paralelo, uma correção equivalente, com os mesmos
arquivos de versão e o mesmo refresh do espelho. Ela foi descartada em favor
de `ec33298` para evitar PRs duplicados. As duas convergiram na versão 1.22.0 e
no mecanismo `specify preset remove` + `add --dev`.

## Checks Performed

| Check | Command / Action | Result | Notes |
|-------|------------------|--------|-------|
| Reproduction (pre-fix) | `detect-preset-version-mismatch.sh --json` em `git archive 95e68db` | fail (esperado) | `mismatch`: `.registry` e espelho em 1.21.0, esperado 1.22.0 |
| Reproduction (post-fix) | `bash .specify/scripts/bash/detect-preset-version-mismatch.sh --json` | pass | `in_sync`, 1.22.0, exit 0 |
| New test (pre-fix) | `bats tests/bootstrap/release-version-lockstep.bats` em `git archive 95e68db` | fail (esperado) | testes 3, 4 e 5 falham (catálogos/URLs, README, espelho/registry) |
| New test (post-fix) | `bats tests/bootstrap/release-version-lockstep.bats` | pass | 5/5 |
| Bootstrap Crítico | `bats tests/bootstrap/*.bats` | pass | 35/35 |
| Version gate | `./scripts/validate-versions.sh` | pass | 0 erros, 4 avisos (tag `v1.22.0` inexistente, timestamps) |
| Agent parity | `scripts/sync-nc-agents-to-integrations.sh --check --target all` | pass | vscode, claude, antigravity, cursor, kiro |
| Mirror integrity | `diff -rq presets/nimbus-code-standards .specify/presets/nimbus-code-standards` | pass | idênticos |
| Regression suite | `./scripts/run-tests.sh` | fail (pré-existente) | 49/50; `happy-path.test.sh` também falha em `95e68db` (`assert len(role_ids) == 15`, manifesto com 18) |

## Output Excerpts

```text
{"status": "in_sync", "preset": "nimbus-code-standards", "version": "1.22.0", "basis": "bundle_manifest", "mismatches": []}
ok 5 espelho ativo .specify/presets e .registry acompanham o bundle.yml
[OK] Todas as validações passaram! (4 aviso(s))
Resultado consolidado: 49/50 arquivos de teste passaram.  # falha: happy-path.test.sh (pré-existente)
```

## Residual Risks

- A verificação foi local (macOS). Os checks de CI no runner Ubuntu do PR são
  a confirmação final.
- A suíte mandatória continua vermelha por causa de T038b até que ela seja corrigida.
- Os `download_url` apontam para `v1.22.0`, que só existe depois de criar a tag e os
  artefatos de release.
- Os checks de versão não são obrigatórios na proteção de branch. Foi assim que o
  #487 entrou com drift. O teste de lockstep reduz o risco porque roda no
  Bootstrap Crítico, que é bloqueante.
- O PR toca catálogos sem tocar manifestos de versão. Por isso precisa do label
  `release:skip` no `release-readiness`, já que o bump para 1.22.0 saiu no #487.

## Recommendation

Fechar o bug. A correção está verificada de ponta a ponta localmente. Seguir com o PR
para `develop` com label `release:skip`. O merge é decisão do Dev, depois dos checks
de CI.
