# NIMBUS CODE — Resumo Executivo (Visão Comercial e de Marketing)

> Documento de apoio para apresentação institucional (ex.: Microsoft Summit).
> Todos os números marcados como "real" foram extraídos ao vivo do repositório
> `venha-pra-nuvem/nimbus-code-spec-kit-template` em 2026-08-20. Números
> marcados como "ilustrativo" são conceituais, para fins didáticos de slide.

---

## 1. O que é o NIMBUS CODE, em uma frase

**Um sistema operacional de governança para desenvolvimento de software com
IA + Humano, 100% nativo no GitHub** — transforma o uso de agentes de IA
(GitHub Copilot e equivalentes) de "experimento individual" em **processo de
engenharia auditável, mensurável e replicável em escala organizacional**.

Não é mais uma ferramenta de IA que escreve código. É a **camada de
governança** que faltava entre "o agente pode fazer isso" e "a empresa confia
no que o agente fez, sabe quanto custou e consegue provar isso depois".

---

## 2. Os problemas reais que o NIMBUS CODE resolve

### Problema 1 — Agentes de IA autônomos sem trilha de auditoria nem limite de escopo
Quando um agente de IA tem acesso amplo a um repositório, ele frequentemente
"corrige tudo que vê pela frente" — inclusive fora do escopo pedido — sem
que ninguém saiba exatamente o que mudou, por quê, e quem aprovou. Isso gera
retrabalho, risco de regressão e perda de confiança na adoção de IA.

**Como o NIMBUS CODE resolve**: isolamento de sessão obrigatório (1 branch,
escopo de arquivos declarado), PR sempre revisado por humano antes do merge,
nunca merge direto pelo próprio agente, e um "Architecture Decision Log"
que registra toda decisão relevante — inclusive quando o agente diverge do
padrão institucional, ele documenta e pede aprovação em vez de decidir
silenciosamente.

### Problema 2 — Custo de IA sem critério (token caro em tarefa trivial)
Empresas que adotam IA generativa em escala frequentemente usam o modelo mais
caro disponível para qualquer tarefa — de corrigir um typo a desenhar uma
arquitetura de microsserviços — porque não existe uma régua de decisão.

**Como o NIMBUS CODE resolve**: escala de complexidade **S0–S4**, mapeada
diretamente para seleção de modelo de IA (do modo rápido/barato ao modelo de
reasoning mais forte), com estimativa de tokens declarada **antes** da tarefa
e comparada ao consumo real depois — visibilidade de custo desde o
planejamento, não uma surpresa na fatura.

### Problema 3 — Conhecimento organizacional se perde a cada nova sessão de agente
Cada nova sessão de IA "começa do zero" — o mesmo erro é cometido de novo, a
mesma solução é reinventada, e ninguém sistematiza o que já funcionou bem.

**Como o NIMBUS CODE resolve**: dois catálogos vivos e complementares —
**Catálogo de Reuso** (padrões técnicos já resolvidos, citados por ponteiro
em vez de re-explicados) e **Harness Engineering** (catálogo de erros/postmortems
que agentes futuros são obrigados a consultar antes de planejar) — mais o
**Loop de Melhoria Contínua**, que também cataloga o que **deu certo**
(não só o que deu errado), com cadência de retrospectiva e métricas DORA.

### Problema 4 — Backlog do GitHub sem hierarquia executiva
Times técnicos acumulam centenas de Issues sem uma estrutura Epic → Feature →
User Story → Task, o que torna impossível reportar progresso de forma
executiva ("em que Epic estamos investindo?") sem trabalho manual.

**Como o NIMBUS CODE resolve**: automação completa de hierarquia via GraphQL
nativo do GitHub (Issue Types + sub-issues), com fallback gracioso via labels
para organizações sem o recurso habilitado, deduplicação por ID estruturado
(reexecutável sem duplicar) e views de board hierárquicas prontas.

### Problema 5 — Risco de segurança/compliance quando o agente tem autonomia ampla
Sem guardrails explícitos, um agente de IA pode commitar segredo em texto
plano, pular revisão de segurança, ou tomar uma decisão arquitetural sensível
(ex.: sem backup, sem TLS) sem ninguém perceber a tempo.

**Como o NIMBUS CODE resolve**: **Security & DevSecOps Gate** obrigatório no
plano de toda feature, com itens explicitamente classificados como
**"Não-Negociável"** (backup, segredos, TLS, branch protegida — sem exceção
possível) vs. **"Escapável via ADR"** (aceitar desvio, mas só com justificativa
e aprovação humana registrada).

### Problema 6 — Dificuldade de medir o ROI real do "time humano + IA"
A maioria das organizações não sabe separar "quanto custou em tokens de IA" de
"quanto custou em horas humanas de revisão" — o que impede decisões de
investimento informadas.

**Como o NIMBUS CODE resolve**: rastreamento explícito de **Modelo Híbrido**
— toda feature registra estimativa de tokens + horas humanas, comparado ao
consumo real no fechamento, alimentando também os 4 indicadores **DORA**
(deployment frequency, lead time, change failure rate, MTTR).

---

## 3. O que o NIMBUS CODE entrega — os 10 pilares

| # | Pilar | O que faz |
|---|---|---|
| 1 | **Fluxo Spec-Driven** | `specify → clarify → plan → tasks → analyze → implement`, com templates e checklists de qualidade de requisitos ("testes unitários para a escrita da especificação") |
| 2 | **Escala de Complexidade S0–S4** | Seleciona automaticamente o modelo de IA certo por tarefa e exige revisão humana obrigatória em S4 (segurança/dados/arquitetura crítica) |
| 3 | **Grafo de Módulos obrigatório** | Todo PR que altera código precisa atualizar `graph.yaml`/`graph.md` — validado automaticamente em CI ("Graph Guard") |
| 4 | **Security & DevSecOps Gate** | Checklist de segurança não-negociável vs. escapável-via-ADR, aplicado a toda feature antes da implementação |
| 5 | **Hierarquia de Issues nativa no GitHub** | Epic → Feature → User Story → Task, criada automaticamente via GraphQL, com labels de fallback e deduplicação |
| 6 | **Catálogo de Reuso** | Reduz custo de tokens citando soluções já resolvidas por ponteiro, em vez de re-derivar |
| 7 | **Harness Engineering** | Catálogo de erros/postmortems — consulta obrigatória antes de planejar, para não repetir o mesmo engano |
| 8 | **Loop de Melhoria Contínua** | Catálogo de sucessos + métricas DORA + retrospectiva proativa por cadência |
| 9 | **Bootstrap de 1 comando** | Provisiona labels, board de projeto, views hierárquicas, devcontainer e scanning de segurança em qualquer repositório novo |
| 10 | **Governança de custo híbrido** | Rastreia tokens de IA + horas humanas lado a lado, com metodologia de comparação estimado vs. real |

---

## 4. Prova real (dados extraídos ao vivo do repositório em 2026-08-20)

| Métrica | Valor real |
|---|---|
| Features especificadas (Epic/Feature/domínio de produto) | **13** |
| Features com plano técnico completo (`plan.md`) | **13** |
| Features com tarefas geradas (`tasks.md`) | **10** (+ 1 em revisão) |
| Issues do GitHub sob governança ativa | **136** abertas |
| Issues 100% aderentes à taxonomia de labels (tipo + prioridade + complexidade + responsável) | **135 de 136 (~99%)** |
| Versão do bundle publicada | **v1.9.0** (release assets completos: preset, extensões, workflows) |
| Modelo de governança de segurança | **12 domínios de controle** no Security Gate (backup, segredos, IaC, TLS, SSO, firewall, observabilidade...) |
| Catálogos vivos de aprendizado organizacional | **2** (Reuso técnico + Harness de erros) + **1** em rollout (Playbooks de sucesso) |

---

## 5. Para quem é

- **Organizações adotando GitHub Copilot em escala** que precisam de
  governança além do "autocomplete individual".
- **Times de Platform Engineering / DevEx** que querem um padrão único e
  replicável de uso de agentes de IA entre múltiplos repositórios/squads.
- **Lideranças técnicas e de produto** que precisam de visibilidade executiva
  (Epic/Feature/US) sobre o que os agentes de IA estão de fato entregando —
  e quanto isso custa.
- **Times de segurança/compliance** que precisam de guardrails
  auditáveis *dentro* do fluxo de trabalho do agente, não como um controle
  externo desconectado.

---

## 6. Diferencial competitivo

- **100% nativo GitHub** (Issues, Projects, Actions, Copilot, Issue Types) —
  zero ferramenta externa de gestão de backlog ou orquestração.
- **Modelo Híbrido por princípio, não por acidente** — o agente propõe, o
  humano sempre valida; a governança está desenhada para nunca remover essa
  camada de decisão humana, mesmo em tarefas altamente autônomas.
- **Extensível como bundle instalável** — presets, extensões e workflows
  versionados e publicados como release, instaláveis em qualquer repositório
  novo em minutos via script de bootstrap.
- **Aprende nos dois sentidos** — cataloga o que deu errado (Harness) e o
  que deu certo (Loop de Melhoria Contínua), fechando o ciclo de melhoria
  contínua organizacional, não apenas técnico.

---

## 7. Uma frase de fechamento (para o slide final / pitch verbal)

> "NIMBUS CODE não é sobre fazer a IA escrever código mais rápido — é sobre
> a empresa conseguir confiar, auditar e medir o que os agentes de IA estão
> entregando, no mesmo GitHub que o time já usa todos os dias."
