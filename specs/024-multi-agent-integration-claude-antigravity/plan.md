# Implementation Plan: Multi-Agent Integration (Claude Code + Antigravity)

**Branch**: `024-multi-agent-integration-claude-antigravity` | **Date**: 2026-09-20 | **Spec**: [spec.md](/Users/lrodrigues/projects/nimbus-code-spec-kit-template.worktrees/users-lrodrigues-projects-nimbus-code-spec-kit-t/specs/024-multi-agent-integration-claude-antigravity/spec.md)

**Input**: Feature specification from `specs/024-multi-agent-integration-claude-antigravity/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Trazer os 12 comandos agnósticos `/speckit-*` e os 9 agentes institucionais `/nc-*` do Nimbus Code para **Claude Code** e **Antigravity**, além do Copilot já suportado, sem remover ou degradar nada do que existe hoje. Abordagem técnica: (1) os 12 comandos `/speckit-*` já são gerenciados pelo próprio `specify` CLI — `specify integration install claude`/`agy` os instala automaticamente em `.claude/skills/`/`.agents/skills/`; (2) os 9 agentes `/nc-*` são customização institucional exclusiva deste template e não são gerenciados pelo `specify` CLI — para eles, criar um **script gerador de sincronização** que lê `.github/skills/nc-*/SKILL.md` como fonte única e emite cópias equivalentes para `.claude/skills/` e `.agents/skills/`, aplicando o pós-processamento específico de cada integração (argument-hint no Claude; nota de conversão `.`→`-` em nomes de comando de hook no Antigravity — o mesmo padrão que o próprio `specify` CLI já aplica aos 12 comandos nativos). Um teste de paridade (bats) impede que as três pastas fiquem fora de sincronia. Antigravity, por não ser `multi_install_safe`, é validado primeiro em worktree isolado antes de qualquer promoção à branch principal.

## Technical Context

**Language/Version**: Bash (compatível com os scripts existentes em `.specify/scripts/bash/` e `scripts/`) + Markdown/YAML (formato `SKILL.md` com frontmatter)

**Primary Dependencies**: `specify` CLI (`specify integration install claude|agy`, já disponível como dependência de ferramenta, não de código) + `yq`/Python (mesmas ferramentas já usadas pelos scripts de sync de preset da SPEC 020, ex. `scripts/scan-org-rename-references.sh`)

**Storage**: N/A — apenas arquivos versionados em git (`.github/skills/`, `.claude/skills/`, `.agents/skills/`)

**Testing**: `bats` (mesmo framework usado em `tests/platform/*.bats` e `tests/bootstrap/*.bats`) para o gate de paridade; `bash -n`/lint YAML para os scripts novos

**Target Platform**: Ambiente local de desenvolvimento (macOS/Linux) + GitHub Actions (CI) — sem componente de runtime em produção

**Project Type**: Ferramenta de linha de comando / automação de repositório (extensão do bootstrap/preset já existente, não uma aplicação nova)

**Performance Goals**: N/A — script roda sob demanda (dev local ou CI), sem requisito de latência de runtime

**Constraints**: A instalação de Claude Code ou Antigravity **nunca** pode alterar arquivos hoje gerenciados pela integração Copilot; a instalação do Antigravity exige CLI `v1.20.5+` e deve ser validada em worktree isolado antes de ir para a branch principal (não é `multi_install_safe`)

**Scale/Scope**: 12 comandos `/speckit-*` + 9 agentes `/nc-*`, replicados para 2 integrações novas (Claude Code, Antigravity), mantendo a 1ª (Copilot) intocada — 3 integrações no total ao final

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **1 branch por sessão / isolamento de escopo**: esta feature só toca `.claude/`, `.agents/`, o novo script gerador, seus testes e a documentação do dev guide — não altera `.github/skills/nc-*` além de leitura (fonte única, não modificada por este trabalho). PASS.
- **Grafo de dependência obrigatório**: `graph.yaml`/`graph.md` já gerados em `/speckit-specify` via `scripts/generate-context-graph.sh` para o bounded context `spec-kit-workflow` (single-repo, sem arestas externas). PASS.
- **Gate de segurança / Não-Negociáveis**: nenhum dado sensível, nenhuma credencial, nenhuma alteração de mecanismo de autenticação — não aciona os itens Bloqueantes do Security Gate. A única atenção operacional é o `multi_install_safe: false` do Antigravity, endereçado via validação em worktree isolado (ver Security & DevSecOps Gate abaixo). PASS.
- **Reuso antes de re-derivar**: consultado `docs/reuse-catalog.yaml` e `docs/harness/harness-catalog.yaml` — nenhuma tag cataloga exatamente "sincronizar uma fonte única para múltiplos destinos com gate de drift", mas o precedente técnico direto é a função `detect_preset_version_mismatch()` do `bootstrap.sh` (SPEC 020) — reaproveitado como padrão de implementação, não re-derivado do zero (ver Harness Gate). PASS.

Nenhuma violação a justificar na Complexity Tracking abaixo.

## Project Structure

### Documentation (this feature)

```text
specs/024-multi-agent-integration-claude-antigravity/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
├── graph.yaml           # Já gerado por /speckit-specify
├── graph.md             # Já gerado por /speckit-specify
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
scripts/
└── sync-nc-agents-to-integrations.sh   # Novo: gerador de sync NC-* -> Claude/Antigravity

.github/skills/nc-*/SKILL.md            # Fonte única (já existente, não recriada nesta feature)
.claude/skills/                         # Novo: gerado por `specify integration install claude`
├── speckit-*/SKILL.md                  #   12 comandos, gerados automaticamente pelo CLI
└── nc-*/SKILL.md                       #   9 agentes, gerados pelo script novo acima
.agents/skills/                         # Novo: gerado por `specify integration install agy`
├── speckit-*/SKILL.md                  #   12 comandos, gerados automaticamente pelo CLI
└── nc-*/SKILL.md                       #   9 agentes, gerados pelo script novo acima

tests/
└── multi-agent-integration/
    └── nc-agents-parity.bats           # Novo: gate de paridade entre as 3 pastas

.github/workflows/
└── nc-agents-parity-check.yml          # Novo: roda o teste de paridade no CI

docs/
└── developer-guide.md                  # Atualizado: seção "Agentes disponíveis por integração"
```

**Structure Decision**: Projeto de automação/tooling de repositório (não uma aplicação com camadas model/service/API) — a estrutura segue o padrão já usado pelas features de bootstrap/preset anteriores (SPEC 020, SPEC 008): um script gerador em `scripts/`, saída em pastas geridas por integração (`.claude/`, `.agents/`), teste `bats` dedicado em `tests/`, e gate correspondente em `.github/workflows/`. Não há Opção 2/3 (web app / mobile) aplicável.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | Nenhuma violação identificada | N/A |


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
| **Nível** | **S3** |
| **Justificativa** | Cruza múltiplos artefatos institucionais (12 comandos `/speckit-*` geridos pelo CLI + 9 agentes `/nc-*` geridos manualmente) e duas integrações externas novas (Claude Code, Antigravity) que passam a fazer parte do fluxo de release do template — não é uma função isolada nem um único módulo, mas também não envolve dado sensível/arquitetura crítica que justifique S4 |
| **Modelo de IA** | Reasoning (conforme tabela S3 do `ai-code-quality-and-observability.md`) |
| **Revisão humana obrigatória** | Não (S3) — mas o Antigravity, por não ser `multi_install_safe`, exige validação em worktree isolado antes de promover à branch principal (ver Security & DevSecOps Gate) |
| **Padrão reutilizado encontrado?** | Não — nenhuma tag de `docs/reuse-catalog.yaml` cobre "sincronizar uma fonte única de artefatos para múltiplos destinos de integração com gate de drift"; o precedente técnico mais próximo é `detect_preset_version_mismatch()` do `bootstrap.sh` (SPEC 020, tag `greenfield-multirepo-governance-baseline`), reaproveitado como referência de implementação (ver Harness Gate), não como match direto de tag |
| **Estimativa de tokens (input+output)** | ~35–55 mil tokens — script gerador + testes de paridade + workflow CI + atualização de `developer-guide.md`, sem desconto de reuso direto (nenhum match de tag), mas com aceleração pelo precedente técnico de SPEC 020 |

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
| HRN-0001 | Agente expande escopo silenciosamente além do combinado com o Dev (scope creep) | Escopo travado ao que o usuário confirmou explicitamente: 12 comandos + 9 agentes, apenas Claude Code e Antigravity — nenhuma integração adicional (ex.: Cursor, Windsurf) será tocada nesta feature sem novo pedido explícito |
| HRN-0003 | Planejar sem consultar `docs/reuse-catalog.yaml` antes, re-derivando solução já resolvida | Catálogo consultado antes de preencher este `plan.md` (ver Classificação de Complexidade acima) — nenhuma tag é match direto, mas o precedente de `detect_preset_version_mismatch()` (SPEC 020) foi identificado e será reaproveitado como referência de implementação do gate de paridade |
| HRN-0002 | Agente implementa decisão de arquitetura divergente do padrão institucional sem documentar/pedir aprovação | Não há divergência de padrão institucional nesta feature (nenhum item do Security & DevSecOps Gate abaixo está marcado como desvio) — citado aqui apenas como lembrete de processo já seguido |

**Resultado da consulta:**
- [x] Match encontrado — padrão(ões) de erro relevante(s) declarado(s) acima e mitigado(s)
- [ ] Nenhum padrão de erro relevante encontrado para este domínio
- [ ] Catálogo vazio — nenhum padrão disponível para consulta

> Se esta feature gerar retrabalho > 20% ou incidente, o checklist de fechamento do
> `tasks.md` exige abrir Issue com `harness:pending` e adicionar entrada ao catálogo.
> Ver `docs/harness/harness-guide.md` para o protocolo completo.

## Nimbus-Code — Playbook de Sucesso Gate

*Preencher ANTES de qualquer gate. Consultar `docs/playbooks/success-catalog.yaml`
por `tags` e `bounded_context` relacionados ao domínio desta feature.
Se o arquivo estiver vazio, declarar "Catálogo vazio". Nunca deixar em branco.*

> **Como consultar:** `grep -i "<tag>" docs/playbooks/success-catalog.yaml`

| Padrão consultado (ID) | O que funcionou | Como foi reaplicado nesta feature |
|---|---|---|
| SUC-0002 | Rollout faseado contract-first (spec/critérios de aceite documentados antes do script) elimina retrabalho de integração | `spec.md` da SPEC 024 já define os 6 ACs e o escopo exato (12 comandos + 9 agentes, 2 integrações) antes de qualquer linha do script gerador ser escrita — o script "passa" quando o teste de paridade valida o contrato já acordado, não o contrário |
| SUC-0001 | Reaproveitar schema/estrutura análoga existente em vez de desenhar do zero | O script gerador segue a mesma estrutura de scripts de sync/detecção de drift já usados em `bootstrap.sh` (SPEC 020) — nenhum design novo de "como sincronizar N destinos a partir de 1 fonte" foi necessário |

**Resultado da consulta:**
- [x] Match encontrado — padrão(ões) de sucesso relevante(s) declarado(s) acima e reaplicado(s)
- [ ] Nenhum padrão relevante encontrado para este domínio
- [ ] Catálogo vazio — nenhum padrão disponível para consulta

> Se esta feature produzir um padrão digno de repetição, o checklist de fechamento do
> `tasks.md` pergunta "o que deu certo aqui?". Registrar em `docs/playbooks/success-catalog.yaml`.
> Ver `docs/playbooks/README.md` para o protocolo completo.

## Nimbus-Code — Rastreabilidade AC → Teste → Módulo

*Preencher antes de `/nimbus-code-tasks`. Cada critério de aceitação do `spec.md`
deve ter ao menos um teste de integração planejado e o módulo que o implementa
identificado — assim o Dev entra no `/nimbus-code-implement` sem surpresas.*

| ID AC | Critério (resumo) | Tipo de teste planejado | Arquivo/módulo do teste | Justificativa de ausência (se N/A) |
|---|---|---|---|---|
| AC-1 | `specify integration install claude` instala os 12 `/speckit-*` em `.claude/skills/` sem alterar `.github/skills/` | integração | `tests/multi-agent-integration/nc-agents-parity.bats::test_AC1_claude_speckit_commands_installed` | — |
| AC-2 | Script gerador sincroniza os 9 `/nc-*` para `.claude/skills/` com `argument-hint` aplicado | integração | `tests/multi-agent-integration/nc-agents-parity.bats::test_AC2_nc_agents_synced_to_claude` | — |
| AC-3 | `specify integration install agy` em worktree isolado, aviso de versão mínima, sem tocar Copilot/Claude | integração | `tests/multi-agent-integration/nc-agents-parity.bats::test_AC3_agy_isolated_install_validated` | — |
| AC-4 | Script gerador sincroniza os 9 `/nc-*` para `.agents/skills/` com nota de conversão `.`→`-` aplicada | integração | `tests/multi-agent-integration/nc-agents-parity.bats::test_AC4_nc_agents_synced_to_agy` | — |
| AC-5 | Gate de paridade bats bloqueia PR/CI quando as 3 pastas ficam fora de sincronia | integração (CI gate) | `tests/multi-agent-integration/nc-agents-parity.bats::test_AC5_nc_agents_parity_gate` + `.github/workflows/nc-agents-parity-check.yml` | — |
| AC-6 | `docs/developer-guide.md` documenta os 12+9 artefatos por integração e o risco Claude vs Antigravity | unitário (lint de doc / grep de seção obrigatória) | `tests/multi-agent-integration/nc-agents-parity.bats::test_AC6_developer_guide_documents_integrations` | — |

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
- [x] `graph.yaml` criado/atualizado com todos os nós e arestas desta feature (single-repo, 1 nó — gerado por `scripts/generate-context-graph.sh spec-kit-workflow --feature 024-multi-agent-integration-claude-antigravity`)
- [x] `graph.md` criado/atualizado com diagrama por código e diagrama por business
- [ ] Para S3/S4: `impact-map.md` criado/atualizado com análise de risco e plano de rollback — **pendente, será gerado na Fase 1 desta execução de `/speckit-plan`** (obrigatório para S3)
- [x] Nenhum módulo/serviço novo criado nesta feature está faltando no grafo (feature é single-repo, sem serviços novos)
- [x] Dependências externas (third-party, cloud) declaradas em `externals` no `graph.yaml` — `specify` CLI declarado como dependência externa de ferramenta
- [x] Grafo será atualizado novamente após `/nimbus-code-implement` se a implementação divergir do plano

### Grafo do Contexto (Multi-Repo Brownfield)

| Campo | Valor |
|---|---|
| **Bounded context** | `spec-kit-workflow` (registrado em `docs/bounded-contexts.yaml`) |
| **Grafo do contexto** | [graph.yaml](/Users/lrodrigues/projects/nimbus-code-spec-kit-template.worktrees/users-lrodrigues-projects-nimbus-code-spec-kit-t/specs/024-multi-agent-integration-claude-antigravity/graph.yaml) / [graph.md](/Users/lrodrigues/projects/nimbus-code-spec-kit-template.worktrees/users-lrodrigues-projects-nimbus-code-spec-kit-t/specs/024-multi-agent-integration-claude-antigravity/graph.md) |
| **Dependências relevantes para esta feature** | Nenhuma — bounded context `spec-kit-workflow` é single-repo (o próprio template Nimbus Code); não há repos satélite afetados por esta feature |
| **Padrões de harvest aplicáveis** | Nenhuma — nenhuma entrada de `docs/reuse-catalog.yaml` originada de `scripts/harvest-patterns.sh` cobre este domínio |

## Nimbus-Code — Estratégia de Release

*Declarar antes de `/nimbus-code-tasks`. Para S3/S4, esta escolha alimenta o
`impact-map.md` (simplifica ou complica o plano de rollback).*

| Campo | Valor |
|---|---|
| **Estratégia** | `direct` |
| **Feature flag name** | `N/A` — não se aplica |
| **Flag provider** | `N/A` — não se aplica |
| **Critério de ativação** | N/A |
| **Critério de rollback** | `git revert` do PR (arquivos afetados: `.claude/`, `.agents/`, script gerador, testes, CI — nenhum estado externo/runtime de produção) |

> **Regra**: features S3/S4 **obrigam** estratégia `flag`, `canary` ou `blue-green`
> — `direct` não é permitido sem justificativa explícita registrada aqui e no ADL.
>
> **Regra adicional**: quando houver toggle, o plano **deve** declarar OpenFeature como padrão.
> O provider específico (LaunchDarkly, AppConfig etc.) fica atrás da API OpenFeature.

**Justificativa para deploy `direct` (se aplicável):**
Esta feature não tem componente de runtime de produção nem usuário final navegando um fluxo — é uma extensão de **tooling de desenvolvimento** (arquivos de skill/comando lidos por CLIs de terceiros, sob demanda, no ambiente local do Dev). Não há "tráfego" para segmentar nem sessão de usuário em produção para proteger com canary. O equivalente funcional a um kill switch é o próprio gate de paridade (AC-5): se a sincronização introduzir inconsistência entre `.github/skills/`, `.claude/skills/` e `.agents/skills/`, o CI falha antes do merge — rollback é `git revert`, instantâneo, sem efeito colateral em runtime. O único ponto de risco real (Antigravity, `multi_install_safe: false`) tem seu próprio controle dedicado no Security & DevSecOps Gate abaixo (validação em worktree isolado antes de promover à branch principal), cumprindo o mesmo papel que um canary cumpriria numa feature de runtime. Documentado também no Architecture Decision Log.

## Nimbus-Code — Plano de Toggle e Rollout (obrigatório com `flag`)

*Preencher para toda feature que usar toggle. Obrigatório para S3/S4 quando
houver homologações concorrentes.*

**N/A** — esta feature usa estratégia `direct` (ver justificativa acima); não há flag/toggle a documentar.

## Nimbus-Code — Cost Reference

*Obrigatório para features com participação híbrida agente+humano. O objetivo é
deixar explícito como estimativa e consumo real serão rastreados ao longo do ciclo.*

| Campo | Valor |
|---|---|
| **Token estimate range** | ~35–55 mil tokens (script gerador + testes bats + workflow CI + atualização do developer-guide) |
| **Human effort estimate range** | ~2–4 horas (revisão de PR + validação manual da instalação do Antigravity em worktree isolado, incluindo checagem de versão do CLI `v1.20.5+`) |
| **Tracking method** | Tabela "Estimativa vs. Consumo Real" no `tasks.md` desta feature + campo "Horas Humanas" no GitHub Project |
| **Budget ceiling (optional)** | ~US$5–10 (baseado no volume de tokens estimado, sem custo de infraestrutura de runtime) |

## Nimbus-Code — SLO Gate

*Preencher para todo componente novo ou alterado de forma relevante. Os valores
aqui definidos são a referência para configuração de alertas (Observability Gate)
e critérios de Go/No-Go do `impact-map.md` (S3/S4).*

| Componente | Latência p99 | Taxa de erro máx. | Disponibilidade | RTO | RPO |
|---|---|---|---|---|---|
| `sync-nc-agents-to-integrations.sh` | — | — | — | — | — |
| `nc-agents-parity-check.yml` (CI gate) | — | — | — | — | — |

> Deixar `—` apenas quando o componente não expõe SLO mensurável (ex.: job batch
> interno). Omissão sem justificativa bloqueia o Observability Gate.

**SLOs não definidos nesta feature e justificativa:**
Nenhum componente desta feature é um serviço de runtime — o script gerador e o gate de CI rodam sob demanda (dev local ou pipeline de PR), sem SLA de disponibilidade/latência aplicável. Falha do script ou do gate é visível imediatamente no terminal do dev ou no check do PR, sem necessidade de alerta assíncrono.

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
| **Backup & Disaster Recovery** | Todo datastore com dado real (produção) tem backup automatizado, retenção definida e restore testado/documentado ao menos uma vez | **Não — bloqueante** | N/A | Não há datastore nesta feature — apenas arquivos versionados em git (já com histórico/restore nativo do próprio git) |
| Autenticação (SSO) | Sistemas novos (greenfield) devem usar SSO | Sim, com justificativa no ADL | N/A | Não há sistema novo com autenticação — feature é tooling de arquivos estáticos |
| Segredos no código/repositório | Nunca em texto plano; secret scanning bloqueia merge se detectar | **Não — bloqueante** | Aplicável | Nenhum segredo é introduzido; secret scanning já vigente no repositório continua ativo para o PR desta feature |
| Branch/merge protegido | PR obrigatório + revisão antes de merge em branch protegida; nenhum merge com CI vermelho ou check obrigatório pulado | **Não — bloqueante** | Aplicável | Segue a mesma branch/PR já em uso nesta sessão (`agents/users-lrodrigues-projects-nimbus-code-spec-kit-t`) |
| Isolamento de ambiente | Credencial de produção nunca usada em ambiente de dev/test | **Não — bloqueante** | N/A | Não há credencial de produção envolvida |
| Containers | Imagem base pinada, scan de vulnerabilidade, usuário não-root | Sim, com justificativa no ADL | N/A | Nenhum container é criado ou alterado por esta feature |
| CI/CD | Segredos via cofre/CI secrets, least privilege no service account do pipeline | Sim, com justificativa no ADL | Aplicável | O novo workflow `nc-agents-parity-check.yml` não usa nenhum segredo — apenas checkout + execução de bats, herda o least-privilege já configurado no repo |
| IaC — provider(s) usado(s) | 100% da infra desta feature via IaC | Sim, com justificativa no ADL | N/A | Não há infraestrutura de nuvem nesta feature |
| Banco de dados | TLS/mTLS obrigatório para dado sensível em trânsito | **Não — bloqueante** | N/A | Não há banco de dados nesta feature |
| **Firewall / Segmentação de rede** | Regras de firewall/least exposure, sem exposição pública desnecessária | Sim, com justificativa no ADL | N/A | Não há exposição de rede nesta feature |
| Observabilidade | Logs, métricas e alertas mínimos definidos para os componentes críticos | Sim, com justificativa no ADL | Aplicável (adaptado) | Substituído pelo gate de paridade (AC-5) — a "observabilidade" equivalente é o CI falhar com mensagem clara apontando o agente/destino desatualizado |
| **Instalação de integração não-`multi_install_safe` (Antigravity)** *(controle adicional específico desta feature, fora da tabela padrão)* | `specify integration install agy` exige CLI `v1.20.5+` e não é `multi_install_safe` — deve ser validado em worktree isolado antes de qualquer promoção à branch principal | Sim, com justificativa no ADL se pulado | Aplicável | Este é o único risco operacional real desta feature: instalar Antigravity direto na branch principal sem isolamento prévio poderia corromper artefatos de Claude/Copilot já instalados, caso a integração não seja realmente segura para múltiplas instalações simultâneas |

**Riscos identificados e decisão:**
O único risco relevante é a instalação do Antigravity (`multi_install_safe: false`, exige CLI `v1.20.5+`). Decisão: **mitigar antes do merge**, não aceitar como risco documentado — a instalação será executada primeiro em um worktree isolado (git worktree separado, fora da branch principal), validada manualmente (nenhum arquivo de `.claude/`/`.github/skills/` alterado, os 12 comandos presentes em `.agents/skills/`), e só então replicada na branch principal desta sessão. Se a validação isolada falhar, a Fase 2/3 desta feature relacionada a Antigravity é adiada (tratada como escopo parcial, sem bloquear a entrega de Claude Code) — decisão a ser tomada pelo Dev/tech lead conforme já previsto na tabela RACI do `spec.md`.

## Nimbus-Code — Qualidade de Código, Testes e Observabilidade Gate

*GATE adicional: deve ser preenchido e aprovado antes de `/nimbus-code-tasks`, junto
com o Constitution Check nativo e o Security & DevSecOps Gate acima. Traduz em
verificações concretas as regras de "Qualidade e Processo" da constituição da
Nimbus-Code (revisão por IA, testes integrados, observabilidade, arquitetura
distribuída e gestão de bugs).*

| Domínio | Controles aplicáveis | Status | Observações |
|---|---|---|---|
| Revisão de código por IA | GitHub Copilot code review solicitado em todo PR desta feature; findings High/Critical bloqueiam merge (mesma régua do SAST/IaC) | Aplicável | Sem exceção |
| Testes integrados | Cada critério de aceitação do `spec.md` tem teste de integração automatizado correspondente, sempre que tecnicamente viável | Aplicável | Ver tabela de Rastreabilidade AC→Teste→Módulo acima — todos os 6 ACs têm teste mapeado, nenhum N/A |
| Observabilidade | Logs estruturados, métricas e alertas mínimos instrumentados para os componentes entregues (obrigatório, não condicional) | N/A (adaptado) | Ver justificativa no SLO Gate acima — substituído pelo CI de paridade, que já cumpre o papel de "alerta" para esta feature |
| Arquitetura distribuída / Microsserviços | Correlation-id/trace-id (W3C Trace Context) propagado ponta a ponta entre serviços; orquestração/coreografia documentada no Architecture Decision Log abaixo | N/A | Monólito de tooling local, sem chamadas entre serviços |
| Gestão de bugs | Bugs encontrados fora do escopo desta tarefa/feature abertos como Issue no GitHub e atribuídos ao Copilot coding agent | Aplicável | Nenhum bug fora de escopo identificado até o momento do planejamento |

**Critérios de aceitação sem teste de integração automatizado (se houver) — justificativa:**
Nenhum — todos os 6 ACs (AC-1 a AC-6) têm teste de integração mapeado na tabela de Rastreabilidade acima.

## Nimbus-Code — Architecture Decision Log

*Preencher para decisões técnicas relevantes desta feature, e **obrigatoriamente**
para qualquer item marcado "Escapável via ADL" nos gates acima que não seguiu o
padrão institucional. Decisões triviais/óbvias não precisam de entrada aqui.*

| Decisão | Alternativas consideradas | Opção escolhida | Trade-off assumido | Justificativa do desvio (se aplicável) | Aprovado por |
|---|---|---|---|---|---|
| Como sincronizar os 9 agentes `/nc-*` para Claude/Antigravity | (a) reescrever manualmente cada `SKILL.md` por integração; (b) script gerador único que lê `.github/skills/nc-*` como fonte e emite cópias transformadas; (c) symlinks entre pastas | (b) script gerador único | Ganha: fonte única de verdade, sem duplicação manual, mesmo padrão que o `specify` CLI já usa internamente para os 12 comandos. Perde: exige rodar o gerador após qualquer edição em `.github/skills/nc-*` (mitigado pelo gate de paridade AC-5) | N/A — não é desvio de padrão institucional, apenas escolha técnica dentro do escopo já aprovado pelo usuário | — |
| Estratégia de release `direct` em vez de flag/canary | (a) `direct`; (b) feature flag controlando exposição dos comandos; (c) canary por % de devs | (a) `direct`, com justificativa registrada na Estratégia de Release acima | Ganha: simplicidade, sem overhead de toggle para tooling de dev local. Perde: nenhum rollback gradual — mitigado por ser trivialmente revertível via `git revert` | Justificativa explícita registrada na seção "Estratégia de Release" — é um desvio do padrão S3 (que obriga flag/canary/blue-green), mas tecnicamente fundamentado (não há tráfego/sessão de produção a proteger) | — |
| Instalar Antigravity apenas após validação em worktree isolado | (a) instalar direto na branch principal e reverter se falhar; (b) validar primeiro em worktree isolado, promover só depois | (b) worktree isolado primeiro | Ganha: nenhum risco de corromper artefatos de Claude/Copilot já commitados, mesmo que a instalação do Antigravity tenha efeito colateral inesperado. Perde: um passo extra de execução (worktree temporário) | N/A — não é desvio de padrão, é a mitigação escolhida para o único risco Escapável identificado no Security & DevSecOps Gate | — |