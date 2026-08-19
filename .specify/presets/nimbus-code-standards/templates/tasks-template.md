<!--
  Este bloco é inserido pelo preset `nimbus-code-standards` (estratégia `append`) ao final
  do tasks-template.md nativo do Nimbus Code — não substitui nenhuma seção/tarefa gerada
  pelo `/nimbus-code-tasks`. Formaliza o checklist de qualidade que antes vivia em
  `references/devops-artifacts-catalog.md` e no Passo 6.3 da skill devops-planning.
-->

## Nimbus-Code — Contrato de Task Executável no GHE

*Toda task orientada a execução humana deve permitir execução sem depender de
leitura adicional de spec/plan. Use este bloco como padrão para cada issue/tarefa.*

```markdown
## Contexto
[o mínimo necessário para entender o problema]

## Objetivo
[ação clara e acionável]

## Resultado Esperado
[entregável verificável]

## Critérios de Aceite
- [ ] [critério 1 verificável]

## Passos Operacionais
1. [passo 1]
2. [passo 2]

## Dependências
[Nenhuma | IDs de tasks/issues bloqueadoras]

## Responsável
Agente: [sim/não]
Humano: [sim/não]

## Estimativa de Esforço
- Tokens (agente): ~X–Y mil
- Horas (humano): ~X–Y horas

## Referência
- AC-ID: AC-N
- Feature: specs/<feature-slug>
- SPEC KIT COST: https://github.com/venha-pra-nuvem/spec-kit-cost
```

- [ ] Toda task com `Responsável.Humano = sim` inclui `Passos Operacionais` completos
- [ ] `Dependências` está preenchido com `Nenhuma` quando não existir bloqueador
- [ ] `Referência` inclui AC-ID e link da feature de origem
- [ ] `SPEC KIT COST` presente quando a task fizer parte do modelo híbrido

## Nimbus-Code — Checklist de Qualidade de Código, Testes e Observabilidade

*Aplicável a TODA tarefa desta lista que produz ou altera código (não apenas
infraestrutura) — traduz em ação as regras de "Qualidade e Processo" da
constituição da Nimbus-Code. Marcar como concluída somente após validar cada item
relevante ao artefato entregue pela tarefa.*

- [ ] `graph.yaml` e `graph.md` atualizados para refletir módulos adicionados ou
      alterados por esta tarefa (Graph Guard valida automaticamente na PR)
- [ ] Para complexidade S3/S4: `impact-map.md` atualizado e revisado antes do merge
- [ ] Critérios de aceitação da `spec.md` cobertos com ID de teste rastreável
      (ex.: `test_AC1_<descricao>`) — ou exceção justificada no `plan.md`
- [ ] Feature flag configurada e ativa para esta feature, conforme estratégia
      de release definida no `plan.md` (ou "N/A — deploy direct justificado")
- [ ] Testes contemplam os dois caminhos da flag (ON/OFF) ou exceção foi
      justificada no `plan.md`
- [ ] Estratégia de rollout progressivo executada em homologação (canário,
      cliente piloto ou equivalente) com evidência anexada ao PR
- [ ] Tarefa/issue de remoção da flag criada com prazo e owner definidos
- [ ] SLO medido em staging dentro dos limites definidos no SLO Gate do `plan.md`
      (ou "N/A — sem ambiente de staging disponível para esta tarefa")
- [ ] Revisão de código por IA (GitHub Copilot code review) solicitada no PR e
      sem findings High/Critical pendentes
- [ ] Teste de integração cobrindo o(s) critério(s) de aceitação do `spec.md`
      correspondente(s) a esta tarefa — ou exceção já justificada no `plan.md`
- [ ] Observabilidade instrumentada: logs estruturados, métricas e alertas
      mínimos para o componente entregue
- [ ] Se esta tarefa faz parte de uma arquitetura de microsserviços: correlation-id/
      trace-id propagado nas chamadas entre serviços e ponto de orquestração/
      coreografia identificado (ou "N/A" se monólito)
- [ ] Bugs encontrados durante o desenvolvimento/teste desta tarefa que não
      foram corrigidos aqui foram abertos como Issue no GitHub e atribuídos ao
      Copilot coding agent

- [ ] Se esta feature introduziu um padrão reaproveitável (não específico só dela),
      uma entrada foi adicionada ao `docs/reuse-catalog.yaml` com `tag`,
      `bounded_context`, `description` e `source` — ver checklist de fechamento
      acima e `docs/ai-code-quality-and-observability.md`, seção 9
- [ ] `retro-template.md` preenchido em `specs/<feature-slug>/retro.md` quando
      a implementação divergiu do plano (grafo mudou, SLO não atingido, bug
      inesperado encontrado) — ver template em
      `presets/nimbus-code-standards/templates/feature-artifacts/retro-template.md`

## Nimbus-Code — Métricas de Branches e Saúde do Repositório (PMO)

*Preencher semanalmente pelo Dev responsável pelo repositório. Métrica de
governança do uso de agentes — branches perdidas são sinal de sessões
não-finalizadas ou PRs abandonados.*

| Métrica | Esta semana | Semana anterior | Tendência |
|---|---|---|---|
| Branches ativas (com PR aberto) | | | |
| **Branches perdidas** (sem PR, inativas ≥ 3 dias) | | | ↑ / ↓ / = |
| Branches mergeadas e não-deletadas | | | |
| PRs abertos por agente há > 5 dias sem revisão | | | |

**Ação obrigatória quando "Branches perdidas" > 0:**
- [ ] Listar as branches perdidas (ver `docs/agent-session-manual.md`, seção 7)
- [ ] Para cada branch perdida: deletar ou abrir PR justificando a continuidade
- [ ] Registrar a causa raiz (sessão não finalizada? instrução vaga? escopo grande?)
  como comentário na tabela acima para rastrear padrões ao longo do tempo

> **Referência:** para o comando de auditoria de branches e o protocolo completo
> de limpeza, ver [`docs/agent-session-manual.md`](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/blob/main/docs/agent-session-manual.md#7-controle-de-branches-perdidas).

## Nimbus-Code — Estimativa vs. Consumo Real de Tokens e Horas Humanas

*Preencher no fechamento da feature (após a última tarefa desta lista),
comparando com a estimativa registrada no `plan.md`. Ver metodologia completa
em `docs/ai-code-quality-and-observability.md`, seções 6 e 8.*

| Métrica | Estimado (`plan.md`) | Real | Variância | Fonte da medição |
|---|---|---|---|---|
| Tokens (input+output) | [ex.: ~80–120 mil] | [valor real ou "não disponível — sem telemetria desta ferramenta"] | [+/-N%] | [ex.: Copilot Usage da organização, uso reportado pelo agente, etc.] |
| Horas humanas | — *(não estimado previamente; ver nota abaixo)* | [total lançado no campo "Horas Humanas" do GitHub Project] | — | GitHub Project — campo "Horas Humanas" |

**Custo real total desta feature** (se a taxa custo/hora do time estiver
documentada no README/ADR do projeto):
`[tokens reais × preço do modelo] + [horas humanas × custo/hora do time] = [valor]`

- [ ] Consumo real de tokens registrado e comparado com a estimativa do
      `plan.md` — variância documentada acima
- [ ] Horas humanas desta feature (revisão de PR, ajustes manuais,
      pareamento) lançadas no campo "Horas Humanas" do GitHub Project
- [ ] Se a variância de tokens for consistentemente alta (real >2× estimado),
      revisar o baseline de estimativa do projeto para próximas features

## Nimbus-Code — Checklist de Qualidade para Tarefas de Infraestrutura/Deploy

*Aplicável apenas às tarefas desta lista que envolvem infraestrutura, pipelines,
containers ou deploy. Marcar como concluída somente após validar cada item
relevante ao artefato entregue pela tarefa.*

- [ ] Sem segredo hardcoded (usa variável, cofre de segredos ou secret do CI)
- [ ] Recurso provisionado 100% via IaC (nenhuma criação/alteração manual via
      console/CLI); framework usado é **Terraform**, ou a exceção (CDK/Bicep/
      Deployment Manager) está justificada no Architecture Decision Log do
      `plan.md`
- [ ] Versões fixadas (imagem base, action, provider) — sem `latest` implícito
- [ ] Permissões seguem least privilege (sem role ampla sem justificativa)
- [ ] Health checks / readiness-liveness definidos, quando aplicável
- [ ] Build multi-stage, quando aplicável (Docker)
- [ ] Testado localmente ou via `plan`/dry-run antes do merge
- [ ] Documentação/README do módulo ou serviço atualizada, se o contrato mudou
