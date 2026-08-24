# Harness Engineering — NIMBUS CODE

## Conceito

**Harness Engineering** é a prática de instrumentar o processo de desenvolvimento
para capturar, catalogar e propagar aprendizados de falhas de forma estruturada,
tornando o conhecimento adquirido reutilizável por toda a organização — não apenas
pelo time que viveu o erro.

No contexto do NIMBUS CODE, o objetivo é:

> *Todo agente que trabalha em qualquer projeto alimenta e consulta um repositório
> central de lições aprendidas, evitando que erros já cometidos em projetos similares
> se repitam.*

---

## Por que Harness Engineering é necessário aqui?

Agentes de IA têm memória de sessão — ao encerrar uma sessão, o contexto se perde.
Sem um mecanismo externo de memória organizacional, cada agente reincide nos mesmos
erros arquiteturais, de escopo, de segurança e de integração que times anteriores já
pagaram para aprender.

O `harness-catalog.yaml` é esse mecanismo: um banco de lições que atravessa sessões,
projetos e agentes.

---

## Quando registrar um Harness

Registre uma entrada no `harness-catalog.yaml` quando ocorrer **ao menos um** dos
seguintes eventos:

| Gatilho | Exemplos |
|---|---|
| **Incidente em produção** | bug que chegou a clientes, rollback de deploy, outage |
| **Retrabalho > 20% do esforço** | decisão arquitetural revertida, escopo reescrito, PR recusado e refeito |
| **Erro de agente identificado** | hallucination documentada, escopo extrapolado, decisão fora do padrão imposta silenciosamente |
| **Pós-sprint com lição clara** | qualquer retrospectiva que produza um "nunca mais faça isso" |
| **S3/S4 com desvio do plano** | feature que não seguiu o impact-map ou violou o gate de segurança |

**Não registre** entradas genéricas ou óbvias ("sempre faça testes"). O harness tem
valor quando é específico, contextualizado e acionável.

---

## Fluxo de Uso

```
Novo projeto / feature
        ↓
Agente consulta harness-catalog.yaml
(por tags + bounded_context relevantes)
        ↓
[Match encontrado]              [Sem match]
Declara no plan.md              Segue fluxo normal
seção "Harness Consultado"
Mitiga preventivamente
        ↓
Feature entregue
        ↓
[Retrabalho/incidente?]         [Fluxo limpo]
Issue com label harness:pending  Fecha normalmente
Dev/agente preenche
harness-catalog.yaml
        ↓
Próximo projeto aprende ♻️
```

---

## Arquivos deste diretório

| Arquivo | Propósito |
|---|---|
| `harness-catalog.yaml` | Catálogo central de lições aprendidas (machine-readable) |
| `incident-template.md` | Template de post-mortem para incidentes S3/S4 |
| `harness-guide.md` | Guia detalhado para devs e agentes |

---

## Integração com o Ciclo NIMBUS CODE

### Em `/nimbus-code-plan`
Antes de redigir o `plan.md`, o agente **deve** consultar `docs/harness/harness-catalog.yaml`
filtrando por `tags` e `bounded_context` relacionados à feature. Se encontrar match,
declara na seção **Harness Consultado** do `plan.md` (adicionada ao template):
- ID do harness
- Padrão de erro evitado
- Como foi mitigado preventivamente nesta feature

### Ao fechar `/nimbus-code-tasks`
Se houve retrabalho relevante ou incidente, o checklist de fechamento inclui:
- [ ] Abrir Issue com label `harness:pending`
- [ ] Preencher entrada no `harness-catalog.yaml`
- [ ] Fechar Issue com label `harness:cataloged`

---

## Labels relacionados

| Label | Significado |
|---|---|
| `harness:pending` | Lição identificada, ainda não catalogada |
| `harness:cataloged` | Lição registrada no `harness-catalog.yaml` |
| `harness:blocking` | Padrão de erro crítico que bloqueia PR até revisão explícita |
