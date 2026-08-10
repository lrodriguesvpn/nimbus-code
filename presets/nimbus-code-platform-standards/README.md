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
| Unidade de trabalho | Feature de código | Plataforma / superfície / sistema legado |
| Grafo | `graph.yaml` (módulos de código) | `platform-graph.yaml` (plataformas → superfícies) |

Um repositório usa **um dos dois presets, nunca os dois** — se o repositório
representa a infraestrutura/ambiente real de um cliente (contas cloud,
tenants M365/GWS, ambiente D365, sistemas legados), use este preset.

## Pipeline de Ciclo de Vida de Plataforma

Cada plataforma (conta/assinatura/tenant) dentro do repositório percorre estas
fases em ordem, rastreadas pelo campo `iac_lifecycle_stage` em `platform-graph.yaml`:

```
discovery → imported → plan_diff_zero → landing_zone_generated → managed
```

| Fase | Produto | Gate de saída |
|---|---|---|
| `discovery` | `nimbus-discovery-report.md` | Relatório revisado por arquiteto |
| `imported` | IaC gerado e versionado | `terraform plan` roda sem erro |
| `plan_diff_zero` | Output de plan zerado | `0 to add, 0 to change, 0 to destroy` |
| `landing_zone_generated` | `landing-zone/<platform-id>/design.md` + `checklist-caf.md` | Landing Zone revisada |
| `managed` | Drift-check ativo | Alerta de drift configurado |

## Templates incluídos

**Templates que modificam templates nativos:**
- **`constitution-template.md`** (`wrap`) — regra de nunca aplicar mudança direta,
  critério de zero-diff, ciclo de vida de plataforma, isolamento de credenciais por tenant,
  cobertura multi-nuvem (Azure/AWS/GCP/GWS/M365/D365) e registro de schemas de legado.
- **`plan-template.md`** (`append`) — classificação de ambiente/cliente/nuvem, gate de fase
  com evidência obrigatória, ferramenta de reconciliação por domínio e checklist de zero-diff.
- **`spec-template.md`** (`prepend`) — cabeçalho com cliente/tenant, ambiente,
  classificação de legado e tipo de spec (`forward` / `reverse`).
- **`tasks-template.md`** (`append`) — checklist de fechamento com confirmação de que nenhuma
  mudança foi aplicada diretamente e gate de avanço de fase.

**Artefatos de feature (templates):**
- `templates/feature-artifacts/platform-graph.yaml` — grafo com hierarquia `platforms[] → surfaces[]` e `iac_lifecycle_stage` por plataforma
- `templates/feature-artifacts/platform-graph.md` — diagramas Mermaid por plataforma/fase e por dependência workload
- `templates/feature-artifacts/nimbus-discovery-report.md` — relatório formal da fase de Discovery (novo em v0.2.0)
- `templates/feature-artifacts/landing-zone/design.md` — topologia da Landing Zone por CAF (novo em v0.2.0)
- `templates/feature-artifacts/landing-zone/checklist-caf.md` — checklist CAF por nuvem (novo em v0.2.0)
- `templates/feature-artifacts/legacy-inventory.md` — auditoria as-is por nuvem/domínio
- `templates/feature-artifacts/db-schema-registry.md` — catálogo de schemas de bancos de sistemas legados

**Artefato de projeto:**
- `templates/project-root/copilot-instructions.md` — regra de "nunca aplicar mudança",
  pipeline de ciclo de vida, matriz de ferramentas por domínio e isolamento de credenciais

## Regra de Ouro

Este tipo de repositório **nunca** executa `terraform apply` ou qualquer
comando de escrita contra um ambiente real. Ele documenta o estado atual
(inventário, IaC gerado a partir do estado real, schemas de bancos legados) e
só considera um recurso "corretamente capturado" quando a reconciliação
mostra **zero diferenças**. Toda mudança real nasce em um repositório de
projeto separado, usando `nimbus-code-standards`.

## Instalação isolada

```bash
specify preset add nimbus-code-platform-standards --from https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/releases/download/vX.Y.Z/nimbus-code-platform-standards-0.2.0.zip --priority 5
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

**v0.2.0** — Publicado no `presets/catalog.json`. Inclui hierarquia de plataformas,
pipeline de ciclo de vida com 5 fases, Nimbus Discovery Report, Landing Zone + CAF
automático, spec `reverse`, isolamento de credenciais e gates formais por fase.

