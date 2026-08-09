# Grafo de Plataforma — `<Cliente/Tenant>`

> Gerado/mantido a partir de `platform-graph.yaml`. Não editar os diagramas
> aqui sem atualizar o `.yaml` correspondente — este arquivo é a versão legível
> por humanos, o `.yaml` é a fonte de verdade estrutural.

## Visão por Nuvem/Domínio

```mermaid
flowchart TB
    subgraph Azure
        AZ_HUB["azure-hub-network<br/>iac_status: parcial"]
    end

    subgraph M365
        M365_CA["m365-conditional-access-baseline<br/>iac_status: não iniciado"]
    end

    subgraph AWS
        AWS_TBD["(adicionar superfícies AWS)"]
    end

    subgraph GCP
        GCP_TBD["(adicionar superfícies GCP)"]
    end

    subgraph GWS["Google Workspace"]
        GWS_TBD["(adicionar superfícies GWS)"]
    end

    subgraph D365["Dynamics 365"]
        D365_TBD["(adicionar superfícies D365)"]
    end
```

## Visão por Dependência (Workload → Superfície de Plataforma)

```mermaid
flowchart LR
    WA["workload-repo-a"] --> AZ_HUB["azure-hub-network"]
    WB["workload-repo-b"] --> AZ_HUB
```

> Toda seta aqui deve corresponder a um item declarado no `impact-map.md` do
> repositório de workload correspondente ("Impacto em superfície de
> plataforma compartilhada"). Se um workload depende de uma superfície e essa
> dependência não está sinalizada nos dois lados, o grafo está desatualizado.

## Status de Cobertura IaC (resumo)

| Superfície | Nuvem | Status | Ferramenta de reconciliação | Última verificação diff-zero |
|---|---|---|---|---|
| azure-hub-network | Azure | parcial | `terraform plan` | YYYY-MM-DD (diff pendente) |
| m365-conditional-access-baseline | M365 | não iniciado | `Test-M365DSCConfiguration` | — |

## Sistemas Legados (referenciados, ainda sem projeto próprio)

| Sistema | Ambiente | Tem Terraform? | Schema registrado? | Projeto responsável |
|---|---|---|---|---|
| `<sistema-legado-exemplo>` | prod | Não | Ver `db-schema-registry.md` | Nenhum ainda |

> Quando um sistema legado desta lista precisar de mudança real, **nasce um
> repositório de projeto novo** para ele — a coluna "Projeto responsável" é
> atualizada aqui assim que isso acontecer.
