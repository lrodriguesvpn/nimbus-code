# Labels — Priorização, Ordenamento e Desenvolvimento Autônomo

> **TL;DR** (S0/S1 — leitura completa reservada para S2+ ou dúvida
> específica): ordene o backlog por `priority:P0-blocker` > `P1-high` >
> `P2-medium` > `P3-low`; desenvolvimento autônomo só com
> `agent:autonomous-ok` **e sem** `agent:needs-human`/`complexity:S4`/
> `type:incident`/`status:blocked`; `type:incident` e `complexity:S4` sempre
> exigem revisão humana; `dora:*` só correlaciona métrica, não dispara
> automação. Ver seções abaixo para o detalhamento e os guardrails do
> workflow de auto-assign.

Este documento descreve a taxonomia padrão de labels do bundle VPN Dev, criada
via [`scripts/setup-github-labels.sh`](../scripts/setup-github-labels.sh), e
como ela é usada para (1) **priorizar e ordenar** issues/PRs no backlog e (2)
decidir quais issues são candidatas a **desenvolvimento autônomo** por agente
(ex.: GitHub Copilot coding agent) via o workflow
[`.github/workflows/agent-auto-assign.yml`](../.github/workflows/agent-auto-assign.yml).

Nasce junto com todo projeto novo que roda `bootstrap.sh` (ver
[README — Bônus: GitHub Project criado automaticamente](../README.md#bônus-github-project-criado-automaticamente))
— não é algo que cada time precisa inventar depois.

## 1. Por que um processo de labels formal?

Sem uma taxonomia compartilhada, cada projeto da VPN Dev acaba reinventando (ou
não tendo) uma forma consistente de responder a duas perguntas recorrentes:

1. **Em que ordem o time (humano ou agente) deve puxar o próximo item do
   backlog?** → resolvido pelos labels `priority:*`.
2. **Esta issue pode ser implementada por um agente de IA sem um humano
   precisar acompanhar cada passo, ou exige revisão humana desde o início?**
   → resolvido pelos labels `agent:*` (e pela guardrail automática de
   `complexity:S4`, que nunca é autônoma).

## 2. Taxonomia completa

| Categoria | Label | Cor | Uso |
|---|---|---|---|
| Prioridade | `priority:P0-blocker` | `#b60205` | Bloqueador — trata antes de qualquer outro item |
| Prioridade | `priority:P1-high` | `#d93f0b` | Próximo item a puxar após todo P0 |
| Prioridade | `priority:P2-medium` | `#fbca04` | Planejado, sem urgência imediata |
| Prioridade | `priority:P3-low` | `#0e8a16` | Nice-to-have |
| Complexidade | `complexity:S0`–`S4` | gradiente verde→vermelho | Mesma escala S0–S4 do `copilot-instructions.md` (ver [`ai-code-quality-and-observability.md`](ai-code-quality-and-observability.md#6-seleção-de-modelo-por-complexidade-s0s4)) |
| Tipo | `type:bug` / `type:feature` / `type:chore` / `type:docs` / `type:incident` | padrão GitHub | Classificação padrão de issue/PR — `type:incident` é originada de ocorrência em produção/ambiente de cliente e **sempre** exige revisão humana (ver seção 4.1) |
| Agente | `agent:autonomous-ok` | `#0e8a16` | Dispara o auto-assign ao Copilot coding agent |
| Agente | `agent:needs-human` | `#e99695` | Bloqueia qualquer auto-assign, mesmo que `agent:autonomous-ok` também esteja presente |
| Status | `status:needs-triage` | `#ededed` | Issue nova, ainda sem `priority:*`/`complexity:*` — não deve ser puxada por agente autônomo |
| Status | `status:blocked` | `#5319e7` | Pular na fila, mesmo com `priority:P0-blocker` |
| DORA | `dora:deployment-frequency` | `#0052cc` | Issue impacta a frequência de deploy |
| DORA | `dora:lead-time` | `#1d76db` | Issue impacta o lead time for changes |
| DORA | `dora:change-failure-rate` | `#d93f0b` | Issue impacta a taxa de falha de mudança |
| DORA | `dora:mttr` | `#b60205` | Issue impacta o tempo de restauração de serviço (MTTR) |

A lista de labels (nome, cor, descrição) vive como fonte única da verdade em
[`scripts/setup-github-labels.sh`](../scripts/setup-github-labels.sh) — este
documento explica o *porquê*, o script é o *o quê* executável.

## 3. Ordenamento do backlog

A ordem de leitura recomendada para qualquer pessoa (ou agente) decidir "qual é
o próximo item a puxar" é:

1. Excluir tudo com `status:blocked` ou `status:needs-triage`.
2. Ordenar o restante por `priority:*`: `P0-blocker` > `P1-high` >
   `P2-medium` > `P3-low`. Itens sem label de prioridade são tratados como
   `P2-medium` por padrão (ver comentários do workflow
   `.github/workflows/agent-auto-assign.yml`).
3. Dentro do mesmo nível de prioridade, usar `complexity:*` apenas para
   decidir alocação de agente/modelo (ver escala S0–S4) — não para desempatar
   ordem, a menos que o time decida isso explicitamente.

Essa ordenação é visualizável diretamente na view **"Board por Prioridade"**
do GitHub Project criado por
[`scripts/setup-github-project.sh`](../scripts/setup-github-project.sh) —
agrupe/ordene essa view pelos labels `priority:*` para obter a fila real.

## 4. Desenvolvimento autônomo: quando é seguro?

Uma issue é candidata a desenvolvimento 100% autônomo (sem humano precisar
acompanhar cada etapa) quando:

- Tem o label `agent:autonomous-ok` **e**
- **Não** tem `agent:needs-human` **e**
- **Não** tem `complexity:S4` (regra da constituição VPN Dev: S4 sempre exige
  revisão humana, nunca é autônomo — ver
  [`constitution-template.md`](../presets/vpndev-standards/templates/constitution-template.md)) **e**
- **Não** tem `type:incident` (regra da constituição VPN Dev: issues originadas
  de ocorrência em produção/ambiente de cliente sempre exigem revisão humana,
  independente da complexidade S0–S4 — ver seção 6) **e**
- **Não** tem `status:blocked` **e**
- Ainda não tem nenhum assignee (evita reatribuir trabalho em andamento).

Todas essas condições são verificadas automaticamente pelo workflow antes de
atribuir — se qualquer uma falhar, o workflow **comenta na issue explicando o
motivo** em vez de falhar silenciosamente ou assumir o pior.

### Como funciona o gatilho

```mermaid
flowchart LR
    A["Alguém aplica o label\nagent:autonomous-ok"] --> B{"Guardrails OK?\nagent:needs-human?\ncomplexity:S4?\ntype:incident?\nstatus:blocked?\njá tem assignee?"}
    B -- "Falhou alguma" --> C["Comenta na issue\nexplicando o motivo\n(não atribui)"]
    B -- "Passou em todas" --> D["Atribui copilot-swe-agent[bot]\nvia REST API\ncom prioridade no contexto"]
    D --> E["Copilot coding agent\ntrabalha na issue\ne abre PR"]
```

### Pré-requisitos para habilitar o auto-assign

1. Rodar `scripts/setup-github-labels.sh` no repositório (cria a taxonomia).
2. Copiar `.github/workflows/agent-auto-assign.yml` para o repositório do
   projeto (feito automaticamente pelo `bootstrap.sh`; ver seção 6).
3. GitHub Copilot coding agent habilitado no repositório/organização.
4. Configurar o secret `COPILOT_AGENT_ASSIGN_TOKEN`: um **Personal Access
   Token** (classic com escopo `repo`, ou fine-grained com leitura/escrita em
   `actions`, `contents`, `issues` e `pull requests`) de um usuário com acesso
   de escrita ao repositório.

   **Por que não dá para usar o `GITHUB_TOKEN` padrão?** A API de atribuição
   de issues ao Copilot só aceita autenticação **user-to-server** (PAT, OAuth
   app token, ou GitHub App user-to-server token). O `GITHUB_TOKEN` que o
   GitHub Actions injeta automaticamente é um token **server-to-server**
   (installation token), explicitamente **não suportado** por essa API — ver
   [documentação oficial da API de agentes do Copilot](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/cloud-agent/use-cloud-agent-via-the-api).
   Sem o secret configurado, o workflow falha explicitamente com uma mensagem
   clara, em vez de tentar e falhar de forma confusa.

Sem o secret configurado, o workflow **falha explicitamente** (ver step
"Atribuir Copilot coding agent à issue") em vez de tentar e falhar de forma
confusa — assim quem instalar o bundle percebe rapidamente que falta esse
passo de configuração.

### Guardrail: por que `complexity:S4` bloqueia sempre

Isso não é uma decisão do workflow — é a aplicação técnica de uma regra que já
existe na constituição do preset (`Features S4 exigem label complexity:S4 no
PR e revisão humana`, ver
[`constitution-template.md`](../presets/vpndev-standards/templates/constitution-template.md)).
O workflow apenas garante que essa regra não pode ser contornada
acidentalmente aplicando `agent:autonomous-ok` numa issue S4.

### Guardrail: por que `type:incident` bloqueia sempre

Mesma lógica do guardrail de `complexity:S4`, mas para uma dimensão diferente:
uma issue pode ser tecnicamente simples (S0/S1) e ainda assim ser
**arriscada de automatizar** porque se origina de uma ocorrência real em
produção/ambiente de cliente — o contexto de "algo já quebrou uma vez" pesa
mais que a complexidade técnica isolada da correção. Por isso `type:incident`
bloqueia autonomia **independente** do label `complexity:*` presente na
mesma issue. Ver seção 6 para o fluxo completo de ocorrência → issue.

## 5. Labels DORA — correlação com métricas DevOps

Os labels `dora:*` não afetam nenhum workflow automático (não são gatilho de
nada) — são puramente um **domínio de classificação** para permitir consultas
e dashboards que correlacionem issues fechadas com os **4 indicadores DORA**
("Four Keys", DevOps Research and Assessment):

| Label | Métrica DORA correspondente | Quando aplicar |
|---|---|---|
| `dora:deployment-frequency` | Deployment Frequency | Issues sobre pipeline de release, automação de deploy, cadência de entrega (ex.: "automatizar deploy canário", "reduzir passos manuais do release") |
| `dora:lead-time` | Lead Time for Changes | Issues sobre reduzir o tempo entre commit e produção (ex.: "paralelizar suite de testes no CI", "remover aprovação manual redundante") |
| `dora:change-failure-rate` | Change Failure Rate | Bugs introduzidos por um deploy/mudança recente, ou trabalho preventivo para reduzir a taxa de falha (ex.: "adicionar smoke test pós-deploy") |
| `dora:mttr` | Time to Restore Service (MTTR) | Incidentes, hotfixes emergenciais, ou trabalho para acelerar detecção/recuperação (ex.: "melhorar alerta de rollback automático") |

**Como usar na prática:**

1. Aplique o label `dora:*` relevante ao **triar** a issue — pode coexistir
   com `priority:*`, `complexity:*` e `type:*` normalmente (não são mutuamente
   exclusivos; uma issue pode até ter mais de um `dora:*` se impactar mais de
   uma métrica, embora isso deva ser raro).
2. Nem toda issue precisa de um label `dora:*` — só aplique quando a issue tem
   relação direta e mensurável com um dos 4 indicadores. Trabalho de feature
   comum (sem relação com pipeline/incidente/qualidade de release) não precisa
   desse label.
3. Para reportar as métricas de fato, consulte/filtre issues fechadas por
   `dora:*` e cruze com dados reais de deploy do seu pipeline de CI/CD — os
   labels **não substituem** a medição automatizada (deploy timestamps,
   incident timestamps), apenas dão contexto de **quais itens de trabalho**
   contribuíram para mover cada indicador, o que é útil para retrospectivas e
   priorização (ex.: "quantas issues P1/P2 deste trimestre foram sobre
   `dora:change-failure-rate`? Vale investir mais aqui?").
4. Times que já têm uma ferramenta dedicada de métricas DORA (ex.: DORA
   Metrics do GitHub, um dashboard próprio) podem usar esses labels como
   **complemento qualitativo** (visão de "issue → intenção"), não como
   substituto da fonte de verdade quantitativa.

## 6. Ocorrências (CRM) e Issues de Infraestrutura

Times que hoje gerenciam atendimento inicial (N1) de ocorrências num CRM (ex.:
Dynamics 365) e querem trazer o trabalho de infraestrutura resultante para o
Spec Kit seguem este fluxo:

```mermaid
flowchart LR
    A["Ocorrência aberta\nno CRM (N1)"] --> B{"N1 resolve com\nprocedimento padrão?"}
    B -- "Sim" --> C["Fecha no CRM\n(não vira issue)"]
    B -- "Não — exige mudança\nreal no ambiente" --> D["Cria issue no repo\nde INFRA"]
    D --> E["Label type:incident\n+ dora:mttr"]
    D --> F["Campo \"Ocorrência CRM (N1)\"\n= URL/ID do atendimento"]
    E --> G["complexity:S0-S4\nnormal (a maioria S0/S1)"]
    G --> H["Revisão humana OBRIGATÓRIA\n(type:incident bloqueia\nauto-assign sempre)"]
```

**Critério de "quando vira issue"**: se o N1 resolveu com um procedimento
padrão já documentado (reinício, ajuste de configuração pontual), **não**
precisa virar issue — foi só um atendimento. Se exigir uma mudança real e
potencialmente recorrente no ambiente (script, correção de infraestrutura,
algo que provavelmente vai se repetir se não for corrigido na causa raiz),
**aí sim** vira issue no repositório de INFRA correspondente.

**Na issue de INFRA:**

- Label `type:incident` (ver seção 2 e o guardrail na seção 4) — **sempre**
  bloqueia atribuição autônoma ao Copilot coding agent, independente da
  complexidade S0–S4 daquela issue específica.
- Label `dora:mttr` na maioria dos casos — o tempo entre abertura da issue e
  fechamento é literalmente a métrica de tempo de restauração de serviço.
- Campo **"Ocorrência CRM (N1)"** do GitHub Project (criado por
  `scripts/setup-github-project.sh`) preenchido com a URL/ID do atendimento
  original no CRM — rastreabilidade e cálculo de MTTR consistente entre as
  duas ferramentas.
- Classificação S0–S4 normal — a maioria das correções de ocorrência é S0/S1,
  mas se a causa raiz exigir redesenho de infraestrutura, pode chegar a S2+
  (e então também exige `graph.yaml`/`graph.md`, e S3/S4 exige `impact-map.md`).

**Infraestrutura sem Terraform (ou sem IaC formal):** isso não é bloqueio
para usar o Spec Kit. A classificação S0–S4, o Module Dependency Graph e o
`impact-map.md` (S3/S4) não presumem nenhuma ferramenta específica de IaC —
o `impact-map.md` fica, na verdade, **mais crítico** quando não há
`terraform plan` como rede de segurança, pois passa a ser o único artefato
documentando blast radius e plano de rollback antes de uma mudança manual no
ambiente do cliente. Documente no `plan.md` da feature qual é a ferramenta
real usada (script, runbook, ClickOps documentado, Ansible, etc.) — o Spec
Kit governa o *o quê* e o *porquê* (spec, critérios de aceitação, risco),
não exige uma ferramenta específica para o *como*.

## 7. Instalação em um projeto novo ou existente

O `bootstrap.sh` já chama `setup-github-labels.sh` automaticamente (mesmo
padrão do GitHub Project — ver
[README](../README.md#bônus-github-project-criado-automaticamente)). Para
instalar manualmente (ou num repositório que já existe e não vai rodar o
bootstrap de novo):

```bash
# 1. Criar/atualizar a taxonomia de labels no repositório
bash ./scripts/setup-github-labels.sh --repo-owner venha-pra-nuvem --repo-name meu-projeto

# 2. Copiar o workflow de auto-assign
mkdir -p .github/workflows
curl -fsSL https://raw.venha-pra-nuvem.ghe.com/venha-pra-nuvem/speckit-vpndev-standards/main/.github/workflows/agent-auto-assign.yml \
  > .github/workflows/agent-auto-assign.yml
git add .github/workflows/agent-auto-assign.yml

# 3. Configurar o secret no GitHub (Settings → Secrets and variables → Actions)
gh secret set COPILOT_AGENT_ASSIGN_TOKEN --repo venha-pra-nuvem/meu-projeto
```

## 8. Evitando disparo duplicado (importante antes de habilitar)

Este workflow é **o único gatilho versionado** deste bundle para atribuição
automática ao Copilot — não existe (e nunca existiu neste repositório) nenhum
outro label, script ou workflow que dispare a mesma ação. O botão manual
**"Assign to Copilot"** em Assignees continua existindo e não conflita, pois é
uma ação humana explícita, não um gatilho automático.

**Atenção a uma fonte de duplicidade que fica FORA do controle deste bundle**:
o GitHub tem uma feature nativa chamada **Copilot cloud agent Automations**
(aba **Agents → Automations** de cada repositório), configurada diretamente
na UI por qualquer pessoa com acesso de escrita — ela **não é versionada em
git**, não aparece em nenhum arquivo do repositório e é **privada de quem a
criou** (nem outros admins do repo a veem). Se alguém já tiver configurado ali
uma automação com trigger "when an issue is created" ou similar, ela rodaria
**em paralelo** a este workflow e poderia atribuir/comentar duas vezes.

Antes de habilitar `agent-auto-assign.yml` num repositório:

1. Confira a aba **Agents → Automations** do repositório (cada colaborador
   precisa checar a própria lista — automações são privadas por criador) e
   desative/ajuste qualquer automação existente com trigger em issues que
   também assigne o Copilot, para não duplicar com este workflow.
2. Se o projeto já usa Automations nativas para esse fim e prefere continuar
   assim, **não instale** `agent-auto-assign.yml` — os dois mecanismos não
   devem coexistir no mesmo repositório para a mesma finalidade.

## 9. Relação com outros documentos

- [`ai-code-quality-and-observability.md`](ai-code-quality-and-observability.md#5-bugs-abertos-e-atribuídos-automaticamente-ao-copilot) —
  gestão de bugs e atribuição ao Copilot (contexto mais amplo).
- [`module-graphs.md`](module-graphs.md) — por que `complexity:S4` exige
  `impact-map.md` e revisão humana.
- [`constitution-template.md`](../presets/vpndev-standards/templates/constitution-template.md) —
  a regra organizacional da qual a guardrail de S4 deste workflow deriva.
- [`developer-guide.md`](developer-guide.md) — manual do dev, cenários de uso
  ponta a ponta.
