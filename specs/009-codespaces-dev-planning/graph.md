# Module Dependency Graph: Codespaces para DEV e CI/CD

## Grafo por Código

```mermaid
graph TD
    Dev["Devcontainer de Referência"] -->|provisiona| Codespace["GitHub Codespaces"]
    IdleGov["Workflow de Governança de Ociosidade"] -->|monitora| Codespace
    CiCdMap["Mapeamento de Aceleração CI/CD"] -.->|documenta uso de| Dev
    AgentModel["Modelo de Sessão de Agente"] -.->|reusa| Dev
```

## Grafo por Business

```mermaid
graph LR
    NewDev["Novo Desenvolvedor"] -->|usa| Codespace["Ambiente Padronizado"]
    PlatformLead["Platform Lead"] -->|aprova| Codespace
    FinOps["Gestor de Custo"] -->|monitora via| Governanca["Política de Governança de Custo"]
    Agent["Sessão Remota de Agente"] -->|roda em| Codespace
```

## Critical Paths

1. **Devcontainer → Onboarding**: se o devcontainer de referência não cobrir
   toda a toolchain necessária, o objetivo de "zero-setup" (AC-1) falha.
2. **Governança de Custo → Sustentabilidade**: sem parada automática de
   Codespaces ociosos, a adoção pode gerar custo inesperado (AC-3), colocando
   em risco a continuidade da iniciativa.
