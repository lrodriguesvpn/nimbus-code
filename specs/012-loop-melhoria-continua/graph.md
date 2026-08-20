# graph.md — Feature 012: Loop de Melhoria Contínua Nimbus-Code

> Gerado a partir de `graph.yaml` — manter os dois em sincronia após cada mudança de módulo.

---

## Diagrama por Código (fluxo de execução)

```mermaid
flowchart TD
    Dev["👤 Tech Lead / Time"]
    Agent["🤖 Agente (Copilot)"]

    subgraph docs["docs/"]
        SuccessCat["playbooks/success-catalog.yaml\n(novo — irmão do harness)"]
        HarnessCat["harness/harness-catalog.yaml\n(feature 011 — erros)"]
        ReuseCat["reuse-catalog.yaml\n(feature 001)"]
    end

    subgraph scripts["scripts/"]
        MetricsScript["process-metrics-report.sh\n(novo — calcula DORA)"]
    end

    subgraph presets["presets/nimbus-code-standards/templates/"]
        PlanTmpl["plan-template.md\n+ Playbook de Sucesso Gate"]
        TasksTmpl["tasks-template.md\n+ checklist 'o que deu certo?'"]
        RetroTmpl["feature-artifacts/retro-template.md\n(já existente)"]
    end

    GHEAPI["☁️ GHE API\n(labels dora:*, datas de issues/PRs)"]

    Dev -->|"1. fecha uma feature"| TasksTmpl
    TasksTmpl -->|"pergunta 'o que deu certo?'"| Agent
    Agent -->|"propõe rascunho"| SuccessCat
    Dev -->|"valida/edita/descarta"| SuccessCat

    Dev -->|"2. roda relatório DORA"| MetricsScript
    MetricsScript -->|"lê labels dora:* e datas"| GHEAPI
    MetricsScript -->|"reporta 4 indicadores"| Dev

    TasksTmpl -->|"3. cadência N features"| RetroTmpl
    RetroTmpl -->|"pode gerar entrada em"| SuccessCat
    RetroTmpl -->|"pode gerar entrada em"| HarnessCat

    Dev -->|"4. /speckit-plan nova feature"| PlanTmpl
    PlanTmpl -->|"consulta obrigatória"| SuccessCat

    SuccessCat -.->|"padrão reutilizável"| ReuseCat
```

---

## Diagrama por Business (ciclo de aprendizado)

```mermaid
flowchart LR
    subgraph erro["❌ Lado do Erro (feature 011 — já existe)"]
        Harness["Harness Catalog\n(o que evitar)"]
    end

    subgraph sucesso["✅ Lado do Sucesso (feature 012 — esta)"]
        Playbook["Success Catalog\n(o que repetir)"]
    end

    subgraph metricas["📊 Métricas de Processo (feature 012)"]
        DORA["4 Indicadores DORA\n(deploy freq, lead time,\nchange failure rate, MTTR)"]
    end

    subgraph cadencia["🔁 Cadência (feature 012)"]
        Retro["Retrospectiva Proativa\n(por N features, não só por incidente)"]
    end

    FeatureConcluida["Feature Concluída"]

    FeatureConcluida -->|"deu errado?"| Harness
    FeatureConcluida -->|"deu certo?"| Playbook
    FeatureConcluida -->|"sempre"| DORA
    FeatureConcluida -->|"a cada N"| Retro

    Retro -->|"pode alimentar"| Harness
    Retro -->|"pode alimentar"| Playbook
    DORA -->|"meta não atingida"| AcaoMelhoria["Ação de Melhoria\n(dono + prazo)"]

    Harness -.->|"consultado antes de"| NovoPlano["Novo plan.md"]
    Playbook -.->|"consultado antes de"| NovoPlano
```

---

## Notas de Manutenção

- Esta feature é **explicitamente complementar** à feature 011 (Harness
  Engineering), não uma duplicata — harness cobre erros, esta cobre sucessos
  + métricas + cadência de retrospectiva.
- Atualizar `graph.yaml` e este arquivo se novos módulos forem adicionados
  durante a implementação (ex.: mecanismo de armazenamento do Retro Cadence
  Counter, ainda em aberto no `data-model.md`).
- Toda entrada em `success-catalog.yaml` e toda meta/ação de melhoria de DORA
  passa por validação humana explícita antes de virar registro definitivo —
  reforço do princípio de Modelo Híbrido (FR-007).
