# 0003 — Multi-Cloud Selection como 1:N Provider Scope, Não Mandatory All-3

- **Status:** Aceita
- **Data:** 2026-08-12
- **Autores:** @nimbus-code-platform-team
- **Contexto:** feature 004 (Platform Preset CMDB + Baselines de Segurança e Compliance)
- **Revisores:** @nimbus-code-arch-board

---

## Contexto e Problema

A Nimbus-Code opera em AWS, Azure e GCP. Ao governar uma plataforma, operadores
precisam indicar qual(is) provedor(es) inventariar, consolidar e validar.

Duas interpretações de "multi-cloud":

1. **Mandatory all-3**: sempre coleta de Azure + AWS + GCP (mesmo que não estejam em uso)
2. **1:N selection**: operador escolhe 1 a N provedores no momento da inicialização
   e apenas aqueles são coletados e consolidados

A escolha define complexidade operacional (excesso de dados inúteis vs. flexibilidade
de escopo) e overhead computacional (3 chamadas de API toda coleta vs. N chamadas).

## Drivers de Decisão

- **Eficiência operacional**: não coletar dados de provedores não-utilizados reduz latência
  e custo de API calls.
- **Clareza de escopo**: operador declara explicitamente quais provedores governar (auditável).
- **Histórico separado**: cada provider-graph mantém seu próprio histórico de versões
  sem contaminar dados irrelevantes (ex.: Azure-prod não afeta AWS-prod timeline).
- **Flexibilidade**: suporta evolução (eg., adicionar GCP a projeto AWS-only posteriormente).
- **Rastreabilidade**: cada CMDB record mantém referência ao scope onde foi coletado.

## Opções Consideradas

- **Opção A** — 1:N: operador seleciona providers no init; coleta apenas selecionados
- **Opção B** — Mandatory all-3: sempre coleta Azure + AWS + GCP
- **Opção C** — Hybrid: sempre tenta todos 3, mas com fallback silencioso se não disponível

## Análise das Opções

### Opção A — 1:N Selection

Operador passa `--providers azure` ou `--providers azure,aws,gcp` no comando de init.
CLI salva em `.state/execution-scope.json` e CLI/API reusa até override explícito.

- ✅ Sem dados irrelevantes (apenas provedores em uso coletados)
- ✅ Histórico limpo por ambiente (Azure-prod e AWS-prod têm timelines independentes)
- ✅ Auditável: é possível ver qual escopo foi escolhido
- ✅ Suporta evolução incremental (pode adicionar provider depois)
- ✅ Reduz latência e custo de API calls
- ✅ Grafo separado por provider (conforme requerido no Design)
- ❌ Risco: operador esquece de adicionar novo provider ao escopo
- ❌ Requer UI/documentação clara sobre seleção (não é automático)

### Opção B — Mandatory All-3

Sempre tenta Azure + AWS + GCP, independente de onde a infraestrutura realmente está.

- ✅ Simplicidade: sem lógica condicional
- ✅ Cobre caso de uso onde operador não sabe todos os provedores upfront
- ❌ Custo alto: 3 chamadas de API *sempre*, mesmo se só AWS em uso
- ❌ CMDB inflado com dados nulos/vazios (degrada query performance)
- ❌ Histórico contaminado: Azure-prod vira "nunca coletado, skip" 1000x
- ❌ Não é intuitivo: por que coletar dados de algo não em uso?

### Opção C — Hybrid: Try-All, Fallback Silent

Tenta todos 3, mas se um provedor não estiver autenticado/disponível, silencia erro.

- ✅ Cobre ambos casos (operador não precisa saber)
- ✅ Sem configuração explícita necessária
- ❌ Ambiguidade: com 1-2 provedores falhando, é difícil saber qual foi intencional
- ❌ Auditoria fraca: não fica claro qual escopo era esperado vs. real
- ❌ CMDB segue tendo dados inúteis (mesmo que vazios)
- ❌ Falha silenciosa viola princípio de "assumir sucesso por default"

## Decisão

**Opção escolhida: Opção A (1:N Selection with Persistence)**, porque:

1. **Eficiência**: reduz latência e custo de APIs desnecessárias
2. **Auditabilidade**: fica claro qual escopo foi escolhido (essencial para compliance)
3. **Rastreabilidade**: histórico por provider não é contaminado
4. **Flexibilidade**: suporta migração gradual (AWS today → AWS + Azure tomorrow)
5. **Alinha com design já aprovado** (grafo separado por provider)

**Corolários**:

- CLI command: `platform-governance init --providers azure,aws --tenant <id>`
- Persistência: `.state/execution-scope.json` (git-ignored) contém scope aprovado
- Override: `--providers gcp --tenant <id>` aceita override explícito
- API: calls incluem scope selecionado no header `X-Execution-Scope`
- CMDB records: incluem referência ao `executionScope` onde foram descobertos
- Grafo: arquivo `platform-graph.yaml` separa entradas por `provider-environment`
  (e.g., `azure-prod`, `aws-prod`, `gcp-prod` podem coexistir)

## Consequências

### Positivas

- Eficiência operacional: coleta apenas de provedores em uso (~33% economia se só Azure)
- CMDB limpo: sem dados nulos inflacionários
- Auditoria clara: cada execution tem escopo explícito
- Evolução flexível: suporta adicionar provider a um projeto existente
- Histórico isolado: provider-A timeline não afetado por provider-B falta de dados

### Negativas / Trade-offs Assumidos

- **Operador burden**: deve lembrar de atualizar scope se arquitetura muda (ex.: "agora
  também usamos GCP"). Mitigado com alertas se nova infraestrutura é detectada fora
  do escopo (futuro: reconciliation agent).
- **Erro silencioso inicial**: se operador esquece um provider, não há sinal de alerta
  automático (mitigado: documentação clara e validação no bootstrap).
- **Mudança de escopo não retroativa**: histórico anterior com escopo A não é
  re-consolidado se scope muda para A+B (aceitável: cada scope tem seu own CMDB entry).

### Ações derivadas

- [x] Implementar CLI `start-execution.js` com `init --providers <list> --tenant <id>`
- [x] Implementar `.state/execution-scope.json` persistence (git-ignored)
- [x] Implementar `resolveScope()` priority logic (CLI args > stored > default)
- [x] Documentar 1:N model no QUICKSTART.md
- [x] Atualizar `graph.yaml` com provider-scoped entries (e.g., `azure-prod`)
- [ ] Implementar scope validation in API middleware (all providers in header must match known protos)
- [ ] Criar alert for out-of-scope infrastructure detection (future: reconciliation agent)
- [ ] Atualizar constitution-template.md to reference this ADR

## Links

- Feature spec: `specs/004-platform-cmdb-dsc-model/spec.md` (Clarifications section)
- Runtime CLI: `platform-governance/src/cli/commands/start-execution.js`
- Scope format: `.state/execution-scope.json`
- API documentation: TBD (POST `/executions` with `X-Execution-Scope` header)
- Related: ADR-0002 (Preset + Runtime separation)
