# Data Model: Correção da Composição Real de Templates

## Conceitos

### Template Layer

Representa uma camada candidata de template encontrada no stack de resolução.

**Campos conceituais**
- `path`: caminho absoluto do arquivo
- `strategy`: `replace` | `prepend` | `append` | `wrap`
- `priority`: ordem de precedência na pilha
- `source`: `override` | `preset` | `extension` | `core`

### Composed Template

Resultado final já resolvido da composição.

**Campos conceituais**
- `template_name`: nome lógico do template
- `content`: texto final composto
- `origin_layers`: lista ordenada das camadas que contribuíram
- `materialized_path`: caminho do arquivo materializado, quando aplicável

## Regras de validação

- `replace` vence integralmente quando é a camada de maior prioridade aplicável.
- `prepend` adiciona conteúdo antes da base efetiva.
- `append` adiciona conteúdo depois da base efetiva.
- `wrap` exige o placeholder `{CORE_TEMPLATE}`.
- Ausência de preset continua retornando o template nativo.
- `setup-tasks.sh` deve sempre devolver um path válido para o arquivo materializado.
