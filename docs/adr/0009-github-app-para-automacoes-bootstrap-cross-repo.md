# ADR-0009: GitHub App para automacoes cross-repo do bootstrap

- **Status**: Em revisao
- **Data**: 2026-08-20
- **Autores**: Copilot (sessao de implementacao da feature 008)
- **Contexto**: `specs/008-bootstrap-governance-hardening`
- **Revisores**: a definir (owner de plataforma e administrador da organizacao)

---

## Contexto e problema

O bootstrap deste template instala e referencia automacoes que atuam alem do
escopo estrito do `GITHUB_TOKEN` nativo: garantir/criar GitHub Projects dos
repositorios, adicionar issues/PRs a boards, sincronizar o campo `Priority` e
atribuir issues ao Copilot coding agent. Ate aqui, o padrao adotado era usar
PATs de longa duracao (`VPNDEV_PROJECT_TOKEN`, `ADD_TO_PROJECT_PAT` e
`COPILOT_AGENT_ASSIGN_TOKEN`) vinculados a pessoas ou contas de servico.

A feature 008 amplia a direcao ja aberta pela ADR-0008. Enquanto a ADR-0008
tratou um caso read-only de seguranca org-wide, esta ADR trata automacoes
operacionais do bootstrap que escrevem em Projects e Issues.

O problema central continua o mesmo: PATs de longa duracao concentram acesso em
credenciais pouco auditaveis e com ciclo de vida acoplado a usuarios.

## Drivers de decisao

- Least privilege por workflow.
- Auditabilidade das automacoes no GHE.
- Compatibilidade retroativa durante o rollout.
- Reducao progressiva de dependencia de PAT classico no bundle.

## Opcoes consideradas

### Opcao A - GitHub App organizacional com fallback explicito para PATs

Cada workflow tenta primeiro emitir um token de instalacao de curta duracao via
`actions/create-github-app-token@v1`. Se o App ainda nao estiver configurado no
repositorio, o workflow reaproveita o secret legado e registra um `::warning::`
explicito.

**Vantagens**
- Mantem compatibilidade retroativa enquanto T005/T006 nao forem concluidas.
- Distingue acoes do App vs. acoes humanas nos logs.
- Permite permissoes explicitas por workflow.

**Desvantagens**
- Exige setup administrativo humano inicial.

### Opcao B - Manter PATs classicos

**Vantagens**
- Zero esforco de migracao imediata.

**Desvantagens**
- Mantem credenciais de longa duracao acopladas a usuarios.
- Nao melhora least privilege nem auditabilidade.

### Opcao C - Usar apenas `GITHUB_TOKEN` nativo

**Vantagens**
- Sem novos secrets.

**Desvantagens**
- Nao cobre automacoes cross-repo/org em APIs que exigem credencial fora do
  escopo padrao do repositorio.
- Nao resolve o caso dos workflows ja existentes do bootstrap.

## Decisao

**Opcao escolhida: Opcao A**, porque entrega o alvo de seguranca da feature sem
quebrar repositorios ja provisionados. A ADR-0008 permanece como precedente
arquitetural; esta ADR apenas estende o mesmo padrao para as automacoes
operacionais do bootstrap.

## Consequencias

### Positivas
- O bundle passa a preferir tokens efemeros de GitHub App.
- O rollout pode ocorrer repositorio a repositorio, sem corte abrupto.
- O padrao fica reutilizavel e documentado em `docs/github-app-auth-snippet.md`.

### Trade-offs assumidos
- Enquanto T005/T006 nao forem concluidas, ainda existe dependencia temporaria
  do PAT de fallback.
- A aprovacao humana de seguranca (T030) continua obrigatoria antes do merge.

### Acoes derivadas
- [ ] Criar o GitHub App `Nimbus Bootstrap Automation` e instala-lo na
      organizacao (T005, humano).
- [ ] Configurar `NIMBUS_APP_ID` e `NIMBUS_APP_PRIVATE_KEY` como secrets
      (T006, humano).
- [ ] Validar um repositorio piloto com o caminho GitHub App ativo antes de
      remover os PATs de fallback.

## Links
- `specs/008-bootstrap-governance-hardening/plan.md`
- `docs/github-app-auth-snippet.md`
- Precedente: `docs/adr/0008-github-app-para-varredura-de-seguranca-org-wide.md`

## Supersede
- Nao supersede nenhuma ADR anterior.
