# NC-Critic: Auditoria da Spec 026 (`026-template-usage-governance`)

**Status:** Aprovado com Clarificações e Refinamentos  
**Data:** 2026-03-30  
**Auditor:** `NC-Critic` (Nimbus Spec Auditor)  
**Complexidade:** S4  

---

## 1. Análise de Ambiguidade e Termos Vagos

| Item / Seção | Termo Original | Risco Identificado | Resolução / Métrica Precisa na Spec |
|---|---|---|---|
| **AC-1 (Bootstrap)** | *"artefatos proprietários"* | Ambiguidade sobre quais arquivos são públicos vs privados no modelo BSL/Dual-License. | Definido explicitamente: Core templates do spec-kit são públicos; Agentes especializados (`nc-*`), Harness catalog, Success Playbooks e Presets de Governança corporativa são os artefatos restritos a entitlement. |
| **AC-2 (Lease Offline)** | *"30 dias de operação"* | Risco de fraude por alteração do relógio do sistema local (*clock rollback attack*). | O lease deve registrar `not_before`, `issued_at`, `expires_at` e manter monotonic time / commit SHA correlation para evitar bypass de expiração. |
| **AC-3 (Telemetria)** | *"apenas metadados"* | Ambiguidade sobre possível vazamento em nomes de repositórios ou mensagens de commit. | Sanitarização estrita de payload: regex e hash SHA-256 de identificadores sensíveis. Zero strings livres de código ou diffs. |
| **AC-6 (Zero Lock-in)** | *"código gerado autônomo"* | Risco de os templates injetarem dependências ou wrappers proprietários no build final. | Requisito verificado por pipeline de CI limpo: o projeto de output deve compilar e rodar em container padrão sem qualquer pacote ou credencial da VPN. |

---

## 2. Perguntas de Esclarecimento & Alinhamento Estratégico (Resolvidas)

1. **Como diferenciar uso de desenvolvimento/avaliação de uso em produção (BSL 1.1)?**
   - **Resposta:** A validação é por contexto de pipeline e tenant ID. Pipelines de CI em branches protegidas (`main`/`prod`) ou com tags de release exigem o token corporativo/Enterprise. Em localhost, o runtime opera em modo de avaliação/Community com aviso não-bloqueante.
2. **Qual é o protocolo de fallback se o servidor de Entitlement da VPN estiver indisponível?**
   - **Resposta:** O cliente local utiliza o lease criptográfico existente com janela de tolerância (grace period de 30 dias). Se for uma instalação inicial (sem lease prévio) e o servidor falhar, o instalador entra em modo Free/Avaliação local temporário por 7 dias.
3. **Como garantir paridade entre VS Code, Cursor, Antigravity e Claude Code?**
   - **Resposta:** O core de governança e validação de lease reside na CLI/Engine (`nimbus-code` / MCP Server). As extensões de IDE e plugins agênticos são adaptadores leves que apenas invocam a camada de governança do core.

---

## 3. Veredito da Auditoria

A especificação funcional `specs/026-template-usage-governance/spec.md` e o assessment estratégico `strategic-assessment.md` estão **consistentes, blindados contra contradições técnicas e alinhados aos requisitos de segurança e negócio**.

**Handoff:** Autorizado avanço para o agente de governança `/nc-governor` e arquiteto de soluções `/nc-arch`.
