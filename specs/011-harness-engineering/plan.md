# Implementation Plan: Harness Engineering — Aprendizado Organizacional com Erros

## Remediação aprovada — 2026-09-20

- Escopo S3 autorizado: corrigir a busca literal do catálogo e a cópia distribuída,
  adicionar `tests/scripts/harness-search.bats`, manter o grafo atualizado.
- Issue existente: #431. O fallback descartava IDs YAML sem aspas e encontrava
  somente a primeira entrada. A remediação usa um leitor `awk` do schema do
  catálogo, sem dependência de `yq`, e compara substrings literais, sem distinguir
  maiúsculas/minúsculas, exclusivamente em cada tag e em `bounded_context`.
- Formatos cobertos: IDs/scalars com ou sem aspas, tags em lista block/flow,
  `error_pattern`/`prevention` simples ou multiline (`>`/`|`). Não é um parser
  YAML genérico (anchors, aliases e objetos arbitrários não são suportados).
- Validação: Bats offline, incluindo paridade byte a byte da cópia distribuída,
  múltiplos resultados, termos com metacaracteres/backslashes e erros de CLI.
- A autorização desta remediação não encerra as revisões #453/#437 nem aprova
  adoção institucional, labels ou métricas operacionais.

**Branch**: `feature/011-harness-engineering` | **Date**: 2026-08-20 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/011-harness-engineering/spec.md`

## Summary

Incorporar o conceito de **Harness Engineering** ao workflow NIMBUS CODE, criando
uma camada de memória organizacional que captura, cataloga e propaga aprendizados
de falhas entre projetos e agentes. Os componentes entregues são:

1. `docs/harness/` — diretório com catálogo, templates e guia de uso
2. Seção "Harness Gate" no `plan-template.md` — consulta obrigatória antes de planejar
3. Instrução de consulta no `copilot-instructions.md` — integra harness ao protocolo do agente
4. Labels `harness:*` no `setup-github-labels.sh` — rastreabilidade de lições no GitHub
5. Script `scripts/harness-search.sh` — busca rápida no catálogo por tags/contexto

## Technical Context

**Language/Version**: YAML (catálogo), Markdown (docs/templates), Bash (script de busca)

**Primary Dependencies**: Bash e `awk` para a busca; `yq` não é necessário.
O leitor suporta o schema do catálogo descrito na remediação acima.

**Storage**: `docs/harness/harness-catalog.yaml` (arquivo estático versionado no repo)

**Testing**: `tests/scripts/harness-search.bats` — regressão offline da busca
e paridade das cópias. Revisão manual dos artefatos e verificação de labels
são atividades distintas, não cobertas pela suíte local.

**Target Platform**: GitHub Enterprise Cloud (`venha-pra-nuvem.ghe.com`); os artefatos
são agnósticos de plataforma (YAML/Markdown/Bash)

**Project Type**: Tooling / processo de engenharia (não há serviço em produção)

**Performance Goals**: `harness-search.sh` responde em < 5s (AC-4)

**Constraints**: Preenchimento do catálogo é manual/curatorial — sem automação de
parsing de PRs nesta fase (ver "Fora de Escopo" na spec)

**Scale/Scope**: Org `venha-pra-nuvem`, todos os repositórios usando NIMBUS CODE

## Constitution Check

| Gate | Status | Observação |
|---|---|---|
| Backup & DR | N/A | Nenhum datastore de produção — `harness-catalog.yaml` é versionado no Git |
| Segredos no código | ✅ | Sem credenciais — busca usa `awk` localmente, sem autenticação |
| Branch/merge protegido | ✅ | PR obrigatório conforme regras da org |
| Isolamento de ambiente | ✅ | Artefatos estáticos, sem acesso cross-repo automático |
| Observabilidade | N/A | Scripts CLI sem SLO; output via `echo` |
| IaC | N/A | Sem infraestrutura provisionada |

## Project Structure

### Documentation (this feature)

```text
specs/011-harness-engineering/
├── spec.md              ✅ Completo
├── plan.md              # Este arquivo
├── graph.yaml           # Grafo de módulos
├── graph.md             # Diagramas Mermaid
├── impact-map.md        # Obrigatório (S3)
└── tasks.md             # Lista de tarefas
```

### Arquivos criados/alterados (fora da pasta de spec)

```text
docs/harness/
├── README.md                      # Conceito, fluxo e links
├── harness-catalog.yaml           # Catálogo central (3 entradas de exemplo)
├── incident-template.md           # Template post-mortem (5-Whys + timeline)
└── harness-guide.md               # Guia para devs e agentes

scripts/
└── harness-search.sh              # Busca no catálogo por tag/bounded_context

presets/nimbus-code-standards/templates/
└── plan-template.md               # + seção "Harness Gate"

.github/
└── copilot-instructions.md        # + instrução de consulta ao harness antes de planejar

scripts/
└── setup-github-labels.sh         # + labels harness:pending, harness:cataloged, harness:blocking
```

---

## Nimbus-Code — Classificação de Complexidade (S0–S4)

| Campo | Valor |
|---|---|
| **Nível** | **S3** |
| **Justificativa** | Cruza múltiplos módulos: `docs/harness/` (novo), `plan-template.md` (estendido), `copilot-instructions.md` (estendido), `setup-github-labels.sh` (estendido), `scripts/harness-search.sh` (novo). Impacta o protocolo de planejamento de todos os agentes futuros |
| **Modelo de IA** | Claude Sonnet (reasoning ativo) |
| **Revisão humana obrigatória** | Não (S3) |
| **Padrão reutilizado encontrado?** | Sim (tag: `hybrid-dev-templates`) — o padrão de catálogo curatorial é análogo ao `reuse-catalog.yaml` (Feature 001); a estrutura de entrada YAML é derivada. Diferença: o harness cataloga *erros*, não *soluções* |
| **Estimativa de tokens (input+output)** | ~25–40 mil tokens (S3 com reuso parcial — catálogo e templates são a maior parte do output) |

---

## Nimbus-Code — Rastreabilidade FR / AC → Teste → Módulo

| ID FR / AC | Critério / Requisito (resumo) | Tipo de teste planejado | Arquivo/módulo do teste | Justificativa de ausência |
|---|---|---|---|---|
| FR-001 / AC-1 | Schema e estrutura do catálogo `harness-catalog.yaml` | Validação de sintaxe YAML (`python3 -c "import yaml; yaml.safe_load(open('docs/harness/harness-catalog.yaml'))"`) | `docs/harness/harness-catalog.yaml` | — |
| FR-002 / AC-1 | `copilot-instructions.md` instrui consulta ao harness antes do plan | Validação de texto (leitura e verificação do arquivo) | `.github/copilot-instructions.md` | — |
| FR-003 / AC-2 / AC-7 | `plan.md` tem seção "Harness Gate" (match, sem match, catálogo vazio) | Validação de template e conformidade de estados | `presets/nimbus-code-standards/templates/plan-template.md` | — |
| FR-004 / AC-3 | Checklist de fechamento inclui passo `harness:pending` (>20% retrabalho) | Validação de template | `presets/nimbus-code-standards/templates/tasks-template.md` | — |
| FR-005 / AC-5 | Governança de `harness:blocking` e permissão exclusiva Tech Lead | Validação documental e governança de labels | `docs/harness/harness-guide.md` | — |
| FR-006 | Sanitização e anonimização de dados PII/segredos | Validação de compliance estático | `docs/harness/harness-guide.md` | — |
| FR-007 / AC-4 | Busca no catálogo via CLI responde em < 5s com fallback grep/awk | Execução de benchmark (`time ./scripts/harness-search.sh <tag>`) | `scripts/harness-search.sh` | — |
| FR-008 / AC-6 | Template de incidente com timeline, 5-Whys e checklist | Validação de integridade de template | `docs/harness/incident-template.md` | — |
| AC-5 / SC-004 | Labels `harness:*` criados pelo script de forma idempotente | Teste de execução CLI (`./scripts/setup-github-labels.sh`) | `scripts/setup-github-labels.sh` | — |

---

## Nimbus-Code — Module Dependency Graph

**Arquivos:**
- `specs/011-harness-engineering/graph.yaml`
- `specs/011-harness-engineering/graph.md`
- `specs/011-harness-engineering/impact-map.md`

**Checklist de manutenção do grafo:**
- [x] `graph.yaml` criado com todos os nós e arestas desta feature
- [x] `graph.md` criado com diagrama por código e diagrama por business
- [x] `impact-map.md` criado (S3 — obrigatório)
- [x] Nenhum módulo/serviço novo criado falta no grafo
- [x] Dependências externas declaradas em `externals` no `graph.yaml`
- [ ] Grafo será atualizado após implementação se divergir do plano

---

## Nimbus-Code — Estratégia de Release

| Campo | Valor |
|---|---|
| **Estratégia** | `direct` |
| **Feature flag name** | N/A |
| **Flag provider** | N/A |
| **Critério de ativação** | N/A — documentação, templates e scripts; sem serviço em produção |
| **Critério de rollback** | Reverter o PR; os artefatos são aditivos (novas seções, novo diretório) e não quebram comportamento existente |

**Justificativa para deploy `direct`:**
Esta feature é composta exclusivamente de arquivos Markdown, YAML e um script Bash.
Não há serviço exposto, dado persistido em datastore de produção nem fluxo de usuário
final. As mudanças em templates e `copilot-instructions.md` são aditivas — novas seções
não afetam seções existentes. Deploy direto é adequado e proporcionado ao risco.

---

## Nimbus-Code — SLO Gate

| Componente | Latência p99 | Taxa de erro máx. | Disponibilidade | RTO | RPO |
|---|---|---|---|---|---|
| `harness-search.sh` | < 5s (execução local) | 0% (somente leitura, sem side-effect) | — | N/A | N/A |

**SLOs não definidos:** Todos os demais componentes são arquivos estáticos (YAML/Markdown)
sem SLO mensurável. O `harness-catalog.yaml` é lido via `awk` localmente —
sem dependência de serviço externo.

---

## Nimbus-Code — Security & DevSecOps Gate

| Domínio | Controles aplicáveis | Escapável via ADL? | Status | Observações |
|---|---|---|---|---|
| Backup & DR | N/A — catálogo versionado no Git | — | ✅ N/A | Git é o mecanismo de versionamento e recuperação |
| Segredos no código | Busca usa `awk` local — sem credenciais | Não — bloqueante | ✅ | Verificado: nenhum secret em texto plano |
| Branch/merge protegido | PR obrigatório | Não — bloqueante | ✅ | |
| Isolamento de ambiente | Artefatos estáticos, sem acesso automático cross-repo | Não — bloqueante | ✅ | |
| Observabilidade | N/A — scripts CLI locais | Sim, com justificativa | ✅ N/A | |
| IaC | N/A — sem infraestrutura provisionada | — | ✅ N/A | |
| Banco de dados / TLS | N/A | — | ✅ N/A | |
| Firewall | N/A | — | ✅ N/A | |

**Riscos identificados:** Nenhum risco de segurança relevante. O `harness-catalog.yaml`
pode conter referências a `source_pr` com links de PRs privados — a visibilidade
já é controlada pela visibilidade do repositório. Para projetos com dado sensível
no `source_pr`, o guia instrui a deixar o campo vazio (`""`).

---

## Nimbus-Code — Qualidade de Código, Testes e Observabilidade Gate

| Domínio | Controles aplicáveis | Status | Observações |
|---|---|---|---|
| Revisão de código por IA | GitHub Copilot code review solicitado no PR | ✅ | PR desta feature incluirá revisão Copilot |
| Testes integrados | Testes manuais (leitura de artefatos, execução do script, verificação de labels) | ⚠️ Manual | Componentes são docs/templates/scripts sem lógica de negócio testável automaticamente |
| Observabilidade | N/A — sem serviço em produção | ✅ N/A | |
| Arquitetura distribuída | N/A — sem chamadas entre serviços | ✅ N/A | |
| Gestão de bugs | Bugs fora do escopo abertos como Issue | ✅ | |

---

## Nimbus-Code — Architecture Decision Log

| Decisão | Alternativas consideradas | Opção escolhida | Trade-off assumido | Justificativa do desvio | Aprovado por |
|---|---|---|---|---|---|
| Formato do catálogo | JSON vs YAML vs banco de dados | YAML estático versionado no Git | Sem query semântica; busca literal via `awk` após remediação #431 | Consistente com `reuse-catalog.yaml` — mesma convenção, zero dependências novas, diff legível no PR | — |
| Localização do catálogo | `docs/` vs `specs/` vs raiz | `docs/harness/` | Separado do reuse-catalog para semântica clara (erros ≠ soluções) | Evita confusão entre os dois catálogos; facilita busca por path | — |
| Automação de preenchimento | Parser automático de PRs vs manual curatorial | Manual curatorial nesta fase | Menor coverage; depende de disciplina do time | Automação de parser requer análise de diff — complexidade S4 fora do escopo desta feature; catálogo de qualidade > catálogo volumoso | — |
| Deploy | `flag` vs `direct` | `direct` | Sem rollout incremental | Tooling/docs sem serviço online; mudanças aditivas | — |
