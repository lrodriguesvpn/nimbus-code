## Nimbus-Code — Cabeçalho Obrigatório da Spec

*Preencher ANTES dos critérios de aceitação. Alimenta o plan.md, o graph.yaml e
a seleção de modelo do agente.*

| Campo | Valor |
|---|---|
| **Feature slug** | `multi-agent-integration-claude-antigravity` |
| **Complexidade estimada** | S3 *(cruza múltiplos artefatos institucionais — preset, bootstrap, docs, testes; não envolve dado sensível/segurança crítica)* |
| **Bounded Context** | `spec-kit-workflow` |
| **PR de referência / Issue** | novo |
| **Data alvo de entrega** | sem data |

> S0 = doc · S1 = função isolada · S2 = módulo · S3 = múltiplos módulos ·
> S4 = arquitetura, segurança, dados ou integração crítica

## Nimbus-Code — SLO Alvo desta Feature

*Preencher para componentes novos ou alterados. Alimenta o Observability Gate do
plan.md — alertas serão configurados com base nesses valores.*

| Componente | Latência p99 (ms) | Taxa de erro máx. (%) | Disponibilidade alvo | RTO | RPO |
|---|---|---|---|---|---|
| Gerador de sync de agentes (script) | — | 0% (falha bloqueia CI) | — | — | — |
| Workflow de detecção de drift entre integrações | — | 0% (falha bloqueia CI) | — | — | — |

> Componentes são scripts/CI locais, sem SLA de runtime contratual — latência/disponibilidade não se aplicam; a taxa de erro máxima é enforced via testes bloqueantes.

## Nimbus-Code — Objetivo e Contexto

**Objetivo:** Permitir que o Nimbus Code seja operado também via **Claude Code** e **Antigravity**, além do Copilot já suportado — trazendo (1) os 12 comandos agnósticos `/speckit-*` (via `specify integration install`) e (2) os 9 agentes institucionais `/nc-*` (via um mecanismo de geração/sincronização novo, já que eles não são gerenciados pelo `specify` CLI), sem remover ou degradar o suporte já existente ao Copilot.

**Motivação:** O time quer flexibilidade para escolher o agente de IA (Copilot, Claude Code ou Antigravity) sem perder nenhuma capacidade institucional do Nimbus Code (os 9 agentes NC-* e seus gates de governança). Hoje essa capacidade existe apenas para Copilot Skills (`.github/skills/`). Investigação técnica confirmou que os três agentes usam o mesmo formato de arquivo (`SKILL.md`), mudando apenas a pasta raiz (`.github/skills/`, `.claude/skills/`, `.agents/skills/`) e um pequeno pós-processamento por integração — o que torna viável um único gerador com múltiplos alvos, em vez de reescrever conteúdo por agente.

**Critério de done (alto nível):** Um dev consegue rodar qualquer um dos 12 comandos `/speckit-*` e qualquer um dos 9 agentes `/nc-*` a partir do Claude Code ou do Antigravity, com o mesmo comportamento e gates de governança do Copilot; um teste automatizado impede que as três pastas fiquem fora de sincronia; a instalação de Claude/Antigravity não modifica nenhum arquivo já gerenciado pelo Copilot.

## Nimbus-Code — Hybrid Collaboration Model

| Papel | Responsabilidades | Critério de handoff | Escalação |
|---|---|---|---|
| Agente | Rodar `specify integration install` para Claude/Antigravity; implementar o script gerador dos 9 agentes NC-*; criar testes de paridade e drift; atualizar `docs/developer-guide.md` | Após instalar cada integração e antes de trazer o Antigravity para a branch principal (não é `multi_install_safe`) — pedir validação humana explícita | Dev responsável pelo template |
| Humano | Validar em ambiente isolado (worktree) que a instalação do Antigravity não corrompe artefatos existentes; aprovar a versão final do CLI do Antigravity (`v1.20.5+`) antes do rollout; decidir se o suporte a Antigravity entra já nesta spec ou fica como fase 2 opcional | Após teste isolado do Antigravity, decide se segue para a branch principal ou aborta essa parte do escopo | Tech lead |

## Nimbus-Code — Critérios de Aceitação (formato BDD)

> **AC-1**
> **Given** o repositório já tem a integração Copilot instalada e funcional
> **When** o dev roda `specify integration install claude`
> **Then** os 12 comandos `/speckit-*` passam a existir em `.claude/skills/`, com o mesmo conteúdo funcional do Copilot, e nenhum arquivo de `.github/skills/` é alterado
> **Test ref:** `test_AC1_claude_speckit_commands_installed`

> **AC-2**
> **Given** os 9 agentes `/nc-*` existem hoje apenas em `.github/skills/`
> **When** o gerador de sync de agentes NC-* é executado com destino Claude Code
> **Then** os 9 agentes passam a existir em `.claude/skills/nc-*/SKILL.md` com o mesmo conteúdo institucional (incl. blocos de ALIAS e reforços de governança), mais o `argument-hint` exigido pelo padrão do Claude
> **Test ref:** `test_AC2_nc_agents_synced_to_claude`

> **AC-3**
> **Given** o Antigravity exige CLI `v1.20.5+` e não é `multi_install_safe`
> **When** o dev roda `specify integration install agy` em um worktree isolado
> **Then** o processo emite aviso claro sobre a versão mínima exigida, os 12 comandos `/speckit-*` são instalados em `.agents/skills/`, e nenhum arquivo do Copilot/Claude é alterado; a promoção para a branch principal só ocorre após validação humana explícita
> **Test ref:** `test_AC3_agy_isolated_install_validated`

> **AC-4**
> **Given** os 9 agentes `/nc-*` também precisam existir no Antigravity
> **When** o gerador de sync de agentes NC-* é executado com destino Antigravity
> **Then** os 9 agentes passam a existir em `.agents/skills/nc-*/SKILL.md`, com a nota de conversão de `.` para `-` em nomes de comando de hook aplicada corretamente (mesmo padrão usado pelos 12 comandos `/speckit-*` no Antigravity)
> **Test ref:** `test_AC4_nc_agents_synced_to_agy`

> **AC-5**
> **Given** as três pastas (`.github/skills/`, `.claude/skills/`, `.agents/skills/`) devem sempre conter os mesmos 9 agentes NC-* em conteúdo equivalente
> **When** um dev edita um `SKILL.md` de agente NC-* apenas em `.github/skills/` e tenta abrir PR/rodar CI sem rodar o gerador de sync
> **Then** um teste de paridade (bats) falha de forma bloqueante, apontando exatamente qual agente e qual destino está desatualizado
> **Test ref:** `test_AC5_nc_agents_parity_gate`

> **AC-6**
> **Given** `docs/developer-guide.md` hoje só documenta o fluxo Copilot
> **When** a spec é implementada
> **Then** o manual do dev passa a ter uma seção "Agentes disponíveis por integração", listando os 12 comandos e os 9 agentes NC-* para as três integrações suportadas, e a diferença de risco entre Claude (`multi_install_safe: yes`) e Antigravity (`multi_install_safe: no`)
> **Test ref:** `test_AC6_developer_guide_documents_integrations`

> *(Mínimo: 1 critério por feature — 6 fornecidos.)*

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Dev usa Claude Code com paridade total ao Copilot (Priority: P1)

Um dev que prefere trabalhar com Claude Code quer usar o Nimbus Code sem abrir mão de nenhum recurso institucional (comandos `/speckit-*` e agentes `/nc-*`).

**Why this priority**: Claude é `multi_install_safe`, de menor risco, e representa o caso de uso mais imediato e mais solicitado.

**Independent Test**: Rodar `specify integration install claude` em um clone do template, confirmar que os 12 comandos e os 9 agentes NC-* aparecem em `.claude/skills/`, e que `specify integration status` reporta o Copilot intocado.

**Acceptance Scenarios**:

1. **Given** o template com Copilot instalado, **When** o dev instala a integração Claude, **Then** os 12 comandos `/speckit-*` funcionam em Claude Code sem alterar nada do Copilot.
2. **Given** o gerador de sync de agentes NC-* já implementado, **When** o dev roda esse gerador com destino Claude, **Then** os 9 agentes `/nc-*` aparecem em `.claude/skills/` com o mesmo comportamento institucional (ALIAS, gates, reforços de governança).

---

### User Story 2 - Dev avalia Antigravity de forma isolada e segura (Priority: P2)

Um dev quer avaliar o Antigravity sem risco de corromper a configuração já existente do Copilot/Claude, dado que essa integração não é `multi_install_safe`.

**Why this priority**: Antigravity tem maior risco técnico (exige CLI `v1.20.5+`, não é multi-install-safe) — precisa de um caminho de validação isolado antes de qualquer rollout.

**Independent Test**: Rodar `specify integration install agy` em um worktree isolado (não na branch principal), confirmar aviso de versão mínima, e confirmar que arquivos de outras integrações não mudam.

**Acceptance Scenarios**:

1. **Given** um worktree isolado do template, **When** o dev instala a integração Antigravity, **Then** os 12 comandos e os 9 agentes NC-* aparecem em `.agents/skills/`, com aviso sobre a versão mínima exigida do CLI.
2. **Given** o teste isolado bem-sucedido, **When** um humano aprova explicitamente, **Then** a integração pode ser promovida para a branch principal do template.

---

### User Story 3 - CI impede drift entre as três integrações (Priority: P3)

O time quer garantir que, uma vez os 9 agentes NC-* portados para as três integrações, nenhuma edição futura fique desalinhada entre elas.

**Why this priority**: Sem esse gate, o esforço de portabilidade se degrada com o tempo (mesmo problema já resolvido para drift de preset na SPEC 020).

**Independent Test**: Editar um `SKILL.md` de agente NC-* só em uma das três pastas e confirmar que o teste de paridade falha, apontando exatamente o agente/destino divergente.

**Acceptance Scenarios**:

1. **Given** as três pastas sincronizadas, **When** um `SKILL.md` de agente NC-* é editado em apenas uma pasta, **Then** o teste de paridade falha de forma bloqueante no CI.
2. **Given** o gerador de sync é executado após a edição, **When** o teste de paridade roda novamente, **Then** ele passa.

---

### Edge Cases

- O que acontece se o dev já tiver o Antigravity `< v1.20.5` instalado? O processo deve avisar claramente e não prosseguir silenciosamente com um layout incompatível.
- Como o sistema lida com um agente NC-* que referencia hooks (ex.: `nc-intake`, `nc-spec`) ao sincronizar para o Antigravity, que exige a nota de conversão `.` → `-`? O gerador deve aplicar essa transformação automaticamente, igual ao que o `specify` já faz para os comandos `/speckit-*`.
- O que acontece se alguém rodar `specify integration install agy` diretamente na branch principal, sem isolar em worktree? Deve haver aviso explícito na documentação recomendando o caminho isolado primeiro, mas o comando em si não deve ser bloqueado tecnicamente (decisão de processo, não de ferramenta).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema MUST permitir instalar a integração Claude Code (`specify integration install claude`) sem alterar nenhum arquivo hoje gerenciado pela integração Copilot.
- **FR-002**: O sistema MUST permitir instalar a integração Antigravity (`specify integration install agy`) sem alterar nenhum arquivo hoje gerenciado pelas integrações Copilot ou Claude.
- **FR-003**: O sistema MUST fornecer um script gerador que produza, a partir de uma fonte única (`.github/skills/nc-*/SKILL.md`), cópias equivalentes em `.claude/skills/nc-*/SKILL.md` e `.agents/skills/nc-*/SKILL.md`, aplicando o pós-processamento específico de cada integração (argument-hint no Claude; nota de conversão `.`→`-` em comandos de hook no Antigravity).
- **FR-004**: O sistema MUST fornecer um teste automatizado (bats) que falhe de forma bloqueante caso as três pastas de agentes NC-* fiquem fora de sincronia.
- **FR-005**: O sistema MUST documentar em `docs/developer-guide.md` quais comandos/agentes estão disponíveis em cada integração e a diferença de risco de instalação entre Claude (`multi_install_safe: yes`) e Antigravity (`multi_install_safe: no`).
- **FR-006**: O sistema MUST exigir validação humana explícita antes de promover a integração Antigravity de um ambiente isolado (worktree) para a branch principal do template.
- **FR-007**: O sistema MUST manter a integração Copilot como padrão (`default_integration`) inalterado, a menos que o dev decida explicitamente trocar via `specify integration use`.

### Key Entities

- **Agente NC-* (SKILL.md)**: representa um agente institucional do Nimbus Code (ex.: NC-Builder, NC-Shield); hoje existe só para Copilot; passa a ter cópias sincronizadas para Claude e Antigravity.
- **Integração (specify integration)**: representa um agente de IA suportado pelo `specify` CLI (Copilot, Claude Code, Antigravity), com atributos próprios (`multi_install_safe`, pasta raiz, pós-processamento).
- **Gerador de sync de agentes NC-***: script novo responsável por manter as três pastas de agentes NC-* equivalentes entre si.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Um dev consegue instalar a integração Claude Code e usar qualquer um dos 12 comandos + 9 agentes institucionais em menos de 10 minutos, sem etapas manuais além dos comandos documentados.
- **SC-002**: 100% dos 9 agentes NC-* estão disponíveis, com paridade de comportamento, nas três integrações (Copilot, Claude, Antigravity) após a implementação.
- **SC-003**: Zero incidentes de arquivos de uma integração sendo sobrescritos/corrompidos pela instalação de outra, validado por teste automatizado antes de qualquer merge.
- **SC-004**: 100% das tentativas de editar um agente NC-* em apenas uma das três pastas são detectadas pelo gate de paridade antes de chegar à branch principal.

## Assumptions

- O CLI do `specify` já suporta oficialmente as integrações `claude` e `agy` na versão atualmente usada pelo template (confirmado via `specify integration list`/`info` nesta investigação).
- O suporte ao Antigravity pode ficar como fase opcional/posterior dentro desta mesma spec, a critério do Dev, dado o risco adicional (`multi_install_safe: no`, exigência de CLI `v1.20.5+`) — não bloqueia a entrega do suporte a Claude Code.
- Não há necessidade de portar os agentes NC-* para o formato nativo de "subagents" do Claude Code (`.claude/agents/`) nesta spec — o formato `SKILL.md` já usado pelo Copilot é suficiente e é o que o `specify` CLI também usa para Claude/Antigravity.
- Esta spec não cobre a sincronização de outras integrações além de Copilot/Claude/Antigravity (ex.: Gemini, Cursor) — pode ser avaliado em spec futura se houver demanda.
