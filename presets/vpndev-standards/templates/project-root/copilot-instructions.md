# Copilot Instructions — <project-name>

<!--
  Este arquivo é o ponto central de configuração do GitHub Copilot para este projeto.
  Gerado pelo preset vpndev-standards. Manter atualizado a cada mudança de arquitetura.
  Referenciado pelo preset via extensão agent-context.
-->

## Contexto do Projeto

- **Repositório:** `<org>/<repo>`
- **Stack principal:** `<linguagem/framework>`
- **Spec Kit workflow:** `vpndev-full-cycle` (specify → plan → tasks → implement)
- **Plano ativo:** `specs/<feature-slug>/plan.md` (atualizar este link na feature em andamento)

---

## Regras Obrigatórias de Grafo

Todo trabalho neste repositório que cria ou altera módulos **deve**:

1. Criar ou atualizar `specs/<feature>/graph.yaml` refletindo todos os módulos envolvidos.
2. Criar ou atualizar `specs/<feature>/graph.md` com os diagramas Mermaid (por código e por business).
3. Para complexidade **S3 ou S4**: criar ou atualizar `specs/<feature>/impact-map.md`.
4. Nenhum PR que altere arquivos em `src/`, `services/`, `infrastructure/` ou `modules/`
   pode ser mergeado sem atualizar o grafo correspondente.

Se você (agente) detectar que o grafo está ausente ou desatualizado ao iniciar uma tarefa,
**pare e atualize o grafo antes de continuar** — não implemente código sem grafo válido.

---

## Escala de Complexidade e Seleção de Modelo (S0–S4)

Antes de iniciar qualquer tarefa, classifique a complexidade e use o modelo correspondente.
**Nunca use modelo mais forte do que o necessário** — isso reduz custo sem perder qualidade.

| Nível | Descrição | Exemplos | Modelo |
|---|---|---|---|
| **S0** | Documentação, comentários, textos | README, ADL, docstring | Auto / modo rápido |
| **S1** | Função isolada, sem dependência externa | Util, helper, validação simples | Auto / modo rápido |
| **S2** | Módulo completo, testes, refatoração | CRUD de um serviço, módulo novo | Auto |
| **S3** | Múltiplos módulos, integração entre serviços | Feature que cruza 2+ serviços | Modelo de reasoning (ex.: GPT-5.4 / Claude Sonnet) |
| **S4** | Arquitetura, segurança, dados sensíveis, integração crítica | Auth, schema de banco, API pública, pipeline de dados PII | Modelo mais forte (ex.: GPT-5.5 / Claude Opus) + **revisão humana obrigatória** |

### Como declarar a complexidade

No início de cada tarefa (ou ao receber um `/speckit-implement`), declare:

```
Complexidade desta tarefa: S<N> — <justificativa breve>
Modelo selecionado: <modelo>
```

### Regras de escalonamento

- **S0 e S1**: use sempre o modelo mais rápido disponível (Auto ou modo inline). Não solicite reasoning.
- **S2**: use Auto. Se encontrar ambiguidade arquitetural, escale para S3 e documente no ADL.
- **S3**: ative reasoning. Documente a decisão no Architecture Decision Log do `plan.md`.
  Atualize `graph.yaml` e `graph.md` antes de implementar.
- **S4**: use o modelo mais forte disponível. **Requerer revisão humana no PR é obrigatório**
  (não opcional). Criar `impact-map.md`. Sinalizar no PR com label `complexity:S4`.

---

## Gates Obrigatórios (Spec Kit VPN Dev)

Antes de `/speckit-tasks`, todos os seguintes gates devem estar aprovados no `plan.md`:

- [ ] **Security & DevSecOps Gate** preenchido
- [ ] **Qualidade de Código, Testes e Observabilidade Gate** preenchido
- [ ] **Module Dependency Graph** (graph.yaml + graph.md) presente e atualizado
- [ ] **Impact Map** presente para S3/S4
- [ ] **Architecture Decision Log** com entradas para decisões relevantes

---

## Estratégia de Release e Feature Flags

- Toda feature S3/S4 deve chegar a produção atrás de feature flag, canary ou
  blue-green — nunca deploy `direct` sem justificativa no `plan.md`.
- Use OpenFeature SDK como abstração do provider de flags.
- Toda flag criada deve ter critério de remoção ou data de expiração no `plan.md`.
- Se encontrar uma flag sem critério de remoção ao revisar código, abrir Issue.

## Decisões de Arquitetura (ADRs)

- Quando uma tarefa exigir uma decisão com impacto duradouro, criar um ADR em
  `docs/adr/NNNN-slug.md` usando o template em
  `presets/vpndev-standards/templates/adr/NNNN-template.md`.
- Referenciar o ADR no Architecture Decision Log do `plan.md`.
- Ver guia completo em `docs/adr-guide.md`.

## Padrões de Código deste Projeto

<!-- Adicionar aqui os padrões específicos do projeto -->
- Convenções de nomenclatura: `<definir>`
- Framework de testes: `<definir>`
- Padrão de logs: JSON estruturado com `trace_id`, `span_id`, `service`, `level`
- Correlation-id: header `X-Correlation-Id` propagado em todas as chamadas entre serviços

---

## Referências

- [Guia do Dev VPN Dev](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/speckit-vpndev-standards/blob/main/docs/developer-guide.md)
- [Seleção de Modelos por Complexidade](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/speckit-vpndev-standards/blob/main/docs/ai-code-quality-and-observability.md#7-seleção-de-modelo-por-complexidade-s0s4)
- [Grafos de Módulos — Guia](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/speckit-vpndev-standards/blob/main/docs/module-graphs.md)
