# Implementation Plan: CMDB↔IaC — Vínculo e Critério de Repositório Dedicado por Projeto

**Branch**: `027-cliente-plataforma-cmdb-iac` | **Data**: 2026-09-22 | **Spec**: [spec.md](./spec.md)

**Entrada**: Especificação da feature em [spec.md](./spec.md), com handoff do assessment
`.specify/assessments/cliente-plataforma-operacional/` (decision.md — veredito Go, Option B).

## Summary

Formalizar, no modelo de dados de **referência** deste template
(`platform-governance/`), o vínculo CMDB↔IaC entre um projeto/ativo de cliente e
(a) um repositório de IaC dedicado externo, ou (b) um registro de inventário com
IaC inline — aplicando o critério objetivo binário decidido na auditoria
`/nc-critic` (repo dedicado **somente** quando o contrato do cliente exigir
isolamento formal). Inclui a criação do ADR nomeado "Repo First Company"
(`docs/adr/0011-repo-first-company.md`), referenciando `vpn-nibo-connect` /
`vpn-nibo-connect-iac` como caso real já em produção.

**Achado crítico de arquitetura (bloqueia parte do escopo nesta sessão):** esta
feature é **inerentemente cross-repo**. O modelo de dados/lógica (User Stories 3
e 5) pode ser implementado neste template, que é o **modelo de referência**
(achado corrigido do Round 2 do assessment). Porém, a **aplicação real** desse
modelo — registrar entradas de vínculo de projetos reais, migrar
`venha-pra-nuvem-client-platform` para o novo esquema, e onboardar um segundo
cliente piloto (User Stories 1, 2 e 4) — só pode ocorrer dentro do repositório
`venha-pra-nuvem/venha-pra-nuvem-client-platform`, que **não está presente
neste workspace** e não é acessível por esta sessão. Ver "Architecture Decision
Log" para o registro formal desta divisão de escopo (protocolo HRN-0002: nunca
assumir silenciosamente que o escopo cross-repo será resolvido "de algum jeito"
dentro desta sessão).

**Reuso declarado (catálogo)**: `multirepo-bounded-context-routing` (padrão
1 Repo Central + N repos satélite, `specs/006-multirepo-support/plan.md`) e
`greenfield-multirepo-governance-baseline` (`specs/020-satellite-repo-governance/plan.md`)
— ambos reaproveitados por analogia para desenhar a relação Repo Plataforma
central ↔ repositórios de IaC dedicados, mesmo não sendo o mesmo tipo de
bounded context (aqui é infraestrutura de cliente, não código de produto).

**Playbook de Sucesso Gate**: SUC-0002 (contract-first / staged rollout) —
reaplicado ao sequenciar User Stories por prioridade (P1: vínculo dedicado e
inline → P2: critério consistente e segunda instância → P3: ADR), documentando
o contrato (spec + AC) antes de qualquer código, exatamente como recomendado.

## Technical Context

**Language/Version**: JavaScript (Node.js, CommonJS) — consistente com
`platform-governance/package.json` (`"type": "commonjs"`).

**Primary Dependencies**: Nenhuma nova dependência de runtime identificada;
reaproveita a camada de domínio já existente (`src/domain/cmdb-consolidation-service.js`,
`src/domain/asset-relationship-service.js`) e o `src/cli/main.js`.

**Storage**: SQL (mesmo motor das migrations existentes em `db/migrations/`,
`001_initial.sql`–`004_dsc_profiles.sql`); esta feature adiciona
`005_iac_link_model.sql`.

**Testing**: `node --test`, seguindo a estrutura `tests/{contract,integration,e2e,performance}/`
já usada pelas migrations 001–004.

**Target Platform**: Mesmo runtime do `platform-governance/` (Node.js server-side,
`src/api/server.js`); nenhuma superfície nova de execução.

**Project Type**: Extensão de biblioteca/serviço de domínio existente (não é um
projeto novo).

**Performance Goals**: Herdados do SLO já declarado no cabeçalho do `spec.md`
(p99 2000 ms, erro ≤0,5%, disponibilidade 99,9% para consulta/registro de
vínculo no Repo Plataforma central).

**Constraints**: O sistema MUST NOT duplicar conteúdo Terraform (FR-003) — a
implementação é estritamente referência/ponteiro, nunca cópia de arquivo.

**Scale/Scope**: Escopo desta feature, dentro deste repositório, é o **modelo
de referência** (schema + lógica de decisão + ADR). A aplicação a clientes reais
(2 pilotos) está fora do alcance físico desta sessão — ver achado crítico acima.

## Constitution Check

*GATE: Deve passar antes da Fase 0 de pesquisa. Reverificar após o desenho da Fase 1.*

| Princípio da Constituição | Aplicável? | Conformidade nesta feature |
|---|---|---|
| Segurança e Dados — nenhum segredo em texto plano | Sim | FR-014 já restringe o registro a metadados (nome de repo, cliente, projeto, timestamp); nenhuma credencial é armazenada no CMDB |
| SSO obrigatório para sistema novo (greenfield) | Não aplicável | Esta feature estende um sistema já existente (`platform-governance/`), que já opera sob o modelo de autenticação herdado da instância real (`venha-pra-nuvem-client-platform`, JWT/Entra ID); não introduz sistema novo com autenticação própria |
| IaC — Terraform como padrão, sem exceção não justificada | Sim | Esta feature não cria nem altera infraestrutura cloud diretamente — ela **governa referências** a repositórios de IaC já em Terraform (ex.: `vpn-nibo-connect-iac`); nenhuma exceção de provider é introduzida |
| Least privilege / IAM | Não aplicável nesta fase | Nenhum novo papel de IAM cloud é criado; FR-012 define aprovador humano do CMDB (papel organizacional, não IAM de nuvem) |
| Grafos de Módulos obrigatórios | Sim | `graph.yaml`/`graph.md` desta feature criados nesta etapa (ver seção Module Dependency Graph) |
| Escala de Complexidade S0–S4 | Sim | S3 confirmado (ver Classificação de Complexidade) |

**Resultado**: Gate passa sem violação que exija entrada na tabela de
Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/027-cliente-plataforma-cmdb-iac/
├── plan.md              # Este arquivo
├── graph.yaml            # Grafo de módulos (fonte de verdade estruturada)
├── graph.md               # Diagramas Mermaid (por código e por business)
├── impact-map.md          # Obrigatório para S3 — análise de risco e rollback
└── tasks.md                # Fase 2 — NÃO criado nesta etapa (usuário pediu para parar no planejamento)
```

### Código (raiz do repositório)

```text
platform-governance/
├── db/
│   └── migrations/
│       └── 005_iac_link_model.sql        # NOVO — tabelas iac_link_entry,
│                                           # inline_inventory_entry, link_decision_criteria
├── src/
│   ├── domain/
│   │   ├── cmdb-consolidation-service.js  # ESTENDER — nova lógica de vínculo
│   │   └── link-decision-service.js       # NOVO — aplica o critério objetivo
│   │                                       # binário (FR-005) e registra a decisão
│   ├── governance/
│   │   └── (sem alteração nesta feature — terraform-advisory-validator.js
│   │        já cobre a validação de plans; não duplica papel aqui)
│   └── cli/
│       └── main.js                         # ESTENDER — novos subcomandos de
│                                            # consulta (FR-006) e registro (FR-001/002)
├── tests/
│   ├── contract/  → contrato de dados de IaCLinkEntry/InlineInventoryEntry
│   ├── integration/ → AC-1 a AC-3 (vínculo, duplicidade, critério consistente)
│   └── e2e/        → AC-4 (segunda instância) fica marcado como manual/documental
│                       nesta feature — ver Rastreabilidade AC → Teste
└── docs/
    └── (referenciado pelo ADR, sem duplicar conteúdo)

docs/
└── adr/
    └── 0011-repo-first-company.md          # NOVO — ADR nomeado (FR-010, AC-5)
```

**Structure Decision**: Extensão in-place do módulo de domínio já existente em
`platform-governance/`, sem criar novo serviço/projeto. A numeração de migration
segue a sequência já estabelecida (001–004 existentes → 005 nesta feature). O
ADR vai para `docs/adr/` deste template (raiz do repo), não para dentro de
`platform-governance/`, seguindo a convenção já usada por ADRs anteriores
(0001–0010).

**Fora desta estrutura (não implementável nesta sessão)**: qualquer alteração
ao repositório `venha-pra-nuvem/venha-pra-nuvem-client-platform` (User Stories
1, 2 e 4 aplicadas a clientes reais) — ver achado crítico no Summary e entrada
correspondente no Architecture Decision Log.

## Nimbus-Code — Classificação de Complexidade (S0–S4)

| Campo | Valor |
|---|---|
| **Nível** | **S3** (herdado do cabeçalho de `spec.md`) |
| **Justificativa** | Cruza modelo de dados, lógica de decisão, ADR nomeado e, potencialmente, um segundo repositório externo (`venha-pra-nuvem-client-platform`) fora do alcance direto desta sessão |
| **Modelo de IA** | Reasoning |
| **Revisão humana obrigatória** | Sim — S3 e a feature altera regra estrutural de onboarding de clientes de Managed Services |
| **Padrão reutilizado encontrado?** | Sim (tags: `multirepo-bounded-context-routing`, `greenfield-multirepo-governance-baseline`) |
| **Estimativa de tokens (input+output)** | ~30–45 mil tokens |

---

## Nimbus-Code — Harness Gate

| Harness consultado (ID) | Padrão de erro evitado | Mitigação preventiva aplicada nesta feature |
|---|---|---|
| HRN-0002 | Decisão arquitetural imposta silenciosamente (ex.: assumir que o escopo cross-repo "dá pra resolver" sem acesso ao repo externo) | Divisão de escopo (este repo = referência/ADR; `venha-pra-nuvem-client-platform` = aplicação real) registrada explicitamente no Summary e no ADL, em vez de assumida silenciosamente |
| HRN-0003 | Re-derivação de padrão já existente sem consultar `reuse-catalog.yaml` | Consultado antes deste plano; reaproveitados `multirepo-bounded-context-routing` e `greenfield-multirepo-governance-baseline` por analogia |
| HRN-0001 | Scope creep do agente fora do escopo explícito | O plano restringe a implementação real nesta sessão a `platform-governance/` (modelo de referência) e `docs/adr/`; nenhuma tentativa de "simular" acesso ao repo externo |

**Resultado da consulta:**
- [x] Match encontrado — padrões relevantes declarados e mitigados
- [ ] Nenhum padrão de erro relevante encontrado para este domínio
- [ ] Catálogo vazio — nenhum padrão disponível

---

## Nimbus-Code — Rastreabilidade AC → Teste → Módulo

| ID AC | Critério (resumo) | Tipo de teste planejado | Arquivo/módulo do teste | Justificativa de ausência |
|---|---|---|---|---|
| AC-1 | Vínculo a repo de IaC dedicado sem duplicar conteúdo | Contrato + integração | `tests/contract/iac-link-entry.test.js`, `tests/integration/link-dedicated.test.js` | — |
| AC-2 | Registro de inventário inline sem repo externo | Contrato + integração | `tests/contract/inline-inventory-entry.test.js`, `tests/integration/link-inline.test.js` | — |
| AC-3 | Critério objetivo aplicado de forma consistente por operadores diferentes | Integração (fixture com 2 "operadores" simulados) | `tests/integration/link-decision-criteria.test.js` | — |
| AC-4 | Segunda instância replicada com baseline medido | Documental/manual | Checklist de onboarding em `platform-governance/docs/` (a criar na Fase de implementação) | Depende de um segundo cliente real de Managed Services e do repositório externo `venha-pra-nuvem-client-platform`, fora do alcance desta sessão — não é automatizável como teste de código deste template |
| AC-5 | ADR "Repo First Company" publicado e referenciando caso real | Revisão documental | `docs/adr/0011-repo-first-company.md` | ADR é artefato documental; validação é revisão humana, não teste automatizado |

---

## Nimbus-Code — Module Dependency Graph

**Arquivos:**
- [graph.yaml](./graph.yaml) — fonte de verdade estruturada
- [graph.md](./graph.md) — diagramas Mermaid
- [impact-map.md](./impact-map.md) — obrigatório (S3)

**Checklist de manutenção do grafo:**
- [x] `graph.yaml` criado com todos os módulos desta feature
- [x] `graph.md` criado com diagrama por código e por business
- [x] `impact-map.md` criado com análise de risco e plano de rollback (S3)
- [x] Nenhum módulo novo ficou fora do grafo
- [x] Dependência externa (`venha-pra-nuvem-client-platform`) declarada explicitamente no `graph.yaml` como fora do domínio de escrita desta sessão
- [x] Grafo será atualizado novamente após `/nc-builder` se a implementação divergir do plano

### Grafo do Contexto (Multi-Repo Brownfield)

| Campo | Valor |
|---|---|
| **Bounded context** | `platform-governance` (interno a este template) |
| **Grafo do contexto** | [graph.yaml](./graph.yaml) / [graph.md](./graph.md) |
| **Dependências relevantes para esta feature** | `platform-governance/src/domain/cmdb-consolidation-service.js`, `platform-governance/db/migrations/`, `docs/adr/`, `docs/reuse-catalog.yaml` |
| **Dependência externa fora do workspace** | `venha-pra-nuvem/venha-pra-nuvem-client-platform` — repositório real da instância GSN Premium; requer sessão/acesso separado para aplicar User Stories 1, 2 e 4 em produção |
| **Padrões de harvest aplicáveis** | `multirepo-bounded-context-routing`, `greenfield-multirepo-governance-baseline` |

## Nimbus-Code — Estratégia de Release

| Campo | Valor |
|---|---|
| **Estratégia** | Rollout faseado: (1) modelo de referência + ADR neste template; (2) aplicação manual opt-in em `venha-pra-nuvem-client-platform` (fora desta sessão); (3) réplica em segundo cliente piloto |
| **Feature flag name** | Não aplicável nesta fase — mudança de schema/documentação em repositório de referência, sem runtime de produção neste template |
| **Flag provider** | N/A |
| **Critério de ativação** | Aprovação humana do plano (esta revisão) + acesso/sessão dedicada ao repo `venha-pra-nuvem-client-platform` para a fase de aplicação real |
| **Critério de remoção** | N/A (não é feature flag de produto) |
| **Critério de rollback** | Reverter migration `005_iac_link_model.sql` e o commit do ADR se a decisão de critério objetivo (FR-005) for revista antes da aplicação em produção |

## Nimbus-Code — Cost Reference

| Campo | Valor |
|---|---|
| **Token estimate range** | ~30–45 mil tokens |
| **Human effort estimate range** | ~4–8 horas (apenas modelo de referência + ADR neste repo; aplicação em clientes reais é esforço adicional fora desta estimativa) |
| **Tracking method** | Tabela "Estimativa vs. Consumo Real" em `tasks.md` (quando criado) + campo "Horas Humanas" no GitHub Project |
| **Budget ceiling (optional)** | N/A |

## Nimbus-Code — Operational Metrics Gate

| Componente | Indicador operacional | Meta inicial | Evidência |
|---|---|---:|---|
| Cobertura de CMDB (SC-001) | % de projetos com entrada de vínculo (dedicada ou inline) | 100% nos 2 clientes piloto | Consulta ao CMDB do Repo Plataforma central (fora deste template) |
| Não-duplicação de Terraform (SC-002) | % de entradas dedicadas sem cópia de conteúdo | 0% de duplicação | Auditoria manual do repositório de IaC dedicado vs. entrada no CMDB |
| Tempo de localização (SC-003) | Baseline manual (cronometragem) antes/depois | Redução mensurável, sem meta numérica fixa nesta v1 | Planilha/issue de cronometragem (FR-009) |
| Rastreabilidade (SC-004) | % de entradas com origem/autor/timestamp/justificativa | 100% | Consulta ao CMDB |
| Replicação (SC-005) | Segunda instância criada sem suporte ad-hoc | Sim/Não (binário) | Checklist de onboarding documental |
| ADR publicado (SC-006) | ADR existe e referencia caso real | Sim/Não (binário) | `docs/adr/0011-repo-first-company.md` |

**SLOs de runtime**: os já declarados no cabeçalho do `spec.md` (p99 2000 ms,
erro ≤0,5%, disponibilidade 99,9%) aplicam-se à consulta/registro no Repo
Plataforma central — mas a medição real só é possível dentro de
`venha-pra-nuvem-client-platform`, não neste template.

## Nimbus-Code — Security & DevSecOps Gate

| Domínio | Controles aplicáveis | Escapável via ADL? | Status | Observações |
|---|---|---|---|---|
| **Backup & Disaster Recovery** | Nova tabela SQL (`005_iac_link_model.sql`) entra no backup já existente do datastore de `platform-governance/` | Não — bloqueante | ✅ | Sem datastore novo, apenas nova migration no mesmo motor |
| Segredos no código/repositório | CMDB MUST NOT armazenar credenciais/segredos (FR-014) | **Não — bloqueante** | ✅ | Checklist básico v1 definido na auditoria `/nc-critic` |
| Branch/merge protegido | PR obrigatório + revisão humana antes de merge | **Não — bloqueante** | ✅ | Segue padrão já vigente do template |
| Isolamento de ambiente | Migration/lógica não depende de credenciais de cliente real | **Não — bloqueante** | ✅ | Modelo de referência é agnóstico de cliente |
| Autenticação (SSO) | Sistema já existente, sem autenticação própria nova | Sim, com justificativa no ADL | ✅ | Ver Constitution Check |
| IaC — provider(s) usado(s) | Terraform (via referência a repos externos, ex.: `vpn-nibo-connect-iac`) | Sim | ✅ N/A | Esta feature não provisiona infraestrutura; apenas referencia repos Terraform existentes |
| Banco de dados | TLS/mTLS, logs de conexão e auditoria de DDL herdados do datastore existente | **Não — bloqueante** | ✅ | Sem alteração de política; nova tabela segue política já vigente |
| LGPD / dados de cliente final | Registro contém apenas metadados técnicos, nunca PII de cliente final | **Não — bloqueante** | ✅ | Checklist básico v1 (FR-014); validação por amostragem manual |
| Aprovação de mudança (FR-012) | Aprovadores reaproveitados de `vpn-nibo-connect-iac` (ambiente `homologacao`) | Sim, com justificativa no ADL | ✅ | Decisão registrada na auditoria `/nc-critic` |
| **Mínimo privilégio / RBAC** | Nenhum papel novo de IAM cloud criado; acesso a criar/editar entradas do CMDB restrito ao papel de aprovador reaproveitado (FR-012), sem acesso amplo tipo `Owner`/`editor` | Sim, com justificativa no ADL | ✅ | Escopo desta feature não introduz superfície de acesso cloud nova — apenas metadados de aplicação, sem credenciais |
| **Destroy de IaC protegido por aprovação humana** | Não aplicável — esta feature não cria, altera nem destrói recursos de infraestrutura cloud; apenas referencia repositórios de IaC externos já existentes e já protegidos por seus próprios workflows (ex.: `vpn-nibo-connect-iac` já exige aprovação manual em `homologacao`) | Sim, com justificativa no ADL | ✅ N/A | Controle permanece de responsabilidade do repositório de IaC dedicado, não do Repo Plataforma central |

**Riscos identificados e decisão:**
- **Critério objetivo binário (só contrato) pode ser insuficiente na prática**: mitigar deixando explícito em `spec.md`/Assumptions que o critério pode ser expandido em versão futura, sem bloquear o v1.
- **Escopo cross-repo pode gerar expectativa de entrega completa nesta sessão**: mitigado por declaração explícita no Summary, Project Structure e ADL de que a aplicação real em clientes fica fora do alcance físico desta sessão.
- **`vpn-nibo-connect-infra` vs `-iac` (FR-013) não resolvido**: mitigar mantendo o ADR como rascunho até essa pendência ser esclarecida pelo time responsável, sem travar o restante da implementação.

## Nimbus-Code — Qualidade de Código, Testes e Observabilidade Gate

| Domínio | Controles aplicáveis | Status | Observações |
|---|---|---|---|
| Revisão de código por IA | Copilot Code Review solicitado em todo PR desta feature | ✅ | |
| Testes contract/integration | AC-1, AC-2, AC-3 cobertos por testes automatizados em `platform-governance/tests/` | ✅ | Segue padrão `node --test` já usado nas migrations 001–004 |
| Testes end-to-end/documentais | AC-4 e AC-5 cobertos por checklist/revisão documental, não automação de código | ⚠️ Parcial (justificado) | Dependem de repositório externo e de artefato documental (ADR) |
| Observabilidade | Consulta/registro de vínculo herda a observabilidade já existente de `platform-governance/src/observability/` | ✅ | Sem novo componente de runtime |
| Gestão de bugs | Pendência FR-013 (`-infra` vs `-iac`) tratada como item de esclarecimento, não bug — não abre issue de bug nesta feature | ✅ | Registrado como `[NEEDS CLARIFICATION]` de execução no `spec.md` |

**Critérios de aceitação sem teste de integração automatizado — justificativa:**
- AC-4 depende de um segundo cliente real de Managed Services e do repositório `venha-pra-nuvem-client-platform`, inacessível a partir deste workspace.
- AC-5 é um artefato documental (ADR); sua validação é revisão humana, não execução de código.

## Nimbus-Code — Architecture Decision Log

| Decisão | Alternativas consideradas | Opção escolhida | Trade-off assumido | Justificativa do desvio (se aplicável) | Aprovado por |
|---|---|---|---|---|---|
| Escopo de implementação cross-repo | (a) Tentar simular/assumir aplicação em `venha-pra-nuvem-client-platform` sem acesso real · (b) Implementar apenas o modelo de referência neste template e declarar o resto fora de escopo · (c) Bloquear todo o planejamento até obter acesso ao repo externo | **(b) Implementar o modelo de referência neste template; declarar aplicação real fora do alcance desta sessão** | Este repositório entrega apenas parte do valor de negócio (US1/US2/US4 não se aplicam em produção); evita risco de HRN-0002 (decisão silenciosa) | Consistente com o modelo de referência/gerador confirmado no `decision.md` do assessment — este template nunca teve, nem deveria ter, acesso de escrita direto a instâncias de cliente | Pendente (revisão do usuário nesta etapa de planejamento) |
| Critério objetivo de repo dedicado (FR-005) | (a) Combinação ponderada de porte+criticidade+contrato · (b) Binário só por exigência contratual · (c) Decisão manual caso a caso sem regra | **(b) Binário — só exigência contratual de isolamento formal** | Critério mais simples e auditável na v1, mas pode classificar como "inline" ativos tecnicamente grandes sem exigência contratual explícita | Decisão do usuário na auditoria `/nc-critic` (sessão 2026-09-22b) | Usuário (via `/nc-critic`) |
| Local do ADR "Repo First Company" | (a) Dentro de `platform-governance/docs/` · (b) `docs/adr/` na raiz deste template | **(b) `docs/adr/` na raiz**, seguindo numeração 0001–0010 já existente | Mantém um único local canônico de ADRs do template, evitando fragmentação | Consistência com convenção já estabelecida | — |
| Numeração da migration nova | (a) Novo arquivo solto fora da sequência · (b) `005_iac_link_model.sql`, continuando a sequência 001–004 | **(b) Continuar a sequência 001–004** | Nenhum | Convenção já estabelecida em `platform-governance/db/migrations/` | — |
| Pendência `vpn-nibo-connect-infra` vs `-iac` (FR-013) | (a) Bloquear o ADR até resolver · (b) Publicar o ADR como rascunho e resolver a nomenclatura depois · (c) Ignorar a pendência | **(b) Publicar como rascunho, resolver depois** | ADR pode precisar de revisão de nomenclatura pós-publicação | Decisão do usuário na auditoria `/nc-critic` — não bloquear o restante do trabalho | Usuário (via `/nc-critic`) |
| Ausência de SSO próprio (item Escapável) | (a) Introduzir autenticação própria para os novos endpoints/CLI · (b) Herdar a autenticação já existente do sistema `platform-governance/`/instância real | **(b) Herdar autenticação existente** | Nenhum — não é sistema novo | Esta feature estende um sistema já existente; não há greenfield de autenticação | Aprovado por herança da decisão original de `platform-governance/` |
| IaC provider (item Escapável) | (a) Introduzir novo provider de IaC para o Repo Plataforma central · (b) Não provisionar infraestrutura nesta feature, apenas referenciar Terraform já usado pelos repos de IaC dedicados | **(b) Não provisionar; apenas referenciar** | Nenhum | Esta feature é sobre modelo de dados/CMDB, não sobre provisionamento; Terraform continua o único provider usado onde há provisionamento real | — |
| Mínimo privilégio / RBAC (item Escapável) | (a) Definir RBAC granular novo para o CMDB nesta feature · (b) Reaproveitar o papel de aprovador já existente (FR-012), sem RBAC granular novo | **(b) Reaproveitar papel existente** | Menos granularidade de controle de acesso na v1; pode precisar de RBAC dedicado se o número de operadores crescer | Escopo desta feature é o modelo de dados de referência, não uma plataforma de administração de acessos; revisitar se necessário em versão futura | Decisão do usuário na auditoria `/nc-critic` (FR-012) |
| Destroy de IaC protegido por aprovação humana (item Escapável) | (a) Implementar controle de destroy nesta feature · (b) Não aplicável — feature não provisiona/destrói infraestrutura | **(b) Não aplicável** | Nenhum | O controle de destroy já existe e é de responsabilidade de cada repositório de IaC dedicado (ex.: `vpn-nibo-connect-iac`), não do Repo Plataforma central que apenas referencia | — |

## Complexity Tracking

> Nenhuma violação da Constitution Check identificada nesta feature — tabela
> não preenchida.

## Nimbus-Code — Governance Verdict (`/nc-governor`)

| Campo | Valor |
|---|---|
| **Auditoria de integridade — `spec.md` (SHA-256)** | `1fdafaa358c1c9a72b97014a7867e7e22be80e2d67f7279dab50269850799a43` (calculado em 2026-09-22, pós-auditoria `/nc-critic`) |
| **Classificação de complexidade confirmada** | **S3** (herdada do cabeçalho de `spec.md`; consistente com a Classificação de Complexidade deste `plan.md`) |
| **Nível de supervisão exigido** | Semiautônomo — revisão humana obrigatória antes de `/nc-qa` (tasks) e `/nc-builder` (implementação), conforme regra S3 da constituição |
| **Pendências críticas em `spec.md`?** | Não — as 5 perguntas `[NEEDS CLARIFICATION]` originais foram resolvidas na auditoria `/nc-critic`, exceto FR-013, mantida deliberadamente como pendência de execução não bloqueante (decisão explícita do usuário) |
| **Security & DevSecOps Gate** | ✅ Aprovado — 6 Controles Não-Negociáveis cobertos (2 diretamente conformes sem exceção, 2 conformes com exceção justificada, 2 marcados Escapável via ADL com justificativa e registro no ADL) |
| **Achado de escopo cross-repo** | Registrado e não bloqueante para esta fase — aplicação real em `venha-pra-nuvem-client-platform` fica explicitamente fora do alcance desta sessão (ver Summary e ADL) |
| **RACI — Responsável pela aprovação humana do plano** | Usuário/Dev (revisão solicitada nesta etapa, antes de `/nc-qa`/`/nc-builder`) |
| **RACI — Consultado** | Time responsável por `vpn-nibo-connect-iac` (para resolver FR-013 durante execução) |
| **Veredito** | ✅ **GO para os artefatos de planejamento** (`plan.md`, `graph.yaml`, `graph.md`, `impact-map.md`). Handoff para `/nc-qa` (tasks.md) e `/nc-builder` (implementação) **fica pausado por instrução explícita do usuário** — aguardando revisão humana antes de prosseguir. |

