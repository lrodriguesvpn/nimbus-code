# Contract: Template Composition

## Function contract

`resolve_template_content(template_name, repo_root) -> composed content string | exit 1`

### Input

- `template_name`: nome do template sem extensão.
- `repo_root`: raiz do repositório que contém `.specify/`.

### Output

- stdout: conteúdo final já composto.
- exit code `0` quando ao menos uma camada é resolvida.
- exit code `1` quando nenhuma camada aplicável é encontrada.

### Semantics

- Camadas são avaliadas por prioridade.
- `replace` retorna apenas a camada mais prioritária aplicável.
- `prepend` concatena antes da base.
- `append` concatena depois da base.
- `wrap` substitui `{CORE_TEMPLATE}` pelo conteúdo base.
- Composição com mais de duas camadas deve continuar recursivamente.
- Repositório sem preset instalado retorna apenas o template nativo.

## Materialization contract by consumer

### `create-new-feature.sh`

- Deve escrever o conteúdo composto de `spec-template` em `$SPEC_FILE`.
- Se o template não for resolvido, deve manter o fallback atual de arquivo vazio.

### `setup-plan.sh`

- Deve escrever o conteúdo composto de `plan-template` em `$IMPL_PLAN`.
- Se o template não for resolvido, deve manter o fallback atual de arquivo vazio.

### `setup-tasks.sh`

- Deve materializar o conteúdo composto de `tasks-template` em um arquivo temporário absoluto.
- Deve retornar esse caminho em `TASKS_TEMPLATE`.
- O contrato de path deve ser preservado; o consumidor continua lendo arquivo, não string.
