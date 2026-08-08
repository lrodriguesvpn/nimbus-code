# vpndev-full-cycle (workflow)

## Propósito

Variante do workflow nativo `speckit` (Full SDD Cycle: `specify → plan → tasks →
implement`) com um **gate explícito de DevSecOps** entre `plan` e `tasks` —
formalizando como um passo real do workflow o que antes era uma skill solta
(`devops-planning`) sem lugar garantido no ciclo.

## Passos

1. `specify` — gera `spec.md`
2. `review-spec` (gate) — aprovação humana da spec
3. `plan` — gera `plan.md` (já com a seção **VPN Dev — Security & DevSecOps Gate**
   e **Architecture Decision Log**, injetadas pelo preset `vpndev-standards`)
4. `devsecops-gate` (gate) — confirma que a seção de segurança do `plan.md` foi
   preenchida e aprovada (rodando `/devops-planning` manualmente antes, se o
   projeto ainda usa essa skill, ou preenchendo direto no `plan.md`)
5. `tasks` — gera `tasks.md` (já com o checklist de qualidade de infra/deploy)
6. `review-tasks` (gate) — aprovação humana das tasks
7. `implement` — executa as tasks

## Uso

```bash
specify workflow run vpndev-full-cycle
```

Ou, se instalado via bundle, disponível também como comando de agente (dependendo
da integração ativa).

## Versionamento

Segue [SemVer](https://semver.org/). Ver a política de versionamento do bundle em
[`../../README.md`](../../README.md).
