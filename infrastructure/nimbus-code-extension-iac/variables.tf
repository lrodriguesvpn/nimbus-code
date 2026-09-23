variable "project_name" {
  type        = string
  description = "Nome do projeto para padronização de nomenclatura de recursos."
  default     = "nimbus-code"
}

variable "environment" {
  type        = string
  description = "Ambiente de deployment (ex: dev, staging, prod)."
  default     = "prod"
}

variable "location" {
  type        = string
  description = "Região Azure onde os recursos serão provisionados."
  default     = "eastus2"
}

variable "tags" {
  type        = map(string)
  description = "Tags padronizadas para governança de custos e recursos."
  default = {
    Project    = "Nimbus-Code-Framework"
    ManagedBy  = "Terraform"
    Owner      = "VPN-Engenharia"
    Compliance = "LGPD-Audit-5Y"
    CostCenter = "VPN-SaaS-Gov"
  }
}

variable "db_admin_username" {
  type        = string
  description = "Nome de usuário administrador para o Azure Database for PostgreSQL."
  default     = "nimbus_admin"
}

variable "db_admin_password" {
  type        = string
  description = "Senha do administrador para o Azure Database for PostgreSQL (recomenda-se injetar via secret ou CI/CD)."
  sensitive   = true
  default     = null
}

variable "container_image" {
  type        = string
  description = "Imagem docker do backend de Entitlement / Telemetria."
  default     = "mcr.microsoft.com/azuredocs/aci-helloworld:latest"
}

variable "audit_retention_days" {
  type        = number
  description = "Período de retenção e imutabilidade WORM para auditoria (5 anos = 1825 dias)."
  default     = 1825
}
