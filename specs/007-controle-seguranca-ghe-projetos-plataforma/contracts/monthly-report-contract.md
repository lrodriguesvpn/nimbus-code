# Contract: Relatório Mensal de Conformidade

**Feature**: `007-controle-seguranca-ghe-projetos-plataforma`

## Formato de publicação

Uma Issue mensal (ou comentário de resumo, decisão de implementação em `/speckit-tasks`) com o título:

```
Relatório de Conformidade de Segurança — {mes_referencia}
```

## Corpo obrigatório

```markdown
## Relatório de Conformidade — {mes_referencia}

**Total de repositórios avaliados**: {total_repos}
**Execuções realizadas no mês**: {n_execucoes} / {n_execucoes_esperadas}

### Conformidade por controle

| Controle | % conforme | Δ vs. mês anterior |
|---|---|---|
| Branch protection | {pct}% | {delta} |
| Revisão obrigatória | {pct}% | {delta} |
| Permissões de Actions | {pct}% | {delta} |
| Secrets configurados | {pct}% | {delta} |
| Matriz de acesso do Projeto Plataforma | {pct}% | {delta} |

### Desvios abertos ao final do mês

| Repo | Controle | Aberto desde | Issue |
|---|---|---|---|
| {repo} | {controle} | {data} | {link} |

### Desvios corrigidos no mês

| Repo | Controle | Aberto em | Fechado em | Issue |
|---|---|---|---|---|
| {repo} | {controle} | {data} | {data} | {link} |

---
_Gerado a partir de {n_execucoes} execuções semanais de `security-compliance-scan.yml`._
```

> **Issue #450**: a tabela "Conformidade por controle" lista **todos** os
> controles de `CONTROL_ORDER` em `scripts/security-compliance-scan.sh` (18
> controles de repositório + Projeto Plataforma). Controle sem avaliação no
> mês aparece como `N/A (não avaliado)` — nunca 0% ou 100% inventado.

## Critério de aceite

- O relatório **deve** existir mensalmente mesmo quando todos os repositórios estão em conformidade (relatório "vazio" de desvios ainda é gerado, evidenciando que a varredura rodou).
- Usado para medir **SC-004** (redução de falhas operacionais por secret/token ausente) comparando a série histórica de `% conforme` do controle "Secrets configurados" mês a mês.
