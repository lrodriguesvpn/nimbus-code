# Concept — Agente de Prototipação de Telas

## Identificação

| Campo | Valor |
|---|---|
| **Assessment** | `agente-prototipacao-telas` |
| **Fase** | Concept Shaping |
| **Data** | 2026-09-21 |
| **Insumos** | [`intake.md`](./intake.md), [`research.md`](./research.md), [`problem.md`](./problem.md) |
| **Status** | Conceito moldado — pronto para `/nc-assess-decide` |

## Recapitulação do problema

Ver [`problem.md`](./problem.md). Resumo: falta uma capacidade governada e
rastreável para explorar/validar experiência de interface **antes** do código,
reutilizável nos dois fluxos (Ideação e Spec Formal), sem duplicar o
julgamento de UX/acessibilidade já existente em `nc-designer`.

## Opções de conceito

### Opção 1 — Modo de prototipação dentro do `nc-designer` (mínima)

**Esboço conceitual:**
Não criar nenhum agente ou skill novo. Adicionar um **novo modo** ao
`nc-designer` existente — por exemplo `nc-designer prototype` — ao lado dos
modos já existentes (`audit`, `critique`, `polish`, `harden`). Esse modo lê o
contexto disponível (`intake.md`/`problem.md` no Fluxo A, ou `interview.md`
no Fluxo B) e produz uma representação estruturada em Markdown: telas,
estados, componentes principais e fluxo de navegação em texto/ASCII/diagrama
Mermaid — sem gerar HTML/CSS renderizável. O humano revisa esse esboço e
decide se precisa evoluir para algo mais visual (o que, nesta opção, seria
feito manualmente fora do Nimbus Code).

**Apetite:** `small` (poucos dias — é uma extensão de instrução em um
`SKILL.md` já existente, sem novo pipeline, sem nova integração).

**Trade-offs:**
- ✅ Reaproveita 100% do julgamento de UX/acessibilidade já presente no
  `nc-designer`, sem duplicar regras.
- ✅ Risco mínimo de regressão — não cria novo agente, novo hook ou novo gate.
- ✅ Compatível imediatamente com os dois fluxos, pois `nc-designer` já é
  portável entre Copilot, Claude Code e Antigravity.
- ⚠️ Saída é texto/diagrama, não navegável — pode não ser suficiente para
  stakeholders que precisam "ver e clicar" antes de aprovar.
- ⚠️ Não resolve, por si só, a rastreabilidade formal (precisaria de convenção
  manual de onde salvar o arquivo gerado).
- ❌ Não atende bem casos onde a validação depende de interatividade (ex.:
  fluxos com múltiplos estados condicionais).

**Esta é a "smallest thing that could work".**

### Opção 2 — Nova skill dedicada `nc-prototype` com artefato versionado (intermediária)

**Esboço conceitual:**
Criar uma skill própria (`nc-prototype` ou nome equivalente), com seu próprio
`SKILL.md`, especializada em transformar contexto (ideia, problema, entrevista
ou requisitos parciais) em um artefato de protótipo estruturado e versionável:
um documento `prototype.md` com telas, componentes, estados, dados de exemplo
e navegação declarada (ex.: tabela de transições entre telas), acompanhado
opcionalmente de um HTML estático simples por tela (sem framework, apenas
para visualização rápida no navegador). A skill invoca `nc-designer` em modo
`critique`/`audit` como etapa obrigatória antes de considerar o protótipo
"pronto para revisão". O artefato é salvo em
`.specify/assessments/<slug>/prototype.md` (Fluxo A) ou
`specs/<feature>/prototype.md` (Fluxo B), com um cabeçalho de rastreabilidade
apontando para a ideia/spec de origem.

**Apetite:** `medium` (algumas semanas — inclui novo `SKILL.md`, definição de
schema do `prototype.md`, template de HTML estático, e testes de integração
com `nc-designer`).

**Trade-offs:**
- ✅ Produz artefato navegável mínimo (HTML estático), suficiente para
  validação visual sem exigir ferramenta externa.
- ✅ Rastreabilidade explícita via convenção de nome/local de arquivo e
  cabeçalho padronizado.
- ✅ Ainda reaproveita `nc-designer` como guardrail, evitando duplicação de
  regras de acessibilidade/qualidade.
- ⚠️ Introduz mais um artefato para manter e versionar por feature/ideia,
  aumentando levemente a carga de governança.
- ⚠️ Exige decisão de schema (quais campos o `prototype.md` deve ter) que
  ainda não foi tomada — risco de retrabalho se o schema mudar depois.
- ❌ Ainda não resolve aprovação formal (quem assina que o protótipo está
  pronto) — precisaria de um RACI específico, hoje inexistente.

### Opção 3 — Etapa formal obrigatória integrada ao processo (ampla)

**Esboço conceitual:**
Elevar a prototipação a uma **etapa formal do processo Nimbus Code**,
equivalente em formalidade a `/nc-critic` ou ao Security & DevSecOps Gate:
um novo gate de "Prototype Gate" no `plan.md`/`concept.md`, com hook
`before_spec`/`before_plan` em `.specify/extensions.yml`, checklist de
acessibilidade obrigatório (via `nc-designer`), RACI formal de aprovação do
protótipo (papéis definidos em `docs/label-taxonomy-and-autonomous-dev.md`
ou equivalente), suporte a múltiplos formatos de saída (wireframe, HTML
navegável, e opcionalmente exportação para ferramentas externas de design) e
rastreabilidade obrigatória verificada por `nc-governor` antes de liberar
`/nc-tasks`.

**Apetite:** `large` (meses — exige mudanças de governança, novo gate
obrigatório, schema versionado, RACI formal, testes de regressão em todo o
pipeline de specs existentes, e possível resistência de adoção por adicionar
fricção a features que não precisam de prototipação visual).

**Trade-offs:**
- ✅ Máxima rastreabilidade e conformidade — nenhuma feature com superfície
  visual avança sem protótipo aprovado.
- ✅ Acessibilidade e qualidade de UX garantidas por gate, não por boa vontade.
- ⚠️ Alto custo de implementação e manutenção; afeta o pipeline de **todas**
  as specs, não só as que precisam de UI.
- ⚠️ Risco de virar burocracia para features sem componente visual relevante
  (ex.: mudanças de backend/infra) se o gate não tiver critério claro de
  aplicabilidade.
- ❌ Esforço desproporcional para uma ideia ainda não validada com uso real —
  não há evidência (métricas) que justifique esse investimento agora (ver
  gaps em `problem.md`).

## Recomendação de shape

**Recomendada para o MVP: Opção 1**, com a **Opção 2 como evolução natural**
caso as métricas propostas em `problem.md` comprovem valor após uso real.

Racional:
- A Opção 1 tem apetite mínimo, risco mínimo, e resolve a dor principal
  (falta de qualquer instrumento de exploração visual antes do código) sem
  comprometer investimento antes de haver evidência de adoção.
- A Opção 3 é prematura: nenhuma métrica de `problem.md` foi medida ainda, e
  criar um gate obrigatório de governança sem essa evidência viola o
  princípio de "não impor decisão de arquitetura sem justificativa" registrado
  nas instruções institucionais do projeto.
- A Opção 2 fica como próximo passo natural, não como MVP: se a Opção 1 for
  adotada e mostrar valor (redução de retrabalho, adoção nos dois fluxos),
  evolui-se para um artefato navegável dedicado.

## Handoff

**Recomendação:** avançar para `/nc-assess-decide` com a Opção 1 como
proposta de escopo mínimo (Go condicionado a esse escopo), registrando a
Opção 2 como possível expansão futura e a Opção 3 como descartada nesta
fase por falta de evidência e apetite desproporcional.
