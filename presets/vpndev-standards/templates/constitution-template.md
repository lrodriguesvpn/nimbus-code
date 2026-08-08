# Princípios Não-Negociáveis da VPN Dev

<!--
  Este bloco é inserido pelo preset `vpndev-standards` (estratégia `wrap`) antes da
  constituição específica de cada projeto. Ele representa o conjunto MÍNIMO de regras
  que valem para TODO projeto da organização — o restante da constituição (abaixo)
  continua sendo preenchido normalmente via `/speckit-constitution` para o que for
  específico deste projeto.

  Alterar este arquivo é uma mudança de política organizacional, não de projeto:
  requer aprovação do time responsável pelos padrões da VPN Dev e deve seguir o
  mesmo controle de versão do preset (ver presets/vpndev-standards/preset.yml).
-->

## Segurança e Dados

- Nenhum segredo (senha, token, chave de API, certificado) pode ser commitado em
  texto plano em qualquer artefato versionado (código, IaC, pipelines, configs).
  Usar cofre de segredos (Secret Manager, Key Vault, GitHub/Azure DevOps secrets).
- Toda conexão com banco de dados gerenciado exige TLS/mTLS obrigatório.
- Toda instância de banco de dados relacional deve habilitar, no mínimo, logs de
  conexão/desconexão, auditoria de statements DDL e duração de query.
- Buckets/containers de armazenamento usados para dados de auditoria ou logs
  arquivados devem ter logging de acesso habilitado e política de retenção.

## Infraestrutura como Código

- **Toda infraestrutura é código, sem exceção**: nenhum recurso em nuvem
  (AWS, GCP ou Azure) é criado ou alterado manualmente via console/CLI em
  ambiente compartilhado — sempre via IaC versionado e revisado em Pull
  Request.
- **Terraform é o framework padrão para os três provedores** (AWS, GCP e
  Azure). Usar a ferramenta nativa do provedor (ex.: AWS CDK, Bicep/ARM,
  Google Cloud Deployment Manager) só é permitido como **exceção
  justificada**, registrada no Architecture Decision Log do `plan.md` da
  feature que a introduziu — nunca como escolha silenciosa ou "porque o time
  prefere".
- Least privilege por padrão: nenhuma role/permissão de IAM ampla (ex.: `Owner`,
  `roles/editor`, papéis "básicos") sem justificativa explícita registrada no plano.
- Versões de imagens base, actions de CI e providers Terraform devem ser fixadas
  (pin), nunca `latest`/sem versão.
- Toda alteração de infraestrutura passa por `terraform plan`/equivalente revisado
  em Pull Request antes de aplicar em qualquer ambiente compartilhado.

## Qualidade e Processo

- Nenhuma implementação de feature relevante começa sem uma especificação formal
  (`/speckit-specify` → `/speckit-plan` → `/speckit-tasks` → `/speckit-implement`).
- Todo Pull Request que altera infraestrutura ou lógica de autorização/segurança
  exige pelo menos uma revisão humana antes do merge.
- Achados de ferramentas de SAST/IaC scanning (ex.: CodeQL, Checkov, tflint)
  classificados como High/Critical bloqueiam o merge, salvo supressão documentada
  com justificativa técnica explícita no próprio código (comentário de skip).
- Todo Pull Request passa por revisão de qualidade de código assistida por IA
  (GitHub Copilot code review) antes do merge, **em complemento** à revisão
  humana já exigida acima — nunca em substituição a ela. Findings High/Critical
  do Copilot bloqueiam o merge sob a mesma régua do SAST/IaC scanning.
- Cada critério de aceitação declarado em `spec.md` deve ter, sempre que
  tecnicamente viável, um teste de integração automatizado correspondente — não
  apenas cobertura por testes unitários isolados. Exceções (ex.: dependência
  externa indisponível em CI) exigem justificativa explícita registrada no
  `plan.md`.
- Observabilidade (logs estruturados, métricas e alertas) é obrigatória para
  todo componente/serviço novo ou alterado de forma relevante — não é opcional.
- Em arquiteturas de microsserviços/distribuídas: propagação de correlation-id
  (ou trace-id via W3C Trace Context) ponta a ponta entre serviços, e
  visibilidade documentada da orquestração/coreografia entre eles, são
  obrigatórias.
- Todo bug identificado (em CI, produção ou revisão de código) que não for
  corrigido dentro da própria tarefa em andamento deve ser aberto
  automaticamente como Issue no GitHub e atribuído ao Copilot coding agent —
  nunca deixado apenas registrado em log/alerta sem rastreamento formal.

Ver o detalhamento técnico de como aplicar estas regras (como solicitar a
revisão do Copilot, padrão de correlation-id/tracing, e como automatizar a
abertura/atribuição de bugs) em
[`docs/ai-code-quality-and-observability.md`](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/speckit-vpndev-standards/blob/main/docs/ai-code-quality-and-observability.md)
do repositório `speckit-vpndev-standards`.

{CORE_TEMPLATE}
