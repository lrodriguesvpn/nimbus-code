# 0006 — SSO Corporativo Central Único como Mecanismo de Autenticação Obrigatório

- **Status:** Aceita
- **Data:** 2026-08-12
- **Autores:** @nimbus-code-platform-team
- **Contexto:** feature 004 (Platform Preset CMDB + Baselines de Segurança e Compliance)
- **Revisores:** @nimbus-code-arch-board

---

## Contexto e Problema

Governança de plataforma exige que cada operação (coleta de inventário, decisões de
conformidade, aprovação de exceções) seja **rastreável a uma identidade corporativa**.

Opções de autenticação:

1. **Múltiplos IdPs**: Azure AD para Azure, AWS IAM para AWS, GCP Identity para GCP
   - ✅ Nativo em cada provedor
   - ❌ Auditoria fragmentada (3 trilhas diferentes)
   - ❌ Complexo: operador precisa de conta em cada IdP

2. **SSO Corporativo Central Único**: um único IdP corporativo (ex.: Azure AD, Okta, Google Workspace)
   autentica acesso ao runtime de plataforma
   - ✅ Auditoria centralizada
   - ✅ Rastreabilidade única (login → access token → all operations)
   - ✅ Simples para operador (um login para tudo)
   - ✅ Suporta MFA corporativo

3. **Sem autenticação** (chaves de API, service accounts)
   - ✅ Simplicidade
   - ❌ Não auditável a pessoa (quem fez a mudança?)
   - ❌ Risco: credenciais compartilhadas

Como a governança é requisito regulatório (compliance, auditoria, trilha de exceções),
a rastreabilidade por **pessoa** é não-negociável. Isso exclui opção 3.

## Drivers de Decisão

- **Auditoria**: cada operação deve ser rastreável a uma pessoa (compliance requirement)
- **Rastreabilidade centralizada**: um único IdP, não 3+ provedores
- **Conformidade com MFA corporativo**: suportar segundo fator de autenticação
- **Interoperabilidade**: não ficar acoplado a um provedor cloud específico
- **Operabilidade**: operador não precisa manter múltiplas contas/credenciais

## Opções Consideradas

- **Opção A** — SSO Corporativo Central Único (Azure AD, Okta, Google Workspace, etc.)
- **Opção B** — Múltiplos IdPs (um por provedor cloud)
- **Opção C** — Sem autenticação (service account / chave de API)

## Análise das Opções

### Opção A — SSO Corporativo Central

Runtime autentica operador contra IdP corporativo único (ex.: Azure AD tenant corporativo).

- ✅ Auditoria centralizada: um único log de acesso
- ✅ Rastreabilidade por pessoa: cada operation tem `requestedBy: user@corp.com`
- ✅ MFA corporativo suportado (conforme policy da corp)
- ✅ Simples para operador: um login
- ✅ Escalável entre múltiplos tenants de cliente
- ✅ Suporta future RBAC (role = aprovador de exceções, etc.)
- ❌ Requer integração com IdP corporativo (configuração one-time)
- ❌ Falha de IdP → operador não consegue acessar runtime (mitigado: fallback credential)

### Opção B — Múltiplos IdPs

Cada cloud usa seu próprio mecanismo:
- Azure: Azure AD (Managed Identity, Service Principal)
- AWS: IAM (AssumeRole, temp credentials)
- GCP: Service Account

- ✅ Nativo em cada provedor (menos setup)
- ✅ Automaticamente sincronizado com cloud permissions
- ❌ Auditoria fragmentada (3 trilhas separadas, impossível correlação)
- ❌ Não identifica "pessoa" que fez a operação (só service account)
- ❌ Não alinha com compliance requirement de "auditoria centralizada"

### Opção C — Sem Autenticação

Service account fixo ou chave de API.

- ✅ Simplicidade máxima (sem integração IdP)
- ❌ Não auditável a pessoa (incumprimento de compliance)
- ❌ Chave compartilhada = risco de vazamento

## Decisão

**Opção escolhida: Opção A (SSO Corporativo Central Único)**, porque:

1. **Compliance obrigatório**: auditoria por pessoa é requisito regulatório não-negociável
2. **Rastreabilidade centralizada**: um único IdP, não múltiplos
3. **Operabilidade**: operador se autentica uma vez, acessa tudo
4. **Escalabilidade**: suporta múltiplos tenants sem duplicar contas

**Corolários**:

- Runtime expõe endpoint de autenticação: POST `/auth/login` (OAuth2 / OIDC flow)
- Operador inicia `platform-governance init` → navegador abre URL de login
- IdP corporativo autentica (MFA se configurado na corp)
- Runtime recebe token do IdP, extrai identidade (`user@corp.com`, grupos, etc.)
- Token é armazenado em `.state/auth.json` (git-ignored) para futuras operações
- Cada operação registra `requestedBy: <identidade>` na auditoria
- Expiração de token: operador faz re-login (conforme policy de IdP)

## Consequências

### Positivas

- Auditoria completa: cada operação é rastreável a uma pessoa e timestamp
- Compliance: alinha com HIPAA, SOC2, ISO27001 (auditabilidade por pessoa)
- Rastreabilidade de exceções: quando alguém aprova exceção de policy, é registrado
  quem fez (essencial para forensics)
- Escalabilidade: múltiplos tenants, múltiplos operadores, um só IdP central
- Suporte a MFA corporativo (sem implementar MFA próprio)

### Negativas / Trade-offs Assumidos

- **Dependência de IdP corporativo**: se IdP cai, operadores não conseguem acessar
  (mitigado com fallback credential configurado em cofre seguro)
- **Integração one-time**: setup de OAuth2/OIDC com IdP corporativo (documentado,
  típico ~1h setup)
- **Token refresh**: operador pode precisar fazer re-login se token expirou
  (mitigado com refresh tokens automáticos, típico ~8h para novo login)

### Ações derivadas

- [x] Implementar OAuth2/OIDC client em `src/shared/auth/sso-client.ts`
- [x] Implementar login endpoint POST `/auth/login` em `src/api/routes/auth.ts`
- [x] Implementar token validation middleware em `src/api/middleware/auth.ts`
- [x] Documentar setup de OAuth2 client com Azure AD / Okta / Google Workspace
- [x] Implementar fallback credential (static secret para operações críticas)
- [x] Adicionar correlation ID tracking (trace cada request a usuário + timestamp)
- [ ] Implementar token refresh logic (background renewal antes de expiração)
- [ ] Criar runbook de "operador perdeu acesso" (password reset via IdP corporativo)
- [ ] Implementar logout endpoint POST `/auth/logout`
- [ ] Criar audit report "operations by user" para compliance reviews

## Links

- Feature spec: `specs/004-platform-cmdb-dsc-model/spec.md` (AC-1)
- Runtime auth: `platform-governance/src/shared/auth/sso-client.ts`
- API routes: `platform-governance/src/api/routes/auth.ts`
- Tests: `tests/contract/auth-session.contract.test.ts`, `tests/e2e/auth-rejection.test.ts`
- Constitution section: `presets/nimbus-code-platform-standards/templates/constitution-template.md`
  (Inicialização do CMDB)
- Related: ADR-0002 (Preset + Runtime), ADR-0004 (Advisory mode)
