# Inventário As-Is — `<Cliente/Tenant>`

> Auditoria de tudo que existe hoje, por nuvem/domínio, antes de qualquer
> tentativa de scriptar/Terraformar. Preencher **antes** de rodar qualquer
> ferramenta de importação (`aztfexport`, `terraformer`, exportação
> M365DSC/GAM/`pac`). Este arquivo é somente-leitura em relação ao ambiente —
> nunca a fonte de uma mudança.

## Como usar

1. Para cada nuvem/domínio marcado na constituição, listar os recursos/áreas
   conhecidas (mesmo que de forma grosseira no início — refinar depois).
2. Marcar honestamente a coluna "Hoje é IaC?" — não marcar "sim" sem uma
   verificação de zero-diff já feita (ver `platform-graph.yaml`).
3. Priorizar o que scriptar primeiro pelo cruzamento de **criticidade alta +
   ainda não é IaC** — não necessariamente pelo que é "mais fácil".

## Azure

| Recurso | Ambiente | Hoje é IaC? | Ferramenta usada hoje | Criticidade | Dono | Prioridade de scriptar |
|---|---|---|---|---|---|---|
| [ex.: rg-prod-network] | prod | Não | ClickOps | Alta | [nome/time] | P1 |

## AWS

| Recurso | Ambiente | Hoje é IaC? | Ferramenta usada hoje | Criticidade | Dono | Prioridade de scriptar |
|---|---|---|---|---|---|---|
| | | | | | | |

## GCP

| Recurso | Ambiente | Hoje é IaC? | Ferramenta usada hoje | Criticidade | Dono | Prioridade de scriptar |
|---|---|---|---|---|---|---|
| | | | | | | |

## Google Workspace (GWS)

| Recurso (OU, grupo, política) | Hoje é IaC/script? | Ferramenta usada hoje | Criticidade | Dono | Prioridade |
|---|---|---|---|---|---|
| | | | | | |

## Microsoft 365 (M365)

| Recurso (Conditional Access, DLP, retenção, Teams policy) | Hoje é config-as-code? | Ferramenta usada hoje | Criticidade | Dono | Prioridade |
|---|---|---|---|---|---|
| | | | | | |

## Dynamics 365 (D365) / Power Platform

| Ambiente/Solution | Hoje é versionado (`pac solution unpack`)? | Criticidade | Dono | Prioridade |
|---|---|---|---|---|
| | | | | |

## Sistemas Legados com Banco de Dados

*Todo item aqui deve ter uma linha correspondente em `db-schema-registry.md`.*

| Sistema | Engine (SQL Server/Postgres/MySQL/Oracle) | Ambiente | Schema extraído? | Criticidade |
|---|---|---|---|---|
| | | | | |

## Critério de "Quando Scriptar Primeiro"

Priorizar nesta ordem:
1. Criticidade alta **e** sem qualquer forma de IaC/config-as-code hoje.
2. Recursos compartilhados por múltiplos projetos/workloads (superfícies de
   plataforma) — impacto de um erro é maior.
3. Recursos com histórico de incidentes (`type:incident`) — reduzir MTTR
   futuro documentando o estado real primeiro.
4. Todo o resto, por ordem de criticidade.
