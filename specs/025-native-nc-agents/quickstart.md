# Quickstart — Native NC Agents

## Prerequisites

- Bash, Python 3, Ruby with YAML support, and Bats installed.
- Run from the repository root.
- Do not edit generated destinations manually.

## Generate the supported surfaces

```bash
bash scripts/sync-nc-agents-to-integrations.sh --target all
```

Expected result: existing Claude and Antigravity skill artifacts remain
functional, native VS Code/Claude artifacts are generated after implementation,
and the source `.github/skills/nc-*` files are unchanged.

## Validate syntax and parity

```bash
bash -n scripts/sync-nc-agents-to-integrations.sh
bats tests/multi-agent-integration/nc-agents-parity.bats
```

Expected result: all existing and new AC tests pass. A modified source without
regeneration must fail the parity test and identify the stale destination.

## Validate governance

```bash
ruby -e 'require "yaml"; ARGV.each { |f| YAML.load_file(f); puts "OK #{f}" }' \
  .nimbus/agent-manifest.yaml \
  specs/025-native-nc-agents/graph.yaml
```

Expected result: both YAML files parse successfully and every NC role selected
by the generator has a source skill.

## Rollback validation

1. Revert only the generated native adapter files and generator change.
2. Re-run the existing skill parity suite.
3. Confirm `.github/skills/nc-*` and `/nc-*` bridge behavior are unchanged.

