# Guia de Bootstrap do Repositório VPN-SKILLS

**Feature de origem**: [specs/003-vpn-skills-repo-governance/](./spec.md)
**Status**: Guia operacional — a ser seguido pelo Dev antes/durante o início da implementação (`/speckit-implement`)

> **Atualização (2026-08-20)**: o cenário deste guia (bootstrap de um repositório
> vazio seguido de implementação task-a-task via `/speckit-implement`) **não foi
> o caminho realmente seguido**. Uma implementação completa das 113 tasks já
> existia numa branch órfã (`copilot/controle-de-custos`, nunca proposta como
> PR) deste template. Em vez de reimplementar do zero, essa implementação foi
> **extraída** (histórico preservado via `git subtree split`) diretamente para
> **[venha-pra-nuvem/vpn-skills](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/vpn-skills)**,
> com labels/Project V2 aplicados via os scripts deste template e proteção de
> branch `main` configurada. Este guia permanece válido como referência para os
> passos 2–4 (bootstrap Nimbus Code, decisão de GitHub App, CODEOWNERS/branch
> protection) que ainda **não foram executados** no repositório novo — ver
> `tasks.md` desta feature para o status consolidado.

## Por que este guia existe

O `tasks.md` desta feature (113 tasks + 3 de convergência) assume que o repositório
`VPN-SKILLS` **já existe** — todas as tasks criam arquivos dentro de `vpn-skills/`,
mas nenhuma cria o repositório em si no GitHub Enterprise. Criar um repositório
novo é uma ação administrativa (nível de organização) que precisa ser feita por um
humano antes que qualquer task de código comece. Este guia cobre exatamente essa
lacuna: **o que fazer fora do `tasks.md`, e em que ordem**.

## Resposta direta: sim, você precisa inicializar o Nimbus Code no novo repositório

O VPN-SKILLS é, por definição (FR-008 do `spec.md`), um repositório que **deve
suportar o fluxo Speckit** (`/nimbus-code-specify` → `/nimbus-code-plan` →
`/nimbus-code-tasks`) para toda nova feature de skill. Isso significa que ele
precisa do mesmo bootstrap que qualquer outro projeto Nimbus-Code — **exatamente
o `bootstrap.sh` deste repositório template**, não um processo separado.

Além disso, `specs/008-bootstrap-governance-hardening/` (User Story 1) classifica
VPN-SKILLS como um repositório de **"Dev Standards"** (não é Plataforma/Cliente —
não gerencia contas cloud, tenants ou ambientes), então o preset correto é
`nimbus-code-standards` (o mesmo que este template já usa), **não**
`nimbus-code-platform-standards`.

## Ordem de operações

### 1. Criar o repositório (manual, humano — [issue #70](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code/issues/70))

- Criar `VPN-SKILLS` na organização `venha-pra-nuvem` no **GitHub Enterprise**
  (`venha-pra-nuvem.ghe.com`) — nunca no GitHub público, conforme política de
  domínio de `specs/008-bootstrap-governance-hardening/` (FR-007).
- Visibilidade: privado (padrão da organização), a menos que haja decisão
  explícita em contrário.
- Não inicializar com README/license pelo GitHub — o `bootstrap.sh` e as tasks
  desta feature cuidam disso.

### 2. Rodar o bootstrap Nimbus Code no repositório novo (manual, humano — [issue #71](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code/issues/71))

Dentro do clone local do `VPN-SKILLS` recém-criado:

```sh
curl -fsSL https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code/raw/main/bootstrap.sh | bash
```

Isso já resolve automaticamente, sem precisar de tasks manuais de código, uma
parte relevante do escopo de **Phase 1** do `tasks.md` desta feature:

| Task original | Já coberta pelo `bootstrap.sh`? | Observação |
|---|---|---|
| T002 — `constitution.md` | ✅ Sim (via preset `nimbus-code-standards`) | Não precisa ser escrito à mão |
| T006 — `.specify/` | ✅ Sim (`specify init --here`) | |
| T007 — `ci.yml` | 🟡 Parcial | `bootstrap.sh` instala `update-speckit-and-bundle.yml`, `ensure-github-project.yml`, `add-to-repo-project.yml`; o `ci.yml` específico de lint/test do VPN-SKILLS (T007) ainda precisa ser escrito pela task |
| T009 — `graph-guard.yml` | ✅ Sim (via `graph-guard.yml` do template, se copiado manualmente do preset) | Confirmar cópia — não está na lista automática do `bootstrap.sh` hoje |
| T010 — `bootstrap.sh` do próprio VPN-SKILLS | ⚠️ Cuidado | Este é um `bootstrap.sh` **novo**, específico do VPN-SKILLS (instala Speckit CLI + deps do próprio produto) — não confundir com o `bootstrap.sh` deste template, que só faz o setup de governança Nimbus-Code. Os dois coexistem no repo. |
| T003–T005 (ADRs específicos do VPN-SKILLS) | ❌ Não | Específicos da arquitetura do VPN-SKILLS, continuam sendo tasks de implementação normais |

- `bootstrap.sh` também cria labels (`priority:*`, `complexity:*`, `type:*`,
  `agent:*`, `status:*`, `dora:*`) e tenta criar o GitHub Project V2 do
  repositório automaticamente (requer `gh` CLI autenticado).

### 3. Decidir a estratégia de GitHub App para o VPN-SKILLS (manual, humano — [issue #72](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code/issues/72))

Conforme `plan.md` (ADL-004), a API e o CLI do VPN-SKILLS precisam acessar
repositórios/organização no GitHub (ex.: compliance report generator lendo
manifestos de 10+ projetos) — isso **deve** usar token de instalação de GitHub
App, nunca PAT clássico. Existem duas opções, e uma decisão explícita é
necessária antes de implementar T095/T114 (camada de autenticação):

- **Opção A**: Reutilizar o GitHub App organizacional mais amplo que
  `specs/008-bootstrap-governance-hardening/` propõe (User Story 4) para
  automações cross-repo/org do bootstrap em geral — se/quando aquela feature for
  implementada primeiro.
- **Opção B**: Criar um GitHub App dedicado só para o VPN-SKILLS (análogo ao
  "Nimbus Code Security Auditor" criado para `specs/007-controle-seguranca-ghe-projetos-plataforma/`,
  ver [ADR-0008](/docs/adr/0008-github-app-para-varredura-de-seguranca-org-wide.md)).

**Recomendação**: Opção B no curto prazo (não bloquear VPN-SKILLS esperando a
008 ser implementada), com nota registrada no ADL-004 do `plan.md` para migrar
para o App organizacional único quando ele existir.

### 4. Confirmar CODEOWNERS e branch protection (manual, humano — [issue #73](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code/issues/73))

- Branch `main` protegida, PR obrigatório, ao menos 1 revisão humana
  (constituição, "Qualidade e Processo").
- `CODEOWNERS` inicial — recomenda-se o mesmo time responsável por padrões
  Nimbus-Code até que o VPN-SKILLS tenha mantenedores próprios definidos.

### 5. A partir daqui: seguir `tasks.md` normalmente

Com o repositório criado, o Nimbus Code bootstrapado, e as decisões acima
tomadas, o restante das 113+3 tasks deste `tasks.md` pode ser executado via
`/speckit-implement` normalmente — sem mais bloqueios de pré-requisito manual.

## Perguntas em aberto (para decisão do Dev, não assumidas aqui)

- Nome definitivo do repositório: `VPN-SKILLS` (maiúsculo, como usado nas specs)
  ou `vpn-skills` (minúsculo, convenção comum do GitHub)? Este guia assume
  `VPN-SKILLS` por ser o nome usado consistentemente em `spec.md`/`plan.md`,
  mas o GitHub normaliza para minúsculas nas URLs de qualquer forma.
- Quem serão os mantenedores iniciais (para `CODEOWNERS`)?
