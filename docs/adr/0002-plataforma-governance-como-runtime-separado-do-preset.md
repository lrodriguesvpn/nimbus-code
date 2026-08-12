# 0002 — Plataforma Governance como Runtime Separado do Preset de Governança

- **Status:** Aceita
- **Data:** 2026-08-12
- **Autores:** @nimbus-code-platform-team
- **Contexto:** feature 004 (Platform Preset CMDB + Baselines de Segurança e Compliance)
- **Revisores:** @nimbus-code-arch-board

---

## Contexto e Problema

A Nimbus-Code precisa de um sistema unificado para inventariar recursos multi-cloud,
consolidar baselines de segurança/compliance e validar conformidade contínua de
infraestrutura. O preset de plataforma (governança/constitution) deve ser capaz de
consumir este estado para decisões de brownfield vs. greenfield.

Porém, existem duas interpretações possíveis da arquitetura:

1. **Preset monolítico**: a constituição do preset contém toda a lógica de coleta,
   consolidação e validação (bloqueante, tudo em uma fase).
2. **Preset + Runtime separados**: o preset é um mecanismo read-only de governance
   que *consome* outputs de um runtime operacional separado (não-bloqueante,
   desacoplado).

A escolha define se a feature é bloqueante para cada inicialização de projeto
ou se pode rodar em background como serviço independente.

## Drivers de Decisão

- **Desacoplamento**: preset e runtime têm ciclos de vida diferentes (governance rules mudam
  raro; inventário/baseline mudam frequente).
- **Performance de bootstrapping**: projeto novo não deve esperar coleta CMDB completa
  antes de iniciar desenvolvimento (latência inaceitável).
- **Reutilização**: múltiplos presets/stacks de infraestrutura podem consumir o mesmo
  CMDB (economia de redundância).
- **Conformidade contínua**: validações de baseline e DSC continuam rodando 24/7
  independente de novas inicializações de projeto.
- **Testabilidade**: runtime com testes isolados; preset com testes de integração apenas
  (reduz tempo de ciclo).

## Opções Consideradas

- **Opção A** — Preset monolítico (lógica de coleta/consolidação embutida na constituição)
- **Opção B** — Preset + Runtime separados (preset consome REST API do runtime)
- **Opção C** — Preset + Runtime no mesmo repositório mas módulos isolados

## Análise das Opções

### Opção A — Preset Monolítico

A constituição executa coleta, consolidação e validação inline durante bootstrap.

- ✅ Simplicidade: uma fase, um fluxo
- ✅ Sem dependência externa (tudo acoplado)
- ❌ **Bloqueante**: novo projeto espera ~5-10min de coleta antes de prosseguir
- ❌ Custo computacional alto por bootstrap
- ❌ Não há como reutilizar CMDB entre múltiplos projetos
- ❌ Baseline/DSC obsoletos após bootstrap (não são atualizados continuamente)

### Opção B — Preset + Runtime Separados

Preset é read-only consumption layer; runtime é serviço operacional persistente.

- ✅ Bootstrap rápido (preset só consulta CMDB via API)
- ✅ CMDB/baseline/DSC atualizados continuamente em background (24h SLO)
- ✅ Reutilizável entre múltiplos stacks/presets
- ✅ Testes isolados por camada (runtime testes em paralelo; preset testes após API)
- ✅ Conformidade contínua sem re-execução a cada novo projeto
- ❌ Complexidade operacional: serviço externo a manter
- ❌ Dependência de rede/API reliability durante bootstrap
- ❌ Estado distribuído (preset não tem memória local)

### Opção C — Mesmo repositório, módulos isolados

Runtime e preset no mesmo repo, mas com interfaces claras (não monolítico).

- ✅ Ciclo de release coordenado
- ❌ Confusão de escopo (qual parte é preset, qual é runtime?)
- ❌ Sem ganho real vs. Opção B se não houver operação compartilhada
- ❌ Testes integrados (não parallelizável como Opção B)

## Decisão

**Opção escolhida: Opção B (Preset + Runtime separados)**, porque:

1. **Performance de bootstrap** é crítico para experiência do desenvolvedor (não deve esperar coleta)
2. **Conformidade contínua** é um requisito explícito (baseline/DSC atualizam 24/7)
3. **Reutilização de CMDB** entre múltiplos projects reduz custo operacional
4. **Desacoplamento de ciclos de vida** permite inovar no runtime sem afetando
   estabilidade do preset (e vice-versa)

**Corolários**:

- Preset ("governed-platform" em `presets/nimbus-code-platform-standards/`) é
  read-only; não inicializa CMDB (isso é trabalho do runtime).
- Runtime ("platform-governance/" em raiz de projeto) é um serviço independente
  que consome recursos cloud e persiste CMDB/baseline/DSC.
- Preset consulta CMDB do runtime via REST API em tempo de bootstrap para detectar
  brownfield vs. greenfield.
- Runtime não conhece preset; é agnóstico a qual governance o usa.

## Consequências

### Positivas

- Bootstrap rápido: ~500ms (chamada REST) vs. ~5-10min (coleta inline)
- Conformidade contínua: baseline/DSC atualizados 24h sem re-bootstrap
- Reutilização: múltiplos presets podem consultar mesmo CMDB
- Testabilidade: runtime testes (unit/contract) rodando independente de preset tests
- Operação: runtime pode escalar horizontalmente, preset permanece stateless

### Negativas / Trade-offs Assumidos

- **Complexidade operacional**: runtime é um microsserviço a manter (deploy, escala, backups)
- **Confiabilidade de API**: bootstrap depende de runtime estar accessible
  (mitigado com fallback: bootstrap prossegue com defaults se API falhar)
- **Latência de dados**: preset vê snapshot de CMDB de até 24h atrás
  (aceitável para brownfield detection, compliance é "point-in-time")

### Ações derivadas

- [x] Scaffold runtime em `platform-governance/` com 40+ arquivos e testes
- [x] Implementar persistência em-memory para runtime (migrável para SQLite)
- [x] Criar CLI `platform-governance/src/cli/commands/start-execution.ts` para scope init
- [x] Documentar contrato de API entre preset e runtime
- [ ] Implementar fallback mode no preset caso runtime API falhe
- [ ] Criar deployment guide para runtime (Dockerfile, K8s manifest, ops runbook)
- [ ] Adicionar SLO monitoring para API latency (p99 < 2s conforme spec)
- [ ] Atualizar constitution-template.md com referência a este ADR

## Links

- Feature spec: `specs/004-platform-cmdb-dsc-model/spec.md`
- Feature plan: `specs/004-platform-cmdb-dsc-model/plan.md`
- Runtime scaffold: `platform-governance/src/runtime/platform-governance.js`
- Preset template: `presets/nimbus-code-platform-standards/templates/constitution-template.md`
- Related: ADR-0001 (Terraform standard)
