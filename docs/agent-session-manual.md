# Manual de Uso de Sessões Remotas com Agentes de Codificação

> **TL;DR:** 1 agente = 1 branch = 1 fase = conjunto fechado de arquivos. Nada
> muda sem aprovação via PR. Branches sem PR em 3 dias são deletadas. Tasks
> grandes são divididas em fases antes de iniciar qualquer sessão.

---

## 1. O que é uma Sessão Remota de Agente

Uma **sessão remota** é uma execução do GitHub Copilot Coding Agent (ou
equivalente) iniciada pelo Dev para um conjunto delimitado de trabalho — uma
fase de uma feature, não uma feature inteira de uma vez. A sessão:

- Cria ou trabalha em um branch existente
- Produz commits e abre um PR ao final
- **Não faz merge** — merge é sempre responsabilidade do Dev após revisão
- É **descartável por design**: se a sessão produzir resultado ruim, o branch é
  deletado e uma nova sessão começa com instrução mais precisa

Cada sessão consome tokens. Sessões mal-delimitadas (escopo grande, instrução
vaga) desperdiçam tokens e geram PRs difíceis de revisar. A regra é: **quanto
menor e mais preciso o escopo, melhor o resultado e menor o custo.**

---

## 2. Modelo de Branches

### Estrutura obrigatória

```
main          ← protegida; nunca editar diretamente; tag de release aqui
  └── develop ← integração; merge só via PR aprovado pelo Dev
        └── feature/fase-{N}-{slug-da-feature}  ← agente trabalha aqui
```

### Regras de nomeação

| Tipo | Padrão | Exemplo |
|---|---|---|
| Feature (agente) | `feature/fase-{N}-{slug}` | `feature/fase-2-api-pedidos` |
| Hotfix (agente) | `fix/fase-{N}-{slug}` | `fix/fase-1-validacao-cpf` |
| Documentação | `docs/{slug}` | `docs/manual-agentes` |

### Ciclo de vida do branch

```
Dev cria branch → Agente commita → Agente abre PR → Dev revisa → Merge → Branch deletada
```

- Branch **sem PR**: deletar após 3 dias de inatividade
- Branch **com PR rejeitado**: o Dev decide: nova sessão no mesmo branch ou
  deleta e recomeça
- Branch **mergeada**: deletar imediatamente após o merge (automático se
  configurado no GitHub)

---

## 3. Planejamento em Fases Antes de Qualquer Sessão

**Nunca inicie uma sessão de agente sem ter as fases definidas.** O planejamento
em fases é o que impede que dois agentes editem o mesmo arquivo e que uma
feature inteira vire um PR monstruoso impossível de revisar.

### Como planejar fases

1. Identifique os arquivos que a feature precisa criar ou alterar
2. Agrupe-os em conjuntos que **não se sobreponham** — cada grupo é uma fase
3. Sequencie as fases (fase 2 depende do que a fase 1 entrega?)
4. Registre no `PLANEJAMENTO.md` do projeto (ou no `plan.md` da feature)

### Tamanho ideal de uma fase para um agente

| Limite | Regra |
|---|---|
| Arquivos por fase | Máximo **5 arquivos** alterados |
| Responsabilidade | Exatamente **1** (ex.: só repositório, só API, só testes) |
| Complexidade | No máximo **S2** por fase; S3/S4 → dividir mais |
| Dependência humana | Se a fase exige decisão de arquitetura → Dev decide antes, não o agente |

### Exemplo de divisão de fases

Feature: "Novo módulo de pedidos"

| Fase | Arquivos | Agente |
|---|---|---|
| 1 — Modelos | `models/order.ts`, `models/order-item.ts` | Sessão A |
| 2 — Repositório | `repositories/order-repo.ts` | Sessão B (após PR da fase 1 aprovado) |
| 3 — API | `routes/orders.ts`, `controllers/order-ctrl.ts` | Sessão C (após PR da fase 2 aprovado) |
| 4 — Testes | `tests/order.test.ts` | Sessão D (após PR da fase 3 aprovado) |

---

## 4. Regra de Isolamento: 1 Agente por Arquivo

**Dois agentes nunca podem editar o mesmo arquivo ao mesmo tempo.** Isso é a
causa mais comum de conflitos de merge, código duplicado e comportamento
inesperado.

### Como garantir o isolamento

- **Antes de iniciar uma sessão**, declare os arquivos que o agente vai tocar
  (campo `files_in_scope` no prompt)
- Se outro agente ainda não terminou sua fase e há sobreposição de arquivos →
  **aguardar o PR ser mergeado antes de iniciar a próxima sessão**
- Se um agente editar um arquivo fora do escopo declarado → fechar o PR, corrigir
  a instrução e abrir nova sessão

### Instrução-padrão para toda sessão de agente

Sempre iniciar a sessão com o bloco abaixo (adaptar os valores):

```
Fase: {N} — {descrição da fase}
Branch: feature/fase-{N}-{slug}
Você só pode criar ou editar os seguintes arquivos:
  - {arquivo 1}
  - {arquivo 2}
  - {arquivo 3}
Não altere nenhum arquivo fora desta lista.
Não faça merge — abra um PR para develop ao finalizar.
```

---

## 5. O que o Dev Não Deve Fazer

| ❌ Erro comum | ✅ Comportamento correto |
|---|---|
| Iniciar agente sem plano de fases | Definir fases e arquivos de escopo antes de abrir qualquer sessão |
| Pedir para o agente implementar a feature inteira | Dividir em fases e iniciar uma sessão por fase |
| Rodar 2 agentes no mesmo repositório ao mesmo tempo (com sobreposição de arquivos) | Esperar o PR da sessão anterior ser aprovado antes de iniciar a próxima |
| Dar instrução vaga ("melhora o código") | Dar escopo preciso: fase, arquivos, objetivo, critério de done |
| Aprovar PR sem revisar o diff arquivo por arquivo | Revisar cada arquivo alterado; verificar se o agente saiu do escopo |
| Deixar branch aberta sem PR | Abrir PR ou deletar o branch em até 24h |
| Pedir mudança enquanto o agente ainda está rodando | Esperar o PR, revisar, e só então abrir nova sessão |
| Fazer merge direto em main ou develop sem PR | Sempre via PR — nunca `git push --force` ou merge local direto |
| Reabrir branch já mergeada para "reaproveitar" | Criar branch nova com nome correto para a próxima fase |

---

## 6. Protocolo de Aprovação (Nada Muda sem Aprovação)

Toda mudança produzida por um agente **deve passar por PR** antes de chegar a
`develop` ou `main`. Não existe exceção.

### Checklist de revisão de PR (obrigatório antes de aprovar)

- [ ] O agente tocou **apenas** nos arquivos declarados no escopo da fase?
- [ ] Nenhum arquivo fora do escopo foi criado, deletado ou alterado?
- [ ] Testes passando (CI verde)?
- [ ] Nenhum segredo ou credencial commitada?
- [ ] A lógica implementada corresponde ao objetivo da fase?
- [ ] Sem regressões em testes anteriores (coverage não caiu)?
- [ ] Para S3/S4: `graph.yaml`, `graph.md` e `impact-map.md` atualizados?

### O que fazer quando o PR é rejeitado

1. Adicionar comentário no PR explicando o que está errado
2. Se a correção é simples → nova sessão no **mesmo branch** com instrução de
   correção
3. Se a sessão saiu muito do escopo → fechar o PR, deletar o branch, recomeçar
   com instrução mais precisa

---

## 7. Controle de Branches Perdidas

Uma **branch perdida** é qualquer branch que existe no repositório remoto e não
tem PR aberto associado **ou** que não teve commit há mais de 3 dias.

### Regras de limpeza

| Situação | Ação |
|---|---|
| Branch sem PR, inativa há ≥ 3 dias | Deletar |
| Branch com PR rejeitado, inativa há ≥ 7 dias | Deletar branch e fechar PR |
| Branch mergeada (PR já fechado como merged) | Deletar imediatamente (automático se configurado) |
| Branch de agente com CI vermelho, sem atividade há ≥ 3 dias | Deletar e registrar ocorrência |

### Como auditar branches perdidas (manual semanal)

```bash
# Listar branches remotas com data do último commit
git fetch --prune
git for-each-ref --sort=-committerdate refs/remotes/origin \
  --format='%(committerdate:short) %(refname:short)'
```

Compare com as branches que têm PRs abertos no GitHub. O delta são as
**branches perdidas** — deletar via `git push origin --delete <branch>` ou
pela interface do GitHub.

### Métrica PMO de branches perdidas

Registrar no GitHub Project o campo **"Branches Perdidas"** conforme definido
na seção "Métricas de Branches" do `tasks-template.md`. A métrica é auditada
semanalmente pelo Dev responsável.

---

## 8. Fluxo Resumido de uma Iteração

```
1. Dev define fases no plan.md (arquivos por fase, sem sobreposição)
         ↓
2. Dev cria branch: feature/fase-N-slug
         ↓
3. Dev inicia sessão do agente com escopo fechado (arquivos explícitos)
         ↓
4. Agente implementa, commita e abre PR para develop
         ↓
5. Dev revisa o diff com o checklist de PR
         ↓
6. Aprovado → merge + branch deletada
   Rejeitado → nova sessão de correção ou novo branch
         ↓
7. Dev define a próxima fase (só após merge da anterior)
```

---

## 9. Referências

- [Constituição VPN Dev](../presets/vpndev-standards/templates/constitution-template.md) — regras não-negociáveis de isolamento e fases
- [Copilot Instructions](../presets/vpndev-standards/templates/project-root/copilot-instructions.md) — regras operacionais injetadas no agente
- [Taxonomia de Labels](label-taxonomy-and-autonomous-dev.md) — como sinalizar issues para agentes autônomos
- [Modelo Híbrido e Custo](ai-code-quality-and-observability.md) — tokens, horas humanas e custo real
- [Grafos de Módulos](module-graphs.md) — graph.yaml, graph.md e Graph Guard
