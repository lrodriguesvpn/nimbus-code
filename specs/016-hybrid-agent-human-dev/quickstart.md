# Quickstart Validation Guide

**Feature**: Hybrid Agent-Human Delivery Templates  
**Purpose**: End-to-end validation that templates work for hybrid execution model

---

## Prerequisites

- [ ] Git e GitHub CLI (`gh`) instalados
- [ ] Acesso a dois projetos piloto (internos, onde testar)
- [ ] Permissão de push em branch `develop` dos projetos piloto
- [ ] Acesso ao repositório [nimbus-code-spec-kit-template](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template)

---

## E2E Validation Scenario

### Step 1: Bootstrap Projeto Piloto

**Command**:
```bash
# Criar novo projeto piloto
mkdir ~/nimbus-pilot-hybrid
cd ~/nimbus-pilot-hybrid
git init
git remote add origin https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/test-hybrid-templates.git
git pull origin main

# Ou, se reutilizando projeto existente:
cd ~/existing-nimbus-project
git checkout -b test/hybrid-validation
```

**Expected**: Projeto inicializado com estrutura Nimbus-Code padrão (`.specify/`, presets, templates).

---

### Step 2: Inicializar Feature com novo Spec Template

**Command**:
```bash
cd ~/nimbus-pilot-hybrid
/speckit-specify "Validar que novo template de spec inclui cabeçalho de colaboração híbrida e compila corretamente."
```

**Expected Output**:
- Nova pasta `specs/005-hybrid-collaboration-test/spec.md` criada
- Spec contém seção "Nimbus-Code — Cabeçalho Obrigatório da Spec" com campos:
  - Feature slug
  - Complexidade estimada (S0–S4)
  - Bounded Context
  - SLO (se novo componente)
- Spec contém "Nimbus-Code — Objetivo e Contexto" com menção clara de "colaboração híbrida"
- Em contexto WEB, spec menciona Impeccable como padrão de design

**Validation Checklist**:
- [ ] spec.md existe e é válido Markdown
- [ ] Cabeçalho obrigatório está presente
- [ ] Objetivo menciona "colaboração" ou "híbrido"
- [ ] Contexto WEB inclui Impeccable como padrão de design

---

### Step 3: Executar Plan com novo Plan Template

**Command**:
```bash
cd ~/nimbus-pilot-hybrid
/speckit-plan
```

**Expected Output**:
- Nova pasta `specs/005-hybrid-collaboration-test/plan.md` preenchida
- Plan contém seção "Nimbus-Code — Classificação de Complexidade" com:
  - Nível (S0–S4)
  - Justificativa
  - Estimativa de tokens (faixa)
  - Modelo de IA selecionado
- Plan contém "Nimbus-Code — Rastreabilidade AC → Teste → Módulo"
- Plan contém "Nimbus-Code — Module Dependency Graph" com referências a `graph.yaml`, `graph.md`
- Plan contém seção "Release Strategy" com flag, rollback criteria
- Plan contém seção de toggle padronizada com OpenFeature como abstração

**Validation Checklist**:
- [ ] plan.md existe e é válido Markdown
- [ ] Classificação de Complexidade preenchida
- [ ] Estimativa de tokens tem faixa (ex.: ~10–15k)
- [ ] Rastreabilidade AC → Teste > 0 entradas
- [ ] Release strategy declara estratégia (flag/direct/canary)
- [ ] Toggle standard referencia OpenFeature

---

### Step 4: Validar que Artefatos de Design Foram Gerados

**Command**:
```bash
ls -la specs/005-hybrid-collaboration-test/
```

**Expected Files**:
- `spec.md` ✓
- `plan.md` ✓
- `research.md` (Phase 0 findings)
- `data-model.md` (entidades esperadas)
- `contracts/spec-contract.md`
- `contracts/task-contract.md`
- `contracts/plan-contract.md`
- `quickstart.md` (você está aqui)
- `graph.yaml` (estrutura de dependências)
- `graph.md` (diagramas Mermaid)
- `impact-map.md` (análise de risco para S3+)
- `checklists/requirements.md` (checklist de qualidade)

**Validation Checklist**:
- [ ] Todos os 11+ arquivos existem
- [ ] Nenhum arquivo vazio (> 100 bytes cada)

---

### Step 5: Gerar Tasks com novo Task Template

**Command**:
```bash
cd ~/nimbus-pilot-hybrid
/speckit-tasks
```

**Expected Output**:
- Novo arquivo `specs/005-hybrid-collaboration-test/tasks.md` criado
- Cada task contém estrutura:
  - ID (task-001, task-002, ...)
  - Objective (claro e acionável)
  - Context (informação necessária)
  - Acceptance Criteria (verificável)
  - Operational Steps (se assigned_to = humano)
  - Dependencies (se houver bloqueadores)
  - Assigned To (agente vs. humano)
  - Effort Estimate (tokens ou horas)
- Tasks publicadas como Issues no GHE com labels `feature:005`, `task:hybrid-validation`

**Validation Checklist**:
- [ ] tasks.md existe
- [ ] Mínimo 3 tasks geradas
- [ ] Cada task tem "Objective" (não vago)
- [ ] Tasks com "Assigned To = humano" têm "Operational Steps" detalhados
- [ ] Issues criadas no GHE com estrutura esperada

---

### Step 6: Validar Clareza para Execução Humana

**Scenario**: Dev humano recebe uma task isolada (sem contexto adicional além do que está na issue do GHE).

**Test**:
1. Escolher uma task aleatória do GHE
2. Ler apenas o conteúdo da issue (sem navegar para spec/plan/research)
3. Responder: "Consigo executar essa task completamente usando apenas o que está escrito?"

**Expected Answers**:
- ✓ Sim — "Objective, Context, Acceptance Criteria e Operational Steps são claros"
- ✓ Sim (com referência) — "Sim, mas precisei de X do plan.md; está linkado na issue"

**Failure Case**:
- ✗ Não — "Falta contexto X, ou steps são vago

---

### Step 7: Validar Referência ao SPEC KIT COST

**Command**:
```bash
grep -r "spec-kit-cost" specs/005-hybrid-collaboration-test/
```

**Expected**:
- Presença da URL https://github.com/venha-pra-nuvem/spec-kit-cost em:
  - `plan.md` (seção CostReferenceBlock ou "Phase 1: Design")
  - `data-model.md` (entidade CostReferenceBlock)
  - Pelo menos 1 task no GHE (campo "Referência")

**Validation Checklist**:
- [ ] URL presente em plan.md
- [ ] URL presente em data-model.md
- [ ] URL presente em pelo menos 1 issue GHE
- [ ] URL retorna HTTP 200 (acessível)

---

### Step 7.1: Validar Padrões Impeccable e OpenFeature

**Command**:
```bash
grep -r "Impeccable\|OpenFeature" specs/005-hybrid-collaboration-test/
```

**Expected**:
- Referência a Impeccable em `spec.md` (quando contexto WEB)
- Referência a OpenFeature em `plan.md` nas seções de release/toggle

**Validation Checklist**:
- [ ] Impeccable presente em spec WEB
- [ ] OpenFeature presente em plan com rollout

---

### Step 8: Validar Gates e Completeness

**Command**:
```bash
# Checar Constitution Check
grep -A 5 "Constitution Check" specs/005-hybrid-collaboration-test/plan.md

# Checar Complexity Classification
grep -A 10 "Classificação de Complexidade" specs/005-hybrid-collaboration-test/plan.md

# Checar Security & DevSecOps Gate
grep -A 20 "Security & DevSecOps Gate" specs/005-hybrid-collaboration-test/plan.md
```

**Expected**:
- Constitution Check: todos os itens com status ✓ Pass ou ⚠️ Deviation (com justificativa)
- Complexidade: nível claro (S0–S4) com justificativa
- Segurança: todos os itens Não-Negociáveis atendidos

**Validation Checklist**:
- [ ] Nenhuma violação ❌ Violation
- [ ] Todas as deviations justificadas no ADL
- [ ] Nenhum item deixado em branco

---

### Step 9: Executar Checklist de Qualidade

**Command**:
```bash
cat specs/005-hybrid-collaboration-test/checklists/requirements.md
```

**Expected**:
- Todas as checkboxes marcadas ([x])
- Status: "PASS" ou "PASS com N notas"
- Se houver notas, devem ser documentadas (não bloqueadoras)

---

## Success Criteria

**Feature 005 considerada PRONTA se**:

- [ ] Todos os 9 steps acima completam sem erro fatal
- [ ] Pelo menos 2 projetos piloto passam validação completa
- [ ] Dev humano consegue executar task sem buscar contexto extra (Step 6)
- [ ] Referência ao SPEC KIT COST presente e ativa (Step 7)
- [ ] Padrões Impeccable e OpenFeature validados (Step 7.1)
- [ ] Gates e Constitution Check passam (Step 8)
- [ ] Checklist de qualidade marca PASS (Step 9)

**Rollback Criteria** (se não passar):

- [ ] Publicar Issue "Validation failed: Feature 005" com detalhes
- [ ] Revert merge de feature branch
- [ ] Atualizar plan.md com blockers identificados
- [ ] Re-executar `/speckit-plan` com refinements

---

## Notes

- Validação é manual + automática (CI/CD linters)
- Esperado tempo total: ~2–3 horas por projeto piloto
- Se receber "não consegui executar sem contexto" de dev humano, isso é um FAIL de contrato de task → retroalimentação para `speckit-tasks` skill

---

## Implementation Validation Evidence (Feature 005)

Use esta seção para registrar rapidamente a conclusão das tarefas de implementação
do contrato híbrido.

- [x] T012 — Spec de exemplo validada contra contrato (ver `fixtures/spec-sample.md`)
- [x] T015 — Corpo de task de exemplo validado para execução humana (ver `fixtures/task-sample.md`)
- [x] T018 — Validação de custo e rollout adicionada (Step 7 + Success Criteria)
- [x] T026 — Validação de Impeccable/OpenFeature adicionada (Step 7.1)

Comando de validação automatizada:

```bash
.specify/scripts/bash/validate-hybrid-contracts.sh
```

Resultado esperado:

```text
OK: hybrid contracts validated in specs/016-hybrid-agent-human-dev/fixtures
```

---

## References

- [Feature Spec](./spec.md)
- [Implementation Plan](./plan.md)
- [Data Model](./data-model.md)
- [Contracts](./contracts/)
- [SPEC KIT COST](https://github.com/venha-pra-nuvem/spec-kit-cost)
