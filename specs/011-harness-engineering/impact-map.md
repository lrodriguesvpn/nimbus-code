# impact-map.md — Feature 011: Harness Engineering — Aprendizado Organizacional com Erros

> Obrigatório para S3/S4. Atualizar se a implementação divergir do plano.

---

## 1. Módulos Impactados

| Módulo | Tipo de impacto | Risco | Mitigação |
|---|---|---|---|
| `docs/harness/harness-catalog.yaml` | **Novo** — catálogo central de lições | Baixo — arquivo estático, sem side-effect | Validar YAML com `yq` ou `python3 -c 'import yaml'` antes do merge |
| `docs/harness/README.md` | **Novo** — documentação | Muito baixo — arquivo Markdown puro | Revisão de links e fluxo |
| `docs/harness/harness-guide.md` | **Novo** — documentação | Muito baixo | Revisão de completude |
| `docs/harness/incident-template.md` | **Novo** — template | Baixo — substitui processo informal | Validar que todos os campos do post-mortem têm correspondência com harness-catalog.yaml |
| `scripts/harness-search.sh` | **Novo** — script CLI | Baixo — somente leitura | Testar com catálogo existente e sem catálogo (arquivo ausente) |
| `presets/nimbus-code-standards/templates/plan-template.md` | **Estendido** — nova seção | Médio — afeta todos os planos futuros criados com o preset | Seção deve ser append (não alterar seções existentes); validar que plan.md desta feature já segue o novo template |
| `.github/copilot-instructions.md` | **Estendido** — instrução ao agente | Médio — muda protocolo de planejamento de todos os agentes futuros | Instrução deve ser adicionada sem remover ou alterar instruções existentes |
| `scripts/setup-github-labels.sh` | **Estendido** — 3 labels novos | Baixo — `--force` garante idempotência | Rodar 2x em sandbox; verificar que labels existentes não são alterados |
| `presets/nimbus-code-standards/templates/tasks-template.md` | **Estendido** — checklist de fechamento | Baixo — checklist aditivo | Verificar que passo de catalogação é claro e acionável |

---

## 2. Análise de Risco

### R001 — Seção "Harness Gate" no plan-template conflita com seções existentes (Baixo)

**Cenário**: A nova seção adicionada ao `plan-template.md` sobrescreve ou
duplica conteúdo de uma seção já existente (ex.: "Catálogo de Reuso").

**Probabilidade**: Baixa — a seção é adicionada como bloco novo com título único.

**Impacto**: Planos futuros ficam com instruções contraditórias; devs confusos
sobre qual seção preencher.

**Mitigação**: Adicionar a seção "Harness Gate" imediatamente após a seção de
"Catálogo de Reuso" no template, com nota explícita diferenciando os dois
catálogos (erros vs. soluções). Validar que não há título duplicado.

**Plano de rollback**: Remover a seção do template via PR de rollback — não
afeta planos já criados (são snapshots do template, não referências).

---

### R002 — Instrução no copilot-instructions.md é ignorada ou interpretada errado (Médio)

**Cenário**: A instrução de consulta ao harness é adicionada ao
`copilot-instructions.md`, mas o agente não a segue por ambiguidade na redação
ou por não encontrar o arquivo (`harness-catalog.yaml` vazio ou ausente).

**Probabilidade**: Média — instruções em linguagem natural podem ser interpretadas
de formas diferentes dependendo do contexto do agente.

**Impacto**: Harness Gate não é preenchido nos planos; lições catalogadas não são
consultadas; valor do catálogo não se realiza.

**Mitigação**: Redigir a instrução no formato imperativo direto (DEVE, SEMPRE,
ANTES DE), com exemplo concreto do que declarar no plan.md quando há e quando
não há match. Incluir fallback explícito: "se o arquivo estiver vazio, declara
'Catálogo vazio — nenhum padrão de erro disponível para consulta'".

**Plano de rollback**: Ajustar a redação da instrução via PR de follow-up; não
há rollback estrutural necessário.

---

### R003 — harness-catalog.yaml cresce sem curadoria e perde qualidade (Baixo-Médio)

**Cenário**: Com o tempo, entradas genéricas, incompletas ou contraditórias são
adicionadas ao catálogo, reduzindo sua utilidade para busca.

**Probabilidade**: Média — sem automação de validação de qualidade.

**Impacto**: Agentes encontram entradas de baixa qualidade; falsos positivos na
consulta; perda de confiança no catálogo.

**Mitigação**: O `harness-guide.md` inclui seção "Como escrever uma boa entrada"
com critérios explícitos. O campo `prevention` deve sempre ser uma instrução
acionável. O processo de merge do catálogo inclui revisão humana do PR.

**Plano de rollback**: Deprecar/remover entradas de baixa qualidade via PR,
com justificativa. Entradas nunca são apagadas sem registro — apenas marcadas
como `deprecated: true` quando substituídas.

---

### R004 — script harness-search.sh falha quando yq não está instalado (Baixo)

**Cenário**: O script usa `yq` para parsing YAML, mas o dev/agente não tem `yq`
instalado no ambiente.

**Probabilidade**: Baixa-média — `yq` não é pré-instalado em todos os ambientes.

**Impacto**: Script falha com erro de comando não encontrado; dev não consegue
buscar no catálogo via script.

**Mitigação**: Implementar fallback `grep`/`awk` quando `yq` não está disponível;
o `grep` é suficiente para a maioria dos casos de busca por tag/context.

**Plano de rollback**: O `grep` direto sempre funciona como alternativa manual.

---

## 3. Plano de Rollback Geral

Esta feature é composta de artefatos aditivos (novos arquivos + novas seções/labels).
O rollback é trivial:

1. **Revert do PR** — restaura todos os arquivos ao estado pré-feature
2. **Sem dados a migrar** — nenhum datastore externo foi alterado
3. **Labels criados** — permanecem no repositório após rollback do script, mas
   não causam dano (labels órfãos sem issues associadas)
4. **Planos já criados** com a seção "Harness Gate" continuam válidos — a seção
   opcional pode ser ignorada se o template for revertido

---

## 4. Go/No-Go Criteria

| Critério | Gate | Verificação |
|---|---|---|
| `harness-catalog.yaml` válido | Qualidade | `python3 -c "import yaml; yaml.safe_load(open('docs/harness/harness-catalog.yaml'))"` sem erro |
| Seção "Harness Gate" no plan-template não conflita com seções existentes | Qualidade | Grep por títulos duplicados no template |
| Labels `harness:*` criados sem erro | AC-5 | `gh label list --repo org/repo \| grep harness` |
| `harness-search.sh` executável e retorna resultado | AC-4 | `./scripts/harness-search.sh agent-scope-creep` retorna HRN-0001 |
| Copilot instructions menciona harness-catalog explicitamente | AC-1 | Grep por "harness-catalog" em `.github/copilot-instructions.md` |

## Remediação S3 — 2026-09-20

| Superfície | Risco | Mitigação / validação |
|---|---|---|
| CLI local e cópia no preset | Divergência de distribuição ou falso negativo sem `yq` | Teste de paridade e execução das duas cópias sem `yq` |
| Parser do schema YAML do catálogo | Perder entradas, campos multiline ou aspas | Fixtures com IDs/scalars quoted/unquoted, listas block/flow e múltiplos matches |
| Termo fornecido pelo usuário | Interpretar regex, escapes ou código | Termo via ambiente, comparação literal `index`, sem interpolação de programa |
| Revisões institucionais | Confundir regressão local com aprovação humana | #453/#437 permanecem abertas; nenhum label ou ambiente remoto é alterado |

Rollback: reverter conjuntamente as duas cópias do script e o teste desta
remediação, preservando os dados do catálogo. Nenhuma migração ou alteração
operacional externa é necessária.
