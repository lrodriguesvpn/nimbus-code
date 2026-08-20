# research.md — Feature 012: Loop de Melhoria Contínua Nimbus-Code

## Decisões Técnicas (Phase 0)

### 1. Estrutura do catálogo de sucesso: arquivo irmão vs. campo `type` no harness-catalog.yaml

- **Decision**: Arquivo irmão separado, `docs/playbooks/success-catalog.yaml`,
  em vez de estender `docs/harness/harness-catalog.yaml` com um campo
  `type: success|error`.
- **Rationale**: Harness e Playbook de Sucesso são consultados em momentos e
  com intenções diferentes — harness é consultado para **evitar repetir um
  erro**, playbook é consultado para **reaplicar uma abordagem que funcionou**.
  Misturar os dois no mesmo arquivo obrigaria toda consulta a filtrar por
  `type`, aumentando a chance de um agente trazer contexto de erro quando só
  queria sucesso (ou vice-versa) — exatamente o tipo de ambiguidade que os
  dois gates (Harness Gate e Playbook de Sucesso Gate) do `plan-template.md`
  tentam evitar ao serem seções distintas e obrigatórias separadamente.
- **Alternatives considered**: Campo `type` único — rejeitada pelo motivo
  acima; um terceiro arquivo unificado de "todas as lições" com metadado rico
  — rejeitada por complexidade desnecessária nesta fase (mesmo racional de
  "Fora de Escopo" do `spec.md`: nenhuma automação de indexação/RAG ainda).

### 2. Fonte dos indicadores DORA: ferramenta externa vs. cálculo local via `gh` CLI

- **Decision**: Cálculo local via `gh api`/`gh issue list`/`gh pr list`,
  agregando por `dora:*` label e por data de merge/close — sem ferramenta
  externa de observabilidade de engenharia.
- **Rationale**: Os labels já existem desde a feature 002 e já são aplicados
  manualmente; o gap não é "captura de dado", é "nunca ser lido de volta".
  Um script CLI simples fecha esse gap sem exigir orçamento/integração nova.
  Consistente com o racional já usado nas features 001 e 011 ("sem
  infraestrutura adicional até o corpus/necessidade justificar").
- **Alternatives considered**: Dashboard de engineering metrics dedicado
  (ex.: LinearB, Faros, Swarmia) — rejeitado como prematuro; pode ser
  revisitado se o volume de repositórios da org crescer o suficiente para
  justificar consolidação cross-repo (nota: `scripts/pmo-cost-rollup.sh` já
  existe para consolidar custo entre repos — um script de DORA rollup
  análogo seria o próximo passo natural, fora de escopo aqui).

### 3. Cadência de retrospectiva proativa: calendário vs. contagem de features

- **Decision**: Cadência por número de features concluídas (N configurável
  no `plan.md`, valor inicial sugerido: N=5), não por data calendário fixa.
- **Rationale**: Uma cadência calendário (ex.: "toda sexta-feira") gera
  retrospectivas vazias em períodos de baixa atividade e atrasa retrospectivas
  necessárias em períodos de alta atividade. Contagem por features concluídas
  acompanha o ritmo real de entrega — mais relevante para capturar
  aprendizado enquanto o contexto ainda está fresco.
- **Alternatives considered**: Cadência calendário fixa — rejeitada pelo
  motivo acima; cadência híbrida (o que vier primeiro, tempo ou contagem) —
  considerada mas adiada para não aumentar a complexidade de configuração
  logo na primeira versão; pode ser revisitada com dado real de uso.

## Validação de dependências (evidência de que os precedentes existem)

Verificado nesta sessão, diretamente no repositório (2026-08-20):

| Dependência | Onde vive | Confirmado |
|---|---|---|
| `docs/harness/harness-catalog.yaml` (padrão estrutural a espelhar) | Feature 011 (PR #139, aguardando merge) | ✅ |
| Labels `dora:*` já aplicáveis | `scripts/setup-github-labels.sh` | ✅ (já existem desde a feature 002) |
| `retro-template.md` referenciado no checklist de fechamento | `presets/nimbus-code-standards/templates/tasks-template.md` | ✅ |
| `docs/reuse-catalog.yaml` (para registrar o padrão desta feature) | Feature 001 | ✅ |

**Output**: Nenhuma pergunta [NEEDS CLARIFICATION] pendente — `spec.md` já
fechou as 3 decisões relevantes nas Assumptions; este documento apenas
formaliza o racional de cada uma no formato Decision/Rationale/Alternatives.
