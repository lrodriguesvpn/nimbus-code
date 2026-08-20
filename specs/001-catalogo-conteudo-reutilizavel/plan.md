# Implementation Plan: Catálogo de Conteúdo Reutilizável

**Branch**: `001-catalogo-conteudo-reutilizavel` (histórico — entregue via release `v1.5.0` do preset `nimbus-code-standards`, sem branch de feature dedicado) | **Date**: 2026-08-20 (documento retroativo; entrega original ocorreu antes desta data) | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-catalogo-conteudo-reutilizavel/spec.md`

> **Nota histórica**: este `plan.md` é gerado retroativamente, a pedido do
> mantenedor, para completar o registro formal do ciclo Nimbus-Code. O escopo
> já foi **aprovado e implementado diretamente** em conversa ("Pode seguir
> vamos usar suas sugestões"), pulando `/speckit-plan`/`/speckit-tasks`
> formais — ver banner de status no topo de `spec.md`. Este documento não
> antecede a implementação; ele a documenta depois do fato, com evidência
> verificada de que cada item do escopo existe hoje no repositório (ver
> `research.md`).

## Summary

Introduzir um mecanismo de reuso de conteúdo entre features/specs para reduzir
custo de tokens: (1) o princípio constitucional "referenciar por ponteiro,
nunca duplicar por valor"; (2) o catálogo machine-readable
`docs/reuse-catalog.yaml`, instalado em todo projeto consumidor pelo
`bootstrap.sh`; (3) resumos "TL;DR" no topo de documentos longos de
referência; (4) o campo "Padrão reutilizado encontrado?" na tabela de
Classificação de Complexidade do `plan-template.md`, para que toda feature
nova consulte o catálogo antes de re-derivar uma solução do zero.

## Technical Context

**Language/Version**: N/A — convenção documental (Markdown/YAML), sem código executável

**Primary Dependencies**: Nenhuma — artefatos consumidos por leitura humana e por agentes de IA via prosa/YAML

**Storage**: `docs/reuse-catalog.yaml` (arquivo estático versionado no repositório, não um datastore)

**Testing**: N/A — validado por revisão humana da conversa de aprovação e por uso subsequente real (features 005, 007 e 008 desta mesma sessão já referenciam entradas do catálogo)

**Target Platform**: Bundle `nimbus-code-project-bundle`, consumido por qualquer repositório GHE da organização `venha-pra-nuvem` que instale o preset `nimbus-code-standards`

**Project Type**: Convenção/documentação e templates de preset — não é um serviço em produção

**Performance Goals**: N/A — sem componente executável com latência mensurável

**Constraints**: Não alterar nenhum comportamento de scripts/workflows já existentes no bundle (ver "Fora de Escopo" no `spec.md`); retrocompatível com specs já escritas antes da introdução do campo "Padrão reutilizado encontrado?"

**Scale/Scope**: Todo o portfólio de repositórios da organização que consomem o preset `nimbus-code-standards` (hoje: este próprio repositório e todo novo repositório de projeto criado via `bootstrap.sh`)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Esta feature **introduziu** o princípio "Referenciar por ponteiro, nunca
duplicar por valor" na constituição — não havia violação a checar contra uma
regra pré-existente, pois a mudança é a própria origem da regra. Reavaliação
pós-design: sem violações — o próprio `plan.md`/`research.md` deste documento
segue o princípio que a feature introduziu (referencia `constitution.md` e
`docs/ai-code-quality-and-observability.md` seção 9 por link/âncora, em vez de
reexplicar o conteúdo).

**Gate: PASS** (sem exceções a justificar em Complexity Tracking).

## Project Structure

### Documentation (this feature)

```text
specs/001-catalogo-conteudo-reutilizavel/
├── spec.md              # Já existente — status "aprovado e implementado"
├── plan.md              # Este arquivo (gerado retroativamente)
├── research.md          # Gerado retroativamente — resolve as 3 perguntas em aberto do spec.md
├── data-model.md         # Gerado retroativamente — schema do reuse-catalog.yaml
├── quickstart.md         # Gerado retroativamente — como validar os artefatos entregues
├── graph.yaml            # Gerado retroativamente — grafo de módulos afetados
└── graph.md              # Gerado retroativamente — diagramas Mermaid
```

*(Sem `tasks.md` — o escopo foi executado diretamente, sem passar por
`/speckit-tasks`, por decisão já registrada no `spec.md`.)*

### Artefatos do bundle afetados (fora da pasta da spec)

```text
presets/nimbus-code-standards/templates/project-root/.specify/memory/
└── constitution-template.md        # + princípio "Referenciar por ponteiro"

presets/nimbus-code-standards/templates/
├── plan-template.md                 # + campo "Padrão reutilizado encontrado?"
└── reuse-catalog.yaml               # novo — template instalado como docs/reuse-catalog.yaml

.github/
└── copilot-instructions.md          # + campo "Padrão reutilizado encontrado?" no fluxo de declaração de tarefa

docs/
├── reuse-catalog.yaml                # novo (raiz deste repo, dogfooding do próprio preset)
├── ai-code-quality-and-observability.md  # + TL;DR e seção 9 "Catálogo de Reuso"
├── label-taxonomy-and-autonomous-dev.md  # + TL;DR
├── module-graphs.md                       # + TL;DR
└── developer-guide.md                     # + TL;DR
```

**Structure Decision**: Estrutura de preset/documentação já usada pelo bundle
(sem diretórios `src/`/`tests/` — este não é um projeto de software
tradicional, é o próprio bundle de convenções). Os artefatos vivem em
`presets/nimbus-code-standards/templates/` (fonte do preset) e são
espelhados/instalados em `docs/`/`.specify/`/`.github/` na raiz deste
repositório, que é ao mesmo tempo o autor e o primeiro consumidor "dogfooded"
do preset (ver comentário no topo do `spec.md`).

## Complexity Tracking

*Fill ONLY if Constitution Check has violations that must be justified*

N/A — Constitution Check passou sem violações (esta feature introduziu a
própria regra que outras features passariam a seguir).

---

## Nimbus-Code — Classificação de Complexidade (S0–S4)

| Campo | Valor |
|---|---|
| **Nível** | **S2** |
| **Justificativa** | Módulo/convenção completa: novo arquivo `docs/reuse-catalog.yaml` + template, ajuste em `constitution-template.md` e `plan-template.md` do preset — sem integração entre serviços externos, sem dado sensível, sem arquitetura distribuída envolvida (conforme já classificado no cabeçalho do `spec.md`) |
| **Modelo de IA** | Auto |
| **Revisão humana obrigatória** | Não (S2) — mas houve aprovação humana explícita registrada em conversa antes da execução direta, substituindo o fluxo formal de gates |
| **Padrão reutilizado encontrado?** | Não — esta feature é a **origem** do catálogo de reuso; não havia catálogo para consultar antes dela |
| **Estimativa de tokens (input+output)** | Não estimada à época (entrega anterior à introdução formal deste campo, que é parte do próprio escopo desta feature). Estimativa retroativa aproximada para o volume entregue (5 arquivos de preset/doc alterados + 1 arquivo novo): ~15–25 mil tokens, compatível com o multiplicador de S2 em `docs/ai-code-quality-and-observability.md` seção 6 |

## Nimbus-Code — Rastreabilidade AC → Teste → Módulo

| ID AC | Critério (resumo) | Tipo de teste planejado | Arquivo/módulo do teste | Justificativa de ausência |
|---|---|---|---|---|
| AC-1 | Princípio de referência por ponteiro presente na constituição | N/A | `.specify/memory/constitution.md` | Convenção textual/de processo — validada por revisão humana da leitura da constituição, não por teste automatizado executável |
| AC-2 | `docs/reuse-catalog.yaml` existe e é machine-readable (parseável como YAML) | Validação estrutural (poderia ser automatizada futuramente) | `docs/reuse-catalog.yaml` | Nesta fase, validado manualmente (parse YAML bem-sucedido verificado em `research.md`); `scripts/validate-manifests.yml` já cobre outros catálogos do bundle e poderia ser estendido para este arquivo numa iteração futura (fora de escopo aqui) |
| AC-3 | TL;DR presente no topo de docs de referência longos | N/A | `docs/ai-code-quality-and-observability.md` e equivalentes | Convenção de redação — validada por revisão humana/leitura, não testável automaticamente |
| AC-4 | Campo "Padrão reutilizado encontrado?" presente no `plan-template.md` e usado nos `plan.md` subsequentes | N/A | `presets/nimbus-code-standards/templates/plan-template.md` | Convenção de template — a evidência de adoção é a presença do campo preenchido nos `plan.md` de features 002 em diante (verificado em `research.md`), não um teste automatizado |

> Todas as linhas desta feature são **N/A justificado**: o escopo é 100%
> convenção/documentação/template, sem lógica executável para cobrir com
> teste de integração — consistente com a classificação S2 "convenção
> completa" do cabeçalho do `spec.md`.

## Nimbus-Code — Module Dependency Graph

**Arquivos:**
- [`graph.yaml`](./graph.yaml) — gerado retroativamente nesta sessão
- [`graph.md`](./graph.md) — gerado retroativamente nesta sessão
- `impact-map.md` — **não aplicável**, feature é S2 (obrigatório apenas para S3/S4)

**Checklist de manutenção do grafo:**
- [x] `graph.yaml` criado com todos os nós e arestas desta feature
- [x] `graph.md` criado com diagrama por código e diagrama por business
- [x] N/A para S2: `impact-map.md` não é obrigatório
- [x] Nenhum módulo/serviço novo criado nesta feature está faltando no grafo
- [x] Dependências externas: nenhuma (sem third-party/cloud envolvido)
- [ ] Grafo será atualizado novamente se a implementação divergir do plano — N/A, implementação já concluída e estável há múltiplas releases do bundle

## Nimbus-Code — Estratégia de Release

| Campo | Valor |
|---|---|
| **Estratégia** | `direct` |
| **Feature flag name** | N/A |
| **Flag provider** | N/A |
| **Critério de ativação** | N/A |
| **Critério de rollback** | `git revert` do PR de release do preset, seguido de nova versão `PATCH` do bundle |

**Justificativa para deploy `direct`:**
Mudança de convenção/documentação em um preset consumido via atualização
explícita e manual (`specify bundle update`) por cada projeto — não há
"rollout" incremental possível ou necessário: cada projeto consumidor decide
quando atualizar para a versão do bundle que inclui esta mudança (ver
"Versão do bundle em uso — Política de Atualização" no `README.md`). Não é
uma mudança de comportamento de sistema em produção que precise de
ativação gradual.

## Nimbus-Code — Plano de Toggle e Rollout

N/A — não há toggle envolvido (ver Estratégia de Release acima).

## Nimbus-Code — Cost Reference

| Campo | Valor |
|---|---|
| **Token estimate range** | ~15–25 mil tokens (estimativa retroativa, ver Classificação de Complexidade acima) |
| **Human effort estimate range** | ~0,5–1 hora (revisão da proposta em conversa + aprovação) |
| **Tracking method** | Não rastreado formalmente à época (esta feature introduziu o mecanismo de rastreamento que passou a ser usado a partir da feature 002) |
| **Budget ceiling (optional)** | N/A |

## Nimbus-Code — SLO Gate

| Componente | Latência p99 | Taxa de erro máx. | Disponibilidade | RTO | RPO |
|---|---|---|---|---|---|
| `docs/reuse-catalog.yaml` (leitura estática) | — | — | — | — | — |

**SLOs não definidos nesta feature e justificativa:**
Todos os componentes são arquivos estáticos (Markdown/YAML) lidos por
humanos ou agentes de IA — não há serviço em execução contínua, logo nenhum
SLO de latência/disponibilidade é mensurável ou aplicável.

## Nimbus-Code — Security & DevSecOps Gate

| Domínio | Controles aplicáveis | Escapável via ADL? | Status | Observações |
|---|---|---|---|---|
| Backup & Disaster Recovery | N/A — sem datastore de produção | Não — bloqueante | N/A | Arquivo versionado no Git; o próprio histórico do repositório é a garantia de recuperação |
| Autenticação (SSO) | N/A — sem sistema novo greenfield | Sim, com justificativa no ADL | N/A | Não aplicável a artefato de documentação |
| Segredos no código/repositório | Nenhum segredo envolvido | Não — bloqueante | ✅ OK | Conteúdo é 100% documentação/convenção, sem credenciais |
| Branch/merge protegido | PR obrigatório antes de merge | Não — bloqueante | ✅ OK | Seguiu convenção já vigente do bundle à época |
| Isolamento de ambiente | N/A | Não — bloqueante | N/A | Sem ambientes de execução envolvidos |
| Containers | N/A | Sim, com justificativa no ADL | N/A | Não aplicável |
| CI/CD | N/A | Sim, com justificativa no ADL | N/A | Sem pipeline novo introduzido |
| IaC | N/A | Sim, com justificativa no ADL | N/A | Não aplicável |
| Banco de dados | N/A | Não — bloqueante | N/A | Sem banco de dados envolvido |
| Firewall / Segmentação de rede | N/A | Sim, com justificativa no ADL | N/A | Não aplicável |
| Observabilidade | N/A | Sim, com justificativa no ADL | N/A | Artefato estático, sem componente observável em runtime |

**Riscos identificados e decisão:**
Nenhum risco de segurança identificado — mudança puramente documental/de
convenção, sem superfície de ataque nova.

## Nimbus-Code — Qualidade de Código, Testes e Observabilidade Gate

| Domínio | Controles aplicáveis | Status | Observações |
|---|---|---|---|
| Revisão de código por IA | GitHub Copilot code review no PR de release do preset | N/A — entrega anterior à formalização desta regra | Aprovação humana em conversa serviu como gate de revisão à época |
| Testes integrados | N/A — sem lógica executável (ver Rastreabilidade AC → Teste acima) | ✅ Justificado | Todas as linhas da tabela AC são N/A justificado |
| Observabilidade | N/A — artefato estático | ✅ N/A | Sem componente em runtime |
| Arquitetura distribuída / Microsserviços | N/A | ✅ N/A | Monólito de documentação, sem chamadas entre serviços |
| Gestão de bugs | Nenhum bug identificado relacionado a esta feature | ✅ OK | — |

**Critérios de aceitação sem teste de integração automatizado — justificativa:**
Todos os 4 critérios de aceitação (AC-1 a AC-4) são convenções de
documentação/template, sem comportamento executável a testar (ver
Rastreabilidade AC → Teste → Módulo acima para a justificativa individual de
cada um).

## Nimbus-Code — Architecture Decision Log

| Decisão | Alternativas consideradas | Opção escolhida | Trade-off assumido | Justificativa do desvio (se aplicável) | Aprovado por |
|---|---|---|---|---|---|
| Onde vive o catálogo de reuso | Preset `nimbus-code-standards` (aplicado a todo projeto) vs. extensão opcional separada (`nimbus-code-backlog-sync`) | Preset `nimbus-code-standards` | Ganha universalidade (todo projeto novo já nasce com o catálogo); perde a opcionalidade de só instalar em quem precisa | N/A — não é desvio de padrão, é a decisão fundacional desta feature | Mantenedor (aprovação em conversa) |
| Automação de preenchimento do catálogo | Automação completa desde o dia 1 vs. curadoria manual inicial | Curadoria manual/curatorial desde o início | Perde velocidade de preenchimento; ganha qualidade/validação do formato antes de investir em automação | N/A — decisão de sequenciamento deliberada, registrada como "Fora de Escopo" no `spec.md` | Mantenedor (aprovação em conversa) |
| Campo `reuse_tags` em `graph.yaml` | Adicionar agora (especulativo) vs. não adicionar até haver necessidade concreta | Não adicionar agora | Evita complexidade/schema não utilizado; risco de precisar migração retroativa se a necessidade aparecer depois | N/A — decisão consciente de adiar até necessidade real, documentada no `spec.md` | Mantenedor (aprovação em conversa) |
