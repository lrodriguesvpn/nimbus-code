# Quickstart Validation Guide

**Feature**: MultiRepo Support no Spec Kit Template
**Purpose**: Validação E2E manual (e automatizada onde possível) dos 15 ACs de `spec.md`

---

## Prerequisites

- [ ] Git e GitHub CLI (`gh`) instalados e autenticados em `venha-pra-nuvem.ghe.com`
- [ ] `python3` com o módulo `yaml` (fallback de parsing usado neste repo — `yq` não é obrigatório)
- [ ] [bats-core](https://github.com/bats-core/bats-core) instalado para rodar os testes unitários de T020 (`brew install bats-core` / `npm i -g bats` / clone + `bin/bats`)
- [ ] Acesso de escrita a pelo menos 1 org/Project V2 de teste no GHE, para validar AC-11/AC-12/AC-13 fim a fim (não executado nesta sessão — requer efeitos colaterais reais na API)

---

## Status desta validação (2026-08-20)

Esta rodada de validação cobriu os ACs que são determinísticos em código (scripts
bash) sem depender de uma API GHE real. Os ACs que dependem do comportamento do
agente (`speckit-specify`, `speckit-taskstoissues`) foram validados por inspeção
cuidadosa do texto do skill (não há forma de testar "o agente segue a instrução"
em CI); os ACs que dependem de `gh api graphql` contra um Project V2 real
(AC-11/AC-12/AC-13) **não foram executados** nesta sessão para evitar efeitos
colaterais em Projects reais — ficam documentados aqui como roteiro para quem
validar manualmente num sandbox.

| AC | Descrição resumida | Método | Resultado |
|---|---|---|---|
| AC-1 | Schema `bounded-contexts.yaml` aceito pelos scripts | Automatizado (bats, ver Step 1) | ✅ Passou |
| AC-2 | Agente valida "Bounded Context" contra slugs cadastrados | Inspeção do skill `speckit-specify/SKILL.md` (step 9) | ✅ Instrução presente — validar em sessão real de `/speckit-specify` |
| AC-3 | `autonomous_ok: false` aplica `agent:needs-human` | Inspeção do skill `speckit-taskstoissues/SKILL.md` ("Agent routing") | ✅ Instrução presente — validar em execução real |
| AC-4 | `--bounded-contexts` persiste `bounded_contexts`/`repos` resolvidos | Automatizado (bats, ver Step 1) | ✅ Passou |
| AC-5 | Flag ausente ⇒ arrays vazios, sem erro | Automatizado (bats, ver Step 1) | ✅ Passou |
| AC-6 | Slug inválido aborta com lista de válidos | Automatizado (bats, ver Step 1) | ✅ Passou |
| AC-7 | Tasks roteadas por `[USN — slug]` para o repo certo | Inspeção do skill (routing step) | ✅ Instrução presente — validar em execução real (Step 2) |
| AC-8 | Repo inacessível: erro isolado, continua os demais | Inspeção do skill (isolamento de erro por repo em 3 pontos: fetch, create, labels) | ✅ Instrução presente |
| AC-9 | Deduplicação por `T00N` por repo, sem duplicar em re-execução | Inspeção do skill (fetch existing issues, por repo) | ✅ Instrução presente |
| AC-10 | Sem `bounded_contexts`: comportamento idêntico ao single-repo | Automatizado (bats, ver Step 1) + inspeção do skill | ✅ Passou |
| AC-11 | `setup-github-project.sh` vincula todos os repos ao Project V2 | Manual — requer GHE real | ⏳ Não executado nesta sessão (ver Step 3) |
| AC-12 | Vínculo idempotente ("✓ já vinculado") | Manual — requer GHE real | ⏳ Não executado nesta sessão (ver Step 3) |
| AC-13 | `bounded-contexts.yaml` ausente ⇒ aviso, não aborta | Manual (código revisado — `_BC_FILE` vazio ⇒ branch de warning, sem `set -e` afetado) | ✅ Revisado no código — comportamento correto |
| AC-14 | `developer-guide.md` documenta o fluxo MultiRepo ponta a ponta | Inspeção de `docs/developer-guide.md` seção 5 | ✅ Presente e completo (5.1–5.6) |
| AC-15 | Template `bounded-contexts.yaml` do preset tem campos completos | Inspeção de `.specify/presets/.../bounded-contexts.yaml` | ✅ Presente |

---

## Step 1: Testes automatizados de `create-new-feature.sh --bounded-contexts`

**Command**:
```bash
bats .specify/scripts/bash/tests/create-new-feature.bats
```

**Expected Output**:
```
1..4
ok 1 valid --bounded-contexts resolves slugs to repos and persists arrays (AC-4)
ok 2 omitting --bounded-contexts yields empty arrays without error (AC-5, AC-10)
ok 3 invalid slug aborts with a clear list of valid slugs (AC-6)
ok 4 missing docs/bounded-contexts.yaml aborts with a clear error when the flag is used
```

**Resultado real desta sessão**: ✅ 4/4 testes passaram (bats-core 1.14.0, `python3` como
parser de YAML — `yq` não estava disponível no ambiente, confirmando também o fallback
gracioso de parsing).

---

## Step 2: Validar roteamento cross-repo do `/speckit-taskstoissues` (AC-7, AC-8, AC-9)

Este passo depende do agente (não é determinístico via script) — execute manualmente
num projeto de teste:

1. Crie uma feature com `bounded_contexts` declarados:
   ```bash
   .specify/scripts/bash/create-new-feature.sh --bounded-contexts "auth,billing" "Checkout cross-repo"
   ```
2. Gere um `tasks.md` com pelo menos duas seções anotadas, por exemplo:
   ```markdown
   ## Phase 2: User Story 1 [US1 — auth]
   - [ ] T001 Implementar endpoint de login

   ## Phase 3: User Story 2 [US2 — billing]
   - [ ] T002 Integrar gateway de pagamento
   ```
3. Rode `/speckit-taskstoissues`.
4. **Esperado**: `T001` criada em `org/svc-auth` (ou repo registrado para `auth`), `T002` em
   `org/svc-billing`. Se `auth` ou `billing` tiver `autonomous_ok: false`, a issue recebe o
   label `agent:needs-human`.
5. Rode `/speckit-taskstoissues` novamente.
6. **Esperado**: nenhuma issue duplicada — `T001`/`T002` reportadas como "already has an
   issue in <repo>, skipping".
7. Torne um dos repos inacessível (ex.: remova o repo de `bounded-contexts.yaml`
   temporariamente, ou use um repo inexistente) e rode novamente.
8. **Esperado**: erro claro nomeando o repo problemático; o outro repo continua sendo
   processado normalmente (AC-8).

---

## Step 3: Validar vínculo ao Project V2 (AC-11, AC-12, AC-13)

⚠️ Requer um Project V2 real e token com `write:org` — **não executado nesta sessão**
para evitar efeitos colaterais (ver risco documentado na issue #21, que já relata um
vínculo indevido causado por este mesmo passo antes do fix de `$GIT_ROOT`).

1. Preencha `docs/bounded-contexts.yaml` com 2+ repos de teste.
2. Rode, a partir da raiz do projeto consumidor (não do clone do template):
   ```bash
   ./scripts/setup-github-project.sh --repo-owner <org> --repo-name <repo-central>
   ```
3. **Esperado (AC-11)**: `Project → Settings → Linked Repositories` lista todos os repos
   de `bounded-contexts.yaml`.
4. Rode o script novamente.
5. **Esperado (AC-12)**: saída mostra `↻ Já vinculado` para cada repo, sem duplicar.
6. Renomeie/mova `docs/bounded-contexts.yaml` temporariamente e rode o script.
7. **Esperado (AC-13)**: aviso "docs/bounded-contexts.yaml não encontrado — pulando
   vínculo de repos", e o restante do setup completa normalmente (exit code 0).

### Regressão do bug da issue #21 (fix desta sessão)

Para confirmar o fix de `$GIT_ROOT`:
1. Clone o template em `/tmp/nimbus-code`.
2. Em outro projeto (`~/meu-app`, com seu próprio `docs/bounded-contexts.yaml`), rode:
   ```bash
   cd ~/meu-app
   /tmp/nimbus-code/scripts/setup-github-project.sh
   ```
3. **Esperado**: o script lê `~/meu-app/docs/bounded-contexts.yaml` (não o do clone em
   `/tmp`) — confirmado por código: `_GIT_ROOT` agora vem de `git rev-parse --show-toplevel`
   sem `-C` (resolve contra `$PWD` do chamador), com fallback para o diretório do script
   apenas se o chamador não estiver num repo git com o arquivo.

---

## Notes

- Itens marcados ⏳ requerem um ambiente GHE real com efeitos colaterais reais (criação/
  vínculo de Project V2) e ficam para validação manual pelo Dev antes do primeiro uso em
  produção — consistente com `plan.md` ("Testing: Manual contra repo sandbox; sem CI
  automatizado para GHE API").
- Os testes automatizados (Step 1) cobrem toda a lógica determinística que não depende
  da API do GHE, reduzindo a superfície de validação manual necessária.
