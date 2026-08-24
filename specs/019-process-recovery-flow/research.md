# Research: Process Recovery Flow for Existing Specs

## Objective

Definir o caminho operacional correto quando uma feature Nimbus Code já possui
`spec.md`, `plan.md` e/ou `tasks.md`, mas surgem erros funcionais, erros
arquiteturais ou expansão de escopo durante a execução.

## Decisions

### 1) `clarify` só entra quando a ambiguidade está na intenção da feature

**Decision**: usar `clarify` apenas quando a equipe descobrir que a própria
`spec.md` está ambígua, incompleta ou contraditória.

**Rationale**: `clarify` resolve incerteza semântica da fonte de verdade; ele
não é mecanismo de correção de código nem de replanejamento técnico por si só.

**Alternatives considered**:
- Rodar `clarify` sempre que surgir qualquer erro
- Tratar `clarify` como substituto de `converge`
- Corrigir ambiguidades apenas oralmente, sem atualizar a spec

### 2) `converge` permanece append-only em `tasks.md`

**Decision**: manter `converge` como etapa de fechamento de gap entre artefatos
existentes e implementação real, sem qualquer autorização para reescrever
`spec.md` ou `plan.md`.

**Rationale**: isso preserva a divisão de responsabilidades do fluxo
`specify -> plan -> tasks -> implement -> converge` e evita que o agente altere
a intenção da feature silenciosamente no fim do ciclo.

**Alternatives considered**:
- Permitir que `converge` edite `spec.md`
- Permitir que `converge` “conserte” `plan.md`
- Reabrir sempre o ciclo do zero em toda divergência

### 3) A regra padrão é atualizar a mesma feature quando o recorte de valor permanece

**Decision**: se o objetivo de negócio continuar o mesmo, a correção deve
acontecer na mesma spec/plan/tasks, e não em uma nova spec.

**Rationale**: abrir nova spec cedo demais fragmenta histórico, duplica
rastreabilidade e incentiva esconder correções como se fossem novas entregas.

**Alternatives considered**:
- Abrir uma nova spec a cada erro descoberto
- Tratar toda mudança de arquitetura como nova feature
- Manter o problema só em issue/PR sem refletir nos artefatos SDD

### 4) Nova spec só existe quando nasce um novo recorte de valor

**Decision**: abrir nova spec somente quando surgir nova entrega de valor,
rollout próprio, owner próprio ou um novo escopo independente da feature
original.

**Rationale**: esse corte mantém a spec como unidade de valor, não como unidade
de “qualquer trabalho residual”.

**Alternatives considered**:
- Abrir nova spec por conveniência administrativa
- Nunca abrir nova spec, mesmo quando o escopo muda completamente

### 5) Edge cases não quebram a regra padrão de permanecer na mesma feature

**Decision**: edge cases como descoberta do erro antes do `plan.md`, depois do
merge em produção ou em cenários que “parecem” nova feature não quebram a regra
padrão: permanecer na mesma feature enquanto o recorte de valor continuar o mesmo.

**Rationale**: sem essa regra explícita, times diferentes podem abrir nova spec
cedo demais, esconder correções como escopo novo ou tratar correção de rota como
mero retrabalho técnico sem atualizar a fonte de verdade.

**Alternatives considered**:
- Abrir nova spec sempre que o problema parecer “grande”
- Tratar bugs pós-merge como fluxo totalmente separado da correção de rota
- Adiar a correção da `spec.md` até que o `plan.md` exista
