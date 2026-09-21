# Avaliação Preliminar de Privacidade e LGPD (Para Revisão do DPO)

**Feature:** `026-template-usage-governance` (Governança de Propriedade Intelectual e Auditoria de Uso do Template Nimbus Code)  
**Data:** 2026-09-21  
**Versão:** 1.0 (Rascunho de Engenharia & DevSecOps)  
**Status:** Aguardando Parecer Formal do DPO (`[NEEDS CLARIFICATION: dpo-review]`)

---

## 1. Contexto e Objetivo do Tratamento

O template **Nimbus Code** é um ativo de propriedade intelectual (IP) corporativo contendo padrões de arquitetura, automações e inteligência de agentes de IA. Para coibir vazamento de código, uso não autorizado fora da infraestrutura corporativa e permitir a rastreabilidade necessária para futura oferta do produto como serviço (SaaS multi-tenant), a engenharia propõe um mecanismo de autorização, licenciamento (lease offline de 30 dias) e auditoria centralizada de inicializações e atualizações de repositórios.

---

## 2. Inventário de Dados Pessoais Coletados

| Dado Pessoal | Categoria | Finalidade Específica | Coletado de Quem? |
|---|---|---|---|
| **Identificador do Usuário (Username GHE / OIDC Subject)** | Identificador corporativo | Identificar a autoria da inicialização ou atualização do template | Empregados, terceiros e clientes autorizados |
| **E-mail Corporativo** | Contato / Identificador | Rastreabilidade e notificação em caso de auditoria ou incidente | Empregados, terceiros e clientes autorizados |
| **Endereço IP (Público / Conexão)** | Dado de conexão telemática | Localização de rede no momento do acesso para detecção de anomalias/fraude | Todos que executarem `bootstrap`/atualização |
| **Identificador da Máquina (Hostname / Device GUID)** | Identificador técnico de terminal | Vincular o lease offline ao dispositivo autorizado, impedindo distribuição descontrolada | Todos que executarem `bootstrap`/atualização |
| **Metadados de Repositório (Nome, Org, Branch)** | Metadado técnico / ativo | Mapear onde o template foi instanciado e qual versão foi aplicada | N/A (associado ao usuário) |
| **Timestamp UTC** | Metadado temporal | Linha do tempo imutável do evento de auditoria | N/A |

> **Nota:** Não são coletados dados pessoais sensíveis (Art. 5º, II da LGPD) como biometria, saúde, raça ou opinião política.

---

## 3. Hipótese Legal Proposta (Base Legal - Art. 7º LGPD)

1. **Legítimo Interesse do Controlador (Art. 7º, IX da LGPD):**
   - *Finalidade legítima:* Prevenção a fraudes, segurança da informação e proteção da propriedade intelectual e segredos industriais da organização contra extração ou cópia indevida.
   - *Teste de Ponderação (LIA - Legitimate Interests Assessment) Preliminar:* O titular (desenvolvedor em ambiente de trabalho ou cliente corporativo) possui a justa expectativa de que ferramentas corporativas e ativos intelectuais tenham seu uso monitorado e registrado para fins de segurança.
2. **Execução de Contrato (Art. 7º, V da LGPD):**
   - No caso de clientes externos (SaaS multi-tenant), o tratamento é estritamente necessário para a verificação de licenciamento contratado e aplicação dos termos de serviço acordados.
3. **Exercício Regular de Direitos (Art. 7º, VI da LGPD):**
   - Preservação probatória de evidências de auditoria para fins de defesa em processos judiciais, administrativos ou arbitrais relativos a quebra de IP ou incidentes de segurança.

---

## 4. Política de Retenção e Descarte Proposta

- **Prazo de Retenção:** **5 (cinco) anos**.
- **Justificativa Jurídica/Técnica do Prazo:**
  - Alinhamento com o prazo prescricional geral de reparação civil e infrações contratuais / propriedade intelectual (Código Civil Brasileiro, Art. 206, § 5º).
  - Padrão do setor para trilhas de auditoria de segurança da informação (ISO/IEC 27001 e SOC 2).
- **Mecanismo de Descarte:** Expiração e expurgo automatizado via política de ciclo de vida nos logs consolidados após 5 anos do registro do evento.

---

## 5. Medidas de Segurança e Salvaguardas Técnicas

1. **Minimização de Dados:** Nenhum dado pessoal adicional (como conteúdo de arquivos locais, histórico de digitação ou credenciais de usuário) é coletado — apenas os metadados estritos de conexão e autoria do evento.
2. **Criptografia em Trânsito e em Repouso:** Todos os eventos trafegam via TLS 1.3 e são armazenados com criptografia em repouso (AES-256).
3. **Controle de Acesso Baseado em Papéis (RBAC):** Os logs consolidados são de acesso restrito a auditores credenciados de DevSecOps, Segurança da Informação e DPO. Desenvolvedores não possuem acesso indiscriminado aos logs de outros colegas.
4. **Isolamento Multi-Tenant:** Em ambiente SaaS, os logs de um cliente/tenant são isolados e jamais expostos a outro tenant.
5. **Transparência:** O script de inicialização e as instruções de uso incluirão aviso prévio claro de que a inicialização registra telemetria e auditoria corporativa.

---

## 6. Questionamentos e Itens para Parecer do DPO

O time de Engenharia e Arquitetura solicita avaliação do DPO nos seguintes tópicos:

1. [ ] **Validação do LIA:** O DPO valida a aplicação do Legítimo Interesse para a coleta de IP e Hostname no contexto de proteção de IP institucional?
2. [ ] **Retenção de 5 Anos:** O prazo de 5 anos está adequado ou deve ser ajustado para um período diferente para usuários internos vs clientes externos?
3. [ ] **Texto do Aviso de Privacidade:** O DPO aprova a inserção do seguinte aviso antes da execução do bootstrap:
   > *"Aviso de Conformidade: A inicialização e atualização deste template coletam dados de identificação corporativa, endereço IP e identificador de dispositivo para fins de segurança, auditoria de licença e proteção de propriedade intelectual (Retenção: 5 anos). O uso não autorizado é monitorado."*
4. [ ] **Mecanismo para Exercício dos Direitos dos Titulares:** Procedimento para atender a eventuais solicitações de confirmação de tratamento ou cópia de logs vinculados a um titular específico.

---
*Documento vinculado à especificação `specs/026-template-usage-governance/`.*
