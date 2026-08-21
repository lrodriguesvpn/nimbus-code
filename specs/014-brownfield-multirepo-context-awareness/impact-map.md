# Impact Map — Feature 014: Brownfield MultiRepo Context Awareness

**Feature**: `014-brownfield-multirepo-context-awareness` | **Complexidade**: S3 | **Data**: 2026-08-21

---

## Componentes Impactados

| Componente | Tipo de Mudança | Risco | Rollback |
|---|---|---|---|
| `scripts/generate-context-graph.sh` | Novo arquivo | Baixo — arquivo adicional, não substitui nada | Remover o arquivo |
| `scripts/harvest-patterns.sh` | Novo arquivo | Baixo — on-demand apenas, sem CI automático | Remover o arquivo |
| `.github/workflows/context-graph-refresh.yml` | Novo workflow | Baixo — só roda quando `bounded-contexts.yaml` muda | Remover o arquivo ou desativar o workflow |
| `.github/skills/speckit-specify/SKILL.md` | Modificação incremental | Médio — altera instrução de fluxo do agente | Reverter a seção adicionada via `git revert` |
| `presets/.../copilot-instructions.md` | Modificação incremental | Baixo — adiciona passo, não remove nem altera existentes | Reverter a seção adicionada |
| `presets/.../plan-template.md` | Modificação incremental | Baixo — adiciona seção opcional, não altera estrutura existente | Reverter a seção adicionada |
| `docs/module-graphs.md` | Modificação incremental | Baixo — documentação pura | Reverter |
| `docs/reuse-catalog.yaml` | Modificado pelo harvest on-demand | Baixo — alterado apenas quando Dev executa o script | `git checkout docs/reuse-catalog.yaml` |

---

## Análise de Dependências Indiretas

| Dependência | Direção | Impacto se falhar |
|---|---|---|
| `docs/bounded-contexts.yaml` (feature 006) | Upstream | `generate-context-graph.sh` não consegue resolver repos; emite erro claro e não gera grafo — fluxo de spec prossegue com aviso (AC-5) |
| GHE API (`gh api`) | Externo | `generate-context-graph.sh` não consegue analisar repos sem clone; documenta repos não analisados e continua com os disponíveis (AC-6) |
| LLM API (`HARVEST_API_URL`) | Externo | `harvest-patterns.sh` aborta com mensagem de erro e instrução de verificar env vars — não corrompe o catálogo |
| `yq` / `python3` | Externo | Fallback progressivo; se ambos ausentes, emite instrução de instalação e pula parsing YAML — comportamento seguro e explícito |
| `speckit-specify` SKILL.md | Downstream | Se o agente não seguir a instrução atualizada, o grafo não é gerado automaticamente — mas o Dev pode rodar `generate-context-graph.sh` manualmente sem perda de funcionalidade |

---

## Plano de Rollback

**Condição de rollback**: qualquer um dos critérios abaixo:
1. `speckit-specify` quebra para features existentes (retrocompatibilidade violada)
2. `harvest-patterns.sh` envia código-fonte completo para a LLM API (violação de privacidade)
3. `context-graph-refresh.yml` falha em toda PR sem fallback visível

**Procedimento**:

```bash
# Rollback completo: reverter o PR desta feature
git revert <sha-do-merge-commit>
git push origin main
```

**Rollback parcial** (desativar apenas harvest sem afetar o restante):
```bash
rm scripts/harvest-patterns.sh
rm scripts/tests/harvest-patterns.bats
# Não há dependência de outros componentes nesta feature com harvest-patterns.sh
```

**Rollback parcial** (desativar apenas CI refresh):
- Desativar o workflow `context-graph-refresh.yml` via GitHub Actions UI ou remover o arquivo.
- `generate-context-graph.sh` continua disponível para execução on-demand.

---

## Critérios Go / No-Go

### Go (pode fazer merge)
- [ ] AC-1: `generate-context-graph.sh` gera `graph.yaml` + `graph.md` válidos para bounded context com ≥2 repos
- [ ] AC-3: `harvest-patterns.sh` produz ≥1 entrada válida para repo Java com interfaces em pacotes de domínio
- [ ] AC-5: bounded context sem repos → aviso + prossegue (sem exceção não tratada)
- [ ] AC-6: fallback via `gh api` documentado e testado com mock
- [ ] AC-governance: `harvest-patterns.sh` não referenciado em nenhum workflow de CI (verificado via `grep`)
- [ ] Retrocompatibilidade: `/speckit-specify` em projeto sem `bounded-contexts.yaml` ou com contexto não mapeado funciona identicamente ao comportamento atual
- [ ] Scan de secrets: nenhum secret em texto plano nos arquivos desta feature

### No-Go (bloqueia merge)
- Qualquer falha silenciosa nos scripts (exit 0 com output incorreto)
- `harvest-patterns.sh` enviando mais do que metadados estruturais para a LLM API
- `context-graph-refresh.yml` rodando `harvest-patterns.sh` (seria CI automático, violação de FR-011)
- Schema `cross_repo: true` quebrando o Graph Guard existente

---

## Estratégia de Validação Pós-Deploy

1. **Imediato (D+0)**: Executar `generate-context-graph.sh spec-kit-workflow` contra o próprio repo template e verificar que `graph.yaml` e `graph.md` são gerados corretamente.
2. **D+1**: Executar `harvest-patterns.sh` apontado para um repo de fixture Java e verificar saída no `reuse-catalog.yaml` via `git diff`.
3. **D+3**: Abrir uma nova spec no bundle usando `/speckit-specify` e verificar que o agente invoca o script automaticamente (AC-2).
4. **D+7**: Alterar `bounded-contexts.yaml` e verificar que o CI `context-graph-refresh.yml` roda e commita os grafos atualizados.
