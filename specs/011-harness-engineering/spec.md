# Feature Specification: Harness Engineering — Aprendizado Organizacional com Erros

**Feature Branch**: `feature/011-harness-engineering`

**Created**: 2026-08-20

**Status**: Draft

---

## Nimbus-Code — Cabeçalho Obrigatório da Spec

| Campo | Valor |
|---|---|
| **Feature slug** | `011-harness-engineering` |
| **Complexidade estimada** | **S3** — cruza `docs/harness/` (novo), `presets/nimbus-code-standards/templates/plan-template.md` (estendido), `scripts/setup-github-labels.sh` (estendido), `.github/copilot-instructions.md` (estendido), `docs/ai-code-quality-and-observability.md` (referenciado) |
| **Bounded Context** | `spec-kit-workflow` |
| **PR de referência / Issue** | novo |
| **Data alvo de entrega** | sem data |

> S0 = doc · S1 = função isolada · S2 = módulo · S3 = múltiplos módulos ·
> S4 = arquitetura, segurança, dados ou integração crítica

## Nimbus-Code — SLO Alvo desta Feature

| Componente | Latência p99 (ms) | Taxa de erro máx. (%) | Disponibilidade alvo | RTO | RPO |
|---|---|---|---|---|---|
| `harness-catalog.yaml` (leitura) | — | 0% (arquivo estático) | — | — | — |
| Scripts de busca (harness-search.sh) | < 5s | 0% (idempotente) | — | — | — |

> Componentes são arquivos estáticos e scripts CLI locais — sem SLO de disponibilidade mensurável.

## Nimbus-Code — Objetivo e Contexto

**Objetivo:** Incorporar o conceito de **Harness Engineering** ao workflow NIMBUS CODE,
criando uma camada de memória organizacional que captura, cataloga e propaga aprendizados
de falhas (erros, incidentes, retrabalhos) entre projetos e agentes. Agentes de IA e devs
consultam o catálogo antes de planejar qualquer feature, evitando que padrões de erro já
conhecidos se repitam.

**Motivação:** Agentes de IA têm memória de sessão — ao encerrar uma sessão, o contexto
se perde. Sem um mecanismo externo de memória organizacional, cada agente reincide nos
mesmos erros arquiteturais, de escopo, de segurança e de integração que times anteriores
já pagaram para aprender. Times que adotam o NIMBUS CODE trabalham em projetos distintos
mas compartilham o mesmo template — a oportunidade de aprendizado cruzado existe, mas
não há estrutura para capturá-la.

**Critério de done (alto nível):** O `harness-catalog.yaml` existe e está populado com
entradas de exemplo; o `plan-template.md` tem a seção "Harness Gate" obrigatória;
o `copilot-instructions.md` instrui o agente a consultar o harness antes de planejar;
os labels `harness:*` estão disponíveis via `setup-github-labels.sh`; e a documentação
do ciclo completo (consulta → catalogação) está acessível em `docs/harness/`.

## Nimbus-Code — Hybrid Collaboration Model

| Papel | Responsabilidades | Critério de handoff | Escalação |
|---|---|---|---|
| Agente | Criação dos artefatos `docs/harness/`, atualização de templates e scripts, entradas de exemplo no catálogo | Quando precisar decidir se uma entrada de exemplo é sensível/confidencial para o projeto | Tech lead |
| Humano | Revisão das entradas de exemplo (aderência à realidade do projeto), validação do fluxo de consulta no plan.md, aprovação do merge | Quando os artefatos estiverem criados e o checklist de quality gate preenchido | Tech lead / product owner |

## Nimbus-Code — Critérios de Aceitação (formato BDD)

> **AC-1**
> **Given** que o diretório `docs/harness/` existe no repositório,
> **When** um agente inicia um novo `/nimbus-code-plan`,
> **Then** o `copilot-instructions.md` instrui explicitamente o agente a consultar `docs/harness/harness-catalog.yaml` por `tags` e `bounded_context` antes de redigir o `plan.md`.
> **Test ref:** `test_AC1_harness_consulta_obrigatoria`

> **AC-2**
> **Given** que o agente encontrou um match no `harness-catalog.yaml`,
> **When** o `plan.md` é redigido,
> **Then** o `plan.md` contém a seção "Harness Gate" com o ID do harness, o padrão de erro evitado e a mitigação preventiva aplicada.
> **Test ref:** `test_AC2_harness_gate_no_plan`

> **AC-3**
> **Given** que uma feature foi entregue com retrabalho > 20% do esforço estimado ou com incidente,
> **When** o checklist de fechamento do `tasks.md` é executado,
> **Then** existe um passo explícito para abrir Issue com label `harness:pending` e preencher o `harness-catalog.yaml`.
> **Test ref:** `test_AC3_harness_pending_checklist`

> **AC-4**
> **Given** que `harness-catalog.yaml` contém ao menos uma entrada,
> **When** um dev ou agente executa busca por tag ou bounded_context,
> **Then** a entrada é localizada em menos de 5s via `grep` ou via `scripts/harness-search.sh`.
> **Test ref:** `test_AC4_harness_busca`

> **AC-5**
> **Given** que executo `scripts/setup-github-labels.sh` num repositório,
> **When** o script termina,
> **Then** os labels `harness:pending`, `harness:cataloged` e `harness:blocking` existem no repositório.
> **Test ref:** `test_AC5_harness_labels`

> **AC-6**
> **Given** que um incidente S3/S4 ocorreu em produção,
> **When** o dev inicia o pós-incidente,
> **Then** o `docs/harness/incident-template.md` fornece estrutura completa (timeline, 5-Whys, ações preventivas, checklist de encerramento) para o post-mortem.
> **Test ref:** `test_AC6_incident_template_completude`

> **AC-7**
> **Given** que o `harness-catalog.yaml` não tem match para o domínio da feature,
> **When** o agente preenche a seção "Harness Gate" no `plan.md`,
> **Then** o campo declara explicitamente "Nenhum padrão de erro relevante encontrado" — não é deixado em branco.
> **Test ref:** `test_AC7_harness_gate_sem_match`

---

## Fora de Escopo

- Automação de preenchimento do `harness-catalog.yaml` via CI/parser de PRs
- Integração com ferramentas externas de gestão de incidentes (PagerDuty, Opsgenie)
- Interface web ou dashboard de visualização do catálogo
- Análise semântica automática de PRs para detectar padrões de harness
- Workflow `harness-check.yml` no CI (pode ser adicionado em feature futura)

---

## Dependências

| Dependência | Tipo | Status |
|---|---|---|
| Feature 001 (`reuse-catalog.yaml`) | upstream — padrão análogo de catálogo | ✅ implementada |
| `copilot-instructions.md` no preset | arquivo a estender | ✅ existe |
| `plan-template.md` no preset | arquivo a estender | ✅ existe |
| `setup-github-labels.sh` | arquivo a estender | ✅ existe |
| `docs/harness/` (artefatos base) | artefatos novos | ✅ criados nesta feature |

---

## Glossário

| Termo | Definição |
|---|---|
| **Harness** | Registro estruturado de uma lição aprendida com um erro, incidente ou retrabalho |
| **Harness Catalog** | Arquivo `harness-catalog.yaml` — repositório central de todos os harnesses |
| **Harness Gate** | Seção obrigatória do `plan.md` declarando se o catálogo foi consultado e o resultado |
| **Post-mortem** | Análise estruturada pós-incidente usando o `incident-template.md` |
| **Error Pattern** | Padrão de erro recorrente que o harness documenta para evitar reincidência |
| **Prevention** | Campo do harness com instrução acionável para o agente/dev na próxima ocorrência |
