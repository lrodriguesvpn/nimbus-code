# Playbook de Sucesso — NIMBUS CODE

## Conceito

**Playbook de Sucesso** é a prática de instrumentar o processo de desenvolvimento
para capturar, catalogar e propagar aprendizados de **acertos** de forma estruturada,
tornando o conhecimento adquirido reutilizável por toda a organização — não apenas
pelo time que viveu o sucesso.

No contexto do NIMBUS CODE, o objetivo é:

> *Todo agente que trabalha em qualquer projeto alimenta e consulta um repositório
> central de padrões bem-sucedidos, acelerando entregas ao reutilizar o que
> funcionou em projetos e contextos similares.*

---

## Por que Playbook de Sucesso é necessário aqui?

Agentes de IA têm memória de sessão — ao encerrar uma sessão, o contexto se perde.
O `harness-catalog.yaml` já resolve a memória de **erros**; o `success-catalog.yaml`
resolve a memória de **acertos**: padrões que funcionaram, soluções elegantes,
abordagens que economizaram tokens ou reduziram retrabalho.

Sem esse catálogo, cada agente redescobre soluções já conhecidas — pagando o custo
de derivação toda vez.

---

## Quando registrar um Playbook

Registre uma entrada no `success-catalog.yaml` quando ocorrer **ao menos um** dos
seguintes eventos:

| Gatilho | Exemplos |
|---|---|
| **Feature entregue sem retrabalho** | todos os ACs passaram no primeiro PR, sem revisão de escopo |
| **Reutilização bem-sucedida de padrão** | schema copiado de outra feature, economizando design do zero |
| **Economia de tokens significativa** | referência por ponteiro reduziu planning em >40% |
| **Abordagem generalizável** | solução aplicável a ≥2 bounded contexts distintos |
| **S3/S4 dentro do orçamento estimado** | feature complexa entregue sem escalonamento de complexidade |

**Não registre** entradas genéricas ou óbvias ("sempre faça testes" não é um playbook).
O catálogo tem valor quando é específico, contextualizado e reaplicável.

---

## Fluxo de Uso

```
Novo projeto / feature
        ↓
Agente consulta success-catalog.yaml
(por tags + bounded_context relevantes)
        ↓
[Match encontrado]              [Sem match]
Declara no plan.md              Segue fluxo normal
seção "Playbook de Sucesso Gate"
Referencia padrão por ponteiro
        ↓
Feature entregue
        ↓
[Padrão digno de registro?]     [Nada a registrar]
Issue com playbook:pending       Fecha normalmente
        ↓                        (declare explicitamente
Dev/agente valida               "Nada relevante a registrar")
e adiciona entry
        ↓
Próximo projeto acelera ♻️
```

---

## Cadência de Revisão de Métricas de Processo (DORA)

As métricas DORA são revisadas em duas cadências complementares
(specs/021-dora-metrics-governance, FR-010):

- **Semanal**, por squad — leitura rápida de tendência própria.
- **Mensal**, para a visão de portfólio/PMO — consolidação entre squads.

### Definições Oficiais dos Indicadores (FR-001)

Estas são as definições fechadas e não ambíguas — toda squad usa exatamente
a mesma fórmula, evento de origem e janela de medição.

| Indicador | Fórmula | Evento de origem | Janela de medição | Regra de inclusão/exclusão |
|---|---|---|---|---|
| `deployment_frequency` | Contagem de deploys no período ÷ semanas no período | Merge de PR rotulado `dora:deployment-frequency` | `--since`/`--until` (default: últimos 30 dias) | Conta apenas PRs mergeados; PRs fechados sem merge não contam |
| `lead_time_for_changes` | Média de (data de merge − data de criação) dos PRs rotulados | Merge de PR rotulado `dora:lead-time` | Mesma janela acima | PR sem `createdAt`/`mergedAt` válidos é ignorado do cálculo, não zerado |
| `change_failure_rate` | (Itens rotulados `dora:change-failure-rate` fechados no período ÷ `deployment_frequency` no mesmo período) × 100 | Issue ou PR fechado/mergeado rotulado `dora:change-failure-rate` | Mesma janela acima, sempre pareada com a janela de `deployment_frequency` | Sem deploys no período, o indicador é `INSUFFICIENT_DATA` (proporção indefinida), nunca 0% |
| `mttr` | Média de (data de fechamento − data de criação) das issues rotuladas, em horas | Issue fechada rotulada `dora:mttr` | Mesma janela acima | Issue sem `closedAt` válido é ignorada do cálculo |

> Indicador sem nenhum item rotulado no período é sempre marcado explicitamente
> como `INSUFFICIENT_DATA` — nunca reportado como zero, que seria enganoso
> (ver `scripts/process-metrics-report.sh`).

### Origem e Rastreabilidade da Coleta (FR-002, FR-003)

Coleta automática via labels `dora:*` continua sendo o **caminho padrão** —
nenhuma intervenção manual é necessária para eventos elegíveis. Todo item
contabilizado é rastreável até o issue/PR de origem (número + labels + datas
retornados por `gh`). Ajustes manuais são sempre a exceção, nunca a rota
primária — ver seção "Ajustes Manuais e Trilha de Auditoria" abaixo.

### Formato de Registro

Cada revisão (semanal ou mensal) é registrada como uma **Issue** com os campos:

| Campo | Descrição |
|---|---|
| `deployment_frequency` | Quantos deploys por semana no período |
| `lead_time_for_changes` | Tempo médio do primeiro commit ao deploy (dias) |
| `change_failure_rate` | % de deploys que geraram incidente ou rollback |
| `mttr` | Tempo médio de recuperação após incidente (horas) |
| Meta | Valor alvo por indicador |
| Ação de melhoria | O que fazer quando abaixo da meta (dono + prazo) |
| `combined_conclusion` | Conclusão da leitura combinada dos 4 indicadores (ver abaixo) — **obrigatória para fechar a revisão** |

### Metas Iniciais Sugeridas

| Indicador | Meta Inicial | Nível de Elite (referência DORA) |
|---|---|---|
| `deployment_frequency` | ≥ 1 deploy/semana | Múltiplos por dia |
| `lead_time_for_changes` | ≤ 7 dias | < 1 hora |
| `change_failure_rate` | ≤ 15% | < 5% |
| `mttr` | ≤ 24 horas | < 1 hora |

> **Como calcular:** use `scripts/process-metrics-report.sh --repo-owner <org> --repo-name <repo> --since <data> --until <data>`
> para obter os 4 indicadores calculados a partir das labels `dora:*` aplicadas em issues e PRs.

### Leitura Combinada — Nunca Decisão por Indicador Isolado (FR-007)

Toda revisão (semanal ou mensal) MUST produzir uma conclusão que considere
os 4 indicadores em conjunto, nunca uma decisão baseada em um único
indicador isolado. Exemplos de leitura combinada:

- `deployment_frequency` subindo **e** `change_failure_rate` subindo junto
  → aceleração pode estar comprometendo qualidade; investigar antes de
  comemorar a frequência isolada.
- `lead_time_for_changes` caindo **e** `mttr` subindo → entregas mais rápidas,
  mas recuperação mais lenta; pode indicar redução de testes/observabilidade.

Uma revisão **não é considerada fechada** sem essa conclusão combinada
registrada na Issue (`combined_conclusion`).

### Ajustes Manuais e Trilha de Auditoria (FR-004, FR-005, FR-006, FR-012)

Ajuste manual é sempre exceção controlada, nunca rota primária de coleta.
Para registrar um ajuste:

```bash
scripts/process-metrics-report.sh --record-manual-adjustment \
  --indicator <deployment_frequency|lead_time_for_changes|change_failure_rate|mttr> \
  --justification "<motivo objetivo>" \
  --author <handle> \
  --evidence-link <url> \
  --exception-category <categoria> \
  [--approved-by <handle>] \
  [--review-cycle-period <periodo>]
```

O script **rejeita** o ajuste se `justification`, `author`, `evidence_link`
ou `exception_category` estiverem ausentes — nenhum ajuste parcial é aceito.
Todo ajuste fica registrado em
[`docs/playbooks/dora-manual-adjustments-log.yaml`](./dora-manual-adjustments-log.yaml),
com autor, timestamp, evidência e categoria (fonte para rastrear "quem
mediu, quem ajustou, quem aprovou").

**Gate de fechamento:** antes de fechar a Issue de revisão de um período,
rode:

```bash
scripts/process-metrics-report.sh --check-review-cycle-closure --review-cycle-period <periodo>
```

Se retornar `CLOSURE_BLOCKED`, a revisão **não pode** ser fechada até que o(s)
ajuste(s) listado(s) tenham todos os campos obrigatórios preenchidos — isso
nunca deve ser contornado manualmente.

### Degradação Vira Ação de Backlog (FR-008, FR-009)

`scripts/process-metrics-report.sh` sinaliza automaticamente quando um
indicador cruza a Meta Inicial (tabela acima) — por exemplo:
`⚠ deployment_frequency abaixo da meta inicial (< 1/semana, atual: 0.23/semana)`.

Esse sinal **não abre uma Issue automaticamente** (mesmo racional da
sinalização proativa de retrospectiva) — o responsável pela revisão deve, ao
ver o sinal:

1. Abrir ou atualizar uma Issue de melhoria reaproveitando os labels
   `priority:*`/`dora:*` já existentes na taxonomia (`docs/label-taxonomy-and-autonomous-dev.md`).
2. Preencher `owner` (responsável pela ação), `priority` inicial e prazo de
   reavaliação — nenhuma ação de melhoria fica sem essas 3 informações.
3. Vincular a Issue à revisão que a originou.

### Comparabilidade entre Squads de Maturidade Diferente (AC-6)

Ao comparar indicadores entre squads, avalie **evolução relativa** de cada
squad ao longo do tempo — nunca um ranking absoluto direto entre squads de
tamanho/escopo/maturidade diferentes. Um squad que está reduzindo seu próprio
`lead_time_for_changes` mês a mês está progredindo, mesmo que seu valor
absoluto ainda seja maior que o de outro squad com contexto mais simples.
Squads recém-criadas sem histórico suficiente ainda não têm baseline para
comparação mensal — aguardar ao menos um ciclo completo antes de tirar
conclusões comparativas.

---

## Arquivos deste diretório

| Arquivo | Propósito |
|---|---|
| `success-catalog.yaml` | Catálogo central de padrões bem-sucedidos (machine-readable) |
| `README.md` | Este guia — conceito, fluxo e referências |
| `retro-cadence-state.yaml` | Estado da cadência de retrospectivas (gerado por `process-metrics-report.sh`) |
| `dora-manual-adjustments-log.yaml` | Trilha de auditoria de ajustes manuais DORA (specs/021-dora-metrics-governance) |

---

## Comparativo: Playbook de Sucesso vs. Harness Catalog

| Dimensão | Playbook de Sucesso | Harness Catalog |
|---|---|---|
| **Propósito** | Catalogar o que **repetir** | Catalogar o que **evitar** |
| **Gatilho de registro** | Feature entregue sem retrabalho; padrão generalizável | Retrabalho > 20%; incidente; erro de agente |
| **Campo central** | `what_worked` + `how_to_reapply` | `error_pattern` + `prevention` |
| **Schema base** | `id: SUC-NNNN` | `id: HRN-NNNN` |
| **Labels de ciclo** | `playbook:pending` → `playbook:cataloged` | `harness:pending` → `harness:cataloged` |
| **Instrução ao agente** | Consultar ANTES do plan.md — seção "Playbook de Sucesso Gate" | Consultar ANTES do plan.md — seção "Harness Gate" |
| **Emoção associada** | ✅ "Faça mais disso" | ⚠️ "Nunca repita isso" |
| **Arquivo** | `docs/playbooks/success-catalog.yaml` | `docs/harness/harness-catalog.yaml` |
