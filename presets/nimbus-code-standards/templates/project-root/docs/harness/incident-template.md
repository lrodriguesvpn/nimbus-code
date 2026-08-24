# Post-Mortem — [Título do Incidente]

> **Uso:** Preencher este template sempre que um incidente S3/S4 atingir produção
> (ou causou rollback/retrabalho > 20% do esforço), como parte do processo de
> catalogação no `harness-catalog.yaml`. Um post-mortem **sem culpa** — o objetivo é
> entender o sistema, não punir pessoas ou agentes.

---

## Metadados

| Campo | Valor |
|---|---|
| **ID Harness** | HRN-NNNN *(atribuir ao criar entrada no harness-catalog.yaml)* |
| **Data do incidente** | YYYY-MM-DD |
| **Data do post-mortem** | YYYY-MM-DD |
| **Severity** | S3 · S4 |
| **Bounded Context** | [slug] |
| **Duração do impacto** | [ex.: 2h30min] |
| **Clientes/usuários afetados** | [ex.: 100% dos usuários da feature X · apenas ambiente hml] |
| **Author(s)** | [dev/agente responsável pelo post-mortem] |
| **PR/Issue de origem** | [link] |

---

## Resumo Executivo (1 parágrafo)

> Descreva o incidente em 3-5 frases: o que aconteceu, qual foi o impacto imediato
> e como foi resolvido. Este parágrafo é o que vai para o `harness-catalog.yaml`
> como `error_pattern` + `impact`.

---

## Timeline

| Horário (UTC) | Evento |
|---|---|
| HH:MM | Primeiro sinal do problema (alerta, relato, detecção) |
| HH:MM | Diagnóstico iniciado |
| HH:MM | Causa raiz identificada |
| HH:MM | Mitigação aplicada |
| HH:MM | Serviço/feature restaurado |
| HH:MM | Incidente declarado encerrado |

---

## Análise de Causa Raiz — 5 Whys

> Repita "Por quê?" até chegar na causa sistêmica. Pare em 5 ou quando a causa
> raiz deixar de ser controlável pelo time. Não pare no primeiro "erro humano" —
> todo erro humano tem um sistema por trás que o permitiu.

1. **Por que o incidente ocorreu?**
   → [resposta]

2. **Por que [resposta 1] aconteceu?**
   → [resposta]

3. **Por que [resposta 2] aconteceu?**
   → [resposta]

4. **Por que [resposta 3] aconteceu?**
   → [resposta]

5. **Por que [resposta 4] aconteceu?**
   → **Causa raiz:** [resposta]

---

## Causa Raiz (síntese)

> 1-3 frases consolidando o 5-Whys. Este campo alimenta diretamente o `root_cause`
> no `harness-catalog.yaml`.

---

## O que foi feito para resolver (fix_applied)

> Descreva a solução de curto prazo aplicada durante o incidente (hotfix, rollback,
> feature flag off etc.) e a solução de longo prazo (se diferente).

**Curto prazo (mitigação):**
[descrição]

**Longo prazo (correção estrutural):**
[descrição ou "a definir — Issue #NNN"]

---

## Ações Preventivas (prevention)

> O que o agente / dev DEVE fazer diferente nas próximas vezes? Acionável e específico.
> Este campo alimenta diretamente `prevention` no `harness-catalog.yaml`.

| Ação | Responsável | Prazo | Issue/PR |
|---|---|---|---|
| [ação preventiva concreta] | [dev/agente/squad] | [data] | [link] |
| [ação preventiva concreta] | [dev/agente/squad] | [data] | [link] |

---

## Gates que falharam (se aplicável)

> Quais gates do NIMBUS CODE (Security Gate, Qualidade Gate, Harness Gate, Graph Gate)
> não detectaram ou não bloquearam este incidente? Isso indica que o gate precisa
> ser endurecido.

| Gate | Falha identificada | Proposta de melhoria |
|---|---|---|
| [nome do gate] | [o que deveria ter capturado e não capturou] | [como melhorar] |

---

## Tags sugeridas para o harness-catalog.yaml

> Selecione as tags mais relevantes para que outros agentes encontrem esta entrada:

- [ ] `agent-scope-creep`
- [ ] `agent-hallucination`
- [ ] `silent-architecture-decision`
- [ ] `adr-bypass`
- [ ] `reuse-catalog-skip`
- [ ] `security-gate-bypass`
- [ ] `missing-rollback-plan`
- [ ] `scope-underestimated`
- [ ] `ci-failure-ignored`
- [ ] `secret-exposure`
- [ ] `database-migration-risk`
- [ ] `feature-flag-missing`
- [ ] `observability-gap`
- [ ] [outra tag específica deste incidente]

---

## Checklist de encerramento

- [ ] Timeline completa
- [ ] 5 Whys completados até causa raiz sistêmica
- [ ] Ações preventivas criadas como Issues com responsável e prazo
- [ ] Entry adicionada ao `docs/harness/harness-catalog.yaml`
- [ ] Issue com `harness:pending` fechada com `harness:cataloged`
- [ ] Gates que falharam identificados e Issue de melhoria aberta (se aplicável)
- [ ] Post-mortem compartilhado com o time (slack, wiki, ou PR de docs)
