#!/usr/bin/env bats
# Regressão: .specify/bugs/pr-481-ci-version-drift
# O bundle.yml é a autoridade de versão do release. Catálogos, download_url,
# README e o espelho ativo em .specify/presets devem acompanhá-lo em lockstep.

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  BUNDLE_YML="$REPO_ROOT/bundles/nimbus-code-project-bundle/bundle.yml"
  BUNDLE_VERSION="$(awk '/^bundle:/{b=1} b && /^[[:space:]]+version:/{gsub(/"/,"",$2); print $2; exit}' "$BUNDLE_YML")"
  PRESET_VERSION="$(awk '/id: "nimbus-code-standards"/{p=1} p && /version:/{gsub(/"/,"",$2); print $2; exit}' "$BUNDLE_YML")"
}

preset_yml_version() {
  awk '/^preset:/{p=1} p && /^[[:space:]]+version:/{gsub(/"/,"",$2); print $2; exit}' "$1"
}

@test "bundle.yml declara versões de bundle e preset" {
  [ -n "$BUNDLE_VERSION" ]
  [ -n "$PRESET_VERSION" ]
}

@test "preset fonte acompanha o bundle.yml" {
  [ "$(preset_yml_version "$REPO_ROOT/presets/nimbus-code-standards/preset.yml")" = "$PRESET_VERSION" ]
}

@test "catálogos e download_url acompanham o bundle.yml" {
  cd "$REPO_ROOT"
  [ "$(jq -r '.bundles["nimbus-code-project-bundle"].version' bundles/catalog.json)" = "$BUNDLE_VERSION" ]
  [ "$(jq -r '.presets["nimbus-code-standards"].version' presets/catalog.json)" = "$PRESET_VERSION" ]
  jq -r '.bundles["nimbus-code-project-bundle"].download_url' bundles/catalog.json | grep -Fq "/v${BUNDLE_VERSION}/"
  jq -r '.presets["nimbus-code-standards"].download_url' presets/catalog.json | grep -Fq "/v${PRESET_VERSION}/"
}

@test "README e seção de bundle acompanham o bundle.yml" {
  cd "$REPO_ROOT"
  grep -Fq "bundle: nimbus-code-project-bundle (v${BUNDLE_VERSION})" README.md
  grep -Fq "preset: nimbus-code-standards (v${PRESET_VERSION})" README.md
  grep -Fq "| \`${BUNDLE_VERSION}\` |" templates/README-bundle-section.md
  grep -Fq "| — preset \`nimbus-code-standards\` | \`${PRESET_VERSION}\` |" templates/README-bundle-section.md
}

@test "espelho ativo .specify/presets e .registry acompanham o bundle.yml" {
  cd "$REPO_ROOT"
  [ "$(preset_yml_version .specify/presets/nimbus-code-standards/preset.yml)" = "$PRESET_VERSION" ]
  [ "$(jq -r '.presets["nimbus-code-standards"].version' .specify/presets/.registry)" = "$PRESET_VERSION" ]
}
