# Module Dependency Graph: Harness Corporativo — Consolidação de Harness Agêntico IDE Pessoal

**Feature**: `029-harness-corporativo-ide`  
**Data**: 2026-09-22  
**Agente**: NC-Arch (Nimbus Solution Architect)  
**Status**: Concluído — Versão 1.0.0

---

## 1. Diagrama por Código (Arquitetura de Módulos e Componentes)

Representa os componentes de código, scripts locais, módulos de sanitização e bibliotecas envolvidas no fluxo de execução.

```mermaid
flowchart TD
    subgraph Local_Developer_Machine["Máquina Local do Desenvolvedor"]
        IDE_Files["Arquivos de Regras IDE<br/><code>~/.claude/CLAUDE.md</code><br/><code>.cursor/rules/*</code>"]
        CLI["scripts/harvest-patterns.sh<br/><code>--source ide-harness</code>"]
        Anonymizer["scripts/lib/harness_anonymizer.py<br/><i>(Sanitização Fail-Closed)</i>"]
        GatewayClient["harvest-patterns.sh (HTTP block)<br/><i>(curl + Bearer Token)</i>"]
        RepoWriter["scripts/lib/central_repo_writer.py<br/><i>(Validador de Destino)</i>"]
    end

    subgraph External_Cloud["Nuvem Corporativa / Gateway"]
        Gateway["Nimbus Harvest Gateway<br/><code>HARVEST_API_URL</code> (Azure/Vertex/Bedrock)"]
    end

    subgraph GHE_Central_Repo["Repositório Central: nimbus-code-harness-corporativo"]
        RawDir[("Diretório raw/<br/><code>RAW-YYYYMMDD-hash.yaml</code>")]
        TriageCLI["scripts/triage-cli.py<br/><i>(Curadoria do Comitê)</i>"]
        PromotedDir[("Diretório promoted/<br/><code>generic/</code> e <code>bounded-contexts/</code>")]
        PurgeJob["scripts/purge-expired.py<br/><i>(Workflow de Expurgo >90d)</i>"]
        ArchiveLog[("Diretório archive/<br/><code>purge-audit.jsonl</code>")]
    end

    subgraph Satellites["Repositórios Satélite de Projetos"]
        SyncTool["scripts/sync-corporate-harness.sh<br/><i>(Redistribuição Idempotente)</i>"]
        SatFiles["Arquivos do Repositório Satélite<br/><code>.claude/CLAUDE.md</code>"]
    end

    %% Fluxo de Código
    IDE_Files -->|"1. Leitura de texto livre"| CLI
    CLI -->|"2. Invoca sanitizador"| Anonymizer
    Anonymizer --"3a. Segredo residual detectado"--> Abort["Abortar com Exit Code 1<br/><i>(Fail-Closed)</i>"]
    Anonymizer -->|"3b. Texto 100% anonimizado"| GatewayClient
    GatewayClient -->|"4. HTTPS POST (prompt anonimizado)"| Gateway
    Gateway -->|"5. JSON com padrões candidatos"| GatewayClient
    GatewayClient -->|"6. Consolida metadados"| RepoWriter
    RepoWriter -->|"7. Grava YAML pendente"| RawDir

    %% Fluxo do Comitê
    RawDir -->|"8. Carrega itens pendentes"| TriageCLI
    TriageCLI -->|"9. Quórum aprova"| PromotedDir
    TriageCLI -->|"10. Comitê descarta"| Discard["Marca descartado"]

    %% Fluxo de Expurgo
    RawDir -->|"11. Verifica >90 dias"| PurgeJob
    PurgeJob -->|"12. Exclusão física"| RawDir
    PurgeJob -->|"13. Grava hash de auditoria"| ArchiveLog

    %% Fluxo de Redistribuição
    PromotedDir -->|"14. Lê regras por bounded context"| SyncTool
    SyncTool -->|"15. Atualiza bloco gerenciado"| SatFiles
```

---

## 2. Diagrama por Fluxo de Negócio e Governança

Ilustra os estágios de maturidade, gates de governança e papéis humanos envolvidos desde a captura inicial na IDE do colaborador até a propagação corporativa.

```mermaid
flowchart LR
    subgraph Stage1["1. Captura & Privacidade"]
        Dev["Colaborador Humano<br/>(Voluntário / Piloto)"]
        SanitizeGate{"Gate Técnico<br/>Fail-Closed"}
        LLMSummary["Síntese via LLM<br/>(Normalização)"]
    end

    subgraph Stage2["2. Quarentena & Triagem"]
        RawRepo["Repositório Central GHE<br/>(Área raw/ - Retenção 90d)"]
        Committee{"Comitê Nimbus Code<br/>(4 Membros: Arch, Sec, Plat, Prod)"}
    end

    subgraph Stage3["3. Governança de Ciclo de Vida"]
        PurgeAction["Expurgo LGPD<br/>(Exclusão após 90 dias)"]
        PromotedRepo["Catálogo Homologado<br/>(Área promoted/)"]
    end

    subgraph Stage4["4. Consumo & Reuso"]
        Satellites["Equipes Satélite<br/>(Reuso via bootstrap.sh)"]
    end

    Dev -->|"Executa harvest on-demand"| SanitizeGate
    SanitizeGate --"Violação detectada"--> Block["Bloqueio Local<br/>(Nada transmitido)"]
    SanitizeGate --"100% Sanitizado"--> LLMSummary
    LLMSummary -->|"Armazena bruto"| RawRepo

    RawRepo -->|"Triagem periódica"| Committee
    Committee --"Sem quórum / Rejeitado"--> RawRepo
    RawRepo -->|"> 90 dias sem promoção"| PurgeAction
    Committee --"Quórum aprovado"--> PromotedRepo

    PromotedRepo -->|"Sincronização seletiva"| Satellites
```

---

## 3. Diagrama Multi-Repo e Fronteiras de Segurança

Evidencia as fronteiras de isolamento estrito entre o repositório local de desenvolvimento, o repositório central institucional e os repositórios satélites (mitigando os riscos de vazamento e poluição cruzada mapeados em HRN-0005).

```mermaid
graph TB
    subgraph Developer_Workspace["Workspace Local do Desenvolvedor"]
        LocalRepo["Repositório do Projeto Local<br/>(ex.: service-pix-core)"]
        LocalReuse["docs/reuse-catalog.yaml<br/><b>[ISOLADO: NUNCA MODIFICADO]</b>"]
        IDEConfig["~/.claude/CLAUDE.md<br/>.cursor/rules"]
    end

    subgraph Network_Boundary["Fronteira de Rede Segura"]
        HarvestCLI["scripts/harvest-patterns.sh"]
        AnonymizerLib["harness_anonymizer.py"]
    end

    subgraph Enterprise_GHE["GitHub Enterprise Corporativo"]
        CentralRepo["venha-pra-nuvem/nimbus-code-harness-corporativo<br/><b>[REPOSITÓRIO CENTRAL DEDICADO]</b>"]
        CentralCatalog["promoted/catalog.yaml"]
    end

    subgraph Satellite_GHE["Repositórios Satélite"]
        SatelliteA["venha-pra-nuvem/service-faturamento"]
        SatelliteB["venha-pra-nuvem/service-checkout"]
    end

    %% Relações e Barreiras
    IDEConfig --> HarvestCLI
    HarvestCLI --> AnonymizerLib
    AnonymizerLib -.->|"PROIBIDO escrever no repo local"| LocalReuse
    AnonymizerLib ==>|"Grava exclusivamente no repo central"| CentralRepo

    CentralCatalog -.->|"Sync idempotente (Etapa 2)"| SatelliteA
    CentralCatalog -.->|"Sync idempotente (Etapa 2)"| SatelliteB
```
