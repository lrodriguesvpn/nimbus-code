# Contract: Workflow de Varredura Semanal (`security-compliance-scan.yml`)

**Feature**: `007-controle-seguranca-ghe-projetos-plataforma`

## Gatilho

```yaml
on:
  schedule:
    - cron: "0 13 * * 1" # toda segunda-feira, 10h BRT
  workflow_dispatch: {}    # execução manual sob demanda (não substitui o cron)
```

## Permissões e Secrets obrigatórios

| Secret | Uso | Obrigatório |
|---|---|---|
| `SECURITY_SCAN_APP_ID` | ID do GitHub App dedicado (ver ADR-0008) | Sim |
| `SECURITY_SCAN_APP_PRIVATE_KEY` | Chave privada do GitHub App (PEM) | Sim |
| `SECURITY_SCAN_APP_INSTALLATION_ID` | ID da instalação do App na organização | Sim |

O workflow **DEVE falhar explicitamente** (não silenciosamente) se qualquer um destes secrets estiver ausente — mesmo padrão já usado em `ensure-github-project.yml`.

```yaml
permissions:
  contents: read
```

## Passos (contrato de comportamento, não implementação)

1. Verificar secrets obrigatórios (falhar com `::error::` se ausente).
2. Gerar installation access token do GitHub App.
3. Resolver o flag `security.baseline_scan.org_wide_enabled` (OpenFeature) — se `false`, restringir a descoberta ao bounded context piloto (`spec-kit-workflow`); se `true`, descobrir todos os repositórios da organização.
4. Para cada repositório no escopo resolvido: avaliar cada `Controle de Segurança` (ver `data-model.md`) usando a API do GitHub (branch protection, required reviews, Actions permissions, secrets configurados).
5. Para o Projeto Plataforma: avaliar a matriz de permissões (`Perfil de Acesso`) do Project V2.
6. Para cada `Evidência de Auditoria` com `status != ok`: criar ou atualizar (idempotente por `id`) a Issue rastreável correspondente.
7. Publicar o resumo da execução (`Scan Run`) nos logs do workflow (`::notice::`) incluindo `repos_avaliados` e `repos_com_erro`.
8. Se `repos_com_erro / repos_avaliados > 5%`: emitir `::warning::` (não falhar a execução inteira).
9. Na 1ª execução de cada mês (ou via job agendado separado): consolidar o `Compliance Report` mensal a partir das execuções anteriores do mês.

## Saída esperada (contrato observável)

- 0 ou mais Issues criadas/atualizadas no formato definido em [`finding-schema.md`](./finding-schema.md).
- Log da execução contendo: total de repositórios avaliados, total com erro, lista de controles com pior conformidade.
- Nenhuma alteração de configuração aplicada nos repositórios avaliados (a automação é **somente leitura + relatório** — nunca corrige automaticamente, conforme decisão de clarificação registrada no `spec.md`).
