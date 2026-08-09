<!--
  Este arquivo é um ARTEFATO DE PROJETO (não um doc central do bundle).
  É copiado automaticamente pelo bootstrap.sh para docs/cost-profiles-and-rates.md
  do repositório do projeto na primeira instalação do bundle.

  Depois de copiado, ele é SEU — o time do projeto pode e deve editar os valores
  (tabela de perfis/taxas) para refletir a realidade de custo real do time. Não
  há sincronização automática de volta com o bundle: mudar a taxa aqui é uma
  decisão de projeto, não uma mudança de política organizacional (essa distinção
  está detalhada na seção "Como ajustar" abaixo).
-->

# Perfis de Custo Humano e Taxas Horárias — VPN Dev

Este documento define os **perfis de senioridade** e a **taxa média de
custo/hora** usados para calcular o custo real de tarefas no
[modelo híbrido (agente + humano)](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/speckit-vpndev-standards/blob/main/docs/ai-code-quality-and-observability.md#8-modelo-híbrido-agentes-de-ia--humanos-codando-juntos):

```
Custo real da tarefa = custo de tokens (agente) + (horas humanas × taxa do perfil)
```

## Perfis e valores padrão

| Perfil | Taxa média (R$/hora) | Observação |
|---|---|---|
| **Júnior** | R$ 40,00 | Perfil de entrada, geralmente com maior necessidade de revisão humana adicional |
| **Pleno** | R$ 60,00 (padrão) | Usado como taxa **padrão/blended** quando o perfil de quem lançou as horas não é registrado por pessoa |
| **Sênior** | R$ 90,00 | Inclui decisões de arquitetura (S4), revisão técnica crítica e pareamento em tarefas complexas |

> **Somente senioridade, não tecnologia.** Estes perfis classificam por
> experiência (tempo/responsabilidade), não por stack técnica — a tecnologia
> influencia *quem* é alocado para a tarefa, não a taxa em si. Isso mantém a
> tabela simples e evitar uma matriz combinatória (perfil × tecnologia) que na
> prática é difícil de manter atualizada.

## Como aplicar no cálculo

1. Ao lançar horas no campo **"Horas Humanas"** do GitHub Project (ver
   [`docs/ai-code-quality-and-observability.md` seção
   8](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/speckit-vpndev-standards/blob/main/docs/ai-code-quality-and-observability.md#onde-lançar-as-horas-humanas)),
   registre também, no comentário da issue/PR, **qual perfil** fez aquele
   trabalho (Júnior/Pleno/Sênior) — o campo numérico do Project não distingue
   perfil sozinho.
2. Se uma tarefa teve horas de mais de um perfil (ex.: Júnior implementou,
   Sênior revisou), registre os dois lançamentos separadamente no comentário,
   mesmo que o campo do Project some o total.
3. No fechamento da feature (checklist "Estimativa vs. Consumo Real" do
   `tasks.md`), o custo humano final é:
   `Σ (horas de cada perfil × taxa daquele perfil)`.

## Como ajustar por projeto

Os valores desta tabela **não são fixos pelo bundle** — são um ponto de
partida documentado. Para ajustar:

- Mudança pontual de valor (reajuste anual, região, squad específico): edite a
  tabela diretamente neste arquivo (já copiado para o seu projeto) e registre a
  data da mudança num comentário Git ou no changelog do projeto.
- Mudança estrutural (ex.: adicionar um 4º perfil, mudar de R$/hora para
  outra moeda, ou vincular a taxa a uma tabela de RH formal): documente como
  **Architecture Decision Record** (`docs/adr/`) — é uma decisão de política
  de custo, não só um número.

## Alinhamento com boas práticas de gestão de projeto

Esta abordagem segue práticas já consolidadas em gestão de projetos e FinOps:

- **PMBOK — processo "Estimate Costs"**: usar uma **taxa de recurso por
  perfil/senioridade** (*resource cost rate*), em vez de custo individual por
  pessoa, é a forma padrão de estimar custo de recursos humanos quando o
  objetivo é rastrear custo de tarefa/projeto, não remunerar indivíduos.
- **Rate cards de consultoria/SOW/T&M**: contratos de time and materials
  comumente usam 3 faixas de senioridade (Júnior/Pleno/Sênior) como a
  granularidade padrão — tecnologia normalmente não entra na taxa, só na
  alocação.
- **FinOps (unit economics)**: mede-se custo por unidade de trabalho (aqui,
  por tarefa/issue) combinando múltiplas fontes de custo (agente + humano) —
  o mesmo racional já aplicado à estimativa de tokens do agente.

## ⚠️ Regra de uso obrigatória

Este dado existe **exclusivamente para compor o custo real da tarefa**
(FinOps/controle de orçamento). **Nunca deve ser usado para avaliar
performance individual** (ex.: "quem gasta menos horas é mais produtivo",
ranking de velocidade por dev). Usar horas lançadas como métrica de
performance individual cria um incentivo perverso — o dev passa a sub-registrar
horas para "parecer eficiente", o que destrói a confiabilidade do dado de
custo real para todo mundo. Se este dado for usado fora do contexto de
custo/orçamento, a própria prática perde a validade.

## PMO — status por projeto e status global

Ver [`docs/ai-code-quality-and-observability.md` seção
8](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/speckit-vpndev-standards/blob/main/docs/ai-code-quality-and-observability.md#como-o-pmo-acompanha-o-status-visão-por-projeto-e-visão-global)
para como o PMO consome esse dado: visão por projeto via Insights do GitHub
Project, e visão consolidada (multi-repo) via `scripts/pmo-cost-rollup.sh`.

## Vínculo com Oportunidade D365

O mesmo GitHub Project que tem o campo "Horas Humanas" também tem um campo de
texto **"Oportunidade D365"** — cole ali a URL completa da Oportunidade no
Dynamics 365 quando a issue/PR estiver ligada a uma venda/negócio específico.
Isso permite depois cruzar o custo real desta tabela (tokens + horas × taxa)
com a Oportunidade de origem, inclusive de forma consolidada entre múltiplos
repositórios via `scripts/pmo-cost-rollup.sh`.
