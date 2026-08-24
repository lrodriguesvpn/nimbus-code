# Research — 017-nimbus-digital-engineer-platform

## Decisão 1: Modelo de execução por modos
- **Decision**: Adotar motor de decisão com três modos (`autonomous`, `semi_autonomous`, `manual_approval`) baseado em criticidade, impacto e compliance.
- **Rationale**: Preserva velocidade em demandas de baixo risco e aumenta controle em demandas críticas.
- **Alternatives considered**:
  - Apenas modo manual (descartado por baixo ganho de produtividade).
  - Apenas modo autônomo (descartado por risco de governança).

## Decisão 2: Estratégia de aprovação e trilha
- **Decision**: Definir checkpoints de aprovação com `RACIProfile` e bloqueio obrigatório para gates mandatórios.
- **Rationale**: Evita continuidade sem responsável autorizado e reforça auditoria.
- **Alternatives considered**:
  - Aprovação por comentário livre sem papel formal (descartado por baixa rastreabilidade).
  - Aprovação apenas no fim do fluxo (descartado por risco de retrabalho tardio).

## Decisão 3: Abstração de feature flags
- **Decision**: OpenFeature como camada obrigatória para toggles de rollout.
- **Rationale**: Evita lock-in de provider e padroniza governança entre ambientes.
- **Alternatives considered**:
  - Uso direto de provider específico (descartado por acoplamento).

## Decisão 4: Cálculo de custo híbrido
- **Decision**: Consolidar custo por demanda em `DeliveryHandoff` com custo IA (tokens) + esforço humano.
- **Rationale**: Transparência para BA/PO e decisão de escala baseada em evidência.
- **Alternatives considered**:
  - Custo apenas técnico por logs de LLM (descartado por não contemplar esforço humano).
  - Custo apenas financeiro de horas humanas (descartado por ignorar consumo de IA).

## Decisão 5: Integração de intake corporativo
- **Decision**: Normalizar entradas de M365 e GitHub em `IntakeEntry` único.
- **Rationale**: Reduz retrabalho de consolidação manual e melhora consistência dos fluxos.
- **Alternatives considered**:
  - Pipelines separados por origem (descartado por fragmentação de dados).

