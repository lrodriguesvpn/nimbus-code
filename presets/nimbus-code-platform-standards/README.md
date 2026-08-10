# nimbus-code-platform-standards (preset)

## Propósito

Aplica os padrões de governança de **plataforma/cliente/ambiente** da Nimbus-Code
sobre os templates nativos do Nimbus Code. É o par complementar do
[`nimbus-code-standards`](../nimbus-code-standards) — mas para um **tipo diferente de
repositório**:

| | `nimbus-code-standards` | `nimbus-code-platform-standards` |
|---|---|---|
| Representa | Um projeto/feature de software | O ambiente real de um cliente/tenant |
| Muda o ambiente? | Sim, via IaC revisado em PR | **Nunca** — somente observação/inventário |
| Unidade de trabalho | Feature de código | Superfície de plataforma / sistema legado |
| Grafo | `graph.yaml` (módulos de código) | `platform-graph.yaml` (superfícies de plataforma) |

Um repositório usa **um dos dois presets, nunca os dois** — se o repositório
representa a infraestrutura/ambiente real de um cliente (contas cloud,
tenants M365/GWS, ambiente D365, sistemas legados), use este preset.

- **`constitution-template.md`** (`wrap`) — regra de nunca aplicar mudança
  direta em ambiente, critério de verdade por zero-diff, cobertura
  multi-nuvem (Azure/AWS/GCP/GWS/M365/D365) e registro de schemas de legado.
- **`plan-template.md`** (`append`) — classificação de ambiente/cliente/nuvem,
  ferramenta de reconciliação por domínio e checklist de zero-diff.
- **`spec-template.md`** (`prepend`) — cabeçalho com cliente/tenant, ambiente
  e classificação de legado.
- **`tasks-template.md`** (`append`) — checklist de fechamento com
  confirmação de que nenhuma mudança foi aplicada diretamente.

**Artefatos de feature (templates):**
- `templates/feature-artifacts/platform-graph.yaml` — grafo estruturado de superfícies de plataforma
- `templates/feature-artifacts/platform-graph.md` — diagramas Mermaid por nuvem/domínio e por workload dependente
- `templates/feature-artifacts/legacy-inventory.md` — auditoria as-is por nuvem/domínio
- `templates/feature-artifacts/db-schema-registry.md` — catálogo de schemas de bancos de sistemas legados

**Artefato de projeto:**
- `templates/project-root/copilot-instructions.md` — regra de "nunca aplicar
  mudança" e matriz de ferramentas por domínio pré-configuradas

## Regra de Ouro

Este tipo de repositório **nunca** executa `terraform apply` ou qualquer
comando de escrita contra um ambiente real. Ele documenta o estado atual
(inventário, IaC gerado a partir do estado real, schemas de bancos legados) e
só considera um recurso "corretamente capturado" quando a reconciliação
mostra **zero diferenças**. Toda mudança real nasce em um repositório de
projeto separado, usando `nimbus-code-standards`.

## Instalação isolada

```bash
specify preset add nimbus-code-platform-standards --from https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/releases/download/vX.Y.Z/nimbus-code-platform-standards-X.Y.Z.zip --priority 5
```

Ou, em modo desenvolvimento, a partir de um clone local:

```bash
specify preset add --dev ./nimbus-code-spec-kit-template/presets/nimbus-code-platform-standards --priority 5
```

## Detalhamento completo

Ver [`docs/platform-standards-and-legacy-infra.md`](../../docs/platform-standards-and-legacy-infra.md)
neste repositório — matriz de ferramentas por domínio (Azure, AWS, GCP, GWS,
M365, D365), fluxo de reconciliação zero-diff, e o piloto interno (Venha Pra
Nuvem como "Cliente Frontier").

## Versionamento

Este preset segue [SemVer](https://semver.org/), de forma independente do
`nimbus-code-standards` — ambos podem evoluir em versões diferentes. Mudar seu
conteúdo é uma mudança de política organizacional e requer aprovação do time
responsável pelos padrões da Nimbus-Code antes de publicar uma nova versão.

## Status

**Preset em estruturação inicial (v0.1.0)** — ainda não registrado em
`presets/catalog.json`/`bundles/catalog.json` e ainda não publicado como
release. O repositório piloto (Venha Pra Nuvem como primeiro cliente) só será
criado depois que este preset **e** o `nimbus-code-standards` estiverem estáveis e
publicados.
