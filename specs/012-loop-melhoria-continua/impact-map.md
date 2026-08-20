# impact-map.md — Feature 012: Loop de Melhoria Contínua Nimbus-Code

> Obrigatório para S3/S4. Atualizar se a implementação divergir do plano.

---

## 1. Módulos Impactados

| Módulo | Tipo de impacto | Risco | Mitigação |
|---|---|---|---|
| `docs/playbooks/success-catalog.yaml` | Novo arquivo | Baixo — arquivo estático aditivo | Curadoria manual desde o início (mesmo racional das features 001/011) |
| `scripts/process-metrics-report.sh` | Novo script | Baixo — somente leitura, sem escrita em issues/PRs | Testado com `bash -n` e fixture de issues/PRs rotulados |
| `presets/nimbus-code-standards/templates/plan-template.md` (+ cópia `.specify/presets/`) | Adição de seção | Médio — afeta todo `plan.md` novo gerado por qualquer projeto que usa o preset | Adição puramente aditiva (nova seção), não altera nenhuma seção existente; testar geração de plano após a mudança |
| `presets/nimbus-code-standards/templates/tasks-template.md` (+ cópia `.specify/presets/`) | Adição de item de checklist | Baixo — item adicional, não remove nenhum existente | — |
| `.github/copilot-instructions.md` | Adição de seção | Baixo — instrução adicional para o agente, não substitui nenhuma existente | — |
| `docs/reuse-catalog.yaml` | Nova entrada | Baixo — apenas acrescenta | — |

---

## 2. Análise de Risco

### R001 — Confusão entre Harness Catalog e Success Catalog (Baixo-Médio)

**Cenário**: Um agente ou dev registra uma entrada de sucesso no
`harness-catalog.yaml` por engano (ou vice-versa), poluindo os dois catálogos.

**Probabilidade**: Baixa — os dois arquivos têm nomes/paths claramente
distintos (`docs/harness/` vs. `docs/playbooks/`) e os dois gates do
`plan.md` (Harness Gate vs. Playbook de Sucesso Gate) são seções separadas
com propósito declarado explicitamente.

**Impacto**: Baixo — mesmo se acontecer, é apenas uma entrada mal
categorizada num arquivo YAML, corrigível por edição manual simples.

**Mitigação**: `docs/harness/harness-guide.md` (feature 011) e um guia
análogo desta feature devem deixar explícita a distinção (ver Edge Case do
`spec.md`: "Harness cataloga erros; esta feature cataloga sucessos").

**Plano de rollback**: Editar/mover a entrada para o catálogo correto — sem
impacto em nenhum outro sistema.

---

### R002 — Métricas DORA calculadas incorretamente por dado insuficiente/mal rotulado (Médio)

**Cenário**: `process-metrics-report.sh` calcula um indicador com base em
poucos itens rotulados, gerando um número estatisticamente pouco
significativo mas apresentado com a mesma confiança de um indicador bem
amostrado.

**Probabilidade**: Média — labels `dora:*` são aplicados manualmente e a
cobertura pode ser inconsistente entre repositórios/times.

**Impacto**: Médio — uma meta de melhoria de processo baseada em dado ruim
pode levar a uma ação de melhoria mal direcionada.

**Mitigação**: O script marca explicitamente indicadores com "dados
insuficientes" (ver `data-model.md`, campo `insufficient_data_flags`) em vez
de reportar um número enganosamente preciso — decisão de design já registrada
no `spec.md` (Edge Case) e no `research.md`.

**Plano de rollback**: N/A — o script é somente leitura; se o cálculo estiver
errado, basta corrigir a lógica e rodar de novo, sem efeito colateral em
dados já existentes.

---

### R003 — Retrospectiva proativa vira ruído/spam se a cadência N for mal calibrada (Baixo)

**Cenário**: N muito baixo gera sinalizações de retrospectiva frequentes
demais, gerando fadiga e o time passa a ignorar o sinal.

**Probabilidade**: Baixa-Média — depende do valor inicial escolhido (sugestão
N=5) e do ritmo real de entrega do time.

**Impacto**: Baixo — a decisão de quando efetivamente parar para
retrospectiva continua sendo humana (o agente só sinaliza, não bloqueia
nada), então o pior caso é a sinalização ser ignorada, não um bloqueio de
trabalho.

**Mitigação**: N é configurável por projeto no `plan.md` (não é uma
constante fixa do bundle) — times podem ajustar conforme sua cadência real.

**Plano de rollback**: Ajustar o valor de N no `plan.md` — sem necessidade de
mudança de código.

---

## 3. Plano de Rollback Geral

| Artefato | Reversão |
|---|---|
| `docs/playbooks/success-catalog.yaml` | Deletar o arquivo — nenhum outro módulo depende dele para funcionar (é consultado, não é dependência hard de nenhum script) |
| `scripts/process-metrics-report.sh` | Deletar o script — não é chamado por nenhum workflow automatizado (uso sob demanda) |
| `plan-template.md`/`tasks-template.md` (seções novas) | `git revert` do PR — remove as seções aditivas sem afetar o restante do template |
| `.github/copilot-instructions.md` | `git revert` do PR |
| `docs/reuse-catalog.yaml` | Remover a entrada adicionada — sem impacto em outras entradas |

---

## 4. Critérios de Go / No-Go

| Critério | Go | No-Go |
|---|---|---|
| `process-metrics-report.sh` calcula os 4 indicadores em < 10s (SC-002) | Confirmado em teste com fixture | Timeout ou erro não tratado |
| Nenhuma entrada gravada no `success-catalog.yaml` sem `validated_by` (FR-007) | Confirmado por revisão do fluxo de proposta/validação | Qualquer entrada gravada sem validação humana |
| Playbook de Sucesso Gate presente em `plan-template.md` (AC-5) | Seção presente e nunca deixada em branco nos testes | Seção ausente ou opcional |
| Distinção clara entre Harness (erro) e Playbook (sucesso) documentada | `docs/harness/harness-guide.md` e guia análogo desta feature deixam isso explícito | Documentação ambígua sobre quando usar qual catálogo |
| PR sem secrets detectados | `secret scanning` não retorna findings | Qualquer finding de secret |
