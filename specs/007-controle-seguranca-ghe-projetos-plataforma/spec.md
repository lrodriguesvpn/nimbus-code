# Feature Specification: Documentação de Controle de Segurança no GHE para Projetos e Projeto Plataforma

**Feature Branch**: `007-controle-seguranca-ghe-projetos-plataforma`

**Created**: 2026-08-19

**Status**: Draft

**Input**: User description: "/scpekit-specify Criar documentacao para Controle de Seguranca no GHE para controle dos projetos e projeto plataforma."

---

## Clarifications

### Session 2026-08-19

- Q: O objetivo desta feature é produzir apenas a documentação (guia manual de configuração), ou ela também deve incluir/gerar automação (scripts, GitHub Actions, rulesets) que aplique os controles descritos? → A: Documentação + automação (scripts/workflows que aplicam ou validam os controles automaticamente)
- Q: Quando um controle automatizado detectar um repositório fora de conformidade, a automação deve corrigir automaticamente ou apenas reportar o desvio para correção manual? → A: Apenas detectar e reportar (gera issue/relatório; correção é manual, seguindo o fluxo já existente)
- Q: Com que frequência/gatilho a automação de detecção deve rodar nos repositórios de projeto e no Projeto Plataforma? → A: Agendamento automático semanal, com relatório consolidado mensal
- Q: Qual deve ser o escopo de repositórios cobertos pela automação: todos os repositórios da organização, apenas os que seguem o fluxo Nimbus Code, ou uma lista explícita configurável? → A: Todos os repositórios da organização automaticamente (descoberta via API, sem lista manual)
- Q: Que tipo de credencial a automação de varredura org-wide deve usar para acessar todos os repositórios da organização? → A: GitHub App dedicado, instalado na organização, com permissões somente-leitura mínimas necessárias

### Session 2026-09-22 (issue #450 — endurecimento de governança de PR e segurança)

- Q: Quais branches devem ser protegidas? → A: branch padrão, branches de produção, `release/*`, `hotfix/*` e demais branches principais configuráveis — parametrizadas por repositório em `.github/security-governance.json` (sem assumir que todos os repositórios têm as mesmas branches).
- Q: Rulesets ou proteção clássica? → A: Repository/Organization Rulesets preferencialmente; proteção clássica aceita apenas por compatibilidade e sempre identificada como tal na evidência.
- Q: Qual a cobertura mínima? → A: 80% global e 80% no código alterado (quando a ferramenta suportar), sem redução sem exceção aprovada; repositórios shell/documentação sem ferramenta aplicável declaram `not-applicable` com justificativa e usam a suíte de testes como gate — nenhuma métrica é inventada.
- Q: A varredura pode auto-remediar ou ganhar permissões de escrita? → A: Não. Continua detectar-e-reportar; o GitHub App permanece somente leitura (permissões adicionais apenas read-only) e a escrita de issues usa o `GITHUB_TOKEN` do workflow no repositório de relatório.
- Q: O rollout org-wide pode ser habilitado junto? → A: Não. O gate humano S4 (T038) continua obrigatório; o flag `security.baseline_scan.org_wide_enabled` não é alterado.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Definir baseline de segurança para repositórios de projeto (Priority: P1)

Como **administrador da organização no GHE**, quero uma documentação única com os controles mínimos obrigatórios para os repositórios de projeto, para que todos os times adotem o mesmo padrão de segurança.

**Why this priority**: Sem baseline única, cada projeto aplica controles diferentes e cria risco de compliance e acesso indevido.

**Independent Test**: Revisar apenas a seção de baseline e validar que um admin consegue aplicar os controles em um repositório novo sem depender de outros documentos.

**Acceptance Scenarios**:

1. **Given** um repositório novo no GHE, **When** sigo a documentação, **Then** consigo configurar branch protection, regras de revisão, secrets e permissões mínimas de Actions.
2. **Given** um repositório já existente, **When** comparo com o checklist da documentação, **Then** identifico rapidamente quais controles estão ausentes.

---

### User Story 2 — Definir governança de segurança para o Projeto Plataforma (Priority: P1)

Como **responsável pela plataforma**, quero documentação específica para o Project V2 de plataforma (visão consolidada), para que o acesso, automações e tokens do board sejam controlados com menor privilégio.

**Why this priority**: O projeto de plataforma concentra informação de múltiplos repositórios e requer governança reforçada.

**Independent Test**: Revisar a seção do Projeto Plataforma e validar que um mantenedor consegue configurar os acessos e segredos necessários sem superprivilégios.

**Acceptance Scenarios**:

1. **Given** o Project V2 de plataforma já criado, **When** aplico os controles documentados, **Then** apenas papéis autorizados conseguem administrar views/campos críticos.
2. **Given** workflows que escrevem no board, **When** sigo a documentação de tokens, **Then** consigo usar PAT com escopo mínimo e rotação definida.

---

### User Story 3 — Padronizar auditoria e operação contínua (Priority: P2)

Como **time de engenharia e governança**, quero uma rotina de auditoria periódica documentada, para que desvios de segurança sejam detectados e corrigidos continuamente.

**Why this priority**: A configuração inicial não é suficiente; sem auditoria recorrente os controles degradam ao longo do tempo.

**Independent Test**: Executar o checklist de auditoria mensal documentado e validar que ele gera evidências objetivas de conformidade.

**Acceptance Scenarios**:

1. **Given** a documentação publicada, **When** um time executa a auditoria mensal, **Then** ele produz um relatório com status de cada controle (ok, pendente, risco).
2. **Given** um desvio identificado, **When** sigo o fluxo de tratamento descrito, **Then** o desvio vira issue rastreável com prioridade e responsável.

---

### User Story 4 — Exigir proteção de branches, checks obrigatórios e segurança de código em todo PR (Priority: P1)

Como **responsável de plataforma/segurança**, quero que branches principais sejam protegidas por Rulesets e que todo Pull Request exija build, testes, cobertura, SAST (CodeQL), SCA (Dependency Review) e verificação de secrets como required status checks, e que a varredura semanal detecte quando isso não estiver configurado, para que nenhum código vulnerável, sem teste ou com secret exposto chegue às branches protegidas.

**Why this priority**: Baseline de repositório sem checks obrigatórios e sem SAST/SCA/secret scanning permite merge de código inseguro mesmo com revisão humana (issue #450).

**Independent Test**: Aplicar a configuração versionada em um repositório piloto, abrir um PR com falha proposital (teste quebrado, dependência vulnerável, secret fictício) e confirmar que o merge é bloqueado; rodar a varredura em dry-run e confirmar evidência dos 18 controles de repositório.

**Acceptance Scenarios**:

1. **Given** a configuração `.github/security-governance.json` de um repositório, **When** a varredura roda, **Then** a branch padrão, as branches de produção e os padrões `release/*`/`hotfix/*` são avaliados (Rulesets e proteção clássica) com evidência contendo repositório, branch/padrão, endpoint e resultado.
2. **Given** um PR para uma branch protegida, **When** um check obrigatório falha, não executa, a cobertura mínima não é atingida, o relatório de cobertura não é publicado, o CodeQL encontra alerta high/critical, o Dependency Review detecta dependência vulnerável/proibida ou há tentativa de introdução de secret, **Then** o merge fica bloqueado.
3. **Given** um repositório sem CodeQL, Dependabot, Dependency Review, Secret Scanning ou Push Protection, **When** a varredura roda, **Then** cada ausência gera finding `risco`/`pendente` rastreável — e APIs indisponíveis no plano ou 403 por permissão são reportadas explicitamente, nunca como `ok`.
4. **Given** uma exceção necessária a um controle, **When** ela é registrada, **Then** contém responsável, justificativa, aprovador, prazo e data de expiração, e passa a bloquear PRs quando vencida.

---

### Edge Cases

- Repositório sem permissões administrativas para aplicar branch protection no momento da auditoria.
- Projeto sem suporte completo a recursos de segurança por limitação de plano/instância GHE.
- Workflow de automação dependente de token expirado ou secret ausente.
- Time com múltiplos projetos vinculados ao mesmo Project V2 de plataforma com níveis de sensibilidade diferentes.
- Repositório com branches diferentes do padrão (sem `release/*`, com `develop`, branch padrão diferente de `main`) — resolvido pela configuração por repositório.
- Padrão protegido (`release/*`) sem nenhuma branch existente — sem Ruleset cobrindo o padrão é `pendente` (branches futuras nasceriam desprotegidas).
- Instância/plano sem Rulesets, Code Scanning, Secret Scanning ou Dependency Review — reportado como `pendente` com a limitação; 403 por permissão insuficiente do App é erro explícito.
- Repositório sem linguagem com ferramenta de cobertura (shell/documentação) — `coverage.mode = not-applicable` justificado, testes como gate.
- Required check com filtro de `paths` que nunca é reportado — proibido nos workflows de checks obrigatórios.

## Requirements *(mandatory)*

### Functional Requirements

> **Saneamento documental (2026-09-20):** removidas as repetições textuais de
> FR-002/003/004/005, preservando seus IDs e vínculos. As duas formulações
> anteriormente identificadas como SC-003 foram consolidadas no mesmo ID,
> mantendo tanto a auditoria mensal quanto a varredura semanal/relatório mensal.
> Isso não aprova requisitos, checklist ou rollout. As revisões
> [#450](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code/issues/450)
> e [#60/T038](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code/issues/60)
> estavam abertas na consulta desta data; aprovação S4, ADR-0008 aceito e
> evidência do piloto continuam dependências humanas.

- **FR-001**: A documentação DEVE listar os controles obrigatórios de segurança para repositórios de projeto no GHE (acesso, branch protection, revisão, Actions, secrets).
- **FR-002**: A documentação DEVE separar claramente controles para nível de repositório e controles para o Projeto Plataforma (Project V2 consolidado).
- **FR-003**: A documentação DEVE definir modelo de acesso por papéis (owner/admin/maintainer/contributor/leitor) com princípio de menor privilégio.
- **FR-004**: A documentação DEVE definir padrão para uso de tokens e secrets de automação (escopo mínimo, rotação, armazenamento e revogação).
- **FR-005**: A documentação DEVE incluir checklist operacional de auditoria periódica com critérios objetivos de conformidade.
- **FR-001a**: A feature DEVE entregar automação (scripts e/ou GitHub Actions) que detecta e reporta (não corrige automaticamente) os controles documentados nos repositórios de projeto e no Projeto Plataforma, gerando issue/relatório rastreável para correção manual seguindo o fluxo existente.
- **FR-004a**: A automação de varredura organizacional DEVE autenticar-se via GitHub App dedicado instalado na organização, com permissões somente-leitura mínimas necessárias (least privilege), em vez de PAT de usuário ou credenciais de escopo amplo.
- **FR-005a**: A automação DEVE executar a varredura de conformidade em agendamento semanal (cron) para repositórios de projeto e Projeto Plataforma, e DEVE consolidar os resultados em um relatório mensal.
- **FR-005b**: A automação DEVE descobrir automaticamente todos os repositórios da organização via API do GHE (sem depender de lista manual configurada) para determinar o escopo de varredura.
- **FR-006**: A documentação DEVE incluir procedimento de resposta para não conformidades (registro, prioridade, responsável, prazo e validação de correção).
- **FR-007**: A documentação DEVE referenciar o fluxo Nimbus Code já existente para governança (labels, board e gates) sem criar processo paralelo.
- **FR-008**: A documentação DEVE explicitar dependências mínimas para workflows que interagem com Projects (permissões e secrets obrigatórios).
- **FR-009** *(issue #450)*: A documentação e a automação DEVEM exigir e validar proteção da branch padrão, das branches de produção, de `release/*`, de `hotfix/*` e de demais branches principais configuráveis — preferencialmente via Repository Rulesets, com proteção clássica explicitamente marcada como compatibilidade — com PR obrigatório, ≥ 1 aprovador, CODEOWNERS quando aplicável, dismiss de aprovações obsoletas, proibição de push direto/force push/exclusão, status checks obrigatórios, branch atualizada e resolução de comentários quando suportados, e merge queue quando adotada. Branches, padrões, branches de produção e checks obrigatórios DEVEM ser parametrizáveis por configuração versionada (`.github/security-governance.json`).
- **FR-010** *(issue #450)*: Todo PR para branch protegida DEVE exigir, como required status checks publicados pelo GitHub Actions com nomes estáveis, no mínimo: build, testes unitários, testes de integração (quando existentes), cobertura, CodeQL/SAST, Dependency Review/SCA e verificação de secrets; checks dependentes de linguagem DEVEM ser declarados de forma extensível, e nenhum check fictício pode ser criado.
- **FR-011** *(issue #450)*: A política de cobertura DEVE exigir 80% global e 80% no código alterado (quando a ferramenta suportar), proibir redução sem exceção aprovada, publicar o relatório como artefato/check e falhar quando o limite não for atingido ou o relatório não for publicado; repositórios sem ferramenta aplicável DEVEM declarar o comportamento explicitamente e usar os testes como gate.
- **FR-012** *(issue #450)*: DEVE existir workflow CodeQL com Actions oficiais fixadas (sem `@latest`), permissões mínimas, execução em PR, na branch padrão e semanal, publicação no Code Scanning e bloqueio de findings high/critical conforme política documentada.
- **FR-013** *(issue #450)*: DEVEM ser documentados/habilitados Dependabot alerts, Dependabot security updates, Dependabot version updates (quando aplicável) e Dependency Review Action em todo PR com severidade mínima configurável, política de licenças e de dependências proibidas, publicado como required check, sem PATs/secrets desnecessários.
- **FR-014** *(issue #450)*: A documentação DEVE diferenciar secrets usados por workflows (GitHub/Environment Secrets, ambientes protegidos, owner, rotação, revogação, OIDC, `permissions:` mínimas) de secrets expostos no código (Secret Scanning, Push Protection, tratamento de alertas, revogação/rotação, exceções); o controle `secrets-configured` continua significando apenas a existência de Actions secrets.
- **FR-015** *(issue #450)*: A varredura DEVE detectar e reportar, sem auto-remediação e preservando findings/issues idempotentes, status `ok`/`pendente`/`risco`, relatório mensal e dry-run, os controles `branch-protection-default`, `branch-protection-required-patterns`, `rulesets-configured`, `required-review`, `required-pr-checks`, `required-test-checks`, `required-coverage-check`, `codeql-enabled`, `codeql-recent`, `codeql-alerts`, `dependabot-alerts-enabled`, `dependabot-security-updates-enabled`, `dependency-review-enabled`, `secret-scanning-enabled`, `secret-scanning-push-protection-enabled`, `secret-alerts`, `actions-permissions` e `secrets-configured`.
- **FR-016** *(issue #450)*: API indisponível na instância/plano DEVE resultar em `pendente` explícito e 403 por permissão insuficiente em erro explícito; nenhuma ausência de controle pode ser mascarada como sucesso.
- **FR-017** *(issue #450)*: O GitHub App da varredura DEVE permanecer somente leitura; permissões adicionais (Code scanning alerts, Dependabot alerts, Secret scanning alerts, Organization Projects) DEVEM ser read-only e documentadas no ADR-0008.
- **FR-018** *(issue #450)*: A documentação DEVE definir SLA de tratamento por severidade, processo de exceções (responsável, justificativa, aprovador, prazo e expiração), evidências para auditoria, pré-requisitos de plano/licença e procedimento de piloto/validação.

### Key Entities *(include if feature involves data)*

- **Controle de Segurança**: Política ou configuração obrigatória no GHE (ex.: proteção de branch, revisão obrigatória, secret management).
- **Projeto de Repositório**: Repositório individual do time, com backlog e automações próprias.
- **Projeto Plataforma**: Project V2 consolidado que agrega visibilidade de vários repositórios.
- **Perfil de Acesso**: Papel de usuário/grupo com permissões delimitadas para repositório e projeto.
- **Evidência de Auditoria**: Registro verificável do estado de conformidade de um controle.
- **Política de Branch** *(issue #450)*: Conjunto de branches/padrões protegidos e regras exigidas (Ruleset ou proteção clássica de compatibilidade), parametrizado em `.github/security-governance.json`.
- **Required Check** *(issue #450)*: Status check publicado pelo GitHub Actions com nome estável e exigido para merge (categoria: build, testes, cobertura, SAST, SCA, secrets, governança).
- **Exception Record** *(issue #450)*: Exceção aprovada e expirável a um controle, versionada em `.github/security-exceptions.json`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% dos novos repositórios conseguem aplicar o baseline de segurança usando apenas esta documentação.
- **SC-002**: O Projeto Plataforma passa a operar com matriz de permissões documentada e sem concessão de acesso administrativo fora da matriz aprovada.
- **SC-003**: Pelo menos 1 auditoria mensal é executada com checklist completo e evidência registrada para cada projeto ativo; a automação executa a varredura semanalmente sem falha e gera um relatório consolidado mensal com evidência registrada para cada projeto ativo.
- **SC-004**: Reduzir em pelo menos 80% a ocorrência de falhas operacionais por secret/token ausente em workflows de governança de Projects.
- **SC-005** *(issue #450)*: 100% dos repositórios do piloto com a branch padrão e os padrões protegidos cobertos por Ruleset e com os required checks da matriz configurados, evidenciados pela varredura semanal.
- **SC-006** *(issue #450)*: 0 alertas abertos de CodeQL critical/high e de secret scanning fora do SLA no piloto após o primeiro ciclo mensal.
- **SC-007** *(issue #450)*: Nenhum finding reportado como `ok` quando a API/permissão correspondente estiver indisponível (verificado por testes automatizados e revisão do relatório do piloto).

## Assumptions

- A organização possui permissões de administração necessárias no GHE para configurar os controles descritos.
- Os repositórios usam o fluxo Nimbus Code e seus workflows padrão de governança.
- O Projeto Plataforma já existe ou será criado com scripts oficiais do template.
- O processo de auditoria será executado por responsável de plataforma com apoio dos times de projeto.
