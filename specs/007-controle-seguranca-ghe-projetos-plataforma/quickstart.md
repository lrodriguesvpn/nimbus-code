# Quickstart: Validação da Documentação e Automação de Controle de Segurança GHE

**Feature**: `007-controle-seguranca-ghe-projetos-plataforma`

Este guia descreve como validar, de ponta a ponta, que a documentação e a automação
de varredura funcionam conforme os contratos definidos em [`contracts/`](./contracts).
Não contém código de implementação — apenas os passos e resultados esperados.

## Pré-requisitos

- Acesso de administrador à organização no GHE (para instalar o GitHub App).
- `gh` CLI autenticado com um usuário que tenha permissão de leitura na organização.
- GitHub App "Nimbus Code Security Auditor" criado e instalado na organização (ver ADR-0008) — passo manual, **fora do escopo de código** desta feature.
- Secrets configurados no repositório: `SECURITY_SCAN_APP_ID`, `SECURITY_SCAN_APP_PRIVATE_KEY`, `SECURITY_SCAN_APP_INSTALLATION_ID`.
- *(issue #450)* Permissões **read-only** adicionais do App concedidas (Code scanning alerts, Dependabot alerts, Secret scanning alerts, Organization Projects — ADR-0008, adendo; task T063).
- *(issue #450)* Nos repositórios piloto: Dependency graph, Dependabot alerts/security updates, GitHub Code Security e Secret Protection habilitados (T064); Rulesets e required checks configurados conforme `docs/security-baseline-ghe.md`, seções 9 e 10 (T065).

## Passo 1 — Validar a documentação publicada

```powershell
# A partir da raiz do repositório
Get-Content docs\security-baseline-ghe.md | Select-String "^## "
```

**Resultado esperado**: as 8 seções obrigatórias do [`documentation-contract.md`](./contracts/documentation-contract.md) aparecem como headings `##`.

## Passo 2 — Rodar a varredura manualmente (piloto)

```powershell
gh workflow run security-compliance-scan.yml
```

**Resultado esperado**:
- O workflow completa em até 30 min (SLO definido no `plan.md`).
- Log da execução mostra `repos_avaliados` e `repos_com_erro`.
- Com o flag `security.baseline_scan.org_wide_enabled=false` (piloto), apenas repositórios do bounded context `spec-kit-workflow` são avaliados.

## Passo 3 — Validar geração de Issue de não conformidade

1. Escolher um repositório de teste sem branch protection configurada.
2. Rodar o workflow (Passo 2).
3. Verificar que uma Issue foi criada no formato de [`finding-schema.md`](./contracts/finding-schema.md), com o marcador `<!-- security-baseline-finding-id: ... -->` e labels de prioridade.

```powershell
gh issue list --search "security-baseline-finding-id in:body" --label security-baseline
```

**Resultado esperado**: 1 issue por controle não conforme, sem duplicatas em execuções subsequentes (rodar o workflow uma 2ª vez e confirmar que o número de issues não dobra).

## Passo 4 — Validar que a automação não corrige nada automaticamente

Comparar a configuração do repositório de teste antes e depois da execução do workflow (branch protection, secrets, permissões de Actions).

**Resultado esperado**: nenhuma configuração foi alterada — apenas a Issue foi criada/atualizada (confirma a decisão de clarificação "detectar e reportar", não auto-remediação).

## Passo 5 — Validar o relatório mensal

Após pelo menos 1 execução semanal completa dentro do mês corrente, verificar a
Issue mensal `Relatório de Conformidade de Segurança — YYYY-MM` criada/atualizada
automaticamente pelo próprio workflow.

**Resultado esperado**: relatório no formato de
[`monthly-report-contract.md`](./contracts/monthly-report-contract.md),
incluindo % de conformidade por controle e lista de desvios abertos/fechados.

## Passo 6 — Validar rollout progressivo (flag)

1. Confirmar que, com o flag desligado, apenas o bounded context piloto é varrido (Passo 2).
2. Após 2 execuções semanais sem erro de API/permissão, alternar o flag `security.baseline_scan.org_wide_enabled` para `true`.
3. Rodar o workflow novamente e confirmar que **todos** os repositórios da organização aparecem no log (`repos_avaliados` aumenta para o total da organização).

## Passo 7 — Validar kill switch

Desativar o flag principal e confirmar que o workflow continua rodando (logs/relatório) mas **para de criar novas issues** (modo dry-run), conforme definido no Plano de Toggle e Rollout do `plan.md`.

## Passo 8 — Validar localmente a configuração e os testes (issue #450)

```bash
bash scripts/validate-security-governance.sh      # check governance-config
bash scripts/validate-repo-static.sh --allow-missing-tools
./scripts/run-tests.sh                            # inclui os testes de fixtures da varredura
```

**Resultado esperado**: `governance-config` válido (avisos apenas para
workflows legados sem SHA/permissions) e todos os testes passando — sem
chamada à API real e sem secrets.

## Passo 9 — Validar bloqueio de PR no piloto (issue #450)

Abrir PRs de teste contra `main` (e contra uma branch `release/*`) com, um de
cada vez: teste quebrado, dependência com CVE high, secret fictício de teste e
uma alteração que remova um check obrigatório.

**Resultado esperado**: os checks `governance-config`, `build`, `unit-tests`,
`CodeQL`, `dependency-review` e `secret-scan` são reportados; cada falha
proposital bloqueia o merge; nenhum check obrigatório fica "Expected — waiting".

## Passo 10 — Validar os 18 controles da varredura (issue #450)

```powershell
gh workflow run security-compliance-scan.yml -f dry_run=true
```

**Resultado esperado**: o log mostra, para cada repositório do piloto, os 18
controles de repositório com evidência `repository | branch/padrão | endpoint
-> HTTP | resultado`; controles indisponíveis no plano aparecem como
`pendente` e 403 como erro explícito em `repos_com_erro` — nunca como `ok`;
nenhuma issue é criada em dry-run e nenhuma configuração é alterada.

## Passo 11 — Validar exceções (issue #450)

Registrar uma exceção de teste com `expires_at` no passado em
`.github/security-exceptions.json` em um PR.

**Resultado esperado**: o check `governance-config` falha citando a exceção
expirada.

---

## Critério de "feature pronta para produção" (Go/No-Go)

- [ ] Passos 1–7 acima executados com sucesso em ambiente piloto
- [ ] Nenhum falso positivo relatado pelos times do bounded context piloto
- [ ] Aprovação humana obrigatória (S4) do plano e do ADR-0008 registrada
- [ ] Rotação inicial da chave privada do GitHub App agendada (ver risco no `plan.md`)
- [ ] *(issue #450)* Passos 8–11 executados no piloto com evidência anexada (T066)
- [ ] *(issue #450)* Permissões adicionais do App confirmadas como read-only e suficientes (T063)
- [ ] *(issue #450)* Rollout org-wide continua bloqueado até a aprovação S4 (T038) — o flag `security.baseline_scan.org_wide_enabled` não é alterado por esta entrega
