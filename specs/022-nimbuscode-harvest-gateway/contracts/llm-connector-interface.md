# Contrato: Interface Interna dos Conectores (`LLMConnector`)

Este contrato é **novo nesta feature** — a interface comum que todo conector
de provedor de nuvem deve implementar, permitindo ao Connector Router trocar
de provedor/modelo só por configuração (AC-5), sem acoplar o restante do
Gateway ao SDK específico de cada nuvem.

## Interface

```python
from typing import Protocol

class LLMConnector(Protocol):
    def complete(
        self,
        system_prompt: str,
        metadata: list[dict],
        model: str,
    ) -> list[dict]:
        """
        Recebe o prompt fixo de harvest-patterns.sh e os metadados estruturais
        já extraídos, e retorna a lista de padrões no formato de
        HarvestResponse (ver data-model.md) — nunca o payload bruto do SDK
        do provedor.

        Deve levantar HarvestConnectorError (ver abaixo) em caso de falha,
        nunca retornar silenciosamente uma lista vazia por erro de
        credencial/rede — lista vazia significa exclusivamente "nenhum
        padrão identificável", nunca "algo deu errado".
        """
        ...
```

## Exceção padrão

```python
class HarvestConnectorError(Exception):
    """
    Levantada por qualquer conector quando a chamada ao provedor falha
    (credencial ausente/inválida, erro de rede, resposta fora do formato
    esperado). O Router captura esta exceção e a traduz em HTTP não-200
    com corpo de erro legível (ver contrato externo), preservando FR-006/AC-7
    (falha explícita, nunca silenciosa).
    """
    def __init__(self, provider: str, reason: str):
        self.provider = provider
        self.reason = reason
```

## Implementações concretas (contrato de configuração de cada uma)

| Conector | Variável de modelo | Credenciais esperadas |
|---|---|---|
| `AzureAIConnector` | `HARVEST_AZURE_MODEL` | `AZURE_AI_ENDPOINT`, `AZURE_AI_KEY` (Azure AI Foundry) |
| `GoogleConnector` | `HARVEST_GOOGLE_MODEL` | `GOOGLE_PROJECT_ID`, `GOOGLE_CREDENTIALS` (Vertex AI/Gemini) |
| `AWSBedrockConnector` | `HARVEST_AWS_MODEL` | credenciais IAM padrão do runtime (role/instance profile — nunca access key hardcoded), `AWS_REGION` |

## Seleção do conector (Router)

```python
CONNECTORS: dict[str, LLMConnector] = {
    "azure": AzureAIConnector(),
    "google": GoogleConnector(),
    "aws": AWSBedrockConnector(),
}

def resolve_connector(provider: str) -> LLMConnector:
    if provider not in CONNECTORS:
        raise HarvestConnectorError(
            provider=provider,
            reason=f"HARVEST_LLM_PROVIDER='{provider}' não reconhecido (esperado: azure, google ou aws)",
        )
    return CONNECTORS[provider]
```

## Garantias que todo conector deve manter

- **Nunca** loga ou persiste o conteúdo de `metadata` além do necessário para
  a chamada em si (Security Gate, FR-008) — nenhum log de debug deve conter
  `metadata` bruto.
- **Sempre** retorna `HarvestConnectorError` (nunca lista vazia) quando a
  causa da ausência de resultado for erro técnico, não ausência real de
  padrão.
- **Sempre** reporta `model` efetivamente usado no `ObservabilityRecord`
  (ver `data-model.md`) — mesmo em caso de falha, para rastreabilidade de
  qual configuração estava ativa no momento.
