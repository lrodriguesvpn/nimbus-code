<!--
  Este bloco é inserido pelo preset `vpndev-standards` (estratégia `append`) ao final
  do tasks-template.md nativo do Spec Kit — não substitui nenhuma seção/tarefa gerada
  pelo `/speckit-tasks`. Formaliza o checklist de qualidade que antes vivia em
  `references/devops-artifacts-catalog.md` e no Passo 6.3 da skill devops-planning.
-->

## VPN Dev — Checklist de Qualidade de Código, Testes e Observabilidade

*Aplicável a TODA tarefa desta lista que produz ou altera código (não apenas
infraestrutura) — traduz em ação as regras de "Qualidade e Processo" da
constituição da VPN Dev. Marcar como concluída somente após validar cada item
relevante ao artefato entregue pela tarefa.*

- [ ] `graph.yaml` e `graph.md` atualizados para refletir módulos adicionados ou
      alterados por esta tarefa (Graph Guard valida automaticamente na PR)
- [ ] Para complexidade S3/S4: `impact-map.md` atualizado e revisado antes do merge
- [ ] Critérios de aceitação da `spec.md` cobertos com ID de teste rastreável
      (ex.: `test_AC1_<descricao>`) — ou exceção justificada no `plan.md`
- [ ] Feature flag configurada e ativa para esta feature, conforme estratégia
      de release definida no `plan.md` (ou "N/A — deploy direct justificado")
- [ ] SLO medido em staging dentro dos limites definidos no SLO Gate do `plan.md`
      (ou "N/A — sem ambiente de staging disponível para esta tarefa")
- [ ] Revisão de código por IA (GitHub Copilot code review) solicitada no PR e
      sem findings High/Critical pendentes
- [ ] Teste de integração cobrindo o(s) critério(s) de aceitação do `spec.md`
      correspondente(s) a esta tarefa — ou exceção já justificada no `plan.md`
- [ ] Observabilidade instrumentada: logs estruturados, métricas e alertas
      mínimos para o componente entregue
- [ ] Se esta tarefa faz parte de uma arquitetura de microsserviços: correlation-id/
      trace-id propagado nas chamadas entre serviços e ponto de orquestração/
      coreografia identificado (ou "N/A" se monólito)
- [ ] Bugs encontrados durante o desenvolvimento/teste desta tarefa que não
      foram corrigidos aqui foram abertos como Issue no GitHub e atribuídos ao
      Copilot coding agent

## VPN Dev — Checklist de Qualidade para Tarefas de Infraestrutura/Deploy

*Aplicável apenas às tarefas desta lista que envolvem infraestrutura, pipelines,
containers ou deploy. Marcar como concluída somente após validar cada item
relevante ao artefato entregue pela tarefa.*

- [ ] Sem segredo hardcoded (usa variável, cofre de segredos ou secret do CI)
- [ ] Recurso provisionado 100% via IaC (nenhuma criação/alteração manual via
      console/CLI); framework usado é **Terraform**, ou a exceção (CDK/Bicep/
      Deployment Manager) está justificada no Architecture Decision Log do
      `plan.md`
- [ ] Versões fixadas (imagem base, action, provider) — sem `latest` implícito
- [ ] Permissões seguem least privilege (sem role ampla sem justificativa)
- [ ] Health checks / readiness-liveness definidos, quando aplicável
- [ ] Build multi-stage, quando aplicável (Docker)
- [ ] Testado localmente ou via `plan`/dry-run antes do merge
- [ ] Documentação/README do módulo ou serviço atualizada, se o contrato mudou
