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

As métricas DORA devem ser revisadas **mensalmente** para garantir que o processo
de entrega está melhorando ao longo do tempo.

### Formato de Registro

Cada revisão mensal é registrada como uma **Issue** com os campos:

| Campo | Descrição |
|---|---|
| `deployment_frequency` | Quantos deploys por semana no período |
| `lead_time_for_changes` | Tempo médio do primeiro commit ao deploy (dias) |
| `change_failure_rate` | % de deploys que geraram incidente ou rollback |
| `mttr` | Tempo médio de recuperação após incidente (horas) |
| Meta | Valor alvo por indicador |
| Ação de melhoria | O que fazer quando abaixo da meta (dono + prazo) |

### Metas Iniciais Sugeridas

| Indicador | Meta Inicial | Nível de Elite (referência DORA) |
|---|---|---|
| `deployment_frequency` | ≥ 1 deploy/semana | Múltiplos por dia |
| `lead_time_for_changes` | ≤ 7 dias | < 1 hora |
| `change_failure_rate` | ≤ 15% | < 5% |
| `mttr` | ≤ 24 horas | < 1 hora |

> **Como calcular:** use `scripts/process-metrics-report.sh --repo-owner <org> --repo-name <repo> --since <data> --until <data>`
> para obter os 4 indicadores calculados a partir das labels `dora:*` aplicadas em issues e PRs.

---

## Arquivos deste diretório

| Arquivo | Propósito |
|---|---|
| `success-catalog.yaml` | Catálogo central de padrões bem-sucedidos (machine-readable) |
| `README.md` | Este guia — conceito, fluxo e referências |
| `retro-cadence-state.yaml` | Estado da cadência de retrospectivas (gerado por `process-metrics-report.sh`) |

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
