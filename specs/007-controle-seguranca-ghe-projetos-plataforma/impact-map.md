<!--
  impact-map.md — Mapa de impacto e análise de risco por feature
  OBRIGATÓRIO para complexidade S3 e S4 — esta feature é S4.
-->

# Mapa de Impacto — `007-controle-seguranca-ghe-projetos-plataforma`

> **Complexidade:** S4 — Arquitetura, segurança, dados sensíveis ou integração crítica
> **Última atualização:** 2026-08-20
> **Grafo:** [graph.md](./graph.md) · [graph.yaml](./graph.yaml)

---

## 1. Módulos/serviços afetados

| Módulo | Tipo de mudança | Impacto estimado | Owner |
|---|---|---|---|
| `docs/security-baseline-ghe.md` | Criação (novo documento) | Baixo — documentação, sem efeito em runtime | Responsável de plataforma |
| `.github/workflows/security-compliance-scan.yml` | Criação (novo workflow) | Médio — roda semanalmente contra toda a organização | Squad de plataforma/governança |
| `scripts/security-compliance-scan.sh` | Criação (novo script) | Médio — lógica central de avaliação e criação de issues | Squad de plataforma/governança |
| GitHub App "Nimbus Code Security Auditor" (novo) | Criação (configuração administrativa, fora do repositório) | **Alto** — credencial com leitura em todos os repositórios da organização | Administrador da organização no GHE |
| `docs/reuse-catalog.yaml` | Atualização futura (ao fechar a feature) | Baixo — apenas adiciona entrada de catálogo | Squad de plataforma |

---

## 2. Dependências impactadas indiretamente

Módulos **não modificados por esta feature** que podem ser afetados por efeito colateral:

| Módulo | Razão do impacto indireto | Ação necessária |
|---|---|---|
| Todos os repositórios da organização | Passam a ser lidos semanalmente pela varredura (metadata, branch protection, secrets configurados) | Comunicar times antes do rollout org-wide; nenhuma ação de configuração é forçada (somente leitura) |
| `docs/label-taxonomy-and-autonomous-dev.md` (taxonomia de labels) | Issues de não conformidade usam labels `priority:*` já existentes | Confirmar que a taxonomia suporta o volume adicional de issues sem reclassificação |
| Rate limit da API do GitHub (organização) | Varredura semanal consome requisições da API — pode competir com outros workflows que usam a mesma API | Monitorar consumo de rate limit; usar paginação e backoff (ver `research.md`) |
| Project V2 "Projeto Plataforma" | Avaliação de leitura da matriz de permissões | Nenhuma alteração — apenas leitura |

---

## 2.1 Conflitos entre homologações (quando houver frentes concorrentes)

| Item | Descrição |
|---|---|
| Branches/homologações concorrentes | Nenhuma frente concorrente conhecida tocando os mesmos arquivos nesta feature |
| Estratégia de coexistência | N/A |
| Decisor de conflito funcional | N/A |
| Critério de limpeza da flag | Remover o flag `security.baseline_scan.org_wide_enabled` 30 dias após rollout 100% estável (ver `plan.md`) |

---

## 3. Análise de risco

| Risco | Probabilidade | Severidade | Score | Mitigação |
|---|---|---|---|---|
| Vazamento da chave privada do GitHub App (leitura de toda a organização) | Baixa | Alta | 🟡 Médio | Armazenar como GitHub Secret; rotação trimestral obrigatória; alerta de uso anômalo via audit log do GHE (ver ADR-0008) |
| Rate limit da API do GitHub interrompe a varredura antes de cobrir todos os repositórios | Média | Média | 🟡 Médio | Paginação + backoff exponencial; contabilizar `repos_com_erro` e reportar sem falhar a execução inteira |
| Falso positivo gera issue incorreta e ruído para os times | Média | Baixa | 🟢 Baixo | Piloto com bounded context `spec-kit-workflow` antes do rollout org-wide; critério de rollback definido no `plan.md` |
| GitHub App mal configurado concede permissão de escrita além do necessário | Baixa | Alta | 🟡 Médio | Revisão humana obrigatória (S4) da configuração de permissões do App antes da instalação; checklist no `quickstart.md` |
| Ausência de observabilidade dedicada (dashboard/alerta) na primeira versão | Média | Baixa | 🟢 Baixo | Aceito como risco documentado nesta fase (ver Security & DevSecOps Gate do `plan.md`); revisar após 1 mês de operação piloto |

> **Score:** 🔴 Alto (prob. ≥ Média **e** sev. Alta) · 🟡 Médio · 🟢 Baixo

---

## 4. Plano de rollback

```
1. Desativar o flag `security.baseline_scan.org_wide_enabled` — a varredura volta
   a rodar apenas no bounded context piloto (ou pode ser pausada via
   workflow_dispatch manual / desabilitação do schedule).
2. Se o GitHub App apresentar comportamento inesperado (ex.: rate limit anômalo,
   permissão incorreta): suspender a instalação do App na organização
   (Settings → GitHub Apps → Suspend) — interrompe imediatamente todo acesso,
   sem precisar reverter código.
3. Issues já criadas permanecem no GHE (não são revertidas automaticamente) —
   times avaliam manualmente se devem ser fechadas ou mantidas.
4. Reverter o merge do workflow/script via PR de revert, se o problema for de
   lógica (não de credencial).
5. Comunicar o responsável de plataforma e os times afetados antes de qualquer
   rollback em produção.
```

---

## 5. Critérios de Go/No-Go para deploy

- [ ] GitHub App criado e instalado na organização com permissões somente-leitura mínimas (validado manualmente por um administrador)
- [ ] Secrets (`SECURITY_SCAN_APP_ID`, `SECURITY_SCAN_APP_PRIVATE_KEY`, `SECURITY_SCAN_APP_INSTALLATION_ID`) configurados no repositório
- [ ] Piloto executado com sucesso no bounded context `spec-kit-workflow` por 2 execuções semanais sem erro de API/permissão
- [ ] Nenhum falso positivo relatado pelo time piloto
- [ ] Documentação (`docs/security-baseline-ghe.md`) revisada e aprovada
- [ ] **Revisão humana obrigatória (S4)** do plano completo e do ADR-0008 registrada e aprovada
- [ ] Plano de rollback revisado e comunicado ao responsável de plataforma

---

> _Este arquivo deve ser revisado pelo tech lead/responsável de segurança antes de `/speckit-tasks`, conforme exigido para features S4._
