# data-model.md — Feature 013: Governança de Testes em PR

> Não há entidades de banco de dados nesta feature — as "entidades" abaixo são
> os conceitos estruturais da política de testes e do gate de CI, extraídos
> das Key Entities do `spec.md`.

## Entidade: Test Policy

Documento normativo único (`docs/testing-policy.md`) que consolida toda a
governança de testes do bundle.

| Campo/Seção | Descrição | Obrigatório |
|---|---|---|
| Inventário da suíte atual | Lista os grupos existentes (`tests/bootstrap/`, `tests/docs/`, `tests/scripts/`, `tests/workflows/`) e seu propósito | Sim |
| Taxonomia de testes | Define unitário/integração/e2e para este bundle (FR-005) | Sim |
| Matriz de decisão de formato | Bats vs. `.test.sh` vs. exceção — prós/contras/critério (FR-003, FR-004) | Sim |
| Convenções de localização/nomenclatura | Onde e como nomear novos arquivos de teste por categoria (FR-006) | Sim |
| Definição do gate obrigatório | Como `test-suite.yml` e `run-tests.sh` implementam o gate (FR-007, FR-008) | Sim |
| Governança de exceções | Critério de aprovação para novo formato/bypass/remoção (FR-009) | Sim |
| Tratamento de testes legados | Migração/exceção temporária/remoção (FR-010) | Sim |

## Entidade: Test Category

Classificação oficial de um teste, conforme FR-005.

| Categoria | Critério de enquadramento neste bundle |
|---|---|
| **Unitário** | Valida uma única unidade isolada (uma função bash, um bloco de schema, uma seção de documentação) sem depender de outros scripts/workflows do repositório |
| **Integração** | Valida a interação entre dois ou mais componentes do bundle (ex.: um script + o workflow que o invoca; um preset + o template que ele resolve) |
| **End-to-end (E2E)** | Valida um fluxo completo de ponta a ponta como um contribuidor/CI o experimentaria (ex.: `/speckit-plan` gerando artefatos reais; um PR completo passando pelo gate obrigatório) — mais custoso, reservado para os fluxos críticos do bundle |

## Entidade: Test Entry Point

Forma oficial de descoberta/execução — um único conceito, duas superfícies:

| Superfície | Arquivo | Papel |
|---|---|---|
| Local | `scripts/run-tests.sh` | Contribuidor roda antes de abrir PR (AC-4) |
| CI | `.github/workflows/test-suite.yml` | Invoca o mesmo `scripts/run-tests.sh` dentro do runner — paridade garantida por construção, não por manutenção paralela |

## Entidade: Mandatory PR Gate

Resultado consolidado de uma execução do Test Entry Point contra uma PR.

| Campo | Tipo | Descrição |
|---|---|---|
| `status` | enum (`pass`, `fail`) | Resultado consolidado da suíte mandatória |
| `failed_segment` | string ou null | Nome do grupo (`bootstrap`, `docs`, `scripts`, `workflows`) que falhou primeiro, se `status = fail` (FR-011) |
| `required` | boolean | Se o check está marcado como "required status check" na proteção de branch (rollout faseado — ver `plan.md`) |

## Entidade: Exception Record

Registro formal de um desvio autorizado do padrão (FR-009), vive no
Architecture Decision Log do `plan.md` da feature que introduziu a exceção
(não em arquivo próprio — reaproveita o mecanismo já existente do bundle).

| Campo | Descrição |
|---|---|
| Motivo | Por que o padrão principal não se aplica |
| Formato alternativo aceito | Qual formato será usado em vez do padrão |
| Duração esperada | Permanente (ex.: `.test.sh` para validação simples) ou temporária (com prazo) |
| Aprovador | Quem aprovou o desvio |

## Relações

```text
Test Policy ──classifica──> Test Category (1:N)
Test Policy ──define──> Test Entry Point (1:2, local + CI)
Test Entry Point (CI) ──produz──> Mandatory PR Gate (1:1 por execução)
Test Policy ──permite──> Exception Record (1:N, quando desvio aprovado)
```
