# Mapa de Impacto — `029-harness-corporativo-ide`

> **Complexidade:** S4 — Arquitetura, segurança, privacidade (LGPD), dados e integração com LLM externo  
> **Data:** 2026-09-22  
> **Grafo:** [graph.md](./graph.md) · [graph.yaml](./graph.yaml)

---

## 1. Módulos e Serviços Afetados

| Módulo | Tipo de Mudança | Impacto Estimado | Owner |
|---|---|---|---|
| `scripts/harvest-patterns.sh` | Modificação (Extensão) | Alto — adiciona modo `--source ide-harness` e validações de isolamento estrito de escrita | platform (nimbus-code-spec-kit-template) |
| `scripts/lib/harness_anonymizer.py` | Novo | Crítico — motor local de detecção e redação preventiva; falha aqui expõe credenciais ou PII ao LLM | security / platform |
| `scripts/lib/central_repo_writer.py` | Novo | Médio — valida integridade e isolamento de escrita no repositório central dedicado | platform |
| `nimbus-code-harness-corporativo` (GHE) | Novo Repositório Central | Alto — repositório centralizado de governança para armazenar itens brutos, triagem e regras promovidas | comitê nimbus-code / arch-board |
| `scripts/triage-cli.py` (Repo Central) | Novo | Médio — ferramenta de apoio para deliberação, conferência de quórum e promoção pelo Comitê | architecture-board |
| `scripts/purge-expired.py` (Repo Central) | Novo | Alto — automação responsável por garantir conformidade legal excluindo itens com >90 dias | governance / devsecops |
| `scripts/sync-corporate-harness.sh` | Novo (Etapa 2) | Médio — script de distribuição idempotente para satélites via padrão do `bootstrap.sh` | platform |
| `docs/reuse-catalog.yaml` (Local) | **Nenhuma Mudança** | N/A — protegido explicitamente contra qualquer escrita nesta modalidade (HRN-0005) | squads de projeto |

---

## 2. Dependências Impactadas Indiretamente

| Módulo / Dependência | Razão do Impacto Indireto | Ação Necessária |
|---|---|---|
| `HARVEST_API_URL` (Harvest Gateway) | Receberá payloads adicionais no formato `ide-agent-harness` contendo prompts de agentes | Nenhuma mudança estrutural no gateway — o contrato de requisição HTTP é integralmente respeitado |
| Repositórios satélite das squads | Passam a ter a opção de receber regras corporativas de seu bounded context na Etapa 2 | Opcional e idempotente — nenhuma squad é forçada a receber regras sem consentimento |
| Ferramentas de IDE dos devs (`~/.claude`, `.cursor`) | Lidas em modo somente-leitura pelo harvester local | Nenhum arquivo pessoal é alterado ou removido no momento da captura |

---

## 2.1 Conflitos entre Homologações e Coexistência de Branches

| Item | Descrição |
|---|---|
| Branches/homologações concorrentes | Nenhuma concorrência direta no repositório template; as mudanças em `scripts/harvest-patterns.sh` são aditivas e não afetam a extração padrão de código (`--source code`). |
| Estratégia de coexistência | Isolamento total por flags (`--source ide-harness` ativa a nova branch de execução). |
| Decisor de conflito funcional | Leonardo Rodrigues (Product Sponsor & Architecture Lead). |
| Critério de limpeza da flag | N/A — ferramenta CLI sem necessidade de feature flag de aplicação web. |

---

## 3. Análise de Risco e Matriz de Mitigação

| Risco | Probabilidade | Severidade | Score | Mitigação Arquitetural |
|---|---|---|---|---|
| **Vazamento de credencial / token no envio ao LLM** (dev colou chave de API ou senha no `CLAUDE.md`) | Baixa | Crítica | 🟡 Médio | Sanitização obrigatória no `harness_anonymizer.py` com regex determinístico + entropia de Shannon + validação **Fail-Closed** antes de qualquer chamada HTTP. |
| **Não conformidade LGPD / retenção excessiva** (dados brutos mantidos indefinidamente) | Baixa | Alta | 🟡 Médio | Expurgo automático semanal com retenção máxima de 90 dias (3 meses) para itens brutos não promovidos (`scripts/purge-expired.py`). |
| **Poluição acidental do catálogo do projeto local** (gravar regras pessoais no `docs/reuse-catalog.yaml`) | Baixa | Média | 🟢 Baixo | Validação bloqueante no CLI: recusa expressa de escrita se o destino apontar para o catálogo local (mitigação contra HRN-0005). |
| **Promoção inadequada de regra prejudicial** (regras confusas ou restritivas aplicadas à empresa) | Baixa | Alta | 🟡 Médio | Promoção 100% manual e exclusiva do Comitê Nimbus Code com quórum mínimo de 2 membros técnicos e aprovação via `CODEOWNERS`. |
| **Sobrescrita de personalizações de desenvolvedores** (redistribuição satélite apagar regras locais) | Baixa | Média | 🟢 Baixo | Algoritmo de bloco gerenciado do `bootstrap.sh`: preserva customizações e gera `.divergent` em caso de conflito. |
| **Execução sem validação jurídica / DPO** (coleta em produção sem cobertura de NDA/DPA) | Baixa | Alta | 🟡 Médio | **Gate de Execução**: o desenvolvimento utiliza dados sintéticos de teste; coleta real só é habilitada após aprovação formal do parecer do DPO. |

> **Score:** 🔴 Alto (prob. ≥ Média **e** sev. Alta) · 🟡 Médio · 🟢 Baixo

---

## 4. Plano de Rollback

```text
1. Se for detectada qualquer falha no motor de sanitização ou suspeita de falso negativo:
   - Suspender imediatamente as execuções de captura comunicando o time piloto.
   - O repositório central dedicado permite purga emergencial imediata via:
     python3 scripts/purge-expired.py --retention-days 0 --repo-dir <central-repo>
   - Todos os arquivos na área raw/ são eliminados instantaneamente.

2. Se a integração com o Gateway falhar ou degradar:
   - A ferramenta continua permitindo uso local com --anonymize-only sem impacto operacional.
   - Como o Harvest é 100% on-demand, sua desativação temporária tem impacto zero sobre os pipelines de CI/CD ou aplicações em produção.

3. Se a redistribuição para satélites gerar inconsistências:
   - Como os arquivos são versionados no Git de cada satélite, o rollback é trivial via 'git checkout' ou reversão de PR.
```

---

## 5. Critérios de Go/No-Go para Ativação Operacional

- [ ] Suíte de testes unitários do sanitizador (`test_harness_anonymizer.py`) cobrindo 100% dos padrões de tokens e entropia com sucesso.
- [ ] Teste de integração BATS confirmando que `scripts/harvest-patterns.sh --source ide-harness` aborta preventivamente em caso de segredo colado (Fail-Closed comprovado).
- [ ] Teste de isolamento de escrita comprovando que `docs/reuse-catalog.yaml` permanece inalterado.
- [ ] Repositório central `nimbus-code-harness-corporativo` provisionado no GHE com proteção de branches e `CODEOWNERS` configurado.
- [ ] Workflow de expurgo automático de 90 dias testado e validado contra arquivos com timestamp retroativo.
- [ ] **Gate Jurídico/DPO**: Parecer formal emitido e arquivado em `docs/compliance/dpo-legal-opinion.md` antes de qualquer execução de coleta com colaboradores humanos reais.
- [ ] Revisão humana de segurança obrigatória (S4) aprovada pelo Security Guardian.
