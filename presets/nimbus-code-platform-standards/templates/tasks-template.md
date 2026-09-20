<!--
  Este bloco é inserido pelo preset `nimbus-code-platform-standards` (estratégia
  `append`) ao final do tasks-template.md nativo do Nimbus Code.
-->

## Nimbus-Code (Plataforma) — Checklist de Fechamento por Tarefa

- [ ] Nenhum comando de escrita/`apply` foi executado contra o ambiente real a
      partir desta tarefa (confirmar explicitamente — este repositório é
      somente-observação)
- [ ] Reconciliação zero-diff executada e evidência anexada ao PR (ver
      `plan.md` para a ferramenta correta do domínio)
- [ ] `platform-graph.yaml`/`.md` atualizados se alguma superfície foi
      adicionada/alterada/removida
- [ ] `legacy-inventory.md` atualizado se o status de cobertura IaC de algum
      recurso mudou
- [ ] `db-schema-registry.md` atualizado se algum schema de banco legado foi
      extraído/re-extraído nesta tarefa
- [ ] **Se esta tarefa avança o `iac_lifecycle_stage` de alguma plataforma:**
  - [ ] Gate de fase preenchido no `plan.md` com evidência do critério de saída
  - [ ] `platform-graph.yaml` atualizado com o novo `iac_lifecycle_stage`
  - [ ] Se avança para `landing_zone_generated`: `landing-zone/<platform-id>/design.md` e
        `checklist-caf.md` criados/atualizados e referenciados no `platform-graph.yaml`
  - [ ] Se avança para `discovery`: `nimbus-discovery-report.md` criado e referenciado
        em `platform-graph.yaml` (`discovery_report_ref`)
- [ ] Se esta tarefa é importação/reconciliação de legado: label
      `type:legacy-import` aplicado, complexidade **S3 ou S4**, e
      **revisão humana** solicitada explicitamente (nunca mesclar apenas com
      aprovação automática)
- [ ] Se houve estratégia de toggle: matriz de ativação por tenant/surface no
      `plan.md` preenchida, com evidência de rollout/rollback controlado
- [ ] Se alguma superfície de plataforma tocada aqui é compartilhada por
      repositórios de workload, os donos desses repositórios foram
      notificados (issue ou menção) para atualizar seus `impact-map.md`

## Nimbus-Code — Fechamento da Execução Agêntica

*Preencher no encerramento da feature/tarefa para consolidar custo de execução,
qualidade final, retrabalho e esforço humano do ciclo híbrido.*

- [ ] Tokens consumidos registrados (`input + output`) e vinculados ao artefato entregue
- [ ] Tempo total da execução registrado (início, fim e duração em minutos)
- [ ] Horas humanas registradas no campo apropriado do GitHub Project ou artefato equivalente
- [ ] Qualidade final resumida com status (`passed`, `passed_with_conditions` ou `failed`) e evidências
- [ ] Retrabalho ocorrido documentado com percentual aproximado e causa resumida
- [ ] Handoff final preenchido em `.nimbus/contracts/delivery-handoff.contract.yaml` ou contrato equivalente
