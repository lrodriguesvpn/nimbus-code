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

**Decision**: OpenFeature permanece como abstração declarativa do rollout, mas a
ausência das credenciais do App não ativa PAT automaticamente. O comportamento
padrão é fail-closed para a etapa cross-repo/org. Um modo de migração PAT só
pode ser habilitado explicitamente, com owner, prazo de expiração, ambiente
permitido, aviso estruturado e registro de auditoria.

**Rationale**: Evita que um secret legado seja usado silenciosamente e preserva
rollback operacional por desativação do rollout, sem transformar PAT em caminho
normal de execução.

**Alternatives considered**:
- Presença/ausência do secret como flag implícita — rejeitada porque transforma
  uma falha de configuração em fallback silencioso e não oferece owner, prazo ou
  auditoria.

## Unknown 3: Suporte a GitHub Apps organizacionais no GHE da organização

**Decision**: Assumir suporte disponível — já validado como parte do trabalho da
feature 007 (`docs/adr/0008-github-app-para-varredura-de-seguranca-org-wide.md`),
que já criou e documentou o processo de criação de GitHub App organizacional no
mesmo ambiente GHE (`venha-pra-nuvem.ghe.com`).

**Rationale**: Reaproveitar validação já feita evita re-trabalho; não há
indicação de que a versão do GHE em uso tenha mudado desde então.

**Alternatives considered**: N/A — decisão por reaproveitamento direto de
achado já validado.

## Unknown 4: Estratégia de versão e tag para o piloto

**Decision**: publicar uma release candidate imutável em `v1.19.0-rc.1`,
mantendo `nimbus-code-project-bundle`/`nimbus-code-standards` em `1.19.0` e
`nimbus-code-platform-bundle`/`nimbus-code-platform-standards` em `0.5.0`.
Depois dos gates do piloto, publicar `v1.19.0`.

**Rationale**: o workflow de release usa a versão do bundle de projeto para a
tag canônica, mas empacota ambos os bundles. O componente de plataforma tem
semver independente; forçá-lo a `1.19.0` perderia a distinção entre contratos.
A ref explícita evita que o piloto consuma `main` móvel.

**Alternatives considered**:
- Manter as versões atuais e usar apenas uma tag operacional — rejeitado,
  porque o bootstrap muda seu contrato publicado.
- Usar `v1.19.0` diretamente no piloto — rejeitado até os gates humanos e o
  piloto validarem a release candidate.

## Unknown 5: Quais melhorias entram nesta release

**Decision**: incluir somente melhorias compatíveis e diretamente relacionadas
ao provisioning: isolamento estrito dos perfis, bootstrap reproduzível,
quality gates e governança agentica no perfil Dev Standards; CMDB/evidência,
zero-diff/drift, baselines, lifecycle e Landing Zone/CAF no perfil Platform.

**Rationale**: evita transformar o piloto em uma migração ampla de workloads,
mas torna os dois presets úteis para seus bounded contexts reais. As capacidades
de CMDB/DSC permanecem contratos e scaffolds do preset; coleta real e apply de
infraestrutura continuam fora do bootstrap.

**Alternatives considered**:
- Incluir implementação completa do CMDB no bootstrap — rejeitado por risco,
  escopo e necessidade de credenciais cloud.
- Fazer apenas a correção do bootstrap — rejeitado porque o piloto não
  exercitaria as capacidades que diferenciam Platform de Dev Standards.
