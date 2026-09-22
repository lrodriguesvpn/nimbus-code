# Decision: Operação de cliente e plataforma

- **Slug**: cliente-plataforma-operacional
- **Decided (Round 1)**: 2026-09-21T15:43:24-03:00
- **Decided (Round 2)**: 2026-09-22T08:10:06-03:00
- **Decided (Round 2b — escopo ampliado)**: 2026-09-22 (mesma sessão, a pedido do usuário)
- **Verdict**: go — Option B completa (apetite medium)
- **Artifacts reviewed**: intake.md (Round 1 & Round 2) | research.md (Round 1 & Round 2) | problem.md (Round 1 & Round 2) | concept.md (Round 1 & Round 2)

## Scorecard (Round 2)

| Criterion | Rating (Round 1 → Round 2) | Justificativa |
|-----------|------------------------------|----------------|
| Problem validity | adequate → **strong** | A Round 2 confirmou, com evidência direta do GitHub Enterprise, que o padrão já está em produção: `venha-pra-nuvem-client-platform` opera o serviço comercial GSN Premium, e `vpn-nibo-connect`/`vpn-nibo-connect-iac` já separam código e IaC. O problema deixou de ser hipotético. |
| Evidence strength | weak → **adequate** | A Round 2 trouxe evidência estrutural/documental direta do ambiente real (auditoria de repositórios, specs, bounded contexts), corrigindo inclusive uma leitura equivocada da Round 1. Ainda falta evidência quantitativa (tempo de localização, drift, retrabalho, custo) e entrevistas — por isso não é "strong". |
| Value vs. inaction | adequate | Mantido. Ownership ambíguo, IaC potencialmente dispersa e falta de infraestrutura versionada no Nuvem 365 são custos plausíveis, mas o impacto financeiro específico segue não quantificado. |
| Feasibility / appetite | adequate → **strong** | O `concept.md` (Round 2) recomenda a Option B apoiada no núcleo de baixíssimo risco da Option A — formalizar o que já existe, sem migrar nada em produção. Apetite claro (small → medium) e caminho incremental bem sequenciado. |
| Strategic fit | adequate | Mantido. Alinhamento confirmado com dois negócios reais (GSN Premium/Managed Services e Nuvem 365/FinOps), mas modelo comercial, preço e constituição estratégica formal seguem não confirmados. |
| Risk posture | weak → **adequate** | O escopo aprovado nesta rodada (ver Veredito) não migra nem altera `venha-pra-nuvem-client-platform` em produção, e a segregação entre clientes continua garantida pela separação física de repositórios já validada. Persistem lacunas de LGPD, RACI e segregação formal de secrets, mas fora do caminho crítico do escopo aprovado. |

## Atualização Round 2b — escopo ampliado a pedido do usuário

Após o veredito inicial (Go restrito ao núcleo da Option A), o usuário pediu
para seguir com a **Option B completa (apetite medium)** e esclareceu um
ponto que não estava suficientemente explícito em `concept.md`: a topologia
exata é **um Repo Plataforma central por CLIENTE**, com **um repositório de
IaC dedicado por PROJETO/ativo** dentro desse cliente (quando o critério
objetivo indicar necessidade). `concept.md` foi atualizado com uma seção
"Topologia confirmada (Option B)" registrando essa hierarquia
(cliente → Repo Plataforma central → N projetos, cada um com repo de IaC
dedicado linkado ou apenas inventariado inline). O veredito abaixo substitui
o escopo restrito anterior.

## Veredito

### ✅ GO — Option B completa (Repo Plataforma central por cliente + repo de IaC dedicado por projeto)

A ideia é aprovada para avançar à especificação formal com o escopo completo
da Option B de `concept.md`, incluindo a topologia confirmada pelo usuário:

- **Aprovado**:
  1. Formalizar, dentro do Repo Plataforma existente
     (`venha-pra-nuvem-client-platform` como instância de referência para o
     cliente Venha Pra Nuvem/GSN Premium), o modelo de vínculo "CMDB registra
     repo de aplicação + repo de IaC dedicado (quando houver)" e o critério
     objetivo de quando um projeto/ativo ganha repositório de IaC dedicado
     (modelo `vpn-nibo-connect-iac`) vs. quando permanece apenas como
     inventário/IaC inline no Repo Plataforma central do cliente.
  2. Adotar formalmente a topologia **1 cliente → 1 Repo Plataforma central →
     N projetos**, cada projeto com repo de IaC dedicado próprio (linkado,
     nunca duplicado) ou apenas inventariado/IaC inline no central — como
     modelo de dados obrigatório do CMDB na especificação.
  3. Documentar "Repo First Company" como padrão nomeado (ADR/pattern) da
     organização, usando `vpn-nibo-connect` (projeto com repo de IaC
     dedicado) e ao menos um projeto sem repo dedicado como casos de teste.
  4. Formalizar e repetir o processo de instanciação do Repo Plataforma
     central em pelo menos um segundo cliente de managed services, medindo
     baseline de localização, rastreabilidade e tempo de auditoria como
     parte do próprio rollout.
- **Não aprovado nesta rodada**: Option C (motor central único multi-cliente,
  com possível migração/aposentadoria de `venha-pra-nuvem-client-platform`)
  e qualquer integração real com o domínio FinOps do Nuvem 365 (bounded
  context `infra`). Ambas ficam registradas como evolução futura,
  condicionadas a evidência de demanda multi-cliente e de esforço de
  propagação manual entre instâncias centrais que o piloto do escopo
  aprovado venha a revelar.

### Condições do Go (a resolver durante `/nc-spec`/`/nc-clarify`, não bloqueiam o Go)

As lacunas abaixo não impedem o Go porque o escopo aprovado é interno,
advisory, de baixo risco e não toca produção de cliente — mas devem virar
requisitos explícitos ou `[NEEDS CLARIFICATION]` endereçados na especificação
formal, não ficar em aberto na implementação:

1. Critério quantitativo/objetivo final para "repo de IaC dedicado vs.
   inventário central" (porte, criticidade, exigência contratual) — o
   `concept.md` propõe a dimensão, mas os limiares exatos precisam virar
   requisito testável no `spec.md`.
2. Quem aprova/revisa uma nova entrada de vínculo CMDB↔IaC (papel humano,
   possivelmente reaproveitando aprovadores já existentes de
   `vpn-nibo-connect-iac`, sem exigir um RACI novo nesta fase).
3. Esclarecer o papel de `vpn-nibo-connect-infra` frente a `vpn-nibo-connect-iac`
   antes de fixar a nomenclatura padrão de repositórios de IaC no ADR "Repo
   First Company".
4. Checklist mínimo de LGPD/segurança para o próprio registro do CMDB
   (metadados, não dados sensíveis do cliente final), já que o escopo
   aprovado não cria nem move estado/segredos de cliente.
5. Método e cadência de medição do baseline (tempo de localização,
   rastreabilidade, tempo de auditoria) a ser coletado durante o rollout do
   escopo aprovado, para servir de evidência à próxima onda (segundo cliente
   + Option C).

### Por que não Kill

O problema é real, já validado em produção (`venha-pra-nuvem-client-platform`,
`vpn-nibo-connect-iac`), e o escopo aprovado (Option B completa) tem caminho
de implementação claro e incremental — formaliza e replica o que já existe,
não constrói algo novo do zero, e a topologia confirmada pelo usuário
(central por cliente, IaC por projeto) já é exatamente o que está em
produção hoje. Descartar a ideia agora jogaria fora uma correção de lacuna
concreta (vínculo CMDB↔IaC) já demandada pela própria operação.

### Por que não Needs Clarification (bloqueante)

A Round 1 bloqueou o avanço porque as perguntas de arquitetura ("modelo de
referência vs. motor central") e de vínculo CMDB↔IaC eram incertezas de
**viabilidade e desenho da ideia**. A Round 2 resolveu ambas com evidência
direta e concreta, e a topologia confirmada pelo usuário nesta rodada (Round
2b) fecha o último ponto de ambiguidade conceitual — a granularidade
cliente/projeto. A Option C (motor central) continua fora, evitando o maior
risco remanescente (migrar/aposentar um sistema em produção sem demanda
multi-cliente comprovada). As lacunas que sobram — RACI fino, LGPD, limiares
quantitativos exatos, nomenclatura de `-infra` vs. `-iac` — são de
**detalhamento de especificação**, apropriadas para `/nc-spec`/`/nc-clarify`,
e não justificam mais uma rodada de research/define antes de especificar a
Option B completa.

## Handoff para Spec Formal

**Próximos passos recomendados:**

```text
/nc-spec slug=cliente-plataforma-operacional
```

ou, caso ainda não exista `interview.md` para esta feature:

```text
/nc-intake
```

seguido de `/nc-spec`, referenciando este assessment (`problem.md`,
`concept.md`, `decision.md`) como contexto de origem.

**Escopo explícito do handoff**: a Option B completa — vínculo CMDB↔IaC +
critério objetivo + ADR "Repo First Company" + topologia formal "1 cliente →
1 Repo Plataforma central → N projetos (IaC dedicado ou inventário inline)"
+ repetição do processo de instanciação em um segundo cliente com medição de
baseline — conforme aprovado acima. A Option C (motor central multi-cliente)
e a integração real com o domínio FinOps do Nuvem 365 **não** devem ser
incluídas na spec resultante — se, após o rollout da Option B, houver
evidência de demanda multi-cliente que justifique um motor central, uma nova
rodada de spec/feature deve tratar essa extensão, não uma expansão silenciosa
de escopo desta spec.
