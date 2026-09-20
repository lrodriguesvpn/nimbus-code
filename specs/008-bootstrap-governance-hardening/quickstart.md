# Quickstart: Bootstrap Governance & Repo Provisioning Hardening

**Purpose**: validacao E2E de que o bootstrap endurecido, a paridade de templates
 e a migracao de autenticacao funcionam como especificado.

## Pre-requisitos

- `gh` CLI autenticado na organizacao `venha-pra-nuvem`
- Acesso a um repositorio de teste (piloto) no GHE
- `python3` disponivel localmente
- Git Bash (`C:\Program Files\Git\bin\bash.exe`) para rodar os scripts shell no Windows

## Cenario 1 - Bootstrap pergunta o tipo de repositorio (AC-1)

```sh
cp -R specs/008-bootstrap-governance-hardening/fixtures/bootstrap-target specs/008-bootstrap-governance-hardening/fixtures/.runtime-bootstrap-manual
cd specs/008-bootstrap-governance-hardening/fixtures/.runtime-bootstrap-manual
git init
bash ../../../../bootstrap.sh --local ../../../../ --repo-type dev_standards
```

**Validacao**: o script deve instalar `nimbus-code-standards` e imprimir a linha
`Preset instalado: nimbus-code-standards (tipo de repositorio: dev_standards)`.
Para o caminho interativo, rode sem `--repo-type` em um terminal real e confirme
que a pergunta `platform/dev_standards` aparece antes da instalacao do preset.

## Cenario 2 - Paridade de templates de issue (AC-2)

```sh
bash scripts/validate-issue-template-parity.sh
bash scripts/validate-issue-template-parity.sh \
  --template-a presets/nimbus-code-standards/templates/project-root/.github/ISSUE_TEMPLATE/nimbus-code-task.md \
  --template-b specs/008-bootstrap-governance-hardening/fixtures/invalid-nimbus-code-task.md \
  --label-a nimbus-code-standards \
  --label-b fixture-divergente
```

**Validacao**: a primeira execucao deve retornar status `0`. A segunda deve falhar e
exibir o diff de headings, cobrindo o caminho de divergencia proposital.

## Cenario 3 - Migracao de workflow para GitHub App (AC-4, AC-5)

Num repositorio de teste com `NIMBUS_APP_ID`/`NIMBUS_APP_PRIVATE_KEY` **nao**
configurados:

```sh
gh workflow run ensure-github-project.yml --repo <org>/<repo-teste>
```

**Validacao**: o log mostra `::warning::GitHub App nao configurado - usando PAT de
fallback`.

Depois da conclusao humana de T005/T006, configure os secrets do App e rode o
mesmo workflow novamente.

**Validacao esperada apos T005/T006**: o log mostra
`::notice::Autenticado via GitHub App`.

Para um workflow de escopo restrito ao proprio repo (ex.: `graph-guard.yml`):

**Validacao**: nenhuma mudanca de comportamento - continua usando `GITHUB_TOKEN`
nativo, sem exigir nenhum secret adicional.

## Cenario 4 - Fonte oficial do Spec Kit e dominio GHE (AC-6, AC-7)

```sh
grep -RIn "github.com" bootstrap.sh docs presets | grep -v "github.com/github/spec-kit"
```

**Validacao**: nenhuma ocorrencia deve ser retornada fora da excecao documentada
para a fonte oficial do Spec Kit.

## Cenario 5 - Manual de skills locais vs. remotas (AC-8)

```sh
grep -A3 "speckit-specify" docs/skills-distribution-guide.md
```

**Validacao**: em ate 2 minutos de leitura, um desenvolvedor consegue determinar
se `speckit-specify` (ou qualquer outra skill consultada) e local ou remota, e
qual o estado atual de disponibilidade.

## Registro de validacao desta implementacao

- [x] AC-1 validado localmente com fixture + execucao nao interativa (`--repo-type`) e falha explicita sem a flag.
- [x] AC-2 validado localmente com caminho feliz e fixture divergente.
- [ ] AC-4/AC-5 pendentes de piloto com GitHub App real (bloqueado por T005/T006); fallback e permanencia do `graph-guard.yml` foram verificados por inspecao e lint.
- [x] AC-6/AC-7 validados localmente pelo teste de URLs publicas.
- [ ] AC-8 com medicao por desenvolvedor real pendente (T026); clareza do manual revisada localmente.

### Limite do registro histórico — 2026-09-20

Os marcadores acima são preservados como registro da implementação, não como
aprovação de adoção. O teste existente
`tests/bootstrap/no-public-github-urls.bats` verifica ocorrências de URLs e sua
allowlist: não demonstra que a instalação efetivamente obteve o Spec Kit da
fonte oficial (AC-6), nem que a atualização/reinstalação do preset funciona.
Não foi localizado o teste dedicado `bootstrap-official-source.bats` planejado
originalmente. O [mapa de testes corrigido no plano](plan.md) distingue
essa lacuna da cobertura de AC-7 e do piloto real ainda pendente em #103/T022.
