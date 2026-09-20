# Implementation Plan: Correção da Composição Real de Templates (Preset + Spec Kit Nativo)

**Branch**: `023-template-resolution-merge-fix` | **Date**: 2026-08-31 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/023-template-resolution-merge-fix/spec.md`

## Summary

Corrigir o ponto exato em que a composição de templates quebra: `common.sh` **já** tem uma
função de composição correta (`resolve_template_content()`, com suporte completo a
`replace`/`prepend`/`append`/`wrap`, recursiva, com paridade quase 1:1 com `resolve_content()`
da CLI oficial `specify`) — mas os três consumidores reais (`create-new-feature.sh`,
`setup-plan.sh`, `setup-tasks.sh`) chamam a função **errada**, `resolve_template()`, que só
devolve o caminho de um único arquivo por prioridade (sem composição), e então fazem `cp`
literal desse arquivo cru, ou entregam esse caminho para a skill ler como "a" estrutura do
template. Abordagem técnica: trocar os três call sites para consumir
`resolve_template_content()` (conteúdo já composto) em vez de `resolve_template()` (caminho de
uma única camada), preservando `resolve_template()` apenas para os casos que genuinamente só
precisam checar existência/caminho, e cobrir a mudança com testes `bats` que usam as specs
021/022 como golden files de regressão.

## Technical Context

**Language/Version**: Bash 3.2+ (compatibilidade já exigida pelos scripts existentes em `.specify/scripts/bash/`, ver comentários de compatibilidade em `common.sh`); Python 3 é usado apenas como dependência opcional já existente (leitura de `preset.yml`/`.registry` via `python3 -c`), não introduzida por esta feature.

**Primary Dependencies**:
- [.specify/scripts/bash/common.sh](../../.specify/scripts/bash/common.sh) — já contém `resolve_template()` (path-only, linha 406) e `resolve_template_content()` (composição correta, linha 490); nenhuma das duas precisa de nova lógica de composição, apenas os call sites downstream precisam trocar de função
- [.specify/scripts/bash/create-new-feature.sh](../../.specify/scripts/bash/create-new-feature.sh) — materializa `spec.md` via `cp "$TEMPLATE" "$SPEC_FILE"` usando `resolve_template()` (linha ~601); precisa passar a escrever o conteúdo composto
- [.specify/scripts/bash/setup-plan.sh](../../.specify/scripts/bash/setup-plan.sh) — materializa `plan.md` via `cp "$TEMPLATE" "$IMPL_PLAN"` usando `resolve_template()` (linha ~46); mesmo padrão de correção
- [.specify/scripts/bash/setup-tasks.sh](../../.specify/scripts/bash/setup-tasks.sh) — não faz `cp` diretamente; resolve `TASKS_TEMPLATE` via `resolve_template()` (linha ~53) e devolve o **caminho** via JSON para a skill `speckit-tasks` ler como estrutura (`.github/skills/speckit-tasks/SKILL.md`, step 1/4: "Read the tasks template from TASKS_TEMPLATE ... and use it as structure") — mesma classe de bug, manifestando via leitura de um único caminho não composto em vez de um `cp`
- CLI oficial `specify` (pacote externo, não deste repositório) — método `resolve_content()` em `specify_cli/presets/__init__.py`, usado apenas como referência de paridade de semântica (comparação em `AC-5`/`FR-006`), nunca invocado ou modificado por esta feature (FR-011)

**Storage**: Nenhum — toda a "persistência" já é arquivo de texto (templates em `.specify/templates/` e `.specify/presets/*/templates/`); sem banco de dados ou novo estado versionado.

**Testing**: `bats` (Bats-core 1.13.0, já usado no repositório — ver [.specify/scripts/bash/tests/create-new-feature.bats](../../.specify/scripts/bash/tests/create-new-feature.bats) como padrão de referência: fixture project isolado via `mktemp -d`, nunca toca `specs/`/`docs/` reais deste repositório).

**Target Platform**: qualquer repositório (central ou satélite) que use `.specify/scripts/bash/` — macOS e Linux, mesma compatibilidade Bash 3.2+ já exigida hoje.

**Project Type**: correção de tooling/scripting interno (não é um serviço novo nem uma aplicação).

**Performance Goals**: execução síncrona de scripts locais (tempo de design, não runtime de produção) — sem meta de performance específica além de não introduzir regressão perceptível na velocidade de `/speckit-plan`/`/speckit-tasks`/`/speckit-specify`.

**Constraints**:
- Não alterar a lógica de composição já correta em `resolve_template_content()` — o bug não está ali (FR-011, confirmado por leitura de código nesta fase de planejamento)
- Não alterar `presets/nimbus-code-standards/preset.yml` (já corrigido em PR anterior) nem depender de mudanças no pacote externo `specify_cli` (FR-011)
- `resolve_template()` deve continuar existindo e funcionando como está para qualquer call site que precise apenas de um caminho de arquivo para checagem de existência — não deve ser removida, apenas parar de ser usada para materialização de conteúdo composto
- A correção em `setup-tasks.sh` precisa manter o contrato de saída atual (`TASKS_TEMPLATE` como caminho absoluto de arquivo, consumido pela skill `speckit-tasks`) — a mudança deve ser materializar o conteúdo composto em um arquivo (cache/temp) e devolver esse caminho, não mudar o contrato JSON para carregar conteúdo bruto

**Scale/Scope**: todo repositório (central e satélites) com o preset `nimbus-code-standards` instalado — mudança em 3 scripts bash + testes; sem mudança de infraestrutura.

## Constitution Check

*GATE: deve passar antes da pesquisa da Fase 0. Revalidar após o design da Fase 1.*

| Gate | Status | Observação |
|---|---|---|
| Backup & DR | ✅ N/A | Sem datastore novo; apenas arquivos de texto versionados em Git |
| Segredos no código | ✅ | Nenhum segredo novo ou alterado |
| Branch/merge protegido | ✅ | Entrega por PR revisado, mesma política já vigente no repositório |
| Isolamento de ambiente | ✅ N/A | Não usa credenciais; opera sobre arquivos locais de template |
| Observabilidade | ✅ N/A | Script de tempo de design (build-time), não runtime de produção — sem componente a observar |
| IaC | ✅ N/A | Não provisiona infraestrutura |

**Gate: APROVADO** — sem violações bloqueantes identificadas nesta fase de planejamento.

## Project Structure

### Documentation (this feature)

```text
specs/023-template-resolution-merge-fix/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── graph.yaml
├── graph.md
├── contracts/
│   └── template-composition.contract.md
└── checklists/
    └── requirements.md
```

### Arquivos candidatos a alteração fora da pasta da feature

```text
.specify/scripts/bash/create-new-feature.sh   # trocar resolve_template()+cp por resolve_template_content()
.specify/scripts/bash/setup-plan.sh           # trocar resolve_template()+cp por resolve_template_content()
.specify/scripts/bash/setup-tasks.sh          # materializar conteúdo composto em cache/temp, devolver caminho
.specify/scripts/bash/common.sh               # sem mudança de lógica; talvez pequeno ajuste de comentário/doc
.specify/scripts/bash/tests/                  # novos testes bats de regressão (composição + golden files 021/022)
```

**Structure Decision**: Correção cirúrgica confinada a 3 scripts consumidores + testes — nenhuma mudança na função de composição já correta (`resolve_template_content()`), nenhuma mudança no manifesto de preset (`preset.yml`, já corrigido em PR anterior) e nenhuma dependência do pacote externo `specify_cli`. Escopo deliberadamente mínimo para reduzir risco em tooling usado por toda a organização (mitigação direta de HRN-0001 — não estender o escopo além do que o bug exige).

## Complexity Tracking

> Nenhuma violação do Constitution Check nesta fase — seção não aplicável.

---

## Nimbus-Code — Classificação de Complexidade (S0–S4)

| Campo | Valor |
|---|---|
| **Nível** | **S2** |
| **Justificativa** | Módulo único (scripts de resolução de template em bash) dentro de um bounded context (`spec-kit-workflow`); a correção é troca de chamada de função + materialização de conteúdo em 3 arquivos, sem cruzar serviços ou repositórios em termos de implementação. O alcance amplo é de impacto (todo repo com preset instalado), não de acoplamento arquitetural — perfil clássico de S2 |
| **Modelo de IA** | Auto |
| **Revisão humana obrigatória** | Não (S0–S3), mas recomendada dado o impacto org-wide na próxima geração de `plan.md`/`tasks.md`/`spec.md` em qualquer repositório |
| **Padrão reutilizado encontrado?** | Não em `docs/reuse-catalog.yaml` (nenhuma entrada sobre composição de templates); porém a lógica de composição correta **já existe** em `resolve_template_content()` — esta feature reaproveita essa função existente por ponteiro, em vez de reimplementar merge do zero |
| **Estimativa de tokens (input+output)** | ~10–16 mil tokens |

> A estimativa de tokens é preenchida **antes** de `/nimbus-code-tasks` e comparada com o
> consumo real no fechamento do `tasks.md`.

## Nimbus-Code — Harness Gate

| Harness consultado (ID) | Padrão de erro evitado | Mitigação preventiva aplicada nesta feature |
|---|---|---|
| HRN-0001 | Agente extrapola escopo silenciosamente ao encontrar "bug adjacente" fora da lista declarada | Escopo desta feature é explicitamente confinado aos 3 call sites de `resolve_template()` identificados por leitura de código (`create-new-feature.sh`, `setup-plan.sh`, `setup-tasks.sh`) + testes; `preset.yml` e `specify_cli` (externo) ficam fora de escopo por design (FR-011) |
| HRN-0004 | Drift entre estado do código e estado real de execução (ex.: "preset instalado" declarado sem validar que o merge realmente acontece) | Esta própria feature nasceu de observar o drift ao vivo: `specs/023-template-resolution-merge-fix/plan.md` foi gerado pelo `setup-plan.sh` **antes** do fix e reproduziu o bug (só a seção Nimbus-Code apareceu, sem `## Summary`/`## Technical Context`/`## Constitution Check` nativos) — usado como evidência real, não hipotética |

**Resultado da consulta:**
- [x] Match encontrado — padrão(ões) de erro relevante(s) declarado(s) acima e mitigado(s)

## Nimbus-Code — Playbook de Sucesso Gate

| Padrão consultado (ID) | O que funcionou | Como foi reaplicado nesta feature |
|---|---|---|
| Nenhum | — | — |

**Resultado da consulta:**
- [x] Nenhum padrão relevante encontrado para este domínio

## Nimbus-Code — Rastreabilidade AC → Teste → Módulo

| ID AC | Critério (resumo) | Tipo de teste planejado | Arquivo/módulo do teste | Justificativa de ausência (se N/A) |
|---|---|---|---|---|
| AC-1 | Estratégia `wrap` substitui `{CORE_TEMPLATE}` | unitário (bats) | `.specify/scripts/bash/tests/resolve-template-composition.bats` | — |
| AC-2 | Estratégia `append` concatena base+preset | unitário (bats) | `.specify/scripts/bash/tests/resolve-template-composition.bats` | — |
| AC-3 | Estratégia `prepend` concatena preset+base | unitário (bats) | `.specify/scripts/bash/tests/resolve-template-composition.bats` | — |
| AC-4 | Estratégia `replace` vence integralmente (regressão) | unitário (bats) | `.specify/scripts/bash/tests/resolve-template-composition.bats` | — |
| AC-5 | Composição recursiva multi-camada | unitário (bats) | `.specify/scripts/bash/tests/resolve-template-composition.bats` | — |
| AC-6 | Regressão contra golden files de specs 021/022 | integração (bats) | `.specify/scripts/bash/tests/template-materialization-regression.bats` | — |
| AC-7 | Sem preset instalado, comportamento inalterado | unitário (bats) | `.specify/scripts/bash/tests/resolve-template-composition.bats` | — |

> Todos os 7 critérios de aceitação têm teste planejado — nenhuma linha N/A.

## Nimbus-Code — Module Dependency Graph

**Arquivos:**
- `specs/023-template-resolution-merge-fix/graph.yaml` — gerado por `scripts/generate-context-graph.sh` (bounded context `spec-kit-workflow`, single-repo)
- `specs/023-template-resolution-merge-fix/graph.md` — diagrama Mermaid correspondente

**Checklist de manutenção do grafo:**
- [x] `graph.yaml` criado/atualizado com todos os nós e arestas desta feature
- [x] `graph.md` criado/atualizado com diagrama por código e diagrama por business
- [x] Para S3/S4: `impact-map.md` — **N/A, feature é S2**
- [x] Nenhum módulo/serviço novo criado nesta feature está faltando no grafo
- [x] Dependências externas (third-party, cloud) declaradas em `externals` no `graph.yaml` — `specify_cli` citado como referência de paridade, não como dependência de execução
- [x] Grafo foi revisado após a implementação; nenhuma divergência de módulo foi identificada

### Grafo do Contexto (Multi-Repo Brownfield)

| Campo | Valor |
|---|---|
| **Bounded context** | `spec-kit-workflow` |
| **Grafo do contexto** | [graph.yaml](./graph.yaml) / [graph.md](./graph.md) — single-repo (`venha-pra-nuvem/nimbus-code-spec-kit-template`), sem repos satélite mapeados para este bounded context |
| **Dependências relevantes para esta feature** | Nenhuma — mudança confinada a este repositório; repos satélite apenas **consomem** o resultado (templates corretamente compostos) na próxima sincronização de preset, sem exigir mudança própria |
| **Padrões de harvest aplicáveis** | Nenhuma entrada em `docs/reuse-catalog.yaml` relacionada a composição de templates |

## Nimbus-Code — Estratégia de Release

| Campo | Valor |
|---|---|
| **Estratégia** | `direct` |
| **Feature flag name** | `N/A` |
| **Flag provider** | `N/A` |
| **Critério de ativação** | Merge do PR ativa a correção imediatamente para toda execução subsequente de `/speckit-specify`/`/speckit-plan`/`/speckit-tasks` neste repositório |
| **Critério de rollback** | Revert do PR — sem estado migrado, sem efeito colateral persistente além dos arquivos gerados |

> **Justificativa para deploy `direct`**: feature é S2 (não S3/S4, onde `flag`/`canary`/`blue-green`
> seriam obrigatórios), corrige um script de tempo de design sem componente de runtime, e a
> "reversão" é trivial (revert de PR) — não há usuário final de produção exposto a um rollout
> gradual. `resolve_template()` (caminho antigo) permanece intacto e funcional durante e após a
> mudança, então não há janela de indisponibilidade.

## Nimbus-Code — Cost Reference

| Campo | Valor |
|---|---|
| **Token estimate range** | ~10–16 mil tokens |
| **Human effort estimate range** | ~0,5–1 hora (revisão de PR) |
| **Tracking method** | Tabela "Estimativa vs. Consumo Real" no `tasks.md` |
| **Budget ceiling (optional)** | — |

## Nimbus-Code — SLO Gate

| Componente | Latência p99 | Taxa de erro máx. | Disponibilidade | RTO | RPO |
|---|---|---|---|---|---|
| `resolve_template_content` (composição) | — | — | — | — | — |

> Deixado `—`: script local de tempo de design, sem SLA de runtime — mesma justificativa já
> registrada no cabeçalho SLO do `spec.md`.

**SLOs não definidos nesta feature e justificativa:**
Toda a feature é um script síncrono de build-time (gera arquivos locais durante `/speckit-plan`/`/speckit-tasks`/`/speckit-specify`); não há componente de runtime de produção a monitorar.

## Nimbus-Code — Security & DevSecOps Gate

| Domínio | Controles aplicáveis | Escapável via ADL? | Status | Observações |
|---|---|---|---|---|
| Backup & Disaster Recovery | N/A | **Não — bloqueante** | ✅ N/A | Sem datastore de produção |
| Autenticação (SSO) | N/A | Sim, com justificativa no ADL | ✅ N/A | Sem superfície de autenticação nova |
| Segredos no código/repositório | Nenhum segredo introduzido | **Não — bloqueante** | ✅ | Mudança é só lógica de leitura/escrita de arquivo de template |
| Branch/merge protegido | PR obrigatório + revisão | **Não — bloqueante** | ✅ | Mesma convenção já vigente |
| Isolamento de ambiente | N/A | **Não — bloqueante** | ✅ N/A | Sem credencial de produção envolvida |
| Containers | N/A | Sim, com justificativa no ADL | ✅ N/A | Sem imagem de container nesta feature |
| CI/CD | N/A | Sim, com justificativa no ADL | ✅ N/A | Sem alteração de pipeline |
| IaC | N/A | Sim, com justificativa no ADL | ✅ N/A | Sem infraestrutura provisionada |
| Banco de dados | N/A | **Não — bloqueante** | ✅ N/A | Sem dado sensível em trânsito |
| Firewall / Segmentação de rede | N/A | Sim, com justificativa no ADL | ✅ N/A | Sem componente de rede |
| Observabilidade | N/A | Sim, com justificativa no ADL | ✅ N/A | Script de build-time, sem componente a observar (mesma justificativa do SLO Gate) |

**Riscos identificados e decisão:** Nenhum risco de segurança identificado — mudança confinada a lógica de composição de arquivos de texto locais, sem dado sensível, sem rede, sem credencial.

## Nimbus-Code — Qualidade de Código, Testes e Observabilidade Gate

| Domínio | Controles aplicáveis | Status | Observações |
|---|---|---|---|
| Revisão de código por IA | GitHub Copilot code review solicitado no PR; findings High/Critical bloqueiam merge | Pendente (no PR) | |
| Testes integrados | Cada AC (1–7) tem teste `bats` correspondente, incluindo regressão golden-file contra specs 021/022 | Planejado | Ver tabela de Rastreabilidade acima |
| Observabilidade | N/A — script de build-time sem componente de runtime | N/A | Mesma justificativa do SLO Gate |
| Arquitetura distribuída / Microsserviços | N/A | N/A | Não é sistema distribuído; script local |
| Gestão de bugs | Bugs fora de escopo encontrados durante a implementação (ex.: em `resolve_template_content()` em si, que hoje parece correta) serão abertos como Issue, não corrigidos inline | Regra declarada | Mitigação de HRN-0001 |

**Critérios de aceitação sem teste de integração automatizado (se houver) — justificativa:** Nenhum — todos os 7 ACs têm teste planejado (ver tabela de Rastreabilidade).

## Nimbus-Code — Architecture Decision Log

| Decisão | Alternativas consideradas | Opção escolhida | Trade-off assumido | Justificativa do desvio (se aplicável) | Aprovado por |
|---|---|---|---|---|---|
| Onde corrigir o bug de composição | (a) Reescrever `resolve_template_content()` do zero; (b) delegar para a CLI Python `specify` via `shell out`; (c) trocar os 3 call sites para usar a função de composição já correta existente em `common.sh` | (c) — trocar os call sites | Menor risco e menor superfície de mudança; não introduz dependência de invocar um binário externo (`specify`) a cada resolução de template, o que seria mais lento e frágil a mudanças de versão do pacote externo | N/A — não é desvio de padrão, é a opção de menor custo/risco encontrada durante a investigação técnica desta fase | — |
| Contrato de saída de `setup-tasks.sh` | (a) Mudar o JSON para carregar o conteúdo composto como string; (b) materializar o conteúdo composto em um arquivo de cache/temp e continuar devolvendo um caminho | (b) — manter contrato de caminho, mudar apenas o que esse caminho aponta para | Evita quebrar a skill `speckit-tasks` (que já espera ler um arquivo em `TASKS_TEMPLATE`) e qualquer outro consumidor externo do JSON de `setup-tasks.sh --json` | N/A — não é desvio de padrão | — |
