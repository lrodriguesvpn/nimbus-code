# Quickstart: Template Composition Fix

## 1. Run the focused Bats suite

```bash
cd /tmp/nimbus-023-remote
bats .specify/scripts/bash/tests/resolve-template-composition.bats
bats .specify/scripts/bash/tests/template-materialization-regression.bats
```

## 2. Compare against the manual merge regressions

Use the merged suffixes already preserved in the reference specs:

```bash
diff -u \
  <(awk '/^## Nimbus-Code — Classificação de Complexidade/{flag=1} flag' specs/021-dora-metrics-governance/plan.md) \
  <(awk '/^## Nimbus-Code — Classificação de Complexidade/{flag=1} flag' specs/023-template-resolution-merge-fix/plan.md)

diff -u \
  <(awk '/^## Nimbus-Code — Contrato de Task Executável no GHE/{flag=1} flag' specs/022-nimbuscode-harvest-gateway/tasks.md) \
  <(awk '/^## Nimbus-Code — Contrato de Task Executável no GHE/{flag=1} flag' specs/023-template-resolution-merge-fix/tasks.md)
```

## 3. Smoke-test the real scripts in a repo with the preset installed

```bash
cd /tmp/nimbus-023-remote
.specify/scripts/bash/setup-plan.sh --json
.specify/scripts/bash/setup-tasks.sh --json
.specify/scripts/bash/create-new-feature.sh --json --dry-run "Template composition smoke"
```

> If `python3 -c 'import yaml'` fails on your machine, run these commands
> inside a temporary venv that has PyYAML installed. The shell scripts use
> that parser to read preset manifests.

## Expected result

- `spec.md`, `plan.md`, and `tasks.md` are generated from composed templates.
- `setup-tasks.sh` returns `TASKS_TEMPLATE` as an absolute file path.
- The composed output already includes the Nimbus-Code appendix sections, with no manual merge.
