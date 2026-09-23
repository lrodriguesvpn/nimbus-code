# Implementation Plan: Documentação de Controle de Segurança no GHE para Projetos e Projeto Plataforma

**Branch**: `007-controle-seguranca-ghe-projetos-plataforma`

**Created**: 2026-08-19

**Status**: Phase 1 Design Complete ✓

**Spec**: [spec.md](./spec.md)

## Summary

Entregar (1) uma documentação única de controles obrigatórios de segurança no GHE para repositórios de projeto e para o Projeto Plataforma (Project V2 consolidado), com modelo de acesso por papéis, padrão de tokens/secrets e checklist de auditoria; e (2) uma automação de detecção (não corretiva) que varre semanalmente **todos os repositórios da organização** via um **GitHub App dedicado com permissões somente-leitura**, reporta desvios como issues rastreáveis (fluxo Nimbus Code existente) e consolida um relatório de conformidade mensal.

---

## Technical Context

*Background, dependencies, and high-level technical approach.*

### Architecture Overview

A feature tem duas camadas:

1. **Camada de Documentação** — guia único em `docs/security-baseline-ghe.md` (ou equivalente), cobrindo: baseline de repositório, governança do Projeto Plataforma, modelo de acesso por papéis, padrão de tokens/secrets, checklist de auditoria e procedimento de não conformidade. Referencia (não duplica) o fluxo Nimbus Code já existente de labels/board/gates.
2. **Camada de Automação de Detecção** — um workflow agendado (`security-compliance-scan.yml`) que:
   - Descobre todos os repositórios da organização via API do GHE (paginado).
   - Autentica-se como **GitHub App dedicado** (permissões somente-leitura: `metadata:read`, `administration:read`, `secrets:read` se disponível, `contents:read`).
   - Avalia cada repositório contra os controles do FR-001 (branch protection, revisão obrigatória, permissões de Actions, secrets configurados) e contra a matriz de acesso do Projeto Plataforma.
   - Roda **semanalmente** (cron); consolida os resultados de 4 execuções em um **relatório mensal**.
   - **Não corrige automaticamente** — para cada desvio, cria/atualiza uma Issue rastreável (idempotente por chave `repo+controle`, reaproveitando o padrão de deduplicação já catalogado em `docs/reuse-catalog.yaml` tag `speckit-deduplication-by-id`).

**Extensão da issue #450 (User Story 4)** — terceira camada, **Checks
obrigatórios de PR**, e ampliação da camada de detecção:

3. **Camada de Checks de PR** — workflows com nomes de job estáveis usados
   como required status checks em Rulesets: `pr-quality-gates.yml`
   (`governance-config`, `build`, `unit-tests`, `integration-tests`,
   `coverage`), `codeql.yml` (`codeql-analyze (<linguagem>)` + `CodeQL`),
   `dependency-review.yml` (`dependency-review`) e `secret-scan.yml`
   (`secret-scan`). Comandos por linguagem, branches protegidas e checks
   esperados são declarados em `.github/security-governance.json`
   (configuração versionada e parametrizável por repositório); exceções em
   `.github/security-exceptions.json`.
4. **Detecção ampliada** — a varredura semanal avalia 18 controles de
   repositório (Rulesets/proteção clássica em múltiplas branches, required
   checks, cobertura, CodeQL, Dependabot, Dependency Review, Secret Scanning,
   Push Protection, alertas), com classificação explícita de API indisponível
   (`pendente`) e 403 (erro), sem auto-remediação. O GitHub App continua
   somente leitura; issues são escritas com o `GITHUB_TOKEN` do workflow no
   repositório de relatório.

**Localização dos artefatos:**
- `docs/security-baseline-ghe.md` — documentação (guia + checklists)
- `.github/workflows/security-compliance-scan.yml` — workflow semanal de varredura
- `scripts/security-compliance-scan.sh` — lógica de varredura, chamado pelo workflow
- `docs/adr/0008-github-app-para-varredura-de-seguranca-org-wide.md` — ADR da decisão de credencial

### Dependencies

- GitHub Enterprise (GHE) — API REST/GraphQL para repositórios, branch protection, Projects V2
- GitHub App dedicado (a criar) — instalado na organização, permissões somente-leitura
- `gh` CLI — já padrão neste repositório (ver `scripts/setup-github-project.sh`, `scripts/setup-github-labels.sh`)
- GitHub Actions (`schedule` trigger) — já padrão neste repositório (ver `.github/workflows/ensure-github-project.yml`)
- Fluxo Nimbus Code de labels/board/gates já existente (`docs/label-taxonomy-and-autonomous-dev.md`)

### Technology Choices

- **Bash + `gh` CLI** para o script de varredura — consistente com o padrão já estabelecido em `scripts/*.sh` deste repositório (nenhuma linguagem nova introduzida).
- **YAML (GitHub Actions)** para o workflow agendado — mesmo padrão de `ensure-github-project.yml` e `graph-guard.yml`.
- **Markdown** para a documentação e para o corpo das issues de não conformidade.
- **GitHub App** (ao invés do padrão de PAT usado em `ensure-github-project.yml`) como credencial da varredura org-wide, por exigência de least privilege (ver ADR-0008).

**Justificativa**: Manter consistência com a stack já usada no repositório (bash/gh/YAML), evitando introduzir uma nova linguagem/runtime só para esta feature.

---

## Constitution Check

*Avaliar a feature contra princípios do projeto. Documentar desvios e obter aprovação se necessário.*

| Princípio | Status | Notas |
|---|---|---|
| Segurança — nenhum segredo em texto plano | ✓ Pass | Private key do GitHub App e tokens ficam em GitHub Secrets; documentação não contém segredos reais |
| SSO obrigatório para sistemas novos (greenfield) | N/A | Feature não expõe nova superfície de autenticação própria; usa autenticação nativa do GitHub (App/OAuth) |
| Infraestrutura como Código (Terraform padrão) | N/A | Feature não provisiona recursos AWS/GCP/Azure; é configuração/automação sobre o próprio GHE |
| Grafos de Módulos (graph.yaml/graph.md obrigatório) | ✓ Pass | `graph.yaml` e `graph.md` gerados nesta fase |
| Escala de Complexidade (S0–S4, revisão obrigatória em S4) | ✓ Pass | Classificada como **S4** — revisão humana obrigatória declarada abaixo |
| Reutilização (catálogo + referência por ponteiro) | ✓ Pass | `docs/reuse-catalog.yaml` consultado; reaproveita `speckit-deduplication-by-id` (issues idempotentes) e o padrão de workflow agendado de `ensure-github-project.yml` |
| Priorização (labels, desenvolvimento autônomo) | ✓ Pass | Issues de não conformidade seguem a taxonomia de labels já existente (prioridade, status) |
| Least privilege (IAM/roles) | ✓ Pass | GitHub App com permissões somente-leitura mínimas — ver ADR-0008 |

---

## Project Structure

### Documentation (this feature)

```text
specs/007-controle-seguranca-ghe-projetos-plataforma/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
├── graph.yaml           # Module Dependency Graph (structured)
├── graph.md             # Module Dependency Graph (Mermaid)
├── impact-map.md        # Impact Map (obrigatório — S4)
└── tasks.md             # Phase 2 output (/speckit-tasks — not created here)
```

### Source Code (repository root)

```text
docs/
└── security-baseline-ghe.md      # Documentação (baseline + governança + auditoria)

.github/workflows/
└── security-compliance-scan.yml  # Workflow agendado (semanal) de varredura

scripts/
└── security-compliance-scan.sh   # Lógica de varredura (gh CLI + GitHub App auth)

docs/adr/
└── 0008-github-app-para-varredura-de-seguranca-org-wide.md

docs/
└── security-operations-manual.md         # Runbook operacional (papéis, ciclo semanal/mensal, rollout, incidentes)

# issue #450 — governança de PR e segurança de código
.github/
├── security-governance.json               # Configuração versionada: branches, regras, required checks, quality gates, cobertura, CodeQL, SCA
├── security-exceptions.json               # Exception Records (owner, aprovador, prazo, expiração)
├── dependency-review-config.yml           # Severidade mínima, escopos, licenças, dependências proibidas
├── dependabot.yml                         # Dependabot version updates
└── workflows/
    ├── pr-quality-gates.yml               # governance-config, build, unit-tests, integration-tests, coverage
    ├── codeql.yml                         # SAST (CodeQL)
    ├── dependency-review.yml              # SCA em PR (atualizado)
    └── secret-scan.yml                    # Verificação complementar de secrets (gitleaks pinado)
.gitleaks.toml                             # Regras do secret-scan (estende o padrão)
scripts/
├── validate-security-governance.sh        # Check governance-config
├── run-quality-gate.sh                    # Executor extensível de build/testes/cobertura
├── validate-repo-static.sh                # Etapa build deste repositório (bash -n, shellcheck, JSON/YAML, actionlint)
└── coverage-gate.py                       # Gate de cobertura (global, diff, baseline, exceções)
```

**Structure Decision**: Reaproveita a convenção já estabelecida neste repositório (`scripts/*.sh` + `.github/workflows/*.yml` + `docs/*.md`) — nenhuma nova pasta de "aplicação" é necessária, pois a feature é documentação + automação de governança, não um serviço novo.

## Complexity Tracking

> Nenhuma violação do Constitution Check identificada — todos os itens são Pass ou N/A com justificativa. Tabela não aplicável.

---

## Nimbus-Code — Classificação de Complexidade (S0–S4)

*Preencher antes de qualquer gate. Determina modelo de IA, artefatos obrigatórios e
nível de revisão exigido.*

| Campo | Valor |
|---|---|
| **Nível** | S0 · S1 · S2 · S3 · **S4** |
| **Justificativa** | Automação com credencial de leitura sobre **todos os repositórios da organização** (GitHub App), avaliação de postura de segurança (branch protection, secrets, permissões) e governança de acesso ao Projeto Plataforma — enquadra-se em "Arquitetura, segurança, dados sensíveis ou integração crítica" |
| **Modelo de IA** | GPT-5.5 / Claude Opus (máximo) — reasoning máximo, conforme tabela de Modelo por Nível |
| **Revisão humana obrigatória** | **Sim** (S4) |
| **Padrão reutilizado encontrado?** | Parcial — `docs/reuse-catalog.yaml` consultado: reaproveita `speckit-deduplication-by-id` (issues idempotentes) e o padrão de workflow agendado de `ensure-github-project.yml`; nenhuma entrada cobre varredura de conformidade org-wide, portanto não é um match completo |
| **Estimativa de tokens (input+output)** | ~140–190 mil tokens — baseline S4 (~30–50× o custo de uma tarefa S0), com desconto parcial pelos padrões reutilizados acima |

> S0 = documentação · S1 = função isolada · S2 = módulo · S3 = múltiplos módulos ·
> S4 = arquitetura, segurança, dados ou integração crítica

> A estimativa de tokens é preenchida **antes** de `/nimbus-code-tasks` e comparada
> com o consumo real no fechamento do `tasks.md` (ver checklist "Estimativa vs.
> Consumo Real de Tokens"). Não é um compromisso exato — é uma faixa para
> permitir comparar depois.

## Nimbus-Code — Rastreabilidade AC → Teste → Módulo

*Preencher antes de `/nimbus-code-tasks`. Cada critério de aceitação do `spec.md`
deve ter ao menos um teste de integração planejado e o módulo que o implementa
identificado — assim o Dev entra no `/nimbus-code-implement` sem surpresas.*

| ID AC | Critério (resumo) | Tipo de teste planejado | Arquivo/módulo do teste | Justificativa de ausência (se N/A) |
|---|---|---|---|---|
| AC-1 (US1.1) | Documentação permite configurar branch protection, revisão, secrets e Actions num repo novo | integração | `tests/docs/security-baseline-checklist.test.sh` (valida presença de cada controle na doc) | — |
| AC-2 (US1.2) | Checklist identifica controles ausentes num repo existente | integração | `tests/scripts/security-compliance-scan.detect.test.sh` | — |
| AC-3 (US2.1) | Apenas papéis autorizados administram views/campos críticos do Projeto Plataforma | integração | `tests/scripts/security-compliance-scan.platform-access.test.sh` | — |
| AC-4 (US2.2) | Workflows usam PAT/GitHub App com escopo mínimo e rotação definida | integração | `tests/docs/security-baseline-tokens.test.sh` | — |
| AC-5 (US3.1) | Auditoria mensal produz relatório com status por controle (ok/pendente/risco) | integração | `tests/workflows/security-compliance-scan.report.test.sh` | — |
| AC-6 (US3.2) | Desvio vira issue rastreável com prioridade e responsável | integração | `tests/scripts/security-compliance-scan.issue-creation.test.sh` | — |
| AC-7 (FR-005a/b) | Scan roda semanalmente e descobre todos os repos via API (sem lista manual) | integração | `tests/workflows/security-compliance-scan.discovery.test.sh` | — |
| AC-8 (FR-004a) | Scan autentica via GitHub App somente-leitura (não PAT de usuário) | integração | `tests/scripts/security-compliance-scan.auth.test.sh` | — |
| AC-9 (US4, FR-009–FR-014, FR-018) | Documentação cobre Rulesets, matrizes de branches e checks, cobertura, SAST, SCA, secrets, exceções, SLA, evidências, pré-requisitos, permissões do App e piloto | integração | `tests/docs/security-governance-policies.test.sh` | — |
| AC-10 (US4.1/4.3, FR-009, FR-015, FR-016) | Varredura avalia branch padrão + padrões, Rulesets, required checks, cobertura, CodeQL, Dependabot, Dependency Review, Secret Scanning/Push Protection e alertas; API indisponível/403 nunca é `ok` | integração | `tests/scripts/security-compliance-scan.governance-controls.test.sh`, `tests/scripts/security-compliance-scan.detect.test.sh` | — |
| AC-11 (US4, FR-015, FR-017) | Issues idempotentes, migração de id legado, fechamento em `ok`, dry-run sem escrita, App nunca escreve | integração | `tests/scripts/security-compliance-scan.issue-lifecycle.test.sh` | — |
| AC-12 (US4.2, FR-011) | Cobertura < 80%, redução ou relatório ausente bloqueiam | integração | `tests/scripts/coverage-gate.test.sh` | — |
| AC-13 (US4.2/4.4, FR-010, FR-018) | Config inválida, check N/A obrigatório, exceção vencida e Action sem pin bloqueiam; teste falhando bloqueia | integração | `tests/scripts/validate-security-governance.test.sh`, `tests/scripts/run-quality-gate.test.sh` | — |
| AC-14 (US4.2, FR-010, FR-012, FR-013) | Workflows com triggers, nomes estáveis, SHA fixado, permissões mínimas; rollout piloto preservado | integração | `tests/workflows/security-governance-workflows.test.sh`, `tests/workflows/security-compliance-scan.discovery.test.sh` | Execução real dos workflows depende do GHE/GHAS (T066) |

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
| **Estratégia** | `flag` — rollout progressivo do escopo de repositórios varridos |
| **Feature flag name** | `security-baseline-scan.org-wide.enabled` |
| **Flag provider** | **OpenFeature** (abstração obrigatória) + provider inicial simples baseado em arquivo/variável de ambiente lido pelo workflow, pluggable por ambiente |
| **Critério de ativação** | Piloto com repositórios do bounded context `spec-kit-workflow` por 2 execuções semanais sem falso-positivo/erro de API antes de expandir para 100% da organização |
| **Critério de rollback** | Taxa de erro de scan > 5% dos repositórios (falha de API/permissão) ou mais de 3 issues de falso-positivo reportadas pelos times na primeira semana |

> **Regra**: features S3/S4 **obrigam** estratégia `flag`, `canary` ou `blue-green`
> — `direct` não é permitido sem justificativa explícita registrada aqui e no ADL.
>
> **Regra adicional**: quando houver toggle, o plano **deve** declarar OpenFeature como padrão.
> O provider específico (LaunchDarkly, AppConfig etc.) fica atrás da API OpenFeature.

**Justificativa para deploy `direct` (se aplicável):**
N/A — estratégia `flag` adotada; não há deploy `direct`.

## Nimbus-Code — Plano de Toggle e Rollout (obrigatório com `flag`)

*Preencher para toda feature que usar toggle. Obrigatório para S3/S4 quando
houver homologações concorrentes.*

| Campo | Valor |
|---|---|
| **Flag key** | `security.baseline_scan.org_wide_enabled` |
| **Tipo de flag** | `release` |
| **Owner da flag** | Nimbus-Code Architecture Board / responsável de plataforma |
| **Ambiente(s)** | prod (workflow roda apenas em produção — não há ambiente dev/hml separado para o GHE da organização) |
| **Default por ambiente** | prod=off até validação do piloto; prod=on (100% dos repos) após critério de ativação satisfeito |
| **Segmentos de ativação** | `pilot-spec-kit-workflow` (bounded context piloto) → `org-wide` (todos os repositórios) |
| **Estratégia de rollout** | piloto (1 bounded context, 2 execuções semanais) → validação manual do Tech Lead → org-wide (100%) |
| **Kill switch definido?** | Sim — desativar a flag interrompe a criação de novas issues de não conformidade (scan continua rodando em modo dry-run/log apenas) |
| **Critério de limpeza** | Remover a flag (deixar sempre org-wide) 30 dias após rollout 100% estável, sem regressão |
| **Issue/tarefa de remoção criada?** | Não — a criar em `/speckit-tasks` como task de fechamento |

**Conflitos funcionais entre homologações (quando aplicável):**
- Decisor de negócio/arquitetura: N/A — não há frentes concorrentes conhecidas tocando os mesmos arquivos nesta feature
- Regra de precedência entre frentes: N/A
- Evidência registrada no ADL: N/A

## Nimbus-Code — Cost Reference (SPEC KIT COST)

*Obrigatório para features com participação híbrida agente+humano. O objetivo é
deixar explícito como estimativa e consumo real serão rastreados ao longo do ciclo.*

| Campo | Valor |
|---|---|
| **SPEC KIT COST URL** | https://github.com/venha-pra-nuvem/spec-kit-cost |
| **Token estimate range** | ~140–190 mil tokens (coerente com Classificação de Complexidade S4) |
| **Human effort estimate range** | ~8–14 horas (revisão humana obrigatória em S4: criação do GitHub App, aprovação do plano/ADR, revisão de PR do workflow e da documentação) |
| **Tracking method** | Tabela "Estimativa vs. Consumo Real" no `tasks.md` + campo "Horas Humanas" no GitHub Project |
| **Budget ceiling (optional)** | ~US$120 (tokens) + revisão humana dedicada de segurança |

## Nimbus-Code — SLO Gate

*Preencher para todo componente novo ou alterado de forma relevante. Os valores
aqui definidos são a referência para configuração de alertas (Observability Gate)
e critérios de Go/No-Go do `impact-map.md` (S3/S4).*

| Componente | Latência p99 | Taxa de erro máx. | Disponibilidade | RTO | RPO |
|---|---|---|---|---|---|
| `security-compliance-scan` (workflow semanal) | Conclusão em até 30 min por execução | 5% dos repositórios com erro de leitura (retry automático) | 95% das execuções semanais concluídas com sucesso | 1 semana (próxima execução agendada) | N/A — não persiste estado próprio; relatório é reconstituído a cada execução |

> Deixar `—` apenas quando o componente não expõe SLO mensurável (ex.: job batch
> interno). Omissão sem justificativa bloqueia o Observability Gate.

**SLOs não definidos nesta feature e justificativa:**
Nenhum — o único componente novo (`security-compliance-scan`) tem SLO definido na tabela acima. A documentação (`docs/security-baseline-ghe.md`) não expõe SLO por ser conteúdo estático.

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
| **Backup & Disaster Recovery** | Todo datastore com dado real (produção) tem backup automatizado, retenção definida e restore testado/documentado ao menos uma vez | **Não — bloqueante** | N/A | Feature não cria datastore próprio; evidências de conformidade são Issues no GHE (já possui backup/retenção nativos da plataforma) |
| Autenticação (SSO) | Sistemas novos (greenfield) devem usar SSO | Sim, com justificativa no ADL | N/A | Feature não expõe superfície de autenticação própria; usa autenticação nativa do GitHub (GitHub App/OAuth) |
| Segredos no código/repositório | Nunca em texto plano; secret scanning bloqueia merge se detectar | **Não — bloqueante** | Implementado em código (issue #450: `secret-scan` + controles de Secret Scanning/Push Protection); habilitação real pendente (T064/T065) | Private key do GitHub App e qualquer token auxiliar DEVEM ser armazenados como GitHub Secret (`SECURITY_SCAN_APP_ID`, `SECURITY_SCAN_APP_PRIVATE_KEY`) — nunca commitados; validar em `/speckit-tasks`/`/speckit-implement` |
| Branch/merge protegido | PR obrigatório + revisão antes de merge em branch protegida; nenhum merge com CI vermelho ou check obrigatório pulado | **Não — bloqueante** | ✓ Pass | Convenção já vigente neste repositório (branch `main` protegida) |
| Isolamento de ambiente | Credencial de produção nunca usada em ambiente de dev/test | **Não — bloqueante** | Pendente (implementação) | GitHub App de produção não deve ser usado em testes locais/CI de PR — testes de `security-compliance-scan.sh` devem usar mocks/fixtures da API, não chamadas reais ao GHE de produção |
| Containers | Imagem base pinada, scan de vulnerabilidade, usuário não-root | Sim, com justificativa no ADL | N/A | Feature não usa containers — workflow roda em runner padrão do GitHub Actions com `gh` CLI |
| CI/CD | Segredos via cofre/CI secrets, least privilege no service account do pipeline | Sim, com justificativa no ADL | ✓ Pass | GitHub App com permissões somente-leitura mínimas (ver ADR-0008); segredos via GitHub Secrets do repositório |
| IaC — provider(s) usado(s) | 100% da infra desta feature via IaC; Terraform como framework padrão | Sim, com justificativa no ADL | N/A | Feature não provisiona recursos AWS/GCP/Azure — é configuração declarativa do próprio GHE (workflow YAML + script), não há infraestrutura de nuvem a gerenciar via Terraform |
| Banco de dados | TLS/mTLS obrigatório para dado sensível em trânsito | **Não — bloqueante** | ✓ Pass | Toda comunicação é HTTPS/TLS nativo da API do GitHub — nenhum banco de dados próprio |
| **Firewall / Segmentação de rede** | Regras de firewall/least exposure, sem exposição pública desnecessária | Sim, com justificativa no ADL | N/A | Feature roda inteiramente dentro do GitHub Actions/GitHub API — sem rede própria a segmentar |
| Observabilidade | Logs, métricas e alertas mínimos definidos para os componentes críticos | Sim, com justificativa no ADL | Pendente (implementação) | Logs do workflow (nativos do GitHub Actions) + alerta de falha via notificação padrão do Actions; métrica de "% repositórios com erro de leitura" registrada no relatório mensal — detalhar em `/speckit-tasks` |

**Riscos identificados e decisão:**
- **Risco**: GitHub App com acesso de leitura a todos os repositórios da organização é um alvo de alto valor se a private key vazar. **Decisão**: mitigar agora — rotação trimestral obrigatória da chave (documentada no guia de segurança) + alerta de uso anômalo via log de auditoria do GHE (Enterprise audit log). Registrado no ADR-0008.
- **Risco**: Rate limit da API do GitHub pode não ser suficiente para varrer todos os repositórios da organização em uma única execução semanal, dependendo do volume. **Decisão**: mitigar agora — script deve paginar e respeitar rate limit (backoff exponencial), documentado como constraint em `research.md`.
- **Risco**: Observabilidade dedicada (dashboard/alerta específico) ainda não implementada nesta fase. **Decisão**: aceitar risco documentado nesta fase (usar logs nativos do Actions + relatório mensal como evidência mínima); revisar necessidade de alerta dedicado após primeiro mês de operação piloto.

## Nimbus-Code — Qualidade de Código, Testes e Observabilidade Gate

*GATE adicional: deve ser preenchido e aprovado antes de `/nimbus-code-tasks`, junto
com o Constitution Check nativo e o Security & DevSecOps Gate acima. Traduz em
verificações concretas as regras de "Qualidade e Processo" da constituição da
Nimbus-Code (revisão por IA, testes integrados, observabilidade, arquitetura
distribuída e gestão de bugs).*

| Domínio | Controles aplicáveis | Status | Observações |
|---|---|---|---|
| Revisão de código por IA | GitHub Copilot code review solicitado em todo PR desta feature; findings High/Critical bloqueiam merge (mesma régua do SAST/IaC) | Planejado | Aplicar ao PR do workflow/script de varredura e ao PR da documentação |
| Testes integrados | Cada critério de aceitação do `spec.md` tem teste de integração automatizado correspondente, sempre que tecnicamente viável | Planejado | Ver tabela de Rastreabilidade AC → Teste → Módulo acima (8 ACs, todos com teste planejado) |
| Observabilidade | Logs estruturados, métricas e alertas mínimos instrumentados para os componentes entregues (obrigatório, não condicional) | Planejado | Logs do workflow + contagem de repositórios com/sem conformidade no relatório mensal |
| Arquitetura distribuída / Microsserviços | Correlation-id/trace-id (W3C Trace Context) propagado ponta a ponta entre serviços; orquestração/coreografia documentada no Architecture Decision Log abaixo | N/A | Feature é um workflow batch single-run, sem chamadas síncronas entre serviços internos que exijam correlation-id |
| Gestão de bugs | Bugs encontrados fora do escopo desta tarefa/feature abertos como Issue no GitHub e atribuídos ao Copilot coding agent | Planejado | Seguir o mesmo fluxo já padronizado no repositório |

**Critérios de aceitação sem teste de integração automatizado (se houver) — justificativa:**
Nenhum — todos os 8 ACs identificados têm teste de integração planejado (ver tabela de Rastreabilidade acima).

## Nimbus-Code — Architecture Decision Log

*Preencher para decisões técnicas relevantes desta feature, e **obrigatoriamente**
para qualquer item marcado "Escapável via ADL" nos gates acima que não seguiu o
padrão institucional. Decisões triviais/óbvias não precisam de entrada aqui.*

| Decisão | Alternativas consideradas | Opção escolhida | Trade-off assumido | Justificativa do desvio (se aplicável) | Aprovado por |
|---|---|---|---|---|---|
| Credencial para varredura org-wide | GitHub App dedicado vs. PAT de conta de serviço vs. `GITHUB_TOKEN` padrão por repositório | GitHub App dedicado, permissões somente-leitura mínimas (ver ADR-0008) | Requer criação e gestão de um GitHub App (mais setup inicial) vs. simplicidade de um PAT; ganha least privilege e rotação/auditoria nativas | N/A — segue o princípio de least privilege da constituição; diverge do padrão de PAT já usado em `ensure-github-project.yml`, decisão documentada e registrada no ADR-0008 | A confirmar (owner de plataforma) |
| Comportamento em não conformidade | Auto-remediação vs. detectar-e-reportar vs. híbrido | Detectar e reportar (issue rastreável, correção manual) | Menor risco de mudança não revisada em produção vs. resolução mais lenta de desvios | N/A — decisão de clarificação do usuário, alinhada ao least privilege | Usuário (sessão de clarificação, 2026-08-19) |
| Frequência de varredura | Mensal apenas vs. semanal vs. sob demanda vs. por evento | Semanal (scan) + relatório mensal (consolidado) | Mais execuções que o mínimo de SC-003 original, mas garante detecção mais rápida de desvio entre auditorias mensais | N/A — decisão de clarificação do usuário | Usuário (sessão de clarificação, 2026-08-19) |
| Escopo de repositórios cobertos | Lista explícita configurável vs. detecção por marcador Nimbus Code vs. todos os repositórios da organização | Todos os repositórios da organização (descoberta via API) | Maior superfície de varredura e necessidade de paginação/rate-limit vs. simplicidade de manutenção de lista manual | N/A — decisão de clarificação do usuário | Usuário (sessão de clarificação, 2026-08-19) |
| Proteção de branches (issue #450) | Proteção clássica vs. Repository/Organization Rulesets | Rulesets preferencialmente; clássica aceita e reportada como compatibilidade (`rulesets-configured` = `pendente`) | Varredura precisa consultar duas fontes (rules/branches + protection) | N/A — alinhado à recomendação atual do GitHub | A confirmar (revisão S4) |
| Destino das issues de não conformidade (issue #450) | Issue em cada repositório (App com `Issues: write`) vs. issues centralizadas no repositório de relatório com `GITHUB_TOKEN` | Centralizadas no repositório de relatório (`SECURITY_SCAN_ISSUE_TARGET=report-repository`), App 100% read-only | Times acompanham desvios no repositório de relatório (repo avaliado no título/campo) em vez de no próprio repo | Requisito explícito da issue #450: não conceder escrita ao App de auditoria; corrige lacuna anterior (App criava issues sem `Issues: write` documentado) | A confirmar (revisão S4) |
| Verificação de secrets em PR (issue #450) | Só GitHub Secret Scanning/Push Protection vs. + verificação complementar em CI | Nativos (obrigatórios, auditados) + `secret-scan.yml` com gitleaks CLI pinado (licença MIT, sem secrets) | Mais um binário externo (versão + checksum fixados) | N/A | A confirmar (revisão S4) |
| Cobertura neste repositório (issue #450) | Inventar métrica vs. instrumentar bash (kcov) vs. `not-applicable` justificado | `not-applicable` justificado, testes (`unit-tests`) como gate; `coverage-gate.py` pronto para repositórios com LCOV/Cobertura | Sem métrica de cobertura para o próprio template | Não há ferramenta de cobertura aplicável e pinada no runner para bash; requisito proíbe métrica inventada | A confirmar (revisão S4) |
| Dependency Review indisponível (issue #450) | Pular silenciosamente (comportamento anterior) vs. falhar | Falhar por padrão; `advisory` só com Exception Record | PRs podem bloquear até Dependency graph/GHAS ser habilitado | Requisito: ausência de controle não pode ser mascarada como sucesso | A confirmar (revisão S4) |
| Linguagem/stack da automação | Node.js/TypeScript (Octokit) vs. Bash + `gh` CLI vs. Python | Bash + `gh` CLI | Menos type-safety/testabilidade que Node.js vs. reuso total do padrão já estabelecido no repositório (`scripts/*.sh`) e zero dependência nova | N/A — não é desvio de padrão, é reforço do padrão já existente | — |

> **ADR relacionado**: [0008 — GitHub App para varredura de segurança org-wide](/docs/adr/0008-github-app-para-varredura-de-seguranca-org-wide.md)

---

## Phase 0: Research & Clarifications

*Resolve NEEDS CLARIFICATION markers from spec.md.*

**Status**: Todos os pontos de ambiguidade foram resolvidos na sessão `/speckit-clarify` de 2026-08-19 (ver `## Clarifications` em [spec.md](./spec.md)). Nenhum `NEEDS CLARIFICATION` remanescente no Technical Context — ver `research.md` para o detalhamento de cada decisão técnica de suporte (paginação/rate limit da API, formato de credencial do GitHub App, formato do relatório mensal).

## Phase 1: Design & Contracts

*Gerar artefatos de design: data-model.md, contracts/, quickstart.md, graph.yaml, graph.md, impact-map.md.*

Ver arquivos gerados nesta mesma pasta:
- [`data-model.md`](./data-model.md) — entidades (Controle de Segurança, Projeto de Repositório, Projeto Plataforma, Perfil de Acesso, Evidência de Auditoria, Scan Run, Compliance Finding, Compliance Report)
- [`contracts/`](./contracts) — contratos de documentação, do workflow de varredura, do schema de finding/issue e do relatório mensal
- [`quickstart.md`](./quickstart.md) — guia de validação E2E
- [`graph.yaml`](./graph.yaml) / [`graph.md`](./graph.md) — grafo de módulos
- [`impact-map.md`](./impact-map.md) — obrigatório para S4

---

## Next Steps (Readiness for `/speckit-tasks`)

- [x] `graph.yaml`, `graph.md`, `impact-map.md` gerados
- [x] `research.md` gerado
- [x] `data-model.md` gerado
- [x] `contracts/*` gerados
- [x] `quickstart.md` gerado
- [x] Gates preenchidos (Security, Quality, Constitution)
- [ ] **Aprovação humana obrigatória (S4)** do plano completo + ADR-0008 antes de `/speckit-tasks` — bloqueante, não pular
- [ ] Criar o GitHub App na organização (fora do escopo de código; ação administrativa manual documentada em `quickstart.md`)

---

## Completion Checklist

- [x] Plan.md preenchido com Summary, Technical Context, Constitution Check, Project Structure
- [x] Classificação de Complexidade (S4) com justificativa e estimativa de tokens
- [x] Phase 0 Research consolidado (`research.md`)
- [x] Phase 1 Design artifacts gerados (`data-model.md`, `contracts/*`, `quickstart.md`, `graph.yaml`, `graph.md`, `impact-map.md`)
- [x] Security & DevSecOps Gate e Quality Gate preenchidos
- [x] ADL completo com 5 decisões arquiteturais + ADR-0008
- [ ] Revisão humana obrigatória (S4) — **pendente**, bloqueia `/speckit-tasks`
