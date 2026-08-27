# Skills locais vs. remotas - estado atual

## Regra rapida
- **Local**: a skill existe em `.github/skills/<nome>/SKILL.md` dentro deste repositorio e pode ser usada imediatamente no contexto deste template.
- **Remota**: a skill vivera em um repositorio dedicado de catalogo (`VPN-SKILLS`), especificado em `specs/003-vpn-skills-repo-governance/`, mas isso ainda nao esta implementado.

Hoje, neste template, **todas as skills versionadas pelo Nimbus Code continuam locais**.

## Estado atual por skill

| Skill | Distribuicao atual | Status | Como localizar/invocar |
|---|---|---|---|
| `speckit-analyze` | local | disponivel | `.github/skills/speckit-analyze/SKILL.md` |
| `speckit-checklist` | local | disponivel | `.github/skills/speckit-checklist/SKILL.md` |
| `speckit-clarify` | local | disponivel | `.github/skills/speckit-clarify/SKILL.md` |
| `speckit-constitution` | local | disponivel | `.github/skills/speckit-constitution/SKILL.md` |
| `speckit-converge` | local | disponivel | `.github/skills/speckit-converge/SKILL.md` |
| `speckit-implement` | local | disponivel | `.github/skills/speckit-implement/SKILL.md` |
| `speckit-interview` | local | disponivel | `.github/skills/speckit-interview/SKILL.md` (passo manual opcional antes do `speckit-specify` — ver `docs/developer-guide.md`) |
| `speckit-nimbus-code-backlog-sync-sync` | local | disponivel | `.github/skills/speckit-nimbus-code-backlog-sync-sync/SKILL.md` |
| `speckit-plan` | local | disponivel | `.github/skills/speckit-plan/SKILL.md` |
| `speckit-specify` | local | disponivel | `.github/skills/speckit-specify/SKILL.md` |
| `speckit-tasks` | local | disponivel | `.github/skills/speckit-tasks/SKILL.md` |
| `speckit-taskstoissues` | local | disponivel | `.github/skills/speckit-taskstoissues/SKILL.md` |

## O que ainda nao existe
- Nenhuma destas skills foi migrada para um repositorio remoto de catalogo.
- Nenhuma invocacao remota via `VPN-SKILLS` deve ser presumida hoje.
- Se alguem pedir uma skill remota do Nimbus Code, a resposta correta neste momento e: **a governanca foi especificada, mas a implementacao ainda nao existe; use a versao local em `.github/skills/`**.

## Como decidir em menos de 2 minutos
1. Procure o nome da skill na tabela acima.
2. Se ela estiver com distribuicao atual `local`, abra o arquivo em `.github/skills/<nome>/SKILL.md`.
3. Se alguem citar `VPN-SKILLS`, verifique `specs/003-vpn-skills-repo-governance/` e trate como **planejado**, nao como capacidade disponivel.

## Nota de transicao
Quando o repositorio `VPN-SKILLS` for efetivamente criado, este manual devera ser atualizado com:
- URL no GHE do catalogo remoto;
- lista das skills migradas; e
- instrucoes de fallback quando a skill ainda existir apenas localmente.
