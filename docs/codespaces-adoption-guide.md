# Guia de Adoção do GitHub Codespaces — Nimbus-Code

> Artefato de decisão da feature [009-codespaces-dev-planning](/specs/009-codespaces-dev-planning/spec.md).
> Este guia documenta **como adotar** o devcontainer de referência
> ([.devcontainer/devcontainer.json](/.devcontainer/devcontainer.json)), a
> política de governança de custo/ociosidade e o modelo de segurança para
> sessões remotas de agentes de IA. Não introduz nenhum rollout automático em
> repositórios de produção — cada repositório decide individualmente se e
> quando adota.

## 1. Devcontainer padrão (FR-001 / AC-1)

O devcontainer de referência deste template
([.devcontainer/devcontainer.json](/.devcontainer/devcontainer.json)) cobre:

| Item | Valor |
|---|---|
| Imagem base | `mcr.microsoft.com/devcontainers/base:ubuntu` |
| Features | Python 3.12, Node.js LTS, GitHub CLI |
| Extensões VS Code | GitHub Copilot, GitHub Copilot Chat, GitLens, YAML, Markdownlint |
| `postCreateCommand` | [scripts/setup-dev-environment.sh](/scripts/setup-dev-environment.sh) — instala `shellcheck`/`jq`, dependências Python (`pyyaml`) e valida o toolchain |

### Como adotar em outro repositório

1. Copiar `.devcontainer/devcontainer.json` e
   `scripts/setup-dev-environment.sh` para o repositório de destino.
2. Ajustar as *features* e dependências do `postCreateCommand` para a stack
   real daquele repositório (ex.: adicionar a feature `docker-in-docker` para
   um repositório que builda imagens; remover `node` se o repositório for
   Python puro).
3. Abrir um Codespace de teste e validar o Cenário 1 do
   [quickstart.md](/specs/009-codespaces-dev-planning/quickstart.md) antes de
   divulgar ao time.

### Quando Codespaces NÃO é a escolha recomendada (FR-006)

Conforme os Edge Cases do [spec.md](/specs/009-codespaces-dev-planning/spec.md):

- **Repositórios majoritariamente de documentação** (sem toolchain de
  build/test relevante): o custo de manter um devcontainer não se paga —
  edição direta (web editor do GitHub ou clone local simples) é suficiente.
- **Repositórios com devcontainer customizado já existente para outro
  propósito**: não sobrescrever — a configuração padrão Nimbus-Code é um
  ponto de partida extensível, não uma substituição obrigatória. Documentar a
  divergência no ADR do repositório se a decisão for não adotar o padrão.
- **Indisponibilidade do provedor de Codespaces**: como fallback, o
  desenvolvimento local tradicional (clone + toolchain manual) permanece
  sempre disponível — Codespaces é uma opção de conveniência, não uma
  dependência rígida do fluxo de trabalho.
- **Picos de demanda simultânea**: se a organização atingir limites de quota
  de Codespaces concorrentes, o fallback é o mesmo — desenvolvimento local.
  Esse limite é uma configuração de organização a ser monitorada pelo gestor
  de plataforma (fora do escopo técnico deste devcontainer de referência).

## 2. Governança de custo e ociosidade (FR-004 / AC-3)

Entidade correspondente: `CodespaceIdleGovernancePolicy` em
[data-model.md](/specs/009-codespaces-dev-planning/data-model.md).

### Primeira linha de governança: configuração nativa do GitHub

Conforme decidido em [research.md](/specs/009-codespaces-dev-planning/research.md)
(Unknown 3), a primeira linha de defesa contra custo de Codespaces ociosos é a
configuração **nativa** do GitHub Codespaces, a nível de organização
(`Settings → Codespaces → Policies`):

| Configuração | Recomendação Nimbus-Code | Racional |
|---|---|---|
| **Default idle timeout** | 30 minutos | Suficiente para pausas curtas (reunião, almoço) sem manter o Codespace ativo desnecessariamente; alinhado ao SLO de disponibilidade de 99,0% do `spec.md` sem gerar custo ocioso significativo |
| **Retention period** (tempo que um Codespace parado é mantido antes de exclusão) | 7 dias (mínimo permitido pelo GitHub para reduzir custo de armazenamento; ajustável para até 30 dias se o time preferir preservar o estado por mais tempo) | Equilibra a conveniência de retomar um Codespace parado sem reconfigurar do zero contra o custo de armazenamento de Codespaces esquecidos |
| **Limite de Codespaces simultâneos por usuário** | Definir conforme quota da organização (validar em Gate 1 do `impact-map.md`) | Evita que um único usuário esgote a quota disponível para o time |

Essas configurações são aplicadas pelo administrador da organização em
`venha-pra-nuvem.ghe.com` — não fazem parte do `devcontainer.json` deste
repositório (não são propriedade do devcontainer, e sim da organização).

### Fallback: workflow de referência

Caso a configuração nativa se mostre insuficiente (ex.: necessidade de
alertas de custo por repositório/time, não apenas parada automática), este
template inclui um workflow de **referência** (não ativo por padrão em
nenhum repositório de projeto):
[.github/workflows/codespaces-idle-governance.yml](/.github/workflows/codespaces-idle-governance.yml).

> **Nota de ativação**: o workflow de referência está configurado com
> `workflow_dispatch` (disparo manual) em vez de `schedule` (cron automático)
> nesta feature de planejamento. Ativar a execução agendada automática é uma
> decisão de rollout que envolve permissões de API (`gh api /user/codespaces`)
> e potencial impacto de custo/billing — **fica pendente de decisão humana**
> por repositório antes de trocar o gatilho para `schedule`.

## 3. Modelo de Sessão de Agente (FR-005 / AC-4)

Entidade correspondente: `RemoteAgentSessionModel` em
[data-model.md](/specs/009-codespaces-dev-planning/data-model.md).

Sessões remotas de agentes de IA (incluindo execuções em background) já fazem
parte do fluxo de trabalho da organização fora de Codespaces (ver
[docs/agent-session-manual.md](/docs/agent-session-manual.md)). Quando um
Codespace é usado como ambiente de execução para uma dessas sessões, as
seguintes regras se aplicam **sem exceção**:

| Regra | Descrição |
|---|---|
| **Escopo de segredos** | Uma sessão de agente rodando em Codespace só pode acessar os *Codespaces secrets* explicitamente concedidos àquele repositório — o **mesmo conjunto** de segredos já permitido para o CI/CD do repositório (`Settings → Secrets and variables → Actions`/`Codespaces`). Nenhum segredo de outro repositório ou de escopo de organização mais amplo do que o já usado pelo CI é acessível. |
| **Sem elevação de permissão** | O token do agente dentro do Codespace não deve ter escopo maior do que o `GITHUB_TOKEN`/PAT já usado pelas sessões de agente atuais fora de Codespaces (ver [docs/agent-session-manual.md](/docs/agent-session-manual.md)). Codespaces não é usado como forma de contornar restrições de permissão já estabelecidas. |
| **Isolamento entre sessões** | Cada sessão de agente roda em um Codespace próprio (`isolation_model` = 1 Codespace por sessão) — nenhum estado (arquivos, variáveis de ambiente, histórico de shell) é compartilhado entre sessões concorrentes, mesmo que do mesmo repositório. |
| **Auditoria** | Toda ação relevante de uma sessão de agente em Codespace segue a mesma trilha de auditoria já exigida para commits/PRs gerados por agente (trailer `Co-authored-by`, PR normal para revisão — nunca merge direto pelo próprio agente). |
| **Máquina mais robusta** | Se uma sessão de agente precisar de um tipo de máquina (CPU/memória) maior do que o padrão do devcontainer, essa escolha é feita explicitamente ao provisionar o Codespace (`--machine` do `gh codespace create`) — não altera a política de segredos/segurança acima, que permanece a mesma independente do tamanho da máquina. |

**Sem ambiguidade (AC-4)**: o escopo de segredos permitido a uma sessão de
agente em Codespace é **idêntico, nunca mais amplo**, ao escopo já configurado
para o CI/CD daquele mesmo repositório. Qualquer necessidade de segredo
adicional deve primeiro ser adicionada à política de CI/CD do repositório (com
a devida revisão de segurança) antes de ficar disponível também para sessões
de agente em Codespace — nunca o caminho inverso.

## 4. Referências

- [spec.md](/specs/009-codespaces-dev-planning/spec.md)
- [plan.md](/specs/009-codespaces-dev-planning/plan.md)
- [quickstart.md](/specs/009-codespaces-dev-planning/quickstart.md)
- [docs/ci-cd-acceleration-map.md](/docs/ci-cd-acceleration-map.md)
- [docs/agent-session-manual.md](/docs/agent-session-manual.md)
