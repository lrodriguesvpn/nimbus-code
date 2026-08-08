<!--
  Este bloco é inserido pelo preset `vpndev-standards` (estratégia `append`) ao final
  do tasks-template.md nativo do Spec Kit — não substitui nenhuma seção/tarefa gerada
  pelo `/speckit-tasks`. Formaliza o checklist de qualidade que antes vivia em
  `references/devops-artifacts-catalog.md` e no Passo 6.3 da skill devops-planning.
-->

## VPN Dev — Checklist de Qualidade para Tarefas de Infraestrutura/Deploy

*Aplicável apenas às tarefas desta lista que envolvem infraestrutura, pipelines,
containers ou deploy. Marcar como concluída somente após validar cada item
relevante ao artefato entregue pela tarefa.*

- [ ] Sem segredo hardcoded (usa variável, cofre de segredos ou secret do CI)
- [ ] Versões fixadas (imagem base, action, provider) — sem `latest` implícito
- [ ] Permissões seguem least privilege (sem role ampla sem justificativa)
- [ ] Health checks / readiness-liveness definidos, quando aplicável
- [ ] Build multi-stage, quando aplicável (Docker)
- [ ] Testado localmente ou via `plan`/dry-run antes do merge
- [ ] Documentação/README do módulo ou serviço atualizada, se o contrato mudou
