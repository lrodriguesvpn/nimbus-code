# Research: Bootstrap Governance & Repo Provisioning Hardening

## Unknown 1: `actions/create-github-app-token@v1` — parâmetros e permissões mínimas

**Decision**: Usar `actions/create-github-app-token@v1` em cada workflow migrado,
com `app-id` e `private-key` vindos de GitHub Secrets do repositório (ou de um
Environment protegido, para permitir aprovação adicional em automações críticas),
e `permission-*` explícitos por workflow (nunca herdar todas as permissões
concedidas ao App na instalação).

**Rationale**: A action já é mantida oficialmente pelo GitHub, gera token de
instalação de curta duração (expira em ~1h), e permite restringir por chamada
quais permissões são realmente usadas — reforça least privilege mesmo que o App
tenha sido instalado com escopo mais amplo.

**Alternatives considered**:
- Gerar o JWT/token manualmente via `curl`+`openssl` (como fez o precedente
  `docs/adr/0008-github-app-para-varredura-de-seguranca-org-wide.md` antes desta
  action ser adotada como padrão) — mais controle, mas duplica lógica em 4
  workflows; rejeitado em favor de reuso via action mantida.

## Unknown 2: Mecanismo de fallback seguro (PAT) durante o rollout

**Decision**: Cada workflow migrado tenta primeiro emitir o token via GitHub App;
se as credenciais do App (`secrets.APP_ID`/`secrets.APP_PRIVATE_KEY`) não
estiverem configuradas no repositório, o workflow cai para o PAT existente
(`VPNDEV_PROJECT_TOKEN` ou equivalente por workflow), com um aviso explícito no
log (`::warning::`) informando que está em modo fallback.

**Rationale**: Permite rollout gradual repositório-a-repositório sem exigir que
todos migrem no mesmo dia; nenhum workflow quebra durante a transição.

**Alternatives considered**:
- Feature flag externa (LaunchDarkly/AppConfig) controlando qual mecanismo usar —
  rejeitado por complexidade desnecessária; a própria presença/ausência do secret
  do GitHub App já funciona como o "flag" (consistente com o padrão de bootstrap
  já usado neste bundle para outros workflows opcionais).

## Unknown 3: Suporte a GitHub Apps organizacionais no GHE da organização

**Decision**: Assumir suporte disponível — já validado como parte do trabalho da
feature 007 (`docs/adr/0008-github-app-para-varredura-de-seguranca-org-wide.md`),
que já criou e documentou o processo de criação de GitHub App organizacional no
mesmo ambiente GHE (`venha-pra-nuvem.ghe.com`).

**Rationale**: Reaproveitar validação já feita evita re-trabalho; não há
indicação de que a versão do GHE em uso tenha mudado desde então.

**Alternatives considered**: N/A — decisão por reaproveitamento direto de
achado já validado.
