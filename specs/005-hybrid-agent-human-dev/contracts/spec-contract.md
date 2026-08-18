# Contract: spec.md Output Format

**Target Audience**: Agente + Humano (tech lead)  
**Enforced by**: `/speckit-specify` skill + linter em CI/CD

---

## Mandatory Sections

Toda spec.md gerada deve conter, nesta ordem:

1. **Nimbus-Code — Cabeçalho Obrigatório da Spec**
   - Tabela com campos: feature slug, complexidade estimada, bounded context, PR de referência/Issue, data alvo
   - NÃO opcional

2. **Nimbus-Code — SLO Alvo desta Feature**
   - Tabela com: componente, latência p99, taxa de erro, disponibilidade, RTO, RPO
   - Obrigatório se feature envolve novo componente; vazio (—) justificado se não

3. **Nimbus-Code — Objetivo e Contexto**
   - Parágrafos: Objetivo, Motivação, Critério de done
   - Linguagem de negócio (não técnica)
   - Deve incluir padrões explícitos quando aplicável (ex.: Impeccable para contexto WEB)

4. **Nimbus-Code — Critérios de Aceitação (BDD)**
   - Formato: Given/When/Then para cada AC
   - IDs: AC-1, AC-2, etc.
   - Test ref: `test_AC<N>_<descricao>` (preenchido em plan.md)

5. **User Scenarios & Testing**
   - User Stories com prioridade (P1, P2, P3)
   - Cada story: independentemente testável
   - Acceptance Scenarios em BDD (Given/When/Then)
   - Edge Cases seção

6. **Requirements**
   - Functional Requirements (FR-001, FR-002, ...)
   - Key Entities (se houver dados)

7. **Success Criteria**
   - Measurable Outcomes (SC-001, SC-002, ...)
   - Tecnology-agnostic

8. **Assumptions**
   - Informed guesses documentadas

---

## Validation Rules

### Content Quality

- [ ] Nenhuma linguagem técnica (Java, Python, API, database, etc.) em seções de objetivo/motivação
- [ ] Nenhuma implementação detalhada (não falar de endpoints, classes, schemas)
- [ ] Escritas para stakeholders não-técnicos (onde aplicável)
- [ ] Todos os campos obrigatórios preenchidos (não deixar como template)

### Requirement Completeness

- [ ] Nenhum `[NEEDS CLARIFICATION]` marker (ou máximo 3, documentado em plan.md)
- [ ] Requirements são testáveis (cada um tem critério de sucesso verificável)
- [ ] Success Criteria são mensuráveis (métrica, percentual, tempo, etc.)
- [ ] Cada AC tem ID único (AC-N)
- [ ] AC está no formato Given/When/Then

### Hybrid Collaboration

- [ ] **Nova regra**: Seção de Objetivo/Contexto menciona explicitamente "colaboração entre agente e humano" ou "modelo híbrido"
- [ ] **Nova regra**: SLO table preenchida (mesmo que parcialmente) para comunicar expectativa de performance
- [ ] **Nova regra**: Assumptions menciona pelo menos um ponto sobre divisão de trabalho ou revisão humana
- [ ] **Nova regra**: Features com contexto WEB mencionam explicitamente Impeccable como padrão de design
- [ ] **Nova regra**: Features com rollout progressivo mencionam OpenFeature como padrão de abstração de toggle

### Rastreabilidade

- [ ] Cada AC tem id único que será referenciado em test ref (test_AC<N>_...)
- [ ] User Stories têm prioridade (P1, P2, P3)

---

## Example Validation

**PASS**:
```markdown
## Objetivo

Tornar o fluxo de desenvolvimento **explícito para operação híbrida** entre agentes de IA e humanos.
```

**FAIL** (falta menção clara de colaboração):
```markdown
## Objetivo

Implementar suporte a templates melhorados.
```

**PASS**:
```markdown
## Assumptions

- Agente (IA) preenche especificação inicial e plano de design
- Tech Lead (humano) revisa e aprova antes de execução
- Implementação é feita por desenvolvedor humano assistido por agente
```

**FAIL** (assumptions não clara):
```markdown
## Assumptions

- Padrão Nimbus-Code será seguido
```

---

## Contract Activation

Este contrato é validado por:
1. `speckit-specify` skill (durante `/speckit-specify`)
2. Linter automático em CI/CD (GitHub Action que checa estrutura)
3. Code review manual (tech lead valida antes de merge)

Violações bloqueiam merge em `develop`.
