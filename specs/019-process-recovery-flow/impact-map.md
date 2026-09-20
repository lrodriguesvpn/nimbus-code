# Impact Map — SPEC 019: Fluxo de Correção de Rota

> Feature S3. Este mapa cobre os artefatos normativos locais e os artefatos de
> distribuição que inicializam repositórios consumidores do Nimbus Code.

## Módulos impactados

| Módulo | Tipo de impacto | Risco | Mitigação |
|---|---|---|---|
| `.specify/memory/constitution.md` | Regra normativa local de idioma e governança | Alto — divergência altera o comportamento esperado do agente | Atualizar via PR, registrar ADR/ADL e exigir aprovação do Architecture Board |
| `docs/developer-guide.md` | Matriz, FAQ e fluxos operacionais | Médio — decisões diferentes entre Dev, BA e agente | Walkthrough dos cenários e rastreabilidade no quickstart |
| `presets/nimbus-code-standards/templates/constitution-template.md` | Distribuição da regra para repositórios de workload | Alto — novos repositórios podem nascer com regra antiga | Comparação automatizada/manual com a constituição local |
| `presets/nimbus-code-platform-standards/templates/constitution-template.md` | Distribuição da regra para repositórios de plataforma | Alto — governança de plataforma pode divergir da de workload | Replicar somente as regras aplicáveis e registrar decisão de escopo |
| `presets/*/templates/project-root/copilot-instructions.md` | Instruções distribuídas aos agentes | Alto — o agente pode seguir orientação diferente da constituição | Atualizar cópias aplicáveis e validar ausência de regra concorrente |
| `.specify/presets/*` | Cópias espelho usadas pelo bootstrap | Alto — bootstrap pode propagar conteúdo defasado | Validar paridade antes do Go/No-Go |
| `specs/019-process-recovery-flow/graph.*` | Grafo de dependências e contexto | Médio — impacto distribuído pode ficar invisível | Incluir presets, cópias espelho e Architecture Board no grafo |

## Riscos e respostas

### R001 — Constituição local e preset divergentes

**Resposta:** bloquear o Go/No-Go quando a comparação identificar divergência
normativa. O Platform Standards deve corrigir as cópias no mesmo PR.

### R002 — Regra duplicada em prompt ou template

**Resposta:** manter a constituição local como ponto normativo único de cada
repositório consumidor; instruções e templates apenas distribuem ou explicam a
regra, sem criar exceções.

### R003 — Mudança de idioma aplicada a preset inadequado

**Resposta:** registrar no ADL quais regras se aplicam a workload e plataforma;
não copiar conteúdo específico de workload para o preset de plataforma.

### R004 — Decisão publicada sem aprovação

**Resposta:** Tarefas de paridade, walkthrough e aprovação do Architecture Board
permanecem abertas até a evidência ser anexada ao PR.

## Rollback

O rollback é feito por revert do PR que alterou a documentação e os templates.
Se apenas um preset apresentar problema, a reversão parcial deve preservar a
constituição local e ser acompanhada de uma nova decisão registrada no ADL.

## Critérios de Go / No-Go

### Go

- `plan.md`, `tasks.md`, grafo e este mapa refletem o impacto S3.
- A constituição local e os presets aplicáveis estão em paridade.
- A matriz de decisão e o teste de recorte de valor foram validados no quickstart.
- O Architecture Board aprovou o pacote.

### No-Go

- Qualquer cópia distribuível contém regra normativa diferente.
- O `impact-map.md` ou o ADL não identifica owner e aprovador.
- O walkthrough não distingue `clarify`, `converge`, atualização de plano e nova spec.
- A aprovação humana ainda está pendente.
