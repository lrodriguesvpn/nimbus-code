# Contract: Finding e Issue de Não Conformidade

**Feature**: `007-controle-seguranca-ghe-projetos-plataforma`

## Schema do Finding (payload interno do script, JSON)

```jsonc
{
  "id": "security-baseline:venha-pra-nuvem/exemplo-repo:branch-protection",
  "repo": "venha-pra-nuvem/exemplo-repo",
  "controle_id": "branch-protection",
  "status": "risco",              // "ok" | "pendente" | "risco"
  "timestamp": "2026-08-19T13:00:00Z",
  "evidencia": "GET /repos/{owner}/{repo}/branches/main/protection -> 404 (não configurado)",
  "issue_url": null                 // preenchido após criação/atualização da issue
}
```

## Regras de validação do schema

- `id` é **sempre** `security-baseline:{repo}:{controle_id}` — chave de deduplicação.
- `status` é um enum fechado: `ok` | `pendente` | `risco`. Qualquer outro valor é erro de contrato.
- `status != "ok"` **exige** que, ao final da execução, `issue_url` esteja preenchido.
- `evidencia` deve ser texto suficiente para um humano validar sem precisar re-executar a consulta (ex.: incluir o endpoint e o resultado observado).

## Template da Issue de não conformidade

```markdown
## 🔴 Não conformidade de segurança — {controle_nome}

**Repositório**: {repo}
**Controle**: {controle_id} — {controle_nome}
**Status**: {status}
**Detectado em**: {timestamp}
**Evidência**: {evidencia}

<!-- security-baseline-finding-id: {id} -->

### O que fazer

{instrucao_de_correcao_especifica_do_controle}

### Critério de validação da correção

A próxima execução semanal da varredura (`security-compliance-scan.yml`) deve
reportar `status: ok` para este controle neste repositório. Esta issue será
fechada automaticamente quando isso ocorrer (ou deve ser fechada manualmente
após validação).

---
_Gerado automaticamente pela varredura semanal de conformidade de segurança —
ver [docs/security-baseline-ghe.md](/docs/security-baseline-ghe.md)._
```

**Labels aplicadas**: `security-baseline`, prioridade conforme severidade do controle (`priority:P0-blocker` se `bloqueante=true`, `priority:P2-medium` caso contrário) — usa a taxonomia de labels já existente (`docs/label-taxonomy-and-autonomous-dev.md`), sem criar taxonomia paralela.

**Deduplicação**: antes de criar, o script busca por uma issue aberta contendo o marcador HTML `<!-- security-baseline-finding-id: {id} -->` no corpo — se encontrar, atualiza em vez de criar (reaproveita o padrão `speckit-deduplication-by-id` do `docs/reuse-catalog.yaml`).
