# Grafo de Módulos: Nimbus Harvest Gateway

Ver [graph.yaml](./graph.yaml) para a fonte estruturada (lida pelo Graph
Guard). Este arquivo traz os mesmos dados em diagramas Mermaid para leitura
humana.

## Grafo por código (módulos internos)

```mermaid
graph TD
  FA["function_app.py<br/>(endpoint HTTP único)"]
  ROUTER["router.py<br/>(Connector Router)"]
  AZ["connectors/azure_ai.py"]
  GG["connectors/google.py"]
  AWS["connectors/aws_bedrock.py"]
  OBS["observability.py"]

  FA --> ROUTER
  FA --> OBS
  ROUTER -->|HARVEST_LLM_PROVIDER=azure| AZ
  ROUTER -->|HARVEST_LLM_PROVIDER=google| GG
  ROUTER -->|HARVEST_LLM_PROVIDER=aws| AWS

  AZ -.->|chamada externa| AZFOUNDRY[("Azure AI Foundry")]
  GG -.->|chamada externa| VERTEX[("Google Vertex AI")]
  AWS -.->|chamada externa| BEDROCK[("AWS Bedrock")]
  OBS -.->|chamada externa| AI[("Application Insights")]
```

## Grafo por business (fluxo de valor)

```mermaid
flowchart LR
    SAT["Repositório satélite\n(scripts/harvest-patterns.sh)"] -->|"POST HARVEST_API_URL"| FA2["Gateway — Function App"]
    FA2 --> ROUTER2["Connector Router"]
    ROUTER2 -->|"provedor ativo"| CONN["Conector selecionado\n(Azure | Google | AWS)"]
    CONN -->|"padrões detectados"| RESP["Resposta ao repositório satélite"]
    FA2 -->|"sempre, sucesso ou falha"| OBS2["Registro de observabilidade\n(repo, provider, model, custo)"]
```

## Grafo de Contexto Multi-Repo (SPEC-014)

```mermaid
graph LR
  venha-pra-nuvem-nimbus-harvest-gateway["venha-pra-nuvem/nimbus-harvest-gateway"]
```

**Repositórios não analisados**: o repositório `venha-pra-nuvem/nimbus-harvest-gateway`
ainda não existe — o grafo de contexto será reprocessado (`scripts/generate-context-graph.sh`)
assim que o repositório for criado, na fase de implementação.
