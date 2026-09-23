# Implementation Plan: Native NC Agents

**Branch**: `025-native-nc-agents` | **Date**: 2026-09-21 | **Spec**: [spec.md](./spec.md)

## Summary

Extend the existing single-source synchronization pattern so NC-* definitions
can be consumed as native custom agents by VS Code/Copilot and Claude Code,
while retaining the current Antigravity skills bridge and `/nc-*` compatibility
surface. The implementation is manifest-driven, deterministic, and blocked by
parity checks when a generated destination drifts.

The existing `.nimbus/agent-manifest.yaml` remains the governance manifest; no
second agent manifest is introduced. The existing
`single-source-multi-target-sync` reuse pattern is referenced rather than
re-derived ([reuse catalog](../../docs/reuse-catalog.yaml)).

## Technical Context

**Language/Version**: Bash 5-compatible shell plus Python 3 for deterministic
frontmatter/body normalization.

**Primary Dependencies**: Existing `scripts/sync-nc-agents-to-integrations.sh`,
`.nimbus/agent-manifest.yaml`, Bats, GitHub Actions, VS Code custom agent
frontmatter, Claude Code subagent frontmatter.

**Storage**: Versioned Markdown/YAML files only; no runtime datastore.

**Testing**: Existing Bats parity suite plus shell syntax checks and YAML
parsing fixtures.

**Target Platform**: Repository-local VS Code/Copilot, Claude Code, and the
currently verified Antigravity `.agents/skills/` contract.

**Project Type**: Developer tooling/template repository.

**Performance Goals**: One deterministic generation pass; no network access
required; parity validation should complete within the existing CI job budget.

**Constraints**: Do not invent an Antigravity native-agent format; do not remove
`/nc-*`; do not silently drop manifest controls; do not modify source skills
while generating destinations; preserve existing unrelated worktree changes.

**Scale/Scope**: 15 NC-* roles, 3 integration surfaces, 1 generator, 1 parity
gate, and platform-specific adapters.

## Constitution Check

**Status: PASS before research**

- S3 architecture change is explicitly classified and requires human approval
  before implementation.
- `graph.yaml`, `graph.md`, and `impact-map.md` exist for this feature.
- No secrets, infrastructure resources, databases, or personal data are added.
- PR review and protected-branch rules remain unchanged.
- The existing reuse catalog, harness catalog, and success playbook were
  consulted before design.
- The existing manifest is extended/reused instead of duplicated.

## Project Structure

```text
scripts/
└── sync-nc-agents-to-integrations.sh

.nimbus/
└── agent-manifest.yaml

.github/
├── agents/
└── skills/nc-*/SKILL.md

.claude/
├── agents/
└── skills/nc-*/

.agents/
└── skills/nc-*/

tests/multi-agent-integration/
└── nc-agents-parity.bats

specs/025-native-nc-agents/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
├── graph.yaml
├── graph.md
└── impact-map.md
```

**Structure Decision**: Keep the current script and source paths, add native
agent output directories, and keep Antigravity on the verified skills bridge
until an official native contract is available.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| Multiple platform adapters | VS Code and Claude require different native file contracts | One shared file cannot satisfy both native discovery and frontmatter rules |
| S3 human gate | Changes agent identity, delegation and permissions across integrations | Treating this as a documentation-only sync would hide execution-policy risk |

## Nimbus-Code — Classificação de Complexidade (S0–S4)

| Campo | Valor |
|---|---|
| **Nível** | **S3** |
| **Justificativa** | Cruza fonte institucional, manifesto, gerador, três integration surfaces e CI parity |
| **Modelo de IA** | Reasoning |
| **Revisão humana obrigatória** | Não (S3), mas aprovação humana antes da implementação é obrigatória |
| **Padrão reutilizado encontrado?** | Sim — `single-source-multi-target-sync` |
| **Estimativa de tokens (input+output)** | ~35–55 mil tokens |

## Nimbus-Code — Harness Gate

| Harness consultado (ID) | Padrão de erro evitado | Mitigação preventiva aplicada |
|---|---|---|
| HRN-0006 | Superfícies customizadas não sincronizadas entre integrações | Lista derivada da fonte, geração determinística e AC-3 parity gate |
| HRN-0002 | Decisão arquitetural silenciosa fora do padrão | Contratos separados, ADL explícito e bloqueio para Antigravity não confirmado |
| HRN-0001 | Escopo expandido silenciosamente | Plataformas e destinos limitados no spec/graph/contract |

**Resultado da consulta:** Match encontrado e mitigado.

## Nimbus-Code — Playbook de Sucesso Gate

| Padrão consultado (ID) | O que funcionou | Como foi reaplicado |
|---|---|---|
| SUC-0002 | Contrato e spec antes da automação reduziram retrabalho | Research/contracts precedem qualquer implementação |
| SUC-0003 | Referenciar catálogo por ponteiro reduziu re-derivação | O plano aponta para `single-source-multi-target-sync` |

**Resultado da consulta:** Match encontrado e reaplicado.

## Phase 0 — Research Summary

As decisões e evidências completas estão em [research.md](./research.md).

- VS Code/Copilot descobre `.agent.md` em `.github/agents` e suporta campos de
  descrição, nome, ferramentas e handoffs.
- Claude Code usa subagents Markdown em `.claude/agents`, com descrição, prompt,
  modelo e permissões controláveis por frontmatter.
- Antigravity permanece no contrato verificado `.agents/skills`; nenhum contrato
  oficial de `.agents/agents` foi confirmado, então não será inventado.

## Phase 1 — Design

### Manifest and adapters

1. Reusar `.nimbus/agent-manifest.yaml` como fonte de identidade, escopo,
   ferramentas e approval policy.
2. Derivar os agentes elegíveis a partir da lista de roles, verificando que cada
   role possui uma skill NC-* correspondente.
3. Gerar **um único** `.github/agents/nimbus.agent.md` (orquestrador `@nimbus`,
   ver ADL-025-04) com frontmatter VS Code, `tools` = união dos allowlists das
   15 roles, e corpo renderizado a partir de
   `scripts/lib/templates/nimbus-agent.template.md` + tabela de cobertura das
   roles. Nenhum `.github/agents/nc-*.agent.md` é gerado.
4. Gerar `.claude/agents/nc-*.md` (15 arquivos, um por role) com frontmatter
   Claude e corpo funcional.
5. Continuar gerando `.agents/skills/nc-*/SKILL.md` para Antigravity.
6. Manter `.github/skills/nc-*/SKILL.md` como bridge e fonte de conteúdo.

### Parity and failure behavior

- Comparar hashes do corpo funcional normalizado e os controles críticos do
  manifesto.
- Falhar com mensagem identificando source, destino e role quando faltar arquivo,
  houver drift ou houver role sem fonte.
- Nunca apagar arquivos arbitrários; destinos gerados devem ser uma lista
  explícita e validada.
- Atualizar o workflow existente para executar geração em fixture temporária e
  validar ausência de drift.

## Nimbus-Code — Rastreabilidade AC → Teste → Módulo

| ID AC | Critério | Tipo | Arquivo/módulo | Justificativa |
|---|---|---|---|---|
| AC-1 | Gera superfícies nativas e bridge | integração | `tests/multi-agent-integration/nc-agents-parity.bats` | — |
| AC-2 | Preserva manifesto e controles | unitário/integração | `tests/multi-agent-integration/nc-agent-manifest.bats` | — |
| AC-3 | Detecta drift | integração | `tests/multi-agent-integration/nc-agents-parity.bats` | — |
| AC-4 | Mantém `/nc-*` | integração | `tests/multi-agent-integration/nc-agents-parity.bats` | — |
| AC-5 | Falha sem contrato suportado | unitário | `tests/multi-agent-integration/nc-agent-contracts.bats` | — |
| AC-6 | Artefatos de governança completos | validação | `tests/multi-agent-integration/nc-agent-governance.bats` | — |

## Nimbus-Code — Module Dependency Graph

- [graph.yaml](./graph.yaml) lista fonte, manifesto, gerador, destinos e gate.
- [graph.md](./graph.md) contém os diagramas técnico e de negócio.
- [impact-map.md](./impact-map.md) contém risco, rollback e Go/No-Go.
- Não há dependências cloud/third-party runtime; os contratos externos são
  documentados em [contracts/](./contracts/).

## Grafo do Contexto (Multi-Repo Brownfield)

| Campo | Valor |
|---|---|
| **Bounded context** | `spec-kit-workflow` |
| **Grafo do contexto** | [graph.yaml](./graph.yaml) e [graph.md](./graph.md) |
| **Dependências relevantes** | Apenas `venha-pra-nuvem/nimbus-code` |
| **Padrões de harvest aplicáveis** | Nenhuma |

## Nimbus-Code — Estratégia de Release

| Campo | Valor |
|---|---|
| **Estratégia** | `canary` |
| **Feature flag name** | N/A — artefatos de tooling, sem toggle runtime |
| **Flag provider** | N/A — não há toggle runtime; OpenFeature não é necessário |
| **Critério de ativação** | Primeiro validar VS Code e Claude em branch/fixture; depois publicar Antigravity bridge sem alterar `/nc-*` |
| **Critério de rollback** | Reverter somente adaptadores/gerador se qualquer parity gate falhar |

## Nimbus-Code — Cost Reference

| Campo | Valor |
|---|---|
| **Token estimate range** | ~35–55 mil tokens |
| **Human effort estimate range** | ~3–6 horas de revisão e validação |
| **Tracking method** | `tasks.md` com estimativa vs. consumo real e campo Horas Humanas no GitHub Project |
| **Budget ceiling (optional)** | N/A |

## Nimbus-Code — SLO Gate

| Componente | Latência p99 | Taxa de erro máx. | Disponibilidade | RTO | RPO |
|---|---|---|---|---|---|
| Gerador local/CI | — | 0% de execuções aceitas com erro oculto | — | — | — |
| Parity gate | — | 0% de drift não detectado | — | — | — |

**SLOs não definidos:** tooling local não atende tráfego de produção; qualidade é
medida por falha explícita e cobertura de drift.

## Nimbus-Code — Security & DevSecOps Gate

| Domínio | Status | Observações |
|---|---|---|
| Backup & DR | N/A | Nenhum datastore ou dado operacional novo |
| SSO | N/A | Nenhum sistema novo exposto |
| Segredos | PASS | Gerador não aceita nem cria segredos |
| Branch/merge protegido | PASS | Mudança segue PR e CI |
| TLS | N/A | Nenhuma conexão nova |
| Isolamento de ambiente | PASS | Geração local/fixture e destinos versionados |
| IaC/destroy | N/A | Nenhuma infraestrutura |
| Supply chain | PASS | Sem dependência nova; contratos fixados em docs oficiais |

### Architecture Decision Log

| ID | Decisão | Alternativa | Justificativa | Aprovação |
|---|---|---|---|---|
| ADL-025-01 | Reusar `.nimbus/agent-manifest.yaml` | Criar `.nimbus/agents.yaml` | Evita duplicação de identidade e drift de governança | Aprovado por @lrodrigues em 2026-09-21 |
| ADL-025-02 | Manter Antigravity em `.agents/skills` | Inventar `.agents/agents` | Não há contrato confirmado; segurança exige falha explícita | Aprovado por @lrodrigues (Arch Board) em 2026-09-21 |
| ADL-025-03 | Manter `/nc-*` como bridge | Remover comandos na mesma feature | Evita quebra de usuários e permite rollout canário | Aprovado por @lrodrigues em 2026-09-21 |
| ADL-025-04 | VS Code recebe um único agente orquestrador (`@nimbus`, gerado a partir de `scripts/lib/templates/nimbus-agent.template.md`) que conduz o usuário (Bug/Fix, Nova Spec, Ideação) e delega internamente para as 15 roles NC, em vez de 15 arquivos `.agent.md` separados | Manter 15 arquivos `.agent.md` (um por role), replicando o modelo Claude/Antigravity | O agent picker do VS Code Copilot Chat fica poluído com 15 entradas; um orquestrador único melhora a UX sem alterar Claude Code (15 subagentes) nem Antigravity (skill bridges), que não sofrem esse problema | Aprovado por @lrodrigues antes da publicação do PR #479 |
| ADL-025-05 | Reabertura (2026-09-22): nomes de ferramenta são **traduzidos por plataforma** no gerador (Claude: `view`→`Read`, `rg`→`Grep`, `glob`→`Glob`, `bash`→`Bash`, `apply_patch`→`Edit`+`Write`, `web_fetch`→`WebFetch`, `skill:*`→`Skill`, `sql`→removido); Claude recebe o orquestrador como skill `/nimbus` (conversa principal), não como subagente | Copiar `tool_allowlist` do manifesto sem tradução (desenho original) | O Claude Code recusa iniciar subagente cujas ferramentas não resolvem para nada; os 18 `.claude/agents/nc-*.md` estavam inutilizáveis e o gate de paridade passava porque só comparava com o manifesto. Subagente Claude não pode chamar subagente, então o orquestrador precisa rodar na conversa principal. Kiro tem o mesmo defeito (ver `research.md`, Decision 5) e fica para T032 | Pendente de aprovação por @lrodrigues no PR da reabertura |

## Constitution Check — Post-Design

**Status: PASS — Todos os ADLs foram formalmente aprovados pelo Dev/Architecture Board.**

- Todos os artefatos S3 obrigatórios estão presentes.
- Nenhuma decisão bloqueante de segurança foi flexibilizada.
- O plano não inicia implementação sem aprovação dos ADLs e dos contratos.
- A remoção de `/nc-*` está explicitamente fora de escopo.

