# Bug Fix: PR #481 CI version drift

- **Slug**: `pr-481-ci-version-drift`
- **Fixed**: 2026-09-22
- **Assessment**: ./assessment.md
- **Status**: applied

## Summary

Alinhados catálogos, `download_url`, README e o espelho ativo
`.specify/presets/nimbus-code-standards` à versão de release **1.22.0**
declarada em `bundles/nimbus-code-project-bundle/bundle.yml` (bump do PR #487).
O espelho foi reinstalado a partir da fonte (não apenas a string de versão), e
um teste de lockstep ancorado no `bundle.yml` impede que o drift volte.

## Changes

| File | Change | Notes |
|------|--------|-------|
| `bundles/catalog.json` | modified | `nimbus-code-project-bundle` 1.21.1 → 1.22.0 (version + download_url); `updated_at` via `validate-versions.sh --fix` |
| `presets/catalog.json` | modified | `nimbus-code-standards` 1.21.1 → 1.22.0 (version + download_url); `updated_at` |
| `README.md` | modified | diagrama bundle/preset → v1.22.0 |
| `templates/README-bundle-section.md` | modified | tabela bundle/preset → 1.22.0 |
| `.specify/presets/nimbus-code-standards/**` | refreshed | reinstalado via `specify preset remove` + `specify preset add --dev presets/nimbus-code-standards --priority 5`; `diff -rq` com a fonte agora vazio (antes faltavam skills `nc-*`, workflows e outros templates) |
| `.specify/presets/.registry` | modified | versão 1.21.0 → 1.22.0, novo `manifest_hash` |
| `tests/bootstrap/release-version-lockstep.bats` | added test | regressão: fonte, catálogos, URLs, README e espelho devem igualar o `bundle.yml` |

## Tests Added or Updated

- `tests/bootstrap/release-version-lockstep.bats` — usa o `bundle.yml` como
  autoridade. Antes da correção, os testes 3, 4 e 5 falhavam (catálogos/URLs,
  README, espelho/registry); depois, 5/5 passam. Cobre a lacuna do
  `interview-flow-parity.bats` #4, que compara README apenas com catálogos e
  por isso passava com ambos defasados em 1.21.1.

## Local Verification

- `bats tests/bootstrap/release-version-lockstep.bats` → 5/5 ok (antes: 3 falhas)
- `bash .specify/scripts/bash/detect-preset-version-mismatch.sh --json` → `in_sync` 1.22.0, exit 0 (antes: mismatch, exit 1)
- `./scripts/validate-versions.sh` → exit 0 (antes: 6 erros); resta aviso de tag git `v1.22.0` inexistente (etapa de release)
- `bats tests/bootstrap/*.bats` → 35/35 ok
- `bash scripts/validate-issue-template-parity.sh` → exit 0
- `scripts/sync-nc-agents-to-integrations.sh --check --target all` → parity OK (vscode, claude, antigravity, cursor, kiro)
- `./scripts/run-tests.sh` → 49/50; a única falha, `tests/agent-orchestration/happy-path.test.sh`, **é pré-existente** (falha igual em `origin/develop` 95e68db) e não relacionada: o teste espera 15 papéis e `.nimbus/agent-manifest.yaml` declara 18.

## Deviations from Assessment

1. **Versão alvo**: a avaliação (2026-09-21) observou 1.20.0/1.21.0/1.19.0. Após
   os PRs de 2026-09-22 (bf05ca4 → 1.21.1; #487 → 1.22.0 em `bundle.yml` e
   `preset.yml` apenas) o estado mudou. O humano confirmou **1.22.0** como
   versão oficial, resolvendo o `[NEEDS CLARIFICATION]`. O bundle de plataforma
   (0.5.0) está consistente e segue versionamento próprio.
2. **Mecanismo de refresh**: `bootstrap.sh --refresh-preset --local .` recusou
   rodar (sem alterar nada) porque arquivos da raiz do repositório central
   divergem intencionalmente dos templates `project-root` (ex.:
   `scripts/validate-versions.sh`, que segundo `docs/developer-guide.md` não
   deve ser copiado para satélites). Foi executado apenas o passo de
   reinstalação do preset que o próprio bootstrap usa
   (`specify preset remove` + `specify preset add --dev ... --priority 5`),
   restrito ao espelho e ao `.registry`.
3. **Gate de release** (item 5 da remediação): em vez de novo workflow, foi
   adicionado o teste bats de lockstep, que roda nas suítes bootstrap/mandatória
   já existentes.

## Follow-ups

- Criar a tag `v1.22.0` e publicar os artefatos de release referenciados pelas
  novas `download_url` (responsável pelo release).
- `validate-versions.yml` já falharia no PR #487, mas não bloqueou o merge:
  avaliar torná-lo check obrigatório na proteção de `develop`/`main` (decisão do responsável).
- Corrigir `tests/agent-orchestration/happy-path.test.sh` (contagem fixa de 15 papéis) em bug separado.
