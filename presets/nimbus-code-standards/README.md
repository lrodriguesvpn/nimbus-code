# nimbus-code-standards (preset)

## Propósito

Aplica os padrões corporativos da Nimbus-Code sobre os templates nativos do Nimbus Code,
sem exigir que cada projeto reescreva as mesmas regras:

- **`constitution-template.md`** (`wrap`) — injeta os princípios não-negociáveis da
  empresa (segurança, IaC, qualidade/processo, grafos de módulos obrigatórios e
  escala de complexidade S0–S4) *antes* do template nativo.
- **`plan-template.md`** (`append`) — acrescenta a **classificação S0–S4**, o
  **Module Dependency Graph obrigatório**, o **Security & DevSecOps Gate** e o
  **Architecture Decision Log** ao final do plano gerado por `/nimbus-code-plan`,
  incluindo plano obrigatório de toggle/rollout para cenários concorrentes.
- **`tasks-template.md`** (`append`) — acrescenta o checklist de qualidade
  (incluindo item de atualização do grafo e ciclo de vida da feature flag) ao final
  do `tasks.md`.

**Artefatos de feature (templates):**
- `templates/feature-artifacts/graph.yaml` — fonte de verdade estruturada do grafo (obrigatório S2+)
- `templates/feature-artifacts/graph.md` — diagramas Mermaid por código e por business (obrigatório S2+)
- `templates/feature-artifacts/impact-map.md` — análise de risco e rollback (obrigatório S3/S4)

**Artefato de projeto:**
- `templates/project-root/copilot-instructions.md` — template de `.github/copilot-instructions.md`
  com regras de grafo e escala S0–S4 pré-configuradas

Nenhuma seção nativa do Nimbus Code é removida ou substituída — tudo é composição
aditiva (`wrap`/`append`).

## Instalação isolada (sem o bundle completo)

```bash
specify preset add nimbus-code-standards --from https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code/releases/download/vX.Y.Z/nimbus-code-standards-X.Y.Z.zip --priority 5
```

Ou, em modo desenvolvimento, a partir de um clone local:

```bash
specify preset add --dev ./nimbus-code/presets/nimbus-code-standards --priority 5
```

> Normalmente este preset não é instalado isoladamente — ele é instalado como parte
> do bundle `nimbus-code-project-bundle` (ver [`../../bundles/nimbus-code-project-bundle`](../../bundles/nimbus-code-project-bundle)).

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
responsável pelos padrões da Nimbus-Code antes de publicar uma nova versão. Ver a
política de versionamento consolidada em [`../../README.md`](../../README.md).

## Como testar localmente

```bash
mkdir /tmp/nimbus-code-preset-smoke && cd /tmp/nimbus-code-preset-smoke
specify init --here --integration copilot --ignore-agent-tools
specify preset add --dev /path/to/nimbus-code/presets/nimbus-code-standards --priority 5
specify preset resolve constitution-template
specify preset resolve plan-template
```


## Instalação isolada (sem o bundle completo)

```bash
specify preset add nimbus-code-standards --from https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code/releases/download/vX.Y.Z/nimbus-code-standards-X.Y.Z.zip --priority 5
```

Ou, em modo desenvolvimento, a partir de um clone local:

```bash
specify preset add --dev ./nimbus-code/presets/nimbus-code-standards --priority 5
```

> Normalmente este preset não é instalado isoladamente — ele é instalado como parte
> do bundle `nimbus-code-project-bundle` (ver [`../../bundles/nimbus-code-project-bundle`](../../bundles/nimbus-code-project-bundle)).

## Versionamento

Este preset segue [SemVer](https://semver.org/). Mudar seu conteúdo é uma **mudança
de política organizacional**, não de projeto individual — requer aprovação do time
responsável pelos padrões da Nimbus-Code antes de publicar uma nova versão. Ver a
política de versionamento consolidada em [`../../README.md`](../../README.md).

## Como testar localmente

```bash
mkdir /tmp/nimbus-code-preset-smoke && cd /tmp/nimbus-code-preset-smoke
specify init --here --integration copilot --ignore-agent-tools
specify preset add --dev /path/to/nimbus-code/presets/nimbus-code-standards --priority 5
specify preset resolve constitution-template
specify preset resolve plan-template
```
