# Quickstart Validation Guide — Platform Preset CMDB + Baselines

## Prerequisites

- acesso a tenant(s) no escopo Azure/AWS/GCP;
- acesso ao tenant M365;
- usuario com SSO corporativo habilitado;
- ambiente com permissao para leitura de inventario e politicas.

## Scenario 1 — Onboarding + SSO + escopo

1. iniciar nova execucao de plataforma;
2. selecionar provedores alvo no escopo;
3. autenticar com SSO corporativo.

**Expected result**
- sessao validada;
- escopo e identidade registrados na trilha de auditoria.

## Scenario 2 — Descoberta e consolidacao CMDB

1. executar coleta multi-cloud completa;
2. consolidar ativos e relacionamentos no CMDB.

**Expected result**
- registros de CMDB criados/atualizados;
- evidencias com origem e timestamp;
- sem perda de historico em nova coleta.

## Scenario 3 — Baseline, politicas e customizacoes

1. carregar baseline corporativo vigente;
2. comparar estado aplicado no tenant;
3. listar nao conformidades e customizacoes.

**Expected result**
- achados por severidade e dominio;
- customizacoes classificadas com impacto.

## Scenario 4 — Perfil DSC versionado

1. gerar novo perfil DSC a partir do estado consolidado;
2. atualizar baseline e regenerar perfil.

**Expected result**
- nova versao criada com delta explicito;
- versao anterior permanece auditavel.

## Scenario 5 — Validacao Terraform advisory

1. submeter artefatos de infraestrutura para validacao;
2. consumir relatorio advisory.

**Expected result**
- nao conformidades apontadas;
- trilha de excecao exigida para itens pendentes;
- pipeline segue no MVP sem bloqueio automatico.

## Scenario 6 — SLO operacional (24h)

1. verificar ultima consolidacao CMDB/DSC por ambiente;
2. medir janela entre execucoes completas.

**Expected result**
- 100% dos ambientes no escopo atualizados em ate 24h.
