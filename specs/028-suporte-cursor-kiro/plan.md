# Implementation Plan: Suporte a Cursor e Kiro como Integrações Agênticas

**Branch**: `028-suporte-cursor-kiro` | **Data**: 2026-09-22 | **Spec**: [spec.md](./spec.md)

**Entrada**: Especificação da feature em [spec.md](./spec.md), extensão direta do
padrão criado em `specs/024-multi-agent-integration-claude-antigravity/` e
revisado em `specs/025-native-nc-agents/`.

## Summary

Estender o par de scripts `scripts/sync-nc-agents-to-integrations.sh` +
`scripts/lib/nc-agent-sync.py` (criados na spec 024, revisados na spec 025)
para dois novos alvos — **Cursor** e **Kiro** — cobrindo tanto os 12 comandos
`/speckit-*` (via `specify integration install cursor-agent`/`kiro-cli`,
já *built-in* no `specify` CLI) quanto os agentes institucionais NC-*
(via extensão do gerador próprio, já que o `specify` CLI não gerencia esses
agentes nem os comandos proprietários do Nimbus Code).

**Formatos de destino confirmados por investigação direta (auditoria
`/nc-critic`, não redescobertos aqui):**

| Alvo | Comandos `/speckit-*` genéricos | Agentes NC-* institucionais |
|---|---|---|
| Cursor | `.cursor/skills/<nome>/SKILL.md` (via `specify`) | `.cursor/skills/nc-<agente>/SKILL.md` (mesma convenção, gerado por este script) |
| Kiro | `.kiro/prompts/speckit.<nome>.md` (via `specify`, flat, dot-separado) | `.kiro/agents/nc-<agente>.md` (mecanismo nativo "Custom agents", **não** `.kiro/prompts/`) |

**Achado crítico de arquitetura (Harness Gate HRN-0006):** os arrays
`EXPECTED_AGENTS` (bash) e `AGENTS` (Python) estão **hardcoded com 15
entradas**, mas a fonte real (`.github/skills/nc-*`) já tem **18** —
`nc-bug-assess`, `nc-bug-fix` e `nc-bug-test` existem e não estão nesses
arrays, reproduzindo o exato antipadrão que HRN-0006 já documentou (drift
silencioso por lista hardcoded desatualizada, mesmo com testes "passando").
Da mesma forma, `EXTRA_SPECKIT_SKILLS` (7 entradas) está incompleto frente aos
10 comandos `/speckit-*` proprietários reais. **Esta feature não corrige
retroativamente o gap nos alvos já existentes** (Claude/Antigravity) — isso é
trabalho separado, fora de escopo (ver ADL). Mas esta feature **MUST**
implementar a descoberta para Cursor e Kiro via **glob dinâmico**, não via
mais uma lista hardcoded, para não repetir o erro em 2 alvos novos.

**Reuso declarado (catálogo)**: `single-source-multi-target-sync`
(`docs/reuse-catalog.yaml`, `source: specs/024-multi-agent-integration-claude-antigravity/plan.md`,
`reuse_count: 0` até esta feature) — é o próprio padrão sendo estendido, não
uma analogia; `reuse_count` deve ser incrementado para 1 ao final da
implementação.

## Technical Context

**Language/Version**: Python 3 (`scripts/lib/nc-agent-sync.py`) + Bash
(`scripts/sync-nc-agents-to-integrations.sh`) — mesmas linguagens já usadas
pelo gerador existente; nenhuma nova linguagem introduzida.

**Primary Dependencies**: `pyyaml` (já usado por `nc-agent-sync.py` para o
manifest); `specify` CLI (já instalado, catálogo built-in cobre `cursor-agent`
e `kiro-cli`); `bats` para testes (já usado pela suíte existente).

**Storage**: N/A — não há datastore; os "dados" são arquivos versionados no
próprio repositório.

**Testing**: `bats` (`tests/multi-agent-integration/*.bats`), seguindo o
padrão de fixtures em `mktemp -d` já usado por `nc-agent-foundation.bats`.

**Target Platform**: CI (`ubuntu-latest`, `.github/workflows/nc-agents-parity-check.yml`)
e ambiente de desenvolvimento local (macOS/Linux).

**Project Type**: Extensão de scripts de automação/CI existentes — não é
projeto novo.

**Performance Goals**: Herdado do SLO do `spec.md` — sem SLA de runtime
(scripts/CI locais), taxa de erro máxima 0% enforced via testes bloqueantes.

**Constraints**: A instalação de Cursor/Kiro MUST NOT alterar nenhum arquivo
já gerenciado por Copilot/Claude/Antigravity (FR-008); o `.github/agents/`
MUST continuar contendo apenas `nimbus.agent.md` (FR-006, regressão da spec
025).

**Scale/Scope**: 2 novos alvos × (agentes NC-* institucionais + comandos
`/speckit-*` proprietários) descobertos dinamicamente na hora da execução,
não um número fixo pré-calculado nesta spec.

## Constitution Check

*GATE: Deve passar antes da Fase 0 de pesquisa. Reverificar após o desenho da Fase 1.*

| Princípio da Constituição | Aplicável? | Conformidade nesta feature |
|---|---|---|
| Segurança e Dados — nenhum segredo em texto plano | Sim | Os arquivos gerados são apenas prompts/instruções de agente; nenhuma credencial é introduzida |
| SSO obrigatório para sistema novo (greenfield) | Não aplicável | Extensão de scripts de automação existentes, sem superfície de autenticação nova |
| IaC — Terraform como padrão | Não aplicável | Feature não provisiona infraestrutura cloud |
| Grafos de Módulos obrigatórios | Sim | `graph.yaml`/`graph.md` desta feature criados nesta etapa |
| Escala de Complexidade S0–S4 | Sim | S3 confirmado (herdado do cabeçalho de `spec.md`) |
| Branch protection / revisão humana | Sim | S3 exige aprovação humana antes de qualquer escrita, conforme `.nimbus/agent-manifest.yaml` (`approval_matrix_by_complexity.S3.human_approval_before_action: true`) |

**Resultado**: Gate passa sem violação que exija entrada na tabela de
Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/028-suporte-cursor-kiro/
├── plan.md              # Este arquivo
├── graph.yaml            # Grafo de módulos
├── graph.md               # Diagramas Mermaid
├── impact-map.md          # Obrigatório para S3
└── tasks.md                # Fase 2 — gerado por /nc-qa a seguir
```

### Código (raiz do repositório)

```text
scripts/
├── sync-nc-agents-to-integrations.sh   # ESTENDER:
│                                         # - TARGET aceita "cursor" e "kiro" além de vscode/claude/antigravity/all
│                                         # - EXPECTED_AGENTS e EXTRA_SPECKIT_SKILLS substituídos por
│                                         #   descoberta via glob (FR-010) — aplica-se a TODOS os alvos,
│                                         #   corrigindo o gap de nc-bug-*/speckit-bug-* como efeito colateral
│                                         #   correto da arquitetura (não como "correção" isolada — ver ADL)
│                                         # - process_for_cursor() NOVO — mesma forma de process_for_claude(),
│                                         #   com frontmatter {name, description, compatibility, metadata}
│                                         # - process_for_kiro_agent() NOVO — gera .kiro/agents/nc-<agente>.md
│                                         #   com campos {name, description, tools, prompt}
└── lib/
    └── nc-agent-sync.py                 # ESTENDER:
                                          # - TARGETS = ("vscode", "claude", "antigravity", "cursor", "kiro")
                                          # - GENERATED_ROOTS["cursor"] = Path(".cursor/skills")
                                          # - GENERATED_ROOTS["kiro"] = Path(".kiro/agents")
                                          # - render()/destination()/validate_contract() ganham ramos para
                                          #   "cursor" (mesma família SKILL.md do antigravity/claude, mas
                                          #   frontmatter próprio) e "kiro" (formato nativo, campos próprios)
                                          # - AGENTS deixa de ser tupla hardcoded; passa a ser descoberta via
                                          #   glob(".github/skills/nc-*") em load_roles()/source_paths()

tests/multi-agent-integration/
├── nc-agent-foundation.bats             # ESTENDER: novo teste garantindo que a descoberta via glob
│                                          # encontra >= 18 agentes (não mais um número fixo desatualizado)
├── nc-agent-contracts.bats               # ESTENDER: contratos de frontmatter para "cursor" e "kiro"
└── nc-agents-parity.bats                 # ESTENDER: paridade cobrindo os 5 alvos

docs/
└── developer-guide.md                    # ESTENDER: seção "Agentes disponíveis por integração"
                                            # passa a listar 5 integrações (FR-007)

.github/workflows/
└── nc-agents-parity-check.yml            # ESTENDER: paths do trigger incluem .cursor/skills/nc-*/**
                                            # e .kiro/agents/nc-*.md
```

**Structure Decision**: Extensão in-place dos dois scripts existentes (bash +
python), sem criar um terceiro script. A descoberta dinâmica (FR-010) é
implementada uma única vez e usada por todos os 5 alvos, não apenas pelos 2
novos — isso é uma melhoria arquitetural que se aplica horizontalmente, não
uma duplicação de lógica por alvo.

## Nimbus-Code — Classificação de Complexidade (S0–S4)

| Campo | Valor |
|---|---|
| **Nível** | **S3** (herdado do cabeçalho de `spec.md`) |
| **Justificativa** | Cruza 2 scripts existentes, 3 suítes de teste bats, 1 workflow de CI e a documentação — além de introduzir uma mudança arquitetural transversal (descoberta dinâmica em vez de lista hardcoded) que afeta os 5 alvos, não só os 2 novos |
| **Modelo de IA** | Reasoning |
| **Revisão humana obrigatória** | Sim — S3, e `.nimbus/agent-manifest.yaml` exige aprovação humana explícita antes de qualquer escrita nesse nível |
| **Padrão reutilizado encontrado?** | Sim (tag: `single-source-multi-target-sync`, reuso direto do próprio mecanismo da spec 024, não analogia) |
| **Estimativa de tokens (input+output)** | ~35–50 mil tokens |

---

## Nimbus-Code — Harness Gate

| Harness consultado (ID) | Padrão de erro evitado | Mitigação preventiva aplicada nesta feature |
|---|---|---|
| **HRN-0006** | Lista hardcoded de agentes/comandos desatualizada frente à fonte real, com testes "passando" mesmo com drift | Descoberta dinâmica via glob (FR-010) substitui `EXPECTED_AGENTS`/`AGENTS`/`EXTRA_SPECKIT_SKILLS` hardcoded; novo teste garante que a contagem descoberta bate com a fonte real, não com um número fixo |
| HRN-0002 | Decisão arquitetural imposta silenciosamente | As duas decisões de formato (Cursor reusa Skills; Kiro usa Custom agents nativos) foram investigadas tecnicamente e **confirmadas explicitamente com o usuário** na auditoria `/nc-critic`, não assumidas |
| HRN-0003 | Re-derivação de padrão já existente sem consultar reuso | Catálogo consultado antes deste plano; `single-source-multi-target-sync` identificado como o próprio mecanismo sendo estendido |
| HRN-0001 | Scope creep do agente fora do escopo explícito | O plano registra explicitamente que o gap pré-existente `nc-bug-*`/`speckit-bug-*` em Claude/Antigravity **não é corrigido retroativamente** nesta feature — apenas os 2 alvos novos nascem corretos |

**Resultado da consulta:**
- [x] Match encontrado — padrões relevantes declarados e mitigados
- [ ] Nenhum padrão de erro relevante encontrado para este domínio
- [ ] Catálogo vazio — nenhum padrão disponível

**Playbook de Sucesso Gate**: nenhum padrão do `docs/playbooks/success-catalog.yaml`
mapeia diretamente para extensão de gerador multi-alvo; o mais próximo
(`SUC-0002`, contract-first/staged rollout) já foi aplicado na sequência de
User Stories da spec (P1 → P2 → P3).

---

## Nimbus-Code — Rastreabilidade AC → Teste → Módulo

| ID AC | Critério (resumo) | Tipo de teste planejado | Arquivo/módulo do teste |
|---|---|---|---|
| AC-1 | `specify integration install cursor-agent` instala os 12 comandos sem afetar outras integrações | Integração (shell) | `tests/multi-agent-integration/nc-agents-parity.bats` (novo caso) |
| AC-2 | Gerador com destino `cursor` sincroniza os agentes NC-* em `.cursor/skills/nc-<agente>/SKILL.md` | Contrato + integração | `nc-agent-contracts.bats`, `nc-agents-parity.bats` |
| AC-3 | `specify integration install kiro-cli` instala os 12 comandos, comunicando pré-requisito de CLI | Integração (shell) | `nc-agents-parity.bats` (novo caso) |
| AC-4 | Gerador com destino `kiro` sincroniza os agentes NC-* em `.kiro/agents/nc-<agente>.md` (Custom agents nativo) | Contrato + integração | `nc-agent-contracts.bats`, `nc-agents-parity.bats` |
| AC-5 | Teste de paridade cobre os 5 alvos e falha bloqueante em drift | Integração | `nc-agents-parity.bats` (estendido) |
| AC-6 | `.github/agents/` continua só com `nimbus.agent.md` após extensão para 5 alvos | Regressão | `nc-agent-foundation.bats` (caso já existente, sem novo código, só reexecutado com 5 alvos) |
| AC-7 | `docs/developer-guide.md` documenta as 5 integrações | Revisão documental | Sem automação — checklist manual em `impact-map.md` |

---

## Nimbus-Code — Module Dependency Graph

**Arquivos:**
- [graph.yaml](./graph.yaml) — fonte de verdade estruturada
- [graph.md](./graph.md) — diagramas Mermaid
- [impact-map.md](./impact-map.md) — obrigatório (S3)

**Checklist de manutenção do grafo:**
- [x] `graph.yaml` criado com todos os módulos desta feature
- [x] `graph.md` criado com diagrama por código e por business
- [x] `impact-map.md` criado com análise de risco e plano de rollback
- [x] Nenhum módulo novo ficou fora do grafo
- [x] Grafo será atualizado novamente após `/nc-builder` se a implementação divergir do plano

### Grafo do Contexto (Multi-Repo Brownfield)

| Campo | Valor |
|---|---|
| **Bounded context** | `spec-kit-workflow` |
| **Grafo do contexto** | [graph.yaml](./graph.yaml) / [graph.md](./graph.md) |
| **Dependências relevantes para esta feature** | `scripts/sync-nc-agents-to-integrations.sh`, `scripts/lib/nc-agent-sync.py`, `tests/multi-agent-integration/*.bats`, `.github/workflows/nc-agents-parity-check.yml`, `docs/developer-guide.md` |
| **Padrões de harvest aplicáveis** | `single-source-multi-target-sync` (reuso direto) |

## Nimbus-Code — Estratégia de Release

| Campo | Valor |
|---|---|
| **Estratégia** | Rollout direto via PR único, sem feature flag — mesma abordagem da spec 024 (script/CI, sem runtime de produção) |
| **Feature flag name** | Não aplicável |
| **Flag provider** | N/A |
| **Critério de ativação** | Aprovação humana do plano (S3) + PR revisado com CI verde (`nc-agents-parity-check.yml`) |
| **Critério de remoção** | N/A |
| **Critério de rollback** | Reverter o PR; a descoberta dinâmica é aditiva (novos alvos + novo mecanismo de discovery), não substitui comportamento de produção existente fora deste script |

## Nimbus-Code — Cost Reference

| Campo | Valor |
|---|---|
| **Token estimate range** | ~35–50 mil tokens |
| **Human effort estimate range** | ~3–6 horas (revisão de PR + validação manual de Cursor/Kiro instalados localmente) |
| **Tracking method** | Tabela "Estimativa vs. Consumo Real" em `tasks.md` + campo "Horas Humanas" no GitHub Project |
| **Budget ceiling (optional)** | N/A |

## Nimbus-Code — Operational Metrics Gate

| Componente | Indicador operacional | Meta inicial | Evidência |
|---|---|---:|---|
| Instalação Cursor/Kiro (SC-001) | Tempo de instalação + primeiro uso | < 10 min | Execução manual documentada em `quickstart.md`/`impact-map.md` |
| Paridade de agentes (SC-002) | % de agentes NC-* equivalentes nos 5 alvos | 100% | `nc-agents-parity.bats` |
| Isolamento entre integrações (SC-003) | Incidentes de sobrescrita entre integrações | 0 | `nc-agent-foundation.bats` + revisão de diff do PR |
| Gate de paridade bloqueante (SC-004) | % de edições fora de sync detectadas antes do merge | 100% | CI (`nc-agents-parity-check.yml`) |
| Regressão do orquestrador único VS Code (SC-005) | Arquivos `nc-*.agent.md` soltos em `.github/agents/` | 0 | `nc-agent-foundation.bats` |

**SLOs de runtime**: não aplicável — componentes são scripts/CI locais (ver `spec.md`).

## Nimbus-Code — Security & DevSecOps Gate

| Domínio | Controles aplicáveis | Escapável via ADL? | Status | Observações |
|---|---|---|---|---|
| **Backup & Disaster Recovery** | N/A — apenas arquivos versionados em Git | Sim | ✅ N/A | Sem datastore |
| Segredos no código/repositório | Arquivos gerados são prompts/instruções; nenhuma credencial | **Não — bloqueante** | ✅ | Mesma garantia já vigente para vscode/claude/antigravity |
| Branch/merge protegido | PR obrigatório + revisão humana (S3) | **Não — bloqueante** | ✅ | |
| Isolamento de ambiente | Scripts não dependem de credenciais de cliente real | **Não — bloqueante** | ✅ | |
| Autenticação (SSO) | Sem sistema novo | Sim, com justificativa no ADL | ✅ N/A | Ver Constitution Check |
| IaC — provider(s) usado(s) | N/A | Sim | ✅ N/A | Sem provisionamento |
| Banco de dados | N/A | Sim | ✅ N/A | Sem datastore |
| TLS obrigatório em trânsito e criptografia em repouso | N/A — comunicação é apenas com o `specify` CLI local e o sistema de arquivos; nenhuma chamada de rede nova introduzida por esta feature | Sim, com justificativa no ADL | ✅ N/A | Sem serviço de rede novo |
| Mínimo privilégio / RBAC | N/A — scripts locais/CI, sem novo papel de acesso | Sim, com justificativa no ADL | ✅ N/A | Nenhuma superfície de acesso nova |
| Destroy de IaC protegido | N/A | Sim | ✅ N/A | Sem infraestrutura |

**Riscos identificados e decisão:**
- **Descoberta dinâmica alterar comportamento dos 3 alvos já existentes (vscode/claude/antigravity)**: mitigar rodando a suíte completa `nc-agents-parity.bats` antes e depois da mudança, confirmando que os 3 alvos existentes continuam 100% verdes; qualquer novo agente descoberto (`nc-bug-*`) que passe a ser sincronizado nos alvos existentes é um efeito colateral **aceitável e correto**, não uma regressão — mas deve ser destacado no PR para revisão humana explícita, não silenciado.
- **Kiro exigir CLI instalado localmente para testes de integração reais**: mitigar com testes de contrato/fixture (sem precisar do binário real) para a maior parte da suíte, documentando no `impact-map.md` quais cenários exigem validação manual com o CLI instalado.

## Nimbus-Code — Qualidade de Código, Testes e Observabilidade Gate

| Domínio | Controles aplicáveis | Status | Observações |
|---|---|---|---|
| Revisão de código por IA | Copilot Code Review solicitado no PR | ✅ | |
| Testes de contrato | Frontmatter de Cursor e Kiro validado por `validate_contract()` estendido | ✅ | |
| Testes de paridade/integração | 5 alvos cobertos por `nc-agents-parity.bats` | ✅ | |
| Testes de regressão | Descoberta dinâmica não quebra os 3 alvos existentes | ✅ | Executar suíte completa antes/depois |
| Observabilidade | N/A — scripts locais/CI, sem runtime | ✅ N/A | |

**Critérios de aceitação sem teste de integração automatizado — justificativa:**
- AC-7 (documentação) é validado por revisão humana, não por automação.

## Nimbus-Code — Architecture Decision Log

| Decisão | Alternativas consideradas | Opção escolhida | Trade-off assumido | Justificativa do desvio (se aplicável) | Aprovado por |
|---|---|---|---|---|---|
| Formato NC-* para Cursor | (a) `.cursor/skills/` (mesma família Skills) · (b) inventar mecanismo próprio · (c) orquestrador único como VS Code | **(a) Reusar `.cursor/skills/nc-<agente>/SKILL.md`** | Nenhum mecanismo nativo de "custom agent" foi encontrado no Cursor além de Skills/Rules — decisão pragmática, não uma limitação aceita às pressas | Confirmada com o usuário na auditoria `/nc-critic` (sem evidência de poluição de menu no Cursor) | Usuário (via `/nc-critic`) |
| Formato NC-* para Kiro | (a) `.kiro/prompts/nc-*.md` (mesma convenção genérica dos comandos) · (b) `.kiro/agents/nc-*.md` (mecanismo nativo Custom agents) | **(b) Usar o mecanismo nativo `.kiro/agents/`** | Exige um terceiro tipo de renderização no gerador (nem `SKILL.md`-like, nem flat-prompt), mas espelha corretamente o pivot já feito para o Claude na spec 025 | Confirmada com o usuário na auditoria `/nc-critic`, com paralelo direto à decisão já tomada para o Claude | Usuário (via `/nc-critic`) |
| Descoberta de agentes/comandos-fonte | (a) Manter listas hardcoded e apenas adicionar cursor/kiro a elas · (b) Substituir por descoberta dinâmica via glob para todos os alvos | **(b) Descoberta dinâmica, aplicada a todos os 5 alvos** | Efeito colateral: `nc-bug-*`/`speckit-bug-*` passam a ser sincronizados também para Claude/Antigravity, algo que não estava no escopo original desta feature | Mitigação direta do antipadrão documentado em HRN-0006 — perpetuar a lista hardcoded ao adicionar 2 alvos novos seria repetir conscientemente um erro já catalogado | **Usuário — aprovado explicitamente nesta etapa de planejamento (2026-09-22)** |
| Escopo do gap pré-existente (`nc-bug-*` ausente em Claude/Antigravity) | (a) Corrigir dentro desta feature, já que o código será tocado de qualquer forma · (b) Tratar como fora de escopo, deixando a correção como efeito colateral da mudança arquitetural, sem tarefas dedicadas de "backfill" | **(b) Fora de escopo como tarefa dedicada; corrigido apenas como efeito colateral da descoberta dinâmica** | Nenhuma tarefa específica de "sincronizar nc-bug-* retroativamente" entra no `tasks.md` desta feature — mas o PR deve declarar explicitamente esse efeito colateral para revisão humana | Consistente com a regra de não fazer scope creep silencioso (`docs/developer-guide.md`, critério de nova spec vs. correção) | — |
| Versão mínima de CLI do Kiro (FR-009) | (a) Manter suposição de versão mínima como no Antigravity · (b) Remover, baseado em evidência empírica de que o `specify` CLI não a impõe | **(b) Remover a suposição, exigir apenas binário no PATH** | Risco de uma versão futura do Kiro exigir versão mínima sem que este plano tenha previsto — mitigado por FR-009 pedir comunicação clara de qualquer pré-requisito detectado | Decisão do usuário na auditoria `/nc-critic`, baseada em teste empírico (`specify init --integration kiro-cli`) | Usuário (via `/nc-critic`) |
| Itens "Escapável via ADL" do Security & DevSecOps Gate (Backup&DR, SSO, IaC provider, Banco de dados, TLS, Mínimo privilégio/RBAC, Destroy de IaC) | (a) Introduzir controles novos mesmo sem superfície aplicável · (b) Marcar N/A com justificativa única, dado que a feature só altera scripts de automação/CI e arquivos versionados, sem runtime, rede, dado ou infraestrutura nova | **(b) Marcar N/A consolidado** | Nenhum — não há superfície de segurança nova introduzida por esta feature | Feature é puramente de automação de sincronização de arquivos-fonte para novos diretórios de destino; nenhum dos 6 controles não-negociáveis tem aplicação real aqui | `/nc-shield` (auditoria desta etapa) |

## Complexity Tracking

> Nenhuma violação da Constitution Check identificada nesta feature — tabela
> não preenchida.

## Nimbus-Code — Governance Verdict (`/nc-governor`)

| Campo | Valor |
|---|---|
| **Auditoria de integridade — `spec.md` (SHA-256)** | `fe82b3116ffd04f0d5b9cf17cda53eb29cd057a2120ee6774b409b20f5284d35` (calculado em 2026-09-22, pós-auditoria `/nc-critic`) |
| **Classificação de complexidade confirmada** | **S3** |
| **Nível de supervisão exigido** | Semiautônomo — revisão humana obrigatória antes de qualquer escrita, conforme `.nimbus/agent-manifest.yaml` (`approval_matrix_by_complexity.S3`) |
| **Pendências críticas em `spec.md`?** | Não — as 3 `[NEEDS CLARIFICATION]` originais (formato Cursor, formato Kiro, versão mínima CLI) foram resolvidas na auditoria `/nc-critic` com investigação técnica direta + confirmação do usuário |
| **Security & DevSecOps Gate** | ✅ Aprovado — 6 Controles Não-Negociáveis cobertos, sem superfície de segurança nova aplicável |
| **Achado de arquitetura transversal** | Descoberta dinâmica (FR-010) afeta os 5 alvos, não só os 2 novos — **aprovado explicitamente pelo usuário** durante o `/nc-arch`, com efeito colateral (sincronização de `nc-bug-*`) destacado para revisão no PR |
| **RACI — Responsável pela aprovação humana do plano** | Usuário/Dev (já concedeu autorização explícita para seguir o fluxo completo, incluindo as decisões de arquitetura registradas no ADL) |
| **RACI — Consultado** | N/A — decisões técnicas resolvidas via investigação direta nesta sessão |
| **Veredito** | ✅ **GO para prosseguir ao `/nc-qa` (tasks.md) e `/nc-builder` (implementação)** — usuário autorizou explicitamente o fluxo completo da spec 028 nesta sessão. |
