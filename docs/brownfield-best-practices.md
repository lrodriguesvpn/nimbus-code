# Boas Práticas Brownfield com Spec Kit

Este documento é uma **referência profunda** de como trabalhar com Spec Kit em
repositórios já existentes (brownfield). Para um guia passo a passo rápido, ver
[`docs/developer-guide.md`](developer-guide.md#2-repositório-existente-sem-spec-kit-brownfield).

## Por que brownfield é diferente

A maioria dos walkthroughs do Spec Kit documenta greenfield: você começa do
zero, escreve constituição + spec do zero, tudo é novo. Brownfield é o oposto:
código já existe, padrões já estão estabelecidos (mesmo que implícitos), e
freqüentemente há um backlog/histórico de decisões já tomadas.

O Spec Kit **funciona em brownfield** (ver
[walkthrough oficial do próprio time do Spec Kit](https://github.com/mnriem/spec-kit-aspnet-brownfield-demo)
aplicado a uma CMS .NET com ~307k linhas), mas o fluxo é **3 passos mais
longo** que greenfield porque o agente precisa **aprender o código antes de
especificar**.

## A Constituição é o passo crítico

Em greenfield, `/speckit.constitution` é rápido: você define os princípios que
quer ("TDD", "functional programming", etc.) e segue.

Em brownfield, **a constituição é um ato de **escaneamento e derivação***:

1. O agente lê a estrutura de pastas.
2. Identifica o stack (linguagens, frameworks, libs, padrões de arquitetura).
3. Analisa testes existentes (cobertura, abordagem, qualidade).
4. Observa convenções de nomenclatura e estrutura de módulos.
5. Procura por padrões de erro handling, logging, validação.
6. Nota o que já é testado vs. o que não é.
7. Cria princípios que **refletem a realidade**, não um ideal genérico.

**Isso leva iterações.** O prompt recomendado (seção 2.3 do `developer-guide.md`)
pede explicitamente "use múltiplas iterações", porque uma análise superficial
(um pass rápido pelo código) quase sempre perde nuances.

Você pode validar o resultado — às vezes o agente interpreta padrões errado ou
superestima certas convenções. Nesse caso, **edite `constitution.md`
manualmente**. É documento vivo.

## Artefatos SDD em brownfield: qual é a ordem?

Ordem esperada:

```
1. constitution.md   ← derivada do código existente (requer iterações)
2. spec.md           ← a feature NOVA (não retro-especifique tudo)
3. plan.md           ← plano técnico (usa stack já aprendido em step 1)
4. tasks.md          ← tarefas ordenadas por dependência
5. implement         ← executa as tarefas (múltiplos passes em repo grande)
6. converge          ← compara código real vs spec/plan/tasks, anexa gaps
                       (repita 5-6 até "✅ Converged")
```

**Não pule a constituição.** Tentadores iniciais ("vamos só especificar a
feature, pulamos a const"):

- ❌ Agente faz suposições contraditórias sobre stack/padrões a cada comando.
- ❌ Cada feature termina com um `plan.md` que contradiz o anterior (pois não
  há princípios comuns).
- ❌ Você acaba corrigindo/reescrevendo planos/tarefas manualmente.

**Custoso acelerar; econômico investir cedo.**

## Múltiplos passes de implement → converge

Repos brownfield grandes frequentemente têm:

- Código legado que já toca a mesma área.
- Dependências internas complexas.
- Testes incompletos.
- Artefatos de compilação/build não óbvios.

Por isso, é muito comum:

```
Pass 1: /speckit.implement → completa tarefas 1-5, agente marca tarefas 6-10
        como "requer validação do developer" ou encontra erro em compilação.
Validar output do pass 1.

Pass 2: /speckit.implement → completa tarefas 6-10.
Validar output do pass 2.

/speckit.converge → encontra 3 gaps (ex.: falta testes de integração).
Converge anexa essas 3 como novas tarefas.

Pass 3: /speckit.implement → completa as 3 tarefas de gap.

/speckit.converge → ✅ Converged. Fim.
```

Isso **não é sinal de falha** — é esperado. O agente está explorando o código
real e identificando lacunas que a spec original não cobria. Converge é
append-only (nunca edita/apaga código já escrito), então é seguro rodar
quantas vezes for necessário.

**Dica prática**: após cada pass de `implement`, sempre rode `/speckit.converge`
antes de seguir para a próxima feature. Nunca deixe gaps pendentes.

## Quando editar artefatos SDD manualmente vs. regenerar

### Editar manualmente (OK):

- Adicionar observações/contexto em comentários dentro de `spec.md`/`plan.md`.
- Atualizar `constitution.md` se princípios derivados estão errados/incompletos.
- Adicionar tags/labels para rastreamento em `tasks.md` (ex.: `[DEVOPS]`,
  `[SECURITY]`).

### Regenerar com o comando (recomendado):

- **Mudar requisito** (parte da spec) → `/speckit.specify` de novo
- **Mudar design/stack** (parte do plano) → `/speckit.plan` de novo
- **Mudar dependências entre tarefas** → `/speckit.tasks` de novo

Por quê? Porque a alteração propaga — se você muda spec manualmente mas o
`plan.md` antigo fica, o `plan.md` fica inconsistente com a spec. Regenerar
mantém tudo coerente.

Exceção: edições em `constitution.md` (princípios) — são menos frágeis e
mudanças manuais lá são seguras.

## Lidando com código legado não testado

Cenário comum: repo brownfield com lógica crítica não testada (ou testada só
com testes frágeis).

O Spec Kit **exige testes de integração** (ver
[`docs/ai-code-quality-and-observability.md`](ai-code-quality-and-observability.md#2-testes-de-integração-cobrindo-os-critérios-de-aceitação)):
cada critério de aceitação do `spec.md` deve ter um teste de integração
automatizado correspondente.

Em brownfield, isso se torna: **você não pode especificar uma feature que
altera código legado não testado sem antes adicionar testes mínimos ao código
antigo**. Isso pode ser um push-back legítimo no `plan.md`:

```
Risco: o módulo de processamento de pedidos (ordem.py) não tem testes
de integração. Antes de adicionar a feature de "múltiplas moedas" que
altera esse módulo, precisamos de testes baseline do comportamento atual.

Recomendação: adicionar 3-4 testes de integração cobrindo os fluxos
críticos de processamento de pedidos (plano de 2-3 dias de trabalho).
Depois disso, a feature de "múltiplas moedas" fica segura de testar.
```

Esse é um cenário legítimo onde o agente marca `implement` como bloqueado até
que o dev manualmente adicione testes de baseline. É bom — força qualidade para
cima.

## Integrando com backlog externo (Azure DevOps / JIRA) em brownfield

Brownfield frequentemente já tem um backlog cheio de cards — algumas features
já em andamento, outras já fechadas.

O Spec Kit não importa o backlog inteiro automaticamente, mas você pode:

1. **Ler contexto histórico**: antes de `/speckit.specify`, peça ao agente (via
   prompt manual) um resumo dos cards relacionados dos últimos meses (seção 2.4
   do `developer-guide.md`). Isso entra como contexto adicional.

2. **Importar card único**: se há um card específico que você quer usar como
   ponto de partida (ex.: PROJ-1234), use o prompt de importação (seção 3 do
   `developer-guide.md`).

3. **Sincronizar spec → board**: depois de gerar `spec.md` e `tasks.md`, a
   extensão `vpndev-backlog-sync` pode sincronizar **para** o board (hooks
   `after_specify`/`after_tasks`, opcionais). Isso é o caminho **oposto** ao
   import acima — você mantém a spec como source-of-truth, e o board fica
   espelhado (não é o contrário).

**Ponto crítico**: em brownfield com backlog, a spec gerada pelo Spec Kit pode
divergir do que o board esperava (porque o Spec Kit refinou requisitos com
clarify/checklist). Nesse caso, **a spec é a verdade** — o board é derivado
dela, não o contrário. Comunique a divergência ao PO antes de sincronizar.

## Branches e PRs com Spec Kit em brownfield

Em brownfield, suas features Spec Kit usualmente vão para PRs como qualquer
outra mudança de código. Recomendação:

```
1. Nova branch: git checkout -b feature/meu-card-123-descricao
2. Rodaprincipal init --here se primeira feature, ou pule se já feito
3. /speckit.specify → gera spec.md
4. /speckit.plan → gera plan.md
5. /speckit.tasks → gera tasks.md
6. Commit: git add .specify/features/ && git commit -m "spec: meu-card-123"
7. /speckit.implement → implementa tarefas
8. /speckit.converge → checa gaps
9. Commit: git add . && git commit -m "implement: meu-card-123 — converged"
10. git push origin feature/meu-card-123-descricao
11. Abra PR normal
12. Revisão: dev + Copilot code review (obrigatória, ver
    docs/ai-code-quality-and-observability.md)
13. Merge
```

O `.specify/` fica versionado (incluindo `spec.md`, `plan.md`, `tasks.md`), então
o histórico de decisões fica no git. Isso é útil para arqueologia futura
("por que fizemos X assim?").

## Migrando incrementalmente um projeto brownfield para Spec Kit

Se o projeto tem **muitas features já em andamento** (não é dia 1), como
integrar Spec Kit sem quebrar tudo?

Abordagem **low-risk**:

1. **Dia 1**: instale o Spec Kit (section 2.1-2.2 do `developer-guide.md`).
   Gere constituição profunda. Nenhuma feature nova ainda.
2. **Semana 1**: próxima feature que chegar, use Spec Kit completo (spec →
   plan → tasks → implement → converge). Essa se torna a "prova de conceito".
3. **Dia 7 forward**: features subsequentes usam Spec Kit. As antigos features
   já em andamento continuam sem Spec Kit (não vale retro-especificar).
4. **3-6 meses after**: a maioria das features ativas usa Spec Kit. Histórico
   do projeto agora é "pre-Spec Kit" (caótico) e "post-Spec Kit" (estruturado).

Isso é seguro e permite ramp-up gradual da equipe.

## Troubleshooting brownfield comum

### Problema: `/speckit.constitution` leva muito tempo e o agente não converge

**Causa**: repo muito grande ou estrutura interna complexa faz o agente perder
o fio.

**Solução**:
- Reduza o escopo inicial: se o repo tem 50 módulos, focar `/speckit.constitution`
  só nos 3-5 mais críticos inicialmente.
- Parta de um "slice" do código (ex.: "considere como principais os módulos em
  `src/core/` e não se preocupe com o resto por agora").
- Deixe o agente rodar 2-3 iterações, depois edite `constitution.md`
  manualmente finalizando (é documento vivo, não precisa ser 100% automático).

### Problema: `tasks.md` tem 50+ tarefas, tudo parece importante, agente não sabe por onde começar

**Causa**: feature especificada era grande demais; ou spec foi ambígua.

**Solução**:
- Reegere `/speckit.tasks` pedindo explicitamente phases menores ("separe em
  3 phases: Setup, Core, Polish, com máx 10 tarefas cada").
- Ou volte a `/speckit.clarify` / `/speckit.specify` redefinindo escopo menor
  ("só implementar leitura primeiro, escrita é v2").

### Problema: `implement` começou bem mas falhou no meio (compilação, erro de teste)

**Esperado** em brownfield grande. Opções:

- Se erro é óbvio (typo, import faltando), corrija manualmente, commit, e rode
  `/speckit.implement` de novo (vai continuar do próximo task).
- Se erro é conceitual, volta a `/speckit.plan` ou `/speckit.tasks`, regenera,
  rodeia `/speckit.implement` novamente.

Nunca force a conclusão se houver erro; converge vai pegar depois.

### Problema: `/speckit.converge` acha muitos gaps mesmo depois de implement

**Esperado** em brownfield. Gaps podem ser:

- Testes de integração faltando (esperado, feature foi criada, testes ainda
  não).
- Edge cases não cobertos (agente foi conservador no `plan.md`, encontrou
  mais casos na prática).
- Documentação faltando.

Rode `/speckit.implement` novamente nas tarefas de gap, depois `/speckit.converge`
de novo. Repita até converged.

## Referências

- [`developer-guide.md`](developer-guide.md) — passo a passo rápido (brownfield
  é a seção 2).
- [`bundle-architecture.md`](bundle-architecture.md) — como preset + extensão +
  workflow se compõem.
- [`ai-code-quality-and-observability.md`](ai-code-quality-and-observability.md) —
  regras de qualidade que valem para todas as features (novo ou brownfield).
- [Walkthrough oficial de brownfield do time do Spec Kit](https://github.com/mnriem/spec-kit-aspnet-brownfield-demo) —
  demonstração real em ~307k linhas de C# .NET.
