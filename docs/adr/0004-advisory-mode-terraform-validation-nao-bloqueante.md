# 0004 — Advisory Mode para Validação de Terraform (Não-Bloqueante com Trilha de Exceção)

- **Status:** Aceita
- **Data:** 2026-08-12
- **Autores:** @nimbus-code-platform-team
- **Contexto:** feature 004 (Platform Preset CMDB + Baselines de Segurança e Compliance)
- **Revisores:** @nimbus-code-arch-board

---

## Contexto e Problema

A validação de conformidade de infraestrutura (Terraform) contra CMDB e baselines é
crítica para segurança/compliance. Porém, há tensão entre rigor e velocidade de entrega:

1. **Bloqueante (strict mode)**: qualquer desvio de policy rejeita o plano de Terraform
   - ✅ Força conformidade
   - ❌ Bloqueia releases legítimas enquanto exceção é aprovada
   - ❌ Aumenta latência de deploy (ciclo: plan → rejection → exception approval → replan)

2. **Advisory (non-blocking)**: relatório de desvios gerado, mas Terraform segue
   - ✅ Não bloqueia release
   - ✅ Auditável: relatório é artefato permanente
   - ✅ Permite exceções explícitas com trilha de aprovação
   - ❌ Risco: desvios ignorados se falta disciplina (mitigado com alertas)

No MVP, precisamos balancear conformidade com velocity de primeira entrega.

## Drivers de Decisão

- **Velocity**: MVP não pode ser bloqueado por validações (primeira feature é proof-of-concept)
- **Auditabilidade**: cada desvio deve ser registrado e rastreável (compliance requirement)
- **Flexibilidade**: exceções legítimas devem ser aprovadas sem re-work de infraestrutura
- **Escalabilidade**: transição futura para strict mode sem mudança de arquitetura
- **Transparência**: relatório de validação deve ser acessível (não oculto em logs)

## Opções Consideradas

- **Opção A** — Bloqueante (rejeita plano se houver desvios)
- **Opção B** — Advisory + trilha de exceção (relatório + aprovação assíncrona)
- **Opção C** — Desabilitado (sem validação no MVP, adicionar depois)

## Análise das Opções

### Opção A — Bloqueante (Strict Mode)

Terraform plan falha se houver conformidade issues. Requer exception approval antes de
re-plan.

- ✅ Força conformidade imediata
- ✅ Zero risco de oversight
- ❌ Bloqueia releases (aumenta lead time)
- ❌ Requer processo de exception approval durante deploy (stressful)
- ❌ Pode desincentivar uso do sistema (é "pesado" demais para MVP)

### Opção B — Advisory + Trilha de Exceção

Terraform plan sucede, mas relatório de validação é gerado. Desvios identificados 
são registrados com referência a exception (se aprovada) ou flag (se ignorado).

- ✅ Não bloqueia release (MVP velocity)
- ✅ Auditável: cada desvio tem record permanente
- ✅ Exceções explícitas (documentadas, rastreáveis)
- ✅ Transição suave para strict mode (same data, different enforcement)
- ✅ Constrói confiança gradualmente no sistema
- ❌ Risco: desvios ignorados se falta disciplina
- ❌ Requer cultura de revisão (não é automático)

### Opção C — Desabilitado

Sem validação no MVP. Validação adicionada em fase futura.

- ✅ Simplicidade imediata
- ✅ Zero overhead no deploy pipeline
- ❌ Perde conformidade data da entrega MVP
- ❌ Impossível migrar para strict mode depois sem reprocessar histórico
- ❌ Não alinha com spec AC-4 (DSC + validação contínua)

## Decisão

**Opção escolhida: Opção B (Advisory + Trilha de Exceção)**, porque:

1. **MVP Velocity**: não bloqueia primeira release
2. **Auditabilidade**: cada desvio é registrado e rastreável (compliance requirement)
3. **Escalabilidade**: mesma arquitetura suporta transição para strict mode depois
4. **Confiança**: time valida incrementalmente sem stress de bloqueios

**Corolários**:

- Terraform plan roda normalmente (não falha)
- POST-plan validation: `platform-governance validate --terraform-plan <file>`
  gera relatório JSON com `{ policy, deviations, exceptions, recommendation }`
- Relatório é artefato no PR (anexado ou comentário automático)
- Desvios podem ter exception reference (`exception-id: EXC-2026-08-12-001`)
- SLA de exception approval: <4h (para não bloquear release)
- Alertas se desvios sem exception aprovado (futuro: auto-reject em strict mode)

## Consequências

### Positivas

- MVP é entregue sem bloqueios de validação
- Auditoria completa: cada desvio tem referência ao contexto (code, policy, exception)
- Transição suave: quando strict mode ativado, mesma validação passa a rejeitar
- Time constrói confiança incremental no sistema (não é "pesado" de primeira)

### Negativas / Trade-offs Assumidos

- **Risco de oversight**: desvios pode ser ignorados (mitigado com alertas, review SLA)
- **Complexidade operacional**: exception approval process não é automático (requer
  governance board ou automation)
- **Não determina conformidade real**: desvio "reportado" ≠ "não permitido"
  (aceitável para MVP; futuro: strict mode muda isso)

### Ações derivadas

- [x] Implementar `terraform-advisory-validator.ts` com 30+ policy checks
- [x] Implementar relatório JSON + exception tracking
- [x] Adicionar endpoint POST `/terraform-validation` com request/response schema
- [ ] Criar approval flow para exceptions (JIRA/Azure DevOps integration)
- [ ] Adicionar GitHub/GitLab PR comment automation para report attachment
- [ ] Criar SLA monitoring para exception approval (< 4h target)
- [ ] Documentar exception approval process no GOVERNANCE.md
- [ ] Criar alert rule: "desvios sem exception aprovado há 24h"
- [ ] Planejar transição para strict mode (quando confidence aumenta)

## Links

- Feature spec: `specs/004-platform-cmdb-dsc-model/spec.md` (AC-4)
- Runtime validator: `platform-governance/src/governance/terraform-advisory-validator.ts`
- API route: `platform-governance/src/api/routes/terraform-validation.ts`
- Tests: `tests/e2e/terraform-advisory.test.ts`
- Related: ADR-0002 (Preset + Runtime)
