# Política de Testes — Governança de Testes em PR

> Documentação gerada pela feature
> [`013-governanca-testes-pr`](/specs/013-governanca-testes-pr/spec.md).
> Consolida a governança de testes deste bundle: o que testar, em qual
> formato, onde colocar, e como o gate obrigatório de PR funciona.

## 1. Inventário da Suíte Atual

Levantamento real (`git ls-tree -r --name-only HEAD -- tests/`), confirmado em
2026-08-20: **10 arquivos de teste em 4 subpastas**.

| Pasta | Arquivos | Formato | Propósito |
|---|---|---|---|
| `tests/bootstrap/` | `issue-template-parity.bats`, `no-public-github-urls.bats` | Bats-core | Valida `bootstrap.sh` e convenções de templates de issue (feature 008) |
| `tests/docs/` | `security-baseline-checklist.test.sh`, `security-baseline-tokens.test.sh` | Script `.test.sh` | Valida conteúdo/estrutura de `docs/security-baseline-ghe.md` (feature 007) |
| `tests/scripts/` | `security-compliance-scan.auth.test.sh`, `security-compliance-scan.detect.test.sh`, `security-compliance-scan.issue-creation.test.sh`, `security-compliance-scan.platform-access.test.sh` | Script `.test.sh` | Valida a lógica de `scripts/security-compliance-scan.sh` (feature 007) |
| `tests/workflows/` | `security-compliance-scan.discovery.test.sh`, `security-compliance-scan.report.test.sh` | Script `.test.sh` | Valida o comportamento de descoberta/relatório do workflow de varredura de segurança (feature 007) |

**Estado atual do CI (antes desta feature): nenhum workflow executa essa suíte
de forma consolidada em toda PR.** Cada arquivo só é executado manualmente
pelo autor da feature que o introduziu — não existe um gate único que rode
os 10 arquivos e bloqueie merge em caso de falha (FR-001, FR-002, AC-1).

## 2. Taxonomia de Testes

Classificação oficial de um teste neste bundle (FR-005):

| Categoria | Critério de enquadramento |
|---|---|
| **Unitário** | Valida uma única unidade isolada (uma função bash, um bloco de schema, uma seção de documentação) sem depender de outros scripts/workflows do repositório. Ex.: `tests/docs/*.test.sh` validando seções de um documento via grep. |
| **Integração** | Valida a interação entre dois ou mais componentes do bundle (ex.: um script + o workflow que o invoca; um preset + o template que ele resolve). Ex.: `tests/scripts/security-compliance-scan.*.test.sh` exercitando funções do script com mocks de API. |
| **End-to-end (E2E)** | Valida um fluxo completo de ponta a ponta como um contribuidor/CI o experimentaria (ex.: `/speckit-plan` gerando artefatos reais; um PR completo passando pelo gate obrigatório). Mais custoso — reservado para os fluxos críticos do bundle. |

## 3. Matriz de Decisão de Formato

Formato executável principal recomendado para **novos** testes de
scripts/CLI: **Bats-core**. Os scripts `.test.sh` existentes permanecem como
formato aceito e permanente para validação simples de conteúdo (ver seção 7).
Nenhuma dependência nova (ex.: `shellspec`) é introduzida (research.md,
Decisão 1).

| Formato | Quando usar | Prós | Contras | Exemplo já existente |
|---|---|---|---|---|
| **Bats-core** (padrão principal) | Testes de scripts/CLI com múltiplas asserções, setup/teardown, ou que se beneficiam de relatório TAP granular | Já usado em produção neste repositório; saída compatível com TAP; nomes de teste legíveis via `@test "descrição"`; contagem de passou/falhou automática | Requer o binário `bats` instalado (ver seção 8) | `tests/bootstrap/*.bats` |
| **Script `.test.sh` simples** (aceito, não descontinuado) | Validação pontual de conteúdo/schema de documentação ou manifest (ex.: "este checklist contém a seção X") sem necessidade de múltiplas asserções organizadas | Zero dependência externa (`bash` puro); simples de ler e escrever | Sem framework de asserção nem descoberta automática de "quantos testes passaram/falharam" por arquivo — cada um implementa sua própria contagem ad-hoc | `tests/docs/*.test.sh`, `tests/scripts/*.test.sh`, `tests/workflows/*.test.sh` |
| **Exceção documentada** (qualquer outro formato, ex.: `shellspec`) | Requer `Exception Record` explícito nesta política (seção 6), com justificativa técnica e aprovador — nunca adoção silenciosa (FR-009) | — | — | Nenhum caso hoje |

## 4. Convenções de Localização e Nomenclatura

- **Bats-core**: arquivo `*.bats` dentro do subdiretório de `tests/` que
  corresponde ao artefato testado (ex.: um novo teste para `bootstrap.sh`
  vai em `tests/bootstrap/<nome-descritivo>.bats`).
- **Script `.test.sh`**: arquivo `<artefato-testado>.<aspecto>.test.sh` dentro
  do subdiretório correspondente ao tipo de artefato (`tests/docs/` para
  documentação, `tests/scripts/` para scripts shell, `tests/workflows/` para
  comportamento de workflow). Ex.: `security-compliance-scan.auth.test.sh`
  testa o aspecto "auth" do script `security-compliance-scan.sh`.
- Um novo subdiretório (`tests/<novo-tipo>/`) só deve ser criado quando o
  artefato testado não se enquadrar em nenhuma categoria existente
  (`bootstrap`, `docs`, `scripts`, `workflows`) — caso contrário, reutilize a
  pasta existente.

## 5. Gate Obrigatório de PR

`scripts/run-tests.sh` é o ponto de entrada único: descobre e executa todo
arquivo `tests/**/*.bats` (via `bats`) e todo arquivo `tests/**/*.test.sh`
(via `bash`), agregando um resultado consolidado (FR-007, FR-012).
`.github/workflows/test-suite.yml` invoca exatamente este mesmo script dentro
do runner do GitHub Actions em todo `pull_request` contra `main` — garantindo
paridade honesta entre CI e execução local por construção, não por manutenção
paralela (FR-008).

**Estado atual (rollout faseado)**: o workflow roda em **modo relatório**
(informativo, não bloqueante) por um período de observação definido no PR de
implementação desta feature. Após esse período sem falso-positivo relevante,
uma decisão humana explícita promove `test-suite.yml` a "required status
check" na proteção de branch de `main` (ver Estratégia de Release do
[`plan.md`](/specs/013-governanca-testes-pr/plan.md) e a task T015 do
[`tasks.md`](/specs/013-governanca-testes-pr/tasks.md)). Enquanto isso não
ocorrer, esta seção reflete o estado real (relatório), não o estado final
desejado.

Se qualquer segmento (`bootstrap`, `docs`, `scripts`, `workflows`) falhar, a
saída de `scripts/run-tests.sh` identifica explicitamente qual foi o primeiro
a falhar, sem exigir inspeção de múltiplos arquivos de log (FR-011, AC-3).

## 6. Governança de Exceções

Qualquer desvio do padrão desta política — novo formato de teste fora da
matriz da seção 3, bypass do gate obrigatório, ou remoção de um teste da
suíte mandatória — exige um **Exception Record** formal, não adoção silenciosa
(FR-009). O registro vive no Architecture Decision Log (ADL) do `plan.md` da
feature que introduz a exceção (reaproveitando o mecanismo já existente do
bundle, em vez de um arquivo próprio):

| Campo | Descrição |
|---|---|
| Motivo | Por que o padrão principal (Bats-core ou `.test.sh`) não se aplica |
| Formato alternativo aceito | Qual formato será usado em vez do padrão |
| Duração esperada | Permanente (ex.: `.test.sh` para validação simples — já coberto pela seção 3, não precisa de novo registro) ou temporária (com prazo) |
| Aprovador | Quem aprovou o desvio |

Sem um Exception Record aprovado, um novo teste que não se enquadre em Bats-core
nem em `.test.sh` simples **não deve ser mergeado**.

## 7. Tratamento de Testes Legados

Os arquivos `.test.sh` existentes (`tests/docs/`, `tests/scripts/`,
`tests/workflows/`, introduzidos pela feature 007) são classificados como
formato **aceito e permanente** — não são um legado a migrar (research.md,
Decisão 4). Nenhum teste existente é removido ou migrado por esta feature.
Uma migração obrigatória para Bats poderia ser reavaliada no futuro como um
Exception Record, se a matriz de decisão da seção 3 se mostrar insuficiente
na prática (ex.: um `.test.sh` crescer a ponto de precisar de múltiplas
asserções organizadas) — mas isso não é o estado atual da política.

## 8. Executando a Suíte Localmente

Este é o mesmo caminho usado por `.github/workflows/test-suite.yml` — paridade
por construção, não por manutenção paralela (AC-4, FR-008).

**Pré-requisitos**:
- `bash` 4+, `git`, `python3` e `jq`
- PyYAML no mesmo `python3` utilizado pelos scripts para composição de presets
  reais; fixtures de composição usam manifests JSON isolados, sem dependência
  de acesso externo
- `bats` — instalado automaticamente por `scripts/setup-dev-environment.sh`
  (Codespaces/devcontainer) ou manualmente via `npm install -g bats-core`

**Comando único**:

```bash
./scripts/run-tests.sh
```

**Resultado esperado**: todos os arquivos `.bats` e `.test.sh` nos grupos
diretos de `tests/`, mais os `.bats` em `.specify/scripts/bash/tests/`, rodam
em sequência. A saída resume arquivos aprovados/falhos e identifica o primeiro
segmento com falha. A contagem é descoberta, não um número fixo documentado.
Os testes internos usam o checkout corrente, nunca um snapshot fixo em `/tmp`.

### ⚠️ Atenção — macOS: use bash 4+ (não o `/bin/bash` padrão do sistema)

Durante a implementação desta feature, confirmamos que
`scripts/security-compliance-scan.sh` usa arrays associativos (`declare -A`),
um recurso **não suportado** pelo `/bin/bash` que vem pré-instalado no macOS
(versão 3.2, por razões de licenciamento — a Apple nunca atualizou para
bash 4+/GPLv3). Rodar `./scripts/run-tests.sh` com esse bash antigo falha com
erros do tipo `unbound variable` que **não são falhas reais do script**, apenas
incompatibilidade de versão do interpretador local. O runner de CI
(`ubuntu-latest` no GitHub Actions) já usa bash 5+ por padrão, então este
problema **não afeta o gate de PR** — apenas a execução local em macOS.

Se você estiver em macOS e vir falhas de `unbound variable` ao rodar os testes
de `tests/scripts/security-compliance-scan.*.test.sh` ou
`tests/workflows/security-compliance-scan.*.test.sh`, instale um bash mais novo
antes de reportar uma falha real:

```bash
brew install bash
# /opt/homebrew/bin/bash (Apple Silicon) ou /usr/local/bin/bash (Intel) — bash 5+
PATH="/opt/homebrew/bin:$PATH" /opt/homebrew/bin/bash scripts/run-tests.sh
```

O `PATH` também seleciona o Bash novo para os subprocessos dos testes; no Intel,
substitua `/opt/homebrew/bin` por `/usr/local/bin`.

`scripts/run-tests.sh` detecta essa situação e emite um aviso explícito (ver
seção "Requisitos de bash" do próprio script) em vez de deixar o contribuidor
interpretar um erro genérico de shell como falha do teste.
