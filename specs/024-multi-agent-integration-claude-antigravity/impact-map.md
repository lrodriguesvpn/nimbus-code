# impact-map.md — Feature 024: Multi-Agent Integration (Claude Code + Antigravity)

> Obrigatório para S3/S4. Atualizar se a implementação divergir do plano.

---

## 1. Módulos Impactados

| Módulo | Tipo de impacto | Risco | Mitigação |
|---|---|---|---|
| `scripts/sync-nc-agents-to-integrations.sh` (novo) | Cria o gerador que lê `.github/skills/nc-*/SKILL.md` e emite cópias transformadas | Médio — se o script falhar silenciosamente, os agentes NC-* ficam fora de sincronia entre integrações | Teste de paridade (bats) roda tanto localmente quanto no CI, bloqueante |
| `.claude/skills/` (novo, gerado) | Recebe os 12 comandos `/speckit-*` (via `specify` CLI) + 9 agentes `/nc-*` (via script novo) | Baixo — Claude é `multi_install_safe: true` | Nenhuma ação especial além do teste de paridade |
| `.agents/skills/` (novo, gerado) | Recebe os 12 comandos `/speckit-*` (via `specify` CLI) + 9 agentes `/nc-*` (via script novo) | **Alto** — Antigravity não é `multi_install_safe`; exige CLI `v1.20.5+` | Validação obrigatória em worktree git isolado antes de promover à branch principal (ver Security Gate do `plan.md`) |
| `.github/skills/nc-*/SKILL.md` (existente) | Somente leitura — fonte única de verdade, não modificada por esta feature | Baixo | Nenhuma escrita nesta pasta faz parte do escopo; qualquer PR que altere estes arquivos deve rodar o gerador antes de commitar |
| `tests/multi-agent-integration/nc-agents-parity.bats` (novo) | Gate de paridade entre as 3 pastas de skills | Baixo | Cobre os 6 ACs da spec.md; roda em CI |
| `.github/workflows/nc-agents-parity-check.yml` (novo) | CI gate bloqueante em todo PR | Baixo | Segue o mesmo padrão de workflows já existentes (`validate-agent-contracts.yml` da SPEC 008) |
| `docs/developer-guide.md` | Nova seção "Agentes disponíveis por integração" | Baixo | Apenas adição de seção, sem reescrever conteúdo Copilot existente |

---

## 2. Análise de Risco

### R001 — Instalação do Antigravity corrompe artefatos de Claude/Copilot já commitados (Alto)

**Cenário**: `specify integration install agy` é executado diretamente na branch
principal e, por não ser `multi_install_safe`, sobrescreve ou corrompe arquivos
de `.claude/skills/` ou `.github/skills/` que já estavam funcionais.

**Probabilidade**: Média (o próprio CLI já sinaliza a falta de garantia via
warning, mas não bloqueia a execução).

**Impacto**: regressão nas integrações Copilot/Claude já em uso pelo time,
quebrando o fluxo de trabalho diário até o revert.

**Mitigação**:
1. Executar `specify integration install agy` primeiro em um `git worktree`
   isolado (fora da branch principal desta sessão).
2. Validar manualmente que nenhum arquivo de `.claude/` ou `.github/skills/`
   foi alterado pela instalação isolada.
3. Confirmar a versão do CLI `specify` (`v1.20.5+`) antes de prosseguir.
4. Só então replicar a instalação (ou os artefatos gerados) na branch principal.

**Plano de rollback**: `git revert` do commit que trouxe os artefatos do
Antigravity — como a mudança está isolada em `.agents/`, o revert não afeta
`.claude/` nem `.github/skills/`.

---

### R002 — Agentes NC-* ficam fora de sincronia entre as 3 integrações (Médio)

**Cenário**: um dev edita `.github/skills/nc-*/SKILL.md` diretamente (ex.: para
corrigir um bug de instrução) e esquece de rodar o script gerador antes de
abrir o PR — `.claude/skills/` e `.agents/skills/` ficam desatualizados.

**Probabilidade**: Média — é um passo manual adicional ao fluxo de edição já
existente.

**Impacto**: comportamento divergente do agente NC-* dependendo de qual
integração (Copilot vs Claude vs Antigravity) o dev estiver usando —
inconsistência de governança institucional.

**Mitigação**:
1. Gate de paridade (AC-5, `nc-agents-parity.bats`) bloqueante no CI — nenhum
   PR que altere `.github/skills/nc-*` sem rodar o gerador passa no check.
2. Mensagem de erro do teste aponta exatamente qual agente/destino está
   desatualizado, reduzindo o tempo de correção.

**Plano de rollback**: não aplicável — o próprio gate impede que o problema
chegue à branch principal; se escapar, rodar o gerador novamente resolve sem
necessidade de revert.

---

### R003 — Escopo expande silenciosamente para outras integrações (Baixo)

**Cenário**: durante a implementação, o agente (ou um dev futuro) decide também
portar os artefatos para outra integração não solicitada (ex.: Cursor,
Windsurf), interpretando o script gerador como "genérico o suficiente para
qualquer integração".

**Probabilidade**: Baixa — mitigado preventivamente no planejamento (ver
Harness Gate do `plan.md`, HRN-0001).

**Impacto**: escopo maior que o aprovado pelo usuário, tempo/tokens gastos fora
do combinado, possível PR mais difícil de revisar.

**Mitigação**:
1. `spec.md` e `plan.md` desta feature travam explicitamente o escopo a
   Claude Code e Antigravity.
2. Qualquer extensão para outra integração exige nova spec/pedido explícito do
   usuário — não é decisão unilateral do agente.

**Plano de rollback**: reverter os artefatos da integração fora de escopo, se
introduzidos por engano; manter apenas Claude/Antigravity nesta feature.

---

## 3. Plano de Rollback Global

Se a feature introduzir uma regressão em qualquer integração:

```bash
git revert <commit-hash-da-feature>
```

Arquivos seguros para reversão total ou parcial (isolados por pasta, sem
dependência cruzada):
- `.claude/skills/` (reversão não afeta `.agents/` nem `.github/skills/`)
- `.agents/skills/` (reversão não afeta `.claude/` nem `.github/skills/`)
- `scripts/sync-nc-agents-to-integrations.sh`
- `tests/multi-agent-integration/nc-agents-parity.bats`
- `.github/workflows/nc-agents-parity-check.yml`
- `docs/developer-guide.md` (seção nova, isolada)

Arquivo que **não** deve ser tocado por este rollback:
- `.github/skills/nc-*/SKILL.md` — fonte única de verdade, somente lida por
  esta feature; não é criada nem modificada por ela, então não há o que
  reverter aqui.

---

## 4. Critérios de Go / No-Go

### Go

- Os 12 comandos `/speckit-*` e os 9 agentes `/nc-*` existem em `.claude/skills/`
  com conteúdo funcional equivalente ao Copilot (AC-1, AC-2)
- A instalação do Antigravity foi validada em worktree isolado antes de ir para
  a branch principal, sem alterar `.claude/` ou `.github/skills/` (AC-3, AC-4)
- O gate de paridade (`nc-agents-parity.bats`) está verde e bloqueante no CI (AC-5)
- `docs/developer-guide.md` documenta as 3 integrações e o risco diferencial
  Claude vs Antigravity (AC-6)

### No-Go

- Antigravity foi instalado direto na branch principal sem validação isolada prévia
- Qualquer arquivo de `.github/skills/nc-*` foi modificado por esta feature
  (deveria permanecer fonte única, somente lida)
- O gate de paridade não é bloqueante (permite merge com pastas fora de sincronia)
- Escopo expandiu para integrações não solicitadas pelo usuário (Cursor,
  Windsurf, etc.) sem novo pedido explícito
