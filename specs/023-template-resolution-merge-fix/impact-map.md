# Impacto da remediação — SPEC 023

Remediação S3 autorizada em 2026-09-20; release continua sujeito à issue #448.

| Superfície | Impacto | Proteção / validação |
|---|---|---|
| Resolução de templates | Conteúdo composto e frontmatter | Testes das quatro estratégias, camadas e erros |
| Consumidores Bash | Arquivos gerados e caminho JSON | CLI real em fixture, comparação byte a byte |
| Bootstrap novo | Overlay dos scripts do bundle | Fixture greenfield, sem chamada externa real |
| Atualização | Artefatos gerenciados e versão | Hashes, preflight de conflitos, preservação de dados locais |
| Satélites | Recebem alterações somente via atualização explícita | PR revisado; automação opt-in/piloto #433/#445 |
| CI | Testes internos passam a integrar gate | Mesma execução local e CI |

Não altera autenticação, infraestrutura ou dados de aplicação. Não migra
automaticamente arquivos legados sem baseline de integridade. Conflitos devem
ser reconciliados por humano e não tratados como atualização bem-sucedida.
Rollback: reverter o PR e reaplicar versão aprovada do bundle após revisão.
