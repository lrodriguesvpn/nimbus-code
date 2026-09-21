# Feature Specification: Correção da Composição Real de Templates (Preset + Spec Kit Nativo)

**Feature Branch**: `023-template-resolution-merge-fix`
**Created**: 2026-08-24
**Status**: Ready
**Input**: Solicitação formalizada do usuário: "Corrigir o bug de resolução de templates em `.specify/scripts/bash/common.sh`: `resolve_template()`/`resolve_template_content()` hoje escolhem um único arquivo bruto por prioridade (preset antes do core) em vez de compor de fato o conteúdo de múltiplas camadas segundo a estratégia declarada em `preset.yml` (`replace`/`prepend`/`append`/`wrap`), como a própria CLI oficial `specify` já faz internamente (`resolve_content()`). Isso faz com que `plan.md`, `tasks.md`, `constitution.md` e demais artefatos gerados por `setup-plan.sh`/`setup-tasks.sh` em qualquer repositório com o preset `nimbus-code-standards` instalado (central ou satélite) recebam OU o template nativo OU o fragmento bruto do preset, nunca os dois combinados — forçando merge manual repetido, como ocorreu nas specs 021 e 022."

## Nimbus-Code — Cabeçalho Obrigatório da Spec

| Campo | Valor |
|---|---|
| **Feature slug** | `023-template-resolution-merge-fix` |
| **Complexidade estimada** | S2 |
| **Bounded Context** | `spec-kit-workflow` |
| **PR de referência / Issue** | novo |
| **Data alvo de entrega** | sem data |

> S0 = doc · S1 = função isolada · S2 = módulo · S3 = múltiplos módulos · S4 = arquitetura, segurança, dados ou integração crítica

**Justificativa da complexidade S2**: a correção é confinada a um módulo único — a lógica de resolução de templates em bash (`.specify/scripts/bash/common.sh` e os scripts que a consomem, como `setup-plan.sh`/`setup-tasks.sh`) dentro do bounded context `spec-kit-workflow`. Não cruza serviços nem repositórios em termos de implementação (o alcance amplo é de *impacto*, não de *acoplamento arquitetural*): é refatoração de módulo com testes, o perfil clássico de S2.

## Nimbus-Code — SLO Alvo desta Feature

| Componente | Latência p99 (ms) | Taxa de erro máx. (%) | Disponibilidade alvo | RTO | RPO |
|---|---|---|---|---|---|
| Resolução de template (`resolve_template_content`) | — | — | — | — | — |

> Deixado vazio (`—`): `resolve_template_content()` é um script local executado de forma síncrona durante `/speckit-plan`/`/speckit-tasks`/`/speckit-constitution` (tempo de design, não de runtime de produção) — não é um serviço com SLA contratual, análogo a um job batch interno sem exposição externa.

## Nimbus-Code — Objetivo e Contexto

**Objetivo:** corrigir a resolução de templates em bash para que ela componha de fato o conteúdo de todas as camadas aplicáveis (core do Spec Kit + preset(s) + extensões) segundo a estratégia declarada em cada camada (`replace`, `prepend`, `append`, `wrap`), em vez de retornar o arquivo de uma única camada escolhida por prioridade.

**Motivação:** a auditoria que corrigiu `preset.yml` (estratégias `copy` inválidas → `replace`) revelou um bug mais profundo e ainda não corrigido: mesmo com o manifesto correto, `resolve_template()`/`resolve_template_content()` em `.specify/scripts/bash/common.sh` nunca implementaram composição — apenas escolhem um arquivo bruto por prioridade. A própria CLI oficial `specify` já resolve esse problema internamente (método `resolve_content()`, usado para validar composição via `specify preset resolve`), confirmando que a semântica de merge é o comportamento pretendido, só não replicado na camada bash usada pelos scripts de setup. Na prática, isso forçou merge manual do conteúdo do preset em `plan.md`/`tasks.md` durante o planejamento das specs 021 e 022 nesta mesma sessão de trabalho.

**Critério de done (alto nível):** em qualquer repositório (central ou satélite) com o preset `nimbus-code-standards` instalado, rodar `/speckit-plan`, `/speckit-tasks` ou `/speckit-constitution` produz um artefato que já contém as seções nativas do Spec Kit **e** as seções do preset combinadas corretamente, sem qualquer merge manual — resultado equivalente ao já obtido manualmente para specs 021 e 022 (usadas como casos de regressão).

**Fora de escopo:** alterar `presets/nimbus-code-standards/preset.yml` (estratégias já corrigidas em PR anterior); modificar o pacote externo `specify_cli` (ferramenta open source de terceiros, fora do controle deste repositório); introduzir novas estratégias de composição além das 4 já suportadas (`replace`/`prepend`/`append`/`wrap`); construir qualquer UI ou comando novo voltado ao usuário final.

## Nimbus-Code — Hybrid Collaboration Model

| Papel | Responsabilidades | Critério de handoff | Escalação |
|---|---|---|---|
| Agente | Implementar a lógica de composição em bash, cobrir com testes `bats` para cada estratégia, validar contra os golden files de specs 021/022 | Repassa quando a saída composta divergir do golden file sem explicação clara, ou quando o bug exigir mudança fora de `common.sh`/scripts de setup | Tech lead |
| Dev | Revisar a lógica de merge e o impacto org-wide (todo repositório satélite passa a gerar artefatos diferentes na próxima execução) antes do merge | Repassa ao agente para ajuste caso a saída composta quebre algum template existente | Tech lead |

> Contexto não é WEB nem envolve rollout/toggle: os padrões Impeccable e OpenFeature não se aplicam a esta feature (script interno de tooling, sem interface de usuário nem feature flag de runtime).

## Nimbus-Code — Critérios de Aceitação (formato BDD)

> **AC-1**
> **Given** um repositório com preset instalado declarando estratégia `wrap` para um template,
> **When** `resolve_template_content()` for chamado para esse template,
> **Then** o conteúdo retornado contém o texto da camada `wrap` com o placeholder `{CORE_TEMPLATE}` substituído pelo conteúdo da camada de menor prioridade imediatamente abaixo — não apenas um dos dois arquivos brutos isoladamente.
> **Test ref:** `test_AC1_wrap_strategy_composes_core_template`

> **AC-2**
> **Given** um preset declarando estratégia `append` para um template,
> **When** `resolve_template_content()` for chamado,
> **Then** o conteúdo da camada base aparece primeiro, seguido do conteúdo da camada `append`, concatenados nessa ordem.
> **Test ref:** `test_AC2_append_strategy_concatenates_after_base`

> **AC-3**
> **Given** um preset declarando estratégia `prepend` para um template,
> **When** `resolve_template_content()` for chamado,
> **Then** o conteúdo da camada `prepend` aparece antes do conteúdo da camada base, concatenados nessa ordem.
> **Test ref:** `test_AC3_prepend_strategy_concatenates_before_base`

> **AC-4**
> **Given** um preset declarando estratégia `replace` (ou nenhuma estratégia declarada) como camada de maior prioridade,
> **When** `resolve_template_content()` for chamado,
> **Then** apenas o conteúdo dessa camada é retornado integralmente, ignorando camadas de menor prioridade — comportamento já correto hoje e que deve permanecer inalterado (guarda de regressão).
> **Test ref:** `test_AC4_replace_strategy_wins_entirely`

> **AC-5**
> **Given** mais de duas camadas aplicáveis ao mesmo template (ex.: extensão de agente + preset + core),
> **When** `resolve_template_content()` for chamado,
> **Then** a composição é aplicada recursivamente respeitando a ordem de prioridade, com a mesma semântica documentada e implementada por `resolve_content()` na CLI oficial `specify`.
> **Test ref:** `test_AC5_recursive_multi_layer_composition`

> **AC-6**
> **Given** os artefatos de specs/021 e specs/022, cujo merge preset+nativo foi feito manualmente antes desta correção,
> **When** os templates equivalentes forem re-resolvidos após o fix,
> **Then** o conteúdo composto automaticamente é equivalente ao merge manual já realizado (usado como golden file de regressão).
> **Test ref:** `test_AC6_regression_against_spec_021_022_manual_merge`

> **AC-7**
> **Given** um repositório sem nenhum preset instalado,
> **When** `resolve_template_content()` for chamado para qualquer template,
> **Then** o comportamento é idêntico ao atual — apenas o template nativo do Spec Kit é retornado, sem qualquer regressão.
> **Test ref:** `test_AC7_no_preset_behavior_unchanged`

## Nimbus-Code — Backlog Hierarchy (EPIC/FEATURE/US)

| Nível | Valor | Observação |
|---|---|---|
| **EPIC** | Governança e Consistência do Nimbus Code Spec Kit | Guarda-chuva de correções na base de tooling compartilhada por todos os repositórios |
| **FEATURE** | Corrigir composição real de templates entre preset e Spec Kit nativo | Escopo desta spec |
| **US1** | Implementar composição para estratégia `wrap` | Substituição de `{CORE_TEMPLATE}` pelo conteúdo da camada base |
| **US2** | Implementar composição para estratégias `append`/`prepend` | Concatenação preservando ordem |
| **US3** | Garantir paridade com `resolve_content()` da CLI oficial `specify` | Composição recursiva multi-camada, incluindo caso `replace` (regra base) |
| **US4** | Cobertura de teste de regressão usando specs 021/022 como golden files | Validação de que o merge manual anterior é reproduzido automaticamente |

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Gerar plan.md/tasks.md já compostos, sem merge manual (Priority: P1)

Como Dev ou agente rodando `/speckit-plan`/`/speckit-tasks` num repositório com o preset `nimbus-code-standards` instalado, quero que o artefato gerado já contenha as seções nativas do Spec Kit e as seções do preset combinadas corretamente, sem precisar copiar/colar manualmente o conteúdo do preset.

**Why this priority**: hoje isso já exigiu merge manual repetido durante o planejamento das specs 021 e 022 — é o custo recorrente mais direto do bug.

**Independent Test**: rodar `setup-plan.sh`/`setup-tasks.sh` num repositório com preset instalado e comparar a saída contra o merge manual já validado em specs 021/022 (golden file).

**Acceptance Scenarios**:

1. **Given** um repositório com preset instalado, **When** `/speckit-plan` for executado, **Then** o `plan.md` gerado contém tanto as seções nativas quanto as seções do preset (Security Gate, tabela de complexidade etc.) combinadas, sem etapa manual adicional.
2. **Given** o mesmo repositório, **When** `/speckit-tasks` for executado, **Then** o `tasks.md` gerado reflete a mesma composição correta.

---

### User Story 2 - Repositórios satélite recém-bootstrapped geram artefatos corretos desde o primeiro uso (Priority: P1)

Como Digital Engineering auditando repositórios satélite, quero que qualquer repositório com o preset instalado — mesmo recém-bootstrapped — gere artefatos corretos sem trabalho manual extra, já que essa foi uma causa raiz relacionada à investigação do "preset ausente" nos satélites.

**Why this priority**: sem essa correção, todo repositório satélite recém-configurado herdaria o mesmo problema de composição, exigindo intervenção manual recorrente em cada um.

**Independent Test**: num repositório satélite com o preset corrigido instalado, rodar `setup-tasks.sh` e confirmar que o `tasks.md` contém o conteúdo do preset combinado com o nativo, sem edição manual.

**Acceptance Scenarios**:

1. **Given** um repositório satélite com preset `nimbus-code-standards` v1.16.0 instalado, **When** `/speckit-tasks` for executado pela primeira vez, **Then** o `tasks.md` já contém a composição correta, sem necessidade de correção manual posterior.

---

### User Story 3 - Lógica bash com paridade em relação à CLI oficial (Priority: P2)

Como agente ou Dev que estende presets no futuro, quero que a lógica de composição em bash espelhe exatamente a semântica já documentada e implementada por `resolve_content()` na CLI oficial `specify`, para reduzir drift entre as duas implementações.

**Why this priority**: evita que a lógica bash e a lógica da CLI oficial divirjam silenciosamente ao longo do tempo, o que reintroduziria o mesmo tipo de bug de forma sutil.

**Independent Test**: para os mesmos templates, comparar a saída da função bash corrigida com o resultado esperado pela composição documentada da CLI oficial (`specify preset resolve <template>`, que reporta a cadeia de composição usada).

**Acceptance Scenarios**:

1. **Given** um template com múltiplas camadas de composição, **When** a função bash corrigida e a CLI oficial forem comparadas quanto à cadeia de composição, **Then** ambas concordam sobre quais camadas contribuem e em que ordem.

### Edge Cases

- O que acontece se uma camada `wrap` não contiver o placeholder `{CORE_TEMPLATE}` em seu conteúdo?
- Como o sistema decide a ordem quando múltiplas camadas de preset (ex.: extensão de agente + preset custom) competem pelo mesmo template?
- Como o sistema trata templates do tipo `command`, cujo conteúdo inclui frontmatter YAML que precisa ser separado do corpo antes da composição?
- O que acontece se o arquivo de alguma camada estiver ilegível ou corrompido (não UTF-8) no meio da cadeia de composição?
- O comportamento permanece idêntico para repositórios sem nenhum preset instalado?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A resolução de templates em `.specify/scripts/bash/common.sh` MUST compor o conteúdo final combinando todas as camadas aplicáveis (core + preset(s) + extensões) segundo a estratégia declarada em cada camada, em vez de retornar o arquivo de uma única camada escolhida por prioridade.
- **FR-002**: Para estratégia `wrap`, o sistema MUST substituir o placeholder `{CORE_TEMPLATE}` pelo conteúdo da camada de menor prioridade imediatamente abaixo.
- **FR-003**: Para estratégia `append`, o sistema MUST concatenar o conteúdo da camada de maior prioridade após o conteúdo da camada base, preservando a ordem.
- **FR-004**: Para estratégia `prepend`, o sistema MUST concatenar o conteúdo da camada de maior prioridade antes do conteúdo da camada base, preservando a ordem.
- **FR-005**: Para estratégia `replace` (ou ausência de estratégia declarada), o sistema MUST manter o comportamento atual — a camada de maior prioridade com essa estratégia vence integralmente, ignorando camadas de menor prioridade.
- **FR-006**: A composição MUST ser recursiva quando houver mais de duas camadas aplicáveis, aplicando as estratégias na ordem correta de prioridade.
- **FR-007**: Repositórios sem nenhum preset instalado MUST continuar recebendo exatamente o template nativo do Spec Kit, sem qualquer alteração de comportamento observável (regressão zero).
- **FR-008**: Templates do tipo `command` (com frontmatter YAML) MUST ter o frontmatter tratado separadamente do corpo durante a composição, preservando o frontmatter da camada de maior prioridade no resultado final.
- **FR-009**: O sistema MUST ter cobertura de teste automatizada (`bats`) validando a composição para cada estratégia (`replace`, `prepend`, `append`, `wrap`) e para o caso "sem preset".
- **FR-010**: O sistema MUST validar, usando os artefatos já mesclados manualmente de specs/021 e specs/022 como casos de regressão, que a saída automática da composição corrigida é equivalente ao merge manual previamente realizado.
- **FR-011**: A correção MUST se limitar à lógica de resolução em bash (`common.sh` e os scripts que a consomem) — não deve alterar `presets/nimbus-code-standards/preset.yml` (já corrigido em PR anterior) nem depender de mudanças no pacote externo `specify_cli`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% dos templates resolvidos (`plan-template`, `tasks-template`, `spec-template`, `constitution-template` etc.) em um repositório com preset instalado contêm tanto o conteúdo nativo quanto o conteúdo do preset combinados, verificável sem intervenção manual.
- **SC-002**: Zero merges manuais de template são necessários nas próximas specs planejadas após o fix (baseline: specs 021 e 022 exigiram merge manual antes do fix).
- **SC-003**: Repositórios sem preset instalado mantêm exatamente o mesmo comportamento observável antes e depois do fix (sem regressão).
- **SC-004**: A suíte de testes automatizados da composição passa 100% para os 4 tipos de estratégia (`replace`/`prepend`/`append`/`wrap`) mais o caso "sem preset".

## Assumptions

- O pacote externo `specify_cli` (CLI oficial `specify`) não será modificado como parte desta feature; a correção replica, em bash, a mesma semântica de composição já implementada e documentada nesse pacote (método `resolve_content()`), de forma independente.
- As specs 021 e 022, cujo merge preset+nativo foi feito manualmente durante a investigação que originou esta feature, servem como casos de regressão/golden files válidos para validar a saída da composição corrigida.
- `presets/nimbus-code-standards/preset.yml` já declara corretamente as estratégias (`replace`/`prepend`/`append`/`wrap`) para cada entrada, graças à correção aplicada em PR anterior — esta feature não precisa alterar essas declarações.
- Repositórios satélite herdam a correção automaticamente na próxima sincronização/instalação do preset, sem exigir nenhuma ação adicional além do processo normal já existente de atualização de preset.
- **Segurança**: nenhuma superfície de autenticação, autorização ou segredo é alterada por esta feature — a mudança é puramente de composição de arquivos de texto (templates) em tempo de execução de scripts locais.
- **LGPD**: nenhum dado pessoal é processado, armazenado ou transmitido por esta feature.
- **Infraestrutura**: nenhuma infraestrutura nova é provisionada; a execução ocorre localmente via scripts bash já existentes em `.specify/scripts/bash/`, sem novo hosting nem novo modo de acesso.
