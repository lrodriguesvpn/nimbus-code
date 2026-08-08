<!--
  Este bloco é inserido pelo preset `vpndev-standards` (estratégia `append`) ao final
  do plan-template.md nativo do Spec Kit — não substitui nenhuma seção existente
  (Summary, Technical Context, Constitution Check, Project Structure, Complexity
  Tracking). Ele formaliza duas práticas que hoje viviam soltas nas skills internas
  de refinamento técnico e planejamento DevOps da VPN Dev.
-->

## VPN Dev — Security & DevSecOps Gate

*GATE adicional: deve ser preenchido e aprovado antes de `/speckit-tasks`, junto com
o Constitution Check nativo. Cobre lacunas que a constituição sozinha não detalha
por domínio técnico.*

| Domínio | Controles aplicáveis | Status | Observações |
|---|---|---|---|
| Containers | Imagem base pinada, scan de vulnerabilidade, usuário não-root | | |
| CI/CD | Segredos via cofre/CI secrets, least privilege no service account do pipeline | | |
| IaC — provider(s) usado(s) | 100% da infra desta feature via IaC (nenhuma alteração manual); **Terraform** como framework padrão para AWS/GCP/Azure; `plan` revisado em PR, sem credenciais hardcoded, state remoto protegido | | Se usar ferramenta nativa do provedor (CDK/Bicep/Deployment Manager) em vez de Terraform, justificar no Architecture Decision Log abaixo |
| Banco de dados | TLS/mTLS obrigatório, flags de auditoria mínimas, backup/retenção definidos | | |
| Rede | Regras de firewall/least exposure, sem exposição pública desnecessária | | |
| Observabilidade | Logs, métricas e alertas mínimos definidos para os componentes críticos | | |

**Riscos identificados e decisão:**
[Lista de riscos relevantes encontrados durante o planejamento e a decisão tomada:
endurecer agora / mitigar em fase seguinte (com data) / aceitar risco documentado]

## VPN Dev — Qualidade de Código, Testes e Observabilidade Gate

*GATE adicional: deve ser preenchido e aprovado antes de `/speckit-tasks`, junto
com o Constitution Check nativo e o Security & DevSecOps Gate acima. Traduz em
verificações concretas as regras de "Qualidade e Processo" da constituição da
VPN Dev (revisão por IA, testes integrados, observabilidade, arquitetura
distribuída e gestão de bugs).*

| Domínio | Controles aplicáveis | Status | Observações |
|---|---|---|---|
| Revisão de código por IA | GitHub Copilot code review solicitado em todo PR desta feature; findings High/Critical bloqueiam merge (mesma régua do SAST/IaC) | | |
| Testes integrados | Cada critério de aceitação do `spec.md` tem teste de integração automatizado correspondente, sempre que tecnicamente viável | | |
| Observabilidade | Logs estruturados, métricas e alertas mínimos instrumentados para os componentes entregues (obrigatório, não condicional) | | |
| Arquitetura distribuída / Microsserviços | Correlation-id/trace-id (W3C Trace Context) propagado ponta a ponta entre serviços; orquestração/coreografia documentada no Architecture Decision Log abaixo | Marcar "N/A" se monólito/sem chamadas entre serviços | |
| Gestão de bugs | Bugs encontrados fora do escopo desta tarefa/feature abertos como Issue no GitHub e atribuídos ao Copilot coding agent | | |

**Critérios de aceitação sem teste de integração automatizado (se houver) — justificativa:**
[Lista de critérios de aceitação do `spec.md` que não terão teste de integração
e o motivo técnico — ex.: dependência externa indisponível em CI]

## VPN Dev — Architecture Decision Log

*Preencher apenas para decisões técnicas relevantes desta feature (não é
necessário registrar decisões triviais/óbvias).*

| Decisão | Alternativas consideradas | Opção escolhida | Trade-off assumido |
|---|---|---|---|
| [ex.: estratégia de mensageria] | [ex.: Pub/Sub vs Kafka vs polling] | [opção] | [o que se perde/ganha com a escolha] |
| [ex.: framework de IaC, apenas se diferente do padrão Terraform] | [ex.: Terraform vs Bicep] | [ex.: Bicep, por exigência de compliance nativo do Azure Policy neste workload] | [ex.: perde padronização multi-cloud com os demais projetos, ganha integração nativa com Azure Policy/Defender] |
