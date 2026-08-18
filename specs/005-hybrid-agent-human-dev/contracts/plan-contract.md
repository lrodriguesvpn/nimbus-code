# Contract: plan.md Output Format

**Target Audience**: Tech Lead + Architecture Board  
**Enforced by**: `/speckit-plan` skill + gates validation

---

## Mandatory Sections

Toda plan.md gerada deve conter:

1. **Summary** — uma frase + status (Planning/In Progress/Done)

2. **Technical Context**
   - Architecture Overview
   - Dependencies
   - Technology Choices (com justificativa)

3. **Constitution Check** — tabela de princípios vs. status

4. **Nimbus-Code — Classificação de Complexidade**
   - Nível (S0–S4), Justificativa, Modelo de IA, Revisão humana?, Padrão reutilizado?, Estimativa tokens

5. **Nimbus-Code — Rastreabilidade AC → Teste → Módulo**
   - Tabela: AC-ID → Tipo teste → Arquivo/módulo

6. **Nimbus-Code — Module Dependency Graph**
   - Links a graph.yaml, graph.md, impact-map.md (S3+)

7. **Nimbus-Code — Estratégia de Release**
   - Estratégia (flag/canary/direct), flag name, provider, critérios
   - Provider padrão deve ser declarado sob abstração OpenFeature

8. **Nimbus-Code — Plano de Toggle (se flag)**
   - Tabela: flag key, tipo, owner, ambientes, default, segmentos, rollout, kill switch

9. **Phase 0: Research & Clarifications** — consolidar findings (ou "nenhuma")

10. **Phase 1: Design & Contracts**
    - Data Model section
    - Contracts section (referências)
    - Quickstart section

11. **Nimbus-Code — Cost Reference (SPEC KIT COST)**
    - URL obrigatória: https://github.com/venha-pra-nuvem/spec-kit-cost
    - Faixa estimada de tokens e horas humanas
    - Método de rastreio do custo real

12. **Security & DevSecOps Gate** — tabela de itens críticos

13. **Quality Gate** — tabela de cobertura e SLO

14. **Architecture Decision Log** — ADRs key

15. **Next Steps** — checklist de readiness para /speckit-tasks

---

## Validation Rules

### Completeness

- [ ] Todos os 15 sections acima estão presentes
- [ ] Summary tem status (Planning/In Progress/Done)
- [ ] Technical Context descreve system holistically
- [ ] Constitution Check cobre todos os itens obrigatórios do constitution.md
- [ ] Todos os gates têm status (✓ Pass / ⚠️ Deviation / ❌ Violation)

### Quality

- [ ] Nenhuma violação não-justificada de Constitution
- [ ] Estimativa de tokens tem faixa (ex.: ~45–65k, não "~50k" exato)
- [ ] Complexity Level é S0–S4 (não vago)
- [ ] Release strategy tem rollback critério definido
- [ ] AC → Test mapping cobre 100% dos AC da spec (nenhuma lacuna)

### Hybrid Collaboration Elements

- [ ] **Nova regra**: Classificação de Complexidade menciona impacto no fluxo de templates/skills
- [ ] **Nova regra**: Release strategy explica como ativar gradualmente para projetos piloto
- [ ] **Nova regra**: Phase 1 Design menciona "Hybrid Collaboration Model" entity
- [ ] **Nova regra**: Quickstart inclui validação de "humano consegue executar task sem contexto extra"
- [ ] **Nova regra**: Plans com contexto WEB declaram Impeccable como padrão de design
- [ ] **Nova regra**: Plans com estratégia de flag declaram OpenFeature como padrão de abstração
- [ ] **Nova regra**: Plan inclui bloco de Cost Reference com URL do SPEC KIT COST

---

## Example: Rastreabilidade AC → Test

**PASS**:
| ID AC | Critério (resumo) | Tipo de teste | Arquivo/módulo |
|---|---|---|---|
| AC-1 | Orientação híbrida na spec | integração | `.specify/presets/nimbus-code-standards/templates/spec-template.md` |
| AC-2 | Tasks no GHE com passos operacionais | integração | `.github/skills/speckit-tasks/SKILL.md` |
| AC-3 | Referência SPEC KIT COST presente | integração | `.specify/presets/nimbus-code-standards/templates/plan-template.md` |
| AC-4 | Padrão Impeccable em contexto WEB | integração | `.specify/presets/nimbus-code-standards/templates/spec-template.md` |
| AC-5 | Padrão OpenFeature para toggles | integração | `.specify/presets/nimbus-code-standards/templates/plan-template.md` |

**FAIL**:
| ID AC | Critério (resumo) | Tipo de teste | Arquivo/módulo |
|---|---|---|---|
| AC-1 | Orientação híbrida na spec | N/A | N/A |

[ PROBLEMA: Sem justificativa de ausência; AC-1 é testável ]

---

## Contract Enforcement

1. **Gate Validation** (automático): `/speckit-plan` skill valida estrutura e gates
2. **Architecture Review** (humano): Architecture Board revisa ADL e design decisions
3. **Code Review** (humano): Tech Lead aprova antes de merge

Violações bloqueiam procedimento para `/speckit-tasks`.
