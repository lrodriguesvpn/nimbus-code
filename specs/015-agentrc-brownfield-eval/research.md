# Research: AgentRC Brownfield Evaluation

## Objective

Determinar se o AgentRC do Microsoft Lab agrega valor ao fluxo atual de análise
de código brownfield do Nimbus Code, sem gerar conflito com mecanismos já
existentes.

## Decisions

### 1) Usar documentação pública como base da avaliação

**Decision**: Avaliar o AgentRC com base no README e na documentação pública do
projeto, cruzando isso com os artefatos internos já existentes neste repositório.

**Rationale**: O AgentRC se apresenta como experimental e sua proposta atual é
context engineering para agentes de codificação. Uma avaliação pública é
reprodutível, segura e suficiente para decidir se vale avançar para piloto.

**Alternatives considered**:
- Instalar e executar o AgentRC localmente agora
- Tratar apenas o README como fonte única
- Basear a decisão em relatos de terceiros

### 2) Comparar contra o fluxo Nimbus Code já existente

**Decision**: A comparação deve cobrir os mecanismos já estabelecidos aqui:
spec/plan/tasks, graph de contexto, catálogo de reuso, harness, hooks e
governança de templates.

**Rationale**: O risco real não é "AgentRC é bom ou ruim", e sim "ele resolve
algo novo ou apenas duplica valor já coberto".

**Alternatives considered**:
- Comparar só com `spec.md`
- Comparar só com o fluxo de tasks
- Comparar contra o template sem considerar docs e catálogos

### 3) Manter esta fase como avaliação, não integração

**Decision**: Não integrar AgentRC ao fluxo em qualquer nível operacional nesta
fase; a entrega termina em recomendação.

**Rationale**: O upstream é experimental e o repositório já possui um conjunto
robusto de controles próprios. Antes de criar mais uma camada, é preciso provar
ganho líquido.

**Alternatives considered**:
- Piloto imediato em um fluxo do template
- Troca parcial de tooling
- Abandono sem análise comparativa

### 4) Tratar o resultado como documento de decisão

**Decision**: A saída principal desta feature é um relatório comparativo com
recomendação e escopo de piloto, se aplicável.

**Rationale**: Isso reduz o risco de overengineering e permite decisão executiva
sem alterar o funcionamento do repositório.

**Alternatives considered**:
- Criar integração técnica agora
- Criar apenas uma nota de opinião
- Registrar a decisão apenas em issue

## Evidence Sources

- AgentRC README público (capabilities: Measure, Generate, Maintain)
- `docs/ai-code-quality-and-observability.md`
- `specs/014-brownfield-multirepo-context-awareness/spec.md`
- `specs/011-harness-engineering/spec.md`
- `specs/016-hybrid-agent-human-dev/spec.md`

