# nimbus-code-full-cycle (workflow)

## Propósito

Ciclo completo do Nimbus Code com **gate explícito de DevSecOps** entre `plan` e
`tasks`, e com o **modelo de branch claro**: branch é criado **apenas** na fase
`implement` — as fases de planejamento (discovery, specify, plan, tasks) não
geram branch nem commit de código.

## Modelo de Fases e Branches

```
Discovery  → sem branch   (entendimento do problema)
Specify    → sem branch   → gera specs/<feature>/spec.md
Plan       → sem branch   → gera specs/<feature>/plan.md
Tasks      → sem branch   → gera specs/<feature>/tasks.md
───────────────────────────────────────────────────────
Implement  → BRANCH criado aqui → feature/fase-{N}-{slug}
Converge   → no mesmo branch   → PR aberto para develop
```

## Passos

1. `discovery` (nota) — delimitação do problema, sem artefato de código
2. `specify` — gera `spec.md` (sem branch)
3. `review-spec` (gate) — aprovação humana da spec
4. `plan` — gera `plan.md` com a seção **Nimbus-Code — Security & DevSecOps Gate** (sem branch)
5. `devsecops-gate` (gate) — confirma que a seção de segurança do `plan.md` foi revisada
6. `graph-gate` (gate) — confirma que graph.yaml/graph.md estão presentes e atualizados
7. `tasks` — gera `tasks.md` com o checklist de qualidade (sem branch)
8. `review-tasks` (gate) — aprovação humana das tasks; após aqui o branch é criado
9. `create-branch` (nota) — sinaliza a criação do branch de implementação
10. `implement` — executa as tasks no branch `feature/fase-{N}-{slug}`
11. `converge` — compara código real vs spec/plan/tasks
12. `converge-gate` (gate) — checklist pós-implementação antes de abrir PR

## Uso

```bash
specify workflow run nimbus-code-full-cycle
```

## Versionamento

Segue [SemVer](https://semver.org/). Ver a política de versionamento do bundle em
[`../../README.md`](../../README.md).
