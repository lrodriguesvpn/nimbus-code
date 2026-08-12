# NNNN — Título Curto da Decisão

<!--
  Template de Architecture Decision Record (ADR) — baseado no formato MADR
  (Markdown Any Decision Records: https://adr.github.io/madr/).

  Uso:
    cp presets/nimbus-code-standards/templates/adr/NNNN-template.md \
       docs/adr/$(printf "%04d" <N>)-<slug>.md

  Ou via extensão nimbus-code-adr (quando disponível):
    /speckit-adr "Título da decisão"

  Convencionar numeração sequencial a partir de 0001.
  Decisões organizacionais (afetam múltiplos projetos) vivem neste repositório
  em docs/adr/. Decisões de projeto vivem no repositório do projeto.
-->

- **Status:** Proposta · **Em revisão** · Aceita · Obsoleta · Supersedida por [NNNN](NNNN-titulo.md)
- **Data:** YYYY-MM-DD
- **Autores:** @autor
- **Contexto:** [feature-slug ou "organizacional"]
- **Revisores:** @revisor1, @revisor2

---

## Contexto e Problema

[Descreva em 2–4 parágrafos o problema que motivou esta decisão. Inclua restrições
do ambiente (multi-cloud, compliance, SLA, stack existente) e por que a decisão é
necessária agora.]

## Drivers de Decisão

- [Driver 1 — ex.: custo operacional]
- [Driver 2 — ex.: consistência com o padrão multi-cloud existente]
- [Driver 3 — ex.: velocidade de entrega da primeira feature]

## Opções Consideradas

- **Opção A** — [nome curto]
- **Opção B** — [nome curto]
- **Opção C** — [nome curto, "manter o que está"]

## Análise das Opções

### Opção A — [Nome]

[Descreva brevemente.]

- ✅ [Vantagem 1]
- ✅ [Vantagem 2]
- ❌ [Desvantagem 1]

### Opção B — [Nome]

[Descreva brevemente.]

- ✅ [Vantagem 1]
- ❌ [Desvantagem 1]
- ❌ [Desvantagem 2]

### Opção C — [Manter o status quo]

[Descreva brevemente.]

- ✅ [Vantagem: zero esforço de migração]
- ❌ [Desvantagem: não resolve o problema]

## Decisão

**Opção escolhida: Opção A**, porque [justificativa em 1–3 frases conectando a
escolha aos drivers acima].

## Consequências

### Positivas

- [Consequência positiva 1]
- [Consequência positiva 2]

### Negativas / Trade-offs Assumidos

- [Trade-off 1 — ex.: perde portabilidade entre provedores]
- [Trade-off 2 — ex.: requer treinamento do time]

### Ações derivadas

- [ ] [Ação necessária para implementar esta decisão, com owner e prazo]
- [ ] [Atualizar ADL do plan.md das features afetadas apontando para este ADR]

## Links

- [Link para issue/PR que motivou a decisão]
- [Link para documentação técnica relevante]
- Supersede: —
- Relacionado a: —
