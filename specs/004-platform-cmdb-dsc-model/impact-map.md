# Impact Map — Platform Preset CMDB + Security/Compliance DSC (S4)

## Objective

Entregar governanca multi-cloud com CMDB orientado a IA, baseline de seguranca/compliance e DSC versionado, sem degradar controles de identidade e auditoria.

## Success impact

- visibilidade unificada de ativos e controles;
- rastreabilidade completa de evidencias;
- validacao de infraestrutura com menor risco operacional no MVP (advisory);
- base pronta para endurecimento futuro (modo bloqueante por fases).

## Key risks and mitigations

### Risk 1: Falha de autenticacao/identidade entre provedores
- **Impacto**: coleta inconsistente e risco de auditoria.
- **Mitigacao**: SSO central unico + bloqueio de coleta sem contexto autenticado.

### Risk 2: Inventario parcial por limites de API
- **Impacto**: CMDB incompleto e falso senso de conformidade.
- **Mitigacao**: status `partial`, evidencias de lacuna e reprocessamento priorizado.

### Risk 3: Divergencia entre baseline e estado real em larga escala
- **Impacto**: volume alto de findings sem priorizacao.
- **Mitigacao**: classificacao por severidade e dominio + trilha de excecao.

### Risk 4: Atualizacao acima da janela de 24h
- **Impacto**: dados stale para governanca e validacao.
- **Mitigacao**: alerta de frescor por ambiente, fila de reexecucao e escalonamento.

### Risk 5: Adoption gap do advisory mode
- **Impacto**: findings ignorados.
- **Mitigacao**: excecao obrigatoria e follow-up rastreado por owner.

## Go/No-Go gates

1. SSO central validado em ambiente piloto.
2. Coleta multi-cloud com cobertura minima operacional definida.
3. CMDB consolidado com rastreabilidade de origem.
4. Baseline/compliance processado com classificacao de severidade.
5. DSC versionado com historico auditavel.
6. Janela operacional de 24h atendida em piloto.
7. Relatorio advisory integrado ao pipeline de infraestrutura.
8. Revisao humana S4 concluida.

## Rollback strategy

- manter feature flag `platform-preset-cmdb-governance` em modo restrito;
- rollback para versao anterior de contratos e perfil DSC;
- suspender apenas componente afetado (discovery, baseline ou dsc) preservando trilha.

## Post-implementation note

- scaffold materializado em `platform-governance/`
- remaining hardening items remain tracked in `tasks.md`

## Deferred decisions for post-MVP

- criterios para migracao de advisory para bloqueante;
- politica de retencao de longo prazo para evidencias de CMDB;
- thresholds de auto-remediacao por tipo de finding.
