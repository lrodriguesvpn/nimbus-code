# Contract: Task (GHE Issue) Output Format

**Target Audience**: Desenvolvedor humano (primary), agente (secondary)  
**Enforced by**: `.github/skills/speckit-tasks/SKILL.md` + GHE template

---

## Task Structure (GHE Issue Body)

Toda task publicada no GHE deve seguir este formato de markdown:

```markdown
## Contexto

[Informação necessária para entender por que essa task existe.
Máx 300 caracteres. Ex: "Feature X depende dessa mudança em Y."]

## Objetivo

[O que fazer. Uma frase acionável. Ex: "Refatorar módulo X para suportar Y"]

## Resultado Esperado

[Descrição do que será entregue. Ex: "Arquivo Y.js refatorado com tests passando"]

## Critérios de Aceite

- [ ] Criterion 1 (verificável)
- [ ] Criterion 2 (verificável)

## Passos Operacionais

1. [Passo claro e acionável]
2. [Próximo passo]
3. ...

## Dependências

[Se houver, listar issue IDs ou tarefas bloqueadoras. Deixar vazio se nenhuma.]

## Responsável

Agente: [sim/não] — Se sim, describe a/agente.
Humano: [sim/não] — Se sim, esse issue precisa de executante humano.

## Estimativa de Esforço

- Tokens (agente): ~X–Y mil
- Horas (humano): ~X–Y horas

## Referência

- AC-ID: [ex.: AC-1] (link à spec)
- Feature: [ex.: Feature 005] (link ao plan)
- SPEC KIT COST: https://github.com/venha-pra-nuvem/spec-kit-cost
```

---

## Validation Rules

### Clarity for Human Execution

- [ ] Contexto não assume conhecimento prévio (um dev novo consegue ler e entender)
- [ ] Objetivo é acionável (não deixa ambiguidade sobre "pronto")
- [ ] Cada critério de aceite é verificável sem interpretação (não: "qualidade boa")
- [ ] Passos operacionais são seqüenciais e completos (não pulam etapas)

### Completeness

- [ ] Contexto preenchido
- [ ] Objetivo preenchido
- [ ] Resultado esperado preenchido
- [ ] Pelo menos 1 critério de aceite
- [ ] Se Responsável.Humano = sim, "Passos Operacionais" é obrigatório
- [ ] Dependências preenchidas ou explicitamente "Nenhuma"

### Traceability

- [ ] AC-ID referencia AC válida da spec
- [ ] Feature referencia feature slug válida
- [ ] SPEC KIT COST link está correto e ativo (HTTP 200)

### Role Clarity

- [ ] Responsável.Agente e Responsável.Humano são ambos claros
- [ ] Se Responsável.Humano = sim, "Passos Operacionais" detalha tudo necessário
- [ ] Se Responsável.Agente = sim, estimativa de tokens é fornecida

---

## Example: PASS

```markdown
## Contexto

Feature 005 (Hybrid Agent-Human Templates) precisa que spec-template.md 
inclua novo cabeçalho de "Hybrid Collaboration Model" para comunicar 
papéis desde o início de cada feature.

## Objetivo

Modificar `.specify/presets/nimbus-code-standards/templates/spec-template.md`
para prepend seção de "Hybrid Collaboration Model" ao template.

## Resultado Esperado

Arquivo spec-template.md atualizado. Novas specs geradas via /speckit-specify
incluem novo cabeçalho. 2 projetos piloto validam que cabeçalho aparece
corretamente.

## Critérios de Aceite

- [ ] Seção "Hybrid Collaboration Model" aparece após "Nimbus-Code Cabeçalho" e antes de "User Scenarios"
- [ ] Seção inclui tabela com campos: role, responsibilities, handoff_criteria, escalation_path
- [ ] Teste manual: gerar 2 specs em projetos piloto e confirmar novo cabeçalho presente
- [ ] PR passa linter e code review

## Passos Operacionais

1. Clone/pull branch `feature/005-hybrid-agent-human-dev`
2. Abra arquivo `.specify/presets/nimbus-code-standards/templates/spec-template.md`
3. Localize seção "## Nimbus-Code — Objetivo e Contexto" (~ linha 40)
4. Insira novo bloco "## Hybrid Collaboration Model" ANTES dessa linha
5. Copie template de tabela: role, responsibilities, handoff_criteria, escalation_path (veja data-model.md)
6. Faça commit: `git commit -am "Add hybrid collaboration model section to spec-template"`
7. Abra PR contra `develop`
8. Aguarde aprovação de tech lead

## Dependências

Nenhuma (pode ser feito independentemente).

## Responsável

Agente: Não (template é arquivo estático, mas validação manual é humana)
Humano: Sim (Tech Lead revisa modificação de template)

## Estimativa de Esforço

- Tokens (agente): ~2–3 mil (se agente revisar/sugerir durante implementação)
- Horas (humano): ~0.5 horas (Tech Lead: review e aprovação)

## Referência

- AC-ID: AC-1
- Feature: Feature 005 (Hybrid Agent-Human Delivery Templates)
- SPEC KIT COST: https://github.com/venha-pra-nuvem/spec-kit-cost
```

---

## Example: FAIL

```markdown
## Objetivo

Melhorar templates.

[ PROBLEMA: Vago demais, não acionável; não menciona arquivo específico ]
```

```markdown
## Passos Operacionais

1. Fazer mudanças
2. Fazer commit
3. Enviar PR

[ PROBLEMA: Cada passo deixa margem para erros; faltam detalhes ]
```

---

## Contract Enforcement

1. **Template GHE** (automático): Bot valida estrutura ao criar issue
2. **Code Review** (humano): Tech Lead verifica Passos Operacionais são claros antes de aprovar
3. **CI/CD Linter** (automático): Valida presença de campos obrigatórios

Violações bloqueiam issue ou requerem conformidade antes de merge.
