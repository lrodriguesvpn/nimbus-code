# quickstart.md — Feature 012: Loop de Melhoria Contínua Nimbus-Code

Guia de validação executável — prova que a feature funciona ponta a ponta.
Ver [data-model.md](./data-model.md) para o schema completo das entidades e
[spec.md](./spec.md) para os critérios de aceite (AC-1 a AC-5).

## Pré-requisitos

- `gh` CLI ≥ 2.40 autenticado no host `venha-pra-nuvem.ghe.com`
- `jq` ≥ 1.6
- Feature 011 (Harness Engineering) já mergeada — `docs/harness/harness-catalog.yaml` e `scripts/harness-search.sh` disponíveis como precedente estrutural

## Cenário 1 — Registrar um Playbook de Sucesso (AC-1)

1. Fechar uma feature de exemplo cujo `tasks.md` não teve nenhuma task
   revertida/retrabalhada.
2. Rodar o checklist de fechamento (ver item novo em `tasks-template.md`).
3. **Resultado esperado**: o agente propõe um rascunho de entrada para
   `docs/playbooks/success-catalog.yaml` citando o padrão que funcionou bem;
   a entrada só é gravada após confirmação humana explícita (`validated_by`
   preenchido).

## Cenário 2 — Calcular os Indicadores DORA (AC-2)

```bash
./scripts/process-metrics-report.sh --repo-owner venha-pra-nuvem --repo-name nimbus-code-spec-kit-template --since 2026-07-01 --until 2026-08-20
```

**Resultado esperado**: saída com os 4 indicadores (deployment frequency,
lead time, change failure rate, MTTR) calculados a partir de issues/PRs
rotulados `dora:*` no período — em menos de 10 segundos (SC-002). Indicadores
sem dado suficiente aparecem marcados como tal, não omitidos silenciosamente
nem com valor inventado (ver Edge Case do `spec.md`).

## Cenário 3 — Revisão Periódica de DORA com Meta (AC-3)

1. Definir uma meta para cada indicador (ex.: lead time médio < 3 dias).
2. Rodar o Cenário 2 no fechamento do período de cadência (ex.: mensal).
3. **Resultado esperado**: para cada indicador abaixo da meta, existe um
   registro (Issue ou entrada de documento) com a ação de melhoria, dono e
   prazo — não apenas o número reportado sem consequência.

## Cenário 4 — Sinalização Proativa de Retrospectiva (AC-4)

1. Simular N features concluídas em sequência (N = valor configurado, sugestão
   inicial 5) sem nenhuma divergência de plano registrada.
2. **Resultado esperado**: ao fechar a N-ésima feature, o agente sinaliza
   proativamente que uma retrospectiva está devida, referenciando
   `retro-template.md` — mesmo sem nenhum incidente ou desvio ter ocorrido.

## Cenário 5 — Playbook de Sucesso Gate no `plan.md` (AC-5)

1. Rodar `/speckit-plan` para uma feature de exemplo.
2. **Resultado esperado**: o `plan.md` gerado contém a seção "Playbook de
   Sucesso Gate" (análoga ao "Harness Gate" já existente da feature 011),
   preenchida com um dos três estados obrigatórios: match encontrado, nenhum
   match relevante, ou catálogo vazio — nunca em branco.

## Validação retroativa desta sessão

Esta spec foi escrita e planejada (spec.md + plan.md + research.md +
data-model.md + quickstart.md + graph.yaml + graph.md + impact-map.md) sem
ainda ter `tasks.md`/implementação — os cenários acima descrevem o
comportamento esperado após `/speckit-tasks` + `/speckit-implement`, não o
estado atual do repositório.
