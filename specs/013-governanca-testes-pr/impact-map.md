# impact-map.md — Feature 013: Governança de Testes em PR

> Obrigatório para S3/S4. Atualizar se a implementação divergir do plano.

---

## 1. Módulos Impactados

| Módulo | Tipo de impacto | Risco | Mitigação |
|---|---|---|---|
| `docs/testing-policy.md` | Novo arquivo | Baixo — documento aditivo, não altera comportamento até ser referenciado | Revisão humana antes de aprovar a matriz de decisão de formato |
| `scripts/run-tests.sh` | Novo script | Médio — se a descoberta de testes tiver bug, pode reportar falso-positivo/negativo para toda a suíte | Testado contra a suíte real existente (`bash -n`, execução real dos 8 arquivos de teste já existentes) antes de virar gate obrigatório |
| `.github/workflows/test-suite.yml` | Novo workflow | **Alto** — se marcado como "required status check" prematuramente, pode bloquear PRs legítimas por falso-positivo, teste legado instável ou tempo de execução | Rollout faseado obrigatório: modo relatório (não bloqueante) por período de observação → só então "required", com decisão humana explícita (ver `plan.md`, Estratégia de Release) |
| `scripts/setup-dev-environment.sh` | Possível edição (adicionar instalação de `bats` se ainda não coberta) | Baixo — aditivo | Verificar se `bats` já está incluído antes de duplicar instalação |
| `docs/reuse-catalog.yaml` | Nova entrada (se aplicável) | Baixo — apenas acrescenta | — |

---

## 2. Análise de Risco

### R001 — Gate obrigatório bloqueia PRs legítimas por falso-positivo (Alto)

**Cenário**: `test-suite.yml` é marcado como "required" antes de a suíte estar
estável, e um teste flaky ou dependente de estado externo passa a bloquear
merges legítimos repetidamente.

**Probabilidade**: Média-Alta se o rollout pular a fase de observação —
os testes atuais (`tests/scripts/security-compliance-scan.*.test.sh`) já lidam
com simulação de acesso a plataforma/autenticação, área historicamente
propensa a comportamento não-determinístico.

**Impacto**: Alto — bloquear todo o fluxo de PR do bundle é o pior cenário
possível para esta feature, que existe justamente para reduzir fricção, não
aumentá-la.

**Mitigação**: Rollout faseado obrigatório (ver `plan.md`, Estratégia de
Release) — `test-suite.yml` roda em modo relatório por um período de
observação definido no PR de implementação antes de qualquer decisão humana
de marcá-lo "required". Kill switch: remover da lista de required checks é
instantâneo, sem precisar reverter código (ver Plano de Toggle e Rollout do
`plan.md`).

**Plano de rollback**: Remover `test-suite.yml` da lista de "required status
checks" na proteção de branch de `main` (config de repositório, não código) —
reversão em segundos, sem `git revert`.

---

### R002 — Matriz de decisão de formato gera debate sem convergência (Baixo-Médio)

**Cenário**: A recomendação de Bats-core como padrão principal (ver
`research.md`, Decisão 1) não é aceita pelo mantenedor humano na revisão,
gerando retrabalho de reescrita da política.

**Probabilidade**: Baixa — Bats-core já está em produção neste repositório
(feature 008), a recomendação não introduz ferramenta nova.

**Impacto**: Baixo — é um documento, não código; ajustar a recomendação é
edição de texto, sem efeito colateral em nenhum sistema.

**Mitigação**: `research.md` já documenta as alternativas consideradas e o
porquê de cada rejeição, permitindo revisão rápida e objetiva pelo humano.

**Plano de rollback**: Editar `docs/testing-policy.md` — sem impacto em
nenhum outro módulo enquanto o gate ainda estiver em modo relatório.

---

### R003 — `run-tests.sh` diverge do comportamento real do CI (paridade quebrada) (Médio)

**Cenário**: `run-tests.sh` funciona localmente mas o ambiente do runner
GitHub Actions (`ubuntu-latest`) tem uma versão diferente de `bats`/`bash`,
quebrando a premissa de paridade (AC-4).

**Probabilidade**: Baixa-Média — mitigada pelo fato de `test-suite.yml` invocar
literalmente o mesmo `run-tests.sh` (não uma reimplementação em YAML), então
divergência só ocorreria por diferença de versão de ferramenta no ambiente,
não por lógica duplicada.

**Impacto**: Médio — quebraria a promessa central da User Story 3
(execução local == execução em PR), gerando confusão para contribuidores.

**Mitigação**: Pinar versão de `bats` instalada via
`scripts/setup-dev-environment.sh` (mesmo padrão já usado para outras
dependências do devcontainer) e documentar a versão esperada em
`docs/testing-policy.md`.

**Plano de rollback**: Corrigir a versão pinada — sem efeito colateral em
dados, apenas em reprodutibilidade do ambiente.

---

## 3. Plano de Rollback Geral

| Artefato | Reversão |
|---|---|
| `docs/testing-policy.md` | `git revert` do PR — documento aditivo, sem dependência de código |
| `scripts/run-tests.sh` | Deletar o script — não é chamado por nenhum outro módulo além do próprio `test-suite.yml` |
| `.github/workflows/test-suite.yml` | Duas camadas de rollback: (1) instantânea — remover da lista de "required status checks" via configuração de branch protection, sem tocar código; (2) `git revert` do PR se o workflow em si precisar ser removido |
| `scripts/setup-dev-environment.sh` (se editado) | `git revert` da linha adicionada |
| `docs/reuse-catalog.yaml` (se editado) | Remover a entrada adicionada — sem impacto em outras entradas |

---

## 4. Critérios de Go / No-Go

| Critério | Go | No-Go |
|---|---|---|
| `run-tests.sh` executa com sucesso toda a suíte hoje existente (8 arquivos, 4 pastas) sem falso-positivo | Confirmado por execução real antes do merge | Qualquer falso-positivo/negativo não explicado |
| `test-suite.yml` roda em modo relatório (não bloqueante) no PR de implementação | Confirmado — check aparece como não-obrigatório | Marcado como "required" sem período de observação prévio |
| Matriz de decisão de formato revisada e aprovada por humano | Aprovação explícita registrada no PR | Divergência não resolvida entre agente e mantenedor |
| FR-011 (identificar segmento que falhou na 1ª leitura) demonstrado | Saída de uma falha simulada aponta o grupo correto | Saída genérica sem indicar o segmento |
| PR sem secrets detectados | `secret scanning` não retorna findings | Qualquer finding de secret |
