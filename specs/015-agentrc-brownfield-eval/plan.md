# Implementation Plan: AgentRC Brownfield Evaluation

**Branch**: `[015-agentrc-brownfield-eval]` | **Date**: 2026-08-23 | **Spec**: [spec.md](./spec.md)

## Summary

Avaliar se o AgentRC do Microsoft Lab traz ganho líquido para análise de código
brownfield neste repositório e, principalmente, se conflita com capacidades que
já existem no fluxo Nimbus Code. A entrega desta fase é uma recomendação clara:
adotar, adotar com restrições ou rejeitar.

## Technical Context

**Language/Version**: Markdown, YAML e Bash (artefatos de planejamento e validação)

**Primary Dependencies**: documentação pública do AgentRC, artefatos atuais do
Nimbus Code (`specs/014`, `specs/011`, `docs/reuse-catalog.yaml`,
`docs/bounded-contexts.yaml`)

**Storage**: `specs/015-agentrc-brownfield-eval/`, `docs/reuse-catalog.yaml`,
`docs/adr/`

**Testing**: revisão documental guiada por checklist; validação manual dos
critérios de aceitação contra as fontes citadas

**Target Platform**: GitHub Enterprise / repositório deste template

**Constraints**:
- AgentRC é experimental; esta fase é de avaliação, não de adoção
- A comparação deve usar apenas evidências públicas e artefatos já presentes no
  repositório
- Não há mudança de runtime, rollout ou toggle nesta feature
- Nenhum segredo, infraestrutura ou datastore novo é introduzido

**Compatibility**: o fluxo atual de spec → plan → tasks permanece intacto;
esta feature apenas documenta a decisão sobre AgentRC

## Constitution Check

| Gate | Status | Observação |
|---|---|---|
| Backup & DR | ✅ N/A | Nenhum datastore ou dado de produção é criado |
| Segredos no código | ✅ | Sem credenciais; apenas documentação pública e artefatos Markdown/YAML |
| Branch/merge protegido | ✅ | Mantém o fluxo normal de PR antes de merge |
| Isolamento de ambiente | ✅ | Avaliação não usa credenciais de produção nem altera ambientes |
| Observabilidade | ✅ N/A | Não há serviço em runtime nesta fase |
| IaC | ✅ N/A | Sem infraestrutura nova ou alteração manual de cloud |

## Project Structure

### Artefatos da feature

```text
specs/015-agentrc-brownfield-eval/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── graph.yaml
├── graph.md
└── checklists/
    └── requirements.md
```

### Arquivos alterados

```text
specs/015-agentrc-brownfield-eval/plan.md
specs/015-agentrc-brownfield-eval/research.md
specs/015-agentrc-brownfield-eval/data-model.md
specs/015-agentrc-brownfield-eval/quickstart.md
```

### Arquivos não aplicáveis

```text
contracts/        # N/A — avaliação documental, sem interface externa a formalizar
impact-map.md     # N/A — feature S2
```

---

## Nimbus-Code — Classificação de Complexidade (S0–S4)

| Campo | Valor |
|---|---|
| **Nível** | **S2** |
| **Justificativa** | Envolve análise comparativa multi-artefato e geração de documentação de decisão, mas sem mudança de runtime nem integração entre serviços |
| **Modelo de IA** | Auto |
| **Revisão humana obrigatória** | Não (S0–S3) |
| **Padrão reutilizado encontrado?** | Sim (tag: `hybrid-dev-templates`) |
| **Estimativa de tokens (input+output)** | ~5–8 mil tokens |

---

## Nimbus-Code — Harness Gate

| Harness consultado (ID) | Padrão de erro evitado | Mitigação preventiva aplicada nesta feature |
|---|---|---|
| HRN-0001 | Scope creep do agente ao editar fora do escopo | A feature fica restrita a artefatos de avaliação; qualquer gap fora do escopo vira Issue separada |
| HRN-0003 | Re-derivação sem consultar reuse-catalog.yaml | O plan referencia padrões já catalogados e evita duplicar avaliação/estrutura já existente |

**Resultado da consulta:**
- [x] Match encontrado — padrões HRN-0001 e HRN-0003 relevantes declarados acima e mitigados

---

## Nimbus-Code — Rastreabilidade AC → Teste → Módulo

| ID AC | Critério (resumo) | Tipo de teste planejado | Arquivo/módulo do teste | Justificativa de ausência (se N/A) |
|---|---|---|---|---|
| AC-1 | Matriz compara capacidades relevantes de AgentRC e fluxo atual | Manual / revisão documental | `specs/015-agentrc-brownfield-eval/quickstart.md` | — |
| AC-2 | Cada capacidade é classificada como complementar/duplicada/conflitante | Manual / revisão documental | `specs/015-agentrc-brownfield-eval/quickstart.md` | — |
| AC-3 | Recomendações terminam em uma decisão única | Manual / revisão documental | `specs/015-agentrc-brownfield-eval/quickstart.md` | — |
| AC-4 | Se houver piloto, escopo e critérios de saída ficam claros | Manual / revisão documental | `specs/015-agentrc-brownfield-eval/quickstart.md` | — |

---

## Nimbus-Code — Module Dependency Graph

**Arquivos:**
- `specs/015-agentrc-brownfield-eval/graph.yaml` — fonte de verdade estruturada
- `specs/015-agentrc-brownfield-eval/graph.md` — visualização Mermaid

**Checklist:**
- [x] `graph.yaml` criado/atualizado com os nós desta feature
- [x] `graph.md` criado/atualizado com diagrama legível por humanos
- [x] Nenhum módulo novo ficou fora do grafo
- [x] Dependências externas foram mantidas como documentação pública, não como runtime
- [x] `impact-map.md` não se aplica (feature S2, sem mudança operacional)

### Grafo do Contexto (Multi-Repo Brownfield)

| Campo | Valor |
|---|---|
| **Bounded context** | `spec-kit-workflow` |
| **Grafo do contexto** | [graph.yaml](./graph.yaml) / [graph.md](./graph.md) |
| **Dependências relevantes para esta feature** | Repositório atual do template e seus artefatos de governança (spec, plan, reuse catalog, harness catalog) |
| **Padrões de harvest aplicáveis** | Nenhuma |

## Nimbus-Code — Estratégia de Release

| Campo | Valor |
|---|---|
| **Estratégia** | `direct` |
| **Feature flag name** | `N/A` |
| **Flag provider** | `N/A` |
| **Critério de ativação** | `N/A` |
| **Critério de rollback** | `N/A` |

**Justificativa para deploy `direct`**: esta fase não altera runtime nem publica
comportamento novo; é uma avaliação documental que termina em recomendação.

## Nimbus-Code — Cost Reference

| Campo | Valor |
|---|---|
| **Token estimate range** | ~5–8 mil tokens |
| **Human effort estimate range** | ~2–4 horas |
| **Tracking method** | Revisão do plan/research/quickstart e registro de horas humanas no GitHub Project quando a decisão for revisada |
| **Budget ceiling (optional)** | N/A |

## Nimbus-Code — SLO Gate

| Componente | Latência p99 | Taxa de erro máx. | Disponibilidade | RTO | RPO |
|---|---|---|---|---|---|
| Avaliação AgentRC vs. fluxo atual | — | — | — | — | — |

**SLOs não definidos nesta feature e justificativa:**
- Nenhum componente em runtime é introduzido; o resultado é um artefato de decisão
  e não um serviço operacional

## Nimbus-Code — Security & DevSecOps Gate

| Domínio | Controles aplicáveis | Escapável via ADL? | Status | Observações |
|---|---|---|---|---|
| Backup & Disaster Recovery | N/A — sem datastore | Não | ✅ N/A | Não existe dado novo a proteger |
| Autenticação (SSO) | N/A — sem sistema novo | Sim | ✅ N/A | Não há superfície de login |
| Segredos no código/repositório | Nunca em texto plano | Não | ✅ | Não há segredo neste plano |
| Branch/merge protegido | PR obrigatório antes de merge | Não | ✅ | Mantém a regra padrão do template |
| Isolamento de ambiente | Sem uso de credenciais de produção | Não | ✅ | Avaliação em docs בלבד |
| Containers | N/A | Sim | ✅ N/A | Sem container novo |
| CI/CD | N/A | Sim | ✅ N/A | Sem pipeline novo |
| IaC — provider(s) usado(s) | N/A | Sim | ✅ N/A | Sem alteração de infraestrutura |
| Banco de dados | N/A | Não | ✅ N/A | Sem banco novo |
| Firewall / Segmentação de rede | N/A | Sim | ✅ N/A | Sem exposição de serviço |
| Observabilidade | N/A | Sim | ✅ N/A | Sem SLO operacional nesta fase |

**Riscos identificados e decisão:**
- Nenhum risco de segurança adicional foi introduzido por esta avaliação; a
  decisão é seguir sem integração até existir aprovação explícita para piloto

## Nimbus-Code — Qualidade de Código, Testes e Observabilidade Gate

| Domínio | Controles aplicáveis | Status | Observações |
|---|---|---|---|
| Revisão de código por IA | N/A para esta fase documental | ✅ N/A | Não há código novo |
| Testes integrados | Critérios validados por revisão documental | ✅ | Quickstart cobre a validação |
| Observabilidade | N/A | ✅ N/A | Nenhum componente em runtime |
| Arquitetura distribuída / Microsserviços | N/A | ✅ N/A | Sem chamadas entre serviços |
| Gestão de bugs | Bugs fora do escopo viram Issue | ✅ | Mantém isolamento da avaliação |

**Critérios de aceitação sem teste de integração automatizado (se houver) — justificativa:**
- AC-1 a AC-4 são validados por revisão documental e checklist, pois a feature
  não entrega código executável nem serviço em runtime

## Nimbus-Code — Architecture Decision Log

| Decisão | Alternativas consideradas | Opção escolhida | Trade-off assumido | Justificativa do desvio (se aplicável) | Aprovado por |
|---|---|---|---|---|---|
| Basear a avaliação em documentação pública do AgentRC | Instalar e executar o AgentRC localmente; analisar só o README; consultar issues do upstream | Usar README/docs públicas + artefatos atuais do Nimbus Code | Menos evidência empírica, mais reprodutibilidade e menor risco operacional | N/A — escolha alinhada ao escopo de avaliação | Dev |
| Manter a fase como avaliação-only | Pilotar imediatamente; integrar no fluxo do template; trocar ferramentas agora | Avaliação sem integração | Adia prova operacional, mas evita conflito e retrabalho prematuros | N/A — escolha de escopo | Dev |
| Não usar rollout/toggle | Flag/canary/blue-green; OpenFeature | Direct / N/A | Sem mecanismo de ativação progressiva porque não há runtime novo | N/A — não existe entrega operacional nesta fase | — |

## Nimbus-Code — Summary of Generated Artifacts

- `research.md`
- `data-model.md`
- `quickstart.md`
- `graph.yaml`
- `graph.md`

