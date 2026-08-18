# Spec Sample

## Nimbus-Code — Cabeçalho Obrigatório da Spec

| Campo | Valor |
|---|---|
| Feature slug | 005-hybrid-agent-human-dev |

## Nimbus-Code — SLO Alvo desta Feature

| Componente | Latência p99 (ms) | Taxa de erro máx. (%) | Disponibilidade alvo | RTO | RPO |
|---|---|---|---|---|---|
| template-engine | 3000 | 0.5 | 99.5% | 5 min | 1 min |

## Nimbus-Code — Objetivo e Contexto

Objetivo: suportar colaboração híbrida entre agente e humano.
Motivação: reduzir ambiguidade em execução manual.
Critério de done: templates geram seções obrigatórias consistentes.

## Nimbus-Code — Critérios de Aceitação (formato BDD)

**AC-1**
**Given** um projeto com preset Nimbus-Code ativo
**When** a spec é gerada por /speckit-specify
**Then** o documento inclui o cabeçalho híbrido e menção ao padrão Impeccable para WEB.

## Assumptions

- Features WEB seguem Impeccable como padrão de design.
