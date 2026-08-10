<!--
  Este bloco é inserido pelo preset `nimbus-code-standards` (estratégia `prepend`) antes
  do spec-template.md nativo do Nimbus Code, adicionando campos obrigatórios da Nimbus-Code:
  classificação de complexidade S0–S4 já na spec, bounded context, SLO alvo e critérios
  de aceitação no formato BDD. O restante da spec (contexto técnico, objetivo etc.)
  continua sendo preenchido normalmente pelo /nimbus-code-specify.
-->

## Nimbus-Code — Cabeçalho Obrigatório da Spec

*Preencher ANTES dos critérios de aceitação. Alimenta o plan.md, o graph.yaml e
a seleção de modelo do agente.*

| Campo | Valor |
|---|---|
| **Feature slug** | `<kebab-case-slug>` — usado como nome da pasta em `specs/` |
| **Complexidade estimada** | S0 · S1 · S2 · S3 · S4 *(marcar um; pode ser revisado no plan.md)* |
| **Bounded Context** | [ex.: Order Management, Identity, Billing, Notification] |
| **PR de referência / Issue** | [link — ou "novo" se não existir] |
| **Data alvo de entrega** | [YYYY-MM-DD — ou "sem data"] |

> S0 = doc · S1 = função isolada · S2 = módulo · S3 = múltiplos módulos ·
> S4 = arquitetura, segurança, dados ou integração crítica

## Nimbus-Code — SLO Alvo desta Feature

*Preencher para componentes novos ou alterados. Alimenta o Observability Gate do
plan.md — alertas serão configurados com base nesses valores.*

| Componente | Latência p99 (ms) | Taxa de erro máx. (%) | Disponibilidade alvo | RTO | RPO |
|---|---|---|---|---|---|
| `<serviço>` | [ex.: 200ms] | [ex.: 0,1%] | [ex.: 99,9%] | [ex.: 5 min] | [ex.: 1 min] |

> Deixar vazio (`—`) apenas se o componente não expõe SLO mensurável (ex.: job
> batch interno sem SLA contratual). Omissão sem justificativa é tratada como
> "não definido" — o Observability Gate bloqueará o plan.md.

## Nimbus-Code — Objetivo e Contexto

*Descreva de forma objetiva o que esta feature entrega e por que ela é necessária.
Sem formato fixo — use parágrafos curtos ou tópicos. Substituiu o campo "User Story"
do modelo anterior: foque no objetivo de negócio/técnico, não numa narrativa de papel.*

**Objetivo:** [o que será construído ou alterado]

**Motivação:** [por que é necessário agora — problema que resolve ou oportunidade]

**Critério de done (alto nível):** [como saber que está feito — sem detalhar testes aqui]

## Nimbus-Code — Critérios de Aceitação (formato BDD)

*Todo critério de aceitação deve estar no formato Given/When/Then para permitir
rastreabilidade direta com testes de integração. Cada item recebe um ID único
(AC-N) que será referenciado no `tasks.md` e nos testes.*

> **AC-1**
> **Given** [contexto inicial / pré-condição]
> **When** [ação do usuário ou evento do sistema]
> **Then** [resultado esperado e verificável]
> **Test ref:** `test_AC1_<descricao>` *(preenchido durante /nimbus-code-tasks)*

> **AC-2**
> **Given** …
> **When** …
> **Then** …
> **Test ref:** `test_AC2_<descricao>`

> *(Adicionar AC-N conforme necessário. Mínimo: 1 critério por feature.)*

{CORE_TEMPLATE}
