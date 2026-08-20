# Checklist de Aderência ao CAF — `<Cliente/Tenant>` / `<platform-id>`

<!--
  Checklist por nuvem de aderência ao Cloud Adoption Framework (CAF) /
  Well-Architected Framework correspondente. Preencher junto com o `design.md`
  da Landing Zone na fase `landing_zone_generated`.

  Salvar em: landing-zone/<platform-id>/checklist-caf.md

  Marcar cada item como:
    ✅ conforme — confirmado com diff-zero no platform-graph.yaml
    ⚠️ parcial  — iniciado mas sem diff-zero ainda
    ❌ ausente  — não implementado (registrar como gap no design.md)
    N/A         — não aplicável para esta nuvem/plataforma
-->

## Nuvem: Azure (CAF — Cloud Adoption Framework for Azure)

> Referência: https://learn.microsoft.com/azure/cloud-adoption-framework/

### Organização e Governança

- [ ] Hierarquia de Management Groups definida (Root → Platform → Landing Zones → Sandbox)
- [ ] Azure Policy aplicada no nível de Management Group (não apenas em subscription)
- [ ] Políticas de conformidade: tags obrigatórias, localização permitida, SKUs aprovados
- [ ] Azure Blueprints / Deployment Stacks ou equivalente Terraform para LZ bootstrap
- [ ] RBAC mínimo: sem permissões Owner/Contributor diretas em subscription (usar grupos)
- [ ] Entra ID: grupos de acesso por função (não por usuário direto)
- [ ] Privileged Identity Management (PIM) ativo para roles críticas

### Conectividade (Hub-Spoke ou Virtual WAN)

- [ ] VNet Hub centralizada com peering para todas as spokes
- [ ] Azure Firewall (ou NVA equivalente) como ponto único de saída
- [ ] DNS privado: Private DNS Zones linkadas ao hub
- [ ] ExpressRoute / VPN Gateway configurado (se aplicável)
- [ ] NSGs em todas as subnets com regras documentadas em IaC
- [ ] DDoS Protection Standard (se carga pública)

### Segurança e Conformidade

- [ ] Microsoft Defender for Cloud habilitado em todas as subscriptions
- [ ] Log Analytics Workspace centralizado (Management Subscription)
- [ ] Diagnóstico de todos os recursos críticos enviando para Log Analytics
- [ ] Microsoft Sentinel ou equivalente SIEM configurado
- [ ] Key Vault por workload (não compartilhado entre workloads diferentes)
- [ ] Soft Delete + Purge Protection habilitados nos Key Vaults de prod
- [ ] Nenhuma credencial/secret em código ou state Terraform

### Gestão de Custos

- [ ] Orçamentos e alertas por subscription configurados
- [ ] Tags obrigatórias por Azure Policy: `CostCenter`, `Environment`, `Owner`, `Project`
- [ ] Cost Management + Billing habilitado com acesso ao time de FinOps

### Automação e IaC

- [ ] Backend Terraform remoto (Azure Storage / Terraform Cloud) — nunca state local
- [ ] State separado por plataforma/ambiente (não um único state para tudo)
- [ ] Drift-check agendado (workflow de `terraform plan` periódico) configurado
- [ ] Nenhuma credencial de `apply` contra produção neste repositório de plataforma

---

## Nuvem: AWS (Well-Architected Framework + Control Tower)

> Referências: https://aws.amazon.com/architecture/well-architected/ e
> https://aws.amazon.com/controltower/

### Organização e Governança

- [ ] AWS Organizations com múltiplas contas (não tudo em conta raiz)
- [ ] SCPs (Service Control Policies) no nível de OU, não de conta individual
- [ ] AWS Control Tower Landing Zone (ou equivalente Terraform) ativo
- [ ] AWS Config habilitado em todas as contas e regiões usadas
- [ ] CloudTrail habilitado em nível de organização (não apenas por conta)
- [ ] IAM Identity Center (SSO) — sem IAM Users locais com acesso persistente

### Conectividade

- [ ] AWS Transit Gateway ou VPC Peering centralizado
- [ ] VPC por conta/ambiente — não compartilhar VPC entre prod e dev
- [ ] Security Groups documentados em IaC (sem regras 0.0.0.0/0 em prod)

### Segurança e Conformidade

- [ ] AWS Security Hub habilitado em nível de organização
- [ ] Amazon GuardDuty habilitado em todas as contas
- [ ] AWS Macie para dados sensíveis (se aplicável)
- [ ] Secrets Manager para credenciais — nenhum hardcode

### Gestão de Custos

- [ ] AWS Budgets por conta e por tag configurados
- [ ] Cost Allocation Tags obrigatórias por SCP

### Automação e IaC

- [ ] Backend Terraform S3 + DynamoDB lock
- [ ] State separado por conta/ambiente
- [ ] Drift-check agendado configurado

---

## Nuvem: GCP (Cloud Foundation Toolkit + Well-Architected)

> Referências: https://cloud.google.com/architecture/framework e
> GoogleCloudPlatform/cloud-foundation-toolkit

### Organização e Governança

- [ ] Google Cloud Organization criada (não apenas projetos avulsos)
- [ ] Hierarquia: Org → Folders (Plataforma, Produção, Dev) → Projetos
- [ ] Organization Policies definidas no nível de Org ou Folder
- [ ] Cloud Identity / Workspace: grupos de segurança para RBAC (não usuários diretos)

### Conectividade

- [ ] Shared VPC configurada (host project separado)
- [ ] Cloud Armor para workloads públicos
- [ ] Cloud DNS privado configurado

### Segurança e Conformidade

- [ ] Security Command Center habilitado
- [ ] Cloud Logging exportado para sink centralizado (Cloud Storage / BigQuery / Pub/Sub)
- [ ] Secret Manager para credenciais

### Gestão de Custos

- [ ] Budgets e alertas por projeto/folder configurados
- [ ] Labels obrigatórias por Organization Policy

---

## Plataforma: Microsoft 365 (Microsoft 365 DSC + CIS Benchmark)

> Referência: https://microsoft365dsc.com/ e CIS Microsoft 365 Foundations Benchmark

### Identidade e Acesso

- [ ] Conditional Access: política de MFA para todos os usuários
- [ ] Conditional Access: bloqueio de países não utilizados
- [ ] PIM habilitado para roles de Administrador Global e similares
- [ ] Acesso de convidados (B2B) com revisão periódica configurada

### Proteção de Dados

- [ ] DLP policies configuradas para dados sensíveis (PII, financeiro)
- [ ] Microsoft Purview / Rótulos de confidencialidade configurados
- [ ] Políticas de retenção definidas para Exchange, SharePoint, Teams

### Segurança

- [ ] Microsoft Secure Score monitorado e meta definida
- [ ] Defender for Office 365 habilitado (Anti-phishing, Safe Links, Safe Attachments)
- [ ] Auditoria unificada habilitada

### Config-as-Code

- [ ] Todas as políticas acima exportadas via Microsoft365DSC e versionadas
- [ ] Diff-zero confirmado via `Test-M365DSCConfiguration`

---

## Plataforma: Dynamics 365 / Power Platform

> Referência: https://learn.microsoft.com/power-platform/guidance/

### Ambientes e ALM

- [ ] Ambientes separados por ciclo de vida: Dev, Hml, Prod (nunca customizar diretamente em prod)
- [ ] Solutions versionadas via `pac solution unpack` e diff-zero confirmado
- [ ] DLP Policies definidas por ambiente
- [ ] CoE Starter Kit instalado (ou equivalente de governança)

### Segurança

- [ ] Roles de segurança mínimas por usuário/equipe (sem System Administrator generalizado)
- [ ] Auditoria habilitada nos ambientes de prod/hml
