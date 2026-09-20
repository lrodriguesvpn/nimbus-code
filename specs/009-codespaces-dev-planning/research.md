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

## Unknown 4: Análise Comparativa de Ambientes (Codespaces vs Google Antigravity/Project IDX vs Devcontainer Local)

**Decision**: Adotar o padrão **Devcontainer Portátil "Local First"** como base da organização, tratando GitHub Codespaces e Google Antigravity / Project IDX como ambientes de execução opcionais/on-demand para onboarding ou tarefas remotas específicas, sem torná-los obrigatórios ou substituir o desenvolvimento local.

**Rationale**:
1. **Google Antigravity / Project IDX**: Baseado em Nix e Code-OSS na nuvem do Google Cloud. Oferece integração nativa com Gemini, emuladores e pré-visualizações multi-plataforma full-stack. Porém, introduz dependência do ecossistema Google Cloud / Firebase, não se integra nativamente ao GitHub Enterprise e possui modelo de billing/VPC próprio.
2. **GitHub Codespaces**: Integração perfeita com GitHub Enterprise, devcontainer nativo, pré-configuração de extensões VS Code e prebuilds. No entanto, possui custo recorrente por hora de computação (vCPU/RAM) + storage, além de exigir conexão constante.
3. **Devcontainers Locais (VS Code Dev Containers / Colima / Docker / Devbox)**: Custo de computação zero para a organização, performance total do hardware do desenvolvedor (M-series Mac, x86), funciona 100% offline, suporta execução de modelos locais leves e usa exatamente a mesma especificação aberta `devcontainer.json`.

**Alternatives considered**:
- Forçar 100% Cloud Dev (Codespaces): Rejeitado pelo alto custo fixo/variável e atrito com desenvolvedores seniores que preferem toolchain local rápida e sem latência de rede.
- Migrar para ecossistema Google Project IDX: Rejeitado devido ao stack principal da organização estar hospedado em GitHub Enterprise.

## Unknown 5: Ganhos Operacionais Reais para CI/CD vs Custo de Prebuilds

**Decision**: A aceleração de CI/CD deve focar em **validação pré-PR via devcontainer local/remoto** e **otimização de cache de GitHub Actions**, sem depender exclusivamente de Prebuilds de Codespaces como mecanismo de CI.

**Rationale**:
- Prebuilds de Codespaces aceleram a criação do *ambiente de desenvolvimento do dev* (reduzindo de 5-10 min para <1 min), mas **não aceleram os workflows de CI/CD em si** (GitHub Actions roda em runners próprios, não dentro do Codespace do dev).
- O ganho real de CI/CD vem da capacidade do desenvolvedor executar `scripts/run-all-tests.sh`, lint e build localmente com 100% de paridade com o runner de CI (graças ao devcontainer compartilhado), reduzindo em mais de 60% as falhas bobas de PR que re-disparam runners de CI.
- O custo de Prebuilds no GHE consome minutos de GitHub Actions a cada push na branch principal para manter o snapshot atualizado, o que só compensa em repositórios com alto volume de novas entradas de devs por semana.

## Unknown 6: Ambientes de Execução para Agentes de IA em Background

**Decision**: Sessões de agentes de IA locais devem operar usando isolamento por Git Worktrees e containers locais. Sessões de agentes cloud/remotas (ex.: GitHub Copilot Workspace, GitHub Actions Agents) devem rodar em runners efêmeros com permissões de mínimo privilégio e segredos injetados por OIDC/GHE secrets, nunca com tokens de desenvolvedor compartilhados.

**Rationale**:
Garante que o princípio de segurança e devsecops (sem segredos em texto plano, isolamento de sessão) seja mantido com paridade absoluta entre execuções humanas e agentivas.

---

## Matriz Comparativa Multidimensional

| Dimensão | GitHub Codespaces | Google Antigravity / Project IDX | Devcontainers Locais (Docker/Colima/Devbox) |
|---|---|---|---|
| **Custo de Computação (TCO)** | Pago por hora (ex: ~$0.18–$0.36/h por 2-4 vCPU) + storage | Cobrança via Google Cloud / Workspace | **$0 (utiliza hardware existente)** |
| **Integração com GHE** | **Nativa e transparente (SSO GHE)** | Requer ponte/autenticação externa | **Nativa via `gh` CLI / SSH** |
| **Suporte Offline** | Não (requer conexão contínua) | Não (cloud-only) | **Sim (100% funcional offline)** |
| **Velocidade de Onboarding** | Excelente (< 2 min com prebuild) | Excelente (< 2 min) | Muito boa (< 5 min primeiro `docker build`) |
| **Integração com IA Agentica** | GitHub Copilot / VS Code Agent | Google Gemini nativo / Nix-based | Copilot SDK, CLI agents, Ollama local |
| **Portabilidade de Configuração** | Padrão aberto `devcontainer.json` | Configuração `.idx/dev.nix` + devcontainer | **Padrão aberto `devcontainer.json`** |
| **Ganhos de CI/CD** | Validação pré-PR idêntica ao CI | Ambiente isolado | **Validação pré-PR idêntica ao CI** |
| **Risco de Lock-in** | Baixo se mantido `devcontainer.json` | Médio (formato Nix customizado) | **Zero (formato padrão aberto)** |
