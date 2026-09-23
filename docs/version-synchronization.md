# Version Synchronization & Validation

Este documento descreve o sistema de validação de versões do Nimbus Code que garante sincronização entre bundles, presets, catalogs e tags git.

## O Problema

Anteriormente, havia desalinhamentos entre:
- Versão do bundle (bundle.yml)
- Versão do preset fornecido pelo bundle
- Versão declarada nos catalogs (catalog.json)
- URLs de download
- Tags git do repositório

Isso causava:
- Confusão durante bootstrap de novos repositórios
- Inconsistência em downloads
- Dificuldade em rastrear qual versão estava realmente em uso

## A Solução

### 1. Script de Validação (`scripts/validate-versions.sh`)

Script shell que valida:

| Validação | Descrição | Impacto |
|---|---|---|
| **Bundle ↔ Preset** | Versão declarada no bundle.yml bate com preset.yml | Crítico |
| **YAML ↔ Catalog** | Versões em YAML batem com catalog.json | Crítico |
| **Download URLs** | URLs contêm as versões corretas | Crítico |
| **Git Tag** | Tag git corresponde à versão do bundle principal | Aviso |
| **Timestamps** | Catalogs têm timestamp atualizado | Aviso |

**Uso:**

```bash
# Validação completa
./scripts/validate-versions.sh

# Corrigir timestamps automaticamente
./scripts/validate-versions.sh --fix
```

### 2. Git Hook de Pré-commit

**Arquivo:** `.git/hooks/pre-commit` (instalado via `install-hooks.sh`)

**Função:** Bloqueia commits que violem a consistência de versão

**Instalação:**
```bash
./scripts/install-hooks.sh
```

**Comportamento:**
- Roda antes de cada commit
- Se falhar, commit é bloqueado com instruções de correção
- Pode ser bypassed com `git commit --no-verify` (não recomendado)

### 3. GitHub Actions Workflow

**Arquivo:** `.github/workflows/validate-versions.yml`

**Função:** Valida versões em cada push/PR que altere bundles ou presets

**Trigger:** 
- Alterações em `bundles/*/bundle.yml`
- Alterações em `presets/*/preset.yml`
- Alterações em `**/catalog.json`

## Como Contribuir

### Ao Alterar uma Versão

**Passo 1: Atualizar a versão do preset**
```yaml
# presets/nimbus-code-standards/preset.yml
preset:
  version: "1.12.0"  # ← Incrementar aqui
```

**Passo 2: Atualizar o bundle que fornece este preset**
```yaml
# bundles/nimbus-code-project-bundle/bundle.yml
provides:
  presets:
    - id: "nimbus-code-standards"
      version: "1.12.0"  # ← Atualizar para match
```

**Passo 3: Atualizar versão do bundle**
```yaml
bundle:
  version: "1.12.0"  # ← Incrementar para match
```

**Passo 4: Rodar validador localmente**
```bash
./scripts/validate-versions.sh
# Se timestamp não bater, corrigir:
./scripts/validate-versions.sh --fix
```

**Passo 5: Sincronizar tag git** (somente antes de release)
```bash
BUNDLE_VERSION=$(yq '.bundle.version' bundles/nimbus-code-project-bundle/bundle.yml)
git tag -d "v${BUNDLE_VERSION}" 2>/dev/null || true
git tag "v${BUNDLE_VERSION}"
git push origin "v${BUNDLE_VERSION}"
```

### Checklist para PR

Antes de abrir PR com alterações em bundles/presets:

- [ ] Rodei `./scripts/validate-versions.sh` localmente e passou
- [ ] Atualizei versões em:
  - [ ] `preset.yml` (se alter preset)
  - [ ] `bundle.yml` que fornece o preset (se versão mudou)
  - [ ] Bundle version (se mudou)
- [ ] **Developer Guide atualizado (`docs/developer-guide.md`)** refletindo novos comandos, agentes ou capacidades (Regra Mandatória)
- [ ] Templates em `presets/nimbus-code-standards/templates/project-root/` sincronizados com a raiz
- [ ] Timestamps dos catalogs estão atualizados (ou rodei `--fix`)
- [ ] GitHub Actions workflow passou na CI

## Estrutura de Versionamento

```
nimbus-code (repo)
├── bundles/
│   ├── nimbus-code-project-bundle/
│   │   └── bundle.yml (v1.11.0)
│   │       └── provides: nimbus-code-standards v1.11.0
│   ├── nimbus-code-platform-bundle/
│   │   └── bundle.yml (v0.4.0)
│   │       └── provides: nimbus-code-platform-standards v0.4.0
│   └── catalog.json (lista todas as versões)
├── presets/
│   ├── nimbus-code-standards/
│   │   └── preset.yml (v1.11.0)
│   ├── nimbus-code-platform-standards/
│   │   └── preset.yml (v0.4.0)
│   └── catalog.json (lista todas as versões)
└── git tag: v1.11.0 (= bundle principal)
```

**Regra:** Versão do bundle = maior versão dos componentes que fornece

## Troubleshooting

### "Git tag atual: v1.10.0, esperado: v1.11.0"

Significa que você atualizou o bundle mas não sincronizou a tag git.

**Solução:**
```bash
BUNDLE_VERSION=$(yq '.bundle.version' bundles/nimbus-code-project-bundle/bundle.yml)
git tag -d "v1.10.0"  # Remover tag antiga
git tag "v${BUNDLE_VERSION}"  # Criar tag nova
git push origin "v${BUNDLE_VERSION}" --force  # Atualizar no remote
```

### "Bundle catalog: nimbus-code-standards tem v1.10.0 em catalog.json, mas v1.11.0 em preset.yml"

Significado: O `presets/catalog.json` não foi atualizado quando o preset.yml foi alterado.

**Solução:** Rodar `./scripts/validate-versions.sh --fix` ou editar `presets/catalog.json` manualmente com a versão correta.

### Hook de pré-commit está bloqueando meu commit

**Opção 1:** Corrigir as versões (recomendado)
```bash
./scripts/validate-versions.sh --fix
```

**Opção 2:** Verificar a saída do script
```bash
./scripts/validate-versions.sh
# Seguir as instruções de correção
```

**Opção 3:** Bypass temporário (não recomendado)
```bash
git commit --no-verify
# ⚠️ Isso desabilita todas as validações de hook
```

## Roadmap

- [ ] Integração com GitHub Release API para auto-tag após merge
- [ ] Validação de semver (não permitir downgrade de versão)
- [ ] Dashboard de alinhamento de versões em GitHub Project
- [ ] Alertas Slack/Teams quando desalinhamento é detectado

## Referências

- [Bundle Specification](../docs/bundle-specification.md)
- [Preset Specification](../docs/preset-specification.md)
- [CI/CD Workflow](../docs/cicd-workflow.md)
