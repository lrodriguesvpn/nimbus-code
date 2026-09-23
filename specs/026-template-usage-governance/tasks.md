# Tasks de Implementação: `026-template-usage-governance` (Abordagem Pragmática em Fases)

## Estrutura de Fases e Ordenação por Dependência

- **Fase 1 (Local First & DevX):** Extensão VS Code/Cursor e Servidor MCP Funcionais Localmente (Sem bloqueio de licença / Sem backend complexo).
- **Fase 2 (IaC Cloud Azure):** Infraestrutura como Código em Terraform no diretório `infrastructure/nimbus-code-extension-iac/` (Azure Container Apps, PostgreSQL Flexible, Blob Storage WORM 5y, Key Vault).
- **Fase 3 (Backend de Entitlement Cloud):** API FastAPI de emissão de leases Ed25519 e ingestão de telemetria para deploy na Azure.
- **Fase 4 (Governança & Pluggable License):** Integração do validador de lease Ed25519 e telemetria (Zero Source Leak / BYO-LLM) na extensão e CLI.
- **Fase 5 (Pipelines de Publicação & Validação BDD / DLP):** Automação de release multi-marketplace e suíte de testes de conformidade.

---

## Detalhamento das Tarefas

### Fase 1: Extensão Local & Servidor MCP (MVP Rápido sem Backend)

- [x] **T01** — Estruturar o workspace da extensão VS Code em `extensions/vscode/` com comandos `@nimbus` (`/nc-spec`, `/nc-arch`, `/nc-qa`, `/nc-builder`) e interface leve. `[P]`
- [x] **T02** — Desenvolver o servidor MCP local em `servers/mcp-nimbus/` com `@modelcontextprotocol/sdk` (TypeScript) expondo o catálogo de ferramentas e personas para Claude Code, Cursor e Antigravity. `[P]`
- [x] **T03** — Permitir execução local em modo irrestrito (Dev Mode / Teste Ágil), sem dependência de chaves de licença ou backend de autenticação. `[P]`

### Fase 2: Infraestrutura Cloud Azure em Terraform (`infrastructure/nimbus-code-extension-iac/`)

- [x] **T04** — Criar `main.tf`, `variables.tf`, `outputs.tf` e `providers.tf` para provisionamento no Azure. `[P]`
- [x] **T05** — Módulo Terraform `resource-group` e `log-analytics-workspace` para observabilidade central. `[P]`
- [x] **T06** — Módulo Terraform `azure-container-apps` (Environment + App) para hospedar a Entitlement API com escalonamento a zero. `[P]`
- [x] **T07** — Módulo Terraform `azure-postgresql-flexible` (B1ms/B2s) para a base multi-tenant de clientes e quotas. `[P]`
- [x] **T08** — Módulo Terraform `azure-storage-account` com Immutability Policy (WORM) de 5 anos para o ledger de auditoria (LGPD Art. 7º, IX e V). `[P]`
- [x] **T09** — Módulo Terraform `azure-key-vault` para proteção da chave mestra assimétrica Ed25519. `[P]`
- [x] **T09.1** — Abertura de RFC/Issue #498 no GHE para debate estratégico de arquitetura dos Servidores MCP com Moisés e Eduardo. `[P]`

### Fase 3: Backend de Entitlement Cloud (FastAPI na Azure)

- [ ] **T10** — Implementar API REST de Entitlement (`/api/v1/lease/issue`, `/api/v1/lease/verify`) em Python FastAPI. `[P]`
- [ ] **T11** — Implementar endpoint de ingestão de telemetria assíncrona com validação estrita de schema JSON (Zero Source Leak). `[P]`
- [ ] **T12** — Dockerfile otimizado e pipeline de containerização para deploy no Azure Container Apps. `[P]`

### Fase 4: Governança de Licenciamento & Leases Ed25519

- [ ] **T13** — Implementar `local-lease-verifier` na CLI e extensão com validação offline de até 30 dias e monotonic time check. `[P]`
- [ ] **T14** — Integrar buffer local de telemetria transitória e sincronização assíncrona com a Entitlement API. `[P]`
- [ ] **T15** — Formalizar termos de licença BSL 1.1 (`LICENSE-BSL.md`) para distribuição pública. `[P]`

### Fase 5: Publicação Multi-IDE e Validação BDD / DLP

- [ ] **T16** — Configurar workflows GitHub Actions de empacotamento e publicação: `vsce publish` (Marketplace), `ovsx publish` (Open-VSX) e `@nimbus-code/cli` (NPM). `[P]`
- [ ] **T17** — Suíte de testes automatizados BDD e inspeção profunda de pacotes (DLP) para atestar Zero Source Leak e Zero Runtime Lock-in. `[P]`

---

## Checklist de Fechamento da Feature

- [ ] Teste da extensão local realizado com sucesso no VS Code e Claude Code sem necessidade de backend.
- [ ] Código Terraform em `infrastructure/nimbus-code-extension-iac/` validado (`terraform fmt` / `terraform validate`).
- [ ] Entitlement API pronta para deploy no Azure Container Apps.
- [ ] Grafos de dependência (`graph.yaml` e `graph.md`) atualizados.
