# Comandos Nimbus Code (/nc-*) e Esquadrão Multiagente (NC-*)

## Objetivo

Documentar a arquitetura canônica de comandos `/nc-*`, o esquadrão multiagente
**NC-*** e a matriz de equivalência com o motor base do Spec Kit / SDD
(Spec-Driven Development), estabelecendo a convenção oficial do ecossistema
**NIMBUS CODE™**.

---

## Visão Geral da Camada Nimbus Code

O **NIMBUS CODE™** estrutura o ciclo completo de entrega de software em 4
camadas integradas através de um esquadrão de **15 agentes especializados** e
seus respectivos comandos/skills (`/nc-*`).

Cada comando `/nc-*` adiciona governança institucional, checagem de isolamento
de sessão, gates de segurança e rastreabilidade sobre as primitivas do Spec Kit:

1. **Camada 0 — Ideação & Viabilidade (Nimbus Discovery - Assessment)**
2. **Camada 1 — Descoberta & Especificação Funcional (Nimbus Discovery - SDD)**
3. **Camada 2 — Arquitetura, Design & Estratégia de Testes (Nimbus Build - Design & QA)**
4. **Camada 3 — Construção Autônoma, Convergência & Observabilidade (Nimbus Build & Grow)**

---

## Matriz Canônica de Equivalência: Agentes, Comandos e Artefatos

| Camada | Agente Nimbus | Comando Oficial | Comando Base Spec Kit | Artefato Principal | Papel & Responsabilidade |
|---|---|---|---|---|---|
| **0. Ideação** | `NC-Assess-Intake` | `/nc-assess-intake` | `/speckit-assess-intake` | `.specify/assessments/<slug>/intake.md` | Captura e normalização de ideias brutas (texto, URL, tickets). |
| **0. Ideação** | `NC-Assess-Research` | `/nc-assess-research` | `/speckit-assess-research` | `.specify/assessments/<slug>/research.md` | Pesquisa de mercado, concorrentes, dados e evidências. |
| **0. Ideação** | `NC-Assess-Define` | `/nc-assess-define` | `/speckit-assess-define` | `.specify/assessments/<slug>/problem.md` | Definição formal do problema, público impactado e metas SMART. |
| **0. Ideação** | `NC-Assess-Shape` | `/nc-assess-shape` | `/speckit-assess-shape` | `.specify/assessments/<slug>/concept.md` | Modelagem conceitual, opções de solução, apetite e trade-offs. |
| **0. Ideação** | `NC-Assess-Decide` | `/nc-assess-decide` | `/speckit-assess-decide` | `.specify/assessments/<slug>/decision.md` | Gate formal de viabilidade (Go / Clarify / Kill) e handoff para SDD. |
| **1. Descoberta** | `NC-Intake` | `/nc-intake` | `/speckit-interview` | `specs/<feature>/interview.md` | Entrevista de descoberta nos 4 blocos (Negócio, Infra, Segurança, LGPD). |
| **1. Descoberta** | `NC-Spec` | `/nc-spec` | `/speckit-specify` | `specs/<feature>/spec.md` | Especificação funcional SMART, User Stories e cenários BDD. |
| **1. Descoberta** | `NC-Critic` | `/nc-critic` | `/speckit-clarify` | `specs/<feature>/spec.md` | Auditoria de ambiguidades, termos vagos e lacunas de requisitos. |
| **1. Descoberta** | `NC-Governor` | `/nc-governor` | `/speckit-constitution` | `.specify/memory/constitution.md` | Governança corporativa, integridade criptográfica SHA-256 e RACI. |
| **2. Design & QA** | `NC-Arch` | `/nc-arch` | `/speckit-plan` | `specs/<feature>/plan.md` + `graph.yaml`/`graph.md` | Arquitetura técnica, registro de ADRs, reuso e grafos de dependência. |
| **2. Design & QA** | `NC-Shield` | `/nc-shield` | `/speckit-analyze` | `specs/<feature>/plan.md` (Security Gate) | DevSecOps, auditoria dos 6 Controles Não-Negociáveis e compliance. |
| **2. Design & QA** | `NC-Designer` | `/nc-designer` | *(Diretrizes UI/UX)* | `specs/<feature>/design-guidelines.md` + `ui-ux-audit.md` | Interface de alto padrão, design system e eliminação de clichês de IA. |
| **2. Design & QA** | `NC-QA` | `/nc-qa` | `/speckit-tasks` + `/speckit-checklist` | `specs/<feature>/tasks.md` + `checklists/` | Estratégia de testes, checklist de validação e tasks ordenadas com `[P]`. |
| **3. Build & Grow** | `NC-Builder` | `/nc-builder` | `/speckit-implement` + `/speckit-converge` | Código em `src/`, suíte de testes e PR | Implementação autônoma TDD sob isolamento estrito de sessão. |
| **3. Build & Grow** | `NC-Telemetry` | `/nc-telemetry` | *(FinOps & SRE)* | `.specify/execution-log.jsonl` + relatórios | Observabilidade, logs JSON, OpenTelemetry, DORA e custo real. |

---

## Transição e Compatibilidade

### Histórico de Notação
Versões anteriores usavam a notação pontuada `nimbus.<fase>` (ex.: `nimbus.discovery`, `nimbus.backlog`, etc.). Esta notação foi **descontinuada e substituída** pela convenção oficial `/nc-*` e pelos 15 agentes `NC-*`.

### Regras de Interoperabilidade
- **Interoperabilidade Total**: Os comandos fundamentais do Spec Kit (`/speckit-*` ou comandos CLI nativos) continuam 100% suportados e interoperáveis.
- **Camada Oficial Nimbus**: Recomenda-se o uso prioritário dos comandos `/nc-*` e dos agentes especializados `NC-*`, pois eles aplicam automaticamente:
  - Cabeçalho de sessão e classificação de complexidade (S0–S4).
  - Verificação de isolamento estrito de branch e escopo de arquivos.
  - Consulta obrigatória ao catálogo de reuso (`docs/reuse-catalog.yaml`), harness e playbooks.
  - Validação dos 6 Controles Não-Negociáveis de segurança e integridade criptográfica.
