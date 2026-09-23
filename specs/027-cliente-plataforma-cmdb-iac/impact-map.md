# Impact Map & Risk Analysis: CMDB↔IaC — Vínculo e Critério de Repositório Dedicado (Feature 027)

## 1. Dependency Impact Analysis

| Módulo/artefato afetado | Tipo de mudança | Impacto |
|---|---|---|
| `platform-governance/db/migrations/005_iac_link_model.sql` | Novo (migration) | Adiciona 3 tabelas (`iac_link_entry`, `inline_inventory_entry`, `link_decision_criteria`); nenhuma tabela existente é alterada |
| `platform-governance/src/domain/cmdb-consolidation-service.js` | Estendido | Novo caminho de lógica para registrar/consultar vínculo; risco de regressão nas funções existentes de consolidação de CMDB |
| `platform-governance/src/domain/link-decision-service.js` | Novo | Isolado; aplica apenas o critério objetivo binário (FR-005) |
| `platform-governance/src/cli/main.js` | Estendido | Novos subcomandos; risco baixo de colisão de nome de comando |
| `docs/adr/0011-repo-first-company.md` | Novo (documentação) | Sem impacto em runtime; risco de nomenclatura pendente (FR-013) |
| `docs/reuse-catalog.yaml` | Atualização pós-implementação (fora deste plano) | Registrar o padrão desta feature após conclusão, via `/nc-builder` |
| **`venha-pra-nuvem/venha-pra-nuvem-client-platform`** (externo) | Fora do alcance desta sessão | Nenhuma alteração feita nesta feature; é o consumidor real do modelo — ver seção 7 (Blast Radius) |

## 2. Risk Assessment Matrix

| Risk | Probability | Impact | Severity | Mitigation |
|---|---|---|---|---|
| **Expectativa de entrega completa nesta sessão**: usuário/Dev espera que clientes reais já estejam vinculados após esta feature | Medium | High | **High** | (1) Escopo cross-repo declarado explicitamente no `plan.md` (Summary + ADL); (2) `tasks.md` (quando criado) deve reforçar a fronteira; (3) Handoff explícito para sessão separada com acesso a `venha-pra-nuvem-client-platform` |
| **Critério objetivo binário (FR-005) insuficiente na prática**: projetos grandes/críticos sem exigência contratual ficam como inline | Medium | Medium | **Medium** | (1) Assumption documentada em `spec.md`; (2) Critério pode ser expandido em versão futura sem reescrever o modelo de dados (campos adicionais em `link_decision_criteria`) |
| **Regressão em `cmdb-consolidation-service.js`**: extensão introduz bug na lógica de consolidação já existente | Low | High | **Medium** | (1) Testes de contrato/integração cobrindo os fluxos já existentes antes de estender; (2) PR com Copilot Code Review obrigatório |
| **Pendência `vpn-nibo-connect-infra` vs `-iac` (FR-013) não resolvida a tempo**: ADR fica com nomenclatura incompleta | Medium | Low | **Low** | (1) ADR publicado como rascunho (Status: Draft) até esclarecimento; (2) Revisão de nomenclatura tratada como follow-up, não bloqueante |
| **Duplicação de conteúdo Terraform por erro humano (FR-003)**: operador copia arquivos em vez de linkar | Low | High | **Medium** | (1) CLI só aceita referência (URL/slug de repo), nunca upload de arquivo `.tf`; (2) Teste de contrato valida que `iac_link_entry` nunca contém payload de arquivo |
| **Baseline de tempo medido de forma inconsistente entre operadores (FR-009)** | Medium | Low | **Low** | (1) Template de planilha/issue padronizado incluído no ADR ou quickstart; (2) Revisão do tech lead antes de consolidar os números |

---

## 3. Rollback Plan

### Scenario: Migration ou lógica de vínculo introduz regressão em `platform-governance/`

**Trigger Conditions**:
- Testes de contrato/integração existentes (migrations 001–004) começam a falhar após a extensão
- `node --test` reporta falha em `cmdb-consolidation-service.js` fora do escopo desta feature
- Revisão humana do PR identifica ambiguidade não coberta pelo critério objetivo (FR-005)

**Rollback Steps** (estimativa: 10–15 min):
1. Reverter o PR desta feature (migration `005_iac_link_model.sql` + extensões de `cmdb-consolidation-service.js`/`main.js`).
2. Confirmar que `node --test` volta a passar 100% no estado anterior (baseline: migrations 001–004).
3. Manter o ADR (`docs/adr/0011-repo-first-company.md`) como rascunho não publicado até nova tentativa.
4. Reabrir a auditoria `/nc-critic` se a causa raiz for uma clarificação mal resolvida.

### Scenario: Escopo cross-repo gera confusão de entrega

**Trigger Conditions**: Dev revisa o plano e espera que `venha-pra-nuvem-client-platform` já tenha sido alterado.

**Ação corretiva** (não é rollback técnico, é esclarecimento): reforçar, antes de qualquer `/nc-builder`, que esta feature entrega apenas o modelo de referência + ADR neste template; a aplicação real requer uma sessão separada com acesso ao repositório do cliente.

## 4. Release Strategy & Staged Rollout

| Fase | Escopo | Repositório |
|---|---|---|
| Fase 1 (esta feature) | Modelo de dados de referência + lógica de decisão + ADR | `nimbus-code` (este) |
| Fase 2 (fora desta sessão) | Aplicação do modelo em `venha-pra-nuvem-client-platform` (migração do cliente GSN Premium existente) | `venha-pra-nuvem-client-platform` |
| Fase 3 (fora desta sessão) | Onboarding do segundo cliente piloto de Managed Services | Novo repo de instância (a criar) |
| Fase 4 (fora desta sessão) | Medição de baseline (FR-009) e consolidação de SC-001 a SC-005 | `venha-pra-nuvem-client-platform` + segundo cliente |

## 5. Data Integrity & State Management

- `iac_link_entry` e `inline_inventory_entry` são **mutuamente exclusivos** por projeto (FR-002) — a integridade é garantida por constraint de banco (`CHECK` ou índice único condicional) na migration `005_iac_link_model.sql`, não apenas por validação de aplicação.
- Migração de `inline_inventory_entry` → `iac_link_entry` (quando o contrato passa a exigir isolamento) MUST preservar o registro anterior (FR-011) — implementar como histórico append-only, nunca `UPDATE` destrutivo.
- Nenhum dado de cliente final ou credencial é armazenado nas novas tabelas (FR-014) — apenas identificadores técnicos e metadados de decisão.

## 6. Critical Path & Success Milestones

1. Migration `005_iac_link_model.sql` criada e testada isoladamente (contrato).
2. `link-decision-service.js` aplica o critério binário e é coberto por AC-3.
3. `cmdb-consolidation-service.js` estendido sem regressão nos testes existentes.
4. CLI expõe registro e consulta (FR-001, FR-002, FR-006).
5. ADR "Repo First Company" publicado como rascunho, com pendência de FR-013 sinalizada.
6. **Marco fora desta sessão**: aplicação real em `venha-pra-nuvem-client-platform` — não faz parte do critério de sucesso desta implementação específica.

## 7. Blast Radius & Affected Systems

| Sistema | Afetado diretamente? | Como |
|---|---|---|
| `platform-governance/` (este repo) | Sim | Nova migration, novo serviço de domínio, extensão de serviço existente e do CLI |
| `docs/adr/` (este repo) | Sim | Novo ADR nomeado |
| `docs/reuse-catalog.yaml` (este repo) | Indireto | Atualização recomendada pós-implementação, fora deste plano |
| `venha-pra-nuvem-client-platform` (externo) | **Não nesta sessão** | É o consumidor futuro do modelo; nenhuma escrita ocorre lá a partir deste plano |
| Segundo cliente piloto (a definir) | **Não nesta sessão** | Onboarding depende de decisão humana de qual cliente e de acesso a um novo/existente repositório |

## 8. Cost & Effort Tracking

| Campo | Valor |
|---|---|
| Estimativa de tokens (esta feature, escopo deste repo) | ~30–45 mil |
| Estimativa de horas humanas | ~4–8 horas (revisão de PR + validação do ADR) |
| Custo da Fase 2–4 (fora desta sessão) | Não estimado aqui — depende de escopo/prazo de uma sessão dedicada com acesso a `venha-pra-nuvem-client-platform` |

## 9. Success Metrics

Ver seção "Operational Metrics Gate" em [plan.md](./plan.md) — SC-001 a SC-006
mapeados com indicador, meta e evidência. Nesta sessão (escopo deste repo),
o critério de sucesso realista é: migration + serviços + CLI + ADR entregues e
testados, **não** a medição real de SC-001–SC-005 (que depende da Fase 2–4).

## 10. Post-Implementation Validation Checklist

- [ ] `node --test` passa 100% em `platform-governance/`, incluindo os novos testes de contrato/integração
- [ ] Migration `005_iac_link_model.sql` aplicada e revertida com sucesso em ambiente de teste local
- [ ] ADR `0011-repo-first-company.md` revisado por pelo menos um humano antes do merge
- [ ] `graph.yaml`/`graph.md` atualizados se a implementação divergir deste plano
- [ ] Pendência FR-013 (`vpn-nibo-connect-infra` vs `-iac`) registrada como follow-up explícito, não esquecida
- [ ] Escopo cross-repo (Fase 2–4) comunicado claramente como próximo passo separado, não como "concluído"

## References

- [spec.md](./spec.md) — especificação funcional desta feature
- [plan.md](./plan.md) — plano de implementação técnica
- [graph.yaml](./graph.yaml) / [graph.md](./graph.md) — grafo de módulos
- `.specify/assessments/cliente-plataforma-operacional/decision.md` — veredito Go de origem
