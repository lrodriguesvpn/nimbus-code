# Evidence Matrix — 017-nimbus-digital-engineer-platform

## Rastreabilidade AC → FR/SC → Evidência

| AC | FR relacionados | SC relacionados | Artefato de validação | Evidência esperada |
|---|---|---|---|---|
| AC-1 | FR-001 | SC-001 | `contracts/intake-entry.contract.yaml` + `quickstart.md` | Intake consolidado com metadados obrigatórios |
| AC-2 | FR-002, FR-009 | SC-002, SC-005 | `mode-policy.md` + `contracts/mode-classification.contract.yaml` | Modo selecionado com justificativa versionada |
| AC-3 | FR-003, FR-004 | SC-002 | `approval-sla.md` + `data-model.md` | Gate bloqueado sem decisão válida |
| AC-4 | FR-005, FR-006 | SC-004 | `contracts/delivery-handoff.contract.yaml` + `plan.md` | Handoff com qualidade + custo IA/humano |
| AC-5 | FR-009 | SC-005 | `mode-policy.md` + `plan.md` | Toggle via OpenFeature com kill switch |
| AC-6 | FR-008 | SC-006 | `data-model.md` + `quickstart.md` | Badges por domínio com critérios auditáveis |

## Evidências por User Story

### US1 — Intake corporativo
- AC principal: AC-1
- Evidências:
  - Contrato de intake com campos mandatórios, regra de deduplicação e status de bloqueio.
  - Cenário de quickstart cobrindo reunião + SharePoint + consolidação.

### US2 — Modos governados
- AC principal: AC-2
- Evidências:
  - Política de classificação por risco/criticidade/compliance.
  - Contrato de saída com `selected_mode`, `justification` e `policy_version`.
  - Regra de precedência para sinais conflitantes.

### US3 — Aprovação RACI
- AC principal: AC-3
- Evidências:
  - Gates mandatórios por etapa com papel aprovador.
  - SLA por criticidade com timeout e escalonamento.
  - Transições de estado `pending -> go/no_go` com bloqueio explícito.

### US4 — Custo e qualidade no handoff
- AC principal: AC-4
- Evidências:
  - Contrato de handoff com evidências de qualidade/aceite.
  - Regras de custo híbrido e ownership de pendências.

### US5 — Badges por domínio
- AC principal: AC-6
- Evidências:
  - Taxonomia de badges (domínio/nível/status).
  - Critérios mínimos de elegibilidade e evidência.
  - Workflow de governança de publicação/depreciação.

