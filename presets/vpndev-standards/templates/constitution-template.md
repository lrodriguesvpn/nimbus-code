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

{CORE_TEMPLATE}
