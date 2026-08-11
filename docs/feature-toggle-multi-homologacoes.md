# Estratégia para múltiplas homologações com Feature Toggle

## Cenário

Cliente com **3 homologações (branches) ativas** e solicitação de uma **4ª homologação**
que altera arquivos também modificados nas outras frentes.

## Resposta curta

Sim, **Feature Toggle** é a abordagem recomendada para reduzir bloqueio entre frentes,
diminuir conflito tardio e permitir validação progressiva por ambiente/cliente.

## Quando essa estratégia é adequada

Use Feature Toggle quando houver, ao mesmo tempo:

- mudanças concorrentes em arquivos compartilhados;
- necessidade de manter entregas parciais em homologações diferentes;
- risco de regressão funcional se tudo for liberado junto;
- necessidade de controlar ativação por ambiente, cliente ou grupo.

## Padrão operacional recomendado

1. Criar a 4ª frente com toggle **desligado por padrão**.
2. Integrar continuamente com branch base (merge frequente) para reduzir acúmulo de conflito.
3. Publicar em homologação sem ativação global.
4. Ativar por escopo controlado (ex.: cliente piloto, ambiente específico, canário).
5. Medir impacto técnico e de negócio.
6. Expandir ativação gradualmente.
7. Remover toggle após estabilização (evitar dívida de toggle permanente).

## Política de conflitos (governança)

Feature Toggle **não elimina** conflito textual de merge; ele reduz conflito de
comportamento e desacoplamento de release. Por isso:

- conflitos técnicos podem ser resolvidos no fluxo normal de integração;
- conflitos de regra de negócio exigem decisão explícita de Product/Arquitetura;
- toda decisão deve ser registrada no Architecture Decision Log do plano da feature.

## Plano para incorporar a regra aos PRESETs

### Objetivo

Padronizar, nos presets, o uso de Feature Toggle em cenários de múltiplas
homologações concorrentes com sobreposição de arquivos.

### Fase 1 — `nimbus-code-standards`

1. **`templates/constitution-template.md` (wrap)**  
   Incluir princípio não-negociável:
   - em frentes concorrentes com sobreposição, a estratégia padrão é toggle com
     ativação progressiva e critério de remoção.

2. **`templates/plan-template.md` (append)**  
   Adicionar gate obrigatório:
   - seção "Plano de Toggle e Rollout";
   - estratégia de ativação por ambiente/cliente;
   - critérios de rollback;
   - dono da decisão de conflito funcional.

3. **`templates/tasks-template.md` (append)**  
   Adicionar checklist:
   - toggle criado default off;
   - cobertura de teste on/off;
   - evidência de canário/homolog controlada;
   - tarefa explícita de remoção do toggle.

4. **Artefatos de feature**  
   Evoluir `impact-map.md` com bloco padrão:
   - "Conflitos entre homologações";
   - "Estratégia de coexistência";
   - "Condição de limpeza do toggle".

### Fase 2 — `nimbus-code-platform-standards`

1. **`templates/spec-template.md` (prepend)**  
   Campo para declarar se a mudança exige convivência temporária entre comportamentos.

2. **`templates/plan-template.md` (append)**  
   Incluir matriz de ativação por plataforma/surface/tenant, respeitando o ciclo
   de fases (`discovery` → `managed`) e sem alteração direta de ambiente real.

3. **`templates/tasks-template.md` (append)**  
   Checklist de evidências por tenant/ambiente para ativação controlada.

### Fase 3 — Critérios de qualidade e adoção

1. Atualizar READMEs dos dois presets com a nova regra e exemplos de uso.
2. Atualizar documentação operacional do repositório com referência cruzada.
3. Incluir validação no fluxo de revisão:
   - PRs S3/S4 com frentes concorrentes devem explicitar estratégia de toggle.
4. Publicar nova versão SemVer dos presets e atualizar `catalog.json`/bundle conforme política.

## Resultado esperado

- Menos bloqueio entre homologações paralelas.
- Menos regressão por liberação simultânea.
- Conflitos funcionais tratados com decisão explícita e rastreável.
- Rollout mais seguro e reversível.
