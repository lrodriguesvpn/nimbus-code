# Impact Map: Codespaces para DEV e CI/CD

**Complexidade**: S3 (revisão humana recomendada, não bloqueante)

## Componentes Impactados

| Componente | Tipo de Mudança | Risco |
|---|---|---|
| `.devcontainer/devcontainer.json` | Novo | Baixo — não afeta nenhum sistema em produção |
| `docs/codespaces-adoption-guide.md`, `docs/ci-cd-acceleration-map.md` | Novo | Baixo — documentação |
| `.github/workflows/codespaces-idle-governance.yml` | Novo (referência) | Baixo — não ativado por padrão em nenhum repositório existente |

## Failure Modes

### FM-1: Devcontainer de referência não cobre toda a stack de um repositório específico

**Trigger**: Repositório com dependências além de Bash/Python/Node não cobertas
pelo devcontainer padrão.

**Impacto**: Time precisa estender manualmente o devcontainer.

**Mitigação**: `spec.md` já assume isso como Edge Case — devcontainer padrão é
ponto de partida extensível, documentado como tal.

### FM-2: Licenciamento de Codespaces não disponível no GHE da organização

**Trigger**: Confirmação comercial (fora do escopo desta feature) revela que
Codespaces não está disponível.

**Impacto**: Plano fica pronto mas não pode ser executado até resolução
comercial.

**Mitigação**: Nenhuma — risco aceito e documentado como Assumption no
`spec.md`; não bloqueia a entrega do plano em si.

## Go/No-Go Gates

- [ ] **Gate 1**: Confirmação de licenciamento/disponibilidade de Codespaces no GHE
- [ ] **Gate 2**: Devcontainer de referência validado com sucesso em repositório de teste
- [ ] **Gate 3**: Política de governança de custo revisada por gestor de plataforma

## Plano de Rollback

Não aplicável — feature não altera nenhum sistema em produção; reverter
significa simplesmente não adotar os artefatos produzidos.

## SLOs (referência para o Observability Gate)

| Componente | Latência p99 | Taxa de erro máx. | Disponibilidade |
|---|---|---|---|
| Provisionamento de Codespace | 120000 ms | 2,0% | 99,0% |
| Prebuild de Codespace | 600000 ms | 2,0% | 98,0% |
