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

**Validacao**: a etapa cross-repo falha fechado antes da primeira operação
ampliada e exibe instrução para configurar o App. Nenhum PAT é usado
automaticamente.

Depois da conclusao humana de T005/T006, configure os secrets do App e rode o
mesmo workflow novamente.

**Validacao esperada apos T005/T006**: o log mostra
`::notice::Autenticado via GitHub App`.

Se o piloto precisar de fallback temporário, ele deve ser habilitado
explicitamente no modo de migração, com owner, prazo, ambiente permitido e
registro de auditoria; a ausência dos secrets, isoladamente, não o habilita.

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

**Validação**: cinco participantes consultam somente
`docs/skills-distribution-guide.md` e, em até dois minutos, identificam para uma
skill sorteada sua modalidade, localização, comando de invocação e
disponibilidade. O cenário passa com pelo menos quatro respostas completas.

## Registro de validacao desta implementacao

- [x] AC-1 validado localmente com fixture + execucao nao interativa (`--repo-type`) e falha explicita sem a flag.
- [x] AC-2 validado localmente com caminho feliz e fixture divergente.
- [ ] AC-4/AC-5 pendentes de piloto com GitHub App real (bloqueado por T005/T006); fallback e permanencia do `graph-guard.yml` foram verificados por inspecao e lint.
- [x] AC-6/AC-7 validados localmente pelo teste de URLs publicas.
- [ ] AC-8 com medicao por desenvolvedor real pendente (T026); clareza do manual revisada localmente.

## Cenario 6 - Release candidate imutavel para o piloto

Após atualizar os manifests, catálogos e bundles no mesmo PR, promover o commit
para `main` e criar a tag candidata:

```sh
git tag -a v1.19.0-rc.1 -m "Nimbus Code v1.19.0-rc.1"
git push origin v1.19.0-rc.1
```

O piloto deve usar a tag, nunca `main`:

```sh
bash bootstrap.sh --ref v1.19.0-rc.1 --repo-type platform \
  --delivery-model monorepo \
  --decision-reason "validacao do perfil de plataforma" \
  --decision-owner "luiz-feitosa"

bash bootstrap.sh --ref v1.19.0-rc.1 --repo-type dev_standards \
  --delivery-model monorepo \
  --decision-reason "validacao do perfil dev standards" \
  --decision-owner "luiz-feitosa"
```

**Validação**:

- `.nimbus/bootstrap.json` deve registrar `source_ref: v1.19.0-rc.1`;
- Platform não pode conter backlog, custo, DEVSTATS, GitHub Project ou hooks
  de workload;
- Dev Standards deve conter os artefatos de ciclo completo e governança de
  agentes;
- os dois repositórios devem ser reexecutáveis com a mesma ref;
- o piloto deve registrar se o GitHub App existente foi reutilizado, quais
  permissões foram exercitadas e qualquer fallback acionado.

## Cenario 7 - Promocao da RC para release final

Promover para `v1.19.0` somente após sete dias sem falha no piloto, revisão
humana de segurança e confirmação dos gates de rollback:

```sh
git tag -a v1.19.0 -m "Nimbus Code v1.19.0"
git push origin v1.19.0
```
