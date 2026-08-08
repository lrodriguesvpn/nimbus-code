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
| IaC (Terraform/equivalente) | `plan` revisado em PR, sem credenciais hardcoded, state remoto protegido | | |
| Banco de dados | TLS/mTLS obrigatório, flags de auditoria mínimas, backup/retenção definidos | | |
| Rede | Regras de firewall/least exposure, sem exposição pública desnecessária | | |
| Observabilidade | Logs, métricas e alertas mínimos definidos para os componentes críticos | | |

**Riscos identificados e decisão:**
[Lista de riscos relevantes encontrados durante o planejamento e a decisão tomada:
endurecer agora / mitigar em fase seguinte (com data) / aceitar risco documentado]

## VPN Dev — Architecture Decision Log

*Preencher apenas para decisões técnicas relevantes desta feature (não é
necessário registrar decisões triviais/óbvias).*

| Decisão | Alternativas consideradas | Opção escolhida | Trade-off assumido |
|---|---|---|---|
| [ex.: estratégia de mensageria] | [ex.: Pub/Sub vs Kafka vs polling] | [opção] | [o que se perde/ganha com a escolha] |
