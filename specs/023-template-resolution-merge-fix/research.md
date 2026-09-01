# Research: Correção da Composição Real de Templates

## Decision 1 — Corrigir os 3 call sites em vez de reescrever `resolve_template_content()`

**Decision**: manter `resolve_template_content()` como está e corrigir apenas os consumidores reais: `create-new-feature.sh`, `setup-plan.sh` e `setup-tasks.sh`.

**Rationale**: a função já implementa a composição correta de camadas; o bug está nos call sites que ainda pedem apenas um caminho bruto via `resolve_template()`. Reescrever a função correta aumentaria o risco sem atacar a causa raiz.

**Alternatives considered**:
- Reimplementar a composição dentro de cada script — descartado por duplicação.
- Alterar `resolve_template_content()` — descartado porque o comportamento já está correto.

## Decision 2 — Não invocar a CLI externa `specify` a cada resolução

**Decision**: não chamar a CLI oficial `specify` durante cada geração de arquivo.

**Rationale**: a CLI externa já serve como referência de semântica, mas adicionaria dependência e custo desnecessários no fluxo normal dos scripts. A implementação local já contém a lógica de composição; o objetivo é reaproveitá-la.

**Alternatives considered**:
- Delegar toda resolução para a CLI externa — descartado por acoplamento e latência.
- Fazer um round-trip por template resolvido — descartado por custo e fragilidade operacional.

## Decision 3 — Materializar `tasks-template` em arquivo temporário preservando o contrato de caminho

**Decision**: `setup-tasks.sh` deve gravar o conteúdo composto em um arquivo temporário absoluto e continuar retornando `TASKS_TEMPLATE` como caminho de arquivo.

**Rationale**: o contrato atual é consumido pela skill `speckit-tasks` como um path. Mudar para string crua quebraria o fluxo. Materializar em arquivo mantém a interface estável e permite ler o conteúdo já composto sem reescrever a skill.

**Alternatives considered**:
- Retornar o conteúdo bruto em JSON — descartado por quebrar o contrato.
- Escrever em arquivo fixo no repositório — descartado para não poluir o worktree.
