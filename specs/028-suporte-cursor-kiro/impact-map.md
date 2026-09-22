# Impact Map & Risk Analysis: Suporte a Cursor e Kiro (Feature 028)

## 1. Dependency Impact Analysis

| Módulo/artefato afetado | Tipo de mudança | Impacto |
|---|---|---|
| `scripts/lib/nc-agent-sync.py` | Refatorado (`AGENTS` hardcoded → glob) + estendido (2 novos alvos) | Afeta os 5 alvos, não só os 2 novos — risco médio de regressão nos 3 já existentes |
| `scripts/sync-nc-agents-to-integrations.sh` | Refatorado (`EXTRA_SPECKIT_SKILLS` hardcoded → glob) + estendido | Mesmo risco do item acima |
| `tests/multi-agent-integration/nc-agents-parity.bats` | Estendido | Deve continuar cobrindo os 3 alvos antigos sem quebrar, mais os 2 novos |
| `tests/multi-agent-integration/nc-agent-foundation.bats` | Estendido (novo caso de contagem dinâmica) | Baixo risco — teste aditivo |
| `.github/workflows/nc-agents-parity-check.yml` | Estendido (paths de trigger) | Baixo risco — apenas adiciona paths, não remove |
| `docs/developer-guide.md` | Estendido | Sem risco técnico — documental |
| `.claude/skills/nc-bug-*`, `.agents/skills/nc-bug-*` | **Criados como efeito colateral** (não existiam antes) | Efeito colateral aprovado explicitamente pelo usuário — deve ser destacado no PR |

## 2. Risk Assessment Matrix

| Risk | Probability | Impact | Severity | Mitigation |
|---|---|---|---|---|
| **Descoberta dinâmica quebra os 3 alvos existentes** (vscode/claude/antigravity deixam de gerar corretamente) | Medium | High | **High** | (1) Rodar suíte completa `nc-agents-parity.bats` antes/depois da refatoração; (2) Comparar hash funcional de cada agente pré/pós mudança para os 3 alvos antigos, não só verificar "passou" |
| **Efeito colateral (`nc-bug-*` sincronizado) surpreende revisores do PR** | Medium | Low | **Medium** | Destacar explicitamente na descrição do PR e no `tasks.md`, não deixar como diff "escondido" entre centenas de linhas |
| **Formato `.kiro/agents/` divergir da documentação oficial na prática** (docs podem estar desatualizadas) | Low | Medium | **Medium** | Validar manualmente com o CLI do Kiro instalado antes de considerar a feature "pronta", não confiar apenas na doc |
| **Cursor introduzir mecanismo de "custom agent" nativo no futuro, tornando `.cursor/skills/` obsoleto** | Low | Low | **Low** | Decisão registrada no ADL como "melhor evidência disponível hoje"; reavaliar em spec futura se Cursor lançar tal mecanismo |
| **Kiro exigir versão mínima de CLI em atualização futura do `specify`** | Low | Medium | **Low** | FR-009 já prevê comunicação clara de qualquer pré-requisito detectado; não é uma suposição rígida |

---

## 3. Rollback Plan

### Scenario: Regressão nos 3 alvos existentes após refatoração da descoberta

**Trigger Conditions**:
- `nc-agents-parity.bats` falha para `vscode`, `claude` ou `antigravity` após a mudança
- Hash funcional de qualquer agente NC-* muda inesperadamente nos alvos já existentes

**Rollback Steps** (estimativa: 10 min):
1. Reverter o PR desta feature.
2. Confirmar que `python3 scripts/lib/nc-agent-sync.py check --target all` e
   `bash scripts/sync-nc-agents-to-integrations.sh --check --target all`
   voltam a passar no estado anterior.
3. Reabrir a fase de plano com um desenho mais conservador (ex.: descoberta
   dinâmica isolada só para os 2 novos alvos, mantendo hardcoded nos 3
   antigos) se o risco se confirmar real.

## 4. Release Strategy & Staged Rollout

| Fase | Escopo |
|---|---|
| Fase 1 | Refatorar descoberta dinâmica (`dynamic-agent-discovery`, `extra-speckit-discovery`), validando que os 3 alvos existentes continuam idênticos |
| Fase 2 | Adicionar renderização para Cursor (`cursor-target-renderer`, `cursor-extra-skills-sync`) |
| Fase 3 | Adicionar renderização para Kiro (`kiro-target-renderer`, `kiro-extra-skills-sync`) |
| Fase 4 | Estender testes de paridade e CI para os 5 alvos |
| Fase 5 | Atualizar `docs/developer-guide.md` |

## 5. Data Integrity & State Management

- Não há dados persistentes/estado além dos arquivos versionados em Git — não
  aplicável no sentido de banco de dados, mas a integridade do **conteúdo
  funcional sincronizado** (hash normalizado, ignorando frontmatter/pós-
  processamento) é o equivalente de "integridade de dados" nesta feature.
- A mudança de `EXPECTED_AGENTS`/`AGENTS` hardcoded para glob MUST preservar
  exatamente o mesmo conjunto de arquivos gerados para os 3 alvos já
  existentes, mais os agentes `nc-bug-*` que passam a ser incluídos — nunca
  deve haver remoção de um agente antes gerado.

## 6. Critical Path & Success Milestones

1. Descoberta dinâmica implementada e validada sem regressão nos 3 alvos existentes.
2. Cursor gera os agentes NC-* corretamente, com contrato de frontmatter validado.
3. Kiro gera os agentes NC-* no mecanismo nativo `.kiro/agents/`, com contrato validado.
4. Teste de paridade cobre os 5 alvos e falha bloqueante em drift simulado.
5. CI atualizado e verde.
6. `docs/developer-guide.md` atualizado.

## 7. Blast Radius & Affected Systems

| Sistema | Afetado diretamente? | Como |
|---|---|---|
| `scripts/lib/nc-agent-sync.py` | Sim | Refatoração de descoberta + 2 novos alvos |
| `scripts/sync-nc-agents-to-integrations.sh` | Sim | Refatoração de descoberta + 2 novos alvos |
| `.claude/skills/`, `.agents/skills/` | Sim (efeito colateral) | Ganham `nc-bug-*`/`speckit-bug-*` pela primeira vez |
| `.cursor/skills/`, `.kiro/agents/`, `.kiro/prompts/` | Sim (novo) | Criados pela primeira vez |
| `.github/agents/` (VS Code) | Não deve mudar | Regressão explicitamente testada (AC-6) |
| CI (`nc-agents-parity-check.yml`) | Sim | Novos paths de trigger, mesma lógica de execução |

## 8. Cost & Effort Tracking

| Campo | Valor |
|---|---|
| Estimativa de tokens | ~35–50 mil |
| Estimativa de horas humanas | ~3–6 horas |

## 9. Success Metrics

Ver seção "Operational Metrics Gate" em [plan.md](./plan.md) — SC-001 a SC-005.

## 10. Post-Implementation Validation Checklist

- [ ] `bash scripts/sync-nc-agents-to-integrations.sh --check --target all` passa (5 alvos, se o `--target all` for estendido para incluir cursor/kiro)
- [ ] `python3 scripts/lib/nc-agent-sync.py check --target all` passa (5 alvos)
- [ ] `bats tests/multi-agent-integration/*.bats` 100% verde
- [ ] Diff do PR destaca explicitamente a criação de `.claude/skills/nc-bug-*` e `.agents/skills/nc-bug-*` como efeito colateral intencional
- [ ] Validação manual com Cursor e/ou Kiro instalados localmente (não apenas testes automatizados com fixtures)
- [ ] `docs/developer-guide.md` revisado por um humano antes do merge
- [ ] `docs/reuse-catalog.yaml`: incrementar `reuse_count` de `single-source-multi-target-sync` para 1

## References

- [spec.md](./spec.md)
- [plan.md](./plan.md)
- [graph.yaml](./graph.yaml) / [graph.md](./graph.md)
- `docs/harness/harness-catalog.yaml` — HRN-0002, HRN-0003, HRN-0006
- `docs/reuse-catalog.yaml` — `single-source-multi-target-sync`
