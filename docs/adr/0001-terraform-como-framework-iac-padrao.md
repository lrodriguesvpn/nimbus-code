# 0001 — Terraform como Framework IaC Padrão (Multi-Cloud)

- **Status:** Aceita
- **Data:** 2024-01-01
- **Autores:** @vpndev-platform-team
- **Contexto:** Organizacional (todos os projetos VPN Dev em AWS, GCP e Azure)
- **Revisores:** @vpndev-arch-board

---

## Contexto e Problema

A VPN Dev opera em múltiplos provedores de nuvem (AWS, GCP e Azure). Sem um
framework IaC padrão, cada time escolhia a ferramenta com que estava mais
familiarizado: CDK em projetos AWS-only, Bicep em projetos Azure, YAML direto
em GCP. Isso resultou em:

- Nenhum engenheiro conseguia operar infraestrutura fora do seu provedor habitual
- Revisões de PR de IaC exigiam conhecimento específico de cada ferramenta
- Módulos de IaC não eram reaproveitáveis entre projetos
- Auditorias de segurança precisavam entender 3+ linguagens de IaC

## Drivers de Decisão

- Portabilidade: módulos de IaC reaproveitáveis entre AWS, GCP e Azure
- Legibilidade: qualquer engenheiro da VPN Dev deve conseguir revisar um PR de IaC
- Maturidade: suporte ativo, registry público, ecossistema de providers robusto
- Integração com ferramentas de segurança: Checkov, tfsec, tflint têm suporte nativo

## Opções Consideradas

- **Opção A** — Terraform (HashiCorp/OpenTofu)
- **Opção B** — Pulumi
- **Opção C** — Ferramentas nativas de cada provedor (CDK, Bicep, Deployment Manager)
- **Opção D** — CDKTF (Terraform CDK)

## Análise das Opções

### Opção A — Terraform

- ✅ Suporte aos três provedores com módulos maduros
- ✅ HCL legível por qualquer engenheiro sem background de dev full-time
- ✅ Checkov, tfsec, tflint integrados ao pipeline de segurança
- ✅ Terraform Registry com módulos auditáveis
- ❌ State remoto exige cuidado (locking, backend protegido)
- ❌ Algumas features de provedores têm delay até aparecer no provider

### Opção B — Pulumi

- ✅ Usa linguagens de programação reais (TypeScript, Python, Go)
- ❌ Curva de aprendizado mais alta para infra engineers não-devs
- ❌ Ferramentas de segurança com suporte menos maduro que Terraform

### Opção C — Ferramentas nativas (CDK, Bicep, Deployment Manager)

- ✅ Zero abstração, acesso imediato a features novas do provedor
- ❌ Portabilidade zero: código AWS-CDK não funciona em Azure
- ❌ Revisores precisam dominar 3 ferramentas diferentes
- ❌ Módulos não são reaproveitáveis

### Opção D — CDKTF

- ✅ Combina expressividade de código com runtime Terraform
- ❌ Adiciona uma camada de abstração sem ganho claro para o perfil da VPN Dev
- ❌ Comunidade menor, risco de suporte reduzido

## Decisão

**Opção escolhida: Terraform (com OpenTofu como alternativa open-source aceita)**,
porque oferece o melhor equilíbrio entre portabilidade multi-cloud, legibilidade
para o perfil do time e integração com ferramentas de segurança já adotadas.

Usar ferramenta nativa de provedor (CDK, Bicep, Deployment Manager) é permitido
**somente como exceção justificada** e registrada no Architecture Decision Log
do `plan.md` da feature que a introduziu.

## Consequências

### Positivas

- Qualquer engenheiro da VPN Dev pode revisar IaC de qualquer projeto
- Módulos Terraform compartilháveis via registry interno
- Pipeline de segurança (Checkov + tflint) aplicado uniformemente

### Negativas / Trade-offs Assumidos

- Features muito novas de provedores (especialmente Azure) podem levar semanas
  para aparecer no provider Terraform — aceitar esse delay ou usar recurso nulo
  + provisionamento manual com registro de exceção
- State remoto protegido é responsabilidade de cada projeto (backend S3/GCS/Azure
  Blob + locking via DynamoDB/GCS/Azure Blob lease)

### Ações derivadas

- [x] Regra adicionada à `constitution-template.md` (princípio "Infraestrutura como Código")
- [x] Controle adicionado ao Security & DevSecOps Gate do `plan-template.md`
- [ ] Criar módulo interno de bootstrap de state backend para cada provedor

## Links

- [Documentação oficial Terraform](https://developer.hashicorp.com/terraform)
- [OpenTofu](https://opentofu.org/) — fork open-source aceito como alternativa
- [Checkov](https://www.checkov.io/) — scanner de segurança para Terraform
