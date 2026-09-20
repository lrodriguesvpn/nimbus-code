# Impact Map: Bootstrap Governance & Repo Provisioning Hardening

**Complexidade**: S4 (revisão humana obrigatória por release de governança,
autenticação cross-repo e piloto controlado — ver `plan.md`)

## Componentes Impactados

| Componente | Tipo de Mudança | Risco |
|---|---|---|
| `bootstrap.sh` | Modificado (novo prompt interativo) | Médio — pode quebrar automações CI existentes que chamam `bootstrap.sh` sem `--repo-type` |
| `ensure-github-project.yml`, `add-to-repo-project.yml`, `sync-priority-field.yml`, `agent-auto-assign.yml` | Modificado (autenticação) | **Alto** — automações em produção; falha na migração pode interromper gestão de boards/labels em repositórios já ativos |
| `presets/nimbus-code-platform-standards/.github/ISSUE_TEMPLATE/` | Novo (hoje ausente) | Baixo — apenas adiciona template ausente |
| `scripts/validate-issue-template-parity.sh` | Novo | Baixo — script de validação, sem efeito colateral em produção |
| `docs/skills-distribution-guide.md` | Novo | Baixo — documentação |
| `bundles/*/bundle.yml`, `presets/*/preset.yml` | Modificado (bump de versão) | Alto — define a ref consumida por novos repositórios |
| `v1.19.0-rc.1` e `v1.19.0` | Novo (release/tag) | Alto — tag errada pode reproduzir artefatos incompletos |
| Perfil Platform (CMDB, zero-diff, baselines, lifecycle) | Ampliado | Alto — risco de induzir apply cloud fora de escopo |
| Perfil Dev Standards (gates, custo, harness/playbook, agentes) | Ampliado | Médio — risco de excesso de governança ou custo operacional |

## Failure Modes

### FM-1: Bootstrap CI quebra por exigir `--repo-type` em modo não-interativo

**Trigger**: Automação existente chama `bootstrap.sh` sem a nova flag `--repo-type`.

**Impacto**: Pipeline de provisionamento de repositório falha.

**Mitigação**: Documentar a mudança com destaque no changelog do bundle;
`bootstrap.sh` imprime mensagem de erro clara nomeando exatamente a flag
faltante e os valores aceitos.

### FM-2: Workflow migrado falha por GitHub App mal configurado

**Trigger**: `NIMBUS_APP_ID`/`NIMBUS_APP_PRIVATE_KEY` configurados incorretamente
(chave inválida, App não instalado no repositório).

**Impacto**: Workflow crítico (ex.: `ensure-github-project.yml`) para de
funcionar num repositório específico.

**Mitigação**: Falha fechada antes da operação ampliada; aviso explícito com
instrução de configuração do App. Um fallback PAT só pode ser habilitado
explicitamente em modo de migração opt-in, com owner, prazo e auditoria.

### FM-3: Divergência entre os dois templates de issue não detectada a tempo

**Trigger**: PR altera um dos dois templates de issue sem que o workflow de
validação de paridade rode (ex.: workflow mal configurado ou desabilitado).

**Impacto**: Repositórios usando presets diferentes voltam a ter contratos de
issue divergentes — o problema original que esta feature resolve.

**Mitigação**: Workflow de CI (`validate-issue-template-parity.yml`) roda em
todo PR que toque qualquer um dos dois arquivos de template, bloqueando merge
em caso de divergência.

## Go/No-Go Gates

- [ ] **Gate 1**: GitHub App organizacional criado e instalado na organização
      (pré-requisito administrativo, humano)
- [ ] **Gate 2**: Pelo menos 1 workflow migrado validado em repositório piloto
      por 7 dias sem falha
- [ ] **Gate 3**: Validador de paridade de templates rodando em CI e bloqueando
      PR de teste com divergência proposital
- [ ] **Gate 4**: Revisão humana explícita de segurança aprovada (obrigatória
      por esta feature alterar mecanismo de autenticação em produção)
- [ ] **Gate 5**: `v1.19.0-rc.1` publicado a partir de commit em `main` e
      consumido pelos dois cenários do projeto piloto
- [ ] **Gate 6**: sete dias de evidência do piloto sem falha crítica; somente
      então promover `v1.19.0`

## Plano de Rollback

1. Reverter o PR desta feature via `git revert` — `bootstrap.sh` volta ao
   comportamento anterior (sem pergunta de tipo de repositório).
2. Workflows migrados: desativar o rollout via OpenFeature e bloquear a etapa
   cross-repo até correção. Não habilitar PAT automaticamente; se o modo de
   migração estiver autorizado, sua ativação deve continuar explícita e auditada.
3. Nenhuma migração de dado — rollback é puramente reversão de código/config.
4. Se a RC falhar, não criar `v1.19.0`; manter o tag candidato como evidência,
   corrigir em novo commit e publicar `v1.19.0-rc.2`.

## SLOs (referência para o Observability Gate)

| Componente | Latência p99 | Taxa de erro máx. | Disponibilidade |
|---|---|---|---|
| `bootstrap.sh` completo | 15000 ms | 1,0% | 99,0% |
| Emissão de token de instalação de GitHub App | 2000 ms | 0,5% | 99,9% |
