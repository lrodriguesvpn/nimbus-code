# graph.md — Feature 013: Governança de Testes em PR

> Gerado a partir de `graph.yaml` — manter os dois em sincronia após cada mudança de módulo.

---

## Diagrama por Código (fluxo de execução)

```mermaid
flowchart TD
    Dev["👤 Contribuidor"]
    PR["Pull Request contra main"]

    subgraph docs["docs/"]
        Policy["testing-policy.md\n(inventário + taxonomia +\nmatriz de decisão + exceções)"]
        ReuseCat["reuse-catalog.yaml\n(+ entrada, se reutilizável)"]
    end

    subgraph scripts["scripts/"]
        RunTests["run-tests.sh\n(ponto de entrada único)"]
    end

    subgraph workflows[".github/workflows/"]
        TestSuite["test-suite.yml\n(gate obrigatório —\nrollout: relatório → required)"]
    end

    subgraph tests["tests/"]
        Bats["tests/bootstrap/*.bats\n(padrão principal)"]
        Shell["tests/{docs,scripts,workflows}/*.test.sh\n(formato aceito)"]
    end

    Dev -->|"1. roda antes de abrir PR"| RunTests
    Dev -->|"2. abre PR"| PR
    PR -->|"3. aciona"| TestSuite
    TestSuite -->|"4. invoca o MESMO script"| RunTests
    RunTests -->|"descobre e roda"| Bats
    RunTests -->|"descobre e roda"| Shell

    Policy -.->|"documenta"| RunTests
    Policy -.->|"documenta"| TestSuite
    Policy -.->|"consultada antes de escrever novo teste"| Dev
```

---

## Diagrama por Business (fecha o gap de governança)

```mermaid
flowchart LR
    Problema["❌ Hoje:\ntestes existem,\nmas nenhum workflow\nroda a suíte completa\nem toda PR"]
    Solucao["✅ Com esta feature:\ngate único e obrigatório,\npolítica clara de formato,\nparidade local/CI"]

    Problema -->|"resolvido por esta feature"| Solucao
    Solucao --> B1["Redução de PRs quebradas\nchegando a main sem\nvalidação consolidada"]
    Solucao --> B2["Onboarding mais rápido:\n1 comando local\n= mesma validação do CI"]
    Solucao --> B3["Governança de exceções\nevita nova fragmentação\nfutura da suíte"]
```

---

## Notas de Manutenção

- Módulos novos desta feature (`docs/testing-policy.md`, `scripts/run-tests.sh`,
  `.github/workflows/test-suite.yml`) devem ser mantidos em paridade — qualquer
  mudança na lógica de descoberta de `run-tests.sh` deve ser refletida
  automaticamente no comportamento de `test-suite.yml` (mesma invocação), sem
  necessidade de duplicar a lógica.
- `tests/bootstrap/` e `tests/{docs,scripts,workflows}/` não são consumidos
  diretamente por nenhum outro módulo do bundle além de `run-tests.sh` — grafo
  local a esta feature, sem dependências externas ao repositório.
- Grafo será atualizado após `/nimbus-code-implement` se a implementação real
  divergir deste plano (ex.: se `run-tests.sh` for dividido em múltiplos
  scripts por categoria).
