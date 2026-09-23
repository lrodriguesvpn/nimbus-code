# Architecture Decision Records (ADRs) — Guia Nimbus-Code

ADRs capturam **por que** uma decisão técnica foi tomada, não apenas **o que**
foi decidido. São a memória organizacional que evita rediscutir as mesmas
escolhas a cada nova feature ou novo membro do time.

## Onde vivem os ADRs

| Escopo | Localização |
|---|---|
| **Organizacional** (afeta múltiplos projetos da Nimbus-Code) | `docs/adr/` neste repositório (`nimbus-code`) |
| **De projeto** (afeta só um repositório) | `docs/adr/` no repositório do projeto |

Regra de decisão: se a decisão *puder* afetar um segundo projeto no futuro,
colocar no nível organizacional.

## Quando criar um ADR

Criar um ADR para qualquer decisão que:

- Escolhe entre duas ou mais alternativas técnicas com trade-offs reais
- Muda um padrão já estabelecido (ex.: troca de banco, novo protocolo)
- Estabelece um padrão novo que não existia antes
- Tem consequências que durarão mais de 3 meses
- Precisou de mais de 30 minutos de discussão para chegar a um consenso

**Não criar** ADR para:
- Decisões triviais sem alternativas reais ("usar Python 3.12 porque é o mais recente")
- Decisões revertidas antes de entrar em produção (registrar como "Obsoleta")
- Detalhes de implementação que não afetam a arquitetura

## Fluxo de criação

### 1. Durante /nimbus-code-plan

O Architecture Decision Log do `plan.md` captura decisões **locais** da feature
em uma tabela simples. Se a decisão tiver impacto organizacional, adicionar uma
linha na coluna "ADR" apontando para um novo arquivo.

### 2. Criar o arquivo ADR

```bash
# Descubra o próximo número disponível
ls docs/adr/ | tail -1

# Copie o template
cp presets/nimbus-code-standards/templates/adr/NNNN-template.md \
   docs/adr/0042-mensageria-entre-servicos.md
```

### 3. Preencher e revisar

Preencher todas as seções obrigatórias (Contexto, Opções, Decisão, Consequências).
Para decisões S4 (arquitetura/segurança): revisão obrigatória por tech lead antes
de marcar como "Aceita".

### 4. Referenciar no plan.md

No Architecture Decision Log do `plan.md` da feature, adicionar o link:

```markdown
| Estratégia de mensageria | Pub/Sub vs Kafka vs polling | Pub/Sub | ... | [ADR-0042](../../docs/adr/0042-mensageria-entre-servicos.md) |
```

## Numeração

- Formato: `NNNN-slug-kebab-case.md` (ex.: `0001-framework-de-iac.md`)
- Numeração sequencial global, sem gaps
- Nunca reutilizar um número (marcar como "Obsoleta" em vez de deletar)

## Status válidos

| Status | Significado |
|---|---|
| **Proposta** | Rascunho em discussão, não aprovada |
| **Em revisão** | Aguardando aprovação formal |
| **Aceita** | Decisão vigente |
| **Obsoleta** | Substituída por circunstâncias — sem sucessora direta |
| **Supersedida por NNNN** | Substituída por uma nova decisão (com link) |

## ADRs organizacionais já registrados

| Nº | Título | Status |
|---|---|---|
| [0001](0001-terraform-como-framework-iac-padrao.md) | Terraform como framework IaC padrão (multi-cloud) | Aceita |

> Adicionar novas entradas aqui ao criar ADRs organizacionais.
