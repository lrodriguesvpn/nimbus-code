# Skills locais vs. remotas - estado atual

## Regra rapida
- **Local**: a skill existe em `.github/skills/<nome>/SKILL.md` dentro deste repositorio e pode ser usada imediatamente no contexto deste template.
- **Remota**: a skill vivera em um repositorio dedicado de catalogo (`VPN-SKILLS`), especificado em `specs/003-vpn-skills-repo-governance/`, mas isso ainda nao esta implementado.

Hoje, neste template, **todas as skills versionadas pelo Nimbus Code continuam locais**.

## Estado atual por skill

### Esquadrão de Skills Nimbus Code (`/nc-*`)

| Skill Nimbus | Agente | Distribuicao atual | Status | Como localizar/invocar |
|---|---|---|---|---|
| `nc-assess-intake` | `NC-Assess-Intake` | local | disponivel | `.github/skills/nc-assess-intake/SKILL.md` |
| `nc-assess-research` | `NC-Assess-Research` | local | disponivel | `.github/skills/nc-assess-research/SKILL.md` |
| `nc-assess-define` | `NC-Assess-Define` | local | disponivel | `.github/skills/nc-assess-define/SKILL.md` |
| `nc-assess-shape` | `NC-Assess-Shape` | local | disponivel | `.github/skills/nc-assess-shape/SKILL.md` |
| `nc-assess-decide` | `NC-Assess-Decide` | local | disponivel | `.github/skills/nc-assess-decide/SKILL.md` |
| `nc-intake` | `NC-Intake` | local | disponivel | `.github/skills/nc-intake/SKILL.md` |
| `nc-spec` | `NC-Spec` | local | disponivel | `.github/skills/nc-spec/SKILL.md` |
| `nc-critic` | `NC-Critic` | local | disponivel | `.github/skills/nc-critic/SKILL.md` |
| `nc-governor` | `NC-Governor` | local | disponivel | `.github/skills/nc-governor/SKILL.md` |
| `nc-arch` | `NC-Arch` | local | disponivel | `.github/skills/nc-arch/SKILL.md` |
| `nc-shield` | `NC-Shield` | local | disponivel | `.github/skills/nc-shield/SKILL.md` |
| `nc-designer` | `NC-Designer` | local | disponivel | `.github/skills/nc-designer/SKILL.md` |
| `nc-qa` | `NC-QA` | local | disponivel | `.github/skills/nc-qa/SKILL.md` |
| `nc-builder` | `NC-Builder` | local | disponivel | `.github/skills/nc-builder/SKILL.md` |
| `nc-telemetry` | `NC-Telemetry` | local | disponivel | `.github/skills/nc-telemetry/SKILL.md` |

### Skills Fundacionais do Spec Kit (`/speckit-*`)

| Skill | Distribuicao atual | Status | Como localizar/invocar |
|---|---|---|---|
| `speckit-analyze` | local | disponivel | `.github/skills/speckit-analyze/SKILL.md` |
| `speckit-assess-decide` | local | disponivel | `.github/skills/speckit-assess-decide/SKILL.md` |
| `speckit-assess-define` | local | disponivel | `.github/skills/speckit-assess-define/SKILL.md` |
| `speckit-assess-intake` | local | disponivel | `.github/skills/speckit-assess-intake/SKILL.md` |
| `speckit-assess-research` | local | disponivel | `.github/skills/speckit-assess-research/SKILL.md` |
| `speckit-assess-shape` | local | disponivel | `.github/skills/speckit-assess-shape/SKILL.md` |
| `speckit-checklist` | local | disponivel | `.github/skills/speckit-checklist/SKILL.md` |
| `speckit-clarify` | local | disponivel | `.github/skills/speckit-clarify/SKILL.md` |
| `speckit-constitution` | local | disponivel | `.github/skills/speckit-constitution/SKILL.md` |
| `speckit-converge` | local | disponivel | `.github/skills/speckit-converge/SKILL.md` |
| `speckit-implement` | local | disponivel | `.github/skills/speckit-implement/SKILL.md` |
| `speckit-interview` | local | disponivel | `.github/skills/speckit-interview/SKILL.md` |
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
