# impact-map.md — Feature 021: Governança de Métricas DORA com Coleta Híbrida

> Obrigatório para S3/S4. Atualizar se a implementação divergir do plano.

---

## 1. Módulos Impactados

| Módulo | Tipo de impacto | Risco | Mitigação |
|---|---|---|---|
| `scripts/process-metrics-report.sh` | Extensão de script existente (qualidade de dados, gate de fechamento, cadência semanal) | Médio — script já usado em produção (feature 012); regressão afeta cálculo de indicadores já consumidos | Testes de integração existentes (`*.detect.test.sh`, `*.retro-cadence.test.sh`) continuam passando + novos testes cobrindo as extensões antes de merge |
| `docs/playbooks/dora-manual-adjustments-log.yaml` | Novo arquivo | Baixo — arquivo estático aditivo, mesmo padrão de `retro-cadence-state.yaml` | Schema comentado + validação por script antes de aceitar entrada incompleta |
| `docs/playbooks/README.md` | Adição de seções (cadência semanal, regras de qualidade, fluxo de ajuste manual) | Baixo — adição, não remove conteúdo existente da seção DORA já presente (feature 012) | Revisão de PR confirma que a seção mensal já existente permanece intacta |
| `tests/scripts/` (novos arquivos de teste) | Novos testes de integração | Baixo — apenas adiciona cobertura | — |

---

## 2. Análise de Risco

### R001 — Extensão do script quebra o cálculo já existente dos 4 indicadores (Médio)

**Cenário**: A adição de qualidade de dados/auditoria/gate introduz uma
regressão em `scripts/process-metrics-report.sh` que quebra o cálculo básico
dos 4 indicadores já usado pela feature 012.

**Probabilidade**: Média — qualquer mudança em um script já em produção com
lógica condicional adicional tem risco de regressão.

**Impacto**: Médio — squads que já dependem do script para revisão mensal
ficariam sem dado confiável até a correção.

**Mitigação**: Rodar a suíte de testes já existente
(`tests/scripts/process-metrics-report.detect.test.sh` e
`tests/scripts/process-metrics-report.retro-cadence.test.sh`) antes e depois
da extensão, garantindo que nenhum teste pré-existente quebre; novos testes
cobrem apenas o comportamento adicional (qualidade de dados, auditoria,
gate), sem alterar a lógica de cálculo original dos 4 indicadores.

**Plano de rollback**: `git revert` do PR de extensão — o script volta ao
comportamento da feature 012, sem efeito colateral em dados já coletados
(scripts são somente-leitura sobre issues/PRs).

---

### R002 — Ajuste manual aceito sem trilha de auditoria completa (Médio)

**Cenário**: Uma entrada em `docs/playbooks/dora-manual-adjustments-log.yaml`
é aceita sem `evidence_link` ou `author`, comprometendo a credibilidade da
métrica (viola FR-004/FR-012 diretamente).

**Probabilidade**: Baixa-Média — depende de o gate de validação ser
efetivamente determinístico (bash, não apenas prosa) e sempre executado.

**Impacto**: Alto se acontecer — é exatamente o risco que esta feature existe
para eliminar (credibilidade dos dados DORA).

**Mitigação**: O gate de validação segue o padrão determinístico já usado por
`check-epic-issue-consistency.sh`/`check-task-hierarchy-consistency.sh`
(reuse-catalog tag `skill-mid-flow-instruction-reliability-gate`) — não
depende de o operador "lembrar" de preencher todos os campos; o script
rejeita entradas incompletas antes de persistir.

**Plano de rollback**: Corrigir/completar a entrada incompleta diretamente no
YAML versionado — sem impacto em nenhum outro sistema, já que é um arquivo
estático consultado sob demanda.

---

### R003 — Gate de fechamento vira bloqueio permanente por ajuste nunca resolvido (Baixo)

**Cenário**: Um `Manual Adjustment` fica pendente indefinidamente (ninguém
completa a justificativa), impedindo o fechamento de toda `Review Cycle`
futura que o referencie.

**Probabilidade**: Baixa — o gate bloqueia apenas o ciclo específico com
pendência, não ciclos futuros sem relação com aquele ajuste.

**Impacto**: Baixo — no pior caso, um único ciclo de revisão permanece
`open` até alguém completar a justificativa; não impede a coleta automática
de continuar normalmente.

**Mitigação**: `pending_manual_adjustments` (ver `data-model.md`) é sempre
reportado explicitamente pelo script, permitindo identificar rapidamente
quem precisa agir para desbloquear o fechamento.

**Plano de rollback**: N/A — não é um bug, é o comportamento pretendido
(FR-006); "rollback" aqui é apenas completar a justificativa pendente.

---

## 3. Plano de Rollback Geral

| Artefato | Reversão |
|---|---|
| `scripts/process-metrics-report.sh` (extensões) | `git revert` do PR — reverte para o comportamento da feature 012, sem efeito colateral em dados já coletados (script somente-leitura) |
| `docs/playbooks/dora-manual-adjustments-log.yaml` | Deletar o arquivo — nenhum outro módulo depende dele para funcionar além do próprio gate desta feature |
| `docs/playbooks/README.md` (seções novas) | `git revert` do PR — remove as seções aditivas sem afetar a seção mensal já existente da feature 012 |
| `tests/scripts/*` (novos) | `git revert` do PR — sem impacto nos testes já existentes |

---

## 4. Critérios de Go / No-Go

| Critério | Go | No-Go |
|---|---|---|
| Testes pré-existentes de `process-metrics-report.sh` continuam passando após a extensão | `bash tests/scripts/process-metrics-report.detect.test.sh` e `*.retro-cadence.test.sh` ✅ | Qualquer teste pré-existente falhando |
| Ajuste manual incompleto é sempre rejeitado (AC-3/FR-004) | Confirmado por teste de integração dedicado | Qualquer caminho aceita ajuste sem os 5 campos obrigatórios |
| `Review Cycle` nunca fecha com ajuste pendente (FR-006) | Confirmado por teste de integração dedicado | Gate reporta `closed` com `pending_manual_adjustments` não vazio |
| Cadência semanal documentada além da mensal já existente (FR-010) | `docs/playbooks/README.md` contém ambas as cadências | Apenas cadência mensal presente |
| PR sem secrets detectados | `secret scanning` não retorna findings | Qualquer finding de secret |
