# research.md — Feature 001: Catálogo de Conteúdo Reutilizável

> **Nota histórica**: este arquivo é gerado retroativamente. O escopo desta
> feature já foi aprovado e implementado diretamente (ver banner no topo de
> `spec.md`), sem passar formalmente por `/speckit-plan`/`/speckit-tasks` — a
> aprovação em conversa ("Pode seguir vamos usar suas sugestões") autorizou a
> execução direta das 3 perguntas em aberto do `spec.md`. Este documento
> registra, no formato Decision/Rationale/Alternatives padrão do Spec Kit, as
> respostas que já estavam registradas em prosa na seção "Atualização" do
> `spec.md`, para completar o registro histórico do ciclo de planejamento.

## Perguntas em Aberto resolvidas

### 1. O catálogo de reuso deve viver no bundle `vpndev-standards` (hoje `nimbus-code-standards`) ou ser uma extensão opcional separada?

- **Decision**: Vive no preset `nimbus-code-standards` (aplicado a todo projeto
  consumidor via `bootstrap.sh`), não como extensão opcional separada.
- **Rationale**: O catálogo de reuso é um mecanismo de redução de custo de
  tokens aplicável a qualquer feature, em qualquer bounded context — não é um
  caso de uso especial que justifique ficar fora do preset padrão (diferente,
  por exemplo, de uma integração específica com um sistema externo, que faria
  sentido como extensão). Manter no preset garante que todo repositório novo já
  nasça com o arquivo `docs/reuse-catalog.yaml` presente.
- **Alternatives considered**: Extensão separada (ex.: `nimbus-code-backlog-sync`)
  — rejeitada porque criaria um passo de instalação opcional extra para um
  mecanismo que deveria ser universal, e fragmentaria a governança de conteúdo
  reutilizável em dois lugares (preset + extensão) sem benefício claro.

### 2. O preenchimento do catálogo deve ser manual (curadoria humana periódica) ou parte do checklist de fechamento do `tasks.md` desde o início?

- **Decision**: Manual/curatorial desde o início. Automação de preenchimento
  fica fora de escopo desta fase (ver seção "Fora de Escopo" do `spec.md`).
- **Rationale**: Sem um corpus mínimo de specs/ADRs já existentes, uma
  automação de indexação (ex.: um workflow que atualiza `reuse-catalog.yaml`
  sozinho ao fechar `/speckit-tasks`) arriscaria criar entradas de baixa
  qualidade ou duplicadas antes de o padrão de curadoria humana estar validado
  na prática. A curadoria manual valida o formato/schema do catálogo com baixo
  risco antes de se investir em automação.
- **Alternatives considered**: Automação completa desde o dia 1 — rejeitada
  por prematura (mesmo racional do item "RAG/índice semântico" nas Fora de
  Escopo do `spec.md`: adiar infraestrutura até o corpus justificar o
  investimento).

### 3. Vale a pena reservar um campo `reuse_tags` em `graph.yaml` agora, mesmo antes do catálogo existir?

- **Decision**: Não adicionar o campo agora.
- **Rationale**: O catálogo (`docs/reuse-catalog.yaml`) já cobre o caso de uso
  de indexação por tag/bounded-context/padrão técnico na granularidade de
  "padrão reutilizável", sem exigir uma mudança de schema em `graph.yaml`
  (que opera na granularidade de "módulo por feature"). Adicionar um campo
  redundante antes de uma necessidade concreta violaria o próprio princípio de
  não introduzir complexidade especulativa.
- **Alternatives considered**: Adicionar `reuse_tags: []` em todo `graph.yaml`
  desde já — rejeitada; pode ser revisitada se, na prática, a granularidade por
  feature se mostrar necessária além da granularidade por padrão/tag já
  coberta pelo catálogo.

## Validação retroativa (evidência de que o escopo foi de fato entregue)

Verificado nesta sessão, diretamente no repositório (2026-08-20):

| Item do Escopo (spec.md) | Onde vive hoje | Confirmado |
|---|---|---|
| Princípio "referenciar por ponteiro, não por valor" | `.specify/memory/constitution.md`, seção "Reutilização de Conteúdo e Referência por Ponteiro" (linha ~105) | ✅ |
| Catálogo de reuso `docs/reuse-catalog.yaml` | Raiz do repo; instalado via `bootstrap.sh` em projetos consumidores | ✅ (em uso ativo — features 005, 007, 008 já referenciam entradas) |
| TL;DR / resumo no topo de docs longos | `docs/ai-code-quality-and-observability.md` e equivalentes | ✅ |
| Campo "Padrão reutilizado encontrado?" na Classificação de Complexidade | `presets/nimbus-code-standards/templates/plan-template.md`, `.github/copilot-instructions.md` | ✅ (presente em todos os `plan.md` de features 002+) |

**Output**: Nenhuma pergunta [NEEDS CLARIFICATION] permanece em aberto — as 3
originais do `spec.md` foram resolvidas e implementadas, conforme registrado
acima.
