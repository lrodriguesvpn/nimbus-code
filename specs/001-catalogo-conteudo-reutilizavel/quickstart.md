# quickstart.md — Feature 001: Catálogo de Conteúdo Reutilizável

> Guia de validação retroativo — a feature já está implementada; este
> documento prova que os artefatos entregues existem e funcionam como
> descrito no `spec.md`, em vez de guiar uma implementação futura.

## Cenário 1 — Princípio "referenciar por ponteiro" presente na constituição (AC-1)

```bash
grep -n "Referenciar por ponteiro" .specify/memory/constitution.md
```

**Resultado esperado**: uma ocorrência, dentro da seção "Reutilização de
Conteúdo e Referência por Ponteiro". Confirmado nesta sessão (linha ~105).

## Cenário 2 — Catálogo de reuso existe e é YAML válido (AC-2)

```bash
python3 -c "import yaml; d = yaml.safe_load(open('docs/reuse-catalog.yaml')); print(len(d['entries']), 'entradas')"
```

**Resultado esperado**: parse bem-sucedido, sem erro de sintaxe, com pelo
menos 1 entrada (a própria feature 001 idealmente deveria ter uma entrada
sobre si mesma — ver Edge Case abaixo).

## Cenário 3 — TL;DR presente em docs de referência longos (AC-3)

```bash
head -20 docs/ai-code-quality-and-observability.md
```

**Resultado esperado**: um resumo curto (2-3 linhas) próximo ao topo do
arquivo, antes do conteúdo detalhado seção por seção.

## Cenário 4 — Campo "Padrão reutilizado encontrado?" presente e em uso (AC-4)

```bash
grep -l "Padrão reutilizado encontrado" presets/nimbus-code-standards/templates/plan-template.md specs/*/plan.md
```

**Resultado esperado**: o `plan-template.md` do preset tem o campo; e a
maioria dos `plan.md` de features 002 em diante também o tem preenchido
(evidência de adoção real, não só de template disponível).

## Nota sobre auto-referência do catálogo

Um gap observado ao escrever este `quickstart.md` retroativo: `docs/reuse-catalog.yaml`
**não tem uma entrada apontando para a própria feature 001** (o padrão de
"catálogo de reuso" em si). Isso é consistente — a feature 001 introduziu o
mecanismo, não havia catálogo anterior para registrar "catálogo de reuso" como
um padrão reutilizável de si mesmo. Não é um bug; é só uma observação para
quem for auditar o arquivo e notar essa ausência aparente.
