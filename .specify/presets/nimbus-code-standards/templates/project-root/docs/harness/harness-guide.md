# Guia Harness Engineering — Para Devs e Agentes

## O que é o Harness?

O **Harness Catalog** (`docs/harness/harness-catalog.yaml`) é a memória
organizacional do NIMBUS CODE: um catálogo estruturado de erros, incidentes e
retrabalhos que já aconteceram em projetos que usam este workflow.

Diferente do `reuse-catalog.yaml` (que cataloga *soluções bem-sucedidas*), o
harness cataloga **o que deu errado** — e como evitar que dê errado de novo.

---

## Para Agentes: Protocolo de Consulta Obrigatória

### Antes de qualquer `/nimbus-code-plan`

```
1. Abrir docs/harness/harness-catalog.yaml
2. Filtrar entradas por:
   - tags relacionadas ao domínio da feature
   - bounded_context igual ou similar ao da feature
3. Para cada match encontrado:
   - Ler error_pattern, root_cause e prevention
   - Avaliar se este projeto pode incorrer no mesmo padrão
4. Declarar no plan.md (seção "Harness Consultado"):
   - IDs dos harnesses consultados
   - Se houve match: como a prevenção será aplicada
   - Se não houve match: "Nenhum padrão de erro relevante encontrado"
```

### Durante a implementação

- Se você (agente) perceber que está prestes a cometer um padrão catalogado no
  harness, **pare imediatamente** e informe o Dev antes de continuar.
- Se encontrar um bug fora do escopo da sessão: **abra uma Issue** com `type:bug`,
  não corrija inline (ver HRN-0001).
- Se identificar divergência arquitetural: **não implemente silenciosamente** em
  nenhuma direção (ver HRN-0002).

### Ao fechar uma feature com retrabalho ou incidente

```
1. Verificar se algum dos gatilhos se aplica:
   - Retrabalho > 20% do esforço estimado?
   - Incidente chegou a produção ou causou rollback?
   - Decisão arquitetural foi revertida?
   - Erro de agente documentado?
2. Se sim:
   a. Abrir Issue com labels: type:incident (ou type:bug) + harness:pending
   b. Preencher docs/harness/incident-template.md
   c. Adicionar entrada em docs/harness/harness-catalog.yaml
   d. Fechar Issue com harness:cataloged
```

---

## Para Devs: Como Escrever uma Boa Entrada de Harness

### Princípios

1. **Específico, não genérico.** "Sempre teste o rollback antes de deploy" é
   inútil — "Deploy do serviço X sem testar rollback do schema de banco causou
   downtime de 2h porque a migration era irreversível" é acionável.

2. **Sem culpa, com sistema.** O campo `root_cause` deve apontar para uma falha
   do processo/sistema, não de uma pessoa. Todo "erro humano" tem um processo por
   trás que o permitiu.

3. **Prevention é o campo mais importante.** Deve ser uma instrução direta ao
   agente/dev: "DEVE fazer X antes de Y", "NUNCA faça Z sem antes verificar W".

4. **Tags são a chave de busca.** Use tags específicas e reutilizáveis em kebab-case.
   Tags genéricas demais (`erro`, `bug`) não ajudam na descoberta.

### Exemplo de entrada bem escrita

```yaml
- id: HRN-0042
  date: 2026-10-15
  complexity: S3
  bounded_context: billing-service
  error_pattern: >
    Migration de schema adicionou coluna NOT NULL sem DEFAULT em tabela com dados
    em produção, causando falha silenciosa em inserts durante o deploy.
  root_cause: >
    O script de migration foi testado apenas em banco vazio (ambiente de dev).
    Não havia gate de validação de migration contra banco com dados reais no CI.
    O impact-map.md não incluiu o cenário de tabela com dados pré-existentes.
  impact: >
    Downtime de 45min na feature de emissão de notas; 120 transações falharam
    silenciosamente; 3h de retrabalho para corrigir dados inconsistentes.
  fix_applied: >
    Rollback da migration + redeploy com versão anterior; nova migration com
    DEFAULT temporário + backfill + remoção do DEFAULT em fase subsequente.
  prevention: >
    Toda migration de schema em S3/S4 DEVE ser testada contra dump do banco de
    produção anonimizado no CI antes do merge. O impact-map.md DEVE incluir
    cenário de tabela com dados pré-existentes. Migrations que adicionam
    NOT NULL sem DEFAULT devem ser divididas em 3 fases: (1) adicionar coluna
    com DEFAULT, (2) backfill, (3) adicionar constraint NOT NULL.
  tags:
    - database-migration-risk
    - schema-change
    - not-null-without-default
    - ci-gap
    - billing-service
  source_pr: "https://ghe.example.com/org/repo/pull/123"
  similar_contexts:
    - payment-service
    - subscription-service
```

---

## Buscando no Catálogo

### Busca por tags (CLI)

```bash
# Encontrar todas as entradas com tag específica
grep -A 20 "tags:" docs/harness/harness-catalog.yaml | grep "database-migration"

# Listar todos os IDs e error_patterns
grep -E "^  - id:|error_pattern:" docs/harness/harness-catalog.yaml
```

### Busca por bounded_context

```bash
grep -A 5 "bounded_context: billing" docs/harness/harness-catalog.yaml
```

### Script de busca (se disponível)

```bash
./scripts/harness-search.sh database-migration billing-service
```

---

## Ciclo de Vida de uma Entrada

```
Incidente/retrabalho detectado
        ↓
Issue aberta: harness:pending
        ↓
incident-template.md preenchido
        ↓
Entrada adicionada ao harness-catalog.yaml
        ↓
PR com a entrada mergeado
        ↓
Issue fechada: harness:cataloged
        ↓
[Próximas features consultam esta entrada antes de planejar]
```

---

## Diferença entre Harness Catalog e Reuse Catalog

| | `reuse-catalog.yaml` | `harness-catalog.yaml` |
|---|---|---|
| **Cataloga** | Soluções bem-sucedidas reutilizáveis | Erros, falhas e lições aprendidas |
| **Quando consultar** | Antes de *desenhar* uma solução | Antes de *planejar* qualquer feature |
| **Valor** | "Não reinvente a roda" | "Não repita o erro" |
| **Entry trigger** | Feature entregue com padrão reaproveitável | Retrabalho > 20%, incidente, erro de agente |

Ambos devem ser consultados no início de todo `/nimbus-code-plan`.

---

## FAQ

**"Tenho que preencher o harness para todo bug menor?"**
Não. Apenas quando o gatilho se aplica: retrabalho > 20%, incidente em produção,
decisão arquitetural revertida, ou erro de agente documentado. Bugs triviais de
implementação não precisam de entrada.

**"Quem é responsável por preencher o harness?"**
O Dev que conduziu o pós-incidente, ou o agente em modo autônomo S2 quando a
tarefa de catalogação for marcada `agent:autonomous-ok`. Para S3/S4 com incidente
em produção, revisão humana é obrigatória antes do merge da entrada.

**"O harness é público ou restrito?"**
Segue a visibilidade do repositório. Para projetos com dado sensível no `source_pr`,
deixe o campo vazio (`""`) — a lição deve ser catalogada mesmo sem o link público.

**"E se a prevenção for contraditória com outra entrada?"**
Abra um PR atualizando ambas as entradas com uma resolução explícita. Conflitos
entre lições são informação valiosa — não apague a antiga, contextualize.
