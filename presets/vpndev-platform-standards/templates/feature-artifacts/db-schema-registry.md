# Registro de Schemas de Bancos de Dados — `<Cliente/Tenant>`

> Catálogo dos schemas (DDL, **sem dados**) de todo banco de dados de sistema
> legado listado no `legacy-inventory.md`. A extração é sempre somente-leitura
> — este repositório nunca aplica migração de schema. Mudança real de schema
> nasce em um repositório de projeto (workload).

## Como extrair (referência rápida por engine)

| Engine | Comando de extração (somente schema, sem dados) |
|---|---|
| PostgreSQL | `pg_dump --schema-only --no-owner --no-privileges <db> > schema.sql` |
| MySQL / MariaDB | `mysqldump --no-data --routines --triggers <db> > schema.sql` |
| SQL Server | `SqlPackage /Action:Extract /SourceConnectionString:"..." /TargetFile:schema.dacpac` |
| Oracle | `expdp ... content=metadata_only` ou DDL via `dbms_metadata.get_ddl` |

Salvar o arquivo em `schemas/<sistema>/<banco>/schema.sql` (ou `.dacpac`) neste
repositório, versionado normalmente via Pull Request.

## Catálogo

| Sistema | Banco | Engine | Ambiente | Caminho do arquivo versionado | Última extração | Diff-zero confirmado? | Sistema(s) que usam |
|---|---|---|---|---|---|---|---|
| [ex.: ERP Legado] | `erp_prod` | SQL Server | prod | `schemas/erp-legado/erp_prod/schema.dacpac` | YYYY-MM-DD | Não | [lista de sistemas/apps consumidores] |

## Regras

- **Nunca** incluir dados (linhas/registros) — apenas estrutura (DDL): tabelas,
  colunas, constraints, índices, views, procedures/functions se aplicável.
- Toda extração deve ser re-executada e comparada (diff) sempre que houver
  suspeita de mudança no sistema de origem — não confiar em "extraído uma vez
  e nunca mais verificado".
- Schema sem confirmação de diff-zero permanece com status implícito
  `iac_status: parcial` para fins do `platform-graph.yaml` — mesma regra de
  qualquer outro recurso de plataforma.
- Se um projeto nascer para alterar o schema de um destes sistemas, o schema
  atualizado (pós-mudança) deve ser re-extraído e sincronizado de volta aqui
  como parte do fechamento daquele projeto — este catálogo nunca fica
  desatualizado silenciosamente.
