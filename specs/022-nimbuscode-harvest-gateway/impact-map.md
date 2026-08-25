# Mapa de Impacto — `022-nimbuscode-harvest-gateway`

> **Complexidade:** S4 — Arquitetura, segurança, dados ou integração crítica
> **Última atualização:** 2026-08-24
> **Grafo:** [graph.md](./graph.md) · [graph.yaml](./graph.yaml)

---

## 1. Módulos/serviços afetados

| Módulo | Tipo de mudança | Impacto estimado | Owner |
|---|---|---|---|
| `function-app` (endpoint HTTP) | Novo | Alto — ponto único de falha para o recurso Harvest de toda a organização | platform |
| `connector-router` | Novo | Alto — qualquer bug aqui afeta os 3 conectores simultaneamente | platform |
| `azure-ai-connector` | Novo | Médio — afeta só chamadas roteadas ao Azure | platform |
| `google-connector` | Novo | Médio — afeta só chamadas roteadas ao Google | platform |
| `aws-bedrock-connector` | Novo | Médio — afeta só chamadas roteadas à AWS | platform |
| `observability` | Novo | Médio — falha aqui não bloqueia a resposta, mas cega a visibilidade de custo | platform |
| `scripts/harvest-patterns.sh` (repositório-fonte) | **Nenhuma mudança** | N/A — contrato mantido intencionalmente inalterado (FR-001) | platform (nimbus-code-spec-kit-template) |

---

## 2. Dependências impactadas indiretamente

| Módulo | Razão do impacto indireto | Ação necessária |
|---|---|---|
| Todo repositório satélite que configurar `HARVEST_API_URL`/`HARVEST_API_TOKEN` de organização | Passa a depender da disponibilidade do Gateway para que o Harvest funcione | Nenhuma ação obrigatória — Harvest continua opcional/on-demand; indisponibilidade do Gateway não bloqueia nenhum fluxo crítico de nenhum repositório |
| `docs/reuse-catalog.yaml` de cada repositório satélite | Passa a receber entradas reais geradas via Harvest, antes impossível | Nenhuma — é o efeito pretendido da feature |

## 2.1 Conflitos entre homologações (quando houver frentes concorrentes)

| Item | Descrição |
|---|---|
| Branches/homologações concorrentes | N/A — feature nova em repositório próprio, sem outra frente concorrente tocando os mesmos arquivos |
| Estratégia de coexistência | N/A |
| Decisor de conflito funcional | N/A |
| Critério de limpeza da flag | N/A — esta feature não usa feature flag (estratégia de release `direct`, ver `plan.md`) |

---

## 3. Análise de risco

| Risco | Probabilidade | Severidade | Score | Mitigação |
|---|---|---|---|---|
| Credenciais de um dos 3 provedores vazadas/comprometidas | Baixa | Alta | 🟡 Médio | Credenciais só via Azure Key Vault/App Settings, nunca hardcoded; rotação de `HARVEST_API_TOKEN` documentada; cada conector só habilitado quando sua US for implementada (não provisionar as 3 nuvens de uma vez) |
| Gateway indisponível (outage do Azure Functions) | Baixa | Baixa | 🟢 Baixo | Harvest é on-demand/opcional — indisponibilidade não afeta nenhum fluxo crítico de nenhum repositório satélite; falha é visível e explícita (AC-7) |
| Resposta do LLM fora do formato JSON esperado, quebrando `harvest-patterns.sh` | Média | Média | 🟡 Médio | Validação de schema da resposta do LLM antes de retornar ao chamador; se inválida, retornar erro explícito em vez de repassar JSON malformado |
| Custo inesperado por uso indevido/loop acidental de algum repositório satélite | Baixa | Média | 🟢 Baixo | Observabilidade por repositório (FR-005) permite detectar rapidamente; volume de chamadas é sempre on-demand por design, nunca automático/CI (mitigação estrutural, não só reativa) |
| Modelo escolhido (ex.: dentro do Azure AI Foundry) descontinuado pelo provedor | Baixa | Baixa | 🟢 Baixo | Troca de modelo é só uma variável de ambiente (`HARVEST_AZURE_MODEL` etc.) — sem redeploy de código |
| Vazamento de dado de código-fonte sensível via metadados enviados ao LLM externo | Baixa | Alta | 🟡 Médio | Allowlist estrita já herdada de `scripts/harvest-patterns.sh` (ADL-004, SPEC-014) — nunca corpo de método/string literal/dado de runtime, só assinaturas estruturais; Gateway reforça isso não logando/persistindo `metadata` além do necessário para a chamada (FR-008) |

> **Score:** 🔴 Alto (prob. ≥ Média **e** sev. Alta) · 🟡 Médio · 🟢 Baixo

---

## 4. Plano de rollback

```
1. Reverter HARVEST_API_URL/HARVEST_API_TOKEN de organização para vazio —
   scripts/harvest-patterns.sh volta a falhar explicitamente como falha
   hoje (status quo pré-feature), sem afetar nenhum outro fluxo.
2. Se um conector específico estiver com problema (ex.: credencial do
   Google expirada): trocar HARVEST_LLM_PROVIDER para outro conector já
   habilitado, sem esperar correção do conector com problema.
3. Se o próprio Gateway estiver indisponível (outage de infraestrutura):
   nenhuma ação de rollback de código é necessária — o Harvest volta a
   ficar indisponível, que é aceitável dado seu caráter on-demand/opcional.
4. Comunicar Digital Engineering antes de desabilitar o Gateway
   organizacionalmente (impacta todos os repositórios satélite que já
   adotaram o Harvest).
```

---

## 5. Critérios de Go/No-Go para deploy

- [ ] Teste de contrato confirma que a resposta do Gateway é bit-a-bit
      compatível com o que `scripts/harvest-patterns.sh` já espera (AC-1)
- [ ] Ao menos 1 conector (Azure, per prioridade de US1) testado
      end-to-end contra o provedor real, não só com SDK mockado
- [ ] Credenciais provisionadas via Key Vault/App Settings, nenhuma em
      texto plano no repositório (Security Gate)
- [ ] Observabilidade validada — uma chamada de teste aparece no
      Application Insights com `repo`/`provider`/`model`/custo corretos
- [ ] Cenário de falha explícita testado (credencial ausente) e confirma
      que a resposta não é 200 silencioso (AC-7)
- [ ] Revisão humana de segurança obrigatória (S4) concluída antes do
      merge, conforme exigido pela constituição
