# quickstart.md — Feature 013: Governança de Testes em PR

> Guia de validação — a implementar em `/speckit-tasks` + `/speckit-implement`.
> Os comandos abaixo assumem que `docs/testing-policy.md`, `scripts/run-tests.sh`
> e `.github/workflows/test-suite.yml` já foram criados pela implementação desta
> feature.

## Pré-requisitos

- Clone do repositório (local ou Codespace — ver [docs/codespaces-adoption-guide.md](/docs/codespaces-adoption-guide.md))
- `bats` instalado (`npm install -g bats` ou via feature do devcontainer, a adicionar em `scripts/setup-dev-environment.sh` durante a implementação)
- `bash`, `jq` (já cobertos por `scripts/setup-dev-environment.sh`)

## Cenário 1 — Executar localmente a mesma validação exigida em PR (AC-4)

```bash
./scripts/run-tests.sh
```

**Resultado esperado**: todos os testes hoje existentes em `tests/bootstrap/*.bats`
e `tests/{docs,scripts,workflows}/*.test.sh` rodam em sequência; saída final
resume quantos grupos passaram/falharam. Sem necessidade de credenciais, rede
externa ou estado de organização (Edge Cases do `spec.md`).

## Cenário 2 — Confirmar que o gate de PR usa exatamente o mesmo caminho (AC-3, AC-4)

```bash
grep -n "run-tests.sh" .github/workflows/test-suite.yml
```

**Resultado esperado**: uma ocorrência — o workflow invoca o script, não duplica
a lógica de descoberta em YAML.

## Cenário 3 — Simular uma falha e verificar identificação do segmento (AC-3, FR-011)

```bash
# Introduzir uma falha proposital num teste existente (ex.: tests/docs/security-baseline-tokens.test.sh)
# e rodar:
./scripts/run-tests.sh; echo "exit code: $?"
```

**Resultado esperado**: saída identifica claramente qual grupo (`docs`, no
exemplo) falhou, sem exigir inspecionar múltiplos workflows separadamente —
reverter a falha proposital após validar.

## Cenário 4 — Consultar a matriz de decisão de formato (AC-2)

```bash
grep -A 5 "Matriz de decisão" docs/testing-policy.md
```

**Resultado esperado**: tabela com pelo menos duas linhas (Bats-core,
`.test.sh`) e critério de quando usar cada uma — ver `research.md` Decisão 1
para o conteúdo de referência.

## Cenário 5 — Confirmar taxonomia de testes documentada (AC-5)

```bash
grep -A 3 "Unitário\|Integração\|End-to-end" docs/testing-policy.md
```

**Resultado esperado**: as três categorias aparecem com critério de
enquadramento explícito — ver `data-model.md`, entidade "Test Category".

## Cenário 6 — Confirmar governança de exceções (AC-6)

```bash
grep -i "exceção\|Exception Record" docs/testing-policy.md
```

**Resultado esperado**: seção explícita exigindo justificativa + aprovador
para qualquer novo formato, bypass ou remoção de suíte mandatória.

## Nota sobre rollout do gate obrigatório

A verificação de que o gate realmente **bloqueia** merge em caso de falha
(vs. apenas reportar) depende da decisão humana de marcar
`test-suite.yml` como "required status check" na proteção de branch de
`main` — isso é **intencionalmente pendente de execução humana** (ver
Estratégia de Release do `plan.md`), não avaliado neste `quickstart.md`.
