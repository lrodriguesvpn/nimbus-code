# research.md — Feature 013: Governança de Testes em PR

## Decisão 1 — Formato executável principal para novos testes

**Decision**: Adotar **Bats-core** como formato executável principal recomendado
para novos testes de scripts/CLI deste bundle, mantendo os scripts `.test.sh`
existentes como formato aceito para testes simples de validação de conteúdo
(grep/parse de documentação, schema), com critério objetivo de quando usar cada
um (ver matriz abaixo). Não introduzir `shellspec` nem nenhuma dependência nova.

**Rationale**:
- Bats-core já é usado em produção neste repositório (`tests/bootstrap/issue-template-parity.bats`,
  `tests/bootstrap/no-public-github-urls.bats`, introduzidos pela feature 008) —
  adotar como padrão principal não introduz ferramenta nova, apenas amplia o uso
  de algo já validado.
- Bats produz saída compatível com TAP (Test Anything Protocol), com nomes de
  teste legíveis por `@test "descrição"` — atende diretamente ao FR-011
  (identificar o segmento que falhou na primeira leitura) sem trabalho adicional.
- Os `.test.sh` existentes (`tests/docs/*.test.sh`, `tests/scripts/*.test.sh`,
  `tests/workflows/*.test.sh`, introduzidos pela feature 007) são scripts bash
  simples com `set -e` e mensagens de saída ad-hoc — funcionam bem para
  verificações pontuais de conteúdo/schema, mas não têm framework de asserção
  nem descoberta automática de "quantos testes passaram/falharam", tornando-os
  menos adequados como padrão principal para crescimento futuro da suíte.
- Migração imediata e obrigatória dos `.test.sh` existentes para Bats teria custo
  de conversão sem benefício proporcional agora — a política adota **convivência
  com critério explícito**, não substituição forçada (ver Decisão 4).

**Alternatives considered**:
- **Manter `.test.sh` como padrão único, descartar Bats**: rejeitado — perderia a
  granularidade de "N testes passaram / M falharam" já disponível em Bats, e
  exigiria reescrever os dois arquivos `.bats` existentes sem ganho real.
  Também os `.test.sh` atuais não têm um "test runner" próprio — cada arquivo é
  invocado individualmente, sem agregação de resultado.
- **`shellspec`** (framework BDD para shell, sintaxe `Describe`/`It`): avaliado
  como terceira alternativa plausível (mais expressivo que Bats para specs
  aninhadas), mas introduziria uma dependência nova não usada em nenhum lugar do
  bundle hoje, com curva de aprendizado adicional para contribuidores — sem
  ganho suficiente sobre Bats (que já é conhecido/usado) para justificar o custo
  de adoção de uma terceira ferramenta.
- **Reescrever tudo em uma linguagem com framework de teste "real" (Python +
  pytest, por exemplo)**: rejeitado — mudaria a stack técnica do bundle (hoje
  100% Bash/YAML/Markdown para scripts e automação), fora do escopo desta
  feature e do Constraints do `spec.md` (não introduzir infraestrutura externa).

### Matriz de decisão (formato → quando usar)

| Formato | Quando usar | Exemplo já existente |
|---|---|---|
| **Bats-core** (padrão principal) | Testes de scripts/CLI com múltiplas asserções, setup/teardown, ou que se beneficiam de relatório TAP granular | `tests/bootstrap/*.bats` |
| **Script `.test.sh` simples** (aceito, não descontinuado) | Validação pontual de conteúdo/schema de documentação ou manifest (ex.: "este checklist contém a seção X") sem necessidade de múltiplas asserções organizadas | `tests/docs/*.test.sh`, `tests/scripts/*.test.sh`, `tests/workflows/*.test.sh` |
| **Exceção documentada** (qualquer outro formato) | Requer `Exception Record` explícito na política, com justificativa técnica e aprovador — nunca adoção silenciosa (FR-009) | Nenhum caso hoje |

## Decisão 2 — Mecanismo de descoberta e execução da suíte mandatória

**Decision**: `scripts/run-tests.sh` (novo) é o ponto de entrada único — descobre
e executa, em sequência: (a) todo arquivo `tests/**/*.bats` via `bats`, e (b)
todo arquivo `tests/**/*.test.sh` via `bash <arquivo>`, agregando um resultado
consolidado (total de grupos, quais falharam). `.github/workflows/test-suite.yml`
apenas invoca este mesmo script dentro do runner — garantindo paridade honesta
entre CI e execução local (AC-4), sem lógica duplicada entre workflow e script.

**Rationale**: Centralizar a lógica de descoberta em um único script bash (em
vez de replicá-la dentro do YAML do workflow) é o mesmo padrão já usado por
`validate-manifests.yml` e `graph-guard.yml` para suas respectivas checagens —
consistente com a convenção já estabelecida neste bundle.

**Alternatives considered**:
- **Lógica de descoberta embutida diretamente no YAML do workflow** (sem script
  intermediário): rejeitado — quebraria a paridade de execução local (AC-4),
  pois o contribuidor precisaria replicar manualmente os mesmos comandos do
  YAML linha a linha.
- **Um workflow por grupo de teste** (`test-bootstrap.yml`, `test-docs.yml`
  etc.), no lugar de um workflow único: rejeitado — contraria diretamente o
  FR-007 (gate único e consolidado) e reintroduziria a fragmentação que esta
  feature busca eliminar.

## Decisão 3 — Rollout do gate obrigatório (modo relatório → required check)

**Decision**: Ver `plan.md`, seção "Estratégia de Release" — rollout faseado
manual (não uma automação de flag), com decisão humana explícita para promover
o check de "informativo" para "obrigatório" na proteção de branch.

**Rationale**: Formalizado no `plan.md`; resumo aqui apenas para consolidar o
rastro de decisões desta feature em um único documento de pesquisa.

**Alternatives considered**: Ver `plan.md` (OpenFeature não se aplica a
branch protection rules do GitHub; alternativa de flag de software descartada
por não haver componente de runtime a alternar).

## Decisão 4 — Tratamento de testes legados fora do padrão principal

**Decision**: Nenhum teste existente é removido ou migrado nesta feature. Os
`.test.sh` existentes permanecem com status **"aceito, não descontinuado"**
(ver matriz da Decisão 1) — não são um "legado a migrar", pois se enquadram
numa categoria válida e permanente da política, não numa exceção temporária.

**Rationale**: Atende diretamente ao FR-010 do `spec.md` (definir tratamento
explícito para testes que não coincidem com o padrão principal) sem gerar
trabalho de migração desnecessário — a política resolve a ambiguidade
classificando ambos os formatos como aceitos, cada um com seu critério de uso,
em vez de forçar uma migração sem benefício técnico claro.

**Alternatives considered**:
- **Migração obrigatória de todos os `.test.sh` para Bats em uma issue de
  follow-up com prazo definido**: considerado, mas não adotado nesta fase —
  pode ser reavaliado como Exception Record futuro se a matriz de decisão se
  mostrar insuficiente na prática (ex.: um `.test.sh` crescer a ponto de
  precisar de múltiplas asserções organizadas).
