# Implementation Plan: Harness Corporativo — Consolidação de Harness Agêntico IDE Pessoal

**Branch**: `029-harness-corporativo-ide` | **Date**: 2026-09-22 | **Spec**: [specs/029-harness-corporativo-ide/spec.md](file:///Users/lrodrigues/.gemini/antigravity/worktrees/nimbus-code-spec-kit-template/nimbus_integration/specs/029-harness-corporativo-ide/spec.md)

**Input**: Feature specification from `specs/029-harness-corporativo-ide/spec.md` e interview em `specs/029-harness-corporativo-ide/interview.md`

---

## Summary

Esta feature implementa a **Opção A** aprovada com GO condicional na fase de assessment (`harness-consolidacao-corporativa`), estendendo o mecanismo de `scripts/harvest-patterns.sh` para capturar os arquivos de configuração pessoal de agentes IDE (`~/.claude/CLAUDE.md` e `.cursor/rules`) dos colaboradores em um repositório centralizado dedicado do GitHub Enterprise (`venha-pra-nuvem/nimbus-code-harness-corporativo`).

A abordagem técnica é construída sobre quatro pilares inegociáveis:
1. **Captura Estritamente On-Demand**: Disparada manualmente pelo desenvolvedor via CLI, sem agentes de background ou varreduras invasivas.
2. **Sanitização Local Preventiva e Fail-Closed**: Módulo Python local (`scripts/lib/harness_anonymizer.py`) que detecta e redige credenciais, tokens de API, e-mails, IPs e dados de alta entropia de Shannon antes de qualquer chamada HTTP ou persistência externa.
3. **Isolamento de Escrita no Repositório Central**: Os arquivos brutos (`raw/`) e regras promovidas (`promoted/`) são gravados exclusivamente no repositório central dedicado, com bloqueio arquitetural que impede terminantemente poluir o `docs/reuse-catalog.yaml` do projeto local (mitigando `HRN-0005`).
4. **Governança Humana do Comitê e Expurgo LGPD em 90 dias**: Promoção exclusiva por quórum formal de 4 papéis no Comitê Nimbus Code (Architecture, Security, Platform, Product) e expurgo físico automatizado semanal para itens brutos não promovidos após 90 dias.

---

## Technical Context

**Language/Version**: Bash 5.0+ (extensão da CLI) e Python 3.11+ (motor de anonimização, triagem do comitê, expurgo e scripts utilitários).

**Primary Dependencies**:
- Python Standard Library (`re`, `math`, `json`, `hashlib`, `urllib`, `argparse`, `dataclasses`, `pathlib`, `typing`) — sem dependências pesadas externas na máquina do desenvolvedor.
- Utilitários de sistema: `curl` e `jq` (já integrados no pipeline do Nimbus Code).
- Testes: `pytest` (para suítes unitárias/integração do sanitizador) e `bats-core` (para testes de integração da CLI e cenários Fail-Closed).

**Storage**:
- Repositório central dedicado no GitHub Enterprise: `venha-pra-nuvem/nimbus-code-harness-corporativo`.
- Estrutura de partições: `raw/` (submissões brutas com prazo de validade), `promoted/` (catálogo corporativo homologado), `archive/` (registros imutáveis de auditoria de expurgo em JSONL) e `manifests/index.yaml` (índice estruturado).

**Testing**:
- Testes unitários do sanitizador com cobertura de 100% dos padrões de tokens e cálculo de entropia.
- Testes de integração BATS da CLI (`harvest-patterns.sh --source ide-harness`).
- Testes de segurança assegurando bloqueio Fail-Closed preventivo.
- Testes de expurgo e sincronização idempotente de bounded context.

**Target Platform**: macOS e Linux (estações de trabalho dos desenvolvedores e runners do GitHub Actions).

**Project Type**: CLI / Ferramentas de Engenharia de Plataforma e Governança de IA.

**Performance Goals**:
- Sanitização local executada em < 200ms para arquivos de até 500KB.
- Overhead total da CLI local < 5s (excluindo tempo de resposta do LLM no Gateway).
- Job semanal de expurgo executado em < 60s no repositório central.

**Constraints**:
- **Zero Plaintext Secrets**: Bloqueio incondicional de credenciais no código e no transporte.
- **Fail-Closed**: Abortar com exit code 1 se houver qualquer dúvida ou credencial não-redigida antes de emitir tráfego HTTP.
- **Retenção Máxima de 90 Dias**: Expurgo físico de dados brutos não promovidos perante a LGPD.
- **Isolamento Estrito**: Impossibilidade de escrita em `docs/reuse-catalog.yaml` do repositório local.

**Scale/Scope**:
- ~50 colaboradores no esquadrão piloto; dezenas a centenas de regras de agentes processadas.

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Controle Inegociável | Requisito da Constituição | Status | Evidência / Mitigação Arquitetural |
|---|---|---|---|
| **1. Zero Plaintext Secrets** | Nenhuma credencial ou segredo em texto plano em trânsito ou repouso | **PASSED** | Sanitização local preventiva (`harness_anonymizer.py`) substitui segredos por tokens canônicos (`[REDACTED_API_KEY]`, etc.). Credenciais de API transmitidas somente via Bearer token do Gateway e variáveis de ambiente protegidas. |
| **2. Fail-Closed Security** | Se houver erro de validação ou suspeita de segredo residual, abortar imediatamente | **PASSED** | O analisador encerra com exit code 1 antes de despachar dados para `HARVEST_API_URL` caso detecte padrão não redigível ou entropia elevada sem contexto seguro (AC-3, FR-005). |
| **3. Traceability & RACI** | Toda decisão e artefato deve ter dono, histórico e integridade rastreável | **PASSED** | Registros de submissão bruta geram ID estável (`RAW-YYYYMMDD-hash`), hash SHA-256 e metadata de autor. Promoções registram assinaturas e quórum do Comitê Nimbus Code. |
| **4. Backward Compatibility** | Preservar contratos existentes sem quebrar funcionalidades atuais | **PASSED** | O comportamento padrão de `scripts/harvest-patterns.sh` (`--source code`) permanece 100% inalterado. O contrato do Nimbus Harvest Gateway (SPEC-022) é reutilizado integralmente. |
| **5. Human in the Loop for S4** | Features S4 exigem validação e aprovação humana explícita antes de promoção | **PASSED** | Nenhuma regra do harness de desenvolvedores é promovida automaticamente a padrão corporativo. Promoção requer aprovação deliberada do Comitê Nimbus Code via `CODEOWNERS`. |
| **6. Disaster Recovery / Retention** | Política de retenção definida e proteção contra acúmulo indevido de dados | **PASSED** | Política estrita de retenção de 90 dias com automação semanal de expurgo físico (`purge-expired.py`) e log imutável de auditoria (`purge-audit.jsonl`). |

---

## Project Structure

### Documentation (this feature)

```text
specs/029-harness-corporativo-ide/
├── plan.md              # Este arquivo (especificação técnica e gates de arquitetura)
├── research.md          # Fase 0: Decisões técnicas e resolução de clarificações
├── data-model.md        # Fase 1: Schemas de entidades, payloads e ciclo de vida
├── quickstart.md        # Fase 1: Guia executável de validação de cenários
├── contracts/           # Fase 1: Contratos de interfaces formais
│   ├── harvest-cli-contract.md
│   ├── anonymizer-contract.md
│   └── central-repo-contract.md
├── graph.yaml           # Fase 1: Grafo de dependência de módulos para o Graph Guard
├── graph.md             # Fase 1: Diagramas Mermaid (código, negócio e multi-repo)
├── impact-map.md        # Fase 1: Mapa de impacto e blast radius (obrigatório para S4)
└── tasks.md             # Fase 2: Lista de tarefas com rastreabilidade [P] (gerado por /nc-qa)
```

### Source Code (repository root & central repo)

```text
# No repositório de templates / ferramentas (nimbus-code-spec-kit-template)
scripts/
├── harvest-patterns.sh          # Extensão da CLI com suporte a --source ide-harness
├── sync-corporate-harness.sh    # Script de redistribuição opcional idempotente (Etapa 2)
└── lib/
    ├── harness_anonymizer.py    # Motor de sanitização local preventiva e fail-closed
    └── central_repo_writer.py   # Validador de caminhos e escritor isolado no repo central

tests/
├── unit/
│   ├── test_harness_anonymizer.py   # Testes unitários do sanitizador e cálculo de entropia
│   └── test_central_repo_writer.py  # Testes de isolamento de escrita
├── integration/
│   ├── test_harvest_ide_cli.bats    # Testes de integração BATS da CLI
│   └── test_purge_and_sync.py       # Testes de expurgo e sincronização de satélite
└── security/
    └── test_fail_closed_secrets.bats # Testes de bloqueio imediato contra vazamento de credenciais

# No repositório central dedicado (nimbus-code-harness-corporativo)
raw/                             # Entradas brutas sanitizadas pendentes de triagem
promoted/                        # Regras promovidas homologadas pelo Comitê
archive/                         # Registros imutáveis de expurgo (purge-audit.jsonl)
manifests/index.yaml             # Catálogo indexador consolidado
scripts/
├── triage-cli.py                # Utilitário de curadoria e validação de quórum do Comitê
└── purge-expired.py             # Script de expurgo de dados com >90 dias
.github/
├── CODEOWNERS                   # Controle estrito de aprovação em promoted/
└── workflows/
    ├── purge-expired-harness.yml # Workflow semanal de expurgo LGPD
    └── pr-validation.yml         # Validação de integridade de schemas
```

**Structure Decision**: A arquitetura mantém clara segregação de responsabilidades: o repositório template hospeda as ferramentas CLI locais (`harvest-patterns.sh`, `harness_anonymizer.py`), enquanto o repositório centralizado `nimbus-code-harness-corporativo` hospeda os dados, a automação de expurgo e as rotinas de curadoria do Comitê.

---

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| Criação de novo repositório central GHE | Isolamento estrito de governança, permissões do Comitê e compliance LGPD | Manter no repositório de trabalho local poluiria o catálogo com regras pessoais e violaria isolamento de squads (HRN-0005). |
| Motor de anonimização local em Python | Análise determinística de regex combinada com cálculo de entropia de Shannon | Shell script puro (sed/awk) é frágil para cálculo de entropia e análise contextual; libs pesadas externas aumentariam o footprint local. |

---

## Nimbus-Code — Classificação de Complexidade (S0–S4)

| Campo | Valor |
|---|---|
| **Nível** | **S4** *(Arquitetura, segurança, dados ou integração crítica)* |
| **Justificativa** | Envolve manipulação de texto livre de desenvolvedores, risco de vazamento de credenciais, integração com LLMs externos, conformidade com LGPD (retenção e expurgo) e novo repositório corporativo GHE. |
| **Modelo de IA** | **Modelo forte / Reasoning** |
| **Revisão humana obrigatória** | **Sim (S4)** — Requer revisão formal pelo Security Guardian e Architecture Lead antes do deploy. |
| **Padrão reutilizado encontrado?** | **Sim** (tags: `brownfield-multirepo-context-graph`, `022-nimbuscode-harvest-gateway` e `refresh_managed_project_root_files` do `bootstrap.sh`) |
| **Estimativa de tokens (input+output)** | ~35k–70k tokens por ciclo completo de análise e síntese de regras |

---

## Nimbus-Code — Harness Gate

*Preencher ANTES de qualquer gate. Consultar `docs/harness/harness-catalog.yaml` por `tags` e `bounded_context`.*

| Harness consultado (ID) | Padrão de erro evitado | Mitigação preventiva aplicada nesta feature |
|---|---|---|
| **HRN-0001** | Scope creep silencioso violando isolamento de sessão do agente | O script possui allowlist estrita de leitura e escrita, rejeitando comandos fora do escopo de harness. |
| **HRN-0002** | Divergência silenciosa de arquitetura sem ADL | Todas as decisões arquiteturais estão registradas no ADL desta feature (ADL-001 a ADL-007). |
| **HRN-0003** | Pular consulta a `docs/reuse-catalog.yaml` duplicando soluções | Reutilização explícita por ponteiros do contrato do Harvest Gateway (022) e da distribuição do `bootstrap.sh`. |
| **HRN-0004** | Drift de código/produção sem verificação operacional | Criação de suíte completa de validação executável em `quickstart.md` e testes BATS automatizados. |
| **HRN-0005** | Escrita/poluição no repositório de código errado | Bloqueio bloqueante na CLI impedindo que submissões de harness escrevam no `docs/reuse-catalog.yaml` local. |
| **HRN-0008** | Falha de propagação em repositórios satélite | Algoritmo de bloco gerenciado testado para prevenir sobrescrita de regras locais do desenvolvedor. |

**Resultado da consulta:**
- [x] **Match encontrado** — padrão(ões) de erro relevante(s) declarado(s) acima e mitigado(s)
- [ ] Nenhum padrão de erro relevante encontrado para este domínio
- [ ] Catálogo vazio — nenhum padrão disponível para consulta

---

## Nimbus-Code — Playbook de Sucesso Gate

*Preencher ANTES de qualquer gate. Consultar `docs/playbooks/success-catalog.yaml`.*

| Padrão consultado (ID) | O que funcionou | Como foi reaplicado nesta feature |
|---|---|---|
| **SUC-0001** | Reuso de schema por analogia a partir de catálogos existentes | Reuso do schema de envelope de requisição e resposta do Nimbus Harvest Gateway (SPEC-022). |
| **SUC-0002** | Rollout gradual com contratos formalizados antes do código | Criação dos contratos em `contracts/` antes de qualquer desenvolvimento de scripts. |
| **SUC-0003** | Referência baseada em ponteiros sem duplicação de dados | Catálogo indexador em `manifests/index.yaml` utiliza ponteiros (`raw_source_ref`) para preservar proveniência. |

**Resultado da consulta:**
- [x] **Match encontrado** — padrão(ões) de sucesso relevante(s) declarado(s) acima e reaplicado(s)
- [ ] Nenhum padrão relevante encontrado para este domínio
- [ ] Catálogo vazio — nenhum padrão disponível para consulta

---

## Nimbus-Code — Rastreabilidade AC → Teste → Módulo

| ID AC | Critério (resumo) | Tipo de teste planejado | Arquivo/módulo do teste | Justificativa de ausência (se N/A) |
|---|---|---|---|---|
| **AC-1** | Captura on-demand de `~/.claude/CLAUDE.md` e `.cursor/rules` disparada manualmente | Integração (BATS) | `tests/integration/test_harvest_ide_cli.bats` | — |
| **AC-2** | Escrita exclusiva no repositório central sem poluir o catálogo de reuso local | Integração (BATS / Pytest) | `tests/integration/test_harvest_ide_cli.bats` | — |
| **AC-3** | Sanitização preventiva Fail-Closed com redação de segredos e PII | Unitário e Segurança (Pytest / BATS) | `tests/unit/test_harness_anonymizer.py` e `tests/security/test_fail_closed_secrets.bats` | — |
| **AC-4** | Triagem humana obrigatória com quórum qualificado do Comitê antes de promoção | Unitário / Funcional | `tests/unit/test_triage_cli.py` | — |
| **AC-5** | Expurgo automático semanal de itens brutos não promovidos após 90 dias | Integração | `tests/integration/test_purge_and_sync.py` | — |
| **AC-6** | Redistribuição opcional idempotente para satélites sem sobrescrever regras locais | Integração | `tests/integration/test_purge_and_sync.py` | — |
| **AC-7** | Tratamento gracioso quando nenhum arquivo de harness existir na máquina | Integração (BATS) | `tests/integration/test_harvest_ide_cli.bats` | — |

---

## Nimbus-Code — Module Dependency Graph

**Arquivos:**
- `specs/029-harness-corporativo-ide/graph.yaml` — fonte de verdade estruturada (lida pelo Graph Guard)
- `specs/029-harness-corporativo-ide/graph.md` — diagramas Mermaid para leitura humana
- `specs/029-harness-corporativo-ide/impact-map.md` — **obrigatório para S3 e S4**

**Checklist de manutenção do grafo:**
- [x] `graph.yaml` criado/atualizado com todos os nós e arestas desta feature
- [x] `graph.md` criado/atualizado com diagrama por código e diagrama por business
- [x] Para S3/S4: `impact-map.md` criado/atualizado com análise de risco e plano de rollback
- [x] Nenhum módulo/serviço novo criado nesta feature está faltando no grafo
- [x] Dependências externas (third-party, cloud) declaradas em `externals` no `graph.yaml`
- [x] Grafo será atualizado novamente após `/nimbus-code-implement` se a implementação divergir do plano

### Grafo do Contexto (Multi-Repo Brownfield)

| Campo | Valor |
|---|---|
| **Bounded context** | `harness-corporativo` |
| **Grafo do contexto** | [specs/029-harness-corporativo-ide/graph.md](./graph.md) |
| **Dependências relevantes para esta feature** | `nimbus-code-spec-kit-template` (fornecedor da CLI) e `nimbus-code-harness-corporativo` (repositório central GHE de destino) |
| **Padrões de harvest aplicáveis** | `brownfield-multirepo-context-graph`, `022-nimbuscode-harvest-gateway` e `refresh_managed_project_root_files` |

---

## Nimbus-Code — Estratégia de Release

| Campo | Valor |
|---|---|
| **Estratégia** | **direct** |
| **Feature flag name** | `N/A` |
| **Flag provider** | `N/A` |
| **Critério de ativação** | `N/A` |
| **Critério de rollback** | Remoção das variáveis de ambiente organizacionais `HARVEST_CENTRAL_REPO_DIR` e `HARVEST_API_URL` |

**Justificativa para deploy `direct`:**
Esta feature consiste em scripts utilitários de CLI e automações distribuídas via preset de repositório, com execução **100% on-demand e manual**. Não há tráfego de produção online de usuários finais ou microsserviços sendo impactados. A ativação ocorre sob demanda por flag de linha de comando (`--source ide-harness`), e qualquer rollback é imediato via reversão de commits no Git ou desativação de credenciais de acesso, sem justificar a complexidade de um sistema de feature flags em tempo de execução web.

---

## Nimbus-Code — Plano de Toggle e Rollout (obrigatório com `flag`)

| Campo | Valor |
|---|---|
| **Flag key** | `N/A` |
| **Tipo de flag** | `N/A` |
| **Owner da flag** | `N/A` |
| **Ambiente(s)** | `N/A` |
| **Default por ambiente** | `N/A` |
| **Segmentos de ativação** | `N/A` |
| **Estratégia de rollout** | `N/A` |
| **Kill switch definido?** | Não se aplica (ferramenta CLI on-demand) |
| **Critério de limpeza** | `N/A` |
| **Issue/tarefa de remoção criada?** | `N/A` |

---

## Nimbus-Code — Cost Reference

| Campo | Valor |
|---|---|
| **Token estimate range** | ~35.000–70.000 tokens por lote de submissões de harness analisado |
| **Human effort estimate range** | ~4–8 horas quinzenais para sessões de triagem do Comitê Nimbus Code |
| **Tracking method** | Registro de tokens no log de execução do harvest e KQL no Application Insights do Gateway |
| **Budget ceiling (optional)** | ~US$ 50/mês para o volume inicial de 50 desenvolvedores participantes do piloto |

---

## Nimbus-Code — SLO Gate

| Componente | Latência p99 | Taxa de erro máx. | Disponibilidade | RTO | RPO |
|---|---|---|---|---|---|
| `harness_anonymizer.py` (Local) | < 200ms | 0,001% (fail-closed seguro) | 100% (execução local) | N/A | N/A |
| `scripts/harvest-patterns.sh` (CLI) | < 5s (excluindo LLM) | < 0,1% | 100% (execução local) | N/A | N/A |
| Repositório Central GHE (`raw/` e `promoted/`) | < 1s (git push) | < 0,01% | 99,9% (SLA GHE) | 1 hora | 5 minutos |
| `purge-expired.py` (Job semanal) | — (Job Batch) | < 0,01% | — | 2 horas | 24 horas |

**SLOs não definidos nesta feature e justificativa:**
O script de expurgo `purge-expired.py` e o utilitário de triagem `triage-cli.py` são ferramentas administrativas assíncronas em lote, monitoradas pelo status de conclusão com sucesso no GitHub Actions e não por métricas de latência síncrona.

---

## Nimbus-Code — Security & DevSecOps Gate

| Domínio | Controles aplicáveis | Escapável via ADL? | Status | Observações |
|---|---|---|---|---|
| **Backup & Disaster Recovery** | Todo datastore com dado real tem backup automatizado e retenção | **Não — bloqueante** | **Aprovado** | Dados persistidos em repositório Git no GitHub Enterprise com replicação corporativa e snapshots diários; expurgo em 90 dias atende retenção LGPD. |
| Autenticação (SSO) | Sistemas novos devem usar SSO | Sim, com justificativa no ADL | **Aprovado via ADL** | CLI usa Bearer Token M2M para Gateway; curadoria no repositório central exige autenticação via SSO/SAML do GHE para membros do Comitê (ADL-003). |
| Segredos no código/repositório | Nunca em texto plano; secret scanning bloqueia merge | **Não — bloqueante** | **Aprovado** | Sanitização preventiva Fail-Closed com substituição determinística antes de qualquer chamada HTTP ou gravação; secret scanning ativo no GHE. |
| Branch/merge protegido | PR obrigatório + revisão antes de merge em branch protegida | **Não — bloqueante** | **Aprovado** | Repositório central configurado com branch `main` protegida e aprovação obrigatória de membros do Comitê via `CODEOWNERS` em `promoted/`. |
| Isolamento de ambiente | Credencial de produção nunca usada em dev/test | **Não — bloqueante** | **Aprovado** | Chaves e tokens segregados; testes utilizam fixtures sintéticas mockadas sem dados de produção. |
| Containers | Imagem base pinada, scan de vulnerabilidades | Sim, com justificativa no ADL | **N/A** | Ferramenta executada nativamente em Bash/Python, sem criação de novas imagens de container nesta fase. |
| CI/CD | Segredos via cofre/secrets, least privilege | Sim, com justificativa no ADL | **Aprovado** | Workflows do GitHub Actions utilizam GITHUB_TOKEN restrito e permissões mínimas de escrita por job. |
| IaC — provider(s) usado(s) | 100% da infraestrutura declarada | Sim, com justificativa no ADL | **Aprovado** | Provisionamento do repositório central via Terraform de governança do GitHub Enterprise da organização. |
| Banco de dados | TLS/mTLS obrigatório para tráfego | **Não — bloqueante** | **Aprovado** | Todo tráfego entre CLI, Gateway e GHE é 100% criptografado via TLS 1.3 (HTTPS / SSH). |
| **Firewall / Segmentação** | Regras de firewall e least exposure | Sim, com justificativa no ADL | **Aprovado** | Gateway acessível apenas via rede corporativa/VPN ou token restrito. |
| Observabilidade | Logs estruturados e métricas de auditoria | Sim, com justificativa no ADL | **Aprovado** | Auditoria imutável gravada em `archive/purge-audit.jsonl` e métricas de consumo logadas no Application Insights do Gateway. |

**Riscos identificados e decisão:**
- *Risco de Coleta Não Aprovada pelo Jurídico*: O desenvolvimento e testes foram desacoplados da ativação operacional em produção. A coleta real contra colaboradores fica bloqueada até que o parecer formal do DPO/Jurídico seja homologado (Gate de Execução, ADL-005).

---

## Nimbus-Code — Qualidade de Código, Testes e Observabilidade Gate

| Domínio | Controles aplicáveis | Status | Observações |
|---|---|---|---|
| Revisão de código por IA | Code review solicitado em todo PR desta feature; findings High/Critical bloqueiam merge | **Aprovado** | Copilot code review ativo em todos os PRs de templates e no repositório central. |
| Testes integrados | Cada critério de aceitação do `spec.md` tem teste automatizado | **Aprovado** | Matriz de rastreabilidade cobre 100% dos critérios (AC-1 a AC-7) com testes BATS e Pytest. |
| Observabilidade | Logs estruturados e trilha de auditoria | **Aprovado** | Registros de sanitização com contadores e trilha de auditoria de expurgo em formato JSONL. |
| Arquitetura distribuída | Propagação de correlação entre CLI, Gateway e GHE | **Aprovado** | IDs de correlação (`RAW-YYYYMMDD-hash`) preservados em todo o ciclo de vida da regra. |
| Gestão de bugs | Bugs fora do escopo abertos como Issue no GitHub | **Aprovado** | Protocolo de abertura de issues com label `harness:pending` mantido. |

**Critérios de aceitação sem teste de integração automatizado (se houver) — justificativa:**
Nenhum. Todos os 7 critérios possuem cobertura planejada em testes automatizados.

---

## Nimbus-Code — Architecture Decision Log

| Decisão | Alternativas consideradas | Opção escolhida | Trade-off assumido | Justificativa do desvio (se aplicável) | Aprovado por |
|---|---|---|---|---|---|
| **ADL-001: Extensão do Harvester Existente** | Criar script independente (`harvest-ide.sh`) vs. estender `harvest-patterns.sh` | Estender `scripts/harvest-patterns.sh` com flag `--source ide-harness` | Adiciona responsabilidade à CLI existente, mas reaproveita infraestrutura de token e transporte HTTP testada | N/A — segue o princípio de reuso institucional | Leonardo Rodrigues |
| **ADL-002: Motor Local de Sanitização Fail-Closed** | Sanitizar no Gateway vs. sanitizar localmente com modelo NLP pesado vs. script Python nativo | Módulo Python nativo (`harness_anonymizer.py`) com regex determinístico e Shannon Entropy em modo Fail-Closed | Exige Python 3.11 na máquina do dev, mas garante execução instantânea (<200ms) sem vazar texto cru para a rede | N/A — atende aos controles bloqueantes de segurança | Leonardo Rodrigues |
| **ADL-003: Repositório Central Dedicado** | Salvar no catálogo do projeto local vs. criar banco de dados próprio vs. repositório central GHE | Criar repositório centralizado dedicado `nimbus-code-harness-corporativo` no GHE | Adiciona um repositório à organização, mas garante governança do Comitê, RBAC via `CODEOWNERS` e compliance LGPD | N/A — atende isolamento estrito de código | Leonardo Rodrigues |
| **ADL-004: Composição do Comitê e Quórum** | Aprovação individual sem quórum vs. quórum unânime de 4 membros para todas as regras | Quórum de 2 membros (ao menos 1 técnico) para regras gerais; 3 membros com poder de veto para regras de bounded context sensível | Pode exigir alinhamento prévio, mas evita paralisia operacional e assegura consistência arquitetural | N/A — alinhamento de governança institucional | Leonardo Rodrigues |
| **ADL-005: Desacoplamento do Gate Jurídico/DPO** | Bloquear todo o desenvolvimento técnico até parecer do DPO vs. desenvolver com dados sintéticos e bloquear apenas a coleta real | Desenvolver e testar com fixtures sintéticas; bloquear execução da coleta real em produção até parecer emitido | Permite avanço da engenharia sem risco legal, condicionando a operação ao parecer formal | N/A — separação formal de ambientes e riscos | Leonardo Rodrigues |
| **ADL-006: Expurgo Automático em 90 Dias** | Retenção indefinida vs. expurgo manual sob demanda vs. GitHub Action semanal | Script `purge-expired.py` executado semanalmente via GitHub Actions com retenção estrita de 90 dias | Registros brutos excluídos fisicamente, mantendo apenas hash criptográfico em `archive/purge-audit.jsonl` | N/A — conformidade explícita com LGPD | Leonardo Rodrigues |
| **ADL-007: Redistribuição Idempotente para Satélites** | Sobrescrever arquivos locais dos devs vs. criar regras em arquivos isolados com bloco gerenciado | Algoritmo de bloco gerenciado (`<!-- NIMBUS-MANAGED -->`) herdado do `bootstrap.sh`, gerando `.divergent` em caso de conflito | Exige marcação clara nos arquivos do satélite, mas preserva 100% das customizações individuais do desenvolvedor | N/A — mitigação de conflitos e drift | Leonardo Rodrigues |
