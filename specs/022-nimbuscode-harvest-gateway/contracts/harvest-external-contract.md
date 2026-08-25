# Contrato: Endpoint HTTP do Gateway (externo, consumido por `harvest-patterns.sh`)

Este contrato **já existe** (definido por `scripts/harvest-patterns.sh`,
SPEC-014) e **não é alterado** por esta feature — documentado aqui apenas
para referência formal de implementação.

## Requisição

```
POST <HARVEST_API_URL>
Authorization: Bearer <HARVEST_API_TOKEN>
Content-Type: application/json
```

```json
{
  "repo": "string",
  "stack": "java | node | go | python | unknown",
  "prompt": "string (instrução fixa de harvest-patterns.sh)",
  "metadata": [
    {"file": "string", "line": "string|null", "signature": "string|null"}
  ]
}
```

## Resposta — sucesso (HTTP 200)

Aceita duas formas equivalentes (o script consumidor já trata ambas):

```json
[
  {
    "tag": "kebab-case-curto",
    "description": "1-2 frases",
    "example": "assinatura mais representativa",
    "source_file": "caminho/do/arquivo",
    "source_line": "42"
  }
]
```

ou

```json
{
  "entries": [ /* mesmo formato de item acima */ ],
  "tokens_used": 1234,
  "estimated_cost": 0.002
}
```

Array vazio (`[]` ou `{"entries": []}`) é uma resposta válida — significa
"nenhum padrão identificável", nunca é tratado como erro.

## Resposta — falha

Qualquer status HTTP diferente de `200` é tratado como falha por
`harvest-patterns.sh` (ele imprime o corpo da resposta e sai com código 1).
O Gateway deve retornar um corpo de erro legível, por exemplo:

```json
{"error": "Credencial ausente para o provedor 'google' (HARVEST_LLM_PROVIDER)."}
```

## Garantias que o Gateway deve manter (não-negociáveis, FR-001)

- Nenhum campo novo obrigatório é adicionado à requisição.
- Nenhum campo existente da resposta é removido ou renomeado.
- `scripts/harvest-patterns.sh` continua funcionando **sem nenhuma alteração
  de código** contra este Gateway.
