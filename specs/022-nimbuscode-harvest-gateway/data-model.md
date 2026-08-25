# Data Model: Nimbus Harvest Gateway

## Entidades

### HarvestRequest

Payload recebido pelo Gateway — herda integralmente o contrato já existente
de `scripts/harvest-patterns.sh` (SPEC-014). Nenhum campo novo é introduzido.

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `repo` | string | Sim | Caminho/identificador do repositório sendo varrido |
| `stack` | string | Sim | Stack detectada (`java`, `node`, `go`, `python`, `unknown`) |
| `prompt` | string | Sim | Instrução fixa (definida em `harvest-patterns.sh`) pedindo identificação de padrões arquiteturais |
| `metadata` | array de objetos `{file, line, signature}` | Sim | Metadados estruturais extraídos — nunca corpo de método, string literal ou dado de runtime (Security Gate, ADL-004 de SPEC-014) |

**Validação**: `repo`, `stack` e `prompt` não podem ser vazios; `metadata` deve
ser um array (pode ser vazio, resultando em `entries: []` na resposta).

### HarvestResponse

Resposta devolvida pelo Gateway — mesmo formato que `harvest-patterns.sh` já
espera hoje.

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `tag` | string (kebab-case) | Sim | Identificador curto do padrão detectado |
| `description` | string | Sim | 1-2 frases descrevendo o padrão |
| `example` | string | Sim | Assinatura mais representativa que evidencia o padrão |
| `source_file` | string | Sim | Arquivo de origem do exemplo |
| `source_line` | string/int | Sim | Linha de origem do exemplo |
| `tokens_used` (opcional, no envelope da resposta, não por item) | number | Não | Usado por `harvest-patterns.sh` para log de custo (T019) |
| `estimated_cost` (opcional, no envelope) | number | Não | Idem |

**Validação**: se nenhum padrão for identificável, a resposta é um array
vazio `[]` — nunca omitido nem substituído por erro.

### ProviderConfig

Configuração interna do Gateway (não trafega na rede) — resolvida a partir de
variáveis de ambiente a cada requisição.

| Campo | Tipo | Origem | Descrição |
|---|---|---|---|
| `provider` | enum (`azure`, `google`, `aws`) | `HARVEST_LLM_PROVIDER` | Conector ativo |
| `model` | string | `HARVEST_AZURE_MODEL` / `HARVEST_GOOGLE_MODEL` / `HARVEST_AWS_MODEL` (conforme `provider`) | Modelo específico dentro do provedor |
| `credentials` | objeto (nunca logado/persistido) | Azure Key Vault / App Settings, por provedor | Credenciais de acesso ao SDK do provedor |

**Validação**: se `provider` não for um dos 3 valores reconhecidos, ou se
`model`/`credentials` estiverem ausentes para o provedor selecionado, o
Gateway rejeita a requisição com erro explícito (FR-006, FR-009, AC-7) — não
há fallback silencioso para outro provedor.

### ObservabilityRecord

Registro de observabilidade — um por requisição processada, com ou sem
sucesso. Persistido no Application Insights (Azure Monitor), não em banco de
dados próprio.

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `timestamp` | datetime (ISO 8601) | Sim | Momento da requisição |
| `repo` | string | Sim | Repositório de origem (do `HarvestRequest.repo`) |
| `provider` | enum (`azure`, `google`, `aws`) | Sim | Provedor usado nesta chamada |
| `model` | string | Sim | Modelo usado nesta chamada |
| `status` | enum (`success`, `failure`) | Sim | Resultado da chamada |
| `failure_reason` | string | Não (obrigatório se `status=failure`) | Motivo explícito (ex.: "credencial ausente para provedor google") |
| `tokens_used` | number | Não (quando disponível pelo SDK do provedor) | Tokens consumidos nesta chamada |
| `estimated_cost` | number | Não | Custo estimado desta chamada, na moeda/unidade que o provedor reportar |

**Relação**: um `HarvestRequest` gera exatamente um `ObservabilityRecord`,
independente de sucesso ou falha (FR-005, AC-6).

## Diagrama de Relacionamento

```text
HarvestRequest ──(processado por)──> ProviderConfig (resolvido do ambiente)
      │                                      │
      │                                      ▼
      │                              LLMConnector.complete()
      │                                      │
      ▼                                      ▼
HarvestResponse <──(retornado ao chamador)── ObservabilityRecord (sempre gravado)
```

## Notas

- Nenhuma entidade desta feature introduz persistência de dado de negócio
  (banco de dados) — `ObservabilityRecord` vive em Application Insights,
  não em uma tabela própria, mantendo o serviço stateless (ver Technical
  Context do `plan.md`).
- `HarvestRequest`/`HarvestResponse` são deliberadamente idênticos ao
  contrato já existente de `scripts/harvest-patterns.sh` — qualquer mudança
  neles está fora de escopo desta feature (ver "Fora de escopo" no
  `spec.md`).
