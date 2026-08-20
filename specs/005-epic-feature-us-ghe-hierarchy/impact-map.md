# impact-map.md — Feature 005: Epic/Feature/US Hierarchy no GHE com Spec Kit

> Obrigatório para S3/S4. Atualizar se a implementação divergir do plano.

---

## 1. Módulos Impactados

| Módulo | Tipo de impacto | Risco | Mitigação |
|---|---|---|---|
| `.specify/feature.json` | Adição de campo `epic_issue` (opcional) | Baixo — campo opcional não quebra fluxo existente | Validar que scripts existentes toleram o campo novo sem falhar |
| `scripts/setup-github-labels.sh` | Adição de 3 labels novos | Baixo — `--force` garante idempotência | Rodar 2x em sandbox antes de merge |
| `scripts/setup-github-project.sh` | Adição de Issue Types + 3 novas views | Médio — criação de Issue Types via GraphQL é irreversível na org (não há `deleteIssueType`) | Testar em org de sandbox antes de rodar em produção; verificar que Issue Types já existentes não são duplicados |
| `docs/developer-guide.md` | Adição de seção nova (append) | Baixo — sem remoção de conteúdo existente | Revisão de consistência com restante do guide |
| `/speckit-specify` | Parâmetro `EPIC_ISSUE` opcional | Baixo — sem `EPIC_ISSUE`, comportamento idêntico ao atual | Teste com e sem o parâmetro |
| `/speckit-taskstoissues` | Lógica de criação de sub-issues e deduplicação, via novo helper `.specify/scripts/bash/create-github-issue-hierarchy.sh` | Alto — erros aqui criam issues duplicadas ou vínculos errados no GHE | Deduplicação por ID `T00N`/marcador oculto deve ser validada antes do vínculo de sub-issue; testar re-execução; validado com chamadas `--dry-run` e `check-issue-types` somente-leitura contra o repo real |

---

## 2. Análise de Risco

### R001 — Issue Types duplicados na org (Médio)

**Cenário**: `setup-github-project.sh` é executado 2x na mesma org e cria Issue
Types duplicados (Epic, Epic).

**Probabilidade**: Média — a API GHE não impõe unicidade de nome em Issue Types.

**Impacto**: Issues existentes com o tipo antigo ficam com ID diferente do tipo
novo; a view de filtragem por tipo pode não funcionar corretamente.

**Mitigação**: Implementar verificação de Issue Types existentes ANTES de criar
(mesma lógica já usada para views e campos do Project V2). Usar `listIssueTypes`
antes de `createIssueType`.

**Plano de rollback**: Remover manualmente os Issue Types duplicados via UI
`Org Settings → Planning → Issue types`. Não é reversível via API atualmente.

---

### R002 — Sub-issues duplicadas em re-execução (Alto)

**Cenário**: `/speckit-taskstoissues` é executado 2x sobre o mesmo `tasks.md`
sem deduplicação, criando issues `T001` duplicadas.

**Probabilidade**: Alta — sem deduplicação, cada execução cria novas issues.

**Impacto**: Issues duplicadas poluem o board, o sub-issue progress fica
inconsistente, deduplicação posterior manual é custosa.

**Mitigação**: Implementar deduplicação por ID `T00N` — antes de criar cada
issue, buscar se já existe uma issue no repo com o label/campo identificador
`T00N`. Só criar se não existir; só vincular como sub-issue se ainda não
estiver vinculada ao parent correto.

**Plano de rollback**: Fechar/deletar issues duplicadas manualmente (ou via
script `gh issue delete`). O script de deduplicação deve ser o primeiro passo
implementado, antes da criação.

---

### R003 — Org sem Issue Types (GHE Server legado) (Baixo-Médio)

**Cenário**: Script de criação de Issue Types falha silenciosamente ou com erro
em org com GHE Server < 3.10 que não suporta Issue Types nativos.

**Probabilidade**: Baixa para `venha-pra-nuvem` (usa GHEC), média para repos
migrados de GHE Server.

**Impacto**: Issues criadas sem `type:`, hierarquia menos rastreável na UI.

**Mitigação**: Detectar suporte a Issue Types na abertura do script (query
`organization { issueTypes { ... } }`); se retornar erro ou lista vazia, ativar
modo degradado com labels `type:epic`, `type:feature`, `type:user-story` e
imprimir mensagem clara `[MODO DEGRADADO]`.

**Plano de rollback**: N/A — fallback é automático, sem rollback necessário.

---

### R004 — Limite de 100 sub-issues por parent (Baixo)

**Cenário**: Uma Feature com mais de 100 User Stories, ou uma User Story com
mais de 100 Tasks atinge o limite da GHE API de sub-issues.

**Probabilidade**: Muito baixa na prática (features bem dimensionadas têm 3-8
US e 5-15 tasks por US).

**Impacto**: A criação da sub-issue falha com erro da API após o limite.

**Mitigação**: Verificar o count de sub-issues existentes antes de tentar
adicionar; se `count >= 90`, imprimir aviso `[AVISO] Parent issue #N já tem
X sub-issues — limite da GHE API é 100. Considere dividir esta feature.` Se
`count >= 100`, abortar com mensagem de erro clara em vez de falha silenciosa.

**Plano de rollback**: N/A — erro é detectado antes da tentativa.

---

## 3. Plano de Rollback Geral

| Artefato | Reversão |
|---|---|
| `feature.json` (campo `epic_issue`) | Remover o campo manualmente — campo opcional, sem impacto em outros scripts |
| `setup-github-labels.sh` (labels novos) | Deletar labels `type:epic`, `type:feature`, `type:user-story` via `gh label delete` ou UI do repo |
| `setup-github-project.sh` (views novas) | Deletar views via UI do Project V2; Issue Types via `Org Settings → Issue types` |
| `developer-guide.md` | Reverter seção via `git revert` ou edição manual |
| Issues criadas em GHE | Script de limpeza `gh issue list --label speckit-taskstoissues | gh issue close` ou deleção manual |

---

## 4. Critérios de Go / No-Go

| Critério | Go | No-Go |
|---|---|---|
| Deduplicação por T00N validada | Re-execução sobre mesmo `tasks.md` não cria duplicatas | Qualquer duplicata criada em teste |
| Fallback de labels funcional | Script completa sem erro em org sem Issue Types | Erro fatal ou saída antecipada |
| Idempotência do setup-github-project.sh | 2ª execução retorna "já existe" para todos os itens | Qualquer item duplicado criado |
| Sub-issue progress no Project V2 | Campo nativo exibe % de conclusão por Feature | Campo ausente ou valor 0% mesmo com tasks fechadas |
| PR sem secrets detectados | `secret scanning` não retorna findings | Qualquer finding de secret |
