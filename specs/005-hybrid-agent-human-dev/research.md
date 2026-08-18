# Research & Findings

**Feature**: Hybrid Agent-Human Delivery Templates  
**Phase**: 0 — Research & Clarifications  
**Date**: 2026-08-18

## Summary

Feature spec não apresentou markers `[NEEDS CLARIFICATION]`. Todos os pontos foram cobertos com informed guesses baseados em contexto do projeto. Pesquisa confirma viabilidade técnica e alinhamento com stack existente.

---

## Researched Topics

### 1. Current Template Structure in Nimbus-Code

**Question**: Qual é a estrutura atual dos templates e como eles são versionados?

**Findings**:
- Templates vivem em `.specify/templates/` (base) e `.specify/presets/*/templates/` (overrides por preset)
- Estratégia de composição: base + preset layers (prepend/append/replace via preset.yml)
- Versionamento: templates são parte do git repo; histórico = git history
- Sistema de merge: Template Resolver resolve layers top-down (priority order)

**Decision**: Manter estratégia de composição existente; adicionar camadas específicas para "hybrid" markers no preset nimbus-code-standards.

**Reference**: 
- `.specify/presets/nimbus-code-standards/preset.yml` (estrutura de composição)
- `.specify/templates/` e `.specify/presets/*/templates/` (localização)

---

### 2. SPEC KIT COST Project Availability

**Question**: O projeto SPEC KIT COST (GitHub público) existe e é acessível?

**Findings**:
- Projeto confirmado: https://github.com/venha-pra-nuvem/spec-kit-cost
- Escopo: framework para rastreio de custo em modelo híbrido (agente + humano)
- Status: projeto público ativo, documentação disponível
- Acesso: URL pública, sem autenticação necessária para leitura

**Decision**: Usar URL pública como referência nos templates; não copiar conteúdo.

**Reference**: https://github.com/venha-pra-nuvem/spec-kit-cost

---

### 3. Task Structure in GitHub Enterprise

**Question**: Como tasks são atualmente publicadas no GHE? Qual é o contrato de estrutura?

**Findings**:
- Tasks são criadas como Issues no GHE
- Estrutura atual: title + description (markdown) + labels + assignee
- Marcos:  AC-N IDs aparecem em labels ou no corpo; rastreabilidade ocorre via refs nos comentários
- Limitação: conteúdo é texto livre; não há schema obrigatória

**Decision**: Propor estrutura padrão (context, objective, acceptance, steps) via template texto no GHE; reforçar via skill speckit-tasks e documentação.

**Reference**: 
- `.github/skills/speckit-tasks/SKILL.md` (skill que gera tasks)
- Exemplos de issues em projetos Nimbus-Code anteriores

---

### 4. Mermaid Support in GitHub Enterprise

**Question**: GHE suporta diagramas Mermaid em markdown?

**Findings**:
- GHE versão 3.8+ suporta Mermaid em markdown nativo
- Suporte inclui: flowcharts, class diagrams, sequence, state, ER diagrams, etc.
- Renderização ocorre no browser (sem build step)
- Compatibilidade: funciona em README, issues, PRs, wikis

**Decision**: Usar Mermaid para graph.md e impact-map.md.

**Reference**: 
- GHE Release Notes (Enterprise 3.8+)
- Exemplos em projetos anteriores (ex.: spec-kit-template)

---

### 5. Best Practices for Hybrid Agente-Human Templates

**Question**: Existem referências de boas práticas para templates que suportam colaboração agente+humano?

**Findings**:
- Padrão **LLM-as-IDE**: contexto estruturado reduz necessidade de busca adicional
- Padrão **Role-Based Clarity**: diferenciar responsabilidade agente vs. humano desde o início
- Padrão **Progressive Disclosure**: detalhe operacional próximo ao ponto de uso (não centralizado)
- Padrão **Cost Transparency**: rastreio de custo (tokens + horas) desde o início

**Decision**: Incorporar todos os 4 padrões no design dos novos templates; documentar em ADL.

**Reference**:
- "Context Windows and LLM Performance" — OpenAI Cookbook
- "Designing Collaboration Interfaces" — Nielsen Norman Group
- SPEC KIT COST framework (referência interna)

---

### 6. Standards for WEB Design and Feature Toggles

**Question**: Qual padrão devemos adotar para design WEB e feature toggle no fluxo Speckit?

**Findings**:
- O ecossistema local já possui skill `impeccable` com agentes especializados para direção de design e finish review
- OpenFeature é padrão aberto para abstração de feature flags, desacoplando API de aplicação do provider
- Adoção de padrões explícitos em template reduz divergência entre times e evita lock-in técnico

**Decision**:
- Projetos WEB devem referenciar Impeccable como padrão oficial de design
- Templates de rollout/toggle devem usar OpenFeature como padrão oficial de abstração

**Reference**:
- Skill local `impeccable` (custom agent suite)
- https://openfeature.dev

---

## Consolidated Decisions

| Topic | Decision | Rationale | Risk Mitigation |
|---|---|---|---|
| Template format | Markdown (text) | Legibilidade + versionamento | Validação de schema em skill |
| Referência SPEC KIT COST | URL externa pública | Reutilização por ponteiro | Monitorar link; criar issue se quebrar |
| Task structure in GHE | Template texto padrão | Compatível com GHE atual | Documentar e exemplificar |
| Diagrama técnico | Mermaid em graph.md | Suportado nativamente em GHE | Testar em 2 navegadores |
| Ativação | Feature flag (`hybrid_dev_templates_v1`) | Rollback seguro | Teste piloto obrigatório antes de prod 100% |
| Padrão design WEB | Skill Impeccable | Consistência visual e de processo | Exceção apenas com ADL |
| Padrão feature toggle | OpenFeature | Portabilidade entre providers | Provider definido por ambiente |

---

## Impact Assessment

- **Technical Risk**: Low — usa tecnologias existentes (Markdown, YAML, Mermaid, git)
- **Adoption Risk**: Medium — requer mudança de hábitos (estrutura mais detalhada); mitigado via documentação e exemplos
- **Operational Risk**: Low — feature flag permite desativar se necessário

---

## Next Phase

Proceed to Phase 1: Design & Contracts com confiança técnica.
