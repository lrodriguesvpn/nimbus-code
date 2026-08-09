# vpndev-standards (preset)

## Propósito

Aplica os padrões corporativos da VPN Dev sobre os templates nativos do Spec Kit,
sem exigir que cada projeto reescreva as mesmas regras:

- **`constitution-template.md`** (`wrap`) — injeta os princípios não-negociáveis da
  empresa (segurança, IaC, qualidade/processo, grafos de módulos obrigatórios e
  escala de complexidade S0–S4) *antes* do template nativo.
- **`plan-template.md`** (`append`) — acrescenta a **classificação S0–S4**, o
  **Module Dependency Graph obrigatório**, o **Security & DevSecOps Gate** e o
  **Architecture Decision Log** ao final do plano gerado por `/speckit-plan`.
- **`tasks-template.md`** (`append`) — acrescenta o checklist de qualidade
  (incluindo item de atualização do grafo) ao final do `tasks.md`.

**Artefatos de feature (templates):**
- `templates/feature-artifacts/graph.yaml` — fonte de verdade estruturada do grafo (obrigatório S2+)
- `templates/feature-artifacts/graph.md` — diagramas Mermaid por código e por business (obrigatório S2+)
- `templates/feature-artifacts/impact-map.md` — análise de risco e rollback (obrigatório S3/S4)

**Artefato de projeto:**
- `templates/project-root/copilot-instructions.md` — template de `.github/copilot-instructions.md`
  com regras de grafo e escala S0–S4 pré-configuradas

Nenhuma seção nativa do Spec Kit é removida ou substituída — tudo é composição
aditiva (`wrap`/`append`).

## Instalação isolada (sem o bundle completo)

```bash
specify preset add vpndev-standards --from https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/speckit-vpndev-standards/releases/download/vX.Y.Z/vpndev-standards-X.Y.Z.zip --priority 5
```

Ou, em modo desenvolvimento, a partir de um clone local:

```bash
specify preset add --dev ./speckit-vpndev-standards/presets/vpndev-standards --priority 5
```

> Normalmente este preset não é instalado isoladamente — ele é instalado como parte
> do bundle `vpndev-project-bundle` (ver [`../../bundles/vpndev-project-bundle`](../../bundles/vpndev-project-bundle)).

## GitHub Action Graph Guard

Para que o enforcement de grafo funcione nos repositórios de projeto, instale o
workflow Graph Guard:

```bash
cp .github/workflows/graph-guard.yml <repo>/.github/workflows/graph-guard.yml
```

O Graph Guard valida automaticamente em toda PR:
- PRs que alteram código sem atualizar `graph.yaml`/`graph.md` → falha
- Features S3/S4 sem `impact-map.md` → falha
- Dessincronia entre `graph.yaml` e `graph.md` → aviso

## Versionamento

Este preset segue [SemVer](https://semver.org/). Mudar seu conteúdo é uma **mudança
de política organizacional**, não de projeto individual — requer aprovação do time
responsável pelos padrões da VPN Dev antes de publicar uma nova versão. Ver a
política de versionamento consolidada em [`../../README.md`](../../README.md).

## Como testar localmente

```bash
mkdir /tmp/vpndev-preset-smoke && cd /tmp/vpndev-preset-smoke
specify init --here --integration copilot --ignore-agent-tools
specify preset add --dev /path/to/speckit-vpndev-standards/presets/vpndev-standards --priority 5
specify preset resolve constitution-template
specify preset resolve plan-template
```


## Instalação isolada (sem o bundle completo)

```bash
specify preset add vpndev-standards --from https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/speckit-vpndev-standards/releases/download/vX.Y.Z/vpndev-standards-X.Y.Z.zip --priority 5
```

Ou, em modo desenvolvimento, a partir de um clone local:

```bash
specify preset add --dev ./speckit-vpndev-standards/presets/vpndev-standards --priority 5
```

> Normalmente este preset não é instalado isoladamente — ele é instalado como parte
> do bundle `vpndev-project-bundle` (ver [`../../bundles/vpndev-project-bundle`](../../bundles/vpndev-project-bundle)).

## Versionamento

Este preset segue [SemVer](https://semver.org/). Mudar seu conteúdo é uma **mudança
de política organizacional**, não de projeto individual — requer aprovação do time
responsável pelos padrões da VPN Dev antes de publicar uma nova versão. Ver a
política de versionamento consolidada em [`../../README.md`](../../README.md).

## Como testar localmente

```bash
mkdir /tmp/vpndev-preset-smoke && cd /tmp/vpndev-preset-smoke
specify init --here --integration copilot --ignore-agent-tools
specify preset add --dev /path/to/speckit-vpndev-standards/presets/vpndev-standards --priority 5
specify preset resolve constitution-template
specify preset resolve plan-template
```
