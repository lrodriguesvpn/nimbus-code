# Research: Codespaces para DEV e CI/CD

## Unknown 1: Disponibilidade de GitHub Codespaces no GHE da organização

**Decision**: Assumir disponibilidade a confirmar administrativamente antes do
rollout — este plano prossegue com o desenho da solução independente da
confirmação comercial, que é tratada como pré-requisito separado (ver
Assumptions do `spec.md`).

**Rationale**: Bloquear o planejamento técnico até a confirmação comercial
atrasaria a entrega do plano sem necessidade — o desenho é válido
independentemente de quando o licenciamento for confirmado.

**Alternatives considered**: Aguardar confirmação antes de planejar — rejeitado
por atraso desnecessário.

## Unknown 2: Imagem base de devcontainer

**Decision**: Usar `mcr.microsoft.com/devcontainers/base:ubuntu` como base,
adicionando features para Bash/Python/Node (via
`ghcr.io/devcontainers/features`), consistente com a stack já usada por
`normalize-github-issues.sh` (Python3) e demais scripts (Bash).

**Rationale**: Imagem oficial mantida, compatível com o conjunto de ferramentas
já usado neste bundle sem exigir customização pesada.

**Alternatives considered**:
- Imagem customizada from-scratch — rejeitada por maior esforço de manutenção
  sem benefício claro para o escopo atual (scripts shell/Python, não uma
  aplicação complexa).

## Unknown 3: Política de retenção/timeout nativa do GitHub Codespaces

**Decision**: Usar a configuração nativa de "Default idle timeout" e "Retention
period" do GitHub Codespaces (nível de organização) como primeira linha de
governança, complementada por um relatório periódico de custo (não uma
automação de parada custom) apenas se a configuração nativa se mostrar
insuficiente.

**Rationale**: Evita reinventar uma automação que o GitHub já oferece
nativamente; reduz superfície de manutenção.

**Alternatives considered**: Automação própria de parada via GitHub Actions
monitorando uso — mantida como opção de fallback (`codespaces-idle-governance.yml`
de referência), não como solução primária.
