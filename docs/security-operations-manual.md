# Manual de Operação de Segurança do GHE — Nimbus-Code

> **Escopo deste manual**: consolida em um único lugar **como o time opera, no dia a dia,**
> tudo o que foi desenvolvido/orquestrado pela feature
> [`007-controle-seguranca-ghe-projetos-plataforma`](/specs/007-controle-seguranca-ghe-projetos-plataforma/spec.md):
> a documentação de baseline, o GitHub App dedicado, o workflow semanal de varredura,
> o fluxo de issues de não conformidade e o relatório mensal consolidado.
>
> **Diferença em relação a `docs/security-baseline-ghe.md`**: aquele documento (entregue
> pelas tasks T013/T021/T028/T032 do [tasks.md](/specs/007-controle-seguranca-ghe-projetos-plataforma/tasks.md))
> é o **catálogo de controles obrigatórios** (o "o quê" — branch protection, papéis,
> tokens, checklist). Este manual é o **runbook operacional** (o "como" — quem faz o quê,
> quando, e o que fazer quando algo sai do previsto). Um referencia o outro; nenhum
> duplica o conteúdo do outro.

**Última atualização**: 2026-08-19
**Owner**: Responsável de Plataforma / Segurança (Nimbus-Code Architecture Board)
**Feature de origem**: [007-controle-seguranca-ghe-projetos-plataforma](/specs/007-controle-seguranca-ghe-projetos-plataforma/spec.md)

---

## 1. Visão geral do que foi orquestrado

| Componente | O que é | Onde vive |
|---|---|---|
| Baseline de segurança | Catálogo de controles obrigatórios (repositório + Projeto Plataforma) | `docs/security-baseline-ghe.md` *(entregue pela implementação desta feature)* |
| GitHub App dedicado | Credencial somente-leitura para a varredura org-wide | Organization Settings → GitHub Apps → "Nimbus Code Security Auditor" |
| Workflow semanal | Automação agendada que varre e reporta desvios | `.github/workflows/security-compliance-scan.yml` |
| Script de varredura | Lógica de descoberta, avaliação de controles e criação de issues | `scripts/security-compliance-scan.sh` |
| Issue de não conformidade | Rastreamento individual de um desvio detectado | Issues do GHE, label `security-baseline` |
| Relatório mensal | Consolidação das execuções semanais do mês | Issue/comentário de resumo mensal |
| ADR da credencial | Decisão de usar GitHub App em vez de PAT | [`docs/adr/0008-github-app-para-varredura-de-seguranca-org-wide.md`](/docs/adr/0008-github-app-para-varredura-de-seguranca-org-wide.md) |
| Plano técnico completo | Contexto, gates, riscos e ADL desta feature | [`specs/007-controle-seguranca-ghe-projetos-plataforma/plan.md`](/specs/007-controle-seguranca-ghe-projetos-plataforma/plan.md) |
| Mapa de impacto e risco | Análise de risco, rollback e critérios Go/No-Go (S4) | [`specs/007-controle-seguranca-ghe-projetos-plataforma/impact-map.md`](/specs/007-controle-seguranca-ghe-projetos-plataforma/impact-map.md) |

**Princípio operacional central**: a automação **nunca corrige nada sozinha**. Ela só
detecta e reporta (issue rastreável). Toda correção de configuração de repositório é
feita por um humano, seguindo o fluxo Nimbus Code já existente de labels/board/gates.

---

## 2. Papéis e responsabilidades

| Papel | Responsabilidade |
|---|---|
| **Administrador da organização (GHE)** | Cria/instala o GitHub App; concede/revoga instalação; suspende o App em caso de incidente |
| **Responsável de Plataforma** | Owner do workflow e do script; aprova rollout piloto → org-wide; mantém a rotação da chave do App |
| **Time de Engenharia/Governança** | Recebe e trata as issues de não conformidade dos seus repositórios; participa da auditoria mensal |
| **Tech Lead / Revisor humano (S4)** | Aprova o `plan.md` e o ADR-0008 antes de qualquer rollout em produção (gate obrigatório, sem exceção) |

---

## 3. Ciclo operacional semanal

1. **Segunda-feira, 10h BRT** — o workflow `security-compliance-scan.yml` roda automaticamente (cron) ou pode ser disparado manualmente via `gh workflow run security-compliance-scan.yml` (`workflow_dispatch`).
2. O script autentica-se como o GitHub App, resolve o escopo (`piloto` ou `org-wide`, conforme o flag `security.baseline_scan.org_wide_enabled`) e descobre os repositórios a avaliar.
3. Cada repositório é avaliado contra os controles do baseline (branch protection, revisão obrigatória, permissões de Actions, secrets configurados) e, para o Projeto Plataforma, contra a matriz de acesso documentada.
4. Para cada desvio (`status: pendente` ou `risco`): o script cria ou atualiza (idempotente) uma Issue no formato definido em [`finding-schema.md`](/specs/007-controle-seguranca-ghe-projetos-plataforma/contracts/finding-schema.md), com label `security-baseline` e prioridade conforme severidade.
5. O log da execução registra `repos_avaliados` e `repos_com_erro`. Se `repos_com_erro / repos_avaliados > 5%`, o workflow emite um `::warning::` (não falha a execução inteira).
6. **Responsável de cada repositório**: ao receber uma issue `security-baseline`, tratar como qualquer outra issue de prioridade — atribuir responsável, prazo, e corrigir manualmente a configuração indicada. A issue é fechada quando a próxima execução semanal confirmar `status: ok` (ou manualmente, após validação).

## 4. Ciclo operacional mensal

1. Ao final de cada mês, o relatório mensal é consolidado a partir das execuções semanais do período, no formato de [`monthly-report-contract.md`](/specs/007-controle-seguranca-ghe-projetos-plataforma/contracts/monthly-report-contract.md).
2. O relatório inclui: total de repositórios avaliados, % de conformidade por controle, desvios abertos e desvios corrigidos no mês.
3. **Responsável de Plataforma** revisa o relatório e decide se algum controle precisa de reforço (ex.: se "Secrets configurados" cair de conformidade mês a mês, investigar causa raiz).
4. O relatório mensal é a evidência objetiva usada para reportar SC-003 e SC-004 do [`spec.md`](/specs/007-controle-seguranca-ghe-projetos-plataforma/spec.md).

## 5. Rollout progressivo (piloto → organização inteira)

A varredura começa restrita ao bounded context piloto (`spec-kit-workflow`, registrado em `docs/bounded-contexts.yaml`) antes de cobrir toda a organização — controlado pelo flag OpenFeature `security.baseline_scan.org_wide_enabled`.

**Critério para avançar do piloto para org-wide** (todos devem ser verdadeiros):
- [ ] Pelo menos 2 execuções semanais completas no piloto, sem erro de API/permissão acima do SLO (5%)
- [ ] Nenhum falso positivo relatado pelo time do bounded context piloto
- [ ] Aprovação humana obrigatória (S4) registrada no ADR-0008 e no `plan.md`

**Como avançar**: alterar o valor do flag `security.baseline_scan.org_wide_enabled` de `false` para `true` na configuração do provider OpenFeature (env/arquivo, conforme `research.md`) — nenhuma mudança de código é necessária, apenas o valor do flag.

**Kill switch**: desativar o flag interrompe a criação de novas Issues (o workflow continua rodando em modo log/dry-run) — usar caso a varredura esteja gerando ruído excessivo ou comportamento inesperado.

## 6. Gestão da credencial (GitHub App)

- **Rotação da chave privada**: trimestral, obrigatória (ver risco registrado no `plan.md` e no `impact-map.md`). Gerar nova chave em Organization Settings → GitHub Apps → "Nimbus Code Security Auditor" → Generate a private key; atualizar o secret `SECURITY_SCAN_APP_PRIVATE_KEY`; revogar a chave antiga.
- **Monitoramento de uso anômalo**: revisar o audit log da organização (Enterprise audit log) periodicamente em busca de atividade do App fora do padrão esperado (ex.: chamadas fora do horário do cron).
- **Suspensão de emergência**: em caso de suspeita de comprometimento da chave, suspender a instalação do App imediatamente (Organization Settings → GitHub Apps → Advanced → Suspend) — isso interrompe todo o acesso sem precisar reverter código. Ver plano de rollback completo no [`impact-map.md`](/specs/007-controle-seguranca-ghe-projetos-plataforma/impact-map.md#4-plano-de-rollback).

## 7. Resposta a incidentes / rollback

Ver o plano de rollback detalhado (4 passos) já registrado em
[`impact-map.md`, seção 4](/specs/007-controle-seguranca-ghe-projetos-plataforma/impact-map.md#4-plano-de-rollback).
Resumo operacional:

1. Desativar o flag `security.baseline_scan.org_wide_enabled` (reduz escopo/impacto imediatamente).
2. Se o problema for a credencial: suspender o GitHub App (não requer deploy).
3. Issues já criadas não são revertidas automaticamente — avaliar manualmente se devem ser fechadas.
4. Se o problema for de lógica no script/workflow: abrir PR de revert.
5. Comunicar o Responsável de Plataforma antes de qualquer rollback em produção.

## 8. Checklist de operação (uso recorrente)

**Semanal** (Responsável de Plataforma ou automatizado via workflow):
- [ ] Confirmar que a execução semanal completou (log do Actions)
- [ ] Verificar se `repos_com_erro` ultrapassou 5% — se sim, investigar causa (rate limit, permissão, repositório arquivado)
- [ ] Confirmar que as issues de não conformidade da semana foram atribuídas a um responsável

**Mensal** (Responsável de Plataforma):
- [ ] Revisar o relatório mensal consolidado
- [ ] Atualizar a série histórica de % de conformidade por controle
- [ ] Verificar se algum bounded context precisa de atenção prioritária

**Trimestral** (Administrador da organização):
- [ ] Rotacionar a chave privada do GitHub App
- [ ] Revisar se as permissões do App continuam sendo o mínimo necessário (least privilege)
- [ ] Revisar o audit log da organização em busca de uso anômalo do App

**Por ocasião de mudança de escopo** (Responsável de Plataforma + Tech Lead):
- [ ] Qualquer expansão de escopo (ex.: novo controle avaliado, novo tipo de credencial) exige nova entrada no Architecture Decision Log do `plan.md` desta feature ou um novo ADR
- [ ] Mudanças que voltem a exigir revisão humana obrigatória (S4) não podem ser puladas

---

## 9. Referências

- [spec.md](/specs/007-controle-seguranca-ghe-projetos-plataforma/spec.md) — requisitos e clarificações
- [plan.md](/specs/007-controle-seguranca-ghe-projetos-plataforma/plan.md) — plano técnico, gates, ADL
- [research.md](/specs/007-controle-seguranca-ghe-projetos-plataforma/research.md) — decisões técnicas de suporte
- [data-model.md](/specs/007-controle-seguranca-ghe-projetos-plataforma/data-model.md) — entidades (Finding, Scan Run, Compliance Report)
- [contracts/](/specs/007-controle-seguranca-ghe-projetos-plataforma/contracts) — contratos de documentação, workflow, finding e relatório mensal
- [quickstart.md](/specs/007-controle-seguranca-ghe-projetos-plataforma/quickstart.md) — guia de validação E2E
- [impact-map.md](/specs/007-controle-seguranca-ghe-projetos-plataforma/impact-map.md) — riscos, rollback, critérios Go/No-Go
- [tasks.md](/specs/007-controle-seguranca-ghe-projetos-plataforma/tasks.md) — tarefas de implementação
- [ADR-0008](/docs/adr/0008-github-app-para-varredura-de-seguranca-org-wide.md) — decisão de credencial
- [docs/label-taxonomy-and-autonomous-dev.md](/docs/label-taxonomy-and-autonomous-dev.md) — taxonomia de labels usada nas issues de não conformidade
- `docs/security-baseline-ghe.md` — catálogo de controles obrigatórios *(entregue pela implementação desta feature — ver tasks T013/T021/T028/T032)*

> _Este manual deve ser atualizado sempre que o workflow, o script ou o GitHub App
> mudarem de comportamento. Divergência entre este manual e a implementação real é
> tratada como bug de documentação — abrir Issue e corrigir na próxima revisão._
