# Quickstart: Nimbus Harvest Gateway

Guia de validação executável — prova que o Gateway funciona ponta a ponta
sem exigir nenhuma mudança em `scripts/harvest-patterns.sh`. Ver
[data-model.md](./data-model.md) para o schema completo e
[spec.md](./spec.md) para os critérios de aceite (AC-1 a AC-7).

## Pré-requisitos

- Gateway deployado (Azure Functions) com ao menos o conector Azure AI
  Foundry habilitado (US1)
- `HARVEST_API_URL`/`HARVEST_API_TOKEN` configurados como variáveis de
  organização em um repositório satélite de teste
- `curl` e `jq` disponíveis localmente

## Cenário 1 — Rodar o Harvest pela primeira vez (AC-1, US1)

```bash
export HARVEST_API_URL="https://<gateway>.azurewebsites.net/api/harvest"
export HARVEST_API_TOKEN="<token>"

scripts/harvest-patterns.sh . --dry-run
```

**Resultado esperado**: HTTP 200, array de padrões (ou array vazio) no
formato exato já esperado pelo script — **sem nenhuma modificação** em
`scripts/harvest-patterns.sh`.

## Cenário 2 — Trocar de provedor sem tocar em nenhum repositório satélite (AC-5, US2)

```bash
# No Gateway (não no repositório satélite):
az functionapp config appsettings set --name <gateway-app> \
  --settings HARVEST_LLM_PROVIDER=google HARVEST_GOOGLE_MODEL=gemini-2.0-flash

# No repositório satélite (nenhuma mudança):
scripts/harvest-patterns.sh . --dry-run
```

**Resultado esperado**: a mesma chamada, sem nenhuma alteração no
repositório satélite, agora é respondida pelo conector Google — confirmável
pelo campo `provider` no `ObservabilityRecord` da chamada.

## Cenário 3 — Trocar de modelo dentro do mesmo provedor (US3)

```bash
az functionapp config appsettings set --name <gateway-app> \
  --settings HARVEST_AZURE_MODEL=gpt-4o
```

**Resultado esperado**: a próxima chamada com `HARVEST_LLM_PROVIDER=azure`
usa o novo modelo, registrado corretamente no `ObservabilityRecord`.

## Cenário 4 — Observabilidade de custo por repositório (AC-6, US4)

1. Rodar `scripts/harvest-patterns.sh` a partir de 2 repositórios satélite
   diferentes.
2. Consultar o Application Insights do Gateway (query KQL básica sobre
   `customEvents`/`traces` filtrando pelo campo `repo`).

**Resultado esperado**: cada chamada aparece separadamente, identificada por
`repo`, `provider`, `model`, `tokens_used`/`estimated_cost`.

## Cenário 5 — Falha explícita com credencial ausente (AC-7)

1. Configurar `HARVEST_LLM_PROVIDER=aws` no Gateway **sem** as credenciais
   IAM do Bedrock configuradas.
2. Rodar `scripts/harvest-patterns.sh . --dry-run` num repositório satélite.

**Resultado esperado**: resposta HTTP não-200, corpo de erro explícito
identificando a credencial/provedor faltante (ex.: `"Credencial ausente para
o provedor 'aws'"`) — nunca uma resposta 200 silenciosa com array vazio.

## Cenário 6 — Provedor não reconhecido (Edge Case do spec.md)

1. Configurar `HARVEST_LLM_PROVIDER=openai` (valor não suportado) no
   Gateway.
2. Rodar `scripts/harvest-patterns.sh . --dry-run`.

**Resultado esperado**: erro claro citando que `openai` não é um dos 3
provedores reconhecidos (`azure`, `google`, `aws`) — não roteia para nenhum
conector por engano.
