# Contract: Issue Template Parity Validator

**Componente**: `scripts/validate-issue-template-parity.sh`

## Entrada

- Caminho do template de issue do preset `nimbus-code-standards`:
  `presets/nimbus-code-standards/templates/project-root/.github/ISSUE_TEMPLATE/nimbus-code-task.md`
- Caminho do template de issue do preset `nimbus-code-platform-standards`:
  `presets/nimbus-code-platform-standards/templates/project-root/.github/ISSUE_TEMPLATE/nimbus-code-task.md`

## Regra de validação

Extrair a lista ordenada de headings `##` de cada arquivo e comparar:

```text
## Contexto
## Objetivo
## Resultado Esperado
## Critérios de Aceite
## Passos Operacionais
## Dependências
## Responsável
## Estimativa de Esforço
## Referência
```

- **Pass**: as duas listas são idênticas (mesmos headings, mesma ordem)
- **Fail**: qualquer diferença — heading ausente, extra, ou fora de ordem;
  imprime diff exato dos headings divergentes

## Saída

```text
$ ./scripts/validate-issue-template-parity.sh
✅ Templates de issue idênticos entre nimbus-code-standards e nimbus-code-platform-standards

# ou, em caso de falha:
❌ Divergência encontrada:
  nimbus-code-platform-standards está faltando: ## Estimativa de Esforço
  Exit code: 1
```

## Uso em CI

Workflow `.github/workflows/validate-issue-template-parity.yml` roda este script
em todo PR que altere qualquer um dos dois arquivos de template, bloqueando o
merge em caso de divergência (AC-2, SC-002).
