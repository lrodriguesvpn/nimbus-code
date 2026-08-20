# Quickstart: Bootstrap Governance & Repo Provisioning Hardening

**Purpose**: Validação E2E de que o bootstrap endurecido, a paridade de templates
e a migração de autenticação funcionam como especificado.

## Pré-requisitos

- `gh` CLI autenticado na organização `venha-pra-nuvem`
- Acesso a um repositório de teste (piloto) no GHE
- `bash`, `jq`, `python3` disponíveis localmente

## Cenário 1 — Bootstrap pergunta o tipo de repositório (AC-1)

```sh
cd /tmp && mkdir repo-teste-bootstrap && cd repo-teste-bootstrap && git init
bash /caminho/para/nimbus-code-spec-kit-template/bootstrap.sh
```

**Validação**: o script pergunta "Plataforma/Cliente ou Dev Standards?" antes de
qualquer instalação de preset. Responder `dev_standards` e confirmar que
`nimbus-code-standards` foi instalado (não `nimbus-code-platform-standards`).

## Cenário 2 — Paridade de templates de issue (AC-2)

```sh
./scripts/validate-issue-template-parity.sh
```

**Validação**: saída `✅ Templates de issue idênticos...`. Para testar o caminho
de falha, remova temporariamente uma seção de um dos dois templates e confirme
que o script reporta a divergência com exit code ≠ 0.

## Cenário 3 — Migração de workflow para GitHub App (AC-4, AC-5)

Num repositório de teste com `NIMBUS_APP_ID`/`NIMBUS_APP_PRIVATE_KEY` **não**
configurados:

```sh
gh workflow run ensure-github-project.yml --repo <org>/<repo-teste>
```

**Validação**: log mostra `::warning::GitHub App não configurado — usando PAT de
fallback`. Configurar os secrets e rodar novamente — log deve mostrar
`::notice::Autenticado via GitHub App`.

Para um workflow de escopo restrito ao próprio repo (ex.: `graph-guard.yml`):

**Validação**: nenhuma mudança de comportamento — continua usando `GITHUB_TOKEN`
nativo, sem exigir nenhum secret adicional.

## Cenário 4 — Fonte oficial do Spec Kit e domínio GHE (AC-6, AC-7)

```sh
grep -n "specify" bootstrap.sh | grep -i "github.com"
grep -rn "github.com" docs/ presets/ .github/workflows/ 2>/dev/null | grep -v "ghe.com" | grep -v "github/spec-kit"
```

**Validação**: única ocorrência de `github.com` público deve ser a referência ao
Spec Kit CLI oficial; nenhuma outra URL `github.com` deve aparecer fora dessa
exceção documentada.

## Cenário 5 — Manual de skills locais vs. remotas (AC-8)

```sh
cat docs/skills-distribution-guide.md | grep -A2 "speckit-specify"
```

**Validação**: em até 2 minutos de leitura, um desenvolvedor consegue determinar
se `speckit-specify` (ou qualquer outra skill consultada) é local ou remota, e
qual o estado atual de disponibilidade.

## Checklist final

- [ ] AC-1 validado (Cenário 1)
- [ ] AC-2 validado (Cenário 2)
- [ ] AC-4/AC-5 validados (Cenário 3)
- [ ] AC-6/AC-7 validados (Cenário 4)
- [ ] AC-8 validado (Cenário 5)
