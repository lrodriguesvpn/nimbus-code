# Feature Specification: MultiRepo Support no Spec Kit Template

**Feature Branch**: `006-multirepo-support`

**Created**: 2026-08-18

**Status**: Ready

---

## Nimbus-Code — Cabeçalho Obrigatório da Spec

| Campo | Valor |
|---|---|
| **Feature slug** | `006-multirepo-support` |
| **Complexidade estimada** | **S3** — cruza `bounded-contexts.yaml` (novo), `feature.json` (estendido), `create-new-feature.sh`, `setup-github-project.sh`, `developer-guide.md`, template de preset |
| **Bounded Context** | `spec-kit-workflow` |
| **PR de referência / Issue** | novo |
| **Data alvo de entrega** | sem data |

> S0 = doc · S1 = função isolada · S2 = módulo · S3 = múltiplos módulos ·
> S4 = arquitetura, segurança, dados ou integração crítica

## Nimbus-Code — SLO Alvo desta Feature

| Componente | Latência p99 (ms) | Taxa de erro máx. (%) | Disponibilidade alvo | RTO | RPO |
|---|---|---|---|---|---|
| Scripts bash (setup/taskstoissues) | — | 0% (idempotentes) | — | — | — |

> Scripts CLI locais/CI — sem SLO de disponibilidade mensurável.

## Nimbus-Code — Objetivo e Contexto

**Objetivo:** Estender o template Nimbus Code para suportar a estratégia
**1 Repo Central de Specs (produto) + N Repos por stack/microsserviço**,
permitindo que o fluxo `/speckit-specify` → `/speckit-taskstoissues` saiba
em quais repos criar cada tipo de issue (Epics/Features/USs no repo central;
Tasks nos repos dos serviços).

**Motivação:** O padrão atual do template assume um único repo. Times com
microsserviços em tecnologias distintas (Go, Node, React, Python, Terraform)
precisam de um modelo onde o board e as specs ficam no repo central, mas as
Tasks de código (e os PRs do Copilot Agent) vivem nos repos dos serviços.
Sem isso, o time ou cria tudo no repo errado ou configura manualmente cada
feature.

**Critério de done (alto nível):** Um projeto com 3+ repos de serviço
consegue, a partir do repo central, rodar `/speckit-specify` declarando os
bounded contexts envolvidos, e o `/speckit-taskstoissues` cria as Tasks nos
repos corretos automaticamente — com board cross-repo funcionando no Project V2.

## Nimbus-Code — Critérios de Aceitação (formato BDD)

> **AC-1**
> **Given** o arquivo `docs/bounded-contexts.yaml` do projeto,
> **When** adiciono uma entrada com `slug`, `repository`, `stack`, `team` e `autonomous_ok`,
> **Then** o formato é aceito pelos scripts downstream sem erro.

> **AC-2**
> **Given** um `bounded-contexts.yaml` preenchido,
> **When** o agente inicia uma nova sessão e lê o cabeçalho da spec,
> **Then** ele valida o campo `Bounded Context` contra os slugs declarados — e rejeita slugs não cadastrados.

> **AC-3**
> **Given** que `autonomous_ok: false` está declarado para um contexto,
> **When** o `/speckit-taskstoissues` cria uma Task naquele repo,
> **Then** o label `agent:needs-human` é aplicado automaticamente na issue criada.

> **AC-4**
> **Given** que executo `create-new-feature.sh` com `--bounded-contexts "auth,orders"`,
> **When** o script termina,
> **Then** o `.specify/feature.json` contém `"bounded_contexts": ["auth","orders"]` e `"repos": ["org/svc-auth","org/svc-orders"]` resolvidos do `bounded-contexts.yaml`.

> **AC-5**
> **Given** que `bounded_contexts` não é informado,
> **When** o script termina,
> **Then** `feature.json` contém `"bounded_contexts": []` e `"repos": []` — campo opcional, sem erro.

> **AC-6**
> **Given** um slug inválido (não existe em `bounded-contexts.yaml`),
> **When** passo `--bounded-contexts "auth,inexistente"`,
> **Then** o script imprime aviso claro e aborta, listando os slugs válidos disponíveis.

> **AC-7**
> **Given** um `tasks.md` com `[US1 — auth]` e `[US2 — frontend-web]`,
> **When** executo `/speckit-taskstoissues`,
> **Then** as Tasks de US1 são criadas em `org/svc-auth` e as de US2 em `org/frontend-web`.

> **AC-8**
> **Given** que o repo do serviço não está acessível,
> **When** o comando tenta criar a Task,
> **Then** imprime erro claro identificando o repo problemático e continua processando os demais.

> **AC-9**
> **Given** que já existem Tasks criadas anteriormente num repo de serviço,
> **When** executo `/speckit-taskstoissues` novamente,
> **Then** as issues existentes são detectadas por ID `T00N` e não são recriadas; apenas vínculos ausentes são adicionados.

> **AC-10**
> **Given** que `feature.json` não tem `bounded_contexts` (feature single-repo),
> **When** executo `/speckit-taskstoissues`,
> **Then** o comportamento é idêntico ao atual — compatibilidade retroativa garantida.

> **AC-11**
> **Given** um `bounded-contexts.yaml` com N repos de serviço,
> **When** executo `setup-github-project.sh`,
> **Then** todos os repos aparecem em "Linked Repositories" do Project V2.

> **AC-12**
> **Given** que um repo já está vinculado ao Project V2,
> **When** executo o script novamente,
> **Then** o script é idempotente — não duplica o vínculo e imprime `✓ já vinculado`.

> **AC-13**
> **Given** que `bounded-contexts.yaml` está ausente,
> **When** executo `setup-github-project.sh`,
> **Then** o script imprime aviso e prossegue normalmente sem abortar.

> **AC-14**
> **Given** que leio a seção "MultiRepo — Registrando Microsserviços" do `developer-guide.md`,
> **Then** encontro passos para: (1) preencher `bounded-contexts.yaml`; (2) declarar `bounded_contexts` numa feature; (3) como o `/speckit-taskstoissues` roteia Tasks; (4) como verificar o board cross-repo.

> **AC-15**
> **Given** que o template `bounded-contexts.yaml` existe no preset,
> **Then** ele já contém campos `repository`, `stack`, `team` e `autonomous_ok` com exemplos comentados.

---

## Fora de Escopo

- Suporte a repos em organizações diferentes (cross-org) — requer autenticação separada
- Criação automática dos repos de serviço — o script assume que eles já existem
- Sincronização de labels entre repos de serviço (cada um roda `setup-github-labels.sh` individualmente)
- Migração de issues já criadas num repo errado

---

## Dependências

| Dependência | Tipo | Status |
|---|---|---|
| Feature 005 (hierarquia Epic/Feature/US/Task) | upstream | ✅ implementada |
| `bounded-contexts.yaml` com campo `repos` | artefato novo | a criar |
| API GraphQL `linkProjectV2ToRepository` | GitHub API | disponível no GHE ≥ 3.8 |

---

## Glossário

| Termo | Definição |
|---|---|
| **Repo Central** | Repo que hospeda `specs/`, `docs/`, boards — não tem código de serviço |
| **Repo de Serviço** | Repo de um microsserviço ou frontend — tem código, CI/CD, PRs do Copilot |
| **Bounded Context** | Unidade de domínio com slug único em `bounded-contexts.yaml`; mapeia para um repo |
| **Cross-repo** | Recurso do Project V2 que exibe issues de múltiplos repos num único board |
