# Impact Map — Feature 025: Native NC Agents

## Impactos

| Area | Impacto | Risco | Mitigacao |
|---|---|---|---|
| Fonte `.github/skills/nc-*` | Continua como bridge e fonte de conteúdo | Drift sem manifesto | Gerador read-only + gate |
| `.github/agents` | Nova superficie de agentes VS Code/Copilot | Frontmatter incompatível | Fixture e validação de contrato |
| `.claude/agents` | Nova superficie de subagents Claude | Perda de permissões/gates | Comparação com manifesto |
| `.agents/skills` | Adaptador Antigravity suportado | Formato nativo não confirmado | Não inventar `.agents/agents`; bloquear em contrato ausente |
| Fluxo `/nc-*` | Compatibilidade durante transição | Remoção prematura | AC-4 e depreciação explícita |
| CI/paridade | Gate bloqueante | Falsos positivos ou arquivos órfãos | Hash funcional + lista derivada da fonte |

## Go / No-Go

### Go

- Contratos nativos de VS Code e Claude confirmados.
- Contrato suportado do Antigravity documentado ou bridge mantido.
- Manifesto, gerador, fixtures e gate de paridade verdes.
- Comandos `/nc-*` continuam funcionando.

### No-Go

- Criar `.agents/agents/` sem contrato oficial.
- Perder `allowed_file_scope`, `tool_allowlist` ou gates.
- Remover bridges sem aprovação humana separada.
- Aceitar drift como sucesso.

## Rollback

Reverter apenas os adaptadores gerados e o gerador; preservar `.github/skills/nc-*`
e os comandos bridge. A retirada futura dos bridges exige uma mudança independente.
