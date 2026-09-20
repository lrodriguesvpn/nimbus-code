# Module Dependency Graph: Bootstrap Governance & Repo Provisioning Hardening

## Grafo por Código

```mermaid
graph TD
    Bootstrap["bootstrap.sh"] -->|instala se dev_standards| PresetStd["nimbus-code-standards"]
    Bootstrap -->|instala se platform| PresetPlat["nimbus-code-platform-standards"]
    Bootstrap -->|instala CLI de| SpecKit["Spec Kit CLI oficial (github.com/github/spec-kit)"]

    Validator["validate-issue-template-parity.sh"] -->|lê/compara| PresetStd
    Validator -->|lê/compara| PresetPlat

    EnsureProj["ensure-github-project.yml"] -->|token de instalação| GHApp["GitHub App organizacional"]
    AddToProj["add-to-repo-project.yml"] -->|token de instalação| GHApp
    SyncPriority["sync-priority-field.yml"] -->|token de instalação| GHApp
    AutoAssign["agent-auto-assign.yml"] -->|token de instalação| GHApp

    GraphGuard["graph-guard.yml"] -->|GITHUB_TOKEN nativo, sem GitHub App| GraphGuard
    Release["v1.19.0-rc.1"] -->|ref imutável| ProjectBundle["nimbus-code-project-bundle 1.19.0"]
    Release -->|ref imutável| PlatformBundle["nimbus-code-platform-bundle 0.5.0"]
    Platform["nimbus-code-platform-standards 0.5.0"] -->|evidência advisory| CMDB["CMDB / inventário cloud"]
    DevGuard["Dev Standards agent guardrails"] -->|governa| Bootstrap

    style GHApp fill:#f9f,stroke:#333
    style SpecKit fill:#bbf,stroke:#333
```

## Grafo por Business

```mermaid
graph LR
    Dev["Dev/Operador"] -->|responde pergunta de tipo| Bootstrap["Processo de Bootstrap"]
    Bootstrap -->|escolhe| GovernancaModel["Modelo de Governança (Dev Standards ou Plataforma)"]

    ArchBoard["Nimbus-Code Architecture Board"] -->|mantém paridade entre| DoisPresets["Os 2 Presets de Governança"]

    SecurityLead["Security Lead"] -->|aprova migração de| AutenticacaoCrossRepo["Autenticação Cross-Repo/Org (GitHub App)"]

    DoisPresets --> GovernancaModel
    AutenticacaoCrossRepo --> GovernancaModel
    Release -->|piloto| Pilot["Projeto de validação"]
    Pilot -->|promove após gates| Final["v1.19.0"]
```

## Critical Paths

1. **Bootstrap → Preset**: se a pergunta de tipo de repositório falhar ou for
   pulada silenciosamente, todo o restante do bootstrap instala o preset errado
   — caminho crítico validado por AC-1.
2. **Workflow → GitHub App**: se o GitHub App não estiver instalado/configurado
   quando um workflow crítico (ex.: `ensure-github-project.yml`) rodar, o
   fallback para PAT preserva a operação, mas com aviso explícito — nunca falha
   silenciosamente (FR-009).
