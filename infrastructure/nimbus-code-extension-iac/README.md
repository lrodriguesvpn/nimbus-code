# Nimbus Code Extension — Infraestrutura Cloud Azure (Terraform)

Este diretório contém os manifestos de Infraestrutura como Código (IaC) em **Terraform** para provisionar o backend de governança, licenciamento e telemetria do **Nimbus Code Framework** na **Microsoft Azure**.

---

## 🏛️ Arquitetura Provisionada

```
+-----------------------------------------------------------------------------------+
| Azure Resource Group: rg-nimbus-code-prod-eastus2                                |
|                                                                                   |
|  [ Azure Container Apps ]                                                         |
|    └── ca-nimbus-code-entitlement-api (FastAPI - Escala a Zero)                   |
|                                                                                   |
|  [ Azure Database for PostgreSQL Flexible Server ]                                |
|    └── psql-nimbus-code-prod (Multi-Tenant, Licenças e Quotas)                   |
|                                                                                   |
|  [ Azure Storage Account (WORM 5y) ]                                              |
|    └── Container Imutável: audit-ledger-immutable (LGPD Art. 7º, IX e V)          |
|                                                                                   |
|  [ Azure Key Vault ]                                                              |
|    └── kv-nimbus-code-prod (Chave Mestra Ed25519 para emissão de leases)          |
|                                                                                   |
|  [ Azure Log Analytics Workspace ]                                                |
|    └── law-nimbus-code-prod (Monitoramento Central e Logs Estruturados)           |
+-----------------------------------------------------------------------------------+
```

---

## 💰 Estimativa de Custo Operacional

- **Container Apps (Consumption):** ~$30 - $80 / mês (Serverless, escala a 0 quando ocioso)
- **PostgreSQL Flexible (B1ms):** ~$60 - $150 / mês
- **Storage Account (Ledger WORM):** ~$15 - $40 / mês
- **Key Vault & Log Analytics:** ~$5 - $10 / mês
- **Total Estimado:** **~US$ 150 – 300 / mês** (Margem bruta de software > 95%)

---

## 🚀 Como Executar o Deploy

### 1. Pré-requisitos
- Terraform `>= 1.5.0`
- Azure CLI (`az login` autenticado na subscrição da VPN)

### 2. Inicialização e Planejamento
```bash
cd infrastructure/nimbus-code-extension-iac

# Inicializa os providers
terraform init

# Valida a sintaxe e configuração
terraform validate

# Gera o plano de execução
terraform plan -out=tfplan
```

### 3. Aplicação
```bash
terraform apply tfplan
```

---

## 🔒 Princípios de Segurança e Conformidade
- **Zero Source Leak:** Nenhum código-fonte transita ou é persistido nesta infraestrutura. Apenas metadados e contadores técnicos de tokens e gates.
- **BYO-LLM:** A VPN não atua como gateway de inferência de IA. O custo de tokens é faturado diretamente na conta do cliente (Copilot, OpenAI, Anthropic).
- **Imutabilidade WORM (5 Anos):** Os logs de auditoria atendem ao prazo prescricional de conformidade e LGPD.
