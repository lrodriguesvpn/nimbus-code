# Implementation Plan: Bootstrap Governance & Repo Provisioning Hardening

**Branch**: `008-bootstrap-governance-hardening` | **Date**: 2026-08-20 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/008-bootstrap-governance-hardening/spec.md`

## Estado verificável — 2026-09-20

O plano original permanece como histórico de design. A auditoria local verificou
paridade dos templates de issue (fontes e cópias ativas), a asserção de URLs de
`tests/bootstrap/no-public-github-urls.bats` e sintaxe Bash; não executou
bootstrap remoto, piloto autenticado nem aprovação de segurança. Esses testes
não comprovam atualização/reinstalação correta de versões de preset.

- **Divergência de classificação:** este plano registra S3 com revisão obrigatória
  de segurança, enquanto
  [#451](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code/issues/451)
  solicita revisão S4. A classificação precisa de ratificação humana; nenhuma
  delas foi alterada ou aprovada neste saneamento. A alegação "19/19 Bats" da
  issue não foi reproduzida nesta auditoria.
- **Pendências abertas consultadas:**
  [#433](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code/issues/433)
  (verificar App existente e piloto),
  [#103/T022](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code/issues/103)
  (piloto com/sem secrets),
  [#107/T026](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code/issues/107)
  (teste com desenvolvedor) e
  [#111/T030](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code/issues/111)
  (aprovação humana). T005/T006 continuam dependendo da confirmação do App e
  dos secrets; o fechamento de #72 não comprova essa configuração, pois seu
  último comentário relata fechamento incorreto e ausência de App/secrets
  naquela verificação.

## Summary

Endurecer o `bootstrap.sh` e os dois presets de governança (`nimbus-code-standards`,
`nimbus-code-platform-standards`) para que: (1) o operador seja explicitamente
questionado sobre o tipo de repositório antes de qualquer preset ser instalado;
(2) os templates de issue dos dois presets tenham paridade estrutural garantida por
validação automatizada; (3) toda automação cross-repo/organização migre de PAT
clássico para token de instalação de GitHub App, preservando `GITHUB_TOKEN` nativo
para automações de escopo restrito ao próprio repositório; (4) a instalação do Spec
Kit CLI sempre aponte para a fonte oficial pública, e todo conteúdo próprio da
Venha Pra Nuvem aponte exclusivamente para o GitHub Enterprise da organização; e
(5) exista um manual claro sobre skills locais vs. remotas (VPN-SKILLS).

Abordagem técnica: extensão do `bootstrap.sh` existente com prompts interativos
(mantendo suporte a flags não-interativas para CI), um script de validação de
paridade de templates de issue (`validate-issue-template-parity.sh`) rodando em CI
via GitHub Action, migração incremental dos workflows de automação existentes
(`ensure-github-project.yml`, `add-to-repo-project.yml`, `sync-priority-field.yml`,
`agent-auto-assign.yml`) para autenticação via `actions/create-github-app-token`, e
um novo documento `docs/skills-distribution-guide.md`.

## Technical Context

**Language/Version**: Bash (compatível com `bash` 3.2+ do macOS, per convenção já
usada em `bootstrap.sh`/`scripts/*.sh`), Markdown/YAML para templates e workflows

**Primary Dependencies**: `gh` CLI (GitHub), `specify` CLI (Spec Kit oficial),
`actions/create-github-app-token@v1` (GitHub Actions), `jq`, `python3` (já usado em
`normalize-github-issues.sh` para parsing de markdown)

**Storage**: N/A — feature é puramente scripts/templates/documentação, sem
persistência própria

**Testing**: Testes de integração via `bats`/shell script assertions para
`bootstrap.sh` (fluxo de perguntas) e para o validador de paridade de templates;
dry-run manual documentado em `quickstart.md`

**Target Platform**: CLI local (macOS/Linux) para `bootstrap.sh`; GitHub Actions
(runners `ubuntu-latest`) para os workflows de automação e validação de paridade

**Project Type**: CLI/automation tooling (extensão de scripts e presets existentes,
não uma aplicação nova)

**Performance Goals**: `bootstrap.sh` completo (perguntas + instalação de
preset/labels/board) em até 15s (ver SLO); emissão de token de instalação de
GitHub App em até 2s por chamada

**Constraints**: Compatibilidade retroativa obrigatória — repositórios já
bootstrapados não podem quebrar ao atualizar o bundle; nenhuma automação pode ficar
sem credencial funcional durante a migração de PAT para GitHub App (rollout
gradual, não corte abrupto)

**Scale/Scope**: Afeta todo repositório futuro que rodar `bootstrap.sh` a partir
deste template, e os workflows de automação já instalados nos repositórios
existentes da organização que dependem de PAT hoje

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Notas |
|---|---|---|
| Segurança — nenhum segredo em texto plano | ✓ Pass | Feature justamente elimina PAT de longa duração; tokens de instalação de GitHub App são de curta duração e nunca commitados |
| SSO obrigatório para sistema novo | N/A | Feature não introduz sistema novo com autenticação própria de usuário — GitHub App é identidade de automação, não login humano |
| Infraestrutura como Código | ✓ Pass | Nenhum recurso cloud provisionado; mudanças são scripts/workflows versionados |
| Grafos de Módulos (S3+) | ✓ Pass | `graph.yaml`/`graph.md`/`impact-map.md` serão gerados na Phase 1 |
| Escala de Complexidade S0–S4 | ✓ Pass | Classificada como **S3** no `spec.md`; modelo de reasoning já em uso neste planejamento |
| Reutilização (catálogo + ponteiro) | ✓ Pass | `docs/reuse-catalog.yaml` consultado — nenhuma entrada match para "bootstrap de repositório + GitHub App"; será adicionada entrada ao final (tag: `bootstrap-github-app-auth`) |
| Qualidade e Processo (revisão humana, PR obrigatório) | ✓ Pass | Mudanças em `bootstrap.sh`/workflows exigem PR + revisão humana antes de merge em `develop`/`main` |

## Project Structure

### Documentation (this feature)

```text
specs/008-bootstrap-governance-hardening/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
├── graph.yaml           # Phase 1 output (S3 — obrigatório)
├── graph.md             # Phase 1 output (S3 — obrigatório)
├── impact-map.md        # Phase 1 output (S3 — obrigatório)
└── tasks.md             # Phase 2 output (/speckit-tasks — not created by /speckit-plan)
```

### Source Code (repository root)

```text
bootstrap.sh                                    # Estendido: perguntas de tipo de repo (Plataforma/Cliente vs Dev Standards)
scripts/
├── validate-issue-template-parity.sh           # Novo: compara estrutura de seções entre os 2 presets
├── setup-github-project.sh                     # Sem mudança de comportamento nesta feature (ver specs/006-multirepo-support/)
└── normalize-github-issues.sh                  # Sem mudança nesta feature (já corrigido em sessão anterior)

.github/workflows/
├── ensure-github-project.yml                   # Migrado: PAT → actions/create-github-app-token
├── add-to-repo-project.yml                     # Migrado: PAT → actions/create-github-app-token
├── sync-priority-field.yml                     # Migrado: PAT → actions/create-github-app-token
├── agent-auto-assign.yml                       # Migrado: PAT → actions/create-github-app-token
└── validate-issue-template-parity.yml           # Novo: roda validate-issue-template-parity.sh em PR

presets/
├── nimbus-code-standards/.github/ISSUE_TEMPLATE/nimbus-code-task.md
└── nimbus-code-platform-standards/.github/ISSUE_TEMPLATE/nimbus-code-task.md  # Novo — hoje ausente (bug confirmado nesta sessão)

docs/
└── skills-distribution-guide.md                # Novo: manual de skills locais vs. remotas (FR-008)
```

**Structure Decision**: Extensão in-place dos scripts/workflows já existentes
(`bootstrap.sh`, `.github/workflows/*.yml`) em vez de reescrevê-los — preserva
compatibilidade retroativa e minimiza superfície de revisão. Único diretório
inteiramente novo de código é `scripts/validate-issue-template-parity.sh` +
seu workflow de CI correspondente.

## Complexity Tracking

*Nenhuma violação do Constitution Check identificada — tabela não aplicável.*

---

## Nimbus-Code — Classificação de Complexidade (S0–S4)

| Campo | Valor |
|---|---|
| **Nível** | **S3** — cruza `bootstrap.sh`, 2 presets de governança, 4 workflows de automação existentes e um novo validador de CI |
| **Justificativa** | Múltiplos módulos interdependentes (script de bootstrap, presets, workflows de automação, novo script de validação); mudança de mecanismo de autenticação com impacto em repositórios já provisionados |
| **Modelo de IA** | Reasoning (Claude Sonnet 4.6+ / GPT-5.4+) — decisões de segurança e compatibilidade retroativa |
| **Revisão humana obrigatória** | **Sim** — não pelo nível S3 em si (S3 não exige por padrão), mas porque a feature altera mecanismo de autenticação de automações já em produção; tratado como decisão de segurança que exige aprovação explícita antes do merge, registrado no ADL abaixo |
| **Padrão reutilizado encontrado?** | Não — `docs/reuse-catalog.yaml` consultado; padrão de GitHub App para automação org-wide já existe como precedente em `docs/adr/0008-github-app-para-varredura-de-seguranca-org-wide.md` (feature 007), mas não como entrada de catálogo reutilizável ainda. Será adicionada entrada ao final desta feature (tag: `bootstrap-github-app-auth`) |
| **Estimativa de tokens (input+output)** | ~35–50 mil tokens — pesquisa de `actions/create-github-app-token`, design do validador de paridade, migração de 4 workflows, e documentação do manual de skills |

## Nimbus-Code — Rastreabilidade AC → Teste → Módulo

| ID AC | Critério (resumo) | Tipo de teste planejado | Arquivo/módulo do teste | Justificativa de ausência (se N/A) |
|---|---|---|---|---|
| AC-1 | Bootstrap pergunta tipo de preset | shell + validação manual | `tests/bootstrap/bootstrap-entrypoints.bats` (caso `/dev/tty`) e Cenário 1 de `quickstart.md` | O teste existente inspeciona o fallback do prompt; não equivale ao fluxo completo com operador. O arquivo planejado `bootstrap-preset-selection.bats` não existe |
| AC-2 | Paridade de issue templates | integração (script) | `scripts/validate-issue-template-parity.sh` + `tests/bootstrap/issue-template-parity.bats` | Script de paridade executado na auditoria; suite Bats não reexecutada |
| AC-4 | GitHub App para automação cross-repo/org | integração (workflow) | `.github/workflows/ensure-github-project.yml` (dry-run em ambiente de teste) | — |
| AC-5 | `GITHUB_TOKEN` nativo para escopo próprio repo | integração (workflow) | Mesmo workflow acima — valida que não requer secret adicional | — |
| AC-6 | Spec Kit sempre de fonte oficial | inspeção/manual | `bootstrap.sh` e Cenário 4 de `quickstart.md` | Não foi localizado o teste dedicado planejado `bootstrap-official-source.bats`; permitir a URL oficial no teste de URLs não comprova a origem da instalação |
| AC-7 | Domínio GHE-only para conteúdo VPN | unitário (grep/lint) | `tests/bootstrap/no-public-github-urls.bats` | Asserção executada sem o runner Bats na auditoria de 2026-09-20; respeita a allowlist literal do teste |
| AC-8 | Manual de skills locais vs. remotas | manual (revisão humana) | `docs/skills-distribution-guide.md` | Documentação — validação é de clareza/completude, não automatizável |

## Nimbus-Code — Module Dependency Graph

**Status (atualização documental de 2026-09-20)**: `graph.yaml`, `graph.md` e
`impact-map.md` existem nesta SPEC. Presença verificada não significa aprovação
humana nem validação de rollout.

**Módulos previstos:**
- Bootstrap Layer: `bootstrap.sh`
- Preset Layer: `nimbus-code-standards`, `nimbus-code-platform-standards` (incluindo paridade de `ISSUE_TEMPLATE`)
- Automation Layer: `ensure-github-project.yml`, `add-to-repo-project.yml`, `sync-priority-field.yml`, `agent-auto-assign.yml`
- Validation Layer: `validate-issue-template-parity.sh` + workflow de CI correspondente
- External Dependency: GitHub App organizacional (a ser criado/instalado — ver `specs/003-vpn-skills-repo-governance/repo-bootstrap-guide.md` para um precedente análogo de decisão)
- External Dependency: Spec Kit CLI oficial (`github.com/github/spec-kit`)

## Nimbus-Code — Estratégia de Release

| Campo | Valor |
|---|---|
| **Estratégia** | `flag` — rollout gradual da migração de autenticação (PAT → GitHub App) por workflow, para não quebrar automações em produção durante a transição |
| **Feature flag name** | `bootstrap_github_app_auth_v1` |
| **Flag provider** | **OpenFeature** (obrigatório como camada de abstração) + provider pluggable por ambiente (bootstrap inicial pode usar fallback simples por variável de ambiente) |
| **Critério de ativação** | Validar em 1 repositório piloto (não-crítico) com todos os 4 workflows migrados, sem falha por 7 dias, antes de aplicar a todos os repositórios que usam o bundle |
| **Critério de rollback** | Qualquer workflow migrado falhando por ausência/erro de token de GitHub App reverte automaticamente para o secret PAT (mantido como fallback até o rollout ser considerado estável) |

**Justificativa para uso de flag**: a mudança de mecanismo de autenticação afeta
automações já em produção em múltiplos repositórios; um corte abrupto sem
possibilidade de rollback rápido é inaceitável dado o histórico de dependência de
PAT documentado no `spec.md`.

## Nimbus-Code — Plano de Toggle e Rollout

| Campo | Valor |
|---|---|
| **Flag key** | `bootstrap_github_app_auth_v1` |
| **Tipo de flag** | `release` |
| **Owner da flag** | Nimbus-Code Architecture Board |
| **Ambiente(s)** | dev · hml · prod (rollout começa em repositório piloto, não em ambiente per se) |
| **Default por ambiente** | Repositório piloto = on; demais repositórios = off até validação |
| **Segmentos de ativação** | `pilot-repo` primeiro, depois `all-bundle-consumers` |
| **Estratégia de rollout** | Piloto (1 repo, 7 dias sem falha) → aplicar a todos os repositórios do bundle → remover fallback PAT após confirmação |
| **Kill switch definido?** | Sim — reverter workflow para usar o secret PAT existente (mantido, não removido, até rollout completo) |
| **Critério de limpeza** | Remover fallback PAT e a flag 30 dias após 100% dos repositórios migrados, com Issue de tracking criada |

## Nimbus-Code — Cost Reference

| Campo | Valor |
|---|---|
| **Estimativa de tokens (agente)** | ~35–50 mil (ver Classificação de Complexidade acima) |
| **Estimativa de horas (humano)** | ~4–8 horas — criação/instalação do GitHub App organizacional (ação administrativa), revisão de segurança da migração de autenticação, aprovação de PR |
| **Metodologia de rastreio** | `docs/ai-code-quality-and-observability.md`, seção 6 |

## Phase 0: Research & Clarifications

**Status**: Nenhuma `[NEEDS CLARIFICATION]` pendente no `spec.md` — todas as decisões
foram resolvidas com o Dev durante a criação da spec (ex.: GitHub App org-level +
`GITHUB_TOKEN` nativo, decidido via `ask_user` antes da escrita do `spec.md`).

**Research tasks**:
- [ ] Validar a API `actions/create-github-app-token@v1` (parâmetros, permissões mínimas por workflow, limites de rate)
- [ ] Confirmar mecanismo de fallback seguro (flag) para reverter a um workflow para PAT sem exigir novo deploy
- [ ] Validar se o GitHub Enterprise da organização (`venha-pra-nuvem.ghe.com`) suporta GitHub Apps organizacionais na versão atual (mesma validação já necessária para `docs/adr/0008-github-app-para-varredura-de-seguranca-org-wide.md`, reaproveitar achado)

**Expected Output**: `research.md`

## Phase 1: Design & Contracts

*Gerar artefatos de design: `data-model.md`, `contracts/`, `quickstart.md`, `graph.yaml`, `graph.md`, `impact-map.md`.*

### Data Model (prévia — detalhado em `data-model.md`)

1. **RepoProvisioningProfile** — tipo de preset escolhido, papel no produto (se aplicável, delegado a `specs/006-multirepo-support/`)
2. **GitHubAppCredentialPolicy** — regra por automação: GitHub App (cross-repo/org) vs. `GITHUB_TOKEN` (mesmo repo)
3. **SourceOfTruthRegistry** — lista de URLs permitidas (Spec Kit oficial vs. GHE da organização)
4. **SkillDistributionManual** — por skill, local vs. remota, e estado atual

### Contracts (prévia — detalhado em `contracts/`)

- **bootstrap-prompt-contract.md**: contrato de I/O das perguntas interativas do `bootstrap.sh` (entrada esperada, validação, comportamento não-interativo via flags para CI)
- **issue-template-parity-contract.md**: contrato do validador (quais seções são obrigatórias, como divergência é reportada)
- **github-app-auth-contract.md**: contrato de autenticação (como cada workflow deve emitir e usar o token de instalação)

### Quickstart Validation Guide

`quickstart.md` documentará: (1) rodar `bootstrap.sh` num repo de teste e validar a
pergunta de tipo de preset; (2) rodar o validador de paridade de templates de issue
contra os dois presets; (3) simular a migração de um workflow para GitHub App em
ambiente de teste; (4) verificar ausência de URLs `github.com` públicas para
conteúdo VPN.

---

## Nimbus-Code — Security & DevSecOps Gate

| Domínio | Controles aplicáveis | Escapável via ADL? | Status | Observações |
|---|---|---|---|---|
| **Backup & Disaster Recovery** | N/A — feature não introduz datastore | **Não — bloqueante** | ✓ N/A | Scripts/templates versionados em git = backup |
| Autenticação (SSO) | N/A — GitHub App não é login humano | Sim, com justificativa no ADL | ✓ N/A | Ver ADL-1 abaixo |
| Segredos no código/repositório | Nenhuma chave privada de GitHub App commitada; sempre via GitHub Secrets | **Não — bloqueante** | ✓ Pass | |
| Branch/merge protegido | PR obrigatório + revisão humana antes de merge (reforçado por esta feature ser S3 com revisão humana obrigatória) | **Não — bloqueante** | ✓ Pass | |
| Isolamento de ambiente | N/A — não há ambientes de execução de produto | **Não — bloqueante** | ✓ N/A | |
| Containers | N/A — feature não usa containers | Sim, com justificativa no ADL | ✓ N/A | |
| CI/CD | Token de GitHub App emitido dinamicamente por execução, nunca persistido; least privilege (permissões somente as necessárias por workflow) | Sim, com justificativa no ADL | ✓ Pass | |
| IaC — provider(s) usado(s) | N/A — feature não provisiona infraestrutura cloud | Sim, com justificativa no ADL | ✓ N/A | |
| Banco de dados | N/A | **Não — bloqueante** | ✓ N/A | |
| **Firewall / Segmentação de rede** | N/A | Sim, com justificativa no ADL | ✓ N/A | |
| Observabilidade | Log de qual mecanismo de auth foi usado por execução do workflow (App vs. fallback PAT), para auditoria da migração | Sim, com justificativa no ADL | ⏳ Pendente | Implementar durante Phase 2 |

**Riscos identificados e decisão:**
- Risco: GitHub App organizacional ainda não existe/instalado quando esta feature for implementada → Decisão: `bootstrap.sh` falha explicitamente (FR-009) em vez de silenciosamente usar PAT como padrão; kill switch permite fallback controlado durante o rollout.

## Nimbus-Code — Qualidade de Código, Testes e Observabilidade Gate

| Domínio | Controles aplicáveis | Status | Observações |
|---|---|---|---|
| Revisão de código por IA | GitHub Copilot code review em todo PR desta feature | ⏳ Pendente (Phase 2) | |
| Testes integrados | Cada AC (AC-1, AC-2, AC-4 a AC-8) tem teste de integração planejado — ver tabela de rastreabilidade acima | ⏳ Pendente (Phase 2) | |
| Observabilidade | Log estruturado de mecanismo de auth por execução de workflow | ⏳ Pendente (Phase 2) | |
| Arquitetura distribuída / Microsserviços | N/A — feature é tooling local/CI, não serviço distribuído | N/A | |
| Gestão de bugs | Bugs fora do escopo abertos como Issue e atribuídos ao Copilot coding agent | ✓ Prática já adotada nesta sessão | |

**Critérios de aceitação sem teste de integração automatizado:**
- AC-3 (fonte oficial do Spec Kit): validação parcialmente manual, já que depende de uma URL externa mantida por terceiros (GitHub) — teste automatizado cobre apenas a forma da URL usada no `bootstrap.sh`, não a disponibilidade do serviço externo em si.

## Nimbus-Code — Architecture Decision Log

| Decisão | Alternativas consideradas | Opção escolhida | Trade-off assumido | Justificativa do desvio (se aplicável) | Aprovado por |
|---|---|---|---|---|---|
| ADL-1: Autenticação para automações cross-repo/org | (A) GitHub App org-level; (B) Fine-grained PAT de conta de serviço; (C) Manter PAT clássico | **(A) GitHub App org-level** para cross-repo/org + `GITHUB_TOKEN` nativo para escopo do próprio repo | Exige setup administrativo inicial (criar/instalar o App) — não é self-service via código | Decidido com o Dev via desafio explícito antes da escrita do `spec.md` (ver histórico da sessão); consistente com o precedente já estabelecido em `docs/adr/0008-github-app-para-varredura-de-seguranca-org-wide.md` (feature 007) | Dev (sessão 2026-08-20) |
| ADL-2: Estratégia de rollout — flag em vez de `direct` | (A) Corte direto de PAT para GitHub App; (B) Rollout gradual com flag e fallback | **(B) Rollout gradual com flag** | Mantém o secret PAT temporariamente como fallback, aumentando a superfície de código durante a transição | Corte abrupto arrisca quebrar automações já em produção sem plano de rollback rápido | — |
| ADL-3: Sem GitHub App dedicado — reaproveitar precedente da feature 007 como referência, não como o mesmo App | (A) Um único GitHub App para tudo (007 + este); (B) Apps separados por domínio de automação | **(B) Apps separados** (a decidir formalmente durante Phase 1/implementação) | Mais Apps para gerenciar, mas escopo de permissão mais granular por domínio (segurança vs. gestão de board) | — | — |

---

## Next Steps (Readiness for `/speckit-tasks`)

- [ ] Revisar os artefatos de Phase 1 existentes (`research.md`, `data-model.md`, `contracts/*.md`, `quickstart.md`, `graph.yaml`, `graph.md`, `impact-map.md`); a geração era o próximo passo histórico, mas os arquivos já estão presentes em 2026-09-20. Revisão não aprovada neste saneamento
- [ ] Validar todos os gates acima (Security, Quality, Constitution)
- [ ] **Obter aprovação humana explícita** antes de `/speckit-tasks` — esta feature altera mecanismo de autenticação de automações em produção (tratado como decisão de segurança, não apenas por ser S3)
