<!--
  Este bloco é inserido pelo preset `vpndev-platform-standards` (estratégia
  `append`) ao final do tasks-template.md nativo do Spec Kit.
-->

## VPN Dev (Plataforma) — Checklist de Fechamento por Tarefa

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
- [ ] Se esta tarefa é importação/reconciliação de legado: label
      `type:legacy-import` aplicado, complexidade **S3 ou S4**, e
      **revisão humana** solicitada explicitamente (nunca mesclar apenas com
      aprovação automática)
- [ ] Se alguma superfície de plataforma tocada aqui é compartilhada por
      repositórios de workload, os donos desses repositórios foram
      notificados (issue ou menção) para atualizar seus `impact-map.md`
