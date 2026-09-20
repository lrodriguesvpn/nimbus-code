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
| Agente | Criação dos artefatos `docs/harness/`, atualização de templates e scripts, entradas de exemplo no catálogo, busca e preenchimento preventivo de gates | Quando precisar decidir se uma entrada de exemplo é sensível/confidencial para o projeto ou sanitização complexa | Tech lead |
| Humano | Revisão das entradas de exemplo (aderência à realidade do projeto), validação do fluxo de consulta no plan.md, aprovação do merge, remoção de labels `harness:blocking` | Quando os artefatos estiverem criados e o checklist de quality gate preenchido | Tech lead / Architecture Board |

## User Stories

### US1 — Consulta Preventiva de Padrões de Erro durante o Planejamento (Agente / Dev)
**Como** Desenvolvedor ou Agente de IA iniciando o planejamento de uma feature (`/nimbus-code-plan`),  
**Quero** consultar `docs/harness/harness-catalog.yaml` por `tags` e `bounded_context` correspondentes à feature,  
**Para que** eu conheça antecipadamente armadilhas, erros arquiteturais e incidentes anteriores e aplique mitigações preventivas no `plan.md`.

### US2 — Registro Estruturado de Lições Aprendidas pós-Retrabalho ou Incidente (Dev / Tech Lead)
**Como** Tech Lead ou Desenvolvedor após fechar uma feature com retrabalho expressivo (>20%) ou pós-incidente S3/S4,  
**Quero** preencher o `incident-template.md` e registrar uma nova entrada sanitizada no `harness-catalog.yaml` com o label `harness:pending`,  
**Para que** a falha se torne um ativo de aprendizado institucional e nunca mais se repita na organização.

### US3 — Busca Rápida e Eficiente no Catálogo via CLI (Dev / Agente)
**Como** Engenheiro ou Agente de IA operando no terminal ou em pipelines locais,  
**Quero** executar `./scripts/harness-search.sh <tag>` ou busca por `bounded_context` com tempo de resposta inferior a 5 segundos,  
**Para que** o tempo de inferência e custo de tokens sejam minimizados sem depender de bibliotecas externas complexas.

## Functional Requirements (FR)

- **FR-001 (Schema e Estrutura do Catálogo)**: O repositório central de harnesses deve ser `docs/harness/harness-catalog.yaml`, contendo esquema estrito com campos obrigatórios: `id` (formato `HRN-NNNN`), `title`, `date`, `bounded_context`, `tags` (lista de strings), `source_type` (`incident` \| `rework` \| `architecture_flaw`), `severity` (`S1` a `S4`), `error_pattern` (descrição clara da armadilha), `root_cause` (análise de causa raiz / 5-Whys), `prevention` (diretriz imperativa de como evitar) e `source_ref` (opcional sanitizado).
- **FR-002 (Instrução Obrigatória de Pré-Consulta ao Agente)**: O arquivo `.github/copilot-instructions.md` deve instruir formalmente o agente a consultar `docs/harness/harness-catalog.yaml` antes de redigir qualquer `plan.md`, declarando o resultado na seção dedicada.
- **FR-003 (Harness Gate Tri-Estado no Plan Template)**: O template `presets/nimbus-code-standards/templates/plan-template.md` deve conter a seção "Harness Gate" cobrindo 3 estados determinísticos:
  1. *Match encontrado*: Declarar IDs, padrão evitado e mitigação aplicada.
  2. *Nenhum match*: Declarar explicitamente `"Nenhum padrão de erro relevante encontrado"`.
  3. *Catálogo vazio/inexistente*: Declarar explicitamente `"Catálogo vazio — nenhum padrão disponível"`.
- **FR-004 (Gatilho de Retrabalho Quantificado e Auditável)**: O gatilho de retrabalho > 20% no checklist de fechamento de tarefas (`tasks.md`) é ativado quando:
  - Horas humanas registradas no GitHub Project excederem em > 20% a estimativa original da feature, OU
  - Houver > 2 rodadas de refatoração substancial pós-revisão no Pull Request.
- **FR-005 (Governança e Bloqueio `harness:blocking`)**: O label `harness:blocking` impede novos deploys/merges no bounded context afetado e só pode ser removido mediante aprovação formal exclusiva do **Tech Lead** ou **Architecture Board** após mitigação validada por testes.
- **FR-006 (Sanitização Estrita e Privacidade de Dados)**: Qualquer entrada catalogada no `harness-catalog.yaml` ou post-mortem deve sofrer anonimização obrigatória: remoção total de PII, nomes de clientes, endereços de rede interna, chaves de API, credenciais e segredos.
- **FR-007 (Utilitário CLI de Busca com Fallback)**: O script `scripts/harness-search.sh` deve suportar busca por tags e bounded context com tempo de execução < 5 segundos, operando com `yq` quando disponível e fallback robusto via `grep`/`awk` para ambientes mínimos.
- **FR-008 (Template Estruturado de Post-Mortem)**: O arquivo `docs/harness/incident-template.md` deve conter estrutura padronizada para incidentes: Sumário executivo, Timeline detalhada, Análise de 5-Whys, Ações Corretivas/Preventivas com donos e prazos, e Checklist de Catalogação no Harness.

## Key Entities & Data Model

```yaml
HarnessEntry:
  id: string              # Ex: HRN-0001 (único, sequencial)
  title: string           # Título conciso do erro/incidente
  date: string            # YYYY-MM-DD
  bounded_context: string # Contexto delimitado afetado (ex: spec-kit-workflow, auth, billing)
  tags: [string]          # Tags para busca (ex: [scope-creep, multi-repo, agent-loop])
  source_type: string     # incident | rework | architecture_flaw
  severity: string        # S1 | S2 | S3 | S4
  error_pattern: string   # Descrição objetiva da falha cometida
  root_cause: string      # Causa raiz identificada
  prevention: string      # Regra imperativa para evitar a repetição
  source_ref: string      # URL/Issue opcional (sanitizada)
  deprecated: boolean     # true se a lição foi superada por nova arquitetura
```

## Success Criteria (SC)

- **SC-001 (Tempo de Recuperação e Busca)**: O utilitário `scripts/harness-search.sh` executa consultas no catálogo em menos de 5 segundos em 100% das invocações.
- **SC-002 (Adesão de Consulta em Planos)**: 100% dos planos gerados via `/nimbus-code-plan` possuem a seção "Harness Gate" preenchida com um dos 3 estados válidos sem omissão.
- **SC-003 (Taxa de Reincidência de Erros Catalogados)**: Redução a zero de reincidências de erros catalogados com severidade S3/S4 nos bounded contexts monitorados.
- **SC-004 (Completude e Idempotência de Labels)**: O script `scripts/setup-github-labels.sh` cria os labels `harness:*` de forma idempotente sem afetar labels pré-existentes.

## Edge Cases

- **EC-001 (Múltiplos Matches)**: Se múltiplos harnesses corresponderem à consulta, o agente deve listar todos no Harness Gate, priorizando as mitigações por severidade (`S4 > S3 > S2 > S1`).
- **EC-002 (Bounded Context não mapeado)**: Caso o bounded context da feature não esteja em `docs/bounded-contexts.yaml`, a busca deve ser realizada exclusivamente por `tags` sem travar o processo.
- **EC-003 (Erro de Sintaxe no YAML)**: Caso o arquivo `harness-catalog.yaml` apresente erro de parse, o script `harness-search.sh` emite aviso claro e o fallback via `grep` entra em ação sem abortar silenciosamente.

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
