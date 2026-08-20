# graph.md — Feature 001: Catálogo de Conteúdo Reutilizável

> Gerado a partir de `graph.yaml` — manter os dois em sincronia após cada mudança de módulo.

---

## Diagrama por Código (fluxo de execução)

```mermaid
flowchart TD
    Dev["👤 Dev / Agente"]

    subgraph docs["docs/"]
        ReuseCat["reuse-catalog.yaml\n(catálogo machine-readable)"]
        AIQuality["ai-code-quality-and-observability.md\n+ TL;DR\n+ seção 9"]
    end

    subgraph specify[".specify/memory/"]
        Constitution["constitution.md\n+ princípio 'referenciar por ponteiro'"]
    end

    subgraph preset["presets/nimbus-code-standards/templates/"]
        PlanTmpl["plan-template.md\n+ campo 'Padrão reutilizado\nencontrado?'"]
    end

    Dev -->|"1. inicia /speckit-plan de uma feature nova"| PlanTmpl
    PlanTmpl -->|"2. consulta antes de preencher"| ReuseCat
    ReuseCat -->|"3. se match: referencia por ponteiro"| Dev
    Dev -->|"cita no plan.md"| Constitution

    Constitution -.->|"formaliza a prática"| ReuseCat
    AIQuality -.->|"documenta o mecanismo completo"| ReuseCat
```

---

## Diagrama por Business (redução de custo de tokens)

```mermaid
flowchart LR
    Problema["❌ Sem catálogo:\ncada feature nova\nre-deriva soluções\njá resolvidas"]
    Solucao["✅ Com catálogo:\nreferenciar por ponteiro\nem vez de re-explicar"]

    Problema -->|"introduzido por esta feature"| Solucao
    Solucao --> Beneficio1["Menos tokens gastos\nem tarefas S0/S1"]
    Solucao --> Beneficio2["Consistência entre\nfeatures que resolvem\no mesmo problema"]
    Solucao --> Beneficio3["Base para catálogos\nirmãos futuros\n(Harness 011, Success 012)"]
```

---

## Notas de Manutenção

- Esta feature (001) é a **origem** dos catálogos de conteúdo reutilizável
  deste bundle — features posteriores (011 Harness Engineering, 012 Loop de
  Melhoria Contínua) seguem o mesmo padrão estrutural para domínios distintos
  (erros, sucessos) em vez de estender este catálogo diretamente.
- Documento gerado retroativamente em 2026-08-20 — a implementação real
  ocorreu antes desta data, entregue via release `v1.5.0` do preset.
