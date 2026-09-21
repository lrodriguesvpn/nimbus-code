# Modelo de Entrevista de Descoberta — `026-template-usage-governance`

<!--
  Guia de entrevista para a fase de DESCOBERTA (antes de escrever o spec.md).
  Feature: 026-template-usage-governance (IP Protection & Template Usage Governance)
-->

## Cabeçalho

| Campo | Valor |
|---|---|
| **Data** | 2026-09-21 |
| **Solicitante/Cliente** | Liderança Técnica / Mantenedores do Nimbus Code |
| **Facilitador** | NC-Intake (Nimbus Agent) |
| **Canal** | assíncrono (sessão interativa) |
| **Feature slug (se já souber)** | `026-template-usage-governance` |
| **Prioridade inferida (uso interno — não ler ao cliente)** | P0-blocker |
| **Versão deste modelo** | v1.3 |
| **Modo desta entrevista** | Completo |
| **Duração real** *(preencher no Encerramento)* | 25 minutos |

---

## Bloco 1 — Negócio (o quê e por quê) — **obrigatório**

1. ⚡ **Qual problema ou necessidade você está tentando resolver? Para quem?**
   - Impedir a inicialização e o uso não autorizado deste template fora do ambiente corporativo (GHE oficial), protegendo a propriedade intelectual (IP) contra vazamento/cópia descontrolada.
   - Registrar auditoria centralizada completa de todas as inicializações e atualizações (quem inicializou/atualizou, quando, em qual máquina/IP e qual repositório).
   - Criar uma arquitetura de proteção/licenciamento que suporte tanto o uso interno atual quanto uma evolução futura para empacotamento e venda do Nimbus Code como serviço (SaaS multi-tenant / artefato distribuído).
   - Público: Engenharia interna, clientes corporativos e futuros assinantes do serviço.

2. **Como isso é feito hoje — manualmente, ou já existe um sistema/ferramenta que faz isso?**
   - Hoje o template é público/acessível via Git puro com execução de `bootstrap.sh`. Qualquer pessoa com acesso ao repositório ou a um fork/cópia consegue inicializar ou atualizar projetos sem validação prévia de autorização, sem checagem de permissão de tenant e sem envio de auditoria centralizada.

3. ⚡ **O que "pronto" significa para você — como saberemos que funcionou?**
   - Tentativas de bootstrap ou atualização fora do escopo corporativo/autorizado são bloqueadas imediatamente, impedindo a instalação de componentes protegidos.
   - Proibição de forks não autorizados e controle de inicialização via artefatos privados (entitlement/licença).
   - Cada evento de bootstrap, inicialização ou atualização gera log auditável registrando ator, máquina, IP, repositório e timestamp com retenção de 5 anos.
   - Suporte a modo offline temporário (até 30 dias com lease/licença criptográfica válida).
   - Arquitetura desacoplada pronta para multi-tenant (clientes internos e externos).

4. **Quem usa isso no dia a dia?**
   - Desenvolvedores e Tech Leads ao iniciar novos projetos ou atualizar presets.
   - Engenheiros de Plataforma e Administradores de Governança para auditoria.
   - Time de Segurança / DPO / Jurídico para auditoria de conformidade e proteção de ativos.
   - Futuros clientes externos / tenants consumidores da plataforma como serviço.

5. ⚡ **O que definitivamente não faz parte deste pedido agora (fora de escopo)?**
   - Bloquear a leitura de arquivos estáticos puramente públicos de documentação básica em markdown.
   - Substituir o GHE ou provedor Git existente por um servidor Git proprietário.
   - Implementação de gateway de cobrança/faturamento (billing financeiro) — o foco é o mecanismo de governança, entitlement e auditoria multi-tenant.

6. **Existe prazo ou evento que torna isso urgente?**
   - Sim: proteção imediata de IP institucional antes da expansão de uso do template entre múltiplos times e preparação para comercialização como produto.

7. **Se só pudesse resolver 1 coisa nesta entrega, qual seria?**
   - Bloquear inicialização não autorizada do template garantindo o registro de auditoria completo (quem, quando, máquina, IP, repo).

8. ⚡ **Quem dá o aceite final? E quem consegue travar?**
   - Aceite final: Liderança Técnica / Mantenedores do Nimbus Code.
   - Pode travar: DPO / Jurídico (validação de conformidade LGPD e retenção de 5 anos) e DevSecOps (arquitetura de chave/entitlement).

9. **Já foi tentado algo parecido antes que não funcionou?**
   - Validações apenas em client-side (scripts puramente em bash no repositório público) são facilmente burladas ou removidas se o código for copiado/bifurcado. É necessário desacoplar os componentes proprietários em artefatos privados protegidos por verificação de autorização/licença.

10. **O que essa demora está custando hoje?**
    - Risco permanente de vazamento de propriedade intelectual, perda de rastreabilidade de onde o template está instalado e impossibilidade de empacotar o template como oferta comercial segura.

11. **Algum outro time ou projeto já está trabalhando em algo parecido?**
    - Não. Padrões correlatos consultados: `bootstrap-github-app-auth` (specs/008), `single-source-multi-target-sync` (specs/024) e `ghe-sub-issues-hierarchy` (specs/005).

12. **Já existe orçamento/patrocínio aprovado para isso, ou ainda estamos validando viabilidade?**
    - Aprovado e prioritário pela plataforma institucional.

### Critérios de Aceite — **obrigatório, mínimo 4 critérios mensuráveis**

- **C1 — Bloqueio de Inicialização Não Autorizada:** O processo de bootstrap/instalação deve consultar a autorização corporativa via Web (sem exigir VPN exclusiva). Se o repositório, usuário ou tenant não for autorizado, o processo aborta imediatamente com erro claro e nenhum componente proprietário/protegido é instalado.
- **C2 — Distribuição Híbrida de Artefatos Protegidos:** O repositório mantém documentação e scaffold base acessíveis, enquanto os módulos centrais e regras de negócio/presets protegidos são empacotados como artefatos privados liberados apenas mediante token/lease de autorização válido. Proibição formal de fork sem credenciais de entitlement.
- **C3 — Auditoria Centralizada Completa:** Todo evento de inicialização de novo repositório ou atualização de template deve registrar: identidade do usuário (GHE / OIDC / e-mail), identificador da máquina/hostname, endereço IP de origem, repositório de destino, versão do template e timestamp UTC. Os logs são consolidados centralmente no ecossistema GHE / repositório de auditoria dedicado.
- **C4 — Suporte a Modo Offline Temporário (Lease de até 30 dias):** Desenvolvedores autorizados podem operar offline por até 30 dias corridos mediante token/licença de curta duração assinada criptograficamente. Após 30 dias sem renovação de conectividade, as operações restritas bloqueiam até nova sincronização.
- **C5 — Suporte Arquitetural Multi-Tenant:** O modelo de autorização e registro de auditoria deve isolar registros por tenant (organização/cliente), suportando tanto os times internos quanto clientes externos futuros.
- **C6 — Política de Retenção e Conformidade de 5 Anos:** Registros de auditoria de IP/máquina/usuário são retidos por 5 anos para fins de defesa de direitos, segurança e conformidade, com documento formal de fundamentação jurídica gerado para avaliação do DPO.

---

## Bloco 1.5 — Análise de Tamanho / Proposta de Quebra (opcional)

Dois sinais presentes (distribuição de artefatos privados + telemetria/auditoria + multi-tenant). Proposta de fatiamento vertical:
- **Fatia 1 (Core Governance):** Mecanismo de autorização Web, bloqueio de bootstrap, pacote de artefatos privados, lease offline de 30 dias e emissão de telemetria de inicialização/atualização.
- **Fatia 2 (Multi-Tenant & DPO Dashboard):** Gateway de gestão multi-tenant, portal de entitlements corporativos e relatórios de auditoria de 5 anos para compliance.

---

## Bloco 2 — Infraestrutura — **obrigatório, mas curto**

1. ⚡ **Onde isso vai rodar/ser hospedado?**
   - Acesso via Web pública segura (HTTPS/TLS 1.3) sem obrigatoriedade de VPN de rede fechada. Backend de autorização e consolidação de logs integrado ao GHE (GitHub Actions, GitHub Apps, repositório de logs / Azure Functions).
2. ⚡ **Isso é uma mudança dentro de um sistema que já existe (brownfield), ou é construído do zero (greenfield)?**
   - Brownfield: afeta `bootstrap.sh`, sincronizadores de agentes, distribuição de presets e esteira de release do Nimbus Code.
3. **Já existe um padrão, bounded context ou repositório de referência que essa solução deve seguir?**
   - Bounded context: `spec-kit-workflow` e `repository-provisioning`. Padrões de reuso: `bootstrap-github-app-auth` (docs/adr/0009).
4. ⚡ **Quem ou o quê vai acessar isso?**
   - Desenvolvedores internos, pipelines de CI/CD, clientes corporativos externos e ferramentas administrativas de auditoria.
5. **Existe expectativa de volume?**
   - Inicialmente centenas de inicializações/mês internamente; escalando para milhares de eventos/mês na evolução SaaS multi-tenant.
6. **Depende de integração com algum sistema já existente?**
   - GitHub Enterprise (GHE) API / GitHub App, OIDC/SSO corporativo e repositório central de logs/artefatos.
7. **Isso pode ficar fora do ar de vez em quando, ou precisa estar sempre disponível?**
   - Alta disponibilidade no serviço de emissão de licenças/autorizações. Graças ao lease offline de até 30 dias, indisponibilidades momentâneas de rede não bloqueiam o desenvolvedor no dia a dia.

---

## Bloco 3 — Segurança — **obrigatório, mas curto**

1. ⚡ **Este sistema expõe alguma informação sensível ou crítica para o negócio?**
   - Sim: Propriedade Intelectual crítica do Nimbus Code (código, presets, heurísticas dos agentes) e metadados corporativos (IP, máquina, repositórios).
2. **Quem pode e quem não pode acessar (perfis de autorização)?**
   - Usuário Comum: inicializar e atualizar repositórios autorizados em seu tenant durante o período de lease.
   - Admin do Tenant: gerenciar permissões de repositórios e visualizar métricas do seu tenant.
   - SecOps / Auditor Nimbus: acesso global aos logs consolidados de 5 anos.
   - Não autorizado: bloqueio imediato, sem download de artefatos privados.
3. **Existe exigência de autenticação corporativa (SSO/AD) ou pode usar um padrão mais simples?**
   - Autenticação via GitHub App / OIDC / GHE OAuth Token emitindo tokens assinados (JWT / PASETO) para validação do lease.
4. **Há necessidade de auditoria/trilha de "quem fez o quê"?**
   - Obrigatória e imutável por 5 anos: data/hora UTC, ator (usuário GHE), identificador da máquina, IP público/privado, repo destino, ação (init, update, check) e status (sucesso, negado, lease-expirado).

---

## Bloco 4 — LGPD / Proteção de Dados — **obrigatório, mas curto**

1. ⚡ **Este pedido envolve dado pessoal?**
   - Sim: username corporativo, e-mail corporativo, endereço IP e identificador de máquina (hostname/device ID).
2. **De quem são esses dados?**
   - Empregados internos, prestadores de serviço terceirizados e usuários de clientes externos (todos os usuários do template).
3. **Qual a base legal para tratar esse dado?**
   - Legítimo Interesse (Art. 7º, IX da LGPD) e Proteção de Ativos / Segurança da Informação e Cumprimento de Contrato (Art. 7º, V da LGPD). Requer parecer formal do DPO.
4. **Esses dados têm prazo de retenção definido?**
   - Retenção estrita de **5 anos** (alinhada aos prazos prescricionais de auditoria e segurança), com expurgo automático após o período.
5. **Esse dado sai da organização?**
   - Não há compartilhamento com terceiros não autorizados. Os dados são consolidados na infraestrutura controlada pela organização/GHE.

---

## Encerramento

- **Resumo em 3–5 linhas**: A feature 026 implementa governança estrita de IP e telemetria de uso para o Nimbus Code, bloqueando inicializações/atualizações não autorizadas fora do GHE corporativo e de tenants autorizados. A distribuição passa a utilizar artefatos privados combinados com código-fonte base, suporte a operação offline por até 30 dias via lease criptográfico e auditoria centralizada (usuário, IP, máquina, repo, data) retida por 5 anos sob parecer do DPO.
- **Pendências / [NEEDS CLARIFICATION]**:
  - `[NEEDS CLARIFICATION: dpo-review]` Validação formal pelo DPO/Jurídico do Relatório de Impacto (RIPD) e da base legal de Legítimo Interesse para registro de IP e máquina por 5 anos.
- **Responsável por validar o spec.md gerado**: Mantenedores da Plataforma Nimbus Code / DevSecOps / DPO
- **Duração real desta entrevista**: 25 minutos

---

## Checklist de Cobertura Mínima

| Item | Estado (Coberto / Ambíguo / Ausente) | Nota |
|---|---|---|
| Objetivo de negócio (o quê e por quê) | Coberto | Proteção de IP, bloqueio fora do GHE, suporte SaaS |
| Critério de sucesso/pronto (entrega + sustentado) | Coberto | Bloqueio efetivo, auditoria centralizada, lease 30d |
| Perfis de usuário identificados | Coberto | Devs internos, clientes externos, SecOps, DPO |
| Escopo fora (o que não é) | Coberto | Sem billing financeiro no MVP, docs públicas livres |
| Critérios de aceite (mínimo 4, mensuráveis e verificáveis) | Coberto | 6 critérios mensuráveis (C1 a C6) |
| Infraestrutura: hospedagem ou padrão de referência | Coberto | Acesso Web, GHE/Azure Functions, tokens assinados |
| Infraestrutura: brownfield/greenfield indicado | Coberto | Brownfield (bootstrap, presets, GitHub Apps) |
| Infraestrutura: repositórios/bounded contexts afetados | Coberto | `spec-kit-workflow`, `repository-provisioning` |
| Infraestrutura: quem acessa | Coberto | Usuários internos e clientes multi-tenant |
| Segurança: sensibilidade/exposição | Coberto | IP crítica, credenciais, integridade de pacotes |
| Segurança: perfis de autorização | Coberto | Usuário, Admin de Tenant, SecOps/Auditor |
| LGPD: presença ou ausência de dado pessoal | Coberto | Username, e-mail, IP e identificador de máquina |
| LGPD: base legal (ou pendência para jurídico/DPO) | Coberto | Legítimo Interesse / Execução Contrato + Parecer DPO |

---

## Saída Estruturada (para automação)

```yaml
interview_output:
  feature_slug: "026-template-usage-governance"
  modo: "completo"
  prioridade_inferida: "P0-blocker"
  negocio:
    problema: "Uso e cópia não autorizada do template Nimbus Code fora do GHE sem auditoria centralizada de IP e atores."
    criterio_sucesso: "Bloqueio de bootstrap não autorizado, distribuição de artefatos privados, lease offline de 30 dias e trilha auditável por 5 anos."
    fora_de_escopo: "Cobrança financeira (billing) e bloqueio de docs públicas."
    orcamento_aprovado: true
    duplicidade_outro_time: false
    criterios_aceite:
      - "C1: Rejeição imediata de bootstrap/atualização em ambiente/tenant não autorizado via Web."
      - "C2: Distribuição híbrida com artefatos protegidos e bloqueio de fork sem licença."
      - "C3: Auditoria completa de usuário, IP, máquina, repositório e timestamp."
      - "C4: Lease criptográfico para até 30 dias de operação offline."
      - "C5: Isolamento arquitetural multi-tenant."
      - "C6: Retenção de 5 anos para logs de segurança e conformidade LGPD."
    quebra_proposta:
      avaliada: true
      aceita: true
      fatias:
        - "026-template-usage-governance-core"
        - "026-template-usage-governance-multitenant"
  infraestrutura:
    hospedagem: "Web pública segura (HTTPS/TLS 1.3), GHE API / GitHub App / Azure Functions"
    brownfield_ou_greenfield: "brownfield"
    repositorios_ou_bounded_contexts:
      - "spec-kit-workflow"
      - "repository-provisioning"
    duplicidade_reuse_catalog: false
    quem_acessa: "Desenvolvedores internos, clientes externos e pipelines de CI/CD"
  seguranca:
    dado_sensivel_negocio: true
    perfis_autorizacao: "Usuário Comum (leitura/bootstrap com lease), Admin Tenant, SecOps Auditor"
  lgpd:
    dado_pessoal: true
    base_legal: "Legítimo Interesse (Art. 7º, IX) e Execução de Contrato / Proteção de Ativos (Art. 7º, V) com pendência formal de parecer do DPO"
  pendencias:
    - "[NEEDS CLARIFICATION: dpo-review] Validação formal pelo DPO do documento de fundamentação e RIPD para retenção de IP/máquina por 5 anos."
  duracao_real_minutos: 25
```
