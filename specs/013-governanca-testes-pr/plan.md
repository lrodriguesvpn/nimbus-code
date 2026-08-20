# Implementation Plan: Governança de Testes em PR — Política E2E, Padrão Executável e Gate Unificado

**Branch**: `013-governanca-testes-pr` | **Date**: 2026-08-20 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/013-governanca-testes-pr/spec.md`

## Summary

Consolidar a governança de testes deste bundle Nimbus-Code: hoje o repositório já
tem testes executáveis reais, mas espalhados em dois formatos distintos
(`tests/bootstrap/*.bats` e `tests/{docs,scripts,workflows}/*.test.sh`) e sem
nenhum workflow de CI que rode a suíte completa em toda PR — cada um dos
workflows atuais (`validate-manifests.yml`, `graph-guard.yml`,
`dependency-review.yml`, `validate-issue-template-parity.yml`) valida uma
preocupação isolada. A abordagem técnica: (1) inventariar e classificar a
suíte existente numa política única (`docs/testing-policy.md`), comparando
Bats vs. scripts `.test.sh` vs. um terceiro formato plausível, com
recomendação e critérios de exceção explícitos; (2) criar um workflow único
(`test-suite.yml`) que descobre e roda toda a suíte mandatória em toda PR
contra `main`, com saída que identifica o segmento que falhou; (3) documentar
um único ponto de entrada de execução local com paridade ao gate de CI; (4)
formalizar a governança de exceções (novo formato, bypass, teste legado) via
Architecture Decision Log. Sem introdução de infraestrutura externa de teste
— o escopo é 100% o toolchain bash/GitHub Actions já usado pelo bundle.

## Technical Context

**Language/Version**: Bash 5 (mesmo toolchain de `scripts/harness-search.sh` e demais scripts do bundle) + GitHub Actions YAML

**Primary Dependencies**: `bats-core` (candidato à padronização — já usado em `tests/bootstrap/`, avaliado em `research.md` contra scripts `.test.sh` simples e contra Bash Automated Testing System via `shellspec` como terceira alternativa), `shellcheck` (já instalado por `scripts/setup-dev-environment.sh`), `gh` CLI

**Storage**: N/A — política é documento versionado (`docs/testing-policy.md`); nenhum datastore de produção

**Testing**: Meta — esta feature define a própria política de testes do bundle; o teste do teste é: (a) o workflow `test-suite.yml` roda de fato a suíte mandatória e bloqueia PR quando ela falha, (b) a execução local (`scripts/run-tests.sh` ou equivalente) produz o mesmo resultado

**Target Platform**: GitHub Actions (`ubuntu-latest`, GHE `venha-pra-nuvem.ghe.com`) + ambiente local/Codespace de contribuidor

**Project Type**: Tooling / convenção de processo — workflow de CI + script de execução local + documentação, sem serviço em produção

**Performance Goals**: Gate obrigatório de testes em PR conclui em < 900000 ms (15 min) — per SLO Alvo do `spec.md`

**Constraints**: Não pode depender de credenciais reais, rede externa ou estado de organização no caminho mandatório (Edge Cases do `spec.md`); não pode quebrar a suíte já existente durante a transição — testes legados exigem tratamento explícito (migração, exceção temporária ou remoção), nunca remoção silenciosa

**Scale/Scope**: Toda a suíte hoje existente sob `tests/` neste template (8 arquivos em 4 subpastas) + toda PR aberta contra `main` deste repositório; o padrão resultante é reutilizável por repositórios consumidores via `docs/reuse-catalog.yaml`, mas o rollout nesses repositórios está fora do escopo desta feature

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Status | Observação |
|---|---|---|
| Backup & DR | N/A | Nenhum datastore de produção — apenas workflow de CI e documento versionado no Git |
| Segredos no código | ✅ | Workflow usa apenas `GITHUB_TOKEN` padrão do runner; nenhuma credencial externa é necessária para rodar a suíte mandatória (Edge Cases do spec.md exigem isso) |
| Branch/merge protegido | ✅ | PR obrigatório conforme regras da org; esta feature reforça essa régua tornando o novo gate obrigatório também |
| Isolamento de ambiente | ✅ | Suíte roda em runner efêmero do GitHub Actions, sem acesso a ambientes de produção |
| Observabilidade | N/A | Workflow de CI local ao repositório, sem componente em runtime contínuo — saída do gate (pass/fail por segmento) cobre a necessidade de diagnóstico (FR-011) |
| IaC | N/A | Sem infraestrutura provisionada |
| Testes de integração por AC (constituição, seção "Qualidade e Processo") | ✅ | Ver tabela de Rastreabilidade AC → Teste → Módulo abaixo — esta feature é justamente a formalização dessa regra constitucional para a própria suíte do bundle |

**Gate: PASS** (sem exceções a justificar em Complexity Tracking).

## Project Structure

### Documentation (this feature)

```text
specs/013-governanca-testes-pr/
├── spec.md              ✅ Completo
├── plan.md              # Este arquivo
├── research.md          # Gerado nesta sessão
├── data-model.md        # Gerado nesta sessão
├── quickstart.md        # Gerado nesta sessão
├── graph.yaml           # Gerado nesta sessão
├── graph.md             # Gerado nesta sessão
├── impact-map.md        # Obrigatório (S3) — gerado nesta sessão
└── tasks.md             # Gerado por /speckit-tasks (próxima fase)
```

### Artefatos alterados (fora da pasta de spec)

```text
docs/
├── testing-policy.md               # novo — política oficial (taxonomia, matriz de decisão, gate obrigatório, exceções)
└── reuse-catalog.yaml               # + entrada apontando para esta feature, se o padrão de gate único for reaproveitável (FR-004)

scripts/
└── run-tests.sh                     # novo — ponto de entrada único de execução local com paridade ao gate de CI (FR-008)

.github/workflows/
└── test-suite.yml                   # novo — descobre e roda toda a suíte mandatória de tests/ em toda PR (FR-007)

tests/
└── (sem remoção de arquivos existentes nesta fase de plano — classificação e eventual migração tratadas via Exception Record, FR-010)
```

**Structure Decision**: Opção de projeto único (Bash CLI + workflow YAML +
documentação) — não se aplica nenhuma das opções de web/mobile do template
nativo, pois esta feature não introduz aplicação com frontend/backend
próprios.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

Nenhuma violação do Constitution Check acima — tabela intencionalmente vazia.

---

<!--
  Este bloco é inserido pelo preset `nimbus-code-standards` (estratégia `append`) ao final
  do plan-template.md nativo do Nimbus Code — não substitui nenhuma seção existente
  (Summary, Technical Context, Constitution Check, Project Structure, Complexity
  Tracking). Ele formaliza práticas que hoje viviam soltas nas skills internas
  de refinamento técnico e planejamento DevOps da Nimbus-Code.
-->

## Nimbus-Code — Classificação de Complexidade (S0–S4)

*Preencher antes de qualquer gate. Determina modelo de IA, artefatos obrigatórios e
nível de revisão exigido.*

| Campo | Valor |
|---|---|
| **Nível** | S0 · S1 · S2 · **S3** · S4 *(marcar um)* |
| **Justificativa** | Cruza múltiplos módulos do bundle: política de testes (`docs/`), workflow de CI (`.github/workflows/`), script de execução local (`scripts/`) e a estrutura já existente de `tests/` — sem introduzir arquitetura/segurança/dados críticos (não é S4) |
| **Modelo de IA** | Reasoning (S3 exige design detalhado antes de código, ver Constituição) |
| **Revisão humana obrigatória** | Não obrigatória por regra (S0–S3), mas recomendada dado impacto direto no fluxo de PR de todos os contribuidores |
| **Padrão reutilizado encontrado?** | Não — consultado `docs/reuse-catalog.yaml`; a entrada mais próxima (`standard-devcontainer`, tag de aceleração de CI/CD via Codespaces) cobre um problema adjacente (ambiente de dev), não a política/gate de testes em si. Ao final desta feature, a entrada de reuso resultante deve ser registrada para features futuras |
| **Estimativa de tokens (input+output)** | ~40–70 mil tokens (S3 típico: inventário real de arquivos existentes + matriz de decisão + design de workflow + 4 artefatos de Phase 1 + impact-map.md) |

> S0 = documentação · S1 = função isolada · S2 = módulo · S3 = múltiplos módulos ·
> S4 = arquitetura, segurança, dados ou integração crítica

> A estimativa de tokens é preenchida **antes** de `/nimbus-code-tasks` e comparada
> com o consumo real no fechamento do `tasks.md` (ver checklist "Estimativa vs.
> Consumo Real de Tokens"). Não é um compromisso exato — é uma faixa para
> permitir comparar depois.

## Nimbus-Code — Harness Gate

*Preencher ANTES de qualquer gate. Consultar `docs/harness/harness-catalog.yaml`
por `tags` e `bounded_context` relacionados ao domínio desta feature.
Se o arquivo estiver vazio, declarar "Catálogo vazio". Nunca deixar em branco.*

> **Como consultar:** `./scripts/harness-search.sh <tag>` — ou `grep` direto no YAML.
> Consultar também `docs/reuse-catalog.yaml` (padrões de soluções, não de erros).

| Harness consultado (ID) | Padrão de erro evitado | Mitigação preventiva aplicada nesta feature |
|---|---|---|
| Nenhum HRN específico de CI/testes catalogado ainda | — | — |

**Resultado da consulta:**
- [ ] Match encontrado — padrão(ões) de erro relevante(s) declarado(s) acima e mitigado(s)
- [x] Nenhum padrão de erro relevante encontrado para este domínio

> **Observação (não-HRN formal, mas relevante como precedente da mesma sessão)**:
> esta mesma sessão descobriu um padrão de risco análogo ao que esta feature
> deve evitar — `scripts/setup-github-labels.sh` tinha labels definidos em
> código, mas o script nunca havia sido re-executado contra produção ("código
> diz X, produção nunca recebeu X"). O risco equivalente aqui é criar
> `test-suite.yml`/`run-tests.sh` que existem no repositório mas nunca são de
> fato acionados/mantidos em dia — a política desta feature (FR-007, FR-012)
> mitiga isso ao tornar o gate obrigatório e bloqueante, não apenas disponível.
> Recomenda-se abrir uma entrada formal em `docs/harness/harness-catalog.yaml`
> para esse padrão de drift código↔produção como tarefa de acompanhamento
> (fora do escopo desta feature específica).

> Se esta feature gerar retrabalho > 20% ou incidente, o checklist de fechamento do
> `tasks.md` exige abrir Issue com `harness:pending` e adicionar entrada ao catálogo.
> Ver `docs/harness/harness-guide.md` para o protocolo completo.

## Nimbus-Code — Rastreabilidade AC → Teste → Módulo

*Preencher antes de `/nimbus-code-tasks`. Cada critério de aceitação do `spec.md`
deve ter ao menos um teste de integração planejado e o módulo que o implementa
identificado — assim o Dev entra no `/nimbus-code-implement` sem surpresas.*

| ID AC | Critério (resumo) | Tipo de teste planejado | Arquivo/módulo do teste | Justificativa de ausência (se N/A) |
|---|---|---|---|---|
| AC-1 | Política inventaria grupos de testes existentes e declara ausência de gate consolidado | unitário (doc) | validação manual + `tests/docs/testing-policy.test.sh` (novo) confere presença das seções obrigatórias em `docs/testing-policy.md` | — |
| AC-2 | Política compara formatos viáveis (Bats/`.test.sh`/terceira opção) com prós/contras/critérios | unitário (doc) | mesmo `tests/docs/testing-policy.test.sh` — grep de seções "Matriz de Decisão" | — |
| AC-3 | Gate obrigatório roda suíte mandatória em toda PR e bloqueia merge em falha | integração | `.github/workflows/test-suite.yml` — validado via execução real do workflow numa PR de teste (não neste repositório de produção sem necessidade, ver `quickstart.md`) | — |
| AC-4 | Contribuidor descobre e executa localmente a mesma validação mandatória | integração | `scripts/run-tests.sh` + Cenário 1 do `quickstart.md` | — |
| AC-5 | Política define taxonomia (unitário/integração/e2e) e convenções de localização/nomenclatura | unitário (doc) | mesmo `tests/docs/testing-policy.test.sh` — grep de seção "Taxonomia" | — |
| AC-6 | Política exige exceção formal (justificativa + aprovador) para novo formato/bypass/remoção | unitário (doc) | mesmo `tests/docs/testing-policy.test.sh` — grep de seção "Governança de Exceções" | — |

> Linha com **Tipo: N/A** exige justificativa explícita (ex.: dependência externa
> indisponível em CI). Critérios sem entrada nesta tabela são tratados como sem
> cobertura — o Qualidade Gate bloqueará o `plan.md`.

## Nimbus-Code — Module Dependency Graph

*OBRIGATÓRIO — deve estar presente e atualizado antes de `/nimbus-code-tasks`.
Para S3/S4, criar também `impact-map.md` na mesma pasta.*

**Arquivos:**
- `specs/<feature-slug>/graph.yaml` — fonte de verdade estruturada (lida pelo Graph Guard)
- `specs/<feature-slug>/graph.md` — diagramas Mermaid para leitura humana
- `specs/<feature-slug>/impact-map.md` — **obrigatório para S3 e S4**

**Checklist de manutenção do grafo:**
- [ ] `graph.yaml` criado/atualizado com todos os nós e arestas desta feature
- [ ] `graph.md` criado/atualizado com diagrama por código e diagrama por business
- [ ] Para S3/S4: `impact-map.md` criado/atualizado com análise de risco e plano de rollback
- [ ] Nenhum módulo/serviço novo criado nesta feature está faltando no grafo
- [ ] Dependências externas (third-party, cloud) declaradas em `externals` no `graph.yaml`
- [ ] Grafo será atualizado novamente após `/nimbus-code-implement` se a implementação divergir do plano

## Nimbus-Code — Estratégia de Release

*Declarar antes de `/nimbus-code-tasks`. Para S3/S4, esta escolha alimenta o
`impact-map.md` (simplifica ou complica o plano de rollback).*

| Campo | Valor |
|---|---|
| **Estratégia** | `direct` |
| **Feature flag name** | N/A |
| **Flag provider** | N/A |
| **Critério de ativação** | N/A — ver rollout faseado documentado abaixo |
| **Critério de rollback** | `git revert` do PR que adiciona `test-suite.yml`; enquanto o workflow não estiver marcado como "required status check" na proteção de branch, ele roda em modo relatório (não bloqueia merge) — reversão imediata sem impacto se o gate se mostrar instável |

> **Regra**: features S3/S4 **obrigam** estratégia `flag`, `canary` ou `blue-green`
> — `direct` não é permitido sem justificativa explícita registrada aqui e no ADL.
>
> **Regra adicional**: quando houver toggle, o plano **deve** declarar OpenFeature como padrão.
> O provider específico (LaunchDarkly, AppConfig etc.) fica atrás da API OpenFeature.

**Justificativa para deploy `direct`:**
Esta feature não introduz software com toggle de runtime — o "rollout" real é
uma mudança de política de CI/governança de branch protection do próprio
repositório, sem equivalente de feature flag de aplicação (OpenFeature não se
aplica a "quais checks são obrigatórios na proteção de branch do GitHub").
Em vez de flag, o rollout é faseado manualmente e registrado aqui como ADL:
(1) `test-suite.yml` é adicionado e roda em **modo relatório** (não obrigatório)
por um período de observação definido pelo humano no PR de implementação;
(2) após o período sem falso-positivo relevante, o check passa a
"required" na proteção de branch de `main` — decisão humana explícita, não
automática. Mesmo racional de "documentação/convenção sem componente de
produção com rollout incremental de software" já usado nas features 001, 011
e 012.

## Nimbus-Code — Plano de Toggle e Rollout (obrigatório com `flag`)

*Preencher para toda feature que usar toggle. Obrigatório para S3/S4 quando
houver homologações concorrentes.*

| Campo | Valor |
|---|---|
| **Flag key** | N/A — sem toggle de software; ver rollout faseado manual na Estratégia de Release acima |
| **Tipo de flag** | N/A |
| **Owner da flag** | N/A |
| **Ambiente(s)** | N/A |
| **Default por ambiente** | N/A |
| **Segmentos de ativação** | N/A |
| **Estratégia de rollout** | Ver Estratégia de Release: modo relatório → required check, decisão humana explícita |
| **Kill switch definido?** | Sim — remover o job `test-suite.yml` da lista de "required status checks" na proteção de branch reverte o comportamento bloqueante instantaneamente, sem precisar reverter código |
| **Critério de limpeza** | N/A — não é uma flag temporária a ser removida |
| **Issue/tarefa de remoção criada?** | N/A |

**Conflitos funcionais entre homologações (quando aplicável):**
N/A — não há homologações concorrentes nesta feature.

## Nimbus-Code — Cost Reference

*Obrigatório para features com participação híbrida agente+humano. O objetivo é
deixar explícito como estimativa e consumo real serão rastreados ao longo do ciclo.*

| Campo | Valor |
|---|---|
| **Token estimate range** | ~40–70 mil tokens (ver Classificação de Complexidade acima) |
| **Human effort estimate range** | ~3–6 horas (revisão da política proposta, aprovação do rollout faseado do gate obrigatório, decisão sobre marcar o check como "required") |
| **Tracking method** | Tabela "Estimativa vs. Consumo Real de Tokens" no `tasks.md` + campo "Horas Humanas" no GitHub Project |
| **Budget ceiling (optional)** | N/A |

## Nimbus-Code — SLO Gate

*Preencher para todo componente novo ou alterado de forma relevante. Os valores
aqui definidos são a referência para configuração de alertas (Observability Gate)
e critérios de Go/No-Go do `impact-map.md` (S3/S4).*

| Componente | Latência p99 | Taxa de erro máx. | Disponibilidade | RTO | RPO |
|---|---|---|---|---|---|
| `test-suite.yml` (gate obrigatório de PR) | < 900000 ms (15 min) | 1% de falha espúria máxima (SC do spec.md) | 99% das PRs recebem resultado conclusivo na 1ª execução | 1 dia útil (reverter para modo relatório) | N/A |
| `docs/testing-policy.md` (política versionada) | — | 0% (artefato estático versionado no Git) | — | — | — |

> Deixar `—` apenas quando o componente não expõe SLO mensurável (ex.: job batch
> interno). Omissão sem justificativa bloqueia o Observability Gate.

**SLOs não definidos nesta feature e justificativa:**
`scripts/run-tests.sh` (execução local): sem SLO formal — depende do hardware/ambiente
do contribuidor, fora do controle da feature; a paridade de resultado com o gate de CI
(não o tempo) é o critério relevante (AC-4).

## Nimbus-Code — Security & DevSecOps Gate

*GATE adicional: deve ser preenchido e aprovado antes de `/nimbus-code-tasks`, junto com
o Constitution Check nativo. Cobre lacunas que a constituição sozinha não detalha
por domínio técnico.*

**Regra de decisões de arquitetura — não impor, documentar e pedir aprovação**:
se durante o planejamento o agente identificar uma decisão de arquitetura (do
usuário ou proposta por ele mesmo) que diverge do padrão institucional, o
agente **não implementa silenciosamente a preferência dele nem a do usuário**.
Ele registra a divergência no Architecture Decision Log abaixo, explica
objetivamente por que considera fora do padrão, e:
- Se o item estiver marcado **Bloqueante** na tabela abaixo: não há exceção
  possível — o gate falha até o controle existir de fato (ex.: não existe
  "justificativa" que substitua ter um backup).
- Se o item estiver marcado **Escapável (ADL)**: o usuário pode manter a
  decisão fora do padrão, mas precisa justificar explicitamente no ADL e essa
  justificativa precisa de aprovação (do owner do repo ou de quem a
  constituição designar) antes do gate ser considerado satisfeito.

| Domínio | Controles aplicáveis | Escapável via ADL? | Status | Observações |
|---|---|---|---|---|
| **Backup & Disaster Recovery** | Todo datastore com dado real (produção) tem backup automatizado, retenção definida e restore testado/documentado ao menos uma vez | **Não — bloqueante** | N/A | Nenhum datastore — apenas Git (já versionado/replicado pelo próprio GHE) |
| Autenticação (SSO) | Sistemas novos (greenfield) devem usar SSO | Sim, com justificativa no ADL | N/A | Nenhum sistema/login novo introduzido |
| Segredos no código/repositório | Nunca em texto plano; secret scanning bloqueia merge se detectar | **Não — bloqueante** | ✅ | `test-suite.yml` usa apenas `GITHUB_TOKEN` padrão do runner (Edge Cases do spec.md exigem isso explicitamente) |
| Branch/merge protegido | PR obrigatório + revisão antes de merge em branch protegida; nenhum merge com CI vermelho ou check obrigatório pulado | **Não — bloqueante** | ✅ | Já vigente; esta feature reforça a régua tornando o novo gate também obrigatório |
| Isolamento de ambiente | Credencial de produção nunca usada em ambiente de dev/test | **Não — bloqueante** | ✅ | Runner efêmero do GitHub Actions, sem credenciais de produção |
| Containers | Imagem base pinada, scan de vulnerabilidade, usuário não-root | Sim, com justificativa no ADL | N/A | Sem container próprio — usa runner padrão `ubuntu-latest` do GitHub Actions |
| CI/CD | Segredos via cofre/CI secrets, least privilege no service account do pipeline | Sim, com justificativa no ADL | ✅ | Nenhum segredo adicional requisitado; `GITHUB_TOKEN` já é least-privilege por padrão |
| IaC — provider(s) usado(s) | 100% da infra desta feature via IaC | Sim, com justificativa no ADL | N/A | Sem infraestrutura provisionada (workflow YAML não é IaC de infraestrutura) |
| Banco de dados | TLS/mTLS obrigatório para dado sensível em trânsito | **Não — bloqueante** | N/A | Sem banco de dados |
| **Firewall / Segmentação de rede** | Regras de firewall/least exposure, sem exposição pública desnecessária | Sim, com justificativa no ADL | N/A | Sem exposição de rede nova |
| Observabilidade | Logs, métricas e alertas mínimos definidos para os componentes críticos | Sim, com justificativa no ADL | ✅ | Saída do `test-suite.yml` já funciona como log/observabilidade mínima exigida (FR-011: identificar segmento que falhou na 1ª leitura) |

**Riscos identificados e decisão:**
Único risco relevante: tornar o gate obrigatório de forma abrupta pode bloquear
PRs legítimas por falso-positivo ou por teste legado ainda não classificado.
Decisão: **mitigar em fase seguinte com data** — rollout faseado (modo relatório
→ required check) documentado na Estratégia de Release acima, com o humano
aprovando a transição.

## Nimbus-Code — Qualidade de Código, Testes e Observabilidade Gate

*GATE adicional: deve ser preenchido e aprovado antes de `/nimbus-code-tasks`, junto
com o Constitution Check nativo e o Security & DevSecOps Gate acima. Traduz em
verificações concretas as regras de "Qualidade e Processo" da constituição da
Nimbus-Code (revisão por IA, testes integrados, observabilidade, arquitetura
distribuída e gestão de bugs).*

| Domínio | Controles aplicáveis | Status | Observações |
|---|---|---|---|
| Revisão de código por IA | GitHub Copilot code review solicitado em todo PR desta feature; findings High/Critical bloqueiam merge (mesma régua do SAST/IaC) | ✅ | Aplicável ao PR de implementação (fora do escopo desta sessão de plano) |
| Testes integrados | Cada critério de aceitação do `spec.md` tem teste de integração automatizado correspondente, sempre que tecnicamente viável | ✅ | Ver tabela de Rastreabilidade AC → Teste → Módulo acima — todos os 6 AC têm teste planejado |
| Observabilidade | Logs estruturados, métricas e alertas mínimos instrumentados para os componentes entregues (obrigatório, não condicional) | ✅ | Saída padrão do GitHub Actions (por job/step) já expõe qual segmento falhou (FR-011); sem necessidade de instrumentação adicional |
| Arquitetura distribuída / Microsserviços | Correlation-id/trace-id (W3C Trace Context) propagado ponta a ponta entre serviços; orquestração/coreografia documentada no Architecture Decision Log abaixo | N/A | Sem chamadas entre serviços — workflow de CI local ao repositório |
| Gestão de bugs | Bugs encontrados fora do escopo desta tarefa/feature abertos como Issue no GitHub e atribuídos ao Copilot coding agent | ✅ | Regra padrão do bundle, sem exceção nesta feature |

**Critérios de aceitação sem teste de integração automatizado (se houver) — justificativa:**
Nenhum. Os 6 AC do `spec.md` têm teste planejado (unitário de documentação ou
integração de workflow) — ver tabela de Rastreabilidade acima.

## Nimbus-Code — Architecture Decision Log

*Preencher para decisões técnicas relevantes desta feature, e **obrigatoriamente**
para qualquer item marcado "Escapável via ADL" nos gates acima que não seguiu o
padrão institucional. Decisões triviais/óbvias não precisam de entrada aqui.*

| Decisão | Alternativas consideradas | Opção escolhida | Trade-off assumido | Justificativa do desvio (se aplicável) | Aprovado por |
|---|---|---|---|---|---|
| Formato executável principal para novos testes do bundle | Bats-core (já usado em `tests/bootstrap/`) vs. scripts `.test.sh` simples (já usados em `tests/{docs,scripts,workflows}/`) vs. `shellspec` (terceira opção, sintaxe BDD) | A decidir em `research.md` — recomendação preliminar por Bats-core (já provado em produção, sintaxe padronizada de asserção) | Migrar os `.test.sh` existentes para Bats tem custo de conversão vs. manter heterogeneidade documentada como exceção temporária | N/A — não é desvio de padrão institucional, é a própria decisão que esta feature formaliza | Pendente aprovação humana no PR de implementação |
| Estratégia de release `direct` em vez de `flag`/`canary` para uma feature S3 | Feature flag via OpenFeature (não aplicável a required status checks do GitHub) vs. rollout faseado manual (modo relatório → required) | Rollout faseado manual, documentado na Estratégia de Release | Sem automação de ativação gradual — depende de decisão humana explícita para promover a "required" | OpenFeature não tem equivalente para políticas de branch protection do GitHub; alternativa documentada substitui o mecanismo de flag com controle humano equivalente | Pendente aprovação humana no PR de implementação |
